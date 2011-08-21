#!/usr/bin/perl

use strict;

# Example class is described in previous examples.
use Macros;

my $dbh = DBI -> connect();

# required for ORM init:
ORM::Db -> init( $dbh );

# Getting objects count:

my $probably_2 = Macros -> count( id => [ 123, 456 ] );

my $total = Macros -> count();

my $many = Macros -> count( address => { 'LIKE', 'PATTERN%' },
			    id      => [ 123, 456 ]
			    created => { '>=', '2011-01-01' } );

# etc
