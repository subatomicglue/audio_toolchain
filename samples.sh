#!/bin/sh

# options:
nocr=0
wavs=()
VERBOSE=false

################################
# scan command line args:
function usage
{
  echo "$0 output the number of samples found in the audio file"
  echo "Usage: "
  echo "  $0               (default)"
  echo "  $0 --help        (this help)"
  echo "  $0 --verbose     (output verbose information)"
  echo "  $0 --nocr        (return the single result with no carriage return, default $nocr)"
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
  samps=`sox "$f" -n stat 2>&1 | grep "Samples read:" | sed -E "s|^Samples read:[[:space:]]*([-.0-9]*).*$|\1|g"`
  samps_padded=`printf "%07.6f" $samps`

  if [ ${#wavs[@]} -gt 1 ]; then
    echo "$f\t->\t$samps"
  elif [ $nocr -eq 1 ]; then
    printf "%s" $samps
  else
    echo "$samps"
  fi
done


exit 0

