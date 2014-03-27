#!/usr/bin/perl

use strict;

package Models::AuthorHFSubFromGenericID_Im;
use ORM;
extends 'Models::GenericIDNew';

sub _db_table { 'author' }

has_field 'his_name' => ( isa => 'Str',
			  description => { db_field => 'aname' } );


__PACKAGE__ -> meta() -> make_immutable();

42;
