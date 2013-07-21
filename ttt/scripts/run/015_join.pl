#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

use TestDB ();
use Test::More;
use Data::Dumper 'Dumper';

ORM::Db -> init( my $dbh = &TestDB::dbconnect() );

use Models::Sales ();
use Models::Author ();
use Models::AuthorInfo ();
use Models::Book ();
use Models::Publications ();

use ORM::Filter ();
use ORM::Clause ();

my $af = Models::Author -> f();
my $aif = Models::AuthorInfo -> f();
my $bf = Models::Book -> f();
my $sf = Models::Sales -> f();

$bf -> connect_filter_complex();
$bf -> connect_filter_complex( $sf );

$af -> connect_filter_complex( $bf );
$af -> connect_filter_complex( $aif );

print "JOINED: " . Dumper( $af -> joined_tables() );


my @all1 = $af -> all_tables_used_in_filter_with_joins_sql();


#print Dumper( \@all1 );

my @all = $af -> get_many( _debug => 1 );

print @all, "\n";
ok( 1, 'test wip' );

$dbh -> disconnect();
done_testing();
exit( 0 );
