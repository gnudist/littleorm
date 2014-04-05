#!/usr/bin/perl

use strict;

package Models::DB1T2;
use ORM;
extends 'ORM::GenericID';

sub _db_table { 'db1_t2' }

use Carp::Assert 'assert';
use Data::Dumper 'Dumper';

sub countries_cf
{
	my $aref = shift;
	assert( ref( $aref ) eq 'ARRAY' );
	my @t = Models::Country -> get_many( id => $aref );

	return \@t;
}

sub countries_ct
{
	my $aref = shift;
	assert( ref( $aref ) eq 'ARRAY', 'wt: ' . Dumper( $aref ) );
	my @t = map { $_ -> id() } @{ $aref };

	return \@t;
}

has_field 'countries' => ( is => 'rw',
			   isa => 'ArrayRef[Models::Country]',
			   description => { coerce_from => \&countries_cf,
					    coerce_to => \&countries_ct } );

has_field 'description' => ( is => 'rw',
			     isa => 'Str' );



42;
