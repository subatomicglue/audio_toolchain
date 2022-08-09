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
  echo "$scriptname output the max level found in the audio file"
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
    #echo "changing to $seconds_to_scan seconds to scan"
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

  wavs+=("${ARGV[$i]}")
  #echo "Audio: ${ARGV[$i]}"
done
################################

# for each wav given:
for f in "${wavs[@]}"; do
  max_lvl=`sox "$f" -n trim 0 $seconds_to_scan stats 2>&1 | grep "Max level" | sed -E "s|^Max level[[:space:]]*([-.0-9]*).*$|\1|g"`
  max_lvl_padded=`printf "%07.6f" $max_lvl`

  if [ ${#wavs[@]} -gt 1 ]; then
    echo "$f\t->\t$max_lvl_padded"
  elif [ $nocr -eq 1 ]; then
    printf "%s" $max_lvl_padded
  else
    echo "$max_lvl_padded"
  fi
done



