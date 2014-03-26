#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

package main;

use TestDB ();
use Test::More;

ORM::Db -> init( my $dbh = &TestDB::dbconnect() );

use Models::TableWithArrayCol ();

my @t = ( 1 .. 10 );

my $new_rec = Models::TableWithArrayCol -> create( arr_col => \@t );

ok( $new_rec -> id(), "insert success" );

ok( 1, "didnt crash" );

done_testing();
exit( 0 );
