#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

use TestDB ();
use Test::More;

ORM::Db -> init( my $dbh = &TestDB::dbconnect() );
use ORM::DataSet ();

use Models::Book ();
use Models::Author ();


{
	my $books_count = Models::Book -> count();
	ok( $books_count, "total: " . $books_count . " books" );
	
	foreach my $author ( Models::Author -> get_many() )
	{
		
		my $books_count = Models::Book -> count( author => $author );
		ok( $books_count, sprintf( "%s has %d books",
					   $author -> his_name(),
					   $books_count ) );
		

	
	}
}

{
	my $max = Models::Book -> max( 'id' );
	ok( $max, "max book id is: " . $max );

	my $min = Models::Book -> min( 'id' );
	ok( $min, "min book id is: " . $min );


	foreach my $author ( Models::Author -> get_many() )
	{

		my $max = Models::Book -> max( 'id',
					       author => $author );
		ok( $max, $author -> his_name() . "'s max book id is: " . $max );

		my $min = Models::Book -> min( 'id',
					       author => $author );
		ok( $min, $author -> his_name() . "'s min book id is: " . $min );


	}

}

{
	my $dsarr = Models::Book -> count( _groupby => [ 'author' ] );

	map { is( ref( $_ ), 'ORM::DataSet', 'count with _groupby returns ORM::DataSet' ) } @{ $dsarr };

	ok( scalar @{ $dsarr } == Models::Author -> count(), 'every author has a book' );
	my $books_count = Models::Book -> count();
	my $sum = 0;

	foreach my $ds ( @{ $dsarr } )
	{
		$sum += $ds -> count();
		is( ref( $ds -> author() ), 'Models::Author', 'valid author object: ' . $ds -> author() -> his_name() );
		is( $ds -> author() -> id(), $ds -> field_by_name( 'author' ) -> id(), 'still the same' );
	}

	is( $books_count, $sum, 'no books left out' );

}

{
	ok( my $afield = Models::Book -> borrow_field( 'author',
						       select_as => 'author' ), '(field) can borrow a field' );

	my $dsarr = Models::Book -> count( _groupby => [ $afield ] );

	map { is( ref( $_ ), 'ORM::DataSet', '(field) count with _groupby returns ORM::DataSet' ) } @{ $dsarr };

	ok( scalar @{ $dsarr } == Models::Author -> count(), '(field) every author has a book' );
	my $books_count = Models::Book -> count();
	my $sum = 0;

	foreach my $ds ( @{ $dsarr } )
	{
		$sum += $ds -> count();
		is( ref( $ds -> author() ), 'Models::Author', '(field) valid author object: ' . $ds -> author() -> his_name() );
		is( $ds -> author() -> id(), $ds -> field_by_name( 'author' ) -> id(), '(field) still the same' );
	}

	is( $books_count, $sum, '(field) no books left out' );

}

{
	ok( my $countf = ORM::Model::Field -> new( db_func => 'count',
						   func_args_tpl => '*' ), 'can create count field' );
	ok( my $count = Models::Author -> get( _fieldset => [ $countf ] ), 'able to select count field' );

	is( ref( $count ), 'ORM::DataSet', 'with fieldset dataset is returned' );

	is( $count -> field( $countf ), Models::Author -> count(), 'count with field matches count with built-in func' );

}

{

	my $pricef = Models::Book -> borrow_field( 'price',
						   'db_func' => 'min' );

	my @recs = Models::Book -> get_many( _fieldset => [ $pricef ],
					     _groupby => [ 'author' ] );

	is( scalar @recs, Models::Author -> count(), "because every author has at leas 1 book" );

	foreach my $rec ( @recs )
	{
		isa_ok( $rec, 'ORM::DataSet', 'this is ds' );
		isa_ok( $rec -> author(), 'Models::Author', 'author is there' );
		ok( $rec -> field( $pricef ), 'aggregate is there' );
	}

}


{
	my $dsarr = Models::Book -> max( 'price',
					 _groupby => [ 'author' ] );

	map { is( ref( $_ ), 'ORM::DataSet', 'count with _groupby returns ORM::DataSet' ) } @{ $dsarr };

	ok( scalar @{ $dsarr } == Models::Author -> count(), 'every author has a book' );

	foreach my $ds ( @{ $dsarr } )
	{
		isa_ok( $ds -> author(), 'Models::Author', 'valid author object: ' . $ds -> author() -> his_name() );
		ok( $ds -> max(), 'value is there (max price): ' . $ds -> max() );
		
	}

	

}


$dbh -> disconnect();
done_testing();
exit( 0 );
