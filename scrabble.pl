#! /usr/bin/perl

=pod

=head1 SYNOPSIS

	scrabble.pl [--dictionary <dict>] 
	            [--contains <letters>]
	            [--min-length <2-15>]
	            [--max-length <2-15>]
	            [--output <type>]
	            [--quiet]
	            [--debug] 
	            <letters>
	scrabble.pl [--help]

=head1 DESCRIPTION

C<scrabble.pl> is a script that will take the letters you enter 
and return all the legal Scrabble words sorted by tile value.
B<letters> is any conbination of letters you want to check, excluding
any B<--contains> letters.  You can use a dot (.) to signify a
blank tile.

=cut

use strict;
use warnings;
use feature qw(say);

use Permutation;
use Subset;
use Getopt::Long;
use Pod::Usage;

my $SOWPODS_PATH = "/usr/local/lib/scrabble/sowpods.txt";
my $COLLINS_PATH = "/usr/local/lib/scrabble/sowpods.txt";
my $TWL_PATH     = "/usr/local/lib/scrabble/twl.txt";
my $WORDS_PATH   = "/usr/share/dict/words";

$| = 1; # Don't buffer output

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
is "twl".  "collins" is a synonym for "sowpods".

B<--contains> <letters>

A letter or letters that the words must contain.  These letter(s)
are added to the letters to build the words with.  That is, if you
want words that are made of the letters "abc" and if must contain
"a", use:

	scrabble.pl --contains a bc

It can be made clearer by using the "equals" flag syntax:

	scrabble.pl --contains=a bc

B<--min-length> 2-15

A digit, from 2 to 15, that is the minimum length of the words
you want to see.  The default is 2.

B<--max-length> 2-15

A digit, from 2 to 15, that is the maximum length of the words
you want to see.  The default is 15.  The maximum length cannot
be less than the minimum length.

B<--output> compact | list | /path/to/file

How the output should be formatted.  'compact' goes to the 
standard out with comma-space (, ) between the words.  List
is one word per line with a LF between lines.  If the output
type is neither of these, it's assumed to be a path and 
file name to send the output to in list format.  The default
is compact.

B<--quiet>

By default, the program prints dots to show you it's thinking.  This switch
stops the printing of those dots.  B<--debug> turns on B<--quiet> automatically.
Outputs that are not "compact" are quiet by default.

B<--debug>

This is a switch that outputs simple debugging messages.  Using the switch
twice gives more output.

B<--help>

This is a switch that outputs this documentation and exits.

=head1 COPYRIGHT

C<scrabble.pl>, C<Subset.pm>, and C<Permutation.pm> are Copyright (C) 2014, by Knute Snortum

It is free software; you can redistribute it and/or modify it under the terms of either:

=over 4

=item * the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option) any
later version, or

=item * the Artistic License version 2.0.

=back

=cut

my $debug = 0;
my $dictionary = '';
my $help = 0;
my $min_length = 2;
my $max_length = 15;
my $contains = '';
my $output = 'compact';
my $quiet = 0;

GetOptions(
	"dictionary=s" => \$dictionary,
	"debug"        => \$debug,
	"help"         => \$help,
	"min-length=i" => \$min_length,
	"max-length=i" => \$max_length,
	"contains=s"   => \$contains,
	"output=s"     => \$output,
	"quiet"        => \$quiet,
) or pod2usage();
pod2usage( "-verbose" => 2 ) if $help;

# What's left after the options should be the letters
my $letters = shift;
pod2usage() unless $letters;
pod2usage() unless $letters =~ /^[a-z.]+$/i;
pod2usage() unless $contains eq '' or $contains =~ /^[a-z]+$/i;
$letters .= $contains;

if ( $dictionary =~ /^words$/i ) {
	$letters = lc $letters;
} else {
	$letters = uc $letters;
}

# Check minimum/maximum length
pod2usage() if $min_length < 2 or $min_length > 15;
pod2usage() if $max_length < 2 or $max_length > 15;
pod2usage() if $max_length < $min_length;

# Quiet is on if you're using a long output (which will probably be piped) 
# or if you are sending output to a file
$quiet = 1 unless $output =~ /^compact$/i;

# Don't print what non-quiet prints if you're in debug
$quiet = 1 if $debug;

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

# Which dictionary to use? 
my $file_name;
SWITCH: for ($dictionary) {
	if ( /^sowpods$/i ) { $file_name = $SOWPODS_PATH; last SWITCH }
	if ( /^collins$/i ) { $file_name = $COLLINS_PATH; last SWITCH }
	if ( /^twl$/i )     { $file_name = $TWL_PATH;     last SWITCH }
	if ( /^words$/i )   { $file_name = $WORDS_PATH;   last SWITCH }
	$file_name = $dictionary;
}

say "The file name for the dictionary is $file_name" if $debug;
say "Slurping dictionary words..." if $debug;
open FH, '<', $file_name or pod2usage( "-verbose" => 2 );
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
# using).  The routine  "find_words" is called for each subset sending 
# in a list of letters.  @found is a list of all legal words found.
say "Starting letter shuffle..." if $debug;
my @found = ();
my %seen = ();
my %value_of = ();
my $wildcard = "";

# Are there wildcards?
if ( $letters =~ /\./ ) {
	$letters =~ s/\.//;

	foreach $wildcard ( 'A' .. 'Z' ) {
		$wildcard = lc $wildcard if $dictionary =~ /^words$/i;
		say "***Blank tile is a '$wildcard'" if $debug;
		print "\n*****\n* $wildcard *\n*****\n" unless $quiet;
		Subset->run(
			string   => $letters . $wildcard,
			routine  => \&find_words,
			wildcard => $wildcard,
		);
	}
} else {
	Subset->run(
		string  => $letters,
		routine => \&find_words,
	);
}

# List found words, sorting by descending total tile value
if ( $debug ) {
	print "\n";
	print "$_($value_of{$_}), " foreach sort keys %value_of;
}

if ( $output =~ /^compact$/i ) {
	say "\n", join ', ', sort { $value_of{$b} <=> $value_of{$a} } @found;
} elsif ( $output =~ /^list$/i ) {
	say join "\n", sort { $value_of{$b} <=> $value_of{$a} } @found;
} else {
	open FH, '>', $output or die "Cannot open $output for writing, $!";
	print FH join "\n", sort { $value_of{$b} <=> $value_of{$a} } @found;
	close FH;
}

###############
# Subroutines #
###############

# For each subset of letter, get all of its permutations (order)
# and test if it is a legal word.
sub find_words {
	my $self = shift;
	my @subset = @{ $self->{subset} };
	my $wildcard = $self->{wildcard};

	# Look for words that are the right length
	return if scalar @subset < $min_length or scalar @subset > $max_length;

	my $these_letters = join '', @subset;
	say "Starting permutations for '$these_letters'" if $debug;

	# $a is an object (ref to hash) that will hold the permutations
	my $a = Permutation->new( string => $these_letters );

	# Look at each permutation
	foreach my $word ( @{ $a->{permutations} } ) {
		print "." unless $quiet;

		# Does this permutation contain all the letters it needs to?
		foreach my $find ( split //, $contains ) {
			if ( $word !~ /$find/i ) {
				say "'$word' does not contain '$find'" if $debug;
				return;
			}
		}

		# Since you can have more than one tile with the same letter,
		# it is possible that we've already tested this permutation.
		# Use a hash for faster lookup.
		next if exists $seen{$word};
		$seen{$word} = '';

		# Is the permutation in the word list? (hash, actually)
		print "is '$word' a word? " if $debug > 1;

		if ( exists $words{$word} ) {
			say 'yes' if $debug > 1;
			push @found, $word;
			set_word_value( $word, $wildcard );
		} else {
			say 'no' if $debug > 1;
		}
	}
}

# Set the total tile value of the entered word
sub set_word_value {
	my $these_letters = shift;
	my $wildcard = shift;

	# Wildcards have zero value
	my $value_letters = $these_letters; 
	$value_letters =~ s/$wildcard// if $wildcard;
	say "Word: $these_letters, without wildcard: $value_letters" if $debug;

	# Total value and save
	my $this_value = 0;
	$this_value += $value{$_} foreach split //, $value_letters;
	my $len_wildcard = 0;
	$len_wildcard = length( $wildcard ) if $wildcard;
	$this_value += 50 if length( $these_letters ) - length( $contains ) == length( $letters ) + $len_wildcard;
	$value_of{ $these_letters } = $this_value;
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

