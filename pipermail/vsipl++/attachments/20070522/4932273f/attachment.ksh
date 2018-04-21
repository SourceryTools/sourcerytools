
Property changes on: .
___________________________________________________________________
Name: svn:externals
   - tests/ref-impl                svn+ssh://cugel/net/merlin/home-s/svk/Repository/csl/vsipl++/trunk/implementation/tests
doc/csl-docbook               svn+ssh://cugel/net/merlin/home-s/svk/Repository/csl/csl-docbook/trunk
vendor/fftw                   svn+ssh://cugel/net/merlin/home-s/svk/Repository/csl/fftw/vendor/3.1.2
vendor/atlas                  svn+ssh://cugel/net/merlin/home-s/svk/Repository/csl/atlas/trunk
vendor/lapack                 svn+ssh://cugel/net/merlin/home-s/svk/Repository/csl/lapack/trunk
vendor/clapack/SRC            svn+ssh://cugel/net/merlin/home-s/svk/Repository/csl/clapack/trunk/SRC
vendor/clapack/F2CLIBS/libF77 svn+ssh://cugel/net/merlin/home-s/svk/Repository/csl/clapack/trunk/F2CLIBS/libF77
vendor/clapack/blas/SRC       svn+ssh://cugel/net/merlin/home-s/svk/Repository/csl/clapack/trunk/BLAS/SRC

   + doc/csl-docbook               svn+ssh://cugel/net/merlin/home-s/svk/Repository/csl/csl-docbook/trunk
vendor/atlas                  svn+ssh://cugel/net/merlin/home-s/svk/Repository/csl/atlas/trunk
vendor/lapack                 svn+ssh://cugel/net/merlin/home-s/svk/Repository/csl/lapack/trunk
vendor/clapack/SRC            svn+ssh://cugel/net/merlin/home-s/svk/Repository/csl/clapack/trunk/SRC
vendor/clapack/F2CLIBS/libF77 svn+ssh://cugel/net/merlin/home-s/svk/Repository/csl/clapack/trunk/F2CLIBS/libF77
vendor/clapack/blas/SRC       svn+ssh://cugel/net/merlin/home-s/svk/Repository/csl/clapack/trunk/BLAS/SRC


Index: ChangeLog
===================================================================
--- ChangeLog	(revision 171912)
+++ ChangeLog	(working copy)
@@ -1,5 +1,11 @@
 2007-05-22  Jules Bergmann  <jules@codesourcery.com>
 
+	* svn:externals: Remove externals for vendor/fft and tests/ref-impl.
+	  vendor/fft must be checked out manually.  test/ref-impl has been
+	  copied within SVN.
+
+2007-05-22  Jules Bergmann  <jules@codesourcery.com>
+
 	* src/vsip/opt/cbe/alf/src/ppu/GNUmakefile.inc.in: Guard dependency
 	  rule for ALF C files only.
 	* src/vsip/opt/simd/simd.hpp: Fix use of unavailable comparisons.
