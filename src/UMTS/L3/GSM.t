use strict;

use Test::Simple tests => 1;
use GPRS::SM;

my $sm = GPRS::SM->decode("\x8A\x47");
ok( (defined($sm) and (ref($sm) eq 'GPRS::SM')), 'decode() works' );
