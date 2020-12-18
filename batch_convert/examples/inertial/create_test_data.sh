#!/bin/sh

# populate this directory with dummy data

tracks=(
  "subatomicglue - inertialdecay - 01 - hard.wav"
  "subatomicglue - inertialdecay - 02 - acidbass.wav"
  "subatomicglue - inertialdecay - 03 - cause.of.a.new.dark.age.wav"
  "subatomicglue - inertialdecay - 04 - daybreak.falls.wav"
  "subatomicglue - inertialdecay - 05 - forestfloor.wav"
  "subatomicglue - inertialdecay - 06 - rabbithole.wav"
  "subatomicglue - inertialdecay - 07 - feedme.wav"
  "subatomicglue - inertialdecay - 08 - grand.wav"
  "subatomicglue - inertialdecay - 09 - strawberryflavoreddeath.wav"
  "subatomicglue - inertialdecay - 10 - subfloor.wav"
  "subatomicglue - inertialdecay - 11 - silicone.wav"
  "subatomicglue - inertialdecay - 12 - inertial decay.wav"
  "subatomicglue - inertialdecay - 13 - the.void.wav"
  "subatomicglue - inertialdecay - 14 - weet.wav"
)

for i in "${tracks[@]}"; do
  sox -V -r 48000 -n -b 16 -c 2 "$i" synth 30 sin 1000 vol -6dB
done

echo "hello!" > README.txt

convert -size 32x32 xc:white Folder.jpg

