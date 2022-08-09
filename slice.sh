#!/bin/sh

# this script's dir (and location of the other tools)
scriptpath=$0
scriptname=`basename "$0"`
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cwd=`pwd`

# options:
dest_dir="sliced"        # CAUTION we DELETE this dir! (unique name here)
thresh=1
wavs=()
VERBOSE=false

################################
# scan command line args:
function usage
{
  echo "$scriptname   auto slices a single audio file containing music instrument samples (separated by silence), into separate .wav files (timmed by silence)"
  echo "Usage: "
  echo "  $scriptname <in>          (in file: ./SD.aif)"
  echo "  $scriptname --help        (this help)"
  echo "  $scriptname --verbose     (output verbose information)"
  echo "  $scriptname --thresh      (silence threshold % 1-100, default: $thresh)"
  echo "  $scriptname --destdir     (default '$dest_dir/')"
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
  if [[ $ARGC -ge 1 && ${ARGV[$i]} == "--thresh" ]]; then
    ((i+=1))
    thresh=${ARGV[$i]}
    $VERBOSE && echo "Parsing Args: Changing noise threshhold to $thresh"
    continue
  fi
  if [[ $ARGC -ge 1 && ${ARGV[$i]} == "--type" ]]; then
    ((i+=1))
    type=${ARGV[$i]}
    $VERBOSE && echo "Parsing Args: Changing to $type type"
    continue
  fi
  if [[ $ARGC -ge 1 && ${ARGV[$i]} == "--destdir" ]]; then
    ((i+=1))
    dest_dir=${ARGV[$i]}
    $VERBOSE && echo "Parsing Args: Changing dest_dir to '$dest_dir/'"
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

outpath="./$dest_dir"  #${wavs[ ${#wavs[@]} - 1 ]}
#unset wavs[${#wavs[@]}-1]
infiles=("${wavs[@]}")

echo In:       ${infiles[@]}
echo Out Path: $outpath
if [ -f "$outpath" ]; then
  echo "ERROR: $outpath appears to be a file"
  exit -1
fi

# sox:
# silence [ -l ] above_periods [ duration threshold[d|%] ] [ below_periods duration threshold[d|%] ]

# The above-periods value is used to indicate if audio should be trimmed at the beginning of the audio. A value of zero indicates no silence should be trimmed from the beginning. When specifying an non-zero above-periods, it trims audio up until it finds non-silence.
# e.g. 1 strips silence before the sound.   2 strips silence, sound, and then more silence (2 periods of silence and whatever was inbetween)
#
# When above-periods is non-zero, you must also specify a duration and threshold:
#
# Duration indicates the amount of time that non-silence must be detected before it stops trimming audio. By increasing the duration, burst of noise can be treated as silence and trimmed off.
#
# Threshold is used to indicate what sample value you should treat as silence. For digital audio, a value of 0 may be fine but for audio recorded from analog, you may wish to increase the value to account for background noise.
#
# When specifying duration, use a trailing zero for whole numbers of seconds (ie, 1.0 instead of 1 to specify 1 second). If you don’t, SoX assumes you’re specifying a number of samples.
#
# Use at 0.1% at a minimum for an audio threshold.
# you can specify the threshold in decibels using d (such as -96d or -55d
#
# The realistic values for the above-period parameter are 0 and 1 and values for the below-period parameter are pretty much just -1 and 1.


echo "================================"
echo "SLICING to $outpath"
echo "================================"
for infile in "${infiles[@]}"; do
  filename=`echo "$infile" | sed -E "s/^.*\/([^/]+)\.[^.]+$/\1/g"`
  inpath=`echo "$infile" | sed -E "s/([^/]+)$//g" | sed -E "s/\/$//g"`
  mkdir -p "./$outpath/$filename"

  outfile="./$outpath/$filename/$filename - .wav"
  echo "Slicing:  \"$infile\" => \"$outfile\" "
  sox "$infile" "$outfile" silence 1 0.1 $thresh% 1 0.1 $thresh% : newfile : restart
done



