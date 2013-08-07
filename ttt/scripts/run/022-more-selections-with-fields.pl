#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

use TestDB ();
use Test::More;

ORM::Db -> init( my $dbh = &TestDB::dbconnect() );

use Models::Author ();
use Models::Book ();

use ORM::Filter ();
use ORM::Clause ();
use ORM::DataSet ();
use Models::Publications ();
use Models::Publisher ();
use ORM::Model::Field ();


ok( my $cnt = Models::Publications -> count(), 'there are some publications' );

my $now = ORM::Model::Field -> new( db_func => 'now' );

ok( my $previous_publications = Models::Publications -> count( created => { '<', $now } ), 'counted some previous publications' );



{
	my $pf1 = Models::Publisher -> f();
	my $pf2 = Models::Publisher -> f();

	my $field1 = $pf1 -> borrow_field( 'parent' );
	my $field2 = $pf2 -> borrow_field( 'parent' );

	$pf1 -> connect_filter( $pf2 );
	
	my @ds = $pf1 -> get_many( _fieldset => [ $field1, $field2 ] );

# SELECT  T1.parent AS _f2,T2.parent AS _f3 FROM publisher T1,publisher T2 WHERE  ( 1=1 )  AND  ( 1=1 )  AND  ( T1.parent=T2.id ) 

	ok( scalar @ds, 'selected some records' );
	foreach my $ds ( @ds )
	{
		isa_ok( $ds, 'ORM::DataSet', 'this is dataset' );

		my $p1 = $ds -> field( $field1 );
		my $p2 = $ds -> field( $field2 );

		ok( ( $p1 or $p2 ), "at least one level parent must be there" );
		
		my ( $p1id, $p2id ) = ( 0, 0 );
		if( $p1 )
		{
			isa_ok( $p1, 'Models::Publisher', 'this is publisher' );
			$p1id = $p1 -> id();
		}

		if( $p2 )
		{
			isa_ok( $p2, 'Models::Publisher', 'this is publisher' );
			$p2id = $p2 -> id();
		}
		isnt( $p1id, $p2id, "they cant be same" );
	}

}



$dbh -> disconnect();
done_testing();
exit( 0 );
