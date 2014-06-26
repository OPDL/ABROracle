#!/usr/bin/perl -w

do "$ENV{PDBA_HOME}/ConfigFile/test2.conf";

use Data::Dumper;

print "CONF: ", Dumper(%Parms::driveSpaceMin), "\n";;

unless ( keys %Parms::driveSpaceMin ) {
	die "No Drives defined\n";
}
#
for my $key ( keys %Parms::driveSpaceMin ) {
	print "drive: $key \t";
	print "space: $Parms::driveSpaceMin{$key} \n";
}




