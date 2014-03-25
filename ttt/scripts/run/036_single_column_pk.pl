#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

package main;

use TestDB ();
use Test::More;

ORM::Db -> init( my $dbh = &TestDB::dbconnect() );

use Models::SingleColumnPK ();

my $new_rec = Models::SingleColumnPK -> create();

ok( $new_rec -> id(), 'success' );

ok( 1, "didnt crash" );

done_testing();
exit( 0 );
