#!/usr/bin/perl

use strict;


package ORM::Meta::Role;

use Moose::Role;

has 'found_orm'	=> ( is => 'rw', isa => 'Bool', default => 0 );

no Moose::Role;



package ORM;

use Moose;
use Moose::Exporter;
use Moose::Util::MetaRole;

use Carp::Assert 'assert';
use Scalar::Util ();

Moose::Exporter -> setup_import_methods( with_meta => [ 'has_field' ],
					 also      => 'Moose' );
sub init_meta
{
	my ( $class, %args ) = @_;
	
	Moose -> init_meta( %args );
	
	return &Moose::Util::MetaRole::apply_metaroles(
		for             => $args{ 'for_class' },
		class_metaroles => {
			class => [ 'ORM::Meta::Role' ]
		}
	    );
}

sub has_field
{
	my ( $meta, $name, %args ) = @_;
	
	unless( $meta -> found_orm() )
	{
		my @isa = $meta -> linearized_isa();
		my $ok  = 0;
		
		foreach my $class ( @isa )
		{
			if( $class -> isa( 'ORM::Model' ) )
			{
				$meta -> found_orm( $ok = 1 );
				
				last;
			}
		}
		
		assert( $ok, sprintf( 'Class "%s" must extend ORM::Model', $isa[ 0 ] ) );
	}

	return &__has_field_no_check( $meta, $name, %args );
}
	
sub __has_field_no_check
{
	my ( $meta, $name, %args ) = @_;

	if( ref( $args{ 'traits' } ) eq 'ARRAY' )
	{
		push @{ $args{ 'traits' } }, 'ORM::Meta::Trait';
	} else
	{
		$args{ 'traits' } = [ 'ORM::Meta::Trait' ];
	}
	
	unless( ref( $args{ 'description' } ) eq 'HASH' )
	{
		$args{ 'description' } = {};
	}

	my $attr = undef;

	unless( $args{ 'description' } -> { 'ignore' } )
	{
		$args{ 'is' }   = 'rw';
		$args{ 'lazy' } = 1;

		foreach my $key ( 'builder', 'default' )
		{
			assert( not( exists $args{ $key } ), sprintf( 'There is a problem with attribute "%s": you should not use "%s" in LittleORM attribute. Consider using "description => { coerce_from => sub{ ... } }" instead, or just add "description => { ignore => 1 }".', $name, $key ) );
		}

		$args{ 'default' } = sub 
		{
			my $self = shift;

			if( $attr -> isa( 'Moose::Meta::Role::Attribute' ) )
			{
				$attr = $self -> meta() -> find_attribute_by_name( $name );
			}

			return $self -> __lazy_build_value( $attr );
		};
	}
	
	$args{ 'is' } ||= 'rw';
	
	$attr = $meta -> add_attribute( $name, %args );

	Scalar::Util::weaken( $attr );

	return 1;
}

no Moose::Util::MetaRole;
no Moose::Exporter;
no Moose;

-1;

