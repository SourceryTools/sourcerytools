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
--- benchmarks/GNUmakefile.inc.in	(revision 170271)
+++ benchmarks/GNUmakefile.inc.in	(working copy)
@@ -24,31 +24,38 @@
 benchmarks_ipp_CXXFLAGS := $(benchmarks_CXXINCLUDES)
 benchmarks_fftw3_CXXFLAGS := $(benchmarks_CXXINCLUDES)
 
-benchmarks_src := $(wildcard $(srcdir)/benchmarks/*.cpp)
+benchmarks_src = $(wildcard $(srcdir)/benchmarks/*.cpp)
+benchmarks_cxx_sources = $(benchmarks_src)
 ifdef VSIP_IMPL_HAVE_LAPACK
-benchmarks_src += $(wildcard $(srcdir)/benchmarks/lapack/*.cpp)
+benchmarks_lapack_src = $(wildcard $(srcdir)/benchmarks/lapack/*.cpp)
+benchmarks_cxx_sources += $(benchmarks_lapack_src)
 endif
 ifdef VSIP_IMPL_HAVE_IPP
-benchmarks_src += $(wildcard $(srcdir)/benchmarks/ipp/*.cpp) 
+benchmarks_ipp_src = $(wildcard $(srcdir)/benchmarks/ipp/*.cpp) 
+benchmarks_cxx_sources += $(benchmarks_ipp_src)
 endif
 ifdef VSIP_IMPL_HAVE_SAL
-benchmarks_src += $(wildcard $(srcdir)/benchmarks/sal/*.cpp) 
+benchmarks_sal_src = $(wildcard $(srcdir)/benchmarks/sal/*.cpp) 
+benchmarks_cxx_sources += $(benchmarks_sal_src)
 endif
 ifdef VSIP_IMPL_FFTW3
-benchmarks_src += $(wildcard $(srcdir)/benchmarks/fftw3/*.cpp) 
+benchmarks_fftw3_src = $(wildcard $(srcdir)/benchmarks/fftw3/*.cpp) 
+benchmarks_cxx_sources += $(benchmarks_fftw3_src)
 endif
 ifdef VSIP_IMPL_HAVE_MPI
-benchmarks_src += $(wildcard $(srcdir)/benchmarks/mpi/*.cpp) 
+benchmarks_mpi_src = $(wildcard $(srcdir)/benchmarks/mpi/*.cpp) 
+benchmarks_cxx_sources += $(benchmarks_mpi_src)
 endif
 ifdef VSIP_IMPL_HAVE_CBE_SDK
-benchmarks_src += $(wildcard $(srcdir)/benchmarks/cell/*.cpp) 
+benchmarks_cell_src = $(wildcard $(srcdir)/benchmarks/cell/*.cpp) 
+benchmarks_cxx_sources += $(benchmarks_cell_src)
 endif
 
-benchmarks_obj := $(patsubst $(srcdir)/%.cpp, %.$(OBJEXT), $(benchmarks_src))
-benchmarks_exe := $(patsubst $(srcdir)/%.cpp, %$(EXEEXT), $(benchmarks_src))
+benchmarks_obj := $(patsubst $(srcdir)/%.cpp, %.$(OBJEXT), $(benchmarks_cxx_sources))
+benchmarks_exe := $(patsubst $(srcdir)/%.cpp, %$(EXEEXT), $(benchmarks_cxx_sources))
 benchmarks_targets := $(filter-out benchmarks/main$(EXEEXT), $(benchmarks_exe)) 
 
-cxx_sources += $(benchmarks_src)
+cxx_sources += $(benchmarks_cxx_sources)
 
 benchmarks_static_targets := $(patsubst %$(EXEEXT), \
                                %.static$(EXEEXT), \
@@ -65,6 +72,36 @@
 clean::
 	rm -f $(benchmarks_targets) $(benchmarks_static_targets)
 
+install::
+	$(INSTALL) -d $(DESTDIR)$(pkgdatadir)/benchmarks
+	$(INSTALL_DATA) $(benchmarks_src) $(DESTDIR)$(pkgdatadir)/benchmarks
+	$(INSTALL_DATA) benchmarks/makefile.standalone \
+	  $(DESTDIR)$(pkgdatadir)/benchmarks/Makefile
+ifdef VSIP_IMPL_HAVE_LAPACK
+	$(INSTALL) -d $(DESTDIR)$(pkgdatadir)/benchmarks/lapack
+	$(INSTALL_DATA) $(benchmarks_lapack_src) $(DESTDIR)$(pkgdatadir)/benchmarks/lapack
+endif
+ifdef VSIP_IMPL_HAVE_IPP
+	$(INSTALL) -d $(DESTDIR)$(pkgdatadir)/benchmarks/ipp
+	$(INSTALL_DATA) $(benchmarks_ipp_src) $(DESTDIR)$(pkgdatadir)/benchmarks/ipp
+endif
+ifdef VSIP_IMPL_HAVE_SAL
+	$(INSTALL) -d $(DESTDIR)$(pkgdatadir)/benchmarks/sal
+	$(INSTALL_DATA) $(benchmarks_sal_src) $(DESTDIR)$(pkgdatadir)/benchmarks/sal
+endif
+ifdef VSIP_IMPL_FFTW3
+	$(INSTALL) -d $(DESTDIR)$(pkgdatadir)/benchmarks/fftw3
+	$(INSTALL_DATA) $(benchmarks_fftw3_src) $(DESTDIR)$(pkgdatadir)/benchmarks/fftw3
+endif
+ifdef VSIP_IMPL_HAVE_MPI
+	$(INSTALL) -d $(DESTDIR)$(pkgdatadir)/benchmarks/mpi
+	$(INSTALL_DATA) $(benchmarks_mpi_src) $(DESTDIR)$(pkgdatadir)/benchmarks/mpi
+endif
+ifdef VSIP_IMPL_HAVE_CBE_SDK
+	$(INSTALL) -d $(DESTDIR)$(pkgdatadir)/benchmarks/cell
+	$(INSTALL_DATA) $(benchmarks_src) $(DESTDIR)$(pkgdatadir)/benchmarks/cell
+endif
+
 $(benchmarks_targets): %$(EXEEXT) : %.$(OBJEXT) benchmarks/main.$(OBJEXT) $(libs)
 	$(CXX) $(LDFLAGS) -o $@ $^ -Llib -lsvpp $(LIBS) || rm -f $@
 
