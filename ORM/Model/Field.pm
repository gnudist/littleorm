use strict;

package ORM::Model::Field;
use Moose;

has 'model' => ( is => 'rw',
		 isa => 'Str' );

has 'base_attr' => ( is => 'rw',
		     isa => 'Str',
		     default => '' );

has 'db_func' => ( is => 'rw',
		   isa => 'Str' );

has 'db_func_tpl' => ( is => 'rw',
		       isa => 'Str',
		       default => '%s(%s)' );

has 'func_args_tpl' => ( is => 'rw',
			 isa => 'Str',
			 default => '%s' );

has 'select_as' => ( is => 'rw',
		     isa => 'Str',
		     default => \&get_select_as_field_name );

has 'post_process' => ( is => 'rw',
			isa => 'CodeRef',
			default => sub { sub { $_[ 0 ] } } );

has 'type_preserve' => ( is => 'rw',
			 isa => 'Bool',
			 default => 0 );

has '_distinct' => ( is => 'rw',
		     isa => 'Bool',
		     default => 0 );


use Carp::Assert 'assert';
use Scalar::Util 'blessed';

{
	my $cnt = 0;

	sub get_select_as_field_name
	{
		$cnt ++;

		return '_f' . $cnt; # lowcase

	}
}

sub this_is_field
{
	my ( $self, $attr ) = @_;

	my $rv = 0;

	if( blessed( $attr ) and ( $attr -> isa( 'ORM::Model::Field' ) ) )
	{
		$rv = 1;
	}
	return $rv;
}

sub assert_model
{
	my ( $self, $model ) = @_;

	my $t = ( ref( $model ) or $model );
	assert( $self -> model() eq $t );
}

sub form_field_name_for_db_select
{
	my ( $self, $table ) = @_;

	my $rv = $self -> base_attr();

	if( $rv )
	{
		assert( $self -> model() );
		$rv = $table . '.' . &ORM::Model::__get_db_field_name( $self -> model() -> meta() -> find_attribute_by_name( $rv ) );
	}

	if( my $f = $self -> db_func() )
	{
		$rv = sprintf( $self -> db_func_tpl(),
			       $f,
			       sprintf( $self -> func_args_tpl(),
					( $self -> _distinct() ? ' DISTINCT ' : '' ) . $rv ) );
	}

	return $rv;

}


394041;
