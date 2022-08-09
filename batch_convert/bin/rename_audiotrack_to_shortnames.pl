#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename; # dirname, basename
use Cwd; # cwd, getcwd
use Cwd 'abs_path';
use File::Path;
use File::Copy;

my $scriptpath = $0;
my $scriptname = basename( $0 );
my $scriptdir = dirname( abs_path( $scriptpath ) );
my $cwd = cwd();

# options:
my $OUTDIR  = "out";
my @args = ();
my $VERBOSE=0;
my $INDIR  = "in";
my $TYPE = "mp3";

#####################################
# scan command line args:
sub usage()
{
   print "$scriptname - Shorten names of files with our audio tracklist naming convention, to track title only:\n";
   print "e.g.:\n";
   print "  \"subatomicglue - inertialdecay - 01 - hard.wav\"  -->  \"hard.wav\"\n";
   print "\n";
   print "Usage:\n";
   print " $scriptname.pl <in dir> <out dir> <type>                           # rename <in dir>/*.<type> files to <out dir>/ (type defaults to \"$TYPE\")\n";
   print " $scriptname.pl \"./myalbum-mp3\" \"./myalbum-mp3-shortnames\" mp3";
   print "\n";
}

# command line can override defaults
my $ARGC=@ARGV;
my $non_flag_args = 0;
my $non_flag_args_required = 2;
for (my $i = 0; $i < $ARGC; $i++)
{
   #print( $i. " " . $ARGV[$i] . "\n");
   if ($ARGV[$i] eq "--help")
   {
    usage();
    exit( -1 );
   }
   if ($ARGV[$i] eq "--verbose")
   {
      $VERBOSE = 1;
      continue
   }
   if (substr( $ARGV[$i], 0, 2 ) eq "--")
   {
      print( "Unknown option ".$ARGV[$i]."\n" );
      exit(-1)
   }
   push( @args, $ARGV[$i] );
   $VERBOSE && print( "Parsing Args: argument #" . ${non_flag_args} . ": \"" . ${ARGV[$i]} . "\"\n" );
   $non_flag_args += 1;
}

# output help if they're getting it wrong...
if ($non_flag_args_required != 0 && ($ARGC == 0 || !($non_flag_args >= $non_flag_args_required))) {
  ($ARGC > 0) && print( "Expected ".${non_flag_args_required}." args, but only got ".${non_flag_args}."\n" );
  usage();
  exit( -1 );
}
##########################################
$INDIR=$args[0];
$OUTDIR=$args[1];
$TYPE=@args > 2 ? $args[2] : $TYPE;

if (! -d "$OUTDIR")
{
   print "Creating dir: $OUTDIR\n";
   mkpath( $OUTDIR );
}

# the files to convert
my @files = glob("$INDIR/*.$TYPE");
foreach (@files)
{
   my $mp3name = $_;

   # convert to MP3
   my $local_filename = $mp3name;
   $local_filename =~ s/^.+[\\\/]//; # remove entire path prefix including last /
   $local_filename =~ /^([^-]+[^\s])\s*-\s*([^-]+[^\s])\s*-\s*([^-]+[^\s])\s*-\s*(.+[^\s])\.([^\.]+)$/; # parse the track info
   my $title = $4;
   my $album = $2;
   my $track = $3;
   my $artist = $1;
   my $ext = $5;

   my $shortname = $OUTDIR . "/" . $title . "." . $ext;
   if (!-f $shortname || ((stat($shortname))[9] < (stat($mp3name))[9]))
   {
      #unlink( $shortname );
      print "Copy \"$mp3name\"  -->  \"$shortname\"\n";
      copy( $mp3name, $shortname );
   }
}

`cp \"$INDIR/"*-*-*README.txt \"$OUTDIR/README.txt\" || echo \"file not found\"`;
`cp \"$INDIR/Folder.jpg\" \"$OUTDIR/\" || echo \"file not found\"`;
