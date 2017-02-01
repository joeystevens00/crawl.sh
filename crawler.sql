CREATE DATABASE crawler;
use crawler;
CREATE TABLE links (id int NOT NULL AUTO_INCREMENT,
	link text, locationDiscovered text, domain text,
	foundAt timestamp,
	PRIMARY KEY(id));
