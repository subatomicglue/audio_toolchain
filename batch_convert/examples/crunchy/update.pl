#!perl
use File::Copy;

# i.e.  subatomicglue - mantis - 01 - hard.flac

$ENV{'PATH'} .= ";../..";

system( 'playlist-gen.pl -i "*.wav" -o ./playlist.m3u' );
system( 'cd-gen.pl -i "*.wav" -o cd.axp' );

system( 'rip.pl -i "*.wav" -o mp3-rip/ -t mp3' );
system( 'tag.pl -i "mp3-rip/*.mp3" -c tags.ini' );
system( 'playlist-gen.pl -i "mp3-rip/*.mp3" -o mp3-rip/playlist.m3u' );
copy( "Folder.jpg", "mp3-rip/" );

system( 'makeshortmp3s.pl' );
copy( "Folder.jpg", "mp3-shortnames/" );

system( 'rip.pl -i "*.wav" -o ogg-rip/ -t ogg' );
system( 'tag.pl -i "ogg-rip/*.ogg" -c tags.ini' );
system( 'playlist-gen.pl -i "ogg-rip/*.ogg" -o ogg-rip/playlist.m3u' );
copy( "Folder.jpg", "ogg-rip/" );

#system( 'rip.pl -i "*.wav" -o flac-rip/ -t flac' );
#system( 'tag.pl -i "flac-rip/*.flac" -c tags.ini' );
#system( 'playlist-gen.pl -i "flac-rip/*.flac" -o flac-rip/playlist.m3u' );
#copy( "Folder.jpg", "flac-rip/" );


