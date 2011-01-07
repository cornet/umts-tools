include $(top_srcdir)/Makefile.pkg

SUBDIRS = DRM MMS NetPacket SMS UMTS WSP

bin_SCRIPTS = umts-answer.pl umts-drm.pl umts-dialer.pl umts-gui.pl umts-multipart.pl umts-phonebook.pl umts-p2klog.pl umts-sms.pl umts-wappush.pl

my_INSTDIR = $(my_PKGDATADIR)
my_INSTFILES += NetPacket.pm

my_EXTRA_DIST += $(bin_SCRIPTS) test-units.pl test-term.pl umts-pdp.pl 
