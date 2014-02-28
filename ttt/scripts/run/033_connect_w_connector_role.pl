#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

package main;

use Test::More;

use Models::BookHFwC ();  # this model has connector role which reaturns meaningful connecting code
use Models::BookHFwCE (); # this model has connector role which reaturns empty arguments, no connecting code

# In real life we now can vary whenever we want or we do not want to
# automatically connect, placing the logic into connect-info-role.

{
	my @t = Models::BookHFwC -> get_many();
	my $cnt = Models::BookHFwC -> count();
	
	is( $cnt, scalar @t, 'count match' );

	ok( 1, "didnt init ORM directly and still didnt crash" );
}


{
	eval {
		my @t = Models::BookHFwCE -> get_many();
	};

	if( $@ )
	{
		print $@;
	}
	ok( $@, 'err occured, ORM not initialized globally, but connect role did not return code' );
}


{

	ORM::Db -> init( my $dbh = &TestDB::dbconnect() );

	my @t = Models::BookHFwCE -> get_many();
	my $cnt = Models::BookHFwCE -> count();

	is( $cnt, scalar @t, 'count match' );
	ok( 1, "fall back to ORM init global dbh" );
}

done_testing();
exit( 0 );
