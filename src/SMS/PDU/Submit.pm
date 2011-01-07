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
package SMS::PDU::Submit;

use strict;
use warnings;

use vars qw(@ISA);

use SMS::PDU qw(:types :sca);
use SMS::PDU::UserData qw(:dcs);

use constant SMS_HDR_VP_REL    => 0x10;  # VP field present : relative (integer)
use constant SMS_HDR_VP_ABS    => 0x18;  # VP field present : absolute (semi-octet)

@ISA = qw(SMS::PDU);


=head1 NAME

SMS::PDU::Submit - Class encapsulating SMS Submit PDUs

=head1 SYNOPSIS

  use SMS::PDU::Submit;
  $s = SMS::PDU::Submit->decode;

=head1 DESCRIPTION

The C<SMS::PDU::Submit> class allows you to encode or decode
SMS Submit Protocol Data Units (PDU). The encoding and decoding of
the TP-UD (user data) field is done by
L<SMS::PDU::UserData|SMS::PDU::UserData>.

The following methods are available:

=over 3

=item SMS::PDU::Submit->decode

Decode an SMS Submit PDU from a binary string.

=cut

sub decode
{
  my $class = shift;
  my($pkt, $parent, @rest) = @_;
 
  my $self = {
    'TP-UDHI' => 0,
    'TP-RP' => 0,
    'TP-SRR' => 0,
    'TP-VPF' => 0,
    'TP-RD' => 0,
    'TP-MTI' => SMS_SUBMIT,

    smsc => '',
    'TP-DA' => '',
    'TP-UD' => undef,
    'TP-DCS' => PDU_DCS_7BIT,
    'TP-PID' => 0x00,
    'TP-MR' => 0x00,
    'TP-VP' => 0xFF,
  };

  bless($self, $class);

  if (defined($pkt) and ($pkt ne '')) {

    ($self->{smsc}, $pkt) = $self->decodeAddress($pkt, SMS_IS_SCA);    

    my $pdutype = unpack('C', $pkt);
    $pkt = substr($pkt, 1);

    #print "PDU type : $pdutype\n";    
    $self->{'TP-UDHI'} = ($pdutype >> 6) & 1;
    $self->{'TP-RP'} = ($pdutype >> 7) & 1;  
    $self->{'TP-SRR'} = ($pdutype >> 5) & 1;
    $self->{'TP-VPF'} = ($pdutype >> 3) & 0x3;
    $self->{'TP-RD'} = ($pdutype >> 2) & 1;      
    #$self->{'TP-MTI'} = $pdutype & 0x3;    
    my $mti = $pdutype & 0x3;
    if ($mti ne SMS_SUBMIT) {
      print "Invalid PDU type, this is not an SMS Submit!\n";
      return;
    }

    # message reference
    $self->{'TP-MR'} = unpack('C', $pkt);
    $pkt = substr($pkt, 1);

    # 
    ($self->{'TP-DA'}, $pkt) = $self->decodeAddress($pkt);

    ($self->{'TP-PID'}, $self->{'TP-DCS'}) = unpack('CC', $pkt);
    $pkt = substr($pkt, 2);

    if ($self->{'TP-VPF'}) {
      $self->{'TP-VP'} = unpack('C', $pkt);
      $pkt = substr($pkt, 1);
    }

    # message length is not used
    my $len = unpack('C', $pkt);
    $pkt = substr($pkt, 1);

    # decode TP-UD
    $self->{'TP-UD'} = SMS::PDU::UserData->decode($pkt, udhi => $self->{'TP-UDHI'}, dcs => $self->{'TP-DCS'}); 
  }

  return $self;
}


=item $s->encode

Encode an SMS Submit PDU into a binary string.

=cut

sub encode
{
  my $self = shift;

  my $hdr;
  
  # SCA
  $hdr .= $self->encodeAddress($self->{smsc}, SMS_IS_SCA);
  
  # set UDHI
  $self->{'TP-UDHI'} = $self->{'TP-UD'}->hasUDHI;
  $self->{'TP-VPF'} = $self->{'TP-VP'} ?  2 : 0;
  
  # PDU type
  my $pdutype = $self->{'TP-MTI'};  
  $pdutype|= ($self->{'TP-RP'} << 7);
  $pdutype|= ($self->{'TP-UDHI'} << 6);  
  $pdutype|= ($self->{'TP-SRR'} << 5);
  $pdutype|= ($self->{'TP-VPF'} << 3);
  $pdutype|= ($self->{'TP-RD'} << 2);  
  $hdr .= pack('C', $pdutype);
  
  # message reference
  $hdr .= pack('C', $self->{'TP-MR'});
  
  # encode destination
  $hdr .= $self->encodeAddress($self->{'TP-DA'});

  # protocol identifier
  $hdr .= pack('C', $self->{'TP-PID'});
  
  # data encoding scheme
  $hdr .= pack('C', $self->{'TP-DCS'});
  
  if ($self->{'TP-VP'}) {
    $hdr .= pack('C', $self->{'TP-VP'});
  }

  # frame length 
  my ($data,$len) = $self->{'TP-UD'}->encode;  
  return $hdr . pack('C', $len) . $data; 
}


sub frameUserData {
  my ($class, $smsc, $msisdn, @uds) = @_;
  defined($smsc) or $smsc = '';
  
  # build SMS frames  
  my @frames;
  foreach my $ud (@uds)
  {
    # make SMS frame
    my $nbs = $class->decode;
    $nbs->{'TP-DCS'} = $ud->{dcs};
    $nbs->{'TP-UD'} = $ud;
    $nbs->{'TP-DA'} = $msisdn;
    $nbs->{smsc} = $smsc;
    push @frames, $nbs;
  }  
  
  return (@frames > 1) ? @frames : shift @frames;
}


=item $s->getNumber

Return the destination phone number of the SMS Submit PDU.

=cut

sub getNumber
{
  my $self = shift;
  return $self->{'TP-DA'};
}


1;

=back
