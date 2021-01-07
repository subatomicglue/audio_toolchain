#!/bin/sh

# populate this directory with dummy data

echo ". . .\nCreating test audiotrack wav files:"
tracks=(
  "subatomicglue - spinningtrees - 01 - start.wav"
  "subatomicglue - spinningtrees - 02 - asdfjlk.wav"
  "subatomicglue - spinningtrees - 03 - violentlydreaming.wav"
  "subatomicglue - spinningtrees - 04 - fruitjam.wav"
  "subatomicglue - spinningtrees - 05 - nothing.wav"
  "subatomicglue - spinningtrees - 06 - fur.wav"
  "subatomicglue - spinningtrees - 07 - speedbase (subatomic remix).wav"
  "subatomicglue - spinningtrees - 08 - war.fist.wav"
  "subatomicglue - spinningtrees - 09 - chilledbroccoli.wav"
  "subatomicglue - spinningtrees - 10 - juno.wav"
  "subatomicglue - spinningtrees - 11 - reversecowbell.wav"
  "subatomicglue - spinningtrees - 12 - offaxis.wav"
  "subatomicglue - spinningtrees - 13 - rotorbaum.wav"
  "subatomicglue - spinningtrees - 14 - bright.wav"
  "subatomicglue - spinningtrees - 15 - disastrous rise of misplaced power.wav"
  "subatomicglue - spinningtrees - 16 - abject worship of authority.wav"
  "subatomicglue - spinningtrees - 17 - deignwish.wav"
  "subatomicglue - spinningtrees - 18 - mypanties get hotter.wav"
  "subatomicglue - spinningtrees - 19 - heavyelement.wav"
  "subatomicglue - spinningtrees - 20 - styrofone.wav"
  "subatomicglue - spinningtrees - 21 - funk.wav"
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

mv README.txt "subatomicglue - spinningtrees - README.txt"
cp Folder.jpg "subatomicglue - spinningtrees.jpg"
