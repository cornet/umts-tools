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

package UMTS::Terminal::CallStatus;

use strict;
use warnings;

use Carp ();
use UMTS::Core;

# ETSI TS 127 007 v5.4.0 pp 8.1
use constant ACT_STATUS_READY       => 0;
use constant ACT_STATUS_UNAVAILABLE => 1;
use constant ACT_STATUS_UNKNOWN     => 2;
use constant ACT_STATUS_RINGING     => 3;
use constant ACT_STATUS_CALL        => 4;
use constant ACT_STATUS_ASLEEP      => 5;

sub new
{
  my ($class, $data) = @_;
  
  $data = defined($data) ? $data : '';  
  my $self = {
    status => ACT_STATUS_UNKNOWN  
  };
  
  if ($data =~ /^\+CPAS: ([0-9])$/) {
    $self->{status} = $1;        
  } else {
    print "Unrecognised phone status '$data'\n";
  }
    
  bless($self, $class);  
}


=item B<getActivityStatus> - Get phone activity status

=cut

sub get
{
  my ($class, $term) = @_;
  
  ref($term) or
    Carp::croak("CallStatus::get : $term is not a terminal!");
  
#  $self->send("AT+CPAS=?" . CR);
#  my $ret = $self->waitfor;
#  my $sup = $self->{extra};
#  $self->logDebug("CPAS support : $sup");

  if ($term->send("AT+CPAS" . CR) and ($term->waitfor eq "OK")) 
  {
    return $class->new($term->{extra});
  }
   
  $term->logDebug("CallStatus::get : could not get activity status");
  return;
}



sub nbActive
{
  my ($self, $mode) = @_;
  
  return ($self->{status} eq ACT_STATUS_CALL) ? 1 : 0;
}


sub isDialing
{
  my ($self, $mode) = @_;
  
  return ($self->{status} eq ACT_STATUS_RINGING) ? 1 : 0;
}



1;
