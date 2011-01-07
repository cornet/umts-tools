include $(top_srcdir)/Makefile.pkg

SUBDIRS =

GENHTMLFILES = umts-answer.html umts-dialer.html umts-drm.html umts-gui.html umts-multipart.html umts-phonebook.html umts-p2klog.html umts-sms.html umts-wappush.html

my_INSTDIR = $(my_PKGDOCDIR)/html
my_INSTFILES += index.html $(GENHTMLFILES)
my_CLEANFILES += $(GENHTMLFILES) *.tmp

%.html: $(top_srcdir)/src/%.pl
	pod2html --infile=$< --outfile=$@
	rm -f *.tmp

