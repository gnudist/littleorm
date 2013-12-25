#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

package main;

use TestDB ();
use TestDB1 ();

use Test::More;

use Models::BookHFwC ();

use Data::Dumper 'Dumper';

my $dbh = &TestDB::dbconnect();
my $dbh1 = &TestDB1::dbconnect();



my @t = Models::BookHFwC -> get_many();
my $cnt = Models::BookHFwC -> count();

is( $cnt, scalar @t, 'count match' );




ok( 1, "didnt init ORM directly and still didnt crash" );

$dbh -> disconnect();
$dbh1 -> disconnect();

done_testing();
exit( 0 );
