Index: ChangeLog
===================================================================
--- ChangeLog	(revision 170337)
+++ ChangeLog	(working copy)
@@ -1,3 +1,14 @@
+2007-05-08  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/core/fft/backend.hpp: Add axis static member variable
+	  to fft and fftm backend classes.
+	* src/vsip/core/parallel/support_block.hpp: New file, block versions
+	  of select parallel support functions in parallel/support.hpp.
+	* src/vsip/opt/fft/return_functor.hpp (Fft_return_functor::local):
+	  Properly determine local subblock size for Fftm case.
+	* tests/regressions/dist_fftm_mmul.cpp: New file, regression test
+	  for Fftm return_functor local subblock size.
+	
 2007-05-03  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip/opt/cbe/ppu/fft.cpp (Fftm_impl): Return if empty subblock.
Index: src/vsip/core/fft/backend.hpp
===================================================================
--- src/vsip/core/fft/backend.hpp	(revision 168761)
+++ src/vsip/core/fft/backend.hpp	(working copy)
@@ -46,6 +46,8 @@
   : public backend_base<1, T>
 {
 public:
+  static int const axis = A;
+
   virtual ~backend() {}
   virtual char const* name() { return "fft-backend-1D-real-forward"; }
   virtual bool supports_scale() { return false;}
@@ -73,6 +75,8 @@
   : public backend_base<1, T>
 {
 public:
+  static int const axis = A;
+
   virtual ~backend() {}
   virtual char const* name() { return "fft-backend-1D-real-inverse"; }
   virtual bool supports_scale() { return false;}
@@ -100,6 +104,8 @@
   : public backend_base<1, T>
 {
 public:
+  static int const axis = A;
+
   virtual ~backend() {}
   virtual char const* name() { return "fft-backend-1D-complex"; }
   virtual bool supports_scale() { return false;}
@@ -138,6 +144,8 @@
   : public backend_base<2, T>
 {
 public:
+  static int const axis = A;
+
   virtual ~backend() {}
   virtual char const* name() { return "fft-backend-2D-real-forward"; }
   virtual bool supports_scale() { return false;}
@@ -169,6 +177,8 @@
   : public backend_base<2, T>
 {
 public:
+  static int const axis = A;
+
   virtual ~backend() {}
   virtual char const* name() { return "fft-backend-2D-real-inverse"; }
   virtual bool supports_scale() { return false;}
@@ -200,6 +210,8 @@
   : public backend_base<2, T>
 {
 public:
+  static int const axis = A;
+
   virtual ~backend() {}
   virtual char const* name() { return "fft-backend-2D-complex"; }
   virtual bool supports_scale() { return false;}
@@ -246,6 +258,8 @@
   : public backend_base<3, T>
 {
 public:
+  static int const axis = A;
+
   virtual ~backend() {}
   virtual char const* name() { return "fft-backend-2D-real-forward"; }
   virtual bool supports_scale() { return false;}
@@ -289,6 +303,8 @@
   : public backend_base<3, T>
 {
 public:
+  static int const axis = A;
+
   virtual ~backend() {}
   virtual char const* name() { return "fft-backend-2D-real-inverse"; }
   virtual bool supports_scale() { return false;}
@@ -332,6 +348,8 @@
   : public backend_base<3, T>
 {
 public:
+  static int const axis = A;
+
   virtual ~backend() {}
   virtual char const* name() { return "fft-backend-2D-complex"; }
   virtual bool supports_scale() { return false;}
@@ -401,6 +419,8 @@
   : public backend_base<2, T>
 {
 public:
+  static int const axis = A;
+
   virtual ~fftm() {}
   virtual char const* name() { return "fftm-backend-real-forward"; }
   virtual bool supports_scale() { return false;}
@@ -436,6 +456,8 @@
   : public backend_base<2, T>
 {
 public:
+  static int const axis = A;
+
   virtual ~fftm() {}
   virtual char const* name() { return "fftm-backend-real-inverse"; }
   virtual bool supports_scale() { return false;}
@@ -471,6 +493,8 @@
   : public backend_base<2, T>
 {
 public:
+  static int const axis = A;
+
   virtual ~fftm() {}
   virtual char const* name() { return "fftm-backend-complex"; }
   virtual bool supports_scale() { return false;}
Index: src/vsip/core/parallel/support_block.hpp
===================================================================
--- src/vsip/core/parallel/support_block.hpp	(revision 0)
+++ src/vsip/core/parallel/support_block.hpp	(revision 0)
@@ -0,0 +1,122 @@
+/* Copyright (c) 2007 by CodeSourcery, Inc.  All rights reserved. */
+
+/** @file    vsip/core/parallel/support_block.hpp
+    @author  Jules Bergmann
+    @date    2007-05-07
+    @brief   VSIPL++ Library: Block versions of parallel support funcions.
+
+*/
+
+#ifndef VSIP_CORE_PARALLEL_SUPPORT_BLOCK_HPP
+#define VSIP_CORE_PARALLEL_SUPPORT_BLOCK_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/core/parallel/services.hpp>
+#include <vsip/support.hpp>
+#include <vsip/core/domain_utils.hpp>
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
+namespace psf_detail
+{
+
+// Return the subdomain of a block/map pair for a subblock.
+
+// Variant of subblock_domain that works with blocks instead of views.
+// This could be used from vsip::subblock_domain.  However, first need
+// to verify that pushing the view.block() into vsip::subblock_domain
+// doesn't force it to always be called.
+
+template <dimension_type Dim,
+	  typename       BlockT>
+inline Domain<Dim>
+block_subblock_domain(
+  BlockT const&       block,
+  Local_map const&    /*map*/,
+  index_type          sb)
+{
+  assert(sb == 0 || sb == no_subblock);
+  return (sb == 0) ? block_domain<Dim>(block)
+                   : empty_domain<Dim>();
+}
+
+template <dimension_type Dim,
+	  typename       BlockT,
+	  typename       MapT>
+inline Domain<Dim>
+block_subblock_domain(
+  BlockT const&    /*block*/,
+  MapT const&      map,
+  index_type       sb)
+{
+  return map.template impl_subblock_domain<Dim>(sb);
+}
+
+} // namespace vsip::impl::psf_detail
+
+
+
+/***********************************************************************
+  Definitions - Sourcery VSIPL++ extended parallel support functions
+***********************************************************************/
+
+/// Return the domain of BLOCK's subblock SB.
+
+/// Requires
+///   DIM to be dimension of block,
+///   BLOCK to be a block,
+///   SB to either be a valid subblock of BLOCK, or the value no_subblock.
+///
+/// Returns
+///   The domain of BLOCK's subblock SB if SB is valid, the empty
+///   domain if SB == no_subblock.
+
+template <dimension_type Dim,
+	  typename       BlockT>
+Domain<Dim>
+block_subblock_domain(
+  BlockT const& block,
+  index_type    sb)
+{
+  return impl::psf_detail::block_subblock_domain<Dim, BlockT>(
+    block, block.map(), sb);
+}
+
+
+
+/// Return the domain of BLOCK's subblock held by the local processor.
+
+/// Requires
+///   BLOCK to be a view
+///
+/// Returns
+///   The domain of BLOCK's subblock held by the local processor.
+
+template <dimension_type Dim,
+	  typename       BlockT>
+Domain<Dim>
+block_subblock_domain(
+  BlockT const& block)
+{
+  return impl::psf_detail::block_subblock_domain<Dim, BlockT>(
+    block, block.map(), block.map().subblock());
+}
+
+} // namespace vsip::impl
+
+} // namespace vsip
+
+#endif // VSIP_IMPL_PAR_SUPPORT_BLOCK_HPP
Index: src/vsip/opt/fft/return_functor.hpp
===================================================================
--- src/vsip/opt/fft/return_functor.hpp	(revision 167964)
+++ src/vsip/opt/fft/return_functor.hpp	(working copy)
@@ -13,8 +13,8 @@
   Included Files
 ***********************************************************************/
 
-#include <iostream>
 #include <vsip/core/block_traits.hpp>
+#include <vsip/core/parallel/support_block.hpp>
 
 
 
@@ -106,8 +106,25 @@
 
   local_type local() const
   {
+    // The local output size is the same as the global output size
+    // along the dimension of the FFT.  Its size along the other
+    // dimension matches that of the input local block.
+    length_type rows = output_size_[0].size();
+    length_type cols = output_size_[1].size();
+    if (BackendT::axis == 0)
+    {
+      cols = block_subblock_domain<2>(in_block_)[1].size();
+      rows = (cols == 0) ? 0 : rows;
+    }
+    else
+    {
+      rows = block_subblock_domain<2>(in_block_)[0].size();
+      cols = (rows == 0) ? 0 : cols;
+    }
+    Domain<2> l_output_size(rows, cols);
+
     return local_type(get_local_block(in_block_),
-		      output_size_, // TODO FIX
+		      l_output_size,
 		      backend_,
 		      workspace_);
   }
Index: tests/regressions/dist_fftm_mmul.cpp
===================================================================
--- tests/regressions/dist_fftm_mmul.cpp	(revision 0)
+++ tests/regressions/dist_fftm_mmul.cpp	(revision 0)
@@ -0,0 +1,124 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+
+/** @file    tests/dist_fftm_mmul.cpp
+    @author  Jules Bergmann
+    @date    2007-05-03
+    @brief   VSIPL++ Library: Distributed Fftm + mmul regression.
+
+    Fft_return_functor was not computing the proper size for a 
+    local subblock.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <algorithm>
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/matrix.hpp>
+#include <vsip/signal.hpp>
+#include <vsip/map.hpp>
+
+#include <vsip_csl/test.hpp>
+
+using namespace std;
+using namespace vsip;
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+template <typename T,
+	  typename MapT>
+void
+test_fftm_mmul(
+  bool        scale,
+  MapT const& map = MapT())
+{
+  typedef Fftm<T, T, row, fft_fwd, by_value, 1> fftm_type;
+
+  length_type rows = 16;
+  length_type cols = 64;
+
+  fftm_type fftm(Domain<2>(rows, cols), scale ? 1.f / cols : 1.f);
+
+  Matrix<T, Dense<2, T, row2_type, MapT> > in (rows, cols,          map);
+  Matrix<T, Dense<2, T, row2_type, MapT> > k  (rows, cols, T(   2), map);
+  Matrix<T, Dense<2, T, row2_type, MapT> > out(rows, cols, T(-100), map);
+
+  in = T(1);
+
+  out = k * fftm(in); 
+
+  for (index_type r=0; r<rows; ++r)
+    test_assert(out.get(r, 0) == T(scale ? 2 : 2*cols));
+}
+
+
+
+/***********************************************************************
+  Main
+***********************************************************************/
+
+int
+main(int argc, char** argv)
+{
+  vsipl init(argc, argv);
+
+#if 0
+  // Enable this section for easier debugging.
+  impl::Communicator& comm = impl::default_communicator();
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
+
+  // Test with local map.
+
+  Local_map lmap;
+
+  test_fftm_mmul<complex<float> >(true,  lmap);
+
+
+  // Test with map that distributes rows across all processors.
+  // (Each processor should have 1 or more rows, unless, NP > 64).
+  //
+  // 070507: This causes Fft_return_functor to create a local subblock
+  //         with the wrong size when np >= 2.
+
+
+  length_type np = vsip::num_processors();
+  Map<> map1(np, 1);
+
+  test_fftm_mmul<complex<float> >(true, map1);
+
+
+  // Test with map that collects all rows on root processor.
+  // (Other processor will have 0 rows, i.e. an empty subblock).
+  //
+  // 070507: This causes Fft_return_functor to create a local subblock
+  //         with the wrong size when np >= 2.
+
+  Map<> map2(1, 1);
+
+  test_fftm_mmul<complex<float> >(true, map2);
+
+  return 0;
+}
