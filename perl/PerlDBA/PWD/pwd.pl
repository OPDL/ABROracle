#!/usr/bin/perl


use PDBA;

my $server;

if ( 'unix' eq PDBA->osname() ) {
	#print "Running Unix\n";
	eval q{
		use PDBA::PWD;
		$server = PDBA::PWD->new("pwd.conf");
		# daemon no logging
		$server->server( DAEMON => 1);

		# daemon with logging
		#$server->server(LOGGING => "/tmp/passwd.log", DAEMON => 1);

	};
} else {
	#print "Running Windows\n";
	eval q{
		use PDBA::PWDNT;
		$server = PDBA::PWDNT->new("pwd.conf");
		$server->server();
		#$server->server(LOGGING => "c:/temp/passwd.log");
	};
}

print "$@\n" if $@;

print "\n\n";


