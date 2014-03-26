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

CREATE table country 
(
	id serial NOT NULL PRIMARY KEY,
	cname VARCHAR UNIQUE NOT NULL
);
INSERT INTO country (cname) values ('USA');
INSERT INTO country (cname) values ('Mexican Rep');
INSERT INTO country (cname) values ('Belgium');
INSERT INTO country (cname) values ('Norway');

ALTER SEQUENCE country_id_seq RESTART WITH 100;

create table author_more_info
(
	id serial NOT NULL PRIMARY KEY,
	author INT NOT NULL REFERENCES author(id),
	birthday timestamp,
	dead timestamp,
	married bool,
	country int references country(id)
);

INSERT INTO author_more_info (author,birthday,dead,married,country) VALUES (1,'1932-04-12',NULL,true,1);

ALTER SEQUENCE author_more_info_id_seq RESTART WITH 100;


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
orgname varchar,
parent int references publisher(id) );

INSERT INTO publisher VALUES (1, 'Major Book House', NULL );
INSERT INTO publisher VALUES (2, 'Less Major Book House1', 1 );
INSERT INTO publisher VALUES (3, 'Less Major Book House2', 1 );
INSERT INTO publisher VALUES (4, 'Less Major Book House3', 1 );
INSERT INTO publisher VALUES (5, 'Even Less Major Book House1', 2 );

ALTER SEQUENCE publisher_id_seq RESTART WITH 100;

CREATE TABLE publication (
id serial NOT NULL PRIMARY KEY,
book int not null references book(id),
published bool NOT NULL DEFAULT false,
created timestamp not null default NOW(),
publisher int not null REFERENCES publisher(id) );


insert into publication (book,publisher) values (1,1);
insert into publication (book,publisher) values (2,1);
insert into publication (book,publisher) values (3,1);

ALTER SEQUENCE publication_id_seq RESTART WITH 100;

CREATE TABLE single_column_pk ( id serial PRIMARY KEY NOT NULL );

CREATE TABLE table_with_array_column ( id serial PRIMARY KEY NOT NULL,
       arr_col varchar[],
       not_null_no_default_col int not null,
       created timestamp not null,
       hr_col varchar );

COMMIT;
