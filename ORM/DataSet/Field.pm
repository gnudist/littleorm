#!/usr/bin/perl

use strict;

package ORM::DataSet::Field;
use Moose;

has 'model' => ( is => 'rw', isa => 'Str' );
has 'dbfield' => ( is => 'rw', isa => 'Str' );
has 'value' => ( is => 'rw' );

4243;
