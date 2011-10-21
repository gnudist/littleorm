package ORM::Db;

my $cached_dbh = undef;

use Carp::Assert;

sub __set_default_if_not_set
{
	my ( $self, $dbh ) = @_;

	unless( my $t = $self -> get_dbh() )
	{
		# small racecond :)
		$self -> init( $dbh );
	}
}

sub dbh_is_ok
{
	my $dbh = shift;

	my $rv = $dbh;

	if( $dbh )
	{

		unless( $dbh -> ping() )
		{
			$rv = undef;
		}
	}

	return $rv;
}

sub init
{
	my ( $self, $dbh ) = @_;

	unless( $dbh )
	{
		# non-object call ?
		$dbh = $self;
	}

	$cached_dbh = $dbh;

}

sub get_dbh
{
	return $cached_dbh;
}

sub dbq
{
	my ( $v, $dbh ) = @_;


	unless( $dbh )
	{
		$dbh = $cached_dbh;
	}

	assert( $dbh );

	return $dbh -> quote( $v );

}

sub getrow
{
	my ( $sql, $dbh ) = @_;

	unless( $dbh )
	{
		$dbh = $cached_dbh;
	}

	assert( $dbh );

	return $dbh -> selectrow_hashref( $sql );

}

sub prep
{
	my ( $sql, $dbh ) = @_;

	unless( $dbh )
	{
		$dbh = $cached_dbh;
	}

	assert( $dbh );

	return $dbh -> prepare( $sql );
	
}

sub doit
{
	my ( $sql, $dbh ) = @_;

	unless( $dbh )
	{
		$dbh = $cached_dbh;
	}

	assert( $dbh );

	return $dbh -> do( $sql );
}

sub errstr
{
	my $dbh = shift;

	unless( $dbh )
	{
		$dbh = $cached_dbh;
	}
	
	assert( $dbh );

	return $dbh -> errstr();
}

sub nextval
{
	my ( $sn, $dbh ) = @_;

	unless( $dbh )
	{
		$dbh = $cached_dbh;
	}

	my $sql = sprintf( "SELECT nextval(%s) AS newval", &dbq( $sn, $dbh ) );

	assert( my $rec = &getrow( $sql, $dbh ),
		sprintf( 'could not get new value from sequence %s: %s',
			 $sn,
			 &errstr( $dbh ) ) );

	return $rec -> { 'newval' };
}

42;
