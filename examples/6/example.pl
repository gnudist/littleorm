#!/usr/bin/perl

use strict;

use ORM::Model;


# ORM class

package Macros;
use Moose;

sub _db_table{ 'macros' }

extends "ORM::GenericID";

has 'name' => ( is => 'rw', isa => 'Str' );

__PACKAGE__ -> meta_change_attr( 'id', sequence => 'macros_id_seq' );

no Moose;

# /ORM class


package main;

# ...

ORM::Db -> init( $dbh );

my $m = Macros -> create( name => 'NEW_NAME' ); # will query sequence

# ...
