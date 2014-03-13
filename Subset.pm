package Subset;

use strict;
use warnings;
use feature qw( say );

sub run {
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;
	my $self = bless {
		routine  => sub { say join ' ', @_ },
		string   => "",
		set      => [],
		@_	
	}, $class;

	if ( $self->{string} ) { 
		my @list = split //, $self->{string};
		$self->{set} = \@list;
	}

	$self->_subsets();

	return $self; # This value can be ignored
}

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
			$self->{current_list} = \@current_list;
			&{ $self->{routine} }( $self );
		}
	};

	&$do_subset();
}

1;

