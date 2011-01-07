include $(top_srcdir)/Makefile.pkg

SUBDIRS = DataLog Dummy GUI L3 Phonebook NetPacket PDP SMS Terminal Test

my_INSTDIR = $(my_PKGDATADIR)/UMTS
my_INSTFILES += App.pm Core.pm Dialer.pm Dummy.pm Log.pm L3.pm Phonebook.pm PDP.pm SMS.pm Terminal.pm Test.pm WBXML.pm

my_CLEANFILES += Core.pm
my_EXTRA_DIST += $(my_INSTFILES) Dummy.t Log.t $(addsuffix .in,$(my_CLEANFILES))
