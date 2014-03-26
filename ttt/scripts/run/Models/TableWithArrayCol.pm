#!/usr/bin/perl

use strict;

package Models::TableWithArrayCol;
use ORM;
extends 'ORM::Model';

sub _db_table { 'table_with_array_column' }

has_field 'id' => ( isa => 'Int',
		    description => { primary_key => 1,
				     db_field_type => 'int' } );

has_field 'arr_col' => ( isa => 'ArrayRef' );

has_field 'hr_col' => ( isa => 'HashRef',
			description => { coerce_from => \&_hr_col_cf,
					 coerce_to => \&_hr_col_ct } );

has_field 'not_null_no_default_col' => ( isa => 'Int' );

has_field 'created' => ( isa => 'Str' );

use Carp::Assert 'assert';

sub _hr_col_cf
{
	my $db_val = shift;

	my %rv = ();
	
	if( $db_val )
	{
		%rv = split( /:/, $db_val );
	}

	return \%rv;
}

sub _hr_col_ct
{
	my $val = shift;

	my $rv = undef;

	if( $val )
	{
		$rv = join( ':', %{ $val } );
	}

	return $rv;
}

42;
