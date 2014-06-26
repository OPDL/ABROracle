#!/usr/bin/perl


=head2 dbup.pl - check if databases are up

=head1 Author


=item Jared Still

=item jkstill@cybcon.com

=item 10/10/2001


=head1 Synopsis

=over 2

monitor Oracle databases for connectivity, 
page and/or email DBA when database is down

=head1 Features

=over 2

=item B<oncall schedule>

allows scheduling of different DBA's for oncall duty
on a rotating schedule


=item B<email addresses>

multiple email addresses for each DBA


=item B<pager address>

a single pager address per DBA - must be an internet address


=item B<nopage>

turn paging off for a database for a period of time

NOT YET IMPLEMENTED


=item B<delayed paging>

don't page the DBA during off hours until a configurable 
number of connection attempts have been made

=item B<configurable uptime>

the uptime requirements can be independently configured for
each database you wish to check


=head1 options

=over 2

=item B<-conf=<configuration file>>

configuration file must be in either current directory, 
$PDBA_HOME or $HOME.


=item B<-debug>

causes much more information to be logged, as well as
printed on the screen


=item B<-nomail>

turns of email.  ON by default


=item B<-daemon>

run as a daemon process

=item B<-h -z -help>

print usage information and exit

=head1 Configuration

Please see the included configuration file for more information
on configuring dbup.

=cut


# required packages

use File::Path;
use File::Spec;
use Date::Manip;
use PDBA;
use PDBA::CM;
use PDBA::Daemon;
use PDBA::LogFile;
use PDBA::ConfigFile;
use PDBA::OPT;
use Date::Format;
use warnings;

use Getopt::Long;

our %optctl=();

# passthrough allows additional command line options
# to be passed to PDBA::OPT if needed
Getopt::Long::Configure(qw{pass_through});

GetOptions( \%optctl,
	"conf=s",
	"debug!",
	"kill!",
	"mail!",
	"daemon!",
	"h|z|help" 
);

our $debug = $optctl{debug} ? 1 : undef;

# kill currently running dbup is requested
if ( $optctl{kill} ) {
	my $lockFile = MISC->getLockFileName;
	print "Lockfile for kill: $lockFile\n" if $debug;

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
	die "dbup -kill:  failed to kill $chkPids[0]\n" unless $procsKilled;
	print "dbup process $chkPids[0] killed\n";
	exit;

}

usage(1) if ( $optctl{h} or $optctl{z} or $optctl{help});

# default configuration file is dbup.conf
my $confFile = $optctl{conf} ? $optctl{conf} : 'dbup.conf';

# open and run the control file
unless ( new PDBA::ConfigLoad( FILE => $confFile ) ) {
	die "\n\nCannot open config file $confFile\n";
}


# if -mail is set, or no mail option, turn mail on
# only set $noMail when the -nomail option given
unless( exists $optctl{mail} ) { $optctl{mail} = 1 }
our $noMail = $optctl{mail} ? undef : 1;

PDBA::Daemon::daemonize() if $optctl{daemon};

lockPidFile();
my $logFile = logFile();

if ( $debug ) {
	printDbupParms();
}

if ( $debug ) {
	for my $db ( keys %dbup::uptime ) {
		printDbupUptime($db);
	}
}

# if supervisor info is setup ( see dbup.conf ) then get it
# for email and paging
no warnings;
my $sprvsrHash = new supervisorInfo( 
	SUPERVISORS => \@dbup::supervisors,
	ADDRESSES => \%dbup::addresses
);
use warnings;

#use Data::Dumper;
#print Dumper($sprvsrHash);
#if ( $sprvsrHash->{pager} ) { print "paging supers\n" }
#else { print "not paging supers\n" }
#print "super emails:  ", join(', ',@{$sprvsrHash->{email}}), "\n";
#print "super pagers:  ", join(', ',@{$sprvsrHash->{pager}}), "\n";
#exit;

# the keys for the uptime data structure are database names
# this loop iterates through those keys and tries to connect
# to each database

my $ignoreHashRef = ();

# track number of connection attempts per database

my %connectionRetries=();

$logFile->printflush("OS Name: " . PDBA::osname . "\n") if $debug;


# main loop here
while(1) {
ignoreSignals();

# setup the database ignore stuff if available
# this allows you to ignore a database until a
# certain time.  see dbignore.conf and dbup.conf
# check the ignore data each time through
if  ( defined $dbup::ignoreFile ) {
	$ignoreHashRef = getDbIgnoreStatus uptime(
		FILE => $dbup::ignoreFile,
		DBLIST => [keys %dbup::uptime]
	);
}


# iterate through the databases in the config file
for my $db ( keys %dbup::uptime ) {

	if ( $ignoreHashRef->{$db} ) {
		$logFile->printflush("Ignoring $db until $ignoreHashRef->{$db}\n");
		print "Ignoring $db until $ignoreHashRef->{$db}\n" if $debug;
		next;
	}

	my $pageFlag = 0;

	$logFile->printflush("Check database: $db\n");

	my $password = PDBA::OPT->pwcOptions (
		INSTANCE => $db,
		MACHINE => $dbup::uptime{$db}->{machine},
		USERNAME => $dbup::uptime{$db}->{username}
	);

	$logFile->printflush("Password not found for $db\n") 
		unless $password;

	my $dbh = '';

	# database connection will cause perl to 'die'
	# will just exit the eval block so we can check
	# the value of $dbh

	eval {
		local $SIG{ALRM} = sub {
		$logFile->printflush("Connection to $db timed out\n");
			die "connection timeout\n";
		};

		alarm $dbup::parms{connectionTimeOut};

		$dbh = new PDBA::CM(
			DATABASE => $db,
			USERNAME => $dbup::uptime{$db}->{username},
			PASSWORD => $password
		);

	};

	# the alarm reset must be outside the eval{}
	alarm 0;

	if($dbh) {
		$dbh->disconnect;
		$logFile->printflush("Connection to $db successful\n");
	} else {

		# determine if this happened during the guaranteed
		# uptime as specified in the SLA
		my $uptimeList = new uptime(\%dbup::uptime);
		my $dbupRequired = $uptimeList->uptimeNow( DATABASE => $db );

		if ( $dbupRequired ) {
			$logFile->printflush("Database $db down during required uptime\n");
			print "Database $db down during required uptime\n" if $debug;
		} else {
			$logFile->printflush("Database $db down during off hours\n");
			print "Database $db down during off hours\n" if $debug;
		}

		# ok, the db should be, who ya gonna call?
		# find out who's on call
		# for now, assume the switch occurs at noon

		no warnings;
		my $dbaList = new oncall(\%dbup::onCallList);
		use warnings;

		my @lt = localtime(time);
		my $onCallDate = Date::Format::strftime('%Y%m%d', @lt);
		my $dba = $dbaList->getDba;

		$logFile->printflush("On call DBA is: $dba\n");
		print "On call DBA is: $dba\n" if $debug;

		# always send an email when database is down
		# as it's rather non-intrusive, at least compared
		# to a pager
		my $pagerAddress = $dbup::addresses{$dba}->{pager};
		my @emailAddresses=();
		push(@emailAddresses, $dbup::addresses{$dba}->{emailWork});
		push(@emailAddresses, $dbup::addresses{$dba}->{emailHome});

		if ( $debug ) {
			$logFile->printflush("pager address: $pagerAddress\n");
			$logFile->printflush("email addresses: " . join(':', @emailAddresses), "\n");
		}

		my $emailSubject = Date::Format::strftime("%Y/%m/%d - %H:%M",@lt) . "DB Down: $db\n";
		my $emailMsg = "Failed to connect to database $db at "
			. Date::Format::strftime("%Y/%m/%d - %H:%M",@lt);

		$emailMsg .= "\n Alert Level: " . $dbup::uptime{$db}->{alertLevel};

		if ( $noMail ) {
			$logFile->printflush("email option turned off. no mail sent to: " . join(', ',@emailAddresses), "\n");
		} else {
			if ( email(\@emailAddresses, $emailMsg, $emailSubject ) ){
				$logFile->printflush("Sent email to " . join(', ',@emailAddresses), "\n");
			} else {
				$logFile->printflush("Failure sending email to " . join(', ',@emailAddresses), "\n");
			}
			# send mail to supervisor(s) if defined - see dbup.conf
			if ( $sprvsrHash->{email} ) {
				if ( email($sprvsrHash->{email}, $emailMsg, $emailSubject ) ){
					$logFile->printflush("Sent email to " . join(', ',@{$sprvsrHash->{email}}), "\n");
				} else {
					$logFile->printflush("Failure sending email to " . join(', ',@{$sprvsrHash->{email}}), "\n");
				}
			}
		}
			
		# after sending email, skip to next database if
		# this is not required uptime
		unless( $dbupRequired ){ next }

		# determine if this is a scheduled time to
		# page the dba immediately
		# check the number of connection attempts that have already
		# occurred.  If over the max, then page anyway.

		my $immediateHours = new pageHours($dbup::parms{hoursToPageImmediate});
		if ( $immediateHours->pageNow ) {
			$pageFlag++;
			$logFile->printflush("Database $db is down - paging DBA: $dba\n");
			$connectionRetries{$db} = 0;
		} else {
			$logFile->printflush("Database $db is down outside of required hours\n");
			$connectionRetries{$db}++;

			# if we've made the maximum number of attempts, page anyway
			if ( $connectionRetries{$db} >= $dbup::parms{maxConnectRetries}) {
				$pageFlag++;
				$logFile->printflush("Maximum connect retries reached for $db - paging DBA: $dba\n");
				$emailMsg .= "\nMaximum connect retries reached";
				$connectionRetries{$db} = 0;
			}
			
		}

		if ( $pageFlag ) {
			# page the DBA, eh?
			$pageFlag=0;
			if ( $noMail ) {
				$logFile->printflush("email turned off. no page sent to $pagerAddress\n");
			} else {
				if ( email([$pagerAddress], $emailMsg, $emailSubject ) ){
					$logFile->printflush("Sent page to $pagerAddress\n");
				} else {
					$logFile->printflush("Failure sending page to $pagerAddress\n");
				}
				# send mail to supervisor(s) if defined - see dbup.conf
				if ( $sprvsrHash->{pager} ) {
					if ( email($sprvsrHash->{pager}, $emailMsg, $emailSubject ) ){
						$logFile->printflush("Sent page to " . join(', ',@{$sprvsrHash->{pager}}), "\n");
					} else {
						$logFile->printflush("Failure sending page to " . join(', ',@{$sprvsrHash->{pager}}), "\n");
					}
				}
			}
		}

	}
}
setSignals();
sleep $dbup::parms{connectInterval};
}

# end of main 

#***********************************
#*** sub routines here
#***********************************


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


sub usage {

	my ( $exitArg ) = @_;

	print q/

  dbup - determine if databases are up

  -conf   configuration file - defaults to dbup.conf
  -debug  turns debugging on - off by default
  -daemon runs in daemon mode
  -mail   mail alerts to DBA - on by default
  -nomail do not mail alerts to DBA - on by default
  -h      print usage and exit
  -z      print usage and exit
  -help   print usage and exit

/;

	exit $exitArg if $exitArg;

};


sub lockPidFile {
	
	use PDBA::PidFile;

	my $lockfile = MISC->getLockFileName;
	my $pid = $$;
	my $fh = new PDBA::PidFile( $lockfile, $pid );

	if ( ! $fh ) {
		die "could not lock file\n";
	}

}

sub logFile {
	use PDBA::LogFile;
	#my $logFile = './test.log';
	my $logFile = $dbup::parms{logfile};
	my $logFh = new PDBA::LogFile($logFile);
	return $logFh;
}

sub printDbupParms {
	no warnings;
	print "hours to page immediate: ", join(':', @{$dbup::parms{hoursToPageImmediate}}), "\n";
	print "max connection retries: $dbup::parms{maxConnectRetries}\n";
	print "connect interval: $dbup::parms{connectInterval}\n";
	print "logfile: $dbup::parms{logfile}\n";
	#-- log to file
	$logFile->printflush("hours to page immediate: ", join(':', @{$dbup::parms{hoursToPageImmediate}}), "\n");
	$logFile->printflush("max connection retries: $dbup::parms{maxConnectRetries}\n");
	$logFile->printflush("connect interval: $dbup::parms{connectInterval}\n");
	$logFile->printflush("logfile: $dbup::parms{logfile}\n");
	$logFile->printflush("no page dir: $dbup::parms{noPageDir}\n");
}

sub printDbupUptime {

	my ($db) = @_;

	my $password = PDBA::OPT->pwcOptions (
		INSTANCE => $db,
		MACHINE => $dbup::uptime{$db}->{machine},
		USERNAME => $dbup::uptime{$db}->{username}
	);

	print "db: $db\n";
	print "\t updays     : ", join(":", @{$dbup::uptime{$db}->{upDays}}), "\n";
	print "\t uphours    : ", join(":", @{$dbup::uptime{$db}->{upHours}}), "\n";
	print "\t username   : $dbup::uptime{$db}->{username}\n";
	print "\t password   : $password\n";
	print "\t alert level: $dbup::uptime{$db}->{alertLevel}\n";
	#--- log also
	$logFile->printflush("db: $db\n");
	$logFile->printflush("updays     : ", join(":", @{$dbup::uptime{$db}->{upDays}}), "\n");
	$logFile->printflush("uphours    : ", join(":", @{$dbup::uptime{$db}->{upHours}}), "\n");
	$logFile->printflush("username   : $dbup::uptime{$db}->{username}\n");
	$logFile->printflush("password   : $password\n");
	$logFile->printflush("alert level: $dbup::uptime{$db}->{alertLevel}\n");
}

sub email {

	use Mail::Sendmail;

	my ($addressRef, $msg, $subject) = @_;
	$subject = "oracle connect failure" unless $subject;

	my %mail = (
		To => join(',', @$addressRef),
		From => $dbup::parms{fromAddress},
		Subject => $subject,
		Message =>  $msg,
		smtp => $dbup::parms{mailServer}
	);

	if ( sendmail(%mail) ) { return 1 } 
	else { return 0 }

}

sub cleanup {
	my $signal = shift;
	$logFile->printflush("caught signal $signal\n");
	$logFile->printflush("exiting\n");
	$logFile->close;
	exit;
}

## modules below here

package oncall;

sub new {
	my ($pkg) = shift;
	my $class = ref($pkg) || $pkg;

	my ($hashRef) = @_;

	my $retList = bless $hashRef, $class;

	return $retList;
	
};

sub getDba {
	my $self = shift;

	# date format YYYYMMDD
	my ($currDate) = @_;

	#print "Currdate: $currDate\n";

	my @lt = localtime(time);
	$currDate ||= Date::Format::strftime('%Y%m%d', @lt);
	my $currHour = Date::Format::strftime('%H',@lt);
	my $cutOffHour = 12;


	my $dateKey;
	my $prevDate;
	for my $date ( sort keys %{$self} ){
		#print "date key: $date\n";
		$dateKey = $prevDate;

		if ( $currDate le $date ) {
			if ( $cutOffHour le $currHour and $currDate eq $date ) {
				$dateKey = $date;
			};
			last;
		}
		#last if  $currDate < $date;
		$prevDate = $date;
	}
	

	#use Data::Dumper;
	#print Dumper ( $self );

	#print "found datekey: $dateKey\n";
	return $self->{$dateKey};

}


package uptime;

sub new {
	my ($pkg) = shift;
	my $class = ref($pkg) || $pkg;

	my ($hashRef) = @_;

	my $retList = bless $hashRef, $class;

	return $retList;
	
};

sub uptimeNow {
	my $self = shift;

	# date format YYYYMMDD
	my (%args) = @_;

	$args{DAY} ||= (localtime(time))[6];
	$args{HOUR}||= (localtime(time))[2];

	# deal with the zero hour and day
	$args{DAY} = '0E0' unless $args{DAY};
	$args{HOUR} = '0E0' unless $args{HOUR};

	# convert days from 0-6 to 1-7 for testing purposes
	# convert hour from 0-23 to 1-24 for testing purposes
	my $hour = $args{HOUR};
	my $day = $args{DAY};
	$day++;
	$hour++;

	my @upDays = map { $_ + 1 } @{$dbup::uptime{$args{DATABASE}}->{upDays}};
	my @upHours = map { $_ + 1 } @{$dbup::uptime{$args{DATABASE}}->{upHours}};

	#print "DAY: $args{DAY}\n";
	#print "UPDAYS: " , join(':', @upDays), "\n";
	#print "UPHOURS: " , join(':', @upHours), "\n";

	my $shouldBeUp = 0;

	if ( grep(/^$day$/, @upDays ) ) {
		if ( grep(/^$hour$/, @upHours) ) {
			$shouldBeUp++;
		}
	}
	return $shouldBeUp;
}

=head2  getDbIgnoreStatus

Set a time in a file until which a database is
to be ignored. Useful when you know a database
will be down for an extended period of time.

ARGS:

  FILE => configuration file name
  DBLIST => ref to list of databases to check

Usage:

  my $ignoreHashRef = '';

  if  ( defined $dbup::ignoreFile ) {

    $ignoreHashRef = uptime->getDbIgnoreStatus(
      FILE => $dbup::ignoreFile,
      DBLIST => [keys %dbup::uptime]
    );

  }

  foreach my $db ( keys %dbup::uptime ) {
    if ( $ignoreHashRef->{$db} ) {
      print "Ignoring $db until $ignoreHashRef->{$db}\n";
    } else {
      print "Processing $db as normal\n";
    }
  }


=cut


sub getDbIgnoreStatus {

	my $pkg = shift;
	my $class = ref($pkg) || $pkg;

	my ( %args ) = @_;

	use Date::Manip;
	use Date::Format;
	#use Data::Dumper;
	#print Dumper(\%args);

	#print "attempting to load $dbup::ignoreFile\n";
	my $hIgnoreFile = new PDBA::ConfigLoad( FILE => $args{FILE} );

	my %ignoreList = map{ $_ => '' } @{$args{DBLIST}};

	my @lt = localtime(time);
	my $dateFormat = "%Y/%m/%d-%H:%M:%S";
	my $currTime = Date::Format::strftime($dateFormat,@lt);

	#print "currtime: $currTime\n\n";

	if ( $hIgnoreFile ) {
		#print "loaded file $dbup::ignoreFile\n";
		foreach my $db ( keys %dbignore::ignoreUntil ) {
	
			my $currCmpDate = ParseDate($currTime);
			my $dbCmpDate = ParseDate($dbignore::ignoreUntil{$db});
	
			# the flag will be < 1 if $currCmpDate <= $dbCmpDate
			my $dbIgnoreFlag = Date_Cmp($dbCmpDate, $currCmpDate);
			#print "dbIgnoreFlag: $dbIgnoreFlag\n";
	
			if ( 0 < $dbIgnoreFlag ) {
				#print "$db ignored until $dbignore::ignoreUntil{$db}\n";
				$ignoreList{$db} = $dbignore::ignoreUntil{$db};
			}
		}

		return bless \%ignoreList, $class;
	}
}




# end

package pageHours;

sub new {
	my ($pkg) = shift;
	my $class = ref($pkg) || $pkg;

	my ($arrayRef) = @_;

	my $retList = bless $arrayRef, $class;

	return $retList;
	
};

sub pageNow {
	my $self = shift;

	# date format YYYYMMDD
	my (%args) = @_;

	$args{HOUR}||= (localtime(time))[2];

	# convert days from 0-6 to 1-7 for testing purposes
	# convert hour from 0-23 to 1-24 for testing purposes
	my $hour = $args{HOUR};
	$hour++;

	my @pageHours = map { $_ + 1 } @{$self};

	#print "HOUR: $hour\n";
	#print "PAGE_HOURS: " , join(':', @pageHours), "\n";

	my $pageNow = 0;

	if ( grep(/^$hour$/, @pageHours) ) {
		$pageNow++;
	}

	return $pageNow;

}

package supervisorInfo;

sub new {
	my ($pkg) = shift;
	my $class = ref($pkg) || $pkg;

	my (%args) = @_;

	my $superHash = {};

	for my $super (@{$args{SUPERVISORS}}) {
		push @{$superHash->{email}}, $args{ADDRESSES}->{$super}{emailWork};
		push @{$superHash->{email}}, $args{ADDRESSES}->{$super}{emailHome};
		push @{$superHash->{pager}}, $args{ADDRESSES}->{$super}{pager};
	}

	my $retHash = bless $superHash, $class;

	return $retHash;
	
};

package MISC;

sub getLockFileName {
	my ($self) = shift;
	my $lockfile = undef;
	if ( 'unix' eq PDBA::osname ) {
		if ( $debug ) {
			$lockfile = '/tmp/dbup_pid_debug.lock';
		} else {
			$lockfile = '/tmp/dbup_pid.lock';
		}
	} else {
		$lockfile = 'c:/temp/dbup_pid.lock';
	}
	return $lockfile;
}


