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

package UMTS::Terminal::SMS;

use strict;

use UMTS::Core;
use UMTS::SMS qw(:modes);
use SMS::PDU::UserData qw(:dcs :codings);
use SMS::PDU;
use SMS::PDU::Deliver;
use SMS::PDU::Submit;


=item B<sendPDU> - Send a PDU encoded message

=cut

sub sendPDUs
{
  my($self, $cmd, @frames) = @_;
  #defined($cmd) or $cmd = 'CMGS';
  # cmd is either CMGS or CMGW
  
  if ($self->{msg_mode} ne SMS_MODE_PDU) {
    $self->setMessageMode(SMS_MODE_PDU) or
      return RET_ERR;
  }

  # make SMS frames
  foreach my $frame ( @frames ) {
    my $binmsg = $frame->encode;
    my $msg = uc(unpack('H*', $binmsg));
    my $len = SMS::PDU->getTPLength($binmsg);
        
    $self->are_match("ERROR", "OK", ">");       
    if (!$self->send("AT+$cmd=$len" . CR) or ($self->waitfor ne ">"))
    {
      $self->log("sendPDU : AT+$cmd=$len failed");  
      return RET_ERR;
    }
    $self->resetMatch;
    
    if (!$self->send($msg . CTRL_Z) or ($self->waitfor ne "OK")) 
    {
      $self->log("sendPDU : sending PDU failed");
      return RET_ERR;
    }        
  }
  
  return RET_OK;
}


=item B<sendSMSTextMessage> - Send a text message

  $nbs->sendSMSTextMessage( $msisdn, $msg, $srr, $flash );

Send a text message ( $msg ) to the gsm number ( $msisdn ) in PDU mode. The message will be split automatically in blocks of 160 characters.

If the $srr option is true, a read report will be requested. 

If the $flash option is true, the message will be displayed immediately on the screen of the receiving mobile phone. This message is not stored in the SIM memory of the mobile phone.
 
=cut

sub sendSMSTextMessage
{
  my ($self, $msisdn, $msg, %opts) = @_;

  my $srr = defined($opts{readreport}) ? $opts{readreport} : 0;
  my $flash = defined($opts{flash}) ? $opts{flash} : 0;
  my $coding = defined($opts{coding}) ? $opts{coding} : PDU_CODING_7BIT;

  my $prefix = "sendSMSTextMessage";
  my $dcs;

  if ($flash && ($coding != PDU_CODING_7BIT))
  {
    $self->log("$prefix : 'flash' attribute will be discarded");
  }

  if ($coding == PDU_CODING_8BIT) {
    $dcs = PDU_DCS_8BITM;
    $self->logDebug("$prefix : using 8BITM encoding");
  } elsif ($coding == PDU_CODING_UCS2) {
    $dcs = PDU_DCS_UCS2;
    $self->logDebug("$prefix : using UCS2 encoding");
  } elsif ($coding == PDU_CODING_7BIT) {
    if ($flash) {
      $dcs = PDU_DCS_7BITI;
      $self->logDebug("$prefix : using 7BITI encoding");
    } else {
      $dcs = PDU_DCS_7BIT;
      $self->logDebug("$prefix : using 7BIT encoding");
    }
  } else {
    Carp::croak("$prefix : an unknown encoding was specified");
  }

  # split into UserData
  my $udFactory = SMS::PDU::UserData->decode('', dcs => $dcs);
  $udFactory->{data} = $msg;
  my @userdata = $udFactory->split;

  my @tmp = SMS::PDU::Submit->frameUserData('', $msisdn, @userdata);
  my @tpdus;
  foreach my $tpdu (@tmp)
  {
    $tpdu->{'TP-SRR'} = $srr;
    push @tpdus, $tpdu;
  }
  return $self->sendPDUs('CMGS', @tpdus);
}


=item B<sendSMSTextMessageDumb> - Send an SMS text message in text mode (AT+CMGF=1)

  $nbs->sendSMSTextMessageDumb( $msisdn, $msg );

Send a text message ( $msg ) to the gsm number ( $msisdn ) in text mode. No checking is done as to the length of the message.

=cut  

sub sendSMSTextMessageDumb
{
  my ($self, $msisdn, $msg) = @_;

  $self->setMessageMode(SMS_MODE_TEXT) or
    return RET_ERR;

  $self->are_match("ERROR", "OK", ">");  
  if (!$self->send("AT+CMGS=\"$msisdn\"" . CR))
  {
    $self->log("sendSMSTextMessageDumb : sending AT+CMGS=\"$msisdn\" failed");  
    return RET_ERR;
  }

  my $ret = $self->waitfor;
  if (($ret ne "OK") and ($ret ne ">"))
  {
    $self->log("sendSMSTextMessageDumb : bad response \"$ret\", sending failed");  
    return RET_ERR;
  }

  $self->resetMatch;
  
  $self->send($msg . CTRL_Z);
  if ($self->waitfor ne "OK")
  {
    return RET_ERR;
  } 
  
  return RET_OK;
}


=item B<setMessageMode> - Set the message mode (0 = PDU, 1 = TEXT)

=cut  

sub setMessageMode
{
 my ($self, $mode) = @_;
 
 my $modes = {
   0  => 'PDU',
   1 => 'text'
 };
 
 if (!defined($modes->{$mode})) {
   $self->log("setMessageMode : unknown mode '$mode'");
   return RET_ERR;
 }
  
 if (defined($self->{msg_mode}) && ($self->{msg_mode} eq $mode)) {
   return RET_OK;
 }
 
 if (!$self->send("AT+CMGF=$mode" . CR) or ($self->waitfor ne "OK"))
  {
    $self->log("setMessageMode : could not set $modes->{$mode} mode");
    return RET_ERR;
  }  
  
  $self->{msg_mode} = $mode;
  return RET_OK;
}


=item B<setSCA> - Set the service center address (for SMS)

=cut  

sub setSCA
{
  my ($self, $sca) = @_;
  my $resp;
  
  $self->send("AT+CSCA=\"$sca\"" . CR);
  if ($self->waitfor ne "OK")
  {
    $self->log("setSCA : could not set service center address!");
    return RET_ERR;    
  }
  
  $self->send("AT+CSCA?" . CR);
  if ($self->waitfor ne "OK") {
    $self->log("setSCA : could not read service center address");
    return RET_ERR;
  }
  
  return RET_OK;
}


return 1;


