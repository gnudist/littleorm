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



{
	my $af = Models::Author -> f( id => 1 );

	my $bf = Models::Book -> f();

	$bf -> connect_filter( _clause => [],
			       $af );

	my @all = $bf -> get_many();


	my $cnt_a = Models::Author -> count();
	my $cnt_b = Models::Book -> count();

	is( scalar @all, $cnt_b, 'because tables were not actually connected (empty clause)' );

}


{
	my $aid = 1;
	my $af = Models::Author -> f( id => $aid );

	my $bf = Models::Book -> f();

	$bf -> connect_filter( $af );

	my @all = $bf -> get_many();
	my $cnt_b = Models::Book -> count( author => $aid );

	is( scalar @all, $cnt_b, 'obvious match' );

}


{

	my $aid = 1;
	my $af = Models::Author -> f( id => $aid );

	my $bf = Models::Book -> f();

	$bf -> connect_filter_left_outer_join( $af,
					       _clause => [] );
	my @all = $bf -> get_many();

	my $cnt_b = Models::Book -> count();

	is( scalar @all, $cnt_b, 'because tables were not actually connected (empty clause)' );

}


$dbh -> disconnect();
done_testing();
exit( 0 );
