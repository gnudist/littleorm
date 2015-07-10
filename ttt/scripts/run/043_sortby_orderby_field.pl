#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

package main;

use TestDB ();
use Test::More;

use Models::Author ();
use Models::Book ();
use ORM::Filter ();

use Data::Dumper 'Dumper';

ORM::Db -> init( my $dbh = &TestDB::dbconnect() );


{
	my $f1 = Models::Book -> borrow_field( 'price' );
	
	my $sql = Models::Author -> filter( Models::Book -> filter() ) -> get_many( _limit => 3,
										    _sortby => [ $f1 => 'DESC' ],
										    _debug => 1 );


	my $correct_sql = 'SELECT  T2.id,T2.aname FROM book T1,author T2 WHERE  ( 1=1 )  AND  ( T2.id=T1.author )  AND  ( 1=1 )  ORDER BY T1.price DESC LIMIT 3 ';
	

	is( $sql, $correct_sql, 'sql ok' );

}


ok( 1, "didnt crash" );

$dbh -> disconnect();

done_testing();
exit( 0 );
