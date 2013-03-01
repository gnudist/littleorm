use LittleORM::Db;
use LittleORM::Db::Field;

package LittleORM::Model;

use Moose;
use Moose::Util::TypeConstraints;

has '_rec' => ( is => 'rw', isa => 'HashRef', required => 1, metaclass => 'LittleORM::Meta::Attribute', description => { ignore => 1 } );

use Carp::Assert 'assert';
use Scalar::Util 'blessed';

sub _db_table{ assert( 0, '" _db_table " method must be redefined.' ) }

# Let it be separate method, m'kay?
sub _clear
{
	my $self = shift;

	foreach my $attr ( $self -> meta() -> get_all_attributes() )
	{
		next if &__descr_attr( $attr, 'do_not_clear_on_reload' ); # well, kinda crutch...
									  #		- Kain

		if( $attr -> has_clearer() )
		{

# http://search.cpan.org/~doy/Moose-2.0603/lib/Class/MOP/Attribute.pm
# $attr->clearer
#     The accessor, reader, writer, predicate, and clearer methods all
#     return exactly what was passed to the constructor, so it can be
#     either a string containing a method name, or a hash reference.

			# -- why does it have to be so complex?
			
			my $clearer = $attr -> clearer();

			# ok, as doc above says:
			if( ref( $clearer ) )
			{
				my $code = ${ [ values %{ $clearer } ] }[ 0 ];
				$code -> ( $self );

			} else
			{
				$self -> $clearer();
			}
			
		} else
		{
			$attr -> clear_value( $self );
		}
	}

	return 1;
}

sub reload
{
	my $self = shift;

	
	if( my @pk = $self -> __find_primary_keys() )
	{
		my %get_args = ();

		foreach my $pk ( @pk )
		{
			my $pkname = $pk -> name();
			$get_args{ $pkname } = $self -> $pkname();
		}

		$self -> _clear();

		my $sql = $self -> __form_get_sql( %get_args,
						   _limit => 1 );

		my $rec = &LittleORM::Db::getrow( $sql, $self -> __get_dbh() );

		$self -> _rec( $rec );

	} else
	{
		assert( 0, 'reload in only supported for models with PK' );
	}
}

sub clone
{
	my $self = shift;

	my $class = ref( $self );

	return $class -> new( _rec => $self -> _rec() );
}


sub get
{
	my $self = shift;

	my @args = @_;
	my %args = @args;

	my $sql = $self -> __form_get_sql( @args, _limit => 1 );

	if( $args{ '_debug' } )
	{
		return $sql;
	}

	my $rec = &LittleORM::Db::getrow( $sql, $self -> __get_dbh( @args ) );

	my $rv = undef;

	if( $rec )
	{
		$rv = $self -> new( _rec => $rec );
	}

	return $rv;
}

sub values_list
{
	my ( $self, $fields, $args ) = @_;

	# example: @values = Class -> values_list( [ 'id', 'name' ], [ something => { '>', 100 } ] );
	# will return ( [ id, name ], [ id1, name1 ], ... )

	my @rv = ();

	foreach my $o ( $self -> get_many( @{ $args } ) )
	{
		my @l = map { $o -> $_() } @{ $fields };

		push @rv, \@l;
	}

	return @rv;
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
	my @args = @_;
	my %args = @args;
	my @outcome = ();


	my $sql = $self -> __form_get_sql( @args );


	if( $args{ '_debug' } )
	{
		return $sql;
	}


	my $sth = &LittleORM::Db::prep( $sql, $self -> __get_dbh( @args ) );
	$sth -> execute();

	while( my $data = $sth -> fetchrow_hashref() )
	{
		my $o = $self -> new( _rec => $data );
		push @outcome, $o;
	}
	$sth -> finish();

	return @outcome;

}

sub count
{
	my $self = shift;
	my @args = @_;
	my %args = @args;

	my $outcome = 0;
	my $sql = $self -> __form_count_sql( @args );

	if( $args{ '_debug' } )
	{
		return $sql;
	}

	my $r = &LittleORM::Db::getrow( $sql, $self -> __get_dbh( @args ) );

	$outcome = $r -> { 'count' };

	return $outcome;
}

sub create
{
	my $self = shift;
	my @args = @_;

	my %args = $self -> __correct_insert_args( @args );
	my $sql = $self -> __form_insert_sql( %args );

	if( $args{ '_debug' } )
	{
		return $sql;
	}

	my $allok = 0;

	if( my @pk = $self -> __find_primary_keys() )
	{
		my $sth = &LittleORM::Db::prep( $sql, $self -> __get_dbh( @args ) );
		my $rc = $sth -> execute();

		if( $rc == 1 )
		{
			$allok = 1;

			foreach my $pk ( @pk )
			{
				unless( $args{ $pk -> name() } )
				{
					my $field = &__get_db_field_name( $pk );
					my $data = $sth -> fetchrow_hashref();
					%args = ();
					$args{ $pk -> name() } = $data -> { $field };
				}
			}
		}

		$sth -> finish();

	} else
	{
		my $rc = &LittleORM::Db::doit( $sql, $self -> __get_dbh( @args ) );

		if( $rc == 1 )
		{
			$allok = 1;
		}
	}

	if( $allok )
	{
		return $self -> get( %args );
	}

	assert( 0, sprintf( "%s: %s", $sql, &LittleORM::Db::errstr( $self -> __get_dbh( @args ) ) ) );
}

sub update
{
	my $self = shift;
	my $debug = shift;
	
	assert( my @pkattr = $self -> __find_primary_keys(), 'cant update without primary key' );

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

		if( &__descr_attr( $attr, 'ignore' ) 
		    or 
		    &__descr_attr( $attr, 'primary_key' )
		    or
		    &__descr_attr( $attr, 'ignore_write' ) )
		{
			next ETxc0WxZs0boLUm1;
		}

		my $value = &__prep_value_for_db( $attr, $self -> $aname() );
		push @upadte_pairs, sprintf( '%s=%s', &__get_db_field_name( $attr ), &LittleORM::Db::dbq( $value, $self -> __get_dbh() ) );

	}

	#


	my $where = '1=2';

	{
		my %where_args = ();

		foreach my $pkattr ( @pkattr )
		{
			my $pkname = $pkattr -> name();

			$where_args{ $pkname } = $self -> $pkname();
		}
		my @where = $self -> __form_where( %where_args );

		assert( $where = join( ' AND ', @where ) );
	}

	my $sql = sprintf( 'UPDATE %s SET %s WHERE %s',
			   $self -> _db_table(),
			   join( ',', @upadte_pairs ),
			   $where );


	if( $debug )
	{
		return $sql;
	} else
	{
		my $rc = &LittleORM::Db::doit( $sql, $self -> __get_dbh() );
		
		unless( $rc == 1 )
		{
			assert( 0, sprintf( "%s: %s", $sql, &LittleORM::Db::errstr( $self -> __get_dbh() ) ) );
		}
	}
}

sub copy
{
	my $self = shift;

	my %args = @_;

	assert( my $class = ref( $self ), 'this is object method' );

	my %copied_args = %args;

kdCcjt3iG8jOfthJ:
	foreach my $attr ( $self -> meta() -> get_all_attributes() )
	{
		my $aname = $attr -> name();

		if( $aname =~ /^_/ )
		{
			# internal attrs start with underscore, skip them
			next kdCcjt3iG8jOfthJ;
		}

		if( &__descr_attr( $attr, 'ignore' ) 
		    or 
		    &__descr_attr( $attr, 'primary_key' )
		    or
		    &__descr_attr( $attr, 'ignore_write' ) )
		{
			next kdCcjt3iG8jOfthJ;
		}

		unless( exists $copied_args{ $aname } )
		{
			$copied_args{ $aname } = $self -> $aname();
		}
	}

	return $class -> create( %copied_args );
}

sub delete
{
	my $self = shift;

	my @args = @_;
	my %args = @args;

	my $sql = $self -> __form_delete_sql( @args );

	if( $args{ '_debug' } )
	{
		return $sql;
	}

	my $rc = &LittleORM::Db::doit( $sql, $self -> __get_dbh( @args ) );

	return $rc;
}

sub meta_change_attr
{
	my $self = shift;

	my $arg = shift;

	my %attrs = @_;

	my $arg_obj = $self -> meta() -> find_attribute_by_name( $arg );

	my $cloned_arg_obj = $arg_obj -> clone();

	my $d = ( $cloned_arg_obj -> description() or sub {} -> () );

	my %new_description = %{ $d };

	while( my ( $k, $v ) = each %attrs )
	{
		if( $v )
		{
			$new_description{ $k } = $v;
		} else
		{
			delete $new_description{ $k };
		}
	}

	$cloned_arg_obj -> description( \%new_description );

	$self -> meta() -> add_attribute( $cloned_arg_obj );
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

		my $orm_initialized_attr_desc_option = 'orm_initialized_attr' . ref( $self );

		if( ( $aname =~ /^_/ ) or &__descr_attr( $attr, 'ignore' ) or &__descr_attr( $attr, $orm_initialized_attr_desc_option ) )
		{
			# internal attrs start with underscore, skip them
			next FXOINoqUOvIG1kAG;
		}

		{

			my $newdescr = ( &__descr_or_undef( $attr ) or {} );
			$newdescr -> { $orm_initialized_attr_desc_option } = 1;

			my $predicate = $attr -> predicate();
			my $trigger   = $attr -> trigger();
			my $clearer   = $attr -> clearer(); # change made by Kain
							    # I really need this sometimes in case of processing thousands of objects
							    # and manual cleanup so I'm avoiding cache-related memleaks
							    # so if you want to give me whole server RAM - wipe it out :)

			my $handles   = ( $attr -> has_handles() ? $attr -> handles() : undef ); # also made by kain

			my $orig_method = $self -> meta() -> get_method( $aname );

			$attr -> default( undef );
			$self -> meta() -> add_attribute( $aname, ( is => 'rw',
								    isa => $attr -> { 'isa' },
								    coerce => $attr -> { 'coerce' },


								    ( defined $predicate ? ( predicate => $predicate ) : () ),
								    ( defined $trigger   ? ( trigger => $trigger )     : () ),
								    ( defined $clearer   ? ( clearer => $clearer )     : () ),
								    ( defined $handles   ? ( handles => $handles )     : () ),

								    lazy => 1,
								    metaclass => 'LittleORM::Meta::Attribute',
								    description => $newdescr,
								    default => sub { $_[ 0 ] -> __lazy_build_value( $attr ) } ) );

			if( $orig_method and $orig_method -> isa( 'Class::MOP::Method::Wrapped' ) )
			{
				my $new_method = $self -> meta() -> get_method( $aname );
				my $new_meta_method = Class::MOP::Method::Wrapped -> wrap( $new_method );
				
				map { $new_meta_method -> add_around_modifier( $_ ) } $orig_method -> around_modifiers();
				map { $new_meta_method -> add_before_modifier( $_ ) } $orig_method -> before_modifiers();
				map { $new_meta_method -> add_after_modifier( $_ )  } $orig_method -> after_modifiers();
				
				$self -> meta() -> add_method( $aname, $new_meta_method );
			}
		}
	}
}

sub __lazy_build_value
{
	my $self = shift;
	my $attr = shift;

	my $rec_field_name = &__get_db_field_name( $attr );
	my $coerce_from = &__descr_attr( $attr, 'coerce_from' );

	my $t = $self -> _rec() -> { $rec_field_name };

	if( defined $coerce_from )
	{
		$t = $coerce_from -> ( $t );
		
	} elsif( my $foreign_key = &__descr_attr( $attr, 'foreign_key' ) )
	{
		&__load_module( $foreign_key );

		my $foreign_key_attr_name = &__descr_attr( $attr, 'foreign_key_attr_name' );

		unless( $foreign_key_attr_name )
		{
			my $his_pk = $foreign_key -> __find_primary_key();
			$foreign_key_attr_name = $his_pk -> name();
		}
		
		$t = $foreign_key -> get( $foreign_key_attr_name => $t,
					  _dbh => $self -> __get_dbh() );
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

sub __correct_insert_args
{
	my $self = shift;

	my %args = @_;

	my $dbh = $self -> __get_dbh( %args );

	foreach my $attr ( $self -> meta() -> get_all_attributes() )
	{
		my $aname = $attr -> name();
		unless( $args{ $aname } )
		{
			if( my $seqname = &__descr_attr( $attr, 'sequence' ) )
			{
				my $nv = &LittleORM::Db::nextval( $seqname, $dbh );

				$args{ $aname } = $nv;
			}
		}
	}

	return %args;
}

sub __form_insert_sql
{
	my $self = shift;

	my %args = @_;

	my @fields = ();
	my @values = ();

	my $dbh = $self -> __get_dbh( %args );

XmXRGqnrCTqWH52Z:
	while( my ( $arg, $val ) = each %args )
	{
		if( $arg =~ /^_/ )
		{
			next XmXRGqnrCTqWH52Z;
		}

		assert( my $attr = $self -> meta() -> find_attribute_by_name( $arg ), 
			sprintf( 'invalid attr name passed: %s', $arg ) );

		if( &__descr_attr( $attr, 'ignore' ) 
		    or 
		    &__descr_attr( $attr, 'ignore_write' ) )
		{
			next XmXRGqnrCTqWH52Z;
		}

		my $field_name = &__get_db_field_name( $attr );
		$val = &__prep_value_for_db( $attr, $val );
		
		push @fields, $field_name;
		push @values, $val;
	}

	my $sql = sprintf( "INSERT INTO %s (%s) VALUES (%s)",
			   $self -> _db_table(),
			   join( ',', @fields ),
			   join( ',', map { &LittleORM::Db::dbq( $_, $dbh ) } @values ) );

	if( my @pk = $self -> __find_primary_keys() )
	{
		$sql .= " RETURNING " . join( ',', map { &__get_db_field_name( $_ ) } @pk );
	}

	return $sql;
}

sub __prep_value_for_db
{
	my ( $attr, $value ) = @_;


	my $isa = $attr -> { 'isa' };

	{
		my $ftc = find_type_constraint( $isa );

		if( $ftc and $ftc -> has_coercion() )
		{
			$value = $ftc -> coerce( $value );
		}
	}

	my $rv = $value;


	my $coerce_to = &__descr_attr( $attr, 'coerce_to' );

	if( defined $coerce_to )
	{
		$rv = $coerce_to -> ( $value );
	}

	if( ref( $value ) and blessed( $value ) and &__descr_attr( $attr, 'foreign_key' ) )
	{
		my $foreign_key_attr_name = &__descr_attr( $attr, 'foreign_key_attr_name' );

		unless( $foreign_key_attr_name )
		{
			my $his_pk = $value -> __find_primary_key();
			$foreign_key_attr_name = $his_pk -> name();
		}

		$rv = $value -> $foreign_key_attr_name();
	}

	return $rv;

}

sub __form_delete_sql
{
	my $self = shift;

	my @args = @_;
	my %args = @args;

	if( ref( $self ) )
	{
		if( my @pk = $self -> __find_primary_keys() )
		{
			foreach my $pk ( @pk )
			{

				my $pkname = $pk -> name();
				$args{ $pkname } = $self -> $pkname();
			}


		} else
		{
			foreach my $attr ( $self -> meta() -> get_all_attributes() )
			{
				my $aname = $attr -> name();
				$args{ $aname } = $self -> $aname();
			}
		}
	}

	my @where_args = $self -> __form_where( %args );

	my $sql = sprintf( "DELETE FROM %s WHERE %s", $self -> _db_table(), join( ' AND ', @where_args ) );

	return $sql;
}

sub __collect_field_names
{
	my $self = shift;

	my @rv = ();

QGVfwMGQEd15mtsn:
	foreach my $attr ( $self -> meta() -> get_all_attributes() )
	{
		
		my $aname = $attr -> name();

		if( $aname =~ /^_/ )
		{
			next QGVfwMGQEd15mtsn;
		}

		if( &__descr_attr( $attr, 'ignore' ) )
		{
			next QGVfwMGQEd15mtsn;
		}

		push @rv, &__get_db_field_name( $attr );
		
	}

	return @rv;
}

sub __form_get_sql
{
	my $self = shift;

	my @args = @_;
	my %args = @args;

	my @where_args = $self -> __form_where( @args );

	my @fields_names = $self -> __collect_field_names();

	my @tables_to_select_from = ( $self -> _db_table() );

	if( my $t = $args{ '_tables_to_select_from' } )
	{
		@tables_to_select_from = @{ $t };
	}

	my $distinct_select = '';

	if( $args{ '_distinct' } )
	{
		$distinct_select = 'DISTINCT';

		if( my @pk = $self -> __find_primary_keys() )
		{
			my @fields = map { sprintf( "%s.%s",
						    ( $args{ '_table_alias' } or $self -> _db_table() ),
						    &__get_db_field_name( $_ ) ) } @pk;

			$distinct_select .= sprintf( " ON ( %s ) ", join( ',', @fields ) );
		}
	}

	my $sql = sprintf( "SELECT %s %s FROM %s WHERE %s",
			   $distinct_select,
			   join( ',', map { ( $args{ '_table_alias' }
					      or
					      $self -> _db_table() ) . "." . $_ } @fields_names ),
			   join( ',', @tables_to_select_from ), 
			   join( ' ' . ( $args{ '_logic' } or 'AND' ) . ' ', @where_args ) );

	$sql .= $self -> __form_additional_sql( @args );

	return $sql;
}

sub __form_count_sql
{
	my $self = shift;

	my @args = @_;
	my %args = @args;

	my @where_args = $self -> __form_where( @args );

	my @tables_to_select_from = ( $self -> _db_table() );

	if( my $t = $args{ '_tables_to_select_from' } )
	{
		@tables_to_select_from = @{ $t };
	}

	my $sql = sprintf( "SELECT count(*) FROM %s WHERE %s", 
			   join( ',', @tables_to_select_from ), 
			   join( ' ' . ( $args{ '_logic' } or 'AND' ) . ' ', @where_args ) );

	return $sql;
}

sub __form_additional_sql
{
	my $self = shift;

	my @args = @_;
	my %args = @args;

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
				my $dbf = $k;
				if( my $t = $self -> meta() -> find_attribute_by_name( $k ) )
				{
					$dbf = &__get_db_field_name( $t );
				}
				push @pairs, sprintf( '%s %s', $dbf, $sort_order );
			}
			$sql .= ' ORDER BY ' . join( ',', @pairs );
		} elsif(  ref( $t ) eq 'ARRAY' )
		{ 
			
			my @pairs = ();

			my @arr = @{ $t };

			while( @arr )
			{
				my $k = shift @arr;
				my $sort_order = shift @arr;

				my $dbf = $k;
				if( my $t = $self -> meta() -> find_attribute_by_name( $k ) )
				{
					$dbf = &__get_db_field_name( $t );
				}



				push @pairs, sprintf( '%s %s', ( $dbf or $k ), $sort_order );
			}
			$sql .= ' ORDER BY ' . join( ',', @pairs );


		} else
		{
			# then its attr name and unspecified order


			my $dbf = $t;

			if( my $t1 = $self -> meta() -> find_attribute_by_name( $t ) )
			{
				$dbf = &__get_db_field_name( $t1 );
			}

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

	my @args = @_;
	my %args = @args;

	my @where_args = ();

	my $dbh = $self -> __get_dbh( @args );


fhFwaEknUtY5xwNr:
	while( my $attr = shift @args )
	{

		my $val = shift @args;

		if( $attr eq '_where' )
		{
			push @where_args, $val;

		} elsif( $attr eq '_clause' )
		{
			if( ref( $val ) eq 'ARRAY' )
			{
				my %more_args = ();

				if( my $ta = $args{ '_table_alias' } )
				{
					$more_args{ 'table_alias' } = $ta;
				}

				$val = $self -> clause( @{ $val },
							%more_args );

				assert( ref( $val ) eq 'LittleORM::Clause' );
			} else
			{
				assert( ref( $val ) eq 'LittleORM::Clause' );
				if( my $ta = $args{ '_table_alias' } )
				{
					unless( $val -> table_alias() )
					{
						my $copy = bless( { %{ $val } }, ref $val );
						$val = $copy;
						$val -> table_alias( $ta );
					}
				}
			}

			push @where_args, $val -> sql();

		}

		if( $attr =~ /^_/ ) # skip system agrs, they start with underscore
		{
			next fhFwaEknUtY5xwNr;
		}

		assert( my $class_attr = $self -> meta() -> find_attribute_by_name( $attr ),
			sprintf( 'invalid non-system attribute in where: %s', $attr ) );

		if( &__descr_attr( $class_attr, 'ignore' ) )
		{
			next fhFwaEknUtY5xwNr;
		}

		my $class_attr_isa = $class_attr -> { 'isa' };

		my $col = &__get_db_field_name( $class_attr );

		my $op = '=';
		my $field = LittleORM::Db::Field -> by_type( &__descr_attr( $class_attr, 'db_field_type' ) or $class_attr_isa );

		if( ref( $val ) eq 'HASH' )
		{
			if( $class_attr_isa =~ 'HashRef' )
			{
				next fhFwaEknUtY5xwNr;
			} else
			{
				my %t = %{ $val };
				my $rval = undef;
				( $op, $rval ) = each %t;

				if( ref( $rval ) eq 'ARRAY' )
				{
					
					$val = sprintf( '(%s)', join( ',', map { &LittleORM::Db::dbq( &__prep_value_for_db( $class_attr, $_ ),
												      $dbh ) } @{ $rval } ) );

				} else
				{
					$val = &LittleORM::Db::dbq( &__prep_value_for_db( $class_attr, $rval ),
							      $dbh );
				}
			}

		} elsif( ref( $val ) eq 'ARRAY' )
		{

			if( $class_attr_isa =~ 'ArrayRef' )
			{
				$val = &LittleORM::Db::dbq( &__prep_value_for_db( $class_attr, $val ),
						      $dbh );
			} else
			{
				$op = 'IN';
				$val = sprintf( '(%s)', join( ',', map { &LittleORM::Db::dbq( &__prep_value_for_db( $class_attr, $_ ),
											$dbh ) } @{ $val } ) );
			}

		} else
		{
			$val = &LittleORM::Db::dbq( &__prep_value_for_db( $class_attr, $val ),
					      $dbh );
		}

		$op = $field -> appropriate_op( $op );

		if( $op )
		{
			push @where_args, sprintf( '%s.%s %s %s', 
						   ( $args{ '_table_alias' } or $self -> _db_table() ),
						   $col,
						   $op,
						   $val );
		}
	}

	unless( @where_args )
	{
		@where_args = ( '1=1' );
	}

	return @where_args;
}

sub __find_primary_key
{
	my $self = shift;

	my @pk = $self -> __find_primary_keys();

	return $pk[ 0 ];
}


sub __find_primary_keys
{
	my $self = shift;

	my @rv = ();

	foreach my $attr ( $self -> meta() -> get_all_attributes() )
	{

		if( my $pk = &__descr_attr( $attr, 'primary_key' ) )
		{
			push @rv, $attr;
		}
	}
	return @rv;
}

sub __descr_or_undef
{
	my $attr = shift;

	my $rv = undef;

	if( $attr -> can( 'description' ) )
	{
		$rv = $attr -> description();
	}
	
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

sub __get_dbh
{
	my $self = shift;

	my %args = @_;

	my $dbh = &LittleORM::Db::dbh_is_ok( $self -> __get_class_dbh() );

	unless( $dbh )
	{
		if( my $t = &LittleORM::Db::dbh_is_ok( $args{ '_dbh' } ) )
		{
			$dbh = $t;
			$self -> __set_class_dbh( $dbh );
			LittleORM::Db -> __set_default_if_not_set( $dbh );
		}
	}

	unless( $dbh )
	{
		if( my $t = &LittleORM::Db::dbh_is_ok( &LittleORM::Db::get_dbh() ) )
		{
			$dbh = $t;
			$self -> __set_class_dbh( $dbh );
		}
	}

	assert( &LittleORM::Db::dbh_is_ok( $dbh ), 'this method is supposed to return valid dbh' );

	return $dbh;
}

sub __get_class_dbh
{

	my $self = shift;

	my $calling_package = ( ref( $self ) or $self );

	my $dbh = undef;

	{
		no strict "refs";
		$dbh = ${ $calling_package . "::_dbh" };
	}

	return $dbh;

	
}

sub __set_class_dbh
{
	my $self = shift;

	my $calling_package = ( ref( $self ) or $self );

	my $dbh = shift;


	{
		no strict "refs";
		${ $calling_package . "::_dbh" } = $dbh;
	}

}

42;