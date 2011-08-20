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

# we have foreign constraint Host class now:

print $m -> host() -> name(), "\n";

my $sql = $m -> update( 'DEBUG: If you pass true here youll get SQL and no update will be made.' );



# hey! you forgot to disconnect! again?

