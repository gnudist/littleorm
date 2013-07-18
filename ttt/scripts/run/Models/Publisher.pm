#!/usr/bin/perl

use strict;

package Models::Publisher;
use Moose;
extends 'ORM::GenericID';

sub _db_table { 'publisher' }

has 'orgname' => ( is => 'rw',
		   isa => 'Str' );

42;
