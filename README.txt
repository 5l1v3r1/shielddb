ShieldDB:
-------------------------
VERSION: THIS IS AN ALPHA VERSION- 0.10.28
This is a simple rdbms tool which uses SQL commands to manage data in csv files.
This data can be relational and keys created upon table creation will apply as
they do in any other dbms. This tool is designed with security in the front seat.


Files:
-------------------------
This tool will create directory tree structures per each table created by the rdbms tool.
The following command:
create table foo(id int not null primary key auto_increment,username varchar(42));
for instance, would create a table csv file in the new directory "db_foo". If we are to 
define a foreign key, we will see an "entanglement.csv" file created within the same directory.
"help" pulls its data from manual/commands.csv


To do:
-------------------------
* As of now, it is just a data manipulation tool from it's own built in command line.
* PHP scripts need written to access the data from the web.
* Enhance the user experience by providing better SQL support for commands.
* Create "install" mechanism which creates the rdbms user and sets permissions on the
CSV files.
* A system for creating tables and table descriptors from arbitrary CSV files
* if(open); try/catch


Author:
-------------------------
Written in Perl, powered by Regular Expressions.
~Douglas Berdeaux