#!/usr/bin/perl -w
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
use warnings;

BEGIN { push @INC, '/usr/share/umts-tools'; }

use UMTS::App;
use Carp ();
use LWP::UserAgent;
use HTTP::Request::Common;
use HTML::Tree;
use URI;
use Getopt::Std;
use MIME::Base64;
use MIME::QuotedPrint;

my $script = "umts-multipart.pl";
my %opts;
my $nl = "\r\n";


=head1 NAME

umts-multipart.pl - A tool for generating multipart/mixed WAP pages

=head1 SYNOPSIS

B<umts-multipart.pl> [options] url

=head1 DESCRIPTION

B<umts-multipart.pl> is a script that allows you to generate a 
multipart/mixed page from a regular XHTML or WML page. You give the script
the URL of an XHTML or WML page and it will retrieve the page and any 
images or CSS stylesheets it refers to and produce a multipart/mixed page.

=head1 OPTIONS

 Options:
  -b<boundary> specify the boundary to separate the parts
  -e<encoding> specify the Content-Transfer-Encoding to use for the page:
               7bit, 8bit, binary, quoted-printable or base64
  -E<encoding> specify the Content-Transfer-Encoding to use for objects:
               7bit, 8bit, binary, quoted-printable or base64
  -h           display this help message
  -n           do not include HTTP headers in the output
  -o<file>     write output a file instead of standard output

=cut

# display program use
sub usage {
  print "[ This is $script $UMTS::App::VERSION, a multipart/mixed generation tool ]\n\n",
        "Syntax:\n",
        "  $script [options] url\n\n",
        " Options:\n",
        "  -b<boundary> specify the boundary to separate the parts\n",
        "  -e<encoding> specify the Content-Transfer-Encoding to use for the page:\n",
        "               7bit, 8bit, binary, quoted-printable or base64\n",
        "  -E<encoding> specify the Content-Transfer-Encoding to use for objects:\n",
        "               7bit, 8bit, binary, quoted-printable or base64\n",
        "  -h           display this help message\n",
        "  -n           do not include HTTP headers in the output\n",
        "  -o<file>     write output a file instead of standard output\n",
        "\n";
}


# parse command line options
sub init
{
  if (!getopts('b:e:E:hno:', \%opts) or !(@ARGV > 0))
  {
    &usage;
    exit(1);
  }
  if (!$opts{b})
  {
    $opts{b} = "testboundaryfoo";
  }
  if ($opts{e})
  {
    $opts{e} = lc($opts{e});
    &checkEncoding($opts{e});
  }
  if ($opts{E})
  {
    $opts{E} = lc($opts{E});
    &checkEncoding($opts{E});
  }
  my $url = shift @ARGV;
  return $url;
}


# check whether the specified encoding is valid / supported
sub checkEncoding
{
  my $encoding = shift;
  if ($encoding !~ /^(7bit|8bit|binary|quoted-printable|base64)$/i)
  {
    print "Invalid Content-Transfer-Encoding specified : $encoding\n";
    &usage;
    exit(1);
  }
}


# the main routine
sub main
{
  my $url = &init;
  my $ua = new LWP::UserAgent;
  $ua->env_proxy;
  
  # get the web page
  my $response = $ua->request(GET $url);
  $response->is_success or
    die("Could not get page $url");
  my $ctype = join("; ", $response->content_type);
  my $output = genObjectPart($url, $ctype, $response->content, $opts{e});

  # get the objects
  my @objurls = &findObjects($response->content);
  foreach my $objurl (@objurls)
  {
    my $absurl = URI->new_abs($objurl, $url);
    $response = $ua->request(GET $absurl);
    $response->is_success or
      die("Could not get object $absurl");
    $ctype = join("; ", $response->content_type);
    $output .= genObjectPart($objurl, $ctype, $response->content, $opts{E});
  }
  $output .= "--$opts{b}--" . $nl;

  # if requested, add the HTTP header
  if (!$opts{n}) 
  {
    my $header = "Content-Type: multipart/mixed; boundary=$opts{b}" . $nl;
    $output = $header . $nl . $output;
  }

  # output the result
  if ($opts{o})
  {
    open(OUT, "> $opts{o}");
    print OUT $output;
    close(OUT);
  } else { 
    print STDOUT $output;
  }
}


# generate the multipart entity for an object
sub genObjectPart
{
  my ($objurl, $objtype, $objdata, $encoding) = @_;
  my $encdata;
  defined($encoding) or $encoding = '';
  if ($encoding =~ /^(7bit|8bit|binary|)$/i) {
    $encdata = $objdata;
  } elsif ($encoding =~ /^base64$/i) {
    $encdata = encode_base64($objdata);
  } elsif ($encoding =~ /^quoted-printable$/i) {
    $encdata = encode_qp($objdata);
  } else {
    Carp::croak("Unhandled transfer-encoding : $encoding");
  }

  my $mbody = "--$opts{b}" . $nl;
  $mbody .= "Content-Type: $objtype" . $nl;
  $mbody .= "Content-Location: $objurl" . $nl;
  if ($encoding) {
    $mbody .= "Content-Transfer-Encoding: $encoding" . $nl;
  }
  $mbody .= $nl . $encdata . $nl;
  return $mbody;
}


# find the objects which will be added as multipart entities
sub findObjects
{
  my $htmldata = shift;
  
  my $tree = HTML::TreeBuilder->new_from_content($htmldata);
  my (%urlhash, @objurls, @tags, $tag);

  @tags = $tree->look_down("_tag", "img");
  foreach $tag(@tags) {
    my $obj = $tag->attr("src");
    $urlhash{$obj}= $obj if ($obj);
  }
  
  @tags = $tree->look_down("_tag", "link");
  foreach $tag(@tags) { 
    my $obj = $tag->attr("href"); 
    $urlhash{$obj}= $obj if ($obj);
  }

  return keys (%urlhash);
}

&main;
