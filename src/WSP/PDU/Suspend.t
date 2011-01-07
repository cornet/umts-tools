use Test::Simple tests => 2;

use WSP::PDU::Suspend;

my $h = WSP::PDU::Suspend->decode("\x08\x87\xC4\x40");
ok( (defined($h) and ref($h) eq 'WSP::PDU::Suspend'), 'decode() works' );

ok( $h->{SessionId} == 123456, 'decode() works for SessionId' );

