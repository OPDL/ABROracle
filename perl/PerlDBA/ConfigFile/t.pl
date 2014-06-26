#!/usr/bin/perl

use lib '../blib/lib';
use PDBA::ConfigFile;
use PDBA;

# test files in order
# local dir overrides HOME
# HOME overrides everything else
# if not there, looks in PATH
# if PATH not set, uses PATH from the environment

my @testfiles=("/tmp/test.conf", "$ENV{HOME}/test.conf", "./test.conf");
unlink @testfiles;

#for my $file ( @testfiles ) { print "FILE: |$file|\n" }

my $i=1;

for my $file ( @testfiles ) {
	system("echo NEW config file $i > $file");
	my $t = new PDBA::ConfigFile( 
		PATH => $ENV{HOME} . PDBA->pathsep() . '/tmp',
		FILE => 'test.conf' 
	);
	while( my $l = $t->getline) {
		print $l;
	}
	#while (<$t>) {
		#print;
	#}
	$t->close;
	$i++;
}

undef %Parms::driveSpaceMin;

#returns undef if not successful
unless ( new PDBA::ConfigLoad( PATH => './', FILE => 'test2.conf' ) ) {
	die "\n\nError Encountered:\n$@\n\n";
}

print "Drive:  D:  Space Required %: $Parms::driveSpaceMin{'D:'}\n";

$t = new PDBA::ConfigFile( 
	PATH => $ENV{HOME} . PDBA->pathsep() . '/tmp', 
	FILE => 'test2.conf' 
);
if ( $t ) { print "found file\n" }
else { print "did not find file\n" }

$t = new PDBA::ConfigFile( PATH => '/tmp', FILE => 'garbage.conf' );
if ( $t ) { print "found file\n" }
else { print "did not find file\n" }



