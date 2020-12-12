#!/bin/sh

VERBOSE=false # for debugging (set to true or false)
TEMPDIR="__intermediate"  # careful, UNIQUE name only, choose name wisely, we'll rm -r it later
IN_DIR=src
OUT_DIR="$IN_DIR"

# just a test...
#./slice.sh src/SD.aif autosliced
#./rename.sh autosliced/src/*/*.wav
#bash -c "./sfz.js $(echo $(tr '\n' ' ' < drumkit.def)) drumkit.sfz"
#exit -1

# we recorded using a monophonic mic... just throw out the right channel...
IN_DIR=$OUT_DIR; OUT_DIR=src_mono
./mono.sh --destdir $TEMPDIR/$OUT_DIR --mix left $IN_DIR/*aif
$VERBOSE && read -p "Press any key..."

# auto slice the source wavs which contain instrument samples separated by silence
# input wavs read from src/, output individual chopped samples to autosliced/
IN_DIR=$OUT_DIR; OUT_DIR=autosliced
./slice.sh $TEMPDIR/$IN_DIR/*.aif $TEMPDIR/$OUT_DIR
$VERBOSE && read -p "Press any key..."

# rename sample files by their velocity
# input wavs from autosliced/, output renamed wavs to final_lvl/ and final_db/
IN_DIR=$OUT_DIR; OUT_DIR=renamed_vel
./rename.sh --destdir $TEMPDIR/$OUT_DIR --type lvl $TEMPDIR/$IN_DIR/*/*.wav
$VERBOSE && read -p "Press any key..."

# normalize each sample to 0.99
IN_DIR=$OUT_DIR; OUT_DIR=normalized
./normalize.sh --destdir $TEMPDIR/$OUT_DIR $TEMPDIR/$IN_DIR/*/*.wav
$VERBOSE && read -p "Press any key..."

# create a sampler instrument from the set of samples
# (suck in the .def file, which is just a bash command line, collapse newlines)
IN_DIR=$OUT_DIR; OUT_DIR=.
bash -c "./sfz.js --prefix $TEMPDIR/$IN_DIR $(echo $(tr '\n' ' ' < drumkit.def)) $OUT_DIR/drumkit.sfz"
$VERBOSE && read -p "Press any key..."

# convert sfz instrument to sf2 file
IN_DIR=$OUT_DIR; OUT_DIR=.
rm -f $OUT_DIR/drumkit.sf2
./sfz_to_sf2.sh $IN_DIR/drumkit.sfz
$VERBOSE && read -p "Press any key..."

# convert sf2 instrument to sfz directory (bundles all samples together)
# TODO: maybe want to bundle the original .wavs in case there is loss of quality?
IN_DIR=$OUT_DIR; OUT_DIR=.
rm -f $OUT_DIR/drumkit_sfz
./sf2_to_sfz.sh $IN_DIR/drumkit.sf2
$VERBOSE && read -p "Press any key..."


rm -r $TEMPDIR
