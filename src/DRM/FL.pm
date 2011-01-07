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

package DRM::FL;

use strict;
use warnings;

use Carp ();

use constant NL => "\r\n";


=head1 NAME

DRM::FL - Class encapsulating DRM Forward Lock files

=head1 SYNOPSIS

  use DRM::FL;
  $fl = DRM::FL->decode($content);

=head1 DESCRIPTION

The C<DRM::FL> class allows you to encode or decode DRM
Forward Lock files.

The following methods are available:

=over 8

=item DRM::FL->decode( [$content] )

Construct a new DRM::FL and optionaly initialise its value from a
binary string.

=cut

sub decode
{
  my $class = shift;
  my $input = shift;

  my $self = 
  {
    'boundary' => '',
    'content-type' => '',
    'content-transfer-encoding'  => '',
    'data' => '',
  };

  bless($self,$class);

  if (defined($input) && ($input ne ''))
  {
    # split headers from the rest
    my $pos = index($input, NL . NL);
    Carp::croak("Could not find end of DRM FL headers")
      unless ($pos > 0);
    my $hdr = substr($input, 0, $pos);
    my $rest = substr($input, $pos + 4);

    # process headers
    my @bits = split(NL, $hdr);
    $self->{'boundary'} = substr(shift @bits, 2);
    foreach my $bit (@bits)
    {
      if ($bit =~ /^Content-Type:\s*(.*)$/i)
      {
        $self->{'content-type'} = $1;
      } elsif ($bit =~ /^Content-Transfer-Encoding:\s*(.*)$/i) {
        $self->{'content-transfer-encoding'} = $1;
      }
    }

    # remove final boundary
    $pos = rindex($rest, NL . "--" . $self->{boundary} . "--" . NL);
    Carp::croak("Could not find final boundary of DRM FL file")
      unless ($pos >= 0);

    # process data
    my $data = substr($rest, 0, $pos);
    my $encoding = $self->{'content-transfer-encoding'};
    
    if ($encoding eq 'binary') {
      $self->{'data'} = $data;
    } else {
      Carp::croak("Content-Transfer-Encoding '$encoding' is not handled");
    }
  } else {
    # default values
    $self->{'boundary'} = 'foobarboundary';
    $self->{'content-transfer-encoding'} = 'binary';
  }

  return $self;
}


=item $fl->encode

Return the binary string representing a DRM::FL object.

=cut

sub encode
{
  my $self = shift;
  my $output =  '';

  Carp::croak("Content-Type of DRM FL file needs to be specified") 
    unless ($self->{'content-type'} ne '');

  $output .= "--" . $self->{boundary} . NL;
  $output .= "Content-Type: ". $self->{'content-type'}. NL;
  $output .= "Content-Transfer-Encoding: ". $self->{'content-transfer-encoding'} . NL;
  $output .=  NL;

  # process data
  my $encoding = $self->{'content-transfer-encoding'};
  if ($encoding eq 'binary') {
    $output .= $self->{data};
  } else {
    Carp::croak("Content-Transfer-Encoding '$encoding' is not handled");
  }
  $output .= NL . "--" . $self->{boundary} . "--" . NL;

  return $output;
}


=item $fl->get_content

Return a DRM FL file's clear content.

=cut

sub get_content
{
  my $self = shift;
  return $self->{data};
}


=item $fl->set_content($clear)

Set a DRM FL file's data from the clear data.

=cut

sub set_content
{
  my ($self, $clear) = @_;
  $self->{data} = $clear;
}


=item $oldvalue = $fl->boundary( [$newvalue] )

Get or set a DRM FL file's boundary.

=cut

sub boundary
{
  my ($self, $new) = @_;
  $self->_get_or_set('boundary', $new);
}


=item $oldvalue = $fl->content_type( [$newvalue] )

Get or set a DRM FL file's Content-Type.

=cut

sub content_type
{
  my ($self, $new) = @_;
  $self->_get_or_set('content-type', $new);
}


=item $oldvalue = $fl->content_transfer_encoding( [$newvalue] )

Get or set a DRM FL file's Content-Transfer-Encoding.

=cut

sub content_transfer_encoding
{
  my ($self, $new) = @_;
  $self->_get_or_set('content-transfer-encoding', $new);
}


=item $fl->info

Return a string containing information about a DRM SD file.

=cut

sub info
{
  my $self = shift;
  my $out = '';
  $out .= "Boundary:\t".$self->boundary."\n";
  $out .= "Content-Type:\t".$self->content_type."\n";
  $out .= "Content-Transfer-Encoding:\t".$self->content_transfer_encoding."\n";
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

