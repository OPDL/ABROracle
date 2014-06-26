#!/usr/bin/perl

# odpc.pl
# oracle default password check
# Jared Still
# jkstill@cybcon.com

use warnings;
use strict;
use Getopt::Long;
use PDBA::CM;
use PDBA::GQ;
use PDBA::ConfigFile;
use PDBA::OPT;
use PDBA::DBA;
use Data::Dumper;

my %optctl = ();

Getopt::Long::GetOptions(
	\%optctl, 
	"machine=s",
	"database=s",
	"username=s",
	"password=s",
	"gen_password!",
	"sysdba!",
	"sysoper!",
	"z","h","help");

my($db, $username, $connectionMode);

if (
	$optctl{h} 
	|| $optctl{z}
	|| $optctl{help}
) {
	Usage(0);
}

$connectionMode = 0;
if ( $optctl{sysoper} ) { $connectionMode = 4 }
if ( $optctl{sysdba} ) { $connectionMode = 2 }

if ( ! defined($optctl{database}) ) {
	Usage(1);
	die "database required\n";
}
$db=$optctl{database};

if ( ! defined($optctl{username}) ) {
	Usage(2);
	die "username required\n";
}

$username=$optctl{username};

# lookup the password if not on the command line
my $password = '';
if ( defined( $optctl{password} ) ) {
	$password = $optctl{password};
} else {

	if (
		! defined($optctl{machine})
		|| ! defined($optctl{database})
		|| ! defined($optctl{username})
	) { Usage(3) }

	$password = PDBA::OPT->pwcOptions (
		INSTANCE => $optctl{database},
		MACHINE => $optctl{machine},
		USERNAME => $optctl{username}
	);
}

my $configFile = $optctl{conf} ? $optctl{conf} : 'odpc.conf';

unless ( new PDBA::ConfigLoad( FILE => $configFile ) ) {
	# need latest version of PDBA::ConfigFile for this to work
	die "could not load config file $configFile\n";
}

#print Dumper(\%odpc::defusers);

my $dbh = new PDBA::CM(
	DATABASE => $optctl{database},
	USERNAME => $optctl{username},
	PASSWORD => $password,
);


my $pw = new PDBA::GQ($dbh, 'dba_users',
	{
		COLUMNS => [qw{username password}],
		WHERE =>  q{ username in('} . join(q{','}, keys %odpc::defusers) . q{')},
	}
);

while( my $row = $pw->next({}) ) {
	if ( exists $odpc::defusers{$row->{USERNAME}} ) {
		if ( $odpc::defusers{$row->{USERNAME}} eq $row->{PASSWORD} ) {
			if ( $optctl{gen_password} ) {
				my $passwdObj = new PDBA::DBA(
					DBH => $dbh, 
					OBJECT => 'new_password', 
					OBJECT_TYPE => 'password' 
				);
				$passwdObj->create;

				printf("Account %-20s is using a default password - suggested password: %-10s\n", 
					$row->{USERNAME}, $passwdObj->{PASSWORD}
				);
			} else {
				printf("Account %-20s is using a default password\n", $row->{USERNAME});
			}
		}
	}
}

$dbh->disconnect;

sub Usage {
	my $exitval = shift;
	use File::Basename;
	my $basename = basename($0);

	print qq{

usage: $basename  Oracle Default Password Checker

-machine      database server
-database     ORACLE_SID
-username     DBA account
-gen_password generate password and print to stdout
-password     account password
              use one of the following options
              to connect as SYSOPER or SYSDBA

              [-sysdba || -sysoper]

};

	exit $exitval;

}


