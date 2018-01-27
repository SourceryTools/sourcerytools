Index: benchmarks/GNUmakefile.inc.in
===================================================================
--- benchmarks/GNUmakefile.inc.in	(revision 170836)
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
@@ -65,6 +79,31 @@
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
+	$(INSTALL) -d $(DESTDIR)$(exec_prefix)/benchmarks
+	$(INSTALL) -d $(DESTDIR)$(exec_prefix)/benchmarks/lapack
+	$(INSTALL) -d $(DESTDIR)$(exec_prefix)/benchmarks/ipp
+	$(INSTALL) -d $(DESTDIR)$(exec_prefix)/benchmarks/sal
+	$(INSTALL) -d $(DESTDIR)$(exec_prefix)/benchmarks/fftw3
+	$(INSTALL) -d $(DESTDIR)$(exec_prefix)/benchmarks/mpi
+	$(INSTALL) -d $(DESTDIR)$(exec_prefix)/benchmarks/cell
+	for binfile in $(benchmarks_targets); do \
+	  $(INSTALL) $$binfile $(DESTDIR)$(exec_prefix)/`dirname $$binfile`; \
+	done
+
 $(benchmarks_targets): %$(EXEEXT) : %.$(OBJEXT) benchmarks/main.$(OBJEXT) $(libs)
 	$(CXX) $(LDFLAGS) -o $@ $^ -Llib -lsvpp $(LIBS) || rm -f $@
 
Index: benchmarks/hpec_kernel/GNUmakefile.inc.in
===================================================================
--- benchmarks/hpec_kernel/GNUmakefile.inc.in	(revision 170836)
+++ benchmarks/hpec_kernel/GNUmakefile.inc.in	(working copy)
@@ -21,29 +21,44 @@
 benchmarks_hpec_kernel_CXXFLAGS := $(benchmarks_hpec_kernel_CXXINCLUDES)
 
 hpec_cxx_sources := $(wildcard $(srcdir)/benchmarks/hpec_kernel/*.cpp)
+hpec_cxx_headers := $(wildcard $(srcdir)/benchmarks/hpec_kernel/*.hpp)
+
+hpec_obj := $(patsubst $(srcdir)/%.cpp, %.$(OBJEXT), $(hpec_cxx_sources))
+hpec_exe := $(patsubst $(srcdir)/%.cpp, %$(EXEEXT), $(hpec_cxx_sources))
+hpec_targets := $(filter-out benchmarks/main$(EXEEXT), $(hpec_exe)) 
+
 cxx_sources += $(hpec_cxx_sources)
 
-hpec_cxx_objects := $(patsubst $(srcdir)/%.cpp, %.$(OBJEXT), \
-                               $(hpec_cxx_sources))
-hpec_cxx_exes    := $(patsubst $(srcdir)/%.cpp, %$(EXEEXT),  \
-                               $(hpec_cxx_sources))
+hpec_install_sources := $(hpec_cxx_sources) $(hpec_cxx_headers)
 
-hpec_cxx_exes_special   := benchmarks/hpec_kernel/main$(EXEEXT)
-hpec_cxx_exes_def_build := $(filter-out $(hpec_cxx_exes_special), \
-                                        $(hpec_cxx_exes)) 
+hpec_install_targets := $(patsubst $(srcdir)/%, %, $(hpec_install_sources))
 
 
 ########################################################################
 # Rules
 ########################################################################
 
-hpec_kernel:: $(hpec_cxx_exes_def_build)
+hpec_kernel:: $(hpec_targets)
 
 # Object files will be deleted by the parent clean rule.
 clean::
-	rm -f $(hpec_cxx_exes_def_build)
+	rm -f $(hpec_targets)
 
-$(hpec_cxx_exes_def_build): %$(EXEEXT) : \
+# Install benchmark source code and executables
+install::
+	$(INSTALL) -d $(DESTDIR)$(pkgdatadir)/benchmarks
+	$(INSTALL) -d $(DESTDIR)$(pkgdatadir)/benchmarks/hpec_kernel
+	for sourcefile in $(hpec_install_targets); do \
+          $(INSTALL_DATA) $(srcdir)/$$sourcefile \
+	    $(DESTDIR)$(pkgdatadir)/`dirname $$sourcefile`; \
+	done
+	$(INSTALL) -d $(DESTDIR)$(exec_prefix)/benchmarks
+	$(INSTALL) -d $(DESTDIR)$(exec_prefix)/benchmarks/hpec_kernel
+	for binfile in $(hpec_targets); do \
+	  $(INSTALL) $$binfile $(DESTDIR)$(exec_prefix)/`dirname $$binfile`; \
+	done
+
+$(hpec_targets): %$(EXEEXT) : \
   %.$(OBJEXT) benchmarks/main.$(OBJEXT) $(libs)
 	$(CXX) $(LDFLAGS) -o $@ $^ -Llib -lsvpp $(LIBS) || rm -f $@
 
Index: benchmarks/hpec_kernel/make.standalone
===================================================================
--- benchmarks/hpec_kernel/make.standalone	(revision 170836)
+++ benchmarks/hpec_kernel/make.standalone	(working copy)
@@ -1,49 +0,0 @@
-######################################################### -*-Makefile-*-
-#
-# File:   share/sourceryvsipl++/benchmarks/hpec_kernel/Makefile
-# Author: Don McCoy
-# Date:   2006-04-11
-#
-# Contents: Makefile for Sourcery VSIPL++-based High Performance 
-#           Embedded Computing (HPEC) Kernel-Level Benchmarks.
-#
-########################################################################
-
-########################################################################
-# Variables
-########################################################################
-
-# This should point to the directory where Sourcery VSIPL++ is installed.
-prefix = /usr/local
-
-# This selects the desired library.  Use '-debug' for building a version 
-# suitable for debugging or leave blank to use the optimized version.
-suffix = 
-
-pkgcommand := PKG_CONFIG_PATH=$(prefix)/lib/pkgconfig 	\
-                     pkg-config vsipl++$(suffix) 	\
-                     --define-variable=prefix=$(prefix)
-
-CXX      = $(shell ${pkgcommand} --variable=cxx)
-CXXFLAGS = $(shell ${pkgcommand} --cflags) \
-	   $(shell ${pkgcommand} --variable=cxxflags) -I..
-LIBS     = $(shell ${pkgcommand} --libs)
- 
-
-########################################################################
-# Rules
-########################################################################
-
-all: firbank
-
-firbank: firbank.o ../main.o
-	$(CXX) $(CXXFLAGS) -o $@ $^ $(LIBS) || rm -f $@
-
-vars:
-	@echo "PKG-CFG : " $(pkgcommand)
-	@echo "CXX     : " $(CXX)
-	@echo "CXXFLAGS: " $(CXXFLAGS)
-	@echo "LIBS    : " $(LIBS)
-
-
-
