#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

use TestDB ();
use Test::More;

ORM::Db -> init( my $dbh = &TestDB::dbconnect() );

use Models::BookHF ();

my @books = Models::BookHF -> get_many();
ok( scalar @books, "(hf) selected some books" );

foreach my $book ( @books )
{
	ok( $book -> id(), "(hf) book has id" );
	ok( $book -> title(), "(hf) book has title" );


	ok( my $author = $book -> author(), '(hf) book has author' );
	is( ref( $author ), 'Models::AuthorHF', '(hf) author is author' );
	ok( ( $author -> id() and $author -> his_name() ), '(hf) author has id and name' );


	ok( my @authors_books = Models::BookHF -> get_many( author => $author ),
	    '(hf) has some books (at least this one)' );

	{
		my $found = 0;
		foreach my $b ( @authors_books )
		{
			if( $b -> id() == $book -> id() )
			{
				is( $b -> title(), $book -> title(), '(hf) titles match too' );
				$found = 1;
			}
		}
		is( $found, 1, "(hf) found among his other books" );
	}

}

$dbh -> disconnect();

done_testing();
exit( 0 );
