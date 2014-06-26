#!/export/home/oracle/perl/bin/perl -w

eval 'exec /export/home/oracle/perl/bin/perl -w -S $0 ${1+"$@"}'
    if 0; # not running under some shell

# sxp.pl
# sql explain plan generation
# stores sql and formatted explain plan output

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

our %sqlstats=();
our %sqltext=();

# get the statistics portion

our $counter = 0;

our $sql = q{
	select s.address, u.username
	from v$sqlarea s, dba_users u
	where u.user_id = s.parsing_user_id
};

our $sth = $dbh->prepare($sql);
our $rv = $sth->execute || die "error with statement $sql \n";

while( my $ary = $sth->fetchrow_arrayref ) {

	#print STDERR "." unless $counter++ % 100;
	my @colarray=(@{$ary})[1..$#{$ary}];

	# skip null address or username
	# not sure why it happens, but it does
	#next unless $colarray[0];
	#next unless $colarray[1];

	$sqlstats{$ary->[0]} = \@colarray;
}

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
	$sqltext{$ary->[0]} .= $ary->[1];
}


# calculate checksums
foreach my $key ( keys %sqltext ) {

	# each line is terminated with CTRL-0 (zero) for some reason
	# get rid of it
	chop $sqltext{$key};

	my $ctx = Digest::MD5->new;
	$ctx->add($sqltext{$key});
	$sqlstats{$key}->[1] = uc($ctx->hexdigest);

}

# get the global name
my $gn = new PDBA::GQ($dbh,'global_name');
my $gnHash = $gn->next;
my $globalName = $gnHash->{GLOBAL_NAME};
undef $gn;
undef $gnHash;

print "Global Name: $globalName\n" if $verbose;

# get the snap date and pk
my $nlsDateFormat = 'mm/dd/yyyy hh24:mi:ss';

$sql = qq{select to_char(sysdate,'$nlsDateFormat') snap_date from dual};
$sth = $dbh->prepare($sql);
$sth->execute;
my ($snapDate) = $sth->fetchrow_array;

# insert snap_date into repository table
$sql = qq{ insert into
	pdba_sxp_dates(snap_date,global_name)
	values (to_date('$snapDate','$nlsDateFormat'),'$globalName')
};
$sth = $repDbh->prepare($sql);
$sth->execute;

# get the PK of just inserted snap_date
my $snapObj = new PDBA::GQ( $repDbh, 'pdba_sxp_dates',
	{
		COLUMNS => ['pk'],
		WHERE => qq{ snap_date = to_date('$snapDate','$nlsDateFormat')}
	}
);
my $snapHash = $snapObj->next;
my $snapPk = $snapHash->{PK};
undef $snapObj;

print "SNAP PK: $snapPk\n" if $verbose;

#use Data::Dumper;
#print  "\n\n", Dumper(\%sqlstats), "\n\n";
#print  "\n\n", Dumper(\%sqltext), "\n\n";

# sometimes the username is undef by the time
# it reaches here.  not sure why yet, but gotta
# get rid of them if it happens
foreach my $key ( keys %sqlstats ) {
	unless ( $sqlstats{$key}->[0] ) {
		delete $sqlstats{$key};
	}
}

# sort the SQL by username so that a connection
# to the database only needs to be made once
# per user
our @sortkeys =
	sort { $sqlstats{$a}->[0] cmp $sqlstats{$b}->[0] }
	keys %sqlstats;


my $repSxpInsertSql = qq{
	insert into pdba_sxp_sql(snap_date_pk, username, chksum, sqltext)
	values(?,?,?,?)
};

my $hRepInsert = $repDbh->prepare($repSxpInsertSql);

my %sqlUsers=();

{

local $repDbh->{PrintError} = 0;

for my $key ( @sortkeys ) {

	next unless $key;
	next unless $sqlstats{$key}->[0];

	# only interested in SELECT, INSERT, UPDATE, DELETE
	# get first word of sql and skip if not one of these
	my $tmpsql = $sqltext{$key};
	next unless $tmpsql;
	$tmpsql =~ s/^\s+//;
	my ($keyword) = split(/\s+/, $tmpsql);
	$keyword = uc($keyword);
	

	unless (
		$keyword eq 'SELECT'
		|| $keyword eq 'INSERT'
		|| $keyword eq 'UPDATE'
		|| $keyword eq 'DELETE'
	) {next}

	# don't get SYS sql
	unless ( $sqlstats{$key}->[0] eq 'SYS' ) {

		printf( "%-30s %s %s\n%s\n\n",
			$sqlstats{$key}->[0],
			$sqlstats{$key}->[1],
			$sqltext{$key},
			'=' x 80
		) if $verbose;

		eval {
			$hRepInsert->execute(
				$snapPk, 
				$sqlstats{$key}->[0], # username
				$sqlstats{$key}->[1], # chksum
				$sqltext{$key} # sql
			);
		};

		if ( $@ ) {
			my $err = $repDbh->err;
			my $errstr = $repDbh->errstr;

			# ignore the unique constraint errors
			# as it's duplicate SQL
			# don't know why it's in v$sqltext, but it's there
			unless ( 1 == $err ) {
				warn "error $err encountered\n";
				warn "message: $errstr\n";
				$repDbh->rollback;
				$repDbh->disconnect;
				$dbh->disconnect;
				die "terminating sxp due to error\n"
			}
		}

		$sqlUsers{$sqlstats{$key}->[0]} = '';

	}
}

}

$repDbh->commit;

#now run the explain plan and capture output

# 128k  - if more than this your sql is too big
$repDbh->{LongReadLen} = 128 * 2**10;
$repDbh->{LongTruncOk} = 0;

foreach my $user ( keys %sqlUsers ) {

	my $userPassword = PDBA::OPT->pwcOptions (
		INSTANCE => lc($optctl{database}),
		MACHINE => lc($optctl{machine}),
		USERNAME => lc($user)
	);

#print "INSTANCE =>", lc($optctl{database}) ,"\n";
#print "MACHINE  =>", lc($optctl{machine}) ,"\n";
#print "USERNAME =>", lc($user) ,"\n";

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

	my $statementId = 'SXPEXP';

	my $userSql = new PDBA::GQ(
		$repDbh, 'pdba_sxp_sql',
		{
			COLUMNS => [qw{ pk sqltext }],
			WHERE => q{snap_date_pk = ? and username = ?},
			BINDPARMS => [$snapPk, uc($user)]
		}
	);

	my $deleteSql = qq{delete from plan_table where statement_id = '$statementId'};

	my $insertExpOkSql = qq{
		insert into pdba_sxp_exp( pdba_sxp_sql_pk, chksum, exptext )
		values(?,?,?)
	};

	my $insertExpErrSql = qq{
		insert into pdba_sxp_exp( pdba_sxp_sql_pk,  explain_error )
		values(?,?)
	};

	my $explainBaseSql = qq{explain plan set statement_id = '$statementId' for };

	my $counter = 0;
	while ( my $row = $userSql->next ) {

	 	print STDERR "." unless $counter++ % 100;

		# sql is not stored in formatted form
		PDBA->formatSql(\$row->{SQLTEXT});

		# delete from plan table
		my $sth = $userDbh->prepare($deleteSql);
		$sth->execute;

		eval {
			# do the explain plan
			local $userDbh->{PrintError} = 0;
			my $explainSql = $explainBaseSql . $row->{SQLTEXT};
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

			#warn "ERR: $errstr\n";

			# save the error message
			my $sth = $repDbh->prepare($insertExpErrSql);
			$sth->execute($row->{PK}, substr($errstr,0,100));

		} else {

			my $explainOutputRef = PDBA->getXP($userDbh,
				STATEMENT_ID => $statementId,
			);

			my $ctx = Digest::MD5->new;
			$ctx->add(${$explainOutputRef});
			my $chksum = uc($ctx->hexdigest);

			$sth = $repDbh->prepare($insertExpOkSql);
			$sth->execute($row->{PK}, $chksum, ${$explainOutputRef} );

		}

	}

}

$repDbh->commit;
$repDbh->disconnect;
$dbh->disconnect;


#----------------------------------------------------------------------------------------

sub usage {
	my $exitVal = shift;
	use File::Basename;
	my $basename = basename($0);
	print qq/

usage: $basename 


  -machine       target database server
  -database      target instance
  -username      target instance dba account
  -password      target instance dba password (optional)
  -rep_machine   repository_server
  -rep_database  repository_database
  -rep_username  repository username
  -rep_password  repositiory username password (optional)

  passwords are optional only if the PWD password server is in use

/;
	exit $exitVal;
};




