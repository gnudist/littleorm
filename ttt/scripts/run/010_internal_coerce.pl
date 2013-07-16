#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

use TestDB ();
use Test::More;

ORM::Db -> init( my $dbh = &TestDB::dbconnect() );

use Models::Sales ();


my @sales = Models::Sales -> get_many();

ok( scalar @sales, 'sales records are there' );
map { isa_ok( $_, 'Models::Sales', 'correct model class' ) } @sales;
map { isa_ok( $_ -> created(), 'DateTime', 'correct coerced field class' ) } @sales;


$dbh -> disconnect();
done_testing();
exit( 0 );
