#!/usr/bin/perl

use strict;

package TestDB1;

use TestDB ();
use Carp::Assert 'assert';

{
	my $dbh = undef;

	sub dbconnect
	{
		unless( $dbh )
		{
			$dbh = &__actually_connect();
		}

		return $dbh;
	}
}

sub __actually_connect
{
	my %args = &TestDB::__collect_connect_parameters();

	assert( $args{ 'TESTDBNAME1' } and $args{ 'TESTDBNAME' } );

	$args{ 'TESTDBNAME' } = $args{ 'TESTDBNAME1' };

	return &TestDB::__actually_connect( %args );

}

42;
