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

use strict;

BEGIN { push @INC, '/usr/share/umts-tools'; }

use Digest::HMAC_SHA1;
use Getopt::Std;

use UMTS::App;
use UMTS::Core qw(read_binary);
use UMTS::NetPacket::Pcap;
use UMTS::WBXML;
use SMS::PDU::Submit;
use SMS::PDU::UserData qw(:dcs);
use WSP::PDU;
use WSP::PDU::Push;

my $script = "umts-wappush.pl";

=head1 NAME

umts-wappush.pl - A WAP PUSH tool for GSM/UMTS terminals

=head1 SYNOPSIS

B<umts-wappush.pl> [options] <msisdn> <file>

=head1 DESCRIPTION

You can send WAP PUSH messages using B<umts-wappush.pl>. In order to
do so, you will first need to produce a WBXML version of the XML
document you wish to send. The easiest way to achieve this is to first
write an XML document and then convert this to WBXML using a compiler
such as the one provided by C<libwbxml>, available at
L<http://libwbxml.aymerick.com/>.

The following type of WAP PUSH messages are currently supported:

 * OMA Content Provisioning
 * OMA DRM Right Objects
 * Nokia/Ericsson OTA settings
 * Service Indication (SI)
 * Service Loading (SL)

=head1 OPTIONS

 Common options:
  -d          debugging mode
  -l<log>     write log to <log>
  -h          display this help message
  -p<port>    terminal is connected to serial port <port>
              e.g. '\\.\COM12', '/dev/usb/acm/0'
  -z          use dummy terminal
 
 Options:
  -k<pin>     use <pin> as the secret for the HMAC hash
  -s<sca>     use <sca> as the Service Center Address
  -w<dump>    write a Pcap dump of WSP to file <dump>
  -x<dump>    write a Pcap dump of PDUs to file <dump>

=head1 NOTES

Motorola terminals seem to only accept OTA settings if they have USERPIN set as the security mechanism. You can specify this PIN by using the B<-k> option.

Samsung terminals seem to require the Service Center Address (SCA) to be set explicitly to send SMS. You can use the B<-s> option to achieve this.

=cut 


# Get command-line arguments
sub init
{
  my %opts;
  if ( not getopts('dhl:p:zk:s:w:x:', \%opts) or $opts{'h'}) {
    &usage();
  }

  if (@ARGV < 2) {
    print "Too few arguments!\n";
    usage();
  }
    
  my $config = UMTS::App->parse_opts(%opts);   
  return ($config, %opts);
}


# Display program usage
sub usage
{
  print "[ This is $script $UMTS::App::VERSION, a WAP PUSH tool for GSM/UMTS terminals ]\n\n",
        "Syntax:\n",
        "  $script [options] <msisdn> <file>\n\n",
        UMTS::App->usage,
        " Options:\n",
        "  -k<pin>     use <pin> as the secret for the HMAC hash\n",        
        "  -s<sca>     use <sca> as the Service Center Address\n",        
        "  -w<dump>    write a Pcap dump of WSP to file <dump>\n",
        "  -x<dump>    write a Pcap dump of PDUs to file <dump>\n",        
        "\n";
  exit 1;
}


# The main routine
sub main
{
  my ($config, %opts) = &init;    
  my ($msisdn, $file) = @ARGV;
  
  if (! -f $file) {
    print("Could not find '$file'");
    exit 1;
  }
 
  my $log = UMTS::App->make_log($config);

  # read WBXML from file 
  my $wbxml = read_binary($file);
  my $mime_type = UMTS::WBXML->guess_mime($wbxml); 

  if (!$mime_type) {
    die("Could not determine MIME type!");
  }
  $log->write("MIME type is '$mime_type'");

  # make WSP message  
  $WSP::PDU::MODE = WSP_CONNECTIONLESS;
  my $wsp = WSP::PDU::Push->decode;
  $wsp->{ContentType} = $mime_type;
  $wsp->{Data} = $wbxml;

  if ($opts{k})
  {
    my $hmac = Digest::HMAC_SHA1->new($opts{k});
    $hmac->add($wsp->{Data});
    $wsp->{ContentType} .= "; SEC=USERPIN";
    $wsp->{ContentType} .= "; MAC=".uc(unpack('H*',$hmac->digest));
  }

  # default source and destination ports
  my $src_port = 9200;
  my $dest_port = 2948;
  
  # figure out type-specific assignments
  if ($mime_type eq 'application/x-wap-prov.browser-settings')
  {
    $src_port = 49154;
    $dest_port = 49999;
  }
  elsif ($mime_type eq 'application/vnd.wap.connectivity-wbxml') 
  {  
    $wsp->{Headers}->header('From' => 'umts-tools@jerryweb.org');
  } 
  elsif ($mime_type eq 'application/vnd.oma.drm.rights+wbxml')
  {
    $wsp->{Headers}->header('X-Wap-Application-Id' => '8');
  }

  # split into PDUs
  my $udFactory = SMS::PDU::UserData->decode;
  
  # Note : PDU_DCS_8BIT addresses the message to the SIM card which
  # causes problems when sending WAP PUSH to Nokia handsets.
  # Thanks to Robert Grabowski for pointing this out!
  $udFactory->{dcs} = PDU_DCS_8BITM;
  $udFactory->{src_port} = $src_port;
  $udFactory->{dest_port} = $dest_port;
  $udFactory->{data} = $wsp->encode;
  my @userdata = $udFactory->split;

  # produce Pcap dump of WSP
  if ($opts{w}) {
    my $pcap = UMTS::NetPacket::Pcap->decode('');
    $pcap->addWSP($wsp, $dest_port, $src_port);
    $log->write("Saving Pcap dump of WSP to '$opts{w}'");    
    $pcap->dump($opts{w});
  }

  # produce Pcap dump of PDUs
  if ($opts{x})
  {
    my $pcap = UMTS::NetPacket::Pcap->decode('');  
    $pcap->addSMS_UD($msisdn, @userdata);
    $log->write("Saving Pcap dump of PDUs to '$opts{x}'");        
    $pcap->dump($opts{x});
  }
          
  $log->write("Sending from port '$src_port' to '$dest_port'");
    
  # set up terminal
  my $term = UMTS::App->make_term($config) or  
    die("Could not open terminal");
  
  $SIG{INT} = sub {
    $term->close;
    exit 1;
  };
          
  $opts{'s'} and
    $term->setSCA($opts{'s'});
    
  # send the WAP PUSH by SMS
  $log->write("Sending WAP PUSH to $msisdn");
  my @tpdus = SMS::PDU::Submit->frameUserData('', $msisdn, @userdata);
  if ($term->sendPDUs('CMGS', @tpdus))
  {
    $log->write("Sent WAP PUSH OK!");
  } else {
    $log->write("Sending WAP PUSH failed.");
  }
  $term->close;

  exit 0;
}

&main
