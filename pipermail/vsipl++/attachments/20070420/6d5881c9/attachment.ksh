Index: ChangeLog
===================================================================
--- ChangeLog	(revision 169305)
+++ ChangeLog	(working copy)
@@ -1,3 +1,8 @@
+2007-04-20  Jules Bergmann  <jules@codesourcery.com>
+
+	* configure.ac: Probe for exception support by compiler.
+	  Disable builtin ATLAS when cross-compiling.
+
 2007-04-19  Jules Bergmann  <jules@codesourcery.com>
 
 	* svn:externals: Use vpp-13-fontsize branch for csl-docbook.
Index: configure.ac
===================================================================
--- configure.ac	(revision 169305)
+++ configure.ac	(working copy)
@@ -109,7 +109,7 @@
 AC_ARG_ENABLE([exceptions],
   AS_HELP_STRING([--disable-exceptions],
                  [Don't use C++ exceptions.]),,
-  [enable_exceptions=yes])
+  [enable_exceptions=probe])
 
 # By default we will probe for MPI and use it if it exists.  If it
 # does not exist, we will configure a serial VSIPL++ library.
@@ -593,11 +593,45 @@
 
 AC_SUBST(AR)
 
-if test "$enable_exceptions" != "yes"; then
-    AC_DEFINE_UNQUOTED(VSIP_HAS_EXCEPTIONS, 0,
-      [Define not to use C++ exceptions.])
+if test "$enable_exceptions" != "no"; then
+  AC_MSG_CHECKING([for exceptions])
+  AC_COMPILE_IFELSE([
+    #include <stdexcept>
+
+    void function() throw (std::bad_alloc)
+    { throw std::bad_alloc(); }
+
+    int main()
+    {
+      int i = 0;
+      try { function(); } catch(std::bad_alloc e) { i = 1; }
+    }
+    ],
+    [AC_MSG_RESULT(yes)
+     has_exceptions=1],
+    [AC_MSG_RESULT(no)
+     has_exceptions=0
+     if test "$enable_exceptions" = "yes"; then
+       AC_MSG_ERROR([Exceptions enabled (--enable-exceptions), but
+                     not supported by the compiler]) ])
+     fi
+else
+  has_exceptions=1
 fi
 
+if test "$enable_exceptions" = "probe"; then
+  if test "$has_exceptions" = "1"; then
+    exception_status="probe -- found"
+  else
+    exception_status="probe -- not found"
+  fi
+else
+  exception_status=$enable_exceptions
+fi
+
+AC_DEFINE_UNQUOTED(VSIP_HAS_EXCEPTIONS, $has_exceptions,
+                   [Define to 1 to use C++ exceptions.])
+
 # Weed out buggy compilers and/or C++ runtime libraries.
 # This is not an AC_CACHE_CHECK because it's likely to grow, so
 # the cache would become invalid.
@@ -1075,7 +1109,7 @@
   done
 
   if test "$pas_found" == "no"; then
-    if test "$with_lapack" != "probe"; then
+    if test "$with_pas" != "probe"; then
       AC_MSG_ERROR([PAS enabled but no library found])
     fi
     AC_MSG_RESULT([No PAS library found])
@@ -1784,7 +1818,13 @@
 
     lapack_packages="mkl7 mkl5"
   elif test "$with_lapack" = "yes" -o "$with_lapack" = "probe"; then
-    lapack_packages="atlas generic1 generic2 builtin"
+    echo "HOST: $host  BUILD: $build"
+    if test "$host" != "$build"; then
+      # Can't cross-compile builtin atlas
+      lapack_packages="atlas generic1 generic2 simple-builtin"
+    else
+      lapack_packages="atlas generic1 generic2 builtin"
+    fi
   elif test "$with_lapack" == "generic"; then
     lapack_packages="generic1 generic2"
   elif test "$with_lapack" == "simple-builtin"; then
@@ -2467,7 +2507,7 @@
 AC_MSG_NOTICE(Summary)
 AC_MSG_RESULT([Build in maintainer-mode:                $maintainer_mode])
 AC_MSG_RESULT([Using config suffix:                     $suffix])
-AC_MSG_RESULT([Exceptions enabled:                      $enable_exceptions])
+AC_MSG_RESULT([Exceptions enabled:                      $exceptions_status])
 AC_MSG_RESULT([With mpi enabled:                        $enable_mpi])
 AC_MSG_RESULT([With PAS enabled:                        $enable_pas])
 if test "$PAR_SERVICE" != "none"; then
