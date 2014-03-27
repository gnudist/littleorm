#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

package main;

use TestDB ();
use Test::More;

ORM::Db -> init( my $dbh = &TestDB::dbconnect() );

use Models::AuthorHFSubFromGenericID ();
use Models::AuthorHFSubFromGenericID_Im ();

use Models::Book ();

use Models::BookHF ();
use Models::AuthorHF ();

use ORM::Filter ();


{
	my $new_author = Models::AuthorHFSubFromGenericID -> create( his_name => 'True Talent' . rand() );
	ok( $new_author -> id(), '"id" is classic style attr and still read back ok: ' . $new_author -> id() );
}


{
	foreach ( 1 .. 10 )
	{
		my $nn = 'Tru3 Talent' . rand();
		my $new_author = Models::AuthorHFSubFromGenericID_Im -> create( his_name => $nn );
		ok( $new_author -> id(), '"id" is classic style attr and still read back ok: ' . $new_author -> id() );
		is( $new_author -> his_name(), $nn, 'name read back ok' );
	}
}


{



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
	
	
}


{
	
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
	
	{
		my $f = Models::BookHF -> filter( Models::AuthorHF -> f() );
		ok( 'didnt crash' );
	}
	
	
}

ok( 1, "didnt crash" );

done_testing();
exit( 0 );
