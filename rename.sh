#!/bin/sh

# options:
dest_dir="final"        # CAUTION we DELETE this dir! (unique name here)
type="db"               # peak "db" or "lvl"
seconds_to_scan=1
wavs=()
VERBOSE=false

################################
# scan command line args:
function usage
{
  echo "$0 rename audio files by their peak level.  useful for individual instrument samples."
  echo "Usage: "
  echo "  $0 <wav files>   (list of wav files to rename, copying to $dest_dir)"
  echo "  $0 --help        (this help)"
  echo "  $0 --verbose     (output verbose information)"
  echo "  $0 --seconds     (number of seconds to scan, default $seconds_to_scan)"
  echo "  $0 --type        (use peak db or lvl in the rename, default $type)"
  echo "  $0 --destdir     (default $dest_dir)"
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
  if [[ $ARGC -ge 1 && ${ARGV[$i]} == "--seconds" ]]; then
    ((i+=1))
    seconds_to_scan=${ARGV[$i]}
    $VERBOSE && echo "Parsing Args: Changing to $seconds_to_scan seconds to scan"
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
    $VERBOSE && echo "Parsing Args: Changing dest_dir to $dest_dir"
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


dest_dir="${dest_dir}_$type"
rm -fr "./$dest_dir"
mkdir -p "./$dest_dir"

for f in "${wavs[@]}"; do
  if [ $type == "db" ]; then
    value=`./peak_dB.sh --nocr --seconds $seconds_to_scan "$f"`db
  elif [[ $type == "lvl" || $type == "level" ]]; then
    value=`./max_lvl.sh --nocr --seconds $seconds_to_scan "$f"`
  fi

  f_new=`echo "$f" | sed -E "s/(- [.0-9]+)?(\.[^.]+)$/${value}\2/g"`
  outfileext=`echo "$f_new" | sed -E "s/^.*\/[^/]+(\.[^.]+)$/\1/g"`
  outfilename=`echo "$f_new" | sed -E "s/^.*\/([^/]+)\.[^.]+$/\1/g"`

  #outpath=`echo "$f_new" | sed -E "s/([^/]+)$//g" | sed -E "s/\/$//g"` # use all of infile's path
  outpath=`echo "$f_new" | sed -E "s/([^/]+)$//g" | sed -E "s/\/$//g" | sed -E "s/^.*\///g"` # use infile's parent dirname only

  echo "$f -> $dest_dir/$outpath/$outfilename$outfileext"
  mkdir -p "./$dest_dir/$outpath"
  cp "$f" "./$dest_dir/$outpath/$outfilename$outfileext"
done



