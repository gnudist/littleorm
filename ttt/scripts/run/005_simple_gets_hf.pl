#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

use TestDB ();
use Test::More;

ORM::Db -> init( my $dbh = &TestDB::dbconnect() );

use Models::AuthorHF ();

my @authors = Models::AuthorHF -> get_many();
ok( scalar @authors, "(hf) selected some records" );

foreach my $rec ( @authors )
{
	is( ref( $rec ), 'Models::AuthorHF', '(hf) correct class' );
	ok( $rec -> id(), "(hf) record has id" );
	ok( $rec -> his_name(), "(hf) record has name" );


	ok( my $by_name = Models::AuthorHF -> get( his_name => $rec -> his_name() ),
	    '(hf) able to select record by name' );

	is( $by_name -> id(), $rec -> id(), '(hf) IDs match' )
}

$dbh -> disconnect();
done_testing();
exit( 0 );
