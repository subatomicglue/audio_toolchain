#!/bin/bash

shopt -s expand_aliases
alias ldd='otool -L'

echo "==========================="
echo "here's a list dependencies:"
echo "==========================="

echo `which bash`

echo `which perl`

echo `which node`

echo `which sox`
ldd `which sox`

echo `ls /Applications/polyphone-*.app/Contents/MacOS/*`
ldd `ls /Applications/polyphone-*.app/Contents/MacOS/*`

