use strict;

use Test::Simple tests => 15;
use UMTS::Core;
use UMTS::Test;
use UMTS::Test::AT;

my $term = UMTS::Test->spawnTerm;

ok( (ref($term) and $term->isa('UMTS::Terminal::Common')), 'spawnTerm() works');
($term->reset eq RET_OK) or 
  die("terminal did not reset");

#probeAT($term, '+CMEE',  'enable verbose errors', P_RNG | P_SUP);
#probeAT($term, '+CVHU',  'voice hangup control',  P_RNG | P_SUP);

#probeAT($term, '+CEER',  'extended error report', P_RUN);

probeAT($term, '+CGMI',  'get manufacturer',      P_RUN);
probeAT($term, '+CGMM',  'get model',             P_RUN);
probeAT($term, '+CGMR',  'get revision',          P_RUN);
probeAT($term, '+CGSN',  'get IMEI',              P_RUN);

probeAT($term, '+CSCS',  'set terminal charset',  P_RNG);
probeAT($term, '+CSQ',   'get signal quality',    P_RUN);

#probeAT($term, '+CSCA',  'get/set SCA',           P_RNG);
probeAT($term, '+CMGF',  'set message mode',      P_RNG);
#probeAT($term, '+CMGS',  'send message',          P_SUP);

probeAT($term, '+CPBS',  'list phonebooks',       P_RNG);
probeAT($term, '+CPBR',  'read phonebook entry',  P_RNG);
probeAT($term, '+CPBW',  'write phonebook entry', P_RNG);

probeAT($term, '+CLCC',  'list current calls',    P_RNG | P_RUN);
probeAT($term, '+CPAS',  'phone activity status', P_RNG | P_RUN);

#probeAT($term, '+CKPD',  'send keystroke',        P_RNG);

$term->close;