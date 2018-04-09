CREATE DATABASE IF NOT EXISTS inova_water;

USE inova_water;

CREATE TABLE IF NOT EXISTS Client(
	client_id integer primary key,
	ip_client varchar(20) not null,
	expend_goal int,
	client_email varchar(50)
);

CREATE TABLE IF NOT EXISTS Water_Consume(
	water_consume_id integer primary key,
	water_expended int not null,
	last_syncronization time not null
);

CREATE TABLE IF NOT EXISTS Client_Water(
	fk_client_id int not null,
	fk_water_consume_id int not null,
	expend_date date not null,
	FOREIGN KEY(fk_client_id) REFERENCES Client(client_id),
	FOREIGN KEY(fk_water_consume_id) REFERENCES Water_Consume(water_consume_id)
);