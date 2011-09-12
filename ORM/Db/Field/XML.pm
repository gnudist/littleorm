package ORM::Db::Field::XML;

use Moose;

extends 'ORM::Db::Field::Default';

sub appropriate_op
{
	my ( $self, $op ) = @_;


	return undef;
}

42;
