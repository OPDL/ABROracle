#!/usr/bin/perl -w

use warnings;
use strict;
no strict 'vars';
use PDBA::CM;
use PDBA::GQ;
use PDBA::OPT;
use Getopt::Long;

my %optctl=();

# passthrough allows additional command line options
# to be passed to PDBA::OPT if needed
Getopt::Long::Configure(qw{pass_through});

GetOptions( \%optctl,
	"help!",
	"machine=s",
	"database=s",
	"username=s",
	"password=s",
	"rep_machine=s",
	"rep_database=s",
	"rep_username=s",
	"rep_password=s",
	"verbose!"
);

if ( $optctl{help} ) { usage(1) }

$optctl{verbose} ||= '';
$verbose = $optctl{verbose};

my $password;

if ( defined $optctl{password} ) {
	$password =  $optctl{password};
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

#print "Password: $password\n";

my $repPassword;
if ( defined $optctl{rep_password} ) {
	$repPassword =  $optctl{rep_password};
} else {

	if (
		! defined($optctl{rep_machine})
		|| ! defined($optctl{rep_database})
		|| ! defined($optctl{rep_username})
	) { usage(1) }

	$repPassword = PDBA::OPT->pwcOptions (
		INSTANCE => $optctl{rep_database},
		MACHINE => $optctl{rep_machine},
		USERNAME => $optctl{rep_username}
	);

}


#print "REP Password: $repPassword\n";

my $dbh = new PDBA::CM(
	DATABASE => $optctl{database},
	USERNAME => $optctl{username},
	PASSWORD => $password,
);

my $repDbh = new PDBA::CM(
	DATABASE => $optctl{rep_database},
	USERNAME => $optctl{rep_username},
	PASSWORD => $repPassword,
);

my %tabHash = (
	PDBA_INDEXES 		=> ['DBA_INDEXES','OWNER'],
	PDBA_IND_COLUMNS 	=> ['DBA_IND_COLUMNS','INDEX_OWNER'],
	PDBA_PARAMETERS 	=> ['V$PARAMETER','ALLROWS'],
	PDBA_PROFILES 		=> ['DBA_PROFILES','ALLROWS'],
	PDBA_ROLES 			=> ['DBA_ROLES','ALLROWS'],
	PDBA_ROLE_PRIVS 	=> ['DBA_ROLE_PRIVS','ALLROWS'],
	PDBA_SEQUENCES 	=> ['DBA_SEQUENCES','SEQUENCE_OWNER'],
	PDBA_SYS_PRIVS 	=> ['DBA_SYS_PRIVS','ALLROWS'],
	PDBA_TABLES 		=> ['DBA_TABLES','OWNER'],
	PDBA_TABLESPACES 	=> ['DBA_TABLESPACES','ALLROWS'],
	PDBA_TAB_COLUMNS 	=> ['DBA_TAB_COLUMNS','OWNER'],
	PDBA_TAB_PRIVS 	=> ['DBA_TAB_PRIVS','ALLROWS'],
	PDBA_USERS 			=> ['DBA_USERS','ALLROWS'],
);

my @usersToIgnore = qw (
	SYSTEM SYS OUTLN DBSNMP ORDSYS 
	ORDPLUGINS MDSYS CTXSYS MTSSYS
);

my $repUser = uc($optctl{rep_username});
print qq{
Retrieving baseline data for database $optctl{database}
};

# get the global name
my $gn = new PDBA::GQ($dbh,'global_name');
my $gnHash = $gn->next;
my $globalName = $gnHash->{GLOBAL_NAME};
undef $gn;
undef $gnHash;

print "Global Name: $globalName\n" if $verbose;

# get the snap date and pk
my $nlsDateFormat = 'mm/dd/yyyy hh24:mi:ss';

my $sql = qq{select to_char(sysdate,'$nlsDateFormat') snap_date from dual};
my $sth = $dbh->prepare($sql);
$sth->execute;
my ($snapDate) = $sth->fetchrow_array;

# insert snap_date into repository table
$sql = qq{ insert into 
	pdba_snap_dates(snap_date,global_name) 
	values (to_date('$snapDate','$nlsDateFormat'),'$globalName')
};
$sth = $repDbh->prepare($sql);
$sth->execute;

# get the PK of just inserted snap_date
my $snapObj = new PDBA::GQ( $repDbh, 'pdba_snap_dates',
	{
		COLUMNS => ['pk'],
		WHERE => qq{ snap_date = to_date('$snapDate','$nlsDateFormat')}
	}
);
my $snapHash = $snapObj->next;
my $snapPk = $snapHash->{PK};
undef $snapObj;

print "SNAP PK: $snapPk\n" if $verbose;

foreach my $repTable ( keys %tabHash  ) {

	print "Working on Baseline for Table: $repTable\n";

	# instantiate an object for the repository table
	# and get the column names

	my $repTab = new PDBA::GQ( $repDbh, $repUser . '.' . $repTable );
	my $repColHash = $repTab->getColumns;
	undef $repTab;

	# delete columns from hash that are only in repository
	# tables and not in data dictionary table
	# this is because we are using this array to fetch
	# matching columns from the target table
	delete $repColHash->{PK};
	delete $repColHash->{GLOBAL_NAME};
	delete $repColHash->{SNAP_DATE_PK};

	my @repColNames = ();
	@repColNames = sort keys %{$repColHash};
	print "COLUMNS: ", join(':',@repColNames), "\n\n" if $verbose;

	# open a query to the dba table
	my $whereClause;
	if ( 'ALLROWS' eq $tabHash{$repTable}->[1] ) {
		$whereClause = '1=1';
	} else {
		$whereClause = qq{$tabHash{$repTable}->[1] not in ('} . join(q{','},@usersToIgnore) . "')";
	}

	my $hBaseTbl = new PDBA::GQ( 
		$dbh, $tabHash{$repTable}->[0],
		{
			COLUMNS => \@repColNames,
			WHERE => $whereClause,
		}
	);

	# build SQL with place holders
	# add 2 to the number of placeholders required
	# 1 is due to arrays being zero based
	# 1 more for the snap_date_pk column
	my $insertRepSql = qq{ insert into $repTable ( SNAP_DATE_PK, } 
		. join(',', @repColNames ) . ')';
	$insertRepSql .=  ' values (' . join(',', split('', '?' x ($#repColNames + 2) ) ) .')';

	print "SQL: $insertRepSql\n\n" if $verbose;

	my $hRepInsert = $repDbh->prepare($insertRepSql);

	my $reportHz = 100;
	my $rownum = 0;
	print "\n";
	while ( my $baseArray = $hBaseTbl->next([]) ) {
		$hRepInsert->execute($snapPk,  @{$baseArray});
		print '.' unless $rownum++ % $reportHz;
	}
	print "\n";

}

$dbh->disconnect;
$repDbh->commit;
$repDbh->disconnect;

sub usage {
	my $exitVal = shift;
	use File::Basename;
	$basename = basename($0);
	print qq/
$basename

  -machine       target database server 
  -database      target instance
  -username      target instance dba account 
  -password      target instance dba password (optional) 
  -rep_machine   repository_server 
  -rep_database  repository_database 
  -rep_username  repository username
  -rep_password  repositiory username password (optional) 

  passwords are optional only if the PWD password server is in use

/;
	exit $exitVal;
};


