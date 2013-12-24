#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

package main;

use TestDB ();
use TestDB1 ();

use Test::More;

use Models::DB1T1 ();
use Models::Country ();

use Data::Dumper 'Dumper';

my $dbh = &TestDB::dbconnect();
my $dbh1 = &TestDB1::dbconnect();




{
	Models::DB1T1 -> set_class_dbh( $dbh1 );
	my @all = Models::DB1T1 -> get_many();
	ok( scalar @all, 'something is there' );
	
	foreach my $item ( @all )
	{
		eval {
			my $c = $item -> country();
		};

		my $err = $@;

		ok( $err, 'error happened, because other DBH dbh required to get FK' );
	}
}

{
	Models::DB1T1 -> set_class_dbh( $dbh1 );
	Models::Country -> set_class_dbh( $dbh );

	my @all = Models::DB1T1 -> get_many();
	ok( scalar @all, 'something is there' );
	
	foreach my $item ( @all )
	{
		eval {
			my $c = $item -> country();
		};

		my $err = $@;

		ok( !$err, 'error NOT happened' );
		is( $item -> country() -> cname(), $item -> data(), 'match' );
	}
}





ok( 1, "didnt crash" );

$dbh -> disconnect();
$dbh1 -> disconnect();

done_testing();
exit( 0 );
