use ORM::Model;
package Macros;

# Example for ORM-based class.

use Moose;

extends 'ORM::Model';

# Table:

sub _db_table{ 'macros' }


# Columns:

has 'id' => ( metaclass => 'ORM::Meta::Attribute',
	      is => 'rw',
	      isa => 'Int',
	      description => { primary_key => 1 } );

# simplest column (although Moose will cluck on missing "is", so you better add it):

has 'body' => ( isa => 'Str' );


# Now some more complex columns to demonstrate various options.

# description.db_field can be used to specify alternative db column name

has 'macrosname' => ( is => 'rw',
		      isa => 'Str', 
		      metaclass => 'ORM::Meta::Attribute',
		      description => { db_field => 'name' } );



# description.ignore means that changes to this attr will be ignored on update

has 'lc_macrosname' => ( is => 'rw', # just to absorb Moose warning
			 isa => 'Str', 
			 metaclass => 'ORM::Meta::Attribute',
			 description => { db_field => 'name',
					  coerce_from => sub { lc( $_[ 0 ] ) },
					  ignore => 1 } );



# description.coerce_from can be used to convert db value to attr value
# description.coerce_to is also required in this case (to convert attr value to db value for update)

has 'splitaddr' => ( is => 'rw',
		     isa => 'ArrayRef',
		     metaclass => 'ORM::Meta::Attribute',
		     description => { db_field => 'address',
				      coerce_from => sub { [ split( //, $_[ 0 ] ) ] },
				      coerce_to => sub { join( '', @{ $_[ 0 ] } ) } } );

42;
