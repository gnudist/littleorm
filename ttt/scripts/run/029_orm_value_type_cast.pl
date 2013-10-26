#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

package main;

use TestDB ();
use Test::More;

use Models::Author ();
use Models::Book ();

use ORM::Model::Field ();
use ORM::Model::Value ();
use ORM::Model ();
use ORM::Clause ();
use ORM::Filter ();

ORM::Db -> init( my $dbh = &TestDB::dbconnect() );

my $author = ORM::Model::Value -> new( db_field_type => 'varchar',
				       value => 100,
				       orm_coerce => 0 );

my $rv = Models::Book -> f( author => $author ) -> get_many( _debug => 1 );

print $rv, "\n";



ok( 1, "didnt crash" );

$dbh -> disconnect();

done_testing();
exit( 0 );
