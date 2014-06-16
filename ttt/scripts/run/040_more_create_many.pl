#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

package main;

use TestDB ();
use Test::More;


use Models::Metatable ();

use Data::Dumper 'Dumper';

ORM::Db -> init( my $dbh = &TestDB::dbconnect() );


my @t = ( id => 1,
	  rgroup => 2,
	  f01 => 'f01',
	  f02 => 'f02',
	  f03 => 'f03',
	  f04 => 'f04',
	  f05 => 'f05',
	  f06 => 'f06',
	  f07 => 'f07',
	  f08 => 'f08',
	  f09 => 'f09' );


my $sql = Models::Metatable -> create_many( \@t,
					    \@t,
					    \@t,
					    \@t,
					    _debug => 1 );


my $etalon_sql = "INSERT INTO metatable (f01,f02,f03,f04,f05,f06,f07,f08,f09,f10,f11,f12,f13,id,rgroup) VALUES ('f01','f02','f03','f04','f05','f06','f07','f08','f09',DEFAULT,DEFAULT,DEFAULT,DEFAULT,'1','2'),('f01','f02','f03','f04','f05','f06','f07','f08','f09',DEFAULT,DEFAULT,DEFAULT,DEFAULT,'1','2'),('f01','f02','f03','f04','f05','f06','f07','f08','f09',DEFAULT,DEFAULT,DEFAULT,DEFAULT,'1','2'),('f01','f02','f03','f04','f05','f06','f07','f08','f09',DEFAULT,DEFAULT,DEFAULT,DEFAULT,'1','2') RETURNING *";


is( $sql, $etalon_sql, "generated sql is correct" );



ok( 1, "didnt crash" );

$dbh -> disconnect();

done_testing();
exit( 0 );
