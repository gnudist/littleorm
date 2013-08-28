#!/usr/bin/perl

use strict;

package Models::AuthorInfo;
use Moose;
extends 'ORM::GenericID';

use DTRoutines ();

sub _db_table { 'author_more_info' }

has 'author' => ( is => 'rw',
		  isa => 'Models::Author',
		  metaclass => 'ORM::Meta::Attribute',
		  description => { foreign_key => 'Models::Author' } );

has 'married' => ( is => 'rw',
		   isa => 'Bool' );



has 'dead' => ( is => 'rw',
		isa => 'Maybe[DateTime]',
		metaclass => 'ORM::Meta::Attribute',
		description => { coerce_from => sub { my $rv = undef;
						      if( my $t = $_[ 0 ] )
						      {
							      $rv = &DTRoutines::ts2dt( $t );
						      }
						      return $rv; },

				 coerce_to => sub { my $rv = undef;
						    if( my $t = $_[ 0 ] )
						    {
							    $rv = &DTRoutines::dt2ts( $t );
						    }
						    return $rv; } } );



# TODO

42;
