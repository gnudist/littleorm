use ORM::Db;
use ORM::Db::Field;

package ORM::Model;

use Moose;
use Moose::Util::TypeConstraints;

has '_rec' => ( is => 'rw', isa => 'HashRef', required => 1, metaclass => 'ORM::Meta::Attribute', description => { ignore => 1 } );

use Carp::Assert 'assert';
use Scalar::Util 'blessed';
use Module::Load ();
use ORM::Model::Field ();

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

		my $rec = &ORM::Db::getrow( $sql, $self -> __get_dbh() );

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

	my $rec = &ORM::Db::getrow( $sql, $self -> __get_dbh( @args ) );

	my $rv = undef;

	if( $rec )
	{
		$rv = $self -> create_one_return_value_item( $rec, @args );
	}

	return $rv;
}

sub borrow_field
{
	my $self = shift;
	my $attrname = shift;
	my %more = @_;

	if( $attrname )
	{
		unless( exists $more{ 'type_preserve' } )
		{
			$more{ 'type_preserve' } = 1;
		}
	}

	my $rv = ORM::Model::Field -> new( model => ( ref( $self ) or $self ),
					   %more );
	if( $attrname )
	{
		assert( my $attr = $self -> meta() -> find_attribute_by_name( $attrname ) );
		$rv -> base_attr( $attrname );
	}

	return $rv;
}

sub create_one_return_value_item
{
	my $self = shift;
	my $rec = shift;
	my %args = @_;

	my $rv = undef;

	if( $rec )
	{
		if( $args{ '_fieldset' } or $args{ '_groupby' } )
		{
			$rv = ORM::DataSet -> new();

			if( my $fs = $args{ '_fieldset' } )
			{
				foreach my $f ( @{ $fs } )
				{
					unless( ORM::Model::Field -> this_is_field( $f ) )
					{

						$f = $self -> borrow_field( $f,
									    select_as => &__get_db_field_name( $self -> meta() -> find_attribute_by_name( $f ) ) );
					}

					my $dbfield = $f -> select_as();
					my $value = $f -> post_process() -> ( $rec -> { $dbfield } );

					$rv -> add_to_set( { model => $f -> model(),
							     base_attr => $f -> base_attr(),
							     dbfield => $dbfield,
							     value => $value } );
				}
			}

			if( my $grpby = $args{ '_groupby' } )
			{
				foreach my $f ( @{ $grpby } )
				{
					my ( $dbfield, $post_process, $base_attr, $model ) = ( undef, undef, undef, ( ref( $self ) or $self ) );

					if( ORM::Model::Field -> this_is_field( $f ) )
					{
						$dbfield = $f -> select_as();
						$base_attr = $f -> base_attr();
						$post_process = $f -> post_process();
						$model = $f -> model();
					} else
					{
						$dbfield = &__get_db_field_name( $self -> meta() -> find_attribute_by_name( $f ) );
					}

					my $value = ( $post_process ? $post_process -> ( $rec -> { $dbfield } ) : $rec -> { $dbfield } );
					$rv -> add_to_set( { model => $model,
							     base_attr => $base_attr,
							     dbfield => $dbfield,
							     value => $value } );
				}
			}
		} else
		{
			$rv = $self -> new( _rec => $rec );
		}
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

	my $sth = &ORM::Db::prep( $sql, $self -> __get_dbh( @args ) );
	$sth -> execute();

	while( my $data = $sth -> fetchrow_hashref() )
	{
		my $o = $self -> create_one_return_value_item( $data, @args );
		push @outcome, $o;
	}

	$sth -> finish();

	return @outcome;
}

sub _sql_func_on_attr
{
	my $self = shift;
	my $func = shift;
	my $attr = shift;

	my @args = @_;
	my %args = @args;

	my $outcome = 0;

	my $sql = $self -> __form_sql_func_sql( _func => $func,
						_attr => $attr,
						@args );
	if( $args{ '_debug' } )
	{
		return $sql;
	}

	my $sth = &ORM::Db::prep( $sql, $self -> __get_dbh( @args ) );
	$sth -> execute();
	my $rows = $sth -> rows();
	
	if( $args{ '_groupby' } )
	{
		$outcome = [];
# TODO ?
		while( my $data = $sth -> fetchrow_hashref() )
		{
			my $set = ORM::DataSet -> new();
			while( my ( $k, $v ) = each %{ $data } )
			{
				my $field = { model => ( ref( $self ) or $self ),
					      dbfield => $k,
					      value => $v };

				$set -> add_to_set( $field );
			}
			push @{ $outcome }, $set;
		}

	} elsif( $rows == 1 )
	{
		$outcome = $sth -> fetchrow_hashref() -> { $func };

	} else
	{
		assert( 0,
			sprintf( "Got '%s' for '%s'",
				 $rows,
				 $sql ) );
	}

	$sth -> finish();

	return $outcome;
}

sub max
{
	my $self = shift;

	assert( my $attrname = $_[ 0 ] );

	my $rv = $self -> _sql_func_on_attr( 'max', @_ );

	my $attr = undef;

	if( ORM::Model::Field -> this_is_field( $attrname ) )
	{
		assert( $attr = $self -> meta() -> find_attribute_by_name( $attrname -> base_attr() ) );
	} else
	{
		assert( $attr = $self -> meta() -> find_attribute_by_name( $attrname ) );
	}

	if( my $coerce_from = &__descr_attr( $attr, 'coerce_from' ) )
	{
		$rv = $coerce_from -> ( $rv );
	}

	return $rv;
}


sub min
{
	my $self = shift;

	assert( my $attrname = $_[ 0 ] );

	my $rv = $self -> _sql_func_on_attr( 'min', @_ );

	my $attr = undef;

	if( ORM::Model::Field -> this_is_field( $attrname ) )
	{
		assert( $attr = $self -> meta() -> find_attribute_by_name( $attrname -> base_attr() ) );
	} else
	{
		assert( $attr = $self -> meta() -> find_attribute_by_name( $attrname ) );
	}

	if( my $coerce_from = &__descr_attr( $attr, 'coerce_from' ) )
	{
		$rv = $coerce_from -> ( $rv );
	}

	return $rv;
}


# sub min
# {
# 	my $self = shift;

# 	assert( my $attrname = $_[ 0 ] );

# 	my $rv = $self -> _sql_func_on_attr( 'min', @_ );

# 	assert( my $attr = $self -> meta() -> find_attribute_by_name( $attrname ) );

# 	if( my $coerce_from = &__descr_attr( $attr, 'coerce_from' ) )
# 	{
# 		$rv = $coerce_from -> ( $rv );
# 	}

# 	return $rv;
# }

sub __default_db_field_name_for_func
{
	my ( $self, %args ) = @_;

	my $rv = '';
	assert( my $func = $args{ '_func' } );

	if( $func eq 'count' )
	{
		$rv = '*';
		if( $args{ '_distinct' } )
		{
			if( my @pk = $self -> __find_primary_keys() )
			{
				assert( scalar @pk == 1, "count of distinct is not yet supported for multiple PK models" );
				my @fields = map { sprintf( "%s.%s",
							    ( $args{ '_table_alias' } or $self -> _db_table() ),
							    &__get_db_field_name( $_ ) ) } @pk;
				$rv = 'DISTINCT ' . join( ", ", @fields );
			}
		}
	}

	return $rv;
}

sub __form_sql_func_sql
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
	assert( my $func = $args{ '_func' } );
	my $dbf = $self -> __default_db_field_name_for_func( %args );

	if( my $attrname = $args{ '_attr' } )
	{
		if( ORM::Model::Field -> this_is_field( $attrname ) )
		{
			$dbf = $attrname -> form_field_name_for_db_select( $attrname -> determine_ta_for_field_from_another_model( $args{ '_tables_used' } ) );
		} else
		{
			assert( my $attr = $self -> meta() -> find_attribute_by_name( $attrname ) );
			$dbf = &__get_db_field_name( $attr );
		}
	}

	my $sql = sprintf( "SELECT %s%s(%s) FROM %s WHERE %s",
			   $self -> __form_sql_func_sql_more_fields( @args ),
			   $func,
			   $dbf,
			   join( ',', @tables_to_select_from ), 
			   join( ' ' . ( $args{ '_logic' } or 'AND' ) . ' ', @where_args ) );

	$sql .= $self -> __form_additional_sql( @args );

	return $sql;
}

sub __form_sql_func_sql_more_fields
{
	my $self = shift;
	
	my @args = @_;
	my %args = @args;
	my $rv = '';
	
	if( my $t = $args{ '_groupby' } )
	{
		my @sqls = ();

		my $ta = ( $args{ '_table_alias' }
			   or
			   $self -> _db_table() );

		foreach my $grp ( @{ $t } )
		{
			my $f = undef;

			if( ORM::Model::Field -> this_is_field( $grp ) )
			{
				my $use_ta = $ta;

				if( $grp -> model() and ( $grp -> model() ne $self ) )
				{
					$use_ta = $grp -> determine_ta_for_field_from_another_model( $args{ '_tables_used' } );

				}
				$f = $grp -> form_field_name_for_db_select_with_as( $use_ta );#form_field_name_for_db_select( $use_ta );

			} else
			{
				$f = sprintf( "%s.%s",
					      $ta,
					      &__get_db_field_name( $self -> meta() -> find_attribute_by_name( $grp ) ) );
			}
			push @sqls, $f;
		}

		$rv .= join( ',', @sqls );
		$rv .= ',';
	}

	return $rv;
}

sub count
{
	my $self = shift;
	return $self -> _sql_func_on_attr( 'count', '', @_ );

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
		my $sth = &ORM::Db::prep( $sql, $self -> __get_dbh( @args ) );
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
		my $rc = &ORM::Db::doit( $sql, $self -> __get_dbh( @args ) );

		if( $rc == 1 )
		{
			$allok = 1;
		}
	}

	if( $allok )
	{
		return $self -> get( %args );
	}

	assert( 0, sprintf( "%s: %s", $sql, &ORM::Db::errstr( $self -> __get_dbh( @args ) ) ) );
}

sub __find_attr_by_its_db_field_name
{
	my ( $self, $db_field_name ) = @_;

	my $rv = undef;

pgmxcobWi7lULIJW:
	foreach my $attr ( $self -> meta() -> get_all_attributes() )
	{
		if( &__get_db_field_name( $attr ) eq $db_field_name )
		{
			$rv = $attr;
			last pgmxcobWi7lULIJW;
		}
	}

	return $rv;
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
		if( $self -> __should_ignore_on_write( $attr ) )
		{
			next ETxc0WxZs0boLUm1;
		}

		my $aname = $attr -> name();

		my $value = &__prep_value_for_db( $attr, $self -> $aname() );
		push @upadte_pairs, sprintf( '%s=%s', &__get_db_field_name( $attr ), &ORM::Db::dbq( $value, $self -> __get_dbh() ) );

	}

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
		my $rc = &ORM::Db::doit( $sql, $self -> __get_dbh() );
		
		unless( $rc == 1 )
		{
			assert( 0, sprintf( "%s: %s", $sql, &ORM::Db::errstr( $self -> __get_dbh() ) ) );
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
		if( $self -> __should_ignore_on_write( $attr ) )
		{
			next kdCcjt3iG8jOfthJ;
		}
		my $aname = $attr -> name();

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

	my $rc = &ORM::Db::doit( $sql, $self -> __get_dbh( @args ) );

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

sub BUILD
{
	my $self = shift;

	if( $self -> meta() -> can( 'found_orm' ) and $self -> meta() -> found_orm() )
	{
		return;
	}


FXOINoqUOvIG1kAG:
	foreach my $attr ( $self -> meta() -> get_all_attributes() )
	{
		my $aname = $attr -> name();

		my $orm_initialized_attr_desc_option = 'orm_initialized_attr' . ref( $self );

		if( $self -> __should_ignore( $attr ) or &__descr_attr( $attr, $orm_initialized_attr_desc_option ) )
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
								    metaclass => 'ORM::Meta::Attribute',
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

	my $t = $self -> __lazy_build_value_actual( $attr,
						    $self -> _rec() -> { $rec_field_name } );

	return $t;
}


sub __lazy_build_value_actual
{
	my ( $self, $attr, $t ) = @_;

	my $coerce_from = &__descr_attr( $attr, 'coerce_from' );

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

	Module::Load::load( $mn );

	# $mn =~ s/::/\//g;
	# $mn .= '.pm';

	# require( $mn );

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
				my $nv = &ORM::Db::nextval( $seqname, $dbh );

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
			   join( ',', map { &ORM::Db::dbq( $_, $dbh ) } @values ) );

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

	unless( ORM::Model::Field -> this_is_field( $value ) )
	{
		my $coerce_to = &__descr_attr( $attr, 'coerce_to' );

		if( defined $coerce_to )
		{
			$rv = $coerce_to -> ( $value );
		}
	}

	if( blessed( $value ) and &__descr_attr( $attr, 'foreign_key' ) )
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

sub __should_ignore_on_write
{
	my ( $self, $attr ) = @_;
	my $rv = $self -> __should_ignore( $attr );

	unless( $rv )
	{
		if( &__descr_attr( $attr, 'primary_key' )
		    or
		    &__descr_attr( $attr, 'ignore_write' ) )
		{
			$rv = 1;
		}
	}

	return $rv;
}

sub __should_ignore
{
	my ( $self, $attr ) = @_;
	my $rv = 0;

	unless( $rv )
	{
		my $aname = $attr -> name();
		if( $aname =~ /^_/ )
		{
			$rv = 1;
		}
	}

	unless( $rv )
	{

		if( &__descr_attr( $attr, 'ignore' ) )
		{
			$rv = 1;
		}
	}

	return $rv;
}

sub __collect_field_names
{
	my $self = shift;
	my %args = @_;

	my @rv = ();

	my $groupby = undef;
	if( my $t = $args{ '_groupby' } )
	{
		my %t = map { $_ => 1 } grep { not ORM::Model::Field -> this_is_field( $_ ) } @{ $t };
		$groupby = \%t;
	}

	my $field_set = $args{ '_fieldset' };

	my $ta = ( $args{ '_table_alias' }
		   or
		   $self -> _db_table() );

QGVfwMGQEd15mtsn:
	foreach my $attr ( $self -> meta() -> get_all_attributes() )
	{
		if( $self -> __should_ignore( $attr ) )
		{
			next QGVfwMGQEd15mtsn;
		}

		my $aname = $attr -> name();

		my $db_fn = $ta .
		            '.' .
			    &__get_db_field_name( $attr );

		if( $groupby )
		{
			if( exists $groupby -> { $aname } )
			{
				push @rv, $db_fn;
			}

		} else
		{
			unless( $field_set )
			{
				push @rv, $db_fn;
			}
		}
	}

	if( $field_set )
	{
		foreach my $f ( @{ $field_set } )
		{
			unless( ORM::Model::Field -> this_is_field( $f ) )
			{
				$f = $self -> borrow_field( $f,
							    select_as => &__get_db_field_name( $self -> meta() -> find_attribute_by_name( $f ) ) );
			}

			my $select = $f -> form_field_name_for_db_select_with_as( $ta );

			if( $f -> model() )
			{
#				unless( $f -> model() eq $self )
#				{
				my $ta = $f -> determine_ta_for_field_from_another_model( $args{ '_tables_used' } );
				$select = $f -> form_field_name_for_db_select_with_as( $ta );
#				}
			}
			push @rv, $select;# . ' AS ' . $f -> select_as();
		}
	}

	return @rv;
}

sub __form_get_sql
{
	my $self = shift;

	my @args = @_;
	my %args = @args;

	my @where_args = $self -> __form_where( @args );

	my @fields_names = $self -> __collect_field_names( @args );

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
			   join( ',', @fields_names ),
			   join( ',', @tables_to_select_from ), 
			   join( ' ' . ( $args{ '_logic' } or 'AND' ) . ' ', @where_args ) );

	$sql .= $self -> __form_additional_sql( @args );

	return $sql;
}

sub __form_additional_sql
{
	my $self = shift;

	my @args = @_;
	my %args = @args;

	my $sql = '';

	$sql .= $self -> __form_additional_sql_groupby( @args );

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
					$dbf = ( $args{ '_table_alias' }
						 or
						 $self -> _db_table() ) .
						 '.' .
						 &__get_db_field_name( $t );
				}
				push @pairs, sprintf( '%s %s',
						      $dbf, 
						      $sort_order );
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
					$dbf = ( $args{ '_table_alias' }
						 or
						 $self -> _db_table() ) . 
						 '.' .
						 &__get_db_field_name( $t );
				}

				push @pairs, sprintf( '%s %s',
						      ( $dbf or $k ),
						      $sort_order );
			}
			$sql .= ' ORDER BY ' . join( ',', @pairs );

		} else
		{
			# then its attr name and unspecified order
			my $dbf = $t;

			if( my $t1 = $self -> meta() -> find_attribute_by_name( $t ) )
			{
				$dbf = ( $args{ '_table_alias' }
					 or
					 $self -> _db_table() ) . '.' . &__get_db_field_name( $t1 );
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

sub __form_additional_sql_groupby
{
	my $self = shift;
	my %args = @_;
	my $rv = '';
	if( my $t = $args{ '_groupby' } )
	{
		$rv = ' GROUP BY ';


		my @sqls = ();

		my $ta = ( $args{ '_table_alias' }
			   or
			   $self -> _db_table() );

		foreach my $grp ( @{ $t } )
		{
			my $f = undef;

			if( ORM::Model::Field -> this_is_field( $grp ) )
			{
				# $self -> assert_field_from_this_model( $grp );

				my $use_ta = $ta;

				if( $grp -> model() and ( $grp -> model() ne $self ) )
				{
					$use_ta = $grp -> determine_ta_for_field_from_another_model( $args{ '_tables_used' } );
				}

				$f = $grp -> form_field_name_for_db_select( $use_ta );

			} else
			{
				$f = sprintf( "%s.%s",
					      $ta,
					      &__get_db_field_name( $self -> meta() -> find_attribute_by_name( $grp ) ) );
			}
			push @sqls, $f;
		}

		$rv .= join( ',', @sqls );
	}

	return $rv;
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

				assert( ref( $val ) eq 'ORM::Clause' );
			} else
			{
				assert( ref( $val ) eq 'ORM::Clause' );
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

		my ( $op, $col ) = ( undef, undef );
		my $ta = ( $args{ '_table_alias' } or $self -> _db_table() );
		( $op, $val, $col ) = $self -> determine_op_and_col_and_correct_val( $attr, $val, $ta, \%args, $dbh ); # this
														       # is
														       # not
														       # a
														       # structured
														       # method,
														       # this
														       # is
														       # just
														       # code
														       # moved
														       # away
														       # from
														       # growing
														       # too
														       # big
														       # function,
														       # hilarious
														       # comment
														       # formatting
														       # btw,
														       # thx
														       # emacs
		if( $op )
		{
			my $f = sprintf( "%s.%s",
					 $ta,
					 $col );
					 
			if( ORM::Model::Field -> this_is_field( $attr ) )
			{
				$attr -> assert_model_soft( $self );
				$f = $attr -> form_field_name_for_db_select( $ta );
			}

			push @where_args, sprintf( '%s %s %s', 
						   $f,
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

sub determine_op_and_col_and_correct_val
{
	my ( $self, $attr, $val, $ta, $args, $dbh ) = @_;

	my $op = '=';
	my $col = 'UNUSED';

	if( ORM::Model::Field -> this_is_field( $attr ) )
	{
		if( ref( $val ) eq 'HASH' )
		{
			my %t = %{ $val };
			my $rval = undef;
			( $op, $rval ) = each %t;
				
			if( ref( $rval ) eq 'ARRAY' )
			{
				# $val = sprintf( '(%s)', join( ',', map { &ORM::Db::dbq( $_,
				# 							$dbh ) } @{ $rval } ) );
				

				$val = sprintf( '(%s)', join( ',', map { $self -> __prep_value_for_db_w_field( $_,
													       $ta,
													       $args,
													       $dbh ) } @{ $rval } ) );
					
			} else
			{
				$val = &ORM::Db::dbq( $rval,
						      $dbh );
			}
			
		} elsif( ref( $val ) eq 'ARRAY' )
		{
			
			my @values = map { $self -> __prep_value_for_db_w_field( $_,
										 $ta,
										 $args ) } @{ $val };
			$val = sprintf( 'ANY(%s)', &ORM::Db::dbq( \@values, $dbh ) );
			
		} elsif( ORM::Model::Field -> this_is_field( $val ) )
		{ 
			my $use_ta = $ta;
			if( $val -> model() )
			{
				unless( $val -> model() eq $self )
				{
					$use_ta = $val -> determine_ta_for_field_from_another_model( $args -> { '_tables_used' } );
				}

			}
			$val = $val -> form_field_name_for_db_select( $use_ta );
		} else
		{
			$val = &ORM::Db::dbq( $val,
					      $dbh );
		}

	} else
	{
		assert( my $class_attr = $self -> meta() -> find_attribute_by_name( $attr ),
			sprintf( 'invalid non-system attribute in where: %s', $attr ) );

		if( &__descr_attr( $class_attr, 'ignore' ) )
		{
			next fhFwaEknUtY5xwNr;
		}

		my $class_attr_isa = $class_attr -> { 'isa' };
		$col = &__get_db_field_name( $class_attr );
		my $field = ORM::Db::Field -> by_type( &__descr_attr( $class_attr, 'db_field_type' ) or $class_attr_isa );
		
		if( ref( $val ) eq 'HASH' )
		{
			if( $class_attr_isa =~ 'HashRef' )
			{
				1;
				# next fhFwaEknUtY5xwNr;
			} else
			{
				my %t = %{ $val };
				my $rval = undef;
				( $op, $rval ) = each %t;
				
				if( ref( $rval ) eq 'ARRAY' )
				{
					
					$val = sprintf( '(%s)', join( ',', map { $self -> __prep_value_for_db_w_field( &__prep_value_for_db( $class_attr, $_ ),
														       $ta,
														       $args,
														       $dbh )  } @{ $rval } ) );

				
				} else
				{
					my $v = &__prep_value_for_db( $class_attr, $rval );
					
					$val = $self -> __prep_value_for_db_w_field( &__prep_value_for_db( $class_attr, $rval ),
										     $ta,
										     $args,
										     $dbh );


				}
			}
			
		} elsif( ref( $val ) eq 'ARRAY' )
		{
			
			if( $class_attr_isa =~ 'ArrayRef' )
			{
				$val = &ORM::Db::dbq( &__prep_value_for_db( $class_attr, $val ),
						      $dbh );
			} else
			{
				my @values = map { $self -> __prep_value_for_db_w_field( &__prep_value_for_db( $class_attr, $_ ),
											 $ta,
											 $args ) } @{ $val };
				$val = sprintf( 'ANY(%s)', &ORM::Db::dbq( \@values, $dbh ) );
			}
			
		} else
		{

			$val = $self -> __prep_value_for_db_w_field( &__prep_value_for_db( $class_attr, $val ),
								     $ta,
								     $args,
								     $dbh );


			# $val = &ORM::Db::dbq( &__prep_value_for_db( $class_attr, $val ),
			# 		      $dbh );
		}
		
		$op = $field -> appropriate_op( $op );
		
	}
	
	return ( $op, $val, $col );
}

sub __prep_value_for_db_w_field
{
	my ( $self, $v, $ta, $args, $dbh ) = @_;

	my $val = $v;

	if( ORM::Model::Field -> this_is_field( $v ) )
	{
		my $use_ta = $ta;
		if( $v -> model() )
		{
			unless( $v -> model() eq $self )
			{
				$use_ta = $v -> determine_ta_for_field_from_another_model( $args -> { '_tables_used' } );
			}

		}

		$val = $v -> form_field_name_for_db_select( $use_ta );

	} elsif( $dbh )
	{
		$val = &ORM::Db::dbq( $v,
				      $dbh );
	}
	    

	return $val;
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

	my $dbh = &ORM::Db::dbh_is_ok( $self -> __get_class_dbh() );

	unless( $dbh )
	{
		if( my $t = &ORM::Db::dbh_is_ok( $args{ '_dbh' } ) )
		{
			$dbh = $t;
			$self -> __set_class_dbh( $dbh );
			ORM::Db -> __set_default_if_not_set( $dbh );
		}
	}

	unless( $dbh )
	{
		if( my $t = &ORM::Db::dbh_is_ok( &ORM::Db::get_dbh() ) )
		{
			$dbh = $t;
			$self -> __set_class_dbh( $dbh );
		}
	}

	assert( &ORM::Db::dbh_is_ok( $dbh ), 'this method is supposed to return valid dbh' );

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
