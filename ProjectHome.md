# ShieldDB #

<img src='http://weaknetlabs.com/shielddb/images/shielddblogosmall.png' />

The Shield database structure is like no other. It utilizes protected area boundaries and strict segregation between data classes, shared session data from the SQL database to the web server, user authentication via the web application as an authenticator, and much, much more. You can think of ShieldDB as an SQLi-less SQL database.


---


### What is SQLi? ###
SQL injection is a code injection technique, used to attack data driven applications, in which malicious SQL statements are inserted into an entry field for execution (e.g. to dump the database contents to the attacker). <a href='http://en.wikipedia.org/wiki/SQL_injection'> Wikipedia 2013.</a>

### How it works ###

ShieldDB is smarter than other databases in the fact it's data is protected by the database itself, it's database files are protected by the OS in which the file-system belongs to, it knows which data should be returned to the web application, it also provides modularized 24/7 updated security which handles session creation, personal client data, and even more. These are just a few of the ShieldDB's strongest abilities.

### FAQs ###

### Download Source Code ###

(12.04.2014) - ShieldDB development tarball from official site: <a href='http://weaknetlabs.com/shielddb/'><a href='http://weaknetlabs.com/shielddb/'>http://weaknetlabs.com/shielddb/</a></a>

### MANUAL ###
[ShieldDB Commands List](https://code.google.com/p/shielddb/wiki/CommandsList)