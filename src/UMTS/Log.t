use Test::Simple tests => 2;

use UMTS::Log;

my $log = UMTS::Log->new();
ok( (defined($log) and ref($log) eq 'UMTS::Log'), 'new() works' );


my $log2 = UMTS::Log->new("tmp.txt");
ok( (defined($log2) and ref($log2) eq 'UMTS::Log'), 'new("tmp.txt") works' );


