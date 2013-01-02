

1. Tables *DO NOT* have declared FK between them:

Code:

M1 -> filter( field1 => M2 -> filter( ...,
				      _return => 'field2' ) ) -> ...

SQL:

... AND M1.field1=M2.field2 ...



2. If tables *DO* have declared FK we still may just write:

M1 -> filter( M2 -> filter( ... ) )

