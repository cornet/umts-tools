use strict;

use Test::Simple tests => 187;
use SMS::PDU::Submit;
use SMS::PDU::UserData qw(:dcs);
use UMTS::Test::NetPacket;

# prepare PDU
my $pdu = SMS::PDU::UserData->decode('', dcs => PDU_DCS_8BIT);
$pdu->{src_port} = 1234;
$pdu->{dest_port} = 5678;
$pdu->{data} = "Hello";


# run over the testcases
my @testcases = (
 { smsc => '',              to => '' },
 { smsc => '',              to => '12' },
 { smsc => '',              to => '123' },
 { smsc => '',              to => '0612345678' },
 { smsc => '',              to => '+33612345678' },
 { smsc => '12',            to => '+33612345678' },
 { smsc => '123',           to => '+33612345678' },
 { smsc => '+6598540020',   to => '+33612345678' },
);


foreach my $testcase (@testcases)
{  
  print "\nTESTCASE : smsc [$testcase->{smsc}] to [$testcase->{to}]\n";
  my $nbs = SMS::PDU::Submit->frameUserData($testcase->{smsc}, $testcase->{to}, $pdu);
  ok( (defined($nbs) and ref($nbs) eq 'SMS::PDU::Submit'), 'decode() works' );
    
  $nbs->{'TP-MR'} = 124;
  $nbs->{'TP-PID'} = 7;
  $nbs->{'TP-VP'} = 15;
  $nbs->{'TP-RP'} = 1;
  $nbs->{'TP-RD'} = 1;
  $nbs->{'TP-SRR'} = 1;
  
  my $nbs2 = SMS::PDU::Submit->decode($nbs->encode);
  ok( (defined($nbs) and ref($nbs) eq 'SMS::PDU::Submit'), 'decode($bin) works' );

  checkSMS_Submit($nbs, $nbs2);
}


##
## SMS Submit decoding
##
my $pdu_sub = SMS::PDU::UserData->decode('', PDU_DCS_7BIT);
$pdu_sub->{data} = 'hellohello';

my $nbs_sub = SMS::PDU::Submit->frameUserData('', '+46708251358', $pdu_sub);
$nbs_sub->{'TP-MR'} = 0;
$nbs_sub->{'TP-PID'} = 0;
$nbs_sub->{'TP-DCS'} = PDU_DCS_7BIT;
$nbs_sub->{'TP-VPF'} = 2;
$nbs_sub->{'TP-VP'} = 0xAA;

my $nbs_sub2 = SMS::PDU::Submit->decode(pack('H*', '0011000B916407281553F80000AA0AE8329BFD4697D9EC37'));

checkSMS_Submit($nbs_sub, $nbs_sub2);
