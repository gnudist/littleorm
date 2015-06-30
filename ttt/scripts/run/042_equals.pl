#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

package main;

use TestDB ();
use Test::More;

use Models::Author ();
use Models::Book ();

use Data::Dumper 'Dumper';

ORM::Db -> init( my $dbh = &TestDB::dbconnect() );



{
	ok( my $a1 = Models::Author -> get(), 'any record will do' );
	ok( my $a2 = Models::Author -> get( id => $a1 -> id() ), 'new object same record' );

	ok( $a1 -> equals( $a2 ), 'equals() 1' );
	ok( $a2 -> equals( $a1 ), 'equals() 2' );


	ok( $a1 -> equals( $a2 -> id() ), 'equals() 3' );
	ok( $a2 -> equals( $a1 -> id() ), 'equals() 4' );

	ok( my $a3 = Models::Author -> get( id => { '!=', $a1 -> id() } ), 'any OTHER record will do' );

	ok( $a3 -> id() != $a1 -> id(), 'free test hooray' );
	ok( ! $a1 -> equals( $a3 ), 'not equals() 1' );
	ok( ! $a3 -> equals( $a1 ), 'not equals() 2' );

	ok( ! $a1 -> equals( $a3 -> id() ), 'not equals() 3' );
	ok( ! $a3 -> equals( $a1 -> id() ), 'not equals() 4' );

	
}




ok( 1, "didnt crash" );

$dbh -> disconnect();

done_testing();
exit( 0 );
