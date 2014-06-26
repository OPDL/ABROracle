#!/usr/bin/perl -w

use warnings;
use strict;
use PDBA;
use PDBA::CM;
use PDBA::GQ;
use PDBA::OPT;
use PDBA::ConfigFile;
use Getopt::Long;

my $nlsDateFormat = q{mm/dd/yyyy hh24:mi};

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
	"conf=s",
	"email!",
	"verbose!",
);

if ( $optctl{help} ) { usage(1) }

# lookup the password if not on the command line
my $password = '';
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

my $configFile = $optctl{conf} ? $optctl{conf} : 'dba_jobs.conf';

# config currently only needed for email
if ( $optctl{email} ) {
	unless ( new PDBA::ConfigLoad( FILE => $configFile ) ) {
		# need latest version of PDBA::ConfigFile for this to work
		die "could not load config file $configFile\n";
	}
}

my $dbh = new PDBA::CM(
	DATABASE => $optctl{database},
	USERNAME => $optctl{username},
	PASSWORD => $password,
);

$dbh->do(qq{alter session set nls_date_format = '$nlsDateFormat'});

# get the global name
my $gn = new PDBA::GQ($dbh,'v$instance');
my $gnHash = $gn->next;
my $instanceName = $gnHash->{INSTANCE_NAME};
my $machineName = $gnHash->{HOST_NAME};
undef $gn;
undef $gnHash;

print "Instance Name: $instanceName\n" if $optctl{verbose};
print "Host Name: $machineName\n" if $optctl{verbose};

# get the system date
my $sn = new PDBA::GQ($dbh,'dual', 
	{ 
		COLUMNS => [qq{to_char(sysdate,'$nlsDateFormat') system_date}]
	}
);
my $snHash = $sn->next;
my $systemDate = $snHash->{SYSTEM_DATE};
undef $sn;
undef $snHash;

print "System Date: $systemDate\n" if $optctl{verbose};


my $gq = new PDBA::GQ ( $dbh, 'dba_jobs',
	{
		COLUMNS => [
			'schema_user', 
			'job', 
			q{to_date(to_char(last_date,'mm/dd/yyyy hh24:mi'),'mm/dd/yyyy hh24:mi') last_date},
			q{to_date(to_char(next_date,'mm/dd/yyyy hh24:mi'),'mm/dd/yyyy hh24:mi') next_date},
			'total_time',
			q{decode(broken,'N','NO','Y','YES','UNKNOWN') broken},
			'interval', 
			'failures', 
			'what', 
		],
		ORDER_BY => "schema_user, next_date"
	}
);

my $tmpFile;

if ($optctl{email}) {

	use POSIX;

	if ( 'unix' eq PDBA->osname ) {
		$tmpFile = POSIX::tmpnam();
	} else {
		$tmpFile = 'C:\TEMP' . POSIX::tmpnam() . 'tmp';
	}

	print "TMPFILE: $tmpFile\n";

	open(FILE,"> $tmpFile") || die "cannot create $tmpFile\n";
	select(FILE);

	# reset the format and format_top names, as using select(FILE)
	# will cause Perl to look for FILE and FILE_TOP
	$~ = 'STDOUT';
	$^ = 'STDOUT_TOP';

}


my $row = {};
while ( $row = $gq->next({}) ) { write }

if ($optctl{email}) {

	#email here
	close FILE;
	select(STDOUT);

	open(FILE, "$tmpFile") || die "cannot open $tmpFile for read - $!\n";
	my @msg = <FILE>;
	close FILE;
	my $msg = join('',@msg);

	my $subject = qq{DBA Jobs Report for $instanceName on host $machineName};

	# stop complaints
	no warnings;
	if ( PDBA->email($dbajobs::emailAddresses,$msg,$subject) ) {
		print "Email Sent\n";
	} else {
		warn "Error Sending Email\n";
	}
	use warnings;

	unlink $tmpFile;
}

$dbh->disconnect;

sub usage {
	my $exitVal = shift;
	use File::Basename;
	my $basename = basename($0);
	print qq/
usage: $basename

  -help       show help and exit
  -machine    which database server
  -database   which database
  -username   username to connect to
  -password   password ( optional if pwd server in use )
  -conf       configuration file ( needed for email )
  -email      send email to users in config file
  -verbose    verbosity on

/;
	exit $exitVal;
};

format STDOUT_TOP =

                                  DBA Jobs Status
Database: @<<<<<<<<<<<<<<<
$instanceName
Date: @<<<<<<<<<<<<<<<<<<<<
$systemDate

SCHEMA                                                 TOTAL                        FAIL
USER         JOB LAST DATE        NEXT DATE             TIME BROKEN INTERVAL        URES WHAT
---------- ----- ---------------- ---------------- --------- ------ --------------- ---- -------------------------

.

format STDOUT =
@<<<<<<<<< @#### @<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<< @######## @<<<<< ^<<<<<<<<<<<<<< @### @<<<<<<<<<<<<<<<<<<<<<<<<
$row->{SCHEMA_USER}, $row->{JOB}, $row->{LAST_DATE}, $row->{NEXT_DATE}, $row->{TOTAL_TIME}, $row->{BROKEN}, $row->{INTERVAL}, $row->{FAILURES}, $row->{WHAT}
~~                                                                  ^<<<<<<<<<<<<<<
                                                                    $row->{INTERVAL}
.






