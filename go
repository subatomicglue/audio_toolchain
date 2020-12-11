#!/bin/sh

# just a test...
#./slice.sh src/SD.aif autosliced
#./rename.sh autosliced/src/*/*.wav
#./sfz.js \
#  --note 55 --samp "normalized/BD 2ft damped" \
#  --note 57 --samp "normalized/BD 2ft ringing" \
#  --note 59 --samp "normalized/BD 3in damped" \
#  --note 60 --samp "normalized/BD 3in ringing" \
#  --note 62 --samp "normalized/SD" \
#  --note 64 --samp "normalized/Open Snare" \
#  --note 65 --samp "normalized/HT" \
#  --note 67 --samp "normalized/MT" \
#  --note 69 --samp "normalized/LT" \
#  --note 66 --samp "normalized/HH Closed" \
#  --note 68 --samp "normalized/HH Foot" \
#  --note 70 --samp "normalized/HH Open" \
#  --note 71 --samp "normalized/HH Bell" \
#  --note 73 --samp "normalized/Zildian Special Dry Crash (Custom K) Stick Tip to Cym Edge" \
#  --note 75 --samp "normalized/Zildian Special Dry Crash (Custom K) - Stick Edge to Cym Edge" \
#  --note 78 --samp "normalized/Ride - Zildian 17_ Projection Crash (Custom A) - Stick Tip to Cym Edge" \
#  test.sfz
#exit -1

# auto slice the source wavs which contain instrument samples separated by silence
# input wavs read from src/, output individual chopped samples to autosliced/
./slice.sh src/*.aif autosliced

# rename sample files by their velocity
# input wavs from autosliced/, output renamed wavs to final_lvl/ and final_db/
./rename.sh --type lvl autosliced/*/*.wav
#./rename.sh --type db autosliced/*/*.wav

# normalize each sample to 0.99
./normalize.sh final_lvl/*/*.wav

# create a sampler instrument from the set of samples
./sfz.js \
  --note 55 --samp "normalized/BD 2ft damped" \
  --note 57 --samp "normalized/BD 2ft ringing" \
  --note 59 --samp "normalized/BD 3in damped" \
  --note 60 --samp "normalized/BD 3in ringing" \
  --note 62 --samp "normalized/SD" \
  --note 64 --samp "normalized/Open Snare" \
  --note 65 --samp "normalized/HT" \
  --note 67 --samp "normalized/MT" \
  --note 69 --samp "normalized/LT" \
  --note 66 --samp "normalized/HH Closed" \
  --note 68 --samp "normalized/HH Foot" \
  --note 70 --samp "normalized/HH Open" \
  --note 71 --samp "normalized/HH Bell" \
  --note 73 --samp "normalized/Zildian Special Dry Crash (Custom K) Stick Tip to Cym Edge" \
  --note 75 --samp "normalized/Zildian Special Dry Crash (Custom K) - Stick Edge to Cym Edge" \
  --note 78 --samp "normalized/Ride - Zildian 17_ Projection Crash (Custom A) - Stick Tip to Cym Edge" \
  drumkit.sfz

./sfz_to_sf2.sh drumkit.sfz
