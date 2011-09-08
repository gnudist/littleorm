use strict;

# 1. no init required anymore

my $t = ExampleClass -> get( _dbh => $dbh,
			     id => 123 );


# 2. DBH is stored:

my $t1 = ExampleClass -> get( id => 456 );





# 3. crash! no dbh stored nor supplied for this class:
# you can still set default for all classes with ORM::Db -> init( $dbh )

my $t2 = AnotherExampleClass -> get( id => 123 ); 




# 4. Another dbh set:

$AnotherExampleClass::_dbh = $dbh;

my $t = AnotherExampleClass -> get( id => 123 ); # ok




42;
