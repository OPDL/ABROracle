#!/usr/bin/perl -w

=head1 kss.pl

kill sniped sessions on unix

Sniped oracle sessions are those that have timed out
due to the IDLE_LIMIT parameter in a user profile.

use kss.pl to remove them completely

see kss.pl -help  and kss.conf for more info

=cut


use warnings;
use strict;
use PDBA;
use PDBA::CM;
use PDBA::GQ;
use PDBA::OPT;
use PDBA::ConfigFile;
use Getopt::Long;
use Carp;

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
	"debug!",
);

if ( $optctl{help} ) { usage(1) }

my $configFile = 'kss.conf';

my $t = new PDBA::ConfigLoad( FILE => $configFile );

die "$configFile not found or misconfigured\n" 
	unless $kss::config{sleepTime};

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

my $logFile = killsnipe->logFile();

use PDBA::Daemon;
PDBA::Daemon::daemonize() unless $optctl{debug};

#print "Password: $password\n";
if ( $password ) {
	$logFile->printflush("password retrieved for user $optctl{username}\n");
} else {
	$logFile->printflush("password not retrieved for user $optctl{username}\n");
}

setSignals();

while (1) {

	ignoreSignals();

	my $dbh = new PDBA::CM(
		DATABASE => $optctl{database},
		USERNAME => $optctl{username},
		PASSWORD => $password,
	);

	# sniped session query handle
	my $ssqh = $dbh->prepare($kss::config{snipeSql});

	$ssqh->execute;

	$logFile->printflush(qq{SCANNING\n});

	while ( my $row = $ssqh->fetchrow_hashref ) {
		print "USER: $row->{USERNAME}  STATUS: $row->{STATUS}  SPID: $row->{SPID}\n";
		$logFile->printflush(qq{STATUS:$row->{USERNAME}:$row->{SID}:$row->{SERIAL}:$row->{SPID}\n}); 

		my $killCmd = $kss::config{killCmd};
		$killCmd =~ s/<<ORACLE_SID>>/$optctl{database}/go;
		$killCmd =~ s/<<PID>>/$row->{SPID}/go;
		qx{$killCmd};
		$logFile->printflush(qq{OSKILL:$row->{USERNAME}:$row->{SID}:$row->{SERIAL}:$row->{SPID}:$killCmd\n}); 

		my $killSql = $kss::config{killSql};
		$killSql =~ s/<<SID>>/$row->{SID}/;
		$killSql =~ s/<<SERIAL>>/$row->{SERIAL}/;

		my $killh = $dbh->prepare($killSql);
		$killh->execute();
		$killh->finish;
		$logFile->printflush(qq{DBKILL:$row->{USERNAME}:$row->{SID}:$row->{SERIAL}:$row->{SPID}:$killSql\n}); 
		
	}
	
	$dbh->disconnect;

	$logFile->printflush(qq{SLEEP: $kss::config{sleepTime}\n});
	setSignals();
	sleep $kss::config{sleepTime};

}

sub usage {
	my $exitVal = shift;
	use File::Basename;
	my $basename = basename($0);
	print qq/
$basename

usage: $basename 

-machine database_server 
-database database 
-username dba account 
-password dba password ( optional )

/;
	exit $exitVal;
};

# end of main

# local subs

sub cleanup {
	my $signal = shift;
	ignoreSignals();
	$logFile->printflush("caught signal $signal\n");
	$logFile->printflush("exiting\n");
	$logFile->close;
	exit;
}

sub setSignals {
	$SIG{INT} = \&cleanup;
	$SIG{ILL} = \&cleanup;
	$SIG{QUIT} = \&cleanup;
	$SIG{ABRT} = \&cleanup;
	$SIG{TERM} = \&cleanup;
	$SIG{TRAP} = \&cleanup;
}

sub ignoreSignals {
	$SIG{INT} = 'IGNORE';
	$SIG{ILL} = 'IGNORE';
	$SIG{QUIT} = 'IGNORE';
	$SIG{ABRT} = 'IGNORE';
	$SIG{TERM} = 'IGNORE';
	$SIG{TRAP} = 'IGNORE';
}


# packages

package killsnipe;

sub logFile {
	my $self = shift;
	use PDBA;
	use PDBA::LogFile;
	use File::Spec;

	my $log = File::Spec->catfile(
		PDBA->pdbaHome(),
		'logs',
		'kss_' . $optctl{database} . '.log'
	);

	my $logFh = new PDBA::LogFile($log);
	return $logFh;
}

