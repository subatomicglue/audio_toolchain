#!/bin/sh
# this script's dir (and location of the other tools)
scriptpath=$0
scriptname=`basename "$0"`
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cwd=`pwd`

# options:
args=()
VERBOSE=false

################################
# scan command line args:
function usage
{
  echo "$scriptname   use polyphone to convert .sf2 files to _sfz directories"
  echo "Usage: "
  echo "  $scriptname <in1...inN>   (in files: e.g. ./drumkit.sf2)"
  echo "  $scriptname --help        (this help)"
  echo "  $scriptname --verbose     (output verbose information)"
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
  if [[ $ARGC -ge 1 && ${ARGV[$i]:0:2} == "--" ]]; then
    echo "Unknown option ${ARGV[$i]}"
    exit -1
  fi

  args+=("${ARGV[$i]}")
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

function filepath_path { local file=$1; echo `dirname -- "${file}"`; }
function filepath_name { local file=$1; echo `basename -- "${file%.*}"`; }
function filepath_ext { local file=$1; echo "${file##*.}"; }

function do_conversion {
  local infile="$1"
  local base_dir="$2"
  #outfile="./$(echo "$(filepath_path "$infile")/$(filepath_name "$infile")" | sed "s/^$base_dir//")_sfz"
  local outfile=".$(filepath_path "${infile#$base_dir}")/$(filepath_name "${infile#$base_dir}")_sfz"
  #echo "splitting=========================================================="
  #echo "in:   \"$infile\""
  #echo "base: \"$base_dir\""
  #echo "   -> \"$outfile\""
  #echo "hello \"$infile\" to \"$outfile\""
  #exit -1

  if [ ! -d "$outfile" ]; then
    echo "==================================================="
    echo "Converting \"$infile\" to \"$outfile\" (thanks polyphone!)"
    mkdir -p "$(filepath_path "${outfile}")"
    /Applications/polyphone-2.2.app/Contents/MacOS/polyphone -3 -i "$infile" -d . -o "${outfile}"
  else
    #infile_date=$(date -r "${infile}" "+%Y%m%d_%H_%M_%S")
    #outfile_date=$(date -r "${outfile}" "+%Y%m%d_%H_%M_%S")
    #if [ "${infile_date}" != "${outfile_date}" ]; then
    #  echo "Skipping, but Timestamps differ! \"$infile\" to \"$outfile\" (exists)"
    #else
      echo "Skipping \"$infile\" to \"$outfile\" (exists)"
    #fi
  fi
}


function go {
  for arg in "${args[@]}"; do
    local infile="$arg"
    if [ -d "$infile" ]; then
      echo "recursing into $infile"
      find "$infile" -type f -name "*.sf2" | while read f; do
        do_conversion "$f" "$infile"
      done
    elif [ -f "$infile" ]; then
      do_conversion "$infile" $(pwd)
    fi

  done;
}

go

