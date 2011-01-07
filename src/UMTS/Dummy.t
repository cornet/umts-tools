use Test::Simple tests => 1;

use UMTS::Dummy;

my $term = UMTS::Dummy->new();
ok( (defined($term) and ref($term) eq 'UMTS::Dummy'), 'new() works' );


