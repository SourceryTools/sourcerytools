Index: benchmarks/mpi/alltoall.cpp
===================================================================
--- benchmarks/mpi/alltoall.cpp	(revision 170718)
+++ benchmarks/mpi/alltoall.cpp	(working copy)
@@ -22,7 +22,7 @@
 #include <vsip/math.hpp>
 #include <vsip/map.hpp>
 #include <vsip/opt/profile.hpp>
-#include <vsip/opt/ops_info.hpp>
+#include <vsip/core/ops_info.hpp>
 
 #include <vsip_csl/test.hpp>
 #include "loop.hpp"
@@ -1551,7 +1551,7 @@
 	  typename SrcOrder,
 	  typename DstOrder,
 	  typename ImplTag>
-struct t_alltoall
+struct t_alltoall : Benchmark_base
 {
   char* what() { return "t_alltoall"; }
   int ops_per_point(length_type  rows)
@@ -1644,7 +1644,7 @@
 	  typename SrcOrder,
 	  typename DstOrder,
 	  typename ImplTag>
-struct t_alltoall_fr
+struct t_alltoall_fr : Benchmark_base
 {
   char* what() { return "t_alltoall_fr"; }
 
Index: benchmarks/mpi/copy.cpp
===================================================================
--- benchmarks/mpi/copy.cpp	(revision 170718)
+++ benchmarks/mpi/copy.cpp	(working copy)
@@ -543,7 +543,7 @@
 
 template <typename T,
 	  typename ImplTag>
-struct t_copy
+struct t_copy : Benchmark_base
 {
   char* what() { return "t_copy"; }
   int ops_per_point(length_type)
Index: benchmarks/ipp/fft.cpp
===================================================================
--- benchmarks/ipp/fft.cpp	(revision 170718)
+++ benchmarks/ipp/fft.cpp	(working copy)
@@ -53,12 +53,12 @@
 struct t_fft_ipp;
 
 template <>
-struct t_fft_ipp<complex<float> >
+struct t_fft_ipp<complex<float> > : Benchmark_base
 {
   char* what() { return "t_fft_ipp"; }
   int ops_per_point(size_t len)  { return fft_ops(len); }
-  int riob_per_point(size_t) { return -1*sizeof(Ipp32fc); }
-  int wiob_per_point(size_t) { return -1*sizeof(Ipp32fc); }
+  int riob_per_point(size_t) { return -1*(int)sizeof(Ipp32fc); }
+  int wiob_per_point(size_t) { return -1*(int)sizeof(Ipp32fc); }
   int mem_per_point(size_t)  { return  2*sizeof(Ipp32fc); }
 
   void operator()(size_t size, size_t loop, float& time)
Index: benchmarks/ipp/fft_ext.cpp
===================================================================
--- benchmarks/ipp/fft_ext.cpp	(revision 170718)
+++ benchmarks/ipp/fft_ext.cpp	(working copy)
@@ -161,12 +161,12 @@
 // Out of place FFT
 
 template <typename T>
-struct t_fft
+struct t_fft : Benchmark_base
 {
   char* what() { return "t_fft"; }
   int ops_per_point(length_type len)  { return fft_ops(len); }
-  int riob_per_point(length_type) { return -1*sizeof(T); }
-  int wiob_per_point(length_type) { return -1*sizeof(T); }
+  int riob_per_point(length_type) { return -1*(int)sizeof(T); }
+  int wiob_per_point(length_type) { return -1*(int)sizeof(T); }
   int mem_per_point(length_type)  { return  2*sizeof(T); }
 
   void operator()(length_type size, length_type loop, float& time)
Index: benchmarks/ipp/vmul.cpp
===================================================================
--- benchmarks/ipp/vmul.cpp	(revision 170718)
+++ benchmarks/ipp/vmul.cpp	(working copy)
@@ -23,7 +23,7 @@
 #include <vsip/math.hpp>
 
 #include <vsip/opt/profile.hpp>
-#include <vsip/opt/ops_info.hpp>
+#include <vsip/core/ops_info.hpp>
 
 #include <ipps.h>
 
@@ -39,7 +39,7 @@
 struct t_vmul_ipp_ip;
 
 template <>
-struct t_vmul_ipp<float>
+struct t_vmul_ipp<float> : Benchmark_base
 {
   typedef float T;
   char* what() { return "t_vmul_ipp"; }
@@ -89,7 +89,7 @@
 
 
 template <>
-struct t_vmul_ipp<std::complex<float> >
+struct t_vmul_ipp<std::complex<float> > : Benchmark_base
 {
   typedef std::complex<float> T;
 
@@ -142,7 +142,7 @@
 
 
 template <>
-struct t_vmul_ipp_ip<1, std::complex<float> >
+struct t_vmul_ipp_ip<1, std::complex<float> > : Benchmark_base
 {
   typedef std::complex<float> T;
 
@@ -193,7 +193,7 @@
 
 
 template <>
-struct t_vmul_ipp_ip<2, std::complex<float> >
+struct t_vmul_ipp_ip<2, std::complex<float> > : Benchmark_base
 {
   typedef std::complex<float> T;
 
Index: benchmarks/ipp/conv.cpp
===================================================================
--- benchmarks/ipp/conv.cpp	(revision 170718)
+++ benchmarks/ipp/conv.cpp	(working copy)
@@ -25,7 +25,7 @@
 #include <vsip/signal.hpp>
 
 #include <vsip/opt/profile.hpp>
-#include <vsip/opt/ops_info.hpp>
+#include <vsip/core/ops_info.hpp>
 
 #include <ipps.h>
 
@@ -67,7 +67,7 @@
 struct t_conv_ipp;
 
 template <>
-struct t_conv_ipp<float>
+struct t_conv_ipp<float> : Benchmark_base
 {
   char* what() { return "t_conv_ipp"; }
   float ops_per_point(size_t size)
Index: benchmarks/ipp/mcopy.cpp
===================================================================
--- benchmarks/ipp/mcopy.cpp	(revision 170718)
+++ benchmarks/ipp/mcopy.cpp	(working copy)
@@ -27,7 +27,7 @@
 #include <vsip/map.hpp>
 #include <vsip/opt/profile.hpp>
 #include <vsip/core/metaprogramming.hpp>
-#include <vsip/opt/ops_info.hpp>
+#include <vsip/core/ops_info.hpp>
 
 #include <vsip_csl/test.hpp>
 #include <vsip_csl/output.hpp>
@@ -119,7 +119,7 @@
 template <typename T,
 	  typename SrcBlock,
 	  typename DstBlock>
-struct t_mcopy<T, SrcBlock, DstBlock, Impl_copy>
+struct t_mcopy<T, SrcBlock, DstBlock, Impl_copy> : Benchmark_base
 {
   typedef typename SrcBlock::map_type src_map_type;
   typedef typename DstBlock::map_type dst_map_type;
@@ -193,7 +193,7 @@
 template <typename T,
 	  typename SrcBlock,
 	  typename DstBlock>
-struct t_mcopy<T, SrcBlock, DstBlock, Impl_transpose>
+struct t_mcopy<T, SrcBlock, DstBlock, Impl_transpose> : Benchmark_base
 {
   typedef typename SrcBlock::map_type src_map_type;
   typedef typename DstBlock::map_type dst_map_type;
@@ -282,7 +282,7 @@
 template <typename T,
 	  typename SrcBlock,
 	  typename DstBlock>
-struct t_mcopy<T, SrcBlock, DstBlock, Impl_select>
+struct t_mcopy<T, SrcBlock, DstBlock, Impl_select> : Benchmark_base
 {
   typedef typename SrcBlock::map_type src_map_type;
   typedef typename DstBlock::map_type dst_map_type;
Index: benchmarks/fftw3/fftm.cpp
===================================================================
--- benchmarks/fftw3/fftm.cpp	(revision 170718)
+++ benchmarks/fftw3/fftm.cpp	(working copy)
@@ -217,8 +217,8 @@
   char const* what() { return "t_fftm_fix_cols"; }
   int ops_per_point(length_type rows)
     { return (int)(this->ops(rows, cols_) / rows); }
-  int riob_per_point(length_type) { return -1*sizeof(T); }
-  int wiob_per_point(length_type) { return -1*sizeof(T); }
+  int riob_per_point(length_type) { return -1*(int)sizeof(T); }
+  int wiob_per_point(length_type) { return -1*(int)sizeof(T); }
   int mem_per_point(length_type cols) { return cols*elem_per_point*sizeof(T); }
 
   void operator()(length_type rows, length_type loop, float& time)
Index: benchmarks/lapack/qrd.cpp
===================================================================
--- benchmarks/lapack/qrd.cpp	(revision 170718)
+++ benchmarks/lapack/qrd.cpp	(working copy)
@@ -113,7 +113,7 @@
 
 template <typename T,
 	  typename OrderT>
-struct t_qrd
+struct t_qrd : Benchmark_base
 {
   char* what() { return "t_qrd"; }
   float ops_per_point(length_type n)
Index: benchmarks/fftm.cpp
===================================================================
--- benchmarks/fftm.cpp	(revision 170718)
+++ benchmarks/fftm.cpp	(working copy)
@@ -482,8 +482,8 @@
   char* what() { return "t_fftm_fix_cols"; }
   float ops_per_point(length_type rows)
     { return (int)(this->ops(rows, cols_) / rows); }
-  int riob_per_point(length_type) { return -1*sizeof(T); }
-  int wiob_per_point(length_type) { return -1*sizeof(T); }
+  int riob_per_point(length_type) { return -1*(int)sizeof(T); }
+  int wiob_per_point(length_type) { return -1*(int)sizeof(T); }
   int mem_per_point(length_type cols) { return cols*elem_per_point*sizeof(T); }
 
   void operator()(length_type rows, length_type loop, float& time)
Index: benchmarks/sal/fft.cpp
===================================================================
--- benchmarks/sal/fft.cpp	(revision 170718)
+++ benchmarks/sal/fft.cpp	(working copy)
@@ -172,7 +172,7 @@
 	  typename ComplexFmt>
 struct t_fft_op : Benchmark_base
 {
-  typedef impl::Scalar_of<T>::type scalar_type;
+  typedef typename impl::Scalar_of<T>::type scalar_type;
 
   char* what() { return "t_fft_op"; }
   int ops_per_point(length_type len)  { return fft_ops(len); }
@@ -256,7 +256,7 @@
 	  typename ComplexFmt>
 struct t_fft_ip : Benchmark_base
 {
-  typedef impl::Scalar_of<T>::type scalar_type;
+  typedef typename impl::Scalar_of<T>::type scalar_type;
 
   char* what() { return "t_fft_ip"; }
   int ops_per_point(length_type len)  { return fft_ops(len); }
Index: benchmarks/hpec_kernel/cfar_c.cpp
===================================================================
--- benchmarks/hpec_kernel/cfar_c.cpp	(revision 170718)
+++ benchmarks/hpec_kernel/cfar_c.cpp	(working copy)
@@ -64,7 +64,7 @@
 ***********************************************************************/
 
 template <typename T>
-struct t_cfar_base
+struct t_cfar_base : Benchmark_base
 {
   int ops_per_point(length_type /*size*/)
   { 
Index: benchmarks/vmmul.cpp
===================================================================
--- benchmarks/vmmul.cpp	(revision 170718)
+++ benchmarks/vmmul.cpp	(working copy)
@@ -148,8 +148,8 @@
   char* what() { return "t_vmmul_fix_rows"; }
   int ops_per_point(length_type cols)
     { return (int)(this->ops(rows_, cols) / cols); }
-  int riob_per_point(length_type) { return -1*sizeof(T); }
-  int wiob_per_point(length_type) { return -1*sizeof(T); }
+  int riob_per_point(length_type) { return -1*(int)sizeof(T); }
+  int wiob_per_point(length_type) { return -1*(int)sizeof(T); }
   int mem_per_point(length_type cols)
   { return SD == row ? (2*rows_+1)*sizeof(T)
                      : (2*rows_+rows_/cols)*sizeof(T); }
@@ -179,8 +179,8 @@
   char* what() { return "t_vmmul_fix_cols"; }
   int ops_per_point(length_type rows)
     { return (int)(this->ops(rows, cols_) / rows); }
-  int riob_per_point(length_type) { return -1*sizeof(T); }
-  int wiob_per_point(length_type) { return -1*sizeof(T); }
+  int riob_per_point(length_type) { return -1*(int)sizeof(T); }
+  int wiob_per_point(length_type) { return -1*(int)sizeof(T); }
   int mem_per_point(length_type rows)
   { return SD == row ? (2*cols_+cols_/rows)*sizeof(T)
                      : (2*cols_+1)*sizeof(T); }
Index: benchmarks/make.standalone
===================================================================
--- benchmarks/make.standalone	(revision 170271)
+++ benchmarks/make.standalone	(working copy)
@@ -1,139 +0,0 @@
-######################################################### -*-Makefile-*-
-#
-# File:   benchmarks/make.standalone
-# Author: Jules Bergmann
-# Date:   2006-01-19
-#
-# Contents: Standalone Makefile for VSIPL++ benchmarks
-#
-# Useful for building benchmarks for an installed library.
-#
-########################################################################
-
-# EXAMPLES:
-#
-# To compile the fft benchmark for an installed with .pc files visible in
-# PKG_CONFIG_PATH:
-#
-#   make -f make.standalone fft
-#
-# To compile the fft benchmark for a library that has been installed into
-# a non-standard prefix, or whose .pc files are not in PKG_CONFIG_PATH:
-#
-#   make -f make.standalone PREFIX=/path/to/library fft
-#
-
-
-
-########################################################################
-# Configuration Variables
-########################################################################
-
-# Variables in this section can be set by the user on the command line.
-
-# Prefix of installed library.  Not necessary if your .pc files are in
-# PKG_CONFIG_PATH and if they have the correct prefix.
-PREFIX   := 
-
-# Package to use.  For binary packages, this should either be 'vsipl++'
-# to use the release version of the library, or 'vsipl++-debug' to
-# use the debug version of the library.  For source packages, this
-# should most likely be 'vsipl++', unless a suffix was given during
-# installation.
-PKG      := vsipl++
-
-# Object file extension
-OBJEXT   := o
-
-# Executable file extension
-EXEEXT   :=  
-
-
-########################################################################
-# Internal Variables
-########################################################################
-
-# Variables in this section should not be modified.
-
-# Logic to call pkg-config with PREFIX, if specified.
-ifdef PREFIX
-   PC    := env PKG_CONFIG_PATH=$(PREFIX)/lib/pkgconfig \
-	    pkg-config --define-variable=prefix=$(PREFIX) $(PKG)
-else
-   PC    := pkg-config $(PKG)
-endif
-
-
-CXX      := $(shell $(PC) --variable=cxx )
-CXXFLAGS := $(shell $(PC) --cflags       ) \
-	    $(shell $(PC) --variable=cxxflags ) \
-	    -I. -I./hpec_kernel -I../tests
-LIBS     := $(shell $(PC) --libs         )
-
-
-sources := $(wildcard *.cpp)
-objects := $(patsubst %.cpp, %.$(OBJEXT), $(sources))
-exes    := $(patsubst %.cpp, %$(EXEEXT),  $(sources))
-headers := $(wildcard *.hpp)
-
-statics := $(patsubst %.cpp, %.static$(EXEEXT),  $(sources))
-
-hpec_sources := $(wildcard hpec_kernel/*.cpp)
-hpec_objects := $(patsubst %.cpp, %.$(OBJEXT), $(hpec_sources))
-hpec_exes    := $(patsubst %.cpp, %$(EXEEXT),  $(hpec_sources))
-
-hpec_targets := $(hpec_exes)
-
-
-# Do not automatically build tests requiring packages that 
-# may not be available
-srcs_lapack := $(wildcard lapack/*.cpp)
-srcs_ipp    := $(wildcard ipp/*.cpp) 
-srcs_sal    := $(wildcard sal/*.cpp) 
-srcs_mpi    := $(wildcard mpi/*.cpp) 
-
-exes_lapack := $(patsubst %.cpp, %$(EXEEXT),  $(srcs_lapack))
-exes_ipp    := $(patsubst %.cpp, %$(EXEEXT),  $(srcs_ipp))
-exes_sal    := $(patsubst %.cpp, %$(EXEEXT),  $(srcs_sal))
-exes_mpi    := $(patsubst %.cpp, %$(EXEEXT),  $(srcs_mpi))
-
-targets     := $(filter-out main$(EXEEXT), $(exes)) 
-all_targets := $(targets) $(exes_lapack) $(exes_ipp) $(exes_sal) $(exes_mpi)
-all_targets += $(hpec_targets)
-
-########################################################################
-# Targets
-########################################################################
-
-benchmarks: $(targets) $(headers)
-
-hpec_kernel:  $(hpec_targets) $(headers)
-
-check: $(targets) $(headers)
-
-main.$(OBJEXT): $(headers)
-
-vars:
-	@echo "PKG-CFG : " $(PC)
-	@echo "CXX     : " $(CXX)
-	@echo "CXXFLAGS: " $(CXXFLAGS)
-	@echo "LIBS    : " $(LIBS)
-
-clean:
-	rm -rf $(targets) $(objects)
-
-
-
-
-########################################################################
-# Implicit Rules
-########################################################################
-
-$(all_targets): %$(EXEEXT) : %.$(OBJEXT) main.$(OBJEXT)
-	$(CXX) $(LDFLAGS) -o $@ $^ $(LIBS) || rm -f $@
-
-$(statics): %.static$(EXEEXT) : %.$(OBJEXT) main.$(OBJEXT)
-	$(CXX) -static $(LDFLAGS) -o $@ $^ $(LIBS) || rm -f $@
-
-%.o: %.cpp
-	$(CXX) -c $(CXXFLAGS) -o $@ $< || rm -f $@
Index: benchmarks/GNUmakefile.inc.in
===================================================================
--- benchmarks/GNUmakefile.inc.in	(revision 170718)
+++ benchmarks/GNUmakefile.inc.in	(working copy)
@@ -20,36 +20,50 @@
 benchmarks_CXXINCLUDES := -I$(srcdir)/src -I$(srcdir)/tests	\
 			  -I$(srcdir)/benchmarks
 benchmarks_CXXFLAGS := $(benchmarks_CXXINCLUDES)
-benchmarks_cell_CXXFLAGS := $(benchmarks_CXXINCLUDES)
+benchmarks_lapack_CXXFLAGS := $(benchmarks_CXXINCLUDES)
 benchmarks_ipp_CXXFLAGS := $(benchmarks_CXXINCLUDES)
+benchmarks_sal_CXXFLAGS := $(benchmarks_CXXINCLUDES)
 benchmarks_fftw3_CXXFLAGS := $(benchmarks_CXXINCLUDES)
+benchmarks_mpi_CXXFLAGS := $(benchmarks_CXXINCLUDES)
+benchmarks_cell_CXXFLAGS := $(benchmarks_CXXINCLUDES)
 
-benchmarks_src := $(wildcard $(srcdir)/benchmarks/*.cpp)
+benchmarks_cxx_sources := $(wildcard $(srcdir)/benchmarks/*.cpp)
+benchmarks_cxx_headers := $(wildcard $(srcdir)/benchmarks/*.hpp)
 ifdef VSIP_IMPL_HAVE_LAPACK
-benchmarks_src += $(wildcard $(srcdir)/benchmarks/lapack/*.cpp)
+benchmarks_cxx_sources += $(wildcard $(srcdir)/benchmarks/lapack/*.cpp)
+benchmarks_cxx_headers += $(wildcard $(srcdir)/benchmarks/lapack/*.hpp)
 endif
 ifdef VSIP_IMPL_HAVE_IPP
-benchmarks_src += $(wildcard $(srcdir)/benchmarks/ipp/*.cpp) 
+benchmarks_cxx_sources += $(wildcard $(srcdir)/benchmarks/ipp/*.cpp) 
+benchmarks_cxx_header += $(wildcard $(srcdir)/benchmarks/ipp/*.hpp) 
 endif
 ifdef VSIP_IMPL_HAVE_SAL
-benchmarks_src += $(wildcard $(srcdir)/benchmarks/sal/*.cpp) 
+benchmarks_cxx_sources += $(wildcard $(srcdir)/benchmarks/sal/*.cpp) 
+benchmarks_cxx_headers += $(wildcard $(srcdir)/benchmarks/sal/*.hpp) 
 endif
 ifdef VSIP_IMPL_FFTW3
-benchmarks_src += $(wildcard $(srcdir)/benchmarks/fftw3/*.cpp) 
+benchmarks_cxx_sources += $(wildcard $(srcdir)/benchmarks/fftw3/*.cpp) 
+benchmarks_cxx_headers += $(wildcard $(srcdir)/benchmarks/fftw3/*.hpp) 
 endif
 ifdef VSIP_IMPL_HAVE_MPI
-benchmarks_src += $(wildcard $(srcdir)/benchmarks/mpi/*.cpp) 
+benchmarks_cxx_sources += $(wildcard $(srcdir)/benchmarks/mpi/*.cpp) 
+benchmarks_cxx_headers += $(wildcard $(srcdir)/benchmarks/mpi/*.hpp) 
 endif
 ifdef VSIP_IMPL_HAVE_CBE_SDK
-benchmarks_src += $(wildcard $(srcdir)/benchmarks/cell/*.cpp) 
+benchmarks_cxx_sources += $(wildcard $(srcdir)/benchmarks/cell/*.cpp) 
+benchmarks_cxx_headers += $(wildcard $(srcdir)/benchmarks/cell/*.hpp) 
 endif
 
-benchmarks_obj := $(patsubst $(srcdir)/%.cpp, %.$(OBJEXT), $(benchmarks_src))
-benchmarks_exe := $(patsubst $(srcdir)/%.cpp, %$(EXEEXT), $(benchmarks_src))
+benchmarks_obj := $(patsubst $(srcdir)/%.cpp, %.$(OBJEXT), $(benchmarks_cxx_sources))
+benchmarks_exe := $(patsubst $(srcdir)/%.cpp, %$(EXEEXT), $(benchmarks_cxx_sources))
 benchmarks_targets := $(filter-out benchmarks/main$(EXEEXT), $(benchmarks_exe)) 
 
-cxx_sources += $(benchmarks_src)
+cxx_sources += $(benchmarks_cxx_sources)
 
+benchmarks_install_sources := $(benchmarks_cxx_sources) $(benchmarks_cxx_headers)
+
+benchmarks_install_targets := $(patsubst $(srcdir)/%, %, $(benchmarks_install_sources))
+
 benchmarks_static_targets := $(patsubst %$(EXEEXT), \
                                %.static$(EXEEXT), \
                                $(benchmarks_targets))
@@ -65,6 +79,21 @@
 clean::
 	rm -f $(benchmarks_targets) $(benchmarks_static_targets)
 
+# Install benchmark source code
+install:: 
+	$(INSTALL) -d $(DESTDIR)$(pkgdatadir)/benchmarks
+	$(INSTALL) -d $(DESTDIR)$(pkgdatadir)/benchmarks/lapack
+	$(INSTALL) -d $(DESTDIR)$(pkgdatadir)/benchmarks/ipp
+	$(INSTALL) -d $(DESTDIR)$(pkgdatadir)/benchmarks/sal
+	$(INSTALL) -d $(DESTDIR)$(pkgdatadir)/benchmarks/fftw3
+	$(INSTALL) -d $(DESTDIR)$(pkgdatadir)/benchmarks/mpi
+	$(INSTALL) -d $(DESTDIR)$(pkgdatadir)/benchmarks/cell
+	$(INSTALL_DATA) benchmarks/makefile.standalone \
+	  $(DESTDIR)$(pkgdatadir)/benchmarks/Makefile
+	for sourcefile in $(benchmarks_install_targets); do \
+          $(INSTALL_DATA) $(srcdir)/$$sourcefile $(DESTDIR)$(pkgdatadir)/`dirname $$sourcefile`; \
+	done
+
 $(benchmarks_targets): %$(EXEEXT) : %.$(OBJEXT) benchmarks/main.$(OBJEXT) $(libs)
 	$(CXX) $(LDFLAGS) -o $@ $^ -Llib -lsvpp $(LIBS) || rm -f $@
 
