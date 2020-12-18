#!/usr/bin/env perl

use File::Basename; # dirname, basename
use Cwd; # cwd, getcwd
use Cwd 'abs_path';
my $cwd = cwd();

# defaults
$IN_FILES  = "*.mp3";
$OUT_PATH  = "mp3-shortnames";
$BIN_PATH = dirname( abs_path($0) ); # script's directory

sub defaults()
{
  return "in[$IN_FILES] out[$OUT_PATH] scriptdir[$BIN_PATH]";
}

# command line can override defaults
for (my $x = 0; $x < @ARGV; $x++)
{
   if ($ARGV[$x] eq "-o" || $ARGV[$x] eq "-out")
   {
      $x++;
      $OUT_PATH = $ARGV[$x];
      $OUT_PATH =~ s/[\\\/]$//;
   }
   elsif ($ARGV[$x] eq "-i" || $ARGV[$x] eq "-in")
   {
      $x++;
      $IN_FILES = $ARGV[$x];
   }
   else
   {
      print "Shorten names of files with our audio tracklist naming convention:\n";
      print "e.g.:\n";
      print "  \"subatomicglue - inertialdecay - 01 - hard.wav\"  ->  \"hard.wav\"\n";
      print "\n";
      print "usage:\n";
      print " makeshortmp3s.pl                       # rename all mp3 files in current dir to $OUT_PATH\n";
      print " makeshortmp3s.pl -o $OUT_PATH     # specify output dir\n";
      print " makeshortmp3s.pl -i \"../myalbum-mp3/*.mp3\" -o ../myalbum-mp3-shortnames";
      print "\n";
      print "Defaults:\n";
      print " ".defaults()."\n";
      exit -1;
   }
}

print "makeshortmp3s[".defaults()."]\n";

##############################################################
use File::Path;
use File::Copy;

print "Creating dir: $OUT_PATH\n";
mkpath( $OUT_PATH );

# the files to convert
@files = glob($IN_FILES);
print "Renaming " . join(",", @files ) . "\n";
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

   my $shortname = $OUT_PATH . "/" . $title . "." . $ext;
   if (!-f $shortname || ((stat($shortname))[9] < (stat($mp3name))[9]))
   {
      unlink( $shortname );
      print "copy $mp3name to $shortname\n";
      copy( $mp3name, $shortname );
   }
}

