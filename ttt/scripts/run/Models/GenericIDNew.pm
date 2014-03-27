use strict;

package Models::GenericIDNew;
use ORM;

extends 'ORM::GenericID';

has_field 'id' => (
	isa         => 'Int',
	is          => 'rw',
	description => {
		primary_key   => 1,
		db_field_type => 'int'
	}
);

no ORM;

-1;

