use strict;

package ORM::Clause;

use Moose;

has 'logic' => ( is => 'rw', isa => 'Str', default => 'AND' );
has 'model' => ( is => 'rw', isa => 'Str', required => 1 );
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

			push @rv, $self -> model() -> __form_where( $item => $value );

		}
	}

	unless( @rv )
	{
		@rv = ( '1=1' );
	}

	return @rv;

}


42;
