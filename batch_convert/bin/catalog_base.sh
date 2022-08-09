#!/bin/bash

######################################################################
if [ -z ${actions+"bok"} ]; then
  echo "STOP!  this is meant to be \"included\" sourced into other scripts."
  echo "example script (e.g. catalog.sh):"
  echo ''
  echo 'SRCDIR="<path-to>/subatomicglue/wav"'
  echo 'DSTDIR="<path-to>/subatomicglue/wav_generated"'
  echo 'SCRIPTDIR="'`pwd`'" # TODO: use $HOME instead of hardcoding'
  echo ''
  echo '# add jobs here:'
  echo 'actions=('
  echo '  "convert;$SRCDIR/inertialdecay;$DSTDIR/inertialdecay'
  echo '  "copy;$SRCDIR/clips-mp3;$DSTDIR/clips-mp3'
  echo ')'
  echo ''
  echo 'source "$SCRIPTDIR/catalog_base.sh"'
  exit -1
fi
######################################################################


# this script's dir (and location of the other tools)
scriptpath=$0
scriptname=`basename "$0"`
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cwd=`pwd`

# options:
args=()
VERBOSE=true
GEN=false
FORCE=false
TMPDIR="$HOME/Downloads" # the base of the tmp dir, set via comand line, with "/__subatomic_encode" appended

function cleanup {
  # sanity check we're only deleting our special __subatomic_encode tmp dir
  if [[ `basename $TMPDIR` == "__subatomic_encode" && -d "$TMPDIR" ]]; then
    echo "cleaning up tmp: $TMPDIR"
    rm -rf "$TMPDIR"
  fi
}
sig_handler_activated=0
function sig_handler {
  if [ "$sig_handler_activated" == "0" ]; then
    sig_handler_activated=1
    echo "CTRL-C detected..."
    exit 0 # exit triggers the EXIT handler which calls cleanup
  fi
  echo "CTRL-C detected... (we heard you)"
}

trap sig_handler SIGINT
trap cleanup EXIT

################################
# scan command line args:
function usage
{
  echo "Music Catalog - subatomiclabs"
  echo "$scriptname - maintain a music catalog.  convert an album folders to mp3/flac/ogg/m4a for distribution"
  echo "delete the dest directory to regenerate"
  echo ""
  echo "Usage:"
  echo "  $scriptname               (default: list catalog)"
  echo "  $scriptname --help        (this help)"
  echo "  $scriptname --verbose     (output verbose information)"
  echo "  $scriptname --gen         (generate encoded catalog)"
  echo "  $scriptname --force       (force regenerate)"
  echo ""
}
ARGC=$#
ARGV=("$@")
non_flag_args=0
non_flag_args_required=0
for ((i = 0; i < ARGC; i++)); do
  if [[ $ARGC -ge 1 && ${ARGV[$i]} == "--help" ]]; then
    usage
    exit -1
  fi
  if [[ $ARGC -ge 1 && ${ARGV[$i]} == "--verbose" ]]; then
    VERBOSE=true
    continue
  fi
  if [[ $ARGC -ge 1 && ${ARGV[$i]} == "--gen" ]]; then
    GEN=true
    continue
  fi
  if [[ $ARGC -ge 1 && ${ARGV[$i]} == "--force" ]]; then
    FORCE=true
    continue
  fi
  if [[ $ARGC -ge 1 && ${ARGV[$i]} == "--tmp" ]]; then
    ((i+=1))
    TMPDIR=${ARGV[$i]}
    continue
  fi
  if [[ $ARGC -ge 1 && ${ARGV[$i]:0:2} == "--" ]]; then
    echo "Unknown option ${ARGV[$i]}"
    exit -1
  fi

  args+=("${ARGV[$i]}")
  $VERBOSE && echo "Parsing Args: \"${ARGV[$i]}\""
  ((non_flag_args+=1))

  # non switch args:
  if [ $non_flag_args -eq 1 ]; then
    INDIR=${ARGV[$i]}
    $VERBOSE && echo "Parsing Args: Changing input directory to '$INDIR'"
  fi
  if [ $non_flag_args -eq 2 ]; then
    OUTDIR=${ARGV[$i]}
    if [[ $OUTDIR == "." || $OUTDIR == ".." ]]; then
      OUTDIR="out"
    fi
    $VERBOSE && echo "Parsing Args: Changing out dir prefix to '$OUTDIR'"
  fi
done

# output help if they're getting it wrong...
if [ $non_flag_args_required -ne 0 ] && [[ $ARGC -eq 0 || ! $ARGC -ge $non_flag_args_required ]]; then
  [ $ARGC -gt 0 ] && echo "Expected $non_flag_args_required args, but only got $ARGC"
  usage
  exit -1
fi
################################

CALLER=$0

echo "=================================="
echo "Music Catalog - subatomiclabs"
echo "=================================="
echo "('$CALLER' calling '$SCRIPTDIR/catalog_base.sh')"
echo ""
TMPDIR="${TMPDIR}/__subatomic_encode"  # we will delete this dir later.

function sanitycheck
{
  local SRC=$1
  local DEST=$2
  local action=$3

  local SAN_INFO=""
  if [ $GEN == false ]; then
    SAN_INFO="(in read-only mode, use --gen to write)..."
  fi
  echo "Sanity Checking $SAN_INFO"

  # protect our valuable data:
  if [[ "$action" == "" ]]; then
    echo "[ABORT]  Your action is empty, check the actions array:"
    echo "    \"$action\""
    exit -1
  fi
  if [[ "$SRC" == "$DEST" ]]; then
    echo "[ABORT]  SCARY! SRC == DEST.  We could have deleted/corrupted your SOURCE!"
    echo "    \"$SRC\" == \"$DEST\""
    exit -1
  fi

  if [[ ! -d "$SRC" ]]; then
    echo "[ABORT]  Your source dir doesn't exist:"
    echo "    \"$SRC\""
    exit -1
  fi

  if [[ "$SRC" == "" ]]; then
    echo "[ABORT]  Your src dir is empty, check the action:"
    echo "    \"$action\""
    exit -1
  fi
  if [[ "$DEST" == "" ]]; then
    echo "[ABORT]  Your dest dir is empty, check the action:"
    echo "    \"$action\""
    exit -1
  fi

  # keep this last...  want the others to get checked before this tells the user to "just use --gen"...
  local parent="$(dirname "$DEST")"
  if [[ ! -d "$parent" ]]; then
    echo "[ABORT]  Your destination dir '$parent' doesn't exist!  (is it mounted?)"
    echo "=> While trying to copy '$SRC' to '$DEST'"
    echo ""
    echo "=> in [$CALLER] action: \"$action\""
    echo ""
    echo "=> Try using --gen to create  '$parent'"
    exit -1
  fi

  echo "Sanity Checking... looks good!"
  echo ""
}


# when forcing, clean DEST dirs out
if [[ $GEN == true && $FORCE == true ]]; then
  for action in "${actions[@]}"
  do
    #echo "action string:  '$action'"
    CMD=`echo "$action" | cut -d ";" -f 1`
    SRC=`echo "$action" | cut -d ";" -f 2`
    DEST=`echo "$action" | cut -d ";" -f 3`

    # dest may not even exist... which is fine
    if [ -d "$DEST" ]; then
      sanitycheck "$SRC" "$DEST" "$action"
    fi

    # if the destination exists
    #if [[ -d "$DEST" ]]; then  # breaks because -mp3 -m4a, etc...
      # remove...
      if [[ "$CMD" == "convert" && $FORCE == true ]]; then
        echo ""
        echo "removing '$DEST-[mp3|flac|ogg|m4a|mp4|mp3-shortnames]'"
        cmd="rm -rf \"$DEST-mp3\" \"$DEST-flac\" \"$DEST-ogg\" \"$DEST-m4a\" \"$DEST-mp4\" \"$DEST-mp3-shortnames\""
        echo "$cmd"
        [ "$key" != "s" ] && read -rsp $'Look ok?  Press any key to DELETE THIS DATA... (s to skip this prompt)\n' -n1 key
        eval $cmd
      fi
      if [[ "$CMD" == "copy" && $FORCE == true && -d "$DEST" ]]; then
        echo ""
        echo "removing '$DEST'"
        cmd="rm -rf \"$DEST\""
        echo "$cmd"
        [ "$key" != "s" ] && read -rsp $'Look ok?  Press any key to DELETE THIS DATA... (s to skip this prompt)\n' -n1 key
        eval $cmd
      fi
    #fi
  done
fi

# run the jobs
[[ $GEN == true && ! -d "$DSTDIR" ]] && echo "Creating directory: $DSTDIR" && mkdir -p "$DSTDIR"
[[ $GEN == true && ! -d "$TMPDIR" ]] && echo "Creating directory: $TMPDIR" && mkdir -p "$TMPDIR"
for action in "${actions[@]}"
do
  #echo "action string:  '$action'"
  CMD=`echo "$action" | cut -d ";" -f 1`
  SRC=`echo "$action" | cut -d ";" -f 2`
  DEST=`echo "$action" | cut -d ";" -f 3`
  PREFIX=`echo "$DEST" | sed -e "s/^.\+\///"`
  DEST_NO_PREFIX=`echo "$DEST" | sed -e "s/\/[^/]\+$//"`

  DEST_parent="$(dirname "$DEST")"
  [[ $GEN == true && ! -d "$DEST_parent" ]] && echo "Creating directory: $DEST_parent" && mkdir -p "$DEST_parent"

  echo ""
  echo "[ACTION] cmd:'$CMD' src:'$SRC' dst:'$DEST'"
  sanitycheck "$SRC" "$DEST" "$action"

  # [convert] CONVERT WAV TO COMPRESSED FORMATS
  if [[ $GEN == true && "$CMD" == "convert" ]]; then
    DO_ONCE=1
    echo "[[[[-----=  CONVERT [$PREFIX]  =-----]]]]"
    mkdir -p "$DEST_NO_PREFIX" || continue
    for type in "mp4" "m4a" "mp3" "ogg" "flac"; do
      if [ ! -d "$DEST_NO_PREFIX/${PREFIX}-$type" ]; then
        if [ $DO_ONCE -eq 1 ]; then
          echo "[$type] Pulling src data to ${TMPDIR}/${PREFIX}-wav"
          rsync -a --info=progress2 "$SRC/" "${TMPDIR}/${PREFIX}-wav" --exclude='backup*' || continue
          DO_ONCE=0
        fi
        "$SCRIPTDIR/convert.sh" "${TMPDIR}/${PREFIX}-wav" "${TMPDIR}/$PREFIX" $type || continue
        if [ $type == "mp3" ]; then
          "$SCRIPTDIR/rename_audiotrack_to_shortnames.pl" "${TMPDIR}/$PREFIX-mp3" "${TMPDIR}/$PREFIX-mp3-shortnames" || continue
        fi
      else
        echo "[$DEST_NO_PREFIX/${PREFIX}-$type] Exists, skipping"
      fi
    done
    if [ -d "${TMPDIR}/${PREFIX}-wav" ]; then
      echo "Removing temporary wav data from ${TMPDIR}/${PREFIX}-wav"
      rm -rf "${TMPDIR}/${PREFIX}-wav"
      echo "Moving data from $TMPDIR/${PREFIX}-* to $DEST_NO_PREFIX/"
      rsync -a --info=progress2 "${TMPDIR}/${PREFIX}-"* "$DEST_NO_PREFIX/" || continue
      #mv "${TMPDIR}/${PREFIX}-"* "$DEST_NO_PREFIX/"
    fi
  fi

  # [copy] COPY DIR
  #FYI: some methods to copy:
  #cp -r "$SRC" "$DEST"                                           # copy it all
  #rsync -a  --info=progress2 "$SRC/" "$DEST" --exclude='backup*'  # exclude backup dirs, show overall progress
  #rsync -av --info=progress2 "$SRC/" "$DEST" --exclude='backup*'  # exclude backup dirs, show progress for each file
  [[ $GEN == true && "$CMD" == "copy" ]] && [[ ! -d "$DEST" ]] && \
    echo "[[[[-----=  COPY [$SRC to $DEST]  =-----]]]]" && \
    rsync -a --info=progress2 "$SRC/" "$DEST" --exclude='backup*'
done

[ $GEN == false ] && echo "Source Locations All Verified!"
[ $GEN == false ] && echo "use --gen to run the jobs above (generates encoded files)"
[[ $GEN == true && $FORCE == false ]] && echo "use --force to clean out destinations, before running jobs"

