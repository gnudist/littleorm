#!/usr/bin/perl

use strict;

package Models::AuthorInfo;
use Moose;
extends 'ORM::GenericID';

sub _db_table { 'author_more_info' }

has 'author' => ( is => 'rw',
		  isa => 'Models::Author',
		  metaclass => 'ORM::Meta::Attribute',
		  description => { foreign_key => 'Models::Author' } );

has 'married' => ( is => 'rw',
		   isa => 'Bool' );

# TODO

42;
