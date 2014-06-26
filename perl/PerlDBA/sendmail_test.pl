#!/usr/bin/perl 

use PDBA;

my @addresses = ('someone@somewhere.com','7775551212@mobile.att.net');
my $message = "this is PDBA test email";
my $subject = "PDBA testing";

print "message: $message\n";

if ( PDBA->email(\@addresses,$message,$subject) ) {
	print "Mail sent\n";
} else {
	print "Mail not sent\n";
}

