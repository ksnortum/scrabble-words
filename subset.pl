#! /usr/bin/perl
#
# subset.pl - Test Subset.pm

use strict;
use warnings;
use feature 'say';

use Subset;

# gather the substs locally
my $subsets = [];

# call with a string that is split into a list,
# ref to local subroutine acts as a closure
Subset->run( 
	string  => 'abc', 
	routine => \&run,
);

# process list of subsets locally
foreach my $subset ( @$subsets ) {
	say join ' ', @$subset;
}

# Another way: send a ref of a list and a ref of a subroutine,
# everything is processed in the module
Subset->run(
	set     => ['1', '2', '3'],
	routine => sub { say @_ },
);

# Local subroutine to use as closure,
# @_ is a list of one subset
sub run {
	push @$subsets, \@_;
}
