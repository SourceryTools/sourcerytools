Index: ChangeLog
===================================================================
--- ChangeLog	(revision 181513)
+++ ChangeLog	(working copy)
@@ -1,3 +1,8 @@
+2007-10-09  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* configure.ac: Test for SAL's vconvert_s8_f32x function signature.
+	* src/vsip/opt/sal/elementwise.hpp: Adjust.
+
 2007-09-10  Stefan Seefeld  <stefan@codesourcery.com>
 
 	* configure.ac: Fix option-default logic for --with-lapack.
Index: configure.ac
===================================================================
--- configure.ac	(revision 181513)
+++ configure.ac	(working copy)
@@ -577,7 +577,7 @@
   CXXDEP="$CXX /QM"
   INTEL_WIN=1
 else
-  CXXDEP="$CXX -M"
+  CXXDEP="$CXX -M -x c++"
 fi
 AC_SUBST(CXXDEP)
 AC_SUBST(INTEL_WIN, $INTEL_WIN)
@@ -1594,12 +1594,34 @@
     AC_CHECK_LIB($sal_lib, vsmulx,  [sal_have_float=1], [sal_have_float=0])
     AC_CHECK_LIB($sal_lib, vsmuldx, [sal_have_double=1], [sal_have_double=0])
 
+    # Check specific SAL signatures
 
+    AC_MSG_CHECKING([for vconvert_s8_f32x signature.])
+    AC_COMPILE_IFELSE([
+#include <sal.h>
+
+int main(int, char **)
+{
+  signed char *input;
+  float *output;
+  vconvert_s8_f32x(input, 1, output, 1, 0, 0, 1, 0, 0);
+}
+],
+[
+  vconvert_s8_f32x_is_signed=1
+  AC_MSG_RESULT([signed char *])
+],
+[
+  vconvert_s8_f32x_is_signed=0
+  AC_MSG_RESULT([char *])
+])
+
     AC_SUBST(VSIP_IMPL_HAVE_SAL, 1)
     if test "$neutral_acconfig" = 'y'; then
       CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_HAVE_SAL=1"
       CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_HAVE_SAL_FLOAT=$sal_have_float"
       CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_HAVE_SAL_DOUBLE=$sal_have_double"
+      CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_VCONVERT_S8_F32X_IS_SIGNED=$vconvert_s8_f32x_is_signed"
     else
       AC_DEFINE_UNQUOTED(VSIP_IMPL_HAVE_SAL, 1,
         [Define to set whether or not to use Mercury's SAL library.])
@@ -1607,6 +1629,8 @@
         [Define if Mercury's SAL library provides float support.])
       AC_DEFINE_UNQUOTED(VSIP_IMPL_HAVE_SAL_DOUBLE, $sal_have_double,
         [Define if Mercury's SAL library provides double support.])
+      AC_DEFINE_UNQUOTED(VSIP_IMPL_VCONVERT_S8_F32X_IS_SIGNED, $vconvert_s8_f32x_is_signed,
+        [Define if Mercury SAL's vconvert_s8_f32x takes signed char * as input type.])
     fi
 
 
Index: src/vsip/opt/sal/elementwise.hpp
===================================================================
--- src/vsip/opt/sal/elementwise.hpp	(revision 181512)
+++ src/vsip/opt/sal/elementwise.hpp	(working copy)
@@ -272,7 +272,11 @@
 
 VSIP_IMPL_SAL_VCONV(vconv,          long,  float, vconvert_s32_f32x);
 VSIP_IMPL_SAL_VCONV(vconv,          short, float, vconvert_s16_f32x);
+#if VSIP_IMPL_VCONVERT_S8_F32X_IS_SIGNED == 1
+VSIP_IMPL_SAL_VCONV(vconv,   signed char,  float, vconvert_s8_f32x);
+#else
 VSIP_IMPL_SAL_VCONV(vconv,          char,  float, vconvert_s8_f32x);
+#endif
 VSIP_IMPL_SAL_VCONV(vconv, unsigned long,  float, vconvert_u32_f32x);
 VSIP_IMPL_SAL_VCONV(vconv, unsigned short, float, vconvert_u16_f32x);
 VSIP_IMPL_SAL_VCONV(vconv, unsigned char,  float, vconvert_u8_f32x);
