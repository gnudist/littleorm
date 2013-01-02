use strict;

package ORM::Model;

# Extend ORM::Model capabilities with clause support:

sub clause
{
	my $self = shift;

	my @args = @_;

	my $class = ( ref( $self ) or $self );

	return ORM::Clause -> new( model => $class,
				   @args );

}



package ORM::Clause;

use Moose;

has 'logic' => ( is => 'rw', isa => 'Str', default => 'AND' );
has 'model' => ( is => 'rw', isa => 'Str', required => 1 );
has 'table_alias' => ( is => 'rw', isa => 'Maybe[Str]' );
has 'cond' => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );

sub sql
{
	my $self = shift;

	my @rv = $self -> gen_clauses();

	return sprintf( ' ( %s ) ', join( ' '. $self -> logic() . ' ', @rv ) );
}

sub gen_clauses
{
	my $self = shift;

	my @rv = ();

	my @c = @{ $self -> cond() };

	while ( @c )
	{
		my $item = shift @c;

		if( ref( $item ) eq 'ORM::Clause' )
		{
			push @rv, $item -> sql();
		} else
		{
			my $value = shift @c;

			push @rv, $self -> model() -> __form_where( $item => $value,
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
