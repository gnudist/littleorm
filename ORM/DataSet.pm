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


{
	my %cache = ();

	sub get_model_instance_for_value_building
	{
		my ( $self, $model ) = @_;

		unless( $cache{ $model } )
		{
			$cache{ $model } = $model -> new( _rec => {} );
		}

		return $cache{ $model };
	}

}

sub field_by_name
{
	my ( $self, $name ) = @_;

	my $rv = undef;
	my $found = 0;

	unless( $found )
	{
		foreach my $f ( @{ $self -> fields() } )
		{
			my $attr = $f -> model() -> __find_attr_by_its_db_field_name( $f -> dbfield() );
			if( $attr
			    and
			    ( $attr -> name() eq $name ) )
			{
				# say no more!
				$found = 1;
				my $t = $self -> get_model_instance_for_value_building( $f -> model() );
				$t -> _rec( { $f -> dbfield() => $f -> value() } );
				$rv = $t -> __lazy_build_value( $attr );
			}
	
		}
	}

	unless( $found )
	{
		foreach my $f ( @{ $self -> fields() } )
		{
			if( $name eq $f -> dbfield() )
			{
				$found = 1;
				$rv = $f -> value();
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
