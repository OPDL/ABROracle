
package PDBA::OPT;

$VERSION = '0.01';

use strict;
no strict 'vars';

use Getopt::Long;
use PDBA::ConfigFile;
use Carp;
%optctl = ();

=head2 pwcOptions

pwcOptions is a wrapper for retrieving command line arguments
for the password client, looking up the password and returning
the remainder of @ARGV unmolested

Valid attributes:

  HOST
  PORT
  MACHINE
  INSTANCE
  USERNAME
  CONF
  KEY
  PWD_USERNAME
  PWD_PASSWORD
  DEBUG

The attributes can be used to override any of the options found
in the config file or on the command line.

The attributes most often used will be MACHINE,INSTANCE and 
USERNAME to specify which password you need.

This module will assume that you have a pwc.conf file setup
and ready to use, and will attempt to use it.  If it is
not available, this module will croak.

e.g.

my $password = PDBA::OPT->pwcOptions (
	MACHINE => 'sherlock',
	INSTANCE => 'orcl',
	USERNAME => 'bilbo',
);

print "Password:  $password\n";

=cut


sub pwcOptions {

	my $self = shift;
	my %args = @_;

	Getopt::Long::Configure(qw{pass_through});

	use PDBA::PWC;

	# read passthrough options
	# this method of doing it prevents options from
	# being processed more than once if there are 
	# multiple calls to PDBA::OPT

	my %optionList = (
		pwc_host => '=s',
		pwc_port => '=i',
		pwc_machine => '=s',
		pwc_instance => '=s',
		pwc_username => '=s',
		pwc_conf => '=s',
		pwc_key => '=s',
		pwc_my_username => '=s',
		pwc_my_password => '=s',
		pwc_debug => '!',
	);

	foreach my $key  ( keys %optionList ) {
		unless ( $optctl{$key} ) {
			my $optionParm = $key . $optionList{$key};
			GetOptions(\%optctl,$optionParm);
		}
	}

	$optctl{pwc_conf} = 'pwc.conf' unless $optctl{pwc_conf};

	# overrides from the config file
	if ( exists( $optctl{pwc_conf} ) ) {
		use PDBA::ConfigFile;
		unless ( new PDBA::ConfigLoad( FILE => $optctl{pwc_conf} ) ) {
			croak "could not load config file  $optctl{pwc_conf}";
		}

		for my $key ( keys %pwc::optctl ) {
			$optctl{'pwc_' . $key} = $pwc::optctl{$key} unless exists $optctl{'pwc_' . $key};
		}
	}

	# overrides from args passed to pwcOptions
	# just a bunch of ifs
	if (defined($args{HOST})){ $optctl{pwc_host} = $args{HOST} }
	if (defined($args{PORT})){ $optctl{pwc_port} = $args{PORT} }
	if (defined($args{MACHINE})){ $optctl{pwc_machine} = $args{MACHINE} }
	if (defined($args{INSTANCE})){ $optctl{pwc_instance} = $args{INSTANCE} }
	if (defined($args{USERNAME})){ $optctl{pwc_username} = $args{USERNAME} }
	if (defined($args{CONF})){ $optctl{pwc_conf} = $args{CONF} }
	if (defined($args{KEY})){ $optctl{pwc_key} = $args{KEY} }
	if (defined($args{PWD_USERNAME})){ $optctl{pwc_my_username} = $args{PWD_USERNAME} }
	if (defined($args{PWD_PASSWORD})){ $optctl{pwc_my_password} = $args{PWD_PASSWORD} }
	if (defined($args{DEBUG})){ $optctl{pwc_debug} = $args{DEBUG} }

	if (
		! defined( $optctl{pwc_host})
		|| ! defined( $optctl{pwc_port})
		|| ! defined( $optctl{pwc_machine})
		|| ! defined( $optctl{pwc_instance})
		|| ! defined( $optctl{pwc_username})
		|| ! defined( $optctl{pwc_key})
		|| ! defined( $optctl{pwc_my_username})
		|| ! defined( $optctl{pwc_my_password})
	) {
	croak qq/usage: $0 with PDBA::OPT
  --pwc_host <password server> 
  --pwc_port <tcp port>
  --pwc_machine <database server>
  --pwc_instance <database instance> 
  --pwc_username <database username> 
  --pwc_conf <configuration file - optional but recommended >
  --pwc_key <encryption key>
  --pwc_my_username <password server username>
  --pwc_my_password <password server password
/;
	}

	my $remote_host=$optctl{pwc_host};
	my $remote_port=$optctl{pwc_port};
	my $machine=$optctl{pwc_machine};
	my $instance=$optctl{pwc_instance};
	my $username=$optctl{pwc_username};
	my $myusername=$optctl{pwc_my_username};
	my $mypassword=$optctl{pwc_my_password};
	my $key=$optctl{pwc_key};

	$optctl{pwc_debug} = exists $optctl{pwc_debug} ? $optctl{pwc_debug} : 0;

	my $client = new PDBA::PWC(
		host => $remote_host,
		port => $remote_port
	);

	$client->authenticate(
		username => $myusername,
		password => $mypassword,
		key => $key,
		debug => $optctl{pwc_debug}
	);

	# get response
	my $password = $client->getPassword(
		machine => $machine,
		instance => $instance,
		username => $username,
		key => $key, 
		debug => $optctl{pwc_debug} 
	);

	return $password;

};

1;

