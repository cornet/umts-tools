use strict;

use Test::Simple tests => 4;
use UMTS::NetPacket::Pcap;
use UMTS::Test::NetPacket;

my $pcap = UMTS::NetPacket::Pcap->decode;
ok( (defined($pcap) and ref($pcap) eq 'UMTS::NetPacket::Pcap'), 'decode() works' );

$pcap->{data} = 'foo';

my $txt = $pcap->encode;
my $pcap2 = UMTS::NetPacket::Pcap->decode($txt);

my @props = qw(major minor data);
checkProps($pcap, $pcap2, "Pcap", @props);
