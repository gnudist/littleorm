#!/usr/bin/perl

use strict;

# Example class is described in previous examples.
use Macros;

my $dbh = DBI -> connect();

# required for ORM init:
ORM::Db -> init( $dbh );


# To create a new object (and record in DB):

my $new_rec = Macros -> create( id => 123,
				macrosname => 'NEW_ONE',
				body => 'New macros contents.' );


# If "id" column has description.sequence in class description, we can omit it:


my $new_rec = Macros -> create( macrosname => 'NEW_ONE',
				body => 'New macros contents.' );

print $new_rec -> id();


