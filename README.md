
# About

Here are some command line tools I use for audio processing.

## Sampler Auto Slicing
  - I use these command line scripts to auto convert single "source" audio files containing recordings of many samples (e.g. bass drum hits at different volumes separated by silence).  We can auto slice these "source" files by silence into separate sample files, renamed with the velocity level, converted to mono, normalized, and then converted to sfz or sf2 sample sets.  All with command line batch tools.
    - [slice.sh](slice.sh) auto slices a single audio file containing music instrument samples (separated by silence), into separate .wav files (timmed by silence)
      - uses `sox` to split the file using specified silence level threshold
    - [rename.sh](rename.sh) rename audio files by their peak level.  useful for individual instrument samples.
      - uses `sox` to detect the sound level
    - [mono.sh](mono.sh) make audio files mono
      - uses `sox` to isolate the left or right channels, or mix them
    - [normalize.sh](normalize.sh) normalize the level of audio files
      - uses `sox` to normalize the sound level
    - [max_lvl.sh](max_lvl.sh) output the max level found in the audio file
    - [peak_dB.sh](peak_dB.sh) output the peak db found in the audio file
    - [samples.sh](samples.sh) output the number of samples found in the audio file
    - [sfz.js](sfz.js) command line script to create a .sfz sampler instrument bank
    - [sfz_to_sf2.sh](sfz_to_sf2.sh) and [sf2_to_sfz.sh](sf2_to_sfz.sh) command line scripts to convert between sf2 and sfz sampler formats.
      - uses `polyphone` to do the conversion

  - See [go](go) as an example of how to run these in a pipeline to auto process and produce `sfz` and `sf2` sampler bank files from a set of "sources" (see above).  Just drop your "source" files into `src/` and run `go`.

## Music Album Batch Conversion
  - I use these scripts to auto convert my albums of raw uncompressed .wav files to distributable mp3/ogg/flac with playlists.
  - every album has a folder with .wav for each track of the album, plus [tags.ini](batch_convert/examples/selling/tags.ini)
  - The main utilities:
    - [convert.sh](batch_convert/bin/convert.sh) convert a single album folder to mp3/m4a/flac/ogg for distribution
      - [rip.pl](batch_convert/bin/rip.pl) (converts .wav to dest compressed format)
        - supports conversion from wav to mp3/m4a/flac/ogg
          - use `lame` for wav to *mp3*
          - use `flac` for wav to *flac*
          - use `oggenc` for wav to *ogg* (mid 2000's I was using oggenc2-aoTuV)
      - [tag.pl](batch_convert/bin/tag.pl) (meta-tags the compressed files)
        - frontend for editing tags in compressed files (ogg/mp3/flac)
          - use perl's MP3::Tag for *mp3* tagging
            - use `lame --help` to generate text for TENC metatag (name of encoder)
          - use `metaflac` for *flac* tagging
          - use `vorbiscomment` for *ogg* tagging
      - [playlist-gen.pl](batch_convert/bin/playlist-gen.pl) (outputs .m3u playlist file for the output set of compressed files)
        - fills in running times by analysing the files
          - use `metaflac` to get running time for *flac* files
          - use `ogginfo` to get running time for *ogg* files
          - use `MP3::Tag` perl module to get running time for *mp3* files
          - use `sox` to get running time for *wav* files
    - [catalog_base.sh](batch_convert/bin/catalog_base.sh) to be included by your [catalog.sh](batch_convert/examples/catalog.sh)  maintain a music catalog.  convert many album folders to mp3/flac/ogg/m4a for distribution
      - [convert.sh](batch_convert/bin/convert.sh) calls convert for each album folder listed in the `actions` section of [catalog.sh](batch_convert/examples/catalog.sh)


# Setup

We rely on some command line tools to do the work:
- Beat Slicing:
  - sox, polyphone, (scripting: bash, nodejs)
- Batch Conversion:
  - flac (flac, metaflac), lame, vorbis-tools (oggenc, ogginfo, vorbiscomment), sox, (scripting: perl)

All of these are open source, cross platform tools, that are available in many platforms including MacOS, Windows, or Linux.

## MacOS
```
# macos's sed is non-standard, we can fix that
brew install gnu-sed       # and follow the instructions to add to your PATH
                           # `which sed` should show the new `*/gnubin` location

# needed for sampler/auto-slicer tools
brew install node
brew install polyphone
brew install sox

# needed for batch processing tools
brew install perl
brew install flac            # for flac, metaflac            (flac encoding)
brew install lame            # for lame                       (mp3 encoding)
brew install vorbis-tools    # for oggenc, vorbiscomment      (ogg encoding)
brew install sox
sudo pip install eyeD3       # for eyeD3                       (mp3 tagging)
brew install fdk-aac-encoder # for fdkaac                     (m4a encoding)
brew install faac            # for faac   (m4a encoding, fallback to fdkaac)
brew install atomicparsley   # for AtomicParsley               (m4a tagging)
brew install imagemagick     # for convert            (to resize folder art)
brew install sip             # for image stats                (width/height)
```

*troubleshooting*  try running `./depend.sh` to verify you have all dependencies

## Windows
*CONTRIBUTE!*  Feel free to contribute instructions for other platforms. :-)

## Linux
*CONTRIBUTE!*  Feel free to contribute instructions for other platforms. :-)

# HOWTO - Sampler Auto Slicing
```
$ git clone audio_toolchain
$ cd audio_toolchain
$ ./depends.sh   # verify you have all the dependencies needed to run these scripts

...   record a drumset into WAV files, into the src directory  ...

$ ls ./src
BD 2ft damped.aif
BD 2ft ringing.aif
BD 3in damped.aif
BD 3in ringing.aif
HH Bell.aif
HH Closed.aif
HH Foot.aif
HH Open.aif
HT.aif
LT.aif
MT.aif
Open Snare.aif
Ride - Zildian 17_ Projection Crash (Custom A) - Stick Tip to Cym Edge.aif
SD.aif
Zildian Special Dry Crash (Custom K) - Stick Edge to Cym Edge.aif
Zildian Special Dry Crash (Custom K) Stick Tip to Cym Edge.aif

$ ./go
```

# HOWTO - Album conversion from WAV to various flac|ogg|mp3|m4a

## Single album:
You'll supply:
 - a directory full of WAV files, one per track of your album
 - `tags.ini` file with extra metadata tags information (like copyright)
 - `Folder.jpg` image representing the album, typically square image 500x500
 - all files conforming to the naming convention `bandname - albumname - tracknum - trackname.wav`

```
$ git clone audio_toolchain
$ cd audio_toolchain
$ ./depends.sh   # verify you have all the dependencies needed to run these scripts
$ cd batch_convert/examples/inertial

$ ./create_test_data.sh  #  generate some typical test files
$ ls
Folder.jpg
subatomicglue - inertialdecay - 01 - hard.wav
subatomicglue - inertialdecay - 02 - acidbass.wav
subatomicglue - inertialdecay - 03 - cause.of.a.new.dark.age.wav
subatomicglue - inertialdecay - README.txt
subatomicglue - inertialdecay.jpg
tags.ini

$ ../../bin/convert.sh . out

$ ls out*
out-flac:
.
..
Folder.jpg
playlist.m3u
subatomicglue - inertialdecay - 01 - hard.flac
subatomicglue - inertialdecay - 02 - acidbass.flac
subatomicglue - inertialdecay - 03 - cause.of.a.new.dark.age.flac
subatomicglue - inertialdecay - README.txt
subatomicglue - inertialdecay.jpg

out-m4a:
.
..
Folder.jpg
playlist.m3u
subatomicglue - inertialdecay - 01 - hard.m4a
subatomicglue - inertialdecay - 02 - acidbass.m4a
subatomicglue - inertialdecay - 03 - cause.of.a.new.dark.age.m4a
subatomicglue - inertialdecay - README.txt
subatomicglue - inertialdecay.jpg

out-mp3:
.
..
Folder.jpg
playlist.m3u
subatomicglue - inertialdecay - 01 - hard.mp3
subatomicglue - inertialdecay - 02 - acidbass.mp3
subatomicglue - inertialdecay - 03 - cause.of.a.new.dark.age.mp3
subatomicglue - inertialdecay - README.txt
subatomicglue - inertialdecay.jpg

out-ogg:
.
..
Folder.jpg
playlist.m3u
subatomicglue - inertialdecay - 01 - hard.ogg
subatomicglue - inertialdecay - 02 - acidbass.ogg
subatomicglue - inertialdecay - 03 - cause.of.a.new.dark.age.ogg
subatomicglue - inertialdecay - README.txt
subatomicglue - inertialdecay.jpg
```

## Catalog of Albums
You'll supply:
 - Multiple single albums in WAV format (see above for naming structure)
 - a [catalog.sh](batch_convert/examples/catalog.sh) file, with an `actions` block containing the list of albums to convert
```
$ git clone audio_toolchain
$ cd audio_toolchain
$ ./depends.sh     # verify you have all the dependencies needed to run these scripts
$ cd batch_convert/examples


$ cat catalog.sh   # you'll copy this file to your music catalog, edit the actions for your albums
#!/bin/bash

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


$ ./catalog.sh --gen  # generate flac|ogg|m4a|mp3 versions of the albums listed in [catalog.sh](batch_convert/examples/catalog.sh)
$ ls generated/
.                       crunchy-ogg             selling-flac            spinning-m4a
..                      inertial-flac           selling-m4a             spinning-mp3
crunchy-flac            inertial-m4a            selling-mp3             spinning-mp3-shortnames
crunchy-m4a             inertial-mp3            selling-mp3-shortnames  spinning-ogg
crunchy-mp3             inertial-mp3-shortnames selling-ogg
crunchy-mp3-shortnames  inertial-ogg            spinning-flac
```

