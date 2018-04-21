Index: configure.ac
===================================================================
--- configure.ac	(revision 161188)
+++ configure.ac	(working copy)
@@ -736,6 +736,10 @@
   vsip_impl_fft_use_long_double=1
 fi
 
+if test "$ref_impl" = "1"; then
+  enable_fft="cvsip"
+fi
+
 fft_backends=`echo "${enable_fft}" | \
                 sed -e 's/[[ 	,]][[ 	,]]*/ /g' -e 's/,$//'`
 
@@ -1492,7 +1496,7 @@
   fi
 fi
 
-if test "x$with_cvsip_prefix" != x; then
+if test "$ref_impl" = "1" -o "x$with_cvsip_prefix" != x; then
   enable_cvsip="yes"
 fi
 if test "$enable_cvsip_fft" == "yes"; then
