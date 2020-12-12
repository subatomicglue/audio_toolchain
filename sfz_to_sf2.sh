#!/bin/sh

infile=$1
outfile=$(echo "$infile" | sed -E "s/\.[^.]+$//g")

echo "==================================================="
echo "Converting $infile to $outfile (thanks polyphone!)"
/Applications/polyphone-2.2.app/Contents/MacOS/polyphone -1 -i "$infile" -d . -o "$outfile"



