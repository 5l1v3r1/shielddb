# shielddb
ShieldDB is a project I started out of pure curiosity. I have always wondered if there could be a DBMS that was also a WAF to block all incoming SQL Injection attacks.
As I began to code, I realized that there could be data that could, in fact, be SQL Inject-able (for SELECT statements) that is already public data and that user accounts and client (web user) accounts must be handled by the DBMS's built in security.
This is purely written in Perl and makes heavy use of Regular Expressions.

# Dependencies
CPAN - Term::ANSIColor - can be installed using the terminal, e.g. "cpan -i Term::ANSIColor" or, if using Linux, 
from the package management system.

# Videos

#
