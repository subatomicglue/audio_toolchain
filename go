#!/bin/sh

VERBOSE=false # for debugging (set to true or false)
TEMPDIR="__intermediate"

# just a test...
#./slice.sh src/SD.aif autosliced
#./rename.sh autosliced/src/*/*.wav
#bash -c "./sfz.js $(echo $(tr '\n' ' ' < drumkit.def)) drumkit.sfz"
#exit -1

# we recorded using a monophonic mic... just throw out the right channel...
./mono.sh --destdir $TEMPDIR/src_mono --mix left src/*aif
$VERBOSE && read -p "Press any key..."

# auto slice the source wavs which contain instrument samples separated by silence
# input wavs read from src/, output individual chopped samples to autosliced/
./slice.sh src_mono/*.aif $TEMPDIR/autosliced
$VERBOSE && read -p "Press any key..."

# rename sample files by their velocity
# input wavs from autosliced/, output renamed wavs to final_lvl/ and final_db/
./rename.sh --type lvl $TEMPDIR/autosliced/*/*.wav
#./rename.sh --type db autosliced/*/*.wav
$VERBOSE && read -p "Press any key..."

# normalize each sample to 0.99
./normalize.sh $TEMPDIR/final_lvl/*/*.wav
$VERBOSE && read -p "Press any key..."

# create a sampler instrument from the set of samples
# (suck in the .def file, which is just a bash command line, collapse newlines)
bash -c "./sfz.js $(echo $(tr '\n' ' ' < drumkit.def)) drumkit.sfz"
$VERBOSE && read -p "Press any key..."

# convert sfz instrument to sf2 file
rm -f ./drumkit.sf2
./sfz_to_sf2.sh drumkit.sfz
$VERBOSE && read -p "Press any key..."

# convert sf2 instrument to sfz directory (bundles all samples together)
# TODO: maybe want to bundle the original .wavs in case there is loss of quality?
./sfz_to_sf2.sh drumkit.sf2
$VERBOSE && read -p "Press any key..."


