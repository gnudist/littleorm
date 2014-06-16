#!/usr/bin/perl

use strict;

# in memory of ...
# you will always be in our hearts

package Models::Metatable;
use ORM;
extends 'ORM::GenericID';

sub _db_table { 'metatable' }

has_field 'rgroup' => ( isa => 'Int' );

has_field 'f01' => ( isa => 'Maybe[Str]' );
has_field 'f02' => ( isa => 'Maybe[Str]' );
has_field 'f03' => ( isa => 'Maybe[Str]' );
has_field 'f04' => ( isa => 'Maybe[Str]' );
has_field 'f05' => ( isa => 'Maybe[Str]' );
has_field 'f06' => ( isa => 'Maybe[Str]' );
has_field 'f07' => ( isa => 'Maybe[Str]' );
has_field 'f08' => ( isa => 'Maybe[Str]' );
has_field 'f09' => ( isa => 'Maybe[Str]' );
has_field 'f10' => ( isa => 'Maybe[Str]' );
has_field 'f11' => ( isa => 'Maybe[Str]' );
has_field 'f12' => ( isa => 'Maybe[Str]' );
has_field 'f13' => ( isa => 'Maybe[Str]' );


42;
