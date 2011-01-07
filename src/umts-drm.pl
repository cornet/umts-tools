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

use File::Type;
use Getopt::Std;
use UMTS::App;
use UMTS::Core qw(read_binary);
use UMTS::WBXML;
use DRM::FL;
use DRM::SD;
use DRM::RightObject;

my $script = "umts-drm.pl";

=head1 NAME

umts-drm.pl - A Digital Rights Management (DRM) tool

=head1 SYNOPSIS

B<umts-drm.pl> <action> [options]

=head1 DESCRIPTION

The B<umts-drm.pl> script allows you to manipulate OMA Digital
Rights Management (DRM) v1 files in Separate Delivery or Forward Lock
formats.

=head1 OPTIONS

 Actions:
  fl-encode   produce a DRM FL protected file from clear content
  fl-decode   produce clear content from a DRM FL protected file
  ro-encode   produce a WBXML Right Object from an XML Right Object
  ro-decode   produce an XML Right Object from a WBXML Right Object
  sd-encode   produce a DRM SD protected file from clear content
  sd-decode   produce clear content from a DRM SD protected file
 
 Options:
  -c<type>    use <type> as Content-Type instead of guessing it
              from the input (for encoding only)
  -d          debugging mode
  -h          display a help message
  -i<input>   read input from <input> instead of standard input
  -o<output>  write output to <output> instead of standard output
  -r<ro>      read the Right Object from the <ro> XML file (for SD only)
  -s<file>    set the SD headers from <file>'s content (for SD encoding only)
  -S<headers> set the SD headers to <headers> (for SD encoding only)
  -w<ro>      read the Right Object from the <ro> WBXML file (for SD only)

=cut

# Get command-line arguments
sub init
{
  my $action = shift @ARGV;
  if ($action eq '-h')
  {
    &usage;
  }
  
  if ($action !~ /^(fl|ro|sd)-(encode|decode)$/)
  {
    print STDERR ($action ? "Unknown action '$action'" : "No action")." specified\n";
    &usage;
  }
  
  my %opts;
  if ( not getopts('c:dhi:o:r:s:S:w:', \%opts) or $opts{'h'}) {
    &usage();
  }

  if (($action =~ /^sd/) && !$opts{r} && !$opts{w})
  {
    print STDERR "You must specify a Right Object with -r or -w\n";
    &usage;
  }

  $opts{i} = '-' unless $opts{i};
  $opts{o} = '-' unless $opts{o};

  return ($action, %opts);
}


# Display program usage
sub usage
{
  print STDERR "[ This is $script $UMTS::App::VERSION, a Digital Rights Management (DRM) tool ]\n\n",
        "Syntax:\n",
        "  $script <action> [options]\n\n",
        " Actions:\n",
        "  fl-encode   produce a DRM FL protected file from clear content\n",
        "  fl-decode   produce clear content from a DRM FL protected file\n",
        "  ro-encode   produce a WBXML Right Object from an XML Right Object\n",
        "  ro-decode   produce an XML Right Object from a WBXML Right Object\n",
        "  sd-encode   produce a DRM SD protected file from clear content\n",
        "  sd-decode   produce clear content from a DRM SD protected file\n",
        "\n",
        " Options:\n",
        "  -c<type>    use <type> as Content-Type instead of guessing it\n",
        "              from the input (for encoding only)\n",
        "  -d          debugging mode\n",
        "  -h          display a help message\n",
        "  -i<input>   read input from <input> instead of standard input\n",
        "  -o<output>  write output to <output> instead of standard output\n",
        "  -r<ro>      read the Right Object from the <ro> XML file (for SD only)\n",
        "  -s<file>    set the SD headers from <file>'s content (for SD encoding only)\n",
        "  -S<headers> set the SD headers to <headers> (for SD encoding only)\n",
        "  -w<ro>      read the Right Object from the <ro> WBXML file (for SD only)\n",
        "\n";
  exit 1;
}


# The main routine
sub main
{
  my ($action, %opts) = &init;

  # read input
  print STDERR "- Reading from ".(($opts{i} eq '-') ? "STDIN" : $opts{i})."\n";
  open(INPUT, "<$opts{i}") or die("Could not open '$opts{i}'");
  binmode(INPUT);
  my ($buff, $input);
  while (sysread(INPUT, $buff, 4096))
  {
    $input .= $buff;
  }
  close(INPUT);

  # perform processing
  my ($content_type, $drm, $output);
  if ($opts{c}) {
    $content_type = $opts{c};
  } else {
    my $ft = File::Type->new;
    $content_type = $ft->mime_type($input);
  }
  
  if ($action eq 'fl-encode')
  {
    $drm = DRM::FL->decode;
    $drm->set_content($input);
    $drm->content_type($content_type);
    $output = $drm->encode;
  } elsif ($action eq 'fl-decode') {
    $drm = DRM::FL->decode($input);
    $output = $drm->get_content;
  } elsif ($action eq 'ro-encode') {
    $output = encode_wbxml($input, 1);
  } elsif ($action eq 'ro-decode') {
    $output = decode_wbxml($input, 1);
  } elsif ($action eq 'sd-encode') {
    my $ro = $opts{r} ? DRM::RightObject->parse_xmlfile($opts{r}) : DRM::RightObject->parse_wbxmlfile($opts{w});
    $drm = DRM::SD->decode;
    $drm->set_content($ro->key_value, $input);
    $drm->content_type($content_type);
    $drm->content_uri($ro->uid);
    my $hdrs;
    if ($opts{s}) {
      $hdrs = read_binary($opts{s});
    } elsif ($opts{S}) {
      $hdrs = $opts{S};
    } else {
      $hdrs = 'Encryption-Method: AES128CBC;padding=RFC2630';
    }
    $drm->headers($hdrs);
    $output = $drm->encode;
  } elsif ($action eq 'sd-decode') {
    my $ro = $opts{r} ? DRM::RightObject->parse_xmlfile($opts{r}) : DRM::RightObject->parse_wbxmlfile($opts{w});
    $drm = DRM::SD->decode($input);
    $output = $drm->get_content($ro->key_value);
  } 

  # print some information
  if ($opts{d})
  {
    print STDERR "- Information about DRM file\n" . $drm->info;
  }

  # write output
  print STDERR "- Writing to ".(($opts{o} eq '-') ? "STDOUT" : $opts{o})."\n";
  open(OUTPUT, ">$opts{o}") or die("Could not open '$opts{o}'");
  binmode(OUTPUT);
  syswrite(OUTPUT, $output);
  close(OUTPUT);
}

&main;
