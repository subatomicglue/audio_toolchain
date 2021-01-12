#!/bin/sh

# Typical files expected within the input folder:
#       Folder.jpg
#       <bandname> - <albumname> - <tracknum> - <trackname>.wav
#       <bandname> - <albumname> - <kind>.jpg  # kind can be: booklet1..N, trayinside, trayoutside
#       <bandname> - <albumname> - README.txt
#
# Our standard audiotrack naming convention:
#       <bandname> - <albumname> - <tracknum> - <trackname>.wav
# e.g.  subatomicglue - mantis - 01 - hard.wav
# <tracknum> is padded for alphebetical dir listing...

INDIR="."                   # name of input directory (with audiotracks, readme, images)
OUTDIR="out"                # name of output directory prefix
# this script's dir (and location of the other tools)
BINDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
args=()
VERBOSE=true

################################
# scan command line args:
function usage
{
  echo "$0 convert an album folder to mp3/flac/ogg for distribution"
  echo "Usage:"
  echo "  $0 <indir> <outdir> (input/output directory, default is \"$INDIR\", and \"$OUTDIR\")"
  echo "  $0 --help        (this help)"
  echo "  $0 --verbose     (output verbose information)"
  echo ""
}
ARGC=$#
ARGV=("$@")
non_flag_args=0
non_flag_args_required=1
for ((i = 0; i < ARGC; i++)); do
  if [[ $ARGC -ge 1 && ${ARGV[$i]} == "--help" ]]; then
    usage
    exit -1
  fi
  if [[ $ARGC -ge 1 && ${ARGV[$i]} == "--verbose" ]]; then
    VERBOSE=true
    continue
  fi
  if [[ $ARGC -ge 1 && ${ARGV[$i]:0:2} == "--" ]]; then
    echo "Unknown option ${ARGV[$i]}"
    exit -1
  fi

  args+=("${ARGV[$i]}")
  $VERBOSE && echo "Parsing Args: \"${ARGV[$i]}\""
  ((non_flag_args+=1))

  # non switch args:
  if [ $non_flag_args -eq 1 ]; then
    INDIR=${ARGV[$i]}
    $VERBOSE && echo "Parsing Args: Changing input directory to '$INDIR'"
  fi
  if [ $non_flag_args -eq 2 ]; then
    OUTDIR=${ARGV[$i]}
    $VERBOSE && echo "Parsing Args: Changing out dir prefix to '$OUTDIR'"
  fi
done

# output help if they're getting it wrong...
if [ $non_flag_args_required -ne 0 ] && [[ $ARGC -eq 0 || ! $ARGC -ge $non_flag_args_required ]]; then
  [ $ARGC -gt 0 ] && echo "Expected $non_flag_args_required args, but only got $ARGC"
  usage
  exit -1
fi
################################

echo "Create an m3u playlist"
"$BINDIR/playlist-gen.pl" -i "$INDIR/*.wav" -o "$INDIR/playlist.m3u"

echo "Generate a CDBurnerXP project file for burning a CD"
"$BINDIR/cd-gen.pl" -i "$INDIR/*.wav" -o "$INDIR/cd.axp"

# usage: convert_audio_to_dir <outputdir> <type>
function convert_audio_to_dir
{
  dest=$1
  type=$2
  echo "============================================="
  echo "Converting *.wav to $dest/ (type = $type)"
  echo "============================================="

  cmd="$BINDIR/rip.pl -i \"$INDIR/*.wav\" -o \"$dest\" -t $type"
  echo $cmd
  eval $cmd

  cmd="$BINDIR/tag.pl -i \"$dest/*.$type\" -c \"$INDIR/tags.ini\" -a \"$INDIR/Folder.jpg\""
  echo $cmd
  eval $cmd

  cmd="$BINDIR/playlist-gen.pl -i \"$dest/*.$type\" -o $dest/playlist.m3u"
  echo $cmd
  eval $cmd

  echo "copy $INDIR/*.jpg $INDIR/*-*-*README.txt $dest\n"
  cp "$INDIR/"*.jpg "$INDIR/"*-*-*README.txt $dest/ || echo "file not found"
  echo ". . . . . . . .  .  .   .   .  .  . . . . . ."
}

convert_audio_to_dir "$OUTDIR-m4a" "m4a"
convert_audio_to_dir "$OUTDIR-mp3" "mp3"
convert_audio_to_dir "$OUTDIR-ogg" "ogg"
convert_audio_to_dir "$OUTDIR-flac" "flac"

echo "============================================="
echo "Creating shortnames for $OUTDIR-mp3 (copying to $OUTDIR-mp3-shortnames)"
echo "============================================="
cmd="$BINDIR/rename_audiotrack_to_shortnames.pl -i \"$OUTDIR-mp3/*.mp3\" -o \"$OUTDIR-mp3-shortnames\""
echo $cmd
eval $cmd
cp "$INDIR/"*-*-*README.txt "$OUTDIR-mp3-shortnames/README.txt" || echo "file not found"
cp "$INDIR/Folder.jpg" "$OUTDIR-mp3-shortnames/" || echo "file not found"
echo ". . . . . . . .  .  .   .   .  .  . . . . . ."

