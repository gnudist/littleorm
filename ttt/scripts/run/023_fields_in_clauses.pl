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
	my $idf = Models::Publisher -> borrow_field( 'id' );
	my $pf = Models::Publisher -> borrow_field( 'parent' );

	my $sd1 = Models::Publisher -> f( _clause => [ cond => [ $idf => { '=', $pf },
								 $idf => $pf,
								 $idf => [ $pf ],
								 id => 20 ],
						       logic => 'OR' ] );

	my @anything = $sd1 -> get_many();
# SELECT  T1.id,T1.parent,T1.orgname FROM publisher T1 WHERE  ( 1=1 AND  ( T1.id = T1.parent OR T1.id = T1.parent OR T1.id IN (T1.parent) OR T1.id = '20' )  ) 

	ok( 1, 'didnt crash' );
}


$dbh -> disconnect();
done_testing();
exit( 0 );
