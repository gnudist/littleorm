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
has 'included_tables' => ( is => 'rw', isa => 'HashRef', default => sub { {} } );

use Carp::Assert 'assert';

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

			my @call_args = ( @args,
					  $item => $value,
					  _table_alias => $self -> table_alias() );

			my @where_part = $self -> model() -> __form_where( @call_args );

			if( $item eq '_where' )
			{
				@where_part = $self -> apply_internal_sql_text_replaces( \@where_part, \@args );
			}

			# print Data::Dumper::Dumper( \@call_args );
			# print Data::Dumper::Dumper( \@where_part );

			push @rv, @where_part;

		}
	}

	unless( @rv )
	{
		@rv = ( '1=1' );
	}

	return @rv;

}

sub apply_internal_sql_text_replaces
{
	my $self = shift;

	my ( $where_part, $args ) = @_;

	my @where_part = @{ $where_part };
	my %args = @{ $args };

	# actually lets be specific:
	assert( $where_part[ 0 ] );
	assert( scalar @where_part == 1 );

	if( my %t = %{ $self -> included_tables() } )
	{
		if( my $already = $args{ '_already_used' } )
		{
			map { delete $t{ $_ } } keys %{ $already };
		}

		my %replaces = ( '[__ORM_USED_TABLES__]' => join( ",", map { $t{ $_ } . " " . $_ } keys %t ) );
		while( my ( $k, $v ) = each %replaces )
		{
			$where_part[ 0 ] =~ s/\Q$k\E/$v/g;
		}
	}

	return @where_part;
}


42;
