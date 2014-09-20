#! /usr/bin/perl

=pod

=head1 SYNOPSIS

	scrabble.pl [--dictionary <dict>] 
	            [--contains <letters>]
	            [--contains-re <regex>]
	            [--prefix <letters>]
	            [--suffix <letters>]
	            [--min-length <1-15>]
	            [--max-length <1-15>]
	            [--output <type>]
	            [--quiet]
	            [--debug] 
	            <letters>
	scrabble.pl [--help]

=head1 DESCRIPTION

C<scrabble.pl> is a script that will take the letters you enter 
and return all the legal Scrabble words sorted by tile value.
B<letters> is any combination of letters you want to check, excluding
any B<--contains> letters.  You can use a dot (.) to signify a
blank tile.

=cut

use strict;
use warnings;

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

B<--contains-re> <regex>

<regex> is any valid Perl regular expression, see I<egrep(1)> or
L<http://perldoc.perl.org/perlre.html>.  Only words matching this 
will be displayed.  Note: unlike B<--contains> you must add any
extra letters that need to be considered to <letter>.  To use the
example from B<--contains> above:

	scrabble.pl --contains-re=^a abc

All regex matches are case insensitive, since it is hard to know
is the dictionary you are using has upper or lower case letters.

B<--prefix> <letters>
B<--suffix> <letters>

<letters> will be added to the beginning (end) of the proposed
word before checking the dictionary.  You do not need to add them
to the <letters> at the end of the command.  Using B<--prefix> or
B<--suffix> cuts down on the processing time needed.

B<--min-length> 1-15

A digit, from 1 to 15, that is the minimum length of the words
you want to see.  The default is 2 unless there is a B<--prefix>
or B<--suffix>, then it is 1.  A B<--min-length> of 1 is only 
valid with a non-empty B<--prefix> or B<--suffix>.

B<--max-length> 1-15

A digit, from 1 to 15, that is the maximum length of the words
you want to see.  The default is 15.  The maximum length cannot
be less than the minimum length.  A B<--max-length> of 1 is only 
valid with a non-empty B<--prefix> or B<--suffix>.

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
my $min_length = -1;
my $max_length = -1;
my $contains = '';
my $contains_re = '';
my $prefix = '';
my $suffix = '';
my $output = 'compact';
my $quiet = 0;

GetOptions(
	"dictionary=s"  => \$dictionary,
	"debug"         => \$debug,
	"help"          => \$help,
	"min-length=i"  => \$min_length,
	"max-length=i"  => \$max_length,
	"contains=s"    => \$contains,
	"contains-re=s" => \$contains_re,
	"prefix=s"      => \$prefix,
	"suffix=s"      => \$suffix,
	"output=s"      => \$output,
	"quiet"         => \$quiet,
) or pod2usage();
pod2usage( "-verbose" => 1 ) if $help;

# What's left after the options should be the letters
my $letters = shift;
pod2usage() unless $letters;
pod2usage() unless $letters =~ /^[A-Za-z.]+$/i;
pod2usage() unless $contains eq '' or $contains =~ /^[a-z]+$/i;
$letters .= $contains;

# Check the regex if there is one
print "regex is: $contains_re\n" if $debug;
if ( $contains_re ) {
	eval { '' =~ /$contains_re/ };
	die "The entered regular expression is not valid: $@\n" if $@;
}

# The "words" dictionary is lower case
if ( $dictionary =~ /^words$/i ) {
	$letters = lc $letters;
	$prefix  = lc $prefix;
	$suffix  = lc $suffix;
} else {
	$letters = uc $letters;
	$prefix  = uc $prefix;
	$suffix  = uc $suffix;
}

# Check minimum/maximum length
$max_length = 15 if $max_length == -1; # default
if ( $min_length == -1 ) {
	if ( $prefix or $suffix ) {
		$min_length = 1;
	} else {
		$min_length = 2;
	}
}
pod2usage() if $min_length < 1 or $min_length > 15;
pod2usage() if $max_length < 1 or $max_length > 15;
pod2usage() if $max_length < $min_length;
if ( not $prefix and not $suffix and ( $min_length == 1 or $max_length == 1) ) {
	die "Minimum or maximum length cannot be 1 unless there is a prefix or suffix\n";
}

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
	if ( not exists $ENV{LANG} or $ENV{LANG} =~ /^en_US|en_CA/ ) {
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

print "The file name for the dictionary is $file_name\n" if $debug;
print "Slurping dictionary words...\n" if $debug;
open FH, '<', $file_name or die "Could not open $file_name, $!\n";
chomp( my @words = <FH> );
my %words = map { $_ => '' } @words;
close FH;
@words = ();

# Get the tile values for all letters
print "Getting letter values...\n" if $debug;
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
print "Starting letter shuffle...\n" if $debug;
my @found = ();
my %seen = ();
my %value_of = ();
my $wildcard = "";

# Are there wildcards?
if ( $letters =~ /\./ ) {
	$letters =~ s/\.//;

	foreach $wildcard ( 'A' .. 'Z' ) {
		$wildcard = lc $wildcard if $dictionary =~ /^words$/i;
		print "***Blank tile is a '$wildcard'\n" if $debug;
		print "\n*****\n* $wildcard *\n*****\n" unless $quiet;
		Subset->run(
			string   => $letters . $wildcard,
			routine  => \&find_words,
			wildcard => $wildcard,
			prefix   => $prefix,
			suffix   => $suffix,
			is_dot   => 1,
		);
	}
} else {
	Subset->run(
		string  => $letters,
		routine => \&find_words,
		prefix  => $prefix,
		suffix  => $suffix,
		is_dot  => 0, 
	);
}

# List found words, sorting by descending total tile value
if ( $output =~ /^compact$/i ) {
	print "\n";
	print "$_($value_of{$_}), " foreach sort by_value keys %value_of;
	print "\n";
} elsif ( $output =~ /^list$/i ) {
	print "$_\t$value_of{$_}\n" foreach sort by_value keys %value_of;
} else {
	open FH, '>', $output or die "Cannot open $output for writing, $!";
	print FH "$_\t$value_of{$_}\n" foreach sort by_value keys %value_of;
	close FH;
}

###############
# Subroutines #
###############

# For each subset of letter, get all of its permutations (order)
# and test if it is a legal word.
sub find_words {
	my $self = shift;
	my @subset   = @{ $self->{subset} };
	my $wildcard = $self->{wildcard};
	my $prefix   = $self->{prefix};
	my $suffix   = $self->{suffix};
	my $is_dot   = $self->{is_dot};

	# Look for words that are the right length
	return if scalar @subset < $min_length or scalar @subset > $max_length;

	my $these_letters = join '', @subset;
	print "[find_words] Starting permutations for '$these_letters'\n" if $debug;

	# $a is an object (ref to hash) that will hold the permutations
	my $a = Permutation->new( string => $these_letters );
	my $count = 0;

	# Look at each permutation
	foreach my $word ( @{ $a->{permutations} } ) {
		$count++;
		print "." if $count % 1000 == 0 and not $quiet;

		# Add any prefix or suffix
		my $orig_word = $word;
		$word = $prefix . $orig_word . $suffix;

		if ( $orig_word ne $word ) {
			print "[find_words] word after prefix/suffix: '$word'\n" if $debug;
		}

		# Does this permutation match the entered regex?
		if ( $contains_re and $word !~ /$contains_re/i ) {
			print "[find_words] '$word' does not match regex $contains_re\n" if $debug;
			next;
		}

		# Does this permutation contain all the letters it needs to?
		my $this_word_doesnt_match = 0;

		foreach my $find ( split //, $contains ) {
			if ( $word !~ /$find/i ) {
				print "[find_words] '$word' does not contain '$find'\n" if $debug;
				$this_word_doesnt_match = 1;
				last;
			}
		}
		
		next if $this_word_doesnt_match;
		
		# Since you can have more than one tile with the same letter,
		# it is possible that we've already tested this permutation.
		# Use a hash for faster lookup.
		next if exists $seen{$word};
		$seen{$word} = '';

		# Is the permutation in the word list? (hash, actually)
		print "[find_words] is '$word' a word? " if $debug > 1;

		if ( exists $words{$word} ) {
			print "yes\n" if $debug > 1;
			push @found, $word;
			set_word_value( $word, $wildcard, $is_dot );
		} else {
			print "no\n" if $debug > 1;
		}
	}
}

# Set the total tile value of the entered word
sub set_word_value {
	my $these_letters = shift;
	my $wildcard = shift;
	my $is_dot = shift;

	# Wildcards have zero value
	my $value_letters = $these_letters; 
	$value_letters =~ s/$wildcard// if $wildcard;
	print "[set_word_value] Word: $these_letters, without wildcard: $value_letters\n" if $debug;

	# Total value and save
	my $this_value = 0;
	$this_value += $value{$_} foreach split //, $value_letters;
	my $len_wildcard = 0;
	$len_wildcard = length( $wildcard ) if $wildcard;
	my $total_len = length( $letters ) + $len_wildcard + ( $is_dot ? 1 : 0 );
	$this_value += 50 if length( $these_letters ) - length( $contains ) == $total_len;
	$value_of{ $these_letters } = $this_value;
}

# Sort words by their value
sub by_value {
	$value_of{ $b } <=> $value_of{ $a };
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

__END__
