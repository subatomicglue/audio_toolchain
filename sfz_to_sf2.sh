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
  echo "$scriptname output the rough frequency found in the audio file"
  echo "Usage: "
  echo "  $scriptname               (default)"
  echo "  $scriptname --help        (this help)"
  echo "  $scriptname --verbose     (output verbose information)"
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
  if [[ $ARGC -ge 1 && ${ARGV[$i]:0:2} == "--" ]]; then
    echo "Unknown option ${ARGV[$i]}"
    exit -1
  fi

  args+=("${ARGV[$i]}")
  $VERBOSE && echo "Parsing Args: \"${ARGV[$i]}\""
done
################################

function filepath_path { local file=$1; echo `dirname -- "${file}"`; }
function filepath_name { local file=$1; echo `basename -- "${file%.*}"`; }
function filepath_ext { local file=$1; echo "${file##*.}"; }

function do_conversion {
  local infile="$1"
  local base_dir="$2"
  local outfile="$base_dir/$(filepath_name "${infile}")"

  if [ ! -f "$outfile" ]; then
    echo "======================================================================"
    echo "Converting \"$infile\" to \"$outfile.sf2\" (thanks polyphone!)"
    /Applications/polyphone-2.2.app/Contents/MacOS/polyphone -1 -i "$infile" -d . -o "$outfile"
  else
    echo "Skipping \"$infile\" to \"$outfile\" (exists)"
  fi
}

for arg in "${args[@]}"; do
  infile="$arg"
  if [ -d "$infile" ]; then
    echo "[$scriptname] recursing into directory: \"$infile\""
    find "$infile" -type f -name "*.sfz" | while read f; do
      do_conversion "$f" "$infile"
    done
  elif [ -f "$infile" ]; then
    do_conversion "$infile" "$(filepath_path "${infile}")"
  fi
done

