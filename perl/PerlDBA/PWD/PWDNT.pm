
package PDBA::PWDNT;

use strict;
use warnings;
our $VERSION = '0.01';

# nonforking password server
# modeled after code in The "Perl Cookbook"
# by Tom Christiansen and Nathan Torkington
# Win32::Daemon courtesy of Dave Roth


use POSIX;
require IO::Socket;
require IO::Select;
use IO::File;
use Socket;
use POSIX qw(:fcntl_h);
use Carp;
use Crypt::RC4;

use PDBA;

use Win32::Daemon;

use PDBA::ConfigFile;
no strict 'vars';
@ISA=qw(IO::Socket IO::Select Win32::Daemon);

%users=();
%inbuffer  = ();
%outbuffer = ();
%ready	  = ();
%authenticated = ();
%username = ();
$_noprint=0;
*OUT=*STDOUT;
$encryptionKey='';

=head1

 get configuration

 see documentation in pwd.conf

=cut 

sub new {


	# class method
	# since it is called by package name, we have
	# to include that in the parameters
	my $pkg = shift;
	my $class = ref($pkg) || $pkg;

	my ($configFile) = @_;
	use PDBA::ConfigFile;

	unless ( new PDBA::ConfigLoad( FILE => $configFile ) ) {
		die "could not load $configFile\n";
	}

	#use Data::Dumper;
	#print Dumper(\%pwd::pwd);

	(undef) = $pwd::port;
	# Listen to port.
	print "Port: $pwd::port\n";
	my $server = IO::Socket::INET->new(
		LocalPort => $pwd::port,
		Listen => 10 ,
		Proto    => "tcp",
		Type     => SOCK_STREAM,
		Reuse  => 1
	) or croak "Can't make server socket: $@\n";
	# nonblocking broken on NT and Win2k
	#nonblock($server);
	my $select = IO::Select->new($server);

	my $self = { server => $server, select => $select };

	my $socket = bless $self, $class;
	return $socket;

}
	
sub server {

	use Data::Dumper;

	my $self = shift;
	my (%args) = @_;

	$args{LOGGING} ||= undef;

	my $logFh;
	if ( $args{LOGGING}  ) {
		$logFh = new IO::File;
		$logFh->open($args{LOGGING}, ">") || 
			croak "Cannot create logfile $args{LOGGING} in $self\n";
		$logFh->autoflush;
		chmod 0600, $args{LOGGING};
		*OUT = $logFh;
	}

	if ( ! $args{LOGGING} ) { $_noprint = 1 }
	output("self args:" , Dumper(@_), "\n");
	output("self %args:", Dumper(%args), "\n");

	my $attempts;
	Win32::Daemon::StartService();
	sleep( 1 );
	my $State = Win32::Daemon::State();
	output("Service Starting - State is: " . $State . "\n");

	while( SERVICE_START_PENDING != $State ) {
		output("Waiting for service - state is: " . $State . "...\n" );
		sleep( 1 );
		if ( $attempts++ > 15 ) {
			output("Failed to start service in " . $attempts . " attempts\n");
			Win32::Daemon::State(SERVICE_STOPPED);
			Win32::Daemon::StopService();
			exit 2;
		}
		$State = Win32::Daemon::State();
	}

	Win32::Daemon::State(SERVICE_RUNNING);
	$State = Win32::Daemon::State();
	output("Service Started - State is: " . $State ."\n");

	output("now entering server main loop\n");

	my $client;
	my $rv;
	my $data;

	my $server = $self->{server};
	my $select = $self->{select};

	# get encryption key, pack it, limited to 56 bytes
	$encryptionKey = 
		pack(
			'H' x ( length($pwd::encryption{key})>56 ? 112 : length($pwd::encryption{key}) * 2 ), 
			$pwd::encryption{key}
		);

	#print "self server:" , Dumper($server), "\n";
	#print "self select:" , Dumper($select), "\n";
	#print "self self  :" , Dumper($self), "\n";
	 # check for new information on the connections we have

# Main loop: check reads/accepts, check writes, check ready to process
	while (1) {

		# check for Win32 Service state
		my $PrevState = SERVICE_RUNNING;
		while( SERVICE_STOPPED != ( $State = Win32::Daemon::State() ) ) {
			if( SERVICE_RUNNING == $State ) { 
				output("Service running\n");
				last;
			} elsif( SERVICE_PAUSE_PENDING == $State ) {
				# "Pausing...";
				output("Pausing Service\n");
				Win32::Daemon::State( SERVICE_PAUSED );
				$PrevState = SERVICE_PAUSED;
				next;
			} elsif( SERVICE_CONTINUE_PENDING == $State ) {
				# "Resuming...";
				output("Resuming Service\n");
				Win32::Daemon::State( SERVICE_RUNNING );
				$PrevState = SERVICE_RUNNING;
				last;
			} elsif( 
				SERVICE_STOP_PENDING == $State  or 
				SERVICE_CONTROL_SHUTDOWN == $State ) {
				# "Stopping...";
				output("Stopping Service\n");
				# Tell the OS that the service is terminating...
				Win32::Daemon::State(SERVICE_STOPPED);
				Win32::Daemon::StopService();
				exit 8;
				last;
			} else {
				# We have some unknown state...
				# reset it back to what we last knew the state to be...
				output("Unknown State of : " . $State . " - exiting...\n");
				Win32::Daemon::State(SERVICE_STOPPED);
				Win32::Daemon::StopService();
				exit 8;
				last;
			}
			sleep 1;
		}
		# anything to read or accept?
		foreach $client ($select->can_read(1)) {

			if ($client == $server) {
			# accept a new connection
	
				output("accepting connection\n");

				$client = $server->accept();
				$select->add($client);
				# nonblocking broken on NT and Win2k
				#nonblock($client);
			} else {
				# read data
				output("reading data\n");
				$data = '';
				$rv	= $client->recv($data, POSIX::BUFSIZ, 0);
				output("encrypted data received: $data\n");
				chomp $data;
				$data = pack("H*",$data);
				$data = RC4($encryptionKey, $data);
				$data .= "\n";

				output("clear data received: $data\n");

				unless (defined($rv) && length $data) {
					# This would be the end of file, so close the client
					output("Closing connection\n");
					delete $inbuffer{$client};
					delete $outbuffer{$client};
					delete $ready{$client};
					delete $authenticated{$client};
					delete $username{$client};
					delete $authenticated{$client};

					$select->remove($client);
					close $client;
					next;
				}

				$inbuffer{$client} .= $data;

				# test whether the data in the buffer or the data we
				# just read means there is a complete request waiting
				# to be fulfilled.  If there is, set $ready{$client}
				# to the requests waiting to be fulfilled.
				while ($inbuffer{$client} =~ s/(.*\n)//) {
					push( @{$ready{$client}}, $1 );
				}
			}
		}

		# Any complete requests to process?
		foreach $client (keys %ready) {
			output("handling client\n");
			handle($client);
		}

		# Buffers to flush?
		foreach $client ($select->can_write(1)) {
			output("Client is writable\n");
			# Skip this client if we have nothing to say
			next unless exists $outbuffer{$client};

			if ( $outbuffer{$client} eq 'REJECTED' ) {
				delete $inbuffer{$client};
				delete $outbuffer{$client};
				delete $ready{$client};
				delete $username{$client};
				delete $authenticated{$client};

				$select->remove($client);
				close($client);
				next;
			}

			output("Sending data\n");
			my $outdata = unpack("H*", RC4($encryptionKey, $outbuffer{$client}));
			$rv = $client->send($outdata . "\n", 0);
			output("wrote data to socket\n" );
			output("clear data: $outbuffer{$client}\n");
			output("encrypted data: $outdata\n");
			unless (defined $rv) {
				warn "unable to write to socket\n";
				next;
			}
			#if ($rv == length($outbuffer{$client} . "\n" ) ||
			if ($rv == length($outdata . "\n") ||
				$! == POSIX::EWOULDBLOCK) {
				output("deleting buffer\n");
				# close socket after returning response
				if ( $outbuffer{$client} =~ /^RESPONSE:/ ) {
					delete $inbuffer{$client};
					delete $outbuffer{$client};
					delete $ready{$client};
					delete $username{$client};
					delete $authenticated{$client};
					$select->remove($client);
					close($client);
					next;
				}
				substr($outbuffer{$client}, 0, $rv) = '';
				delete $outbuffer{$client} unless length $outbuffer{$client};


			} else {
				# Couldn't write all the data, and it wasn't because
				# it would have blocked.  Shutdown and move on.
				output("Write Failed!\n");
				delete $inbuffer{$client};
				delete $outbuffer{$client};
				delete $ready{$client};
				delete $username{$client};
				delete $authenticated{$client};
			
				$select->remove($client);
				close($client);
				next;
			}
		}
	}
}

# handle($socket) deals with all pending requests for $client
sub handle {
	 # requests are in $ready{$client}
	 # send output to $outbuffer{$client}
	 my $client = shift;
	 my $request;

	 foreach $request (@{$ready{$client}}) {
		  # $request is the text of the request
		  # put text of reply into $outbuffer{$client}

		  # only 2 types of requests
		  # if neither matches, cut them off
		  chomp $request;

		  if ( $request =~ /^AUTHENTICATE:/ ) {
				my ( $requestType, $username, $phrase ) = split(/:/, $request );
				output("Authentication:\n");
				output("\tstored   password: $pwd::users{$username}\n");
				output("\treceived username:password: $username:$phrase\n");
				
				if ( $phrase eq $pwd::users{$username} ) {
					output("Authentication accepted\n");
		  			$outbuffer{$client} = "ACCEPTED";
		  			$authenticated{$client} = "ACCEPTED";
		  			$username{$client} = $username;
				} else { 
					output("Authentication rejected\n");
					$outbuffer{$client} = "REJECTED" ;
		  			$authenticated{$client} = "REJECTED";
		  			$username{$client} = undef;
				}
		  } elsif ( $request =~ /^REQUEST:/ ) {

				my ($cmd, $machine,$instance,$account) = split(/:/, $request);

				my $authorized = 
					defined $pwd::instanceAuth{$machine}->{$instance}{$account}
					? grep(/^$username{$client}$/, @{$pwd::instanceAuth{$machine}->{$instance}{$account}})
					: 1;

				output("authorized user: $username{$client}\n");

		  		if ( $authenticated{$client} eq 'ACCEPTED'  and $authorized ) {
					# if authenticated, check to see if valid users
					# have been specified via %instanceAuth hash
					# reject user if not authorized
					output("\tmachine: $machine\n");
					output("\tinstance: $instance\n");
					output("\taccount: $account\n");
					output("AUTH:  $pwd::pwd{$machine}->{$instance}{$account} \n");
					output("LEN ACCT:", length($account), "\n");
					$outbuffer{$client} = 'RESPONSE:' . $pwd::pwd{$machine}->{$instance}{$account};
				} else {
					$outbuffer{$client} = "REJECTED";
				}
		  } else {
		  	$outbuffer{$client} = "REJECTED";
		  }
	 }
	 delete $ready{$client};
}

# nonblocking broken on NT and Win2k
# nonblock($socket) puts socket into nonblocking mode
sub nonblock {
	 my $socket = shift;
	 my $flags;
	 
	 my $f=0;
	 print "F:", $f++,"\n";
	 #$flags = fcntl($socket, F_GETFL, 0)
	  fcntl($socket, F_GETFL, $flags);
				#or die "Can't get flags for socket: $!\n";
	 print "F:", $f++,"\n";
	 fcntl($socket, F_SETFL, $flags | O_NONBLOCK)
				or die "Can't make socket nonblocking: $!\n";
	 print "F:", $f++,"\n";
}


sub reload{
	output("Reloading...\n");
}

sub output {
	print OUT @_ unless $_noprint;
}

1;

