#!/bin/sh

# this script's dir (and location of the other tools)
scriptpath=$0
scriptname=`basename "$0"`
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cwd=`pwd`

# options:
wavs=()
VERBOSE=false
factor="1"
type="pitch"

################################
# scan command line args:
function usage
{
  echo "$scriptname make audio files mono"
  echo "Usage: "
  echo "  $scriptname <wav files>   (list of wav files to rename, copying to '$dest_dir/')"
  echo "  $scriptname --help        (this help)"
  echo "  $scriptname --verbose     (output verbose information)"
  echo "  $scriptname --type        (speed (resample) | pitch (preserve tempo) | tempo (preserve pitch) )"
  echo "  $scriptname --factor      (tempo/speed:  0-1 down;  >1 up;  pitch: +/- cents (1 cent == 100th of a semitone; 1 semitone == interval between 2 adjacent piano keys))"
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
  if [[ $ARGC -ge 1 && ${ARGV[$i]} == "--type" ]]; then
    ((i+=1))
    type=${ARGV[$i]}
    $VERBOSE && echo "Parsing Args: Changing type to $type"
    continue
  fi
  if [[ $ARGC -ge 1 && ${ARGV[$i]} == "--factor" ]]; then
    ((i+=1))
    factor=${ARGV[$i]}
    $VERBOSE && echo "Parsing Args: Changing factor to $factor"
    continue
  fi
  if [[ $ARGC -ge 1 && ${ARGV[$i]:0:2} == "--" ]]; then
    echo "Unknown option ${ARGV[$i]}"
    exit -1
  fi

  wavs+=("${ARGV[$i]}")
  $VERBOSE && echo "Parsing Args: Audio: \"${ARGV[$i]}\""
  ((non_flag_args+=1))
done

# output help if they're getting it wrong...
if [ $non_flag_args_required -ne 0 ] && [[ $ARGC -eq 0 || ! $ARGC -ge $non_flag_args_required ]]; then
  [ $ARGC -gt 0 ] && echo "Expected $non_flag_args_required args, but only got $ARGC"
  usage
  exit -1
fi
################################

f="${wavs[0]}"
f2="${wavs[1]}"
if [ ! -f "$f" ]; then
  echo "$scriptname: \"$f\" not found"
  exit -1
fi

# speed factor[c]
# pitch [-q] shift [segment [search [overlap]]]  (in cents, 100ths of a semitone)
# tempo [-q] factor [segment [search [overlap]]]
echo "${type} \"$f\" -> \"$f2\""
sox "$f" "$f2" "${type}" "${factor}"

