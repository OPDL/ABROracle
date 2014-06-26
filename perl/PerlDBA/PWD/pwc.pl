#!/usr/bin/perl


use IO::Socket;
use Getopt::Long;
use PDBA::PWC;
use PDBA::ConfigFile;

%optctl = ();

GetOptions(\%optctl,
	"host=s",		# remote password server host
	"port=i",		# port to connect to
	"machine=s",	# database server
	"instance=s",	# database instance 
	"username=s",	# database username
	"conf=s",		# configuration file
	"key=s",			# encryption key
	"my_username=s",	# your password server username
	"my_password=s",	# your password server password
	"debug!",			# turn debug on
	"help!"			# get usage screen
);

if ($optctl{help}) { usage(0) };

$optctl{conf} = 'pwc.conf' unless exists $optctl{conf};

unless ( new PDBA::ConfigLoad( FILE => $optctl{conf} ) ) {
	die "could not load config file  $optctl{conf}\n";
}

for my $key ( keys %pwc::optctl ) {
	$optctl{$key} = $pwc::optctl{$key} unless exists $optctl{$key};
}

if ( 
	! defined( $optctl{host})
	|| ! defined( $optctl{port})
	|| ! defined( $optctl{machine})
	|| ! defined( $optctl{instance})
	|| ! defined( $optctl{username})
	|| ! defined( $optctl{key})
	|| ! defined( $optctl{my_username})
	|| ! defined( $optctl{my_password})
) { usage(1) }

$remote_host=$optctl{host};
$remote_port=$optctl{port};
$machine=$optctl{machine};
$instance=$optctl{instance};
$username=$optctl{username};
$myusername=$optctl{my_username};
$mypassword=$optctl{my_password};
$key=$optctl{key};

$optctl{debug} = exists $optctl{debug} ? $optctl{debug} : 0;

my $client = new PDBA::PWC(
	host => $remote_host,
	port => $remote_port
);


$client->authenticate( 
	username => $myusername,
	password => $mypassword,
	key => $key,
	debug => $optctl{debug}
);

# get response
my $password = $client->getPassword( 
	machine => $machine,
	instance => $instance,
	username => $username,
	key => $key, 
	debug => $optctl{debug} 
);

print $password;

## end of main

sub usage {
	my $exitVal = shift;
	use File::Basename;
	my $basename = basename($0);
	print qq{
$basename

usage: $basename 

  --host <password server> 
  --port <tcp port>
  --machine <database server>
  --instance <database instance> 
  --username <database username> 
  --conf <configuration file - optional but recommended >
  --key <encryption key>
  --my_username <password server username>
  --my_password <password server password

};
	exit $exitVal;
};

