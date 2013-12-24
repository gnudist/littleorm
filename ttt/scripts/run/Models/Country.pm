#!/usr/bin/perl

use strict;

package Models::Country;
use Moose;
extends 'ORM::GenericID';

sub _db_table { 'country' }

has 'cname' => ( is => 'rw',
		 isa => 'Str' );



42;
