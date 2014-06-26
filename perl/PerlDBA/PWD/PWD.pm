
package PDBA::PWD;

use strict;
use warnings;
our $VERSION = '0.01';

# nonforking password server
# modeled after code in The "Perl Cookbook"
# by Tom Christiansen and Nathan Torkington

use POSIX;
require IO::Socket;
require IO::Select;
use IO::File;
use Socket;
use Fcntl;
#use Tie::RefHash;
use Carp;
use Crypt::RC4;

use PDBA;
#use lib "./";
require PDBA::Daemon;

use PDBA::ConfigFile;
no strict 'vars';
@ISA=qw(IO::Socket IO::Select PDBA::Daemon);

%users=();
%inbuffer  = ();
%outbuffer = ();
%ready	  = ();
%authenticated = ();
%username = ();
$_noprint=0;
*OUT=*STDOUT;
$encryptionKey='';

# not sure why this was in the example
#tie %ready, 'Tie::RefHash';

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


	(undef) = $pwd::port;
	# Listen to port.
	my $server = IO::Socket::INET->new(
		LocalPort => $pwd::port,
		Listen => 10 ,
		Proto    => "tcp",
		Type     => SOCK_STREAM,
		Reuse  => 1
	) or croak "Can't make server socket: $@\n";
	nonblock($server);
	my $select = IO::Select->new($server);

	my $self = { server => $server, select => $select };

	# reload the authorization file with kill -1
	$SIG{HUP} = \&reload;

	#use Data::Dumper;
	#print "self server:" , Dumper($server), "\n";
	#print "self select:" , Dumper($select), "\n";

	my $socket = bless $self, $class;
	#print "socket :" , Dumper($socket), "\n";
	return $socket;

}
	
sub goDaemon {
	print STDOUT "going daemon 1\n";
	output("going daemon\n");
	# must be called with ampersand to work properly
	&PDBA::Daemon::daemonize;
}

sub server {

	use Data::Dumper;

	my $self = shift;
	my (%args) = @_;

	$args{DAEMON}  ||= 0;
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

	if ( $args{DAEMON} and ! $args{LOGGING} ) { $_noprint = 1 }
	output("self args:" , Dumper(@_), "\n");
	output("self %args:", Dumper(%args), "\n");

	goDaemon() if $args{DAEMON};
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

		# anything to read or accept?
		foreach $client ($select->can_read(1)) {

			if ($client == $server) {
			# accept a new connection
	
				output("accepting connection\n");

				$client = $server->accept();
				$select->add($client);
				nonblock($client);
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

				output("clear data received: $data");

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

# nonblock($socket) puts socket into nonblocking mode
sub nonblock {
	 my $socket = shift;
	 my $flags;
	 
	 $flags = fcntl($socket, F_GETFL, 0)
				or die "Can't get flags for socket: $!\n";
	 fcntl($socket, F_SETFL, $flags | O_NONBLOCK)
				or die "Can't make socket nonblocking: $!\n";
}


sub reload{
	output("Reloading...\n");
}

sub output {
	print OUT @_ unless $_noprint;
}

1;

