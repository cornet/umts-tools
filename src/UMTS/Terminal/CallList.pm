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

package UMTS::Terminal::CallList;

use strict;
use warnings;

use Carp ();
use UMTS::Core;

# ETSI TS 127 007 v5.4.0 pp 7.18
use constant CALL_DIR_MO        => 0;
use constant CALL_DIR_MT        => 1;

use constant CALL_STAT_ACTIVE   => 0;
use constant CALL_STAT_HELD     => 1;
use constant CALL_STAT_DIALING  => 2;
use constant CALL_STAT_ALERTING => 3;
use constant CALL_STAT_INCOMING => 4;
use constant CALL_STAT_WAITING  => 5;

use constant CALL_MODE_VOICE    => 0;
use constant CALL_MODE_DATA     => 1;
use constant CALL_MODE_FAX      => 2;
use constant CALL_MODE_UNKNOWN  => 9;


sub new
{
  my ($class, $data) = @_;
  
  my $self = { 
    calls => [],
  };
  
  my @clines = defined($data) ? (split /[\n]/, $data) : ();
  foreach my $cline (@clines) {
    if ($cline =~ /^\+CLCC: (.*)/) {
      my $call = {};
      
      # split into fields
      ($call->{id}, $call->{dir}, $call->{stat}, $call->{mode}, $call->{mpty}, $call->{number}, $call->{type}, $call->{alpha}) = split /,/, $1;

      # remove quotes
      $call->{number} =~ s/^\"(.*)\"$/$1/;
      $call->{alpha} =~ s/^\"(.*)\"$/$1/;
      
      push @{$self->{calls}}, $call;
    } else {
      print "Unrecognised call format '$cline'\n";
    }
  }

  bless($self, $class);  
}


=item B<get> - Get list of current calls from a terminal

=cut

sub get
{
  my ($class, $term) = @_;

  ref($term) or
    Carp::croak("CallList::get : $term is not a terminal!");

  if ($term->send("AT+CLCC" . CR) and ($term->waitfor eq "OK"))
  {
    return $class->new($term->{extra});
  }
    
  $term->logDebug("CallList::get : could not get list of current calls"); 
  return;
}


sub nbActive
{
  my ($self, $mode) = @_;
  
  my $active = 0;
  for (my $i = 0; $i < $self->nbCalls; $i++)
  {
    my $call = $self->call($i);
    ( !defined($mode) or $call->{mode} eq $mode ) and
      ( $call->{stat} eq CALL_STAT_ACTIVE ) and
      $active++;
  }
  
  return $active;
}


sub isDialing
{
  my ($self, $mode) = @_;
  
  my $dialing = 0;
  
  for (my $i = 0; $i < $self->nbCalls; $i++)
  {
    my $call = $self->call($i);
    ( !defined($mode) or $call->{mode} eq $mode ) and
      ( ($call->{stat} eq CALL_STAT_DIALING) or ($call->{stat} eq CALL_STAT_ALERTING) ) and
      $dialing = 1;      
  }
  
  return $dialing;
}


sub call
{
  my ($self, $idx) = @_;
  
  defined($idx) or
    return;
    
  return $self->{calls}->[$idx];
}


sub nbCalls
{
  my $self = shift;

  return (@{$self->{calls}} + 0);
}

1;
