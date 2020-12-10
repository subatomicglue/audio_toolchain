package Music_Translate_Fields;

my %tr;

sub translate_tr ($) {
  my $a = shift;
  $a =~ s/^\s+//;
  $a =~ s/\s+$//;
  $a =~ s/\s+/ /g;
  $a =~ s/\b(\w)\.\s*/$1 /g;
  $a = $tr{lc $a} or return;
  return $a;
}

sub translate_artist ($$) {
  my ($self, $a) = (shift, shift);
  $ini_a = $a;
  $a = $a->[0] if ref $a;		# [value, handler]
  my $tr_a = translate_tr $a;
  if (not $tr_a and $a =~ /(.*?)\s*,\s*(.*)/s) {	# Schumann, Robert
    $tr_a = translate_tr "$2 $1";
  }
  $a = $tr_a or return $ini_a;
  return ref $ini_a ? [$a, $ini_a->[1]] : $a;
}

my %aliases = (	Rachmaninov	=>	[qw(Rachmaninoff Rahmaninov)],
		Tchaikovskiy 	=>	'Chaikovskiy',
		'Mendelssohn-Bartholdy'	=> 'Mendelssohn',
		Shostakovich	=>	'SCHOSTAKOVICH',
	      );

for (<DATA>) {
  next if /^\s*$/;
  s/^\s+//, s/\s+$//, s/\s+/ /g;
  #warn "Doing `$_'";
  my ($pre, $post) = /^(.*?)\s*(\(.*\))?$/;
  my @f = split ' ', $pre or warn("`$pre' won't split"), die;
  my $last = pop @f;
  my @last = $last;
  (my $ascii = $last) =~
	tr( ¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ\x80-\x9F)
	  ( !cLXY|S"Ca<__R~o+23'mP.,1o>...?AAAAAAACEEEEIIIIDNOOOOOx0UUUUYpbaaaaaaaceeeeiiiidnooooo:ouuuuyPy_);
  push @last, $ascii unless $ascii eq $last;
  my $a = $aliases{$last[0]} ? $aliases{$last[0]} : [];
  $a = [$a] unless ref $a;
  push @last, @$a;
  for my $last (@last) {
    my @comp = (@f, $last);
    $tr{"\L@comp"} = $_;
    $tr{lc $last} ||= $_;		# Two Bach's
    $tr{"\L$f[0] $last"} ||= $_;
    if (@f) {
      my @ini = map substr($_, 0, 1), @f;
      $tr{"\L$ini[0] $last"} ||= $_;	# One initial
      $tr{"\L@ini $last"} ||= $_;	# All initials
    }
  }
}

for ('Frederic Chopin', 'Fryderyk Chopin', 'Joseph Haydn', 'J Haydn',
     'Sergei Prokofiev', 'Antonín Dvorák', 'Peter Tchaikovsky',
     'Sergey Rahmaninov', 'Piotyr Ilyich Tchaikovsky',
     'DIMITRI SCHOSTAKOVICH') {
  my ($last) = (/(\w+)$/) or warn, die;
  $tr{lc $_} = $tr{lc $last};
}

#$tr{lc 'Tchaikovsky, Piotyr Ilyich'} = $tr{lc 'Tchaikovsky'};

# Old misspellings
$tr{lc 'Petr Ilyich Chaikovskiy (1840-1893)'} = $tr{lc 'Tchaikovsky'};
$tr{lc 'Franz Josef Haydn (1732-1809)'} = $tr{lc 'Haydn'};

1;
__DATA__

Ludwig van Beethoven (1770-1827)
Alfred Schnittke (1934-1998)
Franz Schubert (1797-1828)
Frédéric Chopin (1810-1849)
Petr Ilyich Tchaikovsky (1840-1893)
Robert Schumann (1810-1856)
Sergei Rachmaninov (1873-1943)
Alfredo Catalani (1854-1893)
Amicare Ponchielli (1834-1886)
Gaetano Donizetti (1797-1848)
George Frideric Händel (1685-1759)
Gioacchino Rossini (1792-1868)
Giovanni Battista Pergolesi (1710-1736)
Giuseppe Verdi (1813-1901)
Johann Sebastian Bach (1685-1750)
Johann Christian Bach (1735-1782)
Ludwig van Beethoven (1770-1827)
Luigi Cherubini (1760-1842)
Pietro Mascagni (1863-1945)
Riccardo Zandonai (1883-1944)
Richard Wagner (1813-1883)
Ruggiero Leoncavallo (1858-1919)
Umberto Giordano (1867-1948)
Wolfgang Amadei Mozart (1756-1791)
Eduard Grieg (1843-1907)
Johannes Brahms (1833-1897)
Dmitriy Shostakovich (1906-1975)
Franz Joseph Haydn (1732-1809)
Antonio Vivaldi (1678-1741)
Claude Debussy (1862-1918)
Antonin Dvorák (1841-1904)
Antonin Dvorak (1841-1904)
Sergey Prokofiev (1891-1953)
Alfred Schnittke (1934-1998)
Alexander Glazunov (1865-1936)
George Phillipe Telemann (1681-1767)
Jiri Antonin Benda (1722-1795)
Mario Castelnuovo-Tedesco (1895-1968)
Heitor Villa-Lobos (1887-1959)
Hector Berlioz (1803-1869)
Modest Mussorgsky (1839-1881)
George Gershwin (1898-1937)
Carl Orff (1895-1982)
Maurice Ravel (1875-1937)
Isao Matsushita (1951-)
Dietrich Erdmann (1917-)
Paul Dessau (1894-1979)
Erwin Shuloff (1894-1942)
Félix Mendelssohn-Bartholdy (1809-1847)
Dmitry Stepanovich Bortnyansky (1751-1825)
Kurt Weill (1900-1950)
Jean Sibelius (1865-1957)
Franz Liszt (1811-1886)
Domenico Scarlatti (1685-1757)
Alessandro Scarlatti (1660-1725)
Muzio Clementi (1752-1832)
Anatoly Lyadov (1855-1914)
Arnold Schoenberg (1874-1951)
Georges Bizet (1838-1875)
Alexander Borodin (1833-1887)
Alexander Glazunov (1865-1936)
Gabriel Fauré (1845-1924)

Lina Bruna Rasa (1907-1984)
Enrico Caruso (1873-1921)
Sviatoslav Richter (1915-1997)
Glenn Gould (1932-1982)
Edit Piaf (1915-1963)
Oleg Kagan (1946-1990)
David Oistrach (1908-1974)
Vladimir Horowitz (1903-1989)
Vladimir Sofronitsky (1901-1961)
Emil Gilels (1916-1985)
Pablo Casals (1876-1973)
Vladimir Sofronitsky (1901-1961)
Artur Rubinstein (1887-1982)

Ivan Krylov (1769-1844)
Samuil Marshak (1887-1964)
