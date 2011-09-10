use strict;


# 0. Clear default $dbh setting:

ORM::Db -> init( $dbh );


# 1. no init required anymore

my $t = ExampleClass -> get( _dbh => $dbh,
			     id => 123 );



# 2. Now DBH is stored:

my $t1 = ExampleClass -> get( id => 456 );




# 3. It also has been set default, but if you pass _dbh for this
# class, it will be used and stored instead

my $t2 = AnotherExampleClass -> get( id => 123,
				     _dbh => $other_dbh ); 



# Remember that you need to set DBH for class only once. Or just set
# default with first _dbh or ORM::Db -> init()

# 4. Another dbh set:

$AnotherExampleClass::_dbh = $dbh;

my $t = AnotherExampleClass -> get( id => 123 ); # ok



# 5. So if you write:

package Class1;

has 'other' => ( ...,
                 description => { foreign_key => 'Class2' } );

...

$Class2::_dbh = $other_dbh;

my $c = Class1 -> get( ...,
                       _dbh => $first_dbh );

$c -> other(); # selected from $other_dbh

# Remember that you need to set DBH for class only once. Or just set
# default with first _dbh or ORM::Db -> init()

42;
