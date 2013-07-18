BEGIN;

CREATE TABLE author
(
	id serial NOT NULL PRIMARY KEY,
	aname VARCHAR UNIQUE NOT NULL
);

INSERT INTO author (id,aname) values ( 1, 'John Smith' );
INSERT INTO author (id,aname) values ( 2, 'Maurizio Guinti' );
INSERT INTO author (id,aname) values ( 3, 'Anna Dickson' );

ALTER SEQUENCE author_id_seq RESTART WITH 100;

CREATE TABLE book
(
	id serial NOT NULL PRIMARY KEY,
	title varchar NOT NULL,
	author INT NOT NULL REFERENCES author(id),
	price int not null
);

-- this is actually funny

INSERT INTO book (id,title,author,price) VALUES ( 1,'My Life', 1, 12 );
INSERT INTO book (id,title,author,price) VALUES ( 2,'Good Times', 1, 20 );
INSERT INTO book (id,title,author,price) VALUES ( 3,'Old House', 1, 15 );

INSERT INTO book (id,title,author,price) VALUES ( 4,'Green Desert', 2, 14 );
INSERT INTO book (id,title,author,price) VALUES ( 5,'Big City', 2, 10 );
INSERT INTO book (id,title,author,price) VALUES ( 6,'Hot Food', 2, 11 );

INSERT INTO book (id,title,author,price) VALUES ( 7,'Mad Squirrels', 3, 16 );
INSERT INTO book (id,title,author,price) VALUES ( 8,'Pretty Cats', 3, 17 );
INSERT INTO book (id,title,author,price) VALUES ( 9,'Stupid Men', 3, 18 );

ALTER SEQUENCE book_id_seq RESTART WITH 100;


create table sale_log
(
	id serial NOT NULL PRIMARY KEY,
	created timestamp not null default NOW(),
	book int not null references book(id)
);

INSERT INTO sale_log (id,book) VALUES (1,1);
INSERT INTO sale_log (id,book) VALUES (2,2);
INSERT INTO sale_log (id,book) VALUES (3,3);
INSERT INTO sale_log (id,book) VALUES (4,4);
INSERT INTO sale_log (id,book) VALUES (5,5);
INSERT INTO sale_log (id,book) VALUES (6,6);
INSERT INTO sale_log (id,book) VALUES (7,7);
INSERT INTO sale_log (id,book) VALUES (8,8);
INSERT INTO sale_log (id,book) VALUES (9,9);

INSERT INTO sale_log (id,book) VALUES (10,1);
INSERT INTO sale_log (id,book) VALUES (11,2);
INSERT INTO sale_log (id,book) VALUES (12,3);
INSERT INTO sale_log (id,book) VALUES (13,4);
INSERT INTO sale_log (id,book) VALUES (14,5);
INSERT INTO sale_log (id,book) VALUES (15,6);
INSERT INTO sale_log (id,book) VALUES (16,7);
INSERT INTO sale_log (id,book) VALUES (17,8);
INSERT INTO sale_log (id,book) VALUES (18,9);

ALTER SEQUENCE sale_log_id_seq RESTART WITH 100;


CREATE TABLE publisher (
id serial NOT NULL PRIMARY KEY,
orgname varchar );

ALTER SEQUENCE publisher_id_seq RESTART WITH 100;

CREATE TABLE publication (
id serial NOT NULL PRIMARY KEY,
book int not null references book(id),
published bool NOT NULL DEFAULT false,
created timestamp not null default NOW(),
publisher int not null REFERENCES publisher(id) );

ALTER SEQUENCE publication_id_seq RESTART WITH 100;

COMMIT;
