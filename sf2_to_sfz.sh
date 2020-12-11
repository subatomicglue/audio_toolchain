#!/bin/sh

infile=$1
outfile=$(echo "$infile" | cut -f 1 -d '.')

/Applications/polyphone-2.2.app/Contents/MacOS/polyphone -3 -i "$infile" -d . -o "${outfile}_sfz"



