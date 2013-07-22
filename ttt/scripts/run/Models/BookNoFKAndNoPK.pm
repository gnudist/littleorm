#!/usr/bin/perl

use strict;

package Models::BookNoFKAndNoPK;
use Moose;
extends 'ORM::Model';

sub _db_table { 'book' }

has 'id' => ( is => 'rw',
	      isa => 'Int' );

has 'title' => ( is => 'rw',
		 isa => 'Str' );

has 'author' => ( is => 'rw',
		  isa => 'Int' );

has 'price' => ( is => 'rw', isa => 'Str' );

42;
