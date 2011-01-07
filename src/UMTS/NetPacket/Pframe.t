use strict;

use Test::Simple tests => 1;
use UMTS::NetPacket::Pframe;

my $pf = UMTS::NetPacket::Pframe->decode;
ok( (defined($pf) and ref($pf) eq 'UMTS::NetPacket::Pframe'), 'decode() works' );
