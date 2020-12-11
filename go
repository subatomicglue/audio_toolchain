#!/bin/sh

# just a test...
#./slice.sh src/SD.aif autosliced
#./rename.sh autosliced/src/*/*.wav
#bash -c "./sfz.js $(echo $(tr '\n' ' ' < drumkit.def)) drumkit.sfz"
#exit -1

# we recorded using a monophonic mic... just throw out the right channel...
./mono --dest src_mono --mix left src/*aif

# auto slice the source wavs which contain instrument samples separated by silence
# input wavs read from src/, output individual chopped samples to autosliced/
./slice.sh src_mono/*.aif autosliced

# rename sample files by their velocity
# input wavs from autosliced/, output renamed wavs to final_lvl/ and final_db/
./rename.sh --type lvl autosliced/*/*.wav
#./rename.sh --type db autosliced/*/*.wav

# normalize each sample to 0.99
./normalize.sh final_lvl/*/*.wav

# create a sampler instrument from the set of samples
# (suck in the .def file, which is just a bash command line, collapse newlines)
bash -c "./sfz.js $(echo $(tr '\n' ' ' < drumkit.def)) drumkit.sfz"

./sfz_to_sf2.sh drumkit.sfz
