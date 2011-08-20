package ORM::Db;

my $cached_dbh = undef;

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

sub dbgetrow
{
	my $sql = shift;

	return $cached_dbh -> selectrow_hashref( $sql );

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

42;
