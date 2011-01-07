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

package UMTS::Phonebook::Entry;

use strict;

use UMTS::Core;
use Encode ();

use constant NUMBER_TYPE_INT => 145;
use constant NUMBER_TYPE_NAT => 129;

sub new
{
  my ($class, @params) = @_;
  
  my $self = { 
    name => '', 
    value => '',
    book => '',
    index => 0,
    @params
 };
  
  bless ($self, $class);
}


=item B<dump> - Dump phonebook entry to a string

=cut  

sub dump
{
  my $self = shift;
  return "$self->{name};$self->{value};$self->{book};$self->{index}\n";
}


=item B<get> - Retrieve a phonebook entry from a terminal

=cut  

sub get
{
  my ($class, $term, $book, $index) = @_;
  $term->send("AT+CPBR=$index" . CR);
  my $resp = $term->waitfor;

  if ($resp ne "OK")
  {
    $term->log("getPhonebookEntry : error getting phonebook entry $index ($resp)");
    return;  
  }

  my $data = $term->{extra};
  
  $data or 
    return;

  if ($data !~ /^\+CPBR:\s*(.*)/)
  {
    $term->log("getPhonebookEntry : could not parse $data");
    return;
  }  
  $data = $1;

  if ($index eq "?") 
  {
    if ($data !~ /^\(([0-9]+)-([0-9]+)\),\s*([0-9]+),\s*([0-9]+)/) 
    {
      $term->log("getPhonebookEntry : could not parse range $data");      
      return;
    }  
    
    my $out = { low => $1, high => $2, nlength => $3, tlength => $4 };
    return $out;
  } else {
    if ($data !~ /^$index,\s*\"(.*)\",\s*([0-9]+),\s*\"(.*)\"/) 
    {
      $term->log("getPhonebookEntry : could not parse entry $data");      
      return;
    }
    
    # if necessary, do encoding conversion
    my $name = $term->{charset} ? Encode::decode($term->{charset}, $3) : $3;
    # $2 is the type of number 
    return $class->new(name => $name, value => $1, book => $book, index => $index);
  }

  #return $1;
}


=item B<dump> - Read phonebook entry from a string

=cut  

sub parse 
{
  my ($class, $line) = @_;
  
  chomp($line);
  $line or
    return;
  
  my $entry = $class->new;
  ($entry->{name}, $entry->{value}, $entry->{book}, $entry->{index}) = split /;/, $line;
  return $entry;
}


=item B<set> - Write a phonebook entry

=cut  

sub set
{
  my ($self, $term) = @_;

  # if necessary, do encoding conversion
  my $name = $term->{charset} ? Encode::encode($term->{charset}, $self->{name}) : $self->{name};
  
  my $type =  ($self->{value} =~ /^\+/) ? NUMBER_TYPE_INT : NUMBER_TYPE_NAT;
  $term->send("AT+CPBW=$self->{index},\"$self->{value}\",$type,\"$name\"" . CR);
  my $resp = $term->waitfor;

  if ($resp ne "OK")
  {
    $term->log("setPhonebookEntry : error writing phonebook entry $self->{index} ($resp)");
    return RET_ERR;  
  }

  return RET_OK;
}


1;
