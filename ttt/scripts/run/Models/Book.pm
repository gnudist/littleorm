#!/usr/bin/perl

use strict;

package Models::Book;
use Moose;
extends 'ORM::GenericID';

sub _db_table { 'book' }

has 'title' => ( is => 'rw',
		 isa => 'Str' );

has 'author' => ( is => 'rw',
		  isa => 'Models::Author',
		  metaclass => 'ORM::Meta::Attribute',
		  description => { foreign_key => 'Models::Author' } );

42;
