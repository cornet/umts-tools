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

package UMTS::SMS::Entry;

use strict;
use warnings;


=item B<new> - Construct a new SMS entry

=cut  

sub new
{
  my ($class, @params) = @_;
  my $self = { 
    index => '', 
    stat => '',
    alpha => '',
    length => 0,
    data => '',
    @params
 };
  
  bless ($self, $class);
}


=item B<dump> - Dump SMS entry to a string

=cut  

sub dump
{
  my $self = shift;
  return "$self->{index};$self->{stat};$self->{alpha};$self->{length};$self->{data};\n";
}


=item B<dump> - Read SMS entry from a string

=cut  

sub parse 
{
  my ($class, $line) = @_;
  
  chomp($line);
  $line or
    return;
  
  my $entry = $class->new; 
  ($entry->{index}, $entry->{stat}, $entry->{alpha}, $entry->{length}, $entry->{data}) = split /;/, $line;
  return $entry;
}


1;
