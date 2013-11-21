use strict;

# DBH-related routines

package ORM::Model;

use Carp::Assert 'assert';

sub set_read_dbh
{
	my ( $self, $dbh ) = @_;

	# TODO handle arrays
	$self -> meta() -> _littleorm_rdbh( $dbh );
}

sub set_write_dbh
{
	my ( $self, $dbh ) = @_;

	# TODO handle arrays
	$self -> meta() -> _littleorm_wdbh( $dbh );
}

sub set_dbh
{
	my ( $self, $dbh ) = @_;

	if( ref( $dbh ) eq 'HASH' )
	{
		my ( $rdbh, $wdbh ) = @{ $dbh }{ 'read', 'write' };
		assert( $rdbh and $wdbh );

		$self -> set_read_dbh( $rdbh );
		$self -> set_write_dbh( $wdbh );

	} else
	{
		$self -> set_read_dbh( $dbh );
		$self -> set_write_dbh( $dbh );
	}
}

# old methods

sub __get_dbh
{
	my $self = shift;

	my %args = @_;

	my $dbh = &ORM::Db::dbh_is_ok( $self -> __get_class_dbh() ); # here 1

	unless( $dbh )
	{
		if( my $t = $args{ '_dbh' } )
		{
			$dbh = $t;
			$self -> __set_class_dbh( $dbh );
			ORM::Db -> __set_default_if_not_set( $dbh );
		}
	}

	unless( $dbh )
	{
		if( my $t = &ORM::Db::get_dbh() )
		{
			$dbh = $t;
			$self -> __set_class_dbh( $dbh );
		}
	}

	assert( &ORM::Db::dbh_is_ok( $dbh ), 'this method is supposed to return valid dbh' );

	return $dbh;
}

sub __get_class_dbh
{

	my $self = shift;

	my $calling_package = ( ref( $self ) or $self );

	my $dbh = undef;

	{
		no strict "refs";
		$dbh = ${ $calling_package . "::_dbh" };
	}

	return $dbh;
}

sub __set_class_dbh
{
	my $self = shift;

	my $calling_package = ( ref( $self ) or $self );

	my $dbh = shift;

	{
		no strict "refs";
		${ $calling_package . "::_dbh" } = $dbh;
	}

}

42;
