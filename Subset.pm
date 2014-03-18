package Subset;

use strict;
use warnings;
use feature qw( say );

# routine(in) - The subroutine to run for each subset
# string(in)  - The string representation of the set
# set(in)     - The List representation of the set
# subset      - The current subset to be used by routine
# Either 'string' or 'set' should be entered, not both
# Any other key can be passed into $self for use in routine
sub run {
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;
	my $self = bless {
		routine => sub { my $self = shift; say @{ $self->{subset} } },
		string  => "",
		set     => [],
		subset  => [],
		@_	
	}, $class;

	if ( $self->{string} ) { 
		my @list = split //, $self->{string};
		$self->{set} = \@list;
	}

	$self->_subsets();

	return $self; # This value can be ignored
}

# Internal routine that splits the set into subsets and runs the entered routine
sub _subsets {
	my $self = shift;
	my $current_size = 0;                 # Current item
	my @current_list = ();                # Current subset
	my $this_list = $self->{set};         # Ref of list to be subsetted
	my $list_size = scalar @$this_list;   # Size of list to be subsetted
	my $do_subset;                        # Generate each subset
	
	$do_subset = sub {
		if ($current_size < $list_size ) {
			++$current_size;
			&$do_subset();
			push @current_list, $$this_list[ $current_size - 1 ];
			&$do_subset();
			pop @current_list;
			--$current_size;
		} else {
			$self->{subset} = \@current_list;
			&{ $self->{routine} }( $self );		# Run subroutine, passing in $self for arguments
		}
	};

	&$do_subset();
}

1;

