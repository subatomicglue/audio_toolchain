#!perl
use File::Copy;

# i.e.  subatomicglue - mantis - 01 - hard.flac

$ENV{'PATH'} .= ";../..";

system( 'playlist-gen.pl -i "*.wav" -o ./playlist.m3u' );
system( 'cd-gen.pl -i "*.wav" -o cd.axp' );

system( 'rip.pl -i "*.wav" -o spinningtrees-mp3/ -t mp3' );
system( 'tag.pl -i "spinningtrees-mp3/*.mp3" -c tags.ini' );
system( 'playlist-gen.pl -i "spinningtrees-mp3/*.mp3" -o spinningtrees-mp3/playlist.m3u' );
copy( "Folder.jpg", "spinningtrees-mp3/" );

#system( 'makeshortmp3s.pl' );
#copy( "Folder.jpg", "mp3crunchy-rip/" );

system( 'rip.pl -i "*.wav" -o spinningtrees-ogg/ -t ogg' );
system( 'tag.pl -i "spinningtrees-ogg/*.ogg" -c tags.ini' );
system( 'playlist-gen.pl -i "spinningtrees-ogg/*.ogg" -o spinningtrees-ogg/playlist.m3u' );
copy( "Folder.jpg", "spinningtrees-ogg/" );

system( 'rip.pl -i "*.wav" -o spinningtrees-flac/ -t flac' );
system( 'tag.pl -i "spinningtrees-flac/*.flac" -c tags.ini' );
system( 'playlist-gen.pl -i "spinningtrees-flac/*.flac" -o spinningtrees-flac/playlist.m3u' );
copy( "Folder.jpg", "spinningtrees-flac/" );





