#!perl
use File::Copy;

# i.e.  subatomicglue - mantis - 01 - hard.flac

###################################################################
my $DIRNAME="inertialdecay";
my $BINDIR="../../";
###################################################################

$ENV{'PATH'} .= ";$BINDIR";

system( $BINDIR . '/playlist-gen.pl -i "*.wav" -o ./playlist.m3u' );
system( $BINDIR . '/cd-gen.pl -i "*.wav" -o cd.axp' );

#system( $BINDIR . '/makeshortmp3s.pl' );
#copy( "Folder.jpg", "mp3crunchy-rip/" );

sub doit( $$ )
{
   my $dest = shift;
   my $type = shift;
   my $cmd;

   $cmd = $BINDIR . '/rip.pl -i "*.wav" -o "' . $dest . '" -t ' . $type;
   print $cmd . "\n";
   system( $cmd );

   $cmd = $BINDIR . '/tag.pl -i "' . join('/',$dest,"*.$type") . '" -c tags.ini';
   print $cmd . "\n";
   system( $cmd );

   $cmd = $BINDIR . '/playlist-gen.pl -i "' . join('/',$dest,"*.$type") . '" -o "' . join('/',$dest,"playlist.m3u") . '"';
   print $cmd . "\n";
   system( $cmd );

   my @files = glob "*.jpg *.txt";
   for my $file (@files)
   {
      print "copy $file $dest\n";
      copy( $file, $dest );
   }
}

doit( "../$DIRNAME-mp3", "mp3" );
doit( "../$DIRNAME-ogg", "ogg" );
doit( "../$DIRNAME-flac", "flac" );


