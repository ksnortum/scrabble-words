#! /usr/bin/perl
#
# permutation.pl - test Permutation.pm

use strict;
use warnings;

use Permutation;

# Send in a string
my $a = Permutation->new( string => 'abc' );

foreach my $i ( @{ $a->{permutations} } ) {
	print "$i\n";
}

#...or a ref to a list
my @list = qw(1 2 3);
my $b = Permutation->new( list => \@list );

foreach my $i ( @{ $b->{permutations} } ) {
	print "$i\n";
}
