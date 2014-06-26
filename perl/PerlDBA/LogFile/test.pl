# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..6\n"; }
END {print "not ok 1\n" unless $loaded;}
use PDBA::LogFile;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):


my $logFile = './test.log';
my $logFh = new PDBA::LogFile($logFile);

if( $logFh ) { print "ok 2\n" }
else { print "not ok 2\n" }

$logFh->printflush("print this line\n");
sleep 1;
$logFh->printflush("printflush this line\n");

my $logFh2 = new PDBA::LogFile($logFile);

if( ! $logFh2 ) { print "ok 3\n" }
else { print "not ok 3\n" }

$logFile = './logs/test.log';

-f $logFile && unlink $logFile;
-d './logs/' && rmdir "./logs";

if ( -d './logs' ) { print "not ok 4\n" }
else { print "ok 4\n" }

PDBA::LogFile->makepath($logFile);
$logFh = new PDBA::LogFile($logFile);
if( $logFh ) { 
	$logFh->printflush("logfile testing\n");
	print "ok 5\n" ;
} else { print "not ok 5\n" }

if ( -d './logs' ) { print "ok 6\n" }
else { print "not ok 6\n" }

-f $logFile && unlink $logFile;
-d './logs/' && rmdir "./logs";

