#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

package main;

use TestDB ();
use Test::More;

use Models::Author ();
use Models::Book ();
use Models::Publications ();
use Models::Publisher ();

use ORM::Filter ();
use ORM::Clause ();


ORM::Db -> init( my $dbh = &TestDB::dbconnect() );

# look into 022-more-selections-with-fields.pl as well

{
	my $af = Models::Author -> f();
	my $bf = Models::Book -> f();
	my $pf = Models::Publisher -> f();
	my $plf = Models::Publications -> f();

	$bf -> connect_filter( $af );
	$plf -> connect_filter( $bf );
	$plf -> connect_filter( $pf );

	my $author_field = Models::Author -> borrow_field( 'id' );
	
	my $sql1 = $plf -> get_many( _debug => 1,
				     _sortby => $author_field );

	is( $sql1, "SELECT  T4.id,T4.publisher,T4.created,T4.published,T4.book FROM publication T4,book T2,author T1,publisher T3 WHERE  ( 1=1 )  AND  ( 1=1 )  AND  ( 1=1 )  AND  ( T2.author=T1.id )  AND  ( T4.book=T2.id )  AND  ( 1=1 )  AND  ( T4.publisher=T3.id )  ORDER BY T1.id", 'correct sql' );

	my $sql2 = $plf -> get_many( _debug => 1,
				     _sortby => [ $author_field, 'DESC' ] );

	is( $sql2, "SELECT  T4.id,T4.publisher,T4.created,T4.published,T4.book FROM publication T4,book T2,author T1,publisher T3 WHERE  ( 1=1 )  AND  ( 1=1 )  AND  ( 1=1 )  AND  ( T2.author=T1.id )  AND  ( T4.book=T2.id )  AND  ( 1=1 )  AND  ( T4.publisher=T3.id )  ORDER BY T1.id DESC", 'correct sql2' );


	# No test for hash, because hash can not hold field object in as it's key.

}

{

	my $af = Models::Author -> f();
	my $bf = Models::Book -> f();
	my $plf = Models::Publications -> f();

	$bf -> connect_filter( $af );
	$plf -> connect_filter( $bf );

	my $afi = Models::Author -> borrow_field( 'id' );
	my $plfi = Models::Publications -> borrow_field( 'id' );
	
	my $sql = $plf -> get_many( _fieldset => [ $afi, $plfi ],
				    _groupby => [ $afi, $plfi ],
				    _debug => 1 );
	is( $sql, "SELECT  T5.id AS _f2,T7.id AS _f3 FROM publication T7,book T6,author T5 WHERE  ( 1=1 )  AND  ( 1=1 )  AND  ( 1=1 )  AND  ( T6.author=T5.id )  AND  ( T7.book=T6.id )  GROUP BY T5.id,T7.id", "correct sql3" );

	
}



ok( 1, "didnt crash" );

$dbh -> disconnect();

done_testing();
exit( 0 );
