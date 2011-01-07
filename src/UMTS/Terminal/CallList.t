use Test::Simple tests => 20;
use UMTS::Terminal::CallList;
use UMTS::Log;
use Data::Dumper;

my $log = UMTS::Log->new;
my $list;

# empty
$list= UMTS::Terminal::CallList->new();
ok( ( defined($list) and ref($list) eq 'UMTS::Terminal::CallList' ), 'no calls - new() works' );
ok( ($list->nbCalls eq 0), 'no calls - nbCalls() returns 0');
ok( ($list->isDialing eq 0), 'no calls - isDialing() returns 0');
ok( ($list->nbActive eq 0), 'no calls - nbActive() returns 0');
undef($list);


# 1 MO call dialing
$list = UMTS::Terminal::CallList->new(
  '+CLCC: 1,0,2,0,0,"0171778777",129,"",0' . "\r\n"
);
ok( ( defined($list) and ref($list) eq 'UMTS::Terminal::CallList' ), '1 MO call dialing - new() works' );
ok( ($list->nbCalls eq 1), '1 MO call dialing - nbCalls() returns 1');
ok( ($list->isDialing eq 1), '1 MO call dialing - isDialing() returns 1');
ok( ($list->nbActive eq 0), '1 MO call dialing - nbActive() returns 0');
undef($list);

# 1 MO call alerting
$list = UMTS::Terminal::CallList->new(
  '+CLCC: 1,0,3,0,0,"0171778777",129,"",0' . "\r\n"
);
ok( ( defined($list) and ref($list) eq 'UMTS::Terminal::CallList' ), '1 MO call alerting - new() works' );
ok( ($list->nbCalls eq 1), '1 MO call alerting - nbCalls() returns 1');
ok( ($list->isDialing eq 1), '1 MO call alerting - isDialing() returns 1');
ok( ($list->nbActive eq 0), '1 MO call alerting - nbActive() returns 0');
undef($list);

# 1 MO call active
$list = UMTS::Terminal::CallList->new(
  '+CLCC: 1,0,0,0,0,"0171778777",129,"",0' . "\r\n"
);
ok( ( defined($list) and ref($list) eq 'UMTS::Terminal::CallList' ), '1 MO call active - new() works' );
ok( ($list->nbCalls eq 1), '1 MO call active - nbCalls() returns 1');
ok( ($list->isDialing eq 0), '1 MO call active - isDialing() returns 0');
ok( ($list->nbActive eq 1), '1 MO call active - nbActive() returns 1');
undef($list);


# 2 calls
$list = UMTS::Terminal::CallList->new(
  '+CLCC: 1,0,2,0,0,"0171778777",129,"",0' . "\r\n".
  '+CLCC: 2,0,0,0,0,"0626314000",129,"",0' . "\r\n"
);
ok( ( defined($list) and ref($list) eq 'UMTS::Terminal::CallList' ), '2 calls - new() works' );
ok( ($list->nbCalls eq 2), '2 calls - nbCalls() returns 2');
ok( ($list->isDialing eq 1), '2 calls - isDialing() returns 1');
ok( ($list->nbActive eq 1), '2 calls - nbActive() returns 1');
undef($list);

