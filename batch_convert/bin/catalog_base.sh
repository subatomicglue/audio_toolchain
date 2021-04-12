#!/bin/bash

######################################################################
if [ -z ${actions+"bok"} ]; then
  echo "STOP!  this is meant to be "included" sourced into other scripts."
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

args=()
VERBOSE=true
GEN=false
FORCE=false
TMPDIR="$HOME/Downloads"

################################
# scan command line args:
function usage
{
  echo "Music Catalog - subatomiclabs"
  echo "$0 maintain a music catalog.  convert an album folders to mp3/flac/ogg/m4a for distribution"
  echo "delete the dest directory to regenerate"
  echo ""
  echo "Usage:"
  echo "  $0               (default: list catalog)"
  echo "  $0 --help        (this help)"
  echo "  $0 --verbose     (output verbose information)"
  echo "  $0 --gen         (generate encoded catalog)"
  echo "  $0 --force       (force regenerate)"
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

echo "=================================="
echo "Music Catalog - subatomiclabs"
echo "=================================="
TMPDIR="${TMPDIR}/__subatomic_encode"  # we will delete this dir later.

function sanitycheck
{
  local SRC=$1
  local DEST=$2
  local action=$3

  # protect our valuable data:
  if [[ "$action" == "" ]]; then
    echo "[ABORT]  Your action is empty, check the actions array:\n   \"$action\""
    exit -1
  fi
  if [[ "$SRC" == "$DEST" ]]; then
    echo "[ABORT]  SCARY! SRC == DEST.  We could have deleted/corrupted your SOURCE!\n   \"$SRC\" == \"$DEST\""
    exit -1
  fi

  if [[ ! -d "$SRC" ]]; then
    echo "[ABORT]  Your source dir doesn't exist:\n   \"$SRC\""
    exit -1
  fi
  local parent="$(dirname "$DEST")"
  if [[ ! -d "$parent" ]]; then
    echo "[ABORT]  Parent dir '$parent' doesn't exist!  (is it mounted?)\n     => We're trying to copy '$SRC' to '$DEST'\n   \"$action\""
    exit -1
  fi

  if [[ "$SRC" == "" ]]; then
    echo "[ABORT]  Your src dir is empty, check the action:\n   \"$action\""
    exit -1
  fi
  if [[ "$DEST" == "" ]]; then
    echo "[ABORT]  Your dest dir is empty, check the action:\n   \"$action\""
    exit -1
  fi
}


# when forcing, clean DEST dirs out
if [[ $GEN == true && $FORCE == true ]]; then
  for action in "${actions[@]}"
  do
    #echo "action string:  '$action'"
    CMD=`echo "$action" | cut -d ";" -f 1`
    SRC=`echo "$action" | cut -d ";" -f 2`
    DEST=`echo "$action" | cut -d ";" -f 3`

    sanitycheck "$SRC" "$DEST" "$action"

    # if the destination exists
    #if [[ -d "$DEST" ]]; then  # breaks because -mp3 -m4a, etc...
      # remove...
      if [[ "$CMD" == "convert" && $FORCE == true ]]; then
        echo ""
        echo "removing '$DEST-[mp3|flac|ogg|m4a|mp3-shortnames]'"
        cmd="rm -r \"$DEST-mp3\" \"$DEST-flac\" \"$DEST-ogg\" \"$DEST-m4a\" \"$DEST-mp3-shortnames\""
        echo "$cmd"
        [ "$key" != "s" ] && read -rsp $'Look ok?  Press any key to DELETE THIS DATA... (s to skip this prompt)\n' -n1 key
        eval $cmd
      fi
      if [[ "$CMD" == "copy" && $FORCE == true && -d "$DEST" ]]; then
        echo ""
        echo "removing '$DEST'"
        cmd="rm -r \"$DEST\""
        echo "$cmd"
        [ "$key" != "s" ] && read -rsp $'Look ok?  Press any key to DELETE THIS DATA... (s to skip this prompt)\n' -n1 key
        eval $cmd
      fi
    #fi
  done
fi

# run the jobs
[ ! -d "$DSTDIR" ] && echo "Creating directory: $DSTDIR" && mkdir -p "$DSTDIR"
[ ! -d "$TMPDIR" ] && echo "Creating directory: $TMPDIR" && mkdir -p "$TMPDIR"
for action in "${actions[@]}"
do
  #echo "action string:  '$action'"
  CMD=`echo "$action" | cut -d ";" -f 1`
  SRC=`echo "$action" | cut -d ";" -f 2`
  DEST=`echo "$action" | cut -d ";" -f 3`
  PREFIX=`echo "$DEST" | sed -e "s/^.\+\///"`
  DEST_NO_PREFIX=`echo "$DEST" | sed -e "s/\/[^/]\+$//"`

  sanitycheck "$SRC" "$DEST" "$action"

  echo "[ACTION] cmd:'$CMD' src:'$SRC' dst:'$DEST'"
  [[ $GEN == true && "$CMD" == "convert" ]] && [[ ! -d "$DEST-m4a" ]] && mkdir -p "$DEST_NO_PREFIX" && echo "Pulling src data to ${TMPDIR}/${PREFIX}-wav" && cp -r "$SRC" "${TMPDIR}/${PREFIX}-wav" && "$SCRIPTDIR/convert.sh" "${TMPDIR}/${PREFIX}-wav" "${TMPDIR}/$PREFIX" && echo "Removing temporary wav data from ${TMPDIR}/${PREFIX}-wav" && rm -rf "${TMPDIR}/${PREFIX}-wav" && echo "Moving data from $TMPDIR/${PREFIX}-* to $DEST_NO_PREFIX/" && mv "${TMPDIR}/${PREFIX}-"* "$DEST_NO_PREFIX/"
  [[ $GEN == true && "$CMD" == "copy" ]] && [[ ! -d "$DEST" ]] && echo "copying $SRC to $DEST" && cp -r "$SRC" "$DEST"
done

[ $GEN == false ] && echo "use --gen to run the jobs above (generates encoded files)"
[[ $GEN == true && $FORCE == false ]] && echo "use --force to clean out destinations, before running jobs"
rm -rf "$TMPDIR"

