#!/usr/bin/perl

use strict;

package Models::AuthorHFSubFromGenericID;
use ORM;
extends 'ORM::GenericID';

sub _db_table { 'author' }

has_field 'his_name' => ( isa => 'Str',
			  description => { db_field => 'aname' } );

42;
