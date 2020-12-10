#!/bin/sh

# options:
thresh=1
wavs=()
VERBOSE=false

################################
# scan command line args:
function usage
{
  echo "$0   auto slices a single audio file containing music instrument samples (separated by silence), into separate .wav files (timmed by silence)"
  echo "Usage: "
  echo "  $0 <in> <out>    (in/out files: ./SD.aif ./SD/SD.wav)"
  echo "  $0 --help        (this help)"
  echo "  $0 --verbose     (output verbose information)"
  echo "  $0 --thresh      (silence threshold, default: $thresh)"
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
  wavs+=("${ARGV[$i]}")
  $VERBOSE && echo "Parsing Args: Audio: \"${ARGV[$i]}\""
  ((non_flag_args+=1))
done

# output help if they're getting it wrong...
if [[ $ARGC -eq 0 || ! $ARGC -ge $non_flag_args_required ]]; then
  [ $ARGC -gt 0 ] && echo "Expected $non_flag_args_required args, but only got $ARGC"
  usage
  exit -1
fi
################################

outpath=${wavs[ ${#wavs[@]} - 1 ]}
unset wavs[${#wavs[@]}-1]
infiles=("${wavs[@]}")

echo In:       ${infiles[@]}
echo Out Path: $outpath
if [ -f "$outpath" ]; then
  echo "ERROR: $outpath appears to be a file"
  exit -1
fi

# sox:
# silence [ -l ] above_periods [ duration threshold[d|%] ] [ below_periods duration threshold[d|%] ]

for infile in "${infiles[@]}"; do
  filename=`echo "$infile" | sed -E "s/^.*\/([^/]+)\.[^.]+$/\1/g"`
  inpath=`echo "$infile" | sed -E "s/([^/]+)$//g" | sed -E "s/\/$//g"`
  mkdir -p "./$outpath/$filename"

  outfile="./$outpath/$filename/$filename - .wav"
  echo "Slicing:  \"$infile\" => \"$outfile\" "
  sox "$infile" "$outfile" silence 1 0.1 1% 1 0.1 1% : newfile : restart
done



