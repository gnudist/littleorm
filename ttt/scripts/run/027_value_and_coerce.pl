#!/usr/bin/perl

use strict;
use lib ( "./", "../../../" );

use Moose::Util::TypeConstraints;
use XML::Validate ();

subtype 'XML',
        as 'Str',
	where { XML::Validate -> new( Type => 'LibXML' ) -> validate( $_ ) };

coerce 'XML',
        from 'Str',
        via { return "Moose coerce called"; };

no Moose::Util::TypeConstraints;



package test38::Model;
use ORM;
extends 'ORM::Model';

sub _db_table { 'example_table' }

has_field 'attrs' => ( isa => 'XML',
		       description => { coerce_to   => sub{ return "ORM coerce_to called"; },
					coerce_from => sub{ return "ORM coerce_from called"; } },
		       coerce => 1 );

no ORM;


################################################################################

package main;

use TestDB ();
use Test::More;

use ORM::Model::Field ();
use ORM::Model::Value ();
use ORM::Model ();
use ORM::Clause ();
use ORM::Filter ();

ORM::Db -> init( my $dbh = &TestDB::dbconnect() );


{
	my $sql = test38::Model -> get( test38::Model -> borrow_field( 'attrs',
								       db_func => 'xml_attr',
								       db_func_tpl => q|%s( %s, 'attrs.smth' )| )
					=>
					ORM::Model::Value -> new( value => 100500,
								  orm_coerce => 0 ),
					_debug => 1 );
	
	
	is( $sql,
	    "SELECT  example_table.attrs FROM example_table WHERE xml_attr( example_table.attrs, 'attrs.smth' ) = '100500' LIMIT 1 ",
	    "hardcoded sql gen result ok" );
	

}


{
	my $sql = test38::Model -> get( test38::Model -> borrow_field( 'attrs',
								       db_func => 'xml_attr',
								       db_func_tpl => q|%s( %s, 'attrs.smth' )| )
					=>
					ORM::Model::Value -> new( value => 100500,
								  orm_coerce => 1 ),
					_debug => 1 );
	
	
	is( $sql,
	    "SELECT  example_table.attrs FROM example_table WHERE xml_attr( example_table.attrs, 'attrs.smth' ) = 'ORM coerce_to called' LIMIT 1 ",
	    "hardcoded sql gen result ok" );
	

}

ok( 1, "didnt crash" );

$dbh -> disconnect();

done_testing();
exit( 0 );
