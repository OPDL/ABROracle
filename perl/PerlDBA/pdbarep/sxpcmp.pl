#!/usr/bin/perl -w

# sxpcmp.pl
# compare explain plan current sql in database to
# that stored in repository
# print out those that differ


use warnings;
use strict;
use PDBA;
use PDBA::CM;
use PDBA::GQ;
use PDBA::OPT;
use Getopt::Long;
use Digest::MD5;

my %optctl=();

# passthrough allows additional command line options
# to be passed to PDBA::OPT if needed
Getopt::Long::Configure(qw{pass_through});

GetOptions( \%optctl,
	"help!",
	"machine=s",
	"database=s",
	"username=s",
	"password=s",
	"rep_machine=s",
	"rep_database=s",
	"rep_username=s",
	"rep_password=s",
	"rep_report_date=s",
	"sysdba!",
	"sysoper!",
	"verbose!",
);

if ( $optctl{help} ) { usage(1) }

$optctl{verbose} ||= '';
my $verbose = $optctl{verbose};


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

#print "Password: $password\n";

my $connectionMode = 0;
if ( $optctl{sysoper} ) { $connectionMode = 4 }
if ( $optctl{sysdba} ) { $connectionMode = 2 }

my $repPassword;
if ( defined $optctl{rep_password} ) {
	$repPassword =  $optctl{rep_password};
} else {

	if (
		! defined($optctl{rep_machine})
		|| ! defined($optctl{rep_database})
		|| ! defined($optctl{rep_username})
	) { usage(1) }

	$repPassword = PDBA::OPT->pwcOptions (
	INSTANCE => $optctl{rep_database},
	MACHINE => $optctl{rep_machine},
	USERNAME => $optctl{rep_username}
	);

}

#print "REP Password: $repPassword\n";

my $dbh = new PDBA::CM(
	DATABASE => $optctl{database},
	USERNAME => $optctl{username},
	PASSWORD => $password,
	MODE => $connectionMode,
);


my $repDbh = new PDBA::CM(
	DATABASE => $optctl{rep_database},
	USERNAME => $optctl{rep_username},
	PASSWORD => $repPassword,
);

#----------------------------------------------------------------------------------------

my $dateSpecific = undef;

if (  defined($optctl{rep_report_date}) ) { $dateSpecific = 1 }

my $rptDateHash = undef;
if (  $dateSpecific ) {
	$rptDateHash = PDBA->rptDatePk (
		$repDbh,
		TABLE => 'PDBA_SXP_DATES',
		START_DATE => $optctl{rep_report_date},
		END_DATE => $optctl{rep_report_date},
	);

	# only going to use the start date as the date of repository
	# entries to check
	if ( $optctl{verbose} ) {
		print "report date pk      : $rptDateHash->{startDatePk}\n";
		print "report start date   : $rptDateHash->{startDate}\n";
	}
}

my ( $usernameEl, $sqlChksumEl, $sqltextEl ) = (0,1,2,3);

our %sqlstats=();

# get the statistics portion

our $counter = 0;

our $sql = q{
	select s.address, u.username
	from v$sqlarea s, dba_users u
	where u.user_id = s.parsing_user_id
};

our $sth = $dbh->prepare($sql);
our $rv = $sth->execute || die "error with statement $sql \n";

# a collection of sql addresses per user
our %sqlAddresses=();

while( my $ary = $sth->fetchrow_arrayref ) {
	#print STDERR "." unless $counter++ % 100;
	my @colarray=(@{$ary})[1..$#{$ary}];
	$sqlstats{$ary->[0]} = \@colarray;
	push @{$sqlAddresses{$ary->[1]}}, $ary->[0];
}

# don't save addresses for SYS
delete $sqlAddresses{'SYS'};

print STDERR "\n";

# get the sql

$sql=q{
	select  address, sql_text
	from v$sqltext
	order by address, piece
};

$sth = $dbh->prepare($sql);

use vars qw{$rv};
$rv = $sth->execute || die "error with statement $sql \n";


$|++;

$counter = 0;
while( my $ary = $sth->fetchrow_arrayref ) {
	print STDERR "." unless $counter++ % 100;
	$sqlstats{$ary->[0]}->[$sqltextEl] .= $ary->[1];
}


# calculate checksums
foreach my $key ( keys %sqlstats ) {
	# each line is terminated with CTRL-0 (zero) for some reason
	# get rid of it
	chop ($sqlstats{$key}->[$sqltextEl]);
	my $ctx = Digest::MD5->new;
	$ctx->add($sqlstats{$key}->[$sqltextEl]);
	$sqlstats{$key}->[$sqlChksumEl] = uc($ctx->hexdigest);
}

# get the snap date and pk
my $nlsDateFormat = 'mm/dd/yyyy hh24:mi:ss';
$dbh->do(qq{alter session set nls_date_format = '$nlsDateFormat'});
$repDbh->do(qq{alter session set nls_date_format = '$nlsDateFormat'});

# get the global name
my $gn = new PDBA::GQ($dbh,'global_name');
my $gnHash = $gn->next;
my $globalName = $gnHash->{GLOBAL_NAME};
undef $gn;
undef $gnHash;
print "Global Name: $globalName\n" if $verbose;

# get the database system date
my $hSysdate = new PDBA::GQ($dbh,'dual', {COLUMNS=>['sysdate']});
my $sysdateHash = $hSysdate->next;
my $systemDate = $sysdateHash->{SYSDATE};
undef $hSysdate;
undef $sysdateHash;
print "System Date: $systemDate\n" if $verbose;

#use Data::Dumper;
#print Dumper(\%sqlstats);
#print Dumper(\%sqlAddresses);
#exit;

# 128k  - if more than this your sql is too big
$repDbh->{LongReadLen} = 128 * 2**10;
$repDbh->{LongTruncOk} = 0;

# look up stored sql and explain plan info and save in a hash

my $lookupSql = '';
if ( $dateSpecific ) {
	$lookupSql = qq{
		select 
			s.username
			, s.chksum sql_chksum
			, s.sqltext
			, e.chksum exp_chksum
			, e.exptext
			, d.snap_date
		from pdba_sxp_dates d, pdba_sxp_sql s, pdba_sxp_exp e
		where s.pk = e.pdba_sxp_sql_pk
		and s.snap_date_pk = d.pk
		and d.pk = ?
		and s.username = ?
		and s.chksum = ?
		order by username, s.chksum
	};
} else {
	$lookupSql = qq{
		select 
			s.username
			, s.chksum sql_chksum
			, s.sqltext
			, e.chksum exp_chksum
			, e.exptext
			, d.snap_date
		from pdba_sxp_dates d, pdba_sxp_sql s, pdba_sxp_exp e
		where s.pk = e.pdba_sxp_sql_pk
		and s.snap_date_pk = (
			select max(snap_date_pk)
			from pdba_sxp_sql s2
			where s.username = s2.username
			and s.chksum = s2.chksum
		)
		and s.username = ?
		and s.chksum = ?
		order by username, d.snap_date desc
	};
}

my $hLookup = $repDbh->prepare($lookupSql);

#now run the explain plan and capture output

my $statementId = 'SXPEXP';
my $deleteSql = qq{delete from plan_table where statement_id = '$statementId'};
my $explainBaseSql = qq{explain plan set statement_id = '$statementId' for };

my ( 
	$rUsername, $rSqlChksum, $rSnapshotDate, $rSqlText, 
	$rCurrentExplainPlan, $rStoredExplainPlan,
);

foreach my $user ( keys %sqlAddresses ) {

	my $userPassword = PDBA::OPT->pwcOptions (
		INSTANCE => lc($optctl{database}),
		MACHINE => lc($optctl{machine}),
		USERNAME => lc($user)
	);

	unless ( $userPassword ) {
		warn "no password available from PWD for $user\n";
		next;
	}

	# get a connection for this user

	my $userDbh = new PDBA::CM(
		DATABASE => $optctl{database},
		USERNAME => $user,
		PASSWORD => $userPassword,
	);

	eval { PDBA->chkForPlanTable($userDbh) };

	if ( $@ ) {
		warn "\n\nWARNING: cannot create plan table for $user\n";
		next;
	}

	my $counter = 0;
	foreach my $address ( @{$sqlAddresses{$user}} ) {

	 	print STDERR "." unless $counter++ % 100;

		# sql is not stored in formatted form
		my $sqlStatement = $sqlstats{$address}->[$sqltextEl];


		# only interested in SELECT, INSERT, UPDATE, DELETE
		# get first word of sql and skip if not one of these
		my $tmpsql = $sqlStatement;
		$tmpsql =~ s/^\s+//;
		my ($keyword) = split(/\s+/, $tmpsql);
		$keyword = uc($keyword);
		
		unless (
			$keyword eq 'SELECT'
			|| $keyword eq 'INSERT'
			|| $keyword eq 'UPDATE'
			|| $keyword eq 'DELETE'
		) {next}


		PDBA->formatSql(\$sqlStatement);

		#warn "formatted sql: $sqlStatement\n";

		if ( $dateSpecific ) {
			$hLookup->execute(
				$rptDateHash->{startDatePk},
				uc($user),
				$sqlstats{$address}->[$sqlChksumEl]
			);
		} else {
			$hLookup->execute(
				uc($user),
				$sqlstats{$address}->[$sqlChksumEl]
			);
		}

		my $storedStatRef = $hLookup->fetchrow_hashref;
		$hLookup->finish;

		# don't bother generating explain plan if sql not
		# already in repository for comparison
		next unless $storedStatRef;

		# temp
		if ( $optctl{verbose} ) {
			warn "We have a match!\n";
			warn "Current SQL chksum: $sqlstats{$address}->[$sqlChksumEl]\n";
			warn "Stored  SQL chksum: $storedStatRef->{SQL_CHKSUM}\n";
		}

		# delete from plan table
		my $sth = $userDbh->prepare($deleteSql);
		$sth->execute;

		eval {
			# do the explain plan
			local $userDbh->{PrintError} = 0;
			my $explainSql = $explainBaseSql . $sqlStatement;
			$sth = $userDbh->do($explainSql);
		};

		if ($@) {

			my $errstr = $@;
			# remove newlines
			$errstr =~ s/\n/ /gmo;
			# compress space
			$errstr =~ s/\s+/ /gmo;
			# get relevant oracle error
			$errstr =~ s/^(.*)(ORA-[\d]+:)(.+)$/$2$3/gom;

			warn "ERR: $errstr\n";

			next;
		}


		my $explainOutputRef = PDBA->getXP($userDbh,
			STATEMENT_ID => $statementId,
		);

		my $ctx = Digest::MD5->new;
		$ctx->add(${$explainOutputRef});
		my $currExpChksum = uc($ctx->hexdigest);

		if ( $optctl{verbose} ) {
			warn "Current EXP chksum: $currExpChksum\n";
			warn "Stored  EXP chksum: $storedStatRef->{EXP_CHKSUM}\n";
			warn "\n";
		}

		unless  ( $storedStatRef->{EXP_CHKSUM} eq $currExpChksum ) {
			#print "NON matching XP\n";
			( 
				$rUsername, $rSqlChksum, $rSnapshotDate, $rSqlText, 
				$rCurrentExplainPlan, $rStoredExplainPlan,
			) = (
				$user, $sqlstats{$address}->[$sqlChksumEl],
				$storedStatRef->{SNAP_DATE},
				$sqlStatement,
				${$explainOutputRef},
				$storedStatRef->{EXPTEXT}
			);
			write;
		}


	}

}

$hLookup->finish;
$repDbh->disconnect;
$dbh->disconnect;


#----------------------------------------------------------------------------------------

sub usage {
	my $exitVal = shift;
	use File::Basename;
	my $basename = basename($0);
	print qq/

usage: $basename 


  -machine          target database server
  -database         target instance
  -username         target instance dba account
  -password         target instance dba password (optional)
  -rep_machine      repository_server
  -rep_database     repository_database
  -rep_username     repository username
  -rep_password     repository username password (optional)
  -rep_report_date  date of SQL to compare to in repository (optional)

  passwords are optional only if the PWD password server is in use

  the password server must be in use for this script to generate
  execution plans for the SQL statements collected 

/;
	exit $exitVal;
};

format STDOUT_TOP =

Active SQL From Data Dictionary Matching SQL In Repository         Page:   @####
	$%
But With Different Execution Paths                             
Database: @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  Date: @<<<<<<<<<<<<<<<<<<<<
	$globalName, $systemDate

================================================================================

.

no warnings;

format STDOUT = 
SQL Username: @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	$rUsername
SQL Check Sum: @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	$rSqlChksum 
SnapShot Date: @<<<<<<<<<<<<<<<<<<<<<
	$rSnapshotDate
SQL Text: 
@*
	$rSqlText

Current Explain Plan: 
@*
	$rCurrentExplainPlan

Stored Explain Plan: 
@*
	$rStoredExplainPlan,

.


