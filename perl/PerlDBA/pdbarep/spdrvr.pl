#!/usr/bin/perl -w

use warnings;
use strict;
use PDBA::CM;
use PDBA::OPT;
use PDBA::ConfigFile;
use Getopt::Long;

my %optctl=();

# passthrough allows additional command line options
# to be passed to PDBA::OPT if needed
Getopt::Long::Configure(qw{pass_through});

# if you add new tags you will need to enter the new command
# line options here.

GetOptions( \%optctl,
	"help!",
	"machine=s",
	"database=s",
	"username=s",
	"password=s",
	"verbose!",
	"file=s",
	"report_list!",
	"rep_report=s",
	"rep_database=s",
	# report options
	"rep_end_date=s",
	"rep_grantee=s",
	"rep_grantor=s",
	"rep_granted_role=s",
	"rep_index_name=s",
	"rep_object_owner=s",
	"rep_object_name=s",
	"rep_parm_name=s",
	"rep_parm_value=s",
	"rep_pagesize=i",
	"rep_privilege=s",
	"rep_profile=s",
	"rep_resource_type=s",
	"rep_resource_name=s",
	"rep_role=s",
	"rep_schema=s",
	"rep_sequence_name=s",
	"rep_start_date=s",
	"rep_table_name=s",
	"rep_table_owner=s",
	"rep_tablespace_name=s",
	"rep_username=s",
);

if ( $optctl{help} ) { usage(1) }

my $t = new PDBA::ConfigLoad( FILE => 'pdbarepq.conf' );
# show available reports and exit
$optctl{report_list} = defined $optctl{report_list} ? $optctl{report_list} : 0;
if ( $optctl{report_list} ) {
	foreach my $report ( sort keys %pdbarepq::reports ) {
		print $pdbarepq::reports{$report}->{description}
	}
	print "\n";
	exit;
}

my $password = '';
if ( defined $optctl{password} ) {
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

# get the start/end dates if needed
if ( ! defined($optctl{rep_start_date}) ) {
	$optctl{rep_start_date} = pdbarepq->startDate;
}

if ( ! defined($optctl{rep_end_date}) ) {
	$optctl{rep_end_date} = pdbarepq->endDate;
}

my $dbh = new PDBA::CM(
	DATABASE => $optctl{database},
	USERNAME => $optctl{username},
	PASSWORD => $password,
);

my $rptDateHash = pdbarpt->rptDatePk (
	$dbh,
	DATABASE => $optctl{database},
	USERNAME => $optctl{username},
	PASSWORD => $password,
	REP_DATABASE => $optctl{rep_database} ? $optctl{rep_database} : '%',
	START_DATE => $optctl{rep_start_date},
	END_DATE => $optctl{rep_end_date},

);

$dbh->disconnect;

if ( $optctl{verbose} ) {
	print "start date pk: $rptDateHash->{startDatePk}\n";
	print "start date   : $rptDateHash->{startDate}\n";
	print "end   date pk: $rptDateHash->{endDatePk}\n";
	print "end   date   : $rptDateHash->{endDate}\n";
}


# unset SQLPATH if the login.sql script is located
# there and you don't wish to run it
delete $ENV{SQLPATH} if exists $ENV{SQLPATH};

# this line simply keeps perl from complaining about this hash
# comment out to see for your self
if ( defined %pdbarepq::reports ){}
my $spscript = $pdbarepq::reports{$optctl{rep_report}}->{script};
#print "SP: $spscript\n";

unless ( defined $spscript ) {
	warn "query $optctl{rep_report} not defined\n";
	usage(1);
}

# if you add new tags, you will need to modify this hash
# with instructions detailing how the tag should be handled

my %tagHash = (
	'<<END_DATE_PK>>'			=> $rptDateHash->{endDatePk},
	'<<END_DATE>>'				=> $rptDateHash->{endDate},
	'<<GLOBAL_NAME>>'			=> defined $optctl{rep_database} ? uc( $optctl{rep_database}) : '%',
	'<<GRANTED_ROLE>>'		=> defined $optctl{rep_granted_role} ? uc ( $optctl{rep_granted_role} ) : '%',
	'<<GRANTEE>>'				=> defined $optctl{rep_grantee} ? uc( $optctl{rep_grantee} ) : '%',
	'<<GRANTOR>>'				=> defined $optctl{rep_grantor} ? uc( $optctl{rep_grantor} ) : '%',
	'<<LOGIN_DATABASE>>'		=> $optctl{database},
	'<<LOGIN_PASSWORD>>'		=> $password,
	'<<LOGIN_USERNAME>>'		=> $optctl{username},
	'<<INDEX_NAME>>'			=> defined $optctl{rep_index_name} ?  uc($optctl{rep_index_name}) : '%',
	'<<OBJECT_OWNER>>'		=> defined $optctl{rep_object_owner} ? uc ( $optctl{rep_object_owner} ) : '%',
	'<<OBJECT_NAME>>'			=> defined $optctl{rep_object_name} ? uc ( $optctl{rep_object_name} ) : '%',
	'<<OWNER>>'					=> defined $optctl{rep_schema} ?  uc($optctl{rep_schema}) : '%',
	'<<PAGESIZE>>'				=> defined $optctl{rep_pagesize} ? uc ( $optctl{rep_pagesize} ) : '60',
	'<<PARM_NAME>>'			=> defined $optctl{rep_parm_name} ? uc ( $optctl{rep_parm_name} ) : '%',
	'<<PARM_VALUE>>'			=> defined $optctl{rep_parm_value} ? uc ( $optctl{rep_parm_value} ) : '%',
	'<<PRIVILEGE>>'			=> defined $optctl{rep_privilege} ? uc ( $optctl{rep_privilege} ) : '%',
	'<<PROFILE>>'				=> defined $optctl{rep_profile} ?  uc($optctl{rep_profile}) : '%',
	'<<RESOURCE_NAME>>'		=> defined $optctl{rep_resource_name} ?  uc($optctl{rep_resource_name}) : '%',
	'<<RESOURCE_TYPE>>'		=> defined $optctl{rep_resource_type} ?  uc($optctl{rep_resource_type}) : '%',
	'<<SEQUENCE_NAME>>'		=> defined $optctl{rep_sequence_name} ?  uc($optctl{rep_sequence_name}) : '%',
	'<<ROLE>>'					=> defined $optctl{rep_role} ?  uc($optctl{rep_role}) : '%',
	'<<START_DATE_PK>>'		=> $rptDateHash->{startDatePk},
	'<<START_DATE>>'			=> $rptDateHash->{startDate},
	'<<TABLE_NAME>>'			=> defined $optctl{rep_table_name} ?  uc($optctl{rep_table_name}) : '%',
	'<<TABLE_OWNER>>'			=> defined $optctl{rep_table_owner} ?  uc($optctl{rep_table_owner}) : '%',
	'<<TABLESPACE_NAME>>'	=> defined $optctl{rep_tablespace_name} ?  uc($optctl{rep_tablespace_name}) : '%',
	'<<USERNAME>>'				=> defined $optctl{rep_username} ?  uc($optctl{rep_username}) : '%',
);

foreach my $tag ( keys %tagHash ) {
	$spscript =~ s/$tag/$tagHash{$tag}/gm;
}

# open the sqlplus pipe
# simple, eh?

my $tmpSqlFile = '';

if ( 'unix' eq PDBA->osname ) {
open(SP, qq{sqlplus  -s << EOF $spscript
EOF|}) || die "cannot open sqlplus pipe - $! \n";
} else {

	use POSIX;
	$tmpSqlFile = 'C:\TEMP' . POSIX::tmpnam() . 'sql';
	open(SQL,"> $tmpSqlFile" ) || die "cannot create SQL file $tmpSqlFile - $! \n";
	print SQL $spscript;
	print SQL "\nexit\n\n";
	close SQL;
	open(SP, qq{sqlplus -s \@$tmpSqlFile |}) || die "cannot create Win32 sqlplus pipe - $! \n";
}

if ( $optctl{file} ) {
	open(FILE,"+>$optctl{file}") || die "could not write to $optctl{file} - $!\n";
	*STDOUT = *FILE;
}

while(<SP>){ print }

close SP;

unlink $tmpSqlFile unless 'unix' eq PDBA->osname;

print "spscript: $spscript\n" if $optctl{verbose};

## end of main program ##


sub usage {
	my $exitVal = shift;
	use File::Basename;
	my $basename = basename($0);
	print qq/
$basename

usage: $basename 

  -machine              server where repository database resides
  -database             database repository is in
  -username             repository schema
  -file                 output to file <file_name>
  -verbose              print SQL 
  -report_list          list available reports to console
  -rep_report           which report to run
  -rep_database         which database ( global_name ) to report on
  ** report parameters **
  -rep_end_date         end date for report ( not all reports use this )
  -rep_grantee          grantee of privileges
  -rep_grantor          grantor of privileges
  -rep_granted_role     role granted
  -rep_index_name       which index to report on
  -rep_object_owner     owner of database object
  -rep_object_name      name of database object
  -rep_pagesize         control the sqlplus pagesize
  -rep_parm_name        name of database parameter
  -rep_parm_value       value of database parameter
  -rep_privilege        privilege granted
  -rep_profile          profile name
  -rep_resource_type    profile resource type
  -rep_resource_name    profile resource name
  -rep_role             which role to report on
  -rep_schema           which schema to report on
  -rep_sequence_name    name of sequence to report
  -rep_start_date       start date for report ( not all reports use this )
  -rep_table_name       which table to report on
  -rep_table_owner      which table owner to report on
  -rep_tablespace_name  which tablespace to report on
  -rep_username         which username to report on

/;
	exit $exitVal;
};


package pdbarpt;

sub rptDatePk {

	my ($self, $dbh, %args) = @_;

	my $nlsDateFormat = pdbarepq->nlsDateFormat;

	use PDBA::GQ;

	$dbh->do(qq{alter session set nls_date_format = '$nlsDateFormat' } );

	# get the start date
	# find the latest snapshot date LE the start date
	my $sd = new PDBA::GQ(
		$dbh,'pdba_snap_dates',
		{
			WHERE => qq{ 
				( snap_date < trunc(to_date('$args{START_DATE}','$nlsDateFormat')+1) )
				and
				( global_name like upper('$args{REP_DATABASE}%'))
			},
			ORDER_BY => "snap_date"
		}
	);

	my ($sdHash, $startDatePk, $startDate);
	my $dc = 0;
	while ( $sdHash = $sd->next ){
		$dc++;
		$startDatePk = $sdHash->{PK};
		$startDate = $sdHash->{SNAP_DATE};
	}

	# old start date, no rows retrieved
	unless ( $dc ) {
		$sd = new PDBA::GQ(
			$dbh,'pdba_snap_dates',
			{
				ORDER_BY => "snap_date"
			}
		);
		$sdHash = $sd->next;
		$startDatePk = $sdHash->{PK};
		$startDate = $sdHash->{SNAP_DATE};
		$sd->finish;
	}

	# get the end date
	# find the latest snapshot date LE the end date
	my $ed = new PDBA::GQ(
		$dbh,'pdba_snap_dates',
		{
			WHERE => qq{
				( snap_date <= trunc(to_date('$args{END_DATE}','$nlsDateFormat')+1))
				and
				( global_name like upper('$args{REP_DATABASE}%'))
			},
			ORDER_BY => "snap_date"
		}
	);

	my ($edHash, $endDatePk, $endDate);
	while ( $edHash = $ed->next ){
		$endDatePk = $edHash->{PK};
		$endDate = $edHash->{SNAP_DATE};
	}

	print "RPT: start pk    $startDatePk\n";
	print "RPT: start date  $startDate\n";
	print "RPT:   end pk    $endDatePk\n";
	print "RPT:   end date  $endDate\n";


	my %rptDatePk = (
		startDatePk => $startDatePk,
		startDate => $startDate,
		endDatePk => $endDatePk,
		endDate => $endDate,
	);

	return bless \%rptDatePk, $self;
}


