#!/bin/sh

# our standard audiotrack naming convention:
#       <bandname> - <albumname> - <tracknum> - <trackname>.wav
# i.e.  subatomicglue - mantis - 01 - hard.wav
# (we pad the tracknum for alphebetical dir listing...)

OUTDIR="out"                # name of output directory

# this script's dir (and location of the other tools)
BINDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo "Create an m3u playlist"
$BINDIR/playlist-gen.pl -i "*.wav" -o ./playlist.m3u

echo "Generate a CDBurnerXP project file for burning a CD"
$BINDIR/cd-gen.pl -i "*.wav" -o cd.axp

# usage: convert_audio_to_dir <outputdir> <type>
function convert_audio_to_dir
{
  dest=$1
  type=$2
  echo "============================================="
  echo "Converting *.wav to $dest/ (type = $type)"
  echo "============================================="

  cmd="$BINDIR/rip.pl -i \"*.wav\" -o \"$dest\" -t $type"
  echo $cmd
  eval $cmd

  cmd="$BINDIR/tag.pl -i \"$dest/*.$type\" -c tags.ini"
  echo $cmd
  eval $cmd

  cmd="$BINDIR/playlist-gen.pl -i \"$dest/*.$type\" -o $dest/playlist.m3u"
  echo $cmd
  eval $cmd

  echo "copy *.jpg *.txt $dest\n"
  cp *.jpg *.txt $dest/
  echo ". . . . . . . .  .  .   .   .  .  . . . . . ."
}

convert_audio_to_dir "$OUTDIR-mp3" "mp3"
convert_audio_to_dir "$OUTDIR-ogg" "ogg"
convert_audio_to_dir "$OUTDIR-flac" "flac"

echo "============================================="
echo "Creating shortnames for $OUTDIR-mp3 (copying to $OUTDIR-mp3-shortnames)"
echo "============================================="
cmd="$BINDIR/rename_audiotrack_to_shortnames.pl -i \"$OUTDIR-mp3/*.mp3\" -o \"$OUTDIR-mp3-shortnames\""
echo $cmd
eval $cmd
cp ./Folder.jpg "$OUTDIR-mp3-shortnames/"
echo ". . . . . . . .  .  .   .   .  .  . . . . . ."

