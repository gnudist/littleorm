package ORM::Db;

my $cached_dbh = undef;

use Carp::Assert;

sub init
{
	my $self = shift;
	my $dbh = shift;

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
	my $v = shift;

	return $cached_dbh -> quote( $v );

}

sub getrow
{
	my $sql = shift;

	return $cached_dbh -> selectrow_hashref( $sql );

}

sub prep
{
	my $sql = shift;

	return $cached_dbh -> prepare( $sql );
	
}

sub doit
{
	my $sql = shift;
	return $cached_dbh -> do( $sql );
}

sub errstr
{
	return $cached_dbh -> errstr();
}

sub nextval
{
	my $sn = shift;

	my $sql = sprintf( "SELECT nextval(%s) AS newval", &dbq( $sn ) );

	assert( my $rec = &getrow( $sql ),
		sprintf( 'could not get new value from sequence %s: %s',
			 $sn,
			 &errstr() ) );

	return $rec -> { 'newval' };
}

42;
