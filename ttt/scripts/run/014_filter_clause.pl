#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

use TestDB ();
use Test::More;

ORM::Db -> init( my $dbh = &TestDB::dbconnect() );

use Models::Sales ();
use Models::Author ();
use Models::Book ();

use ORM::Filter ();
use ORM::Clause ();


foreach my $author ( Models::Author -> get_many() )
{

	my $bf = Models::Book -> filter();
	
	my $af = Models::Author -> filter();
	my $bc = Models::Book -> clause( cond => [ author => $author ] );
	
	$bf -> push_anything_appropriate( $af );
	$bf -> push_anything_appropriate( $bc );


	my @books = $bf -> get_many();

	is( scalar @books, Models::Book -> count( author => $author ), 'book count ok' );

#	print @anything, "\n";

# SELECT  T3.author,T3.id,T3.title,T3.price FROM author T4,book T3 WHERE  ( 1=1 )  AND  ( 1=1 )  AND  ( T3.author=T4.id )  AND  ( 1=1 )  AND  ( T3.author = '2' )  AND  ( 1=1 )

#	is( scalar @anything, 1, 'one author' );

}

$dbh -> disconnect();
done_testing();
exit( 0 );
