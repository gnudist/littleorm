use strict;

package TestDBConnectConfigRole;

use Moose::Role;

use TestDB ();

sub littleorm_db_connector_config
{
	return ( connect_code => \&TestDB::dbconnect );

}

42;
