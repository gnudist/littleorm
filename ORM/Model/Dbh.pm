use strict;

# DBH-related routines which were inside ORM/Model.pm earlier

package ORM::Model;

use Carp::Assert 'assert';

sub set_read_dbh
{
	my ( $self, $dbh ) = @_;

	# arrayref expected
	$self -> meta() -> _littleorm_rdbh( $dbh );
}

sub set_write_dbh
{
	my ( $self, $dbh ) = @_;

	# arrayref expected
	$self -> meta() -> _littleorm_wdbh( $dbh );
}

sub set_dbh
{
	my ( $self, $dbh ) = @_;

	if( ref( $dbh ) eq 'HASH' )
	{
		my ( $rdbh, $wdbh ) = @{ $dbh }{ 'read', 'write' };
		assert( $rdbh and $wdbh );

		$self -> set_read_dbh( ref( $rdbh ) eq 'ARRAY' ? $rdbh : [ $rdbh ] );
		$self -> set_write_dbh( ref( $wdbh ) eq 'ARRAY' ? $wdbh : [ $wdbh ]  );

	} else
	{
		$self -> set_read_dbh( [ $dbh ] );
		$self -> set_write_dbh( [ $dbh ] );
	}
}

# old methods

sub __get_dbh
{
	my $self = shift;
	my %args = @_;

	assert( my $for_what = $args{ '_for_what' } ); # i must know what this DBH you need for

	my $dbh = &ORM::Db::dbh_is_ok( $self -> __get_class_dbh( $for_what ) );

	unless( $dbh )
	{
		if( my $t = $args{ '_dbh' } )
		{
			$dbh = $t;
			$self -> __set_class_dbh( $dbh, $for_what );
		}
	}

	unless( $dbh )
	{
		if( my $t = &ORM::Db::get_dbh( $for_what ) )
		{
			$dbh = $t;
			$self -> __set_class_dbh( $dbh, $for_what );
		}
	}

	assert( &ORM::Db::dbh_is_ok( $dbh ), 'this method is supposed to return valid dbh' );

	return $dbh;
}

sub __get_class_dbh
{

	my ( $self, $for_what ) = @_;

	my $rv = undef;

	if( $for_what eq 'write' )
	{
		if( my $t = $self -> meta() -> _littleorm_wdbh() )
		{
			$rv = &ORM::Db::__get_rand_array_el( $t );
		}
	} else
	{
		if( my $t = $self -> meta() -> _littleorm_rdbh() )
		{
			$rv = &ORM::Db::__get_rand_array_el( $t );
		}
	}

	# my $calling_package = ( ref( $self ) or $self );
	# my $dbh = undef;

	# {
	# 	no strict "refs";
	# 	$dbh = ${ $calling_package . "::_dbh" };
	# }

	return $rv;
}

sub __set_class_dbh
{
	my ( $self, $dbh, $for_what ) = @_;

	if( $for_what )
	{
		if( $for_what eq 'read' )
		{
			$self -> set_read_dbh( [ $dbh ] );
		} elsif( $for_what eq 'write' )
		{
			$self -> set_write_dbh( [ $dbh ] );
		} else
		{
			assert( 0, 'for what? ' . $for_what );
		}
	} else
	{
		$self -> set_read_dbh( [ $dbh ] );
		$self -> set_write_dbh( [ $dbh ] );
	}

	# ancient DBH storing technique:

	# my $calling_package = ( ref( $self ) or $self );
	# {
	# 	no strict "refs";
	# 	${ $calling_package . "::_dbh" } = $dbh;
	# }

}

42;
