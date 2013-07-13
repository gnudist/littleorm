#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

use TestDB ();
use Test::More;

ORM::Db -> init( my $dbh = &TestDB::dbconnect() );

use Models::Author ();
use Models::Book ();

{
	my $nn = 'Jorgen Murfirson';
	my $nid = undef;

	{
		ok( my $new_author = Models::Author -> create( his_name => $nn ), 'create worked' );
		isa_ok( $new_author, 'Models::Author', 'yup, its author' );
		is( $new_author -> his_name(), $nn, 'valid name' );
		ok( $new_author -> id(), 'has id' );
	}

	{
		my $readback = Models::Author -> get( his_name => $nn );
		isa_ok( $readback, 'Models::Author', 'yup, its author' );
		is( $readback -> his_name(), $nn, 'valid name' );
		ok( $nid = $readback -> id(), 'has id' );
	}


	{
		my $nbn = 'Nord Saga vol.1';
		ok( my $new_book = Models::Book -> create( author => $nid,
							   title => $nbn,
							   price => 9 ), 'create didnt crash' );

		isa_ok( $new_book, 'Models::Book', 'book class ok' );
		is( $new_book -> title(), $nbn, 'name didnt change' );
		is( $new_book -> author() -> his_name(), $nn, 'author name ok' );
	}


	{
		my $nbn = 'Nord Saga vol.2';
		ok( my $new_book = Models::Book -> create( author => Models::Author -> get( his_name => $nn ),
							   title => $nbn,
							   price => 9 ), 'create didnt crash' );

		isa_ok( $new_book, 'Models::Book', 'book class ok' );
		is( $new_book -> title(), $nbn, 'name didnt change' );
		is( $new_book -> author() -> his_name(), $nn, 'author name ok' );
	}



}

$dbh -> disconnect();
done_testing();
exit( 0 );
