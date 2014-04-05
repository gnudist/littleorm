#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

package main;

use TestDB ();
use TestDB1 ();

use Test::More;

use Models::Country ();
use Models::DB1T2 ();

Models::DB1T2 -> set_dbh( &TestDB1::dbconnect() );
Models::Country -> set_dbh( &TestDB::dbconnect() );

my @all = Models::Country -> get_many();
ok( scalar @all, 'some countries there' );


my $group1 = Models::DB1T2 -> create( countries => \@all,
				      description => 'all' );

ok( ( $group1 and $group1 -> id() ), 'record created' );

map { isa_ok( $_, 'Models::Country' ) } @{ $group1 -> countries() };

is( scalar @{ $group1 -> countries() },
    scalar @all,
    'count match' );

ok( 1, "didnt crash" );

done_testing();
exit( 0 );
