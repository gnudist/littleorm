use ORM::Db;

package ORM::Model;

use Moose;

has '_rec' => ( is => 'rw', isa => 'HashRef', required => 1 );

use Carp::Assert;

sub get
{
	my $self = shift;
	my $sql = $self -> __form_get_sql( @_, '_limit' => 1 );
	my $rec = &ORM::Db::getrow( $sql );

	my $rv = undef;

	if( $rec )
	{
		$rv = $self -> new( _rec => $rec );
	}

	return $rv;
}

sub get_or_create
{
	my $self = shift;

	my $r = $self -> get( @_ );

	unless( $r )
	{
		$r = $self -> create( @_ );
	}

	return $r;
}

sub get_many
{
	my $self = shift;

	my @outcome = ();
	my $sql = $self -> __form_get_sql( @_ );
	my $sth = &ORM::Db::prep( $sql );
	$sth -> execute();

	while( my $data = $sth -> fetchrow_hashref() )
	{
		my $o = $self -> new( _rec => $data );
		push @outcome, $o;
	}

	return @outcome;

}

sub count
{
	my $self = shift;

	my $outcome = 0;
	my $sql = $self -> __form_count_sql( @_ );

	my $r = &ORM::Db::getrow( $sql );

	$outcome = $r -> { 'count' };

	return $outcome;
}

sub create
{
	my $self = shift;
	my $sql = $self -> __form_insert_sql( @_ );

	my $rc = &ORM::Db::doit( $sql );

	if( $rc == 1 )
	{
		return $self -> get( @_ );
	}

	assert( 0, sprintf( "%s: %s", $sql, &ORM::Db::errstr() ) );
}

sub update
{
	my $self = shift;
	my $debug = shift;
	
	assert( my $pkattr = $self -> __find_primary_key(), 'cant update without primary key' );

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

		if( &__descr_attr( $attr, 'ignore' ) or &__descr_attr( $attr, 'primary_key' ) )
		{
			next ETxc0WxZs0boLUm1;
		}

		my $value = &__prep_value_for_db( $attr, $self -> $aname() );
		push @upadte_pairs, sprintf( '%s=%s', &__get_db_field_name( $attr ), &ORM::Db::dbq( $value ) );

	}

	my $pkname = $pkattr -> name();

	my $sql = sprintf( 'UPDATE %s SET %s WHERE %s=%s',
			   $self -> _db_table(),
			   join( ',', @upadte_pairs ),
			   &__get_db_field_name( $pkattr ),
			   &ORM::Db::dbq( &__prep_value_for_db( $pkattr, $self -> $pkname() ) ) );


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

sub delete
{
	my $self = shift;
	my $sql = $self -> __form_delete_sql( @_ );

	my $rc = &ORM::Db::doit( $sql );

	return $rc;
}

sub meta_change_attr
{
	my $self = shift;

	my $arg = shift;

	my %attrs = @_;

	my $arg_obj = $self -> meta() -> find_attribute_by_name( $arg );

	my $d = $arg_obj -> description();

	while( my ( $k, $v ) = each %attrs )
	{
		if( $v )
		{
			$d -> { $k } = $v;
		} else
		{
			delete $d -> { $k };
		}
	}

	$arg_obj -> description( $d );
}

################################################################################
# Internal functions below
################################################################################

sub BUILD
{
	my $self = shift;

FXOINoqUOvIG1kAG:
	foreach my $attr ( $self -> meta() -> get_all_attributes() )
	{
		my $aname = $attr -> name();

		if( $aname =~ /^_/ )
		{
			# internal attrs start with underscore, skip them
			next FXOINoqUOvIG1kAG;

		}

		if( &__descr_attr( $attr, 'ignore' ) )
		{
			$self -> meta() -> add_attribute( $attr -> clone() );

		} else
		{
			$self -> meta() -> add_attribute( $aname, ( is => 'rw',
								    isa => $attr -> { 'isa' },
								    lazy => 1,
								    metaclass => 'ORM::Meta::Attribute',
								    description => ( &__descr_or_undef( $attr ) or {} ),
								    default => sub { $_[ 0 ] -> __lazy_build_value( $attr ) } ) );
		}
	}
}

sub __lazy_build_value
{
	my $self = shift;
	my $attr = shift;

	my $rec_field_name = &__get_db_field_name( $attr );
	my $coerce_from = &__descr_attr( $attr, 'coerce_from' );
	my $foreign_key = &__descr_attr( $attr, 'foreign_key' );

	my $r = $self -> _rec();
	my $t = $self -> _rec() -> { $rec_field_name };

	if( defined $coerce_from )
	{
		$t = $coerce_from -> ( $t );
		
	} elsif( $foreign_key )
	{
		&__load_module( $foreign_key );
		
		my $his_pk = $foreign_key -> __find_primary_key();
		
		$t = $foreign_key -> get( $his_pk -> name() => $t );
		
	}
	
	return $t;
	

}

sub __load_module
{
	my $mn = shift;

	$mn =~ s/::/\//g;
	$mn .= '.pm';

	require( $mn );

}

sub __form_insert_sql
{
	my $self = shift;

	my %args = @_;

	my @fields = ();
	my @values = ();

	foreach my $attr ( $self -> meta() -> get_all_attributes() )
	{
		my $aname = $attr -> name();
		unless( $args{ $aname } )
		{
			if( my $seqname = &__descr_attr( $attr, 'sequence' ) )
			{
				my $nv = &ORM::Db::nextval( $seqname );

				$args{ $aname } = $nv;
			}
		}
	}

XmXRGqnrCTqWH52Z:
	while( my ( $arg, $val ) = each %args )
	{
		if( $arg =~ /^_/ )
		{
			next XmXRGqnrCTqWH52Z;
		}

		assert( my $attr = $self -> meta() -> find_attribute_by_name( $arg ), 
			sprintf( 'invalid attr name passed: %s', $arg ) );

		my $field_name = &__get_db_field_name( $attr );
		$val = &__prep_value_for_db( $attr, $val );
		
		push @fields, $field_name;
		push @values, $val;
	}

	my $sql = sprintf( "INSERT INTO %s (%s) VALUES (%s)",
			   $self -> _db_table(),
			   join( ',', @fields ),
			   join( ',', map { &ORM::Db::dbq( $_ ) } @values ) );

	return $sql;
}


sub __prep_value_for_db
{
	my ( $attr, $value ) = @_;

	my $rv = $value;

	my $coerce_to = &__descr_attr( $attr, 'coerce_to' );

	if( defined $coerce_to )
	{
		$rv = $coerce_to -> ( $value );
	}

	if( ref( $value ) and &__descr_attr( $attr, 'foreign_key' ) )
	{
		my $his_pk = $value -> __find_primary_key();
		my $his_pk_name = $his_pk -> name();
		$rv = $value -> $his_pk_name();
	}

	return $rv;

}

sub __form_delete_sql
{
	my $self = shift;

	my %args = @_;

	if( ref( $self ) )
	{
		foreach my $attr ( $self -> meta() -> get_all_attributes() )
		{
			my $aname = $attr -> name();
			$args{ $aname } = $self -> $aname();
		}
	}

	my @where_args = $self -> __form_where( %args );

	my $sql = sprintf( "DELETE FROM %s WHERE %s", $self -> _db_table(), join( ' AND ', @where_args ) );

	return $sql;
}

sub __form_get_sql
{
	my $self = shift;

	my %args = @_;

	my @where_args = $self -> __form_where( %args );

	my $sql = sprintf( "SELECT * FROM %s WHERE %s", $self -> _db_table(), join( ' AND ', @where_args ) );

	$sql .= $self -> __form_additional_sql( %args );

	return $sql;

}

sub __form_count_sql
{
	my $self = shift;

	my %args = @_;

	my @where_args = $self -> __form_where( %args );

	my $sql = sprintf( "SELECT count(1) FROM %s WHERE %s", $self -> _db_table(), join( ' AND ', @where_args ) );

	return $sql;
}

sub __form_additional_sql
{
	my $self = shift;

	my %args = @_;
	my $sql = '';

	if( my $t = $args{ '_sortby' } )
	{
		if( ref( $t ) eq 'HASH' )
		{
			# then its like
			# { field1 => 'DESC',
			#   field2 => 'ASC' ... }

			my @pairs = ();

			while( my ( $k, $sort_order ) = each %{ $t } )
			{
				my $dbf = &__get_db_field_name( $self -> meta() -> find_attribute_by_name( $k ) );
				push @pairs, sprintf( '%s %s', $dbf, $sort_order );
			}
			$sql .= ' ORDER BY ' . join( ',', @pairs );
		} else
		{
			# then its attr name and unspecified order
			my $dbf = &__get_db_field_name( $self -> meta() -> find_attribute_by_name( $t ) );
			$sql .= ' ORDER BY ' . $dbf;
		}
	}

	if( my $t = int( $args{ '_limit' } or 0 ) )
	{
		$sql .= sprintf( ' LIMIT %d ', $t );
	}

	if( my $t = int( $args{ '_offset' } or 0 ) )
	{
		$sql .= sprintf( ' OFFSET %d ', $t );
	}

	return $sql;
}

sub __form_where
{
	my $self = shift;

	my %args = @_;

	my @where_args = ( '1=1' );
fhFwaEknUtY5xwNr:
	foreach my $attr ( keys %args )
	{
		my $val = $args{ $attr };

		if( $attr eq '_where' )
		{
			push @where_args, $val;

		}

		if( $attr =~ /^_/ ) # skip system agrs, they start with underscore
		{
			next fhFwaEknUtY5xwNr;
		}

		my $class_attr = $self -> meta() -> find_attribute_by_name( $attr );

		if( &__descr_attr( $class_attr, 'ignore' ) )
		{
			next fhFwaEknUtY5xwNr;
		}

		my $class_attr_isa = $class_attr -> { 'isa' };

		my $col = &__get_db_field_name( $class_attr );


		my $op = '=';

		if( ref( $val ) eq 'HASH' )
		{
			if( $class_attr_isa =~ 'HashRef' )
			{
				next fhFwaEknUtY5xwNr;
			} else
			{
				( $op, $val ) = each %{ $val };
				$val = &ORM::Db::dbq( &__prep_value_for_db( $class_attr, $val ) );
			}

		} elsif( ref( $val ) eq 'ARRAY' )
		{

			if( $class_attr_isa =~ 'ArrayRef' )
			{
				$val = &ORM::Db::dbq( &__prep_value_for_db( $class_attr, $val ) );
			} else
			{
				$op = 'IN';
				$val = sprintf( '(%s)', join( ',', map { &ORM::Db::dbq( &__prep_value_for_db( $class_attr, $_ ) ) } @{ $val } ) );
			}

		} else
		{
			$val = &ORM::Db::dbq( &__prep_value_for_db( $class_attr, $val ) );
		}

		push @where_args, sprintf( '%s %s %s', $col, $op, $val );
	}
	return @where_args;
}

sub __find_primary_key
{
	my $self = shift;

	foreach my $attr ( $self -> meta() -> get_all_attributes() )
	{

		if( my $pk = &__descr_attr( $attr, 'primary_key' ) )
		{
			return $attr;
		}
	}
}

sub __descr_or_undef
{
	my $attr = shift;

	my $rv = undef;

	eval {
		$rv = $attr -> description();
	};

	return $rv;
}

sub __get_db_field_name
{
	my $attr = shift;

	assert( $attr );

	my $rv = $attr -> name();

	if( my $t = &__descr_attr( $attr, 'db_field' ) )
	{
		$rv = $t;
	}
	
	return $rv;
}

sub __descr_attr
{
	my $attr = shift;
	my $attr_attr_name = shift;

	my $rv = undef;

	if( my $d = &__descr_or_undef( $attr ) )
	{
		if( my $t = $d -> { $attr_attr_name } )
		{
			$rv = $t;
		}
	}

	return $rv;
}

42;
