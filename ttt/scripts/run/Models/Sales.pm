#!/usr/bin/perl

use strict;

package Models::Sales;
use Moose;
extends 'ORM::GenericID';

sub _db_table { 'sale_log' }

use DTRoutines ();

has 'created' => ( is => 'rw',
		   isa => 'DateTime',
		   metaclass => 'ORM::Meta::Attribute',
		   description => { coerce_from => \&DTRoutines::ts2dt,
				    coerce_to => \&DTRoutines::dt2ts } );

has 'book' => ( is => 'rw',
		isa => 'Models::Book',
		metaclass => 'ORM::Meta::Attribute',
		description => { foreign_key => 'Models::Book' } );

42;
