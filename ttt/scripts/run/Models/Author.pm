#!/usr/bin/perl

use strict;

package Models::Author;
use Moose;
extends 'ORM::GenericID';

has his_name => ( is => 'rw',
		  isa => 'Str',
		  metaclass => 'ORM::Meta::Attribute',
		  description => { db_field => 'aname' } );

42;
