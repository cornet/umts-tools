use Test::Simple tests => 1;

use WSP::PDU;
use UNIVERSAL qw(isa);

my $h = WSP::PDU->decode("\x06\x04\x03\xB6\x81\xEA");
ok( (defined($h) and isa($h,'WSP::PDU')), 'decode() works' );


