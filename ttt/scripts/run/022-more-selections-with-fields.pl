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
use ORM::Model::Field ();


ok( my $cnt = Models::Publications -> count(), 'there are some publications' );

my $now = ORM::Model::Field -> new( db_func => 'now' );

ok( my $previous_publications = Models::Publications -> count( created => { '<', $now } ), 'counted some previous publications' );



$dbh -> disconnect();
done_testing();
exit( 0 );
