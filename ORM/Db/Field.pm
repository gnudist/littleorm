
use ORM::Db::Field::Default;
use ORM::Db::Field::XML;

package ORM::Db::Field;

sub by_type
{
	my ( $self, $type ) = @_;

	$type = lc( $type );

	my $rv = undef;

	if( $type eq 'xml' )
	{
		$rv = ORM::Db::Field::XML -> new();
	} else
	{
		$rv = ORM::Db::Field::Default -> new();
	}

	return $rv;
}

42;
