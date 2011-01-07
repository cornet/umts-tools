use Test::Simple tests => 6;
use UMTS::Log;
use UMTS::Phonebook::Entry;
use UMTS::Test::NetPacket;

my $log = UMTS::Log->new;

sub checkEntry
{
  my ($a, $b) = @_;
  checkProps($a, $b, 'UMTS::PhoneBook::Entry', qw(name value book index));
}

my $entry = UMTS::Phonebook::Entry->new;
ok( (defined($entry) and ref($entry) eq 'UMTS::Phonebook::Entry'), 'new() works' );

$entry->{name} = 'Foo Bar/M';
$entry->{value} = '+33612345678';
$entry->{index} = 699;
$entry->{book} = 'SM';

my $entry2 = UMTS::Phonebook::Entry->parse('Foo Bar/M;+33612345678;SM;699;;145');
ok( (defined($entry2) and ref($entry2) eq 'UMTS::Phonebook::Entry'), 'parse() works' );
checkEntry($entry, $entry2);

