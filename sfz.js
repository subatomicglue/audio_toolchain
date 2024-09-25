#!/usr/bin/env node

let fs = require( "fs" );
let path = require( "path" );
const util = require('util');
const exec = util.promisify(require('child_process').exec);

// this script's dir (and location of the other tools)
let scriptpath=__filename  // full path to script
let scriptname=__filename.replace( /^.*\//, "" )  // name of script w/out path
let scriptdir=__dirname    // the dir of the script
let cwd=process.cwd()

// options:
let note = 0;
let samp = "";
let prefix = "";
let wavs = [];
let note_sample_pairs = []; // [ {note: 63,samp: "BD"}, {note: 64, samp: "SD"}, ... ]
let VERBOSE=false;

/////////////////////////////////////
// scan command line args:
function usage()
{
  console.log( `${scriptname} - command line script to create a .sfz sampler instrument bank` );
  console.log( `Usage:
   ${scriptname} <out>         (output file:  bank.sfz)
   ${scriptname} --help        (this help)
   ${scriptname} --verbose     (output verbose information)
   ${scriptname} --note        (note to map to: e.g. 36)
   ${scriptname} --samp        (sample prefix to map to: e.g. ./BD/BD)
   ${scriptname} --prefix      (prefix string to prepend to sample path: default '${prefix}/')
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
    if (prefix != '') samp = prefix + "/" + samp; // prepend prefix
    VERBOSE && console.log( `Parsing Args: Sample ${samp}` )
    note_sample_pairs.push( { note: note, samp: samp } ); // log the note/samp pair
    continue
  }
  if (ARGV[i] == "--prefix") {
    i+=1;
    prefix=ARGV[i]
    prefix.replace( /\/+$/, '' ) // remove trailing slash if present
    VERBOSE && console.log( `Parsing Args: Sample Path Prefix ${prefix} (e.g. ${prefix}/MySample.wav)` )
    continue
  }
  if (ARGV[i].substr(0,2) == "--") {
    console.log( `Unknown option ${ARGV[i]}` );
    process.exit(-1)
  }

  wavs.push( ARGV[i] )
  VERBOSE && console.log( `Parsing Args: argument #${non_flag_args}: \"${ARGV[i]}\"` )
  non_flag_args += 1
}

// output help if they're getting it wrong...
if (non_flag_args_required != 0 && (ARGC == 0 || !(non_flag_args >= non_flag_args_required))) {
  (ARGC > 0) && console.log( `Expected ${non_flag_args_required} args, but only got ${non_flag_args}` );
  usage();
  process.exit( -1 );
}
//////////////////////////////////////////


function pad( s, size ) {
  s = String( s );
  while (s.length < (size || 2)) {s = "0" + s;}
  return s;
}
function padf( s, size, size_dec ) {
  if (typeof s == "number") { s = s.toFixed(size_dec) }
  s = String( s );
  while (s.length < ((size+size_dec+1) || 2)) {s = "0" + s;}
  return s;
}

async function go() {
  console.log( `process args: ${ARGC}  ${ARGV}` );
  outfile = wavs[0];
  outpath = outfile.replace( /\/*[^/]+$/, '' )

  filename = outfile.replace( /^.*\/([^/]+)\.[^.]+$/g, "$1" )
  outpath = outfile.replace( /([^/]+)$/g, "" ).replace( /\/$/g, "" );
  if (outpath != "" && outpath != "." && outpath != "./")
    fs.mkdirSync( outpath, { recursive: true } );
  console.log( `Creating:  \"${outfile}\" filename:${filename}` );
  let data = `
// Sfz created with sfz.js
// Name      : ${filename}
// Author    : sfz.sh (kevin)
// Copyright : (c) today
// Date      : 2020/12/01
// Comment   : auto generated

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

  for (let p of note_sample_pairs) {
    let vel_type = ""; // we detect the type of velocity in the sample set (mixing db and lvl wont work)
    let note = p.note;
    // if handed a dir, we'll map all velocity samples in that dir to the note
    // if handed a file, we'll map to the note
    let sampleset_path_rel = outpath + '/' + p.samp;  // relative to the script dir (may be different)
    let dir_given = fs.existsSync(sampleset_path_rel) && fs.lstatSync(sampleset_path_rel).isDirectory();
    let sampleset_path = dir_given ? p.samp : path.dirname( p.samp );  // dir (sets) or file (single sample)
    sampleset_path_rel = outpath + '/' + sampleset_path; // relative to the script dir (may be different) - fixup: dir (sets) or file (single sample)
    let sampleset_name = path.basename( p.samp )
    console.log( `note: ${note} sampleset_path: "${sampleset_path}" sampleset_name: "${sampleset_name}"` );
    console.log( `- Loading Sample Names` );
    let sample_files = dir_given ? fs.readdirSync( sampleset_path_rel ) : [`${sampleset_name}`];
    let sampleset = [];
    for (let f of sample_files) {
      let db_matches = f.match( /\s([-.0-9]+)(d?b?)\.[^.]+$/ );
      let lvl_matches = f.match( /\s([-0-9]+\.[0-9]+)\.[^.]+$/ );
      let vel  = db_matches ? db_matches[1] : lvl_matches ? lvl_matches[1] : "1.0";
      vel_type = db_matches ? "db" : lvl_matches ? "lvl" : "n/a";
      let velFlt = vel_type == "n/a" ? 1.0 : parseFloat( vel );
      let samps = 0;
      try {
        console.log( sampleset_path_rel, "----", f );
        const { stdout, stderr } = await exec( `${scriptdir}/samples.sh --nocr "${sampleset_path_rel + "/" + f}"` );
        samps = parseInt( stdout );
      } catch (err) {
        console.log( err );
      }
      if (samps > 0) {
        console.log( ` - sample: "${f}" sample_vel: ${padf( velFlt, 1, 6 )} velocity_type: "${vel_type}" samps:${samps}` );
        sampleset.push( { lokey: p.note, hikey: p.note, sample: f, sample_fullname: sampleset_path + "/" + f, sample_vel: velFlt,  samps: samps } );
      } else {
        console.log( ` - SKIPPING "${f}", 0 samples` );
      }
    }

    console.log( "- Sorting by velocity" );
    sampleset = sampleset.sort( (a,b) => a.sample_vel - b.sample_vel ); // ascending 0 to 1

    console.log( "- Normalizing Vel" );
    let lo = sampleset[0].sample_vel;
    let hi = sampleset[sampleset.length-1].sample_vel;
    for (let s of sampleset) {
      let old = s.sample_vel;
      if (lo == hi) {
        s.sample_vel = 1;
        s.vel = 127;
      } else {
        s.sample_vel = (s.sample_vel-lo) * (1-lo)/(hi-lo) + lo // scale [lo..hi] to [lo..1]  (preserve existing lo, hi becomes 1)
        //s.sample_vel = (s.sample_vel-lo) / (hi-lo)             // scale [lo..hi] to [0..1]   (existing lo becomes 0, hi becomes 1)
        s.vel = Math.floor( s.sample_vel * 127 );
      }
      console.log( `  - normalizing: "${s.sample}" old:${padf( old, 1, 6 )} new:${padf( s.sample_vel, 1, 6 )} vel:${s.vel}` );
    }

    console.log( "- Filling in Vel Ranges" );
    for (let i = 0; i < sampleset.length; ++i) {
      let s = sampleset[i];
      s.lovel = i == 0 ? 0 : sampleset[i-1].vel+1;
      s.hivel = i == (sampleset.length-1) ? 127 : s.vel;
      console.log( `  - sample: "${s.sample}" sample_vel: ${padf( s.sample_vel, 1, 6 )} lokey:${pad(s.lokey, 3)} hikey:${pad(s.hikey, 3)} lovel:${pad( s.lovel, 3 )} hivel:${pad( s.hivel, 3 )}` );
    }

    for (let s of sampleset) {
      console.log( `- Writing Sample: samp:"${s.sample_fullname}" key:${pad(s.lokey, 3)}-${pad(s.hikey, 3)} vel:${pad(s.lovel,3)}-${pad(s.hivel,3)}` );
      data += `<region>
sample=${s.sample_fullname.replace( /\//g, "\\")}
lokey=${s.lokey} hikey=${s.hikey}
pitch_keycenter=${s.lokey}
lovel=${s.lovel} hivel=${s.hivel}
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
end=${s.samps}
loop_start=0
loop_end=0

`;
    }
  }

  console.log( `Writing: ${outfile}` );
  fs.writeFileSync( outfile, data );
}

(async () => {
  go();
})();

