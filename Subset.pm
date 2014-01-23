package Subset;

use strict;
use warnings;
use feature 'say';

sub run($%) {
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;
	my $self = bless {
		routine => sub { say join ' ', @_ },
		string  => "",
		set     => [],
		@_	
	}, $class;

	if ( $self->{string} ) { 
		my @list = split //, $self->{string};
		$self->{set} = \@list;
	}

	_subsets( $self->{routine}, $self->{set} );

	return $self;
}

sub _subsets($$) {
	my $routine = shift;                  # Subroutine to call to process each subset
	my $current_size = 0;                 # Current item
	my @current_list = ();                # Current subset
	my $this_list = shift;                # Ref of list to be subsetted
	my $list_size = scalar(@$this_list);  # Size of list to be subsetted

	my $do_subset;     # Generate each subset
	$do_subset = sub {
		if ($current_size < $list_size ) {
			++$current_size;
			&$do_subset();
			push @current_list, $$this_list[ $current_size - 1 ];
			&$do_subset();
			pop @current_list;
			--$current_size;
		} else {
			&$routine(@current_list);
		}
	};

	&$do_subset;
}

1;

