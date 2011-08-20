use ORM::Model;
package Host;

# Example for ORM-based class. It is referred from Macros.pm nearby with foreign constraint.

use Moose;

extends 'ORM::Model';

# Table:

sub _db_table{ 'host' }


# Columns:

has 'foo' => ( metaclass => 'MooseX::MetaDescription::Meta::Attribute',
	       is => 'rw',
	       isa => 'Int',
	       description => { db_field => 'id',
				primary_key => 1 } );


has 'name' => ( is => 'rw',
		isa => 'Str',
		metaclass => 'MooseX::MetaDescription::Meta::Attribute',
		description => { db_field => 'host' } );


42;
