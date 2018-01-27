Index: synopsis.py.in
===================================================================
--- synopsis.py.in	(revision 185107)
+++ synopsis.py.in	(working copy)
@@ -11,7 +11,6 @@
 from Synopsis.Formatters import HTML
 from Synopsis.Formatters.HTML.Views import *
 from Synopsis.Formatters import SXR
-import re
 
 srcdir = '@srcdir@'
 # beware filenames containing whitespace !
@@ -26,7 +25,7 @@
 
 linker = Linker(MacroFilter(pattern = r'^VSIP_(.*)_HPP$'),
                 Comments.Translator(markup = 'rst',
-                                    filter = Comments.SSFilter(),
+                                    filter = Comments.SSDFilter(),
                                     processor = Comments.Grouper()))
 
 html = HTML.Formatter(title = 'Sourcery VSIP++ Reference Manual',
Index: src/vsip/core/fft.hpp
===================================================================
--- src/vsip/core/fft.hpp	(revision 185107)
+++ src/vsip/core/fft.hpp	(working copy)
@@ -29,7 +29,7 @@
 #include <vsip/core/profile.hpp>
 
 #ifndef VSIP_IMPL_REF_IMPL
-# ifdef VSIP_IMPL_CBE_SDK
+# ifdef VSIP_IMPL_CBE_SDK_FFT
 #  include <vsip/opt/cbe/ppu/fft.hpp>
 # endif
 # if VSIP_IMPL_SAL_FFT
@@ -76,7 +76,7 @@
 {
 /// The list of evaluators to be tried, in that specific order.
 typedef Make_type_list<
-#ifdef VSIP_IMPL_CBE_SDK
+#ifdef VSIP_IMPL_CBE_SDK_FFT
   Cbe_sdk_tag,
 #endif
 #if VSIP_IMPL_SAL_FFT
Index: src/vsip/opt/cbe/spu/GNUmakefile.inc.in
===================================================================
--- src/vsip/opt/cbe/spu/GNUmakefile.inc.in	(revision 185107)
+++ src/vsip/opt/cbe/spu/GNUmakefile.inc.in	(working copy)
@@ -15,6 +15,9 @@
 enable_cbe_sdk_embedded_images := @enable_cbe_sdk_embedded_images@
 
 src_vsip_opt_cbe_spu_src := $(wildcard $(srcdir)/src/vsip/opt/cbe/spu/*.c)
+ifneq ($(VSIP_IMPL_CBE_SDK_FFT),1)
+src_vsip_opt_cbe_spu_src := $(filter-out %alf_fft_c.c, $(src_vsip_opt_cbe_spu_src))
+endif
 src_vsip_opt_cbe_spu_mod := $(patsubst $(srcdir)/%.c, %.spe,\
                               $(src_vsip_opt_cbe_spu_src))
 src_vsip_opt_cbe_spu_obj := $(patsubst %.spe, %.$(OBJEXT),\
Index: src/vsip/GNUmakefile.inc.in
===================================================================
--- src/vsip/GNUmakefile.inc.in	(revision 185107)
+++ src/vsip/GNUmakefile.inc.in	(working copy)
@@ -47,10 +47,12 @@
 endif
 ifdef VSIP_IMPL_HAVE_CBE_SDK
 src_vsip_cxx_sources += $(srcdir)/src/vsip/opt/cbe/ppu/task_manager.cpp \
-                        $(srcdir)/src/vsip/opt/cbe/ppu/fft.cpp \
                         $(srcdir)/src/vsip/opt/cbe/ppu/fastconv.cpp \
                         $(srcdir)/src/vsip/opt/cbe/ppu/bindings.cpp
 endif
+ifdef VSIP_IMPL_CBE_SDK_FFT
+src_vsip_cxx_sources += $(srcdir)/src/vsip/opt/cbe/ppu/fft.cpp
+endif
 src_vsip_cxx_sources += $(srcdir)/src/vsip/opt/simd/vmul.cpp \
 			$(srcdir)/src/vsip/opt/simd/rscvmul.cpp \
 			$(srcdir)/src/vsip/opt/simd/vadd.cpp \
Index: ChangeLog
===================================================================
--- ChangeLog	(revision 185107)
+++ ChangeLog	(working copy)
@@ -1,3 +1,16 @@
+2007-10-17  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* configure.ac: Add cbe_fft as possible fft backend.
+	* GNUmakefile.in: Adjust.
+	* src/vsip/GNUmakefile.inc.in: Adjust.
+	* src/vsip/core/fft.hpp: Adjust.
+	* src/vsip/opt/cbe/spu/GNUmakefile.inc.in: Adjust.
+	* examples/GNUmakefile.inc.in: Conditionalize more examples on PNG
+	availability.
+	* doc/GNUmakefile.inc.in: Generate dependencies for doc generation.
+	* synopsis.py.in: Adjust for better document extraction.
+	* doc/tutorial/serial.xml: Fix typo.
+	
 2007-10-09  Stefan Seefeld  <stefan@codesourcery.com>
 
  	* configure.ac: Test whether SAL uses signed char types explicitely.
Index: GNUmakefile.in
===================================================================
--- GNUmakefile.in	(revision 185107)
+++ GNUmakefile.in	(working copy)
@@ -128,6 +128,7 @@
 VSIP_IMPL_SAL_FFT := @VSIP_IMPL_SAL_FFT@
 VSIP_IMPL_IPP_FFT := @VSIP_IMPL_IPP_FFT@
 VSIP_IMPL_FFTW3 := @VSIP_IMPL_FFTW3@
+VSIP_IMPL_CBE_SDK_FFT := @VSIP_IMPL_CBE_SDK_FFT@
 VSIP_IMPL_CVSIP_FFT := @VSIP_IMPL_CVSIP_FFT@
 VSIP_IMPL_HAVE_NUMA := @VSIP_IMPL_HAVE_NUMA@
 
Index: configure.ac
===================================================================
--- configure.ac	(revision 185107)
+++ configure.ac	(working copy)
@@ -282,7 +282,7 @@
 AC_ARG_ENABLE(fft,
   AS_HELP_STRING([--enable-fft],
                  [Specify list of FFT engines. Available engines are:
-                  fftw3, ipp, sal, cvsip, builtin, dft, or no_fft [[builtin]].]),,
+                  fftw3, ipp, sal, cvsip, cbe_sdk, builtin, dft, or no_fft [[builtin]].]),,
   [enable_fft=builtin])
   
 AC_ARG_WITH(fftw3_prefix,
@@ -577,7 +577,7 @@
   CXXDEP="$CXX /QM"
   INTEL_WIN=1
 else
-  CXXDEP="$CXX -M"
+  CXXDEP="$CXX -M -x c++"
 fi
 AC_SUBST(CXXDEP)
 AC_SUBST(INTEL_WIN, $INTEL_WIN)
@@ -899,6 +899,7 @@
 enable_ipp_fft="no"
 enable_sal_fft="no"
 enable_cvsip_fft="no"
+enable_cbe_sdk_fft="no"
 enable_builtin_fft="no"
 
 if test "$enable_fft_float" = yes -o \
@@ -912,6 +913,11 @@
       cvsip) enable_cvsip_fft="yes";;
       fftw3) enable_fftw3="yes";;
       builtin) enable_builtin_fft="yes";;
+      cbe_sdk)
+        AC_SUBST(VSIP_IMPL_CBE_SDK_FFT, 1)
+        AC_DEFINE_UNQUOTED(VSIP_IMPL_CBE_SDK_FFT, 1,
+          [Define to enable Cell/B.E. SDK FFT backend.])
+        ;;
       dft)
         AC_SUBST(VSIP_IMPL_DFT_FFT, 1)
         AC_DEFINE_UNQUOTED(VSIP_IMPL_DFT_FFT, 1,
Index: doc/tutorial/serial.xml
===================================================================
--- doc/tutorial/serial.xml	(revision 185107)
+++ doc/tutorial/serial.xml	(working copy)
@@ -348,7 +348,7 @@
    block, providing it with the pointer.
   </para>
 
-  <programlisting><![CDATA[  Dense<value_type, 2> block(Domain<2>(nrange, npulse), &buffer.front());]]></programlisting>
+  <programlisting><![CDATA[  Dense<2, value_type> block(Domain<2>(nrange, npulse), &buffer.front());]]></programlisting>
 
   <para>
    Since the pointer to data does not encode the data dimensions, it
Index: doc/GNUmakefile.inc.in
===================================================================
--- doc/GNUmakefile.inc.in	(revision 185107)
+++ doc/GNUmakefile.inc.in	(working copy)
@@ -13,6 +13,7 @@
 ########################################################################
 
 doc_syn := src/vsip/core/vsip.syn
+deps    += src/vsip/core/vsip.hpp.d
 
 pdf_manuals += doc/quickstart/quickstart.pdf doc/tutorial/tutorial.pdf
 # The following variable is used by the 'install_html_template' rules.
@@ -149,3 +150,8 @@
 vsip.xref: vsip.syn
 	python synopsis.py xref --output=$@ $<
 
+%.hpp.d: %.hpp
+	@echo generating dependencies for $(@D)/$(<F)
+	$(SHELL) -ec '$(CXXDEP) $(CXXFLAGS) \
+	  $(call dir_var,$(dir $<),CXXFLAGS) $< \
+	  | sed "s|$(*F)\\.o[ :]*|$*\\.d $*\\.syn : |g" > $@'
Index: examples/GNUmakefile.inc.in
===================================================================
--- examples/GNUmakefile.inc.in	(revision 185107)
+++ examples/GNUmakefile.inc.in	(working copy)
@@ -17,7 +17,7 @@
 
 examples_cxx_sources := $(wildcard $(srcdir)/examples/*.cpp)
 ifndef VSIP_CSL_HAVE_PNG
-examples_cxx_sources := $(filter-out $(srcdir)/examples/png.cpp, \
+examples_cxx_sources := $(filter-out %png.cpp %sobel.cpp %stencil.cpp, \
                           $(examples_cxx_sources))
 endif
 examples_cxx_objects := \
