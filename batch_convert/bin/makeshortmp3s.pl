#/usr/bin/perl

## SETUP ##

# Paths
$MP3_PATH  = "mp3-rip";
$SHORT_PATH  = "mp3-shortnames";
#$BIN_PATH = "../bin";

# the files to convert
@files = <$MP3_PATH/*.mp3>;


##############################################################
use File::Path;
use File::Copy;

mkpath( $SHORT_PATH );

foreach (@files)
{
   my $mp3name = $_;

   # convert to MP3
   my $local_filename = $mp3name;
   $local_filename =~ s/^.+[\\\/]//;
   $local_filename =~ /(.+[^\s])\s*-\s*(.+[^\s])\s*-\s*(.+[^\s])\s*-\s*(.+[^\s])\.([^\.]+)$/;
   my $title = $4;
   my $album = $2;
   my $track = $3;
   my $artist = $1;
   my $ext = $5;

   my $shortname = $SHORT_PATH . "/" . $title . "." . $ext;
   if (!-f $shortname || ((stat($shortname))[9] < (stat($mp3name))[9]))
   {
      unlink( $shortname );
      print "copy $mp3name to $shortname\n";
      copy( $mp3name, $shortname );
   }
}

