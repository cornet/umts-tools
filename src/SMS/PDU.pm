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
package SMS::PDU;

use strict;
use warnings;

BEGIN {
  use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
  
  use Exporter;
  
  use constant SMS_DELIVER   => 0x00;  # SMS Deliver
  use constant SMS_SUBMIT    => 0x01;  # SMS Submit
  
  use constant SMS_TOA_DEFAULT   => 0x81;
  use constant SMS_TOA_INTERNAT  => 0x91;
  
  use constant SMS_NOT_SCA       => 0;
  use constant SMS_IS_SCA        => 1;
  
  @ISA = qw(Exporter);
  @EXPORT = qw(SMS_DELIVER SMS_SUBMIT);
  @EXPORT_OK = qw(SMS_IS_SCA SMS_NOT_SCA SMS_TOA_DEFAULT SMS_TOA_INTERNAT);
  %EXPORT_TAGS = ( 
  types => [qw(SMS_DELIVER SMS_SUBMIT)],
  sca => [qw(SMS_IS_SCA SMS_NOT_SCA)],
  );
}

use SMS::PDU::Submit;
use SMS::PDU::Deliver;


=head1 NAME

SMS::PDU - Class encapsulating SMS PDUs

=head1 SYNOPSIS

  use SMS::PDU;
  $s = SMS::PDU->decode($binstr);

=head1 DESCRIPTION

The C<SMS::PDU> class allows you to decode
SMS Protocol Data Units (PDU). For encoding, you should refer to
subclasses such as L<SMS::PDU::Deliver|SMS::PDU::Deliver> or 
L<SMS::PDU::Submit|SMS::PDU::Submit>.

The following methods are available:

=over 1

=item SMS::PDU->decode

Decode an SMS PDU from a binary string.

=cut

sub decode
{
  my $class = shift;
  my($pkt, $parent, @rest) = @_;
  
  if (defined($pkt) and ($pkt ne '')) {
    my ($smsc, $pkt2) = $class->decodeAddress($pkt, SMS_IS_SCA);    
    my $pdutype = unpack('C', $pkt2);
    my $mti = $pdutype & 0x3;
    if ($mti eq SMS_DELIVER) {
      return SMS::PDU::Deliver->decode(@_);      
    } elsif ($mti eq SMS_SUBMIT) {
      return SMS::PDU::Submit->decode(@_);            
    } else {
      print "SMS::PDU::decode : unknown TP-MTI value '$mti'\n";
      return:
    }
  } else {
    print "SMS::PDU::decode : no packet was specified\n";    
    return;
  }
}


sub decodeAddress
{
  my ($self, $in, $is_sca) = @_;
  
  defined($is_sca) or
    $is_sca = SMS_NOT_SCA;          
  
  my $len = unpack('C', $in); 
  $in = substr($in, 1);

  my $bytelen;
    
  # if this is the SCA 
  if ($is_sca) {
    # if length is 0, stop
    $len or
      return ('', $in);

    $bytelen = $len - 1;
  } else {
    $bytelen = ($len + ($len % 2)) / 2;
  }
  #print "bytelen : $bytelen\n";  
  
  my $type = unpack('C', $in);
  $in = substr($in, 1);
  #print "address type : $type, len : $len, len2 : $len2\n";
  
  my $val = substr($in, 0, $bytelen);
  $in = substr($in, $bytelen);

  # Decode number, remove padding
  my $number = unpack('h*', $val);
  $number =~ s/F$//i;

  ($type eq SMS_TOA_INTERNAT) and
    $number = '+' . $number;

  return ($number, $in);  
}


sub getTPLength
{
  my ($self, $pkt) = @_;
  my $smsc;
  ($smsc, $pkt) = $self->decodeAddress($pkt, SMS_IS_SCA);
  return length($pkt);    
}    


sub encodeAddress {
  my ($self, $number, $is_sca) = @_;
  defined($is_sca) or
    $is_sca = SMS_NOT_SCA;    

  if ($is_sca and (!defined($number) or $number eq '')) {
    return pack('C', 0x00);
  }
   
  # Find type of phonenumber
  # no + => unknown number, + => international number
  my $type = (substr($number,0,1) eq '+') ? SMS_TOA_INTERNAT : SMS_TOA_DEFAULT;

  # Delete any non digits => + etc...
  $number =~ s/\D//g;

  # Encode number, padding odd length numbers
  my $val = pack('h*', (length($number) % 2) ? $number . "F" : $number);

  # Length is encoded differently for source and destination
  my $len = $is_sca ? length($val) + 1 : length($number);

  ($is_sca) and
    $len = length($val) + 1;

  my $out = pack('C', $len) . pack('C', $type) . $val;  
  return $out;
}

sub submit
{
  my $class = shift;
  return SMS::PDU::Submit->decode(@_);
}

1;

=back
