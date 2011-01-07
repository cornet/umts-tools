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
package UMTS::NetPacket::Pcap;

use strict;
use warnings;
use vars qw(@ISA @EXPORT @EXPORT_OK);

use Exporter;
use NetPacket::IP qw(IP_PROTO_UDP IP_PROTO_TCP);
use NetPacket::UDP;
use NetPacket::TCP;
use UMTS::NetPacket::Ethernet qw(ETH_TYPE_IP);
use SMS::PDU::UserData qw(:dcs);
use UMTS::NetPacket::Pframe;
use UMTS::NetPacket::SMPP;

@ISA = qw(Exporter);

# Default exports
@EXPORT = qw(ETH_TYPE_IP IP_PROTO_TCP IP_PROTO_UDP);

# Other items we are prepared to export if requested
@EXPORT_OK = qw(
  TCP_FLAG_CWR
  TCP_FLAG_ECN
  TCP_FLAG_URG
  TCP_FLAG_ACK
  TCP_FLAG_PUSH
  TCP_FLAG_RST
  TCP_FLAG_SYN
  TCP_FLAG_FIN
);

use constant TCP_FLAG_CWR   => 0x80;
use constant TCP_FLAG_ECN   => 0x40;
use constant TCP_FLAG_URG   => 0x20;
use constant TCP_FLAG_ACK   => 0x10;
use constant TCP_FLAG_PUSH  => 0x08;
use constant TCP_FLAG_RST   => 0x04;
use constant TCP_FLAG_SYN   => 0x02;
use constant TCP_FLAG_FIN   => 0x01;


sub decode
{
  my $class = shift;
  my ($pkt, $parent, @rest) = @_;
  
  my $self = {
    'data' => undef,
    'major' => 0x0200,
    'minor' => 0x0400,
  };
  
  if (defined($pkt) and $pkt ne '')
  {
    my $magic = unpack('L', $pkt);
    if ($magic ne 0xA1B2C3D4) {
      print "Invalid magic : $magic\n";
      #return;
    }
    $pkt = substr($pkt, 4);
    
    ($self->{major}, $self->{minor}) = unpack('nn', $pkt);
    $pkt = substr($pkt, 4);
       
    my ($a, $b, $c, $d, $e, $f) = unpack('LLnnnn', $pkt);    
    $pkt = substr($pkt, 16);
  
    $self->{data} = $pkt;  
  }
    
  bless($self, $class);
}

sub encode
{
  my $self = shift;
  
  # magic
  my $hdr = pack('L', 0xA1B2C3D4);

  # major and minor
  $hdr .= pack('n', $self->{major});
  $hdr .= pack('n', $self->{minor});
 
  $hdr .= pack('L', 0x0000);
  $hdr .= pack('L', 0x0000);

  $hdr .= pack('n', 0xFFFF);
  $hdr .= pack('n', 0x0000);
  
  $hdr .= pack('n', 0x0100);
  $hdr .= pack('n', 0x0000);

  return $hdr . (defined($self->{data}) ? $self->{data} : '');
}


sub encapsulateEthernet
{
  my ($class, $type, $pkt) = @_;
  
  # make ethernet message
  my $eth = UMTS::NetPacket::Ethernet->decode;  
  $eth->{type} = $type;
  $eth->{data} = $pkt->encode;
  $eth->{src_mac} = '010101010101';
  $eth->{dst_mac} = '020202020202';   
 
  return $eth;
}


sub encapsulateIP
{
  my ($class, $proto, $pkt) = @_;
  
  # make IP message
  my $ip = NetPacket::IP->decode;
  $ip->{ver} = 4;
  $ip->{hlen} = 5;
  $ip->{tos} = 0;
  $ip->{id} = 0x1234;
  $ip->{ttl} = 0x5a;
  $ip->{src_ip} = '1.1.1.1';
  $ip->{dest_ip} = '2.2.2.2';

    
  # assemhle
  # set protocol
  $ip->{proto} = $proto;
  $ip->{data} = $pkt->encode($ip);
  
  return $ip;
}


sub encapsulatePframe
{
  my ($class, $pkt) = @_;
  
  my $pcap = UMTS::NetPacket::Pframe->decode;
  $pcap->{data} = $pkt->encode;
  
  return $pcap;
}


sub encapsulateUDP
{
  my ($class, $pkt) = @_;
  
  my $udp = NetPacket::UDP->decode;
  $udp->{data} = $pkt->encode;
  defined($pkt->{src_port}) and $udp->{src_port} = $pkt->{src_port};
  defined($pkt->{dest_port}) and $udp->{dest_port} = $pkt->{dest_port};  
  
  return $udp;
}


sub encapsulateTCP
{
  my ($class, $pkt) = @_;
  
  my $tcp = NetPacket::TCP->decode;
  $tcp->{hlen} = 5;
  $tcp->{data} = $pkt->encode;
  defined($pkt->{src_port}) and $tcp->{src_port} = $pkt->{src_port};
  defined($pkt->{dest_port}) and $tcp->{dest_port} = $pkt->{dest_port};  
  $tcp->{flags} = TCP_FLAG_ACK | TCP_FLAG_PUSH;
  $tcp->{winsize} = 64081;
  
  return $tcp;
}


sub addIP
{
  my ($self, $pkt) = @_;
  
  my $eth = $self->encapsulateEthernet(ETH_TYPE_IP, $pkt);
  my $pframe = $self->encapsulatePframe($eth);
  
  $self->{data} .= $pframe->encode;
}


sub addSMS_UD
{
  my ($self, $msisdn, @uds) = @_;
  
  foreach my $ud (@uds)
  {
    # make SMPP message
    my $smpp = UMTS::NetPacket::SMPP->decode;
    $smpp->{dcs} = PDU_DCS_8BITM;      
    $smpp->{ud} = $ud;
    $smpp->{msisdn} = $msisdn;
    $smpp->{src_port} = $ud->{src_port};
    $smpp->{dest_port} = $ud->{dest_port};
    
    my $tcp = $self->encapsulateTCP($smpp);
    my $ip = $self->encapsulateIP(IP_PROTO_TCP, $tcp);
    $self->addIP($ip);  
  }
}


sub addWSP
{
  my ($self, $wsp, $dest_port, $src_port) = @_;
  
  my $udp = $self->encapsulateUDP($wsp);
  $udp->{dest_port} = $dest_port;
  $udp->{src_port} = $src_port;  
  my $ip = $self->encapsulateIP(IP_PROTO_UDP, $udp);
  
  $self->addIP($ip);
}

   
# write dump to file
sub dump
{
  my ($self, $pfile) = @_;
  
  if (open(FILE, "> $pfile"))
  {
    print FILE $self->encode;
    close(FILE); 
  } else {
    print("Pcap::dump : Could not open '$pfile' for writing !\n");
  }
}

1;

