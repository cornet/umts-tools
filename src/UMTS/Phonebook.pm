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

package UMTS::Phonebook;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);

use Exporter;
use UMTS::Core;
use UMTS::Phonebook::Entry;

@ISA = qw(Exporter);
@EXPORT_OK = qw(
  $PHONEBOOKS
);


# ETSI TS 100 916 v7.8.0 pp 8.11
my $PHONEBOOKS = {
  'DC' => 'Dialed numbers list',
  'EN' => 'Emergency number',
  'FD' => 'SIM fixdialling-phonebook',
  'LD' => 'SIM last-dialling-phonebook',
  'MC' => 'Missed calls list',
  'ME' => 'Mobile phonebook',
  'MT' => 'Combined SIM and mobile phonebook',
  'ON' => 'Own numbers',
  'RC' => 'Received call list',
  'SM' => 'SIM phonebook',
  'TA' => 'TA phonebook'
};


sub new
{
  my $class = shift;
  
  my $self = {
    @_
  };
  
  bless ($self, $class);
}


=item B<getPhonebookDump> - Retrieve a dump of a phonebook

=cut  

sub getPhonebookDump
{
  my ($class, $term, $book) = @_;

  if (!setPhonebook($class, $term, $book)) 
  {
    $term->log("getPhonebookDump : could not select phonebook `$book`");
    return;
  }
  
  my $range = UMTS::Phonebook::Entry->get($term, $book, "?");
  if (!ref($range)) {
    $term->log("getPhonebookDump : could not get range for phonebook `$book'");
    return;
  }
  my $idx = $range->{low};
  my @pbook;
  my $abort = 0;
  while (!$abort && ($idx <= $range->{high}))
  {
    my $entry = UMTS::Phonebook::Entry->get($term, $book, $idx);
    if ($entry) { 
      push @pbook, $entry;
    } else {
      $abort = 1;
    }
    $idx++;
  }
  return @pbook;
}



=item B<getPhonebooks> - Retrieve available phonebooks

=cut  

sub getPhonebooks
{
  my ($class, $term) = @_;

  $term->send("AT+CPBS=?" . CR);
  my $resp = $term->waitfor;
  
  # for debugging
  #$term->{extra} = "+CPBS: (\"SM\", \"TE\")\n";
  #$resp = "OK";
  
  if ($resp ne "OK")
  {
    $term->log("getPhonebooks : error getting phonebooks ($resp)");
    return;  
  }
    
  my $pbooks = $term->{extra};
  if ($pbooks !~ /^\+CPBS:\s*\((.*)\)/)
  {
    $term->log("getPhonebooks : could not parse $pbooks");
    return;
  }  
  
  if (my @books = eval("( $1 );"))
  {
    return @books;
  } else {
    $term->log("getPhonebooks : error evaluating $1");
    return;      
  }
}


=item B<setPhonebook> - Set the active phonebook

=cut  

sub setPhonebook
{
  my ($class, $term, $book) = @_;
  
  $term->send("AT+CPBS=\"$book\"" . CR);
  my $resp = $term->waitfor;
  if ($resp ne "OK")
  {
    $term->log("setPhonebook : could not select phonebook `$book` ($resp)");
    return RET_ERR;
  }

  return RET_OK;  
}


=item B<setPhonebookDump> - Send a phonebook dump to the terminal

=cut  

sub setPhonebookDump
{
  my ($class, $term, $book, @pbook) = @_;

  if (!setPhonebook($class, $term, $book))
  {
    $term->log("setPhonebookDump : could not select phonebook `$book`");
    return RET_ERR;
  }
  
  my $adjust = 0;
  my $range = UMTS::Phonebook::Entry->get($term, $book, "?");
  if (!ref($range))
  {
    $term->log("gstPhonebookDump : could not get range for phonebook `$book'");
    return RET_ERR;
  }
  if (my $first = shift @pbook) {
    unshift @pbook, $first;  
      
    my $plow = $first->{index};
    $adjust = $range->{low} - $plow;    
    $term->logDebug("first entries : on terminal: $range->{low}, in phonebook: $plow");
  }

  my $ret = RET_OK;  
  foreach my $entry (@pbook) {
    # adjust entry number for current phonebook
    $entry->{index} += $adjust;
    
    # write entry to phonebook
    my $result = $entry->set($term);
    $ret = RET_ERR unless ($result == RET_OK);
  }
  
  return $ret;
}



=item B<readPhonebook> - Reads a phonebook from a file

=cut 

sub readPhonebook
{
  my ($class, $log, $file) = @_;

  my @pbook;  

  if (open(FILE, "< $file")) {
  
    # read the phonebook
    my @lines = <FILE>;  
    close FILE;
  
    # parse the phonbook
    foreach my $line (@lines) {
      my $entry = UMTS::Phonebook::Entry->parse($line);
      ref($entry) and
        push @pbook, $entry;
    }
  
  } else {
  
    # error opening file
    $log->write("Could not open file '$file'");
    
  }  

  return @pbook;
}


=item B<writePhonebook> - Writes a phonebook to a file

=cut 

sub writePhonebook
{
  my ($class, $log, $file, @pbook) = @_;
    
    
  if (open(FILE, "> $file")) {
  
    # write phonebook
    foreach my $entry (@pbook) {
      print FILE $entry->dump;      
    }  
    close FILE;
    
  } else {
    
    # error opening file
    log->write("Could not open file '$file'");
    
  }
}


1;
