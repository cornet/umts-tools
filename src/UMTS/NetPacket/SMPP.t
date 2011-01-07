use strict;

use Test::Simple tests => 23;
use UMTS::NetPacket::SMPP;
use SMS::PDU::UserData qw(:dcs);
use UMTS::Test::NetPacket;

my $ud = SMS::PDU::UserData->decode('', dcs => PDU_DCS_8BIT);
$ud->{src_port} = 1234;
$ud->{dest_port} = 5678;
$ud->{data} = "Hello";

my $smpp = UMTS::NetPacket::SMPP->decode;
ok( (defined($smpp) and ref($smpp) eq 'UMTS::NetPacket::SMPP'), 'decode() works' );

$smpp->{cmd} = 125;
$smpp->{class} = 25;
$smpp->{delivery} = 2;
$smpp->{from} = '0622322364';
$smpp->{msisdn} = '+33612345678';
$smpp->{ud} = $ud;
$smpp->{priority} = 16;
$smpp->{predef} = 12;
$smpp->{proto} = 18;
$smpp->{registered} = 6;
$smpp->{replace} = 4;
$smpp->{seq} = 17;
$smpp->{status} = 321;
$smpp->{tos} = 4;
$smpp->{vp} = 16;

my $bin = $smpp->encode;
my $smpp2 = UMTS::NetPacket::SMPP->decode($bin);

checkSMPP($smpp, $smpp2);
