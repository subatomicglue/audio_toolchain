#!/usr/bin/env perl

use strict;
use warnings;


use File::Basename; # dirname, basename
use Cwd; # cwd, getcwd
use Cwd 'abs_path';

my $scriptpath = $0;
my $scriptname = basename( $0 );
my $scriptdir = dirname( abs_path( $scriptpath ) );
my $cwd = cwd();

# defaults
my $TYPE = "mp3";
my $IN_FILES = "*.wav";
my $OUT_PATH = "out";
my $BIN_PATH = dirname( abs_path($0) ); # script's directory
my $IMAGE = "";

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
   elsif ($ARGV[$x] eq "-image")
   {
      $x++;
      $IMAGE = $ARGV[$x];
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
      print " rip.pl -i \"1.wav 2.wav\" -o mp4-rip -t mp4 -image 'cover.png'\n";
      print "\n";
      print "Defaults:\n";
      print " ".defaults()."\n";
      exit -1;
   }
}

print "rip[".defaults()."\n";

# the files to convert
my @files = glob( $IN_FILES );


##############################################################
use File::Path;

print "creating dir $OUT_PATH\n";
mkpath( $OUT_PATH );

$SIG{INT}  = \&signal_handler;
$SIG{TERM} = \&signal_handler;
$SIG{QUIT} = \&signal_handler;
sub signal_handler {
  print "SIG death... (!)\n";
  clean_up();
  print "-=====================================================================-\n";
  die "\n";
}

my $TEMP_IMAGE="/tmp/489r0sjnm348590sdfhjl.png";

sub clean_up {
  if ( -f "$TEMP_IMAGE" ) {
    #print "[INFO] Removing temporary '$TEMP_IMAGE'\n";
    `rm "$TEMP_IMAGE"`;
  }
}

my $VIDEO_WIDTH=1920;
my $VIDEO_HEIGHT=1080;
# get the image into the format(s) needed (png)
if ( ! -f "$IMAGE" )
{
  `convert -size ${VIDEO_WIDTH}x${VIDEO_HEIGHT} xc:black "$TEMP_IMAGE"`;
}
elsif ( ! $IMAGE =~ /\.(png)$/i )
{
  `convert "$IMAGE" "$TEMP_IMAGE"`;
}
else
{
  `cp "$IMAGE" "$TEMP_IMAGE"`;
}
my $TEMP_IMAGE_WIDTH=`identify -format "%w" $TEMP_IMAGE`;
my $TEMP_IMAGE_HEIGHT=`identify -format "%h" $TEMP_IMAGE`;

# create an image the same dims as the video
`$scriptdir/create_echo_pillarbox_image.sh $TEMP_IMAGE $TEMP_IMAGE $VIDEO_WIDTH $VIDEO_HEIGHT`;
$TEMP_IMAGE_WIDTH=`identify -format "%w" $TEMP_IMAGE`;
$TEMP_IMAGE_HEIGHT=`identify -format "%h" $TEMP_IMAGE`;


# returns an array ( WIDTH, HEIGHT ) for the size the image should take in the video viewport.
sub mapImageToVideo {
  my $VIDEO_WIDTH=shift;
  my $VIDEO_HEIGHT=shift;
  my $IMAGE_WIDTH=shift;
  my $IMAGE_HEIGHT=shift;
  my $VIDEO_ASPECT=$VIDEO_HEIGHT / $VIDEO_WIDTH;
  my $IMAGE_ASPECT=$IMAGE_HEIGHT / $IMAGE_WIDTH;

  if ($VIDEO_ASPECT < $IMAGE_ASPECT)
  {
    return ( $IMAGE_WIDTH * ($VIDEO_HEIGHT / $IMAGE_HEIGHT), $VIDEO_HEIGHT );
  }
  else
  {
    return ( $VIDEO_WIDTH, $IMAGE_HEIGHT * ($VIDEO_WIDTH / $IMAGE_WIDTH) );
  }
}




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
            # Using afconvert: https://developer.apple.com/library/archive/technotes/tn2271/_index.html
            # -s <control mode>    | <control mode> = Bit rate control mode: 0 = CBR 1 = ABR 2 = VBR_constrained 3 = VBR
            # -b <bit rate>        | <bit rate> = Total bit rate in bit/s                                                | Not applicable in VBR mode
            # -u 'vbrq' <quality>  | <quality> = VBR quality in the range 0…127                                          | VBR mode only
            my $cmd = "afconvert -v -f m4af -d aac -b 192000 -q 127 -s 2 \"$wavname\" \"$newname\"";
            print $cmd . "\n";
            `$cmd`;
         }

         # use ffmpeg encoder w/ Apple's AudioToolbox (for afconvert results)
         elsif (`which ffmpeg` && `ffmpeg -h encoder=aac_at 2>&1 | grep Encoder`) {
            # AudioToolbox (apple's afconvert encoder for ffmpeg)
            # ffmpeg -h encoder=aac_at # for help
            my $cmd = "ffmpeg -hide_banner -loglevel error -stats -i \"$wavname\" -c:a aac_at -b:a 320k -aac_at_mode vbr -aac_at_quality 0 \"$newname\"";
            print $cmd . "\n";
            `$cmd`;
         }

         # use ffmpeg encoder w/ fraunhofer's encoder
         elsif (`which ffmpeg` && `ffmpeg -h encoder=libfdk_aac 2>&1 | grep Encoder`) {
            # AudioToolbox (apple's afconvert encoder for ffmpeg)
            # ffmpeg -h encoder=libfdk_aac # for help
            my $cmd = "ffmpeg -hide_banner -loglevel error -stats -i \"$wavname\" -c:a libfdk_aac -b:a 320k \"$newname\"";
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

         # use ffmpeg encoder w/ default AAC
         elsif (`which ffmpeg` && `ffmpeg -h encoder=aac 2>&1 | grep Encoder`) {
            # ffmpeg's default aac encoder
            # ffmpeg -h encoder=aac # for help
            my $cmd = "ffmpeg -hide_banner -loglevel error -stats -i \"$wavname\" -c:a aac -b:a 320k \"$newname\"";
            print $cmd . "\n";
            `$cmd`;
         }

         # Use fraunhoffer's fdk-aac
         # The Fraunhofer FDK AAC is a high-quality open-source AAC encoder library developed by Fraunhofer IIS.
         # https://wiki.hydrogenaud.io/index.php?title=Fraunhofer_FDK_AAC
         # WARNING:  Honda 2016 CRV Touring displays "UNPLAYABLE FILE" for fdkaac here:
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

   if ($TYPE eq "mp4")
   {
      # convert to MP4
      my $mp4name = $wavname;
      $mp4name =~ s/\.wav$/.mp4/;
      $mp4name =~ s/^.*\/([^\/]+)$/$1/; # filename only (remove path)
      $mp4name = "$OUT_PATH/$mp4name";

      # if not found or wav is newer
      if (!-f $mp4name || ((stat($mp4name))[9] < (stat($wavname))[9]))
      {
        unlink( $mp4name );

        my $command = "";
        if ("$TEMP_IMAGE" ne "" && -f "$TEMP_IMAGE")
        {
          my @IMAGE_SIZE_WITHIN_VIEWPORT = mapImageToVideo( $VIDEO_WIDTH, $VIDEO_HEIGHT, $TEMP_IMAGE_WIDTH, $TEMP_IMAGE_HEIGHT );
          my $SCALE=$IMAGE_SIZE_WITHIN_VIEWPORT[0];
          my $FMT="-c:v libx264 -pix_fmt yuv420p";  # -vf scale=1920:1080
          my $FPS="-r 1";
          my $IMAGE1="-f lavfi -i color=c=black:s=${VIDEO_WIDTH}x${VIDEO_HEIGHT}:r=5";
          my $IMAGE2="-f image2 -s ${VIDEO_WIDTH}x${VIDEO_HEIGHT} -i \"$TEMP_IMAGE\"";
          # change scale if you want the image smaller, 1920 = full width.   1200 = partial width
          # todo: read incoming image size, set scale (width) dynamically
          my $IMAGE_COMBINE_FILTER="-filter_complex \"[1:v]scale=$SCALE:-1 [ovrl], [0:v][ovrl]overlay=(main_w-overlay_w)/2:(main_h-overlay_h)/2\"";
          my $IMAGE_CMB="$IMAGE1 $IMAGE2 $IMAGE_COMBINE_FILTER";
          #my $IMAGE="-f lavfi -i color=c=black:s=1920x1080:r=5"
          my $LENGTH="-shortest -max_interleave_delta 200M -fflags +shortest";
          my $AUDIO="-c:a aac -b:a 128k"; # convert wav PCM to AAC format
          $command="ffmpeg -hide_banner -loglevel warning -stats $FPS $IMAGE_CMB -i \"$wavname\" $AUDIO $LENGTH $FMT \"$mp4name\"";   # brew install ffmpeg
        }
        else
        {
          print "[error] must supply a cover image for mp4 conversion, see -help\n";
          exit(-1);
        }

        print $command . "\n";
        #exit(-1);
        `$command`;
      }
   }
}


END {
  clean_up();
}

