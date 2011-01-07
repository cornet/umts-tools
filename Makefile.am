# $Id: Makefile.am,v 1.1 2003/05/03 11:42:40 sharky Exp $

SUBDIRS = @SUBDIRS@

EXTRA_DIST = Makefile.j-pkg Makefile.pkg FAQ install-win32.bat
GSM_SMS_SRC = /usr/share/perl5/GSM/SMS
GSM_SMS_DIST = $(distdir)/src/GSM/SMS

win32-dist: distdir
	ls $(GSM_SMS_SRC)
	mkdir -p $(GSM_SMS_DIST)
	cp $(GSM_SMS_SRC)/PDU.pm $(GSM_SMS_DIST)
	cp -ar $(GSM_SMS_SRC)/NBS $(GSM_SMS_DIST)
	$(AMTAR) chof - $(distdir) | GZIP=$(GZIP_ENV) gzip -c >$(distdir)_win32.tar.gz
	$(am__remove_distdir)
