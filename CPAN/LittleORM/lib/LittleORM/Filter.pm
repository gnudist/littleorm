#!/usr/bin/perl

use strict;

=head1 NAME

LittleORM - ORM for Perl with Moose.

=head1 VERSION

Version 0.08

=cut

=head1 SYNOPSIS

Please refer to L<LittleORM::Tutorial> for thorough description of LittleORM.

=cut

=head1 AUTHOR

Eugene Kuzin, C<< <eugenek at 45-98.org> >>, JID: C<< <gnudist at jabber.ru> >>
with significant contributions by
Kain Winterheart, C<< < kain.winterheart at gmail.com> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-littleorm at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=LittleORM>.  I will
be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc LittleORM


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=LittleORM>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/LittleORM>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/LittleORM>

=item * Search CPAN

L<http://search.cpan.org/dist/LittleORM/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Eugene Kuzin.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut


package LittleORM::Model;

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
			assert( $self -> meta() -> find_attribute_by_name( $val ), sprintf( 'Incorrect %s attribute "%s" in return',
											    $class,
											    $val ) );
			$rv -> returning( $val ); 

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
		assert( my $attr1 = $self -> model() -> meta() -> find_attribute_by_name( $arg ),
			'Injalid attribute 1 in filter: ' . $arg );

		assert( my $attr2 = $filter -> model() -> meta() -> find_attribute_by_name( $filter -> get_returning() ),
			'Injalid attribute 2 in filter (much rarer case)' );

		if( my $fk = &LittleORM::Model::__descr_attr( $attr1, 'foreign_key' ) )
		{
			if( ( $fk eq $filter -> model() ) 
			    and
			    ( my $fkattr = &LittleORM::Model::__descr_attr( $attr1, 'foreign_key_attr_name' ) ) )
			{
				assert( $attr2 = $filter -> model() -> meta() -> find_attribute_by_name( $fkattr ),
					'Injalid attribute 2 in filter (subcase of much rarer case)' );
			}
		}

		my $attr1_t = &LittleORM::Model::__descr_attr( $attr1, 'db_field_type' );
		my $attr2_t = &LittleORM::Model::__descr_attr( $attr2, 'db_field_type' );

		my $cast = '';

		if( $attr1_t and $attr2_t and ( $attr1_t ne $attr2_t ) )
		{
			$cast = '::' . $attr1_t;
		}

		$conn_sql = sprintf( "%s.%s=%s.%s%s",
				     $self -> table_alias(),
				     &LittleORM::Model::__get_db_field_name( $attr1 ),
				     $filter -> table_alias(),
				     &LittleORM::Model::__get_db_field_name( $attr2 ),
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

	unless( $rv )
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
