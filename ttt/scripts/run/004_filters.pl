#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

use TestDB ();
use Test::More;

ORM::Db -> init( my $dbh = &TestDB::dbconnect() );

use Models::Author ();
use Models::Book ();

use ORM::Filter ();
use ORM::Clause ();

{

	ok( my $af = Models::Author -> f(), 'able to create filter object' );
	is( ref( $af ), 'ORM::Filter', 'and it is actually a filter' );
	
	ok( my $bf = Models::Book -> f(), 'able to create filter object' );
	is( ref( $af ), 'ORM::Filter', 'and it is actually a filter' );
	
	my @authors_with_books = $af -> get_many( _exists => $bf );
	map { is( ref( $_ ), 'Models::Author', "this actually is author: " . $_ -> his_name() ) } @authors_with_books;
	
	is( scalar @authors_with_books, Models::Author -> count(), "every author has a book" );
}

{

	ok( my $af = Models::Author -> f( his_name => "John Smith" ), 'able to create filter object' );
	is( ref( $af ), 'ORM::Filter', 'and it is actually a filter' );
	
	ok( my $bf = Models::Book -> f( _exists => $af ), 'able to create filter object' );
	is( ref( $af ), 'ORM::Filter', 'and it is actually a filter' );

	ok( $bf -> count(), 'such books exist' );

	my @books = $bf -> get_many();
	is( scalar @books, $bf -> count(), "items quantity match count" );

	
}


$dbh -> disconnect();
done_testing();
exit( 0 );
