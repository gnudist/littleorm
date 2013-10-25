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


ok( my $author = Models::Author -> get( id => 1 ), 'a1' );
ok( my $another_author = Models::Author -> get( id => 2 ), 'a2' );

Models::Book -> f( author => $author ) -> update( author => $another_author );


ok( 1, "didnt crash" );

$dbh -> disconnect();

done_testing();
exit( 0 );
