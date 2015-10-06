# ShieldDB
<img src="https://weaknetlabs.com/images/shielddblogo.png"/><br /><br />
ShieldDB is a project I started out of pure curiosity. I have always wondered if there could be a DBMS that was also a WAF to block all incoming SQL Injection attacks.
As I began to code, I realized that there could be data that could, in fact, be SQL Inject-able (for SELECT statements) that is already public data and that user accounts and client (web user) accounts must be handled by the DBMS's built in security.
This is purely written in Perl and makes heavy use of Regular Expressions.

# Usage
<span style="color:#a40000">ShieldDB</span> 14:53:13 (<span style="color:#36a400;">testData</span>)> create table foo(id int not null auto_increment primary key,name varchar(50),email varchar(50));<br />
 -> creating table foo with descriptor id int not null auto_increment primary key,name varchar(50),email varchar(50)<br />
<span style="color:#a40000">ShieldDB</span> 14:53:44 (<span style="color:#36a400;">testData</span>)><br />
<span style="color:#a40000">ShieldDB</span> 14:53:46 (<span style="color:#36a400;">testData</span>)> insert into foo values(NULL,"douglas berdeaux","weaknetlabs@gmail.com");<br />
 -> record successfully inserted.<br />
<span style="color:#a40000">ShieldDB</span> 14:54:04 (<span style="color:#36a400;">testData</span>)> insert into foo values(NULL,"Gabriella Berdeaux","crwabapples@gmail.com");<br />
 -> record successfully inserted.<br />
<span style="color:#a40000">ShieldDB</span> 14:54:28 (<span style="color:#36a400;">testData</span>)> select * from foo;<br />
0,douglas berdeaux,weaknetlabs@gmail.com,<br />
1,Gabriella Berdeaux,crwabapples@gmail.com,<br />
<span style="color:#a40000">ShieldDB</span> 14:55:31 (<span style="color:#36a400;">testData</span>)><br />
<h3>Regular Expression Support</h3>
<span style="color:#a40000">ShieldDB</span> 15:00:46 (<span style="color:#36a400;">testData</span>)> delete from foo where name = "/[Dd]ougl.s/";<br />
 -> 1 records removed from table.<br />
<span style="color:#a40000">ShieldDB</span> 15:01:14 (<span style="color:#36a400;">testData</span>)> select * from foo;<br />
1,Gabriella Berdeaux,crwabapples@gmail.com,<br />
<span style="color:#a40000">ShieldDB</span> 15:01:18 (<span style="color:#36a400;">testData</span>)> select email from foo where email = "/wab.*l.s/";<br />
crwabapples@gmail.com,<br />
<span style="color:#a40000">ShieldDB</span> 15:01:52 (<span style="color:#36a400;">testData</span>)><br />
<h3>Update Records Using Regular Expressions</h3>
<span style="color:#a40000">ShieldDB</span> 15:20:52 (<span style="color:#36a400;">testData</span>)> select * from foo;<br />
1,Gabriella Berdeaux,dacrwaaaab2,<br />
2,Douglas Berdeaux,weaknetlabs@gmail.com,<br />
<span style="color:#a40000">ShieldDB</span> 15:20:57 (<span style="color:#36a400;">testData</span>)> update table foo set email = "dacrwaaaab@gmail.com" where name  = "/^[Dd]oug/";<br />
<span style="color:#a40000">ShieldDB</span> 15:22:11 (<span style="color:#36a400;">testData</span>)> select * from foo;<br />
1,Gabriella Berdeaux,dacrwaaaab@gmail.com,<br />
2,Douglas Berdeaux,dacrwaaaab@gmail.com,<br />
<span style="color:#a40000">ShieldDB</span> 15:22:19 (<span style="color:#36a400;">testData</span>)><br />

# Dependencies
CPAN - Term::ANSIColor - can be installed using the terminal, e.g. "cpan -i Term::ANSIColor" or, if using Linux, 
from the package management system.

# Videos

#
