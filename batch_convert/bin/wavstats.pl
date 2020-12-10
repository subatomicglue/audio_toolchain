#!perl -w
use strict;
use Fcntl;

my $fnm = shift;
sysopen WAV,$fnm,O_RDONLY;
my $riff;
sysread WAV,$riff,12;
my $fmt;
sysread WAV,$fmt,24;
my $data;
sysread WAV,$data,8;
close WAV;

# RIFF header: 'RIFF', long length, type='WAVE'
my ($r1,$r2,$r3) = unpack "A4VA4", $riff;
# WAV header, 'fmt ', long length, short unused, short channels,
# long samples/second, long bytes per second, short bytes per sample,
# short bits per sample
my ($f1,$f2,$f3,$f4,$f5,$f6,$f7,$f8) = unpack "A4VvvVVvv",$fmt;
# DATA header, 'DATA', long length
my ($d1,$d2) = unpack "A4V", $data;

my $playlength = $f6 ne 0 ? $d2/$f6 : 0;

print << "EOF";
RIFF header: $r1, length $r2, type $r3

Format: $f1, length $f2, always $f3, channels $f4,
      sample rate $f5, bytes per second $f6,
      bytes per sample $f7, bits per sample $f8

Data: $d1, length $d2
Playlength: $playlength seconds
EOF

__END__

