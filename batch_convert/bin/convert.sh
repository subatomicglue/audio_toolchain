#!/bin/sh

# this script's dir (and location of the other tools)
scriptpath=$0
scriptname=`basename "$0"`
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cwd=`pwd`

# options:
INDIR="."                   # name of input directory (with audiotracks, readme, images)
OUTDIR="out"                # name of output directory prefix
args=()
VERBOSE=true
valid_formats=("mp4" "m4a" "mp3" "ogg" "flac")

################################
# scan command line args:
function usage
{
  echo "$scriptname - convert a music album folder containing original [wav] files, to compressed distribution formats [${valid_formats[@]}]"
  echo "Usage:"
  echo "  $scriptname <indir> <outdir>              (input/output directory, default is \"$INDIR\", and \"$OUTDIR\", generate ALL known formats)"
  echo "  $scriptname <indir> <outdir> <formats...> (format options are: [${valid_formats[@]}])"
  echo "  $scriptname --help                        (this help)"
  echo "  $scriptname --verbose                     (output verbose information)"
  echo ""
  echo "Examples:"
  echo "  $scriptname ./wav ./out        # generate out-xxx/ directories for each of [${valid_formats[@]}]"
  echo "  $scriptname ./wav ./out m4a    # generate out-m4a/ only"
  echo ""
  echo "Typical files expected within the input folder, w/ naming convention here:"
  echo "       Folder.jpg"
  echo "       <bandname> - <albumname> - <tracknum> - <trackname>.wav"
  echo "       <bandname> - <albumname> - <kind>.jpg  # kind can be: booklet1..N, trayinside, trayoutside"
  echo "       <bandname> - <albumname> - README.txt"
  echo " e.g."
  echo "       subatomicglue - inertial decay - 01 - hard.wav"
  echo "       subatomicglue - inertial decay - 02 - acidbass.wav"
  echo "       subatomicglue - inertial decay - 03 - cause of a new dark age.wav"
  echo "       subatomicglue - inertial decay - 04 - daybreak falls.wav"
  echo "                           ....                                "
  echo "       subatomicglue - inertial decay - 14 - weet.wav"
  echo "       subatomicglue - inertial decay - Concept CD Disc.jpg"
  echo "       subatomicglue - inertial decay - Concept CD Booklet Front.jpg"
  echo "       subatomicglue - inertial decay - Concept CD Booklet Back.jpg"
  echo "       subatomicglue - inertial decay - Concept CD Tray Front.jpg"
  echo "       subatomicglue - inertial decay - Concept CD Tray Back.jpg"
  echo "       subatomicglue - inertial decay - Concept Vinyl Cover Back.jpg"
  echo "       subatomicglue - inertial decay - Concept Vinyl Cover Front.jpg"
  echo "       subatomicglue - inertial decay - Concept Vinyl Disc Back.jpg"
  echo "       subatomicglue - inertial decay - Concept Vinyl Disc Front.jpg"
  echo "       subatomicglue - inertial decay - README.txt"
  echo "       Folder.png"
  echo "       tags.ini"
  echo "Where <tracknum> is zero-padded for alphebetical dir listing..."
  echo ""
  echo "Here's a tags.ini example:"
  echo ""
  echo '# tags (the ones not inferable from the filename)
$ALBUMARTIST="subatomicglue";
$DATE="2012";
$SHORTCOMMENT="www.subatomicglue.com";
$COMMENT="In the rusty spaceship the alien plays a didgeridoo-like device, printed with faded letters barely legible \'M^n\'.s:3#7\'. Puffing, crossed legs, levitating, fireflies alight on the instrument making its face like firelight, organic glow halos of digital action, abstract geometry bouncing in time.  ------   Subatomicglue's 7th studio album, Inertial Decay, is the soundtrack to a rusty spaceship piloted by a solitary alien, filled with bliss, horror and polygons.  Frontman Kevin Meinert developed the material during development of the Subatomiclabs Mantis307 virtual analog synthesizer - in a symbiotic relationship - until the fireflies and bloody handprints formed upon all surfaces in the recording studio.  ------   Subatomicglue uses Mantis307 exclusively for all melodic parts (mantis.subatomiclabs.com) - www.subatomicglue.com";
$COMPOSER="k.meinert";
$PUBLISHER="subatomicglue";
$DISCNUMBER="01";
$BPM="secret"; # there is no one bpm...
$GENRE="Techno";"
$URL="http://www.subatomicglue.com";
$COPYRIGHT="$DATE subatomicglue";
';

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
    if [[ $OUTDIR == "." || $OUTDIR == ".." ]]; then
      OUTDIR="out"
    fi
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

echo "=================================="
echo "Audio Batch Convert - subatomiclabs"
echo "Input[$INDIR] Output[$OUTDIR]"
echo "=================================="

# if no format flags given, build all of them
if [ $non_flag_args -le 2 ]; then
  echo "No formats given (using default formats)"
  args+=("mp4")
  args+=("m4a")
  args+=("mp3")
  args+=("ogg")
  args+=("flac")
fi
#for arg in "${args[@]}"; do
#  echo "arg: '$arg'"
#done
requested_formats=(${args[@]:2})
#for format in "${requested_formats[@]}"; do
#  echo "format: '$format'"
#done

function firstExists {
  local files_to_check=($@)
  for i in "${files_to_check[@]}"; do
    if [ -f "$i" ]; then
      echo "$i"
      return
    fi
  done
  echo ""
  return
}

function filepath_path { local file=$1; echo `dirname -- "${file}"`; }
function filepath_name { local file=$1; echo `basename -- "${file%.*}"`; }
function filepath_ext { local file=$1; echo "${file##*.}"; }

# usage: convert_audio_to_dir <outputdir> <type>
function convert_audio_to_dir
{
  local dest=$1
  local type=$2
  echo "\n\n===================================================================="
  echo "[$type]  Converting *.wav to $dest/*.$type"
  echo "===================================================================="

  VIDEO_IMAGE_SEARCH=( "$INDIR/Video.png" "$INDIR/Video.jpg" "$INDIR/Cover.png" "$INDIR/Cover.jpg" "$INDIR/logo.png" "$INDIR/logo.jpg" "$INDIR/Folder.png" "$INDIR/Folder.jpg" )
  ALBUM_IMAGE_SEARCH=( "$INDIR/Folder.png" "$INDIR/Folder.jpg" "$INDIR/Video.png" "$INDIR/Video.jpg" "$INDIR/Cover.png" "$INDIR/Cover.jpg" "$INDIR/logo.png" "$INDIR/logo.jpg" )
  VIDEO_IMAGE=`firstExists "${VIDEO_IMAGE_SEARCH[@]}"`
  ALBUM_IMAGE=`firstExists "${ALBUM_IMAGE_SEARCH[@]}"`

  local cmd="$scriptdir/rip.pl -i \"$INDIR/*.wav\" -o \"$dest\" -t $type"
  if [ -f "$VIDEO_IMAGE" ]; then
    cmd+=" -image '$VIDEO_IMAGE'"
  fi
  echo "\n[$type][rip]\n$cmd"
  eval $cmd || exit -1

  echo "\n[$type][copy]\ncopy $INDIR/*.{jpg|gif|png} $INDIR/*readme.txt $dest/\n"
  local restore_nullglob=$(shopt -p nullglob)
  local restore_nocaseglob=$(shopt -p nocaseglob)
  shopt -s nullglob
  shopt -s nocaseglob
  # fyi: without changing the shell: [rR][eE][aA][dD][mM][eE]
  cp "$INDIR/"*.png "$INDIR/"*.jpg "$INDIR/"*.gif "$INDIR/"*README.txt "$dest/" || echo "file not found"
  eval "$restore_nullglob"
  eval "$restore_nocaseglob"

  ALBUM_IMAGE_DEST="$dest/Folder.jpg"
  if [ -f "$ALBUM_IMAGE" ]; then
    cmd="$scriptdir/install_folder_image.sh --max_dimension 500 --echo_pillar_box \"$ALBUM_IMAGE\" \"$ALBUM_IMAGE_DEST\""
    echo "\n[$type][install/resize $ALBUM_IMAGE_DEST image]\n$cmd"
    eval $cmd || exit -1
  else
    cmd="convert -size 500x500 xc:black \"$ALBUM_IMAGE_DEST\""
    echo "\n[$type][install/resize $ALBUM_IMAGE_DEST black image]\n$cmd"
    eval $cmd || exit -1
  fi

  cmd="$scriptdir/tag.pl -i \"$dest/*.$type\" -c \"$INDIR/tags.ini\""
  if [ -f "$ALBUM_IMAGE" ]; then
    cmd+=" -a '$ALBUM_IMAGE'"
  fi
  echo "\n[$type][tag]\n$cmd"
  eval $cmd || exit -1

  cmd="$scriptdir/playlist-gen.pl -i \"$dest/*.$type\" -o $dest/playlist.m3u"
  echo "\n[$type][playlist-gen]\n$cmd"
  eval $cmd || exit -1

  echo ". . . . . . . .  .  .   .   .  .  . . . . . ."
}

# check if a value exists in an array
function contains {
  local list=$1[@] # pass array as a param
  local elem=$2
  for i in "${!list}"; do
    if [ "$i" == "${elem}" ]; then return 0; fi # true
  done
  return -1 # false
}


echo "[wav] Generate an m3u playlist"
"$scriptdir/playlist-gen.pl" -i "$INDIR/*.wav" -o "$INDIR/playlist.m3u"

echo "[wav] Generate a CDBurnerXP project file for burning a CD"
"$scriptdir/cd-gen.pl" -i "$INDIR/*.wav" -o "$INDIR/cd.axp"

echo "Processing Formats: ${requested_formats[*]}"
for format in "${requested_formats[@]}"; do
  # validate input formats requested
  if contains valid_formats "$format"; then
    # only generate if the dir doesn't exist
    if [ ! -d "$OUTDIR-$format" ]; then
      convert_audio_to_dir "$OUTDIR-$format" "$format"
    else
      echo "[$format] Skipping, directory already exists: \"$OUTDIR-$format\""
    fi
  else
    echo "[$format] Skipping, not a valid format... valid_formats: [${valid_formats[@]}]"
  fi
done

