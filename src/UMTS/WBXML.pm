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

package UMTS::WBXML;

use strict;
use warnings;
use vars qw(@ISA @EXPORT);

use Carp ();
use File::Temp qw(tempfile);
use Exporter;
use WSP::Headers;

@ISA = qw(Exporter);
@EXPORT = qw(encode_wbxml decode_wbxml);


our $WBXML2XML="wbxml2xml";
our $XML2WBXML="xml2wbxml";

# Well-known public document IDs
# see http://www.wapforum.org/wina/wbxml-public-docid
our $WBXML_DOCIDS =
{
  'Unknown or missing public identifier' => 0x01,
  '-//WAPFORUM//DTD WML 1.0//EN'     => 0x02,
  '-//WAPFORUM//DTD WML 1.0//EN'     => 0x02,
  '-//WAPFORUM//DTD WTA 1.0//EN'     => 0x03,
  '-//WAPFORUM//DTD WML 1.1//EN'     => 0x04,
  '-//WAPFORUM//DTD SI 1.0//EN'      => 0x05,
  '-//WAPFORUM//DTD SL 1.0//EN'      => 0x06,
  '-//WAPFORUM//DTD CO 1.0//EN'      => 0x07,
  '-//WAPFORUM//DTD CHANNEL 1.1//EN' => 0x08,
  '-//WAPFORUM//DTD WML 1.2//EN'     => 0x09,
  '-//WAPFORUM//DTD WML 1.3//EN'     => 0x0A,
  '-//WAPFORUM//DTD PROV 1.0//EN'    => 0x0B,
  '-//WAPFORUM//DTD WTA-WML 1.2//EN' => 0x0C,
  '-//WAPFORUM//DTD EMN 1.0//EN'     => 0x0D,
  '-//OMA//DTD DRMREL 1.0//EN'       => 0x0E
};


sub decode
{
  my ($class, $wbxml, $lang) = @_;
  my $self = {};
  $self->{version} = $class->get_version($wbxml);
  $self->{publicid} = $class->get_publicid($wbxml);
  $self->{xml} = decode_wbxml($wbxml, 0, $lang);
  bless($self, $class);
}

sub encode
{
  my ($self, $xml) = @_;
  defined($xml) or $xml = $self->{xml};
  return encode_wbxml($xml, 1);
}

# help functions

sub run_coder
{
  my ($prog, $input, $opts) = @_;
  defined($opts) or $opts = ''; 
  my $output;

  my ($fh, $filename) = tempfile();
  my $pipeok = 1;
  open(CODER, "|$prog $opts -o $filename - &> /dev/null") || ($pipeok = 0);
  local $SIG{PIPE} = sub { $pipeok = 0 };
  $pipeok && print CODER $input;
  close(CODER) || ($pipeok = 0);
  if ($pipeok)
  {
    my @lines = <$fh>;
    $output = join('', @lines);
  } 
  close($fh);
  unlink($filename);
  return $output;
}


sub decode_wbxml
{
  my ($wbxml, $fatal, $lang) = @_;
  defined($fatal) or $fatal = 0;
  my $opts = (defined($lang) && $lang) ? "-l $lang" : '';
  
  my $xml = run_coder($WBXML2XML, $wbxml, $opts);
  if (!defined($xml) && $fatal) {
    Carp::croak("WBXML decoding failed : could not run '$WBXML2XML'");
  } 
  return $xml;
}


sub encode_wbxml
{
  my ($xml, $fatal) = @_;
  defined($fatal) or $fatal = 0;
  
  my $wbxml = run_coder($XML2WBXML, $xml);
  if (!defined($wbxml) && $fatal) {
    Carp::croak("WBXML encoding failed : could not run '$XML2WBXML'");
  } 
  return $wbxml;
}


sub guess_mime
{
  my $self = shift;
  my $wbxml = shift;
  
  # try to guess MIME type from document ID 
  my $mimetype;
  my $id = unpack('C', substr($wbxml, 1, 1));
  
  if ($id == 0x0b) {
    $mimetype = "application/vnd.wap.connectivity-wbxml";  
  } elsif ($id == 0x05) {
    $mimetype = "application/vnd.wap.sic";  
  } elsif ($id == 0x06) {
    $mimetype = "application/vnd.wap.slc";
  } elsif ($id == 0x07) {
    $mimetype = "application/vnd.wap.coc";
  } elsif ($id == 0x0E) {
    $mimetype = "application/vnd.oma.drm.rights+wbxml";
  } elsif ($id == 0x01) {
    # unknown MIME type, look for known markers
    my $first = unpack('C', substr($wbxml, 4, 1)); 
    if ($first == 0x45) {
      # we found a CHARACTERISTIC_LIST
      $mimetype = "application/x-wap-prov.browser-settings";
    } elsif ($first == 0x55) {
      # we found a SyncSettings
      $mimetype = "application/vnd.nokia.syncset+wbxml";    
    }
  }
  
  return $mimetype;
}

sub get_publicid
{
  my $self = shift;
  my $wbxml = shift;
  my $byte = unpack('C', substr($wbxml, 1, 1));
  if ($byte > 0)
  {
    my $id = WSP::Headers->unpack_uintvar(substr($wbxml, 1)); 
    foreach my $key (keys %{$WBXML_DOCIDS})
    {
      return $key if ($WBXML_DOCIDS->{$key} == $id);
    }
  } else {
    $byte = unpack('C', substr($wbxml, 2, 1));
    return "string index : $byte";
  }
}

sub get_version
{
  my $self = shift;
  my $wbxml = shift;
  my $v = unpack('C', $wbxml);
  my $major = 1 + (($v & 0xF0) >> 4);
  my $minor = ($v & 0x0F);
  return "$major.$minor";
}

1;

