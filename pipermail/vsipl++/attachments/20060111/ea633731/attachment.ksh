Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.364
diff -u -r1.364 ChangeLog
--- ChangeLog	10 Jan 2006 21:35:53 -0000	1.364
+++ ChangeLog	11 Jan 2006 15:58:52 -0000
@@ -1,3 +1,3735 @@
+2006-01-11 Jules Bergmann  <jules@codesourcery.com>
+
+	* configure.ac: Check if -lblas is necessary for generic lapack.
+	* src/vsip/map.hpp (impl_subblock_from_global_index): New par
+	  support function to convert from global index to subblock.
+	* src/vsip/map_fwd.hpp: Add forward decls for Global_map and
+	  Local_or_global_map.
+	* src/vsip/math.hpp: Include global_map.hpp.
+	* src/vsip/impl/view_traits.hpp (Is_const_view_type): New trait.
+	* src/vsip/matrix.hpp (Is_const_view_type): New trait.
+	* src/vsip/tensor.hpp: Likewise.
+	* src/vsip/vector.hpp: Likewise.
+	* src/vsip/par-services.cpp (procesor_set): Memoize processor
+	  set returned from communicator pvec.
+	* src/vsip/parallel.hpp: Add headers for map and working-view.
+	  Move processor_set decl to ...
+	* src/vsip/impl/par-util.hpp: ... to here.
+	* src/vsip/random.hpp: Change return type to have Local_or_global_map.
+	* src/vsip/impl/block-traits.hpp (Choose_peb): New trait to
+	  choose the appropriate Par_expr_block variant when evaluating
+	  parallel expressions.
+	* src/vsip/impl/dispatch-assign.hpp: Update check for legal
+	  mixing local/global blocks.
+	* src/vsip/impl/distributed-block.hpp: Implement distribute get/put.
+	  Forward direct data interface calls.
+	* src/vsip/impl/expr_scalar_block.hpp: Add traits and functions
+	  necessary for parallel expressions.
+	* src/vsip/impl/general_dispatch.hpp: Change usage of Op_list_3
+	  to not hard-code assumption of which args are blocks.  Add
+	  Parallel_tag.
+	* src/vsip/impl/eval-blas.hpp: Update to new Op_list_3 usage.
+	* src/vsip/impl/matvec.hpp: Likewise.
+	* src/vsip/impl/global_map.hpp: Implement processor_begin/end
+	  and impl_local_from_global_index.
+	* src/vsip/impl/metaprogramming.hpp (Int_type): Utility to convert
+	  integral value to type.
+	* src/vsip/impl/par-chain-assign.hpp: Reorder allocations/deallocations
+	  to have mirrored order.
+	* src/vsip/impl/par-expr.hpp: Extend Par_expr_block to have multiple
+	  impl tags.  Add variant of Par_expr_block to directly reuse block.
+	* src/vsip/impl/par-services-mpi.hpp: Add additional MPI datatypes.
+	  New broadcast and allreduce communicator functions.  Memoize pvec.
+	* src/vsip/impl/par-services-none.hpp: New broadcast and allreduce
+	  communicator functions.  Memoize pvec.
+	* src/vsip/impl/reductions-idx.hpp: Apply general dispatch treatment.
+	* src/vsip/impl/reductions.hpp: Likewise.  Provide an evaluator for
+	  reductions on
+	* src/vsip/impl/reductions-types.hpp: New file, enumeration of
+	  reductions.
+	* src/vsip/impl/signal-conv-common.hpp: Use assign_local and woring
+	  view to work correctly with distributed arguments.
+	* src/vsip/impl/signal-conv-ext.hpp: Likewise.
+	* src/vsip/impl/solver-lu.hpp: Likewise.
+	* src/vsip/impl/solver-qr.hpp: Likewise.
+	* src/vsip/impl/solver-svd.hpp: Likewise.
+	* src/vsip/impl/vector-iterator.hpp: New file, iterate over values
+	  in a vector.
+	* src/vsip/impl/working-view.hpp: New file, helpers for converting
+	  between distributed and local views.
+	* tests/convolution.cpp: Add distributed cases.
+	* tests/reductions.cpp: Likewise.
+	* tests/solver-lu.cpp: Likewise.
+	* tests/solver-qr.cpp: Likewise.
+	* tests/solver-toepsol.cpp: Likewise.
+	* tests/distributed-getput.cpp: New test for distributed get/put.
+	* tests/expression.cpp: Add map include.
+	* tests/par_expr.cpp: Add coverage for expressions with scalars.
+	* tests/ref_conv.hpp: New file, reference implementation of conv.
+	* tests/solver-common.hpp: In-place version of test_ramp.
+	* tests/test-storage.hpp (Create_map): create maps of given type
+	  and dimension.  Add map parameter to Storage classes.
+	* tests/test.hpp: Make TEST_STRING work with cygwin.
+
+2006-01-10 Jules Bergmann  <jules@codesourcery.com>
+
+	* GNUmakefile.in: Include lib/GNUmakefile.inc
+	* configure.ac (with-g2c-copy): New option to copy libg2c.a into
+	  libdir.
+	* lib/GNUmakefile.inc.in: New file, install libs from libdir.
+
+2006-01-10  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* GNUmakefile.in: Add (packagesuffix) variable.
+	* tests/GNUmakefile.inc.in: expect qmtest to exit with 0 or 2.
+	* scripts/package: Use a config file for package layout info.
+
+2006-01-09 Jules Bergmann  <jules@codesourcery.com>
+
+	* tests/GNUmakefile.inc.in (check): Fix dependency on libs.
+	* vendor/GNUmakefile.inc.in (install): Add dependency to vendor_LIBS.
+
+2006-01-07  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* configure.ac: Revert Nathan's change from 2005-12-26 as as that
+	causes build failures due to MPI misconfiguration.
+	* src/vsip/impl/par-services-mpi.hpp: Likewise.
+	* GNUmakefile.in: Add 'mostlyclean' target.
+	* doc/GNUmakefile.inc.in: Make more rules dependent on $(srcdir) != '.'.
+	* tests/GNUmakefile.inc.in: Rename 'check-installed' to 'installcheck'
+	for standard conformance.
+	* vendor/GNUmakefile.inc.in: Make 'install' dependent on libs.
+	* scripts/package: Do a 'mostlyclean' before each new config build.
+
+2006-01-06  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* configure.ac: Allow (suffix) to be set during configuration.
+	* GNUmakefile.in: Honor (suffix) variable from configure, and better
+	handle binary package creation.
+	* doc/GNUmakefile.inc.in: Make doc2src dependent on doc.
+	* vsipl++.pc.in: Allow (suffix) to be set during configuration.
+	* scripts/package: New packaging driver script.
+
+2006-01-05  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* GNUmakefile.in: Make $(objects) and $(deps) lazy variables.
+	* tests/GNUmakefile.inc.in: Cleanup.
+
+2006-01-04  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* configure.ac: Test for synopsis.
+	* vsipl++.pc.in: Use PACKAGE_VERSION instead of VERSION.
+	* GNUmakefile.in: Add new targets 'sdist' and 'bdist',
+	and add support for $(DESTDIR).
+	* doc/GNUmakefile.inc.in: Add new 'doc2src' target and generally
+	enhance documentation generation.
+	* doc/Doxyfile.in: Build reference into doc/reference/reference.
+	* src/vsip/GNUmakefile.inc.in: Use $(DESTDIR).
+	* vendor/GNUmakefile.inc.in: Likewise.
+	* examples/GNUmakefile.inc.in: Likewise.
+	
+2005-12-28  Mark Mitchell  <mark@codesourcery.com>
+
+	* GNUmakefile.in (PACKAGE_TARNAME): New variable.
+	(PACKAGE_VERSION): Likewise.
+	(pkgdatadir): Likewise.
+	(datarootdir): Likewise.
+	(docdir): Use it.
+	(htmldir): New variable.
+	(pdfdir): Likewise.
+	(pdf_manuals): Likewise.
+	(html_manuals): Likewise.
+	(doc): Depend on html, pdf.
+	(html): New target.
+	(pdf): Likewise.
+	(install): Depend on install-pdf, install-html.
+	(install-pdf): New target.
+	(install-html): Likewise.
+	* configure.ac (AC_INIT): Set PACKAGE_TARNAME, correct
+	PACKAGE_NAME.
+	* doc/GNUmakefile.in: Adjust for improvements to csl-docbook,
+	toplevel GNUmakefile.
+	* examples/GNUmakefile.inc.in (examples/example1$(EXEEXT)): Depend
+	on $(libs).
+	(install): Use $(pkgdatadir).
+	* src/vsip/GNUmakefile.inc.in (libs): Make it a variable, not a
+	target.
+	* vendor/GNUmakefile.inc.in (libs): Likewise.
+	
+2005-12-26  Nathan Myers  <ncm@codesourcery.com>
+
+	* configure.ac, src/vsip/impl/par-services-mpi.hpp: find native MPI
+	  installations, correctly extract build options using C-only libs.
+
+2005-12-23  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* tests/GNUmakefile.inc.in: Add new check-installed target.
+	* tests/context-installed.pre.in: New context file for testing
+	installed packages.
+
+2005-12-23  Nathan Myers  <ncm@codesourcery.com>
+	
+	* configure.ac, vendor/GNUmakefile.inc.in: Add configure options
+	  --disable-fft-double etc., and arrange not to build/install/clean
+	  built-in FFTW3 libs so disabled.
+
+2005-12-23  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* doc/GNUmakefile.inc.in: Fix typo.
+
+2005-12-22  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* GNUmakefile.in: Define and use 'suffix' during installation.
+	* vsipl++.pc.in: Process during configuration and post-process during
+	installation to set suffix variable.
+	* src/vsip/GNUmakefile.inc.in: Use suffix variable for the final
+	library name.
+
+2005-12-21  Don McCoy  <don@codesourcery.com>
+
+	* configure.ac: added --with-fft=none option.
+
+2005-12-21  Nathan Myers  <ncm@codesourcery.com>
+
+	* src/vsip/fft-core.hpp: mention long double in comments
+	* src/vsip/fft-ldouble.cpp: new file, long-double element FFTs
+	* tests/fft.cpp, tests/fftm.cpp: add tests for long double.
+	* tests/fft.cpp: typo; test variant data organizations & axes
+	  with float, double or long double, whichever is first found 
+	  to be supported.
+
+2005-12-21  Nathan Myers  <ncm@codesourcery.com>
+
+	* configure.ac, vendor/GNUmakefile.inc.in: fix "make clean"
+	  for fftw libs, other cleanup, install in $(libdir).
+
+2005-12-21 Jules Bergmann  <jules@codesourcery.com>
+
+	* benchmarks/main.cpp: Add sanity check if library is configured
+	  with usable profile timer.
+	* benchmarks/mcopy.cpp: Add plainblock case.
+	* benchmarks/prod.cpp: Add plainblock case.
+	* benchmarks/prod_var.cpp: Renumber benchmark cases from (not 0).
+	* benchmarks/vmul.cpp: Add scalar*vector case.
+	* src/vsip/dense.hpp: Implement 2-arg and 3-arg get/put directly
+	  instead of abstracting through Point. 
+	* src/vsip/impl/dispatch-assign.hpp: Use Serial_dispatch for
+	  matrices.  Decompose tensor assignment to matrix when dimension
+	  ordering consistent.
+	* src/vsip/impl/expr_serial_dispatch.hpp: Add transpose tag to
+	  LibraryTagList.
+	* src/vsip/impl/expr_serial_evaluator.hpp: Add general loop-fusion
+	  matrix expression evaluator.  Add matrix transpose evaluator.
+	* src/vsip/impl/fast-transpose.hpp: New file, cache-oblivious
+	  transpose algorithm.
+	* src/vsip/impl/ipp.cpp: Add wrappers for IPP scalar-view add, sub,
+	  mul, div.
+	* src/vsip/impl/ipp.hpp: Add evaluators for IPP scalar-view add, sub
+	  mul, div.
+	* src/vsip/impl/profile.hpp: Define DefaultTime::valid to indicate
+	  if profile timer is enabled.
+	* src/vsip/impl/vmmul.hpp: Add general evaluator for vector-matrix
+	  multiply.  Decomposes into individual vector-vector or scalar-vector
+	  multiplies.
+	* tests/matvec-prod.cpp: Remove unnecessary include.
+	* tests/scalar-view.cpp: New file, coverage tests for scalar-view
+	  operators (+, -, *, /).
+
+2005-12-21 Jules Bergmann  <jules@codesourcery.com>
+
+	* configure.ac: Don't build builtin FFTW3 when asked to use another
+	  FFT library than FFTW3.
+
+2005-12-21  Nathan Myers  <ncm@codesourcery.com>
+
+	* configure.ac, vendor/fftw/simd/sse.c, vendor/fftw/simd/sse2.c:
+	  enable using SSE/SSE2 on x86-64.
+	* vendor/GNUmakefile.inc.in: improve build status reports.
+	* configure.ac, GNUmakefile.in, tests/context.in:
+	  rearrange -I, -L so compiler will find internal includes & libs
+	  first, installed ones second, environment ones last.
+
+2005-12-20  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* synopsis.py.in: Additional code not yet part of the last (0.8) release.
+
+2005-12-20  Nathan Myers  <ncm@codesourcery.com>
+
+	* configure.ac: Integrate FFTW3 configure.
+	* vendor/GNUmakefile.inc.in: Integrate FFTW3 build and install.
+
+2005-12-20  Don McCoy  <don@codesourcery.com>
+
+	* GNUmakefile.in: moved variables for detecting libraries to here.
+	* configure.ac: create additional output varibles for same.
+	* benchmarks/GNUmakefile.inc.in: modified to remove tests that are
+	  dependent on libraries that are not available.  fixed 'bench' to
+	  only build those tests.  deleted debugging target.
+	* benchmarks/dot.cpp: corrected evaluator tag for vector-vector 
+	  dot product.
+	* src/vsip/GNUmakefile.inc.in: moved variables to top-level makefile.
+	* vendor/lapack/make.inc: removed.
+
+2005-12-20 Jules Bergmann  <jules@codesourcery.com>
+
+	Add missing conversions for Lvalue_proxy.  Fixes issue #51.
+	* src/vsip/impl/lvalue-proxy.hpp: Add operator= specializations
+	  for lvalues of complex.
+	* tests/test.hpp: Add equal specialization for Lvalue_proxies.
+
+	* tests/*.{hpp,cpp}: Use test_assert() instead of assert().
+	* tests/output.hpp: Move definitions into vsip namespace.
+	* src/vsip/impl/signal-fir.hpp: Fix Wall warnings.
+
+2005-12-19 Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/signal.hpp: Include signal-iir.
+	* src/vsip/impl/signal-iir.hpp: New file, direct implementation of
+	  IIR filter.
+	* tests/iir.cpp: New file, unit tests for IIR filter.
+
+	* src/vsip/impl/signal-fir.hpp: Move obj_state enum to ...
+	* src/vsip/impl/signal-types.hpp: ... here.
+
+2005-12-19 Jules Bergmann  <jules@codesourcery.com>
+
+	* benchmarks/fastconv.cpp: Add new case using out-of-place FFT to
+	  perform in-place FFTM.  Parallel this case and single-loop case.
+	* benchmarks/fftm.cpp: New file, benchmarks for Fftm.
+	* benchmarks/loop.hpp: Print case number to output.
+	* benchmarks/main.cpp: Likewise.
+	* benchmarks/vmmul.cpp: New file, benchmarks for vector-matrix mul.
+	* benchmarks/vmul_ipp.cpp: Add benchmarks for in-place element-wise
+	  vector multiply.
+	* src/vsip/impl/dist.hpp: Add constructor taking number of subblocks.
+
+2005-12-19  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* GNUmakefile.in: Generate vsipl++.pc during installation.
+	* vsipl++.pc.in: Adjust template to be used during installation.
+
+2005-12-14  Mark Mitchell  <mark@codesourcery.com>
+
+	* GNUmakefile.in (maintainer_mode): New variable.  Do not define
+	documentation variables in maintainer mode.
+	(subdirs): Remove doc/tutorial.
+	* configure.ac (maintainer-mode): New variable.
+	(cpu_mhz): Fix typo in help string.
+	* doc/GNUmakefile.inc.in: Build the tutorial here too.
+	* doc/tutorial/tutorial.css: Remove.
+	* doc/tutorial/GNUmakefile.inc.in: Likewise.
+
+2005-12-14  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* doc/tutorial/images/corner-turn.png: New file.
+	* doc/tutorial/images/corner-turn.svg: New file.
+	* doc/tutorial/src/corner-turn.hpp: New file.
+	* doc/tutorial/src/user_block.hpp: New file.
+	* doc/tutorial/optimization.xml: New file.
+	* doc/tutorial/tutorial.css: Highlight remarks.
+	* doc/tutorial/overview.xml: Center images.
+	
+2005-12-13 Jules Bergmann  <jules@codesourcery.com>
+
+	* benchmarks/GNUmakefile.inc.in: Use EXEEXT and OBJEXT.
+	* benchmarks/loop.hpp: Add missing include, use parallel.hpp
+	  instead of impl/global_map.
+	* src/vsip/impl/setup-assign.hpp: Make Holder_base destructor
+	  inline.
+	* tests/test.hpp: Fix test_assert to work with Greenhills.
+
+2005-12-12  Mark Mitchell  <mark@codesourcery.com>
+
+	* GNUmakefile.in: Rely on csl-docbook/GNUmakefile.inc for DocBook
+	rules.
+	* doc/tex.dsl: Remove.
+	* doc/wraptex: Likewise.
+
+2005-12-12 Jules Bergmann  <jules@codesourcery.com>
+
+	Implement 2-D correlation.
+	* src/vsip/impl/signal-corr-common.hpp: Extend Is_corr_impl_avail
+	  to include dimension.  Compute unbiased scaling factor directly
+	  rather than by accumulation.  Implement 2-D correlation.
+	* src/vsip/impl/signal-corr-ext.hpp: Implement 2-D correlation.
+	* src/vsip/impl/signal-corr-opt.hpp: Update Is_corr_impl_avail.
+	* src/vsip/impl/signal-corr.hpp: Implement 2-D correlation.
+	* tests/corr-2d.cpp: New file, tests for 2-D correlation.
+	* tests/correlation.cpp: Move common functionality into error_db
+	  and ref_corr headers.
+	* tests/error_db.hpp: New file, common impl of error_db function.
+	* tests/ref_corr.hpp: New file, reference implementation of 1-D
+	  and 2-D correlation.
+	* tests/test.hpp (test_assert): New macro for assertions, not
+	  disabled by NDEBUG.
+
+	* src/vsip/impl/fns_scalar.hpp: Add scalar ite.
+	* src/vsip/impl/fns_elementwise.hpp: Add element-wise ite.
+
+2005-12-12  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* GNUmakefile.in: Adjust for more robust 'install' target.
+	* doc/tutorial/GNUmakefile.inc.in: Robustify 'install' target.
+	* src/vsip/GNUmakefile.inc.in: Likewise.
+	* doc/csl-docbook/xsl/html/csl.xsl: Remove debug output.
+
+2005-12-06  Don McCoy  <don@codesourcery.com>
+
+	* src/vsip/signal-window.cpp: replaced ramp, clip and frequency
+	  swap inline code with library functions.
+	* src/vsip/signal-window.hpp: deleted unneeded function
+	  impl::frequency_swap().
+
+2005-12-06 Jules Bergmann  <jules@codesourcery.com>
+
+	* doc/quickstart/quickstart.xml: Fix typo.  Bump version to 0.95.
+
+2005-12-05 Jules Bergmann  <jules@codesourcery.com>
+
+	* configure.ac (CPPFLAGS): Add -I for ATLAS include directory.
+
+2005-12-05 Jules Bergmann  <jules@codesourcery.com>
+
+	* configure.ac: Use with-lapack=PKGS to set lapack_trypkg.
+	  Fix bug in determining my_abs_top_srcdir.
+
+2005-12-05 Jules Bergmann  <jules@codesourcery.com>
+
+	* doc/quickstart/quickstart.xml: Document configure options.
+	* src/vsip/parallel.hpp: Put processor_set decl in vsip namespace.
+	* tests/ref-impl/selgen.cpp: Use clip/invclip API in current spec.
+
+2005-12-05  Don McCoy  <don@codesourcery.com>
+
+	* src/vsip/signal.hpp: new header for histograms.
+	* src/vsip/impl/signal-histogram.hpp: implements Histogram class
+	  [signal.histo].
+	* tests/histogram: new tests for above.
+
+2005-12-05  Don McCoy  <don@codesourcery.com>
+
+	* src/vsip/signal.hpp: added new header for freqswap.
+	* src/vsip/impl/signal-freqswap.hpp: implements frequency
+	  swapping functions [signal.freqswap].
+	* tests/freqswap.cpp: tests for above.
+
+2005-12-05 Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/support.hpp: Correct return type in declaration of
+	  num_processors().  Move processor_set() declaration to ...
+	* src/vsip/parallel.hpp: ... here.
+	
+2005-12-05 Jules Bergmann  <jules@codesourcery.com>
+
+	Fix issue #96
+	* src/vsip/impl/eval-blas.hpp: Perform row-major outer product
+	  without changing input vectors.
+
+2005-12-05 Jules Bergmann  <jules@codesourcery.com>
+
+	Update parallel support functions to match parallel specification
+	version 0.9.
+	* src/vsip/map.hpp: Include global_map.  Change map interface
+	  to match par spec version 0.9.
+	* src/vsip/impl/global_map.hpp: Likewise.
+	* src/vsip/impl/local_map.hpp: Likewise.
+	* src/vsip/par-services.cpp: Add processor_set and local_processor
+	  PSF functions.
+	* src/vsip/support.hpp: Remove subblock_type.  Add distribution_type
+	  other.
+	* src/vsip/impl/dist.hpp: Add impl_global_from_local_index
+	  members.  Use index_type instead of subblock_type.
+	* src/vsip/impl/distributed-block.hpp: Remove subblocks_begin/end.
+	  PSF name changes.
+	* src/vsip/impl/view_traits.hpp: Add local() member function to views.
+	* src/vsip/dense.hpp: Use index_type instead of subblock_type.
+	* src/vsip/impl/expr_generator_block.hpp: Likewise.
+	* src/vsip/impl/subblock.hpp: Likewise
+	* src/vsip/impl/par-assign.hpp: PSF name changes.
+	* src/vsip/impl/par-chain-assign.hpp: Likewise.
+	* src/vsip/impl/par-expr.hpp: Likewise.
+	* src/vsip/impl/par-foreach.hpp: Add in-place variation.  PSF name
+	  changes.
+	* src/vsip/impl/par-util.hpp: PSF name changes and updates.
+	* src/vsip/impl/setup-assign.hpp: PSF name changes.
+
+	Update tests to match parallel spec.
+	* tests/appmap.cpp: PSF name changes.
+	* tests/distributed-block.cpp: Likewise.
+	* tests/distributed-subviews.cpp: Likewise.
+	* tests/distributed-user-storage.cpp: Likewise.
+	* tests/map.cpp: Likewise.
+	* tests/par_expr.cpp: Likewise.
+	* tests/util-par.hpp: Likewise.
+	* tests/vmmul.cpp: Likewise.
+
+	* benchmarks/loop.hpp: Support for parallel benchmarks.
+	* benchmarks/fastconv.hpp: New file, benchmark for fast convolution.
+	* benchmarks/mcopy.hpp: New file, benchmark for matrix copy.
+	* benchmarks/prod_var.hpp: New file, benchmark for prod() variations.
+
+2005-12-04 Jules Bergmann  <jules@codesourcery.com>
+
+	* autogen.sh: check if vendor/atlas/autogen.sh is present before
+	  running.
+	* configure.ac: Always pull in IPP image-processing library
+	  when IPP enabled.  Fix typo: with-atlas-libdir should enable
+	  lapack.  Fix -I.../vendor/atlas/include for INT_CPPFLAGS to
+	  be correct when srcdir is relative.
+	* src/vsip/matrix.hpp (view_domain): New function, return domain
+	  of view.
+	* src/vsip/tensor.hpp: Likewise.
+	* src/vsip/impl/ipp.cpp (conv_full_2d, conv_valid_2d): New
+	  functions, wrappers for 2-D IPP convolutions.
+	* src/vsip/impl/ipp.hpp: Likewise.
+	* src/vsip/impl/signal-conv-common.hpp (Is_conv_impl_avail):
+	  Add template parameter for convolution dimension.
+	  (conv_kernel): New function overload for 2D kernels.
+	  (conv_full, conv_same, conv_min): New functions, generic
+	  2D convolutions for different regions of support.
+	  (conv_same_edge): New function, perform edge portion of
+	  same-support convolution.
+	  (conv_same_example): New function, example of using
+	  conv_min and conv_same_edge to perform conv_same.
+	* src/vsip/impl/signal-conv-ext.hpp: Implement 2-D convolution.
+	* src/vsip/impl/signal-conv-ipp.hpp: Likewise.
+	* src/vsip/impl/signal-conv-sal.hpp: Update Is_conv_impl_avail.
+	* src/vsip/impl/signal-conv.hpp: Likewise.
+	* tests/conv-2d.cpp: New file, unit tests for 2-D convolution.
+	
+	* src/vsip/impl/eval-blas.hpp: Fix Wall warnings.
+	* src/vsip/impl/matvec.hpp: Likewise.
+	
+2005-12-02 Jules Bergmann  <jules@codesourcery.com>
+
+	* configure.ac: Cleanup handling of lapack options by
+	  merging --enable-lapack functionality into --with-lapack.
+
+2005-12-01 Jules Bergmann  <jules@codesourcery.com>
+
+	* configure.ac (with-mkl-arch): New option to set MKL arch library
+	  sub-directory.  Default is to deduce arch based on host_cpu.
+	  (--disable-cblas): New option to disable use of CBLAS API and
+	  use fortran BLAS API instead.  Default is to use CBLAS API,
+	  which avoids problems with calling fortran functions from C++.
+	  (--with-g2c-path): New option to specify path for libg2c.a.
+	  (VSIP_IMPL_FORTRAN_FLOAT_RETURN): New AC_DEFINE for the C
+	  return type of a fortran real function.
+	  (--with-mkl-prefix): Change behavior, previously PATH was
+	  the library directory, now it is the prefix above library
+	  and include directories.  Old help string was correct.
+	* GNUmakefile.in: Substitute INT_CPPFLAGS.
+	* tests/context.in: Likewise.
+	* src/vsip/impl/lapack.hpp: Support CBLAS API.
+	* vendor/GNUmakefile.inc.in: Install ATLAS cblas header.
+	* vendor/lapack/make.inc.in: Substitute FFLAGS.
+
+2005-12-01 Jules Bergmann  <jules@codesourcery.com>
+
+	Integrate ATLAS and LAPACK into VSIPL++ source tree.
+	* autogen.sh: process configure.ac in vendor/atlas directory.
+	* configure.ac: Configuration support for builtin lapack library.
+          (disable-builtin-lapack): New option to disable
+	  consideration of builtin lapack (ATLAS).
+	  (--with-lapack): New option to specify lapack library(libraries)
+	  to consider.
+	* GNUmakefile.in (LDFLAGS): Add internal ld flags (@INT_LDFLAGS@).
+	  (libs): New target for libraries necessary to build executables.
+	* src/vsip/GNUmakefile.inc.in (libs): Add dependency to
+	  src/vsip/libvsip.a
+	* examples/GNUmakefile.inc.in: Add dependency to 'libs' target.
+	* tests/GNUmakefile.inc.in (check): Add dependency to libs.
+	* tests/context.in (cxx_options): Add internal ld flags (@INT_LDFLAGS@)
+	* vendor/GNUmakefile.inc.in: New file, brige from VSIPL++
+	  integrate makefile to ATLAS and LAPACK build/make.
+
+	Autoconf for ATLAS.
+	* vendor/atlas/autogen.sh: New file, generate vendor/atlas
+	  configure scripts.
+	* vendor/atlas/configure.ac: New file, autoconf script for ATLAS.
+	* vendor/atlas/csl-scripts/convert-makefile.pl: New file, convert
+	  ATLAS makes/Make.xxx files to CSL Makefile.in files.
+	* vendor/atlas/csl-scripts/create-makeinc.pl: New file, create
+	  per-directory Make.inc files.
+	* vendor/atlas/csl-scripts/convert.sh: New file, wrapper around
+	  convert-makefile.pl and create-makeinc.pl.  Called by autogen.sh.
+	* vendor/atlas/GNUmakefile.in: New file, top-level makefile for
+	  ATLAS.
+	* vendor/atlas/Make.ARCH.in: New file, template Make.ARCH file.
+	* vendor/atlas/bin/ATLrun.sh.in: New file, script to run executable.
+
+	* vendor/atlas/tune/blas/gemm/tfc.c: Fix bug causing heap
+	  corruption.
+
+	Misc. changes to build atlas out of the source directory
+	and prevent compiler warnings.
+	* vendor/atlas/makes/Make.bin: Support build dir different from
+	  source dir.
+	* vendor/atlas/tune/blas/gemm/emit_mm.c: Increase string size to
+	  avoid overrun.  Support build dir different from source dir.
+	* vendor/atlas/bin/atlas_install.c: Assert that defaults are found.
+	* vendor/atlas/bin/atlas_tee.c: Add missing include.
+	* vendor/atlas/bin/atlas_waitfile.c: Likewise.
+	* vendor/atlas/bin/ccobj.c: Likewise.
+	* vendor/atlas/include/contrib/ATL_gemv_ger_SSE.h: Likewise.
+	* vendor/atlas/src/auxil/ATL_buildinfo.c: Likewise.
+	* vendor/atlas/tune/blas/gemm/usercomb.c: Likewise.
+	* vendor/atlas/tune/blas/gemv/gemvtune.c: Likewise.
+	* vendor/atlas/tune/blas/ger/ger1tune.c: Likewise.
+	* vendor/atlas/tune/blas/gemv/mvsearch.c: Add missing include,
+	  automatically rerun if variation exceeds tolerance.
+	* vendor/atlas/tune/blas/ger/r1search.c: Likewise.
+	* vendor/atlas/tune/blas/gemm/ummsearch.c: Support build dir
+	  different from source dir.
+	* vendor/atlas/tune/blas/gemm/userindex.c: Likewise.
+	* vendor/atlas/tune/blas/level1/asumsrch.c: Likewise.
+	* vendor/atlas/tune/blas/level1/axpbysrch.c: Likewise.
+	* vendor/atlas/tune/blas/level1/axpysrch.c: Likewise.
+	* vendor/atlas/tune/blas/level1/copysrch.c: Likewise.
+	* vendor/atlas/tune/blas/level1/cpscsrch.c: Likewise.
+	* vendor/atlas/tune/blas/level1/dotsrch.c: Likewise.
+	* vendor/atlas/tune/blas/level1/iamaxsrch.c: Likewise.
+	* vendor/atlas/tune/blas/level1/nrm2srch.c: Likewise.
+	* vendor/atlas/tune/blas/level1/rotsrch.c: Likewise.
+	* vendor/atlas/tune/blas/level1/scalsrch.c: Likewise.
+	* vendor/atlas/tune/blas/level1/setsrch.c: Likewise.
+	* vendor/atlas/tune/blas/level1/swapsrch.c: Likewise.
+	* vendor/atlas/tune/sysinfo/masearch.c: Add missing headers.
+	  Put missing headers in generated programs.
+
+	Fit LAPACK into autoconf build.
+	* vendor/lapack/make.inc.in: LAPACK make include template.
+	* vendor/lapack/SRC/GNUmakefile.in: New file, Makefile
+	  template for LAPACK.
+
+2005-11-30  Don McCoy  <don@codesourcery.com>
+
+	* src/vsip/impl/matvec.hpp: added modulate function [math.matvec.misc].
+	* tests/matvec.cpp: new tests for same.
+
+2005-11-28  Don McCoy  <don@codesourcery.com>
+
+	* configure.ac: corrected macro for detecting presence of SAL
+	* src/vsip/impl/sal.hpp: added convolution function overloaded
+	  for float and complex<float>.
+	* src/vsip/impl/signal-conv-sal.hpp: new file.  implements 
+	  convolution using Mercury SAL library.
+	* src/vsip/impl/signal-conv.hpp: searches for SAL tag when
+	  choosing convolution functions.
+	* tests/convolution.cpp: added new tests for support of 
+	  non-unit stride data.
+
+2005-11-28 Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/extdata.hpp (is_direct_ok): Merge if statements to
+	  avoid GHS warnings about unreachable statements.
+	* configure.ac: Set configure's internal variables for object and
+	  executable extenions.
+	
+2005-11-22  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* src/vsip/complex.hpp: Fix for ghs.
+
+2005-11-17  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* src/vsip/impl/fns_elementwise.hpp: Fix for ghs.
+	* src/vsip/complex.hpp: Add missing functions.
+	* tests/complex.cpp: Test them.
+
+2005-11-16  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* tests/QMTest/vxworks.py: New infrastructure for cross-testing.
+
+	* src/vsip/support.hpp: Qualify call to fatal_exception()
+	* src/vsip/impl/fns_userelt.hpp: Fix use of 
+	std::pointer_to_unary_function
+	* tests/util-par.hpp: Replace use of cbrt(x) by exp(log(x)/3)
+	
+2005-11-15  Don McCoy  <don@codesourcery.com>
+
+	* tests/matvec-prod.cpp: added tests for special cases such
+	  as split complex layout and subviews (different strides).
+	* src/vsip/impl/eval-sal.hpp: new file.  dispatch routines
+	  for matrix/vector products, outer and gemp.
+	* src/vsip/impl/matvec-prod.hpp: include eval-sal.hpp.
+	* src/vsip/impl/matvec.hpp: include eval-sal.hpp and math-enum.hpp.
+	* src/vsip/impl/sal.hpp: added new overloaded translation 
+	  functions for matrix/vector products, outer and gemp.
+
+2005-11-14  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* src/vsip/map.hpp: Change case ordering in switch statement to always have
+	a return value.
+	* src/vsip/support.hpp: Enable __attribute__((__noreturn__)) for ghs.
+	* src/vsip/impl/dist.hpp: Remove obsolete dummy return statements.
+
+2005-11-11  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* src/vsip/impl/fns_elementwise.hpp: Enable unary operators only for
+	view types.
+	* tests/vector.cpp: Add missing tests for unary operators.
+
+2005-11-11 Jules Bergmann  <jules@codesourcery.com>
+
+	* configure.ac (VSIP_IMPL_FIX_MISSING_ABS): New define, set if
+	  missing std::abs overloads for float and double.
+	* src/vsip/impl/fns_scalar.hpp (mag, magsq): Use abs_detail::abs
+	  instead of std::abs.  Set abs_detail::abs based on
+	  VSIP_IMPL_FIX_MISSING_ABS.
+	* src/vsip/impl/general_dispatch.hpp: When dispatch fail, throw
+	  exception rather than assert.
+	* tests/test.hpp: Use vsip::mag instead of std::abs.
+	
+2005-11-11  Don McCoy  <don@codesourcery.com>
+
+	* tests/sal-assumptions.cpp: corrected unconditional dependency on SAL.
+
+2005-11-11  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* src/vsip/vector.hpp: Work around ghs bug.
+	* doc/csl-docbook/xsl/html/csl.xsl: Fix tutorial building outside the
+	source tree.
+
+2005-11-10  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* doc/tutorial/*: New tutorial sources.
+	* GNUmakefile.in: Build it.
+	* doc/csl-docbook/xsl/html/csl.xsl: Fine tune xslt parameters.
+	* configure.ac: Allow to explicitely set object and executable extensions.
+	* src/vsip/map.hpp: Add missing exception-specifiers.
+	* src/vsip/impl/fns_scalar.hpp: Include <cstdlib> to work around ghs issue.
+	
+2005-11-10  Don McCoy  <don@codesourcery.com>
+
+	* tests/matvec-prod.cpp: Re-arranged tests to avoid running tests
+	  repeatedly with the same ordering.  Added tests for vector-matrix
+	  and matrix-vector products.
+	* tests/matvec.cpp: added test for outer().
+	* tests/ref_matvec.hpp: modified ref::outer() to conjugate complex
+	  values.  Added vector-vector product to use for matrix-matrix
+	  product.  Added v-m and m-v products as well.
+	* src/vsip/impl/eval-blas.hpp: Added evaluators for BLAS outer,
+	  m-v prod, v-m prod and general matrix multiply (gemm).  Fixed
+	  a bug in the runtime check for m-m prod that only affected
+	  col-major cases.
+	* src/vsip/impl/general_dispatch.hpp: Added operation tags for
+	  m-v and v-m products.  New implementation tag for SAL.  New
+	  wrapper classes for operand lists of 3 and 4 arguments along
+	  with the corresponding dispatch classes.
+	* src/vsip/impl/lapack.hpp: Included prototypes for gemv and ger
+	  BLAS functions with overloaded wrappers for calling them.
+	* src/vsip/impl/matvec-prod.hpp: Added generic evaluators for
+	  m-v and v-m products.  Added dispatch functions for same.
+	* src/vsip/impl/matvec.hpp: Same as above for outer and gemp.
+
+2005-11-02 Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/block-copy.hpp: Extend Block_fill to handle
+	  distributed blocks and 1-dim blocks.
+	* src/vsip/impl/block-traits.hpp: Add Is_par_reorg_ok trait.
+	* src/vsip/impl/dispatch-assign.hpp: Use Is_par_reorg_ok to determine
+	  if parallel expression can be reorganized.
+	* src/vsip/impl/dist.hpp: Add missing body for Whole_dist constructor.
+	* src/vsip/impl/distributed-block.hpp: Implement release and find
+	  for Distributed_block.
+	* src/vsip/impl/expr_binary_block.hpp: Specialize Is_par_reorg_ok
+	  for binary expressions.
+	* src/vsip/impl/expr_ternary_block.hpp: Define parallel traits
+	  and functions (Distributed_local_block, get_local_block,
+	  Combine_return_type, apply_combine, apply_leaf, Is_par_same_map,
+	  and Is_par_reorg_ok).
+	* src/vsip/impl/expr_unary_block.hpp: Likewise.
+	* src/vsip/impl/global_map.hpp: Specialize Is_global_only and
+	  Map_equal for Global_maps.
+	* src/vsip/impl/local_map.hpp: Specialize Is_local_only and
+	  Is_global_only for Local_maps.
+	* src/vsip/impl/map-traits.hpp: New file, traits for maps.
+	* src/vsip/impl/subblock.hpp (Diag_block): Use size() to compute
+	  size(1, 0).
+	* src/vsip/impl/vmmul.hpp: Use expression template block to evaluate
+	  vmmul.
+	* src/vsip/map.hpp: Add map_equiv, like op== but only requires
+	  processors match upto number of subblocks.  Use for Map_equal.
+	* src/vsip/vector.hpp: Use Block_fill for scalar assignment.
+	* tests/distributed-subviews.cpp (dump_map): Move from ...
+	* tests/util-par.hpp: ... to here.
+	* tests/util-par.hpp: Update dump_view to single subblock per
+	  processor.  Fix Check_identity to work with negative k.
+	* tests/extdata-output.hpp: Recognize Global_map, Local_map, and
+	  Local_or_global_map.
+	* tests/par_expr.cpp: Extend coverage to parallel expressions with
+	  unary and ternary operators.
+	* tests/vmmul.cpp: Add coverage for parallel vmmul cases.
+
+2005-10-31  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* synopsis.py.in: New synopsis driver script.
+	* GNUmakefile.in: Add rules for ref manual generation via synopsis.
+	* configure.ac: Fix typo in help string.
+	* src/vsip/impl/subblock.hpp: Adjust code to make it synopsis-parsable.
+	* tests/QMTest/vpp_database.py: Fix typo.
+	
+2005-10-28 Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/lapack.hpp: Treat FORTRAN functions returning
+	  complex values as subroutines.
+
+2005-10-27  Nathan Myers  <ncm@codesourcery.com>
+
+	* src/vsip/impl/ipp.cpp, sal.cpp: remove inglorious #ifdefs, defer
+	  to src/vsip/GNUmakefile.in.inc.
+	* src/vsip/impl/signal-fir.hpp: document FIR driver control flags,
+	  remove FIXME for logged spec bug.
+
+2005-10-25  Nathan Myers  <ncm@codesourcery.com>
+
+	* src/vsip/impl/ipp.cpp, src/vsip/impl/signal-fir.hpp:
+	  Use native C++ FIR code for all types and modes not supported 
+	  by IPP FIR.  Confine Intel ipp*.h includes to ipp.cpp where
+	  users' code will not be exposed to them.
+
+2005-10-24  Nathan Myers  <ncm@codesourcery.com>
+
+	* configure.ac: fix help for "--enable-profile-timer".
+	* src/vsip/impl/sal.cpp: #if out if SAL not configured.
+	* src/vsip/impl/signal-fir.hpp: robustify assertions; make copy-ctor
+	  copy output size, fix overload ambiguity copying state_ member; 
+	  make op= return *this; make reset() clear state more thoroughly. 
+	* tests/fir.cpp: test copy ctor more thoroughly.
+	* benchmarks/fir.cpp: new.
+	* benchmarks/loop.hpp: quiet printf-format warnings.
+
+2005-10-14  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* src/vsip/impl/ipp.hpp: Explicitely test for Cmplx_inter_fmt as IPP
+	doesn't support Cmplx_split_fmt.
+	* doc/Doxyfile: Transformed into...
+	* doc/Doxyfile.in: ...this to generate the correct path to the sources
+	during configure.
+	* doc/GNUmakefile.inc.in: Use the generated Doxyfile.
+
+2005-10-14  Don McCoy  <don@codesourcery.com>
+
+	* configure.ac (--enable-sal, --with-sal-include, --with-sal-lib):
+	  New options to add support for SAL.
+	* src/vsip/GNUmakefile.inc.in: conditionally added sal.cpp.
+	* src/vsip/impl/expr_serial_dispatch.hpp: added mercury SAL tag.
+	* src/vsip/impl/expr_serial_evaluator.hpp: likewise.
+	* src/vsip/impl/sal.cpp: new file, wrappers for +-*/ incl. for
+	  real, complex and complex-split types.
+	* src/vsip/impl/sal.hpp: likewise.
+	* tests/elementwise.cpp: new tests for external libraries providing
+	  elementwise funtions.
+	* tests/sal-assumptions.cpp: verifies assumptions regarding complex
+	  split layout when using SAL library.
+
+2005-10-13  Nathan Myers  <ncm@codesourcery.com>
+
+	* src/vsip/impl/signal-fir.hpp: use IPP FIR support where available.
+	* tests/fir.cpp: forgive FFT noise on big samples.
+
+2005-10-12 Jules Bergmann  <jules@codesourcery.com>
+
+	* configure.ac (--with-atlas-prefix, --with-atlas-libdir): New
+	  options to specify ATLAS prefix and/or libdir.  Add support to use
+	  ATLAS for BLAS and LAPACK.  Change trypkg search order for mkl7
+	  and mkl5.
+
+2005-10-12 Jules Bergmann  <jules@codesourcery.com>
+
+	Implement General_dispatch (similar to Serial_expr_dispatch),
+	Use for dot- and matrix-matrix products.
+	* configure.ac (VSIP_IMPL_HAVE_BLAS, VSIPL_IMPL_HAVE_LAPACK):
+	  Define if if BLAS/LAPACK libraries present.
+	* src/vsip/impl/eval-blas.hpp: New file, BLAS evaluators for
+	  dot-product and matrix-matrix product.
+	* src/vsip/impl/general_dispatch.hpp: New file, generalized
+	  dispatch of functions to various implementations.
+	* src/vsip/impl/lapack.hpp: Add dot-product and matrix-matrix
+	  product functions.  Mover error handler xerbla_ into lapack.cpp
+	* src/vsip/impl/matvec.hpp: Use general dispatch for dot products.
+	  Provide default generic evaluator.
+	* src/vsip/impl/matvec-prod.hpp: Use general dispatch for
+	  matrix-matrix products.  Provide default generic evaluator.
+	* src/vsip/impl/signal-conv-common.hpp (Generic_tag, Opt_tag: Change 
+	  to forward decls.
+	* src/vsip/lapack.cpp: New file, contains xerbla_.
+	* tests/matvec-dot.cpp: New file, tests for dot() and cvjdot().
+	* tests/matvec-prod.cpp: Extend to cover different dimension-orders.
+	  (row-major and col-major).  Move reference routines to ref_matvec.
+	* tests/ref_matvec.hpp: New file, reference matvec routines.
+	* tests/test-random.hpp (randv): New function, fill a vector
+	  with random values.
+	* tests/extdata-output.hpp: Optionally use typeid, handle const
+	  types, provide more details for Dense, and handle Unary_expr_block
+	  type.
+
+	* benchmarks/dot.cpp: New file, benchmark for dot product.
+	* benchmarks/prod.cpp: New file, benchmark for matrix-matrix products.
+
+2005-10-09  Nathan Myers  <ncm@codesourcery.com>
+
+	* src/vsip/impl/signal-fir.hpp: support Fir<>::impl_performance()
+	  command "count".
+	* tests/fir.cpp: add tests for accessors, default template arg.
+
+2005-10-09  Nathan Myers  <ncm@codesourcery.com>
+
+	Implement FIR filter, all modes.
+	* src/vsip/impl/signal-fir.hpp, tests/fir.cpp: New.
+	* src/vsip/signal.hpp: Include new impl/signal-fir.hpp.
+
+2005-10-06  Jules Bergmann  <jules@codesourcery.com>
+
+	Implement 1-D correlation.
+	* src/vsip/impl/signal-conv-common.hpp (Opt_tag): Add optimized
+	  implementation tag.
+	* src/vsip/impl/signal-corr-common.hpp: New file, common routines
+	  and decls for correlation.
+	* src/vsip/impl/signal-corr-ext.hpp: New file, generic correlation
+	  implementation using Ext_data interface.
+	* src/vsip/impl/signal-corr-opt.hpp: New file, optimized correlation
+	  implementation using FFT overlap-add.
+	* src/vsip/impl/signal-corr.hpp: New file, correlation class.
+	* src/vsip/signal.hpp: Include signal-corr.hpp.
+	* src/vsip/impl/signal-types.hpp (bias_type): New type for correlation.
+	* src/vsip/matrix.hpp: Pass view by value to op-assign operators.
+	* src/vsip/tensor.hpp: Likewise.
+	* src/vsip/vector.hpp: Likewise.
+	* src/vsip/impl/domain-utils.hpp (normalize): New functions to
+	  normalize a domain to offset=0, stride=1, and length=same.
+	* src/vsip/impl/metaprogramming.hpp (Complex_of): Convert a type
+	  to complex.
+	* tests/correlation.cpp: New file, unit tests for correlation.
+	* benchmarks/corr.cpp: New file, benchmark correlation cases.
+
+2005-10-05  Jules Bergmann  <jules@codesourcery.com>
+
+	Support symmetric convolution kernels.
+	* src/vsip/impl/signal-conv-common.hpp (conv_kernel): Build
+	  convolution kernel from symmetry and coefficients.
+	  (VSIP_IMPL_CONV_CORRECT_MIN_SUPPORT_SIZE): control whether
+	  convolution minimum support output size should be defined
+	  to not require elements outsize of input vector or follow spec.
+	  (conv_output_size): Use ^ when computing output size.
+	  (conv_min): Use safe algorithm when ^ indicates to follow spec.
+	* src/vsip/impl/signal-conv-ext.hpp: Use conv_kernel to apply
+	  symmetry to coefficients.
+	* src/vsip/impl/signal-conv-ipp.hpp: Likewise.
+	* tests/convolution.cpp: Generalize test to symmetric kernels
+	  and to decimations other than 1.
+	
+	* tests/matvec.cpp: Fix Wall warning.
+
+2005-10-03  Don McCoy  <don@codesourcery.com>
+	
+	* src/vsip/impl/matvec.hpp: added outer product, gemp,
+	  gems and cumsum.
+	* tests/matvec.cpp: added tests for gemp, gems and
+	  cumsum which are not covered in ref-impl tests.
+	
+2005-10-03  Jules Bergmann  <jules@codesourcery.com>
+
+	Work arounds for ICC 9.0 compilation errors.
+	* src/vsip/selgen.hpp: Determine clip and invclip return type
+	  through helper classes.
+	* src/vsip/impl/fns_elementwise.hpp: Use single function and
+	  operator^().  Have functor distinguish bxor and lxor cases.
+	* src/vsip/impl/fns_userelt.hpp: For function object overloads of
+	  unary, binary, and ternary functions, determine return values
+	  through helper classes.
+
+2005-09-30  Jules Bergmann  <jules@codesourcery.com>
+
+	Implement LU linear system solver.
+	* src/vsip/impl/solver-lu.hpp: New file, LU solver.
+	* src/vsip/solvers.hpp: Include solver-lu.
+	* src/vsip/impl/lapack.hpp: Add LAPACK routines for LU solver
+	  (getrf and getrs).
+	* tests/solver-lu.cpp: New file, unit tests for LU solver.
+
+	* tests/load_view.hpp: New file, load view utility.
+	* tests/save_view.hpp: New file, save view utility.
+
+	* src/vsip/impl/solver-cholesky.hpp: Use stride to determine
+	  leading dimension.
+
+2005-09-30  Jules Bergmann  <jules@codesourcery.com>
+
+	Implement toeplitz linear system solver.
+	* src/vsip/solvers.hpp: Include solver-toepsol.
+	* src/vsip/impl/fns_scalar.hpp: Implement impl_conj, impl_real,
+	  and impl_imag functions that work with both scalar and complex.
+	* src/vsip/impl/fns_elementwise.hpp: Likewise.
+	* src/vsip/impl/solver-toepsol.hpp: New file, toeplitz solver.
+	* tests/solver-toepsol.cpp: New file, test for toeplitz solver.
+
+2005-09-28  Don McCoy  <don@codesourcery.com>
+	
+	* src/vsip/impl/matvec-prod.hpp: added prod3, prod4,
+	  prodh, prodj and prodt.
+	* tests/matvec-prod.cpp: added tests for same.
+	
+2005-09-28  Nathan Myers  <ncm@codesourcery.com>
+
+	* src/vsip/fft-core.hpp: Make IPP FFT work for 2D FFT. 
+	  Make unimplemented IPP driver functions report failure.
+	* src/vsip/signal-fft.hpp: Initialize scale member early enough 
+	  for IPP create_plan use.
+	* tests/fftm.cpp: Enable tests for complex->real, real->complex.
+	* tests/fft.cpp: Add comprehensive testing:
+	   (2D, 3D) x ((cx->cx fwd, inv), ((re->cx, cx->re) x (all axes))) 
+	   x (Dense/row-major, Dense/column-major, Fast_block)
+	   x (single,double) x (in-place, by_reference, by_value) 
+	   x (unscaled, arbitrary-scaled, scaled by N)
+	Tested with gcc-3.4/em64t/IPP and gcc-4.0.1/x86/FFTW3.
+
+2005-09-28  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/block-traits.hpp (View_block_storage):
+	  Add 'With_rp' template typedef to specify ref-count policy.
+	* src/vsip/impl/extdata.hpp: Use View_block_storage::With_rp to
+	  apply ref-count policy for block being held.
+
+2005-09-27  Nathan Myers  <ncm@codesourcery.com>
+
+	* tests/extdata-fft.cpp, tests/fft.cpp, tests/fftm-par.cpp,
+	  tests/fftm.cpp: #if out tests that depend on FFT where FFT
+	  is not enabled; add tests for double-precision; return 0
+	  at end of main().
+
+2005-09-27  Nathan Myers  <ncm@codesourcery.com>
+
+	* src/vsip/impl/signal-fft.hpp: fix compilation/instantiation typo
+	  in 2D by-value FFT.
+	* src/vsip/impl/fft-core.hpp: fix IPP FFT scaling-request flag.
+
+2005-09-27  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* src/vsip/dense.hpp: Remove redundant header inclusion.
+	* src/vsip/impl/expr_functor.hpp: Add missing header inclusion.
+	* src/vsip/impl/matvec.hpp: Add missing header inclusions.
+	* src/vsip/impl/view_traits.hpp: Fix view forward-declarations.
+	* src/vsip/vecor.hpp: Add generic get/put functions.
+	* src/vsip/matrix.hpp: Likewise.
+	* src/vsip/tensor.hpp: Likewise.
+	* tests/test.hpp: Add view_equal functions.
+	* src/vsip/selgen.hpp: Implement [selgen] functions.
+	* tests/selgen.cpp: Test them.
+
+2005-09-27  Jules Bergmann  <jules@codesourcery.com>
+
+	* configure.ac: Add -lpthread for MKL 5.x.
+	* src/vsip/solvers.hpp: Include solver-svd.
+	* src/vsip/impl/lapack.hpp: Add LAPACK routines for SVD (gebrd,
+	  orgbr/ungbr, sbdsqr).  Replace assertions on LAPACK info with
+	  exceptions.
+	* src/vsip/impl/matvec.hpp: Add trans_or_herm() function.
+	* src/vsip/impl/metaprogramming.hpp: Add Bool_type to encapsulate
+	  a bool as a type.
+	* src/vsip/impl/solver-svd.hpp: New file, implement SVD solver.
+	* src/vsip/impl/subblock.hpp (Diag::size): Check block_d argumment.
+	* tests/solver-common.hpp: Add compare_view functions.  Define
+	  perferred tranpose for value type (regular or conjugate) in
+	  Test_traits.
+	* tests/solver-svd.cpp: New file, unit tests for SVD solver.
+
+2005-09-26  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/math.hpp: Include expr_generator_block.hpp
+	* src/vsip/selgen.hpp: New file, implement ramp.
+	* src/vsip/impl/expr_generator_block.hpp: New file, generator
+	  expression block.
+	* tests/selgen-ramp.cpp: New file, tests for ramp().
+
+2005-09-26  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/vmmul.hpp: New file, implements vmmul.
+	* src/vsip/math.hpp: Inlcude vmmul.hpp.
+	* tests/vmmul.cpp: New file, unit tests for vmmul.
+
+	* apps/sarsim/sarsim.hpp: Align frame buffers.  Report signal
+	  processing object performance.
+	* benchmarks/conv.cpp: Make kernel length a command-line parameter.
+	* benchmarks/fft.cpp: Benchmark in-place vs out-of-place FFTs.
+	* src/vsip/parallel.hpp: New file, single header to pull in
+	  parallel bits.
+	* src/vsip/vector.hpp: Have op-assigns go through dispatch
+	  when possible.
+	* src/vsip/impl/par-foreach.hpp: New file, implement parallel
+	  foreach.
+	* src/vsip/impl/signal-conv.hpp: Add 'time' query to impl_perf.
+	* src/vsip/impl/signal-fft.hpp: Likewise.
+	* src/vsip/impl/solver-covsol.hpp: Throw computation error
+	  if decomposition fails.
+	* src/vsip/impl/subblock.hpp (get_local_block): Properly handle
+	  a Subset_block with a by-value superblock.
+	* tests/extdata-output.hpp: Specializations for subblocks and
+	  layout.
+
+2005-09-26  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* src/vsip/impl/fns_elementwise.hpp: Define binary operator^.
+	* tests/view_operators.cpp: Test it.
+
+2005-09-23  Jules Bergmann  <jules@codesourcery.com>
+
+	* VERSIONS: New file, describes varius CVS tagged versions of
+	  the software.  Recorded V_0_9 tag.
+
+2005-09-21  Don McCoy  <don@codesourcery.com>
+	
+	Corrections to pass fft_ext tests.
+	* src/vsip/signal-window.cpp: cleaned up an unneeded type
+	* tests/window.cpp: added conditional directive for FFT.
+	* tests/fft_ext/fft_ext.cpp: cleaned up so that it will
+	  deduce the fft type from the first two letters of filename.
+	  Also now runs on single and double precision by default.
+
+2005-09-21  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/ipp.cpp (vsub, vdiv): Swap operands (IPP operands in
+	  in "reverse" order).
+	* src/vsip/impl/ipp.hpp (Serial_evaluator_base): Check that all
+	  operands have the same type.
+	
+	* src/vsip/profile.cpp (No_time::clocks_per_sec): Define it when
+	  VSIP_IMPL_PROFILE_TIMER == 0.
+
+	* configure.ac: Make MPI, IPP, FFTW2, FFTW3, LAPACK, MKL, and
+	  profile timer disabled by default.  Make --with-ipp-suffix
+	  optional.
+	* src/vsip/impl/signal-window.cpp: Remove unused variable, use
+	  index_type to iterate over blackman indices.
+	* src/vsip/impl/signal-fft.hpp: Move definition of member scale_
+	  outside #if to allow compilation with no FFT engines defined.
+
+2005-09-20  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* tests/QMTest/vpp_database.py: Make qmtest properly scan
+	  subdirectories.
+
+2005-09-19  Don McCoy  <don@codesourcery.com>
+	
+	Implemented functions from [signal.windows]
+	* src/vsip/signal.hpp: includes impl/signal-window.hpp.
+	* src/vsip/impl/signal-window.hpp: new file.
+	* src/vsip/signal-window.cpp: new file.
+	* tests/window.cpp: new unit tests.
+
+2005-09-19  Nathan Myers  <ncm@codesourcery.com>
+
+	* src/vsip/impl/fft-core.hpp: minor format cleanup, documentation
+	  improvements.
+
+2005-09-19  Nathan Myers  <ncm@codesourcery.com>
+
+	* configure.ac: replace all --enable-fftw* and --enable-ipp-fft with
+	  --with-fft={fftw3,fftw2-float,fftw2-double,fftw2-generic,ipp}.
+	  Enable building with fftw2-double.  Add --with-ipp-suffix, and 
+	  require it if using IPP.
+
+2005-09-19  Don McCoy  <don@codesourcery.com>
+
+	Added support for dot, trans and kron functions in [math.matvec]
+	* src/vsip/math.hpp: included impl/matvec.hpp
+	* src/vsip/impl/matvec.hpp: new file
+	* tests/matvec.cpp: new file 
+
+2005-09-18  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/copy_chain.cpp, src/vsip/domain.hpp,
+	  src/vsip/impl/fft-core.hpp, src/vsip/impl/global_map.hpp,
+	  src/vsip/impl/local_map.hpp, src/vsip/impl/signal-conv.hpp,
+	  src/vsip/impl/signal-fft.hpp, tests/distributed-subviews.cpp,
+	  tests/expression.cpp, tests/extdata-matadd.cpp,
+	  tests/extdata-subviews.cpp, tests/extdata.cpp, tests/fft.cpp,
+	  tests/fftm-par.cpp, tests/fftm.cpp, tests/initfini.cpp,
+	  tests/solver-cholesky.cpp, tests/solver-common.hpp,
+	  tests/solver-llsqsol.cpp, tests/solver-qr.cpp,
+	  tests/static_assert.cpp, tests/tensor_subview.cpp,
+	  tests/fft_ext/fft_ext.cpp: Cleanup.
+
+2005-09-18  Jules Bergmann  <jules@codesourcery.com>
+
+	* tests/tensor-tranpose.cpp (USE_TRANSPOSE_VIEW_TYPEDEF): Work
+	  around conflicting GCC/ICC requirements for 'typename' keyword.
+	  (HAVE_TRANSPOSE): remove it.
+	* tests/test-precision.hpp: Make temporaries volatile to avoid
+	  ICC FP optimization that artificially increases precision
+	  while measuring precision.
+
+2005-09-18  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/signal-fft.hpp: Fix signatures to allow temporary
+	  views as destinations for Fft and Fftm.
+	* tests/regr_fft_temp_view.cpp: New file, regression for above bug.
+
+2005-09-17  Nathan Myers  <ncm@codesourcery.com>
+
+	* tests/fftm-par.cpp: robustify against mysterious behavior
+	  in sethra lam mpi.
+	
+2005-09-17  Mark Mitchell  <mark@codesourcery.com>
+
+	* doc/quickstart/quickstart.xml: Mention FFTW, IPP, MKL, and
+	ATLAS.
+
+	* scripts/src-release: Add -v parameter.
+	* GNUmakefile.in: Adjust default HTML rule.
+	* doc/GNUmakefile.inc.in: Do not conditionalize manual
+	generation. 
+
+	* configure.ac (XEP): Just look for "xep".
+	* GNUmakefile.in (XSLTPROCFOFLAGS): Fix typo.
+	(%.pdf): Do not use -out with XEP.
+
+	* GNUmakefile.in (JADE): Define to empty.
+	(PDFJADETEX): Likewise.
+	(XSLTPROCFLAGS): Rename to ...
+	(XSLTPROCFOFLAGS): ... this.
+	(%/html/index.html): Rename to ...
+	(%.html): ... this.
+	(%.fo): Use XLSTPROCFOFLAGS.
+	(%.pdf): Provide rule to copy from the srcdir.
+	(%.html): Likewise.
+	(GNUmakefile): Add more dependencies.
+	* configure.ac (JADE): Don't check for it.
+	(PDFJADETEX): Likewise.
+	* doc/GNUmakefile.inc.in (install): Handle chunked HTML files.
+	
+	* GNUmakefile.in (DOCBOOK_DTD): Remove.
+	(%/html/index.html): New rule.
+	* configure.ac: Remove conflicts.
+
+	* doc/quickstart/quickstart.xml: Add version variable.
+	Use it throughout.  Adjust formatting.  Remove FIXMEs.
+
+2005-09-17  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/fft-core.hpp: '-Wall' cleanup.
+	* tests/fft_ext/fft_ext.cpp: Likewise.
+
+2005-09-17  Jules Bergmann  <jules@codesourcery.com>
+
+	* configure.ac: Fix typo.
+
+2005-09-17  Nathan Myers  <ncm@codesourcery.com>
+
+	* src/vsip/impl/signal-fft.hpp: fix a real->complex FFTM
+	  stride bug detected by ref-impl/fft-coverage.hpp.
+
+2005-09-16  Jules Bergmann  <jules@codesourcery.com>
+	
+	* src/vsip/impl/aligned_allocator.hpp (VSIP_IMPL_ALLOC_ALIGNMENT):
+	  Macro for default alignment.
+	* src/vsip/impl/signal-conv-common.hpp: Use accumulation trait.
+	* src/vsip/complex.hpp: Cleanup.
+	* src/vsip/matrix.hpp: Cleanup.
+	* src/vsip/tensor.hpp: Cleanup.
+	* src/vsip/vector.hpp: Cleanup.
+	* src/vsip/impl/block-copy.hpp: Cleanup.
+	* src/vsip/impl/extdata.hpp: Cleanup.
+	* src/vsip/impl/lvalue-proxy.hpp: Cleanup.
+	* src/vsip/impl/par-assign.hpp: Cleanup.
+	* src/vsip/impl/par-chain-assign.hpp: Cleanup.
+	* src/vsip/impl/par-expr.hpp: Cleanup.
+	* src/vsip/impl/par-services-mpi.hpp: Cleanup.
+	* src/vsip/impl/reductions.hpp: Cleanup.
+	* src/vsip/impl/refcount.hpp: Cleanup.
+	* src/vsip/impl/signal-conv-ext.hpp: Cleanup.
+	* src/vsip/impl/signal-conv-ipp.hpp: Cleanup.
+	* src/vsip/impl/solver-qr.hpp: Cleanup.
+	* src/vsip/impl/subblock.hpp: Cleanup.
+	
+2005-09-16  Jules Bergmann  <jules@codesourcery.com>
+
+	Implement distributed user-storage.
+	* src/vsip/impl/distributed-block.hpp: User-storage functionality,
+	  pass admit, release through to subblock.
+	* src/vsip/dense.hpp: Add user-storage constructor for distributed
+	  blocks.
+	* tests/distributed-user-storage.cpp: Unit tests for distributed
+	  user-storage.
+
+	* src/vsip/impl/copy_chain.hpp (append_offset): New member function,
+	  append a chain, with an offset to each member.
+	* src/vsip/copy_chain.cpp (append_offset): Implement it.
+	* src/vsip/impl/par-chain-assign.hpp: Build send and recv lists
+	  relative to the base address of the subblock.  Offset those lists
+	  when message is sent.  Allows chain to be used even if location of
+	  storage changes, necessary for distributed user-storage blocks.
+	  Use dimension-ordering when building chain.  Clear req_list.
+	* src/vsip/impl/par-services-mpi.hpp (Chain_builder::add): Take
+	  offset instead of address for new chain element.
+	* src/vsip/impl/par-services-none.hpp (Chain_builder::add): Likewise.
+
+	* src/vsip/map.hpp (impl_local_only, impl_global_only): Delineate
+	  local vs global maps.
+	* src/vsip/impl/global_map.hpp (Local_or_global_map): New map
+	  for blocks that can be local or global, depending on how used.
+	* src/vsip/impl/local_map.hpp: Add constructor taking a
+	  Local_or_global_map.
+	
+	* src/vsip/impl/par-expr.hpp (Par_expr_block): Add missing block
+	  bits: dim, inc/decrement_count.
+	* src/vsip/impl/par-util.hpp: Add parallel support functions to
+	  get domain of local subblock and number of patches.
+
+	* src/vsip/impl/setup-assign.hpp: New file, implements early
+	  binding of serial and parallel assignments.
+
+	* tests/util.hpp (create_view): Add variant for user-storage views.
+	 
+	
+2005-09-16  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* tests/QMTest/vpp_database.py: Reimplement the test database.
+	* tests/QMTest/classes.qmc: Adjust to new extension classes.
+
+	* src/vsip/impl/fns_elementwise.hpp: Fix (work around)
+	issues with elementwise operator implementation.
+
+	* src/vsip/impl/ipp.hpp: Add support for binary
+	elementwise operators *, /, +, and -.
+	* src/vsip/impl/ipp.cpp: Likewise.
+
+	* src/vsip/impl/expr_binary_block.hpp: Cleanup.
+	* src/vsip/impl/expr_unary_block.hpp: Cleanup.
+	* src/vsip/impl/expr_scalar_block.hpp: Cleanup.
+	* tests/fns_scalar.cpp: Cleanup.
+
+2005-09-15  Nathan Myers  <ncm@codesourcery.com>
+
+	* configure.ac: add --enable-ipp-fft
+	* src/vsip/impl/fft-core.hpp: add IPP FFT driver
+	* src/vsip/impl/signal-fft.hpp: adapt to IPP driver details
+
+2005-09-15  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* src/vsip/impl/fns_elementwise.hpp: Implement unary / binary operators.
+	* tests/view_operators.cpp: Test them.
+
+2005-09-15  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/dispatch-assign.hpp (Tag_serial_assign): Cast
+	  value on assignment.
+
+2005-09-15  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/length.hpp (extent): Take dim as explicit template
+	  parameter.
+	* src/vsip/impl/expr_binary_operators.hpp: Pass explicit dim template
+	  parameter to extent.
+	* src/vsip/impl/expr_functor.hpp: Fix scalar_blocks to be constructed
+	  from extent, pass explicit dimension.
+	* src/vsip/impl/fns_scalar.hpp: Fix expoavg to avoid promotion to
+	  double.
+	* tests/expr-coverage.cpp: Generalize coverage to scalar-view
+	  expressions.
+	* tests/test-storage.hpp: Support for testing scalar-view expressions.
+
+2005-09-15  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/random.hpp (Rand_base<complex<T>>::randu): Force order
+	  of real and imag randu calls.
+	
+2005-09-15  Jules Bergmann  <jules@codesourcery.com>
+
+	Use View_block_storage trait for expression blocks.
+	* src/vsip/impl/block-traits.hpp: Add By_value_block_storage
+	  and By_reference_block_storage trait bases.
+	  (View_block_storage) Use By_reference_block_storage as default.
+	  (Expr_block_storage) Remove.
+	* src/vsip/impl/expr_binary_block.hpp: Use View_block_storage to
+	  determine storage.
+	* src/vsip/impl/expr_scalar_block.hpp: Likewise.
+	* src/vsip/impl/expr_ternary_block.hpp: Likewise.
+	* src/vsip/impl/expr_unary_block.hpp: Likewise.
+	* src/vsip/impl/subblock.hpp: Modify View_block_storage traits.
+	* apps/sarsim/cast-block.hpp: Likewise.
+	* tests/expr-coverage.cpp: New file, coverage testing of expressions.
+	* tests/regr_subview_exprs.cpp: New file, regression test for
+	  expressions using row subview of matrix.
+	* tests/test-storage.hpp: Add additional storage types.
+	
+2005-09-15  Mark Mitchell  <mark@codesourcery.com>
+
+	* GNUmakefile.in (DOCBOOK_DTD): Remove.	
+	Use OpenJade to generate PDF if XEP is not available.
+	* configure.ac (DOCBOOK_DTD): Remove.
+	* doc/quickstart/quickstart.xml: Use DocBook 4.2.
+	
+	* GNUmakefile.in (XEP): New variable.
+	(XSLTPROC): Likewise.
+	(docbook_xsl): New internal variable.
+	(docbook_pdf): Likewise.
+	(docbook_html): Likewise.
+	(docbook_dsssl): Likewise.
+	(%.fo): New rule.
+	(%.html): Likewise.
+	(%.pdf): Likewise.
+	* configure.ac: Check for XEP and XSLTPROC.
+	* doc/GNUmakefile.inc.in (doc_pdf_manuals): New variable.
+	(doc_html_manuals): Likewise.
+	(doc_manuals): Define in terms of previous variables.
+	(doc): Revise.
+	* doc/gpl.xml: Remove.
+	* doc/opl.xml: Likewise.
+
+2005-09-14  Don McCoy  <don@codesourcery.com>
+	
+	Implemented random generator class.
+	* src/vsip/random.hpp: New file, implements Rand class.
+	* tests/random.cpp: new unit tests.
+
+2005-09-13  Jules Bergmann  <jules@codesourcery.com>
+
+	Use lvalue factory to determine const_View lvalue type and
+	use const_reference_type from Lvalue_factory_type (closes issue #54).
+	* src/vsip/matrix.hpp: Use Lvalue_factory_type to deterine
+	  const_Matrix::operator() return value.  Use factory 
+	  const_reference_type for Matrix and const_Matrix.
+	* src/vsip/tensor.hpp (const_Tensor): Likewise.
+	* src/vsip/vector.hpp (const_Vector): Likewise.
+	* src/vsip/impl/lvalue-proxy.hpp: Add const_reference_type typedef.
+	* tests/lvalue-proxy.cpp: Add const_reference_type to PseudoBlock.
+	* tests/regr-const_view_at_op.cpp: New file, regression test
+	  for const_View operator().
+	
+2005-09-13  Jules Bergmann  <jules@codesourcery.com>
+
+	Implement generic matrix/vector products.
+	* src/vsip/math.hpp: Include matvec-prod.
+	* src/vsip/impl/matvec-prod.hpp: New file, implements generic
+	  matrix-matrix, matrix-vector, and vector-matrix products.
+	* tests/matvec-prod.cpp: New file, unit tests for matvec products.
+
+	Reorganize common test utilities for random numbers and precision.
+	* tests/test-precision.hpp: New file, compute precision of datatype.
+	* tests/test-random.hpp: New file, generate random matrix.
+	* tests/solver-common.hpp: Remove above functionality.
+	* tests/solver-cholesky.hpp: Include new files.
+	* tests/solver-covsol.hpp: Likewise.
+	* tests/solver-llsqsol.hpp: Likewise.
+	* tests/solver-qr.hpp: Likewise.
+	
+2005-09-12  Jules Bergmann  <jules@codesourcery.com>
+
+	* apps/sarsim/sarsim.hpp: Optimizations: perform range processing
+	  in cube_in_ with explicit corner-turn before azimuth processing.
+	  Move frame shift into azimuth processing loop.
+
+2005-09-12  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/matrix.hpp: Reverse formatting changes.
+
+2005-09-12  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/dispatch-assign.hpp: Avoid Tag_serial_assign for
+	  blocks with split storage.
+	* src/vsip/impl/signal-conv-ext.hpp (impl_performance): Make const.
+	* src/vsip/impl/signal-conv-ipp.hpp: Likewise.
+	* src/vsip/impl/signal-conv.hpp: Likewise.
+
+2005-09-10  Jules Bergmann  <jules@codesourcery.com>
+
+	* apps/sarsim/sarsim.hpp
+	  (init_io, fini_io): New functions to move input and output out of
+	  processing loop.
+	  (cube_in_, cube_out_): Store input and output cubes separately.
+	  (read_frame, write_frame): Read and write single frames.
+	  (io_process): Perform multi-buffering of cube_in_ and cube_out_.
+	* apps/sarsim/GNUmakefile: Add option to enable optimization.
+	* apps/sarsim/histcmp.c: Add include for string.h.
+	* apps/sarsim/mit-sarsim.cpp: Add -profile option.
+	* apps/sarsim/sims-48-4: Pass through commandline.
+	* apps/sarsim/sims-8-4: Likewise.
+	* apps/sarsim/vis-sims-8-4: Pass -nframe to dat2xv.
+	
+2005-09-10  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/solver-cholesky.hpp: New file, implement Cholesky
+	  factorization object.
+	* src/vsip/solvers.hpp: Include solver-choleksy.
+	* src/vsip/impl/lapack.hpp: Add veneers for cholesky factorization
+	  and solver routines.
+	* tests/solver-cholesky.cpp: New file, test cases for cholesky.
+
+2005-09-10  Nathan Myers  <ncm@codesourcery.com>
+
+	* src/vsip/impl/signal-fft.hpp, src/vsip/impl/fft-core.hpp:
+	  fixes & cleanup for parallel fftm
+	* tests/fftm.cpp: add fifth row/column to help catch alignment
+	  and fencepost sensitivities.
+	* tests/fftm-par.cpp: new; parallel complex-fftm tests.  
+
+2005-09-09  Nathan Myers  <ncm@codesourcery.com>
+
+	* src/vsip/matrix.hpp, src/vsip/tensor.hpp, src/vsip/vector.hpp,
+	  src/vsip/impl/par-chain-assign.hpp, src/vsip/impl/subblock.hpp,
+	  src/vsip/impl/dispatch-assign.hpp: Break #include loop.
+	* src/vsip/impl/distributed-block.hpp: Make Distributed_block::
+	  subblock() return the subblock number, not the subblock pointer.
+	* src/vsip/impl/point-fcn.hpp: declare domain() functions inline
+	  to prevent multiple-definitions link error.
+
+2005-09-08  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* configure.ac: Use mpicxx / mpiCC to determine MPI-related
+	build flags.
+
+2005-09-07  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/signal-fft.hpp: Fix compilation errors.
+
+2005-09-07  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/solver-covsol.hpp: New file, implement covsol().
+	* src/vsip/impl/solver-llsqsol.hpp: New file, implement llsqsol().
+	* src/vsip/solvers.hpp: Include solver-{covsol,llsqsol}.hpp.
+	* tests/solver-common.hpp: New file, common bits for solver tests.
+	* tests/solver-covsol.cpp: New file, tests covsol().
+	* tests/solver-llsqsol.cpp: New file, tests llsqsol().
+	* tests/solver-qr.cpp: Use common bits from solver-common.
+
+2005-09-07  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/lapack.hpp: Avoid preprocessor issue with Intel C++.
+
+2005-09-07  Jules Bergmann  <jules@codesourcery.com>
+
+	Use IPP to perform Convolution (when available/possible):
+	* src/vsip/signal.hpp: Include signal-types and signal-conv.
+	* src/vsip/impl/ipp.cpp (conv): Shims for IPP convolution functions.
+	* src/vsip/impl/ipp.hpp (conv): Likewise.
+	* src/vsip/impl/signal-conv-common.hpp: New file, common declarations
+	  and functions for convolution.
+	* src/vsip/impl/signal-conv-ext.hpp: Reorganize into
+	  Convolution_impl class, meant to be derived from by Convolution.
+	  Use functionality from signal-conv-common.
+	* src/vsip/impl/signal-conv-ipp.hpp: New file, IPP implementation of
+	  convolution.
+	* src/vsip/impl/signal-conv.hpp: Common Convolution class, derives
+	  implementation from Convolution_impl.
+	* src/vsip/impl/signal-types.hpp: New file, contains common signal
+	  types.
+	* tests/convolution.cpp: Extend tests to cover different input sizes
+	  and additional types.
+
+	New benchmarks and updates.
+	* benchmarks/copy.cpp: New file, benchmark view copy performance.
+	* benchmarks/fft_ext_ipp.cpp: New file, benchmark performance of
+	  IPP FFT using ext_data to access data in VSIPL++ block.
+	* benchmarks/loop.hpp: Optionally dump profile info after each size.
+	* benchmarks/main.cpp: Change test() to return success, profile flag.
+	* benchmarks/conv.cpp: Select region of support to benchmark.
+	* benchmarks/conv_ipp.cpp: Change test() to return success.
+	* benchmarks/fft.cpp: Likewise.
+	* benchmarks/fft_ipp.cpp: Likewise.
+	* benchmarks/qrd.cpp: Likewise.
+	* benchmarks/sumval.cpp: Likewise.
+	* benchmarks/vmul.cpp: Likewise.
+
+	Profile accumulate mode.
+	* src/vsip/profile.cpp: Add profile mode to accumulate timer data
+	  (provide an average for all events rather than a timeline).
+	* src/vsip/impl/profile.hpp: Likewise.
+
+	* configure.ac: Use -lpthreads for MKL 7.x
+	
+2005-09-02  Nathan Myers  <ncm@codesourcery.com>
+
+	Add support for parallel FFTM on FFTW2, FFTW3; transpose FFT 
+	and FFTM arguments where needed.
+
+	* src/vsip/impl/fft-core.hpp: update to support parallel FFTM
+	  for both FFTW2 and FFTW3.  Clean up explicit instantiations. 
+	  Adapt to explicit use of decimation exponent in interface.
+	* src/vsip/impl/signal-fft.hpp: map VSIPL++ "sd" and "dir"
+	  arguments to sane axis and decimation exponent.  Use Dense 
+	  blocks for temporaries until FFT drivers are adapted to
+	  handle gaps in argument arrays.  Handle all necessary
+	  transpositions for 2D, 3D Fft and Fftm.  Perform Fftm on 
+	  local views of arguments, for parallel execution.  Let
+	  FFT engines which can, do their own scaling.  Fix misuse
+	  of temp storage in by_value forms of Fft and Fftm.
+	* src/vsip/impl/local_map.hpp: make Is_par_same_map<> and
+	  Map_equal<> work for local maps.
+	* tests/fftm.hpp: robustify one test.
+
+	Tested on PPC64/gcc-3.4/FFTW3, x86/gcc-4.0/FFTW2, 
+	x86-64/gcc-4.0/FFTW3, x86-64/icc-8.1/FFTW3.  (Parallel FFTM,
+	argument transposition not exercised yet: tests to come next.)
+
+2005-09-01  Jules Bergmann  <jules@codesourcery.com>
+
+	Fix bugs with Ext_data for split data and subviews to split data.
+	* src/vsip/impl/extdata.hpp: Use storage_type to determine
+	  pointer type.
+	* src/vsip/impl/layout.hpp (Storage::offset): Shift pointer by
+	  offset.
+	* src/vsip/impl/subblock.hpp (Component_block::impl_stride): Use
+	  complex_type to determine stride adjustment.
+	  (Block_layout<Component_block>): Use complex_type to determine
+	  if block maintains unit-stride.
+	  (Subset_block::impl_data): Use storage_type::offset to adjust
+	  pointer.
+	* src/vsip/impl/fast-block.hpp: Add 3-dim specialization.
+	* tests/extdata-subviews.cpp: Add test coverage for vectors
+	  with split storage.
+	* tests/regr_ext_subview_split.cpp: New file, regression test that
+	  Ext_data access to real/imaginary subviews of split-complex data
+	  is correct.
+
+2005-09-01  Don McCoy  <don@codesourcery.com>
+
+	* tests/fft_ext/*fftop_f*: moved to...
+	* tests/fft_ext/data/*
+
+2005-09-01  Don McCoy  <don@codesourcery.com>
+
+	* tests/fft_ext/fft_ext.cpp: New file, fft on external
+	  data files taken from C VSIPL test suite.
+	* tests/fft_ext/*fftop_f*: New files, data for above.
+	
+2005-08-27  Nathan Myers  <ncm@codesourcery.com>
+
+	* tests/tensor-transpose.cpp, src/vsip/tensor.hpp: 
+	  insert "template" and "typename" where gcc-4 wants 'em.
+
+2005-08-27  Jules Bergmann  <jules@codesourcery.com>
+
+	Benchmarks for QR, FFT, convolution, and vector-multiply.
+	* configure.ac: Set IPP search libs to ipps and ippsm7.
+	* benchmarks/loop.hpp: Use ops_per_point to control gain.
+	* benchmarks/main.cpp: Call defaults(), new "-param" option.
+	* benchmarks/ops_info.hpp: New file, op count info.
+	* benchmarks/conv.cpp: New file, vsip::Convolution benchmark.
+	* benchmarks/conv_ipp.cpp: New file, IPP convolution benchmark.
+	* benchmarks/fft.cpp: New file, vsip::Fft benchmark.
+	* benchmarks/fft_ipp.cpp: New file, IPP FFT benchmark.
+	* benchmarks/qrd.cpp: New file, vsip::qrd benchmark.
+	* benchmarks/vmul.cpp: Use ops_info.hpp, set defaults.
+	* benchmarks/vmul_ipp.cpp: New file, IPP vector-mult benchmark.
+	* src/vsip/impl/metaprogramming.hpp (Is_complex): New trait.
+
+	Function inlining.
+	* src/vsip/impl/counter.hpp (Checked_counter::operator+=):
+	  declare inline (avoid GCC -Winline warning).
+	  (Checked_counter::operator-=): Likewise.
+	* src/vsip/impl/domain-utils.hpp (block_domain): Inline.
+	* src/vsip/impl/length.hpp (extent): Inline.
+	  (total_size): New function.
+
+	Non-blocked QR support.
+	* src/vsip/impl/lapack.hpp: Add functions for non-blocked QR (geqr2).
+	* src/vsip/impl/solver-qr.hpp (Qrd_impl): Support non-blocked QR.
+
+2005-08-27  Jules Bergmann  <jules@codesourcery.com>
+
+	Distributed subset subviews.
+	* src/vsip/impl/dist.hpp (Whole_dist): New class for non-distributed
+	  dimension.
+	* src/vsip/impl/distributed-block.hpp (Distributed_block::subblock):
+	  New member function.
+	* src/vsip/impl/par-expr.hpp (Par_expr_block): Add missing
+	  block typedefs reference_type and const_reference_type.
+	* src/vsip/impl/par-services-mpi.hpp: Support complex data types.
+	* src/vsip/impl/subblock.hpp: Handle maps for Subset_block.
+	* src/vsip/impl/view_traits.hpp: Fixe local_type for complex views.
+	* src/vsip/map_fwd.hpp (Map_subdomain): Forward decl.
+	* src/vsip/map.hpp (Map_subdomain): Implementation.
+	  (Map<>::applied_dom): New member function.
+	  (Map<>::impl_local_from_global_dom): New member function.
+	  (Dist_factory): Support Whole_dist.
+	* src/vsip/support.hpp (distribution_type): New enum 'whole'.
+	* tests/distributed-block.cpp: Coverage for complex types.
+
+	* benchmarks/vmul.cpp: Remove unused variable, fix message.
+	* src/vsip/tensor.hpp: Minor formatting.
+
+2005-08-25  Don McCoy  <don@codesourcery.com>
+	
+	* src/vsip/impl/fns_elementwise.hpp: added expoavg().
+	* src/vsip/impl/fns_scalar.hpp: likewise.
+
+2005-08-25  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* configure.ac: Add disable-exceptions option and check for ghs compiler.
+	* GNUmakefile.in: Use $(CXXDEP) command instead of hardcoding '$(CXX) -M'.
+	* src/vsip/support.hpp: Check whether exceptions are to be used.
+	* src/vsip/copy_chain.hpp: Add missing <cassert> include.
+	* src/vsip/dense.hpp: Fix name collision.
+	* src/vsip/impl/aligned_allocator.hpp: Use THROW macro.
+	* src/vsip/impl/dist.hpp: Add dummy return statements.
+	* src/vsip/impl/fast-block.hpp: Fix name collision.
+	* src/vsip/impl/par-services-none.hpp: Add missing friend declarations.
+
+2005-08-25  Don McCoy  <don@codesourcery.com>
+	* src/vsip/tensor.hpp: added subview type transpose
+	* src/vsip/impl/subblock.hpp: updated Permuted_block
+	  class (store data by-value, added copy constructor).
+	  Fixed specialization macro and reverse permutations.
+	* tests/tensor-transpose.cpp: fixed declarations and
+	  reverse permutations.
+
+2005-08-25  Nathan Myers  <ncm@codesourcery.com>
+
+	* src/vsip/domain.hpp: fix improper member specialization
+	* src/vsip/tensor.hpp: add "typename" where required.
+
+2005-08-23  Jules Bergmann  <jules@codesourcery.com>
+
+	Implement QR solver.
+	* configure.ac: Detect LAPACK libraries, including Intel MKL.
+	* src/vsip/math.hpp: Include math-enum.hpp.
+	* src/vsip/solvers.hpp: New file.
+	* src/vsip/impl/lapack.hpp: New file, abstracts blas and lapack
+	  APIs.
+	* src/vsip/impl/math-enum.hpp: New file, [math.enum] enumerations.
+	* src/vsip/impl/solver-qr.hpp: New file, implement QR solver.
+	* src/vsip/impl/temp_buffer.hpp: New file, allocate temporary
+	  buffer.
+	* tests/solver-qr.cpp: New file, unit tests for QR solver.
+	* tests/test.hpp (almost_equal): Overload for complex.
+	
+	* vsipl++.pc.in: New variables for cppflags and cxxflags.  Include
+	  LDFLAGS in Libs.
+
+	* src/vsip/dense.hpp: Fix formatting.
+	* tests/regr_prox_lvalue.cpp: Fix file date.
+
+2005-08-23  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/fns_scalar.hpp (mul): Fix bug.
+	* src/vsip/impl/reductions.hpp: Use Block_layout to determine order.
+	* src/vsip/impl/reductions-idx.hpp: Likewise.
+
+2005-08-22  Nathan Myers  <ncm@codesourcery.com>
+
+	* src/vsip/impl/signal-fft.hpp: use Dense, not Fast_block
+	for FFTM temporaries until prepared to step around padding.
+	* tests/fftm.cpp: enable tests, remove chatter, avoid
+	trying to make zero-size subviews.
+
+2005-08-18  Jules Bergmann  <jules@codesourcery.com>
+
+	* tests/matrix-transpose.cpp: Unit tests for matrix transpose.
+	* tests/tensor-transpose.cpp: Unit tests for tensor transpose.
+
+2005-08-17  Nathan Myers  <ncm@codesourcery.com>
+
+	* src/vsip/impl/signal-fft.hpp: remove "#if 0" code.
+	* tests/fftm.cpp: comment out iffy tests until Fftm<> debugged.
+
+2005-08-17  Nathan Myers  <ncm@codesourcery.com>
+
+	* src/vsip/impl/signal-fft.hpp, fft-core.hpp: add support for
+	  Fftm<>, on (FFTW2, FFTW3) x (c<->c, r<->c, c<->r).  (Much of
+	  it remains untested.)  Document more.  Fix args to in-place 
+	  FFTW2.  Fix FFTW3 complex->real argument clobbering.
+	  Improve name-mangling conformance ("fft" -> "impl_fft", etc.),
+	  namespace usage ("dimension_type" -> "vsip::dimension_type").
+	* tests/fftm.cpp: New.  Tests complex <-> complex.
+	* src/vsip/domain.hpp: make member impl_at() non-const.
+
+2005-08-16  Don McCoy  <don@codesourcery.com>
+
+	* src/vsip/matrix.hpp: Added support for transpose subview. 
+	  Cleaned up type definitions.
+	* src/vsip/impl/subblock.hpp: Updated Transposed_block
+	  class to store by-value.  Added copy constructor.
+	  Fixed references to member holding underlying block
+	  (from blk_. to blk_->).
+
+2005-08-12  Jules Bergmann  <jules@codesourcery.com>
+
+	* configure.ac: Check that timers will compile before using.
+	  Fix typo for ipps header detection.
+	* src/vsip/impl/profile.hpp: Add empty timer policy No_timer.
+	  Selectively compile timer code based on VSIP_IMPL_PROFILE_TIMER. 
+	  Rename timer policies for coding standard.
+	* src/vsip/profile.cpp: Likewise.
+
+	* apps/sarsim/sarsim.cpp (report_performance): Fix decl/defn
+	  mixmatch (missing 'const').
+	* src/vsip/impl/signal-fft.hpp (impl_performance): Make 'const'.
+
+2005-08-12  Jules Bergmann  <jules@codesourcery.com>
+	
+	Add performance measurement for sarsim.
+	* apps/sarsim/sarsim.hpp (SarSim): Add processing timers.
+	  (SarSim::report_performance): New function, report performance
+	  measuered by timers.
+	  (SarSim): Fix off-by-one loop conditions for pt_npols.
+	* apps/sarsim/mit-sarsim.cpp: Call report_performance, replace
+	  assertion with exception.
+
+	* configure.ac (VSIP_IMPL_PROFILE_HARDCODE_CPU_SPEED): Define with
+	  CPU speed in MHz if --enable-cpu-mhz option given.
+	* src/vsip/profile.cpp (VSIP_IMPL_PROFILE_HARDCODE_CPU_SPEED): Use it
+	  if defined.
+	  (read_cpu_info): Move /proc/cpuinfo into separate function,
+	  use for both Pentium TSX and x86_64 TSC timers.
+
+	* src/vsip/GNUmakefile.inc.in (install): add dependency on libvsip.a
+	
+2005-08-12  Jules Bergmann  <jules@codesourcery.com>
+	
+	* benchmarks/GNUmakefile.inc.in: New file.
+	* benchmarks/loop.hpp: New file, loop driver for benchmarks with 1-dim.
+	* benchmarks/main.cpp: New file, common main for benchmarks.
+	* benchmarks/sumval.cpp: New file, benchmark for sumval reduction.
+	* benchmarks/vmul.cpp: New file, benchmark for vector multiply.
+	* src/vsip/impl/copy_chain.hpp: Add missing include.
+
+2005-08-11  Don McCoy  <don@codesourcery.com>
+
+	* src/vsip/impl/subblock.hpp: Corrected implementation of
+	  the direct data access functions for the diag subview.
+	* tests/extdata-subviews.cpp: Modified diag subview test
+	  to use direct data access.
+	
+2005-08-11  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* configure.ac: Do sanity checks on std::complex and
+	IPP's types.
+
+2005-08-10  Mark Mitchell  <mark@codesourcery.com>
+
+	* doc/quickstart/quickstart.xml: Fill in organization section.
+
+	* doc/GNUmakefile.inc.in (doc_manuals): Add dependency on gpl.xml.
+	* doc/gpl.xml: New file.
+	* doc/quickstart/quickstart.xml: Write chapter on VSIPL++
+	licensing.  Add GPL as an appendix.
+
+2005-08-10  Jules Bergmann  <jules@codesourcery.com>
+	
+	* src/vsip/impl/ipp.cpp: Move function calls out of assert predicate.
+
+2005-08-10  Jules Bergmann  <jules@codesourcery.com>
+
+	Fix bug preventing nested unary functions.
+	* src/vsip/impl/expr_ternary_block.hpp: Add specialization of
+	  Expr_block_storage to hold Ternar_expr_blocks by value.
+	* src/vsip/impl/expr_unary_block.hpp (Unar_expr_block): Use
+	  Expr_block_storage trait to determine how to hold operand block.
+	  Add specialization of Expr_block_storage for Unary_expr_block.
+
+	* src/vsip/impl/expr_serial_evaluator.hpp: Comment out unused
+	  parameters.
+	* tests/extdata-subviews.cpp: Fix missing 'typename' keyword.
+
+2005-08-10  Jules Bergmann  <jules@codesourcery.com>
+	
+	* apps/sarsim/simd-48-4: New file, run large synthetic data (double).
+	* apps/sarsim/sims-48-4: New file, run large synthetic data (single).
+	* apps/sarsim/sims-real: New file, run large real data.
+	* apps/sarsim/chk-simd-48-4: New file, checks results of simd-48-4.
+	* apps/sarsim/chk-sims-48-4: New file, checks results of sims-48-4.
+	* apps/sarsim/vis-real: New file, visual real data output.
+	* apps/sarsim/vis-sims-48-4: New file, visual large synthetic output.
+
+2005-08-10  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* configure.ac: Check for Intel's IPP.
+	* src/vsip/GNUmakefile.inc.in: Compile IPP wrapper.
+	* src/vsip/impl/expr_serial_evaluator.hpp: New serial expression 
+	dispatcher.
+	* src/vsip/impl/expr_serial_dispatch.hpp: Likewise.
+	* src/vsip/impl/ipp.hpp: New IPP wrapper.
+	* src/vsip/impl/ipp.cpp: Likewise.
+	* src/vsip/impl/metaprogramming.hpp: Add missing <complex> header.
+	* src/vsip/impl/type_list.hpp: New type list templates.
+	* src/vsip/impl/dispatch-assign.hpp: Use new serial dispatch.
+	* tests/expr-test.cpp: Add tests for serial dispatch.
+	
+2005-08-10  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/matrix.hpp: Add impl_diagblock_type to Matrix.
+	* src/vsip/impl/subblock.hpp: Fix typo.
+
+2005-08-09  Don McCoy  <don@codesourcery.com>
+
+	* src/vsip/impl/fns_scalar.hpp: fixed bug in euler() function
+
+2005-08-09  Don McCoy  <don@codesourcery.com>
+
+	* src/vsip/matrix.hpp: Added diag() functions.
+	* src/vsip/impl/subblock.hpp: Added Diag_block class.
+	* tests/extdata-subviews.cpp: Filled in diag subview test.
+
+2005-08-09  Jules Bergmann  <jules@codesourcery.com>
+
+	* tests/regr_proxy_lvalue_conv.cpp: New file, regression test for
+	  proxy lvalue conversion problems.
+
+2005-08-07  Nathan Myers  <ncm@codesourcery.com>
+
+	* src/vsip/impl/signal-fft.hpp: fix #ifdefs to use names we define.
+
+2005-08-08  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* src/vsip/impl/index.hpp: Removed. Replaced by...
+	* src/vsip/impl/vertex.hpp: ...this.
+	* src/vsip/domain.hpp: Use new Vertex template.
+	* src/vsip/impl/layout.hpp: Adjust.
+	* tests/index.cpp: Adjust.
+	* tests/view.cpp: Adjust.
+	* src/vsip/impl/length.hpp: New Length template.
+	* src/vsip/impl/expr_scalar_block.hpp: Use it.
+	* src/vsip/impl/expr_binary_operators.hpp: Use it.
+	* src/vsip/impl/expr_functor.hpp: Use it.
+
+2005-08-07  Nathan Myers  <ncm@codesourcery.com>
+
+	* src/vsip/impl/signal-fft.hpp: add 1D real->complex,
+	  complex->real, more of 2D, 3D.  Use the correct 
+	  array size.  Make by_value() delegate to by_ref().
+	  Move benchmark timing calls to Fft_imp members.
+	* src/vsip/impl/signal-fft.hpp: add 1D real->complex,
+	  complex->real for FFTW2, FFTW3, most of 2D, 3D.
+	* tests/fft.cpp: test 1D real->complex, complex->real.
+
+2005-08-05  Mark Mitchell  <mark@codesourcery.com>
+
+	* src/vsip/impl/fns_elementwise.hpp: Remove stray semicolons.
+
+	* src/vsip/fft-double.cpp: Remove dummy function.
+	* src/vsip/fft-float.cpp: Likewise.
+
+	* apps/sarsim/sarsim.hpp (SarSim<T>::polarity_type): Remove
+	pt_last and pt_size; use pt_npols instead throughout.
+
+2005-08-05  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/signal.hpp: Use signal-conv-ext.
+	* src/vsip/impl/signal-conv-ext.hpp: Bugfix: use stride when
+	  accessing direct data.
+	* tests/regr_conv_to_subview.cpp: New file, regression test
+	  for convolution bug using ext_data.
+
+2005-08-05  Jules Bergmann  <jules@codesourcery.com>
+
+	* apps/sarsim/GNUmakefile: Build dat2xv.
+	* apps/sarsim/dat2xv.c: New file, program to generate images
+	  from mit-sarsim output.
+	* apps/sarsim/sarsim.cpp: Add empty write_output_header() function.
+	* apps/sarsim/mit-sarsim.cpp: Separate output of frame header
+	  from frame data.  Bug fixes.
+	* apps/sarsim/sarsim.hpp: Fix off-by-one error with polarizations.
+	  Fix size mismatch when applying equalization weights.
+	* apps/sarsim/simd-8-4: Use mit-sarsim.
+	* apps/sarsim/sims-8-4: Use mit-sarsim.
+	* apps/sarsim/chk-sims-8-4: Script cleanup.
+	* apps/sarsim/vis-sims-8-4: New script, generate image.
+	* src/vsip/signal.hpp: Use signal-conv instead of signal-conv-ext.
+
+2005-08-05  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/point-fcn.hpp (extent): Rename to extent_old.
+	  Eventually replace usage with 'extent' function returning Length.
+	* src/vsip/impl/point.hpp: Likewise.
+	* src/vsip/impl/block-copy.hpp:: Likewise.
+	* src/vsip/impl/extdata.hpp: Likewise.
+	* src/vsip/impl/par-assign.hpp: Likewise.
+	* src/vsip/impl/par-chain-assign.hpp: Likewise.
+	* src/vsip/impl/par-util.hpp: Likewise.
+	* tests/distributed-block.cpp: Likewise.
+	* tests/distributed-subviews.cpp: Likewise.
+	* tests/fast-block.cpp: Likewise.
+	* tests/par_expr.cpp: Likewise.
+	* tests/user_storage.cpp: Likewise.
+	* tests/view.cpp: Likewise.
+
+2005-08-04  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/block-traits.hpp (Flexible_access_tag): New data
+	  access tag.
+	* src/vsip/impl/choose-access.hpp: Distinguish between data may
+	  be copied (use flexible) and must be copied (use copy).
+	* src/vsip/impl/extdata.hpp: Implement flexible access to determine
+	  whether to copy data at runtime.
+	* src/vsip/impl/layout.hpp: Applied_layout specialization for 3-dim
+	  Stride_unit_align.  Separate Storage traits (in Storage) from
+	  implementation (new class Allocated_storage).
+	* src/vsip/impl/fast-block.hpp: Use Allocated_storage.
+	* tests/extdata-output.hpp: Handle additional types.
+	* tests/extdata-runtime.cpp: New file, unit tests for runtime
+	  determination of access method.
+	* tests/plainblock.hpp: Use Allocated_storage.
+	* examples/GNUmakefile.inc.in: Remove space after ld -L option.
+
+2005-08-04  Mark Mitchell  <mark@codesourcery.com>
+
+	* apps/sarsim/GNUmakefile: Add mit-sarsim target.
+	* apps/sarsim/mit-sarsim.cpp: Fix typo.
+	* apps/sarsim/sarsim.cpp (SimpleSarSim): New class.
+	* apps/sarsim/sarsim.hpp: Fix typo.
+
+2005-08-03  Mark Mitchell  <mark@codesourcery.com>
+
+	* apps/sarsim/sarsim.cpp: Strip all code.
+	* apps/sarsim/sarsim.hpp: New file, containing refactored form of
+	old sarsim.cpp.
+	* apps/sarsim/mit-sarsim.cpp: New file.
+	* GNUmakefile: Remove GCC-isms.
+
+	* apps/sarsim/azimuth-process.hpp: Remove.
+	* apps/sarsim/range-process.hpp: Remove.
+	* apps/sarsim/sarsim.cpp: Fold range-processing and
+	azimuth-processing into a single routine.  Move I/O out of the
+	core routine.
+
+2005-08-02  Jules Bergmann  <jules@codesourcery.com>
+
+	Update par-services-none.
+	* src/vsip/copy_chain.cpp: New file, Copy_chain implementation.
+	* src/vsip/impl/copy_chain.hpp: New file, pseudo DMA chain for
+	  par-services-none.
+	* src/vsip/impl/par-assign.hpp: Update to new PSFs (get_local_view).
+	* src/vsip/impl/par-chain-assign.hpp: Add 'disable_copy' to force
+	  local messages (increases test coverage for par-services-none).
+	* src/vsip/impl/par-services-none.hpp: Support pseudo DMA chains.
+	* tests/distributed-block.cpp: Enable testing of old parallel
+	  assigns.
+	* tests/mpi.cpp: Removed.
+
+2005-08-02  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* src/vsip/impl/expr_operations.hpp: Make operators and functors conform with
+	std::unary_function and std::binary_function.
+	* src/vsip/impl/expr_functor.hpp: Likewise.
+	* src/vsip/impl/expr_unary_block.hpp: Likewise.
+	* src/vsip/impl/expr_binary_block.hpp: Likewise.
+	* src/vsip/impl/expr_ternary_block.hpp: Likewise.
+	* src/vsip/impl/fns_elementwise.hpp: Likewise.
+	* src/vsip/impl/reductions.hpp: Likewise.
+	* src/vsip/impl/reductions-idx.hpp: Likewise.
+	* src/vsip/impl/fns_userelt.hpp: Define user extension function mechanism.
+	* src/vsip/math.hpp: Use it.
+	* tests/fns_userelt.cpp: Test it.
+
+2005-08-02  Mark Mitchell  <mark@codesourcery.com>
+
+	* apps/sarsim/range-process.hpp (RangeProcess<T>::i_coef_):
+	Remove.
+	(RangeProcess<T>::q_coef_): Likewise.
+	(RangeProcess<T>::RangeProcess): Don't set them.
+
+	* apps/sarsim/range-process.hpp (RangeProcess<T>::vec_iq_): Remove.
+	(RangeProcess<T>:timer_copy1_): Likewise.
+	(RangeProcess<T>::process): Do not read data here.
+	* apps/sarsim/sarsim.cpp (process): Read it here instead.
+
+	* apps/sarsim/GNUmakefile: Remove USE_EXT_FFT logic.
+	(sarsim): Do not link with fft-fftw-impl.o.
+	* apps/sarsim/azimuth-process.hpp: Remove USE_EXT_FFT logic.
+	* apps/sarsim/range-process.hpp: Likewise.
+	(RangeProcess<T>::RangeProcess): Do not use first_.
+	(RangeProcess<T>::process): Remove #if 0'd code.
+	(RangeProcess<T>.first_): Remove.
+	* apps/sarsim/fft-fftw-impl.cpp: Remove.
+	* apps/sarsim/fft-fftw-impl.hpp: Likewise.
+	* apps/sarsim/fft-fftw.hpp: Likewise.
+
+2005-08-01  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* doc/quickstart/quickstart.xml: Correct spelling of <envar>.
+
+2005-07-31  Nathan Myers  <ncm@codesourcery.com>
+
+	* src/vsip/impl/fft-core.hpp, signal-fft.hpp: reorganize and
+	simplify to mimimize cut'n'paste to support multiple FFT 
+	implementations.  Enable 1D FFTW2 real->complex transform, 
+	maybe complex->real too.  Change more names "FFT" -> "Fft".
+
+2005-07-31  Mark Mitchell  <mark@codesourcery.com>
+
+	* doc/quickstart/quickstart.xml: Use <envvar> around
+	PKG_CONFIG_PATH.
+
+	* src/vsip/profile.cpp (PosixTime::clocks_per_sec): Define.
+	(PosixRealtime::clocks_per_sec): Likewise.
+	(PentiumTSCTime::clocks_per_sec): Likewise.
+	(X86_64_TSCTime::clocks_per_sec): Likewise.
+
+2005-07-28  Jules Bergmann  <jules@codesourcery.com>
+
+	* tests/reductions.cpp: Fix how expected value for meansqval is
+	  computed.
+	* tests/test-storage.hpp: Use index_type for get_nth and put_nth
+	  index parameter.
+	* tests/test.hpp: Use relative and absolute error to compare
+	  floating point values.
+
+2005-07-28  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/subblock.hpp: Fix typo, referencing old tuple members.
+
+2005-07-28  Jules Bergmann  <jules@codesourcery.com>
+
+	* tests/reduction.cpp: Fix bug computing expected value for meanval.
+
+2005-07-28  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/extdata.hpp (Desired_block_layout): Keep
+	  pack_type same if access_type is direct.
+	* src/vsip/impl/subblock.hpp: Add direct data access for
+	  Component_block, Subset_block, Transpose_block, Sliced2_block.
+	* tests/extdata-subviews.cpp: Tests for subview direct data access.
+	* src/vsip/impl/fast-block.hpp: Make direct data access interface
+	  public.
+	* tests/plainblock.hpp: Likewise.
+
+2005-07-28  Don McCoy  <don@codesourcery.com>
+	
+	* src/vsip/impl/reductions.hpp: fixed meanval to handle
+	  complex types correctly.
+	
+2005-07-27  Don McCoy  <don@codesourcery.com>
+	
+	* src/vsip/dense.hpp: added default argument for update to 
+	  admit()/release().
+
+2005-07-26  Don McCoy  <don@codesourcery.com>
+
+	* src/vsip/dense.hpp: Fixed size(1,0) bug
+	* src/vsip/support.hpp: renamed tuple Dim0/1/2 to impl_dim0/1/2
+	* tests/user_storage.cpp: as above.
+	
+2005-07-26  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/complex.hpp: Remove using directives.  Include
+	  complex-decl.hpp and math.hpp.
+	* src/vsip/impl/complex-decl.hpp: New file, Complex
+	  declarations not covered by fns_elementwise.hpp.
+	* src/vsip/impl/fast-block.hpp: Remove complex.hpp include.
+	* src/vsip/impl/fns_elementwise.hpp: Import vsip::impl::{tan,tanh}
+	  into vsip::.
+	* src/vsip/impl/layout.hpp: Include complex-decl.hpp instead of
+	  complex.hpp.
+	* src/vsip/tensor.hpp: Include dispatch-assign.hpp.
+	* tests/complex.cpp: Test coverage for complex functions ambiguities.
+	* tests/test.hpp: Remove unnecessary include of cmath.
+
+2005-07-23  Mark Mitchell  <mark@codesourcery.com>
+
+	* configure.ac (exp10): AC_CHECK_DECL it.
+	(exp10f): Likewise.
+	(exp10l): Likewise.
+	* src/vsip/impl/fns_scalar.hpp (<vsip/impl/config.hpp>): Include
+	it.
+	(::exp10): Do not use it.
+	(exp10): Define, with various overloads, conditionalized on
+	whether exp10, exp10f, and exp10l are available in the standard
+	library.  
+	
+	* src/vsip/impl/allocation.hpp (<vsip/impl/config.hpp>): Include
+	it, instead of ...
+	(<vsip/impl/acconfig.hpp>): .. this.
+	* src/vsip/impl/acconfig.hpp (<vsip/impl/config.hpp>): Include
+	it, instead of ...
+	(<vsip/impl/acconfig.hpp>): .. this.
+
+2005-07-22  Mark Mitchell  <mark@codesourcery.com>
+
+	* tests/QMTest/vpp_database.py (VPPDatabase.GetResource): Fix
+	typo.
+
+2005-07-22  Jules Bergmann  <jules@codesourcery.com>
+
+	* configure.ac (AR): Substitute it.
+	* GNUmakefile.in: Use @AR@.  Exclude srcdir prefix from norm_dir.
+	* src/vsip/dense.hpp: Reorganize to better vectorize with ICC.
+	  (Dense_storage): New class, similar to Storage that Dense_impl
+	  derives from.
+	* src/vsip/impl/profile.hpp: Determine clocks_per_second at runtime.
+	* src/vsip/profile.cpp: Likewise.
+	* src/vsip/impl/reductions.hpp: New file, implements
+	  [math.fns.reductions]
+	* src/vsip/impl/reductions-idx.hpp: New file, implements
+	  [math.fns.reductidx]
+	* src/vsip/math.hpp: Include reductions{,-idx}.hpp.
+	* src/vsip/support.hpp: Defines for loop vectorization pragmas.
+	* tests/distributed-block.cpp: Use get_np_square.
+	* tests/reductions-bool.cpp: New file, tests for boolean reductions.
+	* tests/reductions.cpp: New file, tests for reductions.
+	* tests/reductions-idx.cpp: New file, tests for index reductions.
+	* tests/test-storage.hpp: Support tensors.
+	* tests/util-par.hpp: Disambiguate call to sqrt().
+
+2005-07-20  Mark Mitchell  <mark@codesourcery.com>
+
+	* GNUMakefile.in (check): Move actions into ...
+	* tests/GNUmakefile.inc.in: ... this new file.  Automatically copy
+	QMTest extension classes.
+
+2005-07-19  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/aligned_allocator.hpp: Fix printf format.
+	* src/vsip/impl/expr_binary_block.hpp: Likewise.
+	* src/vsip/impl/par-util.hpp: Remove unnecessary variable.
+	* tests/fft.cpp: Gate sinl(), cosl() with ifdef.  Fix ICC control
+	  flow warning.
+
+2005-07-18  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/dist.hpp (impl_local_from_global_index):
+	  Correct return type.
+	* src/vsip/map.hpp (impl_local_from_global_index): Likewise.
+
+2005-07-15  Nathan Myers  <ncm@codesourcery.com>
+
+	* src/vsip/{impl/view_traits,vector,matrix,tensor}.hpp:
+	disambiguate impl_View constructors that take a "T const&"
+	argument in the same position as a length_type, to allow
+	views of blocks with length_type elements.
+
+2005-07-14  Jules Bergmann  <jules@codesourcery.com>
+
+	* tests/regr_view_index.cpp: New file, regression test for
+	  vector and matrix views of index_type with initial value.
+
+2005-07-12  Jules Bergmann  <jules@codesourcery.com>
+
+	Support empty domains and empty blocks.
+	* src/vsip/domain.hpp: Allow empty domains.
+	* src/vsip/impl/block-copy.hpp: Handle empty blocks.
+	* src/vsip/impl/domain-utils.hpp (empty_domain): New function,
+	  returns empty domain of dimension Dim.
+	* src/vsip/impl/point.hpp (valid): New function to simplify
+	  iterating over empty domains.
+
+	Simplify mappings to 0 or 1 subblock per processor.
+	* src/vsip/dense.hpp (Dense): Use Local_map as default map.
+	  (get_local_block): Remove subblock argument.
+	  (assert_local): New function.
+	* src/vsip/impl/distributed-block.hpp (Distributed_block): Simplify 
+	  to hold 0 or 1 subblocks.
+	  (get_local_block): Remove subblock argument.
+	  (get_local_view): Handle by-value blocks correctly.
+	  (assert_local): New function.
+	  (view_assert_local): New function.
+	* src/vsip/impl/expr_binary_block.hpp (get_local_block): Remove
+	  subblock argument.
+	* src/vsip/impl/global_map.hpp (impl_subblock): New function to
+	  return local subblock.
+	* src/vsip/impl/par-chain-assign.hpp: Handle tensor assignment.
+	  Simplify for 1 subblock per processor.
+	* src/vsip/impl/par-expr.hpp (Par_expr_block): Simplify for
+	  1 subblock per processor.
+	  (get_local_block): Remove subblock arg.
+	* src/vsip/impl/par-util.hpp: New PSF functions.
+	  (foreach_point): Simplify for 1 subblock per processor, handle
+	  empty subblocks.
+
+ 	Local Maps.
+	* src/vsip/impl/local_map.hpp: New file, map for local data.
+	* src/vsip/impl/dispatch-assign.hpp: Dispatch local_maps.  Generate
+	  error if global and local maps mixed.  Handle tensor assigns.
+	* src/vsip/impl/block-traits.hpp: Generalize checking of
+	  map equality.
+	* src/vsip/impl/expr_scalar_block.hpp (Scalar_block): Use Local_map.
+	* src/vsip/impl/fast-block.hpp (Fast_block): Use Local_map as default.
+	* src/vsip/impl/signal-fft.hpp: Use Local_map by default.
+	* src/vsip/support.hpp (Local_map): forward decl.
+	  (no_subblock): New const.
+	  (no_processor): New const.
+
+	Support for distributed subviews.
+	* src/vsip/impl/dist.hpp (impl_subblock_from_index): New function,
+	  returns subblock holding index.
+	  (impl_local_from_global_index): New function, returns local
+	  index corresponding to global index.
+	* src/vsip/impl/extdata.hpp (Desired_block_layout): New functor to
+	  transform a block's native layout to a desired layout.  Used
+	  by Ext_data and Persistent_ext_data.
+	  (Ext_data): Temporarily use View_block_storage to hold block,
+	  necessary to handle by-value blocks correctly.
+	  (Persistent_Ext_data): Likewise.
+	* src/vsip/impl/layout.hpp (Is_unit_stride): New trait to determine
+	  if packing format is unit stride.
+	* src/vsip/impl/refcount.hpp (equiv_type): helper typedef.
+	* src/vsip/impl/subblock.hpp: Handle distributed subviews.
+	  Moved map projection into map.hpp.  Added Distributed_local_block
+	  trait and get_local_block overloads.
+	* src/vsip/map_fwd.hpp: Add forward decls for Map_project_1 and
+	  Map_project_2.
+	* src/vsip/map.hpp: Change subblock ordering to be row-major.
+	  (Map::impl_subblock): New function, return local subblock.
+	  (Map::impl_subblock_from_index): New function, forwarded to
+	  dimension member function.
+	  (Map::impl_local_from_global_index): Likewise.
+	  (Map_project_1): New class to project a map, removing 1 dimension.
+	  (Map_project_2): New class to project a map, removing 2 dimensions.
+
+	Misc.
+	* src/vsip/impl/view_traits.hpp: Add local_type convenience typedef.
+	* src/vsip/par-services.cpp (new_processors): New function to
+	  return number of processor in clique.
+	* src/vsip/tensor.hpp: Move whole_domain_type into vsip:: so that
+	  a single whole_domain can be used for all tensors.
+	  (Tensor): Use dispatch_assign.
+
+	Minor changes.
+	* configure.ac: Fix typo in comment.
+	* src/vsip/impl/choose-access.hpp: Add comments.
+	* src/vsip/vector.hpp: Fix formatting.
+
+	Tests.
+	* tests/distributed-block.cpp: Adjust tests for #subblocks <=
+	  #processors.  Add coverage for tensors.  Check validity of
+	  local views.
+	* tests/distributed-subviews.cpp: New test for whole-dimension
+	  subviews (vector subviews of matrices, vector & matrix subviews
+	  of tensors).
+	* tests/extdata-output.hpp: Handle Sliced_block and Sliced2_block.
+	* tests/appmap.cpp: Adjust tests for #subblocks <= #processors.
+	* tests/map.cpp: Likewise.
+	* tests/par_expr.cpp: Likewise.
+	* tests/plainblock.hpp: Use Local_map by default.
+	* tests/util.hpp (create_view): New overload for tensors.
+	* tests/util-par.hpp: Utility functions to compute subblock
+	  arrangements (squares, cubes, 2 x N).
+
+2005-07-04  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/subblock.hpp (Sliced2_block_base::size): Bug fix,
+	  sometimes returning size for wrong dimension.
+	* tests/tensor_subview.cpp: New file, tests for tensor subviews.
+
+2005-07-04  Jules Bergmann  <jules@codesourcery.com>
+
+	Change UPPER_CASE enum, variable, and class names to lower_case
+	for enums and variables, and Lower_case for classes.
+
+2005-06-20  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/map.hpp: Include algorithm, use explicit std::min.
+	* src/vsip/impl/par-services-none.hpp (free_chain): Placine 'inline'
+	  before 'void'.
+
+2005-06-20  Jules Bergmann  <jules@codesourcery.com>
+
+	* configure.ac: Fix typo, use enable_fftw3, not enable_mpi.
+	* src/vsip/impl/subblock.hpp: Fix Wall warning in impl_stride().
+
+2005-06-20  Jules Bergmann  <jules@codesourcery.com>
+
+	* configure.ac (VSIP_IMPL_PROFILE_TIMER): New acconfig.h define to
+	  select profile timer variant.  Make posix timer the default.
+	* src/vsip/impl/profile.hpp: Use VSIP_IMPL_PROFILE_TIMER.  Add
+	  support for x86_64 TSC timer.
+
+2005-06-20  Jules Bergmann  <jules@codesourcery.com>
+
+	FFTW3 Support.
+	* configure.ac: Configure VSIPL++ to use FFTW3 if present.
+	* src/vsip/impl/fft-core.hpp (FFT_core): Specializations for FFTW3.
+	* src/vsip/impl/signal-fft.hpp: Specializations for FFTW3; change
+	  layout_type to Stride_unit; collect and provide profiling data.
+
+	Fast block fill.
+	* src/vsip/impl/block-copy.hpp (Block_fill): New class, fill a
+	  block with a value in cache-friendly way.
+	* src/vsip/matrix.hpp: Use Block_copy for scalar assigments.
+
+	Ext_data improvements
+	* src/vsip/impl/extdata.hpp: Provide cost without requiring a
+	  complete low-level data access class.  Support access to
+	  const blocks.
+	* src/vsip/dense.hpp: Make direct data interface public, for
+	  subblock use.
+	* src/vsip/impl/layout.hpp (is_ct_unit_stride): New static
+	  member of packing formats to indicate if unit-stride known
+	  at compile time.
+	* src/vsip/impl/subblock.hpp: Ext_data support for Sliced_block.
+
+	Optimize handling of simple assignments.
+	* src/vsip/impl/block-traits.hpp (Is_expr_block): New trait.
+	* src/vsip/impl/expr_binary_block.hpp: Provide dim static member.
+	  Specialize Is_expr_block.
+	* src/vsip/impl/expr_ternary_block.hpp: Likewise.
+	* src/vsip/impl/expr_unary_block.hpp: Likewise.
+	* src/vsip/impl/dispatch_assign.hpp: Separate handling of serial
+	  assignments from expressions.  Use Ext_data when possible for
+	  vector serial assignments.
+
+	* src/vsip/tensor.hpp: Fix whole_domain submatrix operator() to
+	  return an impl_type.
+	* src/vsip/impl/profile.hpp (Time_in_scope): New class, use RAII
+	  to start/stop a timer.
+	* src/vsip/impl/refcount.hpp: Add impl_debug_count function.
+	* src/vsip/impl/signal-conv-ext.hpp: New file, alternate
+	  implementation of Convolution using Ext_data.
+	* src/vsip/signal.hpp: Use signal-conv-ext.hpp.
+
+	SAR example program updates.
+	* apps/sarsim/GNUmakefile: Determine CC from CXX; Use vsip::FFT
+	  by default.
+	* apps/sarsim/azimuth-process.hpp: Use vsip::FFT; Use aligned
+	  allocation for io_buf_.
+	* apps/sarsim/range-process.hpp: Use vsip::FFT; record additional
+	  profiling data.
+	* apps/sarsim/sarsim.cpp: Store polarizations in Tensor.
+
+	Test updates.
+	* tests/convolution.cpp: Measure performance of convolution.  Not
+	  enabled for regression testing.
+	* tests/fft.cpp: Test FFT accessors.
+
+2005-06-18  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/fns_elementwise.hpp: Scalar return types for
+	  mag, magsq, maxmgsq, minmgsq.
+	* src/vsip/impl/fns_scalar.hpp: Likewise.
+	* tests/fns_scalar.cpp: Testcases for above functions.
+	* tests/test-storage.hpp (Storage): Add specialization for scalar
+	  values.
+
+2005-06-18  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/signal-fft.hpp: Fix compilation errors for
+	  by-value FFT.
+	* tests/fft.cpp: New file, test case for FFT.
+
+2005-06-18  Nathan Myers  <ncm@codesourcery.com>
+
+	* tests/(lots): normalize header date format.
+
+2005-06-18  Nathan Myers  <ncm@codesourcery.com>
+
+	* src/vsip/impl/signal-fft.hpp: switch to Fast_block for temporary
+	  storage & return result; use mapped blocks (more) correctly.
+	* src/vsip/impl/fft-core.hpp: quiet signed/unsigned warnings
+
+2005-06-18  Jules Bergmann  <jules@codesourcery.com>
+
+	* configure.ac: Check if FFTW2 headers are present.
+	
+2005-06-17  Nathan Myers  <ncm@codesourcery.com>
+
+	* src/vsip/(lots): normalize header date format correctly.
+
+2005-06-17  Nathan Myers  <ncm@codesourcery.com>
+
+	* src/vsip/(lots): normalize header date format.
+	* src/vsip/impl/signal-conv.hpp: inline dim_output_size.
+
+2005-06-17  Nathan Myers  <ncm@codesourcery.com>
+
+	* src/vsip/support.hpp: use ptrdiff_t and size_t for index types.
+
+2005-06-17  Nathan Myers  <ncm@codesourcery.com>
+
+	* src/vsip/fft-float.cpp, src/vsip/fft-double.cpp,
+	  src/vsip/impl/fft-core.hpp: minor cleanups
+	* src/vsip/support.hpp: move out Scalar_of and Is_same_type
+	* src/vsip/impl/metaprogramming.hpp: add Scalar_of, add 
+	  Is_same_type functionality to Type_equal.
+	* src/vsip/signal.hpp: include new impl/signal-fft.hpp
+	* src/vsip/impl/signal-fft.hpp: new; incorporate minor cleanups,
+	  use Ext_data correctly.
+	* src/vsip/signal-fft.hpp: remove
+	* src/vsip/impl/signal-conv.hpp: fix includes
+
+2005-06-17  Jules Bergmann  <jules@codesourcery.com>
+
+	* apps/sarsim/frm_hdr.c: Remove Id and Log keywords.
+	* apps/sarsim/histcmp.c: Likewise.
+	* apps/sarsim/misc.c: Likewise.
+	* apps/sarsim/read_adts.c: Likewise.
+	* apps/sarsim/read_tbv.c: Likewise.
+	* apps/sarsim/sarx.h: Likewise.
+	
+2005-06-17  Nathan Myers  <ncm@codesourcery.com>
+
+	1D complex-complex float FFT using FFTW2; most of 2D, 3D, 
+	double, real->complex, complex->real
+
+	* src/vsip/fft-float.cpp, src/vsip/fft-double.cpp,
+	  src/vsip/signal-fft.hpp, src/vsip/impl/fft-core.hpp: new.
+	* src/vsip/domain.hpp: add lvalue indexed accessor
+	* src/vsip/support.hpp: add utility templates Is_same_type<T1,T2>,
+	  Scalar_of<>; change index typedefs from long to int.
+	* configure.ac: add FFT build options.
+
+2005-06-16  Jules Bergmann  <jules@codesourcery.com>
+
+	SAR example application.
+	* apps/sarsim/sarsim.cpp: New file, SAR simulation, derived from
+	  MIT/LL RASSP SarSim demo program.
+	* apps/sarsim/fft-fftw-impl.cpp: New file, FFT bits that depend
+	  on FFTW3 headers.
+	* apps/sarsim/azimuth-process.hpp: New file, implements SAR azimuth
+	  processing.
+	* apps/sarsim/cast-block.hpp: New file, utility for mixed precision
+	  expressions.
+	* apps/sarsim/fft-common.hpp: New file, common elements for fft.
+	* apps/sarsim/fft-fftw.hpp: New file, Vector_FFT using FFTW3.
+	* apps/sarsim/fft-fftw-impl.hpp: New file, interface to FFT bits
+	  that depend on FFTW3 headers.
+	* apps/sarsim/fft.hpp: New file, plan C++ FFT.
+	* apps/sarsim/loadview.hpp: New file, utility to load file into view.
+	* apps/sarsim/range-process.hpp: New file, implements SAR range
+	  processing.
+	* apps/sarsim/saveview.hpp: New file, utility to save file from view.
+	* apps/sarsim/frm_hdr.c: New file, SarSim C support.
+	* apps/sarsim/histcmp.c: New file, likewise.
+	* apps/sarsim/misc.c: New file, likewise.
+	* apps/sarsim/read_adts.c: New file, likewise.
+	* apps/sarsim/read_tbv.c: New file, likewise.
+	* apps/sarsim/util_io.c: New file, likewise.
+	* apps/sarsim/read_adts.h: New file, likewise.
+	* apps/sarsim/read_tbv.h: New file, likewise.
+	* apps/sarsim/sarx.h: New file, likewise.
+	* apps/sarsim/util_io.h: New file, likewise.
+	* apps/sarsim/GNUmakefile: New file, makefile for SAR example.
+
+	Test data for SAR application.
+	* apps/sarsim/sims-8-4: New file, run single-precision SAR test.
+	* apps/sarsim/simd-8-4: New file, run double-precision SAR test.
+	* apps/sarsim/chk-sims-8-4: New file, check single-precision SAR test.
+	* apps/sarsim/chk-simd-8-4: New file, check single-precision SAR test.
+	* apps/sarsim/test-8/data/: New directory, containing input
+	  data for SAR program.
+	* apps/sarsim/test-8/ref-plan/: New directory, containing reference
+	  output data for SAR program.
+
+	Profiling support:
+	* src/vsip/profile.cpp: New file, basic profiling support.
+	* src/vsip/impl/profile.hpp: New file, likewise.
+	
+	* src/vsip/impl/signal-conv.hpp: New function impl_performance() to
+	  report on measured performance.
+	
+2005-06-15  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/vector.hpp: Add missing argument for parent's
+	  constructor.
+
+	Implement Convolution.
+	* src/vsip/signal.hpp: New file, wrapper for signal processing
+	  objects.
+	* src/vsip/vector.hpp (view_domain): New function, return extent
+	  of view as domain.
+	* src/vsip/impl/signal-conv.hpp: New file, Convolution class.
+	* src/vsip/impl/signal-types.hpp: New file, common enums for
+	  signal processing.
+	* tests/convolution.cpp: New file, test cases for convolution.
+
+	Implement Global_map.
+	* src/vsip/support.hpp (Global_map): Change from definition of
+	  Serial_map to forward declaration of Global_map.
+	* src/vsip/dense.hpp: Include global_map header, apply it at
+	  dense construction, specialize get_local_block for serial
+	  blocks.
+	* src/vsip/impl/distributed-block.hpp: New parallel support
+	  functions subblocks_begin and subblocks_end.
+	* src/vsip/impl/par-assign.hpp: Use buf_send/recv from par-util.
+	* src/vsip/impl/par-chain-assign.hpp: Check if subblock is
+	  replicated destination processor before sending.
+	* src/vsip/impl/par-services-mpi.hpp: Move functions
+	  with view parameters to par-util.
+	* src/vsip/impl/par-services-none.hpp: Likewise.
+	* src/vsip/impl/par-util.hpp: New file, send/recv functions
+	  with view parameters, parallel foreach functions.
+	* src/vsip/impl/global_map.hpp: New file, implements Global_map.
+	* src/vsip/map.hpp: Add 'impl_working_size' function to determine
+	  number of processors owning distributed data.
+	* tests/distributed-block.cpp: Add tests for Global_map.  Move
+	  common functions to util-par.hpp.
+	* tests/par_expr.cpp: Move common function to util.hpp and
+	  util-par.hpp.
+	* tests/util.hpp: New file, common test functions for cloning
+	  views.
+	* tests/util-par.hpp: New file, common parallel test functions
+	  and classes.
+	
+	* src/vsip/impl/dispatch-assign.hpp: Use Global_map instead of
+	  Serial_map.
+	* src/vsip/impl/expr_scalar_block.hpp: Likewise.
+	* src/vsip/impl/fast-block.hpp: Likewise.
+	* src/vsip/impl/subblock.hpp: Likewise.
+	* tests/plainblock.hpp: Likewise.
+
+2005-06-13  Zack Weinberg  <zack@codesourcery.com
+
+	* src/vsip/impl/lvalue-proxy.hpp: Delete True_lvalue_callop_factory;
+	rename True_lvalue_implref_factory to True_lvalue_factory.
+	(Lvalue_proxy [all specializations]): Hold an uncounted reference
+	to the block, not a View_block_storage instance.
+	* src/vsip/impl/block-traits.hpp: Delete True_lvalue_callop_factory;
+	rename True_lvalue_implref_factory to True_lvalue_factory.
+	(Lvalue_factory_type): Add Rebind nested class.
+	* src/vsip/dense.hpp: Rename all operator()(index_type, ...) to
+	impl_ref(). Update Lvalue_factory_type specialization.
+	* src/vsip/impl/subblock.hpp: Add impl_ref() functions to all
+	classes that can implement them, and matching Lvalue_factory_type
+	specializations.
+
+	* tests/plainblock.hpp: Add impl_ref functions, conditional on
+	PLAINBLOCK_ENABLE_IMPL_REF.
+	* tests/lvalue-proxy.cpp: Refer to True_lvalue_factory, not
+	True_lvalue_callop_factory nor True_lvalue_implref_factory.
+	* tests/dense.cpp: Test impl_ref, not operator().
+	* tests/view_lvalue.cpp: Include plainblock.hpp.  Do all tests with
+	both Dense<n> and Plain_block<n> (except <3>).  Add some tests of
+	subblocks.
+
+2005-06-13  Nathan Myers  <ncm@codesourcery.com>
+
+	* src/vsip/impl/view_traits: add vsip::impl_[const_]View
+	  specializations for std::complex<>
+	* src/vsip/{vector,matrix,tensor}.hpp: remove Vector, Matrix,
+	  Tensor specializations, also Vector_base etc. apparatus.
+
+2005-06-11  Nathan Myers  <ncm@codesourcery.com>
+
+	* src/vsip/complex.hpp, map.hpp, impl/distributed-block.hpp,
+	  impl/expr_binary_block.hpp, impl/par-expr.hpp;
+	  tests/appmap.cpp, distributed-block.cpp,
+	  par_expr.cpp: Clean up "-W -Wall" warnings.
+
+2005-06-09  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/par-services-none.hpp: Add missing include.
+
+	Evaluate parallel expressions with different RHS mappings.
+	* src/vsip/impl/block-traits.hpp (Is_par_same_map): New trait.
+	  Combination compile-time/run-time check if maps are same.
+	  (Combine_return_type): New trait to determine return type of
+	  expression tree transformations.
+	  (apply_combine): Function set to transform expression trees.
+	  (apply_leaf): Function set to perform action at expression trees
+	  leaves.
+	* src/vsip/dense.hpp (Combine_return_type): Add specialization.
+	  (apply_combine): Likewise.
+	* src/vsip/impl/distributed-block.hpp: Likewise.
+	* src/vsip/impl/dispatch-assign.hpp: Use 'par_expr()' and
+	  'par_expr_simple()' (from par-expr.hpp) to evalute
+	  distributed expressions.
+	* src/vsip/impl/domain-utils.hpp (block_domain): New function.
+	  Return block extent as domain.
+	* src/vsip/impl/expr_binary_block.hpp
+	  (Expr_block_storage): specialization to store Binary_expr_block
+	  by-value.
+	  (Combine_return_type): Specialization for traversing
+	  Binary_expr_block's.
+	  (apply_combine): Likewise.
+	  (apply_leaf): Likewise.
+	  (Is_par_same_map): Likewise.
+	* src/vsip/impl/par-expr.hpp: New file, provides classes and
+	  functions to evaluate simple and complex distributed
+	  expressions.
+	* src/vsip/impl/par-services-mpi.hpp: Free buffer.
+	* src/vsip/map.hpp (operator==): Compare maps with different types.
+	* tests/par_expr.cpp: Extend to cover expressions with
+	  different RHS maps, and expressions with more than one
+	  operator.
+
+	Merge App_map functionality into Map.
+	* src/vsip/map.hpp: Assume App_map functionality.
+	* src/vsip/impl/appmap.hpp: Remove file.
+	* src/vsip/impl/dispatch-assign.hpp: Use map instead of App_map.
+	* src/vsip/impl/distributed-block.hpp: Likewise.
+	* src/vsip/impl/par-assign.hpp: Likewise.
+	* src/vsip/impl/par-chain-assign.hpp: Likewise.
+	* tests/appmap.cpp: Likewise.
+	* tests/distributed-block.cpp: Likewise.
+	* tests/par_expr.cpp: Likewise.
+
+	Store grid function in std::vector.
+	* src/vsip/map.hpp: Store grid function as std::vector,
+	  provide additional interface to limit external assumptions
+	  on how grid function is stored.
+	* src/vsip/impl/appmap.hpp: Likewise.
+	* src/vsip/impl/par-services-mpi.hpp (Communicator): Return
+	  default processor vector as std::vector.
+	* src/vsip/impl/par-services-none.hpp (Communicator): Likewise.
+	* src/vsip/impl/par-assign.hpp: Access grid function through
+	  general interface.
+	* src/vsip/impl/par-chain-assign.hpp: Likewise.
+
+2005-06-08  Nathan Myers  <ncm@codesourcery.com>
+
+	* src/vsip/impl/allocation.hpp: add "return" to fix syntax
+	  error for the case of no posix_memalign() and no memalign().
+
+2005-06-08  Nathan Myers  <ncm@codesourcery.com>
+
+	* src/vsip/impl/view_traits.hpp: Add vsip::impl_View<View,Block>
+	  and vsip::impl_const_View<View,Block> base class templates
+	  for views.  Also, forward-declare views, and add
+	  impl::Const_of_view<V,B> and impl::Dim_of_view<V> utility
+	  templates.
+	* src/vsip/vector.hpp, matrix.hpp, tensor.hpp: Derive views from
+	  vsip::impl_View<> or vsip::impl_const_View<> as appropriate;
+	  sanitize member typedef names; eliminate unnecessary member
+	  using-directives.
+
+2005-06-06  Mark Mitchell  <mark@codesourcery.com>
+
+	* doc/GNUmakefile.inc.in ($(doc_manuals): Depend on opl.xml.
+	* opl.xml: New file.
+	* doc/quickstart/quickstart.xml: Use it.
+
+2005-06-03  Zack Weinberg  <zack@codesourcery.com>
+
+	* configure.ac: Add probe for xml.dcl.
+	* GNUmakefile.in: Set XML_DCL to the location of xml.dcl as
+	determined by configure.  Don't generate documentation if it
+	wasn't found.  Use $(XML_DCL) in Jade invocation.  Use wraptex
+	in pdfjadetex invocation.
+	* doc/wraptex: New file.
+
+2005-06-03  Zack Weinberg  <zack@codesourcery.com>
+
+	* src/vsip/impl/lvalue-proxy.hpp: New file.
+	* src/vsip/impl/block_traits.hpp (Proxy_lvalue_factory)
+	(True_lvalue_callop_factory, True_lvalue_implref_factory): Declare.
+	(Lvalue_factory_type): New traits class.
+	* src/vsip/dense.hpp: Specialize Lvalue_factory_type appropriately.
+	* src/vsip/matrix.hpp, src/vsip/tensor.hpp, src/vsip/vector.hpp:
+	Include vsip/impl/lvalue-proxy.hpp.  Add 'factory_type'
+	private typedef to Matrix_base, Tensor_base, Vector_base
+	respectively. Change those classes' 'reference_type' to
+	factory_type::reference_type.  Implement operator() with
+	appropriate number of index_type arguments for those classes.
+
+	* tests/lvalue-proxy.cpp, tests/view_lvalue.cpp: New tests.
+
+2005-06-03  Mark Mitchell  <mark@codesourcery.com>
+
+	* src/vsip/impl/refcount.hpp (noincrement_t): Rename to
+	noincrement_type.
+	(Ref_counted_ptr::Ref_counted_ptr): Adjust accordingly.
+	(RPPtr::RPPtr): Likewise.
+	(Mutable): New template.
+	(Stored_value): Use it, instead of storing the object directly.
+
+2005-06-03  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/allocation.hpp: Update malloc.h and memalign
+	  decl to match configure.
+	* src/vsip/impl/dispatch-assign.hpp: -Wall cleanup.
+
+2005-06-02  Mark Mitchell  <mark@codesourcery.com>
+
+	* COPYRIGHT: Rebrand VSIPL++Pro as Sourcery VSIPL++.
+	* README: Likewise.
+	* vsipl++.pc.in: Likewise.
+	* doc/quickstart/quickstart.xml: Likewise.
+	* scripts/src-release: Likewise.
+
+2005-06-02  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/metaprogramming.hpp (Compare): New class to
+	  compare compile-time values against run-time values, while
+	  avoiding -Wall warnings.
+	* src/vsip/impl/subblock.hpp (Sliced_block_base): Use Compare for
+	  unsigned comparison against zero.
+	  (Sliced2_block_base): Likewise.
+	* tests/tensor.cpp (tc_assign): Fix unused parameter.
+
+2005-06-02  Mark Mitchell  <mark@codesourcery.com>
+
+	* src/vsip/map.hpp: Include <vsip/impl/dist.hpp>.
+	(vsip::impl::segment_size): Move to vsip/impl/dist.hpp.
+	(vsip::impl::segment_chunks): Likewise.
+	(vsip::impl::segment_chunk_size): Likewise.
+	(vsip::impl::segment_start): Likewise.
+	(vsip::Block_dist): Likewise.
+	(vsip::Cyclic_dist): Likewise.
+	* src/vsip/impl/subblock.hpp: Include <vsip/impl/dist.hpp>.
+	* src/vsip/impl/dist.hpp: New file.
+
+	* configure.ac: Use AS_HELP_STRING.  Remove check for
+	std::complex<T>::real() and std::comlpex<T>::imag() being
+	lvalues.
+	* src/vsip/impl/subblock.hpp (Real_extractor::set): Do not expect
+	std::complex<T>::real() to be an lvalue.
+	(Imag_extractor::set): Likewise, for std::complex<T>::imag().
+
+2005-06-02  Zack Weinberg  <zack@codesourcery.com>
+
+	* configure.ac: Specify prerequisite headers for AC_CHECK_HEADERS
+	and AC_CHECK_DECLS tests.
+	Set vsip_impl_avoid_posix_memalign explicitly to the empty string,
+	before checking for MPI libs, and to "yes" instead of "true" if
+	using LAM-MPI.
+	Test vsip_impl_avoid_posix_memalign with test -n, not by executing it.
+
+2005-06-02  Jules Bergmann  <jules@codesourcery.com>
+
+	* vsipl++.pc.in (cxx): New variable, compiler used to build library.
+	  (Cflags): Get includes from configure.
+	* doc/quickstart/quickstart.xml: Document getting compiler from
+	  pkg-config.
+
+2005-06-02  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* src/vsip/impl/fns_elementwise.hpp: Provide specialized overloads
+	for binary view functions where V1 == V2 to solve issue 40.
+	* tests/view_functions.cpp: Test it.
+
+2005-06-02  Nathan Myers  <ncm@codesourcery.com>
+
+	* src/vsip/impl/refcount.hpp: put "mutable" where gcc-4 wants it.
+
+2005-06-02  Zack Weinberg  <zack@codesourcery.com>
+
+	* src/vsip/impl/expr_scalar_block.hpp (class Scalar_block_base):
+	Add missing 'dim' static member.
+
+2005-06-02  Jules Bergmann  <jules@codesourcery.com>
+
+	* doc/quickstart/quickstart.xml: Add instructions for using pkg-config.
+	* vsipl++.pc.in: New file, pkg-config metadata.
+	* GNUmakefile.in (install): Install vsipl++.pc .
+
+2005-06-02  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* src/vsip/impl/fns_scalar.hpp: Complete functions as of Table 8.1
+	of the spec.
+	* src/vsip/impl/fns_elementwise.hpp: Likewise.
+	* tests/view_functions.cpp: Test the new functions.
+
+2005-06-02  Jules Bergmann  <jules@codesourcery.com>
+
+	* doc/release/README: Move to ...
+	* README: ... here.
+	* doc/release/COPYRIGHT: Move to ...
+	* COPYRIGHT: ... here.
+	* doc/release/COPYING: Move and rename to ...
+	* LICENSE: ... this.
+
+2005-06-01  Jules Bergmann  <jules@codesourcery.com>
+
+	Distributed Dense blocks.
+	* src/vsip/dense.hpp: Derive Dense blocks with non-serial maps
+	  from Distributed_block.  Add speclializations/overloads for
+	  Distributed_local_block, Is_simple_distributed_block, and
+	  get_local_block().
+	* tests/distributed-block.cpp: Use Dense to name distributed blocks.
+
+	Distributed expressions w/o communication.
+	* src/vsip/impl/dispatch-assign.hpp (par_expr): Use
+	  Distributed_local_block trait to determine local block type.
+	* src/vsip/impl/distributed-block.hpp: Add get_local_block
+	  function general case and specialization for
+	  Distributed_block.
+	* src/vsip/impl/expr_binary_block.hpp: Add Distributed_local_block
+	  and get_local_block specializations for Binary_expr_block.
+	* tests/par_expr.cpp: New file, tests for parallel expressions.
+
+2005-06-01  Mark Mitchell  <mark@codesourcery.com>
+
+	* src/vsip/allocation.cpp (impl_free_align): Return "void".
+	* src/vsip/impl/application.hpp (impl_free_align): Likeiwse.
+
+2005-05-27  Mark Mitchell  <mark@codesourcery.com>
+
+	* GNUmakefile.in (docdir): New variable.
+	(DOXYGEN): Likewise.
+	(all): Depend on doc.
+	(doc): Remove.
+	* configure.ac (doxygen): Check for it.
+	* doc/GNUmakefile.inc.in (doc/html/index.html): New target.
+	(clean): Remove it.
+	(install): Install manuals.
+
+2005-05-26  Mark Mitchell  <mark@codesourcery.com>
+
+	* doc/quickstart/quickstart.xml: Adjust name of source directory.
+	* scripts/src-release: New script.
+
+2005-05-26  Jules Bergmann  <jules@codesourcery.com>
+
+	* doc/quickstart/quickstart.xml: Add paragraphs on compilers known
+	  to work/not work, recommended options for LAM/MPI.  Document
+	  configure '--with-mpi-prefix' option.
+	* examples/GNUmakefile.inc.in (examples/example1$(EXEEXT)): Use
+	  $(LDFLAGS) and $(LIBS).
+	* doc/release/COPYING: New file, license for source releases.
+	* doc/release/COPYRIGHT: New file, copyright for source releases.
+	* doc/release/README: New file, top-level readme for source releases.
+
+2005-05-25  Mark Mitchell  <mark@codesourcery.com>
+
+	* GNUmakefile.in (datadir): New variable.
+	* doc/quickstart/quickstart.xml: Add section on building first
+	VSIPL++ program.
+	* examples/GNUmakefile.inc.in: Fix typos in variable naming
+	convention.
+	(install): New rule.
+	* src/vsip/GNUmakefile.inc.in (install): Simplify slightly.
+
+	* GNUmakefile.in (prefix): Put it first.
+	(EXEEXT): New variable.
+	(OBJEXT): Likewise.
+	(objects): Use $(OBJEXT).
+	(%.o): Rename to ...
+	(%.$(OBJEXT)): ... this.
+	(%.d): Use $(OBJEXT).
+	(check): Fix for objdir != srcdir.
+	* src/vsip/GNUmakefile.inc.in (src_vsip_cxx_objects): Use $(OBJEXT).
+	* examples/GNUmakefile.inc.in: New file.
+	* examples/example1.cpp: Likewise.
+
+	Issue #38
+	* src/vsip/initfini.cpp: Rename to ...
+	* src/vsip/initfin.cpp: ... this.
+	* src/vsip/initfini.hpp: Rename to ...
+	* src/vsip/initfin.hpp: ... this.
+	* tests/distributed-block.cpp: Include <vsip/initfin.hpp>, not
+	<vsip/initfini.hpp>.
+	* tests/initfini.cpp: Likewise.
+	* tests/map.cpp: Likewise.
+
+2005-05-25  Jules Bergmann  <jules@codesourcery.com>
+
+	Aligned memory allocation.
+	* configure.ac: Add checks for memalign and posix_memalign.
+	* src/vsip/allocation.cpp: New file, aligned memory allocation
+	  routines.
+	* src/vsip/impl/allocation.hpp.hpp: Likewise.
+	* src/vsip/impl/aligned_allocator.hpp: New file, aligned allocator.
+	* src/vsip/impl/layout.hpp (Storage): Template parameter for
+	  allocator.
+	* src/vsip/dense.hpp: Call storage deallocate() prior to destruction.
+	* src/vsip/impl/extdata.hpp: Likewise.
+	* src/vsip/impl/fast-block.hpp: Likewise.
+	* tests/plainblock.hpp: Likewise.
+
+2005-05-24  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* src/vsip/impl/expr_functions.hpp: Removed, replaced by...
+	* src/vsip/impl/fns_elementwise.hpp: ...this new file.
+	* src/vsip/impl/expr_functor.hpp: New function dispatching framework.
+	* src/vsip/impl/fns_scalar.hpp: Provide more scalar functions.
+	* src/vsip/math.hpp: Use fns_elementwise.hpp.
+	* src/vsip/impl/view_traits.hpp: Enhance Is_view_type trait.
+	* src/vsip/matrix.hpp: Use it.
+	* src/vsip/vector.hpp: Likewise.
+	* src/vsip/tensor.hpp: Likewise.
+	* src/vsip/impl/expr_binary_operators.hpp: Likewise.
+	* src/vsip/impl/expr_ternary_block.hpp: Likewise.
+	* src/vsip/impl/expr_unary_block.hpp: Likewise.
+	* tests/view_operators.cpp: Move function tests into...
+	* tests/view_functions.cpp: ...this file.
+
+2005-05-21  Mark Mitchell  <mark@codesourcery.com>
+
+	* doc/GNUmakefile.inc.in: New file.
+	* doc/README: Likewise.
+	* doc/tex.dsl: Likewise.
+	* doc/quickstart/quickstart.xml: Likewise.
+
+	* GNUmakefile.in (.DELETE_ON_ERROR): Set it.
+	(all): Move to top of file.
+	(exec_prefix): New variab.e
+	(prefix): Likewise.
+	(includedir): Likewise.
+	(libdir): Likewise.
+	(INSTALL): Likewise.
+	(INSTALL_DATA): Likewise.
+	(JADE): Likewise.
+	(PDFJADETEX): Likewise.
+	(docbook): Likewise.
+	(%.xml): Add to vpath.
+	(%.o): Do not rm files on error.
+	(%.d): Likewise.
+	(%.jtex): New rule.
+	(%.pdf): Likewise.
+	(GNUmakefile): Refine dependencies.
+	(config.status): New rule.
+	* configure.ac (JADE): Set it.
+	(PDFJADETEX): Likewise.
+	(AC_PROG_INSTALL): Use it.
+	* src/vsip/GNUmakefile.inc.in (install): New rule.
+
+2005-05-20  Mark Mitchell  <mark@codesourcery.com>
+
+	* GNUmakefile.in (all): Depend on GNUmakefile.
+	($(srcdir)/configure): New target.
+	(GNUmakefile): Likewise.
+
+2005-05-20  Zack Weinberg  <zack@codesourcery.com>
+
+	* configure.ac: If we cannot find the MPI libraries, fall back
+	to --disable-mpi mode, unless the user explicitly said either
+	--enable-mpi or --with-mpi-prefix=something.  Look for -lmpich
+	before -lmpi.
+
+2005-05-19  Jules Bergmann  <jules@codesourcery.com>
+
+	Implement user-storage (admit/release)
+	* src/vsip/dense.hpp: Add Dense_impl base class that implements
+	  user-storage (admit/release).
+	* src/vsip/impl/layout.hpp (Storage): add rebind() and
+	  is_alloc() members.
+	* src/vsip/impl/point.hpp: Add 3-dim specializations for next,
+	  block get, and block put.
+	* tests/dense.cpp: Add tests for user-storage functions when
+	  user-storage is not being used.
+	* tests/user_storage.cpp: New file, test cases for user-storage.
+
+	* src/vsip/math.hpp: Fix filename in header.
+
+2005-05-18  Zack Weinberg  <zack@codesourcery.com>
+
+	* .cvsignore: New file.
+	* src/vsip/impl/.cvsignore: Also ignore acconfig.hpp.in.
+
+2005-05-18  Zack Weinberg  <zack@codesourcery.com>
+
+	* configure.ac: Rewrite MPI probe from scratch, simplifying
+	logic and adding ability to use <mpi/mpi.h> as well as <mpi.h>.
+	Use AC_CANONICAL_HOST, not AC_CANONICAL_TARGET.  No need for
+	AC_PROG_CPP nor AC_PROG_CC.  Unconditionally set language to
+	C++ after finding compiler.  Reject compilers known to have bugs
+	which VSIPL++ triggers. Fix typo in bug-report address.
+
+	* src/vsip/impl/subblock.hpp: Declare Dist_factory and all its
+	specializations with 'struct', not 'class'.
+
+	* src/vsip/impl/par-services-mpi.hpp: Include vsip/impl/config.hpp
+	and then VSIP_IMPL_MPI_H, whatever that turns out to be.
+	* tests/mpi.cpp: Likewise.
+	* tests/context.in: Use @host@, not @target@.
+	* tests/QMTest/.cvsignore: New file.
+
+2005-05-17  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* src/vsip/impl/expr_functions.hpp: Add support for mixed scalar/view
+	functions.
+	* tests/view_operators.cpp: Test mixed scalar/view functions.
+	* src/vsip/impl/timer.hpp: New file.
+	* src/vsip/impl/subblock.hpp: Infer a subblock's map from the original's
+	block's map.
+	* src/vsip/map.hpp: Move forward declaration of Map ...
+	* src/vsip/map_fwd.hpp: ...here.
+	* src/vsip/tensor.hpp: Fixed some adjustments to new naming scheme.
+
+2005-05-13  Jules Bergmann  <jules@codesourcery.com>
+
+	Initial assignment dispatch.
+	* src/vsip/impl/block-traits.hpp (Is_simple_distributed_block):
+	  New trait.
+	* src/vsip/impl/dispatch-assign.hpp: New file, dispatch for
+	  serial and distributed assignments.
+	* src/vsip/impl/distributed-block.hpp: Implemented 'map()' member
+	  function.
+	* src/vsip/impl/par-chain-assign.hpp: Copy data that stays on
+	  same processor, rather than sending messages.
+	* src/vsip/map.hpp (Is_serial_map): New trait Is_serial_map,
+	  implemented operator== for Map.
+	* src/vsip/matrix.hpp: Use Dispatch_assign for assignments.
+	* src/vsip/vector.hpp: Likewise.
+	* tests/distributed-block.cpp: Use view operator= for
+	  distributed assigments.
+
+2005-05-11  Jules Bergmann  <jules@codesourcery.com>
+
+	Batten down view operators to work only for valid views.
+	* src/vsip/impl/expr_binary_operators.hpp
+	  (Binary_operator_return_type): Add Tag types to trigger SFINAE
+	  if views are not valid.
+	* src/vsip/impl/expr_unary_operators.hpp
+	  (Unary_operator_return_type): Likewise.
+	* src/vsip/impl/view_traits.hpp (Is_view_type): New view trait,
+	  provides typedef 'type' for valid views.
+	* src/vsip/matrix.hpp (Is_view_type): Provide specialization.
+	* src/vsip/tensor.hpp (Is_view_type): Likewise.
+	* src/vsip/vector.hpp (Is_view_type): Likewise.
+
+2005-05-11  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/initfini.cpp (vsipl::vsipl): Put a program name in
+	  fake argc/argv to prevent MPICH-1.2.6 from segfaulting.
+
+2005-05-10  Nathan Myers  <ncm@codesourcery.com>
+
+	* (almost all files): change all StudlyCaps names except
+	  those in the spec.
+
+2005-05-10  Nathan Myers  <ncm@codesourcery.com>
+
+	* src/vsip/impl/par-chain-assign.hpp, tests/appmap.cpp:
+	  Fix misuse of class name as template parameter formal
+	  argument name (AppMap->AppMapT, ExtData->ExtDataT).
+	  This is preparatory to fixing non-template-parameter
+	  uses of StudlyCaps in the library.
+
+2005-05-09  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/par-services-mpi.hpp: Throw unimplemented() on
+	  MPI errors, rather than (incorrectly) use assert().
+
+2005-05-09  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/par-chain-assign.hpp: -Wall cleanup.
+	* src/vsip/impl/par-services-mpi.hpp: Likewise.
+
+2005-05-09  Jules Bergmann  <jules@codesourcery.com>
+
+	Use direct access to block data and MPI datatypes for parallel
+	assignment.
+	* configure.ac: Detect MPICH-1.  Detect if LAM-MPI requires
+	  C++ libraries.
+	* src/vsip/impl/appmap.hpp: Make lookup_index() public.
+	* src/vsip/impl/distributed-block.hpp: Add required include.
+	* src/vsip/impl/extdata.hpp: Rename type 'DataSyncAction' to
+	  'sync_action_type'.  Change LowLevelDataAccess to use
+	  explicit begin/end.  Add PersistentExtData class that exports
+	  begin/end.
+	* src/vsip/impl/layout.hpp: Fix bug where alloc_data_ member
+   	  not being set in constructor.
+	* src/vsip/impl/par-assign.hpp: Rename ChainedParallelAssign
+	  to PackedParallelAssign.  Remove unnecessary empty messages.
+	* src/vsip/impl/par-chain-assign.hpp: New file, implements
+	  parallel assignment with real chaining.
+	* src/vsip/impl/par-services-mpi.hpp (Communicator): Add
+	  send()/recv() for chains (aka MPI_Datatypes).
+	  (ChainBuilder) New class to construct DMA chains.
+	* tests/distributed-block.cpp: Add loop argument to repeat
+	  assignments after setup.
+	* tests/extdata.cpp: Update low-level tests to use begin/end.
+
+2005-05-05  Nathan Myers  <ncm@codesourcery.com>
+
+	* src/vsip/impl/point.hpp: make op[] const return by value
+
+2005-04-30  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* src/vsip/impl/expr_ternary_block.hpp: New file.
+
+2005-04-28  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* src/vsip/impl/expr_unary_block.hpp: Revert last (incomplete) change.
+	* src/vsip/impl/expr_binary_block.hpp: Likewise.
+	* src/vsip/matrix.hpp: More use of StoredValue for subblocks.
+	* src/vsip/impl/subblock.hpp: Likewise. Add Sliced2Block.
+	* tests/matrix.cpp: Fix typo.
+	* src/vsip/tensor.hpp: New file.
+	* tests/tensor.cpp: New file.
+
+2005-04-27  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* src/vsip/impl/expr_unary_block.hpp: Remove redundant 'const'.
+	* src/vsip/impl/expr_binary_block.hpp: Likewise.
+
+	* src/vsip/impl/fns_scalar.hpp: New file.
+	* src/vsip/impl/expr_functor.hpp: New file.
+	* src/vsip/impl/expr_functions.hpp: New file.
+	* src/vsip/math.hpp: Include headers for functions and
+	function expressions.
+	* tests/view_operators.cpp: Add tests for function expressions.
+
+2005-04-27  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/matrix.hpp: Swap fixed dimension for RowBlock and
+	  ColumnBlock typedefs (they were reversed).
+	* tests/matrix.cpp: Additional tests for row and column subviews
+	  of matrix.
+
+
+2005-04-26  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/dense.hpp (Dense): Added 3-dim specialization.yy
+	* src/vsip/impl/layout.hpp (AppliedLayout): Added 3-dim
+	  specialization.
+	* tests/dense.cpp: Added coverage for 3-dim dense blocks.
+
+2005-04-25  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* src/vsip/impl/refcount.hpp: Make StoredValue RefCountedPtr compliant.
+	* src/vsip/impl/subblock.hpp: Change storage trait to StoredValue for
+	subblock types.
+	* src/vsip/vector.hpp: Streamline subblock allocation.
+	* src/vsip/matrix.hpp: Likewise.
+
+2005-04-21  Nathan Myers  <ncm@codesourcery.com>
+
+	* src/vsip/domain.hpp: eliminate Domain_base<1>; add const,
+	  this->, impl_, private: and protected: where appropriate;
+	  change function struct operator()() to members apply().
+
+2005-04-21  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* src/vsip/vector.hpp: Add missing subview types and fix
+	compound assign operators.
+	* src/vsip/matrix.hpp: Add support for column and row subviews
+	as well as real and imaginary component views for complex matrices.
+	* src/vsip/impl/subblock.hpp: Adjust SlicedBlock for use in Matrix.
+	* src/vsip/impl/par-services-mpi.hpp: Remove redundant ';'.
+	* tests/vector.cpp: Test compound assign operators.
+	* tests/matrix.cpp: New matrix tests.
+
+2005-04-20  Nathan Myers  <ncm@codesourcery.com>
+
+	* src/vsip/impl/domain.hpp: Rewrite. Built & tested
+	  on gcc-4 and gcc-3.3.
+
+2005-04-20  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/noncopyable.hpp (NonCopyable): Add comment.on
+	  (NonAssignable): Remove protected constructor to avoid GCC
+	  '-W -Wall' warnings.
+
+	Implement simulate message passing for par-services-none.
+	* src/vsip/impl/par-services-none.hpp (Communicator): Implemented
+	  message passing via queuing of message between send/receive.
+	* tests/distributed-block.cpp: Remove direct references to MPI,
+	  use par-services instead.
+
+	Cleanup for '-Wall' warnings.
+	* src/vsip/impl/appmap.hpp (AppMap): Change initializer list
+	  ordering to match class declaration.
+	* src/vsip/impl/extdata.hpp (mem_required): Change return type
+	  to 'size_t'.
+	* src/vsip/impl/par-assign.hpp: Remove unused variables and debug
+	  sprintfs.
+	* src/vsip/impl/layout.hpp: Remove unused parameter name.
+	* tests/extdata-output.hpp: Likewise.
+	* tests/fast-block.hpp: Likewise.
+
+2005-04-18  Nathan Myers <ncm@codesourcery.com>
+
+	Prepare to replace domain.hpp
+	* src/vsip/domain.hpp: add members impl_add_in (which call op+=)
+	* src/vsip/impl/layout.hpp: include impl/index.hpp
+	* tests/domain.cpp: call member impl_add_in instead of op+=
+	* tests/view.cpp: include impl/index.hpp
+	* src/vsip/initfini.hpp: comment
+
+2005-04-18  Jules Bergmann  <jules@codesourcery.com>
+
+	Implement direct data access for blocks.
+	* src/vsip/dense.hpp: Use new AppliedLayout for layout policy,
+	  (replaces DenseLayout).  Use Storage for management of raw
+	  data array, it understands complex interleaved and split
+	  formats.
+	* src/vsip/support.hpp (tuple): Add static const member
+	  variables's Dim0, Dim1, and Dim2.
+	* src/vsip/impl/block-copy.hpp: New file, copies data
+	  between a block and a regular array.
+	* src/vsip/impl/block-traits.hpp (BlockLayout): New trait
+	  to represent block layout and data access.
+	* src/vsip/impl/choose-access.hpp: New file, Choose data
+	  access type based on block's data access type, block's
+	  layout, and requested layout.
+	* src/vsip/impl/extdata.hpp: New file, implements low-level
+	  data access (LowLevelDataAccess), high-level data acess
+	  (ExtData), utility classes, and utility functions.
+	* src/vsip/impl/fast-block.hpp: New file, block capable of
+	  aligned (non-dense) storage and split/interleaved complex
+	  storage.
+	* src/vsip/impl/layout.hpp: New file, provides layout and
+	  storage classes to handle packing formats and complex
+	  formats respectively.
+	* src/vsip/impl/metaprogramming.hpp: New file, utilities for
+	  template meta-programming.
+	* src/vsip/impl/point-fcn.hpp: New file, contains functions
+	  previously point.hpp dependent on views.
+	* src/vsip/impl/point.hpp: Move functions dependent on views
+	  to point-fcn.hpp to simplify header dependencies.
+	* src/vsip/impl/refcount.hpp (RPPtr): New reference counted
+	  point class that takes reference counting actions as policy.
+	* src/vsip/impl/subblock.hpp: Add BlockLayout traits for
+	  SubsetBlock and TransposeBlock.
+	* tests/extdata-fft.cpp: New file, test/example for using
+	  extdata with pseudo-signal processing objects.
+	* tests/extdata-matadd.cpp: New file, test/example for using
+	  extdata interface with matrix-add example.
+	* tests/extdata.cpp: New file, test/example for using extdata.
+	* tests/extdata-output.hpp: New file, utilities to print
+	  layout formats.
+	* tests/fast-block.cpp: New file, tests for FastBlock.
+	* tests/plainblock.hpp: New file, implements plain block
+	  similar to Dense but with no direct data access.
+	* tests/vector.cpp: Minor, change type names from _t to _type
+	  suffix.
+	* tests/view.cpp: Include point-fcn.hpp header.
+
+2005-04-17  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* GNUmakefile.in: Let 'make check' run 'qmtest run'.
+	* tests/GNUmakefile.inc.in: Removed.
+	* src/vsip/impl/view_traits.hpp: New file forward-declaring traits
+	used by...
+	* src/vsip/vector.hpp: ...this.
+	* src/vsip/matrix.hpp: ...and this.
+	* src/vsip/impl/expr_unary_operators.hpp: ...and this.
+	* src/vsip/impl/expr_binary_operators.hpp: ...and this.
+	* tests/expression.cpp: Use <vsip/math.hpp>.
+
+2005-04-15  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* GNUmakefile.in: Make evaluation of 'norm_dir' and 'dir_var' lazy.
+	* tests/QMTest/configuration.in: New QMTest-based testing harness.
+	* tests/QMTest/vpp_database.py: Likewise.
+	* tests/QMTest/classes.qmc: Likewise.
+	* tests/context.in: Likewise.
+	* configure.ac: Call 'AC_CANONICAL_TARGET' as required by testing harness.
+	* config.guess: New file.
+	* config.sub: New file.
+	* install.sh: New file.
+
+	* src/vsip/vector.hpp: Add support for complex vectors.
+	* tests/vector.cpp: Test the extended API.
+	* src/vsip/impl/expression.hpp: Removed.
+	* tests/expr-test.cpp: Use math.hpp instead of expression.hpp.
+	* tests/expression.cpp: Likewise.
+
+2005-04-14  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/math.hpp: New file, mathematical functions and
+	  operations [math].
+
+2005-04-08  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* GNUMakefile.in: Fix dependency generation rule.
+	* src/vsip/impl/par-services-mpi.hpp: Fix compiler warning.
+
+2005-04-06  Jules Bergmann  <jules@codesourcery.com>
+
+	* tests/complex.cpp: Make atan() argument type explicit float.
+
+2005-04-05  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/matrix.hpp: Add missing return for several operator= and
+	  operator-'op'= functions.
+	* src/vsip/vector.hpp: Likewise.
+	* src/vsip/impl/point.hpp (next): Comment out unused parameter
+	  name.
+	* tests/block_interface.hpp (block_1d_interface_test): Fake
+	  use of unused variables.
+	* tests/map.cpp (count_subblocks): Change 'count' from int to
+	  avoid warning.
+	* tests/static_assert (test_assert_unsigned): Fake use of
+	  unused variables.
+	* tests/test.hpp (use_variable): New function, creates a variable
+	  use.
+	* tests/view.cpp: Add tests for scalar assignment.  Add test
+	  coverage for some of missing returns on view operator=.
+
+2005-04-04  Jules Bergmann  <jules@codesourcery.com>
+
+	* GNUmakefile.in: Locate .d files in build directory, if different
+	  from source directory.
+
+2005-04-01  Jules Bergmann  <jules@codesourcery.com>
+
+	Distributed blocks.
+	* configure.ac: Keep MPI includes and libs in CPPFLAGS and LIBS.
+	  Renamed USE_MPI to USE_PAR.  Fail if mpi enabled but no
+	  mpi.h found, link against lammpi++ library for LAM, prune
+	  _darcs directory from template file search.
+	* GNUmakefile.in: Rename USE_MPI to USE_PAR.
+	* tests/GNUmakefile.inc.in: Add distributed-block.cpp to list of
+	  parallel tests.  Rename USE_MPI to USE_PAR.
+	* src/vsip/impl/appmap.hpp: New file, applied map = map + domain.
+	* src/vsip/impl/block-traits (DistributedLocalBlock): New traits
+	  class to give the local block type of a distributed block.
+	* src/vsip/impl/distributed-block.hpp: New file, implements
+	  distrubited block.
+	* src/vsip/impl/domain-utils.hpp: New file, utilities for domains,
+	  includes projection, construction, intersection, and size.
+	* src/vsip/impl/par-assign.hpp: New file, algorithms for
+	  parallel assignment.  SimpleParallelAssign{SOL, DOL} are
+	  horribly inefficient.  ChainedParallelAssign is an
+	  improvement, it precomputes communcation patterns,
+	  consolidates messages, and eliminates some (but not all)
+	  unnecessary copies.  Direct data access to is necessary to
+	  completely eliminate unnecessary copies and allocations.
+	* src/vsip/impl/par-services.hpp: New file, includes appropriate
+	  parallel services file (currently -mpi or -none).
+	* src/vsip/impl/par-services-mpi.hpp: New file, abstraction
+	  barrier for MPI parallel services.
+	* src/vsip/impl/par-services-none.hpp: New file, provides empty
+	  parallel services for serial execution.
+	* src/vsip/impl/point.hpp: New file, Index-like class for general
+	  programming.
+	* src/vsip/impl/refcount.hpp: Bug fix for copy constructor.
+	* src/vsip/initfini.cpp: Create and destroy parallel services
+	  (ParServices).
+	* src/vsip/initfini.hpp: Add ParService* member to vsipl object.
+	* src/vsip/map.hpp (split_tuple): New function, split a number into
+	  into dimensional components.
+	  (Map): Make AppMap a friend class, add impl_rank() member function,
+	  store communicator in map, use default communicator to compute
+	  default grid function.
+	* src/vsip/matrix.hpp: Add optional map parameter to constructors.
+	  (ViewOfDim): new class to construct a view of a given dimension.
+	* src/vsip/vector.hpp: Likewise.
+	* src/vsip/par-services.cpp: New file, declare static storage.
+	* tests/appmap.cpp: New file, unit tests for applied maps.
+	* tests/distributed-block.cpp: New file, unit tests for
+	  DistributedBlock and parallel assignment of vectors and matrices.
+	* tests/initfini.cpp (main): Run just one of tests per invocation
+	  (MPI, and hence vsipl++, cannot be re-initialized after
+	  finalization).
+	* tests/map.cpp (main): Initialize library with vsipl object.
+	* tests/output.hpp: New file, utility functions to write
+	  VSIPL++ objects to streams.
+	* tests/mpi.cpp: Remove usage of VSIP_IMPL_PAR_SERVICE.
+
+2005-03-31  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* GNUmakefile: Removed.
+	* src/vsip/GNUmakefile.inc: Removed.
+	* tests/GNUmakefile.inc: Removed.
+
+	* autogen.sh: New file.
+	* configure.ac: New file.
+	* src/vsip/impl/config.hpp: New file.
+	* GNUmakefile.in: New file.
+	* src/vsip/GNUmakefile.inc.in: New file.
+	* tests/GNUmakefile.inc.in: New file.
+	* tests/mpi.cpp: New file.
+
+2005-03-31  Jules Bergmann  <jules@codesourcery.com>
+
+	Fix to correctly assign non-const_views with different value type
+	and/or block type.
+	* src/vsip/matrix.hpp (Matrix): New function,
+	  operator=(Matrix<T0, Block0 const&).
+	* src/vsip/vector.hpp (Vector): New function,
+	  operator=(Vector<T0, Block0 const&).
+	* tests/test-storage.hpp: Add dimension order template parameter
+	  to Storage and ConstStorage classes.
+	* tests/view.cpp: Add test-cases to cover view assignment from
+	  non-const_view with different value and block types.
+
+2005-03-29  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* src/vsip/impl/block-traits.hpp: Add ExprBlockStorage trait.
+	* src/vsip/impl/expr_binary_block.hpp: Add type parameters for
+	type conversions during operation evaluation.
+	* src/vsip/impl/expr_unary_block.hpp: Likewise.
+	* src/vsip/impl/expr_scalar_block.hpp: Specialize ExprBlockStorage.
+	* src/vsip/impl/expr_unary_operators.hpp: New file.
+	* src/vsip/impl/expr_binary_operators.hpp: New file.
+	* src/vsip/impl/expr_operations.hpp: Change template parameter names.
+	* tests/view_operators.cpp: New file.
+	* tests/expr-test.cpp: Adjust to API changes in ExprBlocks.
+	* tests/expression.cpp: Likewise.
+
+2005-03-28  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* src/vsip/vector.hpp: Add missing return statements as well as an
+	explicit cast for constructor that imports from a different block type.
+	* src/vsip/impl/subblock.hpp: Fix error in ComponentBlock
+	constructor.
+
+2005-03-25  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/domain.hpp (Domain<3>::size): Make function 'inline'.
+	  (Domain<3>::operator[]) Likewise.
+
+2005-03-25  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/matrix.hpp: New file, implements matrix views.
+	* src/vsip/vector.hpp: Handle subview block reference count through
+	  RAII.
+	* tests/view.cpp: New file, unit tests for vectors and matrixs
+	  (redundant with unit tests in vector.cpp).
+	* tests/test-storage.hpp: New file, storage classes to generalize
+	  view tests.
+
+2005-03-23  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/refcount.hpp: Add decrement_block_count() function.
+	* src/vsip/vector.hpp: Fix subview member functions.
+	* tests/vector.cpp: Tests for vector subviews.
+
+2005-03-23  Jules Bergmann  <jules@codesourcery.com>
+
+	Implementation of Map, BlockDist, and CyclicDist.
+	* src/vsip/map.hpp: New file, implementation of Map, BlockDist,
+	  and CyclicDist class ([view.mapclass] and [view.distribute.*]).
+	* src/vsip/impl/value-iterator.hpp: New file, value iterator used
+	  for Map's subblock_iterator and processor_iterator.
+	* tests/map.cpp: New file, unit tests for maps and distributions.
+
+
+2005-03-23  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/support.hpp: Change 'row3_t' and 'col3_t' to 'row3_type'
+	  and 'col3_type' respectively.
+
+2005-03-21  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/block-traits.hpp: New file for block traits,
+	  primary class definition for ViewBlockStorage.
+	* src/vsip/impl/expr_binary_block.hpp (BinaryExprBlock):
+	  Make class copyable, add ViewBlockStorage specialization.
+	* src/vsip/impl/expr_unary_block.hpp (UnaryExprBlock): Likewise.
+	* src/vsip/impl/noncopyable.hpp: Add NonAssignable class.
+	* src/vsip/impl/refcount.hpp: Add StoredValue class.
+	* src/vsip/vector.hpp (const_Vector): Use ViewBlockStorage trait
+	  to determine how block should be stored.
+	* tests/expr-test.cpp: New file, additional tests for expression
+	  templates.
+
+2005-03-21  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/dense.hpp (Dense): Change 'order_t' to 'order_type'.
+
+2005-03-18  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/vector.hpp (Vector): Add constructor from const_Vector
+	  with different value and block types.
+	  (Vector::operator=): Add 'const' qualifier to assignment from
+	  const_Vector.  Required when assigning from a temporary.
+	* tests/vector.cpp: Added test cases for assignment from temporary
+	  and construction from temporary.
+
+2005-03-18  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/refcount.hpp (RefCount::increment_count): Made
+	  function inline.
+	  (RefCount::decrement_count): Likewise.
+
+2005-03-18  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/complex.hpp: New file, implementing [complex]
+	  functionality.
+	* tests/complex.hpp: New file, unit tests for [complex].
+	* src/vsip/dense.hpp: Remove include <complex>.
+	* src/vsip/support.hpp: Add comment on location of vsip::complex.
+	* tests/test.hpp (equal): specializations for double and complex<>.
+
+2005-03-17  Jules Bergmann  <jules@codesourcery.com>
+
+	Change typename suffix to "_type" (from "_t")
+	* src/vsip/counter.cpp: Likewise.
+	* src/vsip/dense.hpp: Likewise.
+	* src/vsip/domain.hpp: Likewise.
+	* src/vsip/support.hpp: Likewise.
+	* src/vsip/vector.hpp: Likewise.
+	* src/vsip/impl/counter.hpp: Likewise.
+	* src/vsip/impl/expr_binary_block.hpp: Likewise.
+	* src/vsip/impl/expr_scalar_block.hpp: Likewise.
+	* src/vsip/impl/expr_unary_block.hpp: Likewise.
+	* src/vsip/impl/index.hpp: Likewise.
+	* src/vsip/impl/subblock.hpp: Likewise.
+	* tests/block_interface.hpp: Likewise.
+	* tests/counter.cpp: Likewise.
+	* tests/dense.cpp: Likewise.
+	* tests/domain.cpp: Likewise.
+	* tests/expression.cpp: Likewise.
+	* tests/static_assert.cpp: Likewise.
+	* tests/subblock.cpp: Likewise.
+	* tests/vector.cpp: Likewise.
+
+2005-03-15  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/vector.hpp (const_Vector): Allocate Dense block on
+	  construction, remove constructor from Vector.
+	  (Vector): Forward construction to base class, add put(), operator=()
+	  member functions.
+	  (ViewConversion): Fix template parameters.
+	* tests/vector.cpp: New file, tests for Vector and const_Vector.
+
+2005-03-02  Zack Weinberg  <zack@codesourcery.com>
+
+	* src/vsip/vector.hpp: New file.
+	* src/vsip/impl/refcount.hpp: Add RefCountedPtr class.
+
+2005-03-02  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* src/vsip/impl/noncopyable.hpp: New file.
+	* src/vsip/impl/expr_unary_block.hpp: New file.
+	* src/vsip/impl/expr_operations.hpp: New file.
+	* src/vsip/impl/expr_binary_block.hpp: New file.
+	* src/vsip/impl/expr_scalar_block.hpp: New file.
+	* src/vsip/impl/expression.hpp: New file.
+	* tests/block_interface.hpp: New file.
+	* tests/expression.cpp: New file.
+
+2005-03-01  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* src/vsip/dense.hpp: Provide map() methods.
+	* src/vsip/impl/promote.hpp: Provide Promotion templates.
+
+2005-02-23  Zack Weinberg  <zack@codesourcery.com>
+
+	* src/vsip/impl/subblock.hpp: New file.
+	* tests/subblock.hpp: New file.
+
+	* src/vsip/domain.hpp (Domain<1>): Add impl_nth and impl_last
+	member functions.
+	(Domain<1>::is_valid): Use impl_last.
+
+2005-02-16  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* GNUmakefile: Add targets 'depend' and 'doc'.
+	* doc/Doxyfile: Process subdirectories during documentation.
+
+2005-02-16  Zack Weinberg  <zack@codesourcery.com>
+
+	* GNUmakefile: Do not include .d files if doing a clean.
+	(clean): Also delete .d files.
+	* tests/GNUmakefile.inc (clean): No need to delete $(tests_cxx_objects).
+
+2005-02-11  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/refcount.hpp (RefCount): Start count at 1.
+	* tests/refcount.cpp (deref): New function,
+	(test_simple): Update for new RefCount semantics.
+	(test_chain_1): Likewise.
+	(test_chain_2): Likewise.
+	* tests/dense.cpp (test_stack_dense): Likewise.
+	(test_heap_dense): Likewise.
+
+2005-02-09  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/static_assert.hpp: New file.
+	* tests/static_assert.cpp: Likewise.
+
+2005-02-07  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/dense.hpp (DenseLayout::index): Comment out unused
+	parameter names.
+
+2005-01-29  Zack Weinberg  <zack@codesourcery.com>
+
+	* src/vsip/domain.hpp (Domain<1>::is_valid):
+	Cast index_ and	length_ to stride_t to ensure signed arithmetic.
+	Improve grammar	in comment.
+	(Domain<1>::operator=): Add return statement.
+
+2005-01-28  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* src/vsip/dense.hpp: Fix typo.
+
+2005-01-28  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/dense.hpp, src/vsip/impl/refcount.hpp,
+	tests/dense.cpp, tests/refcount.cpp, tests/test.hpp: New files.
+	* src/vsip/support.hpp (impl::RowMajor): New class.
+	(impl::ColMajor) Likewise.
+	(SerialMap) New placeholder class.
+	(impl::unimplemented) New exception class.
+	* src/vsip/domain.hpp (Domain<1>::operator[]) fix precondition.
+
+
+2005-01-27  Zack Weinberg  <zack@codesourcery.com>
+
+	* src/vsip/support.cpp, src/vsip/counter.cpp: New files.
+	* src/vsip/support.hpp (VSIP_IMPL_NORETURN): New macro.
+	(VSIP_IMPL_THROW): Likewise.
+	(VSIP_HAS_EXCEPTIONS): Define to 1 only if not already defined.
+	(vsip::impl::fatal_exception): Declare.
+	* src/vsip/counter.cpp: No need to include <stdexcept> nor <cstdlib>.
+	(CheckedCounter): Add overflow and underflow static member functions.
+	(CheckedCounter::operator+=, CheckedCounter::operator-=): Use them.
+	(operator==, operator!=, operator<, operator>, operator<=)
+	(operator>=): Mark with VSIP_NOTHROW.
+
+2005-01-26  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* tests/domain.cpp: Fix typo.
+
+2005-01-24  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* src/vsip/domain.hpp: New, Domain class template.
+	* tests/domain.cpp: New, Domain API tests.
+
+2005-01-24  Zack Weinberg  <zack@codesourcery.com>
+
+	* GNUmakefile: Mention LDFLAGS.
+	* tests/GNUmakefile.inc: Honor LDFLAGS when linking executables.
+
+2005-01-23  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/support.hpp: Include cassert, fix typo.
+	* tests/support.cpp: Use include cassert instead of assert.h.
+
+2005-01-22  Stefan Seefeld  <stefan@marvin>
+
+	* src/vsip/impl/index.hpp: remove redundant and buggy code
+
+2005-01-22  Zack Weinberg  <zack@codesourcery.com>
+
+	* src/vsip/impl/counter.hpp: Change ValT to value_t throughout.
+	Add non-member operator+ and operator- with value_t left argument.
+	Tidy comment about lack of conversion to bool.
+	* tests/counter.cpp: Include <cassert>.  Add tests of nondestructive
+	arithmetic with an integer literal on the left of the operator.
+	Remove commented-out tests for conversion to bool.  Change
+	one use of CheckedCounter::ValT to value_t.
+
+	* src/vsip/initfini.hpp: Include vsip/impl/counter.hpp.
+	(vsipl::use_count): Make a CheckedCounter.
+	* src/vsip/initfini.cpp: Update to match.
+
+	* tests/.cvsignore: New file, ignore *.d.
+	* tests/GNUmakefile.inc: Add $(tests_cxx_sources) to
+	$(cxx_sources) so they get dependencies calculated.
+
+2005-01-22  Zack Weinberg  <zack@codesourcery.com>
+
+	* src/vsip/impl/counter.hpp: New, checked-counter class.
+	* tests/support.cpp: New, tests for checked counters.
+
+2005-01-21  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* src/vsip/impl/index.hpp: New Index API.
+	* src/tests/index.cpp: New tests for Index API.
+
+2005-01-21  Zack Weinberg  <zack@codesourcery.com>
+
+	* doc/.cvsignore, src/.cvsignore, src/vsip/.cvsignore
+	* src/vsip/impl/.cvsignore: New files.
+
+2005-01-20  Mark Mitchell  <mark@codesourcery.com>
+
+	* src/vsip/GNUmakefile.inc (src_vsip_CXXFLAGS): Define.
+	(src_vsip_CXXINCLUDES): Likewise.
+
+2005-01-20  Zack Weinberg  <zack@codesourcery.com>
+
+	* src/vsip/initfini.hpp, src/vsip/initfini.cpp
+	* tests/initfini.cpp: New files.
+
+2005-01-20  Mark Mitchell  <mark@codesourcery.com>
+
+	* GNUmakefile (AR): New variable.
+	(subdirs): Add src/vsip.
+	(srcdir): New variable.
+	(objects): New variable.
+	(all): Mark it PHONY.
+	(check): New target.
+	(clean): New target.
+	* src/vsip/GNUmakefile.inc: New file.
+	* tests/GNUmakefile.inc: Likewise.
+
+	* GNUmakefile (CXXCPPFLAGS): New variable.
+	(CXXFLAGS): Use it.
+
+2005-01-20  Zack Weinberg  <zack@codesourcery.com>
+
+	* doc/Doxyfile: New file.
+
+2005-01-20  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/support.hpp: New file.
+	* tests/support.cpp: New file.
+
+2005-01-20  Mark Mitchell  <mark@codesourcery.com>
+
+	* GNUmakefile: New file.
+
+2005-01-19  Jules Bergmann  <jules@codesourcery.com>
+
+	* Created repository.
 2006-01-10 Jules Bergmann  <jules@codesourcery.com>
 
 	* GNUmakefile.in: Include lib/GNUmakefile.inc
Index: configure.ac
===================================================================
RCS file: /home/cvs/Repository/vpp/configure.ac,v
retrieving revision 1.71
diff -u -r1.71 configure.ac
--- configure.ac	11 Jan 2006 14:05:22 -0000	1.71
+++ configure.ac	11 Jan 2006 15:58:52 -0000
@@ -1053,10 +1053,12 @@
     lapack_packages="mkl7 mkl5"
   elif test "$with_lapack" == "yes"; then
     if test "$enable_builtin_lapack" == "yes"; then
-      lapack_packages="atlas generic builtin"
+      lapack_packages="atlas generic1 generic2 builtin"
     else
-      lapack_packages="atlas generic"
+      lapack_packages="atlas generic1 generic2"
     fi
+  elif test "$with_lapack" == "generic"; then
+    lapack_packages="generic1 generic2"
   else
     lapack_packages="$with_lapack"
   fi
@@ -1113,11 +1115,16 @@
       fi
 
       lapack_use_ilaenv=0
-    elif test "$trypkg" == "generic"; then
-      AC_MSG_CHECKING([for LAPACK/Generic library])
+    elif test "$trypkg" == "generic1"; then
+      AC_MSG_CHECKING([for LAPACK/Generic library (w/o blas)])
       LIBS="$keep_LIBS -llapack"
       cblas_style="0"	# no cblas.h
       lapack_use_ilaenv=0
+    elif test "$trypkg" == "generic2"; then
+      AC_MSG_CHECKING([for LAPACK/Generic library (w/blas)])
+      LIBS="$keep_LIBS -llapack -lblas"
+      cblas_style="0"	# no cblas.h
+      lapack_use_ilaenv=0
     elif test "$trypkg" == "builtin"; then
       AC_MSG_CHECKING([for built-in ATLAS library])
       if test -e "$srcdir/vendor/atlas/configure"; then
@@ -1189,10 +1196,17 @@
     AC_LINK_IFELSE(
       [AC_LANG_PROGRAM(
 	[[ extern "C" { void sgeqrf_(int*, int*, float*, int*, float*,
-	                             float*, int*, int*); };]],
-	[[int    m, n, lda, lwork, info;
-	  float *a, *tau, *work;
-	  sgeqrf_(&m, &n, a, &lda, tau, work, &lwork, &info);]]
+	                             float*, int*, int*);
+                        void strsm_ (char*, char*, char*, char*,
+				     int*, int*, float*, float*, int*,
+				     float*, int*); };]],
+	[[int    m, n, lda, ldb, lwork, info;
+	  float *a, *b, *tau, *work, alpha;
+	  sgeqrf_(&m, &n, a, &lda, tau, work, &lwork, &info);
+	  char  side, uplo, transa, diag;
+	  strsm_(&side, &uplo, &transa, &diag,
+	         &m, &n, &alpha, a, &lda, b, &ldb);
+        ]]
         )],
       [lapack_found=$trypkg
        AC_MSG_RESULT([found])
Index: src/vsip/map.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/map.hpp,v
retrieving revision 1.20
diff -u -r1.20 map.hpp
--- src/vsip/map.hpp	5 Dec 2005 19:19:18 -0000	1.20
+++ src/vsip/map.hpp	11 Jan 2006 15:58:53 -0000
@@ -202,6 +202,10 @@
   index_type impl_local_from_global_index(dimension_type d, index_type idx)
     const VSIP_NOTHROW;
 
+  template <dimension_type Dim>
+  index_type impl_subblock_from_global_index(Index<Dim> const& idx)
+    const VSIP_NOTHROW;
+
   index_type global_from_local_index(dimension_type d, index_type sb,
 				     index_type idx)
     const VSIP_NOTHROW;
@@ -597,6 +601,42 @@
 
 
 
+/// Determine subblock holding a global index.
+
+template <typename       Dist0,
+	  typename       Dist1,
+	  typename       Dist2>
+template <dimension_type Dim>
+inline index_type
+Map<Dist0, Dist1, Dist2>::impl_subblock_from_global_index(
+  Index<Dim> const& idx
+  )
+  const VSIP_NOTHROW
+{
+  index_type sb = 0;
+  assert(dim_ != 0 && dim_ == Dim);
+
+  for (dimension_type d=0; d<Dim; ++d)
+  {
+    assert(idx[d] < dom_[d].size());
+    if (d != 0)
+      sb *= subblocks_[d];
+    sb += impl_subblock_from_index(d, idx[d]);
+  }
+
+  assert(sb < num_subblocks_);
+  index_type dim_sb[VSIP_MAX_DIMENSION];
+  impl::split_tuple(sb, dim_, subblocks_, dim_sb);
+  for (dimension_type d=0; d<Dim; ++d)
+  {
+    assert(dim_sb[d] == impl_subblock_from_index(d, idx[d]));
+  }
+
+  return sb;
+}
+
+
+
 /// Determine global index from local index for a single dimension
 
 /// Requires:
Index: src/vsip/map_fwd.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/map_fwd.hpp,v
retrieving revision 1.5
diff -u -r1.5 map_fwd.hpp
--- src/vsip/map_fwd.hpp	28 Aug 2005 00:22:39 -0000	1.5
+++ src/vsip/map_fwd.hpp	11 Jan 2006 15:58:53 -0000
@@ -27,6 +27,12 @@
 	  typename Dim2 = Block_dist>
 class Map;
 
+template <dimension_type Dim>
+class Global_map;
+
+template <dimension_type Dim>
+class Local_or_global_map;
+
 namespace impl
 {
 
Index: src/vsip/math.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/math.hpp,v
retrieving revision 1.13
diff -u -r1.13 math.hpp
--- src/vsip/math.hpp	26 Sep 2005 20:23:28 -0000	1.13
+++ src/vsip/math.hpp	11 Jan 2006 15:58:53 -0000
@@ -32,6 +32,7 @@
 #include <vsip/impl/matvec.hpp>
 #include <vsip/impl/matvec-prod.hpp>
 #include <vsip/impl/vmmul.hpp>
+#include <vsip/impl/global_map.hpp>
 
 
 
Index: src/vsip/matrix.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/matrix.hpp,v
retrieving revision 1.29
diff -u -r1.29 matrix.hpp
--- src/vsip/matrix.hpp	5 Dec 2005 15:16:16 -0000	1.29
+++ src/vsip/matrix.hpp	11 Jan 2006 15:58:53 -0000
@@ -370,6 +370,13 @@
   static bool const value = true;
 };
 
+template <typename T, typename Block> 
+struct Is_const_view_type<const_Matrix<T, Block> >
+{
+  typedef const_Matrix<T, Block> type; 
+  static bool const value = true;
+};
+
 template <typename T, typename Block>
 T
 get(const_Matrix<T, Block> view, Index<2> const &i)
Index: src/vsip/par-services.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/par-services.cpp,v
retrieving revision 1.4
diff -u -r1.4 par-services.cpp
--- src/vsip/par-services.cpp	5 Dec 2005 19:19:18 -0000	1.4
+++ src/vsip/par-services.cpp	11 Jan 2006 15:58:53 -0000
@@ -48,15 +48,19 @@
 const_Vector<processor_type>
 processor_set()
 {
-  impl::Communicator::pvec_type pvec;
+  static Dense<1, processor_type>* pset_block_ = NULL;
 
-  pvec = impl::default_communicator().pvec(); 
+  if (pset_block_ == NULL)
+  {
+    impl::Communicator::pvec_type pvec;
+    pvec = impl::default_communicator().pvec(); 
+
+    pset_block_ = new Dense<1, processor_type>(Domain<1>(pvec.size()));
+    for (index_type i=0; i<pvec.size(); ++i)
+      pset_block_->put(i, pvec[i]);
+  }
 
-  Vector<processor_type> pset(pvec.size());
-  for (index_type i=0; i<pvec.size(); ++i)
-    pset.put(i, pvec[i]);
-
-  return pset;
+  return Vector<processor_type>(*pset_block_);
 }
 
 
Index: src/vsip/parallel.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/parallel.hpp,v
retrieving revision 1.3
diff -u -r1.3 parallel.hpp
--- src/vsip/parallel.hpp	6 Dec 2005 02:19:46 -0000	1.3
+++ src/vsip/parallel.hpp	11 Jan 2006 15:58:53 -0000
@@ -15,7 +15,9 @@
 ***********************************************************************/
 
 #include <vsip/vector.hpp>
+#include <vsip/map.hpp>
 #include <vsip/impl/setup-assign.hpp>
+#include <vsip/impl/working-view.hpp>
 #include <vsip/impl/par-util.hpp>
 
 
@@ -27,7 +29,6 @@
 namespace vsip
 {
 
-Vector<processor_type> processor_set();
 
 } // namespace vsip
 
Index: src/vsip/random.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/random.hpp,v
retrieving revision 1.2
diff -u -r1.2 random.hpp
--- src/vsip/random.hpp	15 Sep 2005 11:50:36 -0000	1.2
+++ src/vsip/random.hpp	11 Jan 2006 15:58:53 -0000
@@ -20,6 +20,7 @@
 #include <vsip/support.hpp>
 #include <vsip/vector.hpp>
 #include <vsip/matrix.hpp>
+#include <vsip/impl/global_map.hpp>
 
 
 
@@ -355,7 +356,8 @@
 
 public:
   // View types [random.rand.view types]
-  typedef const_Vector<T> vector_type;
+  typedef Dense<1, T, row1_type, Local_or_global_map<1> > block1_type;
+  typedef const_Vector<T, block1_type> vector_type;
   typedef const_Matrix<T> matrix_type;
   
   // Constructors, copy, assignment, and destructor 
@@ -388,7 +390,7 @@
 
   vector_type randu(length_type len) VSIP_NOTHROW
     {
-      Vector<T> v(len);
+      Vector<T, block1_type> v(len);
       for ( index_type i = 0; i < len; ++i )
         v.put( i, randu() );
       return v;
@@ -405,7 +407,7 @@
 
   vector_type randn(length_type len) VSIP_NOTHROW
     {
-      Vector<T> v(len);
+      Vector<T, block1_type> v(len);
       for ( index_type i = 0; i < len; ++i )
         v.put( i, randn() );
       return v;
Index: src/vsip/tensor.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/tensor.hpp,v
retrieving revision 1.22
diff -u -r1.22 tensor.hpp
--- src/vsip/tensor.hpp	5 Dec 2005 15:16:17 -0000	1.22
+++ src/vsip/tensor.hpp	11 Jan 2006 15:58:53 -0000
@@ -602,6 +602,13 @@
 };
 
 template <typename T, typename Block>
+struct Is_const_view_type<const_Tensor<T, Block> >
+{
+  typedef const_Tensor<T, Block> type; 
+  static bool const value = true;
+};
+
+template <typename T, typename Block>
 T
 get(const_Tensor<T, Block> view, Index<3> const &i)
 {
Index: src/vsip/vector.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/vector.hpp,v
retrieving revision 1.35
diff -u -r1.35 vector.hpp
--- src/vsip/vector.hpp	11 Nov 2005 13:57:04 -0000	1.35
+++ src/vsip/vector.hpp	11 Jan 2006 15:58:53 -0000
@@ -319,6 +319,13 @@
   static bool const value = true;
 };
 
+template <typename T, typename Block> 
+struct Is_const_view_type<const_Vector<T, Block> >
+{
+  typedef const_Vector<T, Block> type;
+  static bool const value = true;
+};
+
 template <typename T, typename Block>
 T
 get(const_Vector<T, Block> view, Index<1> const &i)
Index: src/vsip/impl/block-traits.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/block-traits.hpp,v
retrieving revision 1.15
diff -u -r1.15 block-traits.hpp
--- src/vsip/impl/block-traits.hpp	2 Nov 2005 18:44:03 -0000	1.15
+++ src/vsip/impl/block-traits.hpp	11 Jan 2006 15:58:53 -0000
@@ -233,10 +233,26 @@
 
 
 
+/// Implementation tags for Par_expr_block:
+
+struct Peb_reorg_tag;	// Reorganize block
+struct Peb_reuse_tag;	// Reuse block directly
+struct Peb_remap_tag;	// Reuse block, but with different mapping
+
+
+/// Traits class to choose the appropriate Par_expr_block impl tag for
+/// a block type. By default, blocks should be reorganized.
+
+template <typename BlockT>
+struct Choose_peb { typedef Peb_reorg_tag type; };
+
+
+
 // Forward Declaration
 template <dimension_type Dim,
 	  typename       MapT,
-	  typename       BlockT>
+	  typename       BlockT,
+	  typename       ImplTag = typename Choose_peb<BlockT>::type>
 class Par_expr_block;
 
 
Index: src/vsip/impl/dispatch-assign.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/dispatch-assign.hpp,v
retrieving revision 1.13
diff -u -r1.13 dispatch-assign.hpp
--- src/vsip/impl/dispatch-assign.hpp	22 Dec 2005 01:29:25 -0000	1.13
+++ src/vsip/impl/dispatch-assign.hpp	11 Jan 2006 15:58:53 -0000
@@ -41,6 +41,10 @@
 struct Is_local_map<Local_map>
 { static bool const value = true; };
 
+template <dimension_type Dim>
+struct Is_local_map<Local_or_global_map<Dim> >
+{ static bool const value = true; };
+
 template <typename Map>
 struct Is_global_map
 { static bool const value = false; };
@@ -49,6 +53,16 @@
 struct Is_global_map<Global_map<Dim> >
 { static bool const value = true; };
 
+template <dimension_type Dim>
+struct Is_global_map<Local_or_global_map<Dim> >
+{ static bool const value = true; };
+
+template <typename Dist0,
+	  typename Dist1,
+	  typename Dist2>
+struct Is_global_map<Map<Dist0, Dist1, Dist2> >
+{ static bool const value = true; };
+
 
 
 // Tags used by Dispatch_assign to select assignment implementation.
@@ -82,8 +96,9 @@
   typedef typename Block2::map_type map2_type;
 
   // Cannot mix local and distributed data in expressions.
-  static bool const is_illegal    = Is_local_map<map1_type>::value !=
-                                    Is_local_map<map2_type>::value;
+  static bool const is_illegal    =
+    !((Is_local_map<map1_type>::value && Is_local_map<map2_type>::value) ||
+      (Is_global_map<map1_type>::value && Is_global_map<map2_type>::value));
 
   static bool const is_local      = Is_local_map<map1_type>::value &&
                                     Is_local_map<map2_type>::value;
Index: src/vsip/impl/distributed-block.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/distributed-block.hpp,v
retrieving revision 1.16
diff -u -r1.16 distributed-block.hpp
--- src/vsip/impl/distributed-block.hpp	5 Dec 2005 19:19:18 -0000	1.16
+++ src/vsip/impl/distributed-block.hpp	11 Jan 2006 15:58:53 -0000
@@ -42,6 +42,11 @@
   typedef typename Block::reference_type       reference_type;
   typedef typename Block::const_reference_type const_reference_type;
 
+  typedef typename Block_layout<Block>::complex_type impl_complex_type;
+  typedef Storage<impl_complex_type, value_type>     impl_storage_type;
+  typedef typename impl_storage_type::type           impl_data_type;
+  typedef typename impl_storage_type::const_type     impl_const_data_type;
+
   typedef Map                                  map_type;
 
   // Non-standard typedefs:
@@ -123,14 +128,120 @@
 public:
   // get() on a distributed_block is a broadcast.  The processor
   // owning the index broadcasts the value to the other processors in
-  // the map.
-  value_type get(index_type /*idx*/) const VSIP_NOTHROW
-  { VSIP_IMPL_THROW(impl::unimplemented("Distributed_block::get()")); }
+  // the data parallel group.
+  value_type get(index_type idx) const VSIP_NOTHROW
+  {
+    index_type     sb = map_.impl_subblock_from_global_index(Index<1>(idx));
+    processor_type pr = *(map_.processor_begin(sb));
+    value_type     val;
+
+    if (pr == proc_)
+    {
+      assert(map_.subblock() == sb);
+      index_type lidx = map_.impl_local_from_global_index(0, idx);
+      val = subblock_->get(lidx);
+    }
+
+    map_.impl_comm().broadcast(pr, &val, 1);
+
+    return val;
+  }
+
+  value_type get(index_type idx0, index_type idx1) const VSIP_NOTHROW
+  {
+    index_type     sb = map_.impl_subblock_from_global_index(
+				Index<2>(idx0, idx1));
+    processor_type pr = *(map_.processor_begin(sb));
+    value_type     val;
+
+    if (pr == proc_)
+    {
+      assert(map_.subblock() == sb);
+      index_type l_idx0 = map_.impl_local_from_global_index(0, idx0);
+      index_type l_idx1 = map_.impl_local_from_global_index(1, idx1);
+      val = subblock_->get(l_idx0, l_idx1);
+    }
+
+    map_.impl_comm().broadcast(pr, &val, 1);
+
+    return val;
+  }
+
+  value_type get(index_type idx0, index_type idx1, index_type idx2)
+    const VSIP_NOTHROW
+  {
+    index_type     sb = map_.impl_subblock_from_global_index(
+				Index<3>(idx0, idx1, idx2));
+    processor_type pr = *(map_.processor_begin(sb));
+    value_type     val;
+
+    if (pr == proc_)
+    {
+      assert(map_.subblock() == sb);
+      index_type l_idx0 = map_.impl_local_from_global_index(0, idx0);
+      index_type l_idx1 = map_.impl_local_from_global_index(1, idx1);
+      index_type l_idx2 = map_.impl_local_from_global_index(2, idx2);
+      val = subblock_->get(l_idx0, l_idx1, l_idx2);
+    }
+
+    map_.impl_comm().broadcast(pr, &val, 1);
+
+    return val;
+  }
+
 
   // put() on a distributed_block is executed only on the processor
   // owning the index.
-  void put(index_type /*idx*/, value_type /*val*/) VSIP_NOTHROW
-  { VSIP_IMPL_THROW(impl::unimplemented("Distributed_block::put()")); }
+  void put(index_type idx, value_type val) VSIP_NOTHROW
+  {
+    index_type     sb = map_.impl_subblock_from_global_index(Index<1>(idx));
+
+    if (map_.subblock() == sb)
+    {
+      index_type lidx = map_.impl_local_from_global_index(0, idx);
+      subblock_->put(lidx, val);
+    }
+  }
+
+  void put(index_type idx0, index_type idx1, value_type val) VSIP_NOTHROW
+  {
+    index_type sb = map_.impl_subblock_from_global_index(Index<2>(idx0, idx1));
+
+    if (map_.subblock() == sb)
+    {
+      index_type l_idx0 = map_.impl_local_from_global_index(0, idx0);
+      index_type l_idx1 = map_.impl_local_from_global_index(1, idx1);
+      subblock_->put(l_idx0, l_idx1, val);
+    }
+  }
+
+  void put(index_type idx0, index_type idx1, index_type idx2, value_type val)
+    VSIP_NOTHROW
+  {
+    index_type     sb = map_.impl_subblock_from_global_index(
+				Index<3>(idx0, idx1, idx2));
+
+    if (map_.subblock() == sb)
+    {
+      index_type l_idx0 = map_.impl_local_from_global_index(0, idx0);
+      index_type l_idx1 = map_.impl_local_from_global_index(1, idx1);
+      index_type l_idx2 = map_.impl_local_from_global_index(2, idx2);
+      subblock_->put(l_idx0, l_idx1, l_idx2, val);
+    }
+  }
+
+
+  // Support Direct_data interface.
+public:
+  impl_data_type       impl_data()       VSIP_NOTHROW
+  { return subblock_->impl_data(); }
+
+  impl_const_data_type impl_data() const VSIP_NOTHROW
+  { return subblock_->impl_data(); }
+
+  stride_type impl_stride(dimension_type D, dimension_type d)
+    const VSIP_NOTHROW
+  { return subblock_->impl_stride(D, d); }
 
 
   // Accessors.
Index: src/vsip/impl/eval-blas.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/eval-blas.hpp,v
retrieving revision 1.5
diff -u -r1.5 eval-blas.hpp
--- src/vsip/impl/eval-blas.hpp	5 Dec 2005 19:46:40 -0000	1.5
+++ src/vsip/impl/eval-blas.hpp	11 Jan 2006 15:58:53 -0000
@@ -37,7 +37,8 @@
 	  typename Block0,
 	  typename Block1,
 	  typename Block2>
-struct Evaluator<Op_prod_vv_outer, Block0, Op_list_3<T1, Block1, Block2>,
+struct Evaluator<Op_prod_vv_outer, Block0,
+		 Op_list_3<T1, Block1 const&, Block2 const&>,
 		 Blas_tag>
 {
   static bool const ct_valid = 
@@ -103,7 +104,7 @@
 	  typename Block1,
 	  typename Block2>
 struct Evaluator<Op_prod_vv_outer, Block0, 
-                 Op_list_3<std::complex<T1>, Block1, Block2>,
+                 Op_list_3<std::complex<T1>, Block1 const&, Block2 const&>,
 		 Blas_tag>
 {
   static bool const ct_valid = 
Index: src/vsip/impl/expr_scalar_block.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/expr_scalar_block.hpp,v
retrieving revision 1.10
diff -u -r1.10 expr_scalar_block.hpp
--- src/vsip/impl/expr_scalar_block.hpp	16 Sep 2005 18:21:45 -0000	1.10
+++ src/vsip/impl/expr_scalar_block.hpp	11 Jan 2006 15:58:53 -0000
@@ -3,7 +3,7 @@
 /** @file    vsip/impl/expr_scalar_block.hpp
     @author  Stefan Seefeld
     @date    2005-01-20
-    @brief   VSIPL++ Library: Binary scalar block class template.
+    @brief   VSIPL++ Library: Scalar block class template.
 
     This file defines the Scalar_block class templates.
 */
@@ -16,9 +16,10 @@
 ***********************************************************************/
 
 #include <vsip/support.hpp>
+#include <vsip/impl/block-traits.hpp>
 #include <vsip/impl/noncopyable.hpp>
 #include <vsip/impl/length.hpp>
-#include <vsip/impl/local_map.hpp>
+#include <vsip/map_fwd.hpp>
 
 namespace vsip
 {
@@ -42,7 +43,7 @@
   typedef Scalar value_type;
   typedef value_type& reference_type;
   typedef value_type const& const_reference_type;
-  typedef Local_map map_type;
+  typedef Local_or_global_map<D> map_type;
 
   static dimension_type const dim = D;
 
@@ -103,6 +104,128 @@
   length_type const size1_;
 };
 
+
+
+/// Specialize Is_expr_block for scalar expr blocks.
+template <dimension_type D,
+	  typename       Scalar>
+struct Is_expr_block<Scalar_block<D, Scalar> >
+{ static bool const value = true; };
+
+
+
+// NOTE: Distributed_local_block needs to be defined for const
+// Scalar_block, not regular Scalar_block.
+
+template <dimension_type D,
+	  typename       Scalar>
+struct Distributed_local_block<Scalar_block<D, Scalar> const>
+{
+  typedef Scalar_block<D, Scalar> const type;
+};
+
+
+
+template <dimension_type D,
+	  typename       Scalar>
+Scalar_block<D, Scalar>
+get_local_block(
+  Scalar_block<D, Scalar> const& block)
+{
+  return block;
+}
+
+
+
+template <typename       CombineT,
+	  dimension_type D,
+	  typename       Scalar>
+struct Combine_return_type<CombineT, Scalar_block<D, Scalar> const>
+{
+  typedef Scalar_block<D, Scalar> block_type;
+  typedef typename CombineT::template return_type<block_type>::type
+		type;
+  typedef typename CombineT::template tree_type<block_type>::type
+		tree_type;
+};
+
+
+
+template <typename       CombineT,
+	  dimension_type D,
+	  typename       Scalar>
+struct Combine_return_type<CombineT, Scalar_block<D, Scalar> >
+  : Combine_return_type<CombineT, Scalar_block<D, Scalar> const>
+{};
+
+
+
+template <typename       CombineT,
+	  dimension_type D,
+	  typename       Scalar>
+typename Combine_return_type<CombineT,
+			     Scalar_block<D, Scalar> const>::type
+apply_combine(
+  CombineT const&                combine,
+  Scalar_block<D, Scalar> const& block)
+{
+  return combine.apply(block);
+}
+
+
+
+template <typename       VisitorT,
+	  dimension_type D,
+	  typename       Scalar>
+void
+apply_leaf(
+  VisitorT const&                visitor,
+  Scalar_block<D, Scalar> const& block)
+{
+  visitor.apply(block);
+}
+
+
+
+template <typename       MapT,
+	  dimension_type D,
+	  typename       Scalar>
+struct Is_par_same_map<MapT,
+		       const Scalar_block<D, Scalar> >
+{
+  typedef Scalar_block<D, Scalar> const block_type;
+
+  static bool value(MapT const&, block_type&)
+  {
+    return true;
+  }
+};
+
+
+// Default Is_par_reorg_ok is OK.
+
+
+
+/// Assert that subblock is local to block (overload).
+
+template <dimension_type D,
+	  typename       Scalar>
+void
+assert_local(
+  Scalar_block<D, Scalar> const& block,
+  index_type                     sb)
+{
+  // Scalar_block is always valid locally.
+}
+
+
+
+template <dimension_type D, typename ScalarT>
+struct Choose_peb<Scalar_block<D, ScalarT> >
+{ typedef Peb_reuse_tag type; };
+
+
+
 /***********************************************************************
   Definitions
 ***********************************************************************/
Index: src/vsip/impl/general_dispatch.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/general_dispatch.hpp,v
retrieving revision 1.3
diff -u -r1.3 general_dispatch.hpp
--- src/vsip/impl/general_dispatch.hpp	11 Nov 2005 19:18:52 -0000	1.3
+++ src/vsip/impl/general_dispatch.hpp	11 Jan 2006 15:58:53 -0000
@@ -49,6 +49,7 @@
 struct Blas_tag;		// BLAS implementation (ATLAS, MKL, etc)
 struct Intel_ipp_tag;		// Intel IPP library.
 struct Generic_tag;		// Generic implementation.
+struct Parallel_tag;		// Parallel implementation.
 struct Mercury_sal_tag;		// Mercury SAL library.
 
 
@@ -63,8 +64,7 @@
 
 template <typename Block1>                  struct Op_list_1 {};
 template <typename Block1, typename Block2> struct Op_list_2 {};
-template <typename T0, typename Block1, 
-          typename Block2>                  struct Op_list_3 {};
+template <typename T0, typename T1, typename T2> struct Op_list_3 {};
 template <typename T0, typename Block1, 
           typename Block2, typename T3>     struct Op_list_4 {};
 
@@ -235,8 +235,9 @@
 };
 
 
+
 /***********************************************************************
-  General_dispatch - 2-op block return specialization, one parameter
+  General_dispatch - 3-op block return specialization, one parameter
 ***********************************************************************/
 
 /// In case the compile-time check passes, we decide at run-time whether
@@ -244,22 +245,22 @@
 template <typename OpTag,
 	  typename DstBlock,
           typename T0,
-	  typename Block1,
-	  typename Block2,
+	  typename T1,
+	  typename T2,
 	  typename TagList,
 	  typename Tag,
 	  typename Rest,
 	  typename EvalExpr>
-struct General_dispatch<OpTag, DstBlock, Op_list_3<T0, Block1, Block2>,
+struct General_dispatch<OpTag, DstBlock, Op_list_3<T0, T1, T2>,
                        TagList, Tag, Rest, EvalExpr, true>
 {
-  static void exec(DstBlock& res, T0 param1, Block1 const& op1, Block2 const& op2)
+  static void exec(DstBlock& res, T0 op0, T1 op1, T2 op2)
   {
-    if (EvalExpr::rt_valid(res, param1, op1, op2))
-      EvalExpr::exec(res, param1, op1, op2);
+    if (EvalExpr::rt_valid(res, op0, op1, op2))
+      EvalExpr::exec(res, op0, op1, op2);
     else
-      General_dispatch<OpTag, DstBlock, Op_list_3<T0, Block1, Block2>, Rest>
-		::exec(res, param1, op1, op2);
+      General_dispatch<OpTag, DstBlock, Op_list_3<T0, T1, T2>, Rest>
+		::exec(res, op0, op1, op2);
   }
 };
 
@@ -271,18 +272,18 @@
 template <typename OpTag,
 	  typename DstBlock,
           typename T0,
-	  typename Block1,
-	  typename Block2,
+	  typename T1,
+	  typename T2,
 	  typename TagList,
 	  typename Tag,
 	  typename EvalExpr>
-struct General_dispatch<OpTag, DstBlock, Op_list_3<T0, Block1, Block2>,
+struct General_dispatch<OpTag, DstBlock, Op_list_3<T0, T1, T2>,
 			TagList, Tag, None_type, EvalExpr, true>
 {
-  static void exec(DstBlock& res, T0 param1, Block1 const& op1, Block2 const& op2)
+  static void exec(DstBlock& res, T0 op0, T1 op1, T2 op2)
   {
-    if (EvalExpr::rt_valid(res, param1, op1, op2))
-      EvalExpr::exec(res, param1, op1, op2);
+    if (EvalExpr::rt_valid(res, op0, op1, op2))
+      EvalExpr::exec(res, op0, op1, op2);
     else
       assert(0);
   }
Index: src/vsip/impl/global_map.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/global_map.hpp,v
retrieving revision 1.8
diff -u -r1.8 global_map.hpp
--- src/vsip/impl/global_map.hpp	5 Dec 2005 19:19:18 -0000	1.8
+++ src/vsip/impl/global_map.hpp	11 Jan 2006 15:58:53 -0000
@@ -14,9 +14,11 @@
   Included Files
 ***********************************************************************/
 
-#include <vsip/impl/value-iterator.hpp>
+#include <vsip/impl/vector-iterator.hpp>
 #include <vsip/impl/par-services.hpp>
 #include <vsip/impl/map-traits.hpp>
+#include <vsip/impl/par-util.hpp>
+#include <vsip/map_fwd.hpp>
 
 
 
@@ -32,7 +34,7 @@
 {
   // Compile-time typedefs.
 public:
-  typedef impl::Value_iterator<processor_type, unsigned> processor_iterator;
+  typedef impl::Vector_iterator<Vector<processor_type> > processor_iterator;
   typedef impl::Communicator::pvec_type pvec_type;
 
   // Constructor.
@@ -48,10 +50,20 @@
   index_type subblock() const VSIP_NOTHROW
     { return 0; }
 
-  processor_iterator processor_begin(index_type /*sb*/) const VSIP_NOTHROW
-    { VSIP_IMPL_THROW(impl::unimplemented("Global_map::processor_begin()")); }
-  processor_iterator processor_end  (index_type /*sb*/) const VSIP_NOTHROW
-    { VSIP_IMPL_THROW(impl::unimplemented("Global_map::processor_end()")); }
+  processor_iterator processor_begin(index_type sb) const VSIP_NOTHROW
+  {
+    assert(sb == 0);
+    return processor_iterator(vsip::processor_set(), 0);
+  }
+
+  processor_iterator processor_end  (index_type sb) const VSIP_NOTHROW
+  {
+    assert(sb == 0);
+    return processor_iterator(vsip::processor_set(), vsip::num_processors());
+  }
+
+  const_Vector<processor_type> processor_set() const
+    { return vsip::processor_set(); }
 
   // Applied map functions.
 public:
@@ -75,6 +87,15 @@
     const VSIP_NOTHROW
     { assert(sb == 0 && patch == 0); return dom_; }
 
+  index_type impl_local_from_global_index(dimension_type /*d*/, index_type idx)
+    const VSIP_NOTHROW
+  { return idx; }
+
+  template <dimension_type Dim2>
+  index_type impl_subblock_from_global_index(Index<Dim2> const& /*idx*/)
+    const VSIP_NOTHROW
+  { return 0; }
+
   // Extensions.
 public:
   impl::Communicator impl_comm() const { return impl::default_communicator(); }
Index: src/vsip/impl/matvec.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/matvec.hpp,v
retrieving revision 1.9
diff -u -r1.9 matvec.hpp
--- src/vsip/impl/matvec.hpp	5 Dec 2005 15:16:17 -0000	1.9
+++ src/vsip/impl/matvec.hpp	11 Jan 2006 15:58:53 -0000
@@ -39,7 +39,8 @@
 	  typename Block0,
 	  typename Block1,
 	  typename Block2>
-struct Evaluator<Op_prod_vv_outer, Block0, Op_list_3<T1, Block1, Block2>,
+struct Evaluator<Op_prod_vv_outer, Block0,
+		 Op_list_3<T1, Block1 const&, Block2 const&>,
 		 Generic_tag>
 {
   static bool const ct_valid = true;
@@ -63,7 +64,8 @@
 	  typename Block0,
 	  typename Block1,
 	  typename Block2>
-struct Evaluator<Op_prod_vv_outer, Block0, Op_list_3<std::complex<T1>, Block1, Block2>,
+struct Evaluator<Op_prod_vv_outer, Block0,
+		 Op_list_3<std::complex<T1>, Block1 const&, Block2 const&>,
 		 Generic_tag>
 {
   static bool const ct_valid = true;
@@ -104,7 +106,7 @@
   impl::General_dispatch<
 		impl::Op_prod_vv_outer,
 		Block2,
-                impl::Op_list_3<T0, Block0, Block1>,
+		  impl::Op_list_3<T0, Block0 const&, Block1 const&>,
                 typename impl::Dispatch_order<impl::Op_prod_vv_outer>::type >
 	::exec(r.block(), alpha, a.block(), b.block());
 }
Index: src/vsip/impl/metaprogramming.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/metaprogramming.hpp,v
retrieving revision 1.10
diff -u -r1.10 metaprogramming.hpp
--- src/vsip/impl/metaprogramming.hpp	7 Oct 2005 13:46:46 -0000	1.10
+++ src/vsip/impl/metaprogramming.hpp	11 Jan 2006 15:58:53 -0000
@@ -121,6 +121,10 @@
 struct Bool_type
 {};
 
+template <int value>
+struct Int_type
+{};
+
 } // namespace impl
 } // namespace vsip
 
Index: src/vsip/impl/par-chain-assign.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/par-chain-assign.hpp,v
retrieving revision 1.14
diff -u -r1.14 par-chain-assign.hpp
--- src/vsip/impl/par-chain-assign.hpp	5 Dec 2005 19:19:18 -0000	1.14
+++ src/vsip/impl/par-chain-assign.hpp	11 Jan 2006 15:58:53 -0000
@@ -285,10 +285,10 @@
 
     assert(src_am_.impl_rank() == dst_am_.impl_rank());
 
-    par_chain_assign::build_ext_array<Dim, T1, Block1>(
-      dst_, dst_am_, dst_ext_, impl::SYNC_OUT);
     par_chain_assign::build_ext_array<Dim, T2, Block2>(
       src_, src_am_, src_ext_, impl::SYNC_IN);
+    par_chain_assign::build_ext_array<Dim, T1, Block1>(
+      dst_, dst_am_, dst_ext_, impl::SYNC_OUT);
 
     build_send_list();
     if (!disable_copy)
@@ -305,11 +305,11 @@
     //  - User executed send() without a corresponding wait().
     assert(req_list.size() == 0);
 
-    par_chain_assign::cleanup_ext_array(src_am_.num_subblocks(), src_ext_);
     par_chain_assign::cleanup_ext_array(dst_am_.num_subblocks(), dst_ext_);
+    par_chain_assign::cleanup_ext_array(src_am_.num_subblocks(), src_ext_);
 
-    delete[] src_ext_;
     delete[] dst_ext_;
+    delete[] src_ext_;
   }
 
 
Index: src/vsip/impl/par-expr.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/par-expr.hpp,v
retrieving revision 1.7
diff -u -r1.7 par-expr.hpp
--- src/vsip/impl/par-expr.hpp	5 Dec 2005 19:19:19 -0000	1.7
+++ src/vsip/impl/par-expr.hpp	11 Jan 2006 15:58:53 -0000
@@ -17,6 +17,7 @@
 #include <vsip/impl/fast-block.hpp>
 #include <vsip/impl/domain-utils.hpp>
 #include <vsip/impl/distributed-block.hpp>
+#include <vsip/impl/block-traits.hpp>
 
 
 
@@ -57,7 +58,7 @@
 template <dimension_type Dim,
 	  typename       MapT,
 	  typename       BlockT>
-class Par_expr_block : Non_copyable
+class Par_expr_block<Dim, MapT, BlockT, Peb_reorg_tag> : Non_copyable
 {
 public:
   static dimension_type const dim = Dim;
@@ -108,6 +109,59 @@
 
 
 
+template <dimension_type Dim,
+	  typename       MapT,
+	  typename       BlockT>
+class Par_expr_block<Dim, MapT, BlockT, Peb_reuse_tag> : Non_copyable
+{
+public:
+  static dimension_type const dim = Dim;
+
+  typedef typename BlockT::value_type           value_type;
+  typedef typename BlockT::reference_type       reference_type;
+  typedef typename BlockT::const_reference_type const_reference_type;
+  typedef MapT                                  map_type;
+
+
+  typedef BlockT const                              local_block_type;
+  typedef Distributed_block<local_block_type, MapT> dst_block_type;
+
+  typedef typename View_of_dim<Dim, value_type, dst_block_type>::type
+		dst_view_type;
+  typedef typename View_of_dim<Dim, value_type, BlockT>::const_type
+		src_view_type;
+
+
+public:
+  Par_expr_block(MapT const& map, BlockT const& block)
+    : map_ (map),
+      blk_ (const_cast<BlockT&>(block))
+  {}
+
+  ~Par_expr_block() {}
+
+  void exec() {}
+
+  // Accessors.
+public:
+  length_type size() const VSIP_NOTHROW { return blk_.size(); }
+
+  void increment_count() const VSIP_NOTHROW {}
+  void decrement_count() const VSIP_NOTHROW {}
+
+  // Distributed Accessors
+public:
+  local_block_type& get_local_block() const
+    { return blk_; }
+
+  // Member data.
+private:
+  MapT const&     map_;
+  typename View_block_storage<BlockT>::expr_type blk_;
+};
+
+
+
 /// 'Combine' functor to construct an expression of Par_expr_blocks from an
 /// expression of distributed blockes.
 
@@ -330,7 +384,7 @@
 template <dimension_type Dim,
 	  typename       MapT,
 	  typename       BlockT>
-Par_expr_block<Dim, MapT, BlockT>::Par_expr_block(
+Par_expr_block<Dim, MapT, BlockT, Peb_reorg_tag>::Par_expr_block(
   MapT const&   map,
   BlockT const& block)
   : map_      (map),
@@ -348,10 +402,11 @@
 
 template <dimension_type Dim,
 	  typename       MapT,
-	  typename       BlockT>
-typename Par_expr_block<Dim, MapT, BlockT>::local_block_type&
+	  typename       BlockT,
+	  typename       ImplTag>
+typename Par_expr_block<Dim, MapT, BlockT, ImplTag>::local_block_type&
 get_local_block(
-  Par_expr_block<Dim, MapT, BlockT> const& block)
+  Par_expr_block<Dim, MapT, BlockT, ImplTag> const& block)
 {
   return block.get_local_block();
 }
Index: src/vsip/impl/par-services-mpi.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/par-services-mpi.hpp,v
retrieving revision 1.16
diff -u -r1.16 par-services-mpi.hpp
--- src/vsip/impl/par-services-mpi.hpp	7 Jan 2006 19:56:01 -0000	1.16
+++ src/vsip/impl/par-services-mpi.hpp	11 Jan 2006 15:58:53 -0000
@@ -28,6 +28,7 @@
 #include <vsip/impl/config.hpp>
 #include VSIP_IMPL_MPI_H
 #include <vsip/support.hpp>
+#include <vsip/impl/reductions-types.hpp>
 
 
 
@@ -57,10 +58,15 @@
   static MPI_Datatype value() { return MPITYPE; }			\
 };
 
-VSIP_IMPL_MPIDATATYPE(short,  MPI_SHORT)
-VSIP_IMPL_MPIDATATYPE(int,    MPI_INT)
-VSIP_IMPL_MPIDATATYPE(float,  MPI_FLOAT)
-VSIP_IMPL_MPIDATATYPE(double, MPI_DOUBLE)
+VSIP_IMPL_MPIDATATYPE(short,          MPI_SHORT)
+VSIP_IMPL_MPIDATATYPE(int,            MPI_INT)
+VSIP_IMPL_MPIDATATYPE(long,           MPI_LONG)
+VSIP_IMPL_MPIDATATYPE(unsigned short, MPI_UNSIGNED_SHORT)
+VSIP_IMPL_MPIDATATYPE(unsigned int,   MPI_UNSIGNED)
+VSIP_IMPL_MPIDATATYPE(unsigned long,  MPI_UNSIGNED_LONG)
+VSIP_IMPL_MPIDATATYPE(float,          MPI_FLOAT)
+VSIP_IMPL_MPIDATATYPE(double,         MPI_DOUBLE)
+VSIP_IMPL_MPIDATATYPE(long double,    MPI_LONG_DOUBLE)
 
 template <typename T>
 struct Mpi_datatype<std::complex<T> >
@@ -81,6 +87,26 @@
   }
 };
 
+template <>
+struct Mpi_datatype<bool>
+{
+  static MPI_Datatype value()
+  {
+    static bool         first = true;
+    static MPI_Datatype datatype;
+
+    if (first)
+    {
+      first = false;
+
+      MPI_Type_contiguous(sizeof(bool), MPI_BYTE, &datatype);
+      MPI_Type_commit(&datatype);
+    }
+
+    return datatype;
+  }
+};
+
 #undef VSIP_IMPL_MPIDATATYPE
 
 
@@ -226,25 +252,25 @@
 
 public:
   Communicator()
-    : comm_(MPI_COMM_NULL), rank_(0), size_(0)
+    : comm_(MPI_COMM_NULL), rank_(0), size_(0), pvec_(0)
   {}
 
   Communicator(MPI_Comm comm)
     : comm_(comm),
       rank_(get_rank(comm_)),
-      size_(get_size(comm_))
-  {}
+      size_(get_size(comm_)),
+      pvec_(size_)
+  {
+    for (index_type i=0; i<size_; ++i)
+    {
+      pvec_[i] = static_cast<processor_type>(i);
+    }
+  }
 
   processor_type rank() const { return rank_; }
   length_type    size() const { return size_; }
 
-  pvec_type pvec() const
-  { 
-    pvec_type pvec(size_);
-    for (index_type i=0; i<size_; ++i)
-      pvec[i] = static_cast<processor_type>(i);
-    return pvec;
-  }
+  pvec_type pvec() const { return pvec_; }
 
   void barrier() const { MPI_Barrier(comm_); }
 
@@ -264,12 +290,19 @@
 
   void wait(request_type& req);
 
+  template <typename T>
+  void broadcast(processor_type root_proc, T* data, length_type size);
+
+  template <typename T>
+  T allreduce(reduction_type rdx, T value);
+
   friend bool operator==(Communicator const&, Communicator const&);
 
 private:
-  MPI_Comm		comm_;
-  processor_type	rank_;
-  length_type		size_;
+  MPI_Comm		 comm_;
+  processor_type	 rank_;
+  length_type		 size_;
+  pvec_type		 pvec_;
 };
 
 } // namespace vsip::impl::mpi
@@ -331,6 +364,29 @@
   char*			   buf_;
 };
 
+// supported reductions
+
+template <reduction_type rtype,
+	  typename       T>
+struct Reduction_supported
+{ static bool const value = false; };
+
+template <> struct Reduction_supported<reduce_sum, int>
+{ static bool const value = true; };
+template <> struct Reduction_supported<reduce_sum, float>
+{ static bool const value = true; };
+
+template <> struct Reduction_supported<reduce_all_true, int>
+{ static bool const value = true; };
+
+template <> struct Reduction_supported<reduce_all_true_bool, bool>
+{ static bool const value = true; };
+
+template <> struct Reduction_supported<reduce_any_true, int>
+{ static bool const value = true; };
+
+template <> struct Reduction_supported<reduce_any_true_bool, bool>
+{ static bool const value = true; };
 
 
 
@@ -462,6 +518,50 @@
   MPI_Wait(&req, &status);
 }
 
+
+
+/// Broadcast a value from root processor to other processors.
+
+template <typename T>
+inline void
+Communicator::broadcast(processor_type root_proc, T* data, length_type size)
+{
+  int ierr = MPI_Bcast(data, size, Mpi_datatype<T>::value(), root_proc,
+		       comm_);
+  if (ierr != MPI_SUCCESS)
+    VSIP_IMPL_THROW(impl::unimplemented("MPI error handling."));
+}
+
+
+
+/// Reduce a value from all processors to all processors.
+
+template <typename T>
+inline T
+Communicator::allreduce(reduction_type rtype, T value)
+{
+  T result;
+
+  MPI_Op op;
+
+  switch (rtype)
+  {
+  case reduce_all_true:		op = MPI_LAND; break;
+  case reduce_all_true_bool:	op = MPI_BAND; break;
+  case reduce_any_true:		op = MPI_LOR; break;
+  case reduce_any_true_bool:	op = MPI_BOR; break;
+  case reduce_sum:		op = MPI_SUM; break;
+  default: assert(false);
+  }
+
+  int ierr = MPI_Allreduce(&value, &result, 1, Mpi_datatype<T>::value(),
+		       op, comm_);
+  if (ierr != MPI_SUCCESS)
+    VSIP_IMPL_THROW(impl::unimplemented("MPI error handling."));
+
+  return result;
+}
+
 } // namespace vsip::impl::mpi
 } // namespace vsip::impl
 } // namespace vsip
Index: src/vsip/impl/par-services-none.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/par-services-none.hpp,v
retrieving revision 1.9
diff -u -r1.9 par-services-none.hpp
--- src/vsip/impl/par-services-none.hpp	16 Sep 2005 21:51:08 -0000	1.9
+++ src/vsip/impl/par-services-none.hpp	11 Jan 2006 15:58:53 -0000
@@ -27,6 +27,7 @@
 
 #include <vsip/impl/refcount.hpp>
 #include <vsip/impl/copy_chain.hpp>
+#include <vsip/impl/reductions-types.hpp>
 
 
 
@@ -148,19 +149,18 @@
   Communicator()
     : rank_ (0),
       size_ (1),
-      msgs_ (new Msg_list, impl::noincrement)
-  {}
+      msgs_ (new Msg_list, impl::noincrement),
+      pvec_ (size_)
+  {
+    for (index_type i=0; i<size_; ++i)
+      pvec_[i] = static_cast<processor_type>(i);
+  }
 
   processor_type rank() const { return rank_; }
   length_type    size() const { return size_; }
 
   pvec_type pvec() const
-  { 
-    pvec_type pvec(size_);
-    for (index_type i=0; i<size_; ++i)
-      pvec[i] = static_cast<processor_type>(i);
-    return pvec;
-  }
+    { return pvec_; }
 
   // barrier is no-op for serial execution.
   void barrier() const {}
@@ -181,12 +181,19 @@
 
   void wait(request_type& req);
 
+  template <typename T>
+  void broadcast(processor_type root_proc, T* data, length_type size);
+
+  template <typename T>
+  T allreduce(reduction_type rdx, T value);
+
   friend bool operator==(Communicator const&, Communicator const&);
 
 private:
-  processor_type	 rank_;
-  length_type		 size_;
+  processor_type	    rank_;
+  length_type		    size_;
   Ref_counted_ptr<Msg_list> msgs_;
+  pvec_type                 pvec_;
 };
 
 } // namespace vsip::impl::par_services
@@ -238,6 +245,12 @@
 
 
 
+template <reduction_type rtype,
+	  typename       T>
+struct Reduction_supported
+{ static bool const value = true; };
+
+
 
 /***********************************************************************
   Definitions
@@ -380,6 +393,29 @@
   assert(req.get() == true);
 }
 
+
+
+/// Broadcast a value from root processor to other processors.
+
+template <typename T>
+inline void
+Communicator::broadcast(processor_type root_proc, T*, length_type)
+{
+  assert(root_proc == 0);
+  // No-op: no need to broadcast w/one processor.
+}
+
+
+
+/// Reduce a value from all processors to all processors.
+
+template <typename T>
+inline T
+Communicator::allreduce(reduction_type, T value)
+{
+  return value;
+}
+
 } // namespace vsip::impl::par_services_none
 } // namespace vsip::impl
 } // namespace vsip
Index: src/vsip/impl/par-util.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/par-util.hpp,v
retrieving revision 1.6
diff -u -r1.6 par-util.hpp
--- src/vsip/impl/par-util.hpp	5 Dec 2005 19:19:19 -0000	1.6
+++ src/vsip/impl/par-util.hpp	11 Jan 2006 15:58:53 -0000
@@ -31,6 +31,8 @@
 namespace vsip
 {
 
+const_Vector<processor_type> processor_set();
+
 namespace impl
 {
 
Index: src/vsip/impl/reductions-idx.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/reductions-idx.hpp,v
retrieving revision 1.3
diff -u -r1.3 reductions-idx.hpp
--- src/vsip/impl/reductions-idx.hpp	23 Aug 2005 12:17:11 -0000	1.3
+++ src/vsip/impl/reductions-idx.hpp	11 Jan 2006 15:58:53 -0000
@@ -191,243 +191,376 @@
 };
 
   
+/***********************************************************************
+  Generic evaluators.
+***********************************************************************/
 
+template <template <typename> class ReduceT>
+struct Op_reduce_idx;
 
+// Generic evaluator for vector reductions.
 
-template <template <typename> class Functor,
+template <template <typename> class ReduceT,
 	  typename                  T,
-	  typename                  BlockT>
-typename Functor<T>::result_type
-reduce_idx(const_Vector<T, BlockT> v, Index<1>& idx, row1_type)
-{
-  index_type maxi = 0;
+	  typename                  Block>
+struct Evaluator<Op_reduce_idx<ReduceT>, T,
+		 Op_list_3<Block const&, Index<1>&, row1_type>, Generic_tag>
+{
+  static bool const ct_valid = true;
+  static bool rt_valid(T&, Block const&, Index<1>&, row1_type)
+  { return true; }
+
+  static void exec(T& r, Block const& a, Index<1>& idx, row1_type)
+  {
+    typedef typename Block::value_type VT;
+    index_type maxi = 0;
 
-  Functor<T> maxv(v.get(maxi));
+    ReduceT<VT> maxv(a.get(maxi));
 
-  for (index_type i=0; i<v.size(0); ++i)
-    if (maxv.next_value(v.get(i)))
-      maxi = i;
+    for (index_type i=0; i<a.size(1, 0); ++i)
+      if (maxv.next_value(a.get(i)))
+	maxi = i;
 
-  idx = Index<1>(maxi);
-  return maxv.value();
-}
+    idx = Index<1>(maxi);
+    r =  maxv.value();
+  }
+};
 
 
 
-template <template <typename> class Functor,
+// Generic evaluator for matrix reductions.
+
+template <template <typename> class ReduceT,
 	  typename                  T,
-	  typename                  BlockT>
-typename Functor<T>::result_type
-reduce_idx(const_Matrix<T, BlockT> v, Index<2>& idx, row2_type)
-{
-  index_type maxi = 0;
-  index_type maxj = 0;
-
-  Functor<T> maxv(v.get(maxi, maxj));
-
-  for (index_type i=0; i<v.size(0); ++i)
-    for (index_type j=0; j<v.size(1); ++j)
-      if (maxv.next_value(v.get(i, j)))
+	  typename                  Block>
+struct Evaluator<Op_reduce_idx<ReduceT>, T,
+		 Op_list_3<Block const&, Index<2>&, row2_type>, Generic_tag>
+{
+  static bool const ct_valid = true;
+  static bool rt_valid(T&, Block const&, Index<2>&, row2_type)
+  { return true; }
+
+  static void exec(T& r, Block const& a, Index<2>& idx, row2_type)
+  {
+    typedef typename Block::value_type VT;
+    index_type maxi = 0;
+    index_type maxj = 0;
+
+    ReduceT<VT> maxv(a.get(maxi, maxj));
+
+    for (index_type i=0; i<a.size(2, 0); ++i)
+    for (index_type j=0; j<a.size(2, 1); ++j)
+    {
+      if (maxv.next_value(a.get(i, j)))
       {
 	maxi = i;
 	maxj = j;
       }
+    }
   
-  idx = Index<2>(maxi, maxj);
-  return maxv.value();
-}
+    idx = Index<2>(maxi, maxj);
+    r   = maxv.value();
+  }
+};
 
 
 
-template <template <typename> class Functor,
+template <template <typename> class ReduceT,
 	  typename                  T,
-	  typename                  BlockT>
-typename Functor<T>::result_type
-reduce_idx(const_Matrix<T, BlockT> v, Index<2>& idx, col2_type)
-{
-  index_type maxi = 0;
-  index_type maxj = 0;
-
-  Functor<T> maxv(v.get(maxi, maxj));
-
-  for (index_type j=0; j<v.size(1); ++j)
-    for (index_type i=0; i<v.size(0); ++i)
-      if (maxv.next_value(v.get(i, j)))
+	  typename                  Block>
+struct Evaluator<Op_reduce_idx<ReduceT>, T,
+		 Op_list_3<Block const&, Index<2>&, col2_type>, Generic_tag>
+{
+  static bool const ct_valid = true;
+  static bool rt_valid(T&, Block const&, Index<2>&, col2_type)
+  { return true; }
+
+  static void exec(T& r, Block const& a, Index<2>& idx, col2_type)
+  {
+    typedef typename Block::value_type VT;
+    index_type maxi = 0;
+    index_type maxj = 0;
+
+    ReduceT<VT> maxv(a.get(maxi, maxj));
+
+    for (index_type j=0; j<a.size(2, 1); ++j)
+    for (index_type i=0; i<a.size(2, 0); ++i)
+    {
+      if (maxv.next_value(a.get(i, j)))
       {
 	maxi = i;
 	maxj = j;
       }
+    }
   
-  idx = Index<2>(maxi, maxj);
-  return maxv.value();
-}
+    idx = Index<2>(maxi, maxj);
+    r   = maxv.value();
+  }
+};
 
 
 
-template <template <typename> class Functor,
+template <template <typename> class ReduceT,
 	  typename                  T,
-	  typename                  BlockT>
-typename Functor<T>::result_type
-reduce_idx(const_Tensor<T, BlockT> v, Index<3>& idx, tuple<0, 1, 2>)
-{
-  index_type maxi = 0;
-  index_type maxj = 0;
-  index_type maxk = 0;
-
-  Functor<T> maxv(v.get(maxi, maxj, maxk));
-
-  for (index_type i=0; i<v.size(0); ++i)
-    for (index_type j=0; j<v.size(1); ++j)
-      for (index_type k=0; k<v.size(2); ++k)
-	if (maxv.next_value(v.get(i, j, k)))
-	{
-	  maxi = i;
-	  maxj = j;
-	  maxk = k;
-	}
+	  typename                  Block>
+struct Evaluator<Op_reduce_idx<ReduceT>, T,
+		 Op_list_3<Block const&, Index<3>&, tuple<0, 1, 2> >,
+		 Generic_tag>
+{
+  static bool const ct_valid = true;
+  static bool rt_valid(T&, Block const&, Index<3>&, tuple<0, 1, 2>)
+  { return true; }
+
+  static void exec(T& r, Block const& a, Index<3>& idx, tuple<0, 1, 2>)
+  {
+    typedef typename Block::value_type VT;
+    
+    index_type maxi = 0;
+    index_type maxj = 0;
+    index_type maxk = 0;
+
+    ReduceT<VT> maxv(a.get(maxi, maxj, maxk));
+
+    for (index_type i=0; i<a.size(3, 0); ++i)
+    for (index_type j=0; j<a.size(3, 1); ++j)
+    for (index_type k=0; k<a.size(3, 2); ++k)
+    {
+      if (maxv.next_value(a.get(i, j, k)))
+      {
+	maxi = i;
+	maxj = j;
+	maxk = k;
+      }
+    }
 
-  idx = Index<3>(maxi, maxj, maxk);
-  return maxv.value();
-}
+    idx = Index<3>(maxi, maxj, maxk);
+    r   = maxv.value();
+  }
+};
 
 
 
-template <template <typename> class Functor,
+template <template <typename> class ReduceT,
 	  typename                  T,
-	  typename                  BlockT>
-typename Functor<T>::result_type
-reduce_idx(const_Tensor<T, BlockT> v, Index<3>& idx, tuple<0, 2, 1>)
-{
-  index_type maxi = 0;
-  index_type maxj = 0;
-  index_type maxk = 0;
-
-  Functor<T> maxv(v.get(maxi, maxj, maxk));
-
-  for (index_type i=0; i<v.size(0); ++i)
-    for (index_type k=0; k<v.size(2); ++k)
-      for (index_type j=0; j<v.size(1); ++j)
-	if (maxv.next_value(v.get(i, j, k)))
-	{
-	  maxi = i;
-	  maxj = j;
-	  maxk = k;
-	}
+	  typename                  Block>
+struct Evaluator<Op_reduce_idx<ReduceT>, T,
+		 Op_list_3<Block const&, Index<3>&, tuple<0, 2, 1> >,
+		 Generic_tag>
+{
+  static bool const ct_valid = true;
+  static bool rt_valid(T&, Block const&, Index<3>&, tuple<0, 2, 1>)
+  { return true; }
+
+  static void exec(T& r, Block const& a, Index<3>& idx, tuple<0, 2, 1>)
+  {
+    typedef typename Block::value_type VT;
+    
+    index_type maxi = 0;
+    index_type maxj = 0;
+    index_type maxk = 0;
+
+    ReduceT<VT> maxv(a.get(maxi, maxj, maxk));
+
+    for (index_type i=0; i<a.size(3, 0); ++i)
+    for (index_type k=0; k<a.size(3, 2); ++k)
+    for (index_type j=0; j<a.size(3, 1); ++j)
+    {
+      if (maxv.next_value(a.get(i, j, k)))
+      {
+	maxi = i;
+	maxj = j;
+	maxk = k;
+      }
+    }
 
-  idx = Index<3>(maxi, maxj, maxk);
-  return maxv.value();
-}
+    idx = Index<3>(maxi, maxj, maxk);
+    r   = maxv.value();
+  }
+};
 
 
 
-template <template <typename> class Functor,
+template <template <typename> class ReduceT,
 	  typename                  T,
-	  typename                  BlockT>
-typename Functor<T>::result_type
-reduce_idx(const_Tensor<T, BlockT> v, Index<3>& idx, tuple<1, 0, 2>)
-{
-  index_type maxi = 0;
-  index_type maxj = 0;
-  index_type maxk = 0;
-
-  Functor<T> maxv(v.get(maxi, maxj, maxk));
-
-  for (index_type j=0; j<v.size(1); ++j)
-    for (index_type i=0; i<v.size(0); ++i)
-      for (index_type k=0; k<v.size(2); ++k)
-	if (maxv.next_value(v.get(i, j, k)))
-	{
-	  maxi = i;
-	  maxj = j;
-	  maxk = k;
-	}
+	  typename                  Block>
+struct Evaluator<Op_reduce_idx<ReduceT>, T,
+		 Op_list_3<Block const&, Index<3>&, tuple<1, 0, 2> >,
+		 Generic_tag>
+{
+  static bool const ct_valid = true;
+  static bool rt_valid(T&, Block const&, Index<3>&, tuple<1, 0, 2>)
+  { return true; }
+
+  static void exec(T& r, Block const& a, Index<3>& idx, tuple<1, 0, 2>)
+  {
+    typedef typename Block::value_type VT;
+    
+    index_type maxi = 0;
+    index_type maxj = 0;
+    index_type maxk = 0;
+
+    ReduceT<VT> maxv(a.get(maxi, maxj, maxk));
+
+    for (index_type j=0; j<a.size(3, 1); ++j)
+    for (index_type i=0; i<a.size(3, 0); ++i)
+    for (index_type k=0; k<a.size(3, 2); ++k)
+    {
+      if (maxv.next_value(a.get(i, j, k)))
+      {
+	maxi = i;
+	maxj = j;
+	maxk = k;
+      }
+    }
 
-  idx = Index<3>(maxi, maxj, maxk);
-  return maxv.value();
-}
+    idx = Index<3>(maxi, maxj, maxk);
+    r   = maxv.value();
+  }
+};
 
 
 
-template <template <typename> class Functor,
+template <template <typename> class ReduceT,
 	  typename                  T,
-	  typename                  BlockT>
-typename Functor<T>::result_type
-reduce_idx(const_Tensor<T, BlockT> v, Index<3>& idx, tuple<1, 2, 0>)
-{
-  index_type maxi = 0;
-  index_type maxj = 0;
-  index_type maxk = 0;
-
-  Functor<T> maxv(v.get(maxi, maxj, maxk));
-
-  for (index_type j=0; j<v.size(1); ++j)
-    for (index_type k=0; k<v.size(2); ++k)
-      for (index_type i=0; i<v.size(0); ++i)
-	if (maxv.next_value(v.get(i, j, k)))
-	{
-	  maxi = i;
-	  maxj = j;
-	  maxk = k;
-	}
+	  typename                  Block>
+struct Evaluator<Op_reduce_idx<ReduceT>, T,
+		 Op_list_3<Block const&, Index<3>&, tuple<1, 2, 0> >,
+		 Generic_tag>
+{
+  static bool const ct_valid = true;
+  static bool rt_valid(T&, Block const&, Index<3>&, tuple<1, 2, 0>)
+  { return true; }
+
+  static void exec(T& r, Block const& a, Index<3>& idx, tuple<1, 2, 0>)
+  {
+    typedef typename Block::value_type VT;
+    
+    index_type maxi = 0;
+    index_type maxj = 0;
+    index_type maxk = 0;
+
+    ReduceT<VT> maxv(a.get(maxi, maxj, maxk));
+
+    for (index_type j=0; j<a.size(3, 1); ++j)
+    for (index_type k=0; k<a.size(3, 2); ++k)
+    for (index_type i=0; i<a.size(3, 0); ++i)
+    {
+      if (maxv.next_value(a.get(i, j, k)))
+      {
+	maxi = i;
+	maxj = j;
+	maxk = k;
+      }
+    }
 
-  idx = Index<3>(maxi, maxj, maxk);
-  return maxv.value();
-}
+    idx = Index<3>(maxi, maxj, maxk);
+    r   = maxv.value();
+  }
+};
 
 
 
-template <template <typename> class Functor,
+template <template <typename> class ReduceT,
 	  typename                  T,
-	  typename                  BlockT>
-typename Functor<T>::result_type
-reduce_idx(const_Tensor<T, BlockT> v, Index<3>& idx, tuple<2, 0, 1>)
-{
-  index_type maxi = 0;
-  index_type maxj = 0;
-  index_type maxk = 0;
-
-  Functor<T> maxv(v.get(maxi, maxj, maxk));
-
-  for (index_type k=0; k<v.size(2); ++k)
-    for (index_type i=0; i<v.size(0); ++i)
-      for (index_type j=0; j<v.size(1); ++j)
-	if (maxv.next_value(v.get(i, j, k)))
-	{
-	  maxi = i;
-	  maxj = j;
-	  maxk = k;
-	}
+	  typename                  Block>
+struct Evaluator<Op_reduce_idx<ReduceT>, T,
+		 Op_list_3<Block const&, Index<3>&, tuple<2, 0, 1> >,
+		 Generic_tag>
+{
+  static bool const ct_valid = true;
+  static bool rt_valid(T&, Block const&, Index<3>&, tuple<2, 0, 1>)
+  { return true; }
+
+  static void exec(T& r, Block const& a, Index<3>& idx, tuple<2, 0, 1>)
+  {
+    typedef typename Block::value_type VT;
+    
+    index_type maxi = 0;
+    index_type maxj = 0;
+    index_type maxk = 0;
+
+    ReduceT<VT> maxv(a.get(maxi, maxj, maxk));
+
+    for (index_type k=0; k<a.size(3, 2); ++k)
+    for (index_type i=0; i<a.size(3, 0); ++i)
+    for (index_type j=0; j<a.size(3, 1); ++j)
+    {
+      if (maxv.next_value(a.get(i, j, k)))
+      {
+	maxi = i;
+	maxj = j;
+	maxk = k;
+      }
+    }
 
-  idx = Index<3>(maxi, maxj, maxk);
-  return maxv.value();
-}
+    idx = Index<3>(maxi, maxj, maxk);
+    r   = maxv.value();
+  }
+};
 
 
 
-template <template <typename> class Functor,
+template <template <typename> class ReduceT,
 	  typename                  T,
-	  typename                  BlockT>
-typename Functor<T>::result_type
-reduce_idx(const_Tensor<T, BlockT> v, Index<3>& idx, tuple<2, 1, 0>)
-{
-  index_type maxi = 0;
-  index_type maxj = 0;
-  index_type maxk = 0;
-
-  Functor<T> maxv(v.get(maxi, maxj, maxk));
-
-  for (index_type k=0; k<v.size(2); ++k)
-    for (index_type j=0; j<v.size(1); ++j)
-      for (index_type i=0; i<v.size(0); ++i)
-	if (maxv.next_value(v.get(i, j, k)))
-	{
-	  maxi = i;
-	  maxj = j;
-	  maxk = k;
-	}
+	  typename                  Block>
+struct Evaluator<Op_reduce_idx<ReduceT>, T,
+		 Op_list_3<Block const&, Index<3>&, tuple<2, 1, 0> >,
+		 Generic_tag>
+{
+  static bool const ct_valid = true;
+  static bool rt_valid(T&, Block const&, Index<3>&, tuple<2, 1, 0>)
+  { return true; }
+
+  static void exec(T& r, Block const& a, Index<3>& idx, tuple<2, 1, 0>)
+  {
+    typedef typename Block::value_type VT;
+    
+    index_type maxi = 0;
+    index_type maxj = 0;
+    index_type maxk = 0;
+
+    ReduceT<VT> maxv(a.get(maxi, maxj, maxk));
+
+    for (index_type k=0; k<a.size(3, 2); ++k)
+    for (index_type j=0; j<a.size(3, 1); ++j)
+    for (index_type i=0; i<a.size(3, 0); ++i)
+    {
+      if (maxv.next_value(a.get(i, j, k)))
+      {
+	maxi = i;
+	maxj = j;
+	maxk = k;
+      }
+    }
+
+    idx = Index<3>(maxi, maxj, maxk);
+    r   = maxv.value();
+  }
+};
+
+
+
+template <template <typename> class ReduceT,
+	  typename                  ViewT>
+typename ReduceT<typename ViewT::value_type>::result_type
+reduce_idx(ViewT v, Index<ViewT::dim>& idx)
+{
+  typedef typename ViewT::value_type T;
+  typename ReduceT<T>::result_type r;
+
+  typedef typename Block_layout<typename ViewT::block_type>::order_type
+		order_type;
+
+  impl::General_dispatch<
+		impl::Op_reduce_idx<ReduceT>,
+		typename ReduceT<T>::result_type,
+		impl::Op_list_3<typename ViewT::block_type const&,
+                                Index<ViewT::dim>&,
+                                order_type>,
+                typename Make_type_list<Generic_tag>::type>
+        ::exec(r, v.block(), idx, order_type());
 
-  idx = Index<3>(maxi, maxj, maxk);
-  return maxv.value();
+  return r;
 }
 
 } // namespace impl
@@ -444,7 +577,7 @@
 VSIP_NOTHROW
 {
   typedef typename impl::Block_layout<BlockT>::order_type order_type;
-  return impl::reduce_idx<impl::Max_value>(v, idx, order_type());
+  return impl::reduce_idx<impl::Max_value>(v, idx);
 }
 
 
@@ -459,7 +592,7 @@
 VSIP_NOTHROW
 {
   typedef typename impl::Block_layout<BlockT>::order_type order_type;
-  return impl::reduce_idx<impl::Min_value>(v, idx, order_type());
+  return impl::reduce_idx<impl::Min_value>(v, idx);
 }
 
 
@@ -474,7 +607,7 @@
 VSIP_NOTHROW
 {
   typedef typename impl::Block_layout<BlockT>::order_type order_type;
-  return impl::reduce_idx<impl::Max_mag_value>(v, idx, order_type());
+  return impl::reduce_idx<impl::Max_mag_value>(v, idx);
 }
 
 
@@ -489,7 +622,7 @@
 VSIP_NOTHROW
 {
   typedef typename impl::Block_layout<BlockT>::order_type order_type;
-  return impl::reduce_idx<impl::Min_mag_value>(v, idx, order_type());
+  return impl::reduce_idx<impl::Min_mag_value>(v, idx);
 }
 
 
@@ -504,7 +637,7 @@
 VSIP_NOTHROW
 {
   typedef typename impl::Block_layout<BlockT>::order_type order_type;
-  return impl::reduce_idx<impl::Max_magsq_value>(v, idx, order_type());
+  return impl::reduce_idx<impl::Max_magsq_value>(v, idx);
 }
 
 
@@ -519,7 +652,7 @@
 VSIP_NOTHROW
 {
   typedef typename impl::Block_layout<BlockT>::order_type order_type;
-  return impl::reduce_idx<impl::Min_magsq_value>(v, idx, order_type());
+  return impl::reduce_idx<impl::Min_magsq_value>(v, idx);
 }
 
 } // namespace vsip
Index: src/vsip/impl/reductions-types.hpp
===================================================================
RCS file: src/vsip/impl/reductions-types.hpp
diff -N src/vsip/impl/reductions-types.hpp
--- /dev/null	1 Jan 1970 00:00:00 -0000
+++ src/vsip/impl/reductions-types.hpp	11 Jan 2006 15:58:53 -0000
@@ -0,0 +1,40 @@
+/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/impl/reductions-types.hpp
+    @author  Jules Bergmann
+    @date    2006-01-10
+    @brief   VSIPL++ Library: Enumeration type for reduction functions.
+	     [math.fns.reductions].
+
+*/
+
+#ifndef VSIP_IMPL_REDUCTIONS_TYPES_HPP
+#define VSIP_IMPL_REDUCTIONS_TYPES_HPP
+
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
+namespace vsip
+{
+
+namespace impl
+{
+
+enum reduction_type
+{
+  reduce_all_true,
+  reduce_all_true_bool,
+  reduce_any_true,
+  reduce_any_true_bool,
+  reduce_mean,
+  reduce_mean_magsq,
+  reduce_sum,
+  reduce_sum_bool,
+  reduce_sum_sq
+};
+
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_IMPL_REDUCTIONS_TYPES_HPP
Index: src/vsip/impl/reductions.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/reductions.hpp,v
retrieving revision 1.5
diff -u -r1.5 reductions.hpp
--- src/vsip/impl/reductions.hpp	16 Sep 2005 22:03:20 -0000	1.5
+++ src/vsip/impl/reductions.hpp	11 Jan 2006 15:58:53 -0000
@@ -19,6 +19,9 @@
 #include <vsip/vector.hpp>
 #include <vsip/matrix.hpp>
 #include <vsip/tensor.hpp>
+#include <vsip/impl/general_dispatch.hpp>
+#include <vsip/impl/reductions-types.hpp>
+#include <vsip/impl/par-services.hpp>
 
 
 
@@ -35,6 +38,8 @@
 template <typename T>
 struct All_true
 {
+  static reduction_type const rtype = reduce_all_true;
+
   typedef T result_type;
   typedef T accum_type;
 
@@ -53,6 +58,8 @@
 template <>
 struct All_true<bool>
 {
+  static reduction_type const rtype = reduce_all_true_bool;
+
   typedef bool result_type;
   typedef bool accum_type;
 
@@ -72,6 +79,8 @@
 template <typename T>
 struct Any_true
 {
+  static reduction_type const rtype = reduce_any_true;
+
   typedef T result_type;
   typedef T accum_type;
 
@@ -90,6 +99,8 @@
 template <>
 struct Any_true<bool>
 {
+  static reduction_type const rtype = reduce_any_true_bool;
+
   typedef bool result_type;
   typedef bool accum_type;
 
@@ -108,6 +119,8 @@
 template <typename T>
 struct Mean_value
 {
+  static reduction_type const rtype = reduce_sum;
+
   typedef T result_type;
   typedef T accum_type;
 
@@ -127,6 +140,8 @@
 template <typename T>
 struct Mean_magsq_value
 {
+  static reduction_type const rtype = reduce_sum;
+
   typedef typename Scalar_of<T>::type result_type;
   typedef typename Scalar_of<T>::type accum_type;
 
@@ -146,6 +161,8 @@
 template <typename T>
 struct Sum_value
 {
+  static reduction_type const rtype = reduce_sum;
+
   typedef T result_type;
   typedef T accum_type;
 
@@ -162,11 +179,34 @@
 
 
 
+template <typename T>
+struct Sum_magsq_value
+{
+  static reduction_type const rtype = reduce_sum;
+
+  typedef typename Scalar_of<T>::type result_type;
+  typedef typename Scalar_of<T>::type accum_type;
+
+  static accum_type initial() { return accum_type(); }
+
+  static accum_type update(accum_type state, T new_value)
+    { return state + magsq(new_value); }
+
+  static accum_type value(accum_type state, length_type)
+    { return state; }
+
+  static bool done(accum_type) { return false; }
+};
+
+
+
 /// Specialization for 'bool': return the number of true values.
 
 template <>
 struct Sum_value<bool>
 {
+  static reduction_type const rtype = reduce_sum;
+
   typedef length_type result_type;
   typedef length_type accum_type;
 
@@ -186,6 +226,8 @@
 template <typename T>
 struct Sum_sq_value
 {
+  static reduction_type const rtype = reduce_sum;
+
   typedef T result_type;
   typedef T accum_type;
 
@@ -202,223 +244,457 @@
 
 
 
+/***********************************************************************
+  Generic evaluators.
+***********************************************************************/
+
+template <template <typename> class ReduceT>
+struct Op_reduce;
+
+// Generic evaluator for vector reductions.
+
 template <template <typename> class ReduceT,
 	  typename                  T,
-	  typename                  BlockT>
-typename ReduceT<T>::result_type
-reduce(const_Vector<T, BlockT> v, row1_type)
-{
-  typename ReduceT<T>::accum_type state = ReduceT<T>::initial();
+	  typename                  Block>
+struct Evaluator<Op_reduce<ReduceT>, T,
+		 Op_list_3<Block const&, row1_type, Int_type<1> >, Generic_tag>
+{
+  static bool const ct_valid = true;
+  static bool rt_valid(T&, Block const&, row1_type, Int_type<1>)
+  { return true; }
 
-  length_type length = v.size(0);
-  PRAGMA_IVDEP
-  for (index_type i=0; i<length; ++i)
+  static void exec(T& r, Block const& a, row1_type, Int_type<1>)
   {
-    state = ReduceT<T>::update(state, v.get(i));
-    if (ReduceT<T>::done(state)) break;
-  }
+    typedef typename Block::value_type VT;
+    typename ReduceT<VT>::accum_type state = ReduceT<VT>::initial();
 
-  return ReduceT<T>::value(state, length);
-}
+    length_type length = a.size(1, 0);
+    PRAGMA_IVDEP
+    for (index_type i=0; i<length; ++i)
+    {
+      state = ReduceT<VT>::update(state, a.get(i));
+      if (ReduceT<VT>::done(state)) break;
+    }
+
+    r = ReduceT<VT>::value(state, length);
+  }
+};
 
 
 
 template <template <typename> class ReduceT,
 	  typename                  T,
-	  typename                  BlockT>
-typename ReduceT<T>::result_type
-reduce(const_Matrix<T, BlockT> v, row2_type)
-{
-  typename ReduceT<T>::accum_type state = ReduceT<T>::initial();
+	  typename                  Block>
+struct Evaluator<Op_reduce<ReduceT>, T,
+		 Op_list_3<Block const&, row2_type, Int_type<2> >,
+		 Generic_tag>
+{
+  static bool const ct_valid = true;
+  static bool rt_valid(T&, Block const&, row2_type, Int_type<2>)
+  { return true; }
 
-  length_type length_i = v.size(0);
-  length_type length_j = v.size(1);
-
-  for (index_type i=0; i<length_i; ++i)
-  PRAGMA_IVDEP
-  for (index_type j=0; j<length_j; ++j)
+  static void exec(T& r, Block const& a, row2_type, Int_type<2>)
   {
-    state = ReduceT<T>::update(state, v.get(i, j));
-    if (ReduceT<T>::done(state)) break;
-  }
+    typedef typename Block::value_type VT;
+    typename ReduceT<T>::accum_type state = ReduceT<VT>::initial();
 
-  return ReduceT<T>::value(state, length_i*length_j);
-}
+    length_type length_i = a.size(2, 0);
+    length_type length_j = a.size(2, 1);
+
+    for (index_type i=0; i<length_i; ++i)
+      PRAGMA_IVDEP
+      for (index_type j=0; j<length_j; ++j)
+      {
+	state = ReduceT<VT>::update(state, a.get(i, j));
+	if (ReduceT<VT>::done(state)) break;
+      }
+
+    r = ReduceT<VT>::value(state, length_i*length_j);
+  }
+};
 
 
 
 template <template <typename> class ReduceT,
 	  typename                  T,
-	  typename                  BlockT>
-typename ReduceT<T>::result_type
-reduce(const_Matrix<T, BlockT> v, col2_type)
-{
-  typename ReduceT<T>::accum_type state = ReduceT<T>::initial();
+	  typename                  Block>
+struct Evaluator<Op_reduce<ReduceT>, T,
+		 Op_list_3<Block const&, col2_type, Int_type<2> >,
+		 Generic_tag>
+{
+  static bool const ct_valid = true;
+  static bool rt_valid(T&, Block const&, col2_type, Int_type<2>)
+  { return true; }
 
-  length_type length_i = v.size(0);
-  length_type length_j = v.size(1);
-
-  for (index_type j=0; j<length_j; ++j)
-  PRAGMA_IVDEP
-  for (index_type i=0; i<length_i; ++i)
+  static void exec(T& r, Block const& a, col2_type, Int_type<2>)
   {
-    state = ReduceT<T>::update(state, v.get(i, j));
-    if (ReduceT<T>::done(state)) break;
-  }
+    typedef typename Block::value_type VT;
+    typename ReduceT<T>::accum_type state = ReduceT<VT>::initial();
 
-  return ReduceT<T>::value(state, length_i*length_j);
-}
+    length_type length_i = a.size(2, 0);
+    length_type length_j = a.size(2, 1);
+
+    for (index_type j=0; j<length_j; ++j)
+    PRAGMA_IVDEP
+    for (index_type i=0; i<length_i; ++i)
+    {
+      state = ReduceT<VT>::update(state, a.get(i, j));
+      if (ReduceT<VT>::done(state)) break;
+    }
+
+    r = ReduceT<VT>::value(state, length_i*length_j);
+  }
+};
 
 
 
 template <template <typename> class ReduceT,
 	  typename                  T,
-	  typename                  BlockT>
-typename ReduceT<T>::result_type
-reduce(const_Tensor<T, BlockT> v, tuple<0, 1, 2>)
-{
-  typename ReduceT<T>::accum_type state = ReduceT<T>::initial();
+	  typename                  Block>
+struct Evaluator<Op_reduce<ReduceT>, T,
+		 Op_list_3<Block const&, tuple<0, 1, 2>, Int_type<3> >,
+		 Generic_tag>
+{
+  static bool const ct_valid = true;
+  static bool rt_valid(T&, Block const&, tuple<0, 1, 2>, Int_type<3>)
+  { return true; }
 
-  length_type length_0 = v.size(0);
-  length_type length_1 = v.size(1);
-  length_type length_2 = v.size(2);
-
-  for (index_type i=0; i<length_0; ++i)
-  for (index_type j=0; j<length_1; ++j)
-  for (index_type k=0; k<length_2; ++k)
+  static void exec(T& r, Block const& a, tuple<0, 1, 2>, Int_type<3>)
   {
-    state = ReduceT<T>::update(state, v.get(i, j, k));
-    if (ReduceT<T>::done(state)) break;
-  }
+    typedef typename Block::value_type VT;
+    typename ReduceT<T>::accum_type state = ReduceT<VT>::initial();
 
-  return ReduceT<T>::value(state, length_0*length_1*length_2);
-}
+    length_type length_0 = a.size(3, 0);
+    length_type length_1 = a.size(3, 1);
+    length_type length_2 = a.size(3, 2);
+
+    for (index_type i=0; i<length_0; ++i)
+    for (index_type j=0; j<length_1; ++j)
+    for (index_type k=0; k<length_2; ++k)
+    {
+      state = ReduceT<VT>::update(state, a.get(i, j, k));
+      if (ReduceT<VT>::done(state)) break;
+    }
+
+    r = ReduceT<VT>::value(state, length_0*length_1*length_2);
+  }
+};
 
 
 
 template <template <typename> class ReduceT,
 	  typename                  T,
-	  typename                  BlockT>
-typename ReduceT<T>::result_type
-reduce(const_Tensor<T, BlockT> v, tuple<0, 2, 1>)
-{
-  typename ReduceT<T>::accum_type state = ReduceT<T>::initial();
+	  typename                  Block>
+struct Evaluator<Op_reduce<ReduceT>, T,
+		 Op_list_3<Block const&, tuple<0, 2, 1>, Int_type<3> >,
+		 Generic_tag>
+{
+  static bool const ct_valid = true;
+  static bool rt_valid(T&, Block const&, tuple<0, 2, 1>, Int_type<3>)
+  { return true; }
 
-  length_type length_0 = v.size(0);
-  length_type length_1 = v.size(1);
-  length_type length_2 = v.size(2);
-
-  for (index_type i=0; i<length_0; ++i)
-  for (index_type k=0; k<length_2; ++k)
-  for (index_type j=0; j<length_1; ++j)
+  static void exec(T& r, Block const& a, tuple<0, 2, 1>, Int_type<3>)
   {
-    state = ReduceT<T>::update(state, v.get(i, j, k));
-    if (ReduceT<T>::done(state)) break;
-  }
+    typedef typename Block::value_type VT;
+    typename ReduceT<T>::accum_type state = ReduceT<VT>::initial();
 
-  return ReduceT<T>::value(state, length_0*length_1*length_2);
-}
+    length_type length_0 = a.size(3, 0);
+    length_type length_1 = a.size(3, 1);
+    length_type length_2 = a.size(3, 2);
+
+    for (index_type i=0; i<length_0; ++i)
+    for (index_type k=0; k<length_2; ++k)
+    for (index_type j=0; j<length_1; ++j)
+    {
+      state = ReduceT<VT>::update(state, a.get(i, j, k));
+      if (ReduceT<VT>::done(state)) break;
+    }
+
+    r = ReduceT<VT>::value(state, length_0*length_1*length_2);
+  }
+};
 
 
 
 template <template <typename> class ReduceT,
 	  typename                  T,
-	  typename                  BlockT>
-typename ReduceT<T>::result_type
-reduce(const_Tensor<T, BlockT> v, tuple<1, 0, 2>)
-{
-  typename ReduceT<T>::accum_type state = ReduceT<T>::initial();
-
-  length_type length_0 = v.size(0);
-  length_type length_1 = v.size(1);
-  length_type length_2 = v.size(2);
+	  typename                  Block>
+struct Evaluator<Op_reduce<ReduceT>, T,
+		 Op_list_3<Block const&, tuple<1, 0, 2>, Int_type<3> >,
+		 Generic_tag>
+{
+  static bool const ct_valid = true;
+  static bool rt_valid(T&, Block const&, tuple<1, 0, 2>, Int_type<3>)
+  { return true; }
 
-  for (index_type j=0; j<length_1; ++j)
-  for (index_type i=0; i<length_0; ++i)
-  for (index_type k=0; k<length_2; ++k)
+  static void exec(T& r, Block const& a, tuple<1, 0, 2>, Int_type<3>)
   {
-    state = ReduceT<T>::update(state, v.get(i, j, k));
-    if (ReduceT<T>::done(state)) break;
+    typedef typename Block::value_type VT;
+    typename ReduceT<T>::accum_type state = ReduceT<VT>::initial();
+
+    length_type length_0 = a.size(3, 0);
+    length_type length_1 = a.size(3, 1);
+    length_type length_2 = a.size(3, 2);
+
+    for (index_type j=0; j<length_1; ++j)
+    for (index_type i=0; i<length_0; ++i)
+    for (index_type k=0; k<length_2; ++k)
+    {
+      state = ReduceT<VT>::update(state, a.get(i, j, k));
+      if (ReduceT<VT>::done(state)) break;
+    }
+
+    r = ReduceT<VT>::value(state, length_0*length_1*length_2);
   }
+};
 
-  return ReduceT<T>::value(state, length_0*length_1*length_2);
-}
+
+
+template <template <typename> class ReduceT,
+	  typename                  T,
+	  typename                  Block>
+struct Evaluator<Op_reduce<ReduceT>, T,
+		 Op_list_3<Block const&, tuple<1, 2, 0>, Int_type<3> >,
+		 Generic_tag>
+{
+  static bool const ct_valid = true;
+  static bool rt_valid(T&, Block const&, tuple<1, 2, 0>, Int_type<3>)
+  { return true; }
+
+  static void exec(T& r, Block const& a, tuple<1, 2, 0>, Int_type<3>)
+  {
+    typedef typename Block::value_type VT;
+    typename ReduceT<T>::accum_type state = ReduceT<VT>::initial();
+
+    length_type length_0 = a.size(3, 0);
+    length_type length_1 = a.size(3, 1);
+    length_type length_2 = a.size(3, 2);
+
+    for (index_type j=0; j<length_1; ++j)
+    for (index_type k=0; k<length_2; ++k)
+    for (index_type i=0; i<length_0; ++i)
+    {
+      state = ReduceT<VT>::update(state, a.get(i, j, k));
+      if (ReduceT<VT>::done(state)) break;
+    }
+
+    r = ReduceT<VT>::value(state, length_0*length_1*length_2);
+  }
+};
 
 
 
 template <template <typename> class ReduceT,
 	  typename                  T,
-	  typename                  BlockT>
-typename ReduceT<T>::result_type
-reduce(const_Tensor<T, BlockT> v, tuple<1, 2, 0>)
-{
-  typename ReduceT<T>::accum_type state = ReduceT<T>::initial();
+	  typename                  Block>
+struct Evaluator<Op_reduce<ReduceT>, T,
+		 Op_list_3<Block const&, tuple<2, 0, 1>, Int_type<3> >,
+		 Generic_tag>
+{
+  static bool const ct_valid = true;
+  static bool rt_valid(T&, Block const&, tuple<2, 0, 1>, Int_type<3>)
+  { return true; }
+
+  static void exec(T& r, Block const& a, tuple<2, 0, 1>, Int_type<3>)
+  {
+    typedef typename Block::value_type VT;
+    typename ReduceT<T>::accum_type state = ReduceT<VT>::initial();
+
+    length_type length_0 = a.size(3, 0);
+    length_type length_1 = a.size(3, 1);
+    length_type length_2 = a.size(3, 2);
+
+    for (index_type k=0; k<length_2; ++k)
+    for (index_type i=0; i<length_0; ++i)
+    for (index_type j=0; j<length_1; ++j)
+    {
+      state = ReduceT<VT>::update(state, a.get(i, j, k));
+      if (ReduceT<VT>::done(state)) break;
+    }
+
+    r = ReduceT<VT>::value(state, length_0*length_1*length_2);
+  }
+};
+
+
 
-  length_type length_0 = v.size(0);
-  length_type length_1 = v.size(1);
-  length_type length_2 = v.size(2);
+template <template <typename> class ReduceT,
+	  typename                  T,
+	  typename                  Block>
+struct Evaluator<Op_reduce<ReduceT>, T,
+		 Op_list_3<Block const&, tuple<2, 1, 0>, Int_type<3> >,
+		 Generic_tag>
+{
+  static bool const ct_valid = true;
+  static bool rt_valid(T&, Block const&, tuple<2, 1, 0>, Int_type<3>)
+  { return true; }
 
-  for (index_type j=0; j<length_1; ++j)
-  for (index_type k=0; k<length_2; ++k)
-  for (index_type i=0; i<length_0; ++i)
+  static void exec(T& r, Block const& a, tuple<2, 1, 0>, Int_type<3>)
   {
-    state = ReduceT<T>::update(state, v.get(i, j, k));
-    if (ReduceT<T>::done(state)) break;
+    typedef typename Block::value_type VT;
+    typename ReduceT<T>::accum_type state = ReduceT<VT>::initial();
+
+    length_type length_0 = a.size(3, 0);
+    length_type length_1 = a.size(3, 1);
+    length_type length_2 = a.size(3, 2);
+
+    for (index_type k=0; k<length_2; ++k)
+    for (index_type j=0; j<length_1; ++j)
+    for (index_type i=0; i<length_0; ++i)
+    {
+      state = ReduceT<VT>::update(state, a.get(i, j, k));
+      if (ReduceT<VT>::done(state)) break;
+    }
+
+    r = ReduceT<VT>::value(state, length_0*length_1*length_2);
   }
+};
 
-  return ReduceT<T>::value(state, length_0*length_1*length_2);
-}
 
 
+/***********************************************************************
+  Parallel evaluators.
+***********************************************************************/
 
 template <template <typename> class ReduceT,
-	  typename                  T,
-	  typename                  BlockT>
-typename ReduceT<T>::result_type
-reduce(const_Tensor<T, BlockT> v, tuple<2, 0, 1>)
-{
-  typename ReduceT<T>::accum_type state = ReduceT<T>::initial();
+          typename                  T,
+	  typename                  Block,
+	  typename                  OrderT,
+	  int                       Dim>
+struct Par_reduction_eval_base
+{
+  static bool const ct_valid = 
+    !Is_local_map<typename Block::map_type>::value &&
+    !Type_equal<typename Block::map_type, Global_map<Block::dim> >::value &&
+    Reduction_supported<ReduceT<typename Block::value_type>::rtype,
+                        typename Block::value_type>::value;
 
-  length_type length_0 = v.size(0);
-  length_type length_1 = v.size(1);
-  length_type length_2 = v.size(2);
+  static bool rt_valid(T&, Block const&, OrderT, Int_type<Dim>)
+  { return true; }
+};
 
-  for (index_type k=0; k<length_2; ++k)
-  for (index_type i=0; i<length_0; ++i)
-  for (index_type j=0; j<length_1; ++j)
+template <typename                  T,
+	  typename                  Block,
+	  typename                  OrderT,
+	  int                       Dim>
+struct Evaluator<Op_reduce<Mean_value>, T,
+		 Op_list_3<Block const&, OrderT, Int_type<Dim> >, Parallel_tag>
+  : Par_reduction_eval_base<Mean_value, T, Block, OrderT, Dim>
+{
+  static void exec(T& r, Block const& a, OrderT, Int_type<Dim>)
   {
-    state = ReduceT<T>::update(state, v.get(i, j, k));
-    if (ReduceT<T>::done(state)) break;
+    typedef typename Block::value_type VT;
+    T l_r;
+    typedef typename Distributed_local_block<Block>::type local_block_type;
+    typedef typename Block_layout<local_block_type>::order_type order_type;
+    typedef Int_type<Dim>                                       dim_type;
+    typedef Mean_value<VT> reduce_type;
+
+    impl::General_dispatch<
+		impl::Op_reduce<Sum_value>,
+		typename Sum_value<VT>::result_type,
+		impl::Op_list_3<local_block_type const&,
+		                order_type,
+		                dim_type>,
+                typename Make_type_list<Generic_tag>::type>
+	::exec(l_r, get_local_block(a), order_type(), dim_type());
+
+    r = a.map().impl_comm().allreduce(reduce_type::rtype, l_r);
+    r /= static_cast<typename reduce_type::accum_type>(a.size());
   }
+};
 
-  return ReduceT<T>::value(state, length_0*length_1*length_2);
-}
+
+
+template <typename                  T,
+	  typename                  Block,
+	  typename                  OrderT,
+	  int                       Dim>
+struct Evaluator<Op_reduce<Mean_magsq_value>, T,
+		 Op_list_3<Block const&, OrderT, Int_type<Dim> >, Parallel_tag>
+  : Par_reduction_eval_base<Mean_magsq_value, T, Block, OrderT, Dim>
+{
+  static void exec(T& r, Block const& a, OrderT, Int_type<Dim>)
+  {
+    typedef typename Block::value_type VT;
+    T l_r;
+    typedef typename Distributed_local_block<Block>::type local_block_type;
+    typedef typename Block_layout<local_block_type>::order_type order_type;
+    typedef Int_type<Dim>                                       dim_type;
+    typedef Mean_magsq_value<VT> reduce_type;
+
+    impl::General_dispatch<
+		impl::Op_reduce<Sum_magsq_value>,
+		typename Sum_magsq_value<VT>::result_type,
+		impl::Op_list_3<local_block_type const&,
+		                order_type,
+		                dim_type>,
+                typename Make_type_list<Generic_tag>::type>
+	::exec(l_r, get_local_block(a), order_type(), dim_type());
+
+    r = a.map().impl_comm().allreduce(reduce_type::rtype, l_r);
+    r /= static_cast<typename reduce_type::accum_type>(a.size());
+  }
+};
 
 
 
 template <template <typename> class ReduceT,
 	  typename                  T,
-	  typename                  BlockT>
-typename ReduceT<T>::result_type
-reduce(const_Tensor<T, BlockT> v, tuple<2, 1, 0>)
+	  typename                  Block,
+	  typename                  OrderT,
+	  int                       Dim>
+struct Evaluator<Op_reduce<ReduceT>, T,
+		 Op_list_3<Block const&, OrderT, Int_type<Dim> >, Parallel_tag>
+  : Par_reduction_eval_base<ReduceT, T, Block, OrderT, Dim>
 {
-  typename ReduceT<T>::accum_type state = ReduceT<T>::initial();
-
-  length_type length_0 = v.size(0);
-  length_type length_1 = v.size(1);
-  length_type length_2 = v.size(2);
-
-  for (index_type k=0; k<length_2; ++k)
-  for (index_type j=0; j<length_1; ++j)
-  for (index_type i=0; i<length_0; ++i)
+  static void exec(T& r, Block const& a, OrderT, Int_type<Dim>)
   {
-    state = ReduceT<T>::update(state, v.get(i, j, k));
-    if (ReduceT<T>::done(state)) break;
+    typedef typename Block::value_type VT;
+    T l_r;
+    typedef typename Distributed_local_block<Block>::type local_block_type;
+    typedef typename Block_layout<local_block_type>::order_type order_type;
+    typedef Int_type<Dim>                                       dim_type;
+    typedef ReduceT<VT> reduce_type;
+
+    impl::General_dispatch<
+		impl::Op_reduce<ReduceT>,
+		typename ReduceT<VT>::result_type,
+		impl::Op_list_3<local_block_type const&,
+		                order_type,
+		                dim_type>,
+                typename Make_type_list<Generic_tag>::type>
+	::exec(l_r, get_local_block(a), order_type(), dim_type());
+
+    r = a.map().impl_comm().allreduce(ReduceT<T>::rtype, l_r);
   }
+};
+
 
-  return ReduceT<T>::value(state, length_0*length_1*length_2);
-}
 
+template <template <typename> class ReduceT,
+	  typename                  ViewT>
+typename ReduceT<typename ViewT::value_type>::result_type
+reduce(ViewT v)
+{
+  typedef typename ViewT::value_type T;
+  typename ReduceT<T>::result_type r;
+
+  typedef typename Block_layout<typename ViewT::block_type>::order_type
+		order_type;
+  typedef Int_type<ViewT::dim>                   dim_type;
+
+  impl::General_dispatch<
+		impl::Op_reduce<ReduceT>,
+		typename ReduceT<T>::result_type,
+		impl::Op_list_3<typename ViewT::block_type const&,
+		                order_type,
+                                Int_type<ViewT::dim> >,
+                typename Make_type_list<Parallel_tag, Generic_tag>::type>
+        ::exec(r, v.block(), order_type(), dim_type());
+
+  return r;
+}
 
 
 } // namespace vsip::impl
@@ -432,7 +708,7 @@
 alltrue(ViewT<T, BlockT> v)
 {
   typedef typename impl::Block_layout<BlockT>::order_type order_type;
-  return impl::reduce<impl::All_true>(v, order_type());
+  return impl::reduce<impl::All_true>(v);
 }
 
 
@@ -444,7 +720,7 @@
 anytrue(ViewT<T, BlockT> v)
 {
   typedef typename impl::Block_layout<BlockT>::order_type order_type;
-  return impl::reduce<impl::Any_true>(v, order_type());
+  return impl::reduce<impl::Any_true>(v);
 }
 
 
@@ -456,7 +732,7 @@
 meanval(ViewT<T, BlockT> v)
 {
   typedef typename impl::Block_layout<BlockT>::order_type order_type;
-  return impl::reduce<impl::Mean_value>(v, order_type());
+  return impl::reduce<impl::Mean_value>(v);
 }
 
 
@@ -470,7 +746,7 @@
 meansqval(ViewT<T, BlockT> v)
 {
   typedef typename impl::Block_layout<BlockT>::order_type order_type;
-  return impl::reduce<impl::Mean_magsq_value>(v, order_type());
+  return impl::reduce<impl::Mean_magsq_value>(v);
 }
 
 
@@ -482,7 +758,7 @@
 sumval(ViewT<T, BlockT> v)
 {
   typedef typename impl::Block_layout<BlockT>::order_type order_type;
-  return impl::reduce<impl::Sum_value>(v, order_type());
+  return impl::reduce<impl::Sum_value>(v);
 }
 
 
@@ -494,7 +770,7 @@
 sumsqval(ViewT<T, BlockT> v)
 {
   typedef typename impl::Block_layout<BlockT>::order_type order_type;
-  return impl::reduce<impl::Sum_sq_value>(v, order_type());
+  return impl::reduce<impl::Sum_sq_value>(v);
 }
 
 
Index: src/vsip/impl/signal-conv-common.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/signal-conv-common.hpp,v
retrieving revision 1.6
diff -u -r1.6 signal-conv-common.hpp
--- src/vsip/impl/signal-conv-common.hpp	5 Dec 2005 15:16:17 -0000	1.6
+++ src/vsip/impl/signal-conv-common.hpp	11 Jan 2006 15:58:53 -0000
@@ -149,23 +149,23 @@
   {
     length_type M = coeff.size(0);
     CoeffViewT full_coeff(2*M-1);
-    full_coeff(Domain<1>(0, 1, M))   = coeff;
-    full_coeff(Domain<1>(M, 1, M-1)) = coeff(Domain<1>(M-2, -1, M-1));
+    assign_local(full_coeff(Domain<1>(0, 1, M))  , coeff);
+    assign_local(full_coeff(Domain<1>(M, 1, M-1)), coeff(Domain<1>(M-2, -1, M-1)));
     return full_coeff;
   }
   else if (sym == sym_even_len_even)
   {
     length_type M = coeff.size(0);
     CoeffViewT full_coeff(2*M);
-    full_coeff(Domain<1>(0, 1, M)) = coeff;
-    full_coeff(Domain<1>(M, 1, M)) = coeff(Domain<1>(M-1, -1, M));
+    assign_local(full_coeff(Domain<1>(0, 1, M)), coeff);
+    assign_local(full_coeff(Domain<1>(M, 1, M)), coeff(Domain<1>(M-1, -1, M)));
     return full_coeff;
   }
   else /* (sym == nonsym) */
   {
     length_type M = coeff.size(0);
     CoeffViewT full_coeff(M);
-    full_coeff = coeff;
+    assign_local(full_coeff, coeff);
     return full_coeff;
   }
 }
Index: src/vsip/impl/signal-conv-ext.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/signal-conv-ext.hpp,v
retrieving revision 1.8
diff -u -r1.8 signal-conv-ext.hpp
--- src/vsip/impl/signal-conv-ext.hpp	5 Dec 2005 15:16:17 -0000	1.8
+++ src/vsip/impl/signal-conv-ext.hpp	11 Jan 2006 15:58:53 -0000
@@ -21,6 +21,7 @@
 #include <vsip/impl/signal-types.hpp>
 #include <vsip/impl/profile.hpp>
 #include <vsip/impl/signal-conv-common.hpp>
+#include <vsip/impl/working-view.hpp>
 
 
 
@@ -228,18 +229,35 @@
 void
 Convolution_impl<ConstViewT, Symm, Supp, T, n_times, a_hint, Generic_tag>::
 convolve(
-  const_Vector<T, Block0> in,
-  Vector<T, Block1>       out)
+  const_Vector<T, Block0> a_in,
+  Vector<T, Block1>       a_out)
 VSIP_NOTHROW
 {
+  using vsip::impl::Working_view_holder;
+
+  // PROFILE: Warn if arguments are not entirely on single processor
+  // (either as undistributed views or as local views of distr obj).
+
+  typedef Working_view_holder<const_Vector<T, Block0> > in_work_type;
+  typedef Working_view_holder<      Vector<T, Block1> > out_work_type;
+
+  in_work_type  w_in(a_in);
+  out_work_type w_out(a_out);
+
+  typename in_work_type::type  in  = w_in.view;
+  typename out_work_type::type out = w_out.view;
+
+  typedef typename in_work_type::type::block_type  in_block_type;
+  typedef typename out_work_type::type::block_type out_block_type;
+
   length_type const M = this->coeff_.size(0);
   length_type const N = this->input_size_[0].size();
   length_type const P = this->output_size_[0].size();
 
   assert(P == out.size());
 
-  typedef vsip::impl::Ext_data<Block0> in_ext_type;
-  typedef vsip::impl::Ext_data<Block1> out_ext_type;
+  typedef vsip::impl::Ext_data<in_block_type> in_ext_type;
+  typedef vsip::impl::Ext_data<out_block_type> out_ext_type;
 
   in_ext_type  in_ext (in.block(),  vsip::impl::SYNC_IN,  in_buffer_);
   out_ext_type out_ext(out.block(), vsip::impl::SYNC_OUT, out_buffer_);
@@ -282,10 +300,27 @@
 void
 Convolution_impl<ConstViewT, Symm, Supp, T, n_times, a_hint, Generic_tag>::
 convolve(
-  const_Matrix<T, Block0> in,
-  Matrix<T, Block1>       out)
+  const_Matrix<T, Block0> a_in,
+  Matrix<T, Block1>       a_out)
 VSIP_NOTHROW
 {
+  using vsip::impl::Working_view_holder;
+
+  // PROFILE: Warn if arguments are not entirely on single processor
+  // (either as undistributed views or as local views of distr obj).
+
+  typedef Working_view_holder<const_Matrix<T, Block0> > in_work_type;
+  typedef Working_view_holder<      Matrix<T, Block1> > out_work_type;
+
+  in_work_type  w_in(a_in);
+  out_work_type w_out(a_out);
+
+  typename in_work_type::type  in  = w_in.view;
+  typename out_work_type::type out = w_out.view;
+
+  typedef typename in_work_type::type::block_type  in_block_type;
+  typedef typename out_work_type::type::block_type out_block_type;
+
   length_type const Mr = this->coeff_.size(0);
   length_type const Mc = this->coeff_.size(1);
 
@@ -297,8 +332,8 @@
 
   assert(Pr == out.size(0) && Pc == out.size(1));
 
-  typedef vsip::impl::Ext_data<Block0> in_ext_type;
-  typedef vsip::impl::Ext_data<Block1> out_ext_type;
+  typedef vsip::impl::Ext_data<in_block_type>  in_ext_type;
+  typedef vsip::impl::Ext_data<out_block_type> out_ext_type;
 
   in_ext_type  in_ext (in.block(),  vsip::impl::SYNC_IN,  in_buffer_);
   out_ext_type out_ext(out.block(), vsip::impl::SYNC_OUT, out_buffer_);
Index: src/vsip/impl/solver-lu.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/solver-lu.hpp,v
retrieving revision 1.1
diff -u -r1.1 solver-lu.hpp
--- src/vsip/impl/solver-lu.hpp	30 Sep 2005 21:43:07 -0000	1.1
+++ src/vsip/impl/solver-lu.hpp	11 Jan 2006 15:58:53 -0000
@@ -213,7 +213,7 @@
 {
   assert(m.size(0) == length_ && m.size(1) == length_);
 
-  data_ = m;
+  assign_local(data_, m);
 
   Ext_data<data_block_type> ext(data_.block());
 
@@ -257,7 +257,7 @@
   char trans;
 
   Matrix<T, Dense<2, T, col2_type> > b_int(b.size(0), b.size(1));
-  b_int = b;
+  assign_local(b_int, b);
 
   if (tr == mat_ntrans)
     trans = 'N';
@@ -280,7 +280,7 @@
 		  &ipiv_[0],			  // pivots
 		  b_ext.data(), b_ext.stride(1)); // B, ldb
   }
-  x = b_int;
+  assign_local(x, b_int);
 
   return true;
 }
Index: src/vsip/impl/solver-qr.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/solver-qr.hpp,v
retrieving revision 1.3
diff -u -r1.3 solver-qr.hpp
--- src/vsip/impl/solver-qr.hpp	16 Sep 2005 22:03:20 -0000	1.3
+++ src/vsip/impl/solver-qr.hpp	11 Jan 2006 15:58:53 -0000
@@ -21,6 +21,7 @@
 #include <vsip/impl/math-enum.hpp>
 #include <vsip/impl/lapack.hpp>
 #include <vsip/impl/temp_buffer.hpp>
+#include <vsip/impl/working-view.hpp>
 
 
 
@@ -311,7 +312,7 @@
 
   int lwork   = geqrf_lwork_;
 
-  data_ = m;
+  assign_local(data_, m);
 
   Ext_data<data_block_type> ext(data_.block());
 
@@ -412,7 +413,7 @@
   }
 
   Matrix<T, Dense<2, T, col2_type> > b_int(b.size(0), b.size(1));
-  b_int = b;
+  assign_local(b_int, b);
 
   int blksize   = lapack::mqr_blksize<T>(side, trans,
 					 b.size(0), b.size(1), k_reflectors);
@@ -433,7 +434,7 @@
 		mqr_work.data(), mqr_lwork);
 		
   }
-  x = b_int;
+  assign_local(x, b_int);
 
   return true;
 }
@@ -476,7 +477,7 @@
   }
 
   Matrix<T, Dense<2, T, col2_type> > b_int(b.size(0), b.size(1));
-  b_int = b;
+  assign_local(b_int, b);
   
 
   {
@@ -492,7 +493,7 @@
 	       a_ext.data(), m_,
 	       b_ext.data(), b_ext.stride(1));
   }
-  x = b_int;
+  assign_local(x, b_int);
 
   return true;
 }
@@ -523,7 +524,7 @@
   // Then solve:     R x = b_1
 
   Matrix<T, Dense<2, T, col2_type> > b_int(b_rows, b_cols);
-  b_int = b;
+  assign_local(b_int, b);
 
   {
     Ext_data<Dense<2, T, col2_type> > b_ext(b_int.block());
@@ -552,7 +553,7 @@
 	       b_ext.data(), b_rows);
   }
 
-  x = b_int;
+  assign_local(x, b_int);
 
   return true;
 }
@@ -594,7 +595,7 @@
   // 2. solve for X:         R X = C
 
   Matrix<T, Dense<2, T, col2_type> > c(c_rows, c_cols);
-  c = b;
+  assign_local(c, b);
 
   {
     Ext_data<Dense<2, T, col2_type> > c_ext(c.block());
@@ -627,7 +628,7 @@
 	       c_ext.data(), c_rows);
   }
 
-  x = c(Domain<2>(n_, p));
+  assign_local(x, c(Domain<2>(n_, p)));
 
   return true;
 }
Index: src/vsip/impl/solver-svd.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/solver-svd.hpp,v
retrieving revision 1.1
diff -u -r1.1 solver-svd.hpp
--- src/vsip/impl/solver-svd.hpp	27 Sep 2005 21:30:17 -0000	1.1
+++ src/vsip/impl/solver-svd.hpp	11 Jan 2006 15:58:53 -0000
@@ -414,7 +414,7 @@
 
   int lwork   = lwork_gebrd_;
 
-  data_ = m;
+  assign_local(data_, m);
 
   // Step 1: Reduce general matrix A to bidiagonal form.
   //
Index: src/vsip/impl/vector-iterator.hpp
===================================================================
RCS file: src/vsip/impl/vector-iterator.hpp
diff -N src/vsip/impl/vector-iterator.hpp
--- /dev/null	1 Jan 1970 00:00:00 -0000
+++ src/vsip/impl/vector-iterator.hpp	11 Jan 2006 15:58:53 -0000
@@ -0,0 +1,104 @@
+/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/impl/vector-iterator.hpp
+    @author  Jules Bergmann
+    @date    2006-01-04
+    @brief   VSIPL++ Library: Vector Iterator.
+
+    Iterator over a sequence of values stored in a vector view.
+*/
+
+#ifndef VSIP_IMPL_VECTOR_ITERATOR_HPP
+#define VSIP_IMPL_VECTOR_ITERATOR_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+
+
+/***********************************************************************
+  Declarations & Class Definitions
+***********************************************************************/
+
+namespace vsip
+{
+
+namespace impl
+{
+
+
+/// Class to iterate over values stored in a vector view.
+
+template <typename ViewT>
+class Vector_iterator
+{
+public:
+  typedef typename ViewT::value_type value_type;
+
+  Vector_iterator(ViewT view, index_type idx)
+    : view_(view),
+      idx_ (idx)
+    {}
+
+  Vector_iterator(Vector_iterator const& rhs)
+    : view_(rhs.view_),
+      idx_ (rhs.idx_)
+    {}
+
+  Vector_iterator& operator=(Vector_iterator const& rhs)
+  {
+    view_  = rhs.view_;
+    idx_   = rhs.idx_;
+    return *this;
+  }
+
+  Vector_iterator& operator++()       { idx_ += 1;  return *this; }
+  Vector_iterator& operator--()       { idx_ -= 1;  return *this; }
+  Vector_iterator& operator+=(int dx) { idx_ += dx; return *this; }
+  Vector_iterator& operator-=(int dx) { idx_ -= dx; return *this; }
+
+  Vector_iterator& operator++(int)
+    { Vector_iterator tmp = *this; idx_ += 1; return tmp; }
+  Vector_iterator& operator--(int)
+    { Vector_iterator tmp = *this; idx_ -= 1; return tmp; }
+
+  bool operator==(Vector_iterator const& rhs) const
+    { return &(view_.block()) == &(view_.block()) && idx_ == rhs.idx_; }
+
+  bool operator!=(Vector_iterator const& rhs) const
+    { return &(view_.block()) != &(view_.block()) || idx_ != rhs.idx_; }
+
+  bool operator<(Vector_iterator const& rhs) const
+    { return (idx_ < rhs.idx_); }
+
+  int operator-(Vector_iterator const& rhs) const
+    { return (idx_ - rhs.idx_); }
+
+  Vector_iterator operator+(int dx) const
+  {
+    Vector_iterator res(view_, idx_);
+    res += dx;
+    return res;
+  }
+  Vector_iterator operator-(int dx) const
+  {
+    Vector_iterator res(view_, idx_);
+    res -= dx;
+    return res;
+  }
+  
+  value_type operator*() const
+    { return view_.get(idx_); }
+
+  // Member data.
+private:
+  ViewT         view_;
+  index_type	idx_;
+};
+
+
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_IMPL_VECTOR_ITERATOR_HPP
Index: src/vsip/impl/view_traits.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/view_traits.hpp,v
retrieving revision 1.11
diff -u -r1.11 view_traits.hpp
--- src/vsip/impl/view_traits.hpp	5 Dec 2005 19:19:19 -0000	1.11
+++ src/vsip/impl/view_traits.hpp	11 Jan 2006 15:58:53 -0000
@@ -56,6 +56,12 @@
 
 template <typename> struct Is_view_type { static bool const value = false;};
 
+
+/// Trait that provides typedef 'type' iff VIEW is a valid const view.
+
+template <typename> struct Is_const_view_type
+{ static bool const value = false;};
+
 } // impl
 
 template <typename T = VSIP_DEFAULT_VALUE_TYPE,
Index: src/vsip/impl/working-view.hpp
===================================================================
RCS file: src/vsip/impl/working-view.hpp
diff -N src/vsip/impl/working-view.hpp
--- /dev/null	1 Jan 1970 00:00:00 -0000
+++ src/vsip/impl/working-view.hpp	11 Jan 2006 15:58:53 -0000
@@ -0,0 +1,282 @@
+/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/impl/working-view.hpp
+    @author  Jules Bergmann
+    @date    2005-12-27
+    @brief   VSIPL++ Library: Utilities for local working views.
+
+    Used for working with distributed data by replicating a copy locally
+    to each processor.
+     - Assign_local() transfers data between local and distributed views.
+     - Working_view_holder creates a local working view of an argument,
+       either replicating a distributed view to a local copy, or aliasing
+       a local view.
+*/
+
+#ifndef VSIP_IMPL_WORKING_VIEW_HPP
+#define VSIP_IMPL_WORKING_VIEW_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/support.hpp>
+#include <vsip/vector.hpp>
+#include <vsip/matrix.hpp>
+#include <vsip/impl/par-services.hpp>
+#include <vsip/impl/distributed-block.hpp>
+#include <vsip/impl/static_assert.hpp>
+#include <vsip/impl/metaprogramming.hpp>
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+namespace vsip
+{
+
+namespace impl
+{
+
+// Create a new view of type 'ViewT' that has the same dimensions as the
+// existing view.
+
+template <typename ViewT,
+	  typename T,
+	  typename Block>
+ViewT
+clone_view(const_Vector<T, Block> view)
+{
+  ViewT ret(view.size(0));
+  return ret;
+}
+
+template <typename ViewT,
+	  typename T,
+	  typename Block>
+ViewT
+clone_view(const_Matrix<T, Block> view)
+{
+  ViewT ret(view.size(0), view.size(1));
+  return ret;
+}
+
+template <typename ViewT,
+	  typename T,
+	  typename Block>
+ViewT
+clone_view(const_Tensor<T, Block> view)
+{
+  ViewT ret(view.size(0), view.size(1), view.size(2));
+  return ret;
+}
+
+
+
+// Helper class for assigning between local and distributed views.
+
+template <typename View1,
+	  typename View2,
+	  bool     IsLocal1
+	           = Is_local_map<typename View1::block_type::map_type>::value,
+	  bool     IsLocal2
+	           = Is_local_map<typename View2::block_type::map_type>::value>
+struct Assign_local {};
+
+template <typename View1,
+	  typename View2>
+struct Assign_local<View1, View2, true, true>
+{
+  static void exec(View1 dst, View2 src)
+  {
+    dst = src;
+  }
+};
+
+template <typename View1,
+	  typename View2>
+struct Assign_local<View1, View2, true, false>
+{
+  static void exec(View1 dst, View2 src)
+  {
+    dimension_type const dim = View1::dim;
+
+    typedef typename View1::value_type                     T;
+    typedef typename View1::block_type                     block1_type;
+    typedef Global_map<dim>                                map_type;
+    typedef typename Block_layout<block1_type>::order_type order_type;
+    typedef Dense<dim, T, order_type, map_type>            block_type;
+    typedef typename View_of_dim<dim, T, block_type>::type view_type;
+
+    view_type view(clone_view<view_type>(dst));
+
+    view = src;
+    dst  = view.local();
+  }
+};
+
+template <typename View1,
+	  typename View2>
+struct Assign_local<View1, View2, false, true>
+{
+  static void exec(View1 dst, View2 src)
+  {
+    dimension_type const dim = View1::dim;
+
+    typedef typename View1::value_type                     T;
+    typedef typename View1::block_type                     block2_type;
+    typedef Global_map<dim>                                map_type;
+    typedef typename Block_layout<block2_type>::order_type order_type;
+    typedef Dense<dim, T, order_type, map_type>            block_type;
+    typedef typename View_of_dim<dim, T, block_type>::type view_type;
+
+    view_type view(clone_view<view_type>(dst));
+
+    view.local() = src;
+    dst          = view;
+  }
+};
+
+
+
+/// Assign between local and distributed views.
+
+template <typename ViewT1,
+	  typename ViewT2>
+void assign_local(
+  ViewT1 dst,
+  ViewT2 src)
+{
+  VSIP_IMPL_STATIC_ASSERT((Is_view_type<ViewT1>::value));
+  VSIP_IMPL_STATIC_ASSERT((Is_view_type<ViewT2>::value));
+  VSIP_IMPL_STATIC_ASSERT(ViewT1::dim == ViewT2::dim);
+
+  Assign_local<ViewT1, ViewT2>
+    ::exec(dst, src);
+}
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+template <typename ViewT,
+	  typename MapT = typename ViewT::block_type::map_type>
+struct As_local_view
+{
+  static bool const is_copy = true;
+  static dimension_type const dim = ViewT::dim;
+
+  typedef typename ViewT::value_type                    value_type;
+  typedef typename ViewT::block_type                    block_type;
+  typedef typename Block_layout<block_type>::order_type order_type;
+
+  typedef Dense<dim, value_type, order_type, Local_map> r_block_type;
+
+  typedef typename 
+    ITE_Type<Is_const_view_type<ViewT>::value,
+      As_type<typename View_of_dim<dim, value_type, r_block_type>::type>,
+      As_type<typename View_of_dim<dim, value_type, r_block_type>::const_type>
+      >::type type;
+
+  static type exec(ViewT view)
+  {
+    // The internal view needs to be non-const, even if the function
+    // return type is const.
+    typedef typename
+      View_of_dim<dim, value_type, r_block_type>::type view_type;
+
+    view_type ret(clone_view<view_type>(view));
+    assign_local(ret, view);
+    return ret;
+  }
+};
+
+template <typename ViewT>
+struct As_local_view<ViewT, Local_map>
+{
+  static bool const is_copy = false;
+  typedef ViewT type;
+
+  static type exec(ViewT view) { return view; }
+};
+
+
+
+template <typename       ViewT,
+	  dimension_type Dim>
+struct As_local_view<ViewT, Global_map<Dim> >
+{
+  static bool const is_copy = false;
+  typedef typename ViewT::local_type type;
+
+  static type exec(ViewT view) { return view.local(); }
+};
+
+
+
+template <template <typename, typename> class ViewT,
+	  typename                            T,
+	  typename                            Block>
+typename As_local_view<ViewT<T, Block> >::type
+convert_to_local(ViewT<T, Block> view)
+{
+  return As_local_view<ViewT<T, Block> >::exec(view);
+}
+
+
+template <typename ViewT,
+	  bool     is_const = Is_const_view_type<ViewT>::value>
+struct Working_view_holder
+{
+public:
+  typedef typename As_local_view<ViewT>::type type;
+
+public:
+  Working_view_holder(ViewT v)
+    : orig_view(v), view(convert_to_local(v))
+  {}
+
+  ~Working_view_holder()
+  {
+    if (As_local_view<ViewT>::is_copy)
+    {
+      assign_local(orig_view, view);
+    }
+  }
+
+  // Member data.  This is intentionally public.
+private:
+  ViewT orig_view;
+
+public:
+  type  view;
+};
+
+
+
+template <typename ViewT>
+struct Working_view_holder<ViewT, true>
+{
+public:
+  typedef typename As_local_view<ViewT>::type type;
+
+public:
+  Working_view_holder(ViewT v)
+    : view(convert_to_local(v))
+  {}
+
+  ~Working_view_holder() {}
+
+  // Member data.  This is intentionally public.
+public:
+  type  view;
+};
+
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_IMPL_WORKING_VIEW_HPP
Index: tests/convolution.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/convolution.cpp,v
retrieving revision 1.8
diff -u -r1.8 convolution.cpp
--- tests/convolution.cpp	20 Dec 2005 12:48:40 -0000	1.8
+++ tests/convolution.cpp	11 Jan 2006 15:58:53 -0000
@@ -10,11 +10,22 @@
   Included Files
 ***********************************************************************/
 
+#define VERBOSE 0
+
 #include <vsip/vector.hpp>
 #include <vsip/signal.hpp>
+#include <vsip/initfin.hpp>
 #include <vsip/random.hpp>
+#include <vsip/parallel.hpp>
 
 #include "test.hpp"
+#include "ref_conv.hpp"
+#include "error_db.hpp"
+
+#if VERBOSE
+#  include <iostream>
+#  include "output.hpp"
+#endif
 
 using namespace std;
 using namespace vsip;
@@ -25,7 +36,22 @@
   Definitions
 ***********************************************************************/
 
-length_type expected_output_size(
+length_type
+expected_kernel_size(
+  vsip::symmetry_type symmetry,
+  vsip::length_type   coeff_size)
+{
+  if (symmetry == vsip::nonsym)
+    return coeff_size;
+  else if (symmetry == vsip::sym_even_len_odd)
+    return 2*coeff_size-1;
+  else /* (symmetry == vsip::sym_even_len_even) */
+    return 2*coeff_size;
+}
+		     
+
+length_type
+expected_output_size(
   support_region_type supp,
   length_type         M,    // kernel length
   length_type         N,    // input  length
@@ -47,7 +73,8 @@
 
 
 
-length_type expected_shift(
+length_type
+expected_shift(
   support_region_type supp,
   length_type         M,     // kernel length
   length_type         /*D*/) // decimation factor
@@ -131,6 +158,71 @@
 
 
 
+/// Test general 1-D convolution.
+
+template <symmetry_type       symmetry,
+	  support_region_type support,
+	  typename            T,
+	  typename            Block1,
+	  typename            Block2,
+	  typename            Block3>
+void
+test_conv_base(
+  Vector<T, Block1>        in,
+  Vector<T, Block2>        out,
+  const_Vector<T, Block3>  coeff,	// coefficients
+  length_type              D,		// decimation
+  length_type const        n_loop = 2)
+{
+  typedef Convolution<const_Vector, symmetry, support, T> conv_type;
+
+  length_type M = expected_kernel_size(symmetry, coeff.size());
+  length_type N = in.size();
+  length_type P = out.size();
+
+  length_type expected_P = expected_output_size(support, M, N, D);
+
+  test_assert(P == expected_P);
+
+  conv_type conv(coeff, Domain<1>(N), D);
+
+  test_assert(conv.symmetry() == symmetry);
+  test_assert(conv.support()  == support);
+
+  test_assert(conv.kernel_size().size()  == M);
+  test_assert(conv.filter_order().size() == M);
+  test_assert(conv.input_size().size()   == N);
+  test_assert(conv.output_size().size()  == P);
+
+  Vector<T> exp(P);
+
+  for (index_type loop=0; loop<n_loop; ++loop)
+  {
+    for (index_type i=0; i<N; ++i)
+      in(i) = T(3*loop+i);
+
+    conv(in, out);
+
+    ref::conv(symmetry, support, coeff, in, exp, D);
+
+    // Check result
+    double error = error_db(out, exp);
+
+#if VERBOSE
+    if (error > -120)
+    {
+      cout << "exp = \n" << exp;
+      cout << "out = \n" << out;
+      cout << "diff = \n" << mag(exp-out);
+    }
+#endif
+
+    test_assert(error < -120);
+  }
+}
+
+
+
 /// Test convolution for non-unit strides.
 
 template <typename            T,
@@ -144,7 +236,6 @@
   symmetry_type const         symmetry = nonsym;
   length_type const           D = 1; // decimation
 
-  typedef Convolution<const_Vector, symmetry, support, T> conv_type;
   typedef typename Vector<T>::subview_type vector_subview_type;
 
   length_type const P = expected_output_size(support, M, N, D);
@@ -154,53 +245,13 @@
   Rand<T> rgen(0);
   kernel = rgen.randu(M);
 
-  conv_type conv(kernel, Domain<1>(N), D);
-
-  test_assert(conv.symmetry() == symmetry);
-  test_assert(conv.support()  == support);
-
-  test_assert(conv.kernel_size().size()  == M);
-  test_assert(conv.filter_order().size() == M);
-  test_assert(conv.input_size().size()   == N);
-  test_assert(conv.output_size().size()  == P);
-
-
   Vector<T> in_base(N * stride);
   Vector<T> out_base(P * stride, T(100));
 
   vector_subview_type  in =  in_base( Domain<1>(0, stride, N) );
   vector_subview_type out = out_base( Domain<1>(0, stride, P) );
 
-  for (index_type i=0; i<N; ++i)
-    in(i) = T(i);
-
-  conv(in, out);
-
-
-  int shift = expected_shift(support, M, D);
-  Vector<T> sub(M);
-
-  // Check result
-  for (index_type i=0; i<P; ++i)
-  {
-    sub = T();
-    index_type pos = i*D + shift;
-
-    if (pos+1 < M)
-      sub(Domain<1>(0, 1, pos+1)) = in(Domain<1>(pos, -1, pos+1));
-    else if (pos >= N)
-    {
-      index_type start = pos - N + 1;
-      sub(Domain<1>(start, 1, M-start)) = in(Domain<1>(N-1, -1, M-start));
-    }
-    else
-      sub = in(Domain<1>(pos, -1, M));
-      
-    T val = out(i);
-    T chk = dot(kernel, sub);
-
-    test_assert(equal(val, chk));
-  }
+  test_conv_base<symmetry, support>(in, out, kernel, D, 1);
 }
 
 
@@ -219,84 +270,45 @@
   const_Vector<T1, Block1> coeff,	// coefficients
   length_type const        n_loop = 2)
 {
-  typedef Convolution<const_Vector, symmetry, support, T> conv_type;
-
-  length_type M2 = coeff.size();
-  length_type M;
-
-  if (symmetry == nonsym)
-    M = coeff.size();
-  else if (symmetry == sym_even_len_odd)
-    M = 2*coeff.size()-1;
-  else /* (symmetry == sym_even_len_even) */
-    M = 2*coeff.size();
-
-  length_type const P = expected_output_size(support, M, N, D);
-
-  int shift = expected_shift(support, M, D);
-
-  Vector<T> kernel(M, T());
-
-  if (symmetry == nonsym)
-  {
-    kernel = coeff;
-  }
-  else if (symmetry == sym_even_len_odd)
-  {
-    kernel(Domain<1>(0,  1, M2))   = coeff;
-    kernel(Domain<1>(M2, 1, M2-1)) = coeff(Domain<1>(M2-2, -1, M2-1));
-  }
-  else /* (symmetry == sym_even_len_even) */
-  {
-    kernel(Domain<1>(0,  1, M2)) = coeff;
-    kernel(Domain<1>(M2, 1, M2)) = coeff(Domain<1>(M2-1, -1, M2));
-  }
+  length_type M = expected_kernel_size(symmetry, coeff.size());
+  length_type P = expected_output_size(support, M, N, D);
 
+  Vector<T> in(N);
+  Vector<T> out(P, T(100));
 
-  conv_type conv(coeff, Domain<1>(N), D);
+  test_conv_base<symmetry, support>(in, out, coeff, D, n_loop);
+}
 
-  test_assert(conv.symmetry() == symmetry);
-  test_assert(conv.support()  == support);
 
-  test_assert(conv.kernel_size().size()  == M);
-  test_assert(conv.filter_order().size() == M);
-  test_assert(conv.input_size().size()   == N);
-  test_assert(conv.output_size().size()  == P);
 
+/// Test general 1-D convolution, with distributed arguments.
 
-  Vector<T> in(N);
-  Vector<T> out(P, T(100));
-  Vector<T> sub(M);
+template <typename            T,
+	  symmetry_type       symmetry,
+	  support_region_type support,
+	  typename            MapT>
+void
+test_conv_dist(
+  length_type              N,		// input size
+  length_type              M,		// coeff size
+  length_type              D,		// decimation
+  length_type const        n_loop = 2)
+{
+  length_type const P = expected_output_size(support, M, N, D);
 
-  for (index_type loop=0; loop<n_loop; ++loop)
-  {
-    for (index_type i=0; i<N; ++i)
-      in(i) = T(3*loop+i);
+  typedef Dense<1, T, row1_type, MapT> block_type;
+  typedef Vector<T, block_type>        view_type;
 
-    conv(in, out);
+  MapT map(num_processors());
 
-    // Check result
-    for (index_type i=0; i<P; ++i)
-    {
-      sub = T();
-      index_type pos = i*D + shift;
+  view_type coeff(M, map);
+  view_type in(N, map);
+  view_type out(P, T(100), map);
 
-      if (pos+1 < M)
-	sub(Domain<1>(0, 1, pos+1)) = in(Domain<1>(pos, -1, pos+1));
-      else if (pos >= N)
-      {
-	index_type start = pos - N + 1;
-	sub(Domain<1>(start, 1, M-start)) = in(Domain<1>(N-1, -1, M-start));
-      }
-      else
-	sub = in(Domain<1>(pos, -1, M));
-      
-      T val = out(i);
-      T chk = dot(kernel, sub);
+  Rand<T> rgen(0);
+  impl::assign_local(coeff, rgen.randu(M));
 
-      test_assert(equal(val, chk));
-    }
-  }
+  test_conv_base<symmetry, support>(in, out, coeff, D, n_loop);
 }
 
 
@@ -367,6 +379,24 @@
 
 
 
+// Run a set of convolutions for given type, symmetry, input size, coeff size
+// and decmiation, using distributed arugments.
+
+template <typename      T>
+void
+cases_conv_dist(length_type size, length_type M, length_type D)
+{
+  symmetry_type const sym = nonsym;
+
+  typedef Map<Block_dist> map_type;
+
+  test_conv_dist<T, sym, support_min, map_type> (size, M, D);
+  test_conv_dist<T, sym, support_same, map_type>(size, M, D);
+  test_conv_dist<T, sym, support_full, map_type>(size, M, D);
+}
+
+
+
 // Run a single convolutions for given type, symmetry, support, input
 // size, coeff size and decmiation.
 
@@ -433,8 +463,26 @@
 
 
 int
-main()
+main(int argc, char** argv)
 {
+  vsipl init(argc, argv);
+
+#if 0
+  // Enable this section for easier debugging.
+  impl::Communicator comm = impl::default_communicator();
+  pid_t pid = getpid();
+
+  cout << "rank: "   << comm.rank()
+       << "  size: " << comm.size()
+       << "  pid: "  << pid
+       << endl;
+
+  // Stop each process, allow debugger to be attached.
+  if (comm.rank() == 0) fgetc(stdin);
+  comm.barrier();
+  cout << "start\n";
+#endif
+
   // Regression: These cases trigger undefined behavior according to
   // the C-VSIPL spec defn of output length for minimum output size.
   single_conv<float, sym_even_len_even, support_min>(33, 6, 2, 1, false);
@@ -445,7 +493,12 @@
   cases<int>(rand);
   cases<float>(rand);
   cases<double>(rand);
-  cases<complex<int> >(rand);
+  // cases<complex<int> >(rand);
   cases<complex<float> >(rand);
   cases<complex<double> >(rand);
+
+  // Test distributed arguments.
+  cases_conv_dist<float>(32, 8, 1);
+
+  return 0;
 }
Index: tests/distributed-getput.cpp
===================================================================
RCS file: tests/distributed-getput.cpp
diff -N tests/distributed-getput.cpp
--- /dev/null	1 Jan 1970 00:00:00 -0000
+++ tests/distributed-getput.cpp	11 Jan 2006 15:58:53 -0000
@@ -0,0 +1,160 @@
+/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    tests/distributed-getput.cpp
+    @author  Jules Bergmann
+    @date    2005-12-24
+    @brief   VSIPL++ Library: Unit tests for distributed blocks.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/map.hpp>
+#include <vsip/tensor.hpp>
+#include <vsip/parallel.hpp>
+
+#include "test.hpp"
+#include "output.hpp"
+#include "util.hpp"
+#include "util-par.hpp"
+
+using namespace std;
+using namespace vsip;
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+template <typename T>
+void
+test_getput(length_type size)
+{
+  typedef Map<Block_dist>                  map_type;
+  typedef Dense<1, T, row1_type, map_type> block_type;
+  typedef Vector<T, block_type>            view_type;
+
+  map_type    map(num_processors());
+  view_type   view(size, T(), map);
+
+  for (index_type i=0; i<size; ++i)
+  {
+    view.put(i, T(i));
+  }
+
+  for (index_type i=0; i<size; ++i)
+  {
+    test_assert(equal(view.get(i), T(i)));
+  }
+}
+
+
+
+template <typename T,
+	  typename MapT>
+void
+test_getput(length_type rows, length_type cols)
+{
+  typedef Dense<2, T, row2_type, MapT> block_type;
+  typedef Matrix<T, block_type>        view_type;
+
+  MapT      map(num_processors(), 1);
+  view_type view(rows, cols, T(), map);
+
+  for (index_type r=0; r<rows; ++r)
+    for (index_type c=0; c<cols; ++c)
+      view.put(r, c, T(r*cols+c));
+
+  for (index_type r=0; r<rows; ++r)
+    for (index_type c=0; c<cols; ++c)
+      test_assert(equal(view.get(r, c), T(r*cols+c)));
+}
+
+
+
+template <typename T,
+	  typename MapT>
+void
+test_getput(length_type len0, length_type len1, length_type len2)
+{
+  typedef Dense<3, T, row3_type, MapT> block_type;
+  typedef Tensor<T, block_type>        view_type;
+
+  MapT      map(num_processors(), 1);
+  view_type view(len0, len1, len2, T(), map);
+
+  for (index_type i=0; i<len0; ++i)
+    for (index_type j=0; j<len1; ++j)
+      for (index_type k=0; k<len2; ++k)
+	view.put(i, j, k, T(i*len1*len2 + j*len2 + k));
+
+  for (index_type i=0; i<len0; ++i)
+    for (index_type j=0; j<len1; ++j)
+      for (index_type k=0; k<len2; ++k)
+	test_assert(equal(view.get(i, j, k), T(i*len1*len2 + j*len2 + k)));
+}
+
+
+
+/// Test assign_local
+
+template <typename T,
+	  typename MapT>
+void
+test_assign_local(length_type rows, length_type cols)
+{
+  typedef Dense<2, T, row2_type, MapT> block_type;
+  typedef Matrix<T, block_type>        view_type;
+
+  MapT      map(num_processors(), 1);
+  view_type g1_view(rows, cols, T(0), map);
+  view_type g2_view(rows, cols, T(0), map);
+  Matrix<T> l_view(rows, cols, T(0));
+
+  for (index_type r=0; r<rows; ++r)
+    for (index_type c=0; c<cols; ++c)
+      g1_view.put(r, c, T(r*cols+c));
+
+  assign_local(l_view,  g1_view);
+  assign_local(g2_view, l_view);
+
+  for (index_type r=0; r<rows; ++r)
+    for (index_type c=0; c<cols; ++c)
+      test_assert(equal(g2_view.get(r, c), T(r*cols+c)));
+}
+
+
+
+
+int
+main(int argc, char** argv)
+{
+  vsipl vpp(argc, argv);
+
+#if 0
+  // Enable this section for easier debugging.
+  impl::Communicator comm = impl::default_communicator();
+  pid_t pid = getpid();
+
+  cout << "rank: "   << comm.rank()
+       << "  size: " << comm.size()
+       << "  pid: "  << pid
+       << endl;
+
+  // Stop each process, allow debugger to be attached.
+  if (comm.rank() == 0) fgetc(stdin);
+  comm.barrier();
+  cout << "start\n";
+#endif
+
+  test_getput<float>(8);
+  test_getput<float, Map<Block_dist, Block_dist> >(5, 7);
+  test_getput<float, Map<Block_dist, Block_dist, Block_dist> >(5, 7, 3);
+  test_assign_local<float, Map<Block_dist, Block_dist> >(5, 7);
+
+  return 0;
+}
Index: tests/expression.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/expression.cpp,v
retrieving revision 1.7
diff -u -r1.7 expression.cpp
--- tests/expression.cpp	20 Dec 2005 12:48:40 -0000	1.7
+++ tests/expression.cpp	11 Jan 2006 15:58:53 -0000
@@ -14,6 +14,7 @@
 
 #include <vsip/math.hpp>
 #include <vsip/dense.hpp>
+#include <vsip/map.hpp>
 #include "test.hpp"
 #include "block_interface.hpp"
 
Index: tests/par_expr.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/par_expr.cpp,v
retrieving revision 1.10
diff -u -r1.10 par_expr.cpp
--- tests/par_expr.cpp	20 Dec 2005 12:48:41 -0000	1.10
+++ tests/par_expr.cpp	11 Jan 2006 15:58:53 -0000
@@ -151,6 +151,9 @@
   view_res_t Z2(create_view<view_res_t>(dom, T(0), map_res));
   view_res_t Z3(create_view<view_res_t>(dom, T(0), map_res));
   view_res_t Z4(create_view<view_res_t>(dom, T(0), map_res));
+  view_res_t Z5(create_view<view_res_t>(dom, T(0), map_res));
+  view_res_t Z6(create_view<view_res_t>(dom, T(0), map_res));
+  view_res_t Z7(create_view<view_res_t>(dom, T(0), map_res));
   view_op1_t A(create_view<view_op1_t>(dom, T(3), map_op1));
   view_op2_t B(create_view<view_op2_t>(dom, T(4), map_op2));
 
@@ -170,6 +173,9 @@
     Z2 = B - A;
     Z3 = -A;
     Z4 = -(A - B);
+    Z5 = T(2) + A;
+    Z6 = A + T(2);
+    Z7 = T(2) * A + T(1) + B;
 
     // Calls:
     //    vsip::impl::par_expr(Z, A + B);
@@ -198,6 +204,15 @@
   foreach_point(Z3, checker3);
   test_assert(checker3.good());
 
+  Check_identity<Dim> checker4(dom, 2, 3);
+  foreach_point(Z5, checker4);
+  foreach_point(Z6, checker4);
+  test_assert(checker4.good());
+
+  Check_identity<Dim> checker5(dom, 2*2+3, 2*1+1+2);
+  foreach_point(Z7, checker5);
+  test_assert(checker5.good());
+
   if (map_res.impl_rank() == 0) // rank(map_res) == 0
   {
     typename view0_t::local_type local_view = chk1.local();
Index: tests/reductions.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/reductions.cpp,v
retrieving revision 1.4
diff -u -r1.4 reductions.cpp
--- tests/reductions.cpp	20 Dec 2005 12:48:41 -0000	1.4
+++ tests/reductions.cpp	11 Jan 2006 15:58:53 -0000
@@ -14,6 +14,8 @@
 #include <vsip/initfin.hpp>
 #include <vsip/support.hpp>
 #include <vsip/math.hpp>
+#include <vsip/map.hpp>
+#include <vsip/parallel.hpp>
 
 #include "test.hpp"
 #include "test-storage.hpp"
@@ -88,36 +90,51 @@
   sumval tests.
 ***********************************************************************/
 
-template <typename       StoreT,
-	  dimension_type Dim>
+template <typename ViewT>
 void
-test_sumval(Domain<Dim> const& dom, length_type count)
+view_sumval(
+  ViewT       view,
+  length_type count)
 {
-  typedef typename StoreT::value_type T;
+  typedef typename ViewT::value_type T;
 
-  StoreT      store(dom, T());
-  length_type size = store.view.size();
+  view = T();
 
   index_type  i        = 0;
   T           expected = T();
+  length_type size     = view.size();
   
   for (index_type c=0; c<count; ++c)
   {
     i      = (2*i+3) % size;
     T nval = T(i) - T(5);
 
-    expected -= get_nth(store.view, i);
+    expected -= get_nth(view, i);
     expected += nval;
 
-    put_nth(store.view, i, nval);
+    put_nth(view, i, nval);
     
-    T val = sumval(store.view);
+    T val = sumval(view);
     test_assert(equal(val, expected));
   }
 }
 
 
 
+template <typename       StoreT,
+	  dimension_type Dim>
+void
+test_sumval(Domain<Dim> const& dom, length_type count)
+{
+  typedef typename StoreT::value_type T;
+
+  StoreT      store(dom, T());
+
+  view_sumval(store.view, count);
+}
+
+
+
 template <typename T>
 void
 cover_sumval()
@@ -133,6 +150,26 @@
   test_sumval<Storage<3, T, tuple<1, 2, 0> > >(Domain<3>(15, 17, 7), 8);
   test_sumval<Storage<3, T, tuple<2, 0, 1> > >(Domain<3>(15, 17, 7), 8);
   test_sumval<Storage<3, T, tuple<2, 1, 0> > >(Domain<3>(15, 17, 7), 8);
+
+  test_sumval<Storage<1, T, row1_type, Map<Block_dist> > >(Domain<1>(15), 8);
+}
+
+
+
+template <typename T,
+	  typename MapT>
+void
+par_cover_sumval()
+{
+  typedef Dense<1, T, row1_type, MapT> block_type;
+  typedef Vector<T, block_type>        view_type;
+
+  length_type size = 8;
+
+  MapT      map = create_map<1, MapT>();
+  view_type view(size, map);
+
+  view_sumval(view, 8);
 }
 
 
@@ -188,6 +225,8 @@
   test_sumval_bool<Storage<3, T, tuple<1, 2, 0> > >(Domain<3>(15, 17, 7), 8);
   test_sumval_bool<Storage<3, T, tuple<2, 0, 1> > >(Domain<3>(15, 17, 7), 8);
   test_sumval_bool<Storage<3, T, tuple<2, 1, 0> > >(Domain<3>(15, 17, 7), 8);
+
+  test_sumval_bool<Storage<1, T, row1_type, Map<Block_dist> > >(Domain<1>(15), 8);
 }
 
 
@@ -244,6 +283,8 @@
   test_sumsqval<Storage<3, T, tuple<1, 2, 0> > >(Domain<3>(15, 17, 7), 8);
   test_sumsqval<Storage<3, T, tuple<2, 0, 1> > >(Domain<3>(15, 17, 7), 8);
   test_sumsqval<Storage<3, T, tuple<2, 1, 0> > >(Domain<3>(15, 17, 7), 8);
+
+  test_sumsqval<Storage<1, T, row1_type, Map<Block_dist> > >(Domain<1>(15), 8);
 }
 
 
@@ -299,6 +340,8 @@
   test_meanval<Storage<3, T, tuple<1, 2, 0> > >(Domain<3>(15, 17, 7), 8);
   test_meanval<Storage<3, T, tuple<2, 0, 1> > >(Domain<3>(15, 17, 7), 8);
   test_meanval<Storage<3, T, tuple<2, 1, 0> > >(Domain<3>(15, 17, 7), 8);
+
+  test_meanval<Storage<1, T, row1_type, Map<Block_dist> > >(Domain<1>(15), 8);
 }
 
 
@@ -355,6 +398,8 @@
   test_meansqval<Storage<3, T, tuple<1, 2, 0> > >(Domain<3>(15, 17, 7), 8);
   test_meansqval<Storage<3, T, tuple<2, 0, 1> > >(Domain<3>(15, 17, 7), 8);
   test_meansqval<Storage<3, T, tuple<2, 1, 0> > >(Domain<3>(15, 17, 7), 8);
+
+  test_meansqval<Storage<1, T, row1_type, Map<Block_dist> > >(Domain<1>(15), 8);
 }
 
 
@@ -366,6 +411,9 @@
    
   simple_tests();
 
+  par_cover_sumval<float, Global_map<1> >();
+  par_cover_sumval<float, Map<Block_dist> >();
+
   cover_sumval<int>();
   cover_sumval<float>();
   cover_sumval<double>();
Index: tests/ref_conv.hpp
===================================================================
RCS file: tests/ref_conv.hpp
diff -N tests/ref_conv.hpp
--- /dev/null	1 Jan 1970 00:00:00 -0000
+++ tests/ref_conv.hpp	11 Jan 2006 15:58:53 -0000
@@ -0,0 +1,172 @@
+/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    ref_conv.cpp
+    @author  Jules Bergmann
+    @date    2005-12-28
+    @brief   VSIPL++ Library: Reference implementation of convolution
+*/
+
+#ifndef VSIP_REF_CORR_HPP
+#define VSIP_REF_CORR_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/vector.hpp>
+#include <vsip/signal.hpp>
+#include <vsip/random.hpp>
+#include <vsip/selgen.hpp>
+#include <vsip/parallel.hpp>
+
+namespace ref
+{
+
+vsip::length_type
+conv_output_size(
+  vsip::support_region_type supp,
+  vsip::length_type         M,    // kernel length
+  vsip::length_type         N,    // input  length
+  vsip::length_type         D)    // decimation factor
+{
+  if      (supp == vsip::support_full)
+    return ((N + M - 2)/D) + 1;
+  else if (supp == vsip::support_same)
+    return ((N - 1)/D) + 1;
+  else //(supp == vsip::support_min)
+  {
+#if VSIP_IMPL_CONV_CORRECT_MIN_SUPPORT_SIZE
+    return ((N - M + 1) / D) + ((N - M + 1) % D == 0 ? 0 : 1);
+#else
+    return ((N - 1)/D) - ((M-1)/D) + 1;
+#endif
+  }
+}
+
+
+
+vsip::stride_type
+conv_expected_shift(
+  vsip::support_region_type supp,
+  vsip::length_type         M)     // kernel length
+{
+  if      (supp == vsip::support_full)
+    return 0;
+  else if (supp == vsip::support_same)
+    return (M/2);
+  else //(supp == vsip::support_min)
+    return (M-1);
+}
+
+
+
+/// Generate full convolution kernel from coefficients.
+
+template <typename T,
+	  typename Block>
+vsip::Vector<T>
+kernel_from_coeff(
+  vsip::symmetry_type          symmetry,
+  vsip::const_Vector<T, Block> coeff)
+{
+  using vsip::Domain;
+  using vsip::length_type;
+
+  length_type M2 = coeff.size();
+  length_type M;
+
+  if (symmetry == vsip::nonsym)
+    M = coeff.size();
+  else if (symmetry == vsip::sym_even_len_odd)
+    M = 2*coeff.size()-1;
+  else /* (symmetry == vsip::sym_even_len_even) */
+    M = 2*coeff.size();
+
+  vsip::Vector<T> kernel(M, T());
+
+  if (symmetry == vsip::nonsym)
+  {
+    kernel = coeff;
+  }
+  else if (symmetry == vsip::sym_even_len_odd)
+  {
+    kernel(Domain<1>(0,  1, M2))   = coeff;
+    kernel(Domain<1>(M2, 1, M2-1)) = coeff(Domain<1>(M2-2, -1, M2-1));
+  }
+  else /* (symmetry == sym_even_len_even) */
+  {
+    kernel(Domain<1>(0,  1, M2)) = coeff;
+    kernel(Domain<1>(M2, 1, M2)) = coeff(Domain<1>(M2-1, -1, M2));
+  }
+
+  return kernel;
+}
+
+
+
+template <typename T,
+	  typename Block1,
+	  typename Block2,
+	  typename Block3>
+void
+conv(
+  vsip::symmetry_type           sym,
+  vsip::support_region_type     sup,
+  vsip::const_Vector<T, Block1> coeff,
+  vsip::const_Vector<T, Block2> in,
+  vsip::Vector<T, Block3>       out,
+  vsip::length_type             D)
+{
+  using vsip::index_type;
+  using vsip::length_type;
+  using vsip::stride_type;
+  using vsip::Vector;
+  using vsip::const_Vector;
+  using vsip::Domain;
+  using vsip::unbiased;
+
+  using vsip::impl::convert_to_local;
+  using vsip::impl::Working_view_holder;
+
+  typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
+
+  Working_view_holder<const_Vector<T, Block1> > w_coeff(coeff);
+  Working_view_holder<const_Vector<T, Block2> > w_in(in);
+  Working_view_holder<Vector<T, Block3> >       w_out(out);
+
+  Vector<T> kernel = kernel_from_coeff(sym, w_coeff.view);
+
+  length_type M = kernel.size(0);
+  length_type N = in.size(0);
+  length_type P = out.size(0);
+
+  length_type expected_P = conv_output_size(sup, M, N, D);
+  stride_type shift      = conv_expected_shift(sup, M);
+
+  assert(expected_P == P);
+
+  Vector<T> sub(M);
+
+  // Check result
+  for (index_type i=0; i<P; ++i)
+  {
+    sub = T();
+    index_type pos = i*D + shift;
+
+    if (pos+1 < M)
+      sub(Domain<1>(0, 1, pos+1)) = w_in.view(Domain<1>(pos, -1, pos+1));
+    else if (pos >= N)
+    {
+      index_type start = pos - N + 1;
+      sub(Domain<1>(start, 1, M-start)) = w_in.view(Domain<1>(N-1, -1, M-start));
+    }
+    else
+      sub = w_in.view(Domain<1>(pos, -1, M));
+      
+    w_out.view(i) = dot(kernel, sub);
+  }
+}
+
+} // namespace ref
+
+#endif // VSIP_REF_CORR_HPP
Index: tests/solver-common.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/solver-common.hpp,v
retrieving revision 1.6
diff -u -r1.6 solver-common.hpp
--- tests/solver-common.hpp	20 Dec 2005 12:48:41 -0000	1.6
+++ tests/solver-common.hpp	11 Jan 2006 15:58:53 -0000
@@ -42,6 +42,21 @@
   return r;
 }
 
+template <typename T,
+	  typename BlockT>
+vsip::Vector<T, BlockT>
+test_ramp(
+  vsip::Vector<T, BlockT> view,
+  T                       a,
+  T                       b)
+VSIP_NOTHROW
+{
+  for (vsip::index_type i=0; i<view.size(); ++i)
+    view.put(i, a + T(i)*b);
+
+  return view;
+}
+
 template <typename T>
 struct Test_traits
 {
Index: tests/solver-lu.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/solver-lu.cpp,v
retrieving revision 1.2
diff -u -r1.2 solver-lu.cpp
--- tests/solver-lu.cpp	20 Dec 2005 12:48:41 -0000	1.2
+++ tests/solver-lu.cpp	11 Jan 2006 15:58:53 -0000
@@ -16,6 +16,8 @@
 #include <vsip/support.hpp>
 #include <vsip/tensor.hpp>
 #include <vsip/solvers.hpp>
+#include <vsip/map.hpp>
+#include <vsip/parallel.hpp>
 
 #include "test.hpp"
 #include "test-precision.hpp"
@@ -189,6 +191,132 @@
 
 
 
+template <typename MapT,
+	  typename T,
+	  typename Block1,
+	  typename Block2>
+void
+solve_lu_dist(
+  return_mechanism_type rtm,
+  Matrix<T, Block1>     a,
+  Matrix<T, Block2>     b)
+{
+  length_type n = a.size(0);
+  length_type p = b.size(1);
+
+  test_assert(n == a.size(1));
+  test_assert(n == b.size(0));
+
+  typedef Dense<2, T, row2_type, MapT> block_type;
+
+  Matrix<T, block_type> x1(n, p);
+  Matrix<T, block_type> x2(n, p);
+  Matrix<T, block_type> x3(n, p);
+
+  if (rtm == by_reference)
+  {
+    // 1. Build solver and factor A.
+    lud<T, by_reference> lu(n);
+    test_assert(lu.length() == n);
+
+    bool success = lu.decompose(a);
+    test_assert(success);
+
+    // 2. Solve A X = B.
+    lu.template solve<mat_ntrans>(b, x1);
+    lu.template solve<mat_trans>(b, x2);
+    lu.template solve<Test_traits<T>::trans>(b, x3); // mat_herm if T complex
+  }
+  if (rtm == by_value)
+  {
+    // 1. Build solver and factor A.
+    lud<T, by_value> lu(n);
+    test_assert(lu.length() == n);
+
+    bool success = lu.decompose(a);
+    test_assert(success);
+
+    // 2. Solve A X = B.
+    impl::assign_local(x1, lu.template solve<mat_ntrans>(b));
+    impl::assign_local(x2, lu.template solve<mat_trans>(b));
+    impl::assign_local(x3, lu.template solve<Test_traits<T>::trans>(b));
+  }
+
+
+  // 3. Check result.
+
+  Matrix<T> chk1(n, p);
+  Matrix<T> chk2(n, p);
+  Matrix<T> chk3(n, p);
+
+  prod(a, x1, chk1);
+  prod(trans(a), x2, chk2);
+  prod(trans_or_herm(a), x3, chk3);
+
+  typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
+
+  Vector<float> sv_s(n);
+  svd<T, by_reference> sv(n, n, svd_uvnos, svd_uvnos);
+  sv.decompose(a, sv_s);
+
+  scalar_type a_norm_2 = sv_s(0);
+
+
+  // Gaussian roundoff error (J.H Wilkinson)
+  // (From Moler, Chapter 2.9, p19)
+  //
+  //  || residual ||
+  // ----------------- <= p eps
+  // || A || || x_* ||
+  //
+  // Where 
+  //   x_* is computed solution (x is true solution)
+  //   residual = b - A x_*
+  //   eps is machine precision
+  //   p is usually less than 10
+
+  scalar_type eps     = Precision_traits<scalar_type>::eps;
+  scalar_type p_limit = scalar_type(20);
+
+  for (index_type i=0; i<p; ++i)
+  {
+    scalar_type residual_1 = norm_2((b - chk1).col(i));
+    scalar_type err1       = residual_1 / (a_norm_2 * norm_2(x1.col(i)) * eps);
+    scalar_type residual_2 = norm_2((b - chk2).col(i));
+    scalar_type err2       = residual_2 / (a_norm_2 * norm_2(x2.col(i)) * eps);
+    scalar_type residual_3 = norm_2((b - chk3).col(i));
+    scalar_type err3       = residual_3 / (a_norm_2 * norm_2(x3.col(i)) * eps);
+
+#if VERBOSE
+    scalar_type cond = sv_s(0) / sv_s(n-1);
+    cout << "err " << i << " = "
+	 << err1 << ", " << err2 << ", " << err3
+	 << "  cond = " << cond
+	 << endl;
+#endif
+
+    test_assert(err1 < p_limit);
+    test_assert(err2 < p_limit);
+    test_assert(err3 < p_limit);
+
+    if (err1 > max_err1) max_err1 = err1;
+    if (err2 > max_err2) max_err2 = err2;
+    if (err3 > max_err3) max_err3 = err3;
+  }
+
+#if VERBOSE
+  cout << "a = " << endl << a << endl;
+  cout << "x1 = " << endl << x1 << endl;
+  cout << "x2 = " << endl << x2 << endl;
+  cout << "b = " << endl << b << endl;
+  cout << "chk1 = " << endl << chk1 << endl;
+  cout << "chk2 = " << endl << chk2 << endl;
+  cout << "chk3 = " << endl << chk3 << endl;
+#endif
+}
+
+
+
 // Simple lud test w/diagonal matrix.
 
 template <typename T>
@@ -237,6 +365,32 @@
 
 
 
+// Chold test w/random matrix.
+
+template <typename T,
+	  typename MapA,
+	  typename MapB,
+	  typename MapT>
+void
+test_lud_dist(
+  return_mechanism_type rtm,
+  length_type           n,
+  length_type           p)
+{
+  typedef Dense<2, T, row2_type, MapA> a_block_type;
+  typedef Dense<2, T, row2_type, MapB> b_block_type;
+
+  Matrix<T, a_block_type> a(n, n);
+  Matrix<T, b_block_type> b(n, p);
+
+  randm(a);
+  randm(b);
+
+  solve_lu_dist<MapT>(rtm, a, b);
+}
+
+
+
 // Chold test w/matrix from file.
 
 template <typename FileT,
@@ -304,6 +458,20 @@
 
 
 
+template <typename T>
+void
+dist_lud_cases()
+{
+  typedef Map<Block_dist, Block_dist> map1_type;
+  typedef Map<Block_dist, Block_dist> map2_type;
+  typedef Map<Block_dist, Block_dist> map3_type;
+
+  test_lud_dist<T, map1_type, map2_type, map3_type>(by_reference, 5, 7);
+  test_lud_dist<T, map1_type, map2_type, map3_type>(by_value,     5, 7);
+}
+
+
+
 /***********************************************************************
   Main
 ***********************************************************************/
@@ -328,6 +496,7 @@
     "lu-a-complex-float-99x99.dat", "lu-b-complex-float-99x7.dat", 99, 7);
 #endif
 
+
   lud_cases<float>           (by_reference);
   lud_cases<double>          (by_reference);
   lud_cases<complex<float> > (by_reference);
@@ -338,9 +507,5 @@
   lud_cases<complex<float> > (by_value);
   lud_cases<complex<double> >(by_value);
 
-#if VERBOSE
-  cout << "max_err1 " << max_err1 << endl;
-  cout << "max_err2 " << max_err2 << endl;
-  cout << "max_err3 " << max_err3 << endl;
-#endif
+  dist_lud_cases<float>      ();
 }
Index: tests/solver-qr.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/solver-qr.cpp,v
retrieving revision 1.5
diff -u -r1.5 solver-qr.cpp
--- tests/solver-qr.cpp	20 Dec 2005 12:48:41 -0000	1.5
+++ tests/solver-qr.cpp	11 Jan 2006 15:58:53 -0000
@@ -16,10 +16,12 @@
 #include <vsip/support.hpp>
 #include <vsip/tensor.hpp>
 #include <vsip/solvers.hpp>
+#include <vsip/parallel.hpp>
 
 #include "test.hpp"
 #include "test-precision.hpp"
 #include "test-random.hpp"
+#include "test-storage.hpp"
 #include "solver-common.hpp"
 
 #define VERBOSE  0
@@ -71,7 +73,7 @@
   qr.decompose(a);
 
   for (index_type i=0; i<p; ++i)
-    b.col(i) = test_ramp(T(1), T(i), n);
+    test_ramp(b.col(i), T(1), T(i));
   if (p > 1)
     b.col(1) += Test_traits<T>::offset();
 
@@ -91,7 +93,8 @@
 
 
 
-template <typename T>
+template <typename T,
+	  typename MapT>
 void
 test_covsol_random(
   length_type m,
@@ -100,9 +103,13 @@
 {
   test_assert(m >= n);
 
-  Matrix<T> a(m, n);
-  Matrix<T> b(n, p);
-  Matrix<T> x(n, p);
+  typedef Dense<2, T, row2_type, MapT> block_type;
+
+  MapT map = create_map<2, MapT>();
+
+  Matrix<T, block_type> a(m, n, map);
+  Matrix<T, block_type> b(n, p, map);
+  Matrix<T, block_type> x(n, p, map);
 
   randm(a);
 
@@ -162,25 +169,25 @@
   test_covsol_diag<T>(5,   3, 3);
   test_covsol_diag<T>(17, 11, 3);
 
-  test_covsol_random<T>(1,   1, 2);
-  test_covsol_random<T>(5,   5, 2);
-  test_covsol_random<T>(17, 17, 2);
-
-  test_covsol_random<T>(1,   1, 3);
-  test_covsol_random<T>(5,   5, 3);
-  test_covsol_random<T>(17, 17, 3);
-
-  test_covsol_random<T>(3,   1, 3);
-  test_covsol_random<T>(5,   3, 3);
-  test_covsol_random<T>(17, 11, 3);
+  test_covsol_random<T, Local_map>(1,   1, 2);
+  test_covsol_random<T, Local_map>(5,   5, 2);
+  test_covsol_random<T, Local_map>(17, 17, 2);
+
+  test_covsol_random<T, Local_map>(1,   1, 3);
+  test_covsol_random<T, Local_map>(5,   5, 3);
+  test_covsol_random<T, Local_map>(17, 17, 3);
+
+  test_covsol_random<T, Local_map>(3,   1, 3);
+  test_covsol_random<T, Local_map>(5,   3, 3);
+  test_covsol_random<T, Local_map>(17, 11, 3);
 
 #if DO_SWEEP
   for (index_type i=1; i<100; i+= 8)
     for (index_type j=1; j<10; j += 4)
     {
-      test_covsol_random<T>(i,   i,   j+1);
-      test_covsol_random<T>(i+1, i+1, j);
-      test_covsol_random<T>(i+2, i+2, j+2);
+      test_covsol_random<T, Local_map>(i,   i,   j+1);
+      test_covsol_random<T, Local_map>(i+1, i+1, j);
+      test_covsol_random<T, Local_map>(i+2, i+2, j+2);
     }
 #endif
 }
@@ -219,7 +226,7 @@
   qr.decompose(a);
 
   for (index_type i=0; i<p; ++i)
-    b.col(i) = test_ramp(T(1), T(i), m);
+    test_ramp(b.col(i), T(1), T(i));
   if (p > 1)
     b.col(1) += Test_traits<T>::offset();
 
@@ -239,7 +246,8 @@
 
 
 
-template <typename T>
+template <typename T,
+	  typename MapT>
 void
 test_lsqsol_random(
   length_type m,
@@ -248,10 +256,14 @@
 {
   test_assert(m >= n);
 
-  Matrix<T> a(m, n);
-  Matrix<T> x(n, p);
-  Matrix<T> b(m, p);
-  Matrix<T> chk(m, p);
+  typedef Dense<2, T, row2_type, MapT> block_type;
+
+  MapT map = create_map<2, MapT>();
+
+  Matrix<T, block_type> a(m, n, map);
+  Matrix<T, block_type> x(n, p, map);
+  Matrix<T, block_type> b(m, p, map);
+  Matrix<T, block_type> chk(m, p, map);
 
   randm(a);
   randm(b);
@@ -318,25 +330,25 @@
   test_lsqsol_diag<T>(5,   3, 3);
   test_lsqsol_diag<T>(17, 11, 3);
 
-  test_lsqsol_random<T>(1,   1, 2);
-  test_lsqsol_random<T>(5,   5, 2);
-  test_lsqsol_random<T>(17, 17, 2);
-
-  test_lsqsol_random<T>(1,   1, 3);
-  test_lsqsol_random<T>(5,   5, 3);
-  test_lsqsol_random<T>(17, 17, 3);
-
-  test_lsqsol_random<T>(3,   1, 3);
-  test_lsqsol_random<T>(5,   3, 3);
-  test_lsqsol_random<T>(17, 11, 3);
+  test_lsqsol_random<T, Local_map>(1,   1, 2);
+  test_lsqsol_random<T, Local_map>(5,   5, 2);
+  test_lsqsol_random<T, Local_map>(17, 17, 2);
+
+  test_lsqsol_random<T, Local_map>(1,   1, 3);
+  test_lsqsol_random<T, Local_map>(5,   5, 3);
+  test_lsqsol_random<T, Local_map>(17, 17, 3);
+
+  test_lsqsol_random<T, Local_map>(3,   1, 3);
+  test_lsqsol_random<T, Local_map>(5,   3, 3);
+  test_lsqsol_random<T, Local_map>(17, 11, 3);
 
 #if DO_SWEEP
   for (index_type i=1; i<100; i+= 8)
     for (index_type j=1; j<10; j += 4)
     {
-      test_lsqsol_random<T>(i,   i,   j+1);
-      test_lsqsol_random<T>(i+1, i+1, j);
-      test_lsqsol_random<T>(i+2, i+2, j+2);
+      test_lsqsol_random<T, Local_map>(i,   i,   j+1);
+      test_lsqsol_random<T, Local_map>(i+1, i+1, j);
+      test_lsqsol_random<T, Local_map>(i+2, i+2, j+2);
     }
 #endif
 }
@@ -347,7 +359,8 @@
   Rsol tests
 ***********************************************************************/
 
-template <typename T>
+template <typename T,
+	  typename MapT>
 void
 test_rsol_diag(
   length_type m,
@@ -356,12 +369,18 @@
 {
   test_assert(m >= n);
 
-  Matrix<T> a(m, n);
-  Matrix<T> x(n, p);
-  Matrix<T> b(n, p);
+  typedef Dense<2, T, row2_type, MapT> block_type;
+  
+  MapT map = create_map<2, MapT>();
+
+  Matrix<T, block_type> a(m, n, map);
+  Matrix<T, block_type> x(n, p, map);
+  Matrix<T, block_type> b(n, p, map);
 
   a        = T();
-  a.diag() = T(1);
+  // a.diag() = T(1);
+  for (index_type i=0; i<min(m, n); ++i)
+    a.put(i, i, T(1));
   if (n > 0) a(0, 0)  = Test_traits<T>::value1();
   if (n > 2) a(2, 2)  = Test_traits<T>::value2();
   if (n > 3) a(3, 3)  = Test_traits<T>::value3();
@@ -380,10 +399,13 @@
   //   For complex<T>, Q should be unitary
   // (For complex, we can use Q to check rsol)
 
-  Matrix<T> I(m, m, T()); I.diag() = T(1);
-  Matrix<T> qi(m, m);
-  Matrix<T> iq(m, m);
-  Matrix<T> qtq(m, m);
+  Matrix<T, block_type> I(m, m, T(), map);
+  // I.diag() = T(1);
+  for (index_type i=0; i<m; ++i)
+    I.put(i, i, T(1));
+  Matrix<T, block_type> qi(m, m, map);
+  Matrix<T, block_type> iq(m, m, map);
+  Matrix<T, block_type> qtq(m, m, map);
 
   // First, check multiply w/identity from left-side:
   //   Q I = qi
@@ -427,7 +449,7 @@
   // Check rsol()
 
   for (index_type i=0; i<p; ++i)
-    b.col(i) = test_ramp(T(1), T(i), b.size(0));
+    test_ramp(b.col(i), T(1), T(i));
   if (p > 1) b.col(1) += Test_traits<T>::offset();
 
   T alpha = T(2);
@@ -454,17 +476,17 @@
 void
 rsol_cases()
 {
-  test_rsol_diag<T>( 1,   1, 2);
-  test_rsol_diag<T>( 5,   4, 2);
-  test_rsol_diag<T>( 5,   5, 2);
-  test_rsol_diag<T>( 6,   6, 2);
-  test_rsol_diag<T>(17,  17, 2);
-  test_rsol_diag<T>(17,  11, 2);
-
-  test_rsol_diag<T>( 5,   2, 2);
-  test_rsol_diag<T>( 5,   3, 2);
-  test_rsol_diag<T>( 5,   4, 2);
-  test_rsol_diag<T>( 11,  5, 2);
+  test_rsol_diag<T, Local_map>( 1,   1, 2);
+  test_rsol_diag<T, Local_map>( 5,   4, 2);
+  test_rsol_diag<T, Local_map>( 5,   5, 2);
+  test_rsol_diag<T, Local_map>( 6,   6, 2);
+  test_rsol_diag<T, Local_map>(17,  17, 2);
+  test_rsol_diag<T, Local_map>(17,  11, 2);
+
+  test_rsol_diag<T, Local_map>( 5,   2, 2);
+  test_rsol_diag<T, Local_map>( 5,   3, 2);
+  test_rsol_diag<T, Local_map>( 5,   4, 2);
+  test_rsol_diag<T, Local_map>( 11,  5, 2);
 }
 
 
@@ -614,7 +636,7 @@
 
   // Setup b.
   for (index_type i=0; i<p; ++i)
-    b.col(i) = test_ramp(T(1), T(i), n);
+    test_ramp(b.col(i), T(1), T(i));
   if (p > 1)
     b.col(1) += Test_traits<T>::offset();
 
@@ -890,8 +912,11 @@
 
 
 
+/// Test QR solver with distributed arguments.
+
 template <return_mechanism_type RtM,
-	  typename              T>
+	  typename              T,
+	  typename              MapT>
 void
 test_f_lsqsol_random(
   length_type m,
@@ -900,10 +925,14 @@
 {
   test_assert(m >= n);
 
-  Matrix<T> a(m, n);
-  Matrix<T> x(n, p);
-  Matrix<T> b(m, p);
-  Matrix<T> chk(m, p);
+  typedef Dense<2, T, row2_type, MapT> block_type;
+
+  MapT map = create_map<2, MapT>();
+
+  Matrix<T, block_type> a(m, n, map);
+  Matrix<T, block_type> x(n, p, map);
+  Matrix<T, block_type> b(m, p, map);
+  Matrix<T, block_type> chk(m, p, map);
 
   randm(a);
   randm(b);
@@ -915,8 +944,10 @@
 
   for (index_type i=n; i<m; ++i)
   {
-    a.row(i) = T(i-n+2) * a.row(i-n);
-    b.row(i) = T(i-n+2) * b.row(i-n);
+    // a.row(i) = T(i-n+2) * a.row(i-n);
+    // b.row(i) = T(i-n+2) * b.row(i-n);
+    a.row(i) = a.row(i-n) * T(i-n+2);
+    b.row(i) = b.row(i-n) * T(i-n+2);
   }
 
   f_llsqsol<RtM>(a, b, x);
@@ -960,25 +991,25 @@
   test_f_lsqsol_diag<RtM, T>(5,   3, 3);
   test_f_lsqsol_diag<RtM, T>(17, 11, 3);
 
-  test_f_lsqsol_random<RtM, T>(1,   1, 2);
-  test_f_lsqsol_random<RtM, T>(5,   5, 2);
-  test_f_lsqsol_random<RtM, T>(17, 17, 2);
-
-  test_f_lsqsol_random<RtM, T>(1,   1, 3);
-  test_f_lsqsol_random<RtM, T>(5,   5, 3);
-  test_f_lsqsol_random<RtM, T>(17, 17, 3);
-
-  test_f_lsqsol_random<RtM, T>(3,   1, 3);
-  test_f_lsqsol_random<RtM, T>(5,   3, 3);
-  test_f_lsqsol_random<RtM, T>(17, 11, 3);
+  test_f_lsqsol_random<RtM, T, Local_map>(1,   1, 2);
+  test_f_lsqsol_random<RtM, T, Local_map>(5,   5, 2);
+  test_f_lsqsol_random<RtM, T, Local_map>(17, 17, 2);
+
+  test_f_lsqsol_random<RtM, T, Local_map>(1,   1, 3);
+  test_f_lsqsol_random<RtM, T, Local_map>(5,   5, 3);
+  test_f_lsqsol_random<RtM, T, Local_map>(17, 17, 3);
+
+  test_f_lsqsol_random<RtM, T, Local_map>(3,   1, 3);
+  test_f_lsqsol_random<RtM, T, Local_map>(5,   3, 3);
+  test_f_lsqsol_random<RtM, T, Local_map>(17, 11, 3);
 
 #if DO_SWEEP
   for (index_type i=1; i<100; i+= 8)
     for (index_type j=1; j<10; j += 4)
     {
-      test_f_lsqsol_random<RtM, T>(i,   i,   j+1);
-      test_f_lsqsol_random<RtM, T>(i+1, i+1, j);
-      test_f_lsqsol_random<RtM, T>(i+2, i+2, j+2);
+      test_f_lsqsol_random<RtM, T, Local_map>(i,   i,   j+1);
+      test_f_lsqsol_random<RtM, T, Local_map>(i+1, i+1, j);
+      test_f_lsqsol_random<RtM, T, Local_map>(i+2, i+2, j+2);
     }
 #endif
 }
@@ -1036,4 +1067,10 @@
   f_lsqsol_cases<by_value, double>();
   f_lsqsol_cases<by_value, complex<float> >();
   f_lsqsol_cases<by_value, complex<double> >();
+
+  // Distributed tests
+  test_covsol_random<float, Map<> >(5, 5, 2);
+  test_lsqsol_random<float, Map<> >(5, 5, 2);
+  test_rsol_diag<float, Map<> >( 5,   5, 2);
+  test_f_lsqsol_random<by_reference, float, Map<> >(5,   5, 2);
 }
Index: tests/solver-toepsol.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/solver-toepsol.cpp,v
retrieving revision 1.2
diff -u -r1.2 solver-toepsol.cpp
--- tests/solver-toepsol.cpp	20 Dec 2005 12:48:41 -0000	1.2
+++ tests/solver-toepsol.cpp	11 Jan 2006 15:58:53 -0000
@@ -18,6 +18,8 @@
 #include <vsip/solvers.hpp>
 #include <vsip/selgen.hpp>
 #include <vsip/random.hpp>
+#include <vsip/map.hpp>
+#include <vsip/parallel.hpp>
 
 #include "test.hpp"
 #include "test-precision.hpp"
@@ -189,6 +191,45 @@
 
 
 
+/// Test a general toeplitz linear system (with distributed views).
+
+/// Test that toeplitz solver will correctly work when given
+/// distributed views.  Solver is not parallel.
+
+template <typename T,
+	  typename MapT>
+void
+test_toepsol_dist(
+  return_mechanism_type rtm,
+  length_type           size,
+  length_type           loop)
+{
+  typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
+
+  typedef Dense<1, T, row1_type, MapT> block_type;
+  typedef Vector<T, block_type>        view_type;
+
+  MapT map(num_processors());
+
+  view_type a(size, T(), map);
+  view_type b(size, map);
+
+  a = T();
+
+  for (index_type i=0; i<size; ++i)
+    a(i) = Toepsol_traits<T>::value(i);
+
+  Rand<T> rand(1);
+
+  for (index_type l=0; l<loop; ++l)
+  {
+    vsip::impl::assign_local(b, rand.randu(size)); // b = rand.randu(size);
+    test_toepsol(rtm, a, b);
+  }
+}
+
+
+
 /// Test a non positive-definite toeplitz linear system.
 
 template <typename T>
@@ -240,7 +281,11 @@
   test_toepsol_rand<complex<float> > (rtm, 6, 5);
   test_toepsol_rand<complex<double> >(rtm, 7, 5);
 
+#if VSIP_HAS_EXCEPTIONS
   test_toepsol_illformed<float>      (rtm, 4);
+#endif
+
+  test_toepsol_dist<float, Map<Block_dist> >(rtm, 4, 5);
 }
   
 
Index: tests/test-storage.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/test-storage.hpp,v
retrieving revision 1.8
diff -u -r1.8 test-storage.hpp
--- tests/test-storage.hpp	15 Sep 2005 14:49:26 -0000	1.8
+++ tests/test-storage.hpp	11 Jan 2006 15:58:53 -0000
@@ -69,6 +69,58 @@
  * -------------------------------------------------------------------- */
 
 
+template <vsip::dimension_type Dim,
+	  typename             MapT>
+struct Create_map {};
+
+template <vsip::dimension_type Dim>
+struct Create_map<Dim, vsip::Local_map>
+{
+  typedef vsip::Local_map type;
+  static type exec() { return type(); }
+};
+
+template <vsip::dimension_type Dim>
+struct Create_map<Dim, vsip::Global_map<Dim> >
+{
+  typedef vsip::Global_map<Dim> type;
+  static type exec() { return type(); }
+};
+
+template <typename Dist0, typename Dist1, typename Dist2>
+struct Create_map<1, vsip::Map<Dist0, Dist1, Dist2> >
+{
+  typedef vsip::Map<Dist0, Dist1, Dist2> type;
+  static type exec() { return type(vsip::num_processors()); }
+};
+
+template <typename Dist0, typename Dist1, typename Dist2>
+struct Create_map<2, vsip::Map<Dist0, Dist1, Dist2> >
+{
+  typedef vsip::Map<Dist0, Dist1, Dist2> type;
+
+  static type exec()
+  {
+    using vsip::processor_type;
+
+    processor_type np = vsip::num_processors();
+    processor_type nr = (processor_type)floor(sqrt((double)np));
+    processor_type nc = (processor_type)floor((double)np/nr);
+
+    return type(nr, nc);
+  }
+};
+
+template <vsip::dimension_type Dim,
+	  typename             MapT>
+MapT
+create_map()
+{
+  return Create_map<Dim, MapT>::exec();
+}
+
+
+
 
 // -------------------------------------------------------------------- //
 // Scalar_storage -- provide default vector storage.
@@ -103,7 +155,8 @@
 
 template <vsip::dimension_type Dim,
 	  typename             T,
-	  typename             Order = typename Default_order<Dim>::type>
+	  typename             Order = typename Default_order<Dim>::type,
+          typename             MapT  = vsip::Local_map >
 class Storage;
 
 template <vsip::dimension_type Dim,
@@ -116,8 +169,9 @@
 // -------------------------------------------------------------------- //
 // Scalar_storage -- provide default scalar storage.
 template <typename T,
-	  typename Order>
-class Storage<0, T, Order> {
+	  typename Order,
+	  typename MapT>
+class Storage<0, T, Order, MapT> {
 public:
    static vsip::dimension_type const
 		dim = 0;
@@ -179,8 +233,9 @@
 // Vector_storage -- provide default vector storage.
 
 template <typename T,
-	  typename Order>
-class Storage<1, T, Order>
+	  typename Order,
+	  typename MapT>
+class Storage<1, T, Order, MapT>
 {
   // Compile-time values and typedefs.
 public:
@@ -189,22 +244,24 @@
    
   typedef T	value_type;
    
-  typedef vsip::Dense<dim, T, Order>
-		block_type;
-
-  typedef vsip::Vector<T, block_type>
-		view_type;
+  typedef MapT                                 map_type;
+  typedef vsip::Dense<dim, T, Order, map_type> block_type;
+  typedef vsip::Vector<T, block_type>          view_type;
 
 
   // Constructors.
 public:
-  Storage() : view(5) {}
+  Storage()
+    : map(create_map<1, map_type>()), view(5, map)
+  {}
 
-  Storage(vsip::Domain<dim> const& dom) : view(dom.length()) {}
+  Storage(vsip::Domain<dim> const& dom)
+    : map(create_map<1, map_type>()), view(dom.length(), map)
+  {}
 
   Storage(vsip::Domain<dim> const& dom, T val)
-    : view(dom.length(), val)
-    {}
+    : map(create_map<1, map_type>()), view(dom.length(), val, map)
+  {}
 
 
   // Accessor.
@@ -214,6 +271,7 @@
 
   // Public member data.
 public:
+  map_type      map;
   view_type	view;
 };
 
@@ -274,8 +332,9 @@
 // -------------------------------------------------------------------- //
 // Matrix_storage -- provide default vector storage.
 template <typename T,
-	  typename Order>
-class Storage<2, T, Order>
+	  typename Order,
+	  typename MapT>
+class Storage<2, T, Order, MapT>
 {
   // Compile-time values and typedefs.
 public:
@@ -371,8 +430,9 @@
 /// Storage specialization for Tensors.
 
 template <typename T,
-	  typename Order>
-class Storage<3, T, Order>
+	  typename Order,
+	  typename MapT>
+class Storage<3, T, Order, MapT>
 {
   // Compile-time values and typedefs.
 public:
Index: tests/test.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/test.hpp,v
retrieving revision 1.11
diff -u -r1.11 test.hpp
--- tests/test.hpp	20 Dec 2005 12:48:41 -0000	1.11
+++ tests/test.hpp	11 Jan 2006 15:58:53 -0000
@@ -217,9 +217,15 @@
 # define TEST_ASSERT_FUNCTION    ((__const char *) 0)
 #endif
 
+#ifdef __STDC__
+#  define __TEST_STRING(e) #e
+#else
+#  define __TEST_STRING(e) "e"
+#endif
+
 #define test_assert(expr)						\
   (static_cast<void>((expr) ? 0 :					\
-		     (test_assert_fail(__STRING(expr), __FILE__, __LINE__, \
+		     (test_assert_fail(__TEST_STRING(expr), __FILE__, __LINE__, \
 				       TEST_ASSERT_FUNCTION), 0)))
 
 
