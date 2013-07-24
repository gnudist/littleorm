#!/usr/bin/perl

use strict;

package LittleORM::Model;
use LittleORM::Model::Field ();

# Extend LittleORM::Model capabilities with filter support:

sub f
{
	my $self = shift;
	return $self -> filter( @_ );
}

sub _disambiguate_filter_args
{
	my ( $self, $args ) = @_;

	{
		assert( ref( $args ) eq 'ARRAY', 'sanity assert' );

		my $argsno = scalar @{ $args };
		my $class = ( ref( $self ) or $self );
		my @disambiguated = ();

		my $i = 0;
		foreach my $arg ( @{ $args } )
		{
			if( blessed( $arg ) and $arg -> isa( 'LittleORM::Filter' ) )
			{
				unless( $i % 2 )
				{
					# this will wrk only with single column PKs

					if( my $attr_co_connect = &LittleORM::Filter::find_corresponding_fk_attr_between_models( $class,
															   $arg -> model() ) )
					{
						push @disambiguated, $attr_co_connect;
						$i ++;

					} elsif( my $rev_connect = &LittleORM::Filter::find_corresponding_fk_attr_between_models( $arg -> model(),
															    $class ) )
					{
						# print $class, "\n";
						# print $arg -> model(), "\n";
						# print $rev_connect, "\n";

						my $to_connect_with = 0;

						{
							assert( my $attr = $arg -> model() -> meta() -> find_attribute_by_name( $rev_connect ) );

							if( my $foreign_key_attr_name = &LittleORM::Model::__descr_attr( $attr, 'foreign_key_attr_name' ) )
							{
								$to_connect_with = $foreign_key_attr_name;
							} else
							{
								$to_connect_with = $class -> __find_primary_key() -> name();
							}

						}

						push @disambiguated, $to_connect_with;
						unless( $arg -> returning() )
						{
							$arg -> returning( $rev_connect );
						}

						$i ++;


					} else
					{
						assert( 0,
							sprintf( "Can not automatically connect %s and %s - do they have FK between?",
								 $class,
								 $arg -> model() ) );
					}
				}
			} elsif( blessed( $arg ) and $arg -> isa( 'LittleORM::Clause' ) )
			{
				unless( $i % 2 )
				{
					push @disambiguated, '_clause';
					$i ++;
				}
			}

			push @disambiguated, $arg;
			$i ++;
		}
		$args = \@disambiguated;
	}

	return $args;
}

sub filter
{
	my ( $self, @args ) = @_;

	my @filters = ();

	my @clauseargs = ( _where => '1=1' );

	my $class = ( ref( $self ) or $self );

	my $rv = LittleORM::Filter -> new( model => $class );

	@args = @{ $self -> _disambiguate_filter_args( \@args ) };
	assert( scalar @args % 2 == 0 );

	while( my $arg = shift @args )
	{
		my $val = shift @args;

		if( $arg eq '_return' )
		{
			if( LittleORM::Model::Field -> this_is_field( $val ) )
			{
				$val -> assert_model( $class );
				$rv -> returning_field( $val );
			} else
			{

				assert( $self -> meta() -> find_attribute_by_name( $val ), sprintf( 'Incorrect %s attribute "%s" in return',
											    $class,
											    $val ) );
				$rv -> returning( $val ); 
			}

		} elsif( $arg eq '_sortby' )
		{
			assert( 0, '_sortby is not allowed in filter' );

		} elsif( $arg eq '_exists' )
		{
			assert( $val and ( ( ref( $val ) eq 'HASH' )
					   or
					   $val -> isa( 'LittleORM::Filter' ) ) );
			$rv -> connect_filter_exists( 'EXISTS', $val );

		} elsif( $arg eq '_not_exists' )
		{
			assert( $val and $val -> isa( 'LittleORM::Filter' ) );
			$rv -> connect_filter_exists( 'NOT EXISTS', $val );

		} elsif( blessed( $val ) and $val -> isa( 'LittleORM::Filter' ) )
		{

			$rv -> connect_filter( $arg => $val );

		} elsif( blessed( $val ) and $val -> isa( 'LittleORM::Clause' ) )
		{
			$rv -> push_clause( $val );
		} else
		{
			push @clauseargs, ( $arg, $val );
		}

	}

	{
		my $clause = LittleORM::Clause -> new( model => $class,
						 cond => \@clauseargs,
						 table_alias => $rv -> table_alias() );

		$rv -> push_clause( $clause );
	}

	return $rv;
}


package LittleORM::Filter;

# Actual filter implementation:

use Moose;

has 'model' => ( is => 'rw', isa => 'Str', required => 1 );
has 'table_alias' => ( is => 'rw', isa => 'Str', default => \&get_uniq_alias_for_table );
has 'returning' => ( is => 'rw', isa => 'Maybe[Str]' ); # return column name for connecting with other filter
has 'returning_field' => ( is => 'rw', isa => 'Maybe[LittleORM::Model::Field]', default => undef );
has 'clauses' => ( is => 'rw', isa => 'ArrayRef[LittleORM::Clause]', default => sub { [] } );

use Carp::Assert 'assert';
use List::MoreUtils 'uniq';

{
	my $counter = 0;

	sub get_uniq_alias_for_table
	{
		$counter ++;

		return "T" . $counter;
	}

}

sub form_conn_sql
{
	my ( $self, $arg, $filter ) = @_;

	my $conn_sql = '';

	{
		my $ta1 = $self -> table_alias();
		my $ta2 = $filter -> table_alias();

		my $attr1_t = '';
		my $attr2_t = '';
		my $cast = '';

		my $arg1 = $arg;
		my $arg2 = $filter -> get_returning();

		my ( $f1, $f2 ) = ( '', '' );

		{
			my $attr1 = $self -> model() -> meta() -> find_attribute_by_name( $arg1 );

			assert( ( $attr1 or LittleORM::Model::Field -> this_is_field( $arg1 ) ),
				'Injalid attribute 1 in filter: ' . $arg1 );

			my $attr2 = $filter -> model() -> meta() -> find_attribute_by_name( $arg2 );
			assert( ( $attr2 or LittleORM::Model::Field -> this_is_field( $arg2 ) ),
				'Injalid attribute 2 in filter (much rarer case)' );

			
			if( ( $attr1 and $attr2 ) and ( my $fk = &LittleORM::Model::__descr_attr( $attr1, 'foreign_key' ) ) )
			{
				if( ( $fk eq $filter -> model() ) 
				    and
				    ( my $fkattr = &LittleORM::Model::__descr_attr( $attr1, 'foreign_key_attr_name' ) ) )
				{
					assert( $attr2 = $filter -> model() -> meta() -> find_attribute_by_name( $fkattr ),
						'Injalid attribute 2 in filter (subcase of much rarer case)' );
				}
			}
			if( $attr1 )
			{
				$attr1_t = &LittleORM::Model::__descr_attr( $attr1, 'db_field_type' );
				$f1 = sprintf( "%s.%s",
					       $ta1,
					       &LittleORM::Model::__get_db_field_name( $attr1 ) );
				
			} else
			{
				$f1 = $arg1 -> form_field_name_for_db_select( $ta1 );
			}

			if( $attr2 )
			{
				$attr2_t = &LittleORM::Model::__descr_attr( $attr2, 'db_field_type' );
				$f2 = sprintf( "%s.%s",
					       $ta2,
					       &LittleORM::Model::__get_db_field_name( $attr2 ) );

			} else
			{
				$f2 = $arg2 -> form_field_name_for_db_select( $ta2 );
			}

			if( $attr1_t and $attr2_t and ( $attr1_t ne $attr2_t ) )
			{
				$cast = '::' . $attr1_t;
			}

		}



		$conn_sql = sprintf( "%s=%s%s",
				     $f1,
				     $f2,				     
				     $cast );
	}

	return $conn_sql;

}

sub connect_filter
{
	my $self = shift;

	my ( $arg, $filter ) = $self -> sanitize_args_for_connecting( @_ );

	map { $self -> push_clause( $_, $filter -> table_alias() ) } @{ $filter -> clauses() };

	my $conn_sql = $self -> form_conn_sql( $arg, $filter );

	{
		my $c1 = $self -> model() -> clause( cond => [ _where => $conn_sql ],
						     table_alias => $self -> table_alias() );


		$self -> push_clause( $c1 );
	}
}


sub sanitize_args_for_connecting
{
	my ( $self, $arg, $filter ) = @_;

	unless( $filter )
	{
		if( ref( $arg ) eq 'HASH' )
		{
			assert( scalar keys %{ $arg } == 1 );
			( $arg, $filter ) = %{ $arg };
		}
	}

	unless( $filter )
	{

		if( $arg and blessed( $arg ) and $arg -> isa( 'LittleORM::Filter' ) )
		{
			my $args = $self -> model() -> _disambiguate_filter_args( [ $arg ] );

			( $arg, $filter ) = @{ $args };


		} else
		{
			assert( 0, 'check args sanity' );
		}
	}

	return ( $arg, $filter );

}


sub connect_filter_exists
{
	my $self = shift;
	my $exists_keyword = shift;

	my ( $arg, $filter ) = $self -> sanitize_args_for_connecting( @_ );

	my $exf = LittleORM::Filter -> new( model => $filter -> model(),
				      table_alias => $filter -> table_alias() );
	

	map { $exf -> push_clause( $_, $filter -> table_alias() ) } @{ $filter -> clauses() };
	
	my $conn_sql = $self -> form_conn_sql( $arg, $filter );

	{
		my $c1 = $self -> model() -> clause( cond => [ _where => $conn_sql ],
						     table_alias => $self -> table_alias() );


		$exf -> push_clause( $c1 );
	}

	{

		my $select_from_sql_part = '';

		{
			my %t = $exf -> all_tables_used_in_filter();
			# do not include outer table inside EXISTS select:
			$select_from_sql_part = join( ',', map { $t{ $_ } .
								 " " .
								 $_ }
						           grep { $_ ne $self -> table_alias() }
						           keys %t );

		}

		my $sql = sprintf( " %s (SELECT 1 FROM %s WHERE %s LIMIT 1) ",
				   $exists_keyword,
				   $select_from_sql_part,
				   join( ' AND ', $exf -> translate_into_sql_clauses() ) );
		
		my $c1 = $self -> model() -> clause( cond => [ _where => $sql ],
						     table_alias => $self -> table_alias() );
		
		
		$self -> push_clause( $c1 );
	}
	
	return 0;
}

sub push_clause
{
	my ( $self, $clause, $table_alias ) = @_;


	unless( $clause -> table_alias() )
	{
		unless( $table_alias )
		{
			if( $self -> model() eq $clause -> model() )
			{
				$table_alias = $self -> table_alias();

				# maybe clone here to preserve original clause obj ?
				my $copy = bless( { %{ $clause } }, ref $clause );
				$clause = $copy;
				$clause -> table_alias( $table_alias );
			}
		}
	}

	if( $clause -> table_alias() )
	{

		push @{ $self -> clauses() }, $clause;

	} else
	{
		assert( $self -> model() ne $clause -> model(), 'sanity assert' );

		my $other_model_filter = $clause -> model() -> filter( $clause );
		$self -> connect_filter( $other_model_filter );


	}



	# if( $self -> model() eq $clause -> model() )
	# {

	# } else
	# {
	# 	my $other_model_filter = $clause -> model() -> filter( _clause => $clause );
	# 	$self -> connect_filter( $other_model_filter );
	# }


	return $self -> clauses();
}

sub get_returning
{
	my $self = shift;

	my $rv = $self -> returning();
	
	if( $rv )
	{
		1;
	} elsif( my $rv_f = $self -> returning_field() )
	{
		$rv = $rv_f;

	} else
	{
		assert( my $pk = $self -> model() -> __find_primary_key(),
			sprintf( 'Model %s must have PK or specify "returning" manually',
				 $self -> model() ) );
		$rv = $pk -> name();
	}

	return $rv;

}

sub translate_into_sql_clauses
{
	my $self = shift;
	my @args = @_;

	my $clauses_number = scalar @{ $self -> clauses() };

	my @all_clauses_together = ();

	for( my $i = 0; $i < $clauses_number; $i ++ )
	{
		my $clause = $self -> clauses() -> [ $i ];

		push @all_clauses_together, $clause -> sql( @args );

	}

	return @all_clauses_together;
}

sub all_tables_used_in_filter
{
	my $self = shift;

	my %rv = ();

	foreach my $c ( @{ $self -> clauses() } )
	{
		assert( $c -> table_alias(), 'Unknown clause origin' );
		$rv{ $c -> table_alias() } = $c -> model() -> _db_table();
	}

	return %rv;
}

sub get_many
{
	my $self = shift;

	return $self -> call_orm_method( 'get_many', @_ );
}

sub get
{
	my $self = shift;

	return $self -> call_orm_method( 'get', @_ );
}

sub count
{
	my $self = shift;

	return $self -> call_orm_method( 'count', @_ );
}

sub delete
{
	assert( 0, 'Delete is not supported in LittleORM::Filter. Just map { $_ -> delete() } at what get_many() returns.' );
}

sub call_orm_method
{
	my $self = shift;
	my $method = shift;

	my @args = @_;

	my %all = $self -> all_tables_used_in_filter();

	return $self -> model() -> $method( @args,
					    _table_alias => $self -> table_alias(),
					    _tables_to_select_from => [ map { sprintf( "%s %s", $all{ $_ }, $_ ) } keys %all ],
					    _where => join( ' AND ', $self -> translate_into_sql_clauses( @args ) ) );
}

sub find_corresponding_fk_attr_between_models
{
	my ( $model1, $model2 ) = @_;

	my $rv = undef;

DQoYV7htzKfc5YJC:
	foreach my $attr ( $model1 -> meta() -> get_all_attributes() )
	{
		if( my $fk = &LittleORM::Model::__descr_attr( $attr, 'foreign_key' ) )
		{
			if( $model2 eq $fk )
			{
				$rv = $attr -> name();
			}
		}
	}
	
	return $rv;
}

42;
