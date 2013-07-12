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


{
	my $author_field = Models::Author -> borrow_field( 'his_name' );
	my $book_field = Models::Book -> borrow_field( 'title' );
	my $another_bf = Models::Book -> borrow_field( 'author' );
	
	my @fs = ( $author_field, $book_field, $another_bf );
	map { ref( $_ ), 'ORM::Model::Field', 'field obj type is correct' } @fs;

	my $f = Models::Book -> f( Models::Author -> f() );
	
	my @recs = $f -> get_many( _fieldset => \@fs );
	
	ok( scalar @recs, 'we have results' );
	
	map { is( ref( $_ ), 'ORM::DataSet', 'correct result item type' ) } @recs;
	
	foreach my $rec ( @recs )
	{
		foreach my $field ( @fs )
		{
			ok( my $value = $rec -> field( $field ),
			    'has value' );
		}
		
		is( ref( $rec -> field( $another_bf ) ), "Models::Author", "correct FK field from fieldset" );
		
		is( $rec -> field( $another_bf ) -> his_name(),
		    $rec -> field( $author_field ),
		    "same author of course" );

	}
}


$dbh -> disconnect();
done_testing();
exit( 0 );
