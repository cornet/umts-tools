use Test::Simple tests => 2;

use WSP::PDU::Disconnect;

my $h = WSP::PDU::Disconnect->decode("\x05\x87\xC4\x40");
ok( (defined($h) and ref($h) eq 'WSP::PDU::Disconnect'), 'decode() works' );

ok( $h->{ServerSessionId} == 123456, 'decode() works for ServerSessionId' );

