#!/usr/bin/perl

use strict;

package Models::AuthorHF;
use ORM;
extends 'ORM::Model';

sub _db_table { 'author' }

has_field 'id' => ( isa => 'Int',
		    is => 'rw',
		    description => { primary_key => 1,
				     db_field_type => 'int' } );

has_field 'his_name' => ( is => 'rw',
			  isa => 'Str',
			  description => { db_field => 'aname' } );

42;
