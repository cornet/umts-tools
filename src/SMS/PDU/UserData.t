use strict;

use Test::Simple tests => 127;
use SMS::PDU::UserData qw(:dcs);
use UMTS::Test::NetPacket;


##
## TEST USER DATA HEADER ENCODING
##
my ($ud, $udh, $udhl);

$ud = SMS::PDU::UserData->decode;
$udh = $ud->encode_udh;
ok( $udh eq '', 'encode_udh() works for no UDH'); 

$ud = SMS::PDU::UserData->decode;
$ud->{dest_port} = 123;
$ud->{src_port} = 45;
$udh = $ud->encode_udh;
ok( $udh eq "\x04\x04\x02\x7B\x2D", 'encode_udh() works with 8bit ports'); 

$ud = SMS::PDU::UserData->decode;
$ud->{dest_port} = 1234;
$ud->{src_port} = 5678;
$udh = $ud->encode_udh;
ok( $udh eq "\x06\x05\x04\x04\xD2\x16\x2E", 'encode_udh() works with 16bit ports'); 

$ud = SMS::PDU::UserData->decode;
$ud->{drn} = 15;
$ud->{fmax} = 7;
$ud->{fsn} = 4;
$udh = $ud->encode_udh;
ok( $udh eq "\x05\x00\x03\x0F\x07\x04", 'encode_udh() works with fragmention info'); 

$ud = SMS::PDU::UserData->decode;
$udhl = $ud->decode_udh("\x04\x04\x02\x7B\x2D\xFF");
ok( ($udhl == 05) && ($ud->{dest_port} == 123) &&($ud->{src_port} == 45), 'decode_udh() works with 8bit ports');

$ud = SMS::PDU::UserData->decode;
$udhl = $ud->decode_udh("\x06\x05\x04\x04\xD2\x16\x2E\xFF");
ok( ($udhl == 07) && ($ud->{dest_port} == 1234) &&($ud->{src_port} == 5678), 'decode_udh() works with 16bit ports');

$ud = SMS::PDU::UserData->decode;
$udhl = $ud->decode_udh("\x05\x00\x03\x0F\x07\x04\xFF");
ok( ($udhl == 06) && ($ud->{drn} == 15) && ($ud->{fmax} == 7) && ($ud->{fsn} == 4), 'decode_udh() works with fragmentation info');

##
## TEST SIMPLE USER DATA WITHOUT UDH
##

my @testcases = (
 { data => 'even'           , dcs => PDU_DCS_7BIT },
 { data => 'odd'            , dcs => PDU_DCS_7BIT },
 { data => 'some more text' , dcs => PDU_DCS_7BIT },
 { data => 'even'           , dcs => PDU_DCS_8BIT },
 { data => 'odd'            , dcs => PDU_DCS_8BIT },
);

foreach my $testcase (@testcases)
{
  print "\nTESTCASE : No UDHI, data[$testcase->{data}], dcs[$testcase->{dcs}]\n";  
  my $pdu1 = SMS::PDU::UserData->decode;
  ok( (defined($pdu1) and ref($pdu1) eq 'SMS::PDU::UserData'), 'decode() works' );
  $pdu1->{data} = $testcase->{data};
  $pdu1->{dcs}  = $testcase->{dcs};
 
  my $binstr = $pdu1->encode;
  my $pdu2 = SMS::PDU::UserData->decode($binstr, dcs => $testcase->{dcs}, mouse => 'mickey');
  checkSMS_UD($pdu1, $pdu2);
}


##
## TEST PDU SAR
##

my $pduf = SMS::PDU::UserData->decode;
my (@uds, $cnt);

$pduf->{dcs} = PDU_DCS_8BIT;

$pduf->{data} = 'Universal Mobile Telecommunications System is one of the third-generation (3G) mobile phone technologies. It uses W-CDMA as the underlying standard, is standard';
print "SPLIT TESTS FOR LENGTH : ".length($pduf->{data})."\n";



$pduf->{src_port} = 1234;
$pduf->{dest_port} = 5678;
$pduf->{data} = 'Universal Mobile Telecommunications System is one of the third-generation (3G) mobile phone technologies. It uses W-CDMA as the underlying standard, is standardized by the 3GPP, and represents the European answer to the ITU IMT-2000 requirements for 3G Cellular radio systems.';
print "SPLIT TESTS FOR LENGTH : ".length($pduf->{data})."\n";

@uds = $pduf->split;
$cnt = 1;
foreach my $pdu (@uds) {
  print "\nTESTCASE : 8bit - fragment[$cnt]\n";
  my $binstr = $pdu->encode;
  my $pdu2 = SMS::PDU::UserData->decode($binstr, dcs => $pduf->{dcs}, udhi => 1);
  ok( (defined($pdu2) and ref($pdu2) eq 'SMS::PDU::UserData'), 'decode($txt) works' );
  
  checkSMS_UD($pdu, $pdu2);
  $cnt++;
}


$pduf->{dcs} = PDU_DCS_7BIT;
@uds = $pduf->split;
$cnt = 1;
foreach my $pdu (@uds) {
  print "\nTESTCASE : 7bit - fragment[$cnt]\n";
  my $binstr = $pdu->encode;
  my $pdu2 = SMS::PDU::UserData->decode($binstr, dcs => $pduf->{dcs}, udhi => 1);
  ok( (defined($pdu2) and ref($pdu2) eq 'SMS::PDU::UserData'), 'decode($txt) works' );
  
  checkSMS_UD($pdu, $pdu2);
  $cnt++;
}


$pduf->{dcs} = PDU_DCS_UCS2;
@uds = $pduf->split;
$cnt = 1;
foreach my $pdu (@uds) {
  print "\nTESTCASE : UCS2 - fragment[$cnt]\n";
  my $binstr = $pdu->encode;
  my $pdu2 = SMS::PDU::UserData->decode($binstr, dcs => $pduf->{dcs}, udhi => 1);
  ok( (defined($pdu2) and ref($pdu2) eq 'SMS::PDU::UserData'), 'decode($txt) works' );
  
  checkSMS_UD($pdu, $pdu2);
  $cnt++;
}

