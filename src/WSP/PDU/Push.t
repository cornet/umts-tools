use Test::Simple tests => 2;

use WSP::PDU::Push;

my $h = WSP::PDU::Push->decode("\x06\x04\x03\xB6\x81\xEA");
ok( (defined($h) and ref($h) eq 'WSP::PDU::Push'), 'decode() works' );

ok( $h->{ContentType} eq 'application/vnd.wap.connectivity-wbxml; Charset=utf-8', 'decode() works for ContentType' );
