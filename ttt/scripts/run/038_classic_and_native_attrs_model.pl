#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

package main;

use TestDB ();
use Test::More;

ORM::Db -> init( my $dbh = &TestDB::dbconnect() );

use Models::AuthorHFSubFromGenericID ();

my $new_author = Models::AuthorHFSubFromGenericID -> create( his_name => 'True Talent' );

ok( $new_author -> id(), '"id" is classic style attr and still read back ok: ' . $new_author -> id() );

ok( 1, "didnt crash" );

done_testing();
exit( 0 );
