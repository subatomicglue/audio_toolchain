package MP3::Tag::ParseData;

use strict;
use vars qw /$VERSION @ISA/;

$VERSION="0.01";
@ISA = 'MP3::Tag::__hasparent';

=pod

=head1 NAME

MP3::Tag::ParseData - Module for parsing arbitrary data associated with music files.

=head1 SYNOPSIS

   # parses the file name according to one of the patterns:
   $mp3->config('parse_data', ['i', '%f', '%t - %n - %a.%e', '%t - %y.%e']);
   $title = $mp3->title;

see L<MP3::Tag>

=head1 DESCRIPTION

MP3::Tag::ParseData is designed to be called from the MP3::Tag module.

Each option of configuration item C<parse_data> should be of the form
C<[$flag, $string, $pattern1, ...]>.  For each of the option, patterns of
the option are matched agains the $string of the option, until one of them
succeeds.  The information obtained from later options takes precedence over
the information obtained from earlier ones.

The meaning of the patterns is the same as for parse() or parse_rex() methods
of C<MP3::Tag>.  Since the default for C<parse_data> is empty, by default this
handler has no effect.

$flag is split into 1-character-long flags (unknown flags are ignored):

=over

=item C<i>

the string-to-parse is interpolated first;

=item C<f>

the string-to-parse is interpreted as the name of the file to read;

=item C<n>

the string-to-parse is interpreted as collection of lines, one per track;

=item C<l>

the string-to-parse is interpreted as collection of lines, and the first
matched is chosen;

=item C<I>

the resulting string is interpolated before parsing.

=item C<R>

the patterns are considered as regular expressions.

=item C<m>

one of the patterns must match.

=item C<z>

Do not ignore a field even if the result is a 0-length string.

=back

In any case, the resulting values have starting and trailing whitespace trimmed.
(Actually, breaking into line is done using the configuration item
C<parse_split>; it defaults to C<"\n">.)

If the configuration item C<parse_data> has multiple options, the $strings
which are interpolated will use information set by preceeding options;
similarly, any interolated option may use information obtained by other
handlers - even if these handers are later in the pecking order than
C<MP3::Tag::ParseData> (which by default is the first handler).  For
example, with

  ['i', '%t' => '%t (%y)'], ['i', '%t' => '%t - %c']

and a local CDDB file which identifies title to C<'Merry old - another
interpretation (1905)'>, the first field will interpolate C<'%t'> into this
title, then will split it into the year and the rest.  The second field will
split the rest into a title-proper and comment.

Note that one can use fields of the form

  ['mz', 'This is a forced title' => '%t']

to force particular values for parts of the MP3 tag.

The usual methods C<artist>, C<title>, C<album>, C<comment>, C<year>, C<track>,
C<year> can be used to access the results of the parse.

=cut


# Constructor

sub new_with_parent {
    my ($class, $filename, $parent) = @_;
    $filename = $filename->filename if ref $filename;
    bless {filename => $filename, parent => $parent}, $class;
}

# Destructor

sub DESTROY {}

sub parse_one {
    my ($self, $in) = @_;

    my @patterns = @$in;		# Apply shift to a copy, not original...
    my $flags = shift @patterns;
    my $data  = shift @patterns;

    $data = $self->{parent}->interpolate($data) if $flags =~ /i/;
    if ($flags =~ /f/) {
	local *F;
	open F, "< $data" or die "Can't open file `$data' for parsing: $!";
	local $/;
	my $d = <F>;
	close F or die "Can't close file `$data' for parsing: $!";
	$data = $d;
    }
    my @data = $data;
    if ($flags =~ /[ln]/) {
	my $p = $self->get_config('parse_split')->[0];
	@data = split $p, $data;
    }
    if ($flags =~ /n/) {
	my $track = $self->{parent}->track or return;
	@data = $data[$track - 1];
    }
    my $res;
    my @opatterns = @patterns;
    if ($flags =~ /R/) {
	@patterns = map $self->{parent}->parse_rex_prepare($_), @patterns;
    } else {
	@patterns = map $self->{parent}->parse_prepare($_), @patterns;
    }
    for $data (@data) {
	$data = $self->{parent}->interpolate($data) if $flags =~ /I/;
	$data =~ s/^\s+//;
	$data =~ s/\s+$//;
	my $pattern;
	for $pattern (@patterns) {
	    last if $res = $self->{parent}->parse_rex_match($pattern, $data);
	}
	last if $res;
    }
    {   local $" = "' `";
	die "Pattern(s) `@opatterns' did not succeed vs `@data'"
	    if $flags =~ /m/ and not $res;
    }
    my $k;
    for $k (keys %$res) {
	$res->{$k} =~ s/^\s+//;
	$res->{$k} =~ s/\s+$//;
	delete $res->{$k} unless length $res->{$k} or $flags =~ /z/;
    }
    return unless $res and keys %$res;
    return $res;
}

# XXX Two decisions: which entries can access results of which ones,
# and which entries overwrite which ones; the user can reverse one of them
# by sorting config('parse_data') in the opposite order; but not both.
# Only practice can show whether our choice is correct...   How to customize?
sub parse {
    my ($self,$what) = @_;

    return $self->{parsed}->{$what}	# Recalculate during recursive calls
	if not $self->{parsing} and exists $self->{parsed}->{$what};

    my $data = $self->get_config('parse_data');
    return unless $data and @$data;
    my $parsing = $self->{parsing};
    local $self->{parsing};

    my (%res, $d, $c);
    for $d (@$data) {
	$c++;
	$self->{parsing} = $c;
	# Protect against recursion: later $d can access results of earlier ones
	last if $parsing and $parsing <= $c;
	my $res = $self->parse_one($d);
	# warn "Failure: [@$d]\n" unless $res;
	# Set user-scratch space data immediately
	for my $k (keys %$res) {
	    $self->{parent}->set_user($1, delete $res->{$k}) if $k =~ /^U(\d+)$/
	}
	# later ones overwrite earlier
	%res = (%res, %$res) if $res;
    }
    return unless keys %res;
    $self->{parsed} = \%res;
    return $self->{parsed}->{$what};
}

for my $elt ( qw( title track artist album comment year genre ) ) {
  no strict 'refs';
  *$elt = sub (;$) {
    my $self = shift;
    $self->parse($elt, @_);
  }
}

1;
