#!/bin/sh

# PLEASE CONFIGURE:  where's the AUDIO TOOLCHAIN ?
PATH_TO_AUDIO_TOOLCHAIN="$(pwd)/.."
PATH="${PATH_TO_AUDIO_TOOLCHAIN}":"$PATH"


#-----------------------------------------------------------------------
VERBOSE=false # for debugging (set to true or false)
TEMPDIR="__intermediate"  # careful, UNIQUE name only, choose name wisely, we'll rm -rf it later
IN_DIR=src        # below we'll use  IN_DIR for the processing pipeline
OUT_DIR="$IN_DIR" # below we'll use OUT_DIR for the processing pipeline
rm -rf $TEMPDIR   # clean out the tempdir

# just a test...
#./slice.sh src/SD.aif autosliced
#./rename.sh autosliced/src/*/*.wav
#bash -c "./sfz.js $(echo $(tr '\n' ' ' < drumkit.def)) drumkit.sfz"
#exit -1

# we recorded using a monophonic mic... just throw out the right channel...
IN_DIR=$OUT_DIR; OUT_DIR=1src_mono
mono.sh --destdir $TEMPDIR/$OUT_DIR --mix left $IN_DIR/*aif
$VERBOSE && read -p "Press any key..."

# auto slice the source wavs which contain instrument samples separated by silence
IN_DIR=$OUT_DIR; OUT_DIR=2autosliced
slice.sh --destdir $TEMPDIR/$OUT_DIR --thresh 0.1 $TEMPDIR/$IN_DIR/*.aif
$VERBOSE && read -p "Press any key..."

# rename sample files by their velocity
IN_DIR=$OUT_DIR; OUT_DIR=3renamed_vel
rename.sh --destdir $TEMPDIR/$OUT_DIR --type lvl $TEMPDIR/$IN_DIR/*/*.wav
$VERBOSE && read -p "Press any key..."

# normalize each sample to 0.99
IN_DIR=$OUT_DIR; OUT_DIR=4normalized
normalize.sh --destdir $TEMPDIR/$OUT_DIR $TEMPDIR/$IN_DIR/*/*.wav
$VERBOSE && read -p "Press any key..."

# create a sampler instrument from the set of samples
# (suck in the .def file, which is just a bash command line, collapse newlines)
IN_DIR=$OUT_DIR; OUT_DIR=.
bash -c "sfz.js --prefix $IN_DIR $(echo $(tr '\n' ' ' < drumkit.def)) $TEMPDIR/$OUT_DIR/drumkit.sfz"
$VERBOSE && read -p "Press any key..."

# convert sfz instrument to sf2 file
IN_DIR=$OUT_DIR; OUT_DIR=.
rm -f $OUT_DIR/drumkit.sf2
sfz_to_sf2.sh $TEMPDIR/$IN_DIR/drumkit.sfz
$VERBOSE && read -p "Press any key..."

# convert sf2 instrument to sfz directory (bundles all samples together)
# TODO: maybe want to bundle the original .wavs in case there is loss of quality?
#       YEP: we lose SFZ's lorand and hirand in SF2... TODO: change this
IN_DIR=$OUT_DIR; OUT_DIR=.
rm -rf $TEMPDIR/$OUT_DIR/drumkit_sfz
sf2_to_sfz.sh $TEMPDIR/$IN_DIR/drumkit.sf2
$VERBOSE && read -p "Press any key..."

# results!  collect them
rm -f ./drumkit.sf2
rm -rf ./drumkit_sfz
cp $TEMPDIR/$IN_DIR/drumkit.sf2 .
cp -r $TEMPDIR/$IN_DIR/drumkit_sfz .

# clean up, leave no evidence
#rm -rf $TEMPDIR

