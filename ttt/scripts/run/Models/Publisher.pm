#!/usr/bin/perl

use strict;

package Models::Publisher;
use Moose;
extends 'ORM::GenericID';

sub _db_table { 'publisher' }

has 'orgname' => ( is => 'rw',
		   isa => 'Str' );

has 'parent' => ( is => 'rw',
		  isa => 'Maybe[Models::Publisher]',
		  metaclass => 'ORM::Meta::Attribute',
		  description => { foreign_key => 'Models::Publisher' } );

42;
