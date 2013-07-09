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

has 'select_as' => ( is => 'rw',
		     isa => 'Str',
		     default => \&get_select_as_field_name );


use Carp::Assert 'assert';

{
	my $cnt = 0;

	sub get_select_as_field_name
	{
		$cnt ++;

		return '_f' . $cnt; # lowcase

	}
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
			       $rv );
	}

	return $rv;

}


394041;
