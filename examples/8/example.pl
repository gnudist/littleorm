
ORM::Db -> init( $dbh );

# Default logic is "AND".

my $c1 = Example::ORM::Class -> clause( cond => [ id => { '>', 91 },
						  id => { '<', 100 } ] );

my $c2 = Example::ORM::Class -> clause( cond => [ id => { '>', 100 },
						  id => { '<', 110 } ] );

# Argument cond - can be list of "attr -> value" pairs (like above), or list of other
# ORM::Clause objects (like next line), which then processed recursively:

# my $c3 = Example::ORM::Class -> clause( cond => [ $c1, $c2 ],
# 					  logic => 'OR' );



# my $debug = Example::ORM::Class -> get( _clause => $c3,
# 			        	  _debug => 1 );


# same as:

my $debug = Example::ORM::Class -> get( _clause => [ cond => [ $c1, $c2 ],
						     logic => 'OR' ],
					_debug => 1 );

print $debug, "\n";

# produces: 
# ... WHERE  (  ( id > '91' AND id < '100' )  OR  ( id > '100' AND id < '110' )  )  LIMIT 1


