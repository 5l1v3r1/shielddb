#!/usr/bin/perl -w
#
# Shield DB DBMS TOOL (c) GNU 3.0
# Code began 10.05.2013 by
# Douglas Berdeaux
# weaknetlabs@gmail.com
#
use strict;
use Term::ANSIColor;

# global variables
my $db = ""; # which database in use?

# Subroutine prototypes
sub prompt();     # display the prompt
sub cmd($);       # processing each command
sub msg($);       # message dialog
sub createdb($);  # create database and all files
sub createtbl($); # create table
sub show($);      # show tables
sub error($$);    # error output with code
sub help($);      # help dialog
sub quit();       # exit / file clean up
sub n();          # new line
sub desc($$);     # get the descriptor for a table
sub sel($$);      # SQL SELECT query sel(command,type) type can be "in","del",etc.
sub clone($);     # cloning a table or database
sub retdate();    # return the date
sub drop($);      # delete stuff! \m/
sub chkdb();	  # anywhere we NEED a $db put a: "return if chkdb();"
sub insert($);	  # SQL INSERT query
sub chkkey($$$);  # check (primary|foreign) key for uniqueness
sub whereand($);  # return a hash of where foo => bar (use for delete and select)
sub del($);       # delete record
sub trunc($);     # truncate table
sub update($);	  # update a record
sub incl($);	  # in() clause
sub man();	  # manual page

if(!$ARGV[0]){ # check for arguments
	prompt() while (1); # to infinity and beyond!
}else{
	if($ARGV[0] =~ m/^-?-h(elp)?$/){
		man(); # manual page
	}
}

# All functions below:
sub prompt(){
	my $dbn = $db;
	$dbn = "none" if($dbn eq "");
	my $date = retdate();
	print color 'red';
	print "ShieldDB ";
	print color 'reset';
	#printf("%s (%s)> ",$date,$dbn);
	print $date," (";
	if($dbn ne "none"){
		print color 'green';
	}
	print $dbn;
	if($dbn ne "none"){
		print color 'reset';
	}
	print ")> ";
	my $cmd = <STDIN>;
	chomp $cmd;
	cmd($cmd);
}

sub cmd($){
	return if($_[0] eq ""); # newline
	my $cmd = $_[0];
	if($cmd =~ m/^(quit|exit)/i){
		quit(); # don't be invasive
	}elsif($cmd !~ m/;$/){
		error("SYNTAX","please terminate your commands with a semi-colon");
	}elsif($cmd =~ m/^use /i){
		usedb($cmd);
	}elsif($cmd =~ m/^create database/i){
		createdb($cmd); # create a db directory
	}elsif($cmd =~ m/^help/i){
		help($cmd);
	}elsif($cmd =~ m/^create table/i){
		return if chkdb();
		createtbl($cmd);
	}elsif($cmd =~ m/^show /i){
		return if chkdb();
		show($cmd);
	}elsif($cmd =~ m/.* in(\s+)?\(.*\).*/){
		incl($cmd); # in clause!
	}elsif($cmd =~ m/^describe /i){
		return if chkdb();
		desc($cmd,1);
	}elsif($cmd =~ m/^select /i){
		return if chkdb();
		sel($cmd,"");
	}elsif($cmd =~ m/^clone /i){
		clone($cmd); # copy a table or db
	}elsif($cmd =~ m/^drop /i){
		drop($cmd); # drop a table or db
	}elsif($cmd =~ m/^insert /i){
		return if chkdb();
		insert($cmd); # our insert SQL query!
	}elsif($cmd =~ m/^truncate /){
		if($db ne ""){
			trunc($cmd); # truncate the table
		}else{
			error("DB","please choose a database");
			return 1;
		}
	}elsif($cmd =~ m/^update table /i){
		if(chkdb()){ # is a database chosen?
			error("DB","please choose a database first");
			return 1;
		}else{
			update($cmd);
		}
	}elsif($cmd =~ m/^delete /i){
		if($cmd !~ m/^delete from ([a-z0-9_-]+) where ([a-z0-9_-]+) = .*;$/i){
			error("SYNTAX","try \"help\" command for syntax to remove records with delete");
			return 1; # simple syntax check
		}else{
			del($cmd);
		}
	}else{
		error("DBMS","command not yet implemented");
	}
}

### SQL COMMANDS ###

sub sel($$){ # SELECT / DELETE 
	my @del; # integer of record lines to delete
	my $dc = 1; # start at 1 because $. starts at 1 and we don't want to remove the descriptor line
	my $del = 1 if($_[0] =~ m/^del/); # delete boolean
	my $upd = 1 if($_[0] =~ m/^upd/); # update boolean
	my $table = $_[0];
	my $cols = $_[0];
	my %cols; # hash columnname => int++
	my $where = 0; # where boolean
	my $in = 1 if($_[1] eq "in"); # in() clause boolean
	my $or = 1 if($_[0] =~ m/ or /i); # WE HAVE LOGICAL OR
	my %or if($or); # only create it if need be
	if($or){
		my @or = split(/ or /,$_[0]);
		shift @or; # remove useless first entry
		for(my $i=0;$i<=$#or;$i++){
			$or[$i] =~ s/;$//; # remove last line
			$or[$i] =~ s/["']//g;
			my @splt = split(/\s+=\s+/,$or[$i]);
			$or{$splt[0]} = $splt[1];
		}
	}
	$where = 1 if($table =~ m/ where /i); # boolean true
	$table =~ s/.* from ([^ ]+).*/$1/ if($cols =~ m/^delete/i);
	$table =~ s/.* from ([a-z0-9_-]+).*/$1/i if($cols =~ m/^select /i);
	$table =~ s/.* table ([a-z0-9_-]+).*/$1/i if($cols =~ m/^update /i);
	$cols =~ s/^select ([a-z0-9_,.*-]+).*/$1/i if($cols =~ m/^select /i); # possibly select multiple columns
	$cols =~ s/^update table ([a-z0-9_,.*-]+) set ([0-9a-z_-]+) .* where ([a-z0-9_-]+).*/$3/i if($upd); # update one column
	my $tblPath = "db_".$db."/tables/".$table.".tbl";
	if (!open(TBL,$tblPath)){ # open the table file e.g. "db_testdb/tables/foo.tbl"
		warn $!;
		return;
	}
	my @desc = split(/,/,scalar <TBL>); # shift and get descriptor
	for(my $i=0;$i<=$#desc;$i++){
		$desc[$i] =~ s/^\s+//; # get rid of beginning whitespace
		$desc[$i] =~ s/ .*//; # get rid of constraints
		chomp $desc[$i];
		$cols{$desc[$i]} = $i;
	}
	my %where = whereand($_[0]) if($where); # offloaded!

	my @cols; # array of columns we want to display
	if($cols eq '*' or $del){# for delete we just check all columns
		push (@cols,$_) foreach(@desc); # select *
	}elsif($cols =~ m/,/){
		push(@cols,split(/,/,$cols)); # comma sep
	}else{
		push(@cols,$cols); # just one column (EVEN FOR UPDATE)
	} # now let's loop the rest of the table and display what we want
	while(<TBL>){
		$dc++; # this token is for deletion lines and will be pushed into the @del array
		chomp $_; # IFF this is NOT an in() select statement
		my $record = ""; 
		my @recsplt = split(/,/,$_);
		foreach(@cols){
			if($where && $where{$_}){
				if($where{$_} =~ m/^\/(.*)\/i?$/){ # using regular expressions here	
					my $wh = $where{$_};
					my $igcase;
					$igcase = 1 if($wh =~ m/\/i$/);
					$wh =~ s/^.(.*).i?$/$1/; # drop the syntax, and step away
					if($recsplt[$cols{$_}] =~ m/$wh/){   # from the keyboard!
						$record .= $recsplt[$cols{$_}] . ",";
						if($in){
							push(@del,$recsplt[$cols{$_}]);
						}
					}else{
						if(!$or){ # no OR logic, flow through
							$record = ""; # reset the record because of
							last; # mismatch or partial match; not acceptable
						}else{
							# before failing, let's check the %or{$recsplt[$cols{$_}]} values;
						}
					}
				}else{ # NO REGULAR EXPRESSION
					if($where{$_} eq $recsplt[$cols{$_}]){
						$record .= $recsplt[$cols{$_}] . ",";
						if($in){
							push(@del,$recsplt[$cols{$_}]);
						}
					}else{
						if(!$or){ # no OR logic, flow through
							$record = ""; # reset the record because of
							last; # mismatch or partial match; not acceptable
						}else{
							# before failing, let's check the %or{$recsplt[$cols{$_}]} values;
						}
					}
				}
			}else{
				if($in){
					push(@del,$recsplt[$cols{$_}]);
				}
				$record .= $recsplt[$cols{$_}] . ",";
			}
		}
		if(($upd || $del) && $record ne ""){
			push(@del,$dc); # we want to delete this line
		}else{
			printf("%s\n",$record) if($record ne "" && !$in); # output to STDOUT
		}
	}
	close TBL; # complete!
	return @del; # return our delete array of numbers
}

sub incl($){
	# let's make them the same. eg. if "in(select * from foo)" do pemdas and return comma sep
	# which will match "in(foo,bar,baz)"
	my $in = $_[0]; # select * from users where username in(trev,trevelyn,trevvy,trefflin);
	my $where = $_[0]; # select * from users where username in(select * from usernames);
	$where =~ s/.*where ([a-z0-9_.-]+).*/$1/;
	$in =~ s/.*in(\s+)?\(([a-z0-9,._* -]+)\).*/$2/i;
	my $select = $in if($in =~ m/^select .*/i);
	if($select){
		my $cl = "where " . $where . " = ";
		# msg("subquery: " . $in);
		my @sub = sel($in,"in");
		for(my $i=0;$i<$#sub;$i++){
			$cl .= $sub[$i] . " or " . $where . " = ";
		}
		$cl .= "or " . $where . " = " . $sub[$#sub];
		# msg("subquery 2: " . $cl);
	}else{
		print "WHERE: " . $where . " IN(): " . $in . "\n";
	}
	return 0;
}

sub update($){ # update table userpk set username = "lol" where id = 2;
	my @recs; # all records, modified for printing into new tbl file
	my $tbl = (tbl($_[0]))[0]; # get table name
	my $tblfile = (tbl($_[0]))[1]; # get table name
	my $setwh = $_[0]; # set what
	my $setto = $_[0]; # set what to set to value
	$setwh =~ s/^up.* table .* set ([a-z0-9_-]+).*/$1/;
	$setto =~ s/^update table ([a-z0-9_-]+) set ([a-z0-9_-]+) = ["']?([^ ;"']+).*/$3/;
	#$setto =~ s/([@$])/\\$1/g; # escape special characters.
	my @upd = sel($_[0],"");
	open(TBL,$tblfile); # TODO CHECK ALL OPENS FOR TABLE EXISTENCE!
	my $desc = scalar <TBL>;
	my $i = 0;
	my $col = -1; # get the column number:
	foreach(split(/,/,$desc)){
		chomp $_;
		my $const = $_; # constraint
		my $moddesc = $_;
		$moddesc =~ s/^([a-z0-9_-]+).*/$1/i; # i believe rtthat i mat be too drunk to carryu pon tonight.
		#print "MODDEST: " . $moddesc . " SETWH: " . $setwh . "\n";
		if($moddesc eq $setwh){
			$col = $i;
			if($const =~ m/(primary|foreign) key/){
				error("DB","cannot update a key element");
				return 1; # TODO check entanglement.csv and allow changing foreign keys!
				last;
			}
		}
		$i++;
	}
	while(<TBL>){ # update table userpk set id = 1 where id = 9;
		my $line;
		my $num = int($.);
		if (grep(/$num/,@upd)){
			my @rec = split(/,/,$_);
			for(my $i=0;$i<=$#rec;$i++){
				if($i == $col){
					$rec[$i] = $setto;
				}
				$line .= $rec[$i] . ","; # we changed the line, add it to the pile
			}
			$line =~ s/,$//;
			push(@recs,$line); # put int the modified line.
		}else{ # leave this record untouched
			push(@recs,$_);
		}
	}
	close TBL;
	open(TBL,">$tblfile");
	print TBL $desc;
	foreach(@recs){
		print TBL $_;
	}
	close TBL;
}

sub trunc($){
	my $tblfile = (tbl($_[0]))[1];
	open(TBL,$tblfile); # whoa
	my $desc = scalar <TBL>;
	close TBL;
	open(TBL,">$tblfile");
	print TBL $desc;
	close TBL;
}

sub del($){
	my $delcmd = $_[0];
	my @del = sel($_[0],"");
	if($#del < 0){
		msg("no records changed");
		return 0; # nothing to do
	}
	my @recs;
	my $tbl = (tbl($_[0]))[0];
	my $tblfile = (tbl($_[0]))[1]; # cool syntax
	# print "table: " . $tbl . " file: " . $tblfile . "\n";
	open(TBL,$tblfile);
	while(<TBL>){ # open and read table
		push(@recs,$_) if(!grep(/$./,@del)); # line number NOT in @del numbers
	}
	close TBL;
	open(TBL,">$tblfile"); # open and rewrite table
	print TBL $_ foreach(@recs);
	close TBL; # all done;
	msg(int($#del+1)." records removed from table.");
	return 0;
}

sub tbl($){ # pull out the table and return an array of it and the path to it
	my $tbl = $_[0];
	$tbl =~ s/^.* (from|table) ([a-z0-9_-]+).*/$2/i;
	my @tbl;
	push(@tbl,$tbl);
	push(@tbl,"db_".$db."/tables/".$tbl.".tbl");
	return @tbl; # [0] = tablname, [1] = filepath
}

sub whereand($){ # command, 
	my %where;
	my @where = split(/ and /,$_[0]);
	for(my $i=0;$i<=$#where;$i++){
		$where[$i] =~ s/^.* where //;
		my @tmpsplt = split(/ = /,$where[$i]);
		$tmpsplt[1] =~ s/["';]//g; # remove quotes
		$where{$tmpsplt[0]} = $tmpsplt[1];
	}
	return %where;
}

sub usedb($){
	my $dbs = $_[0]; # database selected
	$dbs =~ s/^use ([a-z0-9_-]+).*/$1/i;
	if($dbs eq "null" || $dbs eq "none"){ $db = "none"; return; }
	if (-r "db_" . $dbs){ # does it exist?
		$db = $dbs;
		msg("now using database: " . $db);
	}else{
		error("DB","database " . $dbs . " does not exist. Please check spelling and case.");
	}
	return;
}

sub createdb($){
	my $cdb = $_[0];
	$cdb =~ s/^cre.* ([a-z0-9_-]+).*/$1/i;
	msg("creating database " . $cdb);
	if(mkdir("db_".$cdb) && mkdir("db_".$cdb."/tables/")){
		msg("database creation successful");
	}else{
		error("FSE","could not create database files");
	}
	return;
}

sub createtbl($){
	if($db eq ""){ # no database selected
		error("DB","no database selected to store new table");
		return;
	}
	my $tbl = $_[0];
	$tbl =~ s/^create table ([a-z0-9_-]+).*/$1/;
	my $desc = $_[0];
	my $regex = ".*".$tbl."\\((.*)\\);\$";
	$desc =~ s/$regex/$1/;
	if($desc =~ m/^create tab/i){ # good enough for now, TODO
		error("SYNTAX","descriptor is invalid for table " . $tbl);
		return;
	}
	msg("creating table " . $tbl . " with descriptor " . $desc);
	if(open(TBL,">db_".$db."/tables/".$tbl.".tbl")){ # tbl extension
		print TBL $desc . "\n";
		close TBL;
	}else{
		error("FSE","could not create table file in database " . $db);
	}	
	return;
}

sub show($){
	if($db eq ""){
		error("DB","no database selected to show items");
		return;
	}
	my $what = $_[0];
	$what =~ s/^show ([a-z]+).*/$1/;
	msg("showing ".$what." in ".$db);
	if($what ne "tables"){
		error("SYNTAX","what should I show you?");
		return;
	}elsif($what eq "tables"){
		if(opendir(DB,"db_".$db."/tables/")){
		n();
			while(my $tbl = readdir(DB)){
				$tbl =~ s/\.tbl//;
				if($tbl !~ m/^\./){
					printf(" %s \n",$tbl);
				}
			}
		n();
		closedir(DB);
		}else{
			error("DB","database does not exist or could not be read on current filesystem");
		}
	} # all done.
	return;
}

sub desc($$){ # describe the table using it's first line descriptor
	my $desc; # decription semi-global to be returned
	my $old; # one liner description
	if($db eq ""){
		error("DB","database not yet selected, try \"use\" command or \"help use\"");
		return;
	}
	my $what = $_[0];
	$what =~ s/desc.* ([a-z0-9_-]+).*/$1/;
	if($_[1]){ # only if told to
		msg("description for " . $what);
		n();
	}
	if(open(TBL,"db_".$db."/tables/".$what.".tbl")){
		my @l = split(/,/,scalar <TBL>);
		foreach(@l){
			my $l = $_;
			chomp $l;
			$desc = $l;
			my $col = $l;
			$col =~ s/ .*//;
			$desc =~ s/^[a-z0-9_-]+ //i; # id int not null auto_increment
			print " column: " . $col . "\n   -> $desc\n" if($_[1]); # print boolean?
			$old .= $desc . ",";
		}	
		n() if($_[1]);
	}else{
		error("TBL","table ".$what." does not exist. Please check spelling and case.");
		return;
	}
	# didn't close the table to read from it.
	return $old; # one liner description
}

sub clone($){ # clone database foo as bar
	my $type = $_[0];
	$type =~ s/^clone ([a-z]+).*/$1/i;
	my $what = $_[0];
	$what =~ s/^.*(base|table) ([a-z0-9_-]+).*/$2/i;
	my $as = $_[0];
	$as =~ s/^.* as ([a-z0-9_-]+).*/$1/i;
	if($type ne "database" && $type ne "table"){
		error("NTD","cannot clone a " . $type . " please check \"help\" for syntax");
		return;
	}else{
		if($what ne "" && $as ne ""){
			if($type eq "table"){ # cloning a table (easy)
				return if chkdb();
				msg("cloning " . $type . " " . $what . " as " . $as);
				open(TBLAS,">db_".$db."/tables/".$as.".tbl");
				if(!open(TBLWH,"db_".$db."/tables/".$what.".tbl")){
					error("DB","table " . $what  . " does not exist in current database. Please check spelling and case.");
					return 1;
				}
				print TBLAS $_ while(<TBLWH>);
				close TBLAS;
				close TBLWH;
				return;
			}elsif($type eq "database" or $type eq "db"){
				msg("cloning " . $type . " " . $what . " as " . $as);
				# let us do a try with just cp -R (GNU needed)
				system("cp -R db_" . $what . " db_" . $as);
				if(opendir(DIR,"db_".$as)){
					msg("database cloning completed successfully for " . $as);
					closedir(DIR); # close her up
				}else{
					error("FSE","could not write to dbms root");
				}
			}
		}else{ # TODO: add specifics!
			error("SYNTAX","please check \"help\" for proper syntax");
			return;
		}
	}
}

sub drop($){
	my $type = $_[0]; # type of thing to drop
	my $what = $_[0]; # drop what?
	$type =~ s/^drop ([a-z]+) .*/$1/i;
	$what =~ s/^.*p ([a-z]+) ([a-z0-9_-]+).*/$2/i;
	if($type ne "table" && $type ne "database" && $type ne "db"){
		error("SYNTAX","i cannot drop a " . $type . " please check \"help\" for syntax");
		return 1;
	}
	msg("dropping " . $type . " " . $what);
	if($type eq "table"){
		return if chkdb(); # no database set
		if(unlink "db_".$db."/tables/".$what.".tbl"){
			msg("table file unlinked from filesystem successfully");
		}else{
			error("FSE","could not unlink table file, permission error?");
			return 1;
		}
	}else{
		opendir(DH,"db_".$what."/tables/");
		my @tbls = readdir DH;
		closedir DH;	
		foreach(@tbls){ unlink "db_".$what."/tables/".$_; } # remove all tables, add more files if db dir grows.
		rmdir "db_".$what."/tables/"; # remove tables directory
		rmdir ("db_".$what); # remove parent directory
	}
	return;
}

sub insert($){ # insert into users values(NULL,"4nalysis","analytical@wnl.com");
	my $tbl = $_[0]; # whole command
	chomp $tbl;
	my $valine = $tbl; # values string
	$tbl =~ s/.* into ([^ ]+).*/$1/;
	my $table = "db_".$db."/tables/".$tbl.".tbl";
	if(!open(TBL,">>$table")){
		error("DB","table " . $tbl . " does not exist. Please check spelling and case.");
		return 1;
	}
	$valine =~ s/.*alues\(([^\)]+)\);/$1/; # Values to insert
	my @vals = split(/,/,$valine); # get each value for validation
	my @const = split(/,/,desc($tbl,0)); # int not null auto_increment,varchar(15),varchar(35),
	if($#vals != $#const){ # value count is wrong
		error("DB","you have entered the wrong number of values, there should be: " . int($#const+1) . " for table " . $tbl); # TODO get numbers and compare
		return 1;
	}else{
		for(my $i=0;$i<=$#vals;$i++){ # check constraints
			if($const[$i] =~ m/int/i && $vals[$i] !~ m/\D/ && $const[$i] !~ m/auto_increment/i){ # \D negates integer
				if($const[$i] =~ m/(primary|foreign) key/i){
					if(chkkey($table,$i,$vals[$i])){
						return 1;
					}else{
						next;
					}
				}
			}elsif($const[$i] =~ m/auto_increment/i && $vals[$i] eq "NULL" && $const[$i] =~ m/not null/i){
				$vals[$i] = 0; # this is a new or truncated table (DEFAULT)
				while(<TBL>){ # get last value
					my @rec = split(/,/,$_);
					$vals[$i] = int($rec[$i])+1; # just keep grabbing the value until last record
				} # no next, we just wanted to set the "next" value, we can check if key later
			}elsif($const[$i] =~ m/not null/i && $vals[$i] eq "NULL" && $const[$i] !~ m/auto_increment/i){
				error("DB","data insertion failed. the value entered for column " . int($i+1) . " cannot be NULL");
				return 1; # i KNOW this will heppen to someon at some point
			}elsif($const[$i] =~ m/auto_increment/i && $vals[$i] ne "NULL"){ # integer specified when shouldn't be.
				error("DB","this is an auto incremented value constraint, specify \"NULL\" to insert next value");
				return 1;
			}elsif($const[$i] =~ m/varchar/i && $vals[$i] =~ m/^("|').*("|')$/){
				$vals[$i] =~ s/["']//g; # drop the quotes
				my $max = $const[$i];
				$max =~ s/.*\(([0-9]+).*/$1/; # make integer
				$max = int($max);
				if(length($vals[$i]) <= $max){ # length constraint
					next;
				}else{ # rather than truncate, error out.
					error("DB","data insertion failed. the length of data you've entered for column " . int($i+1) . " is not correct");
					return 1;
				}
			}elsif($const[$i] =~ m/(primary|foreign) key/i){ # a data key (MUST be unique
				if(chkkey($table,$i,$vals[$i])){
					return 1; # alreday notified of error
				}else{
					next; # key is unique
				}
			}else{
				error("DB","data insertion failed. the value entered for column " . int($i+1) . " is not correct");
				return 1;
			}
		}
		close TBL;
		open(TBL,">>$table");
		my $record;
		$record .= $_ . "," foreach(@vals);
		$record =~ s/,$//; # tailgater!
		print TBL $record . "\n"; # insert it :)
		close TBL;
	}
	msg("record successfully inserted.");
	return 0;
}

sub chkkey($$$){ # pass me the filename, value of iterator, and the key
	my @keys;
	my $file = $_[0]; # the table file
	my $col  = $_[1]; # the iterator
	my $key  = $_[2]; # the key we want to INSERT
	close(TBL); # in case we have read it
	open(TBL,$file); # open the table
	while(<TBL>){ # it's okay to push in the constraint value too
		my @rec = split(/,/,$_); # split up each record
		push (@keys,$rec[$col]); # get all keys for this column
	}
	close TBL;
	if(grep($key,@keys)){ # if it is in the @keys, fail.
		error("DB","this \"key\" value already exists.");
		return 1;
	}else{
		return 0;
	}
}

### GENERIC COMMANDS: ###
sub retdate(){ # for logging and prompt
	my @date = localtime;
	for(my $i=0;$i<=2;$i++){ # only use 0,1,2 elements
		$date[$i] = "0" . $date[$i] if(length($date[$i]) < 2);
	}
	return $date[2] . ":" . $date[1] . ":" . $date[0];
}
sub msg($){
	printf(" -> %s\n",$_[0]);
	return;
}

sub error($$){ # printing to STDERR
	print STDERR (" -> There was an error of type: " . $_[0] . " \n -> MSG: " . $_[1] . "\n");
	return 1;
}

sub help($){
	n();
	my $what = $_[0];
	my $hb = 0; # help boolean
	$what =~ s/^help\s?([a-z0-9_;-]+)?/$1/i;
	$what =~ s/;$//;
	if($what eq ""){ # generic help:
		if(open(CMNL,"manual/commands.csv")){
			printf(" == SHIELDDB SQL COMMANDS ==\n\n");
			while(<CMNL>){
				my @l = split(/,/,$_);
				printf(" -> %s\n",shift(@l)); # grab the first line
				foreach(@l){ # the rest of the line
					my $l = $_;
					$l =~ s/_/,/g; # because we can't edit $_ - fooey!
					$l =~ s/auto,increment/auto_increment/; # dirty fix for now
					printf("\t=> %s\n",$l);
				}
				$hb = 1;
			}
			close(CMNL);
		}else{
			error("FSE","missing commands manual");
		}
	}else{
		if(open(CMNL,"manual/commands.csv")){
			while(<CMNL>){
				my @l = split(/,/,$_);
				if($l[0] eq $what){
					$hb = 1;
					printf(" -> %s\n",shift(@l)); # grab the first line
					foreach(@l){ # the rest of the line
						my $l = $_;
						$l =~ s/_/,/g; # because we can't edit $_ - fooey!
						$l =~ s/auto,increment/auto_increment/; # dirty fix for now
						printf("\t=> %s\n",$l);
					}
				}
			}
		}else{
			error("FSE","missing commands manual");
		}
	}
	if(!$hb){
		printf(" no help for " . $what . "\n");
	}
	return;
}

sub chkdb(){
	if($db eq ""){
		error("DB","please first choose a database");
		return 1;
	}
}

sub man() { # manual output from "--help" or "-h"
        if(open(CMNL,"manual/commands.csv")){
                printf(" == SHIELDDB SQL COMMANDS ==\n\n");
                while(<CMNL>){
                        my @l = split(/,/,$_);
                        printf(" -> %s\n",shift(@l)); # grab the first line
                        foreach(@l){ # the rest of the line
                                my $l = $_;
                                $l =~ s/_/,/g; # because we can't edit $_ - fooey!
                                $l =~ s/auto,increment/auto_increment/; # dirty fix for now
                                printf("\t=> %s\n",$l);
                        }
                }
                close(CMNL);
        }else{
                error("FSE","missing commands manual");
        }
	return;
}

sub n(){
	printf("\n");
}
sub quit(){
	# clean up files here
	exit;
}
END{
	printf("Goodbye\n");
}
