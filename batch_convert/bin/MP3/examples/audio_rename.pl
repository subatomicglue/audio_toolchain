extproc perl -Sw
#!/usr/bin/perl -w

$VERSION = 0.01;

# Will rename .inf file too.

use MP3::Tag;
use Getopt::Std 'getopts';
use File::Spec;
use File::Path;
use strict;

my %opt = (E => '');
# WinCyrillic (win1251), short (CDFS), Keep non-filename chars, Dry run, Glob, 
# path via pattern, |-separated list of associated extensions
# (PEC@ as in mp3info2)
getopts('csKDGp:e:P:E:C:@', \%opt);

# Interprete Escape sequences:
my %r = ( 'n' => "\n", 't' => "\t", '\\' => "\\"  );
for my $e (split //, $opt{E}) {
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

sub convert_to_filename ($) {
  my $outfile = shift;
  $outfile =~ tr( ¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ\x80-\x9F)
		( !cLXY|S"Ca<__R~o+23'mP.,1o>...?AAAAAAACEEEEIIIIDNOOOOOx0UUUUYpbaaaaaaaceeeeiiiidnooooo:ouuuuyPy_);
  $outfile =~ s/\s+/ /g;
  $outfile =~ s/\s*-\s*/-/g;
  #$outfile =~ s/([?.:!,;\/õ"\\\' ])/$filename_subs{$1}/g;
  $outfile =~ s/[?|.:!,;\/õ"\\\' <>|]/_/g;
  #$outfile =~ s/_+/_/g;
  $outfile;
}

my $translator;

sub win1251_to_volapuk ($) {
  unless ($translator) {
    require FindBin;
    push @INC, $FindBin::Bin;
    require transliterate_win1251;
    $translator = transliterate_win1251::make_translator(
	 (transliterate_win1251::prepare_translation(
		transliterate_win1251::cyr_table(),
		transliterate_win1251::lat_table()))[0] );
  }
  local $_ = shift;
  my $in = $_;
  # Detect broken stuff where cyrillic aR is written as latin p
  my $c = (tr/a-zA-Z//);
  my $c1 = (tr/p//);

  $translator->();

  my $c2 = (tr/abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ//);
  # Assume p=aR if there is a lot of cyrillic stuff
  # and either p is the only Latin, or p is always surrounded by cyrillic stuff
  # at least on one side: /((?<=[^\s -~])|(?=.[^\s -~]))p/: funny stuff on one side
  tr/p/r/ if $c1 and $c2 > 2*$c1
	     and ($c == $c1 or (not /((?<=[^\s -~])|(?=.[^\s -~]))p/
			        and not $in =~ /(?!((?<=[^\s -~])|(?=.[^\s -~])))p/));
  $_
}

warn "Target spec: $opt{p}%E\n" if $opt{p};
my @comp = split m|/|, ($opt{p} || "%02n_%t");
my @ext = split m/\|/, ($opt{e} || ".inf");
my ($extl_add, $e) = 0;
for $e (@ext) {
    $extl_add = length $e if $extl_add < length $e;
}
my $f;
my @f = @ARGV;
if ($opt{G}) {
  require File::Glob;			# "usual" glob() fails on spaces...
  @f = map File::Glob::bsd_glob($_), @f;
}
FILELOOP:
for $f (@f) {
    print "File: $f\n";
    my $mp3=MP3::Tag->new($f);
    if ($mp3) {
	$mp3->config('parse_data', @parse_data) if @parse_data;
	my $ext = $mp3->filename_extension();
	my $base = $mp3->interpolate("%A");
	my $extl = length $ext;
	for $e (@ext) {
	    $extl = length $e if $extl < length $e and -f "$base$e";
	}
	my $i = -1;
	my ($name, $dirname);
	while (++$i < @comp) {
	    my $comp = $comp[$i];
	    my $ocomp = $comp;
	    $comp = $mp3->interpolate($comp);
	    warn("Component `$ocomp' interpolates to empty, skipping the file\n"), next FILELOOP
		unless defined $comp and length $comp;
	    unless ($ocomp =~ /%[fFDABN]/) {	# Already valid
		$comp = win1251_to_volapuk($comp) if $opt{c};
		$comp = convert_to_filename $comp unless $opt{K};
	    }
	    my $last = $i == $#comp;
            $comp = substr $comp, 0, 64 - ($last ? $extl : 0) if $opt{s};
	    if ($last) {
		my $post1 = '';
		my $post2 = '';
		while (1) {
		    my $n = ((defined $name)
			     ? File::Spec->catfile($name, "$comp$post1$post2$ext")
			     : "$comp$post1$post2$ext");
		    last unless -e $n;
		    if ($post1) {
			$post2++;
		    } else {
			$post1 = '-';
			$post2 = 'a';
		    }
		    $comp = substr $comp, 0, 64 - length "$post1$post2$ext"
			if $opt{s};
		}
	    }
	    $dirname = $name;
	    if (not defined $name) {
		$name = $comp;
	    } elsif ($last) {
		$name = File::Spec->catfile($name, $comp);
	    } else {
		$name = File::Spec->catdir($name, $comp);
	    }
	}
	print("... No change\n"), next if $f eq "$name$ext";
	print "  ==> `$name$ext'\n";
	next if $opt{D};
	mkpath $dirname if defined $dirname and not -d $dirname;
	undef $mp3;			# Close the file
	rename $f, "$name$ext" or die "rename: $!";
	for $e (@ext) {
	    next unless -f "$base$e";
	    rename "$base$e", "$name$e" or die "rename $base$e => $name$e: $!";
	}
    } else {
	print "Not found...\n";
    }
}

=head1 NAME

audio_rename - rename an audio file via information got via L<MP3::Tag>.

=head1 SYNOPSIS



=head1 DESCRIPTION



=cut

