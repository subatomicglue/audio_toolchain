#!perl
use File::Copy;

# i.e.  subatomicglue - mantis - 01 - hard.flac

$ENV{'PATH'} .= ";T:/subatomicglue/subatomic.music/2011crunchy/bin";

system( 'playlist-gen.pl -i "*.wav" -o ./playlist.m3u' );
system( 'cd-gen.pl -i "*.wav" -o cd.axp' );

#system( 'makeshortmp3s.pl' );
#copy( "Folder.jpg", "mp3crunchy-rip/" );

sub doit( $$ )
{
   my $dest = shift;
   my $type = shift;
   my $cmd;

   $cmd = 'rip.pl -i "*.wav" -o "' . $dest . '" -t ' . $type;
   #print $cmd . "\n";
   system( $cmd );

   $cmd = 'tag.pl -i "' . join('/',$dest,"*.$type") . '" -c tags.ini';
   #print $cmd . "\n";
   system( $cmd );

   $cmd = 'playlist-gen.pl -i "' . join('/',$dest,"*.$type") . '" -o "' . join('/',$dest,"playlist.m3u") . '"';
   #print $cmd . "\n";
   system( $cmd );

   my @files = glob "*.jpg *.txt";
   for my $file (@files)
   {
      #print "copy $file $dest\n";
      copy( $file, $dest );
   }
}

doit( "../selling-mp3", "mp3" );
doit( "../selling-ogg", "ogg" );
doit( "../selling-flac", "flac" );



