#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

package main;

use TestDB ();
use Test::More;

use Models::Author ();
use Models::Book ();
use Models::Publications ();
use ORM::Filter ();
use ORM::Clause ();

use Data::Dumper 'Dumper';

ORM::Db -> init( my $dbh = &TestDB::dbconnect() );


{
	my $sql = Models::Author -> f( Models::Book -> f( Models::Publications -> f() ) ) -> get_many( _debug => 1 );

	is( $sql, 'SELECT  T3.id,T3.aname FROM publication T1,book T2,author T3 WHERE  ( 1=1 )  AND  ( T2.id=T1.book )  AND  ( 1=1 )  AND  ( T3.id=T2.author )  AND  ( 1=1 ) ', 'sql ok' );

}

{
	my $c1 = Models::Author -> clause( id => 123 );
	my $c4 = Models::Author -> clause( id => 111 );
	my $c2 = Models::Book -> clause( id => 456 );
	my $c3 = Models::Publications -> clause( id => 789 );
	
	my $sql = Models::Author -> f( Models::Book -> f( Models::Publications -> f( $c3 ),
							  $c2 ),
				       $c1 ) -> get_many( _debug => 1,
							  _clause => $c4 );

	is( $sql, "SELECT  T6.id,T6.aname FROM publication T4,book T5,author T6 WHERE  ( T6.id = '111' )  AND  ( T4.id = '789' )  AND  ( 1=1 )  AND  ( T5.id=T4.book )  AND  ( T5.id = '456' )  AND  ( 1=1 )  AND  ( T6.id=T5.author )  AND  ( T6.id = '123' )  AND  ( 1=1 ) ", 'sql ok once again' );

}


# {
# 	my $c1 = Models::Author -> clause( id => 123 );
# 	my $c4 = Models::Book -> clause( id => 111 );
	
# 	my $c2 = Models::Book -> clause( id => 456 );
# 	my $c3 = Models::Publications -> clause( id => 789 );
	
# 	my $sql = Models::Author -> f( Models::Book -> f( Models::Publications -> f( $c3 ),
# 							  $c2 ),
# 				       $c1 ) -> get_many( _debug => 1,
# 							  _clause => $c4 );

	
# 	print "'", $sql, "'\n";

# }


ok( 1, "didnt crash" );

$dbh -> disconnect();

done_testing();
exit( 0 );
