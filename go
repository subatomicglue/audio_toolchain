
# just a test...
#./slice.sh src/SD.aif autosliced
#./rename.sh autosliced/src/*/*.wav
./sfz.js --note 64 --samp "final_lvl/BD 2ft damped" test.sfz
exit -1

# auto slice the source wavs which contain instrument samples separated by silence
# input wavs read from src/, output individual chopped samples to autosliced/
./slice.sh src/*.aif autosliced

# rename sample files by their velocity
# input wavs from autosliced/, output renamed wavs to final_lvl/ and final_db/
./rename.sh --type lvl autosliced/*/*.wav
./rename.sh --type db autosliced/*/*.wav

# create a sampler instrument from the set of samples
./sfz.js --note 64 --samp final_lvl/BD/BD test.sfz

