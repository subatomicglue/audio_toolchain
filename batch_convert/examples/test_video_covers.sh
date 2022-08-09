mkdir -p generated

CREATE_COVER_FOR_VIDEO="../bin/create_echo_pillarbox_image.sh"

echo "Here, we'll test $CREATE_COVER_FOR_VIDEO to generate cover images for videos"
for file in "covers"/*.*; do
  F=`basename $file`
  if [ ! -f "./generated/cover-$F" ]; then
    cmd="$CREATE_COVER_FOR_VIDEO \"./covers/$F\" \"./generated/cover-$F\" 1920 1080"
    echo "$cmd"
    eval $cmd
  else
    echo "Already Exists, Skipping: \"./generated/cover-$F\""
  fi
done

