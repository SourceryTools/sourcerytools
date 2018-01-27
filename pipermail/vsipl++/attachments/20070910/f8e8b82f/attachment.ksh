Index: ChangeLog
===================================================================
--- ChangeLog	(revision 181512)
+++ ChangeLog	(working copy)
@@ -1,3 +1,9 @@
+2007-09-10  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* configure.ac: Fix option-default logic for --with-lapack.
+	* src/vsip/core/fft.hpp: Fix typo.
+	* tests/ref-impl/GNUmakefile: Remove as obsoleted.
+	
 2007-08-25  Jules Bergmann  <jules@codesourcery.com>
 
 	Fix bug: dispatch to SAL evaluated A-b*C as A*b-C.
Index: src/vsip/core/fft.hpp
===================================================================
--- src/vsip/core/fft.hpp	(revision 181512)
+++ src/vsip/core/fft.hpp	(working copy)
@@ -207,7 +207,7 @@
 
 #ifdef VSIP_IMPL_REF_IMPL
   template <typename ViewT>
-  typename fft::result<), typename ViewT::block_type>::view_type
+  typename fft::result<O, typename ViewT::block_type>::view_type
   operator()(ViewT in) VSIP_THROW((std::bad_alloc))
   {
     typename base::Scope scope(*this);
Index: tests/ref-impl/GNUmakefile
===================================================================
--- tests/ref-impl/GNUmakefile	(revision 181512)
+++ tests/ref-impl/GNUmakefile	(working copy)
@@ -1,142 +0,0 @@
-######################################################### -*-Makefile-*-
-#
-# File:   Makefile
-# Author: Jeffrey D. Oldham, CodeSourcery, LLC.
-# Date:   07/09/2002
-#
-# Contents:
-#   Makefile to build the VSIPL++ Library unit tests.
-# 
-# Copyright 2005 Georgia Tech Research Corporation, all rights reserved.
-# 
-# A non-exclusive, non-royalty bearing license is hereby granted to all
-# Persons to copy, distribute and produce derivative works for any
-# purpose, provided that this copyright notice and following disclaimer
-# appear on All copies: THIS LICENSE INCLUDES NO WARRANTIES, EXPRESSED
-# OR IMPLIED, WHETHER ORAL OR WRITTEN, WITH RESPECT TO THE SOFTWARE OR
-# OTHER MATERIAL INCLUDING, BUT NOT LIMITED TO, ANY IMPLIED WARRANTIES
-# OF MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE, OR ARISING
-# FROM A COURSE OF PERFORMANCE OR DEALING, OR FROM USAGE OR TRADE, OR OF
-# NON-INFRINGEMENT OF ANY PATENTS OF THIRD PARTIES. THE INFORMATION IN
-# THIS DOCUMENT SHOULD NOT BE CONSTRUED AS A COMMITMENT OF DEVELOPMENT
-# BY ANY OF THE ABOVE PARTIES.
-# 
-# The US Government has a license under these copyrights, and this
-# Material may be reproduced by or for the US Government.
-#
-########################################################################
-
-########################################################################
-# Configuration Section
-########################################################################
-
-# The root of the implementation tree.
-IMPLEMENTATION_ROOT =	..
-
-include $(IMPLEMENTATION_ROOT)/GNUmakefile.inc
-
-########################################################################
-# Definition Section
-########################################################################
-
-# All the unit tests
-UNIT_TESTS = admitrelease complex dense math math-matvec math-reductions \
-	     math-scalarview matrix matrix-math matrix-const \
-	     random selgen \
-	     signal signal-convolution signal-correlation \
-	     signal-fft signal-fir signal-histogram signal-windows \
-	     fft-coverage \
-	     solvers-chol solvers-lu solvers-qr solvers-covsol \
-	     vector vector-math vector-const \
-	     view-math dim-order
-
-########################################################################
-# Specific Rule Section
-########################################################################
-
-# Create all the unit tests.
-all: $(UNIT_TESTS)
-
-admitrelease: admitrelease.o
-
-complex: complex.o
-
-dense: dense.o
-
-init: init.o
-
-math: math.o
-
-math-matvec: math-matvec.o
-
-math-reductions: math-reductions.o
-
-math-scalarview: math-scalarview.o
-
-matrix: matrix.o
-
-matrix-math: matrix-math.o
-
-matrix-const: matrix-const.o
-
-random: random.o
-
-selgen: selgen.o
-
-signal: signal.o
-
-signal-convolution: signal-convolution.o
-
-signal-correlation: signal-correlation.o
-
-signal-fir: signal-fir.o
-
-signal-fft: signal-fft.o
-
-signal-histogram: signal-histogram.o
-
-signal-windows: signal-windows.o
-
-fft-coverage: fft-coverage.o
-
-solvers-chol: solvers-chol.o
-
-solvers-lu: solvers-lu.o
-
-solvers-qr: solvers-qr.o
-
-solvers-covsol: solvers-covsol.o
-
-vector: vector.o
-
-vector-math: vector-math.o
-
-vector-const: vector-const.o
-
-dim-order: dim-order.o
-
-view-math: view-math.o
-
-regr-1: regr-1.o
-regr-2: regr-2.o
-
-# Run all the unit tests.
-check: all
-	./complex && ./dense && ./math && ./math-matvec && \
-	./math-reductions && ./math-scalarview && \
-	./matrix && ./matrix-math && ./matrix-const && \
-	./random && ./selgen && \
-	./signal && ./signal-convolution && ./signal-correlation && \
-	./signal-fft && ./signal-fir && \
-	./signal-histogram && ./signal-windows && \
-	./solvers-chol && ./solvers-lu && \
-	./solvers-qr && \
-	./vector && ./vector-math && ./vector-const \
-	./dim-order && ./view-math
-
-# Remove unnecessary files.
-clean:
-	-rm -f *.o *.s *.ii
-
-realclean: clean
-	-rm -f $(UNIT_TESTS)
Index: configure.ac
===================================================================
--- configure.ac	(revision 181512)
+++ configure.ac	(working copy)
@@ -1999,7 +1999,8 @@
 if test "$ref_impl" = "1"; then
   if test "$with_lapack" == "probe"; then
     with_lapack="no"
-  else
+  fi
+  if test "$with_lapack" != "no"; then
     AC_MSG_ERROR([Cannot use LAPACK with reference implementation.])
   fi
 fi
