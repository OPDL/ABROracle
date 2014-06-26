
use Config;


my $script = 'pwd.pl';
open(PWD,">$script") || die "cannot create $script\n";

my $os =  $Config{osname} ;

unless ( $os eq 'MSWin32' ) {
	my $perl = `which perl`;
	print PWD "#!", $perl, "\n";
	my $perlVersion = $Config{version};
	open(MK,"../Makefile") || die "cannot open Makefile for PDBA\n";
	my @Makefile = <MK>;
	close MK;
	my ($prefix) = grep(/^PREFIX\s+=/, @Makefile);
	(undef,undef,$prefix) = split(/\s+/, $prefix);
	print "PREFIX: |$prefix|\n";
	unless ( $prefix eq q{/usr} ) {
		print PWD "use lib qq{$prefix/lib/site_perl/$Config{version}};\n";
	}
}

open (SRC,"PWD.src") || die "cannot open PWD.src\n";

while(<SRC>){
	next if /\#\!.+perl/;
	print PWD;
}

close PWD;
 
chmod 0755, $script;

