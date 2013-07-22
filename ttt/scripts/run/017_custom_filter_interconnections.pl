#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

use TestDB ();
use Test::More tests => 10;
use Data::Dumper 'Dumper';

ORM::Db -> init( my $dbh = &TestDB::dbconnect() );

use Models::Author ();
use Models::AuthorNoPK ();

use Models::Book ();
use Models::BookNoFK ();
use Models::BookNoFKAndNoPK ();

use ORM::Filter ();
use ORM::Clause ();
use ORM::DataSet ();


subtest 'BookNoFK => Author' => sub
{
	plan tests => 7;

	my $bf = Models::BookNoFK -> f( author => Models::Author -> f() );

	isa_ok( $bf, 'ORM::Filter', 'filter' );

	my $count = () = $bf -> get_many( _distinct => 1 );

	ok( ( $count > 0 ), 'Got some rows' );

	is( $bf -> count(), $count, 'count()' );


	ok( $bf -> max( 'id' ), 'max()' );
	ok( $bf -> min( 'id' ), 'min()' );

	isa_ok( my $r = $bf -> get( _fieldset => [ Models::Author -> borrow_field( 'his_name' => ( select_as => 'his_name' ) ) ] ), 'ORM::DataSet', 'result' );

	ok( $r -> his_name(), 'DataSet has his_name()' );
};


subtest 'BookNoFKAndNoPK => Author' => sub
{
	plan tests => 7;

	my $bf = Models::BookNoFKAndNoPK -> f( author => Models::Author -> f() );

	isa_ok( $bf, 'ORM::Filter', 'filter' );

	my $count = () = $bf -> get_many( _distinct => 1 );

	ok( ( $count > 0 ), 'Got some rows' );

	is( $bf -> count(), $count, 'count()' );
	ok( $bf -> max( 'id' ), 'max()' );
	ok( $bf -> min( 'id' ), 'min()' );

	isa_ok( my $r = $bf -> get( _fieldset => [ Models::Author -> borrow_field( 'his_name' => ( select_as => 'his_name' ) ) ] ), 'ORM::DataSet', 'result' );

	ok( $r -> his_name(), 'DataSet has his_name()' );
};

subtest 'BookNoFK => AuthorNoPK' => sub
{
	plan tests => 7;

	my $bf = Models::BookNoFK -> f( author => Models::AuthorNoPK -> f( _return => 'id' ) );

	isa_ok( $bf, 'ORM::Filter', 'filter' );

	my $count = () = $bf -> get_many( _distinct => 1 );

	ok( ( $count > 0 ), 'Got some rows' );

	is( $bf -> count(), $count, 'count()' );
	ok( $bf -> max( 'id' ), 'max()' );
	ok( $bf -> min( 'id' ), 'min()' );

	isa_ok( my $r = $bf -> get( _fieldset => [ Models::AuthorNoPK -> borrow_field( 'his_name' => ( select_as => 'his_name' ) ) ] ), 'ORM::DataSet', 'result' );

	ok( $r -> his_name(), 'DataSet has his_name()' );
};

subtest 'BookNoFKAndNoPK => AuthorNoPK' => sub
{
	plan tests => 7;

	my $bf = Models::BookNoFKAndNoPK -> f( author => Models::AuthorNoPK -> f( _return => 'id' ) );

	isa_ok( $bf, 'ORM::Filter', 'filter' );

	my $count = () = $bf -> get_many( _distinct => 1 );

	ok( ( $count > 0 ), 'Got some rows' );

	is( $bf -> count(), $count, 'count()' );
	ok( $bf -> max( 'id' ), 'max()' );
	ok( $bf -> min( 'id' ), 'min()' );

	isa_ok( my $r = $bf -> get( _fieldset => [ Models::AuthorNoPK -> borrow_field( 'his_name' => ( select_as => 'his_name' ) ) ] ), 'ORM::DataSet', 'result' );

	ok( $r -> his_name(), 'DataSet has his_name()' );
};

subtest 'Author => BookNoFK' => sub
{
	plan tests => 7;
#	plan skip_all => 'broken';

	my $bf = Models::Author -> f( id => Models::BookNoFK -> f( _return => 'author' ) );

	isa_ok( $bf, 'ORM::Filter', 'filter' );

	my $count = () = $bf -> get_many( _distinct => 1 );

	ok( ( $count > 0 ), 'Got some rows' );

#	is( $bf -> count(), $count, 'count()' );
	is( $bf -> count( _distinct => 1 ), $count, 'count()' );
	ok( $bf -> max( 'id' ), 'max()' );
	ok( $bf -> min( 'id' ), 'min()' );

	isa_ok( my $r = $bf -> get( _fieldset => [ Models::Author -> borrow_field( his_name => ( select_as => 'his_name' ) ) ] ), 'ORM::DataSet', 'result' );

	ok( $r -> his_name(), 'DataSet has his_name()' );
};

subtest 'Author => BookNoFKAndNoPK' => sub
{
	plan tests => 7;
#	plan skip_all => 'broken';

	my $bf = Models::Author -> f( id => Models::BookNoFKAndNoPK -> f( _return => 'author' ) );

	isa_ok( $bf, 'ORM::Filter', 'filter' );

	my $count = () = $bf -> get_many( _distinct => 1 );

	ok( ( $count > 0 ), 'Got some rows' );

	is( $bf -> count( _distinct => 1 ), $count, 'count()' );
	ok( $bf -> max( 'id' ), 'max()' );
	ok( $bf -> min( 'id' ), 'min()' );

	isa_ok( my $r = $bf -> get( _fieldset => [ Models::Author -> borrow_field( his_name => ( select_as => 'his_name' ) ) ] ), 'ORM::DataSet', 'result' );

	ok( $r -> his_name(), 'DataSet has his_name()' );
};

subtest 'AuthorNoPK => BookNoFK' => sub
{
	plan tests => 8;

	my $bf = Models::AuthorNoPK -> f( id => Models::BookNoFK -> f( _return => 'author' ) );

	isa_ok( $bf, 'ORM::Filter', 'filter' );

	my $count = () = $bf -> get_many( _distinct => 1 );

	ok( ( $count > 0 ), 'Got some rows' );

#	is( $bf -> count(), $count, 'count()' );
	ok( $bf -> count(), 'count()' ); # <= counts not unique rows

	subtest 'distinct count' => sub
	{
		plan tests => 2;

		my $row = $bf -> get(
			_fieldset => [
				$bf -> model() -> borrow_field( id => (
					_distinct => 1,
					select_as => 'count',
					db_func   => 'count'
				) )
			]
		);

		isa_ok( $row, 'ORM::DataSet', 'result' );

		is( $row -> count(), $count, 'distinct count()' );
	};

	ok( $bf -> max( 'id' ), 'max()' );
	ok( $bf -> min( 'id' ), 'min()' );

	isa_ok( my $r = $bf -> get( _fieldset => [ Models::AuthorNoPK -> borrow_field( 'his_name' => ( select_as => 'his_name' ) ) ] ), 'ORM::DataSet', 'result' );

	ok( $r -> his_name(), 'DataSet has his_name()' );
};

subtest 'AuthorNoPK => BookNoFKAndNoPK' => sub
{
	plan tests => 8;

	my $bf = Models::AuthorNoPK -> f( id => Models::BookNoFKAndNoPK -> f( _return => 'author' ) );

	isa_ok( $bf, 'ORM::Filter', 'filter' );

	my $count = () = $bf -> get_many( _distinct => 1 );

	ok( ( $count > 0 ), 'Got some rows' );

#	is( $bf -> count(), $count, 'count()' );
	ok( $bf -> count(), 'count()' ); # <= counts not unique rows

	subtest 'distinct count' => sub
	{
		plan tests => 2;

		my $row = $bf -> get(
			_fieldset => [
				$bf -> model() -> borrow_field( id => (
					_distinct => 1,
					select_as => 'count',
					db_func   => 'count'
				) )
			]
		);

		isa_ok( $row, 'ORM::DataSet', 'result' );

		is( $row -> count(), $count, 'distinct count()' );
	};

	ok( $bf -> max( 'id' ), 'max()' );
	ok( $bf -> min( 'id' ), 'min()' );

	isa_ok( my $r = $bf -> get( _fieldset => [ Models::AuthorNoPK -> borrow_field( 'his_name' => ( select_as => 'his_name' ) ) ] ), 'ORM::DataSet', 'result' );

	ok( $r -> his_name(), 'DataSet has his_name()' );
};

subtest 'AuthorNoPK => BookNoFK, without BookNoFK _return definition' => sub
{
	plan tests => 7;

	my $bf = Models::AuthorNoPK -> f( id => Models::BookNoFK -> f() );

	isa_ok( $bf, 'ORM::Filter', 'filter' );

	my $count = () = $bf -> get_many( _distinct => 1 );

	ok( ( $count > 0 ), 'Got some rows' );

	is( $bf -> count(), $count, 'count()' );
	ok( $bf -> max( 'id' ), 'max()' );
	ok( $bf -> min( 'id' ), 'min()' );

	isa_ok( my $r = $bf -> get( _fieldset => [ Models::AuthorNoPK -> borrow_field( 'his_name' => ( select_as => 'his_name' ) ) ] ), 'ORM::DataSet', 'result' );

	ok( $r -> his_name(), 'DataSet has his_name()' );

	diag 'Logically it seems to be OK, but do we really need such wrong queries?';
};

subtest 'Impossible filters are impossible' => sub{
	my @the_whole_thing = (
#		[ sub{ Models::AuthorNoPK -> f( id => Models::BookNoFK -> f() ) }, 'author.id => book.?' ], # <= works, look above
		[ sub{ Models::AuthorNoPK -> f( id => Models::BookNoFKAndNoPK -> f() ) }, 'author.id => book.?' ],
		[ sub{ Models::AuthorNoPK -> f( Models::BookNoFK -> f( _return => 'author' ) ) }, 'author.? => book.author' ],
		[ sub{ Models::BookNoFK -> f( author => Models::AuthorNoPK -> f() ) }, 'book.author => author.?' ],
		[ sub{ Models::BookNoFK -> f( Models::AuthorNoPK -> f( _return => 'id' ) ) }, 'book.? => author.id' ],

		[ sub{ Models::BookNoFK -> f( Models::AuthorNoPK -> f() ) }, 'book.? => author.?' ],
		[ sub{ Models::AuthorNoPK -> f( Models::BookNoFK -> f() ) }, 'author.? => book.?' ],

		[ sub{ Models::Author -> f( Models::BookNoFK -> f() ) }, 'author.id => book.?' ],
		[ sub{ Models::AuthorNoPK -> f( Models::Book -> f() ) }, 'author.? => book.author' ],
		[ sub{ Models::Book -> f( Models::AuthorNoPK -> f() ) }, 'book.author => author.?' ],
		[ sub{ Models::BookNoFK -> f( Models::Author -> f() ) }, 'book.? => author.id' ]
	);

	plan tests => scalar( @the_whole_thing );

	foreach my $spec ( @the_whole_thing )
	{
		my ( $code, $note ) = @$spec;

		my $filter = eval{ $code -> () };

		ok( not( defined $filter ), sprintf( q|Can't create such filter: %s|, $note ) );
	}
};

FINISHEDTEST:

$dbh -> disconnect();

exit( 0 );

