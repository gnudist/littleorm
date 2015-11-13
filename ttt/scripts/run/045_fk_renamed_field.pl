#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

package main;

use TestDB ();
use Test::More;

use Models::Author ();
use Models::BookRenamedField ();

use ORM::Filter ();
use ORM::Clause ();


ORM::Db -> init( my $dbh = &TestDB::dbconnect() );



my $f = Models::Author -> f( Models::BookRenamedField -> f() );

print $f -> get_many( _debug => 1 ); 




ok( 1, "didnt crash" );

$dbh -> disconnect();

done_testing();
exit( 0 );
