#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

package main;

use TestDB ();
use Test::More;

use Models::Metatable ();

use Data::Dumper 'Dumper';

ORM::Db -> init( my $dbh = &TestDB::dbconnect() );

{

	my $f2 = Models::Metatable -> borrow_field( 'f01',
						    db_func => 'date' );
	
	my $f1 = ORM::Model::Field -> new( db_func => 'now' );
	my $f3 = ORM::Model::Field -> new( db_func => 'date',
					   base_field => $f1 );
	
	
	my $sql = Models::Metatable -> get( $f2 => $f3,
					    _fieldset => [ 'id' ],
					    _debug => 1 );
	
	is( $sql, 'SELECT  metatable.id AS id FROM metatable WHERE date(metatable.f01) = date(now()) LIMIT 1 ', 'correct sql' );
	
}

{

	my $f2 = Models::Metatable -> borrow_field( 'f01',
						    db_func => 'date' );
	
	my $f1 = ORM::Model::Field -> new( db_func => 'now' );
	my $f3 = $f1 -> wrap_field( db_func => 'date' ); # the only change compared to prev. block
	
	my $sql = Models::Metatable -> get( $f2 => $f3,
					    _fieldset => [ 'id' ],
					    _debug => 1 );
	
	is( $sql, 'SELECT  metatable.id AS id FROM metatable WHERE date(metatable.f01) = date(now()) LIMIT 1 ', 'correct sql (wrap field method)' );
	
}

ok( 1, "didnt crash" );

$dbh -> disconnect();

done_testing();
exit( 0 );
