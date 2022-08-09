#!/bin/sh

# this script's dir (and location of the other tools)
scriptpath=$0
scriptname=`basename "$0"`
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cwd=`pwd`

# options:
seconds_to_scan=1
nocr=0
wavs=()
VERBOSE=false

################################
# scan command line args:
function usage
{
  echo "$scriptname output the peak db found in the audio file"
  echo "Usage: "
  echo "  $scriptname               (default)"
  echo "  $scriptname --help        (this help)"
  echo "  $scriptname --verbose     (output verbose information)"
  echo "  $scriptname --seconds     (number of seconds to scan, default $seconds_to_scan)"
  echo "  $scriptname --nocr        (return the single result with no carriage return, default $nocr)"
  echo ""
}
ARGC=$#
ARGV=("$@")
# no arguments given, output help
if [ $ARGC -eq 0 ]; then
  usage
  exit -1
fi
for ((i = 0; i < ARGC; i++)); do
  if [[ $ARGC -ge 1 && ${ARGV[$i]} == "--help" ]]; then
    usage
    exit -1
  fi
  if [[ $ARGC -ge 1 && ${ARGV[$i]} == "--verbose" ]]; then
    VERBOSE=true
    continue
  fi
  if [[ $ARGC -ge 1 && ${ARGV[$i]} == "--seconds" ]]; then
    ((i+=1))
    seconds_to_scan=${ARGV[$i]}
    $VERBOSE && echo "Parsing Args: Changing to $seconds_to_scan seconds to scan"
    continue
  fi
  if [[ $ARGC -ge 1 && ${ARGV[$i]} == "--nocr" ]]; then
    nocr=1
    $VERBOSE && echo "Parsing Args: Will not output New Line after single result"
    continue
  fi
  if [[ $ARGC -ge 1 && ${ARGV[$i]:0:2} == "--" ]]; then
    echo "Unknown option ${ARGV[$i]}"
    exit -1
  fi

  wavs+=("${ARGV[$i]}")
  $VERBOSE && echo "Parsing Args: Audio: \"${ARGV[$i]}\""
done
################################

# for each wav given:
for f in "${wavs[@]}"; do
  db=`sox "$f" -n trim 0 $seconds_to_scan stats 2>&1 | grep "Pk lev dB" | sed -E "s|^Pk lev dB[[:space:]]*([-.0-9]*).*$|\1|g"`

  db_padded=`printf "%07.3f" $db`
  # db is always negative unless it clipped, then 000.000
  if [ $db_padded == "000.000" ]; then
    db_padded="-00.000"
  fi

  if [ ${#wavs[@]} -gt 1 ]; then
    echo "$f\t->\t$db_padded"
  elif [ $nocr -eq 1 ]; then
    printf "%s" $db_padded
  else
    echo "$db_padded"
  fi
done



