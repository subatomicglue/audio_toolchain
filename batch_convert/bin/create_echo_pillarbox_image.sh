
# Echo Pillarboxing (and Letterboxing)
# Convert an image into another aspect ratio (like 1:1 or 4:3, into a 16:9 ratio)
#
# Fill the letterbox/pillarbox black bars with something attractive.
# Called "echo" pillarboxing (or letterboxing).  Aka stylized pillarboxing.
#
# by doing the following series of compositing steps:
# - black viewport
# - image fit to cover viewport
# - blur viewport    (some for rectangular/opaque art, a lot for art w/ alpha)
# - blacken viewport (some for rectangular/opaque art, a lot for art w/ alpha)
# - image fit to viewport

# this script's dir (and location of the other tools)
scriptpath=$0
scriptname=`basename "$0"`
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cwd=`pwd`

# options:
args=()
VERBOSE=false

################################
# scan command line args:
function usage
{
  echo "$scriptname - Create image for use in video using Echo Pillarboxing (or Letterboxing) technique."
  echo ""
  echo "  Converts a given image into another aspect ratio (e.g. give 1:1 or 4:3, get an image w/ 16:9 ratio)"
  echo "  Use Echo Pillarboxing (or Letterboxing) to fill the letterbox/pillarbox black bars with something attractive."
  echo "  Aka \"stylized pillarboxing\"."
  echo ""
  echo "Usage:"
  echo "  $scriptname <in image> <out image> <out width> <out height>"
  echo "  $scriptname --help        (this help)"
  echo "  $scriptname --verbose     (output verbose information)"
  echo ""
  echo "Examples:"
  echo "  $scriptname Folder.jpg video_cover.png 1920 1080"
  echo ""
}
ARGC=$#
ARGV=("$@")
non_flag_args=0
non_flag_args_required=4
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

IMAGE="${args[0]}"
TARGET_IMAGE="${args[1]}"
TARGET_WIDTH="${args[2]}"
TARGET_HEIGHT="${args[3]}"
TARGET_ASPECT=$(( ($TARGET_HEIGHT*1000000) / $TARGET_WIDTH )) # bash cant do floatingpoint, so do % in integers instead
IMAGE_WIDTH=`magick identify -format "%w" "$IMAGE"`;
IMAGE_HEIGHT=`magick identify -format "%h" "$IMAGE"`;
IMAGE_ASPECT=$(( ($IMAGE_HEIGHT*1000000) / $IMAGE_WIDTH ))    # bash cant do floatingpoint, so do % in integers instead

# calculate new width/height of final image
SCALEX=$( (($TARGET_ASPECT < $IMAGE_ASPECT)) && echo $(( ($IMAGE_WIDTH * $TARGET_HEIGHT) / $IMAGE_HEIGHT )) || echo "$TARGET_WIDTH")
SCALEY=$(( ($SCALEX * $IMAGE_ASPECT) / 1000000 ))

function getWidth {
  local FILENAME="$1"
  echo `convert "$FILENAME" -format "%w" info:`
}
function getHeight {
  local FILENAME="$1"
  echo `convert "$FILENAME" -format "%h" info:`
}
function getIsOpaque {
  local FILENAME="$1"
  local HEIGHT=`getHeight "$FILENAME"`
  #local X=1
  #local Y=1
  #echo `convert -colorspace sRGB "$FILENAME" -format "%[fx:int(255*p{$X,$Y}.r)],%[fx:int(255*p{$X,$Y}.g)],%[fx:int(255*p{$X,$Y}.b)],%[fx:int(255*p{$X,$Y}.a)]" info:`
  #echo `convert -colorspace sRGB -matte -crop 1x1+1+1  "$FILENAME" -format "%[opaque]" info:`
  echo `convert -colorspace sRGB "$FILENAME" -format "%[opaque]" info:`
}
echo "Image:    ${IMAGE_WIDTH}x${IMAGE_HEIGHT}"
echo "Image:    ${SCALEX}x${SCALEY} (scaled)"
echo "Target:   ${TARGET_WIDTH}x${TARGET_HEIGHT}"

OPAQUE=`getIsOpaque "$IMAGE"` # top left pixel
if [ "${OPAQUE}" == "True" ]; then
  BLUR=32
  ALPHA=0.75
else
  BLUR=64
  ALPHA=0.9
fi
echo "Opaque:   ${OPAQUE}  (Blur:$BLUR Alpha $ALPHA)"
echo "Writing:  $TARGET_IMAGE"

magick convert -colorspace sRGB \
  -size ${TARGET_WIDTH}x${TARGET_HEIGHT} xc:black \
  "$IMAGE"                   -gravity Center -geometry ${TARGET_WIDTH}                       -composite \
  -blur 0x$BLUR \
  xc:"rgba(0, 0, 0, $ALPHA)" -gravity Center -geometry ${TARGET_WIDTH}x${TARGET_HEIGHT}+0+0  -composite \
  "$IMAGE"                   -gravity Center -geometry ${SCALEX}x${SCALEY}+0+0               -composite \
  "$TARGET_IMAGE"

