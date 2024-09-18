#!/bin/bash

###################################################################################################################################
#### Bash functions to extend the "sox" command line audio api:
####
#### What's sox?
####    sox is an audio processing utility for the command line (similar to: magick/ImageMagick for Images; ffmpeg for Video...)
####
#### All bash functions prefix with "sox_" in order to extend the sox command line api with some useful wrapper scripts.
#### Of course, some of the more advanced functionality couldn't be done with sox...  and requires ffmpeg or other utilities.
###################################################################################################################################

######################################################################
# STOP!  this is meant to be \"included\" sourced into other scripts
# how to include  (e.g. into your .bashrc):
#
# source "'$SCRIPTDIR'/functions.sh"
######################################################################



# get parts of the filepath
# bok=`filepath_path ../bok.m4a`
# echo $bok
function filepath_path { local file=$1; echo `dirname -- "${file}"`; }
function filepath_name { local file=$1; echo `basename -- "${file%.*}"`; }
function filepath_ext { local file=$1; echo "${file##*.}"; }



function sox_split_wav_by_labeltrack
{
  if [[ "$#" -lt 3 ]]; then
    echo "Usage:"
    echo "  ${FUNCNAME[0]} <Audacity Label Track> <audio wav file to split> <destination folder>"
    echo "Example:"
    echo "  ${FUNCNAME[0]} \"Label Track.txt\" \"audio.wav\" \"out/\""
    echo ""
    echo "Notes:"
    echo "  \"Label Track.txt\" is a tab delimited file:"
    echo "  <starttime>\\t<endtime>\\t<label name>"
    echo ""
    echo "Example \"Label Track.txt\":"
    echo "3.486461	36.077288	superczar temple"
    echo "37.176281	74.921007	tow the line"
    echo "5573.508857	6014.228181	the impending weekend"
    echo ""
    echo "Instructions:"
    echo '1. open "audio.wav" in Audacity'
    echo '2. add labels'
    echo '3. export labels from Audacity'
    echo '4. sox_split_wav_by_labeltrack "Label Track.txt" "audio.wav" "out/"'
    return
  fi

  local input="$1"
  local wav="$2"
  local dest="$3"
  local line="--"
  local count=1
  local VERBOSE=0

  if [ -d "$dest" ]; then
    echo "Destination \"$dest\" exists, remove or move it out of the way"
    echo "   rm -r \"$dest\""
    return -1
  fi
  mkdir -p "$dest"

  echo "Opening $input"
  echo "Slicing \"$wav\" to \"$dest/\""
  while IFS= read -r line
  do
    # fortunately it's a tab delimited file.
    local A=$(awk -F'\t' '{print $1}' <<< "$line")
    local B=$(awk -F'\t' '{print $2}' <<< "$line")
    local C=$(awk -F'\t' '{print $3}' <<< "$line")
    local out_filename="$dest/$(printf "%02d" $count) - $C.wav"
    [ "$VERBOSE" == 1 ] && echo "================================================================"
    [ "$VERBOSE" == 1 ] && echo "start:[$A] end:[$B] name:\"$C\"  :=-"
    local cmd="sox \"$wav\" \"$out_filename\" trim \"$A\" \$(bc -l <<< \"$B - $A\")"
    [ "$VERBOSE" == 1 ] && echo "$cmd"
    echo " - \"$out_filename\""
    eval "$cmd"
    #echo "$line"
    let "count+=1"
  done < "$input"
}


function sox_speed {
  if [[ "$#" -lt 2 ]]; then
    echo "Usage:"
    echo "  ${FUNCNAME[0]} <speed multiplier> <infile.wav>"
    echo "Example:"
    echo "  ${FUNCNAME[0]} 0.8  infile.wav"
    echo "  ${FUNCNAME[0]} 1.25 *.wav"
    return
  fi
  local SPEED="$1"
  local re='^[0-9.]+$'
  if ! [[ $SPEED =~ $re ]] ; then
    echo "error: Speed '$SPEED' must be a number" >&2; return -1
  fi
  echo "Changing speed to $SPEED"
  local ARGV=("$@")
  for file in "${ARGV[@]:1}"; do
    local FILENAME=`filepath_name "$file"`
    local FILEEXT=`filepath_ext "$file"`
    local OUTFILE="$FILENAME.$FILEEXT"
    if [ "$file" != "$OUTFILE" ]; then
      echo ""
      echo "Processing ${SPEED}x: '$file' => './$OUTFILE'"
      #echo sox "$file" "$OUTFILE" speed "$SPEED"
      sox "$file" "./$OUTFILE" speed "$SPEED"
    else
      echo "SKIPPING: Output cannot be the same as the input: './$OUTFILE' (try from a different directory than '$file')"
    fi
  done
}


# these are prefixed with sox, but sox doesn't support m4a, so we use other tools when m4a detected...

function sox_convert_to_wav
{
  if [[ "$#" -lt 1 ]]; then
    echo "${FUNCNAME[0]} <audio file1> ... <audio filen>"
    return
  fi
  for file in "$@"; do
    local FILENAME=`filepath_name "$file"`
    if [[ "m4a" == `filepath_ext "$file"` || "mp4" == `filepath_ext "$file"` ]]; then
      echo "Converting to wav:  \"./$FILENAME.wav\"    (using ffmpeg for m4a and mp4)"
      #faad -o "$file.wav" "$file"     # brew install faad2
      ffmpeg -i "$file" "./$FILENAME.wav"   # brew install ffmpeg
    else
      echo "Converting to wav:  \"./$FILENAME.wav\""
      sox "$file" "./$FILENAME.wav"
    fi
  done
}
function sox_convert_to_m4a
{
  if [[ "$#" -lt 1 ]]; then
    echo "${FUNCNAME[0]} <audio file1> ... <audio filen>"
    return
  fi
  for file in "$@"; do
    local FILENAME=`filepath_name "$file"`
    if [ "wav" == `filepath_ext "$file"` ]; then
      echo "Converting to m4a:  \"./$FILENAME.m4a\"    (using ffmpeg for m4a)"
      ffmpeg -i "$file" "./$FILENAME.m4a"   # brew install ffmpeg
    else
      echo "Not in wav format:  \"$file\"  (use sox_convert_to_wav first)"
    fi
  done
}

function sox_convert_ALAC_to_m4a
{
  if [[ "$#" -lt 1 ]]; then
    echo "Convert ALAC (Apple Lossless) encoded files to AAC encoded .m4a files"
    echo "We'll try to preserve album art, tags, etc, when possible"
    echo "We'll use the highest bitrate"
    echo "${FUNCNAME[0]} <audio file1> ... <audio filen>"
    return
  fi
  for file in "$@"; do
    local FILENAME=`filepath_name "$file"`
    local FILEEXT=`filepath_ext "$file"`
    ffmpeg -i "$file" 2>&1 | grep alac > /dev/null
    local is_alac=$?
    if [ $is_alac -eq 0 ]; then
      #echo "[INFO] ALAC stream detected \"$FILENAME.$FILEEXT\""
      if [[ "m4a" == "$FILEEXT" ]] || [[ "aac" == "$FILEEXT" ]]; then
        if [ ! -f "./$FILENAME.m4a" ]; then
          echo ""
          echo "Converting to m4a:  \"./$FILENAME.m4a\"    (using ffmpeg for m4a)"
          ffmpeg -h encoder=libfdk_aac 2>&1 | grep Encoder > /dev/null # fraunhofer encoder may not be present in your ffmpeg build
          local has_fraunhofer=$?
          ffmpeg -h encoder=aac_at 2>&1 | grep Encoder > /dev/null # check for the AudioToolbox (afconvert, apple's encoder) availability on MacOS
          local has_afconvert=$?
          if [ $has_afconvert -eq 0 ]; then
            echo "[INFO] Using ffmpeg (aac_at: AudioToolbox, apple's encoder used in afconvert/iTunes/etc)"
            # Using afconvert: https://developer.apple.com/library/archive/technotes/tn2271/_index.html
            # ffmpeg -h encoder=aac_at # for help
            ffmpeg -hide_banner -loglevel info -stats -i "$file" -c:v copy -c:a aac_at -b:a 320k -aac_at_mode vbr -aac_at_quality 0 "./$FILENAME.m4a"
          elif [ $has_fraunhofer -eq 0 ]; then
            echo "[INFO] Using ffmpeg (libfdk_aac: fraunhofer's encoder)"
            ffmpeg -hide_banner -loglevel info -stats -i "$file" -c:v copy -c:a libfdk_aac -b:a 320k "./$FILENAME.m4a"
          else
            echo "[INFO] Using ffmpeg (aac: ffmpeg's encoder)"
            # strip the art:
            #ffmpeg -i "$file" -vn -c:a aac -b:a 320k "./$FILENAME.m4a"

            # preserve the art:
            ffmpeg -hide_banner -loglevel info -stats -i "$file" -c:v copy -c:a aac -b:a 320k "./$FILENAME.m4a"

            # best quality (apple's own converter), does NOT copy tags or art
            #afconvert -v -f m4af -d aac -b 192000 -q 127 -s 2 "$file" "./$FILENAME.m4a"
          fi
        else
          echo "[ERROR] Move ./$FILENAME.m4a away, or change to an empty directory to write to ./$FILENAME.m4a"
          echo "[HINT]    rm \"./$FILENAME.m4a\"";
        fi
      else
        echo "[WARNING] Skipping.  Not in m4a or aac format:  \"$file\""
      fi
    else
      echo "[WARNING] No ALAC streams found in \"$file\""
    fi
  done
}

function sox_remux_mp3 {
  if [[ "$#" -lt 1 ]]; then
    echo "${FUNCNAME[0]} <audio file1> ... <audio filen>"
    return
  fi
  file="$1"

  if [ "mp3" == `filepath_ext "$file"` ]; then
    local FILENAME=`filepath_name "$file"`
    if [ ! -f "$FILENAME.mp3" ]; then
      # strip the art:
      #ffmpeg -vn -i "$file" -c:a copy "$FILENAME.mp3"
      # preserve the art:
      ffmpeg -i "$file" -c:a copy -c:v copy "$FILENAME.mp3"
    else
      echo "[ERROR] Move $FILENAME.mp3 away, we will need to write to it..."
    fi
  else
      echo "[WARNING] Skipping, only works with mp3 files..."
  fi
}


function sox_convert_to_mp4
{
  if [[ "$#" -lt 1 ]]; then
    echo "${FUNCNAME[0]} <audio file1> ... <audio filen>"
    return
  fi
  local DEFAULT_LOGO="$HOME/Google Drive/FabLab/Mantis/custom-logo/color-hires.png"
  local CWD=`pwd`
  if [ -f "$CWD/logo.png" ]; then
    DEFAULT_LOGO="$CWD/logo.png"
  fi
  if [ -f "$CWD/logo.jpg" ]; then
    DEFAULT_LOGO="$CWD/logo.jpg"
  fi
  echo "Changing Logo: '$DEFAULT_LOGO'" # announce we've changed the logo

  # scan arguments.
  for file in "$@"; do
    if [[ "png" == `filepath_ext "$file"` ]] || [[ "jpg" == `filepath_ext "$file"` ]]; then
      DEFAULT_LOGO="$file"
      echo "Changing Logo: '$DEFAULT_LOGO'" # announce we've changed the logo
    else
      local FILENAME=`filepath_name "$file"`
      echo "Converting "`filepath_ext "$file"`" to mp4:  \"./$FILENAME.mp4\"    (using ffmpeg for mp4)"

      # Generate a png from the logo, since ffmpeg options below only works with png
      local TMP_LOGO="/tmp/asjdklflauiowqrn43758734825974385723489.png"
      if [ ! -f "$DEFAULT_LOGO" ]; then
        echo "[WARNING] '$DEFAULT_LOGO' Not found, Generating a Black Image to use..."
        convert -size 1920x1080 xc:black "$TMP_LOGO"
        DEFAULT_LOGO="$TMP_LOGO"
        echo "Changing Logo: '$DEFAULT_LOGO'" # announce we've changed the logo
      elif [ "png" == `filepath_ext "$DEFAULT_LOGO"` ]; then
        cp "$DEFAULT_LOGO" "$TMP_LOGO"
      else
        magick convert "$DEFAULT_LOGO" "$TMP_LOGO"
      fi

      # Calculate video and logo sizes to use in ffmpeg options below
      local VIDEO_WIDTH=1920
      local VIDEO_HEIGHT=1080
      local VIDEO_ASPECT=$(( ($VIDEO_HEIGHT*10000) / $VIDEO_WIDTH )) # bash cant do floatingpoint, so do % in integers instead
      echo "VIDEO: ${VIDEO_WIDTH}x${VIDEO_HEIGHT} ratio:${VIDEO_ASPECT}%"
      #echo "Reading logo width: "
      local LOGO_WIDTH=`magick identify -format "%w" "$DEFAULT_LOGO"`
      #echo "Reading logo height:"
      local LOGO_HEIGHT=`magick identify -format "%h" "$DEFAULT_LOGO"`
      local LOGO_ASPECT=$(( ($LOGO_HEIGHT*10000) / $LOGO_WIDTH ))    # bash cant do floatingpoint, so do % in integers instead
      echo "LOGO:  ${LOGO_WIDTH}x${LOGO_HEIGHT} ratio:${LOGO_ASPECT}%"
      # change scale if you want the image smaller (full width == VIDEO_WIDTH;  1/2 width == VIDEO_WIDTH/2)
      local SCALE=$( (($VIDEO_ASPECT < $LOGO_ASPECT)) && echo $(( ($LOGO_WIDTH * $VIDEO_HEIGHT) / $LOGO_HEIGHT )) || echo "$VIDEO_WIDTH")
      #local SCALE=$VIDEO_WIDTH
      echo "SCALE: $SCALE"

      # setup ffmpeg command line options:
      local FPS="-r 1"
      # start with a black screen
      local IMAGE1="-f lavfi -i color=c=black:s=${VIDEO_WIDTH}x${VIDEO_HEIGHT}:r=5"
      # overlay the cover logo image
      local IMAGE2="-f image2 -s ${VIDEO_WIDTH}x${VIDEO_HEIGHT} -i \"$DEFAULT_LOGO\""
      # specify how the images combine (overlay), scale and position
      local IMAGE_COMBINE_FILTER="-filter_complex \"[1:v]scale=${SCALE}:-1 [ovrl], [0:v][ovrl]overlay=(main_w-overlay_w)/2:(main_h-overlay_h)/2\""
      local IMAGE="$IMAGE1 $IMAGE2 $IMAGE_COMBINE_FILTER"
      local LENGTH="-shortest -max_interleave_delta 200M -fflags +shortest"
      local FMT="-c:v libx264 -pix_fmt yuv420p"  # -vf scale=1920:1080

      if [ "m4a" == `filepath_ext "$file"` ]; then
        echo "Using m4a AAC direct copy"
        echo "--------------------------------"
        local AUDIO="-c:a copy"  # copy m4a aac format directly in
        local CMD="ffmpeg $FPS $IMAGE -i \"$file\" $AUDIO $LENGTH $FMT \"./$FILENAME.mp4\""   # brew install ffmpeg
        echo "$CMD"
        echo "==============================================="
        eval "$CMD"
      elif [ "wav" == `filepath_ext "$file"` ]; then
        echo "Using wav to AAC conversion"
        echo "--------------------------------"
        local AUDIO="-c:a aac -b:a 128k" # convert wav PCM to AAC format
        local CMD="ffmpeg $FPS $IMAGE -i \"$file\" $AUDIO $LENGTH $FMT \"./$FILENAME.mp4\""   # brew install ffmpeg
        echo "$CMD"
        echo "==============================================="
        eval "$CMD"
      elif [ "DAT" == `filepath_ext "$file"` ]; then
        local IS_264=`ffprobe "$file" 2>&1 | grep Video | grep libx264`
        local IS_mpeg1=`ffprobe "$file" 2>&1 | grep Video | grep mpeg1`
        local IS_MP3=`ffprobe "$file" 2>&1 | grep Audio | grep mp3`
        local IS_ACC=`ffprobe "$file" 2>&1 | grep Audio | grep acc`
        echo "Using DAT (video + audio) conversion"
        echo "--------------------------------"
        #echo "IS_264 $IS_264"
        #echo "IS_mpeg $IS_mpeg"
        #echo "IS_MP3 $ISIS_MP3_264"
        #echo "IS_ACC $IS_ACC"
        local AUDIO="-c:a aac -b:a 128k" # convert existing sudio to AAC format
        if [[ "${IS_MP3}" != "" ]] || [[ "${IS_ACC}" != "" ]]; then
          echo "!!!!!!!!!!!!!!!    DETECTED A GOOD AUDIO FMT, COPYING  !!!!!!!!!!!!!!!!!"
          AUDIO="-c:a copy"  # copy audio formats directly in
        fi
        if [[ "${IS_264}" != "" ]]; then
          echo "!!!!!!!!!!!!!!!    DETECTED A GOOD VIDEO FMT, COPYING  !!!!!!!!!!!!!!!!!"
          FMT="-c:v copy"  # copy video format directly in
        fi
        local CMD="ffmpeg -i \"$file\" -fflags +genpts $AUDIO $FMT \"./$FILENAME.mp4\""   # brew install ffmpeg
        echo "$CMD"
        echo "==============================================="
        eval "$CMD"

        CMD="ffmpeg -i \"$file\" -c:a copy -c:v copy \"./$FILENAME.dat.mp4\""   # brew install ffmpeg
        echo "$CMD"
        echo "==============================================="
        eval "$CMD"
      else
        echo "Not in wav format:  \"$file\"  (use sox_convert_to_wav first)"
      fi

      rm -f "$TMP_LOGO"
    fi
  done
}

function sox_convert_to_mp3
{
  if [[ "$#" -lt 1 ]]; then
    echo "${FUNCNAME[0]} <audio file1> ... <audio filen>"
    return
  fi
  for file in "$@"; do
    local FILENAME=`filepath_name "$file"`
    if [ "wav" == `filepath_ext "$file"` ]; then
      echo "Converting to mp3:  \"./$FILENAME.mp3\""
      sox "$file" "./$FILENAME.mp3"
    else
      echo "Not in wav format:  \"$file\"  (use sox_convert_to_wav first)"
    fi
  done
}
function sox_convert_to_flac
{
  if [[ "$#" -lt 1 ]]; then
    echo "${FUNCNAME[0]} <audio file1> ... <audio filen>"
    return
  fi
  for file in "$@"; do
    local FILENAME=`filepath_name "$file"`
    if [ "wav" == `filepath_ext "$file"` ]; then
      echo "Converting to flac:  \"./$FILENAME.flac\""
      sox "$file" "./$FILENAME.flac"
    else
      echo "Not in wav format:  \"$file\"  (use sox_convert_to_wav first)"
    fi
  done
}
function sox_convert_to_ogg
{
  if [[ "$#" -lt 1 ]]; then
    echo "${FUNCNAME[0]} <audio file1> ... <audio filen>"
    return
  fi
  for file in "$@"; do
    local FILENAME=`filepath_name "$file"`
    if [ "wav" == `filepath_ext "$file"` ]; then
      echo "Converting to ogg:  \"./$FILENAME.ogg\""
      sox "$file" "./$FILENAME.ogg"
    else
      echo "Not in wav format:  \"$file\"  (use sox_convert_to_wav first)"
    fi
  done
}
function sox_convert_to_stereo44k
{
  if [[ "$#" -lt 1 ]]; then
    echo "${FUNCNAME[0]} <audio file1> ... <audio filen>"
    return
  fi
  for file in "$@"; do
    local FILENAME=`filepath_name "$file"`
    if [ "wav" == `filepath_ext "$file"` ]; then
      echo "Converting to stereo:  \"$FILENAME-stereo.wav\""
      sox "$file" "./$FILENAME-stereo.wav" channels 2 rate 44k norm -0.1
    else
      echo "Not in wav format:     \"$file\"  (use sox_convert_to_wav first)"
    fi
  done
}
function sox_convert_to_mono44k
{
  if [[ "$#" -lt 1 ]]; then
    echo "${FUNCNAME[0]} <audio file1> ... <audio filen>"
    return
  fi
  for file in "$@"; do
    local FILENAME=`filepath_name "$file"`
    if [ "wav" == `filepath_ext "$file"` ]; then
      echo "Converting to mono:    \"$FILENAME-mono.wav\""
      sox "$file" "./$FILENAME-mono.wav" channels 1 rate 44k norm -0.1
    else
      echo "Not in wav format:     \"$file\"  (use sox_convert_to_wav first)"
    fi
  done
}

function sox_info
{
  if [[ "$#" -lt 1 ]]; then
    echo "${FUNCNAME[0]} <audio file1> ... <audio filen>"
    return
  fi
  file="$1"

  if [ "m4a" == `filepath_ext "$file"` ]; then
    echo "==============================---ffprobe (verbose)---===================================="
    ffprobe -loglevel 0 -print_format json -show_format -show_streams  "$file" 2>&1
    echo "==============================---ffprobe---=================================="
    ffprobe -i  "$file" 2>&1
    echo "==============================---afinfo---=================================="
    afinfo "$file" 2>&1
    echo "==============================---mlds---=================================="
    mdls "$file" 2>&1

    echo "==============================---AtomicParsley---=================================="
    AtomicParsley "$file" -T 1 2>&1
    echo "==============================---AtomicParsley---=================================="
    AtomicParsley "$file" -t + 2>&1
  else
    echo "==============================---ffprobe (verbose)---===================================="
    ffprobe -loglevel 0 -print_format json -show_format -show_streams  "$file" 2>&1
    echo "==============================---ffprobe---===================================="
    ffprobe -i  "$file" 2>&1

    echo "==============================---soxi---===================================="
    sox --i "$file" 2>&1
  fi
}

function sox_forloop_help
{
  echo "for file in *.mp3; do sox \"\$file\" \"\$file.wav\"; done"
  echo "for file in *.mp3; do sox \"\$file\" \"\$file.wav\" channels 2 rate 44k norm -0.1; done"
}

function sox_duration_total
{
  if [[ "$#" -lt 1 ]]; then
    echo "Generate stats for a given list of Audio files"
    echo "  sox_duration_total *.wav"
    echo ""
    return
  fi
  for i in "$@"; do
    val=`soxi -d "$i"`
    echo "$val | $i"
  done
  soxi -D "$@" | python -c "import sys;print(\"\ntotal sec:    \" +str( sum(float(l) for l in sys.stdin)))"
  soxi -D "$@" | python -c "import sys;print(\"total min:    \" +str( sum(float(l) for l in sys.stdin)/60 ))"
  soxi -D "$@" | python -c "import sys;import datetime;print(\"running time: \" +str( datetime.timedelta(seconds=sum(float(l) for l in sys.stdin)) ))"
}

function sox_stats
{
  if [[ "$#" -lt 1 ]]; then
    echo "Generate stats for a given list of Audio files"
    echo "  sox_stats *.wav"
    echo ""
    return
  fi
  for i in "$@"; do
    filetype=`soxi -t "$i"` # file type    -- wav
    dur=`soxi -d "$i"` # duration          -- 00:02:30.24
    rate=`soxi -r "$i"` # samp rate        -- 4100
    ch=`soxi -c "$i"` # channels           -- 2
    bits=`soxi -b "$i"` # bits per sample  -- 24-bit
    #precision=`soxi -p "$i"` # sample precision -- 24-bit
    enc=`soxi -e "$i"` # encoding          -- Signed Integer PCM
    echo "$dur $filetype $rate $ch $bits $enc | $i"
  done
  soxi -D "$@" | python -c "import sys;print(\"\ntotal sec:    \" +str( sum(float(l) for l in sys.stdin)))"
  soxi -D "$@" | python -c "import sys;print(\"total min:    \" +str( sum(float(l) for l in sys.stdin)/60 ))"
  soxi -D "$@" | python -c "import sys;import datetime;print(\"running time: \" +str( datetime.timedelta(seconds=sum(float(l) for l in sys.stdin)) ))"
}

function ffmpeg_upscale {
  if [[ "$#" -lt 1 ]]; then
    echo "Upscale any video (to h264 video; with m4a (aac) audio encoding)"
    echo "  ffmpeg_upscale *.mov 1920 1080"
    echo "  ffmpeg_upscale *.mp4 1280 720"
    echo "  ffmpeg_upscale *.m4v 1920 1080"
    echo ""
    return
  fi
  local in="$1"
  local out="$(basename -- "$in")"
  local w="$2"
  local h="$3"
  ffmpeg -i "$in" -c:v libx264 -c:a aac -b:a 128k -vf scale=${w}x${h}:flags=lanczos "$out.mp4"
}
alias mp4_upscale=ffmpeg_upscale
alias m4v_upscale=ffmpeg_upscale

function ffmpeg_portrait_to_landscape {
  if [[ "$#" -lt 1 ]]; then
    echo "Upscale any portrait mode video to letterbox 16:9 (using black sides)"
    echo "  ffmpeg_upscale video.mp4 # will output to ./video-landscape.mp4"
    echo "  ffmpeg_upscale video_portrait.mp4 video_letterbox.mp4"
    echo ""
    return
  fi
  local in="$1"
  local out="./$(filepath_name "$in")-landscape.$(filepath_ext "$in")"
  if [[ "$#" -ge 2 ]]; then
    out="$2"
  fi
  ffmpeg -i "${in}" -vf "scale=iw*sar:ih,setsar=1,pad=ih*16/9:ih:(ow-iw)/2:0" "${out}"
}

function ffmpeg_portrait_to_landscape_echo_pillarbox {
  if [[ "$#" -lt 1 ]]; then
    echo "Upscale any portrait mode video to letterbox 16:9 (using echo pillarbox)"
    echo "  ffmpeg_upscale video.mp4    # will output to ./video-echo-pillarbox.mp4"
    echo "  ffmpeg_upscale video_portrait.mp4 video_echo-pillarbox.mp4"
    echo ""
    return
  fi
  local in="$1"
  local out="./$(basename -- "$in")-echo-pillarbox.$(filepath_ext "$in")"
  if [[ "$#" -ge 2 ]]; then
    out="$2"
  fi
  ffmpeg -i "${in}" \
  -vf 'split[original][copy];[copy]scale=ih*16/9:-1,crop=h=iw*9/16,gblur=sigma=20[blurred];[blurred][original]overlay=(main_w-overlay_w)/2:(main_h-overlay_h)/2' \
  "${out}"
}

