#!/usr/bin/perl
#
# umts-tools - tools for manipulating 3G terminals
# Copyright (C) 2004-2005 Jeremy Laine <jeremy.laine@m4x.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#

use strict;

BEGIN { push @INC, '/usr/share/umts-tools'; }

use UMTS::App;
use UMTS::Phonebook;
use Getopt::Std;

my $script = "umts-phonebook.pl";


=head1 NAME

umts-phonebook.pl - A GSM/UMTS terminal phonebook tool

=head1 SYNOPSIS

B<umts-phonebook.pl> [options]

=head1 DESCRIPTION

The B<umts-phonebook.pl> script allows you to read entries from a handset's
phonebook or to write entries to it. On most terminals, this gives you
access to both the SIM phonebook and the terminal's own phonebook. This
allows you to make backups of your phonebook to plaintext files and
restore them at a later date.

=head1 OPTIONS

 Common options:
  -d          debugging mode
  -l<log>     write log to <log>
  -h          display this help message
  -p<port>    terminal is connected to serial port <port>
              e.g. '\\.\COM12', '/dev/usb/acm/0'
  -z          use dummy terminal
  
 Options:
  -b<book>    operate on phonebook <book> from terminal
              examples : SM (SIM), ME (terminal)
  -f<file>    read/write phonebook to <file>
  -s          write to the selected phonebook in terminal
  -x          extract selected phonebook from terminal

=cut 
 

# Get command-line arguments
sub init
{
  my %opts;
  if ( not getopts('dhl:p:zb:f:sx', \%opts) or $opts{'h'}) {
    &usage();
  }
    
  my $config = UMTS::App->parse_opts(%opts);    
  
  if (($opts{x} or $opts{s}) and !$opts{b}) 
  {
    print "You must specify a phonebook to send or extract!\n";
    &usage();
  }

  if ($opts{s} and !$opts{f}) 
  {
    print "You must specify the file to read from!\n";
    &usage();
  }
    
  return ($config, %opts);
}


# Display program usage
sub usage
{
  print "[ This is $script $UMTS::App::VERSION, a GSM/UMTS terminal phonebook tool ]\n\n",
        "Syntax:\n",
        "  $script [options]\n\n",
        UMTS::App->usage,
        " Options:\n",
        "  -b<book>    operate on phonebook <book> from terminal\n",
        "              examples : SM (SIM), ME (terminal)\n",
        "  -f<file>    read/write phonebook to <file>\n",
        "  -s          write to the selected phonebook in terminal\n",        
        "  -x          extract selected phonebook from terminal\n",
        "\n";
  exit 1;
}


# The main routine
sub main
{
  my ($config, %opts) = &init;

  my $log = UMTS::App->make_log($config);
  my $term = UMTS::App->make_term($config, $log) or
    die("Could not open terminal");
 
  # print available phonebooks    
  my @pbooks = UMTS::Phonebook->getPhonebooks($term);
  $log->write("Phonebooks : @pbooks");

  if ($opts{x}) {
    my $book = $opts{b};
    my $file = $opts{f};
    $log->write("Extracting phonebook $book");
    my @pbook = UMTS::Phonebook->getPhonebookDump($term, $book);

    if ($file) {
      $log->write("Writing phonebook to '$file'");  
      UMTS::Phonebook->writePhonebook($log, $file, @pbook);
    }

  } elsif ($opts{s}) {
    my $book = $opts{b};
    my $file = $opts{f};
  
    $log->write("Reading phonebook from '$file'");  
    my @pbook = UMTS::Phonebook->readPhonebook($log, $file);

    $log->write("Sending phonebook to the terminal");
    UMTS::Phonebook->setPhonebookDump($term, $book, @pbook);
  }

  $term->close;

  exit 0;
}

&main;
