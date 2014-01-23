package Permutation;

use strict;
use warnings;

# string (in)       = initial string, optional
# list (in)         = ref to the inistal list of characters, optional
# permutation (out) = ref to array of all permutations
# include_self (in) = 1: include initial string in permutations
#                     0: do not include initial string
sub new {
	my $invocant = shift; # Invoked by a class or an object?
	my $class = ref($invocant) || $invocant;
	my $self = bless {
		string       => '',
		list         => [],
		permutations => [],
		include_self => 1,
		@_ # Invocation can change defaults or even add keys
	}, $class;

	if ( $self->{string} ) {
		my @a = split //, $self->{string};
		$self->{list} = \@a;
	}

	$self->_perm( $self->{list}, 0 );
	
	return $self; # return a blessed hash reference as object
}

# Internal subrutine, not intended to be called outside of object
# Params:
# 1) ref to the object
# 2) ref to the permutations array
# 3) index into the perm array
sub _perm($$$) {
	my $self = shift;
	my $a = shift;
	my $i = shift;
	
	if ( $i == $#$a ) {
		my $s = join '', @$a;
		
		if ( $self->{include_self} or $s ne $self->{string} ) {
			push @{ $self->{permutations} }, $s
		} 
	} else {
		foreach my $j ( $i .. $#$a ) {
			@$a[$i, $j] = @$a[$j, $i];
			$a = $self->_perm( $a, $i + 1 );
			@$a[$i, $j] = @$a[$j, $i];
		}
	}
	
	return $a;
}

1;
