#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

use TestDB ();
use Test::More;

ORM::Db -> init( my $dbh = &TestDB::dbconnect() );

use Models::Author ();
use Models::Book ();


my @books = Models::Book -> get_many( id => { '>=', 0 } );

ok( scalar @books, 'something is there' );

foreach my $book ( @books )
{
	isa_ok( $book, 'Models::Book', 'correct class' );

	my $copy = $book -> copy();
	isa_ok( $copy, 'Models::Book', 'correct class' );
	$copy -> title( $copy -> title() . ' (copy)' );
	$copy -> update();

	isnt( $copy -> id(), $book -> id(), 'other book - other id' );

	my $cloned = $book -> clone();
	isa_ok( $cloned, 'Models::Book', 'correct class' );
	is( $cloned -> id(), $book -> id(), 'same book - same id' );

}


$dbh -> disconnect();
done_testing();
exit( 0 );
