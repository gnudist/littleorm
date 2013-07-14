#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

use TestDB ();
use Test::More;

ORM::Db -> init( my $dbh = &TestDB::dbconnect() );

use Models::Author ();
use Models::Book ();

{

	foreach my $author ( Models::Author -> get_many() )
	{
		my $new_name = $author -> his_name() . ' Jr.';
		$author -> his_name( $new_name );
		$author -> update();


		my $record_with_new_name = Models::Author -> get( his_name => $new_name );
		is( $record_with_new_name -> id(), $author -> id(), 'same author with new name' );
	}
}

{
	foreach my $book ( Models::Book -> get_many() )
	{
		$book -> price( int( rand( 1000 ) ) );
		$book -> update();
		ok( 1, 'set price and update and didnt crash' );
	}
}


$dbh -> disconnect();
done_testing();
exit( 0 );
