#!/usr/bin/env node

let fs = require( "fs" );

// options:
let note = 0;
let samp = "";
let wavs = [];
let pairs = [];
let VERBOSE=false;

/////////////////////////////////////
// scan command line args:
function usage()
{
  console.log( `${process.argv[1]} command line script to create a .sfz sampler instrument bank` );
  console.log( `Usage:
   ${process.argv[1]} <out>         (output file:  bank.sfz)
   ${process.argv[1]} --help        (this help)
   ${process.argv[1]} --verbose     (output verbose information)
   ${process.argv[1]} --note        (note to map to: e.g. 36)
   ${process.argv[1]} --samp        (sample prefix to map to: e.g. ./BD/BD)
  ` );
}
let ARGC = process.argv.length-2; // 1st 2 are node and script name...
let ARGV = process.argv;
let non_flag_args = 0;
let non_flag_args_required = 1;
for (let i = 2; i < (ARGC+2); i++) {
  if (ARGV[i] == "--help") {
    usage();
    process.exit( -1 )
  }

  if (ARGV[i] == "--verbose") {
    VERBOSE=true
    continue
  }
  if (ARGV[i] == "--note") {
    i+=1;
    note=ARGV[i]
    VERBOSE && console.log( `Parsing Args: Note ${note}` )
    continue
  }
  if (ARGV[i] == "--samp") {
    i+=1;
    samp=ARGV[i]
    VERBOSE && console.log( `Parsing Args: Sample ${samp}` )
    pairs.push( { note: note, samp: samp } );
    continue
  }
  wavs.push( ARGV[i] )
  VERBOSE && console.log( `Parsing Args: Audio: \"${ARGV[i]}\"` )
  non_flag_args += 1
}

// output help if they're getting it wrong...
if (ARGC == 0 || !(non_flag_args >= non_flag_args_required)) {
  (ARGC > 0) && console.log( `Expected ${non_flag_args_required} args, but only got ${non_flag_args}` );
  usage();
  process.exit( -1 );
}
//////////////////////////////////////////


outfile = wavs[0];

filename = outfile.replace( /^.*\/([^/]+)\.[^.]+$/g, "$1" )
outpath = outfile.replace( /([^/]+)$/g, "" ).replace( /\/$/g, "" );
if (outpath != "" && outpath != "." && outpath != "./")
  fs.mkdirSync( outpath, { recursive: true } );
console.log( `Creating:  \"${outfile}\" filename:${filename}` );
let data = `
// Sfz created with sfz.js (hack script kevin made)
// Name      : gah
// Author    :
// Copyright :
// Date      : 2020/12/01
// Comment   :

<group>
loop_mode=no_loop
amplfo_freq=3.00125
fillfo_freq=3.00125
transpose=0
tune=0
ampeg_attack=0.001
pitchlfo_freq=8.176
fil_type=lpf_2p
cutoff=19913

`;

for (let p of pairs) {
  let files = fs.readdirSync(p.samp);
  for (let file of files) {
  }

  for (let duh of duhs) {
    console.log( `Sample:  \"${p.note}\" ${p.samp} ${file}` );
    data += `<region>
sample=${p.samp.replace( /\//g, "\\")}\\${file}
lokey=${p.note} hikey=${p.note}
pitch_keycenter=60
lovel=0 hivel=127
fil_type=lpf_2p
cutoff=19914
pan=0
ampeg_attack=0.001
ampeg_decay=1
ampeg_sustain=51.2861
ampeg_release=5.64706
volume=0
transpose=0
tune=0
pitch_keytrack=0
offset=0
end=15424
loop_start=0
loop_end=0

`;
  }
}

fs.writeFileSync( outfile, data );

