#!/bin/bash

# copy this file to your music catalog, edit the actions for your albums

################################################################################
# -->> TODO: DELETE THIS SECTION!
# just for demo purposes, create the test data if it doesn't exist yet
[ ! -f "crunchy/subatomicglue - crunchy - 01 - heartonfire.wav" ] && cd crunchy && ./create_test_data.sh && cd -
[ ! -f "inertial/subatomicglue - inertialdecay - 01 - hard.wav" ] && cd inertial && ./create_test_data.sh && cd -
[ ! -f "selling/subatomicglue-selling your friend for cash-01-bospherous.wav" ] && cd selling && ./create_test_data.sh && cd -
[ ! -f "spinning/subatomicglue - spinningtrees - 01 - start.wav" ] && cd spinning && ./create_test_data.sh && cd -
# -->> TODO: DELETE THIS SECTION!
################################################################################

SRCDIR="`pwd`"
DSTDIR="`pwd`/generated"
SCRIPTDIR="`pwd`/../bin"

# add jobs here:
actions=(
  "convert;$SRCDIR/crunchy;$DSTDIR/crunchy"
  "convert;$SRCDIR/inertial;$DSTDIR/inertial"
  "convert;$SRCDIR/selling;$DSTDIR/selling"
  "convert;$SRCDIR/spinning;$DSTDIR/spinning"
)

source "$SCRIPTDIR/catalog_base.sh"

