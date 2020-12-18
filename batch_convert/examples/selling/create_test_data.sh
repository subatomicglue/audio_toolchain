#!/bin/sh

# populate this directory with dummy data

echo ". . .\nCreating test audiotrack wav files:"
tracks=(
  "subatomicglue-selling your friend for cash-01-bospherous.wav"
  "subatomicglue-selling your friend for cash-02-3circles.wav"
  "subatomicglue-selling your friend for cash-03-brkn.wav"
  "subatomicglue-selling your friend for cash-04-fleeting.wav"
  "subatomicglue-selling your friend for cash-05-floorist.wav"
  "subatomicglue-selling your friend for cash-06-grass is green.wav"
  "subatomicglue-selling your friend for cash-07-selling your friend (for cash).wav"
  "subatomicglue-selling your friend for cash-08-greenhousegas.wav"
  "subatomicglue-selling your friend for cash-09-myrandomthought.wav"
  "subatomicglue-selling your friend for cash-10-novus ordo seclorum.wav"
  "subatomicglue-selling your friend for cash-11-wintermute.wav"
  "subatomicglue-selling your friend for cash-12-aggression.wav"
  "subatomicglue-selling your friend for cash-13-coma40.wav"
  "subatomicglue-selling your friend for cash-14-morning jungle fortress.wav"
  "subatomicglue-selling your friend for cash-15-mantissong.wav"
  "subatomicglue-selling your friend for cash-16-darksky [zero horizon].wav"
  "subatomicglue-selling your friend for cash-17-blow.wav"
  "subatomicglue-selling your friend for cash-18-erosion.wav"
  "subatomicglue-selling your friend for cash-19-clearia.wav"
  "subatomicglue-selling your friend for cash-20-sun&moon.wav"
  "subatomicglue-selling your friend for cash-21-smartbomb.wav"
  "subatomicglue-selling your friend for cash-22-shattered.wav"
)
for i in "${tracks[@]}"; do
  sox -V -r 48000 -n -b 16 -c 2 "$i" synth 30 sin 1000 vol -6dB
done

echo ". . .\nCreating test Folder.jpg"
convert -size 32x32 xc:white Folder.jpg

echo ". . .\nCreating test README.txt"
echo "hello world\n\n<tell us all about your album here>\n\nrun ../../bin/convert.sh to batch convert!" > README.txt

echo ". . .\nContents of README.txt:"
cat README.txt

mv README.txt "subatomicglue-selling your friend for cash-README.txt"
cp Folder.jpg "subatomicglue-selling your friend for cash.jpg"
