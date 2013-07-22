#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

use TestDB ();
use Test::More tests => 9;
use Data::Dumper 'Dumper';

ORM::Db -> init( my $dbh = &TestDB::dbconnect() );

use Models::Book ();
use Models::Sales ();
use Models::Publications ();

use ORM::Filter ();
use ORM::Clause ();
use ORM::DataSet ();

my $bf = Models::Book -> f();
my $sf = Models::Sales -> f();
my $pf = Models::Publications -> f();

$bf -> connect_filter_left_join( $sf );
$bf -> connect_filter_left_join( $pf );

{
	my @all     = $bf -> get_many( _distinct => 1 );
	my $all_cnt = scalar( @all );

	ok( ( $all_cnt > 0 ), 'Got some rows' );

	subtest 'regular get_many call' => sub{
		plan tests => $all_cnt;

		isa_ok( $_, 'Models::Book', 'book' ) for @all;
	};

	is( $all_cnt, Models::Book -> count(), 'count match' );
}

{
	my $author_f = Models::Book -> borrow_field( 'author', _distinct => 1 );
	isa_ok( $author_f, 'ORM::Model::Field', 'borrowed a field' );

	my $title_f = Models::Book -> borrow_field( 'title', _distinct => 1 );
	isa_ok( $title_f, 'ORM::Model::Field', 'borrowed a field' );

	my @all_fieldset     = $bf -> get_many( _fieldset => [ $author_f, $title_f ], _distinct => 1 );
	my $all_fieldset_cnt = scalar( @all_fieldset );

	ok( ( $all_fieldset_cnt > 0 ), 'Got some rows' );

	my $found_author = 0;
	my $found_title  = 0;

	subtest 'get_many w/ DataSet' => sub{
		plan tests => $all_fieldset_cnt;

		foreach my $ds ( @all_fieldset )
		{
			isa_ok( $ds, 'ORM::DataSet', 'its ds' );

			++$found_author if $ds -> field( $author_f );
			++$found_title if $ds -> field( $title_f );
		}
	};

	is( $found_author, scalar( @all_fieldset ), 'Every book has its author' );
	is( $found_title, scalar( @all_fieldset ), 'Every book has its title' );
}

$dbh -> disconnect();

exit( 0 );

