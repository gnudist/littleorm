#!/usr/bin/perl

use strict;

# Example class is described in previous examples.
use Macros;

my $dbh = DBI -> connect();

# required for ORM init:
ORM::Db -> init( $dbh );

# Examples on getting multiple objects:

# this will be transformed into WHERE id IN ( 123, 456 )

my @two_macros = Macros -> get_many( id => [ 123, 456 ] );


# Passing hashref actually allows you to use an SQL operator:

my @macros_with_id_more_than_1000 = Macros -> get_many( id => { '>=', 1000 } );

my @several = Macros -> get_many( address => { 'LIKE', 'PATTERN%' },
				  id => { '>=', 1000 } );


