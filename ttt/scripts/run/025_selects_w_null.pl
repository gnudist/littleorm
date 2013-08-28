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
use Models::AuthorInfo ();
use ORM::Model::Field ();
use Models::BookNoFK ();

{
	my @t = Models::AuthorInfo -> get_many( dead => undef );
	ok( scalar @t, 'some are not dead' ); 
}

# TODO

$dbh -> disconnect();
done_testing();
exit( 0 );
