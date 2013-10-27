#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

package main;

use TestDB ();
use Test::More;

use Models::Author ();
use Models::Book ();

use ORM::Model::Field ();
use ORM::Model::Value ();
use ORM::Model ();
use ORM::Clause ();
use ORM::Filter ();

ORM::Db -> init( my $dbh = &TestDB::dbconnect() );


ok( my $author = Models::Author -> get( id => 1 ), 'a1' );
ok( my $another_author = Models::Author -> get( id => 2 ), 'a2' );

my @a1books = map { $_ -> id() } Models::Book -> f( author => $author ) -> get_many();

my $rv = Models::Book -> f( author => $author ) -> update( author => $another_author );

is( scalar @a1books, $rv, 'count match' );

foreach my $bid ( @a1books )
{
  	my $rv = Models::Book -> f( id => $bid,
  				    author => $another_author ) -> update( author => $author );
	
	is( $rv, 1, 'change was really made and now rolled back' );
	
}



my $sql = Models::Book -> f( author => $author ) -> update( author => Models::Book -> borrow_field( 'title' ),
							    _debug => 1 );

is( $sql, 
    "UPDATE book SET author=title::int WHERE  ( author = '1' ) ",
    'sql req generated as palnned' );



# my $sql = Models::Book -> update( author => $another_author,
# 				  _where => [ author => $author ],
# 				  _debug => 1 );

# print $sql, "\n";


# $book -> update( author => $another_author );


# Models::Book -> update( author => $another_author,
#                         _where => [ author => $author ] );


ok( 1, "didnt crash" );

$dbh -> disconnect();

done_testing();
exit( 0 );
