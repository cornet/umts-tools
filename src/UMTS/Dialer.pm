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

package UMTS::Dialer;

use strict;
# use warnings;

use UMTS::Core;
use UMTS::Log;

sub new
{
  my $class = shift; 
  my %params = @_;

  if (!defined($params{term}))
  {
    print "UMTS::Dialer::new parameter 'term' must be set!\n";
    return;
  }
  
  if (!defined($params{call_number}))
  {
    print "UMTS::Dialer::new parameter 'call_number' must be set!\n";
    return;
  }
  
  my $self = {
    'beep' => 1,
    'call_duration' => 120,
    'call_wait' => 60,
    'call_max' => 100,
    'call_type' => 'voice',
    'result_freq' => 10,
    @_
  };

  ref($self->{log}) or $self->{log} = UMTS::Log->new;
  ref($self->{reslog}) or $self->{reslog} = UMTS::Log->new;

  $self->{results} = {
    calls => 0,
    errors => 0,
    call_fail => 0,
    call_drop => 0,
  };
            
  bless($self, $class);
}


=item B<bail> - Set bail out flag

=cut  

sub bail
{
  my $self = shift;
  $self->log("bail : setting bail flag");
  $self->{term}->{bail} = 1;
}

=item B<isBailing> - Is the bail out flag set?

=cut  

sub isBailing
{
  my $self = shift;
  return $self->{term}->{bail};
}


=item B<log> - Add a log entry

=cut  

sub log
{
  my ($self, $msg) = @_;
  $self->{log}->write("UMTS::Dialer::$msg");
}



# the main loop
sub run
{
  my ($self) = @_;
  
  if (!ref($self->{term})) {
    $self->log("run : not a valid terminal");
    return RET_ERR;    
  }
  
  # this is called if the program is interrupted
  $SIG{INT} = sub 
  {
    $self->log("run : caught interrupt");
    #undef $SIG{INT};    
    $self->bail;    
  };

  # log terminal information
  $self->{term}->cacheTermInfo;
  $self->{reslog}->write("-- Terminal information --");  
  $self->{term}->{ue}->log($self->{reslog});
  
  $self->log("run : $self->{call_max} $self->{call_type} calls of $self->{call_duration}s to $self->{call_number}");
  # performs the tests
  while (($self->{results}->{calls} < $self->{call_max}) and !$self->isBailing)
  {
    my $prf = $self->{call_type} . "Call(".$self->{results}->{calls}.")";
    
    # place the call
    my ($dial_ok, $call_ok) = $self->{term}->placeCall($self->{call_number}, $self->{call_type}, $self->{call_duration}, $prf);
        
    if ($self->isBailing) {
      next;
    }
    
    $self->{results}->{calls}++;
  
    # if there was an error, count it    
    if (!$dial_ok or !$call_ok) {
          
      $self->{results}->{errors}++;    
    
      # optionally emit a bit on a call failure
      $self->{beep} and
        print "\a\a\a\a";
    }
    
    # detetermine the error type
    if (!$dial_ok)
    {        
      # this is a call setup failure
      $self->{results}->{call_fail}++;      
    } 
    elsif (!$call_ok)
    {
      # this is a call drop
      $self->{results}->{call_drop}++;
    }
    
    # log results if this is not the last call and if we have reached
    # the logging frequency
    if (($self->{results}->{calls} < $self->{call_max}-1) and
        ($self->{results}->{calls} and $self->{result_freq}) and
	(($self->{results}->{calls} % $self->{result_freq}) eq 0))
    {
      $self->logResults($self->{reslog});
    }
    
    # wait before starting again
    $self->log("run : waiting for $self->{call_wait} seconds");
    $self->{term}->wait($self->{call_wait});
  }

  # output the final results
  $self->logResults($self->{reslog});    
   
  $self->log("run : cleaning up");
  $self->{term}->{bail} = 0;
  $self->{term}->endCall($self->{call_type});

  $self->log("run : returning");
  return RET_OK;
}


# outputs the results of the measurements
sub logResults
{
  my ($self, $log) = @_;

  my $results = $self->{results};
  my $dial_ok = $results->{calls} - $results->{call_fail};    
  my $err_percent = $results->{calls}? ($results->{errors} / $results->{calls} * 100) : 0;
  my $fail_percent = $results->{calls} ? ($results->{call_fail} / $results->{calls} * 100) : 0;    
  my $drop_percent = $dial_ok ? ($results->{call_drop} / $dial_ok * 100) : 0;
  
  $log->write("-- Results after $results->{calls} calls --");
  $log->write("Total errors  : $results->{errors} ($err_percent %)");    
  $log->write("Call failures : $results->{call_fail} ($fail_percent %)");    
  $log->write("Call drops    : $results->{call_drop} ($drop_percent %)");     
}


return 1;
