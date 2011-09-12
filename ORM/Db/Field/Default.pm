package ORM::Db::Field::Default;

use Moose;

sub appropriate_op
{
	my ( $self, $op ) = @_;

	return $op;
}

42;
