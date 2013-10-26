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

	my @rv = $self -> gen_clauses( @_ );
	return sprintf( ' ( %s ) ', join( ' '. $self -> logic() . ' ', @rv ) );
}

sub gen_clauses
{
	my $self = shift;
	my @args = @_;

	my @rv = ();

	my @c = @{ $self -> cond() };

	while( @c )
	{
		my $item = shift @c;

		if( ref( $item ) eq 'ORM::Clause' )
		{
			if( ( $item -> model() eq $self -> model() ) and ( my $ta = $self -> table_alias() ) and ( not $item -> table_alias() ) )
			{
				# copy obj ?
				my $copy = bless( { %{ $item } }, ref $item );
				$item = $copy;
				$item -> table_alias( $ta );
			}

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
		@rv = ( '2=2' );
	}

	return @rv;

}


42;
