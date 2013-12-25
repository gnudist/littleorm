#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

package main;

use TestDB ();
use TestDB1 ();

use Test::More;

use Models::DB1T1 ();
use Models::Country ();
use Models::Book ();
use Models::Author ();

use Data::Dumper 'Dumper';

my $dbh = &TestDB::dbconnect();
my $dbh1 = &TestDB1::dbconnect();

{
	ORM::Db -> init( $dbh );

	my $any_book = Models::Book -> get();

	my $book_class_read_dbh = Models::Book -> get_class_dbh( 'read' );
	my $book_class_write_dbh = Models::Book -> get_class_dbh( 'write' );

	ok( !$book_class_read_dbh, '(read) its not set!' );
	ok( !$book_class_write_dbh, '(write) its not set!' );

}


{
	ORM::Db -> init( { read => $dbh,
			   write => $dbh1 } );

	my $any_book = Models::Book -> get();

	eval {

		my $old_title = $any_book -> title();
		$any_book -> title( 'ZZZ' );
		$any_book -> update(); 
	};

	my $err = $@;
	
	ok( $err, 'error IS happened, write DBH used' );

}

{
	ORM::Db -> init( { read => $dbh,
			   write => $dbh } );

	my $any_book = Models::Book -> get();

	eval {

		my $old_title = $any_book -> title();
		$any_book -> title( 'ZZZ' );
		$any_book -> update(); 
	};

	my $err = $@;
	
	ok( !$err, 'error IS NOT happened, same DBH used' );

}


{
	ORM::Db -> init( { read => [ $dbh ],
			   write => [ $dbh1 ] } );

	my $any_book = Models::Book -> get();

	eval {

		my $old_title = $any_book -> title();
		$any_book -> title( 'ZZZ' );
		$any_book -> update(); 
	};

	my $err = $@;
	
	ok( $err, '(arrayref dbh init) error IS happened, write DBH used' );

}

{
	ORM::Db -> init( { read => [ $dbh ],
			   write => [ $dbh ] } );

	my $any_book = Models::Book -> get();

	eval {

		my $old_title = $any_book -> title();
		$any_book -> title( 'ZZZ' );
		$any_book -> update(); 
	};

	my $err = $@;
	
	ok( !$err, '(arrayref dbh init ok) error IS NOT happened, write DBH used' );

}



ok( 1, "didnt crash" );

$dbh -> disconnect();
$dbh1 -> disconnect();

done_testing();
exit( 0 );
