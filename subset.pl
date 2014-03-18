#! /usr/bin/perl
#
# subset.pl - Test Subset.pm

use strict;
use warnings;
use feature qw( say );

use Subset;

# call with a string that is split into a list,
# ref to local subroutine 
Subset->run( 
	string  => 'abc', 
	routine => \&do_this,
);

say '---------------------';

# Another way: send a ref of a list and a subroutine
Subset->run(
	set     => ['1', '2', '3'],
	routine => sub { my $self = shift; say join ':', @{ $self->{subset} } },
);

say '---------------------';

# use default routine
Subset->run( string => 'xyz' );

# routine to use in Subset
sub do_this {
	my $self = shift;
	say join ', ', @{ $self->{subset} };
}

