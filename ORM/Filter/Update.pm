#!/usr/bin/perl
use strict;

package ORM::Filter;

# update related subs moved here to keep module file size from growing
# too much

use Data::Dumper 'Dumper';

sub update
{
	my $self = shift;
	my @update_args = @_;

	
	my @t = $self -> model() -> __form_where( @update_args );
	print Dumper( \@t );


	print "imma out\n";
	

}

42;
