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

package UMTS::Terminal::Call;

use strict;
use warnings;

use UMTS::Core;
use UMTS::Terminal::CallList;
use UMTS::Terminal::CallStatus;


=item B<checkCallEstablished> - Check that a call was correctly established

=cut  

sub checkCallEstablished
{
  my ($self, $pollwait) = @_;  
  
  # log prefix
  my $prefix = "checkCallEstablished";

  # Set how often we poll the call status in seconds
  defined($pollwait) or $pollwait = 1;
  
  # check if the UE has a mechanism to poll call status
  my $CallStat = $self->{ue}->getCallStat;          
  
  my $timeout = $self->time + $self->{timeout};
    
  # check activity status
  if ($CallStat)
  {
    my $stat;
    
    # if we are dialing or alerting and if we have not yet reached timeout
    # we wait for a bit
    do
    {
      # get the current call status
      $stat = $CallStat->get($self);
      if (!ref($stat))
      {
         $self->logDebug("$prefix : could not get call status, aborting");
	 return RET_ERR;
      }
      if ($stat->isDialing)
      {
        $self->logDebug("$prefix : dialing in progress, pausing");
        if (!$self->wait($pollwait)) {
          $self->logDebug("$prefix : wait failed, aborting");
          return RET_ERR;
        }
      }
    } while ($stat->isDialing and ($self->time < $timeout));

    # check if the call succeeded
    if ($stat->nbActive) 
    {
      $self->logDebug("$prefix : ok, found active call");
      return RET_OK;
    }
    else
    {
      $self->logDebug("$prefix : no active call found");      
      return RET_ERR;
    }    
    
  } else {
    
    # if no checking mechanism is available, we assume call succeeded
    $self->logDebug("$prefix : no mechanism available, assuming ok");    
    return RET_OK;
    
  }

}


=item B<monitorCall> - Monitor a call for a given duration

=cut  

sub monitorCall
{
  my ($self, $duration, $pollwait) = @_;

  # Set how often we poll the call status in seconds
  #
  # * for short calls (less than 60s) poll every 5s, 
  # * for longer calls only poll every 30s to save terminal battery time.  
  defined($pollwait) or $pollwait = ($duration < 60) ? 5 : 30;
  
  # check if the UE has a mechanism to poll call status
  my $CallStat = $self->{ue}->getCallStat;
  
  my $start = $self->time;
  my $stop = $start + $duration;  
    
  # initially, call is OK
  my $ret = RET_OK;
  my $exit = 0;
  
  # loop until we get an exit condition
  while ( !$exit )
  {
    # if necessary, adjust the waiting time so that we do not exceed the
    # planned dialing time
    my $now = $self->time;
    my $thiswait = (($now + $pollwait) < $stop) ? $pollwait : ($stop - $now);
    
    # sleep for a bit
    if (!$self->wait($thiswait)) {
      $self->logDebug("monitorCall : wait failed, aborting");
      return RET_ERR;
    }
  
    # poll the call status if we can and if the call is OK so far
    if ($CallStat and ($ret eq RET_OK))
    {
      my $stat = $CallStat->get($self);
      if (!ref($stat))
      {
        $self->log("monitorCall : could not get call status, aborting");
	return RET_ERR;
      }
      
      # if there are no active calls, the call was dropped
      if (!$stat->nbActive)
      {
        my $lasted = $self->time - $start;
        $self->log("monitorCall : call drop detected at $lasted seconds");
        $ret = RET_ERR;
      }
      
    }
    
    # check exit condition
    if ($duration) {
    
      # if the duration is non-zero, the exit condition is that we reached
      # the expected call duration
      $exit = ($self->time >= $stop);
      
    } else {
    
      # if the duration is 0, the exit condition is that the call was dropped
      $exit = ($ret eq RET_ERR);
      
    }    
  }
  
  return $ret;
  
}


=item B<dialVideo> - Dial a video call

=cut

sub dialVideo
{
  my ($self, $phoneNumber, $logPrefix) = @_;

  defined($logPrefix) or $logPrefix = "dialVideo";
  
  # some features are UE type specific
  $self->cacheTermInfo;      
   
  # did the call succeed?
  my $result = RET_ERR;
  
  # make sure we are in the idle screen before dialing
  $self->wakeup;
  $self->gotoIdleScreen;
    
  # place video call  
  $self->log("$logPrefix : making video call to $phoneNumber");  
  if ($self->{ue}->type eq "motorola")
  {
    my $revision = $self->{ue}->revision;
    my $dialstr;
    $self->logDebug("$logPrefix : UE revision $revision");
    if ($revision =~ /_U_80\./) {    
      # for 80.xx.yy
      $dialstr = "mvv[";
    } elsif ($revision =~ /_U_83\./) {    
      # for 83.xx.yy
      $dialstr = "mv[";
    } elsif ($revision =~ /_U_85\./) {    
      # for 85.xx.yy
      $dialstr = "[vvvv[";
    } else {
      $self->log("$logPrefix : dial string for this revision is not known!\n");
      return RET_ERR;
    }

    $self->send("AT+ckpd=\"$phoneNumber\"" . CR);
    $self->waitfor;

    $self->send("AT+ckpd=$dialstr" . CR);
    $self->waitfor;
    
    $self->wait(1);

  } elsif ($self->{ue}->type eq "semc") {
  
    $self->send("AT+ckpd=\"$phoneNumber\"" . CR);
    $self->waitfor;
    
    $self->wait(3);
    
    $self->send("AT+ckpd=\":M\"" . CR);
    $self->waitfor;          

  } else {
  
    $self->log("$logPrefix : UE type '".$self->{ue}->type."' does not support video call");
    return RET_ERR;    
  }

  # check the call was established
  if ($self->checkCallEstablished ne RET_OK) 
  {
    $self->log("$logPrefix : no active call found");

    # make sure we return to the idle screen
    $self->gotoIdleScreen;
    return RET_ERR;
  } 
    
  return RET_OK;
}


=item B<dialVoice> - Dial a voice call

=cut  

sub dialVoice
{
  my ($self, $phoneNumber, $logPrefix) = @_;
  
  defined($logPrefix) or $logPrefix = "dialVoice";

  $self->log("$logPrefix : making voice call to $phoneNumber");  
    
  # check we sent the command OK
  if (!$self->send("ATD$phoneNumber;" . CR))
  {
    $self->log("$logPrefix : failed to send dial string");
    return RET_ERR;
  }
  
  # check we got an OK response
  if ($self->waitfor ne "OK")
  {
    $self->log("$logPrefix : call failed (".$self->getErrorReport.")");
    return RET_ERR;
  }  

  # check the call was established
  if ($self->checkCallEstablished ne RET_OK) 
  {
    $self->log("$logPrefix : no active call found");
    return RET_ERR;
  }
    
  return RET_OK;  
}


=item B<hangupVoice> - Hang up voice call

=cut  

sub hangupVoice
{
  my $self = shift;
  
  # some features are UE type specific
  $self->cacheTermInfo;      
  my $hup = $self->{ue}->getHangup;
  
  # hangup the modem
  $self->log("hangup : hanging up voice call");
  $self->send($hup . CR);
  
  # Samsung terminals reply "NO CARRIER" to indicate a call 
  # was terminated and repy "OK" when no call was ended.
  
  return ($self->waitfor eq "OK") ? RET_OK : RET_ERR;
}


=item B<hangupVideo> - Hang up video call

=cut  

sub hangupVideo
{
  my $self = shift;

  # some features are UE type specific
  $self->cacheTermInfo;
    
  if ($self->{ue}->type eq "motorola")
  {
    # hangup video call
    $self->log("hangup : hanging up video call");
    $self->send("AT+ckpd=e" . CR);
  } else {
    $self->hangupVoice;
  }
  
  return RET_OK;
}


=item B<placeCall> - Place a call and hold it for a specified duration

=cut  

sub placeCall
{
  my ($self, $phoneNumber, $type, $callDuration, $prefix) = @_;
   
  # get signal quality
  my ($rssi, $ber) = $self->getSignalQuality;
  $self->log("$prefix : signal level $rssi, BER $ber");

  # place call
  my ($dial_ok, $call_ok);
  
  if ($type eq "voice")
  {
    $dial_ok = $self->dialVoice($phoneNumber, $prefix);
  } 
  elsif ($type eq "video") 
  {
    $dial_ok = $self->dialVideo($phoneNumber, $prefix);
  } else {
    $self->log("$prefix : ERROR, unknown call type '$type'");
    return RET_ERR;
  }
 
  # check if we are bailing
  return RET_ERR if $self->{bail};
  
  if ($dial_ok)
  {
    # monitor the call for the specified call duration  
    $self->log("$prefix : OK, call established, monitoring for $callDuration seconds");    
    $call_ok = $self->monitorCall($callDuration);        
  
  } else {
    # call failed, wait for the specified call duration
    $self->log("$prefix : ERROR, call failed, waiting $callDuration seconds");    
    $self->wait($callDuration);
    
    return RET_ERR;
  }

  # check if we are bailing
  return RET_ERR if $self->{bail};
  
  # hang up
  $self->endCall($type);

  return ($dial_ok, $call_ok);
}


=item B<endCall> - Terminate a call

=cut  

sub endCall
{
  my ($self, $type) = @_;
 
  if ($type eq "voice") 
  {
    return $self->hangupVoice;
  }
  elsif ($type eq "video") 
  {
    return $self->hangupVideo;
  } else {
    $self->log("endCall : ERROR, unknown call type '$type'");
    return RET_ERR;
  }
}

1;

