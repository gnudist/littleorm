#!/usr/bin/perl

use strict;

package TestDB;

use DBI ();
use Carp::Assert 'assert';
use Data::Dumper 'Dumper';

{
	my $dbh = undef;

	sub dbconnect
	{
		unless( $dbh )
		{
			$dbh = &__actually_connect();
		}

		return $dbh;
	}
}

sub __actually_connect
{
	my %args = @_;

	unless( %args )
	{
		%args = &__collect_connect_parameters();
	}

	my ( $dbname,
	     $dbhost,
	     $dbport,
	     $dbuser,
	     $dbpass ) = @args{ 'TESTDBNAME', 'TESTDBHOST', 'TESTDBPORT', 'TESTDBUSER', 'TESTDBPASS' };
	
	my $dbspec = 'dbi:Pg:dbname=' . $dbname . ';host=' . $dbhost . ';port=' . $dbport;

	my $dbh = DBI -> connect( $dbspec,
				  $dbuser,
				  $dbpass, { RaiseError => 1 } );

	return $dbh;

}


sub __collect_connect_parameters()
{

# I believe I'm in ttt/scripts/run dir

	my %rv = ();
	my $config = "../../test-db-config.sh";

	assert( open( my $fh, '<', $config ) );

	my $rx = qr/^(TESTDBNAME1|TESTDBNAME|TESTDBUSER|TESTDBPASS|TESTDBPORT|TESTDBHOST)\=([\w\.]+)/;

	while( my $line = <$fh> )
	{
		$line =~ s/\s//g;

		if( $line =~ $rx )
		{
			my ( $key, $value ) = ( $1, $2 );
			$rv{ $key } = $value;
		}
	}

	close( $fh );
	return %rv;
}

42;
