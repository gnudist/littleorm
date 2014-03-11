#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

package main;

use TestDB ();
use Test::More;

ORM::Db -> init( my $dbh = &TestDB::dbconnect() );

use Models::Author ();
use Models::Book ();
use ORM::Clause ();
use Data::Dumper 'Dumper';

use ORM::DataSet ();

my $cnt = Models::Book -> count();
ok( $cnt > 0, 'we have some books indeed: ' . $cnt );

my $a_cnt = Models::Author -> count();
ok( $a_cnt > 0, 'we have some authors indeed: ' . $a_cnt );


my @distinct_books = Models::Book -> get_many( _distinct => 'yes' );
is( scalar @distinct_books, $cnt, 'books count matches to distinct books number' );


my @distinct_authors = Models::Book -> get_many( _distinct => 'yes',
						 _fieldset => [ 'author' ] );

ok( scalar @distinct_authors <= $a_cnt, "maybe not all authors have books" );


ok( 1, "didnt crash" );

done_testing();
exit( 0 );
