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
package SMS::PDU::Deliver;

use strict;
use warnings;

use vars qw(@ISA);

use SMS::PDU qw(:types :sca);
use SMS::PDU::UserData qw(:dcs);

@ISA = qw(SMS::PDU);


=head1 NAME

SMS::PDU::Deliver - Class encapsulating SMS Deliver PDUs

=head1 SYNOPSIS

  use SMS::PDU::Deliver;
  $s = SMS::PDU::Deliver->decode;

=head1 DESCRIPTION

The C<SMS::PDU::Deliver> class allows you to encode or decode
SMS Deliver Protocol Data Units (PDU). The encoding and decoding of
the TP-UD (user data) field is done by
L<SMS::PDU::UserData|SMS::PDU::UserData>.

The following methods are available:

=over 3

=item SMS::PDU::Deliver->decode

Decode an SMS Deliver PDU from a binary string.

=cut

sub decode
{
  my $class = shift;
  my($pkt, $parent, @rest) = @_;
 
  my $self = {
    'TP-UDHI' => 0,  
    'TP-RP' => 0,
    'TP-SRI' => 0,
    'TP-MMS' => 0,
    'TP-MTI' => SMS_DELIVER,
    smsc => '',
    'TP-OA' => '',
    'TP-UD' => undef,
    'TP-DCS' => PDU_DCS_7BIT,
    'TP-PID' => 0x00
  };

  bless($self, $class);

  if (defined($pkt) and ($pkt ne '')) {

    ($self->{smsc}, $pkt) = $self->decodeAddress($pkt, SMS_IS_SCA);    

    my $pdutype = unpack('C', $pkt);
    $pkt = substr($pkt, 1);

    #print "PDU type : $pdutype\n";
    $self->{'TP-UDHI'} = ($pdutype >> 6) & 1;
    $self->{'TP-RP'} = ($pdutype >> 7) & 1;    
    $self->{'TP-SRI'} = ($pdutype >> 5) & 1;
    $self->{'TP-MMS'} = ($pdutype >> 2) & 1;    
    my $mti = $pdutype & 0x3;
    if ($mti ne SMS_DELIVER) {
      print "Invalid PDU type, this is not an SMS Deliver!\n";
      return;
    }

    # sender
    ($self->{'TP-OA'}, $pkt) = $self->decodeAddress($pkt);

    ($self->{'TP-PID'}, $self->{'TP-DCS'}) = unpack('CC', $pkt);
    $pkt = substr($pkt, 2);

    $self->{'TP-SCTS'} = 0;
    $pkt = substr($pkt, 7);  

    # message length is not used
    my $len = unpack('C', $pkt);
    $pkt = substr($pkt, 1);

    $self->{'TP-UD'} = SMS::PDU::UserData->decode($pkt, udhi => $self->{'TP-UDHI'}, dcs => $self->{'TP-DCS'}); 
  }

  return $self;
}


=item $s->encode

Encode an SMS Deliver PDU into a binary string.

=cut

sub encode
{
  my $self = shift;

  my $hdr;

  # SCA
  $hdr .= $self->encodeAddress($self->{smsc}, SMS_IS_SCA);

  # set UDHI
  $self->{'TP-UDHI'} = $self->{'TP-UD'}->hasUDHI;

  # PDU type
  my $pdutype = $self->{'TP-MTI'};  
  $pdutype|= ($self->{'TP-RP'} << 7);
  $pdutype|= ($self->{'TP-UDHI'} << 6);  
  $pdutype|= ($self->{'TP-SRI'} << 5);
  $pdutype|= ($self->{'TP-MMS'} << 2);
  $hdr .= pack('C', $pdutype);

  # encode destination
  $hdr .= $self->encodeAddress($self->{'TP-OA'});

  # protocol identifier
  $hdr .= pack('C', $self->{'TP-PID'});

  # data encoding scheme
  $hdr .= pack('C', $self->{'TP-DCS'});

  # SCTS
  $hdr .= pack('CCCCCCC', 0);

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
    $nbs->{'TP-OA'} = $msisdn;
    $nbs->{smsc} = $smsc;
    push @frames, $nbs;
  }  
  
  return (@frames > 1) ? @frames : shift @frames;
}


=item $s->getNumber

Return the originating phone number of the SMS Deliver PDU.

=cut

sub getNumber
{
  my $self = shift;
  return $self->{'TP-OA'};
}


1;

=back
