use strict;

use Test::Simple tests => 142;
use SMS::PDU::Deliver;
use SMS::PDU::UserData qw(:dcs);
use UMTS::Test::NetPacket;

# prepare PDU
my $pdu = SMS::PDU::UserData->decode;
$pdu->{src_port} = 1234;
$pdu->{dest_port} = 5678;
$pdu->{dcs} = PDU_DCS_8BIT;
$pdu->{data} = "Hello";


# run over the testcases
my @testcases = (
 { smsc => '',              from => '' },
 { smsc => '',              from => '12' },
 { smsc => '',              from => '123' },
 { smsc => '',              from => '0612345678' },
 { smsc => '',              from => '+33612345678' },
 { smsc => '12',            from => '+33612345678' },
 { smsc => '123',           from => '+33612345678' },
 { smsc => '+6598540020',   from => '+33612345678' },
);


foreach my $testcase (@testcases)
{  
  print "TESTCASE : smsc [$testcase->{smsc}] from [$testcase->{from}]\n";
  my $nbs = SMS::PDU::Deliver->frameUserData($testcase->{smsc}, $testcase->{from}, $pdu);
  ok( (defined($nbs) and ref($nbs) eq 'SMS::PDU::Deliver'), 'decode() works' );
    
  $nbs->{'TP-PID'} = 7;
  $nbs->{'TP-RP'} = 1;
  $nbs->{'TP-MMS'} = 1;
  
  my $nbs2 = SMS::PDU::Deliver->decode($nbs->encode);
  ok( (defined($nbs) and ref($nbs) eq 'SMS::PDU::Deliver'), 'decode($bin) works' );

  checkSMS_Deliver($nbs, $nbs2);
}



##
## SMS Deliver decoding
##

my $pdu_del = SMS::PDU::UserData->decode;
$pdu_del->{dcs} = 0;
$pdu_del->{data} = 'hellohello';

my $nbs_del = SMS::PDU::Deliver->frameUserData('+27381000015', '27838890001', $pdu_del);
$nbs_del->{'TP-DCS'} = 0;

my $nbs_del2 = SMS::PDU::Deliver->decode(pack('H*','07917283010010F5040BC87238880900F10000993092516195800AE8329BFD4697D9EC37'));
checkSMS_Deliver($nbs_del, $nbs_del2);

