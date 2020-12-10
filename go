
# just a test...
#./slice.sh src/SD.aif autosliced
#./rename.sh autosliced/src/*/*.wav

# auto slice the source wavs which contain instrument samples separated by silence
# input wavs read from src/, output individual chopped samples to autosliced/
./slice.sh src/*.aif autosliced

# rename sample files by their velocity
./rename.sh --type lvl autosliced/*/*.wav
./rename.sh --type db autosliced/*/*.wav

# create a sampler instrument from the set of samples
./sfz.js --note 64 --samp autosliced/BD/BD test.sfz

