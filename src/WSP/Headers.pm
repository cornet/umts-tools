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

package WSP::Headers;

use strict;
use warnings;

use Carp ();
use Math::BigInt;
use HTTP::Date;
use HTTP::Headers;
use WSP::Headers::Field;
use POSIX qw(floor);
use Text::ParseWords;
use MIME::Base64 ();
use UNIVERSAL qw(isa);

our $SHORTINT_MAX = 127;
our $LONGINT_MAX = ( Math::BigInt->new(2) << 239 ) - 1;
our $UINTVAR_MAX = ( Math::BigInt->new(2) << 34 ) - 1;

sub trimwhitespace
{
  my $s = shift;
  $s =~ s/^\s*//;
  $s =~ s/\s*$//;
  return $s;
}


# Well-known content types
# see http://www.wapforum.org/wina/wsp-content-type.htm
our $WSP_CONTENT_TYPES =
{
  '*/*'					=>	0x00,
  'text/*'				=>	0x01,
  'text/html'				=>	0x02,
  'text/plain'				=>	0x03,
  'text/x-hdml'				=>	0x04,
  'text/x-ttml'				=>	0x05,
  'text/x-vCalendar'			=>	0x06,
  'text/x-vCard'			=>	0x07,
  'text/vnd.wap.wml'			=>	0x08,
  'text/vnd.wap.wmlscript'		=>	0x09,
  'text/vnd.wap.wta-event'		=>	0x0A,
  'multipart/*'				=>	0x0B,
  'multipart/mixed'			=>	0x0C,
  'multipart/form-data'			=>	0x0D,
  'multipart/byterantes'		=>	0x0E,
  'multipart/alternative'		=>	0x0F,
  'application/*'			=>	0x10,
  'application/java-vm'			=>	0x11,
  'application/x-www-form-urlencoded'	=>	0x12,
  'application/x-hdmlc'			=>	0x13,
  'application/vnd.wap.wmlc'		=>	0x14,
  'application/vnd.wap.wmlscriptc'	=>	0x15,
  'application/vnd.wap.wta-eventc'	=>	0x16,
  'application/vnd.wap.uaprof'		=>	0x17,
  'application/vnd.wap.wtls-ca-certificate'	=>	0x18,
  'application/vnd.wap.wtls-user-certificate'	=>	0x19,
  'application/x-x509-ca-cert'		=>	0x1A,
  'application/x-x509-user-cert'	=>	0x1B,
  'image/*'				=>	0x1C,
  'image/gif'				=>	0x1D,
  'image/jpeg'				=>	0x1E,
  'image/tiff'				=>	0x1F,
  'image/png'				=>	0x20,
  'image/vnd.wap.wbmp'			=>	0x21,
  'application/vnd.wap.multipart.*'	=>	0x22,
  'application/vnd.wap.multipart.mixed'	=>	0x23,
  'application/vnd.wap.multipart.form-data'	=>	0x24,
  'application/vnd.wap.multipart.byteranges'	=>	0x25,
  'application/vnd.wap.multipart.alternative'	=>	0x26,
  'application/xml'			=>	0x27,
  'text/xml'				=>	0x28,
  'application/vnd.wap.wbxml'		=>	0x29,
  'application/x-x968-cross-cert'	=>	0x2A,
  'application/x-x968-ca-cert'		=>	0x2B,
  'application/x-x968-user-cert'	=>	0x2C,
  'text/vnd.wap.si'			=>	0x2D,
  'application/vnd.wap.sic'		=>	0x2E,
  'text/vnd.wap.sl'			=>	0x2F,
  'application/vnd.wap.slc'		=>	0x30,
  'text/vnd.wap.co'			=>	0x31,
  'application/vnd.wap.coc'		=>	0x32,
  'application/vnd.wap.multipart.related'	=>	0x33,
  'application/vnd.wap.sia'		=>	0x34,
  'text/vnd.wap.connectivity-xml'	=>	0x35,
  'application/vnd.wap.connectivity-wbxml'	=>	0x36,
  'application/pkcs7-mime'		=>	0x37,
  'application/vnd.wap.hashed-certificate'	=>	0x38,
  'application/vnd.wap.signed-certificate'	=>	0x39,
  'application/vnd.wap.cert-response'	=>	0x3A,
  'application/xhtml+xml'		=>	0x3B,
  'application/wml+xml'			=>	0x3C,
  'text/css'				=>	0x3D,
  'application/vnd.wap.mms-message'	=>	0x3E,
  'application/vnd.wap.rollover-certificate'	=>	0x3F,
  'application/vnd.wap.locc+wbxml'	=>	0x40,
  'application/vnd.wap.loc+xml'		=>	0x41,
  'application/vnd.syncml.dm+wbxml'	=>	0x42,
  'application/vnd.syncml.dm+xml'	=>	0x43,
  'application/vnd.syncml.notification'	=>	0x44,
  'application/vnd.wap.xhtml+xml'	=>	0x45,
  'application/vnd.wv.csp.cir'		=>	0x46,
  'application/vnd.oma.dd+xml'		=>	0x47,
  'application/vnd.oma.drm.message'	=>	0x48,
  'application/vnd.oma.drm.content'	=>	0x49,
  'application/vnd.oma.drm.rights+xml'	=>	0x4A,
  'application/vnd.oma.drm.rights+wbxml'	=>	0x4B,

# extended values
  'application/vnd.uplanet.cacheop-wbxml'	=> 0x0201,
  'application/vnd.uplanet.signal'	=>	0x0202,
  'application/vnd.uplanet.alert-wbxml'	=>	0x0203,
  'application/vnd.uplanet.list-wbxml'	=>	0x0204,
  'application/vnd.uplanet.listcmd-wbxml'	=>	0x0205,
  'application/vnd.uplanet.channel-wbxml'	=>	0x0206,
  'application/vnd.uplanet.provisioning-status-uri'	=>	0x0207,
  'x-wap.multipart/vnd.uplanet.header-set'	=>	0x0208,
  'application/vnd.uplanet.bearer-choice-wbxml'	=>	0x0209,
  'application/vnd.phonecom.mmc-wbxml'	=>	0x020A,
  'application/vnd.nokia.syncset+wbxml'	=>	0x020B,
  'image/x-up-wpng'			=>	0x020C,
  'application/iota.mmc-wbxml'		=>	0x0300,
  'application/iota.mmc-xml'		=>	0x0301,
  'application/vnd.syncml+xml'		=>	0x0302,
  'application/vnd.syncml+wbxml'	=>	0x0303,
  'text/vnd.wap.emn+xml'		=>	0x0304,
  'text/calendar'			=>	0x0305,
  'application/vnd.omads-email+xml'	=>	0x0306,
  'application/vnd.omads-file+xml'	=>	0x0307,
  'application/vnd.omads-folder+xml'	=>	0x0308,
  'text/directory;profile=vCard'	=>	0x0309,
  'application/vnd.wap.emn+wbxml'	=>	0x030A,
  'application/vnd.nokia.ipdc-purchase-response'	=>	0x030B,
  'application/vnd.motorola.screen3+xml'	=>	0x030C,
  'application/vnd.motorola.screen3+gzip'	=>	0x030D,
  'application/vnd.cmcc.setting+wbxml'	=>	0x030E,
  'application/vnd.cmcc.bombing+wbxml'	=>	0x030F,
};


our $WSP_CONTENT_DISPOSITIONS = 
{
  'Form-data'				=> 0x00,
  'Attachment'				=> 0x01,
  'Inline'				=> 0x02,
};


our $WSP_CONTENT_ENCODINGS = 
{
  'Gzip'				=> 0x00,
  'Compress'				=> 0x01,
  'Deflate'				=> 0x02,
};


our $WSP_CONNECTIONS =
{
  'Close'				=> 0x00,
};

# Well-known character sets
# see OMA-WAP-TS-WSP Appendix A
our $WSP_CHARSETS =
{
  '*'				=>	0x00,
  'big5'			=>	0x07EA,
  'iso-10646-ucs-2'		=>	0x03E8,
  'iso-8859-1'			=>	0x04,
  'iso-8859-2'			=>	0x05,
  'iso-8859-3'			=>	0x06,
  'iso-8859-4'			=>	0x07,
  'iso-8859-5'			=>	0x08,
  'iso-8859-6'			=>	0x09,
  'iso-8859-7'			=>	0x0A,
  'iso-8859-8'			=>	0x0B,
  'iso-8859-9'			=>	0x0C,
  'shift_JIS'			=>	0x11,
  'us-ascii'			=>	0x03,
  'utf-8'			=>	0x6A,
};


# Well-known languages
# see OMA-WAP-TS-WSP Appendix A
our $WSP_LANGUAGES =
{
  "*"				=>	0,
  "aa"				=>	0x01,
  "ab"				=>	0x02,
  "af"				=>	0x03,
  "am"				=>	0x04,
  "ar"				=>	0x05,
  "as"				=>	0x06,
  "ay"				=>	0x07,
  "az"				=>	0x08,
  "ba"				=>	0x09,
  "be"				=>	0x0a,
  "bg"				=>	0x0b,
  "bh"				=>	0x0c,
  "bi"				=>	0x0d,
  "bn"				=>	0x0e,
  "bo"				=>	0x0f,
  "br"				=>	0x10,
  "ca"				=>	0x11,
  "co"				=>	0x12,
  "cs"				=>	0x13,
  "cy"				=>	0x14,
  "da"				=>	0x15,
  "de"				=>	0x16,
  "dz"				=>	0x17,
  "el"				=>	0x18,
  "en"				=>	0x19,
  "eo"				=>	0x1a,
  "es"				=>	0x1b,
  "et"				=>	0x1c,
  "eu"				=>	0x1d,
  "fa"				=>	0x1e,
  "fi"				=>	0x1f,
  "fj"				=>	0x20,
  "fo"				=>	0x82,
  "fr"				=>	0x22,
  "fy"				=>	0x83,
  "ga"				=>	0x24,
  "gd"				=>	0x25,
  "gl"				=>	0x26,
  "gn"				=>	0x27,
  "gu"				=>	0x28,
  "ha"				=>	0x29,
  "he"				=>	0x2a,
  "hi"				=>	0x2b,
  "hr"				=>	0x2c,
  "hu"				=>	0x2d,
  "hy"				=>	0x2e,
  "ia"				=>	0x84,
  "id"				=>	0x30,
  "ie"				=>	0x86,
  "ik"				=>	0x87,
  "is"				=>	0x33,
  "it"				=>	0x34,
  "iu"				=>	0x89,
  "ja"				=>	0x36,
  "jw"				=>	0x37,
  "ka"				=>	0x38,
  "kk"				=>	0x39,
  "kl"				=>	0x8a,
  "km"				=>	0x3b,
  "kn"				=>	0x3c,
  "ko"				=>	0x3d,
  "ks"				=>	0x3e,
  "ku"				=>	0x3f,
  "ky"				=>	0x40,
  "la"				=>	0x8b,
  "ln"				=>	0x42,
  "lo"				=>	0x43,
  "lt"				=>	0x44,
  "lv"				=>	0x45,
  "mg"				=>	0x46,
  "mi"				=>	0x47,
  "mk"				=>	0x48,
  "ml"				=>	0x49,
  "mn"				=>	0x4a,
  "mo"				=>	0x4b,
  "mr"				=>	0x4c,
  "ms"				=>	0x4d,
  "mt"				=>	0x4e,
  "my"				=>	0x4f,
  "na"				=>	0x81,
  "ne"				=>	0x51,
  "nl"				=>	0x52,
  "no"				=>	0x53,
  "oc"				=>	0x54,
  "om"				=>	0x55,
  "or"				=>	0x56,
  "pa"				=>	0x57,
  "pl"				=>	0x58,
  "ps"				=>	0x59,
  "pt"				=>	0x5a,
  "qu"				=>	0x5b,
  "rm"				=>	0x8c,
  "rn"				=>	0x5d,
  "ro"				=>	0x5e,
  "ru"				=>	0x5f,
  "rw"				=>	0x60,
  "sa"				=>	0x61,
  "sd"				=>	0x62,
  "sg"				=>	0x63,
  "sh"				=>	0x64,
  "si"				=>	0x65,
  "sk"				=>	0x66,
  "sl"				=>	0x67,
  "sm"				=>	0x68,
  "sn"				=>	0x69,
  "so"				=>	0x6a,
  "sq"				=>	0x6b,
  "sr"				=>	0x6c,
  "ss"				=>	0x6d,
  "st"				=>	0x6e,
  "su"				=>	0x6f,
  "sv"				=>	0x70,
  "sw"				=>	0x71,
  "ta"				=>	0x72,
  "te"				=>	0x73,
  "tg"				=>	0x74,
  "th"				=>	0x75,
  "ti"				=>	0x76,
  "tk"				=>	0x77,
  "tl"				=>	0x78,
  "tn"				=>	0x79,
  "to"				=>	0x7a,
  "tr"				=>	0x7b,
  "ts"				=>	0x7c,
  "tt"				=>	0x7d,
  "tw"				=>	0x7e,
  "ug"				=>	0x7f,
  "uk"				=>	0x50,
  "ur"				=>	0x21,
  "uz"				=>	0x23,
  "vi"				=>	0x2f,
  "vo"				=>	0x85,
  "wo"				=>	0x31,
  "xh"				=>	0x32,
  "yi"				=>	0x88,
  "yo"				=>	0x35,
  "za"				=>	0x3a,
  "zh"				=>	0x41,
  "zu"				=>	0x5c,
  "zu"				=>	0x5c,
};

our $WSP_METHODS =
{
  "GET"				=>	0x40,
  "OPTIONS"			=>	0x41,
  "HEAD"			=>	0x42,
  "DELETE"			=>	0x43,
  "TRACE"			=>	0x44,
  "POST"			=>	0x60,
  "PUT"				=>	0x61,
};


our $WSP_ACCEPT_RANGES =
{
  'None'			=> 	0x00,
  'Bytes',			=>	0x01,
};


our $WSP_SEC_PINS = {
  NETWPIN			=> 0x00,
  USERPIN			=> 0x01,
  USERNETWPIN			=> 0x02,
  USERPINMAC			=> 0x03,
};


our $WSP_HEADERS = [
[ 'Accept',			0x00,	'accept_value',		LIST	],
[ 'Accept-Language',		0x03,	'accept_language_value',LIST	],
[ 'Accept-Ranges',		0x04,	'accept_ranges_value',	LIST	],
[ 'Age',			0x05,	'integer_value',	NOLIST	],
[ 'Allow',			0x06,	'allow_value',		LIST	], 
# TODO [ 'Authorization',		0x07,	'credentials',		BRKLIST	],
[ 'Connection',			0x09,	'connection_value',	LIST	],
[ 'Content-Base',		0x0A,	'text_string',		NOLIST	],
[ 'Content-Encoding',		0x0B,	'content_encoding_value',	LIST	],
[ 'Content-Language',		0x0C,	'content_language_value',	LIST	], 
[ 'Content-Length',		0x0D,	'integer_value',	NOLIST	],
[ 'Content-Location',		0x0E,	'text_string',		NOLIST	],
[ 'Content-MD5',		0x0F,	'content_md5_value',	NOLIST	],
[ 'Content-Type',		0x11,	'accept_value',		NOLIST	],
[ 'Date',			0x12,	'date_value',		NOLIST	],
[ 'Etag',			0x13,	'text_string',		NOLIST	],
[ 'Expires',			0x14,	'date_value',		NOLIST	],
[ 'From',			0x15,	'text_string',		NOLIST	],
[ 'Host',			0x16,	'text_string',		NOLIST	],
[ 'If-Modified-Since',		0x17,	'date_value',		NOLIST	],
[ 'If-Match',			0x18,	'text_string',		NOLIST	],
[ 'If-None-Match',		0x19,	'text_string',		NOLIST	],
# TODO [ 'If-Range',			0x1A,	'if_range',		NOLIST	],
[ 'If-Unmodified-Since',	0x1B,	'date_value',		NOLIST	],
[ 'Location',			0x1C,	'text_string',		NOLIST	],
[ 'Last-Modified',		0x1D,	'date_value',		NOLIST	],
[ 'Max-Forwards',		0x1E,	'integer_value',	NOLIST	],
# TODO [ 'Pragma',			0x1F,	'pragma_value',		LIST	],
# TODO [ 'Proxy-Authenticate',		0x20,	'challenge',		BRKLIST	],
# TODO [ 'Proxy-Authorization',	0x21,	'credentials',		BRKLIST	],
[ 'Public',			0x22,	'public_value',		LIST	], 
[ 'Range',			0x23,	'range',		NOLIST	],
[ 'Referer',			0x24,	'text_string',		NOLIST	],
[ 'Retry-After',		0x25,	'retry_after_value',	NOLIST	],
[ 'Server',			0x26,	'text_string',		NOLIST	],
[ 'Transfer-Encoding',		0x27,	'transfer_encoding_value',	LIST	],
[ 'Upgrade',			0x28,	'text_string',		NOLIST	],
[ 'User-Agent',			0x29,	'text_string',		NOLIST	],
[ 'Vary',			0x2A,	'field_name',		LIST	],
[ 'Via',			0x2B,	'text_string',		LIST	],
# TODO [ 'Warning',			0x2C,	'warning',		LIST	],
# TODO [ 'WWW-Authenticate',		0x2D,	'challenge',		BRKLIST	],
[ 'X-Wap-Application-Id',	0x2F,	'integer_value',	NOLIST	],
[ 'X-Wap-Content-URI',		0x30,	'text_string',		NOLIST	],
[ 'X-Wap-Initiator-URI',	0x31,	'text_string',		NOLIST	],
# TODO [ 'Accept-Application',		0x32,					],
[ 'Bearer-Indication',		0x33,	'integer_value',	NOLIST	],
[ 'Push-Flag',			0x34,	'short_integer',	NOLIST	],
[ 'Profile',			0x35,	'text_string',		NOLIST	],
# TODO [ 'Profile-Diff',		0x36,					],
# TODO [ 'TE',				0x39,					],
# TODO [ 'Trailer',			0x3A,					],
[ 'Accept-Charset',		0x3B,	'accept_charset_value',	LIST	],
[ 'Accept-Encoding',		0x3C,	'accept_encoding_value',LIST	],
# TODO [ 'Content-Range',		0x3E,	'content_range',	LIST	],
# TODO [ 'X-Wap-Tod',			0x3F,					],
[ 'Content-ID',			0x40,	'quoted_string',	NOLIST	],
[ 'Set-Cookie',			0x41,	'text_string',		LIST	],
[ 'Cookie',			0x42,	'text_string',		LIST	],
# TODO [ 'Encoding-Version',		0x43,	'encoding_version_value', NOLIST],
# TODO [ 'Profile-Warning',		0x44,					],
[ 'Content-Disposition',	0x45,	'content_disposition_value',	NOLIST	],
# TODO [ 'X-WAP-Security',		0x46,					],
# TODO [ 'Cache-Control',		0x47,	'cache_control',	LIST	],
# TODO [ 'Expect',			0x48,					],
# TODO [ 'X-Wap-Loc-Invocation',	0x49,					], 
# TODO [ 'X-Wap-Loc-Delivery',		0x4A,					],
];

our $WSP_PARAMETERS = [
[ 'Q',				0x00,	'q_value'			],
[ 'Charset',			0x01,	'well_known_charset'		],
[ 'Level',			0x02,	'version_value'			],
[ 'Type',			0x03,	'integer_value'			],
[ 'Name',			0x05,	'text_string'			],
[ 'Filename',			0x06,	'text_string'			],
# TODO [ 'Differences',		0x07,	'field_name'			], 
[ 'Padding',			0x08,	'short_integer'			],
# TODO [ 'Type',			0x09,	'constrained_encoding'		]
[ 'Start',			0x0A,	'text_string'			],
[ 'Start-info',			0x0B,	'text_string'			],
[ 'Comment',			0x0C,	'text_string'			],
[ 'Domain',			0x0D,	'text_string'			],
[ 'Max-Age',			0x0E,	'integer_value'			],
[ 'Path',			0x0F,	'text_string'			],
[ 'Secure',			0x10,	'no_value'			],
[ 'SEC',			0x11,	'sec_value'			],
[ 'MAC',			0x12,	'text_string'			],
[ 'Creation-date',		0x13,	'date_value'			],
[ 'Modification-date',		0x14,	'date_value'			],
[ 'Read-date',			0x15,	'date_value'			],
[ 'Size',			0x16,	'integer_value'			],
[ 'Name',			0x17,	'text_value'			],
[ 'Filename',			0x18,	'text_value'			],
[ 'Start',			0x19,	'text_value'			],
[ 'Start-info',			0x1A,	'text_value'			],
[ 'Comment',			0x1B,	'text_value'			],
[ 'Domain',			0x1C,	'text_value'			],
[ 'Path',			0x1D,	'text_value'			],
];


# useful regexps from RFC 2616
#my $reg_separator = '[\(\)<>@,;:\\"\/\[\]?={} \t]';
my $reg_token = '[!\x23-\x27\*\+\-\.0-9A-Z\^_`a-z|~]';

=head1 NAME

WSP::Headers - Class for encoding/decoding WSP headers

=head1 SYNOPSIS

  use WSP::Headers;
  
  # construction from field values
  my $wsp = WSP::Headers->new(
    'Date'         => 'Tue, 06 Sep 2005 06:16:43 GMT',
    'Content-Type' => 'application/vnd.wap.wmlc'
  );
  
  # construction from binary string
  my $wsp = WSP::Header->decode("\x91\x94");
  
  # encoding into a binary string
  my $binstr = $wsp->encode;

=head1 DESCRIPTION

The C<WSP::Headers> class allows you encode and decode Wireless
Session Protocol (WSP) headers to and from their binary
representation. C<WSP::Headers> is designed as a wrapper around
libwww-perl's C<HTTP::Headers>, so many of the functions found in
C<HTTP::Headers> are also available from C<WSP::Headers>.

The following methods are available:

=over 10

=item WSP::Headers->new

=item WSP::Headers->new( $field => $value, ... )

Construct a WSP::Headers and optionally initialise its value from some
HTTP headers.

=cut

sub new
{
  my $class = shift;

  my $self = bless {
    '_headerdefs' => $WSP_HEADERS,
    '_paramdefs' => $WSP_PARAMETERS,
    '_headervals' => HTTP::Headers->new(@_),
  }, $class;
  $self;
}


=item $h->as_string

Return a plain-text string representation of the WSP headers. This 
method behaves exactly like the one in C<HTTP::Headers>.

=cut

sub as_string
{
  my $self = shift;
  $self->{_headervals}->as_string(@_);
}


=item $h->clear

Remove all header fields. This method behaves exactly like the one in
C<HTTP::Headers>.

=cut

sub clear
{
  my $self = shift;
  $self->{_headervals}->clear(@_);
}


=item $h->header( $field )

=item $h->header( $field => $value, ... )

Get or set the value of one or more header fields. This method behaves
exactly like the one in C<HTTP::Headers>.

=cut

sub header
{
  my $self = shift; 
  $self->{_headervals}->header(@_);
}


=item $h->header_field_names

Return the list of distinct names for the fields present in the header.
This method behaves exactly like the one in C<HTTP::Headers>.

=cut

sub header_field_names
{
  my $self = shift;
  $self->{_headervals}->header_field_names(@_);
}


=item $h->header_remove( $field, ...)

Remove the header fields with the specified names. This method behaves
exactly like the one in C<HTTP::Headers>.

=cut

sub header_remove
{
  my $self = shift;
  $self->{_headervals}->header_remove(@_);
}


=item $h->encode

Encode the WSP headers into a binary string.

=cut

sub encode
{
  my ($self, $input) = @_;

  my $httpheaders = ref($input) ? $input : $self->{_headervals}->clone;

  my $str = '';
  foreach my $hname ($httpheaders->header_field_names)
  {
    my $hvalue = $httpheaders->header($hname);

    # lookup the field definition
    my $field = $self->_find_valdef('name', $hname, $self->{_headerdefs});
    if (ref($field))
    {
      # this is a well-known field
      my $func = $field->{pack_function};
      Carp::croak("Encoding of '$field->{name}' is not implemented")
        unless $func;

      my @vals;
      # check if we allow lists
      if ($field->{list} eq LIST)
      {
        @vals = &parse_line(",", 1, $hvalue);  
      } elsif ($field->{list} eq BRKLIST) {
        @vals = &parse_line(";", 1, $hvalue);  
      } else {
        push @vals, $hvalue;
      }

      # process each value
      foreach my $val (@vals)
      {
        $val = &trimwhitespace($val);
        # encode field name and field value
        $str .= $self->pack_short_integer($field->{id});
        $str .= $self->$func($val);
      }

    } else {
      # this is an Application-header 
      $str .= $self->pack_token_text($hname);
      $str .= $self->pack_text_string($hvalue);
    }
  }
  return $str;
}


=item WSP::Headers->decode( $binstr )

Decode WSP headers from a binary string.

=cut

sub decode
{
  my ($ref, $str) = @_;
  my $self = ref($ref) ? $ref : $ref->new;
  
  $self->clear;
  while (length($str))
  {
    my $c = unpack('C', $str);
    my ($hname, $hvalue);

    if ($c == 127) {
      # this is a Shift-delimiter, Page-Identity follows
      $str = substr($str, 0, 2);

    } elsif (($c > 0) && ($c < 32)) {
      # this is a Short-cut-shift-delimiter
      $str = substr($str, 0, 1);

    } elsif ($c & 0x80) {
      # this is a Well-known-header, lookup field definition
      (my $hid, $str) = $self->unpack_short_integer($str);
      my $field = $self->_find_valdef('id', $hid, $self->{_headerdefs});
      Carp::croak("Unknown header : 0x" . sprintf("%.2X", $hid))
        unless ref($field);

      # extract and process value
      (my $type, my $data, $str) = $self->unpack_field_value($str);
      my $func = $field->{unpack_function};
      $hvalue = $self->$func($data);
      $hname = $field->{name};

      # check whether we need to re-assemble
      my $old = $self->header($hname);
      if (defined($old) && $field->{list}) {
        my $sep = ($field->{list} == LIST) ? "," : ";";
	$hvalue = "$old$sep $hvalue";
      }
      $self->header($hname, $hvalue);
    } else {
      # this is an Application-header 
      ($hname, $str) = $self->unpack_token_text($str);
      ($hvalue, $str) = $self->unpack_text_string($str);
      $self->header($hname, $hvalue);
    }
  }
  return $self;
}


# find a value definition
sub _find_valdef
{
  my ($self, $search_field, $search_value, $vals) = @_;
 
  my @valscpy = @{$vals};
  while (my $line = pop @valscpy)
  {
    my $hdr = WSP::Headers::Field->new($line);

    if ( (($search_field eq 'id')&&($hdr->{$search_field} == $search_value)) ||
         (($search_field ne 'id')&&(uc($hdr->{$search_field}) eq uc($search_value))) )
    {
      return $hdr;
    }
  }
  return;
}


# separate media and parameters
sub parse_parameters
{
  my ($self, $val) = @_;
  $val =~ /^([^;]+)(\s*;(.*))?$/
    or Carp::croak("Malformed header value : '$val'");
  my ($media, $pstring) = ($1, $3);

  # pack the parameters
  my @pbits = &parse_line(";", 1, $pstring);
  my $params;
  foreach my $param (@pbits)
  {
    $param = trimwhitespace($param);
    my ($pn, $pv) = split /=/, $param;
    $params->{$pn} = $pv;
  }
  return ($media, $params);
} 


# unwrap continuation lines
# see RFC2616
sub unwrap_lines
{
  my ($self, $string) = @_;
  $string =~ s/\r\n[ \t]+/ /g;
  return $string;
}


# determine whether a string is a token string
# see RFC2616 section 2.2
sub is_token
{
  my ($self, $string) = @_;
  return ($string =~ /^$reg_token+$/);
}


# determine whether a string is TEXT
# see RFC2616 section 2.2
sub is_TEXT
{
  my ($self, $string) = @_;
 
  # simplify continuation lines
  $string = $self->unwrap_lines($string);

  return ($string =~ /^[\x20-\x7E\x80-\xFF]*$/);
}


# determine whether a string is a quoted-string
# see RFC2616 section 2.2
sub is_quoted_string
{
  my ($self, $string) = @_;

  # check we have the outter quotes, then remove them
  return 0 unless ($string =~ /^"(.*)"$/s);
  $string = $1;

  # the remainder must be a TEXT without quotes
  return ($string !~ /"/) && $self->is_TEXT($string);
}


##
##  PACKING FUNCTIONS
##


# pack a short integer
# see OMA-WAP-TS-WSP section 8.4.2.1
sub pack_short_integer
{
  my ($self, $val) = @_;
  Carp::croak("The value '$val' is not a short integer")
    if (($val < 0) or ($val > $SHORTINT_MAX)); 
  
  return pack('C', 0x80 | $val); 
}


# pack a long integer
# see OMA-WAP-TS-WSP section 8.4.2.1
sub pack_long_integer
{
  my ($self, $ival) = @_;
  
  # work with BigInt
  my $bval = Math::BigInt->new($ival);
  Carp::croak("The value '$bval' is not a long integer")
    if (($bval < 0) or ($bval > $LONGINT_MAX));

  my $pck = '';
  do
  {
    my $oct = $bval & 0xFF;
    $bval = $bval >> 8;
    $pck = pack('C', $oct) . $pck;
  } while ($bval > 0);

  return pack('C', length($pck)) . $pck;
}


# pack an 8bit unsigned integer
sub pack_uint8
{
  my ($self, $val) = @_;
  return pack("C", $val);
}


# pack a variable length unsigned integer
# see OMA-WAP-TS-WSP section 8.1.2
sub pack_uintvar
{
  my ($self, $ival) = @_;
 
  # work with BigInt
  my $bval = Math::BigInt->new($ival);
  Carp::croak("The value '$bval' is not a uintvar")
    if (($bval < 0) or ($bval > $UINTVAR_MAX));
  
  my $pck = '';
  do
  {
    my $sept = $bval & 0x7F;
    $bval = $bval >> 7;
    $pck = pack('C', $sept | ((length($pck) > 0) ? 0x80 : 0) ) . $pck;
  } while ($bval > 0);
  
  return $pck;
}


# pack a Value-length
# see OMA-WAP-TS-WSP section 8.4.2.2
sub pack_value_length
{
  my ($self, $len) = @_;

  if ($len < 31) 
  {
    return pack('C', $len);
  } else {
    return "\x1F" . $self->pack_uintvar($len);
  }
}

# pack a Token-text
# see OMA-WAP-TS-WSP section 8.4.2.1
sub pack_token_text
{
  my ($self, $str) = @_;
  Carp::croak("The string '$str' is not a token")
    unless $self->is_token($str);

  return pack("Z*", $str);
}


# pack a Text-string
# see OMA-WAP-TS-WSP section 8.4.2.1
sub pack_text_string
{
  my ($self, $str) = @_;
  Carp::croak("The string '$str' is not TEXT")
    unless $self->is_TEXT($str); 
  
  my $f = substr($str, 0, 1);
  if (ord($f) > 127)
  {
    return pack("CZ*", 0x7F, $str);
  } else {
    return pack("Z*", $str);
  }
}


# pack a Quoted-string
# see OMA-WAP-TS-WSP section 8.4.2.1
sub pack_quoted_string
{
  my ($self, $str) = @_;
  Carp::croak("The string '$str' is not a quoted string")
    unless $self->is_quoted_string($str);

  $str =~ s/^"(.*)"$/$1/;
  return pack("CZ*", 0x22, $str);
}


# pack a No-value
# see OMA-WAP-TS-WSP section 8.4.2.3
sub pack_no_value
{
  my ($self, $val) = @_;
  Carp::croak("The value '$val' is not a No-value")
    if (length($val));
  return "\x00";
}


# pack a Text-value
# see OMA-WAP-TS-WSP section 8.4.2.3
sub pack_text_value
{
  my ($self, $val) = @_;

  # if the value is empty, pack a No-value
  return $self->pack_no_value if !length($val);

  # otherwise, if this is Token-text, pack it as such
  return $self->pack_token_text if $self->is_token($val);

  # the only possibility left is a Quoted-string
  Carp::croak("The value '$val' is not a Text-value")
    unless $self->is_quoted_string($val);
  $self->pack_quoted_string($val);
}


# pack an Integer-value
# see OMA-WAP-TS-WSP section 8.4.2.3
sub pack_integer_value
{
  my ($self, $ival) = @_;
  my $bval = Math::BigInt->new($ival);
  if ($bval <= $SHORTINT_MAX) {
    return $self->pack_short_integer($ival);
  } else {
    return $self->pack_long_integer($ival);
  }
}


# pack a Date-value
# see OMA-WAP-TS-WSP section 8.4.2.3
sub pack_date_value
{
  my ($self, $str) = @_;
  my $secs = str2time($str);
  $self->pack_long_integer($secs);
}


# pack a Q-value
# see OMA-WAP-TS-WSP section 8.4.2.3
sub pack_q_value
{
  my ($self, $val) = @_;
  Carp::croak("Invalid Q-value : $val")
    unless (($val >= 0)&&($val < 1)&&(floor($val * 1000) == ($val * 1000)));

  if (floor($val * 100) == ($val * 100))
  {
    return $self->pack_uintvar($val * 100 + 1);
  } else {
    return $self->pack_uintvar($val * 1000 + 100);
  }
}


# pack a Well-known charset
sub pack_well_known_charset
{
  my ($self, $val) = @_;
  my $ival = $self->encode_well_known_value($val, $WSP_CHARSETS);
  Carp::croak("Not a well-known charset : $val")
    unless defined($ival);
  return $self->pack_integer_value($ival);
}


# pack a Sec parameter value
sub pack_sec_value
{
  my ($self, $val) = @_;
  my $str = $self->pack_well_known_short($val, $WSP_SEC_PINS);
  Carp::croak("Unknown value for SEC parameter : '$val'")
    unless defined($str);
  return $str;
}


# pack a Version-value
# see OMA-WAP-TS-WSP section 8.4.2.3
sub pack_version_value
{
  my ($self, $version) = @_;
  if ($version =~ /^([0-7])(\.([0-9]|1[0-4]))?$/)
  {
    my ($major, $minor) = ($1, $3);
    defined($minor) or $minor = 15;
    return $self->pack_short_integer(($major << 4) + $minor);
  } else {
    return $self->pack_text_string($version);
  }
}


# encode a well-known value
sub encode_well_known_value
{
  my ($self, $val, $table) = @_;
 
  Carp::croak("Cannot encode a well-known value without a value table!")
    unless ref($table);

  return $table->{$val};
}


# decode a well-known value
sub decode_well_known_value
{
  my ($self, $ival, $table) = @_;
  
  Carp::croak("Cannot decode a well-known value without a value table!")
    unless ref($table);
  
  my %rev = reverse %{$table};

  Carp::croak("Cannot decode unknown value '$ival'")
    unless defined($rev{$ival});

  return $rev{$ival};
}


# pack a well-known value as a Short-integer
sub pack_well_known_short
{
  my ($self, $val, $table) = @_;
  my $ival = $self->encode_well_known_value($val, $table);
  return unless (defined($ival) && ($ival <= $SHORTINT_MAX));
  $self->pack_short_integer($ival);
}


# pack a well-known value or Token-text
sub pack_well_known_or_token
{
  my ($self, $val, $table) = @_;
  my $ival = $self->encode_well_known_value($val, $table);
  return $self->pack_integer_value($ival) if defined($ival);
  $self->pack_token_text($val);
}


# pack an Accept-xxx-value
sub _pack_accept_xxx_value
{
  my ($self, $val, $table, $noshort) = @_;
  my $str;
  
  # try well-known encoding
  if (!$noshort) {
    $str = $self->pack_well_known_short($val, $table);
    return $str if defined($str);
  }
  
  # separate media and parameters
  my ($media, $params) = $self->parse_parameters($val);

  # pack the media type
  my $imedia = $self->encode_well_known_value($media, $table);
  if (defined($imedia)) {
    $str = $self->pack_integer_value($imedia);
  } else {
    $str = $self->pack_text_string($media);
  }

  # pack the parameters
  $str .= $self->pack_parameters($params);
  return $self->pack_value_length(length($str)) . $str;
}


# pack an Accept-value
# see OMA-WAP-TS-WSP section 8.4.2.7
sub pack_accept_value
{
  my ($self, $val) = @_;
  $self->_pack_accept_xxx_value($val, $WSP_CONTENT_TYPES);
}


# pack an Accept-charset-value
# see OMA-WAP-TS-WSP section 8.4.2.8
sub pack_accept_charset_value
{
  my ($self, $val) = @_;
  $self->_pack_accept_xxx_value($val, $WSP_CHARSETS);
}


# pack an Accept-encoding-value
# see OMA-WAP-TS-WSP section 8.4.2.9
sub pack_accept_encoding_value
{
  my ($self, $val) = @_;
  $self->_pack_accept_xxx_value($val, $WSP_CONTENT_ENCODINGS);
}


# pack an Accept-language-value
# see OMA-WAP-TS-WSP section 8.4.2.10
sub pack_accept_language_value
{
  my ($self, $val) = @_;
  $self->_pack_accept_xxx_value($val, $WSP_LANGUAGES);
}


# pack an Accept-ranges-value
# see OMA-WAP-TS-WSP section 8.4.2.11
sub pack_accept_ranges_value
{
  my ($self, $val) = @_;
  $self->pack_well_known_or_token($val, $WSP_ACCEPT_RANGES); 
}


# pack an Allow-value
# see OMA-WAP-TS-WSP section 8.4.13
sub pack_allow_value
{
  my ($self, $val) = @_;
  my $str = $self->pack_well_known_short($val, $WSP_METHODS);
  Carp::croak("Unknown Allow-value : $val")
    unless defined($str);
  return $str;
}


# pack a Connection-value
# see OMA-WAP-TS-WSP section 8.4.16
sub pack_connection_value
{
  my ($self, $val) = @_;
  $self->pack_well_known_or_token($val, $WSP_CONNECTIONS); 
}


# pack an Content-encoding-value
# see OMA-WAP-TS-WSP section 8.4.18
sub pack_content_encoding_value
{
  my ($self, $val) = @_;
  $self->pack_well_known_or_token($val, $WSP_CONTENT_ENCODINGS); 
}


# pack an Content-language-value
# see OMA-WAP-TS-WSP section 8.4.20
sub pack_content_language_value
{
  my ($self, $val) = @_;
  $self->pack_well_known_or_token($val, $WSP_LANGUAGES); 
}


# pack a Content-MD5-value
# see OMA-WAP-TS-WSP section 8.4.22
sub pack_content_md5_value
{
  my ($self, $val) = @_;
  my $decoded = MIME::Base64::decode($val);
  return $self->pack_value_length(16) . pack("a16", $decoded);
}


# pack an Public-value
# see OMA-WAP-TS-WSP section 8.4.41
sub pack_public_value
{
  my ($self, $val) = @_;
  $self->pack_well_known_or_token($val, $WSP_METHODS); 
}


# pack a Content-disposition-value
# see OMA-WAP-TS-WSP section 8.4.53
sub pack_content_disposition_value
{
  my ($self, $val) = @_;
  $self->_pack_accept_xxx_value($val, $WSP_CONTENT_DISPOSITIONS, 1);
}


# pack parameters
sub pack_parameters
{
  my ($self, $params) = @_;

  my $str = '';
  foreach my $name (keys %{$params})
  {
    my $value = $params->{$name};
    my $param = $self->_find_valdef('name', $name, $self->{_paramdefs});
    if (ref($param))
    {
      # this is a Typed-parameter
      $str .= $self->pack_short_integer($param->{id});
      
      # encode the field value
      my $func = $param->{pack_function};
      $str .= $self->$func($value);
    } else {
      # this is an Untyped-parameter
      $str .= $self->pack_token_text($name);
      $str .= $self->pack_text_string($value);
    }
  }
  return $str;
}



##
##  UNPACKING FUNCTIONS
##


# unpack a short integer
# see OMA-WAP-TS-WSP section 8.4.2.1
sub unpack_short_integer
{
  my ($self, $str) = @_;
  my $val = unpack('C', $str);
  Carp::croak("Invalid short integer")
    unless ($val & 0x80);
  
  $self->_unpack_result($val & 0x7F, substr($str, 1));
}


# unpack a long integer
# see OMA-WAP-TS-WSP section 8.1.2
sub unpack_long_integer
{
  my ($self, $str) = @_;
  my $val = Math::BigInt->new(0);

  my $len = unpack('C', $str);
  $str = substr($str, 1);
  Carp::croak("Invalid long integer")
    unless($len <= 30);
    
  for (my $i = 0; $i < $len; $i++)
  {
    $val = ($val << 8) + unpack('C', $str);
    $str = substr($str, 1);
  }

  $self->_unpack_result($val, $str);
}


# unpack a variable length unsigned integer
# see OMA-WAP-TS-WSP section 8.1.2
sub unpack_uintvar
{
  my ($self, $str) = @_;
  my $val = Math::BigInt->new(0);
  my $char;

  do {
    $char = unpack('C', $str);
    $str = substr($str, 1);
    $val = ($val << 7) + ($char & 0x7F);
  } while ($char & 0x80);

  $self->_unpack_result($val, $str);
}


# unpack a Value-length
# see OMA-WAP-TS-WSP section 8.4.2.2
sub unpack_value_length
{
  my ($self, $str) = @_;
  my $val = Math::BigInt->new;
  
  # check whether we have a length quote
  if (substr($str, 0, 1) eq "\x1F")
  {
    $str = substr($str, 1);
    ($val, $str) = $self->unpack_uintvar($str); 
  } else {
    $val = unpack('C', $str);
    $str = substr($str, 1);
  }
  $self->_unpack_result($val, $str);
}


# unpack a Token-text
# see OMA-WAP-TS-WSP section 8.4.2.1
sub unpack_token_text
{
  my ($self, $str) = @_;

  my $val = unpack("Z*", $str);
  
  $self->_unpack_result($val, substr($str, length($val) + 1));
}


# unpack a Text-string
# see OMA-WAP-TS-WSP section 8.4.2.1
sub unpack_text_string
{
  my ($self, $str) = @_;

  # if the first character is the Quote character, remove it
  $str = substr($str, 1) if (substr($str, 0, 1) eq "\x7F");

  # unpack the string
  my $val = unpack("Z*", $str);
  Carp::croak("The unpacked string '$val' is not TEXT")
    unless $self->is_TEXT($val); 
  
  $self->_unpack_result($val, substr($str, length($val) + 1));
}


# unpack a Quoted-string
# see OMA-WAP-TS-WSP section 8.4.2.1
sub unpack_quoted_string
{
  my ($self, $str) = @_;

  # remove quote character
  Carp::croak("The string '$str' does not represent a Quoted-string")
    unless (substr($str, 0, 1) eq '"');
  $str = substr($str, 1);

  # unpack the string
  my $val = unpack("Z*", $str);
  Carp::croak("The unpacked string '$val' is not TEXT")
    unless $self->is_TEXT($val); 
 
  $self->_unpack_result($val, substr($str, length($val) + 1));
}


# unpack a No-value
# see OMA-WAP-TS-WSP section 8.4.2.3
sub unpack_no_value
{
  my ($self, $str) = @_;
  my $c = unpack('C', $str);
  Carp::croak("No-value can only be octet 0!")
    unless ($c == 0);
  
  $self->_unpack_result(undef, substr($str, 1));
}


# unpack a Text-value
# see OMA-WAP-TS-WSP section 8.4.2.3
sub unpack_text_value
{
  my ($self, $str) = @_;
  my $c = unpack('C', $str);
  
  # check whether this is a No-value
  return $self->unpack_no_value($str) if ($c == 0);

  # otherwise try Quoted-string
  return $self->unpack_quoted_string($str) if ($c == 0x34);

  # the only possibility left is a Token-text
  $self->unpack_token_text($str);
}


# unpack an Integer-value
# see OMA-WAP-TS-WSP section 8.4.2.3
sub unpack_integer_value
{
  my ($self, $str) = @_;
  my $c = unpack('C', $str);
  if ($c < 31) {
    return $self->unpack_long_integer($str);
  } elsif ($c > 127) {
    return $self->unpack_short_integer($str);
  } else {
    Carp::croak("Bad Integer-value");
  }
}


# unpack a Date-value
# see OMA-WAP-TS-WSP section 8.4.2.3
sub unpack_date_value
{
  my ($self, $str) = @_;
  my $secs;
  ($secs, $str) = $self->unpack_long_integer($str);
  $self->_unpack_result(time2str($secs), $str);
}


# unpack a Q-value
# see OMA-WAP-TS-WSP section 8.4.2.3
sub unpack_q_value
{
  my ($self, $str) = @_;
  my ($qv, $val);
  ($qv, $str) = $self->unpack_uintvar($str);
  $qv = "$qv";
  $val = ($qv > 100) ? (($qv - 100) / 1000) : ($qv - 1) / 100;
  $self->_unpack_result($val, $str);
}


# unpack a Well-known charset
sub unpack_well_known_charset
{
  my ($self, $str) = @_;
  (my $ival,$str) = $self->unpack_integer_value($str);
  my $val = $self->decode_well_known_value($ival, $WSP_CHARSETS);
  $self->_unpack_result($val, $str);
}


# unpack a Sec parameter value
sub unpack_sec_value
{
  my ($self, $str) = @_;
  (my $val, $str) = $self->unpack_well_known_short($str, $WSP_SEC_PINS);
  $self->_unpack_result($val, $str);
}


# unpack a Version-value
# see OMA-WAP-TS-WSP section 8.4.2.3
sub unpack_version_value
{
  my ($self, $str) = @_;
  my $c = unpack('C', $str);
  my $val;
  if ($c & 0x80) 
  {
    ($val, $str) = $self->unpack_short_integer($str);
    my $major = ($val & 0x70) >> 4;
    my $minor = $val & 0x0F;
    $val = ($minor == 15) ? $major : "$major.$minor";
  } else {
    ($val, $str) = $self->unpack_text_string($str);
  }
  $self->_unpack_result($val, $str);
}


# unpack a well-known Short-integer value
sub unpack_well_known_short
{
  my ($self, $str, $table) = @_;
  (my $ival, $str)  = $self->unpack_short_integer($str);
  my $valstr = $self->decode_well_known_value($ival, $table);
  $self->_unpack_result($valstr, $str);
}

# unpack a well-known value or token-text
sub unpack_well_known_or_token
{
  my ($self, $str, $table) = @_;
  my $val;

  # unpack value
  (my $type, my $data, $str) = $self->unpack_field_value($str);
  if ($type == FIELD_VALUE_ENCODED || $type == FIELD_VALUE_DATA)
  {
    my $ival = $self->unpack_integer_value($data);
    $val = $self->decode_well_known_value($ival, $table);
  } elsif ($type == FIELD_VALUE_STRING) {
    $val = $self->unpack_token_text($data);
  }
  $self->_unpack_result($val, $str);
}


# unpack an Accept-xxx-value
sub _unpack_accept_xxx_value
{
  my ($self, $str, $table) = @_;
  my $val;

  # unpack value
  (my $type, my $data, $str) = $self->unpack_field_value($str);
  if ($type == FIELD_VALUE_ENCODED)
  {
    $val = $self->unpack_well_known_short($data, $table);
  } elsif ($type == FIELD_VALUE_STRING) {
    $val = $self->unpack_text_string($data);
  } elsif ($type == FIELD_VALUE_DATA) {
    ($val, $data) = $self->unpack_value_length($data);
    ($type, my $media, $data) = $self->unpack_field_value($data);
    if ($type == FIELD_VALUE_STRING) {
      $val = $self->unpack_text_string($media);
    } else {
      my $imedia = $self->unpack_integer_value($media);
      $val = $self->decode_well_known_value($imedia, $table);
    }

    # unpack the parameters
    my $params = $self->unpack_parameters($data);
    foreach my $param (keys %{$params})
    {
      $val .= "; $param=$params->{$param}";
    }
  }
  $self->_unpack_result($val, $str);
}

# pack an Accept-value
# see OMA-WAP-TS-WSP section 8.4.2.7
sub unpack_accept_value
{
  my ($self, $str) = @_;
  $self->_unpack_accept_xxx_value($str, $WSP_CONTENT_TYPES);
}


# unpack an Accept-charset-value
# see OMA-WAP-TS-WSP section 8.4.2.8
sub unpack_accept_charset_value
{
  my ($self, $str) = @_;
  $self->_unpack_accept_xxx_value($str, $WSP_CHARSETS);
}


# unpack an Accept-encoding-value
# see OMA-WAP-TS-WSP section 8.4.2.9
sub unpack_accept_encoding_value
{
  my ($self, $str) = @_;
  $self->_unpack_accept_xxx_value($str, $WSP_CONTENT_ENCODINGS);
}


# unpack an Accept-language-value
# see OMA-WAP-TS-WSP section 8.4.2.10
sub unpack_accept_language_value
{
  my ($self, $str) = @_;
  $self->_unpack_accept_xxx_value($str, $WSP_LANGUAGES);
}

# pack an Accept-ranges-value
# see OMA-WAP-TS-WSP section 8.4.2.11
sub unpack_accept_ranges_value
{
  my ($self, $str) = @_;
  $self->unpack_well_known_or_token($str, $WSP_ACCEPT_RANGES);
}


# pack an Allow-value
# see OMA-WAP-TS-WSP section 8.4.13
sub unpack_allow_value
{
  my ($self, $str) = @_;
  $self->unpack_well_known_short($str, $WSP_METHODS);
}


# unpack a Connection-value
# see OMA-WAP-TS-WSP section 8.4.16
sub unpack_connection_value
{
  my ($self, $str) = @_;
  $self->unpack_well_known_or_token($str, $WSP_CONNECTIONS);
}


# unpack an Content-encoding-value
# see OMA-WAP-TS-WSP section 8.4.18
sub unpack_content_encoding_value
{
  my ($self, $str) = @_;
  $self->unpack_well_known_or_token($str, $WSP_CONTENT_ENCODINGS);
}


# unpack an Content-language-value
# see OMA-WAP-TS-WSP section 8.4.20
sub unpack_content_language_value
{
  my ($self, $str) = @_;
  $self->unpack_well_known_or_token($str, $WSP_LANGUAGES);
}


# unpack a Content-MD5-value
# see OMA-WAP-TS-WSP section 8.4.22
sub unpack_content_md5_value
{
  my ($self, $str) = @_;
  (my $len, $str) = $self->unpack_value_length($str);
  Carp::croak("Content-MD5 length must be 16, not $len")
    unless ($len == 16);
  my $val = MIME::Base64::encode(unpack("a16", $str));
  chomp $val;
  $self->_unpack_result($val, substr($str, 16));
}


# unpack a Public-value
# see OMA-WAP-TS-WSP section 8.4.41
sub unpack_public_value
{
  my ($self, $str) = @_;
  $self->unpack_well_known_or_token($str, $WSP_METHODS);
}


# unpack a Content-disposition-value
# see OMA-WAP-TS-WSP section 8.4.53
sub unpack_content_disposition_value
{
  my ($self, $str) = @_;
  $self->_unpack_accept_xxx_value($str, $WSP_CONTENT_DISPOSITIONS, 1);
}


# unpack WSP parameters
sub unpack_parameters
{
  my ($self, $str) = @_;

  my $params;
  while (length($str))
  {
    my $c = unpack('C', $str);
    if ($c < 32) {
      Carp::croak("Unexpected CTRL in parameter name");
    } elsif ($c & 0x80) {
      # this is a Typed-parameter
      (my $id, $str) = $self->unpack_short_integer($str);
      my $def = $self->_find_valdef('id', $id, $self->{_paramdefs});
      Carp::croak("Unknown parameter : 0x" . sprintf("%.2X", $id))
        unless ref($def);
      my $name = $def->{name};
      
      # extract and process value
      my $func = $def->{unpack_function};
      ($params->{$name},$str) = $self->$func($str);
    } else {
      # this is an Untyped-parameter
      (my $name, $str) = $self->unpack_token_text($str);
      ($params->{$name}, $str) = $self->unpack_text_string($str);
    }
  }
  $self->_unpack_result($params, $str);
}


# generic function to unpack a WSP header value, without interpreting it
# see OMA-WAP-TS-WSP section 8.4.1.2
sub unpack_field_value
{
  my ($self, $str) = @_;
  my ($data, $type);
  
  # determine the type and length of the header value
  # see OMA-WAP-TS-WSP section 8.4.1.2
  my $c = unpack('C', $str);
  if ($c == 0) {
    $type = FIELD_VALUE_NONE;
    $data = substr($str, 0, 1);
    $str = substr($str, 1);

  } elsif ($c < 32) {
    # we have a Value-length, then data
    # this is General-form encoding
    $type = FIELD_VALUE_DATA;
    my ($hlen,$tmp) = $self->unpack_value_length($str);
    $hlen += length($str) - length($tmp);
    $data = substr($str, 0, $hlen);
    $str = substr($str, $hlen);

  } elsif ($c > 127) {
    # this is an encoded 7-bit value
    $type = FIELD_VALUE_ENCODED;
    $data = substr($str, 0, 1);
    $str = substr($str, 1);

  } else {
    # we have a Text-string terminated with 0
    $type = FIELD_VALUE_STRING;
    ($data, $str) = $self->unpack_text_string($str);
    $data .= "\x00";

  }
  return ($type, $data, $str);
}


sub _unpack_result
{
  my ($self, $val, $rest) = @_;
  return ($val, $rest) if wantarray;
  return $val;
}


sub hexsprint
{
  my ($self, $a) = @_;
  my $chunklen = 16;

  my $str = '';
  while (length($a))
  {
    my $chunk = substr($a, 0, $chunklen);
    $a = substr($a, length($chunk));

    for (my $i = 0; $i < length($chunk); $i++)
    {
      my $b = unpack("C", substr($chunk, $i, 1));
      $str .= sprintf("%.2X ", $b);
    }
    #$str .= "\t$chunk";
    $str .= "\n";
  }
  chomp($str);
  return $str;
}


sub hexprint
{
  my ($self, $a) = @_;
  print STDERR $self->hexsprint($a) . "\n";
}

1;

