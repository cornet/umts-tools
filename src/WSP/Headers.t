use Test::Simple tests => 60;

use WSP::Headers;
use Math::BigInt;

my $h = WSP::Headers->new();
ok( (defined($h) and ref($h) eq 'WSP::Headers'), 'new() works' );

my($bin,$val,$rest);


### text tests ###
print "\nText tests\n";
ok( $h->is_token("hello"), 'is_token() works with a simple token');
ok( !$h->is_token(""), 'is_token() fails with an empty string');
ok( !$h->is_token("hello\bthere"), 'is_token() fails with a CTL');
ok( !$h->is_token("hello there"), 'is_token() fails with a space');

ok( $h->is_TEXT("Good line\r\n wrap\r\n\there"), 'is_TEXT() works for valid LWS');
ok( !$h->is_TEXT("Bad line\r\nwrap"), 'is_TEXT() fails for invalid LWS');
ok( !$h->is_TEXT("Control\x05chars"), 'is_TEXT() fails with control characters');

ok( $h->is_quoted_string('"Hello there"'), 'is_quoted_string() works for simple quoted text');
ok( $h->is_quoted_string("\"Hello\r\n there\""), 'is_quoted_string() works with valid LWS');
ok( !$h->is_quoted_string("\"Hello\r\nthere\""), 'is_quoted_string() fails with invalid LWS');
ok( !$h->is_quoted_string("\"Hello\"\r\n there\""), 'is_quoted_string() fails with extra quote');


### short integer tests ###
print "\nShort integer tests\n";

$bin = $h->pack_short_integer(0);
ok( $bin eq "\x80", 'pack_short_integer() works for 0' );

($val, $rest) = $h->unpack_short_integer("\x80\xFF");
ok( ($val == 0) && ($rest eq "\xFF"), 'unpack_short_integer() works for 0' );

$bin = $h->pack_short_integer(0x25);
ok( $bin eq "\xA5", 'pack_short_integer() works' );

($val,$rest) = $h->unpack_short_integer("\xA5\xFF");
ok( ($val == 0x25) && ($rest eq "\xFF"), 'unpack_short_integer() works' );

$bin = $h->pack_short_integer(127);
ok( $bin eq "\xFF", 'pack_short_integer() works for SHORTINT_MAX' );

($val,$rest) = $h->unpack_short_integer("\xFF\xFF");
ok( ($val == 127) && ($rest eq "\xFF"), 'unpack_short_integer() works for SHORTINT_MAX' );


### long integer tests ###
print "\nLong integer tests\n";

$bin = $h->pack_long_integer(0);
ok( $bin eq "\x01\x00", 'pack_long_integer() works for 0' );

($val, $rest) = $h->unpack_long_integer("\x01\x00\xFF");
ok( ($val == 0) && ($rest eq "\xFF"), 'unpack_long_integer() works for 0' );

$bin = $h->pack_long_integer(0x4321);
ok( $bin eq "\x02\x43\x21", 'pack_long_integer() works' );

($val, $rest) = $h->unpack_long_integer("\x02\x43\x21\xFF");
ok( ($val == 0x4321) && ($rest eq "\xFF"), 'unpack_long_integer() works' );

my $lmax = ( Math::BigInt->new(2) << 239 ) - 1;
my $lstr = "\x1E" . ("\xFF" x 30);
$bin = $h->pack_long_integer($lmax);
ok( $bin eq $lstr, 'pack_long_integer() works for LONGINT_MAX' );

($val, $rest) = $h->unpack_long_integer($lstr . "\x45");
ok( ($val == $lmax) && ($rest eq "\x45"), 'unpack_long_integer() works for LONGINT_MAX' );


### uintvar tests ###
print "\nuintvar tests\n";

$bin = $h->pack_uintvar(0);
ok( $bin eq "\x00", 'pack_uintvar() works for 0' );

($val,$rest) = $h->unpack_uintvar("\x00\xFF");
ok( ($val  == 0) && ($rest eq "\xFF"), 'unpack_uintvar() works for 0' );

$bin = $h->pack_uintvar(0x87A5);
ok( $bin eq "\x82\x8F\x25", 'pack_uintvar() works' );

($val,$rest) = $h->unpack_uintvar("\x82\x8F\x25\xFF");
ok( ($val == 0x87A5) && ($rest eq "\xFF"), 'unpack_uintvar() works' );

my $umax = ( Math::BigInt->new(2) << 34 ) - 1;
$bin = $h->pack_uintvar($umax);
ok( $bin eq "\xFF\xFF\xFF\xFF\x7F", 'pack_uintvar() works for UINTVAR_MAX' );

($val,$rest) = $h->unpack_uintvar("\xFF\xFF\xFF\xFF\x7F\xFF");
ok( ($val == $umax) && ($rest eq "\xFF"), 'unpack_uintvar() works for UINTVAR_MAX' );


### Value-length tests ###
print "\nValue-length tests\n";

$bin = $h->pack_value_length(29);
ok( $bin eq "\x1D", "pack_value_length() works for Short-length"); 

($val, $rest) = $h->unpack_value_length("\x1D\xFF");
ok( ($val == 29) && ($rest eq "\xFF"), 'unpack_value_length() works for Short-length' );

$bin = $h->pack_value_length(400);
ok( $bin eq "\x1F\x83\x10", "pack_value_length() works with Length-quote"); 

($val, $rest) = $h->unpack_value_length("\x1F\x83\x10\xFF");
ok( ($val == 400) && ($rest eq "\xFF"), 'unpack_value_length() works with Length-quote' );


### Token-text string tests ###
print "\nToken-text tests\n";

$bin = $h->pack_token_text("Testing");
ok( $bin eq "Testing\x00", 'pack_token_text() works' );

($val, $rest) = $h->unpack_token_text("Testing\x00\xFF");
ok( ($val eq "Testing") && ($rest eq "\xFF"), 'unpack_token_text() works');


### text string tests ###
print "\nText-string tests\n";

$bin = $h->pack_text_string("Testing");
ok( $bin eq "Testing\x00", 'pack_text_string() works with plain text' );

($val, $rest) = $h->unpack_text_string("Testing\x00\xFF");
ok( ($val eq "Testing") && ($rest eq "\xFF"), 'unpack_text_string() works with plain text');

$bin = $h->pack_text_string("\x81Boink");
ok( $bin eq "\x7F\x81Boink\x00", 'pack_text_string() works with special text' );

($val, $rest) = $h->unpack_text_string("\x7F\x81Boink\x00\xFF");
ok( ($val eq "\x81Boink") && ($rest eq "\xFF"), 'unpack_text_string() works with special text');


### Quoted-text tests ###
print "\nQuoted-text tests\n";

$bin = $h->pack_quoted_string('"Yahoo"');
ok( $bin eq "\x22Yahoo\x00", 'pack_quoted_string() works' );

($val, $rest) = $h->unpack_quoted_string("\x22Testing\x00\xFF");
ok( ($val eq "Testing") && ($rest eq "\xFF"), 'unpack_quoted_string() works');


### Integer-value tests ###
print "\nInteger-value tests\n";

$bin = $h->pack_integer_value(0x25);
ok( $bin eq "\xA5", 'pack_integer_value() works for a short int' );

($val,$rest) = $h->unpack_integer_value("\xA5\xFF");
ok( ($val == 0x25) && ($rest eq "\xFF"), 'unpack_integer_value() works for a short int' );

$bin = $h->pack_integer_value(0x4321);
ok( $bin eq "\x02\x43\x21", 'pack_integer_value() works for a long int' );

($val, $rest) = $h->unpack_integer_value("\x02\x43\x21\xFF");
ok( ($val == 0x4321) && ($rest eq "\xFF"), 'unpack_integer_value() works for a long int' );


### Date-value tests ###
print "\nDate-value tests\n";

$bin = $h->pack_date_value("Thu, 23 Apr 1998 13:41:37 GMT");
ok( $bin eq "\x04\x35\x3f\x45\x11", 'pack_date_value() works' );

($val, $rest) = $h->unpack_date_value("\x04\x35\x3f\x45\x11\xFF");
ok( ($val eq "Thu, 23 Apr 1998 13:41:37 GMT") && ($rest eq "\xFF"), 'unpack_date_value() works');


### Q-value tests ###
print "\nQ-value tests\n";

$bin = $h->pack_q_value("0.1");
ok( $bin eq "\x0B", 'pack_q_value() works for 1 decimal' );

($val, $rest) = $h->unpack_q_value("\x0B\xFF");
ok( ($val eq "0.1") && ($rest eq "\xFF"), 'unpack_q_value() works for 1 decimal');

$bin = $h->pack_q_value("0.99");
ok( $bin eq "\x64", 'pack_q_value() works for 2 decimals' );

($val, $rest) = $h->unpack_q_value("\x64\xFF");
ok( ($val eq "0.99") && ($rest eq "\xFF"), 'unpack_q_value() works for 2 decimals');

$bin = $h->pack_q_value("0.333");
ok( $bin eq "\x83\x31", 'pack_q_value() works for 3 decimals' );

($val, $rest) = $h->unpack_q_value("\x83\x31\xFF");
ok( ($val eq "0.333") && ($rest eq "\xFF"), 'unpack_q_value() works for 3 decimals');


### Version-value tests ###
print "\nVersion-value tests\n";

$bin = $h->pack_version_value("1");
ok( $bin eq "\x9F", 'pack_version_value() works for 1' );

($val, $rest) = $h->unpack_version_value("\x9F\xFF");
ok( ($val eq "1") && ($rest eq "\xFF"), 'unpack_version_value() works for 1');

$bin = $h->pack_version_value("2.1");
ok( $bin eq "\xA1", 'pack_version_value() works for 2.1' );

($val, $rest) = $h->unpack_version_value("\xA1\xFF");
ok( ($val eq "2.1") && ($rest eq "\xFF"), 'unpack_version_value() works for 2.1');

$bin = $h->pack_version_value("9.5");
ok( $bin eq "9.5\x00", 'pack_version_value() works for 9.5' );

($val, $rest) = $h->unpack_version_value("9.5\x00\xFF");
ok( ($val eq "9.5") && ($rest eq "\xFF"), 'unpack_version_value() works for 9.5');



