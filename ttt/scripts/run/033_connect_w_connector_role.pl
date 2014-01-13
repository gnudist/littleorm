#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

package main;

use Test::More;

use Models::BookHFwC ();

my @t = Models::BookHFwC -> get_many();
my $cnt = Models::BookHFwC -> count();

is( $cnt, scalar @t, 'count match' );

ok( 1, "didnt init ORM directly and still didnt crash" );

done_testing();
exit( 0 );
