#!/usr/bin/perl

use Test::Harness;

$Test::Harness::Verbose = 1;

my @alltests = qw(
GPRS/SM.t
MMS/Headers.t
SMS/PDU/UserData.t
SMS/PDU/Deliver.t
SMS/PDU/Submit.t
WSP/Headers.t
WSP/PDU.t
WSP/PDU/ConfirmedPush.t
WSP/PDU/Disconnect.t
WSP/PDU/Push.t
WSP/PDU/Suspend.t
UMTS/Log.t
UMTS/Dummy.t
UMTS/NetPacket/Ethernet.t
UMTS/NetPacket/Pcap.t
UMTS/NetPacket/Pframe.t
UMTS/NetPacket/SMPP.t
UMTS/Phonebook/Entry.t
UMTS/SMS/Entry.t
UMTS/Terminal/Info.t
UMTS/Terminal/CallList.t
UMTS/Terminal/CallStatus.t
);

runtests(@alltests);
