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

package MMS::Headers;

use strict;
use vars qw(@ISA);

use WSP::Headers;
use Carp ();

@ISA = qw(WSP::Headers);

our $MMS_HEADERS = [
[ 'Bcc',			0x01,		],
[ 'Cc',				0x02,		],
[ 'X-MMs-Content-Location',	0x03,		],
[ 'Content-Type',		0x04,		],
[ 'Date',			0x05,		],
[ 'X-MMs-Delivery-Report',	0x06,		],
[ 'X-Mms-Delivery-Time',	0x07,		],
[ 'X-Mms-Expiry',		0x08,		],
[ 'From',			0x09,		],
[ 'X-Mms-Message-Class',	0x0A,		],
[ 'Message-ID',			0x0B,		],
[ 'X-Mms-Message-Type',		0x0C,		],
[ 'X-Mms-MMS-Version',		0x0D,		],
[ 'X-Mms-Message-Size',		0x0E,		],
[ 'X-Mms-Priority',		0x0F,		],
[ 'X-Mms-Read-Report',		0x10,		],
[ 'X-Mms-Report-Allowed',	0x11,		],
[ 'X-Mms-Response-Status',	0x12,		],
[ 'X-Mms-Response-Text',	0x13,		],
[ 'X-Mms-Sender-Visibility',	0x14,		],
[ 'X-Mms-Status',		0x15,		],
[ 'Subject',			0x16,		],
[ 'To',				0x17,		],
[ 'X-Mms-Transaction-Id',	0x18,		],
[ 'X-Mms-Retrieve-Status',	0x19,		],
[ 'X-Mms-Retrieve-Text',	0x1A,		],
[ 'X-Mms-Read-Status',		0x1B,		],
[ 'X-Mms-Reply-Charging',	0x1C,		],
[ 'X-Mms-Reply-Charging-Deadline',	0x1D,		],
[ 'X-Mms-Reply-Charging-ID',	0x1E,		],
[ 'X-Mms-Charging-Size',	0x1F,		],
[ 'X-Mms-Previously-Sent-By',	0x20,		],
[ 'X-Mms-Previously-Sent-Date',	0x21,		],
[ 'X-Mms-Store',		0x22,		],
[ 'X-Mms-MM-State',		0x23,		],
[ 'X-Mms-MM-Flags',		0x24,		],
[ 'X-Mms-Store-Status',		0x25,		],
[ 'X-Mms-Store-Status-Text',	0x26,		],
[ 'X-Mms-Stored',		0x27,		],
[ 'X-Mms-Attributes',		0x28,		],
[ 'X-Mms-Totals',		0x29,		],
[ 'X-Mms-Mbox-Totals',		0x2A,		],
[ 'X-Mms-Quotas',		0x2B,		],
[ 'X-Mms-Mbox-Quotas',		0x2C,		],
[ 'X-Mms-Message-Count',	0x2D,		],
[ 'Content',			0x2E,		],
[ 'X-Mms-Start',		0x2F,		],
[ 'Additional-headers',		0x30,		],
[ 'X-Mms-Distribution-Indicator',	0x31,		],
[ 'X-Mms-Element-Descriptor',	0x32,		],
[ 'X-Mms-Limit',		0x33,		],
[ 'X-Mms-Recommended-Retrieval-Mode',	0x34,		],
[ 'X-Mms-Recommended-Retrieval-Mode-Text',	0x35,	],
[ 'X-Mms-Status-Text',		0x36,		],
[ 'X-Mms-Applic-ID',		0x37,		],
[ 'X-Mms-Reply-Applic-ID',	0x38,		],
[ 'X-Mms-Aux-Applic-Info',	0x39,		],
[ 'X-Mms-Content-Class',	0x3A,		],
[ 'X-Mms-DRM-Content',		0x3B,		],
[ 'X-Mms-Adaptation-Allowed',	0x3C,		],
[ 'X-Mms-Replace-ID',		0x3D,		],
[ 'X-Mms-Cancel-ID',		0x3E,		],
[ 'X-Mms-Cancel-Status',	0x3F,		],
];

sub new
{
  my $class = shift;

  # call the parent constructor
  my $self = $class->SUPER::new(@_);
  
  bless $self, $class;
  return $self;
}

1;


