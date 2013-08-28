package ORM::Db::Field::Default;

use Moose;

sub appropriate_op
{
	my ( $self, $op, $val ) = @_;

	if( ( $op eq '=' ) and ( ( not defined $val ) or ( $val eq 'NULL' ) ) )
	{
		$op = 'IS';
	}

	return $op;
}

42;
