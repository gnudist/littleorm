#!/usr/bin/perl

use strict;

package Models::BookHF;
use ORM;
extends 'ORM::Model';

sub _db_table { 'book' }

has_field 'id' => ( isa => 'Int',
		    is => 'rw',
		    description => { primary_key => 1,
				     db_field_type => 'int' } );

has_field 'title' => ( is => 'rw',
		       isa => 'Str' );

has_field 'author' => ( is => 'rw',
			isa => 'Models::AuthorHF',
			description => { foreign_key => 'Models::AuthorHF' } );

42;
