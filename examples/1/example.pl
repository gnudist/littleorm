#!/usr/bin/perl

use strict;

# Example class is described in Macros.pm nearby
use Macros;

my $dbh = DBI -> connect();

# required for ORM init:
ORM::Db -> init( $dbh );


my $m = Macros -> get( id => 123 );

# can work with attrs now:
print "name: ", $m -> macrosname(), "\n";
print "lc_name: ", $m -> lc_macrosname(), "\n";
print "splitaddr: ", join( ' ', @{ $m -> splitaddr() } ), "\n";

$m -> update();

# hey! you forgot to disconnect!


