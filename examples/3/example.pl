#!/usr/bin/perl

use strict;

# Example class is described in previous examples.
use Macros;

my $dbh = DBI -> connect();

# required for ORM init:
ORM::Db -> init( $dbh );

# Examples on getting multiple objects:

# 1. This will be transformed into WHERE id IN ( 123, 456 )

my @two_macros = Macros -> get_many( id => [ 123, 456 ] );


# 2. Passing hashref actually allows you to use an SQL operator:

my @macros_with_id_more_than_1000 = Macros -> get_many( id => { '>=', 1000 } );


# 3. Can combine:

my @many = Macros -> get_many( address => { 'LIKE', 'PATTERN%' },
			       id      => [ 123, 456 ]
			       created => { '>=', '2011-01-01' } ); # but this is string yet


# 4. Can sort (SQL ORDER BY) by field (default is ASC ?):

@many = Macros -> get_many( address => { 'LIKE', 'PATTERN%' },
			    id => { '>=', 1000 },
			    _sortby => 'created' );



# 5. Add LIMIT, OFFSET, and ORDER BY if needed:

@many = ExampleORMClass -> get_many( address => { 'LIKE', 'PATTERN%' },
				     id      => { '>=', 1000 },

				     _sortby => { id      => 'ASC',
						  created => 'DESC' },

				     _limit => 100,
				     _offset => 200 );

