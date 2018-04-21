Index: ChangeLog
===================================================================
--- ChangeLog	(revision 218806)
+++ ChangeLog	(working copy)
@@ -1,5 +1,10 @@
 2008-08-26  Jules Bergmann  <jules@codesourcery.com>
 
+	* README.cbe: Update for binary CML package.
+	* examples/cell/setup.sh: New file, example CBE configury options.
+
+2008-08-26  Jules Bergmann  <jules@codesourcery.com>
+
 	* src/vsip/opt/ukernel.hpp: Make 64-bit clean.
 
 2008-08-26  Jules Bergmann  <jules@codesourcery.com>
Index: README.cbe
===================================================================
--- README.cbe	(revision 218695)
+++ README.cbe	(working copy)
@@ -23,19 +23,10 @@
 	fftw-devel
 
 
-2. Configure, build, and install the CML library.
+2. Install the CML library.
 
-   The details of building the CML library are included in the README
-   file within the CML source package.  For native compilation, the only
-   required option to configure is --prefix=$cml_prefix, where
-   $cml_prefix is the desired installation location for the CML library.
-   The relevant environment variables for specifying the compiler and
-   compiler options should be taken from the CML README file.
-
-   Both the "make" and "make install" targets in the CML makefile must
-   be run, to install CML into the $cml_prefix location, before building
-   Sourcery VSIPL++.  We also recommend running "make check" to confirm
-   that the library has built correctly.
+   In subsequent steps, $cml_prefix refers to the installation
+   location of CML.
    
 
 3. Configure the Sourcery VSIPL++ library.
@@ -79,7 +70,10 @@
    Check for warnings and error messages in the configure output before
    continuing.
 
+   $(srcdir)/examples/cell/setup.sh provides an example of invoking
+   configure.
 
+
 4. Make the library
 
    To build the library, run "make" in the build directory.
@@ -145,9 +139,27 @@
 
    Please also refer to chapter 3 of the Quickstart "Building Applications"
    for details on using pkg-config, make, and building manually.
+
+
+6. Set ALF_LIBRARY_PATH environment variable.
+
+   It is necessary to set ALF_LIBRARY_PATH to indicate where VSIPL++
+   and CML's ALF kernels can be found.
+
+   With SDK 3.0, ALF_LIBRARY_PATH can only contain a single
+   directory, so it is necessary to copy the CML kernels into
+   same directory as the VSIPL++ kernels.
+
+   	> cp $cml_prefix/lib/cml_kernels.so $svpp_prefix/lib
+	> setenv ALF_LIBRARY_PATH $svpp_prefix/lib
+
+   SDK 3.1 and later allow multiple directories separated by ':'
+   in ALF_LIBRARY_PATH:
+
+   	> setenv ALF_LIBRARY_PATH $svpp_prefix/lib:$cml_prefix/lib
    
 
-6. Run tests
+7. Run tests
 
    The library comes with a test-suite that validates its operation.
    The tests are located in the 'tests' subdirectory of source package.
@@ -183,7 +195,7 @@
    and we will try to help.
 
 
-7. Run benchmarks
+8. Run benchmarks
 
    Sourcery VSIPL++ also includes a number of micro-benchmarks that
    measure the performance of various kernels in the library.  These
Index: examples/cell/setup.sh
===================================================================
--- examples/cell/setup.sh	(revision 0)
+++ examples/cell/setup.sh	(revision 0)
@@ -0,0 +1,54 @@
+#! /bin/sh
+
+#########################################################################
+# examples/cell/setup.sh -- setup script to configure Sourcery VSIPL++
+#			    for use on Cell/B.E. systems
+#
+# (25 Aug 08) Jules Bergmann, CodeSourcery, Inc.
+#########################################################################
+
+#########################################################################
+# Instructions:
+#  - Modify flags below to control where and how VSIPL++ is built.
+#  - Run setup.sh
+#  - Run 'make'
+#  - Run 'make install'
+#
+# Variables:
+#  - src_dir	-- source directory
+#  - sdk_dir	-- SDK install directory (default is for SDK 3.0)
+#  - cml_dir	-- CML install directory
+#  - svpp_prefix-- VSIPL++ installation prefix (VSIPL++ will be installed
+#                  here).
+#########################################################################
+
+src_dir=../sourceryvsipl++-20080825
+sdk_dir=/opt/ibm/cell-sdk/prototype
+cml_dir=/scratch/jules/opt/cml
+svpp_prefix=/scratch/jules/build-test/install
+
+bits="-m32"
+opt="-mcpu=cell -maltivec -g -O2 -funswitch-loops -fgcse-after-reload -DNDEBUG --param max-inline-insns-single=2000 --param large-function-insns=6000 --param large-function-growth=800 --param inline-unit-growth=300"
+
+export CFLAGS="$bits $opt"
+export CXXFLAGS="$bits $opt"
+export LDFLAGS="$bits"
+export CC=ppu-gcc
+export CXX=ppu-g++
+export LD=ppu-ld
+
+$src_dir/configure								\
+	--with-cbe-sdk=3.0							\
+	--with-cbe-sdk-prefix=$sdk_dir						\
+	--disable-fft-long-double						\
+	--disable-parallel							\
+	--with-lapack=atlas							\
+	--with-atlas-include=/usr/include/atlas					\
+	--with-atlas-libdir=/usr/lib/altivec					\
+	--enable-fft=cbe_sdk,fftw3						\
+	--with-builtin-simd-routines=generic					\
+	--with-complex=split							\
+	--with-test-level=1							\
+	--prefix=$svpp_prefix							\
+	--with-cml-prefix=$cml_dir 			 			\
+	--enable-timer=power_tb

Property changes on: examples/cell/setup.sh
___________________________________________________________________
Name: svn:executable
   + *

