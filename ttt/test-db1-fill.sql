BEGIN;

create table db1_t1
(
id serial not null primary key,
country int not null,

-- references country table by id (from other db)

data text );

insert into db1_t1 (country,data) values (1,'USA');
insert into db1_t1 (country,data) values (2,'Mexican Rep');
insert into db1_t1 (country,data) values (3,'Belgium');
insert into db1_t1 (country,data) values (4,'Norway');


create table db1_t2
(
	id serial not null primary key,
	description varchar not null unique,
	countries int[] );

COMMIT;
