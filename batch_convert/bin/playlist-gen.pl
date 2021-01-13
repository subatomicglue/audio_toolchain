#!/usr/bin/env perl

# run this section before "use lib" (which is just BEGIN{require ...} )
BEGIN
{
   use File::Basename; # dirname, basename
   use Cwd; # cwd, getcwd
   use Cwd 'abs_path';
   my $cwd = cwd();

   # defaults
   $IN_FILES = "*.mp3";
   $M3U_PATH  = "playlist.m3u";
   $BIN_PATH = dirname( abs_path($0) ); # script's directory

   sub defaults()
   { return "in[$IN_FILES] out[$M3U_PATH] scriptdir[$BIN_PATH]"; }

   # command line can override defaults
   for (my $x = 0; $x < @ARGV; $x++)
   {
      if ($ARGV[$x] eq "-i" || $ARGV[$x] eq "-in")
      {
         $x++;
         $IN_FILES = $ARGV[$x];
      }
      elsif ($ARGV[$x] eq "-o" || $ARGV[$x] eq "-out")
      {
         $x++;
         $M3U_PATH = $ARGV[$x];
      }
      else
      {
         print "Creates an m3u playlist";
         print "";
         print "usage:\n";
         print " playlist-gen.pl -i \"$IN_FILES\" -o $M3U_PATH\n";
         print "\n";
         print "defaults:\n";
         print " ".defaults()."\n";
         exit -1;
      }
   }
}

print "playlist-gen[".defaults()."]\n";

# the files we want to auto-tag
@files = glob( $IN_FILES );


#############################################################################
use lib "$BIN_PATH";   # where MP3::Tag package is kept
use MP3::Tag;  # mp3 tagger
use POSIX;     # needed for floor()
use File::Path;

# Perl trim function to remove whitespace from the start and end of the string
sub trim($)
{
   my $string = shift;
   $string =~ s/^\s+//;
   $string =~ s/\s+$//;
   return $string;
}

# gen some playlists for each converted set...
my $M3U_FOLDER = $M3U_PATH;
if ($M3U_FOLDER =~ s/[\\\/][^\\\/]+$// && !-d "$M3U_FOLDER")
{
  print "creating dir '$M3U_FOLDER'\n";
   mkpath( $M3U_FOLDER );
}
open( PLAYLIST_M3U_FILE, ">$M3U_PATH" );
print PLAYLIST_M3U_FILE "#EXTM3U\n";

# loop over file list
# print tag information
foreach (@files)
{
   my $filename = $_;

   # extract attributes from the filename
   # we expect file naming like this:
   #    subatomicglue - mantis - 01 - hard.wav
   my $local_filename = $filename;
   $local_filename =~ s/^.+[\\\/]//;
   $local_filename =~ /(.+[^\s])\s*-\s*(.+[^\s])\s*-\s*(.+[^\s])\s*-\s*(.+[^\s])\.([^\.]+)$/;
   my $title = $4;
   my $album = $2;
   my $track = $3;
   my $artist = $1;
   my $ext = $5;
   print "File[$filename]: title[$title] album[$album] track[$track] artist[$artist]\n";

   # for MP3 files
   if ($ext =~ /mp3/i)
   {
      # open mp3 file
      my $mp3 = MP3::Tag->new($filename);
      $mp3->get_tags();

      # write playlist entry
      print PLAYLIST_M3U_FILE "#EXTINF:".$mp3->total_secs_int().",$artist - $title\n";
      print PLAYLIST_M3U_FILE "$local_filename\n";
      $mp3->close();
   }

   # for FLAC files
   if ($ext =~ /flac/i)
   {
      # get running time for the file
      my $samprate = `"metaflac" --show-sample-rate -- "$filename"`;
      my $samples = `"metaflac" --show-total-samples -- "$filename"`;
      my $time = floor(0.5 + $samples / $samprate);

      # write playlist entry
      print PLAYLIST_M3U_FILE "#EXTINF:$time,$artist - $title\n";
      print PLAYLIST_M3U_FILE "$local_filename\n";
   }

   # for OGG files
   if ($ext =~ /ogg/i)
   {
      # get running time for the file
      my $info = join( ";", `"ogginfo" "$filename"` );
      $info =~ /Playback length: ([^;]+)/;
      my $time = trim( $1 );
      $time =~ /(.*)m/;
      my $min = floor( $1 );
      $time =~ /:(.*)s/;
      my $sec = floor( $1 );
      $time = ($min * 60 + $sec);

      # write playlist entry
      print PLAYLIST_M3U_FILE "#EXTINF:$time,$artist - $title\n";
      print PLAYLIST_M3U_FILE "$local_filename\n";
   }

   # for WAV files
   if ($ext =~ /wav/i)
   {
      # get running time for the wav file
      my $secs = floor( `"sox" --i -D "$filename"` );

      # write playlist entry
      print PLAYLIST_M3U_FILE "#EXTINF:$secs,$artist - $title\n";
      print PLAYLIST_M3U_FILE "$local_filename\n";
   }
}

close( PLAYLIST_M3U_FILE );

