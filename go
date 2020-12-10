
#./slice.sh src/SD.aif autosliced
#./rename.sh autosliced/src/*/*.wav

./slice.sh src/*.aif autosliced
./rename.sh --type lvl autosliced/*/*.wav
./rename.sh --type db autosliced/*/*.wav

