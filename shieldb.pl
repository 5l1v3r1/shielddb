#!/usr/bin/perl -w
use strict;
#
# ShieldDB Engine - Draft
# 2013-2014 WeakNet Labs
# WeakNetLabs@Gmail.com
#

sub prompt(); # prototyping in Perl? coool! :D
sub query();
sub db();
sub error; # pass type and msg as strings
sub sql_sel(); # SQL SELECT statement
sub desc(); # similar to MySQL's describe
sub n(); # for code dedupe
sub getDate;
sub help();
sub cleanUp();
sub trunc;
sub clone;
sub drop;
sub alter;
$SIG{INT} = \&cleanUp;

my @ARGV; # reserved for future CLI use
my $db = "none";
my $cmd = "";
my $pcmd = ""; # preserved cmd for regexp / case sens / etc

# Security (for now! Needs to be offloaded!):
my @sec = ('users');
my $sec = 0; # boolean for secured database usage
my $logfile = getDate("log");
open(LOG,">>$logfile");

printf("\n Welcome to the ShieldDB Console.\n\n");
prompt();
sub prompt(){
	printf("shieldDB %s (%s)> ",getDate("l"),$db);
	# add the current database to the shell
	$cmd = <STDIN>;
	chomp $cmd;
	$pcmd = $cmd; # preserve for regexp
	$cmd =~ tr/A-Z/a-z/;
	if($cmd ne ''){
		query();
	}else{
		prompt();
	}
}

sub query(){
	my $logq = getDate("l");
	$logq .= ": " . $cmd . "\n";
	print LOG $logq;
	if($cmd =~ m/^(exit|quit)/i){ # leave right away to not be
		exit();        # invasive.
	}elsif($cmd =~ m/^help/){
		help();
		prompt();
	}
	# --
	# Generic commands:
	# check here for syntax errors!
	elsif($cmd !~ m/;$/){
		error("syntax","missing terminating semi colon");
		prompt();
	} # do what the man says!
	elsif($cmd =~ m/^clear/){ # clear the screen for my sanity
                print "\n" x 300;
                prompt();
        }
	elsif($cmd =~ m/^use (database)?/i){ # database select
		db();
		prompt();
	}elsif($cmd =~ m/^clone .* as /i){ # "AS" Required
		# clone table tablename as newtablename
		my $type = $cmd; # table or database
		my $what = $cmd; # table or database name to clone
		my $as = $cmd;   # table or database name to clone INTO
		$type =~ s/^clone ([a-z]+) .*/$1/i; # what type to clone? table or database
		$what =~ s/^clone [a-z]+ ([a-z0-9_-]+) .*/$1/i; # what to clone
		$as =~ s/.* as ([a-z0-9_-]+).*/$1/i;
		if($type eq "database" || $type eq "table"){
			clone($type,$what,$as);
		}else{
			error("NTD","I can only clone a table or database");
		}
		prompt();
	}elsif($cmd =~ m/^drop /i){
		my $type = $cmd; # drop table or db?
		my $what = $cmd; # name to be dropped
		$type =~ s/^drop ([a-z]+) .*/$1/i;
		$what =~ s/^drop [a-z]+ ([a-z0-9_-]+).*/$1/i;
		drop($type,$what);
		prompt();
	}
	# --
	# EVERYTHING below this line REQUIRES a database:
	if($db eq 'none'){
		error("NTD","No database was selected yet.");
		prompt();
	}
	elsif($cmd =~ m/^select/i){ # SQL SELECT statement
		sql_sel();
	}elsif($cmd =~ m/^describe/){
		desc();
	}elsif($cmd =~ m/^show /i){
		show();
	}elsif($cmd =~ m/^truncate /i){
		my $tbl = $cmd;
		$tbl =~ s/.* ([A-Za-z0-9_-]+).*/$1/;
		trunc("db_" . $db . "/tables/" . $tbl . ".tbl");
	}elsif($cmd =~ m/^alter /i){
		my $addWhat = $cmd;
		my $where = $cmd; 
		my $table = $cmd; # let's do some parsing:
		$table =~ s/.* table ([a-z0-9_-]+) .*/$1/i;
		$where =~ s/.*\) ([a-z]+).*/$1/i;
		$addWhat =~ s/.* add ([a-z0-9_ \)\(-]+) .*/$1/i;
	# ALTER TABLE contacts ADD email VARCHAR(60) AFTER name;
	# alter(tabl,where,what);
	
		alter($table,$where,$addWhat);
		prompt();

	# --
	# $cmd Not yet implemented
	}else{
		print " Sorry, SQL command not recognized.\n";
	}
	prompt();
}
# SQL Subroutines:
sub db(){
	# check here if the db actually exists!
	printf(" -> Using database: %s\n",$db);
	$db = $cmd; # set the database name in shell
	$db =~ s/.* ([a-zA-Z0-9_]+);$/$1/; # rid of trash!
	if(opendir(my $d,"db_".$db)){
		closedir($d);
		printf(" -> Dabatase %s loaded successfully\n",$db);
	}else{
		error("NTD","Database " . $db . " does not exist.");
		$db = "none"; # reset
	}
	if(grep($db,@sec)){
		printf(" WARNING: %s is a secured Database!\n",$db);
		$sec = 1;
	}else{
		$sec = 0; # in case they switched DBs in maintenance
	}
}
sub sql_sel(){
	my $clause = 0; # a where clause? (boolean)
	my $header = ""; # header with column names
	my $sep = "+"; # separator for records (dynamic length)
	my $regex = 0; # boolean for regular expressions
	my $whereWhat = "";
	my @output; # array of records
	my $whereEq = "";
	my $what = $cmd;
	my %ands; # for the and clauses linked list
	$what =~ s/.*ect ([A-Za-z0-9,._*-]+) .*/$1/;
	my @what = split(/,/,$what); # for multiple specified columns
	my $tbl = $cmd;
	my $and = 0;
	$tbl =~ s/.*from ([a-zA-Z0-9._-]+).*/$1/;
	if($cmd =~ m/ where /i){ # we have a WHERE clause;
		$clause = 1;
		$whereWhat = $cmd;
		$whereWhat =~ s/.*where ([0-9A-Za-z_.-]+) =.*/$1/;
		$whereEq = $pcmd; # use the preserved version
			# select * from usernames where user = 'trevelyn' and email = 'weaknet' and phone = '412
		$whereEq =~ s/.*where [0-9A-Za-z_.-]+ = ('|")([|\/*?\]\[\{\}\)\(\^\$'"A-Za-z0-9_.-]+)('|").*/$2/;
		if($whereEq =~ m/^\/.*\/$/) {
			$regex = 1; 
			printf(" -> Using Regular Expression Pattern: %s\n",$whereEq); 
		} # we have a regular expression //
	}
	if($cmd =~ m/ and /i){ # we have an AND clause
		$and = 1;
		my @ands = split(/ and /i,$cmd);
		shift @ands; # remove the first element that's just garbage
		foreach (@ands){
			my $what = $_;
			$what =~ s/ .*//;
			my $is = $_;
			$is =~ s/.* ('|")(.*)('|").*/$2/;
			if($is =~ m/^\/.*\/$/){
				print " -> Using (AND) Regular Expression pattern: " . $is . "\n";
				$is =~ s/^\/(.*)\/$/$1/;
				$is = "Regexp_1_3_3_7_-RE-" . $is; # unique enough? ;)		
			}
			$ands{$what} = $is;
		}
	}
	if(!open(TBL,"db_".$db."/tables/".$tbl.".tbl")){
		error("NTD","Table: ".$tbl." does not exist or could not be read.");
		prompt();
	}else{
		my @tblDesc = split(/,/,scalar <TBL>); # split up the first row
		my %recHash; # record hash
		my %colSize; # column length for padding purposes
		my $i = 0; # to build the hash (auto? in interator?)
		@what = () if ($what eq '*'); # for querys that are for every row
		for(my $i = 0;$i<=$#tblDesc;$i++){ # array of table names
			chomp($tblDesc[$i]);
			my $len = $tblDesc[$i];
			$len =~ s/.*\(([0-9]+)\).*/$1/; # grab length as integer - thanks to duck typing
			$tblDesc[$i] =~ s/ .*//; # get rid of the " varchar(30)" at the end leaving the column name
			if($len <= length($tblDesc[$i])){ # in case the title of the column is longer than the max length
				$len += (length($tblDesc[$i]) - $len); # add the difference
			}
			$colSize{$tblDesc[$i]} = $len; # make has colSize be "column name" => integer for length
		}
		foreach(@tblDesc){
			push(@what, $_) if($what eq '*');
			$recHash{$_}=$i;
			$i++;
		}
		# do specified columns actually exist?
		foreach(@what){
			if(!grep(/$_/,@tblDesc)){
				error("COL","Column: ".$_." in Table: ".$tbl." does not exist.");
			}
			$sep .= "-" x int($colSize{$_} + 2) . "+"; # build the separator bar once
		}
		$header = $sep . "\n |"; # now that the separator is constructed, let's get the column names:
		foreach(@what){	
			my $buff = $colSize{$_} - length($_);
			$header .= " " . $_ . (" " x $buff) . " |";
		}
		push(@output,$header); # now throw it into the pile
		n();

		### FOREACH LOOP THROUGH TABLE FILE ###
		while(<TBL>){ # loop through the table and display matching records:
			chomp $_;
			my @record = split(/,/,$_); # array of the record line in the table
			my $output = ''; # reset output
			my $partial = 0; # partial AND clause match (boolean)
			if($clause){ # we have a CLAUSE (boolean)
				if($regex){ # for regex syntax (boolean)
					$whereEq =~ s/\/(.*)\//$1/; # drops the '/'s from the expression leaving just a pattern
					if($record[$recHash{$whereWhat}] =~ m/$whereEq/){ # if that element from the record line matches the pattern ^[ft] for example
						# construct the string result from specified columns
						while(my($what, $is) = each(%ands)){
							# print "WHAT: " . $what . " IS: " . $is . " RECORD: " . $record[$recHash{$what}] . "\n";
							# insert regexp support here
							if($is =~ m/^Regexp_1_3_3_7_-RE-/){
								$is =~ s/^Regexp_1_3_3_7_-RE-//; # get rid of the regexp token
								$partial = 1 if($record[$recHash{$what}] !~ m/$is/); # if field does not match our regexp
							}else{
								$partial = 1 if($is ne $record[$recHash{$what}]); # the difference is "match" vs. "equals"
							}
						}
						if ($partial){
							next; # go to next line because the AND clause was not met
						}
						foreach(@what){ # (name,email) for example
							my $match = "";
							if(length($record[$recHash{$_}]) <= $colSize{$_}){
								$match = " | " . $record[$recHash{$_}];
								my $buff = (int($colSize{$_}) - length($record[$recHash{$_}]));
								$match .= " " x $buff; # append a buffer for display
							}else{
								# THAIR SHOUL BE NO ELSE! HOW DARE UUUU!!!!!!!
							}
							$output .= $match;
						}
						$output = $sep . "\n". $output . " | ";
						push(@output,$output);
					}
				}else{ # no regex syntax
					if($record[$recHash{$whereWhat}] eq $whereEq){
						# AND clause?
						while(my($what, $is) = each(%ands)){
							# insert regexp support here
							$partial = 1 if($is ne $record[$recHash{$what}]);
						}
						if ($partial){
							next; # go to next line because the AND clause was not met
						}
						foreach(@what){
							my $match = "";
							if(length($record[$recHash{$_}]) <= $colSize{$_}){
								$match = " | " . $record[$recHash{$_}];
								my $buff = (int($colSize{$_}) - length($record[$recHash{$_}]));
								$match .= " " x $buff; # append a buffer for display
							}else{
								# THAIR SHOUL BE NO ELSE! HOW DARE UUUU!!!!!!!
							}
							$output .= $match;
						}
						$output = $sep . "\n" . $output . " | ";
						push(@output,$output);
					}
				}
			}else{ # no clause, print all
				foreach(@what){
					my $match = "";
					my $len = 0;
					if(not defined $record[$recHash{$_}]){ # doesn't exist, blank value in record
						$len = 0; 
					}else{
						$len = length($record[$recHash{$_}]);
					}
					if($len <= $colSize{$_}){
						if(defined $record[$recHash{$_}]){
							$match = " | " . $record[$recHash{$_}];
						}else{
							$match = " | "; # doesn't exist/value empty in record
						}
						my $buff = (int($colSize{$_}) - $len);
						$match .= " " x $buff; # append a buffer for display
					}else{
						# NO ELSE
					}
					$output .= $match;
				}
				$output = $sep . "\n". $output . " | ";
				push(@output,$output);
				$output = ''; # reset
			}
		}
		if(grep(/[a-zA-Z0-9]/,@output)){
			push(@output,$sep."\n");
		}
		my $c = $#output - 1; # because of the $sep
		if($#output > 1){ # because the first line is the "+-------+" $sep bar
			foreach(@output){ 
				printf(" %s\n",$_); 
			} # print them out
		}
		printf(" -> %i records returned from database\n",$c); 
	}
	n();
	prompt();
}
sub desc(){ # TODO: separate this from the database
	my $what = $cmd;
	my $rc = -1; # record count minus one for description
	$what =~ s/des.* ([A-Za-z0-9_-]+);.*/$1/;
	if(!open(TBL,"db_".$db."/tables/".$what.".tbl")){
		error("NTD","Table " . $what . " does not exist.");
		prompt();
	}else{
		$rc = @{[<TBL>]};
		close TBL;
		open(TBL,"db_".$db."/tables/".$what.".tbl");
	}
	my $fl = scalar <TBL>; # read ONLY the first line
	chomp $fl;
	my @cols = split(/,/,$fl); # split the file line
	n(); # newline
	printf(" Database: %s, Table: %s, Records: %s\n\n",$db,$what,$rc);
	foreach(@cols){
		my $s = $_;
		my $pk = 0; # primary key
		my $fk = 0; # foreign key
		my $ai = 0; # auto_increment stored proc
		$pk = 1 if($_ =~ m/primary_key/);
		$fk = 1 if($_ =~ m/foreign_key/);
		$ai = 1 if($_ =~ m/auto_increment/);
		$s =~ s/ /\t=>\t/;
		$s =~ s/varchar\(([0-9]+)\)/variable character field with max length: $1./;
		$s =~ s/int.*/integer field./; # integer (like MySQL "int")
		$s .= " (primary key)" if($pk);
		$s .= " (foreign key)" if($fk);
		$s .= " value is automatically incremented" if($ai);
		printf(" %s\n",$s);
	}
	n();
	prompt();
}
sub show(){ # for now, just tbales:
	if($cmd =~ m/ow tables.*;$/i){
		opendir(my $d,"db_".$db."/tables/");
		my @tbls = readdir($d);
		n();
		foreach(@tbls){
			my $tbl = $_;
			$tbl =~ s/\.tbl$//;
			printf(" %s\n",$tbl) if ($tbl !~ m/^\./); # UNIX has those, you know.
		}
		n();
		closedir($d);
	}else{
		error("SYNTAX","show what?");
		prompt();
	}
	prompt();
}
sub clone{ # clone tables OR databases for backups
	if($_[1] eq $_[2]){
		error("FSI","Both names are the same, please choose a different name");
		return;
	}
	print " -> cloning a " . $_[0] . " labeled " . $_[1] . " as " . $_[2] . "\n";
	if($_[0] eq "table"){ # open a new file and copy the table
		my $tbl = "db_" . $db . "/tables/" . $_[1] . ".tbl"; # table name on FS
		my $tbl2 = "db_" . $db . "/tables/" . $_[2] . ".tbl"; # table name on FS
		if(open(TBL1,$tbl)){ # opened successfully, exists.
			if(open(TBL2,">$tbl2")){ # we have FS permissions
				while(<TBL1>){
					print TBL2 $_;
				}
				close TBL2;
				close TBL1;
				printf(" -> clone completed.\n");
			}else{
				error("PERM","permission denied by the file system to create table " . $_[2]);
				return;
			}
		}else{ # doe not exist
			error("NTD","table " . $_[1] . " does not exist");
			return;
		}
	}else{
		system("cp -R db_" . $_[1] . " db_" . $_[2]);
		print " -> cloning of database completed.\n";
		# copy the entire database
	}
}
sub trunc{ # pass me a table file name to truncate
	if(open(TTT,"$_[0]")){ # read
		my $firstLine = scalar <TTT>;
		my $rc = 0; # record count
		while(<TTT>){
			$rc++;
		}
		close TTT;
		open (TTT,">$_[0]");
		print TTT $firstLine; # over write table with table description
		print " -> " . $rc . " -> records dropped from " . $_[0] . "\n";
	}else{
		error("NTD","Table " . $_[0] . "does not exist.");
	}
	close TTT; # close for clean/saving table file to FS
}
sub drop{
	# $_[0] = database,db, or table # $_[1] = name of which to drop
	print " -> dropping type: " . $_[0] . " named: " . $_[1] . "\n";
	if($_[0] eq "table"){
		system("rm db_".$db."/tables/".$_[1].".tbl");
		print " -> table removed.\n";
	}elsif($_[0] =~ m/d(ata)?b(ase)?/){ # db, or database, or datab, or dbase, etc...
		system("rm -rf db_".$_[1]);
		print " -> database completely removed from the filesystem.\n";
	}
	return;
}

sub alter{
	# ALTER TABLE contacts ADD email VARCHAR(60) AFTER name;
	my $where = $_[1]; # FIRST, LAST, AFTER
	my $what = $_[2];  # what to add, "email varchar(60)" in example
	my @tableLines;# every line in the table
	my $tbl = "db_".$db."/tables/".$_[0].".tbl";
	print " -> altering table: " . $_[0] . " adding column: " . $what . " at place: " . $where . "\n";
	my $desc; # table descriptor
	# TODO ADD "after"
	if(open(TBL,$tbl)){ # open it for "reading" first to check it's existence and
		$desc = scalar <TBL>; # snag the first line
		chomp $desc; # get rid of new line in case of append
		$desc .= ",".$what."\n" if($where eq "last");
		$desc = $what.",".$desc."\n" if($where eq "first");
		while(<TBL>){
			push(@tableLines,$_) if ($_ =~ m/[a-z0-9_-]/i);
		}
	}else{
		error("NTD","table: ".$_[0]." does not exist in current database.");
		return;
	}
	if($_[1] ne "first" and $_[1] ne "last" and $_[1] ne "after"){
		error("SYNTAX","I'm not sure where you want this column, try \"help\" command\n");
		return;
	}
	for(my $i = 0; $i<=$#tableLines; $i++){
		chomp $tableLines[$i];
		$tableLines[$i] .= "," if($_[1] eq "last"); # append
		print "TBALLINES[I]: " . $tableLines[$i] . "\n";
		if($_[1] eq "after"){
			# do this part
		}
	}
	# now we write the table file:
	close TBL;
	if(open (TBL,">$tbl")){
		print TBL $desc; # put in the description line first
		foreach(@tableLines){
			print TBL $_ . "\n"; # print the rest of the lines into the table
			print "ADDING LINE: " . $_ . "\n";
		}
		close TBL;
	}else{
		error("FSI","no permission to write to the filesystem");
		return;
	}
}

# Generic Subroutines:
sub error{
	printf(" -> There was an error of type: %s\n MESSAGE: %s\n",$_[0],$_[1]);
}
sub n(){ # just to save some time:
	printf("\n");
}
sub getDate{ # This is used in multiple places
	my @time = localtime(time);
	for(my $i=0;$i<=$#time;$i++){
		if(length($time[$i]) < 2){
			$time[$i] = "0".$time[$i];
		}
	}
	if($_[0] eq 'log'){ # To create the log file:
		return "logs/shieldDB." . $time[4] . "." . $time[3] . "." . ($time[5] + 1900) . ".log";
	}else{
		return $time[2].":".$time[1].":".$time[0];
	}
}
sub help(){ # Help for beginners
	print "\n +--------------------------------------+\n  ";
	print "ShieldDB - Database Management Systems\n ";
	print "+--------------------------------------+\n\n ";
	system("cat manual/capability.txt");
	n();
}
sub cleanUp(){ # to write out the log file if CTRL+C
	close LOG;
	printf(" Goodbye\n");
	exit;
}


# EOF
