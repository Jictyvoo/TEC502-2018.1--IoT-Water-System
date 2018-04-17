CREATE DATABASE IF NOT EXISTS inova_water;

USE inova_water;

CREATE TABLE IF NOT EXISTS Client(
	client_id integer primary key,
	ip_client varchar(20) not null,
	zone char(2),
	expend_goal real,
	goal_update int(1),
	client_email varchar(50)
);

CREATE TABLE IF NOT EXISTS Client_Expend(
	water_expend_id integer primary key,
	fk_client_id int not null,
	expend_date date not null,
	FOREIGN KEY(fk_client_id) REFERENCES Client(client_id)
);

CREATE TABLE IF NOT EXISTS Water_Consume(
	water_consume_id integer primary key,
	water_expended real not null,
	last_syncronization time not null,
	fk_water_expend_id int not null,
	FOREIGN KEY(fk_water_expend_id) REFERENCES Client_Expend(water_expend_id)
);