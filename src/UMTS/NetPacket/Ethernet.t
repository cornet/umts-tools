use strict;

use Test::Simple tests => 5;
use UMTS::NetPacket::Ethernet;
use UMTS::Test::NetPacket;

my $mooh = 'abcd';
my $eth = UMTS::NetPacket::Ethernet->decode;
ok( (defined($eth) and ref($eth) eq 'UMTS::NetPacket::Ethernet'), 'decode() works' );

$eth->{src_mac} = '010101010101';
$eth->{dest_mac} = '020202020202';
$eth->{type} = ETH_TYPE_IP;
$eth->{data} = 'foo';

my $txt = $eth->encode;
my $eth2 = UMTS::NetPacket::Ethernet->decode($txt);

my @props = qw(src_mac dest_mac type data);
checkProps($eth, $eth2, "Ethernet", @props);
