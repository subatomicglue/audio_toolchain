#!/bin/sh

# populate this directory with dummy data

echo ". . .\nCreating test audiotrack wav files:"
tracks=(
  "subatomicglue - crunchy - 01 - heartonfire.wav"
  "subatomicglue - crunchy - 02 - bodyquake.wav"
  "subatomicglue - crunchy - 03 - tryptamine.wav"
  "subatomicglue - crunchy - 04 - flowerfall.wav"
  "subatomicglue - crunchy - 04 - vampire.wav"
  "subatomicglue - crunchy - 05 - blow it all up.wav"
  "subatomicglue - crunchy - 06 - crevice.wav"
  "subatomicglue - crunchy - 07 - goaway.wav"
  "subatomicglue - crunchy - 08 - progress.wav"
  "subatomicglue - crunchy - 09 - promise.wav"
  "subatomicglue - crunchy - 10 - aloft.wav"
  "subatomicglue - crunchy - 11 - the wait, im so alive.wav"
  "subatomicglue - crunchy - 12 - youre the one i do not want.wav"
  "subatomicglue - crunchy - 13 - psychopath and on and on.wav"
  "subatomicglue - crunchy - 14 - ineptitude for everyone.wav"
  "subatomicglue - crunchy - 15 - tensionhead.wav"
)
for i in "${tracks[@]}"; do
  sox -V -r 48000 -n -b 16 -c 2 "$i" synth 30 sin 1000 vol -6dB
done

echo ". . .\nCreating test Folder.jpg"
convert -size 32x32 xc:white Folder.jpg

echo ". . .\nCreating test README.txt"
echo "hello world\n\n<tell us all about your album here>\n\nrun '../../bin/convert.sh . out' to batch convert!" > README.txt

echo ". . .\nContents of README.txt:"
cat README.txt

mv README.txt "subatomicglue - crunchy - README.txt"
cp Folder.jpg "subatomicglue - crunchy.jpg"
