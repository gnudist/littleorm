use ORM::Model;
package Macros;

# Example for ORM-based class.

use Moose;

extends 'ORM::Model';

# Table:

sub _db_table{ 'macros' }


# Columns (note description.sequence attr):

# description.sequence is the name of the sequence from which new
# value will be taken for create() method

has 'id' => ( metaclass => 'MooseX::MetaDescription::Meta::Attribute',
	      is => 'rw',
	      isa => 'Int',
	      description => { primary_key => 1,
			       sequence => 'macros_id_seq' } );

# simplest column (although Moose will cluck on missing "is", so you better add it):

has 'body' => ( is => 'rw', isa => 'Str' );

# Now some more complex columns to demonstrate various options.


# description.foreign_key (we'll have a lazy object builder installed)

has 'host' => ( is => 'rw', 
		isa => 'Host',
		metaclass => 'MooseX::MetaDescription::Meta::Attribute',
		description => { foreign_key => 'Host' } );


# description.db_field can be used to specify alternative db column name

has 'macrosname' => ( is => 'rw',
		      isa => 'Str', 
		      metaclass => 'MooseX::MetaDescription::Meta::Attribute',
		      description => { db_field => 'name' } );

42;
