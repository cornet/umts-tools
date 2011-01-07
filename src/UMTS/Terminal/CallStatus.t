use Test::Simple tests => 3;
use UMTS::Terminal::CallStatus;
use UMTS::Log;
use Data::Dumper;

my $log = UMTS::Log->new;
my $stat;

# empty
$stat = UMTS::Terminal::CallStatus->new();
ok( ( defined($stat) and ref($stat) eq 'UMTS::Terminal::CallStatus' ), 'no status - new() works' );
ok( ($stat->isDialing eq 0), 'no status - isDialing() returns 0');
ok( ($stat->nbActive eq 0), 'no status - nbActive() returns 0');
undef($stat);

