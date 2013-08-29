#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

package test33::Model;

use ORM;

extends 'ORM::Model';

sub _db_table { 'model1table' }

has_field attrs => ( isa => 'Int' );#, description => { coerce_from => sub{ {} }, coerce_to => sub{ '' } } );

no ORM;

package main;

use TestDB ();
use Test::More;

use ORM::Model::Field ();
use ORM::Model ();
use ORM::Clause ();
use ORM::Filter ();

ORM::Db -> init( my $dbh = &TestDB::dbconnect() );

print test33::Model -> filter() -> get_many(
	_debug  => 1,
	_limit  => 100500,
	_offset => 0
) . "\n";

ok( 1, "didnt crash" );

$dbh -> disconnect();

done_testing();
exit( 0 );
