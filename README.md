
# About

Here are some command line tools I use for audio processing.

## Sampler Auto Slicing
  - I use these command line scripts to auto convert a single audio file containing recordings of many samples (e.g. separate bass drum hits at different volumes), auto sliced by silence to separate sample files named with the velocity level, and then convert to sfz or sf2 sample sets
    - [slice.sh](slice.sh) auto slices a single audio file containing music instrument samples (separated by silence), into separate .wav files (timmed by silence)
      - uses `sox` to split the file using specified silence level threshold
    - [rename.sh](rename.sh) rename audio files by their peak level.  useful for individual instrument samples.
      - uses `sox` to detect the sound level
    - [sfz.js](sfz.js) command line script to create a .sfz sampler instrument bank
    - [sfz_to_sf2.sh](sfz_to_sf2.sh) and [sf2_to_sfz.sh](sf2_to_sfz.sh) command line scripts to convert between sf2 and sfz sampler formats.
      - uses `polyphone` to do the conversion

## Music Album Batch Conversion
  - I use these scripts to auto convert my albums of raw uncompressed .wav files to distributable mp3/ogg/flac with playlists.
  - every album has a folder with .wav for each track of the album, plus tags.ini plug update.pl
  - For each compressed output format, update.pl calls:
    - [batch_convert/bin/rip.pl](rip.pl) (converts .wav to dest compressed format)
      - supports conversion from wav to mp3/flac/ogg
        - use `lame` for wav to *mp3*
        - use `flac` for wav to *flac*
        - use `oggenc` for wav to *ogg* (mid 2000's I was using oggenc2-aoTuV)
    - [batch_convert/bin/tag.pl](tag.pl) (meta-tags the compressed files)
      - frontend for editing tags in compressed files (ogg/mp3/flac)
        - use perl's MP3::Tag for *mp3* tagging
          - use `lame --help` to generate text for TENC metatag (name of encoder)
        - use `metaflac` for *flac* tagging
        - use `vorbiscomment` for *ogg* tagging
    - [batch_convert/bin/playlist-gen.pl](playlist-gen.pl) (outputs .m3u playlist file for the output set of compressed files)
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
  - flac, lame, metaflac, oggenc, ogginfo, sox, soxi, vorbiscomment, (scripting: perl)

```
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
