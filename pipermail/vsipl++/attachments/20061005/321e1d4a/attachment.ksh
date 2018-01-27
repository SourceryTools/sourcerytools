Index: configure.ac
===================================================================
--- configure.ac	(revision 150717)
+++ configure.ac	(working copy)
@@ -2032,58 +2032,57 @@
 #
 # Python frontend
 #
-echo "PYTHON $PYTHON"
-if test -n "$PYTHON" -a "$PYTHON" != yes; then
+if test "$enable_scripting" == "yes"; then
+  AC_SUBST(enable_scripting, 1)
+  if test -n "$PYTHON" -a "$PYTHON" != yes; then
 dnl  AC_CHECK_FILE($PYTHON,,AC_MSG_ERROR([Cannot find Python interpreter]))
 dnl else
-  AC_PATH_PROG(PYTHON, python2 python, python)
-fi
-PYTHON_INCLUDE=`$PYTHON -c "from distutils import sysconfig; print sysconfig.get_python_inc()"`
-PYTHON_EXT=`$PYTHON -c "from distutils import sysconfig; print sysconfig.get_config_var('SO')"`
+    AC_PATH_PROG(PYTHON, python2 python, python)
+  fi
+  PYTHON_INCLUDE=`$PYTHON -c "from distutils import sysconfig; print sysconfig.get_python_inc()"`
+  PYTHON_EXT=`$PYTHON -c "from distutils import sysconfig; print sysconfig.get_config_var('SO')"`
 
-case $build in
-CYGWIN*)
-  if test `$PYTHON -c "import os; print os.name"` = posix; then
-    PYTHON_PREFIX=`$PYTHON -c "import sys; print sys.prefix"`
-    PYTHON_VERSION=`$PYTHON -c "import sys; print '%d.%d'%(sys.version_info[[0]],sys.version_info[[1]])"`
-    PYTHON_LIBS="-L $PYTHON_PREFIX/lib/python$PYTHON_VERSION/config -lpython$PYTHON_VERSION"
+  case $build in
+  CYGWIN*)
+    if test `$PYTHON -c "import os; print os.name"` = posix; then
+      PYTHON_PREFIX=`$PYTHON -c "import sys; print sys.prefix"`
+      PYTHON_VERSION=`$PYTHON -c "import sys; print '%d.%d'%(sys.version_info[[0]],sys.version_info[[1]])"`
+      PYTHON_LIBS="-L $PYTHON_PREFIX/lib/python$PYTHON_VERSION/config -lpython$PYTHON_VERSION"
 dnl Cygwin doesn't have an -lutil, but some versions of distutils tell us to use it anyway.
 dnl It would be better to check for each library it tells us to use with AC_CHECK_LIB, but
 dnl to do that, we need the name of a function in each one, so we'll just hack -lutil out 
 dnl of the list.
-    PYTHON_DEP_LIBS=`$PYTHON -c "from distutils import sysconfig; import re; print re.sub(r'\\s*-lutil', '', sysconfig.get_config_var('LIBS') or '')"`
-  else dnl this is 'nt'
-    if test "$CXX" = "g++"; then
-      CFLAGS="-mno-cygwin $CFLAGS"
-      CXXFLAGS="-mno-cygwin $CXXFLAGS"
-      LDFLAGS="-mno-cygwin $LDFLAGS"
-      PYTHON_PREFIX=`$PYTHON -c "import sys; print sys.prefix"`
-      PYTHON_VERSION=`$PYTHON -c "import sys; print '%d%d'%(sys.version_info[[0]],sys.version_info[[1]])"`
-      PYTHON_LIBS="-L `cygpath -a $PYTHON_PREFIX`/Libs -lpython$PYTHON_VERSION"
+      PYTHON_DEP_LIBS=`$PYTHON -c "from distutils import sysconfig; import re; print re.sub(r'\\s*-lutil', '', sysconfig.get_config_var('LIBS') or '')"`
+    else dnl this is 'nt'
+      if test "$CXX" = "g++"; then
+        CFLAGS="-mno-cygwin $CFLAGS"
+        CXXFLAGS="-mno-cygwin $CXXFLAGS"
+        LDFLAGS="-mno-cygwin $LDFLAGS"
+        PYTHON_PREFIX=`$PYTHON -c "import sys; print sys.prefix"`
+        PYTHON_VERSION=`$PYTHON -c "import sys; print '%d%d'%(sys.version_info[[0]],sys.version_info[[1]])"`
+        PYTHON_LIBS="-L `cygpath -a $PYTHON_PREFIX`/Libs -lpython$PYTHON_VERSION"
+      fi
+      PYTHON_INCLUDE=`cygpath -a $PYTHON_INCLUDE`
+      PYTHON_DEP_LIBS=`$PYTHON -c "from distutils import sysconfig; print sysconfig.get_config_var('LIBS') or ''"`
     fi
-    PYTHON_INCLUDE=`cygpath -a $PYTHON_INCLUDE`
-    PYTHON_DEP_LIBS=`$PYTHON -c "from distutils import sysconfig; print sysconfig.get_config_var('LIBS') or ''"`
-  fi
-  LDSHARED="$CXX -shared"
+    LDSHARED="$CXX -shared"
+    PYTHON_LIBS="$PYTHON_LIBS $PYTHON_DEP_LIBS"
+    ;;
+  *)
+    LDSHARED="$CXX -shared"
+    ;;
+  esac
+
   PYTHON_LIBS="$PYTHON_LIBS $PYTHON_DEP_LIBS"
-  ;;
-*)
-  LDSHARED="$CXX -shared"
-  ;;
-esac
 
-PYTHON_LIBS="$PYTHON_LIBS $PYTHON_DEP_LIBS"
+  AC_SUBST(PYTHON)
+  AC_SUBST(PYTHON_CPP, "-I $PYTHON_INCLUDE")
+  AC_SUBST(PYTHON_LIBS)
+  AC_SUBST(PYTHON_EXT)
 
-AC_SUBST(PYTHON)
-AC_SUBST(PYTHON_CPP, "-I $PYTHON_INCLUDE")
-AC_SUBST(PYTHON_LIBS)
-AC_SUBST(PYTHON_EXT)
+  AC_SUBST(LDSHARED)
 
-AC_SUBST(LDSHARED)
-
-AC_LANG(C++)
-if test "$enable_scripting" == "yes"; then
-  AC_SUBST(enable_scripting, 1)
+  AC_LANG(C++)
   if test -n "$with_boost_prefix"; then
     BOOST_CPPFLAGS="-I$with_boost_prefix/include"
     BOOST_LDFLAGS="-L$with_boost_prefix/lib"
