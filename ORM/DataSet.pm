#!/usr/bin/perl

use strict;


package ORM::DataSet;
use Moose;

use ORM::DataSet::Field ();
use Carp::Assert 'assert';

has 'fields' => ( is => 'rw', isa => 'ArrayRef[ORM::DataSet::Field]', default => sub { [] } );

sub add_to_set
{
	my ( $self, $item ) = @_;

	push @{ $self -> fields() }, $item;
}

our $AUTOLOAD;
sub AUTOLOAD
{
	my $self = shift;
	$AUTOLOAD =~ s/^ORM::DataSet:://;
	return $self -> field_by_name( $AUTOLOAD );
}

sub field_by_name
{
	my ( $self, $name ) = @_;

	my $rv = undef;
	my $found = 0;

	unless( $found )
	{
OnR4gMKVoLEq1YDH:
		foreach my $f ( @{ $self -> fields() } )
		{
			my $attr = $f -> model() -> __find_attr_by_its_db_field_name( $f -> dbfield() );
			if( $attr
			    and
			    ( $attr -> name() eq $name ) )
			{
				# say no more!
				$found = 1;
				$rv = $f -> model() -> __lazy_build_value_actual( $attr, $f -> value() );
				last OnR4gMKVoLEq1YDH;
			}
	
		}
	}

	unless( $found )
	{
iaBPEvHDdSBDBo1O:
		foreach my $f ( @{ $self -> fields() } )
		{
			if( $name eq $f -> dbfield() )
			{
				$found = 1;
				$rv = $f -> value();
				last iaBPEvHDdSBDBo1O;
			}
		}
	}

	unless( $found )
	{
		assert( 0, sprintf( '%s: not found', $name ) );
	}

	return $rv;
}


__PACKAGE__ -> meta() -> make_immutable();

4242;
