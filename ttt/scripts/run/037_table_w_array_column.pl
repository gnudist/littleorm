#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

package main;

use TestDB ();
use Test::More;

ORM::Db -> init( my $dbh = &TestDB::dbconnect() );

use Models::TableWithArrayCol ();

my @t = ( 1 .. 10 );

my $new_rec = Models::TableWithArrayCol -> create( arr_col => \@t,
						   not_null_no_default_col => 0,
						   created => ORM::Model::Field -> new( db_func => 'now' ),
						   hr_col => { one => 1,
							       two => 2 } );

ok( $new_rec -> id(), "insert success" );

ok( my $same_rec = Models::TableWithArrayCol -> get( id => $new_rec -> id() ) );

is( $same_rec -> hr_col() -> { 'one' }, 1, 'value saved and read back ok' );
ok( $same_rec -> created(), 'created: ' . $same_rec -> created() );

ok( 1, "didnt crash" );

done_testing();
exit( 0 );
