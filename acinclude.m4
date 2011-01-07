dnl Check the prefix
AC_DEFUN(AC_CHECK_PREFIX,
[
AC_PREFIX_DEFAULT(/usr/local)
AC_MSG_CHECKING([for prefix])
if test "x$prefix" = "xNONE"; then
  prefix=$ac_default_prefix
  ac_configure_args="$ac_configure_args --prefix $prefix"
fi
AC_MSG_RESULT($prefix)
])

