#!/usr/bin/perl -w
#
# Reboot of shieldb file
# 10.05.2013
# weaknetlabs@gmail.com
#
use strict;

# global variables
my @ARGV; # reserved
my $db = "";

# Subroutine prototypes
sub prompt();
sub cmd($);
sub msg($);
sub createdb($);
sub createtbl($);
sub show($);
sub error($$);
sub help($);
sub quit();
sub n();
sub desc($);
sub sel($);
sub format($$);

if(!$ARGV[0]){
	prompt() while (1);
}

sub prompt(){
	my $dbn = $db;
	$dbn = "none" if($dbn eq "");
	printf("ShieldDB:(%s)> ",$dbn);
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
		createtbl($cmd);
	}elsif($cmd =~ m/^show /i){
		show($cmd);
	}elsif($cmd =~ m/^describe /i){
		desc($cmd);
	}elsif($cmd =~ m/^select /i){
		sel($cmd);
	}


	else{
		error("DBMS","command not yet implemented");
	}
}

### SQL COMMANDS ###

sub sel($){
	my @what;    # array of what columns were queried
	my @whatnum; # array of intger place holders
	my $what  = $_[0];
	my $table = $_[0];
	my %tblhash; # hash of columnname => integer
	$what =~ s/^select ([a-z0-9_,*-]+).*/$1/i;
	$table =~ s/.*from ([a-z0-9_,-]+).*/$1/i;
	@what = split(/,/,$what) if($what =~ m/,/); # do we have multiple columns specified?
	if($what !~ /,/ && $what ne "*"){
		push(@what,$what);
	}
	open(TBL,"db_".$db."/tables/".$table.".tbl") || die;
	my @desc = split(/,/,scalar <TBL>);
	for(my $i=0;$i<=$#desc;$i++){
		$desc[$i] =~ s/^([a-z0-9_-]+) .*/$1/;
		chomp $desc[$i];
		if(grep(/$desc[$i]/,@what) or $what eq '*'){ # we want this column
			push(@whatnum,$i); # 0,1,2,etc...
		}
	}
	while(<TBL>){
		my $cl = $_;
		chomp $cl;
		my @line = split(/,/,$cl);
		for(my $i=0;$i<=$#line;$i++){
			if(grep(/$i/,@whatnum)){
				print $line[$i] . ",";
			}else{
				# THAIR SHOUL BE NO ELSE!!!
			}
		}
		n();
	}
}

sub format($$){ # format(column length,value length);
	my $string = "-"; 
	$string .= "+"; # add a plus at the end
	return $string; # e.g. "------------+" per column
}

sub usedb($){
	# grab the database from the command
	my $dbs = $_[0]; # database selected
	$dbs =~ s/^use ([a-z0-9_-]+).*/$1/i;
	# check for existence:
	if (-r "db_" . $dbs){
		$db = $dbs;
		msg("now using database: " . $db);
	}else{
		error("DB","database " . $dbs . " does not exist");
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

sub desc($){ # describe the table using it's first line descriptor
	my $desc; # decription semi-global to be returned
	if($db eq ""){
		error("DB","database not yet selected, try \"use\" command or \"help use\"");
		return;
	}
	my $what = $_[0];
	$what =~ s/desc.* ([a-z0-9_-]+).*/$1/;
	msg("description for " . $what);
	n();
	if(open(TBL,"db_".$db."/tables/".$what.".tbl")){
		my @l = split(/,/,scalar <TBL>);
		foreach(@l){
			chomp $_;
			$desc = $_;
			my $col = $_;
			$col =~ s/ .*//;
			$desc =~ s/^[a-z0-9_-]+ //i; # id int not null auto_increment
			print " " . $col . "\n\t-> $desc\n";
		}	
		n();
	}else{
		error("TBL","table ".$what." does not exist");
		return;
	}
	return $desc;
}

### GENERIC COMMANDS: ###
sub msg($){
	printf(" -> %s\n",$_[0]);
	return;
}

sub error($$){ # i realize this could be msg($) with an extra arg
	printf(" -> There was an error of type: %s\n -> MSG: %s\n",$_[0],$_[1]);
	return;
}

sub help($){
	n();
	my $what = $_[0];
	my $hb = 0; # help boolean
	$what =~ s/^help\s?([a-z0-9_;-]+)/$1/i;
	if($what eq ";"){ # generic help:
		if(open(CMNL,"manual/commands.csv")){
			printf(" == SHIELDDB SQL COMMANDS ==\n\n");
			while(<CMNL>){
				my @l = split(/,/,$_);
				printf(" -> %s\n",shift(@l)); # grab the first line
				foreach(@l){ # the rest of the line
					printf("\t=> %s\n",$_);
				}
			}
			close(CMNL);
		}else{
			error("FSE","missing commands manual");
		}
	}else{
		$what =~ s/;$//; # get rid of syntax lol
		if(open(CMNL,"manual/commands.csv")){
			while(<CMNL>){
				my @l = split(/,/,$_);
				if($l[0] eq $what){
					$hb = 1;
					printf(" -> %s\n",shift(@l)); # grab the first line
					foreach(@l){ # the rest of the line
						printf("\t=> %s\n",$_);
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
sub n(){
	printf("\n");
}
sub quit(){
	printf("Goodbye\n");
	# clean up files here
	exit;
}
