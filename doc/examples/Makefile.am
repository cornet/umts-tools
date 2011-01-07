include $(top_srcdir)/Makefile.pkg

SUBDIRS = 

XMLFILES = wap-prov10.xml wap-prov10-delete.xml wap-si.xml wap-si-long.xml wap-sl.xml drm-jpg-sd-10count.xml
WBXMLFILES= $(XMLFILES:.xml=.wbxml)

my_INSTDIR = $(my_PKGDOCDIR)/examples
my_INSTFILES += $(XMLFILES) $(WBXMLFILES) drm-jpg-clear.jpg drm-jpg-fl.dm drm-jpg-sd-10count.dcf config
my_CLEANFILES += $(WBXMLFILES)

%.wbxml: %.xml
	xml2wbxml -o $@ $<
