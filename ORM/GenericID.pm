
use ORM::Model;

package ORM::GenericID;

# Generic PK ID column for inheritance.

use Moose;

extends 'ORM::Model';

has 'id' => ( metaclass => 'ORM::Meta::Attribute',
	      isa => 'Int',
	      is => 'rw',
	      description => { primary_key => 1 } );


42;
