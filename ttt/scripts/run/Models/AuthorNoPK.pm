#!/usr/bin/perl

use strict;

package Models::AuthorNoPK;
use Moose;
extends 'ORM::Model';

sub _db_table { 'author' }

has 'id' => ( is => 'rw',
	      isa => 'Int' );

has 'his_name' => ( is => 'rw',
		    isa => 'Str',
		    metaclass => 'ORM::Meta::Attribute',
		    description => { db_field => 'aname' } );

42;
