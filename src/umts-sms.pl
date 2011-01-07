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

use UMTS::App;
use SMS::PDU;
use SMS::PDU::UserData qw(:codings);
use UMTS::SMS qw(:stat);
use Getopt::Std;

my $script = "umts-sms.pl";

=head1 NAME

umts-sms.pl - An SMS tool for GSM/UMTS terminals

=head1 SYNOPSIS

B<umts-sms.pl> [options] [<msisdn> <msg>]

=head1 DESCRIPTION

You can send SMS by using the B<umts-sms.pl> script. Both text mode
and PDU mode are supported, and messages are automatically sent as
concatenated SMS as needed.

There are two modes for sending SMS : text mode and PDU mode. Both of
these modes are supported by B<umts-sms.pl>. If your terminal supports
it, PDU mode is preferable as it allows better support of character
sets.

=head1 OPTIONS

 Common options:
  -d          debugging mode
  -l<log>     write log to <log>
  -h          display this help message
  -p<port>    terminal is connected to serial port <port>
              e.g. '\\.\COM12', '/dev/usb/acm/0'
  -z          use dummy terminal
 
 Options:
  -f          make the SMS a 'flash' SMS (not stored)
  -e<coding>  encode outgoing messages using <encoding>
              ('gsm' or 'ucs2')
  -g<store>   get messages stored in <store> from terminal
              examples : SM (SIM), ME (terminal)
  -s<sca>     use <sca> as the Service Center Address
  -r          request a delivery report

=head1 NOTES

Samsung terminals seem to require the Service Center Address (SCA) to
be set explicitly to send SMS. You can use the -s option to achieve
this.

=cut


# Get command-line arguments
sub init
{
  my %opts;
  if ( not getopts('dhl:p:ze:fg:m:rs:', \%opts) or $opts{'h'}) {
    &usage();
  }

  my $config = UMTS::App->parse_opts(%opts);
  
  if (!defined($opts{g}) and (@ARGV < 2)) {
    print "Too few arguments!\n";
    usage();
  }
    
  return ($config, %opts);
}


# Display program usage
sub usage
{
  print "[ This is $script $UMTS::App::VERSION, an SMS tool for GSM/UMTS terminals ]\n\n",
        "Syntax:\n",
        "  $script [options] [<msisdn> <msg>]\n\n",
        UMTS::App->usage,
        " Options:\n",
        "  -f          make the SMS a 'flash' SMS (not stored)\n",
        "  -e<coding>  encode outgoing messages using <encoding>\n",
	"              ('gsm' or 'ucs2')\n",
        "  -g<store>   get messages stored in <store> from terminal\n",
        "              examples : SM (SIM), ME (terminal)\n",
        "  -s<sca>     use <sca> as the Service Center Address\n",
        "  -r          request a delivery report\n",        
        "\n";
  exit 1;
}


# The main routine
sub main
{
  
  my ($config, %opts) = &init;    
  my ($dest, $msg) = @ARGV;

  # do some cleanup on the message
  #$msg =~ s/:/-/g;
  
  # read options
  my $flash = $opts{f};    
  my $sca = $opts{s};
  my $storage = $opts{g};
  my $srr = $opts{r};

  defined($opts{e}) or $opts{e} = "gsm";
  my $coding;
  if ($opts{e} eq "ucs2")
  {
    $coding = PDU_CODING_UCS2;
  } elsif ($opts{e} eq "gsm") {
    $coding = PDU_CODING_7BIT;
  } else {
    die("Unknown coding '$opts{e}' specified");
  }

  # setup log
  my $log = UMTS::App->make_log($config);
  my $term = UMTS::App->make_term($config) or  
    die("Could not open terminal");
  
  $SIG{INT} = sub {
    $term->close;
    exit 1;
  };
           
  if (defined($storage)) 
  {
    my @pstore = UMTS::SMS->getStorages($term);    
    $log->write("Available message storages : @pstore");
    
    $log->write("Selecting message storage '$storage'");
    UMTS::SMS->setStorage($term, $storage);
    
    $log->write("Retrieving all messages");
    my @msgs = UMTS::SMS->getMessages($term, SMS_STAT_ALL);
    
#    my $pcap = UMTS::NetPacket::Pcap->decode;
    foreach my $msg (@msgs)
    {
      my $sms = SMS::PDU->decode(pack('H*', $msg->{data}));
#      $pcap->addSMS_UD('0611223344', $sms->{'TP-UD'});
      my $data = $sms->{'TP-UD'}->{data};     
      print "--\n";
      print("From: ".$sms->getNumber."\n");
      print("$data\n");
    }
    print("--\n");          
    
#    $pcap->dump('sms.pcap');
  
  } else {
    $log->write("Sending SMS to $dest : \"$msg\"");     
  
    # optionally set SCA
    $sca and
      $term->setSCA($sca);
  
    my $resp;
    if ($term->{msg_mode} eq 1)
    {
      $resp = $term->sendSMSTextMessageDumb($dest, $msg);
    } else {
      $resp = $term->sendSMSTextMessage($dest, $msg, 'coding' => $coding, 'readreport' => $srr, 'flash' => $flash);
    }
      
    if ($resp)
    {
      $log->write("Sent SMS OK!");
    } else {
      $log->write("Sending SMS failed.");
    }    
  }
  
  $term->close;

  exit 0;
}

&main

