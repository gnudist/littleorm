#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

use TestDB ();
use Test::More;
use Data::Dumper 'Dumper';

ORM::Db -> init( my $dbh = &TestDB::dbconnect() );

use Models::Sales ();
use Models::Author ();
use Models::AuthorInfo ();
use Models::Book ();
use Models::Publications ();

use ORM::Filter ();
use ORM::Clause ();
use ORM::DataSet ();

my $af = Models::Author -> f();
my $aif = Models::AuthorInfo -> f();
my $bf = Models::Book -> f();
my $sf = Models::Sales -> f();

$bf -> connect_filter_left_join( $sf );
$af -> connect_filter( $bf );
$af -> connect_filter_left_join( $aif );

if( 1 )
{
	my @all = $af -> get_many( _distinct => 1 );

# SELECT  T1.id,T1.aname FROM author T1 JOIN author_more_info T2 ON ( T1.id=T2.author ) ,book T3 JOIN sale_log T4 ON ( T3.id=T4.book )  WHERE  ( 1=1 )  AND  ( 1=1 )  AND  ( 1=1 )  AND  ( T1.id=T3.author )  AND  ( 1=1 )

#print Dumper( \@all );

	map { isa_ok( $_, 'Models::Author', 'author' ) } @all;

	is( scalar @all, Models::Author -> count(), 'count match' );
}

if( 1 )
{
	my $author_f = Models::Book -> borrow_field( 'author', _distinct => 1 );
	isa_ok( $author_f, 'ORM::Model::Field', 'borrowed a field' );

	my $married_f = Models::AuthorInfo -> borrow_field( 'married' );
	isa_ok( $married_f, 'ORM::Model::Field', 'borrowed a field' );

	my @all_fieldset = $af -> get_many( _fieldset => [ $author_f, $married_f ], _distinct => 1 );

# print @all_fieldset, "\n"; die;

# SELECT  T3.author AS _f1,T2.married AS _f2 FROM author T1 LEFT JOIN author_more_info T2 ON ( T1.id=T2.author ) ,book T3 LEFT JOIN sale_log T4 ON ( T3.id=T4.book )  WHERE  ( 1=1 )  AND  ( 1=1 )  AND  ( 1=1 )  AND  ( T1.id=T3.author )  AND  ( 1=1 )

	my $found_married = 0;

	foreach my $ds ( @all_fieldset )
	{
		isa_ok( $ds, 'ORM::DataSet', 'its ds' );
		if( $ds -> field( $married_f ) )
		{
			$found_married = 1;
		}
	}
	ok( $found_married, 'someone is married' );

}



$dbh -> disconnect();
done_testing();
exit( 0 );
