#!/usr/bin/perl 

=head1 idxr.pl

 rebuild indexes
 uses 'analyze index validate structure' to rebuild
 the index if the estimated height is less than actual
 or if the percentage of deleted rows exceeds a configurable
 threshold

=cut

use FileHandle;
use DBI;
use PDBA;
use PDBA::CM;
use PDBA::GQ;
use PDBA::OPT;
use PDBA::ConfigFile;
use PDBA::LogFile;
use strict;
use warnings;

use Carp;
use Getopt::Long;

my %optctl = ();

Getopt::Long::GetOptions(
	\%optctl, 
	"machine=s",
	"database=s",
	"username=s",
	"password=s",
	"conf=s",
	"target_schema=s",
	"compute_statistics!",
	"help"
);

usage(1) if $optctl{help};

my $configFile = $optctl{conf} ? $optctl{conf} : 'idxr.conf';

unless (  new PDBA::ConfigLoad( FILE => $configFile ) ) {
	die "error loading $configFile\n";
}

PDBA::LogFile->makepath($idxr::config{logFile});
my $logFh = new PDBA::LogFile($idxr::config{logFile});

my($db, $username, $password);

if ( ! defined($optctl{database}) ) {
	warn "database required\n";
	usage(1);
}
$db=$optctl{database};

if ( ! defined($optctl{username}) ) {
	warn "username required\n";
	usage(1);
}

if ( ! defined($optctl{target_schema}) ) {
	warn "target_schema required\n";
	usage(1);
}

$username=$optctl{username};

# lookup the password if not on the command line
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

# determine how long in seconds this 
# program is allowed to run
#my $maxRunSeconds = $idxr::config{maxRunTime} * 60;

my $maxRunSeconds = idxrp->startTimer($idxr::config{maxRunTime});

$logFh->printflush("starting\n");
$logFh->printflush("maxRunSeconds:$maxRunSeconds\n");

my $dbh = new PDBA::CM(
	DATABASE => $optctl{database},
	USERNAME => $optctl{username},
	PASSWORD => $password,
);

my $systemDate = PDBA->sysdate($dbh, NLS_DATE_FORMAT => 'yyyy/mm/dd hh24:mi');
my $globalName = PDBA->globalName($dbh);

$logFh->printflush("sysDate:$systemDate\n");
$logFh->printflush("globalName:$globalName\n");

# this sql will retrieve the names of indexes
# in a schema.  If the index has partitions or
# subpartions, those will be listed instead.  The
# reason for that is that partitions and subpartitions
# can be rebuilt independently of the index. There is
# later code that will find the name of the index
# for partitions and subpartitions

my $oracleVersion = PDBA->oracleVersion($dbh);;
# get left to characters of version
$oracleVersion =~ s/^(..).*$/$1/;

my $idxRebuildCandidateSql = $oracleVersion < 81
? qq{select
	'INDEX' index_type, index_name
	from dba_indexes
	where owner = upper(?)
	and (
		last_analyzed <= sysdate - ?
		or last_analyzed is null
	)	
}
: qq{select
	'INDEX' index_type, index_name
	from dba_indexes
	where owner = upper(?)
	and (
		last_analyzed <= sysdate - ?
		or last_analyzed is null
	)	
	minus (
		select distinct 'INDEX' index_type, index_name
		from dba_ind_partitions 
		where index_owner = upper(?)
		union
		select distinct 'INDEX' index_type, index_name
		from dba_ind_subpartitions
		where index_owner = upper(?)
	)
	union 
	select 'INDEX PARTITION' , partition_name
	from dba_ind_partitions
	where index_owner = upper(?)
	and (
		last_analyzed <= sysdate - ?
		or last_analyzed is null
	)	
	union 
	select 'INDEX SUBPARTITION' , subpartition_name
	from dba_ind_subpartitions
	where index_owner = upper(?)
	and (
		last_analyzed <= sysdate - ?
		or last_analyzed is null
	)	
}
;

my $sth = $dbh->prepare($idxRebuildCandidateSql);

my $target = uc($optctl{target_schema});
# don't check indexes that have been analyzed more recently
# than a specified number of days. The reason for this is
# that large systems may have many thousands of indexes, more
# than can be done in a single pass.  It may take several passes
# if you have an hour each night to run this, and it takes 20 
# hours to validate structure, rebuild and analyze your indexes,
# you would set this parameter to 20 and maxRunTime to 60

my $mostRecentDays = $idxr::config{mostRecentlyAnalyzed};

$logFh->printflush("schema:$target\n");
$logFh->printflush("checking indexes analyzed more than $mostRecentDays days ago \n");

if ($oracleVersion < 81 ) {
	$sth->execute(
		$target,
		$mostRecentDays
	);
} else {
	$sth->execute(
		$target,
		$mostRecentDays,
		$target,
		$target,
		$target,
		$mostRecentDays,
		$target,
		$mostRecentDays,
	);
}

while(  my $ary = $sth->fetchrow_hashref ) {
	$logFh->printflush("checking $ary->{INDEX_TYPE} $ary->{INDEX_NAME}\n");

	# generate and execute SQL for 'validate structure'
	# return results in hashref
	my $gv = idxrp->genValidateSql($dbh,$target,$ary);

	#print "SQL: $gv->{VALIDATE_SQL}\n";

	$dbh->do($gv->{VALIDATE_SQL});

	my $statRow = idxrp->getStat($dbh);

	if ( defined $statRow &&
		(
			'YES' eq $statRow->{CAN_REDUCE_LEVEL} 
			or
			$statRow->{PCT_DELETED} >= $idxr::config{pctDeletedThreshold}
		)
	) {
		$logFh->printflush("Rebuilding $gv->{INDEX_TYPE} $ary->{INDEX_NAME}\n");
		
		my $rebuildSql = idxrp->genRebuildSql($gv, \%optctl);

		# turn off error printing
		# attempt to rebuild index
		# trap error 8108 that may occur attempting
		# to rebuild online, and attempt offline
		my $printErrorState = $dbh->{PrintError};
		eval {
			$dbh->{PrintError} = 0;
			$logFh->printflush("Attempting to Rebuild Index online\n");
			$dbh->do($rebuildSql);
			$logFh->printflush("Rebuilt $ary->{INDEX_TYPE} $ary->{INDEX_NAME} online\n");
		};

		my ($err, $errstr) = ( $dbh->err, $dbh->errstr);

		if ( defined $err ) {
			# error 8108 occurs when index type cannot be built online
			if ( '8108' eq $err  ) {
				$rebuildSql =~ s/\sonline\s//g;
				eval {
					$dbh->do($rebuildSql);
					$logFh->printflush("Rebuilt $ary->{INDEX_TYPE} $ary->{INDEX_NAME} offline\n");
				};
				my ($err, $errstr) = ( $dbh->err, $dbh->errstr);
				if ( defined $err ) { 
					$logFh->printflush("error rebuilding index\n");
					$logFh->printflush("SQL: $rebuildSql\n");
					$logFh->printflush("ERROR: $errstr\n");
				}
			} else {
				$logFh->printflush("error rebuilding index\n");
				$logFh->printflush("SQL: $rebuildSql\n");
				$logFh->printflush("ERROR: $errstr\n");
			}
		}

		# reset print error state
		$dbh->{PrintError} = $printErrorState;

	}

	if ( my $runSeconds = idxrp->checkTimer ) {
		$logFh->printflush("Max runtime of $maxRunSeconds seconds reached\n");
		$logFh->printflush("Actual runtime was $runSeconds seconds\n");
		last;
	}

}

$logFh->printflush("exiting\n");
$sth->finish;
$dbh->disconnect;

#### 

sub usage {
	my $exitVal = shift;
	use File::Basename;
	my $basename = basename($0);
	print qq/
$basename

usage: $basename 

-machine             database server 
-database            database to check indexes in
-username            dba account
-password            dba password ( optional if using pwd server )
-conf                configuration file - default is idxr.conf
-target_schema       schema to analyze indexes for
-compute_statistics  causes statistics to be computed during index rebuild

/;
	exit $exitVal;
};


package idxrp;

sub genValidateSql {

	my ($self, $dbh, $target, $rowhash) = @_;

	my $rh = {};

	if ( 'INDEX PARTITION' eq $rowhash->{INDEX_TYPE} ) {

		$rh->{INDEX_TYPE} = 'INDEX PARTITION';
		my $sql = qq{
			select index_name
			from dba_ind_partitions
			where index_owner = ?
			and partition_name = ?
		};

		my $sth = $dbh->prepare($sql);
		$sth->execute($target, $rowhash->{INDEX_NAME});
		my $row = $sth->fetchrow_hashref;

		$rh->{INDEX_NAME} = $row->{INDEX_NAME};
		$rh->{PARTITION_NAME} = $rowhash->{INDEX_NAME};

		$rh->{VALIDATE_SQL} = 'analyze index ' 
			. $target . '.' . $rh->{INDEX_NAME}
			. ' partition (' . $rh->{PARTITION_NAME} 
			. ') validate structure';

	} elsif ( 'INDEX SUBPARTITION' eq $rowhash->{INDEX_TYPE} ) {

		$rh->{INDEX_TYPE} = 'INDEX SUBPARTITION';
		my $sql = qq{
			select index_name
			from dba_ind_subpartitions
			where index_owner = ?
			and subpartition_name = ?
		};

		my $sth = $dbh->prepare($sql);
		$sth->execute($target, $rowhash->{INDEX_NAME});
		my $row = $sth->fetchrow_hashref;

		$rh->{INDEX_NAME} = $row->{INDEX_NAME};
		$rh->{SUBPARTITION_NAME} = $rowhash->{INDEX_NAME};

		$rh->{VALIDATE_SQL} = 'analyze index ' 
			. $target . '.' . $rh->{INDEX_NAME}
			. ' subpartition (' . $rh->{SUBPARTITION_NAME}
			. ') validate structure';


	} else {
		$rh->{INDEX_TYPE} = 'INDEX';
		$rh->{INDEX_NAME} = $rowhash->{INDEX_NAME};
		$rh->{VALIDATE_SQL} = 'analyze index ' 
			. $target . '.' . $rh->{INDEX_NAME}
			. ' validate structure';
	}

	return $rh;

}

=head1 getStat()

This method is based on information from the Oracle paper
'How To Stop Defragmenting and Start Living: The Definitive Word
On Fragmentation'  Bhaskmar Himatsingka, Juan Loaiza of Oracle Corp.

http://technet.oracle.com/deploy/availability/pdf/defrag.pdf

=cut

sub getStat {
	my ($self, $dbh) = @_;

	my $statSql = q{
		select 
			name index_name
			, decode (
				sign(
					ceil(
						log(
							br_blk_len/(br_rows_len/br_rows), 
							lf_blk_len/(
								decode(lf_rows_len - del_lf_rows_len,
									0,0.000001,
									lf_rows_len - del_lf_rows_len
								)
								/
								decode(lf_rows - del_lf_rows,
									0,0.000001,
									lf_rows - del_lf_rows
								)
							)
						)
					) + 1 - height
				)
				, -1, 'YES'
				, 'NO'
			) can_reduce_level 
			,del_lf_rows*100/decode(lf_rows, 0, 1, NULL, 1, lf_rows) pct_deleted
		from index_stats
		where lf_rows <> 0
		and del_lf_rows <> 0
		and del_lf_rows_len <> 0
		and lf_rows_len <> 0
		and br_rows <> 0
		and br_rows_len <> 0
	};

	my $statSth = $dbh->prepare($statSql);
	$statSth->execute;
	my $row = $statSth->fetchrow_hashref;

	return $row ? $row : undef;

}

sub genRebuildSql {

	my ($self, $gv, $opthash ) = @_;
	my $rebuildSql = undef;

	if ( 'INDEX PARTITION' eq $gv->{INDEX_TYPE} ) {

		$rebuildSql = qq{
			alter index $opthash->{target_schema}.$gv->{INDEX_NAME}
			rebuild partition $gv->{PARTITION_NAME} online };

		if ($opthash->{compute_statistics} ) 
		{$rebuildSql .= ' compute statistics'}

	} elsif ( 'INDEX SUBPARTITION' eq $gv->{INDEX_TYPE} ) {

		$rebuildSql = qq{
			alter index $opthash->{target_schema}.$gv->{INDEX_NAME}
			rebuild  subpartition $gv->{SUBPARTITION_NAME} online };

		if ($opthash->{compute_statistics} ) 
		{$rebuildSql .= ' compute statistics'}

	} else {

		$rebuildSql = qq{
			alter index $opthash->{target_schema}.$gv->{INDEX_NAME}
			rebuild online };

		if ($opthash->{compute_statistics} ) 
		{$rebuildSql .= ' compute statistics'}

	}
	
	return $rebuildSql;
}

# use a closure for the timing
{

	# determine how long in seconds this 
	# program is allowed to run
	my $maxRunSeconds = undef;
	# start time in seconds - the epoch
	my $startTimeSeconds = time;

	sub startTimer {
		my ($self, $maxMinutes) = @_;
		$maxRunSeconds = $idxr::config{maxRunTime} * 60;
		$startTimeSeconds = time;
		return $maxRunSeconds;
	}

	sub checkTimer {
		my $self = shift;
		my $currTimeSeconds = time;
		my $runSeconds = $currTimeSeconds - $startTimeSeconds;
		if ( $runSeconds >= $maxRunSeconds ) {
			return $runSeconds;
		} else { return 0 }
	}

}


