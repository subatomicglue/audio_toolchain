#!perl

use File::Basename; # dirname, basename, $path_separator
use Cwd; # cwd, getcwd
use Cwd 'abs_path';
my $cwd = cwd();

# defaults
$IN_FILES = "*.wav";
$OUT_SF2 = "out.sf2";
$BIN_PATH = dirname( abs_path($0) );
$NAME = "default";

sub defaults()
{ return "in[$IN_FILES] out[$OUT_SF2] name[$INSTRUMENT] tools[$BIN_PATH]"; }

# command line can override defaults
for (my $x = 0; $x < @ARGV; $x++)
{
   if ($ARGV[$x] eq "-o" || $ARGV[$x] eq "-out")
   {
      $x++;
      $OUT_SF2 = $ARGV[$x];
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
   elsif ($ARGV[$x] eq "-name")
   {
      $x++;
      $NAME = $ARGV[$x];
   }
   else
   {
      print "usage:\n";
      print " wavs2sf2.pl -o $OUT_SF2                 # all wavs in cur dir\n";
      print " wavs2sf2.pl -i \"*.wav\" -o msvdrm.sf2 -name \"massive drums\"\n";
      print " wavs2sf2.pl -i \"1.wav 2.wav\" -o $OUT_SF2 -tools \"$BIN_PATH\"\n";
      print "   -tools is the path to \"sox\" & \"sf2comp\" utilities\n";
      print "\n";
      print "Defaults:\n";
      print " ".defaults()."\n";
      exit -1;
   }
}

print "wavs2sf2[".defaults()."\n";


use File::Path;
use File::Copy;

@files = glob( "*.wav" );
%note_to_number = (
   "c" => 0,
   "d" => 2,
   "e" => 4,
   "f" => 5,
   "g" => 7,
   "a" => 9,
   "b" => 11,
);

sub clamp( $$$ )
{
   my $val = shift;
   my $low = shift;
   my $hi = shift;
   return $val < $low ? $low : $hi < $val ? $hi : $val;
}

sub hashCode
{
   my $hash = 0;
   use integer;
   foreach(split //,shift)
   {
      $hash = 31 * $hash + ord($_);
   }
   return $hash;
}

my %unique_strings = {};
sub reduceTo20chars( $ )
{
   my $s = shift;
   $s =~ s/-.+$//;     # leave out tags from samp name
   $s =~ s/[-_\. ]//g; # remove whitespace, make more fit
   my ( $v1 );
   my $x = 0;
   do
   {
      ( $v1 ) = unpack( "a" . (20 - length( "$x" )), $s );
      $v1 .= "$x";
      #print "testing: $v1\n";
      $x++;
   } while (exists $unique_strings{$v1});
   $unique_strings{$v1} = 1;
   #print "returning: $v1\n";
   return $v1;
}


my $tempdir = "temp123459876";
rmtree( $tempdir );
mkpath( "temp123459876" );

# preset defaults
my $PresetName=$NAME;
my $Bank=0;
my $Program=1;
my $Instrument=$NAME;
my $L_LowKey=0;
my $L_HighKey=127;
my $L_LowVelocity=0;
my $L_HighVelocity=127;

# instrument
my $InstrumentName = $NAME;

sub filename2attrs( $$ )
{
   my $filename = shift;
   my $i = shift; #instrumentsamples hash
   $filename =~ s/^[^-]*-//;
   my @tokens = split( /[-]/, $filename );
   for (my $x = 0; $x < @tokens; $x++)
   {
      my ($type, $value) = ($tokens[$x] =~ /^(.)(.+)$/);
      if ($type eq 'v')
      {
         $value = clamp( $value, 0, 127 );
         if ($i->{Z_LowVelocity} eq -1)
         {
            $i->{Z_LowVelocity} = $value;
         }
         else
         {
            $i->{Z_HighVelocity} = $value;
         }
      }
      if ($type eq 'e')
      {
         $i->{Z_exclusiveClass} = clamp( $value, 0, 32767 );
      }
      if ($type =~ /[nr]/ && $value =~ /^([a-gA-G])([#b]?)([0-9]+)$/)
      {
         my $note = lc( $1 );
         my $sharpflat = $2;
         my $octave = clamp( $3, 0, 8 );
         $value = 12 # is C0
                  + $note_to_number{ $note }
                  + ($octave*12)
                  + ($sharpflat eq 'b' ? -1 : $sharpflat eq '#' ? 1 : 0);
      }
      if ($type =~ /[nr]/ && "$value" =~ /^([0-9]+)$/)
      {
         if ($type eq 'r')
         {
            $i->{Z_overridingRootKey} = $value;
         }
         elsif ($type eq 'n')
         {
            if ($i->{Z_LowKey} eq -1)
            {
               $i->{Z_LowKey} = $value;
            }
            else
            {
               $i->{Z_HighKey} = $value;
            }
         }
      }
   }
   $i->{Z_LowKey} = $i->{Z_LowKey} eq -1 ? ($i->{Z_overridingRootKey} eq -1 ? 60 : $i->{Z_overridingRootKey}) : $i->{Z_LowKey};
   $i->{Z_HighKey} = $i->{Z_HighKey} eq -1 ? $i->{Z_LowKey} : $i->{Z_HighKey};
   $i->{Z_overridingRootKey} = $i->{Z_overridingRootKey} eq -1 ? ($i->{Z_LowKey} eq -1 ? 60 : $i->{Z_LowKey}) : $i->{Z_overridingRootKey};

   $i->{Z_LowVelocity} = $i->{Z_LowVelocity} eq -1 ? ($i->{Z_HighVelocity} eq -1 ? 0 : $i->{Z_HighVelocity}) : $i->{Z_LowVelocity};
   $i->{Z_HighVelocity} = $i->{Z_HighVelocity} eq -1 ? ($i->{Z_LowVelocity} eq -1 ? 127 : $i->{Z_LowVelocity}) : $i->{Z_HighVelocity};
}

# build a quick lookup of how many wav files assigned to each note
my %note_hash = {};
foreach (@files)
{
   my $file = $_;
   $file =~ /([^\\\/]+)\.[^\.]+$/;
   my $filename = $1;
   my %instsample = {};
   $instsample{Z_LowKey}=-1;
   $instsample{Z_HighKey}=-1;
   $instsample{Z_overridingRootKey}=-1;
   $instsample{Z_LowVelocity}=-1;
   $instsample{Z_HighVelocity}=-1;
   $instsample{Z_exclusiveClass}=-1;
   filename2attrs( $filename, \%instsample );
   $note_hash{$instsample{Z_overridingRootKey} }++;
}

# each file is a SF2 "sample", parse the filename for parameters
# all samples given in @files make up an "Instrument"
foreach (@files)
{
   my $file = $_;
   $file =~ /([^\\\/]+)\.([^\.]+)$/;
   my $filename = $1;
   my $filename_short = reduceTo20chars( $1 );
   my $fileext = $2;
   my @tokens = split( /[-]/, $filename );

   # read the sample rate from the file.
   my $samprate = `"$BIN_PATH/sox" --i -r "$file"`;
   my $channels = `"$BIN_PATH/sox" --i -c "$file"`;
   my $bitdepth = `"$BIN_PATH/sox" --i -b "$file"`;
   chomp( $samprate );
   chomp( $channels );
   chomp( $bitdepth );
   print "[$filename_short] [$samprate/$channels/$bitdepth]\n";

   # sample defaults
   my $SampleName = $filename_short;
   my $SampleRate = $samprate;
   my $Key = 60;
   my $FineTune = 0;
   my $Type = 1;

   # InstSample defaults
   my $Sample=$filename_short;
   my %instsample = {};
   $instsample{Z_LowKey}=-1;
   $instsample{Z_HighKey}=-1;
   $instsample{Z_overridingRootKey}=-1;
   $instsample{Z_LowVelocity}=-1;
   $instsample{Z_HighVelocity}=-1;
   $instsample{Z_exclusiveClass}=-1;
   filename2attrs( $filename, \%instsample );

   # build temp directory of files that will build the .sf2, resample if needed.
   if ($samprate ne 44100 || $channels ne 1 || $bitdepth ne 16)
   {
      print " - detected $bitdepth/$channels/$samprate resampling to 16/1/44100\n";
      `"$BIN_PATH/sox" "$file" -b 16 -c 1 -r 44100 "$tempdir/$filename_short.$fileext"`;
   }
   else
   {
      copy( $file, "$tempdir/$filename_short.$fileext" );
   }

   # store configuration text for the sample,
   # this defines the .sf2 using sf2comp's data file format.
   $samples_text .= "    SampleName=$SampleName
            SampleRate=$SampleRate
            Key=$Key
            FineTune=$FineTune
            Type=$Type\n\n";
   $instsamples_text .= "        Sample=$Sample
            Z_LowKey=$instsample{Z_LowKey}
            Z_HighKey=$instsample{Z_HighKey}
            Z_overridingRootKey=$instsample{Z_overridingRootKey}
            Z_LowVelocity=$instsample{Z_LowVelocity}
            Z_HighVelocity=$instsample{Z_HighVelocity}
            Z_pan=0
            Z_attackVolEnv=32768
            Z_decayVolEnv=32768
            Z_sustainVolEnv=32768
            Z_releaseVolEnv=1901
            Z_sampleModes=0
            Z_scaleTuning=100
            ".

            ($instsample{Z_exclusiveClass} ne -1 ?
               "Z_exclusiveClass=$instsample{Z_exclusiveClass}
            " : "") .

            (($note_hash{$instsample{Z_overridingRootKey} } gt 1) ?
               "Z_Modulator=(NoteOnVelocity,NormalDirection,Unipolar,Linear), initialAttenuation, 0, (NoController,NormalDirection,Unipolar,Linear), 0\n\n"
            :
               "Z_Modulator=(NoteOnVelocity,ReverseDirection,Unipolar,Linear), initialFilterFc, 0, (NoteOnVelocity,ReverseDirection,Unipolar,Switch), 0\n\n");
}


open( FILE, ">$tempdir/output.txt" );
print FILE "[Samples]

$samples_text


[Instruments]

    InstrumentName=$InstrumentName

$instsamples_text

        GlobalZone
            GZ_initialAttenuation=127


[Presets]

    PresetName=$PresetName
        Bank=$Bank
        Program=$Program

        Instrument=$Instrument
            L_LowKey=$L_LowKey
            L_HighKey=$L_HighKey
            L_LowVelocity=$L_LowVelocity
            L_HighVelocity=$L_HighVelocity

        GlobalLayer
            GZ_startAddrsOffset=
            GZ_endAddrsOffset=
            GZ_startloopAddrsOffset=
            GZ_endloopAddrsOffset=
            GZ_startAddrsCoarseOffset=
            GZ_modLfoToPitch=
            GZ_vibLfoToPitch=
            GZ_modEnvToPitch=
            GZ_initialFilterFc=
            GZ_initialFilterQ=
            GZ_modLfoToFilterFc=
            GZ_modEnvToFilterFc=
            GZ_endAddrsCoarseOffset=
            GZ_modLfoToVolume=
            GZ_unused1=
            GZ_chorusEffectsSend=
            GZ_reverbEffectsSend=
            GZ_pan=
            GZ_unused2=
            GZ_unused3=
            GZ_unused4=
            GZ_delayModLFO=
            GZ_freqModLFO=
            GZ_delayVibLFO=
            GZ_freqVibLFO=
            GZ_delayModEnv=
            GZ_attackModEnv=
            GZ_holdModEnv=
            GZ_decayModEnv=
            GZ_sustainModEnv=
            GZ_releaseModEnv=
            GZ_keynumToModEnvHold=
            GZ_keynumToModEnvDecay=
            GZ_delayVolEnv=
            GZ_attackVolEnv=
            GZ_holdVolEnv=
            GZ_decayVolEnv=
            GZ_sustainVolEnv=
            GZ_releaseVolEnv=
            GZ_keynumToVolEnvHold=
            GZ_keynumToVolEnvDecay=
            GZ_reserved1=
            GZ_startloopAddrsCoarseOffset=
            GZ_keynum=
            GZ_velocity=
            GZ_initialAttenuation=
            GZ_reserved2=
            GZ_endloopAddrsCoarseOffset=
            GZ_coarseTune=
            GZ_fineTune=
            GZ_sampleModes=
            GZ_reserved3=
            GZ_scaleTuning=
            GZ_exclusiveClass=
            GZ_overridingRootKey=
            GZ_unused5=

[Info]
Version=2.1
Engine=EMU8000
Name=$Instrument
ROMName=
ROMVersion=0.0
Date=
Designer=
Product=
Copyright=
Editor=
Comments=";

close( FILE );

# "touch" the output sf2 file so we can get can abs path for it
open( FILE, ">$OUT_SF2" );
close( FILE );
#get absolute path
$OUT_SF2 = abs_path( $OUT_SF2 );

# change to temp dir, compile it to sf2, change back
$cwd = cwd();
chdir( $tempdir );
`"$BIN_PATH/sf2comp" c -i output.txt "$OUT_SF2"`;
chdir( $cwd );

# done, clean up temp files.
rmtree( $tempdir );

