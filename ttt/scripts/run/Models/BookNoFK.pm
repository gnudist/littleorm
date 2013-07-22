#!/usr/bin/perl

use strict;

package Models::BookNoFK;
use Moose;
extends 'ORM::GenericID';

sub _db_table { 'book' }

has 'title' => ( is => 'rw',
		 isa => 'Str' );

has 'author' => ( is => 'rw',
		  isa => 'Int' );

has 'price' => ( is => 'rw', isa => 'Str' );

42;
