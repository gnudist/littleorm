#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

use ORM::Db ();
use TestDB ();

use Test::More;

plan tests => 1;

my $dbh = &TestDB::dbconnect();

ok( ORM::Db::dbh_is_ok( $dbh ), 'LittleORM likes this $dbh' );

$dbh -> disconnect();

exit( 0 );
