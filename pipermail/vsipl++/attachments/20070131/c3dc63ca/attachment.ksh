        * src/vsip/GNUmakefile.inc.in: Don't put non-BSD sources in
          cxx_sources when building ref-impl.
        * scripts/config: Update ref-impl binary package options.
        * tests/extdata_dist.cpp: Remove unnecessary include and define.
        * configure.ac: Imply --enable-cvsip and --enable-fft=cvsip
          when --enable-ref-impl given.


Index: src/vsip/GNUmakefile.inc.in
===================================================================
--- src/vsip/GNUmakefile.inc.in	(revision 161463)
+++ src/vsip/GNUmakefile.inc.in	(working copy)
@@ -19,6 +19,11 @@
 src_vsip_cxx_sources += $(wildcard $(srcdir)/src/vsip/core/*.cpp)
 src_vsip_cxx_sources += $(wildcard $(srcdir)/src/vsip/core/parallel/*.cpp)
 src_vsip_cxx_sources += $(wildcard $(srcdir)/src/vsip/core/signal/*.cpp)
+ifdef VSIP_IMPL_CVSIP_FFT
+src_vsip_cxx_sources += $(srcdir)/src/vsip/core/cvsip/fft.cpp
+endif
+
+ifndef VSIP_IMPL_REF_IMPL
 src_vsip_cxx_sources += $(wildcard $(srcdir)/src/vsip/opt/*.cpp)
 ifdef VSIP_IMPL_HAVE_IPP
 src_vsip_cxx_sources += $(srcdir)/src/vsip/opt/ipp/fir.cpp
@@ -40,14 +45,13 @@
 src_vsip_cxx_sources += $(srcdir)/src/vsip/opt/cbe/ppu/alf.cpp \
                         $(srcdir)/src/vsip/opt/cbe/ppu/bindings.cpp
 endif
-ifdef VSIP_IMPL_CVSIP_FFT
-src_vsip_cxx_sources += $(srcdir)/src/vsip/core/cvsip/fft.cpp
-endif
 src_vsip_cxx_sources += $(srcdir)/src/vsip/opt/simd/vmul.cpp \
 			$(srcdir)/src/vsip/opt/simd/rscvmul.cpp \
 			$(srcdir)/src/vsip/opt/simd/vadd.cpp \
 			$(srcdir)/src/vsip/opt/simd/vgt.cpp \
 			$(srcdir)/src/vsip/opt/simd/vlogic.cpp
+endif # VSIP_IMPL_REF_IMPL
+
 src_vsip_cxx_objects := $(patsubst $(srcdir)/%.cpp, %.$(OBJEXT), $(src_vsip_cxx_sources))
 
 cxx_sources += $(src_vsip_cxx_sources)
Index: scripts/config
===================================================================
--- scripts/config	(revision 161549)
+++ scripts/config	(working copy)
@@ -131,10 +131,8 @@
 # Reference Implementation
 
 ref_impl = [ '--enable-ref-impl',
-	     '--enable-cvsip',
              '--with-cvsip-prefix=%s'%cvsip_dir,
-	     '--with-lapack=no',
-	     '--enable-fft=cvsip']
+	     '--with-lapack=no']
 
 
 # C-VSIP BE, non reference implementation
Index: tests/extdata_dist.cpp
===================================================================
--- tests/extdata_dist.cpp	(revision 161549)
+++ tests/extdata_dist.cpp	(working copy)
@@ -14,8 +14,6 @@
   Included Files
 ***********************************************************************/
 
-#include <iostream>
-
 #include <vsip/vector.hpp>
 #include <vsip/core/extdata_dist.hpp>
 #include <vsip/initfin.hpp>
@@ -25,8 +23,6 @@
 #include <vsip_csl/test.hpp>
 #include <vsip_csl/output.hpp>
 
-#define VERBOSE 1
-
 using namespace std;
 using namespace vsip;
 using namespace vsip_csl;
Index: configure.ac
===================================================================
--- configure.ac	(revision 161463)
+++ configure.ac	(working copy)
@@ -736,6 +736,11 @@
   vsip_impl_fft_use_long_double=1
 fi
 
+if test "$ref_impl" = "1"; then
+  enable_fft="cvsip"
+fi
+
+
 fft_backends=`echo "${enable_fft}" | \
                 sed -e 's/[[ 	,]][[ 	,]]*/ /g' -e 's/,$//'`
 
@@ -1492,7 +1497,7 @@
   fi
 fi
 
-if test "x$with_cvsip_prefix" != x; then
+if test "$ref_impl" = "1" -o "x$with_cvsip_prefix" != x; then
   enable_cvsip="yes"
 fi
 if test "$enable_cvsip_fft" == "yes"; then
