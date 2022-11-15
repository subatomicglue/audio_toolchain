#!/usr/bin/env perl

# run this section before "use lib" (which is just BEGIN{require ...} )
BEGIN
{
   use File::Basename; # dirname, basename
   use Cwd; # cwd, getcwd
   use Cwd 'abs_path';
   my $cwd = cwd();

   # defaults
   $IN_FILES  = "";
   $ALBUM_IMG  = "";
   $BIN_PATH = dirname( abs_path($0) ); # my script dir
   $TAGINI = "tags.ini";
   $CWD=$cwd;

   sub defaults()
   { return "in[$IN_FILES] config[$TAGINI] scriptdir[$BIN_PATH] album_image[$ALBUM_IMG]"; }

   # command line can override defaults
   for (my $x = 0; $x < @ARGV; $x++)
   {
      if ($ARGV[$x] eq "-c" || $ARGV[$x] eq "-config")
      {
         $x++;
         $TAGINI = $ARGV[$x];
      }
      elsif ($ARGV[$x] eq "-i" || $ARGV[$x] eq "-in")
      {
         $x++;
         $IN_FILES = $ARGV[$x];
      }
      elsif ($ARGV[$x] eq "-a" || $ARGV[$x] eq "-album_image")
      {
         $x++;
         $ALBUM_IMG = $ARGV[$x];
      }
      else
      {
         print "usage:\n";
         print " tag.pl -i \"mp3-rip/*.mp3\" -c $TAGINI\n";
         print " tag.pl -i \"mp3-rip/*.mp3 flac-rip/*.flac ogg-rip/*.ogg\" -c $TAGINI -a Folder.jpg\n";
         print "\n";
         print "defaults:\n";
         print " ".defaults()."\n";
         exit -1;
      }
   }
}

print "tag[".defaults()."\n";

if (! -f "$TAGINI") {
  my $handle;
  open( $handle, '>>', $TAGINI ) or die("[tag.pl] Cant open '$TAGINI'");
  print( $handle, '# tags (the ones not inferable from the filename)
$ALBUMARTIST="<ARTIST>";
$DATE="<YEAR>";
$SHORTCOMMENT="www.<ARTIST>.com";
$COMMENT="www.<ARTIST>.com";
$COMPOSER="<COMPOSER NAME>";
$PUBLISHER="<PUBLISHER>";
$DISCNUMBER="01";
$BPM="secret"; # no way to tell... bullshit goes here...
$GENRE="<GENRE>";
$URL="http://www.<ARTIST>.com";
$COPYRIGHT="$DATE <ARTIST>";' );
  close ($handle) or die ("[tag.pl] Unable to close '$TAGINI'");
}

# include tag.ini
print "Reading: [$TAGINI]\n";
require "$TAGINI";
print " ::[ '$ALBUMARTIST' '$DATE' '$COMPOSER' '$PUBLISHER' '$GENRE' '$COPYRIGHT' ]::\n";

# the audio files we want to auto-tag (flac/ogg/mp3 types)
@files = glob( $IN_FILES );

#############################################################################
use lib "$BIN_PATH";   # where MP3::Tag package is kept
use MP3::Tag;  # mp3 tagger
use POSIX;     # needed for floor()

sub setframe
{
   my $self = shift;
   $self->remove_frame($_[0]) if defined $self->get_frame($_[0]);
   $self->add_frame(@_);
}

# Perl trim function to remove whitespace from the start and end of the string
sub trim($)
{
   my $string = shift;
   $string =~ s/^\s+//;
   $string =~ s/\s+$//;
   return $string;
}
sub kill_newlines {
    my $text = shift;
    $text =~ s/\n//g;
    $text =~ s/\r//g;
    return $text;
}

@lame_help = `lame --help`;

$SIG{INT}  = \&signal_handler;
$SIG{TERM} = \&signal_handler;
$SIG{QUIT} = \&signal_handler;
sub signal_handler {
  print "SIG death... (!)\n";
  clean_up();
  print "-=====================================================================-\n";
  die "\n";
}

# NOTE: AtomicParsley SEGFAULTS if the jpg resolution (DPI) is 300, install_folder_image makes the image square AND knocks down the DPI to 72...
my $TEMP_DIR=kill_newlines( `mktemp -d -t __temp234758923456` );
my $TEMP_IMAGE="$TEMP_DIR/3478t345.jpg";
if ( -f "$ALBUM_IMG" ) {
  `$BIN_PATH/install_folder_image.sh --max_dimension 500 --echo_pillar_box \"$ALBUM_IMG\" \"$TEMP_IMAGE\"`;
}

sub clean_up {
  if ( -f "$TEMP_DIR" ) {
    #print "[INFO] Removing temporary '$TEMP_DIR'\n";
    `rm -r "$TEMP_DIR"`;
  }
}

# loop over file list
# print tag information
foreach (@files)
{
   my $filename = $_;

   # extract attributes from the filename
   # we expect file naming like this:
   #    subatomicglue - mantis - 01 - hard.mp3
   #    subatomicglue-mantis-01-hard.mp3
   my $local_filename = $filename;
   $local_filename =~ s/^.+[\\\/]//; # remove entire path prefix including last /
   $local_filename =~ /^([^-]+[^\s])\s*-\s*([^-]+[^\s])\s*-\s*([^-]+[^\s])\s*-\s*(.+[^\s])\.([^\.]+)$/; # parse the track info
   my $title = $4;
   my $album = $2;
   my $track = $3;
   my $artist = $1;
   my $ext = $5;
   print "File[$filename]: title[$title] album[$album] track[$track] artist[$artist]\n";
   #print "\"$COMMENT\"\n";

   # tag MP3 files
   if ($ext =~ /mp3/i)
   {
      # open mp3 file
      my $mp3 = MP3::Tag->new($filename);
      $mp3->get_tags();

      # create tags if not present
      if (!exists $mp3->{ID3v1})
      {
         $mp3->new_tag("ID3v1");
      }
      if (!exists $mp3->{ID3v2})
      {
         $mp3->new_tag("ID3v2");
      }

      # print out id3v1
      if (0)
      {
         print "Artist: " . $mp3->{ID3v1}->artist . "\n";
         print "Title: " . $mp3->{ID3v1}->title . "\n";
         print "Album: " . $mp3->{ID3v1}->album . "\n";
         print "Year: " . $mp3->{ID3v1}->year . "\n";
         print "Genre: " . $mp3->{ID3v1}->genre . "\n";
      }

      # print out id3v2
      if (0)
      {
         # get a list of frames as a hash reference
         $frames = $mp3->{ID3v2}->get_frame_ids();

         # iterate over the hash
         # process each frame
         foreach $frame (keys %$frames)
         {
            # for each frame
            # get a key-value pair of content-description
            ($value, $desc) = $mp3->{ID3v2}->get_frame($frame);
            print "$frame $desc: ";
            # sometimes the value is itself a hash reference containing more values
            # deal with that here
            if (ref $value)
            {
               while (($k, $v) = each (%$value))
               {
                  print "\n     - $k: $v";
               }
               print "\n";
            }
            else
            {
               print "$value\n";
            }
         }
      }

      # write id3v1
      if (1)
      {
         # save track information
         $mp3->{ID3v1}->title($title);
         $mp3->{ID3v1}->track($track);
         $mp3->{ID3v1}->artist($artist);
         $mp3->{ID3v1}->comment($SHORTCOMMENT);
         $mp3->{ID3v1}->album($album);
         $mp3->{ID3v1}->year($DATE);
         $mp3->{ID3v1}->genre($GENRE);
         $mp3->{ID3v1}->write_tag();
      }

      # write id3v2
      if (1)
      {
         setframe( $mp3->{ID3v2}, 'TALB', $album );         #album
         setframe( $mp3->{ID3v2}, 'TCON', $GENRE );         #genre
         setframe( $mp3->{ID3v2}, 'TPE1', $artist );        #artist
         setframe( $mp3->{ID3v2}, 'COMM', "", "", $COMMENT );#comment
         setframe( $mp3->{ID3v2}, 'TCOM', $COMPOSER );      #composer
         setframe( $mp3->{ID3v2}, 'TRCK', $track );         #track
         setframe( $mp3->{ID3v2}, 'TYER', $DATE );          #year
         setframe( $mp3->{ID3v2}, 'TIT2', $title );         #title
         setframe( $mp3->{ID3v2}, 'TPUB', $PUBLISHER );     #publisher
         setframe( $mp3->{ID3v2}, 'TPOS', $DISCNUMBER );    #disc
         setframe( $mp3->{ID3v2}, 'TOPE', $ALBUMARTIST );   #original artist
         setframe( $mp3->{ID3v2}, 'TPE2', $ALBUMARTIST );   #album artist
         setframe( $mp3->{ID3v2}, 'WXXX', 0, "", $URL );    #URL
         setframe( $mp3->{ID3v2}, 'TCOP', $COPYRIGHT );     #copyright
         setframe( $mp3->{ID3v2}, 'TENC', trim( $lame_help[0] ) );#encoded by
         setframe( $mp3->{ID3v2}, 'TBPM', $BPM );           #bpm

         $mp3->{ID3v2}->write_tag();
      }

      $mp3->close();
   }

   # tag FLAC files
   if ($ext =~ /flac/i)
   {
      my $cmd = "metaflac ".
                "--remove-tag=TITLE --set-tag=\"TITLE=$title\" ".
                "--remove-tag=ARTIST --set-tag=\"ARTIST=$artist\" ".
                "--remove-tag=ALBUM --set-tag=\"ALBUM=$album\" ".
                "--remove-tag=\"ALBUM ARTIST\" --set-tag=\"ALBUM ARTIST=$ALBUMARTIST\" ".
                "--remove-tag=DATE --set-tag=\"DATE=$DATE\" ".
                "--remove-tag=COMMENT --set-tag=\"COMMENT=$COMMENT\" ".
                "--remove-tag=COMPOSER --set-tag=\"COMPOSER=$COMPOSER\" ".
                "--remove-tag=PUBLISHER --set-tag=\"PUBLISHER=$PUBLISHER\" ".
                "--remove-tag=TRACKNUMBER --set-tag=\"TRACKNUMBER=$track\" ".
                "--remove-tag=DISCNUMBER --set-tag=\"DISCNUMBER=$DISCNUMBER\" ".
                "--remove-tag=BPM --set-tag=\"BPM=$BPM\" ".
                "--remove-tag=GENRE --set-tag=\"GENRE=$GENRE\" ".
                "-- \"$filename\" ";
      `$cmd`;
   }

   # tag OGG files
   if ($ext =~ /ogg/i)
   {
      my $cmd = "vorbiscomment -w ".
                "-t \"TITLE=$title\" ".
                "-t \"ARTIST=$artist\" ".
                "-t \"ALBUM=$album\" ".
                "-t \"ALBUM ARTIST=$ALBUMARTIST\" ".
                "-t \"DATE=$DATE\" ".
                "-t \"COMMENT=$COMMENT\" ".
                "-t \"COMPOSER=$COMPOSER\" ".
                "-t \"PUBLISHER=$PUBLISHER\" ".
                "-t \"TRACKNUMBER=$track\" ".
                "-t \"DISCNUMBER=$DISCNUMBER\" ".
                "-t \"BPM=$BPM\" ".
                "-t \"GENRE=$GENRE\" ".
                "-- \"$filename\" ";
      #print $cmd . "\n\n";
      `$cmd`;
   }

   # tag M4A files
   if ($ext =~ /m4a/i)
   {
      my $cmd = "tmp_dir=\$(mktemp -d -t __temp2435789234759) && ".
                "AtomicParsley \"$filename\" ".
                "--title \"$title\" ".
                "--artist \"$artist\" ".
                "--album \"$album\" ".
                "--albumArtist \"$ALBUMARTIST\" ".
                "--year \"$DATE\" ".
                "--comment \"$COMMENT\" ".
                "--description \"$COMMENT\" ".
                "--longdesc \"Publisher: $PUBLISHER  URL: $URL\" ".
                "--composer \"$COMPOSER\" ".
                "--tracknum \"$track\" ".
                "--disk \"$DISCNUMBER\" ".
                "--bpm \"$BPM\" ".
                "--genre \"$GENRE\" ".
                "--copyright \"$COPYRIGHT\" ".
                #"--encodingTool \"subatomiclabs batch tools (fdkaac or faac)\" ".
                #"--encodedBy \"subatomiclabs\" ".
                "--podcastURL \"$URL\" ".
                #"--overwrite"
                "--title \"$title\" ".
                "-o \"\$tmp_dir/__temp2435789234759.m4a\" && mv \"\$tmp_dir/__temp2435789234759.m4a\" \"$filename\"; rm -rf \"\${tmp_dir}\"";
      `$cmd`;
   }

   # add the album cover to mp3
   if ($ext =~ /mp3/i && -f "$TEMP_IMAGE")
   {
     my $cmd = "eyeD3 -Q --preserve-file-times --add-image=\"$TEMP_IMAGE\":FRONT_COVER:\"Album cover\" \"$filename\"";
     `$cmd`;
   }

   # add the album cover to m4a
   if ($ext =~ /m4a/i && -f $TEMP_IMAGE)
   {
     my $cmd = "tmp_dir=\$(mktemp -d -t __temp2435789234759) && ".
               "AtomicParsley \"$filename\" ".
               "--artwork '$TEMP_IMAGE' ".
               #"--overwrite".
               "-o \"\$tmp_dir/__temp2435789234759.m4a\" && mv \"\$tmp_dir/__temp2435789234759.m4a\" \"$filename\"; rm -rf \"\${tmp_dir}\"";
     `$cmd`;
   }

   # add the album cover to flac
   if ($ext =~ /flac/i && -f "$TEMP_IMAGE")
   {
     my $cmd = "metaflac --import-picture-from=\"$TEMP_IMAGE\" \"$filename\"";
     `$cmd`;
   }

   # add the album cover to ogg
   if ($ext =~ /ogg/i && -f "$TEMP_IMAGE")
   {
     my $cmd = "$BIN_PATH/ogg-cover-art.sh \"$TEMP_IMAGE\" \"$filename\" > /dev/null 2>&1";
     #print $cmd . "\n";
     `$cmd`;
   }

   # add the album cover to mp4
   if ($ext =~ /mp4/i && -f "$TEMP_IMAGE")
   {
      my $cmd = "";
      print "DONE:  Already implemented in rip.pl, since we encode the image into the video stream using ffmpeg\n";
      #`$cmd`
   }
}

