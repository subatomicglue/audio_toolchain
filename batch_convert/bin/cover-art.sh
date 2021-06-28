
AUDIOFILES=()
VERBOSE=false
BINDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

################################
# scan command line args:
function usage
{
  echo "$0 add cover art image to an audio file [mp3|m4a|flac|ogg]"
  echo "Usage:"
  echo "  $0 <artfile.jpg> <audio_file>"
  echo "  $0 --help        (this help)"
  echo "  $0 --verbose     (output verbose information)"
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
  if [[ $ARGC -ge 1 && ${ARGV[$i]:0:2} == "--" ]]; then
    echo "Unknown option ${ARGV[$i]}"
    exit -1
  fi

  args+=("${ARGV[$i]}")
  $VERBOSE && echo "Parsing Args: \"${ARGV[$i]}\""
  ((non_flag_args+=1))

  # non switch args:
  if [ $non_flag_args -eq 1 ]; then
    ARTFILE=${ARGV[$i]}
    $VERBOSE && echo "Parsing Args: Changing art file to '$ARTFILE'"
  fi
  if [ $non_flag_args -ge 2 ]; then
    AUDIOFILES+=("${ARGV[$i]}")
    $VERBOSE && echo "Parsing Args: Changing audio file to '$AUDIOFILES'"
  fi
done

# output help if they're getting it wrong...
if [ $non_flag_args_required -ne 0 ] && [[ $ARGC -eq 0 || ! $ARGC -ge $non_flag_args_required ]]; then
  [ $ARGC -gt 0 ] && echo "Expected $non_flag_args_required args, but only got $ARGC"
  usage
  exit -1
fi
################################
if [ ! -f "$ARTFILE" ]; then
  echo "File not found: \"$ARTFILE\""
  exit -1
fi
for AUDIOFILE in "${AUDIOFILES[@]}"
do
  if [ ! -f "$AUDIOFILE" ]; then
    echo "File not found: \"$AUDIOFILE\""
    exit -1
  fi
done

if [ "${ARTFILE: -4}" != ".jpg" ]; then
  echo "Unknown art filetype for \"$ARTFILE\""
  exit -1
fi

for AUDIOFILE in "${AUDIOFILES[@]}"
do
  echo "-----------------------------------------------------------------------------------"
  echo "[$AUDIOFILE]"
  echo " - Adding '$ARTFILE'"
  if [ "${AUDIOFILE: -4}" == ".mp3" ]; then
    eyeD3 -Q --preserve-file-times --add-image="$ARTFILE":FRONT_COVER:"Album cover" "$AUDIOFILE"

  elif [ "${AUDIOFILE: -4}" == ".m4a" ]; then
    # atomicparsely overwrite was buggy, or not what i expected/needed...  use a temp file
    tmp_dir=$( mktemp -d -t __temp2435789234759 ) && AtomicParsley "$AUDIOFILE" --artwork REMOVE_ALL --artwork "$ARTFILE" -o "$tmp_dir/__temp2435789234759.m4a" && sleep 1 && mv "$tmp_dir/__temp2435789234759.m4a" "$AUDIOFILE"
    rm -rf "${tmp_dir}"

  elif [ "${AUDIOFILE: -5}" == ".flac" ]; then
    metaflac --remove --dont-use-padding --block-type=PICTURE "$AUDIOFILE"
    metaflac --remove --dont-use-padding --block-type=PADDING "$AUDIOFILE"
    metaflac --import-picture-from="$ARTFILE" "$AUDIOFILE"

  elif [ "${AUDIOFILE: -4}" == ".ogg" ]; then
    "$BINDIR/ogg-cover-art.sh" "$ARTFILE" "$AUDIOFILE" > /dev/null 2>&1

  else
    echo "Unknown audio filetype for \"$AUDIOFILE\""
  fi
done
