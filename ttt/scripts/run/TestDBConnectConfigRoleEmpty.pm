use strict;

package TestDBConnectConfigRoleEmpty;

use Moose::Role;

use TestDB ();

sub littleorm_db_connector_config
{
	return ();
}

42;
