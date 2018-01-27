Index: ChangeLog
===================================================================
--- ChangeLog	(revision 170727)
+++ ChangeLog	(working copy)
@@ -1,3 +1,9 @@
+2007-05-09  Jules Bergmann  <jules@codesourcery.com>
+
+	* configure.ac: Fix typo in check for std::isfinite.
+	* examples/mercury/mcoe-setup.sh: Enable exceptions (rather than
+	  probe) when exceptions="y".
+
 2007-05-08  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip/core/fns_elementwise.hpp (is_finite, is_nan, is_normal):
Index: configure.ac
===================================================================
--- configure.ac	(revision 170727)
+++ configure.ac	(working copy)
@@ -795,7 +795,7 @@
        AC_DEFINE_UNQUOTED(HAVE_STD_ISNORMAL, 1,
 		   [Define to 1 if you have the '$fcn' function.])
      fi],
-    [AC_MSG_ERROR([no])])
+    [AC_MSG_RESULT([no])])
 done
 
 
Index: examples/mercury/mcoe-setup.sh
===================================================================
--- examples/mercury/mcoe-setup.sh	(revision 170727)
+++ examples/mercury/mcoe-setup.sh	(working copy)
@@ -177,6 +177,7 @@
   cfg_flags="$cfg_flags --disable-exceptions"
 else
   cxxflags="$cxxflags $ex_on_flags"
+  cfg_flags="$cfg_flags --enable-exceptions"
 fi
 
 if test "x$extra_args" != "x"; then
