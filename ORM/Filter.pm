#!/usr/bin/perl

use strict;

package ORM::Model;

# Extend ORM::Model capabilities with filter support:

sub f
{
	return &filter( @_ );
}

sub filter
{
	my ( $self, @args ) = @_;

	my @filters = ();

	my @clauseargs = ( _where => '1=1' );

	my $class = ( ref( $self ) or $self );

	my $rv = ORM::Filter -> new( model => $class );

	foreach my $arg ( @args )
	{
		if( blessed( $arg ) and $arg -> isa( 'ORM::Filter' ) )
		{

			map { $rv -> push_clause( $_ ) } @{ $arg -> clauses() };


		} else
		{
			push @clauseargs, $arg;
		}

	}

	{

		my $clause = ORM::Clause -> new( model => $class,
						 cond => \@clauseargs );

		$rv -> push_clause( $clause );
	}


	return $rv;
}


package ORM::Filter;

# Actual filter implementation:

use Moose;

has 'model' => ( is => 'rw', isa => 'Str', required => 1 );
has 'clauses' => ( is => 'rw', isa => 'ArrayRef[ORM::Clause]', default => sub { [] } );

use Carp::Assert 'assert';
use List::MoreUtils 'uniq';

sub push_clause
{
	my ( $self, $clause ) = @_;

	push @{ $self -> clauses() }, $clause;

	return $self -> clauses();
}


sub translate_into_sql_clauses
{
	my $self = shift;


	my $clauses_number = scalar @{ $self -> clauses() };

	my @all_clauses_together = ();

	for( my $i = 0; $i < $clauses_number; $i ++ )
	{
		my $clause = $self -> clauses() -> [ $i ];

		push @all_clauses_together, $clause -> sql();

		if( $i < $clauses_number - 1 )
		{
			my $next_clause = $self -> clauses() -> [ $i + 1 ];

			assert( my $connecting_sql = $self -> construct_connecting_sql_between( $clause -> model(),
												$next_clause -> model() ),
				sprintf( 'Could not connect %s to %s (do they have FK between them?)',
					 $clause -> model(),
					 $next_clause -> model() ) );

			push @all_clauses_together, $connecting_sql;

		}
	}

	return @all_clauses_together;
}

sub all_models_used_in_filter
{
	my $self = shift;

	my @rv = ();

	foreach my $c ( @{ $self -> clauses() } )
	{
		push @rv, $c -> model();
	}

	return @rv;
}

sub get_many
{
	my $self = shift;

	return $self -> call_orm_method( 'get_many', @_ );
}

sub get
{
	my $self = shift;

	return $self -> call_orm_method( 'get', @_ );
}

sub count
{
	my $self = shift;

	return $self -> call_orm_method( 'count', @_ );
}

sub delete
{
	assert( 0, 'Delete is not supported in ORM::Filter. Just map { $_ -> delete() } at what get_many() returns.' );
}

sub call_orm_method
{
	my $self = shift;
	my $method = shift;

	my @args = @_;

	return $self -> model() -> $method( @args,
					    _tables_to_select_from => [ uniq map { $_ -> _db_table() } $self -> all_models_used_in_filter() ],
					    _where => join( ' AND ', $self -> translate_into_sql_clauses() ) );
}

sub construct_connecting_sql_between_actually_do
{
	my ( $self, $model1, $model2 ) = @_;

	my $rv = undef;

DQoYV7htzKfc5YJC:
	foreach my $attr ( $model1 -> meta() -> get_all_attributes() )
	{
		if( my $fk = &ORM::Model::__descr_attr( $attr, 'foreign_key' ) )
		{
			if( $model2 eq $fk )
			{
				my $foreign_key_attr_name = &ORM::Model::__descr_attr( $attr, 'foreign_key_attr_name' );
				
				unless( $foreign_key_attr_name )
				{
					my $his_pk = $model2 -> __find_primary_key();
					$foreign_key_attr_name = $his_pk -> name();
				}
				
				
				$rv = sprintf( " ( %s.%s = %s.%s ) ",
					       $model1 -> _db_table(),
					       &ORM::Model::__get_db_field_name( $attr ),
					       $model2 -> _db_table(),
					       $foreign_key_attr_name );
				last DQoYV7htzKfc5YJC;
			}
		}
	}
	
	return $rv;
}

sub construct_connecting_sql_between
{
	my ( $self, $model1, $model2 ) = @_;

	my $rv = undef;


	$rv = ( $self -> construct_connecting_sql_between_actually_do( $model1, $model2 )
		or
		$self -> construct_connecting_sql_between_actually_do( $model2, $model1 ) );

	return $rv;
}

42;
