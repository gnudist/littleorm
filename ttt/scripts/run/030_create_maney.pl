#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

package main;

use TestDB ();
use Test::More;

use Models::Author ();
use Models::Book ();

use Data::Dumper 'Dumper';

ORM::Db -> init( my $dbh = &TestDB::dbconnect() );

my @to_create = ( [ his_name => 'Author1' ],
		  [ his_name => 'Author2' ] );

my @recs = Models::Author -> create_many( @to_create );

is( scalar @recs, scalar @to_create, 'all recs created' );

ok( 1, "didnt crash" );

$dbh -> disconnect();

done_testing();
exit( 0 );
