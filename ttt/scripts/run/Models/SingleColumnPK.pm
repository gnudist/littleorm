#!/usr/bin/perl

use strict;

package Models::SingleColumnPK;
use ORM;
extends 'ORM::Model';

sub _db_table { 'single_column_pk' }

has_field 'id' => ( isa => 'Int',
		    is => 'rw',
		    description => { primary_key => 1,
				     db_field_type => 'int' } );

42;
