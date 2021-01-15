#!/bin/sh

# options:
which="width"
nocr=0
args=()
VERBOSE=false

################################
# scan command line args:
function usage
{
  echo "$0 output the image stats"
  echo "Usage: "
  echo "  $0 <imagefile>   (default)"
  echo "  $0 --help        (this help)"
  echo "  $0 --verbose     (verbose debugging (if any))"
  echo "  $0 --width       (output width of image (default))"
  echo "  $0 --height      (output height of image)"
  echo "  $0 --nocr        (return the single result with no carriage return, default $nocr)"
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
  if [[ $ARGC -ge 1 && ${ARGV[$i]} == "--width" ]]; then
    #((i+=1))
    which="width"
    $VERBOSE && echo "Parsing Args: outputting width"
    continue
  fi
  if [[ $ARGC -ge 1 && ${ARGV[$i]} == "--height" ]]; then
    #((i+=1))
    which="height"
    $VERBOSE && echo "Parsing Args: outputting height"
    continue
  fi
  if [[ $ARGC -ge 1 && ${ARGV[$i]} == "--nocr" ]]; then
    nocr=1
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

$VERBOSE && echo "Displaying $which"

# sips -g pixelHeight -g pixelWidth "$1"
if [ $which == "width" ]; then
  DIM=`sips -g pixelWidth "${args[0]}" | grep pixelWidth | grep pixelWidth | sed -e "s/  pixelWidth: //g"`
elif [ $which == "height" ]; then
  DIM=`sips -g pixelHeight "${args[0]}" | grep pixelHeight | grep pixelHeight | sed -e "s/  pixelHeight: //g"`
fi

if [ $nocr -eq 1 ]; then
  printf "%s" $DIM
else
  echo $DIM
fi

