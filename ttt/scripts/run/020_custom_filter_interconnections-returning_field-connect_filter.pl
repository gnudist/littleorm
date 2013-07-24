#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

use TestDB ();
use Test::More tests => 6;
use Data::Dumper 'Dumper';

ORM::Db -> init( my $dbh = &TestDB::dbconnect() );

use Models::Author ();
use Models::AuthorNoPK ();

use Models::BookNoFK ();
use Models::BookNoFKAndNoPK ();

use ORM::Clause ();
use ORM::Filter ();


subtest 'BookNoFK => AuthorNoPK' => sub
{
	plan tests => 3;

	my $bf = Models::BookNoFK -> f();

	{
		my $af = Models::AuthorNoPK -> f();

		ok( not( defined( eval{ $bf -> connect_filter( author => $af ); $bf } ) ), 'Impossible connection is impossible' );

		my $old_field = $af -> returning_field();

		$af -> returning_field( $af -> model() -> borrow_field( 'id' ) );

		$bf -> connect_filter( author => $af );

		$af -> returning_field( $old_field );

		ok( not( defined( eval{ $bf -> connect_filter( author => $af ); $bf } ) ), 'Impossible connection is still impossible' );
	}

	ok( $bf -> get(), 'Works' );
};

subtest 'BookNoFKAndNoPK => AuthorNoPK' => sub
{
	plan tests => 3;

	my $bf = Models::BookNoFKAndNoPK -> f();

	{
		my $af = Models::AuthorNoPK -> f();

		ok( not( defined( eval{ $bf -> connect_filter( author => $af ); $bf } ) ), 'Impossible connection is impossible' );

		my $old_field = $af -> returning_field();

		$af -> returning_field( $af -> model() -> borrow_field( 'id' ) );

		$bf -> connect_filter( author => $af );

		$af -> returning_field( $old_field );

		ok( not( defined( eval{ $bf -> connect_filter( author => $af ); $bf } ) ), 'Impossible connection is still impossible' );
	}

	ok( $bf -> get(), 'Works' );
};

subtest 'Author => BookNoFK' => sub
{
	plan tests => 1;

	my $bf = Models::Author -> f();

	{
		my $af = Models::BookNoFK -> f();

		my $old_field = $af -> returning_field();

		$af -> returning_field( $af -> model() -> borrow_field( 'author' ) );

		$bf -> connect_filter( id => $af );

		$af -> returning_field( $old_field );
	}

	ok( $bf -> get(), 'Works' );
};

subtest 'Author => BookNoFKAndNoPK' => sub
{
	plan tests => 3;

	my $bf = Models::Author -> f();

	{
		my $af = Models::BookNoFKAndNoPK -> f();

		ok( not( defined( eval{ $bf -> connect_filter( id => $af ); $bf } ) ), 'Impossible connection is impossible' );

		my $old_field = $af -> returning_field();

		$af -> returning_field( $af -> model() -> borrow_field( 'author' ) );

		$bf -> connect_filter( id => $af );

		$af -> returning_field( $old_field );

		ok( not( defined( eval{ $bf -> connect_filter( id => $af ); $bf } ) ), 'Impossible connection is still impossible' );
	}

	ok( $bf -> get(), 'Works' );
};

subtest 'AuthorNoPK => BookNoFK' => sub
{
	plan tests => 1;

	my $bf = Models::AuthorNoPK -> f();

	{
		my $af = Models::BookNoFK -> f();

		my $old_field = $af -> returning_field();

		$af -> returning_field( $af -> model() -> borrow_field( 'author' ) );

		$bf -> connect_filter( id => $af );

		$af -> returning_field( $old_field );
	}

	ok( $bf -> get(), 'Works' );
};

subtest 'AuthorNoPK => BookNoFKAndNoPK' => sub
{
	plan tests => 3;

	my $bf = Models::AuthorNoPK -> f();

	{
		my $af = Models::BookNoFKAndNoPK -> f();

		ok( not( defined( eval{ $bf -> connect_filter( id => $af ); $bf } ) ), 'Impossible connection is impossible' );

		my $old_field = $af -> returning_field();

		$af -> returning_field( $af -> model() -> borrow_field( 'author' ) );

		$bf -> connect_filter( id => $af );

		$af -> returning_field( $old_field );

		ok( not( defined( eval{ $bf -> connect_filter( id => $af ); $bf } ) ), 'Impossible connection is still impossible' );
	}

	ok( $bf -> get(), 'Works' );
};

$dbh -> disconnect();

exit( 0 );

