#!/usr/bin/perl

use strict;

package Models::DB1T1;
use Moose;
extends 'ORM::GenericID';

sub _db_table { 'db1_t1' }


has 'country' => ( is => 'rw',
		   isa => 'Models::Country',
		   metaclass => 'ORM::Meta::Attribute',
		   description => { foreign_key => 'Models::Country',
				    db_field_type => 'int' } );

has 'data' => ( is => 'rw',
		isa => 'Str' );



42;
