
package PDBA::PWC;

use strict;
use IO::Socket;
use Getopt::Long;
use Crypt::RC4;
use Carp;

=head1 new Password Client

usage:  

my $client = new PDBA::PWC( 
	host => 'mybox.gothere.com', 
	port => 1800
);

=cut

sub new {

	my $pkg = shift;
	my $class = ref($pkg) || $pkg;
	my %options = @_;

	unless ( defined($options{host}) and  defined($options{port}) ) {
		croak "host and port must be defined in $pkg \n";
	}

	my $client = IO::Socket::INET->new(
		PeerAddr => $options{host},
		PeerPort => $options{port},
		Proto    => "tcp",
		Type     => SOCK_STREAM,
		Timeout	=> 30
	) or croak "Couldn't connect to $options{host}:$options{port} : $@\n";

	my $self = { client => $client };

	my $socket = bless $self, $class;

	return $socket;
}

=head1

usage:

my $client = new PDBA::PWC( 
	host => 'mybox.gothere.com', 
	port => 1800
);

$client->authenticate(
	username => 'your_user_name',
	password => 'your_password',
	key => 'encryption_key',
	debug => 1  # turn on debug
);


=cut

# print to socket
sub authenticate {
	
	my $self = shift;
	my %args= @_;

	unless ( 
		defined($args{key}) 
		and defined($args{username})
		and defined($args{password})
	) {
		croak "username/password/key must be defined in PDBA::PWC::authenticate\n";
	}
	my $client = $self->{client};

	print  "AUTHENTICATE:\n" .
		"\t$args{username}:\n" .
		"\t$args{password}:\n" .
		"\t$args{key}\n" if $args{debug};
	
	$self->send (
		 RC4(
			prepareKey($args{key}), 
			"AUTHENTICATE:$args{username}:$args{password}:"
		)
	);
	
}

=head1

usage:

$client->passwordRequest(
	machine => 'requested machine ',
	instance => 'requested database instance',
	username => 'requested username',
	key => 'encryption_key',
	debug => 1  # turn on debug
);

=cut

sub passwordRequest {
	
	my $self = shift;
	my %args= @_;

	unless ( 
		defined($args{key}) 
		and defined($args{machine})
		and defined($args{instance})
		and defined($args{username})
	) {
		croak "machine/instance/username/key must be defined in PDBA::PWC::request\n";
	}
	my $client = $self->{client};

	print  "AUTHENTICATE:\n" .
		"\t$args{machine}:\n" .
		"\t$args{instance}:\n" .
		"\t$args{username}:\n" .
		"\t$args{key}:\n" 
	if $args{debug};
	
	$self->send (
		 RC4(
			prepareKey($args{key}), 
			"REQUEST:$args{machine}:$args{instance}:$args{username}:"
		)
	);
	
}

{
sub send {
	my $self = shift;
	my $line = shift;
	my $client = $self->{client};
	$line = unpack("H*", $line);
	print $client $line . "\n";
}
}
=head1

usage:

my $answer = client->receive( key => 'key test', debug => 0 );


=cut


sub receive {

	my $self = shift;
	my %args= @_;

	unless ( defined($args{key}) ) {
		croak "key must be defined in PDBA::PWC::receive\n";
	}

	my $client = $self->{client};

	# get response
	my $response = <$client>;

	chomp $response if $response;
	$response = pack("H*", $response);
	print "RESPONSE RECEIVED\n" if $args{debug};
	print "RESPONSE BEFORE DECRYPT: $response\n" if $args{debug};
	$response = RC4(prepareKey($args{key}), $response) if $response;
	print "RESPONSE AFTER DECRYPT: $response\n" if $args{debug};

	return $response

}

sub close {
	my $self = shift;
	close $self->{client};
}


{
sub prepareKey {
	my $key = shift;
	$key = pack(
		'H' x ( length($key)>56 ? 112 : length($key) * 2 ),
		$key
	);
	$key;
}
}


sub getPassword {

	my $self = shift;
	my %args= @_;

	my $response = $self->receive( key => $args{key}, debug => $args{debug} );

	#print "RESPONSE: $response\n";

	if ( $response eq 'ACCEPTED' ) {

		print  "REQUEST:$args{machine}:$args{instance}:$args{username}:\n" if $args{debug};

		$self->passwordRequest( 
			machine => $args{machine},
			instance => $args{instance},
			username => $args{username},
			key => $args{key},
			debug => $args{debug}
		);

		$response = $self->receive( key => $args{key}, debug => $args{debug} );

		#print "RESPONSE: $response\n";
		# and terminate the connection when we're done
		my ( undef, $password ) = split(/:/,$response) if $response;
		return $password;

	} else { return undef }

}


1;


