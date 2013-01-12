use strict;

package LittleORM::Model;

# Extend LittleORM::Model capabilities with clause support:

sub clause
{
	my $self = shift;

	my @args = @_;

	my $class = ( ref( $self ) or $self );

	return LittleORM::Clause -> new( model => $class,
					 @args );

}



package LittleORM::Clause;

use Moose;

has 'logic' => ( is => 'rw', isa => 'Str', default => 'AND' );
has 'model' => ( is => 'rw', isa => 'Str', required => 1 );
has 'table_alias' => ( is => 'rw', isa => 'Maybe[Str]' );
has 'cond' => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );

sub sql
{
	my $self = shift;

	my @rv = $self -> gen_clauses( @_ );

	return sprintf( ' ( %s ) ', join( ' '. $self -> logic() . ' ', @rv ) );
}

sub gen_clauses
{
	my $self = shift;
	my @args = @_;

	my @rv = ();

	my @c = @{ $self -> cond() };

	while ( @c )
	{
		my $item = shift @c;

		if( ref( $item ) eq 'LittleORM::Clause' )
		{
			push @rv, $item -> sql();
		} else
		{
			my $value = shift @c;

			push @rv, $self -> model() -> __form_where( @args,
								    $item => $value,
								    _table_alias => $self -> table_alias() );

		}
	}

	unless( @rv )
	{
		@rv = ( '1=1' );
	}

	return @rv;

}


42;
