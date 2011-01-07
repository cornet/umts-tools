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
package SMS::PDU::UserData;

use strict;
use warnings;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

use Carp ();
use Exporter;
use Encode ();

@ISA = qw(Exporter);

# Default exports
@EXPORT = qw();

# Other items we are prepared to export if requested
@EXPORT_OK = qw(
  PDU_CODING_7BIT
  PDU_CODING_8BIT
  PDU_CODING_UCS2
  PDU_DCS_UCS2 
  PDU_DCS_7BIT 
  PDU_DCS_7BITI 
  PDU_DCS_8BIT
  PDU_DCS_8BITI
  PDU_DCS_8BITM
);

%EXPORT_TAGS = (
  codings => [qw(PDU_CODING_7BIT PDU_CODING_8BIT PDU_CODING_UCS2)],
  dcs => [qw(PDU_DCS_UCS2 PDU_DCS_7BIT PDU_DCS_7BITI  PDU_DCS_8BIT PDU_DCS_8BIT PDU_DCS_8BITM)]
);

use constant PDU_CODING_7BIT => 0;
use constant PDU_CODING_8BIT => 1;
use constant PDU_CODING_UCS2 => 2;

use constant PDU_DCS_UCS2  => 0x08;

use constant PDU_DCS_7BIT  => 0x00;

use constant PDU_DCS_7BITI => 0xF0; # 7bit, class 0

use constant PDU_DCS_8BITI => 0xF4; # 8bit, class 0
use constant PDU_DCS_8BITM => 0xF5; # 8bit, class 1 (ME-specific)
use constant PDU_DCS_8BIT  => 0xF6; # 8bit, class 2 (SIM-specific)

use constant PDU_TAG_FRAG          => 0x00;
use constant PDU_TAG_SPECIAL       => 0x01;
use constant PDU_TAG_PORTS_8BIT    => 0x04;
use constant PDU_TAG_PORTS_16BIT   => 0x05;
use constant PDU_TAG_SMSC_CONTROL  => 0x06;
use constant PDU_TAG_UDH_SOURCE    => 0x07;

use constant USE_FRAG  => 0x00;
use constant SKIP_FRAG => 0x01;

use constant UD_MAX_OCTETS => 140;
use constant UD_FRAG_OCTETS => 5;

my @UD_FIELDS_ALL  = qw(src_port dest_port data dcs drn fmax fsn);

=head1 NAME

SMS::PDU::UserData - Class encapsulating SMS PDU UserData fields

=head1 SYNOPSIS

  use SMS::PDU::UserData;
  $ud = SMS::PDU::UserData->decode;
  $binstr = $ud->encode;

=head1 DESCRIPTION

The C<SMS::PDU::UserData> class allows you to encode or decode
SMS Protocol Data Units (PDU) UserData fields. This is used by
L<SMS::PDU::Deliver|SMS::PDU::Deliver> and
L<SMS::PDU::Submit|SMS::PDU::Submit> for instance.

The following methods are available:

=over 8

=item SMS::PDU::UserData->decode

Decode an octet string into an SMS TP-UD

=cut

sub decode
{
  my $class = shift;
  my($pkt, %params) = @_;

  my $self = {
    src_port => undef,
    dest_port => undef,
    data => '',
    dcs => defined($params{dcs}) ? $params{dcs} : PDU_DCS_7BIT,
    fmax => 1,
    fsn => 0
  };

  bless($self, $class); 

  if (defined($pkt) and $pkt ne '') {

    my $udh_len;
    if (defined($params{udhi}) and $params{udhi}) {
      $udh_len = $self->decode_udh($pkt);
      $pkt = substr($pkt, $udh_len);
    } else {
      $udh_len = 0;
    }

    my $coding = $self->coding;
    if ($coding == PDU_CODING_7BIT)
    {
      my $nbits = $udh_len * 8;
      my $fillbits = ((int($nbits / 7) + 1) * 7 - $nbits) % 7;

      $self->{data} = Encode::decode('gsm0338', unpack_7bit($pkt, $fillbits));
    } elsif ($coding == PDU_CODING_UCS2) {
      $self->{data} = Encode::decode('UCS-2BE', $pkt);
    } else {
      $self->{data} = $pkt;
    }

  }

  return $self;
}


=item $ud->decode_udh

Decode an SMS TP-UD's User Data Header from an octet string

=cut

sub decode_udh
{
  my ($self, $pkt) = @_;

  my $udh_len = unpack('C', $pkt);
  $pkt = substr($pkt, 1);

  #print("User Data Header len : $udh_len\n");
  my $done = 0;
  while ($done < $udh_len) {

    my ($id, $len) = unpack('CC', $pkt);
    $pkt = substr($pkt, 2);
    $done += 2;

    #print "tag len : $len\n";
    if ($id eq PDU_TAG_PORTS_8BIT) {
      ($self->{dest_port}, $self->{src_port}) = unpack('CC', $pkt);
    } elsif ($id eq PDU_TAG_PORTS_16BIT) {
      ($self->{dest_port}, $self->{src_port}) = unpack('nn', $pkt);
    } elsif ($id eq PDU_TAG_FRAG) {
      ($self->{drn}, $self->{fmax}, $self->{fsn}) = unpack('CCC', $pkt);   
    } else {
      print "PDU header contains unknown tag : $id\n";
    }
    $pkt = substr($pkt, $len);
    $done += $len;
  }
  # add 1 to take into account the UDH Length byte
  $udh_len++;

  return $udh_len;
}



=item $ud->encode

Encode an SMS TP-UD into an octet string

=cut  

sub encode
{
  my $self = shift;

  # encode UDH
  my $udh = $self->encode_udh;

  # encode the message data, add it to the UDH
  my ($data,$msglen);
  my $coding = $self->coding;
  if ($coding == PDU_CODING_7BIT)
  {
    # calculate fill bits to align message data on a septet boundary
    my $nbits = length($udh) * 8;
    my $fillbits = ((int($nbits / 7) + 1) * 7 - $nbits) % 7;
    #print "encode() UDH length : ".length($udh).", fill bits : $fillbits, data length :".length($self->{data})."\n";
    $data = $udh . pack_7bit(Encode::encode('gsm0338',$self->{data}), $fillbits);
    $msglen = int(($nbits+$fillbits)/7) + length($self->{data});
    #print "encode() msglen : $msglen\n";

  } else {
    if ($coding == PDU_CODING_UCS2) {
      $data = $udh . Encode::encode('UCS-2BE', $self->{data});
    } else {
      $data.= $udh . $self->{data};
    }
    $msglen = length($data);
  }

  return ($data, $msglen) if wantarray;
  return $data;
}


=item $ud->encode_udh

Encode an SMS TP-UD's User Data Header into an octet string

=cut  

sub encode_udh
{
  my ($self, $use_frag) = @_;
  $use_frag = USE_FRAG unless defined($use_frag);

  my $hdr = '';

  # port addressing
  if (defined($self->{dest_port}) and $self->{dest_port} > 0) {
    defined($self->{src_port}) or $self->{src_port} = $self->{dest_port};

    if (($self->{dest_port} < 256) && ($self->{src_port} < 256))
    {
      # 8bit port addressing
      $hdr .= pack('C', PDU_TAG_PORTS_8BIT);
      # length  
      $hdr .= pack('C', 0x02);
      $hdr .= pack('C', $self->{dest_port});
      $hdr .= pack('C', $self->{src_port});
    } else {
      # 16bit port addressing
      $hdr .= pack('C', PDU_TAG_PORTS_16BIT);
      # length  
      $hdr .= pack('C', 0x04);
      $hdr .= pack('n', $self->{dest_port});  
      $hdr .= pack('n', $self->{src_port});
    }
  }

  # fragmentation info
  if (($use_frag == USE_FRAG) && defined($self->{fmax}) and $self->{fmax} > 1) {
    $hdr .= pack('C', PDU_TAG_FRAG);               # Fragmentation information element
    $hdr .= pack('C', 0x03);                       # Length of Info el
    $hdr .= pack('C', $self->{drn});               # fragment id
    $hdr .= pack('C', $self->{fmax});              # max amount of frags
    $hdr .= pack('C', $self->{fsn});               # sequence number fragment
  }
 
  if (length($hdr))
  {
    return pack('C', length($hdr)) . $hdr;
  } else {
    return '';
  }
}


=item $ud->hasUDHI

Returns true if an SMS TP-UD's contains a User Data Header

=cut

sub hasUDHI
{
  my $self = shift;
  my $udh = $self->encode_udh;
  return (length($udh) > 0);
}


=item $ud->coding

Returns the type of coding of an SMS TP-UD (7bit, 8bit, UCS2)

=cut

sub coding
{
  my $self = shift;
  my $is;
 
  if (!($self->{dcs} & 0xC0)) {
    # General Data Coding indication
    my $alph = ($self->{dcs} & 0x0C) >> 2;
    if ($alph == 0) {
      $is = PDU_CODING_7BIT;
    } elsif ($alph == 1) {
      $is = PDU_CODING_8BIT;
    } elsif ($alph == 2) {
      $is = PDU_CODING_UCS2;
    } else {
      Carp::croak("General Data Coding : unsupported alphabet");
    }
  
  } elsif (($self->{dcs} & 0xF0) == 0xF0) {
    # Data coding/message class
    my $alph = ($self->{dcs} & 0x04) >> 2;
    $is = $alph ? PDU_CODING_8BIT : PDU_CODING_7BIT;
  
  } else {
    # other data coding schemes
    Carp::croak("Unhandled Data Coding Scheme : $self->{dcs}");
  }
  
  my $alph = ($is == PDU_CODING_UCS2) ? "UCS2" : (($is == PDU_CODING_8BIT) ? "8BIT" : "7BIT");
  #printf("DCS: %.2X, alphabet: %s\n", $self->{dcs}, $alph);
  
  return $is;
}


=item $ud->clone

Return a copy of a UserData

=cut

sub clone
{
  my ($self, $use_frag) = @_;
  $use_frag = USE_FRAG unless defined($use_frag);

  my $clone = SMS::PDU::UserData->decode;
  foreach my $field(@UD_FIELDS_ALL)
  {
    my $skip = !defined($self->{$field});

    if (!$skip && ($use_frag == SKIP_FRAG))
    {
      $skip = ($field =~ /^(drn|fsn|fmax)$/);
#      print "field : $field, skipping : $skip\n";
    }

    if (!$skip) {
      $clone->{$field} = $self->{$field};
    }
  }

  return $clone;
}



=item $ud->split

Split a TP-UD into several TP-UD if the data does not fit in a single one.

=cut

sub split
{
  my $self = shift;
  my @uds;

  # encode UDH without fragmentation info
  my $udh = $self->encode_udh(SKIP_FRAG);
  my $max_part_len = $self->max_part_length(length($udh));
  Carp::croak("User Data Header is too long (without fragmentation info)!") unless ($max_part_len > 0);
  #print "split() max single part length : $max_part_len\n"; 

  # try fitting into a single UserData
  if (length($self->{data}) <= $max_part_len)
  {
    # we need a single UserData
    my $ud = $self->clone(SKIP_FRAG);
    push @uds, $ud;

  } else {

    # we need several UserData

    # determine maximum part length with fragmentation
    my $udh_len = length($udh) ? length($udh) + UD_FRAG_OCTETS : 1 + UD_FRAG_OCTETS;
    #print "split() dcs : $self->{dcs}, udh_len : $udh_len\n";
    $max_part_len = $self->max_part_length($udh_len);
    #print "split() max part length : $max_part_len\n";

    Carp::croak("User Data Header is too long (with fragmentation info)!") unless ($max_part_len > 0);

    my $data = $self->{data};
    #print "split() data length : ".length($data)."\n";
    my $nfrags = int((length($data)+ ($max_part_len - 1))/$max_part_len);
    my $drn = int(rand(256));

    for (my $i = 1; $i <= $nfrags; $i++) {
      my $chunksize = (length($data) > $max_part_len) ? $max_part_len : length($data);
      #print "processing fragment $i of $nfrags ($chunksize chars)..\n";

      my $ud = $self->clone(SKIP_FRAG);
      $ud->{drn} = $drn;
      $ud->{fmax} = $nfrags;
      $ud->{fsn} = $i;
      $ud->{data} = substr($data, 0, $chunksize);
      $data = substr($data, $chunksize);
      push @uds, $ud;
    }
  }
  return @uds;

}


sub max_part_length
{
  my ($self, $udh_len) = @_;
  my $max_part_len;
  my $coding = $self->coding;
  if ($coding == PDU_CODING_7BIT)
  {
    $max_part_len = int(UD_MAX_OCTETS * 8 / 7) - int(($udh_len * 8 + 6) / 7);
  } elsif ($coding == PDU_CODING_UCS2) {
    $max_part_len = int((UD_MAX_OCTETS - $udh_len) / 2);
  } else {
    $max_part_len = UD_MAX_OCTETS - $udh_len;
  }
  return $max_part_len;
}


sub pack_7bit
{
  my ($s, $fillbits) = @_;
  $fillbits = 0 unless defined($fillbits);

  $s = unpack('b*', $s);
  
  # zap the high order (8th) bits
  $s =~ s/(.{7})./$1/g;

  # add fill bits
  $s = ("0"x$fillbits) . $s;
  
  return pack('b*', $s);
}


sub unpack_7bit {
  my ($s, $fillbits) = @_;
  $fillbits = 0 unless defined($fillbits);
  
  $s = unpack('b*', $s);
 
  # remove fill bits
  $s = substr($s, $fillbits);

  # we chop $s to make sure its length is a multiple of 7
  my $r = length($s) % 7;
  $s = substr($s, 0, -$r) if $r;

  # Stuff in high order (8th) bits
  $s =~ s/(.{7})/${1}0/g;

  return pack('b*', $s);
}

1;

=cut
