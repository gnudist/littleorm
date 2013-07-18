#!/usr/bin/perl

use strict;

package Models::Publications;
use Moose;
extends 'ORM::GenericID';

sub _db_table { 'publication' }

use DTRoutines ();


has 'publisher' => ( is => 'rw',
		     isa => 'Models::Publisher',
		     metaclass => 'ORM::Meta::Attribute',
		     description => { foreign_key => 'Models::Publisher' } );


has 'created' => ( is => 'rw',
		   isa => 'DateTime',
		   metaclass => 'ORM::Meta::Attribute',
		   description => { coerce_from => \&DTRoutines::ts2dt,
				    coerce_to => \&DTRoutines::dt2ts } );

has 'book' => ( is => 'rw',
		isa => 'Models::Book',
		metaclass => 'ORM::Meta::Attribute',
		description => { foreign_key => 'Models::Book' } );


has 'published' => ( is => 'rw',
		     isa => 'Bool' );

42;
