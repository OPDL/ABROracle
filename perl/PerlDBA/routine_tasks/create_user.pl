#!/usr/bin/perl -w

use warnings;
use strict;
use PDBA::CM;
use PDBA::GQ;
use PDBA::OPT;
use PDBA::DBA;
use PDBA::ConfigFile;
use Getopt::Long;

my %optctl=();

# passthrough allows additional command line options
# to be passed to PDBA::OPT if needed
Getopt::Long::Configure(qw{pass_through});

GetOptions( \%optctl,
	"help!",
	"machine=s",
	"database=s",
	"username=s",
	"new_username=s",
	"new_password=s",
	"password=s",
	"pdbarole=s",
	"default_tbs=s",
	"temp_tbs=s",
	"verbose!",
	"list_roles!",
);

if ( $optctl{help} ) { usage(1) }

my $conf = new PDBA::ConfigLoad( FILE => 'create_user.conf');

use Data::Dumper;

# list roles if requested
if ( $optctl{list_roles} ) {
	foreach my $role ( sort keys %cuconf::roles ) {
		print "ROLE: $role\n";
		foreach my $privType ( sort keys %{$cuconf::roles{$role}} ) {
			print "\tTYPE: $privType\n";
			my $refType =  ref($cuconf::roles{$role}->{$privType});
			if ( 'HASH' eq $refType  ) {
				foreach my $priv ( sort keys %{$cuconf::roles{$role}->{$privType}} ) {
					print "\t\tPRIV: $priv: $cuconf::roles{$role}->{$privType}{$priv}\n";
				}
			} elsif ( 'ARRAY' eq $refType ) {
				foreach my $priv ( sort @{$cuconf::roles{$role}->{$privType}} ) {
					print "\t\tPRIV: $priv\n";
				}
			} else { 
				die "invalid reftype encountered in configuration file\n";
			}
		}
	}

	exit 0;
}

usage(1) unless $optctl{pdbarole};

unless ( exists $cuconf::roles{$optctl{pdbarole}} ) {
	warn "role $optctl{pdbarole} not defined in configuration file\n";
	usage(1);
}

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

my $dbh = new PDBA::CM(
	DATABASE => $optctl{database},
	USERNAME => $optctl{username},
	PASSWORD => $password,
);

my $tmpTbs = $cuconf::roles{$optctl{pdbarole}}->{tablespaces}{temporary}
	? $cuconf::roles{$optctl{pdbarole}}->{tablespaces}{temporary}
	: $cuconf::tablespaces{temporary};

$tmpTbs = $optctl{temp_tbs} 
	? $optctl{temp_tbs} 
	: $tmpTbs;

my $defTbs = $cuconf::roles{$optctl{pdbarole}}->{tablespaces}{default}
	? $cuconf::roles{$optctl{pdbarole}}->{tablespaces}{default}
	: $cuconf::tablespaces{default};

$defTbs = $optctl{default_tbs} 
	? $optctl{default_tbs} 
	: $defTbs;

if ( $optctl{verbose} ) {
	print qq/

creating user '$optctl{new_username}'

default tablespace  : $defTbs
temporary tablespace: $tmpTbs

grants:  @{$cuconf::roles{$optctl{pdbarole}}->{grants}}

revokes:  @{$cuconf::roles{$optctl{pdbarole}}->{revokes}}

quotas: 

/;

	for my $tbs ( keys %{$cuconf::roles{$optctl{pdbarole}}->{quotas}} ){
		print "  $tbs:  $cuconf::roles{$optctl{pdbarole}}->{quotas}{$tbs}\n";
	}
	print "\n";
}

my $newPassword = $optctl{new_password} 
	? $optctl{new_password} 
	: 'generate';

my $newUser = new PDBA::DBA(
	DBH => $dbh,
	OBJECT_TYPE => 'user',
	OBJECT => $optctl{new_username},
	PASSWORD => $newPassword,
	DEFAULT_TABLESPACE => $defTbs,
	TEMPORARY_TABLESPACE => $tmpTbs,
	PRIVS => $cuconf::roles{$optctl{pdbarole}}->{grants},
	REVOKES => $cuconf::roles{$optctl{pdbarole}}->{revokes},
	QUOTAS => $cuconf::roles{$optctl{pdbarole}}->{quotas},
);

eval {
	local $dbh->{PrintError} = 0;
	local $dbh->{RaiseError} = 1;
	$newUser->create;
};

if ($@) {
	if (  $@ =~ /ORA-01920/ ) {
		warn "error creating user - user '$optctl{new_username}' already exists\n";
	} else {
		warn "$@\n";
	}
} else {
	if ($optctl{verbose}) {
		print "user '$optctl{new_username}' created\n" ;
		print "password: $newUser->{PASSWORD}\n";
	} else {
		print "$newUser->{PASSWORD}\n";
	}
}

$dbh->disconnect;

sub usage {
	my $exitVal = shift;
	use File::Basename;
	my $basename = basename($0);
	print qq/
$basename

usage: $basename 

-machine       database_server 
-database      database to create user in
-username      dba account
-password      dba password ( optional if using pwd server )
-new_username  username to create
-new_password  password for user 
               value of 'generate' will generate a password
-pdbarole      role as defined in create_user.conf
-default_tbs   default tablespace ( override value in create_user.conf )
-temp_tbs      temporary tablespace ( override value in create_user.conf )
-verbose       print out informational messages - off by default
-list_roles    display list of configured PDBA roles from config file

/;
	exit $exitVal;
};

