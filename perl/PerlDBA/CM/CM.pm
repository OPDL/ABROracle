

package PDBA::CM;

use PDBA;

our $VERSION = '0.01';

=head1 Connection Manager

$Author: jkstill $
$Date: 2002/01/07 02:08:19 $
$Id: CM.pm,v 1.15 2002/01/07 02:08:19 jkstill Exp $


=cut

require DBI;

@ISA=qw(DBI);

__PACKAGE__->init_rootclass;

#use DBI;
use PDBA::ConfigFile;
use Carp;
use strict;
use warnings;
use diagnostics;

=head1

sub new

use to establish a new connection to an Oracle database

example: my $dbh = new CM(
  DATABASE => $db, 
  USERNAME => $username, 
  PASSWORD => $password
);

If you have setup a configuration file for CM, it will
use the value of $db to lookup the values for ORACLE_HOME,
ORACLE_BASE and TNS_ADMIN.  

ORACLE_HOME/bin will be prepended to the current path.

If you are on a unix system, the value of LD_LIBRARY_PATH 
will be set as well.

If $db has not been setup in the configuration file, then
the environment will be set to the 'default' environment, if
it has been setup in the configuration file.

The name of this file defaults to 'cm.conf'.  It may be found
in either the current directory, your home directory or
in the directory pointed to by PDBA_HOME.

You may optionally specify the location of the CM configuration
file via the the FILE and PATH hash arguments.

e.g. 
  my $dbh = new PDBA::CM(
	 DATABASE => 'orcl',
	 USERNAME => 'scott',
	 PASSWORD => 'tiger',
    PATH => "$ENV{ORACLE_HOME}/conf",
    FILE => 'cm.conf'
  ); 

The use of this conguration file is completely optional.  If not
used, you must have the ORACLE_HOME, ORACLE_SID and other 
environment variables set as you would normally do.

If the ORACLE_HOME environment variable is set, the cm.conf
file will be ignored, unless you set the FORCE_CONFIG attribute.


e.g. 
  my $dbh = new PDBA::CM(
	 DATABASE => 'orcl',
	 USERNAME => 'scott',
	 PASSWORD => 'tiger',
    FORCE_CONFIG => 1
  ); 



If you wish to connect as either SYSOPER or SYSDBA, the 
MODE argument must be used. Accepted values for MODE
are SYSDBA and SYSOPER.

e.g.

 my $dbh = new PDBA::CM(
   DATABASE => 'orcl',
   USERNAME => 'scott',
   PASSWORD => 'tiger',
   MODE => 'SYSOPER' 
 ); 

Please see the sample cm.conf found in the distribution
for further details on it's contents.


=cut

=head1 new

current valid arguments are:

DATABASE
USERNAME
PASSWORD
MODE
PATH
FILE
FORCE_CONFIG

=cut

sub new {

	# class method
	# since it is called by package name, we have
	# to include that in the parameters
	my $pkg = shift;
	my $class = ref($pkg) || $pkg;

	my ( %args ) = @_;

	my $configFile;
	if ( defined $args{FILE} ) {
		$configFile = $args{FILE};
	} else { $configFile = 'cm.conf' }

	my $configPath;
	if ( defined $args{PATH} ) {
		$configPath = $args{PATH};
	} else { $configPath = '' }

	# setup the environment
	# don't change if already set unless FORCE_CONFIG
	# look for specific environment for db
	# then look for default
	# cm.conf is hardcoded config file name
	if ( $args{DEBUG} ) {
		if ( $args{FORCE_CONFIG} and exists( $ENV{ORACLE_HOME}) ) 
			{ delete $ENV{ORACLE_HOME} }
		print "ORACLE_HOME: "; 
		if ( exists($ENV{ORACLE_HOME}) ){ print "$ENV{ORACLE_HOME}\n" } 
		else { print "\n"}
	}

	unless ( $ENV{ORACLE_HOME} ) {
		if ( $args{DEBUG} ) {
			print "setting environment\n";
			print "FILE => $configFile\n";
			print "PATH => $configPath\n";
			print "ConfigPath: $configPath|\n";
		}
		my $db = lc($args{DATABASE});
		if ( my $conf = new PDBA::ConfigLoad( PATH => $configPath, FILE => $configFile ) ) {

			my $envName = 'does not exist';;
			if ( exists($cmconf::env{$db}) ) {
				$envName = $db;
			} elsif(  exists($cmconf::env{default} ) ) {
				$envName = 'default';
			}

			print "setting environment to $envName\n" if $args{DEBUG};

			if ( exists($cmconf::env{$envName} ) ) {
				if ( exists $cmconf::env{$envName}->{ORACLE_HOME} ) {
					$ENV{ORACLE_HOME} = $cmconf::env{$envName}->{ORACLE_HOME};
					if ( 'unix' eq PDBA->osname() ) {
						$ENV{LD_LIBRARY_PATH} = qq{$cmconf::env{$envName}->{ORACLE_HOME}/lib}
							. PDBA->pathsep() 
							. defined $ENV{LD_LIBRARY_PATH} ? $ENV{LD_LIBRARY_PATH} : '' ;
						}
				}
				$ENV{ORACLE_BASE} = $cmconf::env{$envName}->{ORACLE_BASE}
					if exists $cmconf::env{$envName}->{ORACLE_BASE};
				$ENV{TNS_ADMIN} = $cmconf::env{$envName}->{TNS_ADMIN}
					if exists $cmconf::env{$envName}->{TNS_ADMIN};

				if ( PDBA->osname() eq 'unix' ) {
					$ENV{LD_LIBRARY_PATH} =
						qq{$cmconf::env{$envName}->{ORACLE_HOME}/lib} 
						. PDBA->pathsep() . $ENV{LD_LIBRARY_PATH};
				}
			}
		}
	}

	#determine connection mode

	my $connectionMode = 0;
	if ( exists( $args{MODE} )) {
		# set the default
		$connectionMode = 0;
		if ( $args{MODE} eq 'SYSOPER') { $connectionMode = 4 }
		if ( $args{MODE} eq 'SYSDBA' ) { $connectionMode = 2 }
	}

	my $dbh = $class->SUPER::connect(
		'dbi:Oracle:' . $args{DATABASE},
		$args{USERNAME}, $args{PASSWORD},
		{ 
			RaiseError => 1, 
			AutoCommit => 0 ,
			ora_session_mode => $connectionMode
		}
	);

	croak "Connect to $args{USERNAME} failed \n" unless $dbh; 

	# with DBI 1.13 and DBD::Oracle 1.08 this method
	# works as expected.
	# when DBI is upgraded to 1.20 and DBD::Oracle to 1.12,
	# this no longer works and you must just return the dbh
	# handle.  Do not know why yet.

	# DBI 1.13; DBD::Oracle 1.08
   #my $connection = bless $dbh, $class;
	#return $connection;

	# works with all, and the only way to do it
	# with DBI 1.20 and DBD::Oracle 1.08 and newer
	return $dbh;

}

package PDBA::CM::db;
no strict 'vars';
@ISA = qw(DBI::db);

package PDBA::CM::st;
no strict 'vars';
@ISA = qw(DBI::st);

	
1;

