#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

use ORM::Db ();
use TestDB ();

use Carp::Assert 'assert';

my $dbh = &TestDB::dbconnect();

assert( ORM::Db::dbh_is_ok( $dbh ) );

$dbh -> disconnect();

exit( 0 );
