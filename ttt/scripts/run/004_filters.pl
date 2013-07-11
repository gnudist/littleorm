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

ok( my $af = Models::Author -> f(), 'able to create filter object' );
is( ref( $af ), 'ORM::Filter', 'and it is actually a filter' );


done_testing();
exit( 0 );
