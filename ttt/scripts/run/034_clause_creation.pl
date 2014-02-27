#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

package main;

use TestDB ();
use Test::More;

ORM::Db -> init( my $dbh = &TestDB::dbconnect() );

use Models::Author ();
use Models::Book ();
use ORM::Clause ();
use Data::Dumper 'Dumper';



{
	my @cond = ( id => 1 );

	my $c1 = Models::Author -> clause( @cond );
	my $c2 = Models::Author -> clause( cond => \@cond );


	my $a1 = Models::Author -> get( _clause => $c1 );
	ok( $a1, 'a1 get ok' );

	my $a2 = Models::Author -> get( _clause => $c2 );
	ok( $a2, 'a2 get ok' );


	is( $a1 -> id(), $a2 -> id(), 'same' )

}

{
	my @ids = ( 1, 2 );

	my @cond = ();
	map { push( @cond, ( id => $_ ) ) } @ids;

	# incorrect
	my $c1 = Models::Author -> clause( @cond,
					   logic => 'OR' );

	# correct
	my $c2 = Models::Author -> clause( cond => \@cond,
					   logic => 'OR' );
	

	my @a1 = Models::Author -> get_many( _clause => $c1 );
	my @a2 = Models::Author -> get_many( _clause => $c2 );


	is( scalar @a2, scalar @ids, 'exactly, correct clause' );
	is( scalar @a1, scalar @ids, 'too' );
	ok( scalar @a1 > 0, 'something is there' );

}


ok( 1, "didnt crash" );

done_testing();
exit( 0 );
