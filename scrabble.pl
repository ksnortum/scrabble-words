#! /usr/bin/perl

=pod

=head1 SYNOPSIS

	scrabble.pl [--debug] 
	            [--dictionary <dict>] 
	            [--min-length <2-15>]
	            <letters>
	scrabble.pl [ --help ]

=head1 DESCRIPTION

C<scrabble.pl> is a script that will take the letters you enter 
and return all the legal Scrabble words sorted by tile value.

=cut

use strict;
use warnings;
use feature qw(say);

use Permutation;
use Subset;
use Getopt::Long;
use Pod::Usage;

=pod

=head1 OPTIONS

B<--dictionary> sowpods | collins | twl | words | /path/to/dict

Defined which which Scrabble dictionary to use.  
A dictionary is a text file with one legal word per line.  The 
text line separators should be correct for your system.  The 
value after the flag can be a path (use only slashes "/") or one
of the three names given.  You are responsible for downloading
or installing the correct dictionary.

The default is "sowpods" unless the LANG environment variable is
set and its value starts with en_US or en_CA.  Then the default
is "twl".  "collins" is a symonym for "sowpods".

B<--debug>

This is a switch that outputs simple debugging messages.

B<--min-length> 2-15

A digit, from 2 to 15, that is the minimum length of the words
you want to see.  The default is 2.

B<--help>

This is a switch that outputs this documentation and exits.

=cut

my $debug = 0;
my $dictionary = '';
my $help = 0;
my $min_length = 2;

GetOptions(
	"dictionary=s" => \$dictionary,
	"debug"        => \$debug,
	"help"         => \$help,
	"min-length=i" => \$min_length,
) or pod2usage();
pod2usage( "-verbose" => 1 ) if $help;

# What's left after the options should be the letters
my $letters = shift;
pod2usage() unless $letters;

if ( $dictionary =~ /^words$/i ) {
	$letters = lc $letters;
} else {
	$letters = uc $letters;
}

# Get minimum length
pod2usage() if $min_length < 2 or $min_length > 15;

# Read a dictionary of legal words.  Put all words into a hash
# for faster lookup
#
# Default dictionary is based on country 
unless ( $dictionary ) {
	if ( $ENV{LANG} =~ /^en_US|en_CA/ ) {
		$dictionary = 'twl';
	} else {
		$dictionary = 'sowpods';
	}
}

# Which dictionary to use?  Change these to match your system
my $file_name;
SWITCH: for ($dictionary) {
	if ( /^sowpods$/i ) { $file_name = "/usr/local/lib/scrabble/sowpods.txt"; last SWITCH }
	if ( /^collins$/i ) { $file_name = "/usr/local/lib/scrabble/sowpods.txt"; last SWITCH }
	if ( /^twl$/i )     { $file_name = "/usr/local/lib/scrabble/twl.txt";     last SWITCH }
	if ( /^words$/i )   { $file_name = "/usr/share/dict/words";               last SWITCH }
	$file_name = $dictionary;
}

say "The file name for the dictionary is $file_name" if $debug;
say "Slurping dictionary words..." if $debug;
open FH, $file_name or pod2usage( "-verbose" => 1 );
chomp( my @words = <FH> );
my %words = map { $_ => '' } @words;
close FH;
@words = ();

# Get the tile values for all letters
say "Getting letter values..." if $debug;
my %value = ();
while (<DATA>) {
	chomp;
	/^([A-Z])\s+(\d+)$/ or next;
	$value{$1} = $2;
	$value{"\L$1"} = $2; # lower case
}
close DATA;

########
# Main #
########

# Call Subset to get all subsets of the letters (what tiles are we
# using).  The routine  "find_words" is call for each subset sending 
# in a list of letters.  @found is a list of all legal words found.
say "Starting letter shuffle..." if $debug;
my @found = ();
my %seen = ();
Subset->run(
	string  => $letters,
	routine => \&find_words
);

# List found words, sorting by descending total tile value
say join ', ', sort { value_of($b) <=> value_of($a) } @found;

###############
# Subroutines #
###############

# For each subset of letter, get all of its permutations (order)
# and test if it is a legal word.
sub find_words {
	# Look for words of at least $min_length characters
	return if scalar @_ < $min_length;

	my $letters = join '', @_;
	say "Starting permutations for '$letters'" if $debug;

	# $a is an object (ref to hash) that will hold the permutations
	my $a = Permutation->new( string => $letters );

	# Look at each permutation
	foreach my $word ( @{ $a->{permutations} } ) {

		# Since you can have more than one tile with the same letter,
		# it is possible that we've already tested this permutation.
		# Use a hash for faster lookup.
		next if exists $seen{$word};
		$seen{$word} = '';

		# Is the permutation in the word list? (hash, actually)
		print "is '$word' a word? " if $debug;

		if ( exists $words{$word} ) {
			say 'yes' if $debug;
			push @found, $word;
		} else {
			say 'no' if $debug;
		}
	}
}

# Returns the total tile value of the entered word
sub value_of {
	my @word = split //, shift;
	my $this_value = 0;
	$this_value += $value{$_} foreach @word;
	return $this_value;
}

__DATA__
A 1
B 3
C 3
D 2
E 1
F 4
G 2
H 4
I 1
J 8
K 5
L 1
M 3
N 1
O 1
P 3
Q 10
R 1
S 1
T 1
U 1
V 4
W 4
X 8
Y 4
Z 10

