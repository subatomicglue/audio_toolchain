#!/bin/sh

# this script's dir (and location of the other tools)
scriptpath=$0
scriptname=`basename "$0"`
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cwd=`pwd`

# options:
type="db"               # peak "db" or "lvl"
dest_dir="renamed"      # CAUTION we DELETE this dir! (unique name here)
seconds_to_scan=1
wavs=()
VERBOSE=false

################################
# scan command line args:
function usage
{
  echo "$scriptname rename audio files by their peak level.  useful for individual instrument samples."
  echo "Usage: "
  echo "  $scriptname <wav files>   (list of wav files to rename, copying to '$dest_dir/')"
  echo "  $scriptname --help        (this help)"
  echo "  $scriptname --verbose     (output verbose information)"
  echo "  $scriptname --seconds     (number of seconds to scan, default $seconds_to_scan)"
  echo "  $scriptname --type        (use peak db or lvl in the rename, default $type)"
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

rm -fr "./$dest_dir"
mkdir -p "./$dest_dir"

for f in "${wavs[@]}"; do
  if [ $type == "db" ]; then
    value=`${scriptdir}/peak_dB.sh --nocr --seconds $seconds_to_scan "$f"`db
  elif [[ $type == "lvl" || $type == "level" ]]; then
    value=`${scriptdir}/max_lvl.sh --nocr --seconds $seconds_to_scan "$f"`
  fi

  f_new=`echo "$f" | sed -E "s/(- [.0-9]+)?(\.[^.]+)$/${value}\2/g"`
  outfileext=`echo "$f_new" | sed -E "s/^.*\/[^/]+(\.[^.]+)$/\1/g"`
  outfilename=`echo "$f_new" | sed -E "s/^.*\/([^/]+)\.[^.]+$/\1/g"`

  #outpath=`echo "$f_new" | sed -E "s/([^/]+)$//g" | sed -E "s/\/$//g"` # use all of infile's path ("src/SD/SD.wav" to "src/SD")
  outpath=`echo "$f_new" | sed -E "s/([^/]+)$//g" | sed -E "s/\/$//g" | sed -E "s/^.*\///g"` # use infile's parent dirname only ("src/SD/SD.wav" to "SD")

  # if only one directory (when full path == parent dir)  (e.g. "src/file.wav" parent dir is "src")
  fullpath=`echo "$f_new" | sed -E "s/\/?([^/]+)$//g"`
  if [ "$outpath" == "$fullpath" ]; then
    outpath="."
  fi

  echo "$f -> $dest_dir/$outpath/$outfilename$outfileext"
  mkdir -p "./$dest_dir/$outpath"
  cp "$f" "./$dest_dir/$outpath/$outfilename$outfileext"
done



