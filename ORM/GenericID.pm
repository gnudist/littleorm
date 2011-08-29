
use ORM::Model;

package ORM::GenericID;

# Generic PK ID column for inheritance.

use Moose;

extends 'ORM::Model';

sub _db_table{ 'CHANGEME' }

has 'id' => ( metaclass => 'MooseX::MetaDescription::Meta::Attribute',
	      is => 'rw',
	      isa => 'Int',
	      description => { primary_key => 1 } );

42;
