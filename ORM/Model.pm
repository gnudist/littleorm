use ORM::Db;

package ORM::Model;

use Moose;

has '_rec' => ( is => 'rw', isa => 'HashRef' );

use Carp::Assert;

sub BUILD
{
	my $self = shift;

	assert( $self -> _rec(), 'rec must be set' );

FXOINoqUOvIG1kAG:
	foreach my $attr ( $self -> meta() -> get_all_attributes() )
	{
		my $aname = $attr -> name();

		if( $aname =~ /^_/ )
		{
			# internal attrs start with underscore, skip them
			next FXOINoqUOvIG1kAG;

		}

		my $rec_field_name = &get_db_field_name( $attr );
		my $coerce_from = &descr_attr( $attr, 'coerce_from' );
		my $foreign_key = &descr_attr( $attr, 'foreign_key' );

		$self -> meta() -> add_attribute( $aname, ( is => 'rw',
							    isa => $attr -> { 'isa' },
							    lazy => 1,
							    metaclass => 'MooseX::MetaDescription::Meta::Attribute',
							    description => ( &descr_or_undef( $attr ) or {} ),
							    default => sub {
								    
								    my $t = $self -> _rec() -> { $rec_field_name };

								    if( defined $coerce_from )
								    {
									    $t = $coerce_from -> ( $t );

								    } elsif( $foreign_key )
								    {
									    &load_module( $foreign_key );

									    my $his_pk = $foreign_key -> find_primary_key();

									    $t = $foreign_key -> get( $his_pk -> name() => $t );

								    }

								    return $t;




								    
							    } ) );
		
	}
	
}

sub load_module
{
	my $mn = shift;

	$mn =~ s/::/\//g;
	$mn .= '.pm';

	require( $mn );

}

sub get
{
	my $self = shift;

	my %args = @_;

	my @where_args = $self -> form_where( %args );

	my $sql = sprintf( "SELECT * FROM %s WHERE %s LIMIT 1", $self -> _db_table(), join( ' AND ', @where_args ) );

	my $rec = &ORM::Db::getrow( $sql );

	return $self -> new( _rec => $rec );
}

sub get_many
{
	my $self = shift;

	my %args = @_;

	my @outcome = ();

	my @where_args = $self -> form_where( %args );

	my $sql = sprintf( "SELECT * FROM %s WHERE %s", $self -> _db_table(), join( ' AND ', @where_args ) );

	my $sth = &ORM::Db::prep( $sql );
	$sth -> execute();

	while( my $data = $sth -> fetchrow_hashref() )
	{
		my $o = $self -> new( _rec => $data );
		push @outcome, $o;
	}

	return @outcome;

}

sub form_where
{
	my $self = shift;

	my %args = @_;

	my @where_args = ( '1=1' );
	foreach my $attr ( keys %args )
	{

		my $col = &get_db_field_name( $self -> meta() -> get_attribute( $attr ) );

		my $val = $args{ $attr };
		my $op = '=';

		if( ref( $val ) eq 'HASH' )
		{
			( $op, $val ) = each %{ $val };
			$val = &ORM::Db::dbq( $val );

		} elsif( ref( $val ) eq 'ARRAY' )
		{
			$op = 'IN';
			$val = sprintf( '(%s)', join( ',', map { &ORM::Db::dbq( $_ ) } @{ $val } ) );
		} else
		{
			$val = &ORM::Db::dbq( $val );
		}

		push @where_args, sprintf( '%s %s %s', $col, $op, $val );
	}

	return @where_args;

}

sub update
{
	my $self = shift;
	my $debug = shift;
	
	assert( my $pkattr = $self -> find_primary_key(), 'cant update without primary key' );

	my @upadte_pairs = ();


ETxc0WxZs0boLUm1:
	foreach my $attr ( $self -> meta() -> get_all_attributes() )
	{
		my $aname = $attr -> name();

		if( $aname =~ /^_/ )
		{
			# internal attrs start with underscore, skip them
			next ETxc0WxZs0boLUm1;
		}

		if( &descr_attr( $attr, 'ignore' ) or &descr_attr( $attr, 'primary_key' ) )
		{
			next ETxc0WxZs0boLUm1;
		}

		my $value = $self -> $aname();
		my $coerce_to = &descr_attr( $attr, 'coerce_to' );

		if( defined $coerce_to )
		{
			$value = $coerce_to -> ( $value );
		}

		if( ref( $value ) and &descr_attr( $attr, 'foreign_key' ) )
		{
			my $his_pk = $value -> find_primary_key();
			my $his_pk_name = $his_pk -> name();
			$value = $value -> $his_pk_name();
		}

		push @upadte_pairs, sprintf( '%s=%s', &get_db_field_name( $attr ), &ORM::Db::dbq( $value ) );

	}

	my $pkname = $pkattr -> name();

	my $sql = sprintf( 'UPDATE %s SET %s WHERE %s=%s',
			   $self -> _db_table(),
			   join( ',', @upadte_pairs ),
			   &get_db_field_name( $pkattr ),
			   &ORM::Db::dbq( $self -> $pkname() ) );


	if( $debug )
	{

		return $sql;

	} else
	{

		my $rc = &ORM::Db::doit( $sql );
		
		unless( $rc == 1 )
		{
			assert( 0, sprintf( "%s: %s", $sql, &ORM::Db::errstr() ) );
		}
	}
			   
}

sub find_primary_key
{
	my $self = shift;

	foreach my $attr ( $self -> meta() -> get_all_attributes() )
	{

		if( my $pk = &descr_attr( $attr, 'primary_key' ) )
		{
			return $attr;
		}

	}

}


sub descr_or_undef
{
	my $attr = shift;

	my $rv = undef;

	eval {
		$rv = $attr -> description();
	};

	return $rv;


}

sub get_db_field_name
{
	my $attr = shift;

	my $rv = $attr -> name();

	if( my $t = &descr_attr( $attr, 'db_field' ) )
	{
		$rv = $t;
	}
	
	return $rv;

}

sub descr_attr
{
	my $attr = shift;
	my $attr_attr_name = shift;

	my $rv = undef;

	if( my $d = &descr_or_undef( $attr ) )
	{
		if( my $t = $d -> { $attr_attr_name } )
		{
			$rv = $t;
		}
	}

	return $rv;

}

42;
