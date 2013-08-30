#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

use TestDB ();
use Test::More;

ORM::Db -> init( my $dbh = &TestDB::dbconnect() );

use Models::Author ();
use Models::Book ();

{
	my @authors = Models::Author -> get_many();
	ok( scalar @authors, "Selected some records" );

	foreach my $rec ( @authors )
	{
		is( ref( $rec ), 'Models::Author', 'correct class' );
		ok( $rec -> id(), "record has id" );
		ok( $rec -> his_name(), "record has name" );


		ok( my $by_name = Models::Author -> get( his_name => $rec -> his_name() ),
		    'able to select record by name' );

		is( $by_name -> id(), $rec -> id(), 'IDs match' )
	}




}

{
	my @authors = Models::Author -> get_many();
	my @books = Models::Book -> get_many( author => \@authors );

	is( scalar @books, Models::Book -> count(), 'every book has some author' );


	foreach my $au ( @authors )
	{
		my @b1 = Models::Book -> get_many( author => { '=', $au } );
		my @b2 = Models::Book -> get_many( author => { '!=', $au } );
		my @b3 = Models::Book -> get_many( author => { 'IN', [ $au ] } );


		my $af = Models::Book -> borrow_field( 'author' );

		my @b4 = Models::Book -> get_many( $af => { '=', $au } );
		my @b5 = Models::Book -> get_many( $af => { '!=', $au } );
		my @b6 = Models::Book -> get_many( $af => { 'IN', [ $au ] } );


		is( scalar @b1, scalar @b4, 'match' );
		is( scalar @b2, scalar @b5, 'match' );
		is( scalar @b3, scalar @b6, 'match' );


	}
}

{
	my @authors = Models::Author -> get_many();
	my @names = map { $_ -> his_name() } @authors;
	my @ids = map { $_ -> id() } @authors;

	my @authors_by_name = Models::Author -> get_many( his_name => \@names );
	is( scalar @authors, scalar @authors_by_name, 'select by array field works' );

	my @authors_by_ids = Models::Author -> get_many( id => \@ids );
	is( scalar @authors, scalar @authors_by_ids, 'select by id field works' );

	my @authors_by_both = Models::Author -> get_many( id => \@ids,
							  his_name => \@names );

	is( scalar @authors, scalar @authors_by_both, 'select by 2 array fields works' );


}



$dbh -> disconnect();
done_testing();
exit( 0 );
