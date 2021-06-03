#!/bin/bash

shopt -s expand_aliases
alias ldd='otool -L'

echo "=============================="
echo "sanity"
echo "=============================="

echo "sed should be GNU sed:"
sed --version | grep "GNU sed"

echo "=============================="
echo "sampler tools dependencies:"
echo "=============================="

echo `which bash`
echo `which node`
echo `which sox`
echo `ls /Applications/polyphone-*.app/Contents/MacOS/*`

echo "=============================="
echo "batch tools dependencies:"
echo "=============================="

echo `which bash`
echo `which perl`
echo `which flac`
echo `which lame`
echo `which vorbis-tools`
echo `which sox`
echo `which fdk-aac-encoder`
echo `which faac`
echo `which atomicparsley`
echo `which imagemagick`
echo `which sip`


echo ""
echo "=========================================================="
echo "verbose stuff"
echo "=========================================================="

echo ""
echo "what's sox linked to:"
echo ""
ldd `which sox`

echo ""
echo "what's polyphone linked to?"
echo ""
ldd `ls /Applications/polyphone-*.app/Contents/MacOS/*`

