# ShieldDB
<img src="https://weaknetlabs.com/images/shielddblogo.png"/><br /><br />
ShieldDB is a project I started out of pure curiosity. I have always wondered if there could be a DBMS that was also a WAF to block all incoming SQL Injection attacks.
As I began to code, I realized that there could be data that could, in fact, be SQL Inject-able (for SELECT statements) that is already public data and that user accounts and client (web user) accounts must be handled by the DBMS's built in security.
This is purely written in Perl and makes heavy use of Regular Expressions.

# Usage
<h3>Stored Procedures and Keys</h3>
<img src="https://weaknetlabs.com/images/shielddbms_example0"/><br />
<h3>Regular Expression Support</h3>
<img src="https://weaknetlabs.com/images/shielddbms_example1"/><br />
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
CPAN - Term::ANSIColor (http://search.cpan.org/~rra/Term-ANSIColor-4.03/lib/Term/ANSIColor.pm) - can be installed using the terminal, e.g. "cpan -i Term::ANSIColor" or, if using Linux, 
from the package management system.

# Videos

#
