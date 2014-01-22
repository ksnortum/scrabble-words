#! /usr/bin/perl
#
# scrabble.pl <letters> - list all possible words from a list of letters

use strict;
use warnings;
use feature 'say';

use Permutation;
use Subset;

my $letters = uc shift;
exit unless $letters;

my $debug = 0;
my %seen = ();
my @found = ();

say "slurping dictionary words..." if $debug;
## my $file_name = '/usr/share/dict/words';
my $file_name = 'sowpods.txt';
## my $file_name = 'twl.txt';
open FH, $file_name or die;
chomp( my @words = <FH> );
my %words = map { $_ => '' } @words;
close FH;
@words = ();

say "getting letter values..." if $debug;
my %value = ();
while (<DATA>) {
	chomp;
	/^([A-Z])\s+(\d+)$/ or next;
	$value{$1} = $2;
}
close DATA;

say "starting letter shuffle..." if $debug;
Subset->run(
	string  => $letters,
	routine => \&find_words
);

unless ($debug) {
	say join ', ', sort { value_of($a) <=> value_of($b) } @found;
}

sub find_words {
	return if scalar @_ < 2;

	my $letters = join '', @_;
	say "starting permutations for '$letters'" if $debug;
	my $a = Permutation->new( string => $letters );

	foreach my $word ( @{ $a->{permutations} } ) {
		next if exists $seen{$word};
		$seen{$word} = '';

		if ($debug) {
			print "is '$word' a word? ";
			say exists $words{$word} ? 'yes' : 'no';
		} else {
			push @found, $word if exists $words{$word};
		}
	}
}

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

