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

package UMTS::Terminal::Common;

use strict;
use warnings;

use UMTS::Core;
use UMTS::Log;
use UMTS::Terminal::Info;
use Time::HiRes;


my $CHARSETS = {
  'ASCII' => '', 
  'GSM' => 'gsm0338',
  'UTF-8' => 'utf8',
  'UCS2' => 'UCS-2BE',
  '8859-1' => 'iso-8859-1',
};


=item B<echo> - Sends the attention command

=cut  

sub attention {
  my $self = shift;
  $self->logDebug('attention : sending attention sequence');

  # Send attention sequence
  $self->send('AT+++' . CR);

  # Wait 200 milliseconds
  $self->wait(0.2);
  $self->waitfor;
  
  return RET_OK;
}


=item B<init> - Initialise some member variables

=cut  

sub init
{
  my $self = shift;
  my %params = @_;

  # bail flag
  $self->{bail} = 0;

  # port
  $self->{port} = defined($params{port}) ? $params{port} : '';
  
  # member variables
  $self->{log} = ref($params{log}) ? $params{log} : UMTS::Log->new;
  
  # timeout for responses from terminal, in seconds
  $self->{timeout} = defined($params{timeout}) ? $params{timeout} : 30;
  
  # is debugging enabled?
  $self->{debug} = defined($params{debug}) ? $params{debug} : 0;  

  # the initialisation string to send to the terminal
  $self->{init_string} = defined($params{init_string}) ? $params{init_string} : 'Z V1 E0';      
}


=item B<cacheTermInfo> - Cache terminal information

=cut  

sub cacheTermInfo
{
  my ($self, $print) = @_;
  defined($print) or $print = 0;
      
  # cache info
  ref($self->{ue}) or
    $self->{ue} = $self->getTermInfo;  
  
  # print log entry
  $print and
    $self->{ue}->log($self->{log});   
  
  return RET_OK;
}


=item B<echo> - Enable or disable local echo

=cut  

sub echo {
  my($self, $lEnable) = @_;

  $self->logDebug("echo : ".( $lEnable ? 'enabling' : 'disabling' ) );
  $self->send( ($lEnable ? 'ATE1' : 'ATE0') . CR );
  
  return RET_OK;
}


=item B<getSignalQuality> - Get signal quality and BER estimation

=cut  
sub getErrorReport
{
  my $self = shift;
  
  my $error = '';  
  if ($self->send("AT+CEER" . CR) and $self->waitfor)
  {
    $error = $self->{extra};
  }
  
  return $error;
}


=item B<getSignalQuality> - Get signal quality and BER estimation

=cut  

sub getSignalQuality
{
  my $self = shift;
  
  if (!$self->send("AT+CSQ" . CR))
  {
    $self->log("getSignalQuality : could not get signal quality\n");
    return RET_ERR;
  }
  
  my $stat = $self->waitfor;
  if (($self->{extra} !~ /^\+CSQ: ([0-9]+),([0-9]+)/)) 
  {
    $self->log("getSignalQuality : could not parse signal quality response : $self->{extra}");
    return RET_ERR;
  }
  
  my ($rssi, $ber) = ($1, $2);
  my ($rssitxt, $bertxt);

  if (!$rssi)
  {
    $rssitxt = "-113 dBm or less";
  } elsif ($rssi == 31) {
    $rssitxt = "-51 dBm or greater";
  } elsif ($rssi == 99) {
    $rssitxt = "unknown";
  } else {
    $rssitxt = ( 2* $rssi - 113). " dBm";
  }

  if ($ber == 99)
  {
    $bertxt = "unknown";
  } else {
    $bertxt = "$ber %";
  }

  return ("$rssitxt ($rssi)", "$bertxt ($ber)");
}


=item B<getTermInfo> - Return terminal information

=cut  

sub getTermInfo
{
  my $self = shift;
  my ($t_manuf, $t_model, $t_rev, $t_imei, $t_imsi);
  
  $self->send("AT+CGMI" . CR);
  if ($self->waitfor)
  {
    $t_manuf = $self->{extra};
    $t_manuf =~ s/^\+CGMI: (.*)$/$1/;
    $t_manuf =~ s/^\"(.*)\"$/$1/;
  }  
    
  $self->send("AT+CGMM" . CR);
  if ($self->waitfor)
  {
    $t_model = $self->{extra};
    $t_model =~ s/^\+CGMM: (.*)$/$1/;
  }
  
  $self->send("AT+CGMR" . CR);
  if ($self->waitfor)
  {
    $t_rev = $self->{extra};
    $t_rev =~ s/^\+CGMR: (.*)$/$1/;
    $t_rev =~ s/^\"(.*)\"$/$1/;    
  }  
  
  $self->send("AT+CGSN" . CR);
  if ($self->waitfor)
  {
    $t_imei = $self->{extra};
    $t_imei =~ s/^\+CGSN: (.*)$/$1/;
  }

  $self->send("AT+CIMI" . CR);
  if ($self->waitfor)
  {
    $t_imsi = $self->{extra};
    $t_imsi =~ s/^\+CIMI: (.*)$/$1/;
  }

  # try to guess type
  return UMTS::Terminal::Info->new($t_manuf, $t_model, $t_rev, $t_imei, $t_imsi);  
}


=item B<log> - Add a log entry

=cut  

sub log
{
  my ($self, $msg) = @_;
  $self->{log}->write("UMTS::Terminal::$msg");
}


=item B<logDebug> - Add a debugging log entry

=cut  

sub logDebug
{
  my ($self, $msg) = @_;
  
  $self->{debug} and $self->log($msg);  
}


=item B<send> - Send a command to the terminal

=cut
sub send
{
  die("send must be overriden");
}


=item B<main> - Set the TE character set

=cut 

sub setCharacterSet
{
  my ($self, $charset) = @_;
  
  if (!exists($CHARSETS->{$charset})) {
    $self->log("setCharacterSet : unknown character set '$charset' specified");
    return RET_ERR;
  }  
  
  $self->send("AT+CSCS=\"$charset\"" . CR);
  if ($self->waitfor ne "OK")
  {
    $self->log("setCharacterSet : setting character set '$charset' failed");
    return RET_ERR;
  }
  
  $self->{charset} = $CHARSETS->{$charset};
  
  return RET_OK;
}


=item B<time> - Return the time in seconds

=cut  

sub time {
  return Time::HiRes::time();
}


=item B<wait> - Wait for a certain number of seconds

=cut  

sub wait {
  my( $self, $secs ) = @_;

#  $self->logDebug("waiting for $secs seconds");
  my $now = $self->time;
  my $timeout = $now + $secs;

  while ($now < $timeout)
  {
    if ($self->{bail}) {
      $self->logDebug("wait : bail flag is set, aborting");
      return RET_ERR;
    }
    my $left = $timeout - $now;
    my $slp = ($left > 1) ? 1 : $left;
    my $actual = Time::HiRes::sleep($slp);
    $now = $self->time;
  }

#  $self->logDebug("wait : total delta ". ($now - $timeout));
  return RET_OK;
}


=item B<waitfor> - Wait until we get a given response

=cut  

sub waitfor
{
  die("waitfor needs to be overriden");
}


return 1;


