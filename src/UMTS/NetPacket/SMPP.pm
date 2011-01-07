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
package UMTS::NetPacket::SMPP;

use strict;
use warnings;

use SMS::PDU::UserData qw(:dcs);

# SMPP 5.0 pp 4.7.1
use constant SMPP_TON_UNKNOWN   => 0x00;
use constant SMPP_TON_INTERNAT  => 0x01;
use constant SMPP_TON_NATIONAL  => 0x02;
use constant SMPP_TON_NETWORK   => 0x03;
use constant SMPP_TON_SUBSCR    => 0x04;
use constant SMPP_TON_ALPHA     => 0x05;
use constant SMPP_TON_ABBREV    => 0x06;

# SMPP 5.0 pp 4.7.2
use constant SMPP_NPI_UNKNOWN   => 0x00;
use constant SMPP_NPI_ISDN      => 0x01;
use constant SMPP_NPI_DATA      => 0x03;
use constant SMPP_NPI_TELEX     => 0x04;
use constant SMPP_NPI_LAND      => 0x06;
use constant SMPP_NPI_NATIONAL  => 0x08;
use constant SMPP_NPI_PRIVATE   => 0x09;
use constant SMPP_NPI_ERMES     => 0x10;
use constant SMPP_NPI_IP        => 0x14;
use constant SMPP_NPI_WAP       => 0x18;

# SMPP 5.0 pp 4.7.5 command_id
use constant SMPP_CMD_QUERY_SM   => 0x00000003;
use constant SMPP_CMD_SUBMIT_SM  => 0x00000004;
use constant SMPP_CMD_DELIVER_SM => 0x00000005;

# command_status
use constant SMPP_STAT_OK        => 0x00000000;

# data coding
use constant SMPP_DCS_DEFAULT    => 0x00;
use constant SMPP_DCS_8BIT       => 0x02;
use constant SMPP_DCS_LATIN1     => 0x03;
use constant SMPP_DCS_UCS2       => 0x08;

sub decode
{
  my $class = shift;
  my($pkt, $parent, @rest) = @_;
 
  my $self = {
    cmd => SMPP_CMD_SUBMIT_SM,
    status => SMPP_STAT_OK,
    seq => 0,
   
    tos => 0x00,   
    from => '',
    msisdn => '',
    class => 0x40,   
    proto => 0x00,
    priority => 0x00,
   
    delivery => 0x00,
    vp => 0x00,
   
    registered => 0x00,
    replace => 0x00,
    predef => 0,
    dcs => SMPP_DCS_8BIT,
   
    ud => undef,
  };
 
  bless($self, $class);
  
  if (defined($pkt) and $pkt ne '') 
  {
    ## DECODE FRAME HEADER ##
   
    my $len;
    ($len, $self->{cmd}, $self->{status}, $self->{seq}) = unpack('NNNN', $pkt);
    $pkt = substr($pkt, 16);
   
    ## DECODE FRAME BODY ##
   
    $self->{tos} = unpack('C', $pkt);
    $pkt = substr($pkt, 1);
   
    ($self->{from}, $pkt) = $self->decodeAddress($pkt);
    ($self->{msisdn}, $pkt) = $self->decodeAddress($pkt);
     
    ($self->{class}, $self->{proto}, $self->{priority}) = unpack('CCC', $pkt);
    $pkt = substr($pkt, 3);
   
    ($self->{delivery}, $self->{vp}) = unpack('CC', $pkt);
    $pkt = substr($pkt, 2);
   
    my $len2;
    ($self->{registered}, $self->{replace}, $self->{dcs}, $self->{predef}, $len2) = unpack('CCCCC', $pkt);
    $pkt = substr($pkt, 5);

    if (length($pkt) eq $len2)
    {
      $self->{ud} = SMS::PDU::UserData->decode($pkt, udhi => 1, dcs => PDU_DCS_8BIT);
    } else {
      print "SMPP::decode : data length mismatch, frame is corrupted\n";
      return;
    }    
    
  }
 
  return $self;
}


sub encode
{
  my $self = shift;  
  
  # the payload
#  print "encode() PDU dcs " . $self->{ud}->{dcs}."\n";
  my ($data) = $self->{ud}->encode;
  
  ## BUILD FRAME BODY ##
  my $frame;
  
  # type of service
  $frame = pack('C', $self->{tos});
  
  # originatorref
  $frame .= $self->encodeAddress($self->{from});
    
  # dest
  $frame .= $self->encodeAddress($self->{msisdn});

  # class, proto, priority
  $frame .= pack('CCC', $self->{class}, $self->{proto}, $self->{priority});
    
  # schedule_delivery_time, validity_period
  $frame .= pack('CC', $self->{delivery}, $self->{vp});
  
  # registered, replace, dcs, predefined message
  $frame .= pack('CCCC', $self->{registered}, $self->{replace}, $self->{dcs}, $self->{predef});
  
  # message length  
  $frame .= pack('C', length($data));  
  $frame .= $data;

  
  ## BUILD FRAME HEADER ##
  
  # command length, operation, status, sequence number 
  my $hdr = pack('NNNN', 16 + length($frame), $self->{cmd}, $self->{status}, $self->{seq});
    
  return $hdr . $frame;  
}


sub decodeAddress
{
  my ($self, $in) = @_;  

  my ($type, $npi, $number) = unpack('CCZ*', $in);
  $in = substr($in, length($number) + 3);  
  
  ($type eq SMPP_TON_INTERNAT) and
    $number = '+' . $number;
    
  return ($number, $in);  
}


sub encodeAddress
{
  my ($self, $number) = @_;

  my $type = SMPP_TON_UNKNOWN;
  my $npi = 0x01;
  
  defined($number) or $number = '';
  
  if (length($number) > 0)
  {
    # Find type of phonenumber
    # no + => unknown number, + => international number
    $type = (substr($number,0,1) eq '+')? SMPP_TON_INTERNAT : SMPP_TON_NATIONAL;
  
    # Delete any non digits => + etc...
    $number =~ s/\D//g;
  }
  
  return pack('CCZ*', $type, $npi, $number);
}


1;
