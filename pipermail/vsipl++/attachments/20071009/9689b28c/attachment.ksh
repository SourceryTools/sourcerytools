Index: ChangeLog
===================================================================
--- ChangeLog	(revision 184420)
+++ ChangeLog	(working copy)
@@ -1,3 +1,8 @@
+2007-10-09  Stefan Seefeld  <stefan@codesourcery.com>
+
+ 	* configure.ac: Test whether SAL uses signed char types explicitely.
+	* src/vsip/opt/sal/elementwise.hpp: Adjust.
+
 2007-05-09  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip/opt/simd/simd.hpp: Fix faux-complex trait to work
Index: configure.ac
===================================================================
--- configure.ac	(revision 184420)
+++ configure.ac	(working copy)
@@ -1436,12 +1436,37 @@
     CPPFLAGS=$save_CPPFLAGS
     LDFLAGS=$save_LDFLAGS
   else
+    # Check specific SAL signatures
+
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
+      CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_SAL_USES_SIGNED=$vconvert_s8_f32x_is_signed"
     else
       AC_DEFINE_UNQUOTED(VSIP_IMPL_HAVE_SAL, 1,
         [Define to set whether or not to use Mercury's SAL library.])
+      AC_DEFINE_UNQUOTED(VSIP_IMPL_SAL_USES_SIGNED, $vconvert_s8_f32x_is_signed,
+        [Define if Mercury's SAL uses signed char *.])
     fi
 
     if test "$enable_sal_fft" != "no"; then 
Index: src/vsip/opt/sal/elementwise.hpp
===================================================================
--- src/vsip/opt/sal/elementwise.hpp	(revision 184420)
+++ src/vsip/opt/sal/elementwise.hpp	(working copy)
@@ -246,14 +246,22 @@
 
 VSIP_IMPL_SAL_VCONV(vconv, float,          long,  vconvert_f32_s32x);
 VSIP_IMPL_SAL_VCONV(vconv, float,          short, vconvert_f32_s16x);
+#if VSIP_IMPL_SAL_USES_SIGNED == 1
+VSIP_IMPL_SAL_VCONV(vconv, float,   signed char,  vconvert_f32_s8x);
+#else
 VSIP_IMPL_SAL_VCONV(vconv, float,          char,  vconvert_f32_s8x);
+#endif
 VSIP_IMPL_SAL_VCONV(vconv, float, unsigned long,  vconvert_f32_u32x);
 VSIP_IMPL_SAL_VCONV(vconv, float, unsigned short, vconvert_f32_u16x);
 VSIP_IMPL_SAL_VCONV(vconv, float, unsigned char,  vconvert_f32_u8x);
 
 VSIP_IMPL_SAL_VCONV(vconv,          long,  float, vconvert_s32_f32x);
 VSIP_IMPL_SAL_VCONV(vconv,          short, float, vconvert_s16_f32x);
+#if VSIP_IMPL_SAL_USES_SIGNED == 1
+VSIP_IMPL_SAL_VCONV(vconv,   signed char,  float, vconvert_s8_f32x);
+#else
 VSIP_IMPL_SAL_VCONV(vconv,          char,  float, vconvert_s8_f32x);
+#endif
 VSIP_IMPL_SAL_VCONV(vconv, unsigned long,  float, vconvert_u32_f32x);
 VSIP_IMPL_SAL_VCONV(vconv, unsigned short, float, vconvert_u16_f32x);
 VSIP_IMPL_SAL_VCONV(vconv, unsigned char,  float, vconvert_u8_f32x);
