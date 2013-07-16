#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

use TestDB ();
use Test::More;

ORM::Db -> init( my $dbh = &TestDB::dbconnect() );


use Models::Book ();
use Models::Author ();
use Models::Sales ();

use ORM::Filter ();
use ORM::Clause ();
use ORM::DataSet ();

use Data::Dumper 'Dumper';


{
	my $af = Models::Author -> f();
	my $bf = Models::Book -> f( $af );
	my $sf = Models::Sales -> f( $bf );

	my $author_field = Models::Author -> borrow_field( 'id' );

	my $count = $sf -> count( _groupby => [ $author_field ] );

# SELECT T1.id,count(*)
# FROM author T1,book T2,sale_log T3
# WHERE  ( 1=1 )  AND  ( T2.author=T1.id )  AND  ( 1=1 )  AND  ( T3.book=T2.id )  AND  ( 1=1 )  GROUP BY T1.id

# ^^ FIXED (missing AS)

	ok( scalar @{ $count }, "something is there" );
	map { isa_ok( $_, 'ORM::DataSet', 'dataset' ) } @{ $count };

	foreach my $ds ( @{ $count } )
	{
		ok( my $aid = $ds -> field( $author_field ), 'author id' );
		isa_ok( Models::Author -> get( id => $aid ), 'Models::Author', 'it exists' );
		ok( $ds -> count(), 'count has value' );
	}
}


{

# sales sum by author

	my $bf = Models::Book -> f();
	my $sf = Models::Sales -> f( $bf );

	my $author_field = Models::Book -> borrow_field( 'author' );

	my $sales_sum_field = Models::Book -> borrow_field( 'price',
							    db_func => 'sum' );

	my @recs = $sf -> get_many( _fieldset => [ $author_field, $sales_sum_field ],
				    _groupby => [ $author_field ] );

	ok( scalar @recs, 'something is there' );

	foreach my $ds ( @recs )
	{
		isa_ok( $ds, 'ORM::DataSet', 'its ds' );

		isa_ok( $ds -> field( $author_field ), 'Models::Author', 'author' );

		ok( $ds -> field( $sales_sum_field ), 'sales sum there' );

		ok( 1, sprintf( "%s has sales sum %d",
				$ds -> field( $author_field ) -> his_name(),
				$ds -> field( $sales_sum_field ) ) );

	}
}


$dbh -> disconnect();
done_testing();
exit( 0 );
