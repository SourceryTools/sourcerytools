Index: ChangeLog
===================================================================
--- ChangeLog	(revision 174994)
+++ ChangeLog	(working copy)
@@ -1,3 +1,17 @@
+2007-07-02  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/core/expr/generator_block.hpp (Generator_expr_block):
+	  Remove use of missing define, use Local_or_global_map.
+	* src/vsip/core/parallel/scalar_block_map.hpp (impl_apply): Fix
+	  Wall warning.
+	* vendor/GNUmakefile.inc.in: Use $(MAKE) instead of make.
+	* configure.ac (--disable-shared-acconfig): New option, puts
+	  varying defines in acconfig.h instead of on command line.
+	  (fftw3_simd): New option, disables use of SIMD with builtin
+	  FFTW3.
+	* doc/quickstart/quickstart.xml: Document new configure options.
+	  Prefer "Cell/B.E.".
+	
 2007-06-26  Don McCoy  <don@codesourcery.com>
 
 	* src/vsip/core/mpi/services.hpp (VSIP_IMPL_MPI_H_TYPE): Fix typo 
Index: src/vsip/core/expr/generator_block.hpp
===================================================================
--- src/vsip/core/expr/generator_block.hpp	(revision 174994)
+++ src/vsip/core/expr/generator_block.hpp	(working copy)
@@ -49,11 +49,7 @@
 
   typedef value_type&         reference_type;
   typedef value_type const&   const_reference_type;
-#if VSIP_IMPL_GENERATOR_USE_LOCAL_OR_GLOBAL
   typedef Local_or_global_map<Dim> map_type;
-#else
-  typedef Local_map           map_type;
-#endif
 
 
   // Constructors.
Index: src/vsip/core/parallel/scalar_block_map.hpp
===================================================================
--- src/vsip/core/parallel/scalar_block_map.hpp	(revision 174994)
+++ src/vsip/core/parallel/scalar_block_map.hpp	(working copy)
@@ -87,7 +87,7 @@
   length_type impl_num_patches(index_type sb) const VSIP_NOTHROW
     { assert(sb == 0); return 1; }
 
-  void impl_apply(Domain<Dim> const& dom) VSIP_NOTHROW
+  void impl_apply(Domain<Dim> const& /*dom*/) VSIP_NOTHROW
     { assert(0); }
 
   template <dimension_type Dim2>
Index: vendor/GNUmakefile.inc.in
===================================================================
--- vendor/GNUmakefile.inc.in	(revision 173072)
+++ vendor/GNUmakefile.inc.in	(working copy)
@@ -74,26 +74,26 @@
 ##### RULES
 $(vendor_FLAPACK):
 	@echo "Building FLAPACK (see flapack.build.log)"
-	@make -C vendor/lapack/SRC all > flapack.build.log 2>&1
+	@$(MAKE) -C vendor/lapack/SRC all > flapack.build.log 2>&1
 
 $(vendor_CLAPACK):
 	@echo "Building CLAPACK (see clapack.build.log)"
-	@make -C vendor/clapack/SRC all > clapack.build.log 2>&1
+	@$(MAKE) -C vendor/clapack/SRC all > clapack.build.log 2>&1
 
 $(vendor_CLAPACK_BLAS):
 	@echo "Building CLAPACK BLAS (see clapack.blas.build.log)"
-	@make -C vendor/clapack/blas/SRC all > clapack.blas.build.log 2>&1
+	@$(MAKE) -C vendor/clapack/blas/SRC all > clapack.blas.build.log 2>&1
 
 $(vendor_LIBF77):
 	@echo "Building LIBF77 (see libF77.blas.build.log)"
-	@make -C vendor/clapack/F2CLIBS/libF77 all > libF77.blas.build.log 2>&1
+	@$(MAKE) -C vendor/clapack/F2CLIBS/libF77 all > libF77.blas.build.log 2>&1
 
 lib/libF77.a: $(vendor_LIBF77)
 	cp $< $@
 
 $(vendor_ATLAS_LIBS):
 	@echo "Building ATLAS (see atlas.build.log)"
-	@make -C vendor/atlas build > atlas.build.log 2>&1
+	@$(MAKE) -C vendor/atlas build > atlas.build.log 2>&1
 
 $(vendor_MERGED_LAPACK): $(vendor_LAPACK) $(vendor_PRE_LAPACK)
 	@echo "Merging pre-lapack and reference lapack..."
@@ -114,7 +114,7 @@
 
 clean::
 	rm -f lib/libF77.a
-	@make -C vendor/clapack/F2CLIBS/libF77 clean > libF77.blas.clean.log 2>&1
+	@$(MAKE) -C vendor/clapack/F2CLIBS/libF77 clean > libF77.blas.clean.log 2>&1
 endif
 
 ifdef BUILD_REF_LAPACK
@@ -135,7 +135,7 @@
 clean::
 	@echo "Cleaning ATLAS (see atlas.clean.log)"
 	@# If installing atlas from a tarball, a Makefile won't be there.
-	-@make -C vendor/atlas clean > atlas.clean.log 2>&1
+	-@$(MAKE) -C vendor/atlas clean > atlas.clean.log 2>&1
 	rm -f $(vendor_ATLAS)
 	rm -f vendor/atlas/lib/libcblas.a
 	rm -f $(vendor_MERGED_LAPACK)
Index: configure.ac
===================================================================
--- configure.ac	(revision 173072)
+++ configure.ac	(working copy)
@@ -14,8 +14,6 @@
 AC_REVISION($Revision: 1.110 $)
 AC_INIT(Sourcery VSIPL++, 1.3, vsipl++@codesourcery.com, sourceryvsipl++)
 
-neutral_acconfig="y"
-
 ######################################################################
 # Configure command line arguments.
 ######################################################################
@@ -36,6 +34,23 @@
    esac],
   [maintainer_mode=]) 
 AC_SUBST(maintainer_mode)
+
+# Determine whether acconfig should be "neutral".  A neutral acconfig
+# can be shared by different variants (parallel vs serial, IPP/MKL vs
+# builtin) in the same binary package.
+AC_ARG_ENABLE(shared-acconfig,
+  AS_HELP_STRING([--disable-shared-acconfig],
+                 [Do not attempt to make acconfig.hpp that can be shared
+	 	  by different configurations.  If you are configuring
+		  Sourcery VSIPL++ for use from eclipse and do not want
+		  to copy over a large number of defines, you should use
+		  this option.]),
+  [case x"$enableval" in
+    xyes) neutral_acconfig="y" ;;
+    xno)  neutral_acconfig="n" ;;
+    *)   AC_MSG_ERROR([Invalid argument to --disable-shared-acconfig.])
+   esac],
+  [neutral_acconfig="y"])
  
 AC_ARG_WITH(suffix,
   AS_HELP_STRING([--with-suffix=SUFFIX],
@@ -296,6 +311,14 @@
                  [Specify CFLAGS to use when building built-in FFTW3.
 		  Only used if --with-fft=builtin.]))
 
+AC_ARG_ENABLE(fftw3_simd,
+  AS_HELP_STRING([--disable-fftw3-simd],
+                 [Disable use of SIMD instructions by FFTW3.  Useful
+		  when cross-compiling for a host that does not have
+		  SIMD ISA]),,
+  [enable_fftw3_simd=yes])
+
+
 # LAPACK and related libraries (Intel MKL)
 
 # This option allows the user to OVERRIDE the default CFLAGS for CLAPACK.
@@ -1017,13 +1040,15 @@
     fftw3_f_simd=
     fftw3_d_simd=
     fftw3_l_simd=
-    case "$host_cpu" in
-      ia32|i686|x86_64) fftw3_f_simd="--enable-sse"
-	                 fftw3_d_simd="--enable-sse2" 
-	                 ;;
-      ppc*)             fftw3_f_simd="--enable-altivec" ;;
-      powerpc*)         fftw3_f_simd="--enable-altivec" ;;
-    esac
+    if test "$enable_fftw3_simd" = "yes"; then
+      case "$host_cpu" in
+        ia32|i686|x86_64) fftw3_f_simd="--enable-sse"
+	                  fftw3_d_simd="--enable-sse2" 
+	                  ;;
+        ppc*)             fftw3_f_simd="--enable-altivec" ;;
+        powerpc*)         fftw3_f_simd="--enable-altivec" ;;
+      esac
+    fi
     AC_MSG_NOTICE([fftw3 config options: $fftw3_opts $fftw3_simd.])
 
     # We don't export CFLAGS to FFTW configure because this overrides its
Index: doc/quickstart/quickstart.xml
===================================================================
--- doc/quickstart/quickstart.xml	(revision 173072)
+++ doc/quickstart/quickstart.xml	(working copy)
@@ -908,6 +908,19 @@
      </varlistentry>
 
      <varlistentry>
+      <term><option>--disable-fftw3-simd</option></term>
+      <listitem>
+       <para>
+        Disable builtin FFTW3 from using SIMD ISA extensions
+	(such as AltiVec or SSE2).  By default, FFTW3 uses
+	SIMD ISA extensions because they improve performance.
+	However, this option is useful when building for a platform
+	that does not support the ISA extensions.
+       </para>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
       <term><option>--with-lapack</option></term>
       <listitem>
        <para>
@@ -1066,8 +1079,8 @@
       <term><option>--enable-cbe-sdk</option></term>
       <listitem>
        <para>
-        Enable the use of the IBM Cell BE Software Development Kit
-        (SDK) if found.  Enabling the Cell BE SDK will accelerate the
+        Enable the use of the IBM Cell/B.E. Software Development Kit
+        (SDK) if found.  Enabling the Cell/B.E. SDK will accelerate the
         performance of FFTs, vector-multiplication, vector-matrix
 	multiplication, and fast convolution.
        </para>
@@ -1078,9 +1091,9 @@
       <term><option>--with-cbe-sdk-prefix=<replaceable>directory</replaceable></option></term>
       <listitem>
        <para>
-	Search for Cell BE SDK installation in
+	Search for Cell/B.E. SDK installation in
 	<replaceable>directory</replaceable> first.  This option has
-	the effect of enabling use of the Cell BE SDK (i.e.
+	the effect of enabling use of the Cell/B.E. SDK (i.e.
 	<option>--enable-cbe-sdk</option>).  This option is useful if the
 	SDK is installed in a non-standard location, or if multiple
 	SDK versions are installed.
@@ -1103,7 +1116,7 @@
       <term><option>--enable-numa</option></term>
       <listitem>
        <para>
-        Enable the use of libnuma.  This is useful on Cell BE systems
+        Enable the use of libnuma.  This is useful on Cell/B.E. systems
         to insure that SPE resources allocated for accelertion are
         local to the PPE running VSIPL++.
        </para>
@@ -1282,6 +1295,24 @@
       </listitem>
      </varlistentry>
 
+     <varlistentry>
+      <term><option>--disable-shared-acconfig</option></term>
+      <listitem>
+       <para>
+        Do not generate a acconfig.hpp that can be shared by
+	different configurations.  Instead generate an acconfig.hpp
+	file that can only be used by this configuration.
+
+	By default, a sharable acconfig.hpp is generated.  However,
+	this requires putting macros on the compiler command line,
+	which can be unwieldy unless automated by use of pkg-config.
+
+	This option is useful when building for a platform that
+	does not have or support pkg-config, such as Eclipse.
+       </para>
+      </listitem>
+     </varlistentry>
+
     </variablelist>
    </para>
 
@@ -1705,10 +1736,10 @@
    </section> <!-- Configuration Notes for Windows Systems -->
 
    <section id="cfg-cell-be">
-    <title>Configuration Notes for Cell BE Systems</title>
+    <title>Configuration Notes for Cell/B.E. Systems</title>
 
     <para>
-     When configuring Sourcery VSIPL++ for a Cell BE system, the
+     When configuring Sourcery VSIPL++ for a Cell/B.E. system, the
      following environment variables and configuration flags are
      recommended:
      <itemizedlist>
@@ -1716,8 +1747,8 @@
       <listitem>
        <para><option>--enable-cbe-sdk</option></para>
        <para>
-        Enable use of the Cell BE SDK.  This is necessary to use the
-        Cell BE's SPE processors to accelerate VSIPL++ functionaity.
+        Enable use of the Cell/B.E. SDK.  This is necessary to use the
+        Cell/B.E.'s SPE processors to accelerate VSIPL++ functionaity.
         If the SDK is not installed in the standard location, the
         <option>--with-cbe-sdk-prefix</option> should be used to
         specify the location.
@@ -1744,7 +1775,7 @@
      </itemizedlist>
     </para>
 
-   </section> <!-- Configuration Notes for Cell BE Systems -->
+   </section> <!-- Configuration Notes for Cell/B.E. Systems -->
 
    <section id="cfg-ref-impl">
     <title>Configuration Notes for the Reference Implementation</title>
