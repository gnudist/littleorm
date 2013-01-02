

Code:

M1 -> filter( field1 => M2 -> filter( ...,
				      _return => 'field2' ) ) -> ...

SQL:

... AND M1.field1=M2.field2 ...
