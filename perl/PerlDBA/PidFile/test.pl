# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use PDBA::PidFile;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $testId=1;

my $lockfile = './lock.txt';
my $pid = $$;
my $fh = new PDBA::PidFile( $lockfile, $pid );

if ( $fh ) {
	print "ok ", ++$testId, "\n";
} else {
	print "not ok ", ++$testId, "\n";
}


# this next test is ok if it fails
# we *want* it to fail, as the file
# is already locked

# fake a new process
$pid++;

my $fh2 = new PDBA::PidFile( $lockfile, $pid );

#print "Child PID: $pid\n";
#print "Child  LockPID: $lockPid2\n";
if ( $fh2 ) {
	print "not ok ", ++$testId, "\n";
} else {
	print "ok ", ++$testId, "\n";
}


