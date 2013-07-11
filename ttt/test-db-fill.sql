BEGIN;

CREATE TABLE author
(
	id serial NOT NULL PRIMARY KEY,
	aname VARCHAR UNIQUE NOT NULL
);

INSERT INTO author (aname) values ( 'John Smith' );
INSERT INTO author (aname) values ( 'Maurizio Guinti' );
INSERT INTO author (aname) values ( 'Anna Dickson' );

COMMIT;
