extproc perl -Sw
#!/usr/bin/perl -w

use FindBin;
use lib "$FindBin::Bin";

use MP3::Tag;
use Getopt::Std 'getopts';
use strict;

BEGIN { eval 'require Music_Translate_Fields' }

my %opt;
getopts('c:a:t:l:n:g:y:uDp:C:P:E:G@', \%opt);
exec 'perldoc', '-F', $0 unless @ARGV;

# keys of %opt to the MP3::Tag keywords:
my %trans = (	't' => 'title',
		'a' => 'artist',
		'l' => 'album',
		'y' => 'year',
		'g' => 'genre',
		'c' => 'comment',
		'n' => 'track'  );

# Interprete Escape sequences:
my %r = ( 'n' => "\n", 't' => "\t", '\\' => "\\"  );
for my $e (split //, (exists $opt{E} ? $opt{E} : 'p')) {
  $opt{$e} =~ s/\\([nt\\])/$r{$1}/g if defined $opt{$e};
}
if ($opt{'@'}) {
  for my $k (keys %opt) {
    $opt{$k} =~ s/\@/%/g;
  }
}

# Configure stuff...
if (defined $opt{C}) {
  my ($c) = ($opt{C} =~ /^(\W)/);
  $c = quotemeta $c if defined $c;
  $c = '(?!)' unless defined $c;		# Never match
  my @opts = split /$c/, $opt{C};
  shift @opts if @opts > 1;
  for $c (@opts) {
    $c =~ s/^(\w+)=/$1,/;
    MP3::Tag->config(split /,/, $c);
  }
}

for my $elt ( qw( title track artist album comment year genre ) ) {
  no strict 'refs';
  MP3::Tag->config("translate_$elt", \&{"Music_Translate_Fields::translate_$elt"})
    if defined &{"Music_Translate_Fields::translate_$elt"};
}

my @parse_data;
if (defined $opt{P}) {
  my ($c) = ($opt{P} =~ /^\w*(\W)/s);
  $c = quotemeta $c if defined $c;
  $c = '(?!)' unless defined $c;		# Never match
  @parse_data = map [split /$c/], split /$c$c$c/, $opt{P};
  for $c (@parse_data) {
    die "Two few parts in parse directive `@$c'.\n" if @$c < 3;
  }
}

# E.g., to make Inf overwrite existing title, do 
# mp3info2.pl -C title,Inf,ID3v2,ID3v1,filename -u *.mp3

my $f;
my @f = @ARGV;
if ($opt{G}) {
  require File::Glob;			# "usual" glob() fails on spaces...
  @f = map File::Glob::bsd_glob($_), @f;
}
for $f (@f) {
    my $mp3=MP3::Tag->new($f);	# BUGXXXX Can't merge into if(): extra refcount
    if ($mp3) {
	print $mp3->interpolate(<<EOC) unless exists $opt{p};
File: %F
EOC
	my $data = $mp3->autoinfo('from');
	my $modify;
	my @args;
	for my $k (keys %trans) {
	  if (exists $opt{$k}) {
	    push @args, ['mz', $opt{$k}, "%$k"];
	    if (exists $data->{$trans{$k}}) {
		if ( $data->{$trans{$k}}->[0] ne $opt{$k}
		     or $data->{$trans{$k}}->[1] !~ /^id3/i ) {
		    warn "Need to change $trans{$k}\n";
		    $data->{$trans{$k}} = [$opt{$k}, 'cmd'];
		    $modify = 1;
		}
	    } else {
		warn "Need to add $trans{$k}\n";
		$data->{$trans{$k}} = [$opt{$k}, 'cmd'];
		$modify = 1;
	    }
	  }
	}
	if ($opt{u} and not $modify) {		# Update
	    for my $k (keys %$data) {
		next if $k eq 'song'; # Alias for title (otherwise double warn)
		next if $data->{$k}->[1] =~ /^(ID3|cmd)/;
		next unless defined $data->{$k}->[0];
		next unless length  $data->{$k}->[0];
		$modify = 1;
		warn "Need to propagate $k from $data->{$k}->[1]\n";
	    }
	}
	my $odata = $data;
	# Now, when we know what should be updated, retry with arguments
	if (@args or @parse_data) {
            $mp3 = MP3::Tag->new($f);
	    $mp3->config('parse_data', @parse_data, @args);
	    $data = $mp3->autoinfo('from');
	}

	print $mp3->interpolate(exists $opt{p} ? $opt{p} : <<EOC);
Title:   %-50t Track: %n
Artist:  %a
Album:   %-50l Year:  %y
Comment: %-50c Genre: %g
EOC

	# Recheck whether we need to update
	if (not $modify and $opt{u} and @parse_data) {
	    for my $k (keys %$data) {
		$modify = 1, last
		    if defined $data->{$k} and 
			(not defined $odata->{$k} or $data->{$k} ne $odata->{$k});
	    }
	}
	$opt{u} and warn "No update needed\n" unless $modify;
	next unless $modify and not $opt{D};	# Dry run

	$mp3->new_tag("ID3v1") unless exists $mp3->{ID3v1};
	my $elt;
	for $elt (qw/title artist album year comment track genre/) {
	    $mp3->{ID3v1}->$elt( $data->{$elt}->[0] )
		if defined $data->{$elt} and $data->{$elt}->[1] ne 'ID3v1';
	}				# Skip what is already there...
	$mp3->{ID3v1}->write_tag;

	next if $mp3->{ID3v1}->fits_tag($data) and not exists $mp3->{ID3v2};

	$mp3->new_tag("ID3v2") unless exists $mp3->{ID3v2};
	for $elt (qw/title artist album year comment track genre/) {
	    $mp3->{ID3v2}->$elt( $data->{$elt}->[0] )
		if defined $data->{$elt} and $data->{$elt}->[1] ne 'ID3v2';
	}				# Skip what is already there...
	# $mp3->{ID3v2}->comment($data->{comment}->[0]);
	$mp3->{ID3v2}->write_tag;
    } else {
	print "Not found...\n";
    }
}

=head1 NAME

mp3info2 - get/set MP3 tags; uses L<MP3::Tag> to get default values.

=head1 SYNOPSIS

  # Print the information in tags and autodeduced info
  mp3info2 *.mp3

  # In addition, set the year field to 1981
  mp3info2 -y 1981 *.mp3

  # Same without printout of information
  mp3info2 -p "" -y 1981 *.mp3

  # Do not deduce any field, print the info from the tags only
  mp3info2 -C autoinfo=ID3v2,ID3v1 *.mp3

  # Get the artist from CDDB_File, autodeduce other info, write it to tags
  mp3info2 -C artist=CDDB_File -u *.mp3

  # For the title, prefer information from .inf file; autodeduce and update
  mp3info2 -C title=Inf,ID3v2,ID3v1,filename -u *.mp3

  # Same, and get the author from CDDB file
  mp3info2 -C "#title=Inf,ID3v2,ID3v1,filename#artist=CDDB_File" -u *.mp3

  # Write a script for conversion of .wav to .mp3 autodeducing tags
  mp3info2 -p "lame -h --vbr-new --tt '%t' --tn %n --ta '%a' --tc '%c' --tl '%l' --ty '%y' '%f'\n" *.wav >xxx.sh

=head1 DESCRIPTION

The program prints a message summarizing tag info (obtained via
L<MP3::Tag|MP3::Tag> module) for specified files.

It may also update the information in MP3 tags.  This happens in two
different cases.

=over

=item *

If the information supplied in command-line options differs
from the content of the corresponding ID3 tags (or there is no
corresponding ID3 tags).

=item *

if C<MP3::Tag> obtains the info from other means than MP3 tags, and
C<-u> forces the update of the ID3 tags.

=back

(Both ways are disabled by C<-D> option.)  ID3v2 tag is written if
needed.

The option C<-C> sets C<MP3::Tag> configuration data (separated by
commas; the first comma can be replaced by C<=> sign) as MP3::Tag->config()
would do.  (To call config() multiple times, separate the parts by arbitrary
non-alphanumeric character, and repeat this character in the start of C<-C>
option.)  Note that since C<ParseData> is used to inject the user-specified
tag fields (such as C<-a "A. U. Thor">), usually it should be kept in the
C<autoinfo> configuration (and related fields C<author> etc).

The option C<-u> writes (C<u>pdates) the fetched information to the MP3 ID3
tags.  This option is assumed if tag elements are set via command-line
options.  (This option is overwritten by C<-D> option.)

The option C<-p> prints a message using the next argument as format
(by default C<\\>, C<\t>, C<\n> are replaced by backslash, tab and newline;
governed by the value of C<-E> option); see
L<MP3::Tag/"interpolate"> for details of the format of sprintf()-like escapes.

With option C<-D> (dry run) no update is performed.

Use options

  t a l y g c n

to overwrite the information (title artist album year genre comment
track-number) obtained via C<MP3::Tag> heuristics (C<-u> switch is implied
if any one of these arguments differs from what would be found otherwise; use
C<-D> switch to disable auto-update).

The option C<-P> should contain the parse recipes.  They become the
configuration item C<parse_data> of C<MP3::Tag>; eventually this information
is processed by L<MP3::Tag::ParseData|MP3::Tag::ParseData> module.  The option
is split into
C<[$flag, $string, @patterns]> on its
first non-alphanumeric character; if multiple options are needed, one should
separate
them by this character repeated 3 times.  This data is processed by
L<MP3::Tag::ParseData> (if present in the chain of heuristics).

If option C<-G> is specified, the file names on the command line are considered
as glob patterns.  This may be useful if the maximal command-line length is too
low).

The option C<-E> should contain the letters of the options where
C<\\, \n, \t> are interpolated (default: C<p>).  If the option C<-@> is given,
all characters C<@> in the options are replaced by C<%>; this may be convenient
if the shell treats C<%> specially.

=head1 Extra translation

If a module C<Music_Translate_Fields> is available, it is loaded.  It may
defined methods C<translate_artist> etc which would be used by L<MP3::Tag>.

=head1 EXAMPLES

Only the C<-P> option is complicated enough to deserve comments...

For a (silly) example, one can replace C<-a Homer -t Iliad> by

  -P mz=Homer=%a===mz=Iliad=%t

A less silly example is forcing a particular way of parsing a file name via

  -P "im=%{d0}/%f=%a/%n %t.%e"

This interpolates the string C<"%{d0}/%f"> and parses the result (which is
the file name with one level of the directory part preserved) using the
pattern C<"%a/%n %t.%e">; thus the directory name becomes author, the leading
numeric part - the track number, and the rest of the file name (without
extension) - the title.  Note that since multiple patterns are allowed,
one can similarly allow for multiple formats of the names, e.g.

  -P "im=%{d0}/%f=%a/%n %t.%e=%a/%t (%y).%e"

allows for the file basename to be also of the form "TITLE (YEAR)".  To give
more examples,

  -P "if=%D/.comment=%c"

will read comment from the file F<.comment> in the directory of the audio file;

  -P "ifn=%D/.comment=%c"

has similar effect if the file F<.comment> has one-line comments, one per
track (this assumes the the track number can be found by other means).

Suppose that a file F<Parts> in a directory of MP3 files has the following
format: it has a preamble, then has a short paragraph of information per
audio file, preceeded by the track number and dot:

   ...

   12. Rezitativ.
   (Pizarro, Rocco)

   13. Duett: jetzt, Alter, jetzt hat es Eile, (Pizarro, Rocco)

   ...

The following command puts this info into the title of the ID3 tag (provided
the audio file names are informative enough so that MP3::Tag can deduce the
track number):

 mp3info2 -u -C parse_split='\n(?=\d+\.)' -P 'fl;Parts;%=n. %t'

If this paragraph of information has the form C<TITLE (COMMENT)> with the
C<COMMENT> part being optional, then use

 mp3info2 -u -C parse_split='\n(?=\d+\.)' -P 'fl;Parts;%=n. %t (%c);%=n. %t'

If you want to remove a dot or a comma got into the end of the title, use

 mp3info2 -u -C parse_split='\n(?=\d+\.)' \
   -P 'fl;Parts;%=n. %t (%c);%=n. %t;;;iR;%t;%t[.,]$'

The second pattern of this invocation is converted to

  ['iR', '%t' => '%t[.,]$']

which essentially matches the title vs the substitution C<s/(.*)[.,]$/$1/s>.

Now suppose that in addition to F<Parts>, we have a text file F<Comment> with
additional info; we want to put this info into the comment field I<after>
what is extracted from C<TITLE (COMMENT)>; separate these two parts of
the comment by an empty line:

 mp3info2 -E C -C '#parse_split=\n(?=\d+\.)#parse_join=\n\n' \
  -P 'f;Comment;%c;;;fl;Parts;%=n. %t;;;i;%t///%c;%t (%c)///%c;;;iR;%t;%t[.,]$'

This assumes that the title and the comment do not contain C<'///'> as a
substring.  Explanation: the first pattern of C<-P> reads comment from the
file C<Comment> into the comment field; the second reads a chunk of C<Parts>
into the title field.  The third one

  ['i', '%t///%c' => '%t (%c)///%c']

rearranges the title and comment I<provided> the title is of the form C<TITLE
(COMMENT)>.  (The configuration option C<parse_join> takes care of separating
two chunks of comment corresponding to two occurences of C<%c> on the right
hand side.)

Finally, the fourth pattern is the same as in the preceeding example; it
removes spurious punctuation at the end of the title.

  mp3info2 -u -P 'i;%c///with piano;///%c' *.mp3
  mp3info2 -u -P 'iz;%c;with piano%c' *.mp3
  mp3info2 -C autoinfo=ParseData -a "A. U. Thor" *.mp3

Finish by a very simple example: all that the pattern

  -P 'i;%t;%t'

does is removal of trailing and leading blanks from the title (deduced by
other means).

=head1 AUTHOR

Ilya Zakharevich <cpan@ilyaz.org>.

=head1 SEE ALSO

MP3::Tag, MP3::Tag::ParseData

=cut
