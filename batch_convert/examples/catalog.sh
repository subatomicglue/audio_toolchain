#!/bin/bash

################################################################################
# -->> TODO: delete this section!
# just for demo purposes, create the test data if it doesn't exist yet
[ ! -f "crunchy/subatomicglue - crunchy - 01 - heartonfire.wav" ] && cd crunchy && ./create_test_data.sh && cd -
[ ! -f "inertial/subatomicglue - inertialdecay - 01 - hard.wav" ] && cd inertial && ./create_test_data.sh && cd -
[ ! -f "selling/subatomicglue-selling your friend for cash-01-bospherous.wav" ] && cd selling && ./create_test_data.sh && cd -
[ ! -f "spinning/subatomicglue - spinningtrees - 01 - start.wav" ] && cd spinning && ./create_test_data.sh && cd -
# -->> TODO: delete this section!
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

