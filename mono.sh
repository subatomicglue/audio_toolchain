#!/bin/sh

# this script's dir (and location of the other tools)
scriptpath=$0
scriptname=`basename "$0"`
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cwd=`pwd`

# options:
dest_dir="mono"        # CAUTION we DELETE this dir! (unique name here)
wavs=()
VERBOSE=false
mix="left"  # left, right, mix

################################
# scan command line args:
function usage
{
  echo "$scriptname make audio files mono"
  echo "Usage: "
  echo "  $scriptname <wav files>   (list of wav files to rename, copying to '$dest_dir/')"
  echo "  $scriptname --help        (this help)"
  echo "  $scriptname --verbose     (output verbose information)"
  echo "  $scriptname --mix         (left, right or mix. default $mix)"
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
  if [[ $ARGC -ge 1 && ${ARGV[$i]} == "--mix" ]]; then
    ((i+=1))
    mix=${ARGV[$i]}
    $VERBOSE && echo "Parsing Args: Changing mix to $level"
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


#rm -fr "./$dest_dir"
mkdir -p "./$dest_dir"

function filepath_path { local file=$1; echo `dirname -- "${file}"`; }
function filepath_name { local file=$1; echo `basename -- "${file%.*}"`; }
function filepath_ext { local file=$1; echo "${file##*.}"; }

for f in "${wavs[@]}"; do
  if [ ! -f "$f" ]; then
    echo "$0: \"$f\" not found"
    continue
  fi
  f_new=`echo "$f" | sed -E "s/(\s+-\s+[0-9]+\.[0-9]+)?(\.[^.]+)$/\2/g"`
  outfileext=".$(filepath_ext "${f_new}")"
  outfilename="$(filepath_name "${f_new}")"

  #outpath=`echo "$f_new" | sed -E "s/([^/]+)$//g" | sed -E "s/\/$//g"` # use all of infile's path ("src/SD/SD.wav" to "src/SD")
  outpath=`echo "$f_new" | sed -E "s/([^/]+)$//g" | sed -E "s/\/$//g" | sed -E "s/^.*\///g"` # use infile's parent dirname only ("src/SD/SD.wav" to "SD")

  # if only one directory (when full path == parent dir)  (e.g. "src/file.wav" parent dir is "src")
  fullpath=`echo "$f_new" | sed -E "s/\/?([^/]+)$//g"`
  if [ "$outpath" == "$fullpath" ]; then
    outpath="."
  fi

  echo "Mono \"$f\" -> \"$dest_dir/$outpath/$outfilename$outfileext\""
  mkdir -p "./$dest_dir/$outpath"
  if [ $mix == "left" ]; then
    sox "$f" "./$dest_dir/$outpath/$outfilename$outfileext" remix 1
  elif [ $mix == "right" ]; then
    sox "$f" "./$dest_dir/$outpath/$outfilename$outfileext" remix 2
  elif [ $mix == "mix" ]; then
    sox "$f" "./$dest_dir/$outpath/$outfilename$outfileext" remix 1,2
  fi
done



