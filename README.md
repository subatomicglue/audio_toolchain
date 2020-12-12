
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
    - [sfz.js](sfz.js) command line script to create a .sfz sampler instrument bank
    - [sfz_to_sf2.sh](sfz_to_sf2.sh) and [sf2_to_sfz.sh](sf2_to_sfz.sh) command line scripts to convert between sf2 and sfz sampler formats.
      - uses `polyphone` to do the conversion

  - See [go](go) as an example of how to run these in a pipeline to auto process and produce `sfz` and `sf2` sampler bank files from a set of "sources" (see above).

## Music Album Batch Conversion
  - I use these scripts to auto convert my albums of raw uncompressed .wav files to distributable mp3/ogg/flac with playlists.
  - every album has a folder with .wav for each track of the album, plus [tags.ini](batch_convert/examples/selling/tags.ini) plus [update.pl](batch_convert/examples/selling/update.pl)
  - For each compressed output format, update.pl calls:
    - [rip.pl](batch_convert/bin/rip.pl) (converts .wav to dest compressed format)
      - supports conversion from wav to mp3/flac/ogg
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
brew install flac          # for metaflac as well
brew install lame
brew install vorbis-tools  # for oggenc, vorbiscomment
brew install sox

```

## Windows
*CONTRIBUTE!*  Feel free to contribute instructions for other platforms. :-)

## Linux
*CONTRIBUTE!*  Feel free to contribute instructions for other platforms. :-)

