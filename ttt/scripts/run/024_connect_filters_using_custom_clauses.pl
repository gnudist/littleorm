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
use ORM::DataSet ();
use Models::Publications ();
use Models::Publisher ();
use Models::AuthorInfo ();
use ORM::Model::Field ();
use Models::BookNoFK ();


{
	my $af = Models::Author -> f( id => 1 );

	my $bf = Models::Book -> f();

	$bf -> connect_filter( _clause => [],
			       $af );

	my @all = $bf -> get_many();


	my $cnt_a = Models::Author -> count();
	my $cnt_b = Models::Book -> count();

	is( scalar @all, $cnt_b, 'because tables were not actually connected (empty clause)' );

}


{
	my $aid = 1;
	my $af = Models::Author -> f( id => $aid );

	my $bf = Models::Book -> f();

	$bf -> connect_filter( $af );

	my @all = $bf -> get_many();
	my $cnt_b = Models::Book -> count( author => $aid );

	is( scalar @all, $cnt_b, 'obvious match' );

}


{

	my $aid = 1;
	my $af = Models::Author -> f( id => $aid );

	my $bf = Models::Book -> f();

	$bf -> connect_filter_left_outer_join( $af,
					       _clause => [] );
	my @all = $bf -> get_many();

	my $cnt_b = Models::Book -> count();

	is( scalar @all, $cnt_b, 'because tables were not actually connected (empty clause)' );

}


{
	# completely artificial example 

	my $bf = Models::Book -> f( id => 1 );
	my $titlef = $bf -> borrow_field( 'title' );
	my $pricef = $bf -> borrow_field( 'price' );
	my $authorf = $bf -> borrow_field( 'author' );

	my $af = Models::Author -> f( id => { '>', 0 } );
	
	$af -> connect_filter( $bf,
			       _clause => [ cond => [ _clause => [ cond => [ $titlef => { 'IS NOT', undef },
									     id => $authorf ] ],
							  
							  _clause => [ cond => [ $titlef => { 'IS', undef },
										 id => { '!=', $authorf } ] ]
						      
					    ],
					    
					    logic => 'OR' ] );
	

	my $ami = Models::AuthorInfo -> f( $af );


	my @recs = $ami -> get_many();
	ok( 1, 'didnt crash' );

#SELECT T9.author,T9.id,T9.married FROM author T8,book
#T7,author_more_info T9 WHERE ( 1=1 AND T8.id > '0' ) AND ( 1=1 AND
#T7.id = '1' ) AND ( ( T7.title IS NOT NULL AND T8.id = T7.author ) OR
#( T7.title IS NULL AND T8.id != T7.author ) ) AND ( T9.author=T8.id )
#AND ( 1=1 )




}

{
	my $af = Models::Author -> f( id => 1 );
	my $bf = Models::BookNoFK -> f();

	$bf -> connect_filter( $af,
			       _clause => [ cond => [ author => $af -> borrow_field( 'id' ) ] ] );

	my $cnt = $bf -> count();

	ok( 1, 'didnt crash' );

	is( $cnt, Models::Book -> count( author => 1 ), 'match' );

}

$dbh -> disconnect();
done_testing();
exit( 0 );
