Index: ChangeLog
===================================================================
--- ChangeLog	(revision 169787)
+++ ChangeLog	(working copy)
@@ -1,3 +1,9 @@
+2007-04-27  Jules Bergmann  <jules@codesourcery.com>
+
+	* configure.ac (PAS_HEAP_SIZE, PAS_SHARE_DYNAMIC_XFER): Alway define.
+	  (LDFLAGS): Fix bug when configuring for SAL that introduced empty
+	  -L option.
+
 2007-04-26  Jules Bergmann  <jules@codesourcery.com>
 
 	* scripts/char.pl: New file, characterization script.
Index: configure.ac
===================================================================
--- configure.ac	(revision 169646)
+++ configure.ac	(working copy)
@@ -1139,17 +1139,10 @@
     AC_MSG_RESULT([Using $pas_found for PAS])
     vsipl_par_service=2
     PAR_SERVICE=pas
-    AC_DEFINE_UNQUOTED(VSIP_IMPL_PAS_HEAP_SIZE, $enable_pas_heap_size,
-       [Define the heap size used inside the PAS backend.])
 
-    if test $enable_pas_share_dynamic_xfer = "yes"; then
-      enable_pas_share_dynamic_xfer=1
-    else
-      enable_pas_share_dynamic_xfer=0
-    fi
-    AC_DEFINE_UNQUOTED(VSIP_IMPL_PAS_SHARE_DYNAMIC_XFER,
-       $enable_pas_share_dynamic_xfer,
-       [Define to 1 to share a dynamic_xfer object, 0 otherwise.])
+    # The folling AC_DEFINEs are defined below:
+    #  - VSIP_IMPL_PAS_HEAP_SIZE
+    #  - VSIP_IMPL_PAS_SHARE_DYNAMIC_XFER
   fi
 
 elif test "$enable_mpi" == "openmpi"; then
@@ -1399,6 +1392,25 @@
     [Define to parallel service provided (0 == no service, 1 = MPI, 2 = PAS).])
 fi
 
+
+
+# These values are not used if PAS is not enabled (i.e. if PAR_SERVICE != 2).
+# They are always defined for binary packaging convenience.  This allows
+# the same acconfig.hpp to be used with/without PAS.
+
+AC_DEFINE_UNQUOTED(VSIP_IMPL_PAS_HEAP_SIZE, $enable_pas_heap_size,
+       [Define the heap size used inside the PAS backend.])
+
+if test $enable_pas_share_dynamic_xfer = "yes"; then
+  enable_pas_share_dynamic_xfer=1
+else
+  enable_pas_share_dynamic_xfer=0
+fi
+
+AC_DEFINE_UNQUOTED(VSIP_IMPL_PAS_SHARE_DYNAMIC_XFER,
+       $enable_pas_share_dynamic_xfer,
+       [Define to 1 to share a dynamic_xfer object, 0 otherwise.])
+
 #
 # Find the Mercury SAL library, if enabled.
 #
@@ -1431,11 +1443,10 @@
 
     # Find the library.
 
+    save_LDFLAGS="$LDFLAGS"
     if test -n "$with_sal_lib"; then
-      SAL_LDFLAGS="$with_sal_lib"
+      LDFLAGS="$LDFLAGS -L$with_sal_lib"
     fi
-    save_LDFLAGS="$LDFLAGS"
-    LDFLAGS="$LDFLAGS -L$SAL_LDFLAGS"
     AC_SEARCH_LIBS(vaddx, csal, [sal_found="yes"], [sal_found="no"])
 
     AC_MSG_CHECKING([for std::complex-compatible SAL-types.])
