SUBDIRS =

man_MANS = umts-answer.pl.1 umts-dialer.pl.1 umts-drm.pl.1 umts-gui.pl.1 umts-multipart.pl.1 umts-pdp.pl.1 umts-phonebook.pl.1 umts-p2klog.pl.1 umts-sms.pl.1 umts-wappush.pl.1

%.pl.1: $(top_srcdir)/src/%.pl
	pod2man $< $@

CLEANFILES = $(man_MANS)
EXTRA_DIST = $(man_MANS)

