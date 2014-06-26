#!/usr/bin/perl -w

use warnings;
use strict;
use PDBA;
use PDBA::CM;
use PDBA::GQ;
use PDBA::OPT;
use PDBA::DBA;
use PDBA::ConfigFile;
use PDBA::LogFile;
use Getopt::Long;
use File::Basename;
use Data::Dumper;

my %optctl=();

my $basename = basename($0);

# passthrough allows additional command line options
# to be passed to PDBA::OPT if needed
Getopt::Long::Configure(qw{pass_through});

GetOptions( \%optctl,
	"help!",
	"machine=s",
	"database=s",
	"username=s",
	"filename=s",
	"application=s",
	"message_file=s",
	"logfile=s",
	"pdbarole=s",
	"default_tbs=s",
	"temp_tbs=s",
	"field_separator=s",
	"verbose!",
	"mail_password!",
	"dryrun!",
);

if ( $optctl{help} ) { usage(1) }
usage(1) unless $optctl{pdbarole};


# the config file from create_user.pl is doing double duty
unless ( new PDBA::ConfigLoad( FILE => 'create_user.conf') ) {
	die "unable to load create_user.conf\n";
}

# get the m8.pl specific file
unless ( new PDBA::ConfigLoad( FILE => 'mucr8.conf') ) {
	die "unable to load mucr8.conf\n";
}

if ( $optctl{message_file} )
{ $mucr8::conf{messageFile} = $optctl{message_file} }

if ( $optctl{field_separator} )
{ $mucr8::conf{fieldSeparator} = $optctl{field_separator} }

open(MSG,"< $mucr8::conf{messageFile}") 
	|| die "cannot open message file $mucr8::conf{messageFile} - $!\n";

my @mailMsg = <MSG>;
close MSG;

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

# open user file
open(USERS,"< $optctl{filename}") || die "cannot open $optctl{filename} - $!\n";

my $dryrun = $optctl{dryrun};

# if dryrun then don't log
my $logging = ! $dryrun;

# never send mail from a dryrun
my $mailing = $optctl{mail_password};
$mailing = ! $dryrun if $mailing;

# setup log file
$optctl{logfile} = 'mucr8.log' unless $optctl{logfile};

my $logFh =  new PDBA::LogFile($optctl{logfile}) 
	if $logging;;

if ($dryrun) {
	print "dry run only \n\n";
	print "default tablespace: $defTbs\n";
	print "temp    tablespace: $tmpTbs\n";
	print "grants:  @{$cuconf::roles{$optctl{pdbarole}}->{grants}}\n";
	for my $tbs ( keys %{$cuconf::roles{$optctl{pdbarole}}->{quotas}} ){
		print "  $tbs:  $cuconf::roles{$optctl{pdbarole}}->{quotas}{$tbs}\n";
	}
	print "\n";
} else {
	$logFh->printflush("new users created by $basename\n");
	$logFh->printflush("default tablespace  : $defTbs\n");
	$logFh->printflush("temporary tablespace: $tmpTbs\n");
	$logFh->printflush("PDBA role: $optctl{pdbarole}\n");
	$logFh->printflush("grants: @{$cuconf::roles{$optctl{pdbarole}}->{grants}}\n");
	$logFh->printflush("quotas:\n");
	for my $tbs ( keys %{$cuconf::roles{$optctl{pdbarole}}->{quotas}} ){
		$logFh->printflush("  $tbs:  $cuconf::roles{$optctl{pdbarole}}->{quotas}{$tbs}\n");
	}
	$logFh->printflush("\n");
}


while (<USERS>) {

	chomp;

	my @fields = split(/$mucr8::conf{fieldSeparator}/);
	my ($newUsername, $newUserEmailAddress) = 
		@fields[
			$mucr8::conf{usernamePosition}, 
			$mucr8::conf{emailAddressPosition}
		];

	if ( $dryrun ) {
		printf("user: %-30s  email: %-50s\n",$newUsername,$newUserEmailAddress);
	} else {
		my $newUser = new PDBA::DBA(
			DBH => $dbh,
			OBJECT_TYPE => 'user',
			OBJECT => $newUsername,
			PASSWORD => 'generate',
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
				warn "error creating user - user '$newUsername' already exists\n";
			} else {
				warn "$@\n";
			}
			$logFh->printflush("error creating user $newUsername\n$@\n\n");
			next;
		} else {
			if ($optctl{verbose}) {
				printf( "user: %-30s password: %-20s\n", $newUsername, $newUser->{PASSWORD});
			} else {
				print "$newUser->{PASSWORD}\n";
			}
			$logFh->printflush(sprintf( "user: %-30s password: %-20s\n", $newUsername, $newUser->{PASSWORD}));

			#print Dumper(\%mucr8::tags), "\n";

			if ($mailing) {
				# turn the mail msg arrary into a string
				# for simple regex manipulation
				my $msg = join('',@mailMsg);
				for my $tag ( keys %mucr8::tags ) {
					# this line replaces the <<TAGS>> with code from the
					# %tags hash in mucr8.conf and executes it
					#print "\nTAG: $tag  VALUE: $mucr8::tags{$tag}\n";
					no warnings; # not all tags may be used - turn off warning
					eval '$msg =~ ' . "s/$tag/" . (eval $mucr8::tags{$tag}) . "/gm" ;
					use warnings;
				}
				if ( PDBA->email([$newUserEmailAddress],$msg,'New Oracle Account') ) {
					$logFh->printflush("\tmail sent to user at $newUserEmailAddress\n");
				} else {
					$logFh->printflush("\terror sending mail to user at $newUserEmailAddress\n");
				}
			}
		}

	}
}

$dbh->disconnect;

sub usage {
	my $exitVal = shift;
	print qq/
$basename

usage: $basename 

-machine         database_server 
-database        database to create user in
-username        dba account
-password        dba password ( optional if using pwd server )
-application     name of application account is created for
-filename        file containing user information
-pdbarole        role as defined in create_user.conf
-default_tbs     default tablespace ( override value in create_user.conf )
-temp_tbs        temporary tablespace ( override value in create_user.conf )
-verbose         print out informational messages - off by default

-message_file    file containing text of mail to new users
                 ( override value in configuration file )
-logfile         file to log operations
-field_separator character to separate fields in user file
                 ( override value in configuration file )
-mail_password!  mail passwords to new users
                 email address must be in user file
-dryrun!         just display what would be done without actually
                 creating any accounts

/;
	exit $exitVal;
};

