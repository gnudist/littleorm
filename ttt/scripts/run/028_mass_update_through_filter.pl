#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

package main;

use TestDB ();
use Test::More;

use Models::Book ();

use ORM::Model::Field ();
use ORM::Model::Value ();
use ORM::Model ();
use ORM::Clause ();
use ORM::Filter ();

ORM::Db -> init( my $dbh = &TestDB::dbconnect() );



Models::Book -> f( author => $author ) -> update( author => $another_author );


ok( 1, "didnt crash" );

$dbh -> disconnect();

done_testing();
exit( 0 );
