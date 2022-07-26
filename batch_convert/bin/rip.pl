#!/usr/bin/env perl

use File::Basename; # dirname, basename
use Cwd; # cwd, getcwd
use Cwd 'abs_path';
my $cwd = cwd();

# defaults
$TYPE = "mp3";
$IN_FILES = "*.wav";
$OUT_PATH = "out";
$BIN_PATH = dirname( abs_path($0) ); # script's directory

sub defaults()
{ return "in[$IN_FILES] out[$OUT_PATH] type[$TYPE] scriptdir[$BIN_PATH]"; }

# command line can override defaults
for (my $x = 0; $x < @ARGV; $x++)
{
   if ($ARGV[$x] eq "-o" || $ARGV[$x] eq "-out")
   {
      $x++;
      $OUT_PATH = $ARGV[$x];
      $OUT_PATH =~ s/[\\\/]$//;
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
      print " rip.pl -i \"1.wav 2.wav\" -o ogg-rip -t $TYPE\n";
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

print "creating dir $OUT_PATH\n";
mkpath( $OUT_PATH );

foreach (@files)
{
   my $wavname = $_;

   if ($TYPE eq "mp3")
   {
      # convert to MP3
      my $mp3name = $wavname;
      $mp3name =~ s/\.wav$/.mp3/;       # change file ext
      $mp3name =~ s/^.*\/([^\/]+)$/$1/; # filename only (remove path)
      $mp3name = "$OUT_PATH/$mp3name";
      if (!-f $mp3name || ((stat($mp3name))[9] < (stat($wavname))[9]))
      {
         unlink( $mp3name );
         my $command = "lame -b 192 -B 320 -c -h -m j -q 0 -t -V 3 -p --replaygain-accurate --vbr-new \"$wavname\" \"$mp3name\"";
         print $command . "\n";
         `$command`;
      }
   }

   if ($TYPE eq "m4a")
   {
      # convert to MP3
      my $newname = $wavname;
      $newname =~ s/\.wav$/.m4a/;       # change file ext
      $newname =~ s/^.*\/([^\/]+)$/$1/; # filename only (remove path)
      $newname = "$OUT_PATH/$newname";
      if (!-f $newname || ((stat($newname))[9] < (stat($wavname))[9]))
      {
         unlink( $newname );

         # use AppleMusic/iTunes encoder
         if (`which afconvert`) {
            my $cmd = "afconvert -v -f m4af -d aac -b 192000 -q 127 -s 2 \"$wavname\" \"$newname\"";
            print $cmd . "\n";
            `$cmd`;
         }

         # use faac
         # FAAC is the oldest free and open-source AAC encoder. It is available for practically all Linux distributions.
         # https://wiki.hydrogenaud.io/index.php/FAAC#Best_Settings
         elsif (`which faac`) {
            # Generally, the best results are achieved in CVBR mode with -b <bitrate> setting, e.g. -b 128 or -b 160.
            # The default VBR quality setting for faac, q=100, generates files at an average bitrate of approx. 128kbps. This quality level is good enough for casual, non-critical listening, but note that other encoders for AAC and other compressed formats may provide better quality files at similar bitrates.
            # For better quality encoding, I suggest q=150, resulting in average bitrates around 175kbps. Based on my own (subjective) tests, at this quality level faac provides high quality artifact free music reproduction and is comparable in quality to proprietary AAC encoders at similar bitrates.
            # Note that faac will by default wrap AAC data in an MP4 container for output files with the extensions .mp4 and .m4a.

            # --artist "%a" --album "%b" --title "%t" --genre "%g" --year "%y" --track "%tn"
            #my $cmd = "faac \"$wavname\" -o \"$newname\" -b 160 --overwrite"; # CBR mode with (ABR=160)
            my $cmd = "faac \"$wavname\" -o \"$newname\" -q 150 --overwrite"; # VBR mode with (ABR=175)
            print $cmd . "\n";
            `$cmd`;
         }

         # use ffmpeg encoder
         elsif (`which ffmpeg`) {
            my $cmd = "ffmpeg -i \"$wavname\" \"$newname\"";
            print $cmd . "\n";
            `$cmd`;
         }

         # WARNING:  Honda 2016 CRV Touring displays "UNPLAYABLE FILE" for fdkaac here:
         # use fraunhoffer's fdk-aac
         # The Fraunhofer FDK AAC is a high-quality open-source AAC encoder library developed by Fraunhofer IIS.
         # https://wiki.hydrogenaud.io/index.php?title=Fraunhofer_FDK_AAC
         elsif (`which fdkaac`) {
            my $cmd = "fdkaac --ignorelength --profile 2 --bitrate-mode 5 -o \"$newname\" \"$wavname\"";
            print $cmd . "\n";
            `$cmd`;
         }
      }
   }

   if ($TYPE eq "flac")
   {
      # convert to FLAC
      my $flacname = $wavname;
      $flacname =~ s/\.wav$/.flac/;
      $flacname =~ s/^.*\/([^\/]+)$/$1/; # filename only (remove path)
      $flacname = "$OUT_PATH/$flacname";
      if (!-f $flacname || ((stat($flacname))[9] < (stat($wavname))[9]))
      {
         unlink( $flacname );
         my $command = "flac --best --replay-gain -o \"$flacname\" -- \"$wavname\"";
         print $command . "\n";
         `$command`;
      }
   }

   if ($TYPE eq "ogg")
   {
      # convert to OGG
      my $oggname = $wavname;
      $oggname =~ s/\.wav$/.ogg/;
      $oggname =~ s/^.*\/([^\/]+)$/$1/; # filename only (remove path)
      $oggname = "$OUT_PATH/$oggname";
      if (!-f $oggname || ((stat($oggname))[9] < (stat($wavname))[9]))
      {
         unlink( $oggname );
         my $command = "oggenc -s 696969 -q 5 -o \"$oggname\" \"$wavname\"";
         print $command . "\n";
         `$command`;
      }
   }
}

