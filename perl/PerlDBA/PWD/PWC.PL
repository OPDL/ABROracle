
use Config;


my $script = 'pwc.pl';
open(PWC,">$script") || die "cannot create $script\n";

my $os =  $Config{osname} ;

unless ( $os eq 'MSWin32' ) {
	my $perl = `which perl`;
	print PWC "#!", $perl, "\n";
	my $perlVersion = $Config{version};
	open(MK,"../Makefile") || die "cannot open Makefile for PDBA\n";
	my @Makefile = <MK>;
	close MK;
	my ($prefix) = grep(/^PREFIX\s+=/, @Makefile);
	(undef,undef,$prefix) = split(/\s+/, $prefix);
	print "PREFIX: |$prefix|\n";
	unless ( $prefix eq q{/usr} ) {
		print PWC "use lib qq{$prefix/lib/site_perl/$Config{version}};\n";
	}
}

open (SRC,"PWC.src") || die "cannot open PWC.src\n";

while(<SRC>){
	next if /\#\!.+perl/;
	print PWC;
}

close PWC;

chmod 0755, $script;


