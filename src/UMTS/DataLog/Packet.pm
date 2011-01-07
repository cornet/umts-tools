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

package UMTS::DataLog::Packet;

use strict;
use warnings;

use vars qw(@ISA @EXPORT);

use Exporter;
use SMS::SM_RP;
use SMS::PDU;
use WSP::PDU qw(:types :modes);
use UMTS::L3;
use UMTS::L3::GSM;
use UMTS::L3::SMC;
use UMTS::WBXML;

@ISA = qw(Exporter);
@EXPORT = qw(N_TO_MS MS_TO_N);

use constant N_TO_MS => 0;
use constant MS_TO_N => 1;

use constant CONTENT_BINARY => 0;
use constant CONTENT_TEXT   => 1;
use constant CONTENT_WBXML  => 2;

my @sms_frags;

=head1 NAME

UMTS::DataLog::Packet - A class encapsulating data log packets

=head1 SYNOPSIS

  my $pkt = UMTS::DataLog::Packet->new(
    'dir'   => N_TO_MS,
    'level' => 1,
    'stamp' => 12345,
    'data'  => "foo"
  );

=head1 DESCRIPTION

The C<UMTS::DataLog::Packet> class encapsulates packets captured
from a terminal's data log.

=cut

sub new
{
  my $class = shift;
  my %args = @_;
  bless(\%args, $class);
}


sub lprint
{
  my ($dir, $level, $format, @data) = @_;
  print( (($dir == MS_TO_N) ? '<= ' : '=> ' ) .("  " x $level) . sprintf($format, @data) . "\n");
}


sub print_title
{
  my ($p, $title, $dump) = @_;
  my $dfile;
  if ($dump) {
    $dfile = $p->dump($title);
    $title .= " (dumped to $dfile)";
  }
  lprint($p->{dir}, $p->{level}, $title);
}


sub print_field
{
  my ($p, $fname, $fval) = @_;
  lprint($p->{dir}, $p->{level} + 1, "$fname: $fval");
}

sub print_mime_field
{
  my ($p, $fname, $ftype, $fval) = @_;

  my $cat = $p->mime_category($ftype);
  if ($cat == CONTENT_TEXT) {
    $p->print_field($fname, $fval);
  } elsif ($cat == CONTENT_WBXML) {
    my $lang;
    if ($ftype =~ /^application\/x-wap-prov\.browser-settings/)
    {
      $lang = "OTA"; 
    }
    $p->child($fval)->process_WBXML($lang);
  } else {
    $p->print_field($fname, "<binary>");
  }
}

sub child
{
  my ($p, $data) = @_;

  my $c = ref($p);
  return $c->new(
    dir => $p->{dir},
    stamp => $p->{stamp},
    level => $p->{level}+1,
    data => $data,
    tag => $p->{tag},
  );
}

sub dump
{
  my ($p, $pname) = @_;
  $pname = $p->{tag} . "_" . $pname if ($p->{tag});
  my $file = sprintf("%.10i_%s.dump", $p->{stamp}, $pname);
  open(DFP, ">$file");
  binmode(DFP);
  syswrite(DFP, $p->{data}, length($p->{data}));
  close(DFP);
  return $file;
}


sub process_L3
{
  my $p = shift;
  my $pd = unpack("C", $p->{data}) & 0x0F;
  if ($pd == L3_PD_SMC) {
    $p->process_L3_SMC;
  } elsif ($pd == L3_PD_GSM) {
    $p->process_L3_GSM;
  } else {
    my $msg = UMTS::L3->decode($p->{data});
    $p->process_L3_header($msg);
    #$p->print_title(sprintf("L3 protocol %i", $pd));
  }
}


sub process_L3_header
{
  my ($p, $msg) = @_;
  $p->print_title($msg->msgProtocol);
  $p->print_field("Type", $msg->msgType);
}


sub process_L3_GSM
{
  my $p = shift;
  my $msg = UMTS::L3::GSM->decode($p->{data});
  $p->process_L3_header($msg);
  $p->print_field("APN", $msg->{APN}) if defined($msg->{APN});
}


sub process_L3_SMC
{
  my $p = shift;
  my $msg = UMTS::L3::SMC->decode($p->{data});
  $p->process_L3_header($msg);
  if ($msg->{'CP-UD'}) {
    $p->child($msg->{'CP-UD'})->process_SM_RP;
  }
}


sub process_SM_RP
{
  my $p = shift;
  $p->print_title("SM-RP");

  my $smsrp = SMS::SM_RP->decode($p->{data});
  $p->print_field("Type", $smsrp->msgType);
  if ($smsrp->{'RP-UD'}) {
    $p->child($smsrp->{'RP-UD'})->process_SM_TP;
  }
}


sub process_SM_TP
{
  my $p = shift;
  $p->print_title("SM-TP", 1);
  
  my $sms = SMS::PDU->decode("\x00" . $p->{data});
  $p->disp_SM_TP($sms);

  # handle SMS reassembly
  if (defined($sms->{'TP-UD'}->{fmax}) && ($sms->{'TP-UD'}->{fmax} > 1))
  {
    my %frags;
    push @sms_frags, $sms;
    my @sms_rest;
    foreach my $csms (@sms_frags)
    {
      if (($csms->{'TP-UD'}->{fmax} == $sms->{'TP-UD'}->{fmax}) &&
          ($csms->{'TP-UD'}->{drn} == $sms->{'TP-UD'}->{drn}))
      {
        #print "Found fragment : ".$csms->{'TP-UD'}->{fsn}."\n";
        $frags{$csms->{'TP-UD'}->{fsn}} = $csms;
      } else {
        push @sms_rest, $csms;
      }
    }
    my $complete = 1;
    my $data_buff = "";
    for (my $i = 1; $i <= $sms->{'TP-UD'}->{fmax}; $i++)
    {
      if (defined($frags{$i})) {
        $data_buff .= $frags{$i}->{'TP-UD'}->{data};
      } else {
        $complete = 0;
      }
    }
    if ($complete)
    {
      $sms->{'TP-UD'}->{data} = $data_buff;
      undef $sms->{'TP-UD'}->{drn};
      undef $sms->{'TP-UD'}->{fmax};
      undef $sms->{'TP-UD'}->{fsn};
      $p->{tag} = "reassembled";
      $p->print_title("SM-TP (reassembled)", 0);
      $p->disp_SM_TP($sms);
      @sms_frags = @sms_rest;
    }
  }
}

sub disp_SM_TP
{
  my ($p, $sms) = @_;
  if ($sms->{'TP-OA'}) {
    $p->print_field("From", $sms->{'TP-OA'});
  } else {
    $p->print_field("To", $sms->{'TP-DA'});
  }
  my $ud = $sms->{'TP-UD'};
  my $printdata = 1;
  my $isfrag = 0;
  if (defined($ud->{fmax}) && ($ud->{fmax} > 1)) {
    $p->print_field("Fragment", $ud->{fsn} . " / ". $ud->{fmax});
    $p->print_field("Frag DRN", $ud->{drn});
    $isfrag = 1;
    $printdata = 0;
  }
  if ($ud->{src_port}) {
    $p->print_field("SrcPort", $ud->{src_port});
    $p->print_field("DstPort", $ud->{dest_port});
    my ($sport, $dport) = ($ud->{src_port}, $ud->{dest_port});
    if (!$isfrag && ( ($sport == 9200) || ($dport == 2948)|| (($sport == 49154)&&($dport == 49999)) ) ) 
    {
      $p->child($ud->{data})->process_WSP_CL;
      $printdata = 0;
    }
  }
  $p->print_field("Data", $ud->{data}) if ($printdata);
}

sub process_WSP_CL
{
  my $p = shift;
  $p->print_title("WSP-CL", 1);
  $p->process_WSP_pdu(WSP_CONNECTIONLESS);
}

sub process_WSP_pdu
{
  my ($p, $mode) = @_;
  $WSP::PDU::MODE = $mode;
  my $wsp = WSP::PDU->decode($p->{data});
  $p->print_field("Type", $wsp->msgType);
  if ($wsp->{Type} == WSP_TYPE_PUSH) {
    $p->print_field("ContentType", $wsp->{ContentType});
    $p->child("")->process_WSP_headers($wsp->{Headers});
    $p->print_mime_field("Data", $wsp->{ContentType}, $wsp->{Data});
  } elsif ($wsp->{Type} == WSP_TYPE_DISCONNECT) {
    $p->print_field("ServerSessionId", $wsp->{ServerSessionId});
  }
}

sub process_WSP_headers
{
  my ($p, $hdr) = @_;
  $p->print_title("Headers");
  foreach my $key($hdr->header_field_names)
  {
    $p->print_field($key, $hdr->header($key));
  }
}

sub process_WBXML
{
  my ($p, $lang) = @_;
  $p->print_title("WBXML", 1);
  my $wbxml = UMTS::WBXML->decode($p->{data}, $lang);
  $p->print_field("Version", $wbxml->{version});
  $p->print_field("PublicID", $wbxml->{publicid});

  if (defined($wbxml->{xml})) {
    my $q = $p->child($wbxml->{xml});
    $q->print_title("XML", 1);
  }
}

sub mime_category
{
  my $p = shift;
  my $mimetype = shift;
  # strip extra parameters
  $mimetype =~ s/^([^;]+);.*/$1/;
  if ($mimetype =~ /^text\//) {
    return CONTENT_TEXT;
  } elsif (($mimetype =~ /^application\/vnd\.wap\.(wmlc|wmlscriptc|wta-eventc|sic|slc|coc)$/) || ($mimetype =~ /wbxml$/)) {
    return CONTENT_WBXML;
  } elsif ($mimetype =~ /^application\/x-wap-prov\.browser-settings/) {
    return CONTENT_WBXML;
  } else {
    return CONTENT_BINARY;
  }
}

1;
