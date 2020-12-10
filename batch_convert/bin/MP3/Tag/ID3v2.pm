package MP3::Tag::ID3v2;

# Copyright (c) 2000-2004 Thomas Geffert.  All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the Artistic License, distributed
# with Perl.

use strict;
use File::Basename;
# use Compress::Zlib;

use vars qw /%format %long_names %res_inp @supported_majors %v2names_to_v3 $VERSION @ISA/;

$VERSION="0.91";
@ISA = 'MP3::Tag::__hasparent';

# ignore different $\ settings, otherwise tags may not be written correctly
local $\="";

=pod

=head1 NAME

MP3::Tag::ID3v2 - Read / Write ID3v2.x.y tags from mp3 audio files

=head1 SYNOPSIS

MP3::Tag::ID3v2 supports
  * Reading of ID3v2.2.0 and ID3v2.3.0 tags
  * Writing of ID3v2.3.0 tags

MP3::Tag::ID3v2 is designed to be called from the MP3::Tag module.

  use MP3::Tag;
  $mp3 = MP3::Tag->new($filename);

  # read an existing tag
  $mp3->get_tags();
  $id3v2 = $mp3->{ID3v2} if exists $mp3->{ID3v2};

  # or create a new tag
  $id3v2 = $mp3->new_tag("ID3v2");

See L<MP3::Tag|according documentation> for information on the above used functions.

* Reading a tag

  $frameIDs_hash = $id3v2->get_frame_ids('truename');

  foreach my $frame (keys %$frameIDs_hash) {
      my ($name, @info) = $id3v2->get_frame($frame);
      for my $info (@info) {  
	  if (ref $info) {
	      print "$name ($frame):\n";
	      while(my ($key,$val)=each %$info) {
		  print " * $key => $val\n";
             }
          } else {
	      print "$name: $info\n";
          }
      }
  }

* Adding / Changing / Removing / Writing a tag

  $id3v2->add_frame("TIT2", "Title of the song");
  $id3v2->change_frame("TALB","Greatest Album");
  $id3v2->remove_frame("TLAN");
  $id3v2->write_tag();

* Removing the whole tag

  $id3v2->remove_tag();

* Get information about supported frames

  %tags = $id3v2->supported_frames();
  while (($fname, $longname) = each %tags) {
      print "$fname $longname: ", 
            join(", ", @{$id3v2->what_data($fname)}), "\n";
  }

=head1 AUTHOR

Thomas Geffert, thg@users.sourceforge.net

=head1 DESCRIPTION

=over 4

=pod

=item get_frame_ids()

  $frameIDs = $tag->get_frame_ids;
  $frameIDs = $tag->get_frame_ids('truename');

  [old name: getFrameIDs() . The old name is still available, but you should use the new name]

get_frame_ids loops through all frames, which exist in the tag. It
returns a hash reference with a list of all available Frame IDs. The
keys of the returned hash are 4-character-codes (short names), the
internal names of the frames, the according value is the english
(long) name of the frame.

You can use this list to iterate over all frames to get their data, or to
check if a specific frame is included in the tag.

If there are multiple occurences of a frame in one tag, the first frame is
returned with its normal short name, following frames of this type get a
'00', '01', '02', ... appended to this name.  These names can then
used with C<get_frame> to get the information of these frames.  These
fake frames are not returned if C<'truename'> argument is set; one
can still use C<get_frames()> to extract the info for all of the frames with
the given short name.

=cut

###### structure of a tag frame
#
# major=> Identifies format of frame, normally set to major version of the whole
#         tag, but many ID3v2.2 frames are converted automatically to ID3v2.3 frames
# flags=> Frame flags, depend on major version
# data => Data of frame
# gid  => group id, if any
#


sub get_frame_ids {
        my $self=shift;
        my $basic = shift;

	# frame headers format for the different majors
	my $headersize = (0,0,6,10,10)[$self->{major}];
	my $headerformat=("","","a3a3","a4Nn","a4a4n")[$self->{major}];

	if (exists $self->{frameIDs}) {
	        return unless defined wantarray;
		my %return;
		foreach (keys %{$self->{frames}}) {
		    next if $basic and length > 4;   # ignore frames with 01 etc. at end
		    $return{$_}=$long_names{substr($_,0,4)};
		}
		return \%return;
	}

	my $pos=$self->{frame_start};
	if ($self->{flags}->{extheader}) {
		warn "get_frame_ids: possible wrong IDs because of unsupported extended header\n";
	}
	my $buf;
	while ($pos+$headersize < $self->{data_size}) {
		$buf = substr ($self->{tag_data}, $pos, $headersize);
		my ($ID, $size, $flags) = unpack($headerformat, $buf);
		# tag size is handled differently for all majors
		if ($self->{major}==2) {
			# flags don't exist in id3v2.2
			$flags=0;
			my $rawsize=$size;
			$size=0;
			foreach (unpack("C3", $rawsize)) {
				$size = ($size << 8) + $_;
			}
		} elsif ($self->{major}==4) {
			my $rawsize=$size;
			$size=0;
			foreach (unpack("C4", $rawsize)) {
				$size = ($size << 7) + $_;
			}
		} elsif ($self->{major}==3 and $size>255) {
			# Size>255 means at least 2 bytes are used for size.
			# Some programs use (incorectly) for the frame size
			# the format of the tag size (snchsafe). Trying do detect that here
			if ($pos+10+$size> $self->{data_size} ||
			    !exists $long_names{substr ($self->{tag_data}, $pos+$size,4)}) {
				# wrong size or last frame
				my $fsize=0;
				foreach (unpack("x4C4", $buf)) {
					$fsize = ($fsize << 7) + $_;
				}
				if ($pos+20+$fsize<$self->{data_size} &&
				    exists $long_names{substr ($self->{tag_data}, $pos+10+$fsize,4)}) {
					warn "Probably wrong size format found in frame $ID. Trying to correct it\n";
					#probably false size format detected, using corrected size
					$size = $fsize;
				}
			}
		}

		if ($ID !~ "\000\000\000") {
		        my $major = $self->{major};
			if ($self->{major}==2) {
				# most frame IDs can be converted directly to id3v2.3 IDs
				 if (exists  $v2names_to_v3{$ID}) {
				     # frame is direct convertable to major 3
				     $ID = $v2names_to_v3{$ID};
				     $major=3;
				 }
			}
			if (exists $self->{frames}->{$ID}) {
			        ++$self->{extra_frames}->{$ID};
			        $ID .= '01';
				while (exists $self->{frames}->{$ID}) {
					$ID++;
				}
			}

			$self->{frames}->{$ID} = {flags=>check_flags($flags, $self->{major}),
						  major=>$major,
						  data=>substr($self->{tag_data}, $pos+$headersize, $size)};
			$pos += $size+$headersize;
		} else { # Padding reached, cut tag data here
			last;
		}
	}
	# tag is seperated into frames, tagdata not more needed
	$self->{tag_data}="";
	
	$self->{frameIDs} =1;
	my %return;
	foreach (keys %{$self->{frames}}) {
	        next if $basic and length > 4;   # ignore frames with 01 etc. at end
		$return{$_}=$long_names{substr($_,0,4)};
	}
	return \%return;
}

*getFrameIDs = \&get_frame_ids;

=pod

=item get_frame()

  ($info, $name, @rest) = $tag->get_frame($ID);
  ($info, $name, @rest) = $tag->get_frame($ID, 'raw');

  [old name: getFrame() . The old name is still available, but you should use the new name]

get_frame gets the contents of a specific frame, which must be specified by the
4-character-ID (aka short name). You can use C<get_frame_ids> to get the IDs of
the tag, or use IDs which you hope to find in the tag. If the ID is not found, 
C<get_frame> returns empty list, so $info and $name become undefined.

Otherwise it extracts the contents of the frame. Frames in ID3v2 tags can be
very small, or complex and huge. That is the reason, that C<get_frame> returns
the frame data in two ways, depending on the tag.

If it is a simple tag, with only one piece of data, this date is returned
directly as ($info, $name), where $info is the text string, and $name is the
long (english) name of the frame.

If the frame consist of different pieces of data, $info is a hash reference, 
$name is again the long name of the frame.

The hash, to which $info points, contains key/value pairs, where the key is 
always the name of the data, and the value is the data itself.

If the name starts with a underscore (as eg '_code'), the data is probably
binary data and not printable. If the name starts without an underscore,
it should be a text string and printable.

If the second parameter 'raw' is given, the whole frame data is returned,
but not the frame header.  If the second parameter is 'intact', no mangling
of embedded C<"\0"> and trailing spaces is performed.

If the data was stored compressed, it is
uncompressed before it is returned (even in raw mode). Then $info contains a string
with all data (which might be binary), and $name the long frame name.

See also L<MP3::Tag::ID3v2-Data> for a list of all supported frames, and
some other explanations of the returned data structure.

If more than one frame with name $ID is present, @rest contains $info fields
for all consequent frames with the same name.

! Encrypted frames are not supported yet !

! Some frames are not supported yet, but the most common ones are supported !

=cut

sub get_frame {
    my ($self, $fname, $raw)=@_;
    $self->get_frame_ids() unless exists $self->{frameIDs};
    return unless exists $self->{frames}->{$fname};
    my $frame=$self->{frames}->{$fname};
    my ($e, @extra) = 0;				# More frames follow?
    $e = $self->{extra_frames}->{$fname} || 0
            if wantarray and $self->{extra_frames};
    @extra = map scalar $self->get_frame((sprintf "%s%02d", $fname, $_), $raw),
            1..$e;
    $fname = substr ($fname, 0 ,4);
    my $start_offset=0;
    if ($frame->{flags}->{encryption}) {
	warn "Frame $fname: encryption not supported yet\n" ;
	return;
    }

    my $result = $frame->{data};

    if ($frame->{flags}->{groupid}) {
	$frame->{gid} = substring $result, 0, 1;
	$result = substring $result, 1;
    }

    if ($frame->{flags}->{compression}) {
	my $usize=unpack("N", $result);
	require Compress::Zlib;
	$result = Compress::Zlib::uncompress(substr ($result, 4));
	warn "$fname: Wrong size of uncompressed data\n" if $usize=!length($result);
    }

    if (defined $raw and $raw eq 'raw') {
      return ($result, $long_names{$fname}, @extra) if (wantarray);
      return $result;
    }

    my $format = get_format($fname);
    if (defined $format) {
      $format = [map +{%$_}, @$format], $format->[-1]{data} = 1
	if defined $raw and $raw eq 'intact';
      $result = extract_data($result, $format);
      if (scalar keys %$result == 1 && exists $result->{Text}) {
	$result= $result->{Text};
      }
    }
    if (wantarray) {
      return ($result, $long_names{$fname}, @extra);
    } else {
      return $result;
    }
}

*getFrame= \&get_frame;


=pod

=item get_frame_option()

  $options = get_frame_option($ID);

  Option is a hash reference, the hash contains all possible options.
  The value for each option is 0 or 1.

  groupid    -- not supported yet
  encryption -- not supported yet
  compression -- Compresses frame before writing tag; 
                 compression/uncompression is done automatically
  read_only   -- Ignored by this library, should be obeyed by application
  file_preserv -- Ignored by this library, should be obeyed by application
  tag_preserv -- Ignored by this library, should be obeyed by application

=cut

sub get_frame_option {
    my ($self, $fname)=@_;
    $self->get_frame_ids() unless exists $self->{frameIDs};
    return undef unless exists $self->{frames}->{$fname};
    return $self->{frames}->{$fname}->{flags};
}

=pod

=item set_frame_option()

  $options = set_frame_option($ID, $option, $value);

  Set $option to $value (0 or 1). If successfull the new set of
  options is returned, undef otherwise.

  groupid    -- not supported yet
  encryption -- not supported yet
  compression -- Compresses frame before writing tag; 
                 compression/uncompression is done automatically
  read_only   -- Ignored by this library, should be obeyed by application
  file_preserv -- Ignored by this library, should be obeyed by application
  tag_preserv -- Ignored by this library, should be obeyed by application


=cut

sub set_frame_option {
    my ($self, $fname,$option,$value)=@_;
    $self->get_frame_ids() unless exists $self->{frameIDs};
    return undef unless exists $self->{frames}->{$fname};
    if (exists $self->{frames}->{$fname}->{flags}->{$option}) {
	    $self->{frames}->{$fname}->{flags}->{$option}=$value?1:0;
    } else {
	    warn "Unknown option $option\n";
	    return undef;
    }
    return $self->{frames}->{$fname}->{flags};
}

# build_tag()
# create a string with the complete tag data
sub build_tag {
    my ($self, $ignore_error) = @_;
    my $tag_data;

    # in which order should the frames be sorted?
    # with a simple sort the order of frames of one type is the order of adding them
    my @frames=sort keys %{$self->{frames}};

    for my $frameid (@frames) {
  	    my $frame = $self->{frames}->{$frameid};

	    if ($frame->{major}!=3) {
		    #try to convert to ID3v2.3 or
		    warn "Can't convert $frameid to ID3v2.3\n";
		    next if ($ignore_error);
		    return undef;
	    }
	    my $data = $frame->{data};
	    my %flags = ();
	    #compress data if this is wanted
	    if ($frame->{flags}->{compression} || $self->{flags}->{compress_all}) {
		    $flags{compression} = 1;
		    $data = pack("N", length($data)) . compress $data unless $frame->flags->{unchanged};
	    }

	    #encrypt data if this is wanted
	    if ($frame->{flags}->{encryption} || $self->{flags}->{encrypt_all}) {
	            if ($frame->{flags}->{unchanged}) {
		            $flags{encryption} = 1;
		    } else {
		            # ... not supported yet
		            return undef unless $ignore_error;
		            warn "Encryption not supported yet\n";
		    }
	    }

	    # set groupid
	    if ($frame->{flags}->{group_id}) {
		    return undef unless $ignore_error;
		    warn "Group ids are not supported in writing\n";
	    }

	    #prepare header
	    my $header = substr($frameid,0,4) . pack("Nn", length ($data), build_flags(%flags));

	    $tag_data .= $header . $data;
    }
    return $tag_data;
}

# insert_space() copies a mp3-file and can insert one or several areas
# of free space for a tag. These areas are defined as
# ($pos, $old_size, $new_size)
# $pos says at which position of the mp3-file the space should be inserted
# new_size gives the size of the space to insert and old_size can be used
# to skip this size in the mp3-file (e.g if 
sub insert_space {
	my ($self, $insert) = @_;
	my $mp3obj = $self->{mp3};
	# !! use a specific tmp-dir here
	my $tempfile = dirname($mp3obj->{filename}) . "/TMPxx";
	my $count = 0;
	while (-e $tempfile . $count . ".tmp") {
		if ($count++ > 999) {
			warn "Problems with tempfile\n";
			return undef;
		}
	}
	$tempfile .= $count . ".tmp";
	unless (open (NEW, ">$tempfile")) {
		warn "Can't open '$tempfile' to insert tag\n";
		return -1;
	}
	my ($buf, $pos_old);
	binmode NEW;
	$pos_old=0;
	$mp3obj->seek(0,0);

	foreach my $ins (@$insert) {
		if ($pos_old < $ins->[0]) {
			$pos_old += $ins->[0];
			while ($mp3obj->read(\$buf,$ins->[0]<16384?$ins->[0]:16384)) {
				print NEW $buf;
				$ins->[0] = $ins->[0]<16384?0:$ins->[0]-16384;
			}
		}
		for (my $i = 0; $i<$ins->[2]; $i++) {
			print NEW chr(0);
		}
		if ($ins->[1]) {
			$pos_old += $ins->[1];
			$mp3obj->seek($pos_old,0);
		}
	}

	while ($mp3obj->read(\$buf,16384)) {
		print NEW $buf;
	}
	close NEW;
	$mp3obj->close;

	# rename tmp-file to orig file
	unless (( rename $tempfile, $mp3obj->{filename})||
	    (system("mv",$tempfile,$mp3obj->{filename})==0)) {
		unlink($tempfile);
		warn "Couldn't rename temporary file $tempfile to $mp3obj->{filename}\n";
		return -1;
	}
	return 0;
}

=pod

=item get_frames()

  ($name, @info) = get_frames($ID);
  ($name, @info) = get_frames($ID, 'raw');

Same as get_frame() with different order of the returned values.
$name and elements of the array @info have the same semantic as for
get_frame(); each frame with id $ID produces one elements of array @info.

=cut

sub get_frames {
    my ($self, $fname, $raw) = @_;
    my ($info, $name, @rest) = $self->get_frame($fname, $raw) or return;
    return ($name, $info, @rest);
}


=item write_tag()

  $id3v2->write_tag($ignore_error);

Saves all frames to the file. It tries to update the file in place,
when the space of the old tag is big enough for the new tag.
Otherwise it creates a temp file with a new tag (i.e. copies the whole
mp3 file) and renames/moves it to the original file name.

An extended header with CRC checksum is not supported yet.

Encryption of frames and group ids are not supported. If $ignore_error
is set, these options are ignored and the frames are saved without these options.
If $ignore_error is not set and a tag with an unsupported option should be save, the
tag is not written and a 0 is returned.

If a tag with an encrypted frame is read, and the frame is not changed
it can be saved encrypted again.

ID3v2.2 tags are converted automatically to ID3v2.3 tags during
writing. If a frame cannot be converted automatically (PIC; CMR),
writing aborts and returns a 0. If $ignore_error is true, only not
convertable frames are ignored and not written, but the rest of the
tag is saved as ID3v2.3.

At the moment the tag is automatically unsynchronized.

If the tag is written successfully, 1 is returned.

=cut

sub write_tag {
    my ($self,$ignore_error) = @_;

    if ($self->{major}>3) {
	    warn "Only writing of ID3v2.3 is supported. Cannot convert ID3v".
	      $self->{version}." to ID3v2.3 yet.\n";
	    return undef;
    }

    # which order should tags have?

    my $tag_data = build_tag($self, $ignore_error);
    return 0 unless defined $tag_data;

    # perhaps search for first mp3 data frame to check if tag size is not
    # too big and will override the mp3 data

    #ext header are not supported yet
    my $flags = chr(0);
    $flags = chr(128) if $tag_data =~ s/\xFF(?=[\x00\xE0-\xFF])/\xFF\x00/g; # sync
    my $taglen = length $tag_data;

    my $header = 'ID3' . chr(3) . chr(0);

    # actually write the tag
    my $mp3obj = $self->{mp3};

    my $padding = (length $tag_data and chr(0xFF) eq substr $tag_data, -1, 1);
    my $padtail = $self->{tagsize} - length ($tag_data);
    if ($padding > $padtail) {
	# if creating new tag / increasing size add at least 2k padding
	# add additional bytes to make new filesize multiple of 4k
	my $filesize = (stat($mp3obj->{filename}))[7];
	my $newsize = ($filesize + $taglen - $self->{tagsize} + 0x800);
	$newsize = (($newsize + 0xFFF) & ~0xFFF);
	$padding = $newsize - $taglen - ($filesize - $self->{tagsize});
	my @insert_space = ([0, $self->{tagsize}+10, $taglen + $padding + 10]);
	return undef unless (insert_space($self, \@insert_space)==0);
        $padtail = 0;				# 0s written by insert_space...
	$self->{tagsize} = $taglen + $padding;
    } else {					# Keep tagsize
	$padding = $padtail;			# Automatically >=0
    }

    #convert size to header format specific size
    my $size = unpack('B32', pack ('N', $self->{tagsize}));
    substr ($size, -$_, 0) = '0' for (qw/28 21 14 7/);
    $size= pack('B32', substr ($size, -32));

    $mp3obj->close;
    if ($mp3obj->open("write")) {
	    $mp3obj->seek(0,0);
	    $mp3obj->write($header);
	    $mp3obj->write($flags);
	    $mp3obj->write($size);
	    $mp3obj->write($tag_data);
	    $mp3obj->write(chr(0) x $padtail) if $padtail;
    } else {
	    warn "Couldn't open file write tag!";
	    return undef;
    }
    return 1;
}

=pod

=item remove_tag()

  $id3v2->remove_tag();

Removes the whole tag from the file by copying the whole
mp3-file to a temp-file and renaming/moving that to the
original filename.

Do not use remove_tag() if you only want to change a header,
as otherwise the file is copied unneccessary. Use write_tag()
directly, which will override an old tag.

=cut 

sub remove_tag {
    my $self = shift;
    my $mp3obj = $self->{mp3};  
    my $tempfile = dirname($mp3obj->{filename}) . "/TMPxx";
    my $count = 0;
    while (-e $tempfile . $count . ".tmp") {
	if ($count++ > 999) {
	    warn "Problems with tempfile\n";
	    return undef;
	}
    }
    $tempfile .= $count . ".tmp";
    if (open (NEW, ">$tempfile")) {
	my $buf;
	binmode NEW;
	$mp3obj->seek($self->{tagsize}+10,0);
	while ($mp3obj->read(\$buf,16384)) {
	    print NEW $buf;
	}
	close NEW;
	$mp3obj->close;
	unless (( rename $tempfile, $mp3obj->{filename})||
		(system("mv",$tempfile,$mp3obj->{filename})==0)) {
	    warn "Couldn't rename temporary file $tempfile\n";    
	}
    } else {
	warn "Couldn't write temp file\n";
	return undef;
    }
    return 1;
}

=pod

=item add_frame()

  $fn = $id3v2->add_frame($fname, @data);

Add a new frame, identified by the short name $fname. 
The $data must consist from so much elements, as described
in the ID3v2.3 standard. If there is need to give an encoding
parameter and you would like standard ascii encoding, you
can omit the parameter or set it to 0. Any other encoding
is not supported yet, and thus ignored. 

It returns the the short name $fn, which can differ from
$fname, when there existed already such a frame. If no
other frame of this kind is allowed, an empty string is
returned. Otherwise the name of the newly created frame
is returned (which can have a 01 or 02 or ... appended). 

@data must be undef or the number of elements of @data must 
be equal to the number of fields of the tag. See also 
L<MP3::Tag::ID3v2-Data>.

You have to call write_tag() to save the changes to the file.

Examples:

 $f = add_frame("TIT2", 0, "Abba");   # $f="TIT2"
 $f = add_frame("TIT2", "Abba");      # $f="TIT201", encoding=0 implicit

 $f = add_frame("COMM", "ENG", "Short text", "This is a comment");

 $f = add_frame("COMM");              # creates an empty frame

 $f = add_frame("COMM", "ENG");       # ! wrong ! $f=undef, becaues number 
                                      # of arguments is wrong

=cut 

sub add_frame {
    my ($self, $fname, @data) = @_;
    $self->get_frame_ids() unless exists $self->{frameIDs};
    my $format = get_format($fname);
    return undef unless defined $format;

    #prepare the data
    my $args = $#$format;

    unless (@data) {
	@data = map {""} @$format;
    }

    # encoding is not used yet
    my $encoding=0;
    my $defenc=0;
    $defenc = 1 if (($#data == ($args - 1)) && ($format->[0]->{name} eq "_encoding"));
    return 0 unless $#data == $args || defined $defenc;

    my $datastring="";
    foreach my $fs (@$format) {
	if ($fs->{name} eq "_encoding") {
	    $encoding = shift @data unless $defenc;
	    warn "Encoding of text not supported yet\n" if $encoding;
	    $encoding = 0; # other values are not used yet, so let's not write them in a tag
	    $datastring .= chr($encoding);
	    next;
	}
	my $d = shift @data;
	if ($fs->{isnum}) {
	  ## store data as number
	  my $num = int($d);
	  $d="";
 	  while ($num) { $d=pack("C",$num % 256) . $d; $num = int($num/256);}
	  if ( exists $fs->{len} and $fs->{len}>0 ) {
	    $d = substr $d, -$fs->{len};
	    $d = ("\x00" x ($fs->{len}-length($d))) . $d if length($d) < $fs->{len};
	  }
	  if ( exists $fs->{mlen} and $fs->{mlen}>0 ) {
	    $d = ("\x00" x ($fs->{mlen}-length($d))) . $d if length($d) < $fs->{mlen};
	  }
	}elsif ( exists $fs->{len} ) {
	  if ($fs->{len}>0) {
	    $d = substr $d, 0, $fs->{len};
	    $d .= " " x ($fs->{len}-length($d)) if length($d) < $fs->{len};
	  }elsif ($fs->{len}==0) {
	    $d .= chr(0);
	  }
	}elsif (exists $fs->{mlen} and $fs->{mlen}>0) {
	    $d .= " " x ($fs->{mlen}-length($d)) if length($d) < $fs->{mlen};
	}
	$datastring .= $d;
    }

    #add frame to tag
    if (exists $self->{frames}->{$fname}) {
	$fname .= '01';
	while (exists $self->{frames}->{$fname}) {
	    $fname++;
	}
    }
    $self->{frames}->{$fname} = {flags=>check_flags(0), major=>3,
				 data=>$datastring };
    return $fname;
}

=pod

=item change_frame()

  $id3v2->change_frame($fname, @data);

Change an existing frame, which is identified by its
short name $fname. @data must be same as in add_frame;

If the frame $fname does not exist, undef is returned.

You have to call write_tag() to save the changes to the file.

=cut 

sub change_frame {
    my ($self, $fname, @data) = @_;
    $self->get_frame_ids() unless exists $self->{frameIDs};
    return undef unless exists $self->{frames}->{$fname};

    $self->remove_frame($fname);
    $self->add_frame($fname, @data);

    return 1;
}

=pod

=item remove_frame()

  $id3v2->remove_frame($fname);

Remove an existing frame. $fname is the short name of a frame,
eg as returned by C<get_frame_ids>.

You have to call write_tag() to save the changes to the file.

=cut

sub remove_frame {
    my ($self, $fname) = @_;
    $self->get_frame_ids() unless exists $self->{frameIDs};
    return undef unless exists $self->{frames}->{$fname};
    delete $self->{frames}->{$fname};
    return 1;
}

=pod

=item supported_frames()

  $frames = $id3v2->supported_frames();

Returns a hash reference with all supported frames. The keys of the
hash are the short names of the supported frames, the 
according values are the long (english) names of the frames.

=cut

sub supported_frames {
    my $self = shift;

    my (%tags, $fname, $lname);
    while ( ($fname, $lname) = each %long_names) {
	$tags{$fname} = $lname if get_format($fname, "quiet");
    }

    return \%tags;
}

=pod 

=item what_data()

  ($data, $res_inp) = $id3v2->what_data($fname);

Returns an array reference with the needed data fields for a
given frame.
At this moment only the internal field names are returned,
without any additional information about the data format of
this field. Names beginning with an underscore (normally '_data')
can contain binary data.

$resp_inp is a reference to an array, which contains information about
a restriction for the content of the data field ( coresspodending to
the same array field in the @$data array).
If the entry is undef, no restriction exists. Otherwise it is a hash.
The keys of the hash are the allowed input, the correspodending value
is the value which should stored later in that field. If the value
is undef then the key itself is valid for saving.
If the hash contains an entry with "_FREE", the hash contains
only suggestions for the input, but other input is also allowed.

Example for picture types of the APIC frame:

C<  {"Other" => "\x00",
   "32x32 pixels 'file icon' (PNG only)" => "\x01",
   "Other file icon" => "\x02",
   ...}>

=cut

sub what_data{
    my ($self, $fname)=@_;
    $fname = substr $fname, 0, 4;   # delete 01 etc. at end
    return if length($fname)==3;    #id3v2.2 tags are read-only and should never be written
    my $reswanted = wantarray;
    my $format = get_format($fname, "quiet");
    return unless defined $format;
    my (@data, %res);

    foreach (@$format) {
        next unless exists $_->{name};
	push @data, $_->{name} unless $_->{name} eq "_encoding";
	next unless $reswanted;
	my $key=$fname . $_->{name};
	if (exists($res_inp{$key})) {
	    if ($res_inp{$key} =~ /CODE/) {
		$res{$_->{name}}= $res_inp{$key}->(1,1);
	    } else {
		$res{$_->{name}}= $res_inp{$key};
	    }
	}
    }

    if ($reswanted) {
	return (\@data, \%res);
    }
    return \@data;
}

=pod

=item title( [@new_title] )

Returns the title composed of the tags configured via C<MP3::Tag->config('v2title')>
call (with default 'Title/Songname/Content description' (TIT2)) from the tag.
(For backward compatibility may be called by deprecated name song() as well.)

Sets TIT2 frame if given the optional arguments @new_title.  If this is an
empty string, the frame is removed.

=cut

*song = \&title;

sub v2title_order {
    my $self = shift;
    @{ $self->get_config('v2title') };
}

sub title {
    my $self = shift;
    if (@_) {
	$self->remove_frame('TIT2') if defined $self->get_frame( "TIT2");
	return if @_ == 1 and $_[0] eq '';
	return $self->add_frame('TIT2', @_);
    }
    my @parts = grep defined && length,
	map scalar $self->get_frame($_), $self->v2title_order;
    return unless @parts;
    my $last = pop @parts;
    my $part;
    for $part (@parts) {
	$part =~ s(\0)(///)g;		# Multiple strings
	$part .= ',' unless $part =~ /[.,;:\n\t]\s*$/;
	$part .= ' ' unless $part =~ /\s$/;
    }
    return join '', @parts, $last;
}

=item _comment([$language])

Returns the file comment (COMM with an empty 'short') from the tag, or
"Subtitle/Description refinement" (TIT3) frame (unless it is considered a part
of the title).

=cut

sub _comment {
    my $self = shift;
    my $language;
    $language = lc shift if @_;
    my @info = get_frames($self, "COMM");
    shift @info;
    for my $comment (@info) {
	next unless exists $comment->{short} and not length $comment->{short};
	next if defined $language and (not exists $comment->{Language}
				       or lc $comment->{Language} ne $language);
	return $comment->{Text};
    }
    return if grep $_ eq 'TIT3', $self->v2title_order;
    return scalar $self->get_frame("TIT3");
}

=item comment()

   $val = $id3v2->comment();
   $newframe = $id3v2->comment('Just a comment for freddy', 'eng', 'personal');

Returns the file comment (COMM frame with an empty 'short' field) from the
tag, or "Subtitle/Description refinement" (TIT3) frame (unless it is considered
a part of the title).

If optional arguments ($comment, $short, $language) are present, sets the
comment frame.  If $language is omited, sets C<XXX> (it should be lowercase
3-letter abbreviation according to ISO-639-2); if $short is omited, sets
to C<''>.  If $comment is an empty string, the frame is removed.

=cut

sub comment {
    my $self = shift;
    my ($comment, $short, $language) = @_  or return $self->_comment();
    my @info = get_frames($self, "COMM");
    shift @info;
    my $c = -1;
    for my $comment (@info) {
	++$c;
	next unless exists $comment->{short} and not length $comment->{short};
	next if defined $language and (not exists $comment->{Language}
				       or lc $comment->{Language} ne lc $language);
	$self->remove_frame($c ? sprintf 'COMM%02d', $c : 'COMM');
	# $c--;				# Not needed if only one frame is removed
	last;
    }
    return if @_ == 1 and $_[0] eq '';
    $language = 'XXX' unless defined $language;
    $short = ''       unless defined $short;
    $self->add_frame('COMM', $language, $short, $comment);
}

=item year( [@new_year] )

Returns the year (TYER/TDRC) from the tag.

Sets TYER and TDRC frames if given the optional arguments @new_year.  If this
is an empty string, the frame is removed.

The format is similar to timestamps of IDv2.4.0, but ranges can be separated
by C<-> or C<-->, and non-contiguous dates are separated by C<,> (comma).  If
periods need to be specified via duration, then one needs to use the ISO 8601
C</>-notation  (e.g., see

  http://www.mcs.vuw.ac.nz/technical/software/SGML/doc/iso8601/ISO8601.html

); the C<duration/end_timestamp> is not supported.

On output, ranges of timestamps are converted to C<-> or C<--> separated
format depending on whether the timestamps are years, or have additional
fields.

If configuration variable C<year_is_timestamp> is false, the return value
is always the year only (of the first timestamp of a composite timestamp).

Recall that ID3v2.4.0 timestamp has format yyyy-MM-ddTHH:mm:ss (year, "-",
month, "-", day, "T", hour (out of
24), ":", minutes, ":", seconds), but the precision may be reduced by
removing as many time indicators as wanted. Hence valid timestamps
are
yyyy, yyyy-MM, yyyy-MM-dd, yyyy-MM-ddTHH, yyyy-MM-ddTHH:mm and
yyyy-MM-ddTHH:mm:ss. All time stamps are UTC. For durations, use
the slash character as described in 8601, and for multiple noncontiguous
dates, use multiple strings, if allowed by the frame definition.

=cut

sub year {
    my $self = shift;
    if (@_) {
	$self->remove_frame('TYER') if defined $self->get_frame( "TYER");
	$self->remove_frame('TDRC') if defined $self->get_frame( "TDRC");
	return if @_ == 1 and $_[0] eq '';
	my @args = @_;
	$args[-1] =~ s/^(\d{4}\b).*/$1/;
	$self->add_frame('TYER', @args);	# Obsolete
	@args = @_;
	$args[-1] =~ s/-(-|(?=\d{4}\b))/\//g;	# ranges are /-separated
	$args[-1] =~ s/,(?=\d{4}\b)/\0/g;	# dates are \0-separated
	$args[-1] =~ s#([-/T:])(?=\d(\b|T))#${1}0#g;	# %02d-format
	return $self->add_frame('TDRC', @args);	# new; allows YYYY-MM-etc as well
    }
    my $y;
    ($y) = $self->get_frame( "TDRC", 'intact')
	or ($y) = $self->get_frame( "TYER") or return;
    return substr $y, 0, 4 unless ($self->get_config('year_is_timestamp'))->[0];
    # Convert to human-readable form
    $y =~ s/\0/,/g;
    my $sep = ($y =~ /-/) ? '--' : '-';
    $y =~ s#/(?=\d)#$sep#g;
    return $y;
}

=pod

=item track( [$new_track] )

Returns the track number (TRCK) from the tag.

Sets TRCK frame if given the optional arguments @new_track.  If this is an
empty string or 0, the frame is removed.

=cut

sub track {
    my $self = shift;
    if (@_) {
	$self->remove_frame('TRCK') if defined $self->get_frame("TRCK");
	return if @_ == 1 and not $_[0];
	return $self->add_frame('TRCK', @_);
    }
    return scalar $self->get_frame("TRCK");
}

=pod

=item artist( [ $new_artist ] )

Returns the artist name (TPE1 (or TPE2 if TPE1 does not exist, of TCOM
if neither TPE1 nor TPE2 exist)) from the tag.

Sets TPE1 frame if given the optional arguments @new_artist.  If this is an
empty string, the frame is removed.

=cut

sub artist {
    my $self = shift;
    if (@_) {
	$self->remove_frame('TPE1') if defined $self->get_frame( "TPE1");
	return if @_ == 1 and $_[0] eq '';
	return $self->add_frame('TPE1', @_);
    }
    my $a;
    ($a) = $self->get_frame("TPE1") and return $a;
    ($a) = $self->get_frame("TPE2") and return $a;
    ($a) = $self->get_frame("TCOM") and return $a;
    return;
}

=pod

=item album( [ $new_album ] )

Returns the album name (TALB) from the tag.  If none is found, returns
the "Content group description" (TIT1) frame (unless it is considered a part
of the title).

Sets TALB frame if given the optional arguments @new_album.  If this is an
empty string, the frame is removed.

=cut

sub album {
    my $self = shift;
    if (@_) {
	$self->remove_frame('TALB') if defined $self->get_frame( "TALB");
	return if @_ == 1 and $_[0] eq '';
	return $self->add_frame('TALB', @_);
    }
    my $a;
    ($a) = $self->get_frame("TALB") and return $a;
    return if grep $_ eq 'TIT1', $self->v2title_order;
    return scalar $self->get_frame("TIT1");
}

=item genre( [ $new_genre ] )

Returns the genre string from TCON frame of the tag.

Sets TCON frame if given the optional arguments @new_genre.  If this is an
empty string, the frame is removed.

=cut

sub genre {
    my $self = shift;
    if (@_) {
	$self->remove_frame('TCON') if defined $self->get_frame( "TCON");
	return if @_ == 1 and $_[0] eq '';
	return $self->add_frame('TCON', @_);	# XXX add genreID 0x00 ?
    }
    my $g = $self->get_frame( "TCON");
    return unless defined $g;
    $g =~ s/^\d+\0(?:.)//s;		# XXX Shouldn't this be done in TCON()?
    $g;
}

=item version()

  $version = $id3v2->version();
  ($major, $revision) = $id3v2->version();

Returns the version of the ID3v2 tag. It returns a formatted string
like "3.0" or an array containing the major part (eg. 3) and revision
part (eg. 0) of the version number. 

=cut

sub version {
    my ($self) = @_;
    if (wantarray) {
          return ($self->{major}, $self->{revision});
    } else {
	  return $self->{version};
    }
}

=item new()

  $tag = new($mp3fileobj);

C<new()> needs as parameter a mp3fileobj, as created by C<MP3::Tag::File>.  
C<new> tries to find a ID3v2 tag in the mp3fileobj. If it does not find a
tag it returns undef.  Otherwise it reads the tag header, as well as an
extended header, if available. It reads the rest of the tag in a
buffer, does unsynchronizing if neccessary, and returns a
ID3v2-object.  At this moment only ID3v2.3 is supported. Any extended
header with CRC data is ignored, so no CRC check is done at the
moment.  The ID3v2-object can be used to extract information from
the tag.

Please use

   $mp3 = MP3::Tag->new($filename);
   $mp3->get_tags();                 ## to find an existing tag, or
   $id3v2 = $mp3->new_tag("ID3v2");  ## to create a new tag

instead of using this function directly

=cut

sub new {
    my ($class, $mp3obj, $create) = @_;
    my $self={mp3=>$mp3obj};
    my $header=0;
    bless $self, $class;

    $mp3obj->open or return unless $mp3obj->is_open;
    $mp3obj->seek(0,0);
    $mp3obj->read(\$header, 10);
    $self->{frame_start}=0;
    # default ID3v2 version
    $self->{major}=3;
    $self->{revision}=0;
    $self->{version}= "$self->{major}.$self->{revision}";

    if ($self->read_header($header)) {
	if (defined $create && $create) {
	    $self->{tag_data} = '';
	    $self->{data_size} = 0;
	} else {
	    $mp3obj->read(\$self->{tag_data}, $self->{tagsize});
	    $self->{data_size} = $self->{tagsize};
	    # un-unsynchronize comes in all versions first
	    if ($self->{flags}->{unsync}) {
		my $hits= $self->{tag_data} =~ s/\xFF\x00/\xFF/gs;
		$self->{data_size} -= $hits;
	    }
	    # in v2.2.x complete tag may be compressed, but compression isn't
	    # described in tag specification, so get out if compression is found
	    if ($self->{flags}->{compress_all}) {
		    # can we test if it is simple zlib compression and use this?
		    warn "ID3v".$self->{version}." compression isn't supported. Cannot read tag\n";
		    return undef;
	    }
	    # read the ext header if it exists
	    if ($self->{flags}->{extheader}) {
		unless ($self->read_ext_header(substr ($self->{tag_data}, 0, 14))) {
		    return undef; # ext header not supported
		}
	    }
	    if ($self->{flags}->{footer}) {
		    $self->{frame_start} += 10; # footers size is 10 bytes
		    warn "ID3v".$self->{version}." footer isn't supported. Ignoring it\n";
	    }
	}
	$mp3obj->close;
	return $self;
    } else {
	$mp3obj->close;
	if (defined $create && $create) {
	    $self->{tag_data}='';
	    $self->{tagsize} = -10;
	    $self->{data_size} = 0;
	    return $self;
	}
    }
    return undef;
}

sub new_with_parent {
    my ($class, $filename, $parent) = @_;
    return unless my $new = $class->new($filename, undef);
    $new->{parent} = $parent;
    $new;
}

##################
##
## internal subs
##

# This sub tries to read the header of an ID3v2 tag and checks for the right header
# identification for the tag. It reads the version number of the tag, the tag size
# and the flags.
# Returns true if it finds a known ID3v2.x header, false otherwise.

sub read_header {
	my ($self, $header) = @_;
	my %params;

	if (substr ($header,0,3) eq "ID3") {
		# flag meaning for all supported ID3v2.x versions
		my @flag_meaning=([],[], # v2.0 and v2.1 aren't supported yet
			       ["unknown","unknown","unknown","unknown","unknown","unknown","compress_all","unsync"],
			       ["unknown","unknown","unknown","unknown","unknown","experimental","extheader","unsync"],
			       ["unknown","unknown","unknown","unknown","footer","experimental","extheader","unsync"]
			      );

		# extract the header data
		my ($major, $revision, $pflags) = unpack ("x3CCC", $header);
		# check the version
		if ($major >= $#supported_majors || $supported_majors[$major] == 0) {
			warn "Unknown ID3v2-Tag version: V$major.$revision\n";
			print "| $major > ".($#supported_majors)." || $supported_majors[$major] == 0\n";
			print "| ",join(",",@supported_majors),"n";
			print "$_: $supported_majors[$_]\n" for (0..5);
			return 0;
		}
		if ($revision != 0) {
			warn "Unknown ID3v2-Tag revision: V$major.$revision\nTrying to read tag\n";
		}
		# get the tag size
		my $size=0;
		foreach (unpack("x6C4", $header)) {
			$size = ($size << 7) + $_;
		}
		# check the flags
		my $flags={};
		my $unknownFlag=0;
		my $i=0;
	 	foreach (split (//, unpack('b8',pack('v',$pflags)))) {
 			$flags->{$flag_meaning[$major][$i]}=1 if $_;
			$i++;
		}
		$self->{version} = "$major.$revision";
		$self->{major}=$major;
		$self->{revision}=$revision;
		$self->{tagsize} = $size;
		$self->{flags} = $flags;
		return 1;
	}
	return 0; # no ID3v2-Tag found
}

# Reads the extended header and adapts the internal counter for the start of the
# frame data. Ignores the rest of the ext. header (as CRC data).

sub read_ext_header {
    my ($self, $ext_header) = @_;
    # flags, padding and crc ignored at this time
    my $size = unpack("N", $ext_header);
    $self->{frame_start} += $size+4; # 4 bytes extra for the size
    return 1;
}


# Main sub for getting data from a frame.

sub extract_data {
	my ($data, $format) = @_;
	my ($rule, $found,$encoding, $result);

	foreach $rule (@$format) {
		next if exists $rule->{v3name};
		$encoding=0;
		# get the data
		if ( exists $rule->{mlen} ) {
			($found, $data) = ($data, "");
		} elsif ( $rule->{len} == 0 ) {
			if (exists $rule->{encoded} && $encoding !=0) {
				($found, $data) = split /\x00\x00/, $data, 2;
			} else {
				($found, $data) = split /\x00/, $data, 2;
			}
		} elsif ($rule->{len} == -1) {
			($found, $data) = ($data, "");
		} else {
			$found = substr $data, 0,$rule->{len};
			substr ($data, 0,$rule->{len}) = '';
		}
	
		# was data found?
		unless (defined $found && $found ne "") {
			$found = "";
			$found = $rule->{default} if exists $rule->{default};
		}

		# work with data
		if ($rule->{name} eq "_encoding") {
			$encoding=unpack ("C", $found);
		} else {
			if (exists $rule->{encoded} && $encoding != 0) {
				# decode data
				warn "Encoding not supported yet: found in $rule->{name}\n";
				next;
			}
			
			$found = toNumber($found) if ( $rule->{isnum} );

			$found = $rule->{func}->($found) if (exists $rule->{func});
			
			unless (exists $rule->{data} || !defined $found) {
				$found =~ s/[\x00]+$//;   # some progs pad text fields with \x00
				$found =~ s![\x00]! / !g; # some progs use \x00 inside a text string to seperate text strings
				$found =~ s/ +$//;        # no trailing spaces after the text
			}

			if (exists $rule->{re2}) {
				while (my ($pat, $rep) = each %{$rule->{re2}}) {
					$found =~ s/$pat/$rep/gis;
				}
			}
			# store data
			$result->{$rule->{name}}=$found;
		}
	}
	return $result;
}

#Searches for a format string for a specified frame. format strings exist for
#specific frames, or also for a group of frames. Specific format strings have
#precedence over general ones.

sub get_format {
    my $fname = shift;
    # to be quiet if called from supported_frames or what_data
    my $quiet = shift;
    my $fnamecopy = $fname;
    while ($fname ne "") {
	return $format{$fname} if exists $format{$fname};
	substr ($fname, -1) =""; #delete last char
    }
    warn "Unknown Frame-Format found: $fnamecopy\n" unless defined $quiet;
    return undef;
}

#Reads the flags of a frame, and returns a hash with all flags as keys, and 
#0/1 as value for unset/set.
sub check_flags {
    # how to detect unknown flags?
    my ($flags)=@_;
    my @flagmap=qw/0 0 0 0 0 groupid encryption compression 0 0 0 0 0 read_only file_preserv tag_preserv/;
    my %flags = map { (shift @flagmap) => $_ } split (//, unpack('b16',pack('v',$flags)));
    $flags{unchanged}=1;
    return \%flags;
}

sub build_flags {
    my %flags=@_;
    my $flags=0;
    my %flagmap=(groupid=>32, encryption=>64, compression=>128,
		 read_only=>8192, file_preserv=>16384, tag_preserv=>32768);
    while (my($flag,$set)=each %flags) {
	if ($set and exists $flagmap{$flag}) {
	    $flags += $flagmap{$flag};
	} elsif (not exists $flagmap{$flag}) {
	    warn "Unknown flag during tag write: $flag\n";
	}
    }
    return $flags;
}

sub DESTROY {
}


##################################
#
# How to store frame formats?
#
# format{fname}=[{xxx},{xxx},...]
#
# array containing descriptions of the different parts of a frame. Each description
# is a hash, which contains information, how to read the part.
#
# As Example: TCON
#     Text encoding                $xx
#     Information                  <text string according to encoding
#
# TCON consist of two parts, so a array with two hashes is needed to describe this frame.
#
# A hash may contain the following keys.
#
#          * len     - says how many bytes to read for this part. 0 means read until \x00, -1 means
#                      read until end of frame, any value > 0 specifies an exact length
#          * mlen    - specifies a minimum length for the data, real length is until end of frame
#          * name    - the user sees this part of the frame under this name. If this part contains
#                      binary data, the name should start with a _
#                      The name "_encoding" is reserved for the encoding part of a frame, which
#                      is handled specifically to support encoding of text strings
#          * encoded - this part has to be encoded following to the encoding information
#          * func    - a reference to a sub, which is called after the data is extracted. It gets
#                      this data as argument and has to return some data, which is then returned
#                      a result of this part
#          * isnum=1 - indicator that field stores a number as binary number
#          * re2     - hash with information for a replace: s/key/value/ 
#                      This is used after a call of func 
#          * data=1  - indicator that this part contains binary data
#          * default - default value, if data contains no information
#
# Name and exactly one of len or mlen are mandatory.
#
# TCON example:
# 
# $format{TCON}=[{len=> 1, name=>"encoding", data=>1},
#                {len=>-1, name=>"text", func=>\&TCON, re2=>{'\(RX\)'=>'Remix', '\(CR\)'=>'Cover'}] 
#
############################

sub toNumber {
  my $num = 0;
  $num = (256*$num)+unpack("C",$_) for split("",shift);

  return $num;
}

sub APIC {
    my $byte = shift;
    my $index = unpack ("C", $byte);
    my @pictypes = ("Other", "32x32 pixels 'file icon' (PNG only)", "Other file icon",
		    "Cover (front)", "Cover (back)", "Leaflet page",
		    "Media (e.g. lable side of CD)", "Lead artist/lead performer/soloist",
		    "Artist/performer", "Conductor", "Band/Orchestra", "Composer",
		    "Lyricist/text writer", "Recording Location", "During recording",
		    "During performance", "Movie/video screen capture",
		    "A bright coloured fish", "Illustration", "Band/artist logotype",
		    "Publisher/Studio logotype");
    if (defined shift) { # called by what_data
	my $c=0;
	my %ret = map {$_, chr($c++)} @pictypes;
	return \%ret;
    }
    # called by extract_data
    return "" if $index > $#pictypes;
    return $pictypes[$index];
}

sub COMR {
    my $number = unpack ("C", shift);
    my @receivedas = ("Other","Standard CD album with other songs",
		      "Compressed audio on CD","File over the Internet",
		      "Stream over the Internet","As note sheets",
		      "As note sheets in a book with other sheets",
		      "Music on other media","Non-musical merchandise");
    if (defined shift) {
	my $c=0;
	my %ret = map {$_, chr($c++)} @receivedas;
	return \%ret;
    }
    return $number if ($number>8);
    return $receivedas[$number];
}

sub PIC {
	# ID3v2.2 stores only 3 character Image format for pictures
	# and not mime type: Convert image format to mime type
	my $data = shift;
	
	if (defined shift) { # called by what_data
		my %ret={};
		return \%ret;
	}
	# called by extract_data
	if ($data ne "-->") {
		$data = "image/".(lc $data);
	} else {
		warn "ID3v2.2 PIC frame with link not supported\n";
		$data = "text/plain";
	}
	return $data;
}

sub TCON {
    require MP3::Tag::ID3v1;
    my $data = shift;
    if (defined shift) { # called by what_data
	my $c=0;
	my %ret = map {$_, "(".$c++.")"} @{MP3::Tag::ID3v1::genres()};
	$ret{"_FREE"}=1;
	$ret{Remix}='(RX)';
	$ret{Cover}="(CR)";
	return \%ret;
    }
    # called by extract_data
    if ($data =~ /\((\d+)\)/) {
	$data =~ s/\((\d+)\)/MP3::Tag::ID3v1::genres($1)/e;
    }
    return $data;
}

sub TFLT {
    my $text = shift;
    if (defined shift) {# called by what_data
	my %ret=("MPEG Audio"=>"MPG",
		 "MPEG Audio MPEG 1/2 layer I"=>"MPG /1",
		 "MPEG Audio MPEG 1/2 layer II"=>"MPG /2",
		 "MPEG Audio MPEG 1/2 layer III"=>"MPG /3",
		 "MPEG Audio MPEG 2.5"=>"MPG /2.5",
		 "Transform-domain Weighted Interleave Vector Quantization"=>"VQF",  
		 "Pulse Code Modulated Audio"=>"PCM",
		 "Advanced audio compression"=>"AAC",
		 "_FREE"=>1,
		);
	return \%ret;
    }
    #called by extract_data
    return "" if $text eq "";
    $text =~ s/MPG/MPEG Audio/;  
    $text =~ s/VQF/Transform-domain Weighted Interleave Vector Quantization/;  
    $text =~ s/PCM/Pulse Code Modulated Audio/;
    $text =~ s/AAC/Advanced audio compression/;
    unless ($text =~ s!/1!MPEG 1/2 layer I!) {
	unless ($text =~ s!/2!MPEG 1/2 layer II!) {
	    unless ($text =~ s!/3!MPEG 1/2 layer III!) {
		$text =~ s!/2\.5!MPEG 2.5!;
	    }
	}
    }
    return $text;
}

sub TMED {
    #called by extract_data
    my $text = shift;
    return "" if $text eq "";
    if ($text =~ /(?<!\() \( ([\w\/]*) \) /x) {
	my $found = $1;
	if ($found =~ s!DIG!Other digital Media! || 
	    $found =~ /DAT/ ||
	    $found =~ /DCC/ ||
	    $found =~ /DVD/ ||
	    $found =~ s!MD!MiniDisc!  || 
	    $found =~ s!LD!Laserdisc!) {
	    $found =~ s!/A!, Analog Transfer from Audio!;
	}
	elsif ($found =~ /CD/) {
	    $found =~ s!/DD!, DDD!;
	    $found =~ s!/AD!, ADD!;
	    $found =~ s!/AA!, AAD!;
	}
	elsif ($found =~ s!ANA!Other analog Media!) {
	    $found =~ s!/WAC!, Wax cylinder!;
	    $found =~ s!/8CA!, 8-track tape cassette!;
	}
	elsif ($found =~ s!TT!Turntable records!) {
	    $found =~ s!/33!, 33.33 rpm!;
	    $found =~ s!/45!, 45 rpm!;
	    $found =~ s!/71!, 71.29 rpm!;
	    $found =~ s!/76!, 76.59 rpm!;
	    $found =~ s!/78!, 78.26 rpm!;
	    $found =~ s!/80!, 80 rpm!;
	}
	elsif ($found =~ s!TV!Television! ||
	       $found =~ s!VID!Video! ||
	       $found =~ s!RAD!Radio!) {
	    $found =~ s!/!, !;
	}
	elsif ($found =~ s!TEL!Telephone!) {
	    $found =~ s!/I!, ISDN!;
	}
	elsif ($found =~ s!REE!Reel! ||
	       $found =~ s!MC!MC (normal cassette)!) {
	    $found =~ s!/4!, 4.75 cm/s (normal speed for a two sided cassette)!;
	    $found =~ s!/9!, 9.5 cm/s!;
	    $found =~ s!/19!, 19 cm/s!;
	    $found =~ s!/38!, 38 cm/s!;
	    $found =~ s!/76!, 76 cm/s!;
	    $found =~ s!/I!, Type I cassette (ferric/normal)!;
	    $found =~ s!/II!, Type II cassette (chrome)!;
	    $found =~ s!/III!, Type III cassette (ferric chrome)!;
	    $found =~ s!/IV!, Type IV cassette (metal)!;
	}
	$text =~ s/(?<!\() \( ([\w\/]*) \)/$found/x;
    }
    $text =~ s/\(\(/\(/g;
    $text =~ s/  / /g;

    return $text;
}

BEGIN {
	# ID3v2.2, v2.3 are supported
	@supported_majors=(0,0,1,1,0);
	
	my $encoding    ={len=>1, name=>"_encoding", data=>1};
	my $text_enc    ={len=>-1, name=>"Text", encoded=>1};
	my $text        ={len=>-1, name=>"Text"};
	my $description ={len=>0, name=>"Description", encoded=>1};
	my $url         ={len=>-1, name=>"URL"};
	my $data        ={len=>-1, name=>"_Data", data=>1};
	my $language    ={len=>3, name=>"Language"};

	# this list contains all id3v2.2 frame names which can be matched directly to a id3v2.3 frame
	%v2names_to_v3 = (
			  BUF => "RBUF",
			  CNT => "PCNT",
			  COM => "COMM",
			  CRA => "AENC",
			  EQU => "EQUA",
			  ETC => "ETCO",
			  GEO => "GEOB",
			  IPL => "IPLS",
			  MCI => "MDCI",
			  MLL => "MLLT",
			  POP => "POPM",
			  REV => "RVRB",
			  RVA => "RVAD",
			  SLT => "SYLT",
			  STC => "SYTC",
			  TFT => "TFLT",
			  TMT => "TMED",
			  UFI => "UFID",
			  ULT => "USLT",
			  TAL => "TALB",
			  TBP => "TBPM",
			  TCM => "TCOM",
			  TCO => "TCON",
			  TCR => "TCOP",
			  TDA => "TDAT",
			  TDY => "TDLY",
			  TEN => "TENC",
			  TIM => "TIME",
			  TKE => "TKEY",
			  TLA => "TLAN",
			  TLE => "TLEN",
			  TOA => "TOPE",
			  TOF => "TOFN",
			  TOL => "TOLY",
			  TOR => "TORY",
			  TOT => "TOAL",
			  TP1 => "TPE1",
			  TP2 => "TPE2",
			  TP3 => "TPE3",
			  TP4 => "TPE4",
			  TPA => "TPOS",
			  TPB => "TPUB",
			  TRC => "TSRC",
			  TRD => "TRDA",
			  TRK => "TRCK",
			  TSI => "TSIZ",
			  TSS => "TSSE",
			  TT1 => "TIT1",
			  TT2 => "TIT2",
			  TT3 => "TIT3",
			  TXT => "TEXT",
			  TXX => "TXXX",
			  TYE => "TYER",
			  WAF => "WOAF",
			  WAR => "WOAR",
			  WAS => "WOAS",
			  WCM => "WCOM",
			  WCP => "WCOP",
			  WPB => "WPUB",
			  WXX => "WXXX",
			 );

	%format = (
		   AENC => [$url, {len=>2, name=>"Preview start", isnum=>1},
			    {len=>2, name=>"Preview length", isnum=>1}],
		   APIC => [$encoding, {len=>0, name=>"MIME type"},
			    {len=>1, name=>"Picture Type", func=>\&APIC}, $description, $data],
		   COMM => [$encoding, $language, {name=>"short", len=>0, encoding=>1}, $text_enc],
		   COMR => [$encoding, {len=>0, name=>"Price"}, {len=>8, name=>"Valid until"},
			    $url, {len=>1, name=>"Received as", func=>\&COMR},
			    {len=>0, name=>"Name of Seller", encoded=>1},
			    $description, {len=>0, name=>"MIME type"},
			    {len=>-1, name=>"_Logo", data=>1}],
		   CRM  => [{v3name=>""},{len=>0, name=>"Owner ID"}, {len=>0, name=>"Content/explanation"}, $data], #v2.2
		   ENCR => [{len=>0, name=>"Owner ID"}, {len=>0, name=>"Method symbol"}, $data],
		   #EQUA => [],
		   #ETCO => [],
		   GEOB  => [$encoding, {len=>0, name=>"MIME type"},
			     {len=>0, name=>"Filename"}, $description, $data],
		   GRID => [{len=>0, name=>"Owner"}, {len=>1, name=>"Symbol", isnum=>1},
			    $data],
		   IPLS => [$encoding, $text_enc],	# in 2.4 split into TMCL, TIPL
		   LNK  => [{len=>4, name=>"ID", func=>\&LNK}, {len=>0, name=>"URL"}, $text],
		   LINK => [{len=>4, name=>"ID"}, {len=>0, name=>"URL"}, $text],
		   MCDI => [$data],
		   #MLLT  => [],
		   OWNE => [$encoding, {len=>0, name=>"Price payed"},
			    {len=>0, name=>"Date of purchase"}, $text],
		   PCNT => [{mlen=>4, name=>"Text", isnum=>1}],
		   PIC  => [{v3name => "APIC"}, $encoding, {len=>3, name=>"Image Format", func=>\&PIC},
			    {len=>1, name=>"Picture Type", func=>\&APIC}, $description, $data], #v2.2
		   POPM  => [{len=>0, name=>"URL"},{len=>1, name=>"Rating", isnum=>1}, {mlen=>4, name=>"Counter", isnum=>1}],
		   #POSS => [],
		   PRIV => [{len=>0, name=>"Text"}, $data],
		   RBUF => [{len=>3, name=>"Buffer size", isnum=>1},
			    {len=>1, name=>"Embedded info flag", isnum=>1},
			    {len=>4, name=>"Offset to next tag", isnum=>1}],
		   #RVAD => [],
		   RVRB => [{len=>2, name=>"Reverb left (ms)", isnum=>1},
			    {len=>2, name=>"Reverb right (ms)", isnum=>1},
			    {len=>1, name=>"Reverb bounces (left)", isnum=>1},
			    {len=>1, name=>"Reverb bounces (right)", isnum=>1},
			    {len=>1, name=>"Reverb feedback (left to left)", isnum=>1},
			    {len=>1, name=>"Reverb feedback (left to right)", isnum=>1},
			    {len=>1, name=>"Reverb feedback (right to right)", isnum=>1},
			    {len=>1, name=>"Reverb feedback (right to left)", isnum=>1},
			    {len=>1, name=>"Premix left to right", isnum=>1},
			    {len=>1, name=>"Premix right to left", isnum=>1},],
		   SYTC => [{len=>1, name=>"Time Stamp Format", isnum=>1}, $data],
		   #SYLT => [],
		   T    => [$encoding, $text_enc],
		   TCON => [$encoding, {%$text_enc, func=>\&TCON, re2=>{'\(RX\)'=>'Remix', '\(CR\)'=>'Cover'}}], 
		   TCOP => [$encoding, {%$text_enc, re2 => {'^'=>'(C) '}}],
		   # TDRC => [$encoding, $text_enc, data => 1],
		   TFLT => [$encoding, {%$text_enc, func=>\&TFLT}],
		   TIPL => [{v3name => "IPLS"}, $encoding, $text_enc],
		   TMCL => [{v3name => "IPLS"}, $encoding, $text_enc],
		   TMED => [$encoding, {%$text_enc, func=>\&TMED}],
		   TXXX => [$encoding, $description, $text],
		   UFID => [{%$description, name=>"Text"}, $data],
		   USER => [$encoding, $language, $text],
		   USLT => [$encoding, $language, $description, $text],
		   W    => [$url],
		   WXXX => [$encoding, $description, $url],
	      );

    %long_names = (
		   AENC => "Audio encryption",
		   APIC => "Attached picture",
		   COMM => "Comments",
		   COMR => "Commercial frame",
		   ENCR => "Encryption method registration",
		   EQUA => "Equalization",
		   ETCO => "Event timing codes",
		   GEOB => "General encapsulated object",
		   GRID => "Group identification registration",
		   IPLS => "Involved people list",
		   LINK => "Linked information",
		   MCDI => "Music CD identifier",
		   MLLT => "MPEG location lookup table",
		   OWNE => "Ownership frame",
		   PRIV => "Private frame",
		   PCNT => "Play counter",
		   POPM => "Popularimeter",
		   POSS => "Position synchronisation frame",
		   RBUF => "Recommended buffer size",
		   RVAD => "Relative volume adjustment",
		   RVRB => "Reverb",
		   SYLT => "Synchronized lyric/text",
		   SYTC => "Synchronized tempo codes",
		   TALB => "Album/Movie/Show title",
		   TBPM => "BPM (beats per minute)",
		   TCOM => "Composer",
		   TCON => "Content type",
		   TCOP => "Copyright message",
		   TDAT => "Date",
		   TDLY => "Playlist delay",
		   TENC => "Encoded by",
		   TEXT => "Lyricist/Text writer",
		   TFLT => "File type",
		   TIME => "Time",
		   TIPL => "Involved people list",
		   TIT1 => "Content group description",
		   TIT2 => "Title/songname/content description",
		   TIT3 => "Subtitle/Description refinement",
		   TKEY => "Initial key",
		   TLAN => "Language(s)",
		   TLEN => "Length",
		   TMCL => "Musician credits list",
		   TMED => "Media type",
		   TOAL => "Original album/movie/show title",
		   TOFN => "Original filename",
		   TOLY => "Original lyricist(s)/text writer(s)",
		   TOPE => "Original artist(s)/performer(s)",
		   TORY => "Original release year",
		   TOWN => "File owner/licensee",
		   TPE1 => "Lead performer(s)/Soloist(s)",
		   TPE2 => "Band/orchestra/accompaniment",
		   TPE3 => "Conductor/performer refinement",
		   TPE4 => "Interpreted, remixed, or otherwise modified by",
		   TPOS => "Part of a set",
		   TPUB => "Publisher",
		   TRCK => "Track number/Position in set",
		   TRDA => "Recording dates",
		   TRSN => "Internet radio station name",
		   TRSO => "Internet radio station owner",
		   TSIZ => "Size",
		   TSRC => "ISRC (international standard recording code)",
		   TSSE => "Software/Hardware and settings used for encoding",
		   TYER => "Year",
		   TXXX => "User defined text information frame",
		   UFID => "Unique file identifier",
		   USER => "Terms of use",
		   USLT => "Unsychronized lyric/text transcription",
		   WCOM => "Commercial information",
		   WCOP => "Copyright/Legal information",
		   WOAF => "Official audio file webpage",
		   WOAR => "Official artist/performer webpage",
		   WOAS => "Official audio source webpage",
		   WORS => "Official internet radio station homepage",
		   WPAY => "Payment",
		   WPUB => "Publishers official webpage",
		   WXXX => "User defined URL link frame",

		   # ID3v2.2 frames which cannot linked directly to a ID3v2.3 frame
		   CRM => "Encrypted meta frame",
		   PIC => "Attached picture",
		   LNK => "Linked information",
		  );

	# these fields have restricted input (FRAMEfield)
	%res_inp=( "APICPicture Type" => \&APIC,
		   "TCONText" => \&TCON,
		   "TFLTText" => \&TFLT,
		   "COMRReceived as" => \&COMR,
		 );
}

=pod

=head1 SEE ALSO

L<MP3::Tag>, L<MP3::Tag::ID3v1>, L<MP3::Tag::ID3v2-Data>

ID3v2 standard - http://www.id3.org

=head1 COPYRIGHT

Copyright (c) 2000-2004 Thomas Geffert.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the terms of the Artistic License, distributed
with Perl.

=cut


1;
