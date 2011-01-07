dnl Process this file with autoconf to produce configure script

AC_INIT(acinclude.m4)
PACKAGE=umts-tools
PERLMOD=UMTS

dnl version number
VERSION=0.9.4

dnl
AM_INIT_AUTOMAKE($PACKAGE, $VERSION)
AC_SUBST(PACKAGE)
AC_SUBST(PERLMOD)
AC_SUBST(VERSION)

dnl Check prefix
AC_CHECK_PREFIX

dnl subdirectories
SUBDIRS="doc src"
AC_SUBST(SUBDIRS)
AC_CONFIG_SUBDIRS(SUBDIRS)

dnl output
AC_CONFIG_FILES([Makefile])
AC_CONFIG_FILES([doc/Makefile])
AC_CONFIG_FILES([doc/examples/Makefile])
AC_CONFIG_FILES([doc/html/Makefile])
AC_CONFIG_FILES([doc/man/Makefile])
AC_CONFIG_FILES([src/Makefile])
AC_CONFIG_FILES([src/DRM/Makefile])
AC_CONFIG_FILES([src/MMS/Makefile])
AC_CONFIG_FILES([src/NetPacket/Makefile])
AC_CONFIG_FILES([src/SMS/Makefile])
AC_CONFIG_FILES([src/SMS/PDU/Makefile])
AC_CONFIG_FILES([src/UMTS/Makefile])
AC_CONFIG_FILES([src/UMTS/DataLog/Makefile])
AC_CONFIG_FILES([src/UMTS/Dummy/Makefile])
AC_CONFIG_FILES([src/UMTS/GUI/Makefile])
AC_CONFIG_FILES([src/UMTS/L3/Makefile])
AC_CONFIG_FILES([src/UMTS/NetPacket/Makefile])
AC_CONFIG_FILES([src/UMTS/Phonebook/Makefile])
AC_CONFIG_FILES([src/UMTS/PDP/Makefile])
AC_CONFIG_FILES([src/UMTS/SMS/Makefile])
AC_CONFIG_FILES([src/UMTS/Terminal/Makefile])
AC_CONFIG_FILES([src/UMTS/Test/Makefile])
AC_CONFIG_FILES([src/WSP/Makefile])
AC_CONFIG_FILES([src/WSP/Headers/Makefile])
AC_CONFIG_FILES([src/WSP/PDU/Makefile])
AC_OUTPUT
