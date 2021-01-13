#!/usr/bin/env perl

use File::Path;

#defaults
$IN_FILES = "*.wav";
$AXP_PATH = "cd.axp";

sub defaults()
{ return "in[$IN_FILES] out[$AXP_PATH]"; }

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
      $AXP_PATH = $ARGV[$x];
   }
   else
   {
      print "Generates a CDBurnerXP project file for burning a CD";
      print "";
      print "usage:\n";
      print " cd-gen.pl -i \"$IN_FILES\" -o $AXP_PATH\n";
      print "\n";
      print "defaults:\n";
      print " ".defaults()."\n";
      exit -1;
   }
}

# the files we want to include output
@files = glob( "$IN_FILES" );

#############################################################################

# Perl trim function to remove whitespace from the start and end of the string
sub trim($)
{
   my $string = shift;
   $string =~ s/^\s+//;
   $string =~ s/\s+$//;
   return $string;
}

# gen some playlists for each converted set...
my $AXP_FOLDER = $AXP_PATH;
if ($AXP_FOLDER =~ s/[\\\/][^\\\/]+$// && !-d "$AXP_FOLDER")
{
  print "creating dir $AXP_FOLDER\n";
  mkpath( $AXP_FOLDER );
}
open( CD_PROJECT_FILE, ">$AXP_PATH" );
print CD_PROJECT_FILE '<?xml version="1.0" encoding="utf-8" standalone="yes"?>
<!DOCTYPE layout PUBLIC "http://www.cdburnerxp.se/help/audio.dtd" "">
<?xml-stylesheet type="text/xsl" href="http://www.cdburnerxp.se/help/compilation.xsl"?>
<!--audio compilation created by CDBurnerXP 4.3.8.2474 (http://cdburnerxp.se)-->
<layout type="Audio" version="4.3.8.2474" date="2/16/2011" time="8:05 PM">' . "\n";

my $once = 1;

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

   # write playlist entry
   if ($once)
   {
      print CD_PROJECT_FILE
            '  <compilation name="audio-template" title="'.$album.
            '" artist="'.$artist.'">' . "\n";
      $once = 0;
   }
   print CD_PROJECT_FILE   '    <track path="'.$local_filename.
                           '" title="'.$title.
                           '" artist="'.$artist.
                           '" number="'.$track.
                           '" />'.
                           "\n";
}

print CD_PROJECT_FILE "  </compilation>\n</layout>\n";
close( CD_PROJECT_FILE );

