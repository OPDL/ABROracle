#!/usr/bin/perl -w

=head1 dba_jobsm.pl

 like dba_jobs.pl, but connects to multiple servers
 as specified in the config file

=cut

use warnings;
use strict;
use PDBA;
use PDBA::CM;
use PDBA::GQ;
use PDBA::OPT;
use PDBA::ConfigFile;
use PDBA::LogFile;
use Getopt::Long;

my $nlsDateFormat = q{yyyy/mm/dd hh24:mi};

my %optctl=();

# passthrough allows additional command line options
# to be passed to PDBA::OPT if needed
Getopt::Long::Configure(qw{pass_through});

GetOptions( \%optctl,
	"help!",
	"conf=s",
	"confpath=s",
	"logfile=s",
	"logcolumns!",
	"email!",
	"verbose!",
	"debug!",
);

if ( $optctl{help} ) { usage(1) }

# config is required
my $configFile = $optctl{conf} 
	? $optctl{conf} 
	: 'dba_jobs.conf';

# load the configuration file
unless ( 
	new PDBA::ConfigLoad( 
		FILE => $configFile, 
		DEBUG => $optctl{debug},
		PATH => $optctl{confpath},
	) 
) {
	die "could not load config file $configFile\n";
}

# setup and open the log file
my $logFile = $optctl{logfile} 
	? $optctl{logfile}
	: PDBA->pdbaHome . q{/logs/dba_jobsm.log};

my $logFh = new PDBA::LogFile($logFile);

if ( $optctl{debug} ) {

	foreach my $machine ( keys %dbajobs::databases ) {
		print "machine: $machine\n";
		foreach my $database ( keys %{$dbajobs::databases{$machine}} ) {
			print "\tdb: $database\n";
			print "\t\tusername: $dbajobs::databases{$machine}->{$database}\n";
		}
	}
	exit;
}

my $instanceName = undef;
my $machineName = undef;
my $systemDate = undef;
my $row = {};
my $tmpFile;

if ($optctl{email}) {

	use POSIX;

	if ( 'unix' eq PDBA->osname ) {
		$tmpFile = POSIX::tmpnam();
	} else {
		$tmpFile = 'C:\TEMP' . POSIX::tmpnam() . 'tmp';
	}

	print "TMPFILE: $tmpFile\n" if $optctl{verbose};

	open(FILE,"> $tmpFile") || die "cannot create $tmpFile\n";
	select(FILE);

	# reset the format and format_top names, as using select(FILE)
	# will cause Perl to look for FILE and FILE_TOP
	$~ = 'STDOUT';
	$^ = 'STDOUT_TOP';

}

foreach my $machine ( keys %dbajobs::databases ) {

	foreach my $database ( keys %{$dbajobs::databases{$machine}} ) {

		my $username = $dbajobs::databases{$machine}->{$database};

		# retrieve the password from the password server
		my $password = PDBA::OPT->pwcOptions (
			INSTANCE => $database,
			MACHINE => $machine,
			USERNAME => $username
		);

		# create a database connection
		my $dbh = new PDBA::CM(
			DATABASE => $database,
			USERNAME => $username,
			PASSWORD => $password,
		);

		$dbh->do(qq{alter session set nls_date_format = '$nlsDateFormat'});

		# get the host and instance name
		my $gn = new PDBA::GQ($dbh,'v$instance');
		my $gnHash = $gn->next;
		$instanceName = $gnHash->{INSTANCE_NAME};
		$machineName = $gnHash->{HOST_NAME};
		undef $gn;
		undef $gnHash;

		print "Instance Name: $instanceName\n" if $optctl{verbose};
		print "Host Name: $machineName\n" if $optctl{verbose};

		# get the system date
		$systemDate = PDBA->sysdate($dbh, NLS_DATE_FORMAT => $nlsDateFormat);
		print "System Date: $systemDate\n" if $optctl{verbose};
		
		my $gq = new PDBA::GQ ( $dbh, 'dba_jobs',
			{
				COLUMNS => [
					qw(schema_user job last_date next_date interval failures what),
					q{round(total_time,2) total_time},
					q{decode(broken,'N','NO','Y','YES','UNKNOWN') broken},
				],
				ORDER_BY => q{schema_user, next_date}
			}
		);

		# print the column names in the log
		my $colHash = $gq->getColumns;
		$logFh->printflush(
			join('~', (
					$machine, $database, 
					map {$_} sort keys %{$colHash}
				)
			) . "\n") if $optctl{logcolumns};

		while ( $row = $gq->next({}) ) { 
			$logFh->printflush( 
				join("~", (
						$machine ,
						$database ,
						# the map function is use to place all values from the
						# $row hash ref into an array.  The ternary ?: operator
						# is used with 'defined()' to avoid warnings on undefined
						# values.  These occur when a NULL is returned from a 
						# SQL statement
						map { defined($row->{$_}) ? $row->{$_} : '' } sort keys %$row
					)
				) . "\n"
			);
			write;
		}

		$dbh->disconnect;

		# set number of lines on page left to 0
		# forcing a form feed
		$- = 0;

	}
}

if ($optctl{email}) {

	#email here
	close FILE;
	select(STDOUT);

	open(FILE, "$tmpFile") || die "cannot open $tmpFile for read - $!\n";
	my @msg = <FILE>;
	close FILE;
	my $msg = join('',@msg);

	my $subject = qq{DBA Jobs Report For All Servers};

	unless ( PDBA->email($dbajobs::emailAddresses,$msg,$subject) ) {
		warn "Error Sending Email\n";
	}

	unlink $tmpFile;

	$logFh->printflush(("report mailed to ", @$dbajobs::emailAddresses, "\n"));
}


## end of main

sub usage {
	my $exitVal = shift;
	use File::Basename;
	my $basename = basename($0);
	print qq/
usage: $basename

  -help       show help and exit
  -conf       configuration file ( needed for email )
  -confpath   path to configuration file ( optional )
  -logfile    logfile - may include path ( optional )
  -logcolumns include column names in logfile 
  -email      send email to users in config file
  -verbose    verbosity on

/;
	exit $exitVal;
};

no warnings;
format STDOUT_TOP =

                                  DBA Jobs Status
Database: @<<<<<<<<<<<<<<<
$instanceName
Machine : @<<<<<<<<<<<<<<<
$machineName
Date    : @<<<<<<<<<<<<<<<<<<<<
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

