#!/usr/bin/perl   -w

# chkalert.pl

# monitor the alert log for TNS or ORA errors

use warnings;
use Fcntl qw(:flock);
use IO::File;
use Carp;
use Getopt::Long;
use PDBA;
use PDBA::ConfigFile;
use PDBA::Daemon;
use PDBA::PidFile;
use Date::Format;

my %optctl = ();

GetOptions(\%optctl,
	"database=s",
	"alertlog=s",
	"sendmail",
	"kill!",
	"help",
	"details",
	"debug!"
);

if ($optctl{details}) {
	details();
	exit 4;
}

if ($optctl{help}) {
	&Usage;
	exit 2;
}

if (! $optctl{database} ) {
	&Usage;
	exit(3);
}

my $configFile = 'chkalert.conf';

unless ( new PDBA::ConfigLoad( FILE => $configFile ) ) {
	die "Config file $configFile not found\n";
}

my $DataBase;
my $MailOut;
my $DEBUG=$optctl{debug};
my $progName='chkalert';

$DataBase = $optctl{database};
$MailOut = $optctl{sendmail};
$MailSubject = $DataBase . " Database - Alert Log Errors" ;

# names of dba's for debug mode
my @DebugDBAs=@{$chkalert::ckConf{debugDBA}};

my @DbaAddresses = ();

if ( $DEBUG ) { @DbaAddresses = @DebugDBAs }
else { @DbaAddresses = @{$chkalert::ckConf{dbaAddresses}}};

# get oracle home from oratab
my $fh_oraTab = new IO::File;
$fh_oraTab->open($chkalert::ckConf{oratabFile}) || die "unable to open $chkalert::ckConf{oratabFile}\n";
chomp(@Oratab=<$fh_oraTab>);
$fh_oraTab->close;
($Oratab)=grep(/^$DataBase/,@Oratab);

die "cannot find $DataBase in $chkalert::ckConf{oratabFile}\n" unless $Oratab;

print "oratab: $Oratab\n" if $DEBUG;

my ($dummy, $ORACLE_HOME);
($dummy,$ORACLE_HOME) = split(/:/,$Oratab);
print "ORACLE_HOME: $ORACLE_HOME\n" if $DEBUG;

# attempt to find the alert.log in a few different places

# first in ORACLE_HOME/admin/SID/bdump
my $alertLog = undef;

# alert log may be on command line
$alertLog = $optctl{alertlog} if defined($optctl{alertlog});

unless ( $alertLog ) {

	if ($DEBUG){
		my @dumpDirs = ();
		push @dumpDirs, qq{$ENV{'HOME'}/tmp/${DataBase}/bdump};
	} else {

		push @dumpDirs, qq{${ORACLE_HOME}/admin/${DataBase}/bdump};
		push @dumpDirs, qq{${ORACLE_HOME}/../admin/${DataBase}/bdump};
	}

	# for testing - you need a file '$HOME/tmp/$ORACLE_SID/bdump/alert_ORACLE_SID.log

	for my $dir ( @dumpDirs ) {
		$alertLog = qq{${dir}/alert_${DataBase}.log};
		last if -r $alertLog;
	}

}

print STDOUT "DATABASE: $DataBase\n";
print STDOUT "ALERT LOG: $alertLog\n";
print STDOUT "DBA's    : @DbaAddresses\n";

use vars qw { $sec $min $hour $mday $mon $year };
($sec,$min,$hour,$mday,$mon,$year) = localtime(time);
$year+=1900;

# change name of process
$0 = $progName . "_" . $DataBase;

my $hAlertLog = new IO::File;
$hAlertLog->open("$alertLog") || die "unable to open new alert log : $!\n\t$alertLog\n";

# seek to end of file
seek($hAlertLog, 0, 2);

@LogLines=();

SetSig();

my $tmpdir;
$tmpdir = '/tmp/';

my $lockFile = $tmpdir . 'chkalert.' . $DataBase;

#kill and exit if requested

if ( $optctl{kill} ) {

	my $lockPid;
	my @chkPids=();

	if ( open(PID,$lockFile) ) {
		my ($lockPid) = <PID>;
		close PID;
		push(@chkPids, $lockPid);
	} else {
		die "unable to open $lockFile - $! \n";
	}

	my $procsKilled = kill 3, @chkPids;
	die "chkalert -kill:  failed to kill $chkPids[0]\n" unless $procsKilled;
	print "chkalert process $chkPids[0] killed\n";
	exit;
	
}

unless ( $DEBUG ) {
	PDBA::Daemon::daemonize();
}

# setup for lock file
my $pid=$$;

my $hLockFile = new PDBA::PidFile( $lockFile, $pid );

unless ( $hLockFile ) {
	die "could not create and/or lock file $lockFile\n";
}

$SIG{ALRM}=\&SigAlarm;
alarm($chkalert::ckConf{alarmTime});

my @watchdog;

my $throttleEnabled = 0;

while(1) {

	while(<$hAlertLog>) {

		if ($DEBUG ){print STDOUT }

		if ( /$chkalert::ckConf{errorList}/io ) {
			my @lt = localtime(time);
			my($timestamp) = Date::Format::strftime("%Y/%m/%d - %H:%M",@lt);
			chomp;
			push(@LogLines, $_ . " encountered  in $DataBase at $timestamp");

			if( $#LogLines >= $chkalert::ckConf{maxLogLines}-1 ) {

				alarm(0);
				if ( $throttleEnabled ) { 
					if ( $DEBUG ) {
						print STDOUT "THROTTLE: sleeping for $chkalert::ckConf{throttleDelaySeconds} seconds\n";
					}
					sleep $chkalert::ckConf{throttleDelaySeconds} ;
				}

				MailMsgs();
				alarm($chkalert::ckConf{alarmTime});

				# prevent runaway mail
				# if the error messages are coming so fast
				# the first of $chkalert::ckConf{watchdogLength} messages occurred
				# less than $chkalert::ckConf{watchdogLength} * $chkalert::ckConf{watchdogTime} seconds ago,
				# send a message the dba's and abort
				# this is to avoid flooding the mail system
				push(@watchdog, time());

				# check to see if watchdog has expired
				# if last batch of email sent was at least 3 * $chkalert::ckConf{throttleDelaySeconds} ago,
				# then turn throttle off

				if ( $throttleEnabled ) {

					if ( $DEBUG ) {
						print STDOUT "WATCHDOG DIFF:  " ,$watchdog[$#watchdog] - $watchdog[$#watchdog-1], " \n";
					}

					if ( ( $watchdog[$#watchdog] - $watchdog[$#watchdog-1] ) > ( 3 * $chkalert::ckConf{throttleDelaySeconds} ) ) { 
						$throttleEnabled = 0;
						throttleNotify('Chkalert throttle has been disabled. Error messages will be delivered normally.' );
					}
				}

				if ( $#watchdog > ( $chkalert::ckConf{watchdogLength} - 1 ) ) {
					shift @watchdog;
					if ( ! $throttleEnabled )  {
						if ( ( $watchdog[$#watchdog] - $watchdog[0] ) < ( $chkalert::ckConf{watchdogLength} * $chkalert::ckConf{watchdogTime} ) ) {
							$throttleEnabled = 1;
							throttleNotify('Chkalert has been throttled back due to excessive error messages.  Please check the database.' );
						}
					}
				}
			}
		}
	}
	sleep 1;
	$hLockFile->clearerr() if $hLockFile;
}

sub SigAlarm {
	MailMsgs();
	alarm($chkalert::ckConf{alarmTime});
}

sub MailMsgs {

	if( $MailOut and @LogLines )
	{
		my($ErrMsg) = "\n" . join("\n",@LogLines);
		my $subject = "Alert Log Errors in $DataBase on $chkalert::ckConf{serverName}";

		if ( $DEBUG ) { 
			my @lt = localtime(time);
			my($timestamp) = Date::Format::strftime("%Y/%m/%d - %H:%M",@lt);
			print STDOUT "\n\nAlarm Time: ", $timestamp,"\n\n";

			print "SUBJ: $MailSubject - $ErrMsg\n";

			print STDOUT "sending email\n";
		}

		email(\@DbaAddresses, $ErrMsg, $subject);

	}
	@LogLines=();
}

sub email {

	my ($addressRef, $msg, $subject) = @_;
	$subject = "Oracle errors from $DataBase" unless $subject;

	unless ( PDBA->email($addressRef, $msg, $subject) ) {
		carp "Error Sending Email\n";
	}
}

sub Usage {

	use File::Basename;
	my $basename = basename($0);

	print qq/

  $basename: scan the Oracle alert log for 'ORA' errors 

  -sendmail mail output to all addresses in config file
  -database database to monitor
  -alertlog full pathname to alert log
  -details  show detailed usage
  -kill     kill the chkalert daemon for a database 
            chkalert.pl -database ts01 -kill
            if you use kill -9 to kill chkalert, you must
            manually remove the lock file

/;

}


sub SetSig {

	$SIG{HUP} = \&CleanupAndExit;
	$SIG{INT} = \&CleanupAndExit;
	$SIG{QUIT} = \&CleanupAndExit;
	$SIG{TERM} = \&CleanupAndExit;
	$SIG{TRAP} = \&CleanupAndExit;
	$SIG{ABRT} = \&CleanupAndExit;
	$SIG{ILL} = \&CleanupAndExit;

}


sub CleanupAndExit {
	alarm(0);
	undef $hLockFile;
	unlink $lockFile;
	#undef $hAlertLog;
	print STDOUT "files cleaned up\n" if $DEBUG;
	exit 7;
}

sub throttleNotify {

	my $throttleMsg = $_[0];

	warn " trottleMsg required for call to throttleNotify" unless $throttleMsg;

	my $throttleSubject = qq{!! $DataBase chkalert throttle alert!!};

	email::SendMail(\@DbaAddresses, $throttleMsg, $throttleSubject);

}


sub details {

	while(<DATA>) {
	print;
	}
}


__DATA__


QUICKSTART
-----------

start chkalert 

  /opt/share/oracle/lib/chkalert.server


kill chkalert

  /opt/share/oracle/lib/chkalert.kill

STARTING chkalert:
-------------------------

chkalert is a perl script used to monitor your alert logs

It can be started by:

   chkalert -database mydb -sendmail

This will start the daemon for database mydb, and will send
mail to DBA's when errors are received.

chkalert will only send mail every chkalert::ckConf{alarmTime} seconds, 
or when the number of error is >= chkalert::ckConf{maxLogLines}

This is to prevent driving your mail agent crazy if you 
start getting a large number of errors suddenly.  Rather
than mailing each message separately, they are grouped 
together into a single mail message.

In addition, if chkalert determines that a large number of 
error messages are being continually generated, it will 
automatically throttle down to avoid flooding the email system.

The throttle will be disabled when the rate of error messages
returns to normal.

Please see comments in chkalert.conf and chkalert itself for
details on how this works.

-----------------------------

!! do not use kill -9 on chkalert !!

A normal kill command will work just fine.  Using kill -9
does not allow chkalert to clean up after itself.

Better yet, just use the -kill option.

e.g. ./chkalert.pl -database ts01 -kill


