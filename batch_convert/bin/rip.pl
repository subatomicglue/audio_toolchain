#!/usr/bin/env perl

use File::Basename; # dirname, basename
use Cwd; # cwd, getcwd
use Cwd 'abs_path';
my $cwd = cwd();

# defaults
$TYPE = "mp3";
$IN_FILES = "*.wav";
$OUT_PATH = "out";
$BIN_PATH = dirname( abs_path($0) );

sub defaults()
{ return "in[$IN_FILES] out[$OUT_PATH] type[$TYPE] tools[$BIN_PATH]"; }

# command line can override defaults
for (my $x = 0; $x < @ARGV; $x++)
{
   if ($ARGV[$x] eq "-o" || $ARGV[$x] eq "-out")
   {
      $x++;
      $OUT_PATH = $ARGV[$x];
      $OUT_PATH =~ s/[\\\/]$//;
   }
   elsif ($ARGV[$x] eq "-tools")
   {
      $x++;
      $BIN_PATH = $ARGV[$x];
   }
   elsif ($ARGV[$x] eq "-i" || $ARGV[$x] eq "-in")
   {
      $x++;
      $IN_FILES = $ARGV[$x];
   }
   elsif ($ARGV[$x] eq "-t" || $ARGV[$x] eq "-type")
   {
      $x++;
      $TYPE = $ARGV[$x];
   }
   else
   {
      print "usage:\n";
      print " rip.pl -o $OUT_PATH -t $TYPE                 #all wav files in current dir\n";
      print " rip.pl -i \"*.wav\" -o mp3-rip -t $TYPE\n";
      print " rip.pl -i \"1.wav 2.wav\" -o ogg-rip -t $TYPE -tools $BIN_PATH\n";
      print '   -tools is the path to "lame" "flac" and "oggenc2-aoTuV" utilities'."\n";
      print "\n";
      print "Defaults:\n";
      print " ".defaults()."\n";
      exit -1;
   }
}

print "rip[".defaults()."\n";

# the files to convert
@files = glob( $IN_FILES );


##############################################################
use File::Path;

mkpath( $OUT_PATH );

foreach (@files)
{
   my $wavname = $_;

   if ($TYPE eq "mp3")
   {
      # convert to MP3
      my $mp3name = $wavname;
      $mp3name =~ s/\.wav$/.mp3/;
      $mp3name = "$OUT_PATH/$mp3name";
      if (!-f $mp3name || ((stat($mp3name))[9] < (stat($wavname))[9]))
      {
         unlink( $mp3name );
         my $command = "\"$BIN_PATH/lame\" -b 192 -B 320 -c -h -m j -q 0 -t -V 3 -p --replaygain-accurate --vbr-new \"$wavname\" \"$mp3name\"";
         print $command . "\n";
         `$command`;
      }
   }

   if ($TYPE eq "flac")
   {
      # convert to FLAC
      my $flacname = $wavname;
      $flacname =~ s/\.wav$/.flac/;
      $flacname = "$OUT_PATH/$flacname";
      if (!-f $flacname || ((stat($flacname))[9] < (stat($wavname))[9]))
      {
         unlink( $flacname );
         my $command = "\"$BIN_PATH/flac\" --best --replay-gain -o \"$flacname\" -- \"$wavname\"";
         print $command . "\n";
         `$command`;
      }
   }

   if ($TYPE eq "ogg")
   {
      # convert to OGG
      my $oggname = $wavname;
      $oggname =~ s/\.wav$/.ogg/;
      $oggname = "$OUT_PATH/$oggname";
      if (!-f $oggname || ((stat($oggname))[9] < (stat($wavname))[9]))
      {
         unlink( $oggname );
         my $command = "\"$BIN_PATH/oggenc2-aoTuV\" -s 696969 -q 5 -o \"$oggname\" \"$wavname\"";
         print $command . "\n";
         `$command`;
      }
   }
}

