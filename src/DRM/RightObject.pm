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

package DRM::RightObject;

use strict;
use warnings;

use Carp ();
use File::Temp qw(tempfile);
use XML::Simple;
use MIME::Base64 ();
use UMTS::WBXML;
use UMTS::Core qw(read_binary);


=head1 NAME

DRM::RightObject - Class encapsulating DRM Right Objects

=head1 SYNOPSIS

  use DRM::RightObject;
  $ro = DRM::SD->parse_xml($xml);
  $ro = DRM::SD->parse_wbxml($wbxml);
  $key = $ro->key_value;

=head1 DESCRIPTION

The C<DRM::RightObject> class allows you to encode or decode DRM
Right Objects. This is used by L<DRM::SD|DRM::SD> for content encryption
and decryption.

The following methods are available:

=over 5

=item DRM::RightObject->parse_xml($xml)

Construct a new DRM::RightObect from XML data.

=cut

sub parse_xml
{
  my ($class, $xml) = @_;
  my ($fh, $filename) = tempfile();
  print $fh $xml;
  close($fh);
  return $class->parse_xmlfile($filename);
}


=item DRM::RightObject->parse_xmlfile($file)

Construct a new DRM::RightObect from an XML file.

=cut

sub parse_xmlfile
{
  my ($class, $file) = @_;
  
  my $xsl = XML::Simple->new();
  my $doc = $xsl->XMLin($file);

  bless($doc, $class);
}


=item DRM::RightObject->parse_wbxml($wbxml)

Construct a new DRM::RightObect from a WBXML data.

This requires the 'wbxml2xml' tool to be present on your system.

=cut

sub parse_wbxml
{
  my ($class, $wbxml) = @_;
  my $xml = decode_wbxml($wbxml, 1);
  return $class->parse_xml($xml);
}


=item DRM::RightObject->parse_wbxmlfile($file)

Construct a new DRM::RightObect from a WBXML file.

This requires the 'wbxml2xml' tool to be present on your system.

=cut

sub parse_wbxmlfile
{
  my ($class, $file) = @_;
  my $wbxml = read_binary($file);
  return $class->parse_wbxml($wbxml);
}


=item $ro->key_value

Returns the Right Object's encrption key.

=cut

sub key_value
{
  my $self = shift;
  my $kv = $self->{'o-ex:agreement'}->{'o-ex:asset'}->{'ds:KeyInfo'}->{'ds:KeyValue'};
  return MIME::Base64::decode($kv);
}

=item $ro->uid

Returns the Right Object's <uid> element, the identifier of the DRM 
content this Right Object applies to.

=cut

sub uid
{
  my $self = shift;
  my $uid = $self->{'o-ex:agreement'}->{'o-ex:asset'}->{'o-ex:context'}->{'o-dd:uid'};
  $uid =~ s/^\s*//;
  $uid =~ s/\s*$//;
  return $uid;
}

1;

=back
