#!/bin/sh

# i.e.  subatomicglue - mantis - 01 - hard.flac

DIRNAME="inertialdecay"
BINDIR="../../bin"

#PATH="$PATH";"$BINDIR"

echo "Create an m3u playlist"
$BINDIR/playlist-gen.pl -i "*.wav" -o ./playlist.m3u

echo "Generate a CDBurnerXP project file for burning a CD"
$BINDIR/cd-gen.pl -i "*.wav" -o cd.axp

#$BINDIR/makeshortmp3s.pl
#cp Folder.jpg mp3crunchy-rip

# usage: convert_audio_to_dir <outputdir> <type>
function convert_audio_to_dir
{
  dest=$1
  type=$2

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
}

# output directories _next_ to my directory
convert_audio_to_dir "../$DIRNAME-mp3" "mp3"
convert_audio_to_dir "../$DIRNAME-ogg" "ogg"
convert_audio_to_dir "../$DIRNAME-flac" "flac"

