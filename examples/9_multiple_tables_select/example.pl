
# Sorry if its too brief.

# We have three connected with FK tables (models) :

# Library 
# Library_Contents
# Book
# Author

use ORM::Filter;

# Select all libraries which have books of certain author:

my @libraries = Libraries -> filter( Library_Contents -> filter( Book -> filter( author => $author ) ) ) -> get_many();



# Can combine with other clauses (books of author X appeared in library after certain date):

my @libraries = Libraries -> filter( Library_Contents -> filter( Book -> filter( author => $author ),
								 arrived => { '>' => '2010-01-01' } ) ) -> get_many();



# Or clause object:


my @libraries = Libraries -> filter( Library_Contents -> filter( Book -> filter( author => $author ),
								 _clause => $clause ) ) -> get_many();



# More: select books from certain library.
# f() is shortcut for filter() :

my @books = Book -> f( Library_Contents -> f( library => $lib ) ) -> get_many();


# you can pass ( _distinct => 1 ) to get_many() to SELECT DISTINCT

# All other service fields ( _limit, _sortby, more clauses ) can also be passed to get_many()

# get(), get_many(), count() are supported by ORM::Filter

