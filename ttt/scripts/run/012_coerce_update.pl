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


foreach my $s ( @sales )
{
	my $created = $s -> created() -> clone();
	my $plu1day = $s -> created() -> clone() -> add( days => 1 );

	$s -> created( $plu1day );
	$s -> update();
	$s -> reload();

	ok( ( $created and $plu1day ), &DTRoutines::dt2ts( $created ) . ' (plus 1 day, read back from db) ' . &DTRoutines::dt2ts( $plu1day ) );
}

$dbh -> disconnect();
done_testing();
exit( 0 );
