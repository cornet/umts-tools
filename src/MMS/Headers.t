use Test::Simple tests => 1;

use MMS::Headers;

my $h = MMS::Headers->new();
ok( (defined($h) and ref($h) eq 'MMS::Headers'), 'new() works' );

my($bin,$val,$rest);

