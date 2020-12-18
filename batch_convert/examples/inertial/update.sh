#!/bin/sh

# i.e.  subatomicglue - mantis - 01 - hard.flac

DIRNAME="inertialdecay"
BINDIR="../../bin"

#PATH="$PATH";"$BINDIR"

$BINDIR/playlist-gen.pl -i "*.wav" -o ./playlist.m3u
exit -1
$BINDIR/cd-gen.pl -i "*.wav" -o cd.axp

#$BINDIR/makeshortmp3s.pl
#cp Folder.jpg mp3crunchy-rip

function doit
{
  dest=$1
  type=$2
  my $cmd;

  $cmd = "$BINDIR/rip.pl" -i "*.wav" -o "$dest" -t $type
  echo $cmd
  $($cmd)

  $cmd = "$BINDIR/tag.pl" -i "$dest/"*.$type -c tags.ini
  echo $cmd
  $($cmd)

  $cmd = "$BINDIR/playlist-gen.pl" -i "$dest/"*.$type -o $dest/playlist.m3u
  echo $cmd
  $($cmd)

  echo "copy *.jpg *.txt $dest\n";
  cp *.jpg *.txt $dest/
}

# output directories _next_ to my directory
doit "../$DIRNAME-mp3" "mp3"
doit "../$DIRNAME-ogg" "ogg"
doit "../$DIRNAME-flac" "flac"

