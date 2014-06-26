# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..8\n"; }
END {print "not ok 1\n" unless $loaded;}
use PDBA;
use PDBA::ConfigFile;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# test files in order
# local dir overrides HOME
# HOME overrides everything else
# if not there, looks in PATH
# if PATH not set, uses PATH from the environment

my $debugVal = '';

my $phome = PDBA::pdbaHome();

my @testfiles=("/tmp/test.conf", "${phome}/test.conf", "./test.conf");
unlink @testfiles;

#for my $file ( @testfiles ) { print "FILE: |$file|\n" }

my $i=2;

for my $file ( @testfiles ) {
	system("echo NEW config file $i > $file");
	my $t = new PDBA::ConfigFile( PATH => '/tmp', FILE => 'test.conf' );
	if ($t) {print "ok $i\n" }
	else { print "not ok $i\n"}
	while (<$t>) {
		;	
	}
	$t->close;
	$i++;
}
unlink @testfiles;

my $t = new PDBA::ConfigFile( PATH => './', FILE => 'test2.conf' , DEBUG => $debugVal);
my @code=<$t>;
$t->close;
eval join('',@code);

my $junk = $Parms::driveSpaceMin{'C:'};
if ( $Parms::driveSpaceMin{'C:'}) { 
 	print "ok $i\n";
} else { 
 	print "not ok $i\n";
}

$i++;
undef $t;
undef %Parms::driveSpaceMin;
$t = new PDBA::ConfigLoad( PATH => './', FILE => 'test2.conf' , DEBUG => $debugVal );

if ( $Parms::driveSpaceMin{'D:'}) { 
 	print "ok $i\n";
} else { 
 	print "not ok $i\n";
}

# test for good file
$i++;
undef $t;
$t = new PDBA::ConfigFile(  FILE => 'test2.conf', DEBUG => $debugVal );

if ($t) { print "ok $i\n" }
else { print "not ok $i\n" }

# test for phony file
$i++;
undef $t;
$t = new PDBA::ConfigFile( PATH => './', FILE => 'hoserfile.conf', DEBUG => $debugVal );

if ($t) { print "not ok $i\n" }
else { print "ok $i\n" }


