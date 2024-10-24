#!/bin/sh

# this script's dir (and location of the other tools)
scriptpath=$0
scriptname=`basename "$0"`
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cwd=`pwd`

# options:
type="db"               # peak "db" or "lvl"
dest_dir="renamed"      # CAUTION we DELETE this dir! (unique name here)
start_in_seconds=0
duration_in_seconds=1
wavs=()
VERBOSE=false

################################
# scan command line args:
function usage
{
  echo "$scriptname rename audio files by their peak level.  useful for individual instrument samples."
  echo "Example: "
  echo "  $scriptname --destdir out --type lvl \"myfile - 001.wav\"   # outputs \"myfile - 0.521.wav\""
  echo ""
  echo "Usage: "
  echo "  $scriptname <wav files>   (list of wav files to rename, copying to '$dest_dir/')"
  echo "  $scriptname --help        (this help)"
  echo "  $scriptname --verbose     (output verbose information)"
  echo "  $scriptname --seconds     same as --duration"
  echo "  $scriptname --duration    (number of seconds to scan, default $duration_in_seconds)"
  echo "  $scriptname --start       (starting offset in seconds, default $start_in_seconds)"
  echo "  $scriptname --type        (use peak db or lvl or freq in the rename, default $type)"
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
  if [[ $ARGC -ge 1 && ${ARGV[$i]} == "--start" ]]; then
    ((i+=1))
    start_in_seconds=${ARGV[$i]}
    $VERBOSE && echo "Parsing Args: Changing to $start_in_seconds seconds to scan"
    continue
  fi
  if [[ $ARGC -ge 1 && ${ARGV[$i]} == "--seconds" ]]; then
    ((i+=1))
    duration_in_seconds=${ARGV[$i]}
    $VERBOSE && echo "Parsing Args: Changing to $duration_in_seconds seconds to scan"
    continue
  fi
  if [[ $ARGC -ge 1 && ${ARGV[$i]} == "--duration" ]]; then
    ((i+=1))
    duration_in_seconds=${ARGV[$i]}
    $VERBOSE && echo "Parsing Args: Changing to $duration_in_seconds seconds to scan"
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

#rm -fr "./$dest_dir"
mkdir -p "./$dest_dir"

function filepath_path { local file=$1; echo `dirname -- "${file}"`; }
function filepath_name { local file=$1; echo `basename -- "${file%.*}"`; }
function filepath_ext { local file=$1; echo "${file##*.}"; }

for f in "${wavs[@]}"; do
  if [ $type == "db" ]; then
    value=`${scriptdir}/peak_dB.sh --nocr --start "$start_in_seconds" --duration "$duration_in_seconds" "$f"`db
  elif [ $type == "freq" ]; then
    value=`${scriptdir}/freq.sh --nocr --start "$start_in_seconds" --duration "$duration_in_seconds" "$f"`
  elif [[ $type == "lvl" || $type == "level" ]]; then
    value=`${scriptdir}/max_lvl.sh --nocr --start "$start_in_seconds" --duration "$duration_in_seconds" "$f"`
  fi

  #f_new=`echo "$f" | sed -E "s/(\s+-\s+)?([.0-9]+)?(\.[^.]+)$/\1\2\1${value}\3/g"` # rename with peak level
  f_new=`echo "$f" | sed -E "s/(\s+-\s+)?([.0-9]+)?(\.[^.]+)$/\1${value}\3/g"` # rename with peak level
  outfileext=".$(filepath_ext "${f_new}")"
  outfilename="$(filepath_name "${f_new}")"

  #outpath=`echo "$f_new" | sed -E "s/([^/]+)$//g" | sed -E "s/\/$//g"` # use all of infile's path ("src/SD/SD.wav" to "src/SD")
  outpath=`echo "$f_new" | sed -E "s/([^/]+)$//g" | sed -E "s/\/$//g" | sed -E "s/^.*\///g"` # use infile's parent dirname only ("src/SD/SD.wav" to "SD")

  # if only one directory (when full path == parent dir)  (e.g. "src/file.wav" parent dir is "src")
  fullpath=`echo "$f_new" | sed -E "s/\/?([^/]+)$//g"`
  if [ "$outpath" == "$fullpath" ]; then
    outpath="."
  fi

  echo "Rename ($type) $f -> $dest_dir/$outpath/$outfilename$outfileext"
  mkdir -p "./$dest_dir/$outpath"
  cp "$f" "./$dest_dir/$outpath/$outfilename$outfileext"
done



