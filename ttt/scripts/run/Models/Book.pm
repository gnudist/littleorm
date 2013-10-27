#!/usr/bin/perl

use strict;

package Models::Book;
use Moose;
extends 'ORM::GenericID';

sub _db_table { 'book' }

has 'title' => ( is => 'rw',
		 isa => 'Str',
		 metaclass => 'ORM::Meta::Attribute',
		 description => { db_field_type => 'varchar' } );

has 'author' => ( is => 'rw',
		  isa => 'Models::Author',
		  metaclass => 'ORM::Meta::Attribute',
		  description => { foreign_key => 'Models::Author',
				   db_field_type => 'int' } );

has 'price' => ( is => 'rw', isa => 'Str' );

42;
