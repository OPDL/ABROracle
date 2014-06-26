#!/usr/bin/perl

#  ddl_oracle.pl
# jared still
# jkstill@cybcon.com

use DBI;
use DDL::Oracle;
use PDBA::ConfigFile;
use PDBA::OPT;
use PDBA::GQ;
use PDBA::CM;
use PDBA::DBA;
use strict;

use Getopt::Long;

our %optctl = ();

Getopt::Long::GetOptions(
	\%optctl, 
	"machine=s",
	"database=s",
	"username=s",
	"password=s",
	"conf=s",
	"verbose!",
	"z","h","help"
);

if ( $optctl{h} || $optctl{z} || $optctl{help} ) { usage(0) }

my $username;

if ( ! defined($optctl{database}) ) {
	warn "database required\n";
	usage(1);
}

if ( ! defined($optctl{username}) ) {
	warn "username required\n";
	usage(1);
}

my $password = undef;

if ( defined( $optctl{password} ) ) {
	$password = $optctl{password};
} else {

	if (
		! defined($optctl{machine})
		|| ! defined($optctl{database})
		|| ! defined($optctl{username})
	) { usage(1) }

	$password = PDBA::OPT->pwcOptions (
		INSTANCE => $optctl{database},
		MACHINE => $optctl{machine},
		USERNAME => $optctl{username}
	);
}

$optctl{conf} = 'exp_exclude.conf' unless $optctl{conf};

unless ( new PDBA::ConfigLoad( FILE => $optctl{conf} ) ) {
	warn "Config file $optctl{conf} not loaded\n";
}

my $dbh = new PDBA::CM(
	DATABASE => $optctl{database},
	USERNAME => $optctl{username},
	PASSWORD => $password,
);

DDL::Oracle->configure(
	dbh => $dbh,
	heading => 0
);

$|++;

print STDERR "Building List\n";

# type
# owner
# sql
# save file name

my $usersToExclude = 
	defined @expexclude::users 
	? "'" . join("','",@expexclude::users) . "'" 
	: q{'SYS'};

my $rolesToExclude = 
	defined @expexclude::roles 
	? "'" . join("','",@expexclude::roles) . "'" 
	: q{'DBA'};

my %objlist  = (

	tablespaces => [
		'tablespace',
		'tablespaces',
		q{
			select tablespace_name, tablespace_name
			from dba_tablespaces
			where tablespace_name not in ('SYSTEM')
		},
		'2_tbs_ddl.sql'
	],

	rollback_segments => [
		'rollback segment',
		'rollback segments',
		q{
			select segment_name, segment_name
			from dba_rollback_segs
		},
		'3_rbs_ddl.sql'
	],

	public_db_links => [
		'database link',
		'public database links',
		q{
			select owner, db_link
			from dba_db_links
			where owner = 'PUBLIC'
		},
		'4_pub_db_link.sql'
	],

	public_synonyms => [
		'synonym',
		'public synonyms',
		q{
			select owner, synonym_name
			from dba_synonyms
			where owner = 'PUBLIC'
			and table_owner not in ( }
		. $usersToExclude .
		q{)},
		'5_pub_synonyms.sql'
	],

	profiles => [
		'profile',
		'profiles',
		q{
			select distinct 'PROFILE', profile
			from dba_profiles
			where profile != 'DEFAULT'
		},
		'6_user_profiles.sql'
	],

);

my $sth;

my @masterScripts;

for my $key ( sort keys %objlist ) {

	if ( $optctl{verbose} ) {
		print "key: $key\n";
		print "\ttype: $objlist{$key}->[0]\n";
		print "\tsql: $objlist{$key}->[2]\n";
		print "\tsave file: $objlist{$key}->[3]\n";
		print "\n\n";
	}

	#	Create a list of one or	more objects
	$sth = $dbh->prepare( $objlist{$key}->[2] );

	$sth->execute;
	my $list = $sth->fetchall_arrayref;

	my $obj =	DDL::Oracle->new(
		type	=> $objlist{$key}->[0],
		list	=> $list,
	);

	print STDERR "working on $objlist{$key}->[1]\n";

	my $ddl = $obj->create; 

	open(DDL, qq(+>$objlist{$key}->[3])) || die "cannot create $objlist{$key}->[3] - $!\n";
	push @masterScripts, $objlist{$key}->[3];

	print DDL $ddl;

}

print STDERR "working on users\n";
# use the PDBA:DBA ddl method for users
# to get just the user create statement
my $userList = new PDBA::GQ( $dbh,'dba_users',
	{
		WHERE => 'username not in (' . join(',', split(//,'?' x ($#expexclude::users + 1)) ) . ')',
		BINDPARMS => \@expexclude::users
	}
);

my %userScripts = ();

my $userDdlFile = '8_user_ddl.sql';

open(DDL, qq(+> $userDdlFile)) || die "cannot create $userDdlFile - $!\n";
push @masterScripts, $userDdlFile;

# get schema and grants
while ( my $row = $userList->next({}) ) {

	print STDERR "working on $row->{USERNAME}\n";

	# get user create DDL
	my $userObj = new PDBA::DBA(
		DBH => $dbh,
		OBJECT => $row->{USERNAME},
		OBJECT_TYPE => 'user'
	);

	my $ddl = $userObj->ddl;
	print DDL "$ddl\n\n";

	# get DDL to create the users schema
	my $schemaFile = "9_schema_" . lc($row->{USERNAME}) . ".sql";
	open(SCHEMA,qq(+> $schemaFile)) || die "could not create $schemaFile - $!\n";

	my @schemaName = [$row->{USERNAME}];
	my $schemaObj =   DDL::Oracle->new(
		type  => 'schema',
		list  => \@schemaName
	);

	my $schemaDDL = $schemaObj->create;
	print SCHEMA $schemaDDL;

	# get DDL for all GRANTs made by this user
	my $grantFile = "10_grant_" . lc($row->{USERNAME}) . ".sql";
	open(GRANTS,qq(+> $grantFile)) || die "could not create $grantFile - $!\n";

	@{$userScripts{$row->{USERNAME}}} = ($schemaFile, $grantFile);

	my $grantObj = new PDBA::DBA(
		DBH => $dbh,
		OBJECT => $row->{USERNAME},
		OBJECT_TYPE => 'privsbygrantor'
	);

	my $grantDDL = $grantObj->ddl;
	
	print GRANTS $grantDDL;

}

print STDERR "working on roles\n";
# use the PDBA:DBA ddl method for roles

my $roleList = new PDBA::GQ( $dbh,'dba_roles',
	{
		WHERE => 'role not in (' . join(',', split(//,'?' x ($#expexclude::roles + 1)) ) . ')',
		BINDPARMS => \@expexclude::roles
	}
);

my $roleScript = '7_role_ddl.sql';
open(DDL, qq(+> $roleScript)) || die "cannot create $roleScript - $!\n";
push @masterScripts, $roleScript;

while ( my $row = $roleList->next({}) ) {

	print STDERR "working on $row->{ROLE}\n";

	my $roleObj = new PDBA::DBA(
		DBH => $dbh,
		OBJECT => $row->{ROLE},
		OBJECT_TYPE => 'role'
	);

	my $ddl = $roleObj->ddl;
	print DDL "$ddl\n\n";

}

my $masterScript = "1_create.sql";
open(MASTER, qq(+> $masterScript)) || die "cannot create $masterScript - $!\n";

print MASTER '@@', join("\n".'@@', sort @masterScripts ), "\n";

foreach my $username ( keys %userScripts ) {
	print MASTER qq{
prompt connecting to $username - please enter the password
connect $username
\@\@$userScripts{$username}->[0]
\@\@$userScripts{$username}->[1]
};
}

$sth->finish;
$dbh->disconnect;

sub usage {
	my $exitVal = shift;
	use File::Basename;
	my $basename = basename($0);
	print qq/
$basename

usage: $basename 

-machine  database_server 
-database database 
-username dba account 
-password dba password ( optional )
-conf     configuration file - default is exp_exclude.conf

/;
	exit $exitVal;
};



