#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

use TestDB ();
use Test::More;

ORM::Db -> init( my $dbh = &TestDB::dbconnect() );

use Models::Book ();

my @books = Models::Book -> get_many();
ok( scalar @books, "Selected some books" );

foreach my $book ( @books )
{
	ok( $book -> id(), "book has id" );
	ok( $book -> title(), "book has title" );


	ok( my $author = $book -> author(), 'book has author' );
	is( ref( $author ), 'Models::Author', 'author is author' );
	ok( ( $author -> id() and $author -> his_name() ), 'author has id and name' );


	ok( my @authors_books = Models::Book -> get_many( author => $author ),
	    'has some books (at least this one)' );

	{
		my $found = 0;
		foreach my $b ( @authors_books )
		{
			if( $b -> id() == $book -> id() )
			{
				is( $b -> title(), $book -> title(), 'titles match too' );
				$found = 1;
			}
		}
		is( $found, 1, "found among his other books" );
	}

}

$dbh -> disconnect();
done_testing();
exit( 0 );
