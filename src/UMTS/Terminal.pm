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

package UMTS::Terminal;

use strict;
use vars qw($OS_win @ISA);

use UMTS::Core;
use UMTS::Terminal::Call;
use UMTS::Terminal::Common;
use UMTS::Terminal::Keys;
use UMTS::Terminal::SMS;

# take care of loading Win32 or POSIX module
BEGIN
{
  $OS_win = ($^O eq "MSWin32") ? 1 : 0;
#  print "OS : $^O\n";

  # This must be in a BEGIN in order for the 'use' to be conditional
  if ($OS_win) {
#    print "Loading Windows modules\n";
    eval "use Win32::SerialPort qw (:STAT)";
    die "$@\n" if ($@);
  }
  else {
#    print "Loading POSIX modules\n";
    eval "use Device::SerialPort qw (:STAT)";
    die "$@\n" if ($@);
  }
}

@ISA = $OS_win ? qw(Win32::SerialPort) : qw(Device::SerialPort);
push @ISA, qw(UMTS::Terminal::Common UMTS::Terminal::Call UMTS::Terminal::Keys UMTS::Terminal::SMS);

=head1 NAME

UMTS::Terminal - Class allowing access to a GSM/UMTS terminal

=head1 SYNOPSIS

  use UMTS::Terminal;
  $term = UMTS::Terminal->new( 'port' => $port );

=head1 DESCRIPTION

The C<UMTS::Terminal> class

The following methods are available:

=over 1

=item UMTS::Terminal->new( $options )

Constructs a new terminal instance.

=cut  

sub new
{
  my $class = shift;
  my %params = @_;
    
  my $self = $class->SUPER::new($params{port});
  
  ref($self) or
    return $self;

  UMTS::Terminal::Common::init($self, @_);
  
  # set serial port settings
  $self->baudrate(115200);
  $self->parity("none");
  $self->databits(8);
  $self->stopbits(1);
  $self->handshake("none");
  $self->write_settings;

  # Timeouts will need adjustment for dfferent services and locations.
  # Must give the receiving modem a few seconds to pickup and negotiate.
  #$self->read_const_time(30000);

 
  # atomic wait time
  $self->{waitfor_cycle} = defined($params{waitfor_cycle}) ? $params{waitfor_cycle} : 0.1;
  
  # should we flip DTR and RTS? 
  # This has no effect on USB ports from I can tell, for serial ports a value of 3 is reasonable
  $self->{flip_dtr_rts} = defined($params{flip_dtr_rts}) ? $params{flip_dtr_rts} : 0;
  
  # You probably need at least BUSY and CONNECT
  $self->resetMatch;

  bless ($self, $class);
}


=item $term->flipDTR_RTS

Flip DTR and RTS to try to get hold of the terminal.

=cut  

sub flipDTR_RTS
{
  my $self = shift;  
  my $delay = $self->{flip_dtr_rts};
  my $prefix = "flipDTR_RTS :";
  
  $self->logDebug("$prefix flipping should take about ". $delay * 4 . "s");
  
  # Flip on DTR and RTS
  my $dtr=$self->dtr_active(1) ? "okay" : "failed";
  my $rts=$self->rts_active(1) ? "okay" : "failed";
  $self->logDebug("$prefix activated DTR($dtr) and RTS($rts)");
  $self->wait($delay);

  $dtr=$self->dtr_active(0) ? "okay" : "failed";
  $rts=$self->rts_active(0) ? "okay" : "failed";
  $self->logDebug("$prefix deactivated DTR($dtr) and RTS($rts)");
  $self->wait($delay);
  
  $dtr=$self->dtr_active(1) ? "okay" : "failed";
  $self->logDebug("$prefix activated DTR($dtr)");
  $self->wait($delay);

  $rts=$self->rts_active(1) ? "okay" : "failed";
  $self->logDebug("$prefix activated RTS($rts)");
  $self->wait($delay);
  
  #$self->logLineStatus();
  
}


=item $term->logLineStatus

Log the current line status of the terminal.

=cut  

sub logLineStatus
{
  my $self = shift;
  my $status = $self->modemlines;
 
  # watch out, MS_DTR_ON and MS_RTS_ON not present on Device::SerialPort 0.22!

  #my $msg = sprintf("Modem status = 0x%04X (DTR=%s CTS=%s RTS=%s DSR=%s RNG=%s CD=%s)",
  #      $status,
  #      ($status & MS_DTR_ON) ? "ON " : "off",
  #      ($status & MS_CTS_ON) ? "ON " : "off",
  #      ($status & MS_RTS_ON) ? "ON " : "off",
  #      ($status & MS_DSR_ON) ? "ON " : "off",
  #      ($status & MS_RING_ON) ? "ON " : "off",
  #      ($status & MS_RLSD_ON) ? "ON " : "off",
  #);
  #$self->logDebug($msg);
}


=item $term->reset

Reset the terminal.

=cut  

sub reset
{
  my $self = shift;

  $self->logDebug("reset : resetting terminal");

  # clear errors and buffers
  $self->purge_all;
  $self->reset_error;

  # flip DTR and RTS
  $self->{flip_dtr_rts} and  
    $self->flipDTR_RTS;

  # start by turning local echo off
  # for some reason, if we skip this step some terminals do not respond
  $self->echo(0);

  # my modem resets to give verbose responses
  $self->send("AT". $self->{init_string} . CR);
  if ($self->waitfor ne "OK")
  {
    $self->log("reset : terminal did not reset");
    return RET_ERR;
  }

  # make sure local echo is OFF
  $self->echo(0);

  # enable verbose errors
  $self->send("AT+CMEE=2" . CR);
  if ($self->waitfor ne "OK")
  {
    $self->logDebug("reset : failed to set verbose errors");
  }
  
  # set voice hangup control
  $self->send("AT+CVHU=0" . CR);
  if ($self->waitfor ne "OK")
  {
    $self->logDebug("reset : failed to set voice hangup control");
  }
 
  return RET_OK;
}


=item $term->resetMatch

Reset the match strings to default.

=cut

sub resetMatch
{
  my $self = shift;
  # You probably need at least BUSY and CONNECT
  $self->are_match("BUSY","CONNECT","OK",
       "NO DIALTONE","ERROR","RING","NO CARRIER","NO ANSWER");

}


=item $term->send( $command )

Send a command to the terminal.

=cut
sub send
{
  my ($self, $msg) = @_;
  my $chunk = 64;

  if ($self->{bail})
  {
    $self->logDebug("send : bail flag is set, aborting");
    return RET_ERR;
  }
  
  my $dmsg = $msg;
  my $cr = CR;
  $dmsg =~ s/$cr$//;
  $self->logDebug("send : [$dmsg]");

  $self->purge_all();
  
  my $bytes = length($msg);
  my $done = 0;
  while (length($msg) > 0) {
      my $xmsg = substr($msg, 0, (length($msg)<$chunk)? length($msg) : $chunk );
      $msg = (length($xmsg) < length($msg)) ? substr($msg, $chunk) : '';
      $done += $self->write($xmsg);
      $self->write_drain() unless $OS_win;
      $self->wait(0.1);
  }
 
  return ($done == $bytes) ? RET_OK : RET_ERR;
}


=item $term->waitfor( [$response] )

Wait until we get a given response.

=cut  

sub waitfor
{
  my $self = shift;

  # clear buffers
  $self->lookclear;
  my $gotit = "";
  my $response = shift;

  if ($response)
  {
    $self->are_match($response);
    $self->logDebug("waitfor : Waiting for \"$response\"");
  }

  my $timeout = $self->time + $self->{timeout};

  # loop until we get a response or time out
  for(;;) {
    if ($self->{bail})
    {
      $self->logDebug("waitfor : bail flag is set, aborting");
      return RET_ERR;
    }
    return RET_ERR unless (defined ($gotit = $self->lookfor));

    if ($gotit ne "")
    {
      my ($match, $after) = $self->lastlook;

      #my $got2 = $gotit;
      #$got2 =~ s/[\r\n]+/\n/g;
      #print "----\n" . $got2 . "\n----\n";            

      # remove last sent command from what we received      
      my $extra = $gotit;

      # clean up new line delimiters
      $extra =~ s/[\r\n]+/\n/g;
      $extra =~ s/^\n//;
      $extra =~ s/\n$//;
      $self->{extra} = $extra;

      $after =~ s/[\r\n]+/\n/g;
      $after =~ s/^\n//;
      $after =~ s/\n$//;

      $self->logDebug("waitfor : got: [$match]");
      $self->logDebug("waitfor : extra: [$extra]");
      $self->logDebug("waitfor : after: [$after]");
      return $match;
    }

    if ($self->reset_error)
    {
      $self->log("waitfor : reset_error");
      return RET_ERR;
    }

    if ($self->time > $timeout)
    {
      # we got a timeout    
      $self->log("waitfor : request timed out");
      return RET_ERR;
    }

    $self->wait($self->{waitfor_cycle});
  }

  return RET_ERR;
}

return 1;

=back

