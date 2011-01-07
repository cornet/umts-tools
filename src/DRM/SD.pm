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

package DRM::SD;

use strict;
use warnings;
use vars qw(@ISA);

use Carp ();
use WSP::Headers;
use Crypt::Rijndael;

@ISA = qw(WSP::Headers);


=head1 NAME

DRM::SD - Class encapsulating DRM Separate Delivery files

=head1 SYNOPSIS

  use DRM::SD;
  $sd = DRM::SD->decode($content);

=head1 DESCRIPTION

The C<DRM::SD> class allows you to encrypt or decrypt DRM
Separate Delivery files. It relies on L<DRM::RightObject|DRM::RightObject>
for access to Right Objects.

The following methods are available:

=over 9

=item DRM::SD->decode( [$content] )

Construct a new DRM::SD and optionaly initialise its value from a
binary string.

=cut

sub decode
{
  my $class = shift;
  my $input = shift;

  my $self = 
  {
    'version'     => 1,
    'content-type' => '',
    'content-uri'  => '',
    'headers'     => '',
    'data'        => '',
  };

  bless($self,$class);

  if (defined($input) && ($input ne ''))
  {
    ($self->{version}, my $ctlen, my $culen) = unpack('CCC', $input);
    $input = substr($input, 3);
    $self->{'content-type'} = substr($input, 0, $ctlen);
    $input = substr($input, $ctlen);
    $self->{'content-uri'} = substr($input, 0, $culen);
    $input = substr($input, $culen);
    (my $hlen, $input) = $self->unpack_uintvar($input);
    (my $dlen, $input) = $self->unpack_uintvar($input);
    $self->{headers} = substr($input, 0, $hlen);
    $input = substr($input, $hlen);
    $self->{data} = substr($input, 0, $dlen);
  }

  return $self;
}


=item $sd->encode

Return the binary string representing a DRM::SD object.

=cut

sub encode
{
  my $self = shift;
  my $output =  '';

  Carp::croak("Content-Type of DRM SD file needs to be specified") 
    unless ($self->{'content-type'} ne '');

  $output .= pack('CCC', $self->{version}, length($self->{'content-type'}), length($self->{'content-uri'}));
  $output .= $self->{'content-type'};
  $output .= $self->{'content-uri'};

  $output .= $self->pack_uintvar(length($self->{'headers'}));
  $output .= $self->pack_uintvar(length($self->{'data'}));
  $output .= $self->{'headers'};
  $output .= $self->{'data'};

  return $output;
}


=item $sd->get_content($key)

Decrypt an SD file's content and return the clear data. The 128bit
key to use for decryption must be provided.

=cut

sub get_content
{
  my ($self, $key) = @_;
  
  # prepare cipher
  my $cipher = Crypt::Rijndael->new($key, Crypt::Rijndael::MODE_CBC);
  
  # get initialisation vector
  my $iv = substr($self->{data}, 0, 16);
  $cipher->set_iv($iv);
  
  # perform decryption
  my $cyphertext = substr($self->{data}, 16);
  my $clear = $cipher->decrypt($cyphertext);

  # remove padding
  my $last = substr($clear, -1, 1);
  my $plen = unpack('C', $last);
  my $padding = $last x $plen;
  Carp::croak("DRM SD file has incorrect padding, decryption probably failed")
    unless (substr($clear, -$plen, $plen) eq $padding);
  $clear = substr($clear, 0, -$plen);
  
  return $clear;
}


=item $sd->set_content($ro, $clear)

Set an SD file's data from the clear data. The 128bit key to use
for encryption must be provided.

=cut

sub set_content
{
  my ($self, $key, $clear) = @_;
 
  # prepare cipher
  my $cipher = Crypt::Rijndael->new($key, Crypt::Rijndael::MODE_CBC);

  # add padding
  my $blklen = 16;
  my $plen = $blklen - (length($clear) % $blklen);
  $clear .= (pack('C', $plen) x $plen);
 
  # set initialisation vector
  my $iv = '';
  for (my $i = 0; $i < 16; $i++)
  {
    $iv .= pack('C', int(rand(256)));
  }
  $cipher->set_iv($iv);
 
  # encrypt
  my $cyphertext = $cipher->encrypt($clear);

  $self->{data} = $iv . $cyphertext;
}


=item $oldvalue = $sd->content_type( [$newvalue] )

Get or set a DRM SD file's Content-Type.

=cut

sub content_type
{
  my ($self, $new) = @_;
  $self->_get_or_set('content-type', $new);
}


=item $oldvalue = $sd->content_uri( [$newvalue] )

Get or set a DRM SD file's Content-URI.

=cut

sub content_uri
{
  my ($self, $new) = @_;
  $self->_get_or_set('content-uri', $new);
}


=item $oldvalue = $sd->headers( [$newvalue] )

Get or set a DRM SD file's headers.

=cut

sub headers
{
  my ($self, $new) = @_;
  $self->_get_or_set('headers', $new);
}


=item $oldvalue = $sd->version( [$newvalue] )

Get or set a DRM SD file's Version.

=cut

sub version
{
  my ($self, $new) = @_;
  $self->_get_or_set('version', $new);
}


=item $sd->info

Return a string containing information about a DRM SD file.

=cut

sub info
{
  my $self = shift;
  my $out = '';
  $out .= "Version:\t".$self->version."\n";
  $out .= "Content-Type:\t".$self->content_type."\n";
  $out .= "Content-Uri:\t".$self->content_uri."\n";
  $out .= "--Headers--\n".$self->headers."\n----\n";
  return $out; 
}


sub _get_or_set
{
  my ($self, $field, $new) = @_;
  my $old = $self->{$field};
  $self->{$field} = $new if (defined($new));
  return $old;
}


1;

=back

