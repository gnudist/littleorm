#!/usr/bin/perl

use strict;

package Models::TableWithArrayCol;
use ORM;
extends 'ORM::Model';

sub _db_table { 'table_with_array_column' }

has_field 'id' => ( isa => 'Int',
		    description => { primary_key => 1,
				     db_field_type => 'int' } );

has_field 'arr_col' => ( isa => 'ArrayRef' );


42;
