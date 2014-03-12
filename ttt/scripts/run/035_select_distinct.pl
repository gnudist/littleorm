#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

package main;

use TestDB ();
use Test::More;

ORM::Db -> init( my $dbh = &TestDB::dbconnect() );

use Models::Author ();
use Models::Book ();
use ORM::Clause ();
use Data::Dumper 'Dumper';

use ORM::DataSet ();

my $cnt = Models::Book -> count();
ok( $cnt > 0, 'we have some books indeed: ' . $cnt );

my $a_cnt = Models::Author -> count();
ok( $a_cnt > 0, 'we have some authors indeed: ' . $a_cnt );


my @distinct_books = Models::Book -> get_many( _distinct => 'yes' );
is( scalar @distinct_books, $cnt, 'books count matches to distinct books number' );

my @distinct_authors = Models::Book -> get_many( _distinct => [ 'author' ],
						 _fieldset => [ 'author' ] );

ok( scalar @distinct_authors <= $a_cnt, "maybe not all authors have books" );


foreach my $ds ( @distinct_authors )
{
	isa_ok( $ds, 'ORM::DataSet', 'of course this is dataset' );

	ok( my $author = $ds -> field_by_name( 'author' ) );
	isa_ok( $author, 'Models::Author', 'of course this is author' );

}


{
	my $afield = Models::Book -> borrow_field( 'author' );

	my @distinct_authors = Models::Book -> get_many( _distinct => [ $afield ],
							 _fieldset => [ $afield ] );

	ok( scalar @distinct_authors <= $a_cnt, "maybe not all authors have books" );


	foreach my $ds ( @distinct_authors )
	{
		isa_ok( $ds, 'ORM::DataSet', 'of course this is dataset' );
		
		ok( my $author = $ds -> field( $afield ) );
		isa_ok( $author, 'Models::Author', 'of course this is author' );
		
	}
	
	
}

ok( 1, "didnt crash" );

done_testing();
exit( 0 );
