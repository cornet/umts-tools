use Test::Simple tests => 2;
use UMTS::SMS::Entry;

# check Entry properties
sub checkEntry
{
  my ($a, $b) = @_;
  
  #print "\n--- a ---\n". Dumper($a);
  #print "\n--- b ---\n" . Dumper($b);
  
  foreach my $prop qw(name number)
  {
    my $ok = ( (!defined($a->{$prop}) and !defined($b->{$prop})) or
               (defined($a->{$prop}) and defined($b->{$prop}) and
                 ($a->{$prop} eq $b->{$prop}) ) );
		 
    ok($ok, "property '$prop' matches ($a->{$prop})");
    $ok or
      print "mismatch : `$a->{$prop}` vs `$b->{$prop}`\n";
  }

}

my $entry = UMTS::SMS::Entry->new;
ok( (defined($entry) and ref($entry) eq 'UMTS::SMS::Entry'), 'new() works' );

my $entry2 = UMTS::SMS::Entry->parse('158;1;;28;07913306091093F0000B913326364100F00011503012207461400AE6F71BA40EDFC3E934;');
ok( (defined($entry2) and ref($entry2) eq 'UMTS::SMS::Entry'), 'parse() works' );

