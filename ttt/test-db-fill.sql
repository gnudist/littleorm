BEGIN;

CREATE TABLE author
(
	id serial NOT NULL PRIMARY KEY,
	aname VARCHAR UNIQUE NOT NULL
);

INSERT INTO author (aname) values ( 'John Smith' );
INSERT INTO author (aname) values ( 'Maurizio Guinti' );
INSERT INTO author (aname) values ( 'Anna Dickson' );


CREATE TABLE book
(
	id serial NOT NULL PRIMARY KEY,
	title varchar NOT NULL,
	author INT NOT NULL REFERENCES author(id)
);

-- this is actually funny

INSERT INTO book (title,author) VALUES ( 'My Life', (SELECT id FROM author WHERE aname='John Smith') );
INSERT INTO book (title,author) VALUES ( 'Good Times', (SELECT id FROM author WHERE aname='John Smith') );
INSERT INTO book (title,author) VALUES ( 'Old House', (SELECT id FROM author WHERE aname='John Smith') );

INSERT INTO book (title,author) VALUES ( 'Green Desert', (SELECT id FROM author WHERE aname='Maurizio Guinti') );
INSERT INTO book (title,author) VALUES ( 'Big City', (SELECT id FROM author WHERE aname='Maurizio Guinti') );
INSERT INTO book (title,author) VALUES ( 'Hot Food', (SELECT id FROM author WHERE aname='Maurizio Guinti') );

INSERT INTO book (title,author) VALUES ( 'Mad Squirrels', (SELECT id FROM author WHERE aname='Anna Dickson') );
INSERT INTO book (title,author) VALUES ( 'Pretty Cats', (SELECT id FROM author WHERE aname='Anna Dickson') );
INSERT INTO book (title,author) VALUES ( 'Stupid Men', (SELECT id FROM author WHERE aname='Anna Dickson') );


COMMIT;
