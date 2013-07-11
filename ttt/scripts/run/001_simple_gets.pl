#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

use TestDB ();
use Test::More;

ORM::Db -> init( my $dbh = &TestDB::dbconnect() );

use Models::Author ();

my @authors = Models::Author -> get_many();
ok( scalar @authors, "Selected some records" );

foreach my $rec ( @authors )
{
	is( ref( $rec ), 'Models::Author', 'correct class' );
	ok( $rec -> id(), "record has id" );
	ok( $rec -> his_name(), "record has name" );


	ok( my $by_name = Models::Author -> get( his_name => $rec -> his_name() ),
	    'able to select record by name' );

	is( $by_name -> id(), $rec -> id(), 'IDs match' )
}

$dbh -> disconnect();

done_testing();
exit( 0 );
