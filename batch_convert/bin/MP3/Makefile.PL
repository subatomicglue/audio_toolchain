use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'MP3::Tag',
    'VERSION_FROM'	=> 'Tag.pm', # finds $VERSION
    'PMLIBDIRS'         => ['Tag', 'MP3::Tag'],
    'AUTHOR'            => '"Thomas Geffert" <thg@users.sourceforge.net>',
    'PREREQ_PM'         => {
				# Compress::Zlib => 0,
			   },
    'PL_FILES'          => {'data_pod.PL'=>'ID3v2-Data.pod'},
    'clean'             => {FILES => 'ID3v2-Data.pod'},
);

# Tell MakeMaker about manifying ID3v2-Data.pod
package MY;
sub manifypods {
    my $self = shift;
    $self->{MAN3PODS}->{'ID3v2-Data.pod'} = '$(INST_MAN3DIR)/MP3::Tag::ID3v2-Data.$(MAN3EXT)';
    $self->SUPER::manifypods(@_);
}
