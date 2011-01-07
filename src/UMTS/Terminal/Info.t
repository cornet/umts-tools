use Test::Simple tests => 12;
use UMTS::Terminal::Info;
use UMTS::Log;

my $log = UMTS::Log->new;

# empty
my $info = UMTS::Terminal::Info->new();
ok( ( defined($info) and ref($info) eq 'UMTS::Terminal::Info' ), 'new() works' );
ok( ($info->name eq 'Generic handset'), 'Generic handset correctly identified');
ok( ($info->type eq 'default'), 'Generic handset uses correct driver');

# Motorola V1050
my $info_V1050 = UMTS::Terminal::Info->new('Motorola CE, Copyright 2005', '"GSM900","GSM1800","GSM1900","WCDMA","MODEL=V1050"');
ok( ( defined($info) and ref($info) eq 'UMTS::Terminal::Info' ), 'new() for V1050 works' );
ok( ($info_V1050->name eq 'Motorola V1050'), 'V1050 correctly identified');
ok( ($info_V1050->type eq 'motorola'), 'V1050 uses correct driver');

# Sony Ericsson V800
my $info_v800 = UMTS::Terminal::Info->new('Sony Ericsson', 'AAD-3021011-BV');
ok( ( defined($info) and ref($info) eq 'UMTS::Terminal::Info' ), 'new() for V800 works' );
ok( ($info_v800->name eq 'Sony Ericsson V800'), 'V800 correctly identified');
ok( ($info_v800->type eq 'semc'), 'V800 uses correct driver');

# Samsung Z107
my $info_z107 = UMTS::Terminal::Info->new('SAMSUNG ELECTRONICS CORPORATION', '129');
ok( ( defined($info) and ref($info) eq 'UMTS::Terminal::Info' ), 'new() for Z107 works' );
ok( ($info_z107->name eq 'Samsung Z107'), 'Z107 correctly identified');
ok( ($info_z107->type eq 'samsung'), 'Z107 uses correct driver');

