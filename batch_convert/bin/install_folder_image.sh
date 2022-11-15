#!/bin/sh

# this script's dir (and location of the other tools)
scriptpath=$0
scriptname=`basename "$0"`
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cwd=`pwd`

# options:
max_dimension=500
resize_square=false
crop_square=false
echo_pillar_box=false
args=()
VERBOSE=false
# script's dir:
BINDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

################################
# scan command line args:
function usage
{
  echo "$scriptname copy a Folder.jpg to destination, resizing if needed"
  echo "Usage: "
  echo "  $scriptname <folder.jpg> <destination.jpg>"
  echo "  $scriptname <folder.jpg> <destination.jpg> --help                (this help)"
  echo "  $scriptname <folder.jpg> <destination.jpg> --verbose             (verbose debugging (if any))"
  echo "  $scriptname <folder.jpg> <destination.jpg> --max_dimension <dim> (maximum pixel dimension default:$max_dimension)"
  echo "  $scriptname <folder.jpg> <destination.jpg> --resize_square       (force the image to be square default:$resize_square)"
  echo "  $scriptname <folder.jpg> <destination.jpg> --crop_square         (force the image to be square default:$crop_square)"
  echo ""
}
ARGC=$#
ARGV=("$@")
non_flag_args=0
non_flag_args_required=2
for ((i = 0; i < ARGC; i++)); do
  if [[ $ARGC -ge 1 && ${ARGV[$i]} == "--help" ]]; then
    usage
    exit -1
  fi
  if [[ $ARGC -ge 1 && ${ARGV[$i]} == "--verbose" ]]; then
    VERBOSE=true
    continue
  fi
  if [[ $ARGC -ge 1 && ${ARGV[$i]} == "--max_dimension" ]]; then
    ((i+=1))
    max_dimension=${ARGV[$i]}
    $VERBOSE && echo "Parsing Args: changing max dimension to $max_dimension"
    continue
  fi
  if [[ $ARGC -ge 1 && ${ARGV[$i]} == "--resize_square" ]]; then
    resize_square=true
    continue
  fi
  if [[ $ARGC -ge 1 && ${ARGV[$i]} == "--crop_square" ]]; then
    crop_square=true
    continue
  fi
  if [[ $ARGC -ge 1 && ${ARGV[$i]} == "--echo_pillar_box" ]]; then
    echo_pillar_box=true
    continue
  fi
  if [[ $ARGC -ge 1 && ${ARGV[$i]:0:2} == "--" ]]; then
    echo "Unknown option ${ARGV[$i]}"
    exit -1
  fi

  args+=("${ARGV[$i]}")
  $VERBOSE && echo "Parsing Args: File: \"${ARGV[$i]}\""
done

# output help if they're getting it wrong...
if [ $non_flag_args_required -ne 0 ] && [[ $ARGC -eq 0 || ! $ARGC -ge $non_flag_args_required ]]; then
  [ $ARGC -gt 0 ] && echo "Expected $non_flag_args_required args, but only got $ARGC"
  usage
  exit -1
fi
################################

if [ ! -f "${args[0]}" ]; then
  echo "${args[0]} not found"
  exit -1
fi

# yep, we could just run convert without all this crap, convert has the "if" logic we need.
# I just wanted to output some stats... :)
WIDTH=`$BINDIR/image_stats.sh --nocr --width "${args[0]}"`
HEIGHT=`$BINDIR/image_stats.sh --nocr --height "${args[0]}"`
# Set `min_dimension` to lesser of width and height
MIN_WIDTH_HEIGHT=$WIDTH
[ $HEIGHT -lt $MIN_WIDTH_HEIGHT ] && MIN_WIDTH_HEIGHT=$HEIGHT
MAX_WIDTH_HEIGHT=$WIDTH
[ $HEIGHT -gt $MAX_WIDTH_HEIGHT ] && MAX_WIDTH_HEIGHT=$HEIGHT
$VERBOSE && echo "${args[0]} image is $WIDTH x $HEIGHT"
if [[ $WIDTH -gt $max_dimension ]]; then
  MAX_WIDTH_HEIGHT=$max_dimension
fi
if [[ $HEIGHT -gt $max_dimension ]]; then
  MAX_WIDTH_HEIGHT=$max_dimension
fi


echo "Resizing image from ${WIDTH}x${HEIGHT} to fit inside a ${MAX_WIDTH_HEIGHT}x${MAX_WIDTH_HEIGHT} box"
echo " - ${args[0]} (${WIDTH}x${HEIGHT})"
if [ $echo_pillar_box == true ]; then
  echo "echo_pillar_box $cmd"
  cmd="\"$BINDIR/create_echo_pillarbox_image.sh\" \"${args[0]}\" \"/tmp/tempASDFHJASD237824798.png\" \"$MAX_WIDTH_HEIGHT\" \"$MAX_WIDTH_HEIGHT\""
  eval "$cmd"

  # make it 72
  convert -units PixelsPerInch "/tmp/tempASDFHJASD237824798.png" -thumbnail ${MAX_WIDTH_HEIGHT}x${MAX_WIDTH_HEIGHT}^ -gravity Center -extent ${MAX_WIDTH_HEIGHT}x${MAX_WIDTH_HEIGHT} -density 72 "${args[1]}"
  rm "/tmp/tempASDFHJASD237824798.png"

elif [ $crop_square == true ]; then
  echo "crop_square"
  convert -units PixelsPerInch "${args[0]}" -thumbnail ${MAX_WIDTH_HEIGHT}x${MAX_WIDTH_HEIGHT}^ -gravity Center -extent ${MAX_WIDTH_HEIGHT}x${MAX_WIDTH_HEIGHT} -density 72 "${args[1]}"
elif [ $resize_square == true ]; then
  echo "resize square"
  convert -units PixelsPerInch "${args[0]}" -resize ${MAX_WIDTH_HEIGHT}x${MAX_WIDTH_HEIGHT}\! -density 72 "${args[1]}"
else
  echo "resize"
  convert -units PixelsPerInch "${args[0]}" -resize ${MAX_WIDTH_HEIGHT}x${MAX_WIDTH_HEIGHT}\> -density 72 "${args[1]}"
fi

WIDTH=`$BINDIR/image_stats.sh --nocr --width "${args[1]}"`
HEIGHT=`$BINDIR/image_stats.sh --nocr --height "${args[1]}"`
echo " - ${args[1]} (${WIDTH}x${HEIGHT})"


