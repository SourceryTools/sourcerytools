? ChangeLog.new
? config.log
? src/vsip/.domain.hpp.swp
? src/vsip/impl/my_patch
? tests/Makefile.in
? vendor/atlas/autom4te.cache
? vendor/atlas/configure
? vendor/atlas/CONFIG/acconfig.hpp.in
? vendor/atlas/bin/Makefile.in
? vendor/atlas/interfaces/blas/C/src/Makefile.in
? vendor/atlas/interfaces/blas/C/testing/Makefile.in
? vendor/atlas/interfaces/blas/F77/src/Makefile.in
? vendor/atlas/interfaces/blas/F77/testing/Makefile.in
? vendor/atlas/interfaces/lapack/C/src/Makefile.in
? vendor/atlas/interfaces/lapack/F77/src/Makefile.in
? vendor/atlas/lib/Makefile.in
? vendor/atlas/src/auxil/Makefile.in
? vendor/atlas/src/blas/gemm/Make.inc.in
? vendor/atlas/src/blas/gemm/Makefile.in
? vendor/atlas/src/blas/gemm/GOTO/Makefile.in
? vendor/atlas/src/blas/gemv/Make.inc.in
? vendor/atlas/src/blas/gemv/Makefile.in
? vendor/atlas/src/blas/ger/Make.inc.in
? vendor/atlas/src/blas/ger/Makefile.in
? vendor/atlas/src/blas/level1/Make.inc.in
? vendor/atlas/src/blas/level1/Makefile.in
? vendor/atlas/src/blas/level2/Makefile.in
? vendor/atlas/src/blas/level2/kernel/Makefile.in
? vendor/atlas/src/blas/level3/Makefile.in
? vendor/atlas/src/blas/level3/kernel/Makefile.in
? vendor/atlas/src/blas/level3/rblas/Makefile.in
? vendor/atlas/src/blas/pklevel3/Makefile.in
? vendor/atlas/src/blas/pklevel3/gpmm/Makefile.in
? vendor/atlas/src/blas/pklevel3/sprk/Makefile.in
? vendor/atlas/src/blas/reference/level1/Makefile.in
? vendor/atlas/src/blas/reference/level2/Makefile.in
? vendor/atlas/src/blas/reference/level3/Makefile.in
? vendor/atlas/src/lapack/Makefile.in
? vendor/atlas/src/pthreads/blas/level1/Makefile.in
? vendor/atlas/src/pthreads/blas/level2/Makefile.in
? vendor/atlas/src/pthreads/blas/level3/Makefile.in
? vendor/atlas/src/pthreads/misc/Makefile.in
? vendor/atlas/src/testing/Makefile.in
? vendor/atlas/tune/blas/gemm/Makefile.in
? vendor/atlas/tune/blas/gemv/Makefile.in
? vendor/atlas/tune/blas/ger/Makefile.in
? vendor/atlas/tune/blas/level1/Makefile.in
? vendor/atlas/tune/blas/level3/Makefile.in
? vendor/atlas/tune/sysinfo/Makefile.in
Index: src/vsip/dense.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/dense.hpp,v
retrieving revision 1.35
diff -u -r1.35 dense.hpp
--- src/vsip/dense.hpp	27 Mar 2006 23:19:34 -0000	1.35
+++ src/vsip/dense.hpp	3 Apr 2006 15:26:15 -0000
@@ -23,7 +23,7 @@
 #include <vsip/impl/layout.hpp>
 #include <vsip/impl/extdata.hpp>
 #include <vsip/impl/block-traits.hpp>
-#include <vsip/impl/point.hpp>
+#include <vsip/domain.hpp>
 
 /// Complex storage format for dense blocks.
 #if VSIP_IMPL_PREFER_SPLIT_COMPLEX
@@ -33,6 +33,7 @@
 #endif
 
 
+using vsip::Index;
 
 /***********************************************************************
   Declarations
@@ -536,8 +537,8 @@
 
 protected:
   // Dim-dimensional get/put
-  T    get(Point<Dim> const& idx) const VSIP_NOTHROW;
-  void put(Point<Dim> const& idx, T val) VSIP_NOTHROW;
+  T    get(Index<Dim> const& idx) const VSIP_NOTHROW;
+  void put(Index<Dim> const& idx, T val) VSIP_NOTHROW;
 
   // 2-diminsional get/put
   T    impl_get(index_type idx0, index_type idx1) const VSIP_NOTHROW
@@ -558,8 +559,8 @@
 
 protected:
   // Dim-dimensional lvalue.
-  reference_type       impl_ref(Point<Dim> const& idx) VSIP_NOTHROW;
-  const_reference_type impl_ref(Point<Dim> const& idx) const VSIP_NOTHROW;
+  reference_type       impl_ref(Index<Dim> const& idx) VSIP_NOTHROW;
+  const_reference_type impl_ref(Index<Dim> const& idx) const VSIP_NOTHROW;
 
   // Accessors.
 public:
@@ -779,11 +780,11 @@
 
   reference_type impl_ref(index_type idx0, index_type idx1)
     VSIP_NOTHROW
-    { return base_type::impl_ref(impl::Point<2>(idx0, idx1)); }
+    { return base_type::impl_ref(Index<2>(idx0, idx1)); }
 
   const_reference_type impl_ref(index_type idx0, index_type idx1)
     const VSIP_NOTHROW
-    { return base_type::impl_ref(impl::Point<2>(idx0, idx1)); }
+    { return base_type::impl_ref(Index<2>(idx0, idx1)); }
 };
 
 
@@ -901,12 +902,12 @@
 
   reference_type impl_ref(index_type idx0, index_type idx1, index_type idx2)
     VSIP_NOTHROW
-    { return base_type::impl_ref(impl::Point<3>(idx0, idx1, idx2)); }
+    { return base_type::impl_ref(Index<3>(idx0, idx1, idx2)); }
 
   const_reference_type impl_ref(index_type idx0, index_type idx1,
 				  index_type idx2)
     const VSIP_NOTHROW
-    { return base_type::impl_ref(impl::Point<3>(idx0, idx1, idx2)); }
+    { return base_type::impl_ref(Index<3>(idx0, idx1, idx2)); }
 };
 
 
@@ -1329,7 +1330,7 @@
 inline
 T
 Dense_impl<Dim, T, OrderT, MapT>::get(
-  Point<Dim> const& idx)
+  Index<Dim> const& idx)
   const VSIP_NOTHROW
 {
   for (dimension_type d=0; d<Dim; ++d)
@@ -1346,7 +1347,7 @@
 inline
 void
 Dense_impl<Dim, T, OrderT, MapT>::put(
-  Point<Dim> const& idx,
+  Index<Dim> const& idx,
   T                 val)
   VSIP_NOTHROW
 {
@@ -1364,7 +1365,7 @@
 inline
 typename Dense_impl<Dim, T, OrderT, MapT>::reference_type
 Dense_impl<Dim, T, OrderT, MapT>::impl_ref(
-  Point<Dim> const& idx) VSIP_NOTHROW
+  Index<Dim> const& idx) VSIP_NOTHROW
 {
   for (dimension_type d=0; d<Dim; ++d)
     assert(idx[d] < layout_.size(d));
@@ -1380,7 +1381,7 @@
 inline
 typename Dense_impl<Dim, T, OrderT, MapT>::const_reference_type
 Dense_impl<Dim, T, OrderT, MapT>::impl_ref(
-  Point<Dim> const& idx) const VSIP_NOTHROW
+  Index<Dim> const& idx) const VSIP_NOTHROW
 {
   for (dimension_type d=0; d<Dim; ++d)
     assert(idx[d] < layout_.size(d));
Index: src/vsip/domain.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/domain.hpp,v
retrieving revision 1.15
diff -u -r1.15 domain.hpp
--- src/vsip/domain.hpp	19 Sep 2005 03:39:54 -0000	1.15
+++ src/vsip/domain.hpp	3 Apr 2006 15:26:15 -0000
@@ -31,6 +31,8 @@
   Index(index_type x) VSIP_NOTHROW : Vertex<index_type, 1>(x) {}
 };
 
+// mathematical operations for Index
+/*
 inline bool 
 operator==(Index<1> const& i, Index<1> const& j) VSIP_NOTHROW
 {
@@ -38,6 +40,46 @@
     static_cast<Vertex<index_type, 1> >(i) == 
     static_cast<Vertex<index_type, 1> >(j);
 }
+*/
+
+template <dimension_type Dim>
+inline bool 
+operator==(Index<Dim> const& i, Index<Dim> const& j) VSIP_NOTHROW
+{
+  for (dimension_type d=0; d<Dim; ++d)
+    if (i[d] != j[d])
+      return false;
+  return true;
+}
+
+template <dimension_type Dim>
+inline
+Index<Dim>
+operator-(
+  Index<Dim> const& op1,
+  Index<Dim> const& op2)
+{
+  Index<Dim> res;
+  for (dimension_type d=0; d<Dim; ++d)
+    res[d] = op1[d] - op2[d];
+  return res;
+}
+
+
+
+template <dimension_type Dim>
+inline
+Index<Dim>
+operator+(
+  Index<Dim> const& op1,
+  Index<Dim> const& op2)
+{
+  Index<Dim> res;
+  for (dimension_type d=0; d<Dim; ++d)
+    res[d] = op1[d] + op2[d];
+  return res;
+}
+
 
 template <> class Index<2> : public Vertex<index_type, 2>
 {
Index: src/vsip/matrix.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/matrix.hpp,v
retrieving revision 1.30
diff -u -r1.30 matrix.hpp
--- src/vsip/matrix.hpp	11 Jan 2006 16:22:44 -0000	1.30
+++ src/vsip/matrix.hpp	3 Apr 2006 15:26:15 -0000
@@ -401,6 +401,18 @@
   return Domain<2>(view.size(0), view.size(1));
 }
 
+/// Get the extent of a matrix view, as a Length.
+
+template <typename T,
+	  typename Block>
+Length<2>
+extent(const_Matrix<T, Block> v)
+{
+  return Length<2>(v.size(0), v.size(1));
+}
+
+
+
 } // namespace vsip::impl
 
 } // namespace vsip
Index: src/vsip/vector.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/vector.hpp,v
retrieving revision 1.38
diff -u -r1.38 vector.hpp
--- src/vsip/vector.hpp	22 Mar 2006 20:48:58 -0000	1.38
+++ src/vsip/vector.hpp	3 Apr 2006 15:26:15 -0000
@@ -354,6 +354,18 @@
   return Domain<1>(view.size(0));
 }
 
+/// Get the extent of a vector view, as a Length. 
+
+template <typename T,
+	  typename Block>
+Length<1>
+extent(const_Vector<T, Block> v)
+{
+  return Length<1>(v.size(0));
+}
+
+
+
 } // namespace vsip::impl
 
 
Index: src/vsip/impl/block-copy.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/block-copy.hpp,v
retrieving revision 1.11
diff -u -r1.11 block-copy.hpp
--- src/vsip/impl/block-copy.hpp	27 Mar 2006 23:19:34 -0000	1.11
+++ src/vsip/impl/block-copy.hpp	3 Apr 2006 15:26:15 -0000
@@ -51,9 +51,9 @@
 
   static void copy_in (Block* block, LP& layout, ptr_type data)
   {
-    Point<Dim> ext = extent_old<Dim>(*block);
+    Length<Dim> ext = extent<Dim>(*block);
 
-    for (Point<Dim> idx; valid(ext, idx); next(ext, idx))
+    for (Index<Dim> idx; valid(ext, idx); next(ext, idx))
     {
       storage_type::put(data, layout.index(idx), get(*block, idx));
     }
@@ -61,9 +61,9 @@
 
   static void copy_out(Block* block, LP& layout, ptr_type data)
   {
-    Point<Dim> ext = extent_old<Dim>(*block);
+    Length<Dim> ext = extent<Dim>(*block);
 
-    for (Point<Dim> idx; valid(ext, idx); next(ext, idx))
+    for (Index<Dim> idx; valid(ext, idx); next(ext, idx))
     {
       put(*block, idx, storage_type::get(data, layout.index(idx)));
     }
Index: src/vsip/impl/domain-utils.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/domain-utils.hpp,v
retrieving revision 1.8
diff -u -r1.8 domain-utils.hpp
--- src/vsip/impl/domain-utils.hpp	7 Oct 2005 13:46:46 -0000	1.8
+++ src/vsip/impl/domain-utils.hpp	3 Apr 2006 15:26:15 -0000
@@ -336,6 +336,242 @@
 }
 
 
+/// Get the nth index in a domain.
+
+
+template <dimension_type Dim>
+Index<Dim>
+domain_nth(
+  Domain<Dim> const& dom,
+  Index<Dim> const&  idx)
+{
+  Index<Dim> res;
+
+  for (dimension_type d=0; d<Dim; ++d)
+    res[d] = dom[d].impl_nth(idx[d]);
+
+  return res;
+}
+
+/// Get the extent of a domain as a Length.
+
+template <dimension_type Dim>
+Length<Dim>
+extent(
+  Domain<Dim> const& dom)
+{
+  Length<Dim> res;
+
+  for (dimension_type d=0; d<Dim; ++d)
+    res[d] = dom[d].length();
+
+  return res;
+}
+
+
+/// Get the first index of a domain.
+
+template <dimension_type Dim>
+Index<Dim>
+first(
+  Domain<Dim> const& dom)
+{
+  Index<Dim> res;
+  for (dimension_type d=0; d<Dim; ++d)
+    res[d] = dom[d].first();
+  return res;
+}
+
+
+
+
+/// Construct a 1-dim domain with an offset and a size (implicit
+/// stride of 1)
+
+inline Domain<1>
+domain(
+  Index<1> const& first,
+  Length<1> const& size)
+{
+  return Domain<1>(first[0], 1, size[0]);
+}
+
+
+
+/// Construct a 2-dim domain with an offset and a size (implicit
+/// stride of 1)
+
+inline Domain<2>
+domain(
+  Index<2> const& first,
+  Length<2> const& size)
+{
+  return Domain<2>(Domain<1>(first[0], 1, size[0]),
+		   Domain<1>(first[1], 1, size[1]));
+}
+
+
+
+/// Construct a 3-dim domain with an offset and a size (implicit
+/// stride of 1)
+
+inline Domain<3>
+domain(
+  Index<3> const& first,
+  Length<3> const& size)
+{
+  return Domain<3>(Domain<1>(first[0], 1, size[0]),
+		   Domain<1>(first[1], 1, size[1]),
+		   Domain<1>(first[2], 1, size[2]));
+}
+
+/* Now let's make the "next" functions that work Index. This function is the
+ * same as the Point one but it operates on an Index
+ */
+inline
+Index<1>&
+next(
+  Length<1> const& /*extent*/,
+  Index<1>&        idx)
+{
+  ++idx[0];
+  return idx;
+}
+
+
+
+inline
+Index<2>&
+next(
+  Length<2> const& extent,
+  Index<2>&        idx)
+{
+  if (++idx[0] == extent[0])
+  {
+    if (++idx[1] != extent[1])
+      idx[0] = 0;
+  }
+  return idx;
+}
+
+
+
+inline
+Index<3>&
+next(
+  Length<3> const& extent,
+  Index<3>&        idx)
+{
+  if (++idx[0] == extent[0])
+  {
+    if (++idx[1] == extent[1])
+    {
+      if (++idx[2] == extent[2])
+	return idx;
+      idx[1] = 0;
+    }
+    idx[0] = 0;
+  }
+
+  return idx;
+}
+
+// This function checks if the index is valid given a certain length. This
+// function works for multiple dimension spaces.
+template <dimension_type D>
+inline bool
+valid(
+  Length<D> const& extent,
+  Index<D>  const& idx)
+{
+  for(dimension_type d=0;d<D;++d)
+    if(idx[d] >= extent[d])
+      return false;
+  return true;
+}
+
+
+
+/// Get a value from a 1-dim block.
+
+template <typename Block>
+inline typename Block::value_type
+get(
+  Block const&    block,
+  Index<1> const& idx)
+{
+  return block.get(idx[0]);
+}
+
+
+
+/// Get a value from a 2-dim block.
+
+template <typename Block>
+inline typename Block::value_type
+get(
+  Block const&    block,
+  Index<2> const& idx)
+{
+  return block.get(idx[0], idx[1]);
+}
+
+
+
+/// Get a value from a 3-dim block.
+
+template <typename Block>
+inline typename Block::value_type
+get(
+  Block const&    block,
+  Index<3> const& idx)
+{
+  return block.get(idx[0], idx[1], idx[2]);
+}
+
+
+
+/// Put a value into a 1-dim block.
+
+template <typename Block>
+inline void
+put(
+  Block&                            block,
+  Index<1> const&                   idx,
+  typename Block::value_type const& val)
+{
+  block.put(idx[0], val);
+}
+
+
+/// Put a value into a 2-dim block.
+
+template <typename Block>
+inline void
+put(
+  Block&                            block,
+  Index<2> const&                   idx,
+  typename Block::value_type const& val)
+{
+  block.put(idx[0], idx[1], val);
+}
+
+
+template <typename Block>
+inline void
+put(
+  Block&                            block,
+  Index<3> const&                   idx,
+  typename Block::value_type const& val)
+{
+  block.put(idx[0], idx[1], idx[2], val);
+}
+
+
+
+
+
+
 
 } // namespace vsip::impl
 
Index: src/vsip/impl/extdata.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/extdata.hpp,v
retrieving revision 1.18
diff -u -r1.18 extdata.hpp
--- src/vsip/impl/extdata.hpp	7 Mar 2006 02:15:22 -0000	1.18
+++ src/vsip/impl/extdata.hpp	3 Apr 2006 15:26:15 -0000
@@ -19,8 +19,8 @@
 #include <vsip/impl/block-traits.hpp>
 #include <vsip/impl/metaprogramming.hpp>
 #include <vsip/impl/layout.hpp>
-#include <vsip/impl/point.hpp>
 #include <vsip/impl/choose-access.hpp>
+#include <vsip/impl/domain-utils.hpp>
 
 
 
@@ -425,7 +425,7 @@
   Low_level_data_access(Block&         blk,
 			raw_ptr_type   buffer = NULL)
     : use_direct_(is_direct_ok<LP>(blk)),
-      layout_    (extent_old<dim>(blk)),
+      layout_    (extent<dim>(blk)),
       storage_   (use_direct_ ? 0 : layout_.total_size(), buffer)
   {}
 
@@ -516,7 +516,7 @@
 public:
   Low_level_data_access(Block&         blk,
 			raw_ptr_type   buffer = NULL)
-    : layout_   (extent_old<dim>(blk)),
+    : layout_   (extent<dim>(blk)),
       storage_  (layout_.total_size(), buffer)
   {}
 
Index: src/vsip/impl/fast-block.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/fast-block.hpp,v
retrieving revision 1.12
diff -u -r1.12 fast-block.hpp
--- src/vsip/impl/fast-block.hpp	1 Sep 2005 20:02:16 -0000	1.12
+++ src/vsip/impl/fast-block.hpp	3 Apr 2006 15:26:15 -0000
@@ -24,9 +24,9 @@
 #include <vsip/impl/layout.hpp>
 #include <vsip/impl/extdata.hpp>
 #include <vsip/impl/block-traits.hpp>
-#include <vsip/impl/point.hpp>
 
 
+using vsip::Index;
 
 /***********************************************************************
   Declarations
@@ -115,14 +115,14 @@
 
   // Dim-dimensional accessors
 protected:
-  T    get(Point<Dim> idx) const VSIP_NOTHROW
+  T    get(Index<Dim> idx) const VSIP_NOTHROW
   {
     for (dimension_type d=0; d<Dim; ++d)
       assert(idx[d] < layout_.size(d));
     return storage_.get(layout_.index(idx));
   }
 
-  void put(Point<Dim> idx, T val) VSIP_NOTHROW
+  void put(Index<Dim> idx, T val) VSIP_NOTHROW
   {
     for (dimension_type d=0; d<Dim; ++d)
       assert(idx[d] < layout_.size(d));
@@ -237,9 +237,9 @@
   // 2-dimensional data accessors.
 public:
   T get(index_type idx0, index_type idx1) const VSIP_NOTHROW
-    { return bast_t::get(Point<2>(idx0, idx1)); }
+    { return bast_t::get(Index<2>(idx0, idx1)); }
   void put(index_type idx0, index_type idx1, T val) VSIP_NOTHROW
-    { bast_t::put(Point<2>(idx0, idx1), val); }
+    { bast_t::put(Index<2>(idx0, idx1), val); }
 };
 
 
@@ -271,10 +271,10 @@
   // 3-dimensional data accessors.
 public:
   T get(index_type idx0, index_type idx1, index_type idx2) const VSIP_NOTHROW
-    { return bast_t::get(Point<3>(idx0, idx1, idx2)); }
+    { return bast_t::get(Index<3>(idx0, idx1, idx2)); }
   void put(index_type idx0, index_type idx1, index_type idx2, T val)
     VSIP_NOTHROW
-    { bast_t::put(Point<3>(idx0, idx1, idx2), val); }
+    { bast_t::put(Index<3>(idx0, idx1, idx2), val); }
 };
 
 
Index: src/vsip/impl/layout.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/layout.hpp,v
retrieving revision 1.19
diff -u -r1.19 layout.hpp
--- src/vsip/impl/layout.hpp	27 Mar 2006 23:19:34 -0000	1.19
+++ src/vsip/impl/layout.hpp	3 Apr 2006 15:26:15 -0000
@@ -15,11 +15,12 @@
 
 #include <vsip/domain.hpp>
 #include <vsip/impl/complex-decl.hpp>
-#include <vsip/impl/point.hpp>
 #include <vsip/domain.hpp>
+#include <vsip/impl/length.hpp>
 #include <vsip/impl/aligned_allocator.hpp>
 
 
+using vsip::Index;
 
 /***********************************************************************
   Declarations
@@ -178,7 +179,7 @@
     size_[0] = dom[0].length();
   }
 
-  Applied_layout(Point<1> const& extent)
+  Applied_layout(Length<1> const& extent)
   {
     size_[0] = extent[0];
   }
@@ -194,10 +195,6 @@
     const VSIP_NOTHROW
     { return idx[0]; }
 
-  index_type index(Point<1> idx)
-    const VSIP_NOTHROW
-    { return idx[0]; }
-
   stride_type stride(dimension_type d)
     const VSIP_NOTHROW
     { assert(d <= dim); return 1; }
@@ -238,7 +235,7 @@
     size_[0] = dom[0].length();
   }
 
-  Applied_layout(Point<1> const& extent)
+  Applied_layout(Length<1> const& extent)
   {
     size_[0] = extent[0];
   }
@@ -254,10 +251,6 @@
     const VSIP_NOTHROW
     { return idx[0]; }
 
-  index_type index(Point<1> idx)
-    const VSIP_NOTHROW
-    { return idx[0]; }
-
   stride_type stride(dimension_type d)
     const VSIP_NOTHROW
     { assert(d <= dim); return 1; }
@@ -292,7 +285,7 @@
     size_[0] = size0;
   }
 
-  Applied_layout(Point<1> const& extent)
+  Applied_layout(Length<1> const& extent)
   {
     size_[0] = extent[0];
   }
@@ -308,10 +301,6 @@
     const VSIP_NOTHROW
     { return idx[0]; }
 
-  index_type index(Point<1> idx)
-    const VSIP_NOTHROW
-    { return idx[0]; }
-
   stride_type stride(dimension_type d)
     const VSIP_NOTHROW
     { assert(d <= dim); return 1; }
@@ -352,7 +341,7 @@
     size_[1] = dom[1].length();
   }
 
-  Applied_layout(Point<2> const& extent)
+  Applied_layout(Length<2> const& extent)
   {
     size_[0] = extent[0];
     size_[1] = extent[1];
@@ -369,10 +358,6 @@
     const VSIP_NOTHROW
     { return idx[0] * size_[1] + idx[1]; }
 
-  index_type index(Point<2> idx)
-    const VSIP_NOTHROW
-    { return idx[0] * size_[1] + idx[1]; }
-
   stride_type stride(dimension_type d)
     const VSIP_NOTHROW
     { return d == 0 ? size_[1] : 1; }
@@ -413,7 +398,7 @@
     size_[1] = dom[1].length();
   }
 
-  Applied_layout(Point<2> const& extent)
+  Applied_layout(Length<2> const& extent)
   {
     size_[0] = extent[0];
     size_[1] = extent[1];
@@ -430,10 +415,6 @@
     const VSIP_NOTHROW
     { return idx[0] + idx[1] * size_[0]; }
 
-  index_type index(Point<2> idx)
-    const VSIP_NOTHROW
-    { return idx[0] + idx[1] * size_[0]; }
-
   stride_type stride(dimension_type d)
     const VSIP_NOTHROW
     { return d == 0 ? 1 : size_[0]; }
@@ -486,7 +467,7 @@
       stride_ += (Align - stride_%Align);
   }
 
-  Applied_layout(Point<2> const& extent)
+  Applied_layout(Length<2> const& extent)
   {
     size_[0] = extent[0];
     size_[1] = extent[1];
@@ -508,10 +489,6 @@
     const VSIP_NOTHROW
     { return idx[0] * stride_ + idx[1]; }
 
-  index_type index(Point<2> idx)
-    const VSIP_NOTHROW
-    { return idx[0] * stride_ + idx[1]; }
-
   stride_type stride(dimension_type d)
     const VSIP_NOTHROW
     { return d == 0 ? stride_ : 1; }
@@ -565,7 +542,7 @@
       stride_ += (Align - stride_%Align);
   }
 
-  Applied_layout(Point<2> const& extent)
+  Applied_layout(Length<2> const& extent)
   {
     size_[0] = extent[0];
     size_[1] = extent[1];
@@ -587,10 +564,6 @@
     const VSIP_NOTHROW
     { return idx[0] + idx[1] * stride_; }
 
-  index_type index(Point<2> idx)
-    const VSIP_NOTHROW
-    { return idx[0] + idx[1] * stride_; }
-
   stride_type stride(dimension_type d)
     const VSIP_NOTHROW
     { return d == 1 ? stride_ : 1; }
@@ -631,14 +604,14 @@
     size_[2] = dom[2].length();
   }
 
-  Applied_layout(Point<3> const& extent)
+  Applied_layout(Length<3> const& extent)
   {
     size_[0] = extent[0];
     size_[1] = extent[1];
     size_[2] = extent[2];
   }
 
-  index_type index(Point<3> idx)
+  index_type index(Index<3> idx)
     const VSIP_NOTHROW
   {
     assert(idx[0] < size_[0] && idx[1] < size_[1] && idx[2] < size_[2]);
@@ -649,11 +622,8 @@
 
   index_type index(index_type idx0, index_type idx1, index_type idx2)
     const VSIP_NOTHROW
-    { return index(Point<3>(idx0, idx1, idx2)); }
+    { return index(Index<3>(idx0, idx1, idx2)); }
 
-  index_type index(Index<3> idx)
-    const VSIP_NOTHROW
-    { return index(Point<3>(idx[0], idx[1], idx[2])); }
 
   stride_type stride(dimension_type d)
     const VSIP_NOTHROW
@@ -707,7 +677,7 @@
     stride_[Dim0] = size_[Dim1] * stride_[Dim1];
   }
 
-  Applied_layout(Point<3> const& extent)
+  Applied_layout(Length<3> const& extent)
   {
     size_[0] = extent[0];
     size_[1] = extent[1];
@@ -720,7 +690,7 @@
     stride_[Dim0] = size_[Dim1] * stride_[Dim1];
   }
 
-  index_type index(Point<3> idx)
+  index_type index(Index<3> idx)
     const VSIP_NOTHROW
   {
     assert(idx[0] < size_[0] && idx[1] < size_[1] && idx[2] < size_[2]);
@@ -731,11 +701,7 @@
 
   index_type index(index_type idx0, index_type idx1, index_type idx2)
     const VSIP_NOTHROW
-    { return index(Point<3>(idx0, idx1, idx2)); }
-
-  index_type index(Index<3> idx)
-    const VSIP_NOTHROW
-  { return index(Point<3>(idx[0], idx[1], idx[2])); }
+    { return index(Index<3>(idx0, idx1, idx2)); }
 
   stride_type stride(dimension_type d)
     const VSIP_NOTHROW
Index: src/vsip/impl/lvalue-proxy.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/lvalue-proxy.hpp,v
retrieving revision 1.8
diff -u -r1.8 lvalue-proxy.hpp
--- src/vsip/impl/lvalue-proxy.hpp	22 Mar 2006 20:48:58 -0000	1.8
+++ src/vsip/impl/lvalue-proxy.hpp	3 Apr 2006 15:26:15 -0000
@@ -19,7 +19,6 @@
 
 #include <vsip/impl/noncopyable.hpp>
 #include <vsip/impl/block-traits.hpp>
-#include <vsip/impl/point.hpp>
 
 /***********************************************************************
   Declarations
Index: src/vsip/impl/par-assign.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/par-assign.hpp,v
retrieving revision 1.11
diff -u -r1.11 par-assign.hpp
--- src/vsip/impl/par-assign.hpp	27 Mar 2006 23:19:34 -0000	1.11
+++ src/vsip/impl/par-assign.hpp	3 Apr 2006 15:26:15 -0000
@@ -21,6 +21,8 @@
 #include <vsip/matrix.hpp>
 #include <vsip/impl/par-services.hpp>
 #include <vsip/impl/par-util.hpp>
+#include <vsip/impl/length.hpp>
+#include <vsip/domain.hpp>
 
 #define VSIP_IMPL_PA_VERBOSE 0
 
@@ -124,9 +126,9 @@
 
 	      if (intersect(src_dom, dst_dom, intr))
 	      {
-		Point<dim>  offset   = first(intr) - first(src_dom);
+		Index<dim>  offset   = first(intr) - first(src_dom);
 		Domain<dim> send_dom = domain(first(src_ldom) + offset,
-					      extent_old(intr));
+					      extent(intr));
 
 #if VSIP_IMPL_PA_VERBOSE
 		  std::cout << "(" << rank << ") send "
@@ -186,9 +188,9 @@
 
 	      if (intersect(dst_dom, src_dom, intr))
 	      {
-		Point<dim>  offset   = first(intr) - first(dst_dom);
+		Index<dim>  offset   = first(intr) - first(dst_dom);
 		Domain<dim> recv_dom = domain(first(dst_ldom) + offset,
-					      extent_old(intr));
+					      extent(intr));
 
 		recv(comm, proc, local_view(recv_dom));
 #if VSIP_IMPL_PA_VERBOSE
@@ -292,9 +294,9 @@
 
 	      if (intersect(src_dom, dst_dom, intr))
 	      {
-		Point<dim>  offset   = first(intr) - first(src_dom);
+		Index<dim>  offset   = first(intr) - first(src_dom);
 		Domain<dim> send_dom = domain(first(src_ldom) + offset,
-					      extent_old(intr));
+					      extent(intr));
 
 #if VSIP_IMPL_PA_VERBOSE
 		  std::cout << "(" << rank << ") send "
@@ -351,9 +353,9 @@
 
 	      if (intersect(dst_dom, src_dom, intr))
 	      {
-		Point<dim>  offset   = first(intr) - first(dst_dom);
+		Index<dim>  offset   = first(intr) - first(dst_dom);
 		Domain<dim> recv_dom = domain(first(dst_ldom) + offset,
-					      extent_old(intr));
+					      extent(intr));
 
 		recv(comm, proc, local_view(recv_dom));
 #if VSIP_IMPL_PA_VERBOSE
@@ -544,9 +546,9 @@
 
 	      if (intersect(src_dom, dst_dom, intr))
 	      {
-		Point<dim>  offset   = first(intr) - first(src_dom);
+		Index<dim>  offset   = first(intr) - first(src_dom);
 		Domain<dim> send_dom = domain(first(src_ldom) + offset,
-					      extent_old(intr));
+					      extent(intr));
 
 		send_list.push_back(Src_record(proc, local_view, send_dom));
 		send_size[proc] += impl::size(send_dom);
@@ -617,9 +619,9 @@
 
 	      if (intersect(dst_dom, src_dom, intr))
 	      {
-		Point<dim>  offset   = first(intr) - first(dst_dom);
+		Index<dim>  offset   = first(intr) - first(dst_dom);
 		Domain<dim> recv_dom = domain(first(dst_ldom) + offset,
-					      extent_old(intr));
+					      extent(intr));
 
 		recv_list.push_back(Dst_record(proc, local_view, recv_dom));
 		recv_size[proc] += impl::size(recv_dom);
@@ -675,10 +677,10 @@
 #if VSIP_IMPL_PA_VERBOSE
 	    std::cout << "(" << rank << "): - " << (*sl_cur).ldom_ << std::endl; 
 #endif
-	    for (Point<dim> idx; idx != extent_old((*sl_cur).ldom_);
-		 next(extent_old((*sl_cur).ldom_), idx))
+            Length<dim> ext = extent((*sl_cur).ldom_);
+	    for (Index<dim> idx; valid(ext,idx); next(ext, idx))
 	    {
-	      Point<dim> l_idx = domain_nth((*sl_cur).ldom_, idx);
+	      Index<dim> l_idx = domain_nth((*sl_cur).ldom_, idx);
 	      send_buf[buf_idx++] = get(local_view, l_idx);
 #if VSIP_IMPL_PA_VERBOSE
 		std::cout << "(" << rank << "): - " << idx << " "
@@ -729,10 +731,10 @@
 	  {
 	    dst_local_view local_view(*((*rl_cur).blk_.get()));
 	    // std::cout << "(" << rank << "): - " << *rl_cur << std::endl; 
-	    for (Point<dim> idx; idx != extent_old((*rl_cur).ldom_);
-		 next(extent_old((*rl_cur).ldom_), idx))
+	    Length<dim> ext = extent((*rl_cur).ldom_);
+	    for (Index<dim> idx; valid(ext,idx); next(ext, idx))
 	    {
-	      Point<dim> l_idx = domain_nth((*rl_cur).ldom_, idx);
+	      Index<dim> l_idx = domain_nth((*rl_cur).ldom_, idx);
 	      put(local_view, l_idx, recv_buf[recv_idx++]);
 	    }
 	  }
Index: src/vsip/impl/par-chain-assign.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/par-chain-assign.hpp,v
retrieving revision 1.18
diff -u -r1.18 par-chain-assign.hpp
--- src/vsip/impl/par-chain-assign.hpp	27 Mar 2006 23:19:34 -0000	1.18
+++ src/vsip/impl/par-chain-assign.hpp	3 Apr 2006 15:26:15 -0000
@@ -19,9 +19,8 @@
 
 #include <vsip/support.hpp>
 #include <vsip/impl/par-services.hpp>
-#include <vsip/impl/point.hpp>
-#include <vsip/impl/point-fcn.hpp>
 #include <vsip/impl/profile.hpp>
+#include <vsip/domain.hpp>
 
 #define VSIP_IMPL_PCA_ROTATE  0
 #define VSIP_IMPL_PCA_VERBOSE 0
@@ -478,9 +477,9 @@
 
 	    if (intersect(src_dom, dst_dom, intr))
 	    {
-	      Point<dim>  offset   = first(intr) - first(src_dom);
+	      Index<dim>  offset   = first(intr) - first(src_dom);
 	      Domain<dim> send_dom = domain(first(src_ldom) + offset,
-					    extent_old(intr));
+					    extent(intr));
 
 	      par_chain_assign::chain_add<dst_order_t>(builder, *ext, send_dom);
 
@@ -581,9 +580,9 @@
 	    
 	    if (intersect(dst_dom, src_dom, intr))
 	    {
-	      Point<dim>  offset   = first(intr) - first(dst_dom);
+	      Index<dim>  offset   = first(intr) - first(dst_dom);
 	      Domain<dim> recv_dom = domain(first(dst_ldom) + offset,
-					    extent_old(intr));
+					    extent(intr));
 	      
 	      par_chain_assign::chain_add<dst_order_t>(builder, *ext, recv_dom);
 	      
@@ -656,12 +655,12 @@
 
 	  if (intersect(src_dom, dst_dom, intr))
 	  {
-	    Point<dim>  send_offset = first(intr) - first(src_dom);
+	    Index<dim>  send_offset = first(intr) - first(src_dom);
 	    Domain<dim> send_dom    = domain(first(src_ldom) + send_offset,
-					     extent_old(intr));
-	    Point<dim>  recv_offset = first(intr) - first(dst_dom);
+					     extent(intr));
+	    Index<dim>  recv_offset = first(intr) - first(dst_dom);
 	    Domain<dim> recv_dom    = domain(first(dst_ldom) + recv_offset,
-					     extent_old(intr));
+					     extent(intr));
 
 	    copy_list.push_back(Copy_record(src_sb, dst_sb, send_dom, recv_dom));
 
Index: src/vsip/impl/par-foreach.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/par-foreach.hpp,v
retrieving revision 1.3
diff -u -r1.3 par-foreach.hpp
--- src/vsip/impl/par-foreach.hpp	3 Mar 2006 14:30:53 -0000	1.3
+++ src/vsip/impl/par-foreach.hpp	3 Apr 2006 15:26:15 -0000
@@ -19,8 +19,6 @@
 #include <vsip/vector.hpp>
 #include <vsip/matrix.hpp>
 #include <vsip/impl/distributed-block.hpp>
-#include <vsip/impl/point.hpp>
-#include <vsip/impl/point-fcn.hpp>
 #include <vsip/impl/par-util.hpp>
 
 
Index: src/vsip/impl/par-util.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/par-util.hpp,v
retrieving revision 1.8
diff -u -r1.8 par-util.hpp
--- src/vsip/impl/par-util.hpp	27 Mar 2006 23:19:34 -0000	1.8
+++ src/vsip/impl/par-util.hpp	3 Apr 2006 15:26:15 -0000
@@ -19,8 +19,7 @@
 #include <vsip/vector.hpp>
 #include <vsip/matrix.hpp>
 #include <vsip/impl/distributed-block.hpp>
-#include <vsip/impl/point.hpp>
-#include <vsip/impl/point-fcn.hpp>
+#include <vsip/domain.hpp>
 
 
 
@@ -113,10 +112,11 @@
       Domain<dim> ldom = local_domain(view, sb, p);
       Domain<dim> gdom = global_domain(view, sb, p);
 
-      for (Point<dim> idx; valid(extent_old(ldom), idx); next(extent_old(ldom), idx))
+      Length<dim> ext = extent(ldom);
+      for (Index<dim> idx; valid(ext,idx); next(ext, idx))
       {
-	Point<dim> l_idx = domain_nth(ldom, idx);
-	Point<dim> g_idx = domain_nth(gdom, idx);
+	Index<dim> l_idx = domain_nth(ldom, idx);
+	Index<dim> g_idx = domain_nth(gdom, idx);
 
 	put(local_view, l_idx, fcn(get(local_view, l_idx), l_idx, g_idx));
       }
Index: tests/appmap.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/appmap.cpp,v
retrieving revision 1.10
diff -u -r1.10 appmap.cpp
--- tests/appmap.cpp	27 Mar 2006 23:19:34 -0000	1.10
+++ tests/appmap.cpp	3 Apr 2006 15:26:15 -0000
@@ -13,14 +13,16 @@
 #include <vsip/support.hpp>
 #include <vsip/map.hpp>
 #include <vsip/matrix.hpp>
+#include <vsip/impl/length.hpp>
+#include <vsip/impl/domain-utils.hpp>
 #include "test.hpp"
 #include "output.hpp"
 
 using namespace std;
 using namespace vsip;
 
-using vsip::impl::Point;
-using vsip::impl::extent_old;
+using vsip::impl::Length;
+using vsip::impl::extent;
 using vsip::impl::valid;
 using vsip::impl::next;
 using vsip::impl::domain_nth;
@@ -95,12 +97,6 @@
 
 
 
-inline Index<1> as_index(Point<1> const& p) {return Index<1>(p[0]); }
-inline Index<2> as_index(Point<2> const& p) {return Index<2>(p[0],p[1]); }
-inline Index<3> as_index(Point<3> const& p) {return Index<3>(p[0],p[1],p[2]); }
-
-
-
 // Check that local and global indices within a patch are consistent.
 
 template <dimension_type Dim,
@@ -147,16 +143,16 @@
     }
   }
 
-  Point<Dim> ext = extent_old(gdom);
 
-  for (Point<Dim> idx; valid(ext, idx); next(ext, idx))
+  Length<Dim> ext = extent(gdom);
+  for(Index<Dim> idx; valid(ext,idx); next(ext,idx))
   {
-    Index<Dim> g_idx = as_index(domain_nth(gdom, idx));
-    Index<Dim> l_idx = as_index(domain_nth(ldom, idx));
-
+    Index<Dim> g_idx = domain_nth(gdom,idx);
+    Index<Dim> l_idx = domain_nth(ldom,idx);
     test_assert(map.impl_subblock_from_global_index(g_idx) == sb);
     test_assert(map.impl_patch_from_global_index(g_idx)    == p);
   }
+
 }
 
 
Index: tests/fast-block.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/fast-block.cpp,v
retrieving revision 1.6
diff -u -r1.6 fast-block.cpp
--- tests/fast-block.cpp	20 Dec 2005 12:48:40 -0000	1.6
+++ tests/fast-block.cpp	3 Apr 2006 15:26:15 -0000
@@ -13,16 +13,18 @@
 #include <iostream>
 #include <cassert>
 #include <vsip/support.hpp>
-#include <vsip/impl/point.hpp>
-#include <vsip/impl/point-fcn.hpp>
 #include <vsip/impl/fast-block.hpp>
+#include <vsip/impl/length.hpp>
+#include <vsip/impl/domain-utils.hpp>
 #include "test.hpp"
 
 using namespace std;
 using namespace vsip;
 
-using vsip::impl::Point;
-using vsip::impl::extent_old;
+using vsip::impl::Length;
+using vsip::impl::extent;
+using vsip::impl::valid;
+using vsip::impl::next;
 
 
 
@@ -30,33 +32,31 @@
   Definitions
 ***********************************************************************/
 
+
 template <typename T>
 inline T
 identity(
-  Point<1> /*extent*/,
-  Point<1> idx,
+  Length<1> /*extent*/,
+  Index<1> idx,
   int      k)
 {
   return static_cast<T>(k*idx[0] + 1);
 }
 
 
-
 template <typename T>
 inline T
 identity(
-  Point<2> extent,
-  Point<2> idx,
-  int      k)
+  Length<2> extent,
+  Index<2>  idx,
+  int       k)
 {
-  Point<2> offset;
+  Index<2> offset;
   index_type i = (idx[0]+offset[0])*extent[1] + (idx[1]+offset[1]);
   return static_cast<T>(k*i+1);
 }
 
 
-
-
 template <dimension_type Dim,
 	  typename       Block>
 void
@@ -64,15 +64,14 @@
 {
   typedef typename Block::value_type value_type;
 
-  Point<Dim> ex = extent_old<Dim>(blk);
-  for (Point<Dim> idx; idx != ex; next(ex, idx))
+  Length<Dim> ex = extent<Dim>(blk);
+  for (Index<Dim> idx; valid(ex,idx); next(ex, idx))
   {
     put(blk, idx, identity<value_type>(ex, idx, k));
   }
 }
 
 
-
 template <dimension_type Dim,
 	  typename       Block>
 void
@@ -80,8 +79,8 @@
 {
   typedef typename Block::value_type value_type;
 
-  Point<Dim> ex = extent_old<Dim>(blk);
-  for (Point<Dim> idx; idx != ex; next(ex, idx))
+  Length<Dim> ex = extent<Dim>(blk);
+  for (Index<Dim> idx; valid(ex,idx); next(ex, idx))
   {
     test_assert(equal( get(blk, idx),
 		  identity<value_type>(ex, idx, k)));
@@ -89,7 +88,6 @@
 }
 
 
-
 template <dimension_type Dim,
 	  typename       Block>
 void
Index: tests/output.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/output.hpp,v
retrieving revision 1.2
diff -u -r1.2 output.hpp
--- tests/output.hpp	20 Dec 2005 12:48:41 -0000	1.2
+++ tests/output.hpp	3 Apr 2006 15:26:15 -0000
@@ -17,7 +17,7 @@
 #include <vsip/domain.hpp>
 #include <vsip/vector.hpp>
 #include <vsip/matrix.hpp>
-#include <vsip/impl/point.hpp>
+#include <vsip/domain.hpp>
 
 
 
@@ -116,14 +116,14 @@
 }
 
 
-/// Write a point to a stream.
+/// Write an Index to a stream.
 
 template <vsip::dimension_type Dim>
 inline
 std::ostream&
 operator<<(
   std::ostream&		        out,
-  vsip::impl::Point<Dim> const& idx)
+  vsip::Index<Dim> const& idx)
   VSIP_NOTHROW
 {
   out << "(";
Index: tests/us-block.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/us-block.cpp,v
retrieving revision 1.1
diff -u -r1.1 us-block.cpp
--- tests/us-block.cpp	10 Feb 2006 22:24:02 -0000	1.1
+++ tests/us-block.cpp	3 Apr 2006 15:26:15 -0000
@@ -13,17 +13,17 @@
 #include <iostream>
 #include <cassert>
 #include <vsip/support.hpp>
-#include <vsip/impl/point.hpp>
-#include <vsip/impl/point-fcn.hpp>
 #include <vsip/impl/us-block.hpp>
+#include <vsip/impl/length.hpp>
+#include <vsip/impl/domain-utils.hpp>
 
 #include "test.hpp"
 
 using namespace std;
 using namespace vsip;
 
-using vsip::impl::Point;
-using vsip::impl::extent_old;
+using vsip::impl::Length;
+using vsip::impl::extent;
 
 
 
@@ -31,32 +31,31 @@
   Definitions
 ***********************************************************************/
 
+
 template <typename T>
 inline T
 identity(
-  Point<1> /*extent*/,
-  Point<1> idx,
+  Length<1> /*extent*/,
+  Index<1> idx,
   int      k)
 {
   return static_cast<T>(k*idx[0] + 1);
 }
 
 
-
 template <typename T>
 inline T
 identity(
-  Point<2> extent,
-  Point<2> idx,
-  int      k)
+  Length<2> extent,
+  Index<2>  idx,
+  int       k)
 {
-  Point<2> offset;
+  Index<2> offset;
   index_type i = (idx[0]+offset[0])*extent[1] + (idx[1]+offset[1]);
   return static_cast<T>(k*i+1);
 }
 
 
-
 template <dimension_type Dim,
 	  typename       Block>
 void
@@ -64,15 +63,14 @@
 {
   typedef typename Block::value_type value_type;
 
-  Point<Dim> ex = extent_old<Dim>(blk);
-  for (Point<Dim> idx; idx != ex; next(ex, idx))
+  Length<Dim> ex = extent<Dim>(blk);
+  for (Index<Dim> idx; valid(ex,idx); next(ex, idx))
   {
     put(blk, idx, identity<value_type>(ex, idx, k));
   }
 }
 
 
-
 template <dimension_type Dim,
 	  typename       Block>
 void
@@ -80,16 +78,17 @@
 {
   typedef typename Block::value_type value_type;
 
-  Point<Dim> ex = extent_old<Dim>(blk);
-  for (Point<Dim> idx; idx != ex; next(ex, idx))
+  Length<Dim> ex = extent<Dim>(blk);
+  for (Index<Dim> idx; valid(ex,idx); next(ex, idx))
   {
     test_assert(equal( get(blk, idx),
-		       identity<value_type>(ex, idx, k)));
+		  identity<value_type>(ex, idx, k)));
   }
 }
 
 
 
+
 template <dimension_type Dim,
 	  typename       BlockT>
 void
Index: tests/user_storage.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/user_storage.cpp,v
retrieving revision 1.6
diff -u -r1.6 user_storage.cpp
--- tests/user_storage.cpp	20 Dec 2005 12:48:41 -0000	1.6
+++ tests/user_storage.cpp	3 Apr 2006 15:26:15 -0000
@@ -14,27 +14,25 @@
 #include <cassert>
 #include <vsip/support.hpp>
 #include <vsip/dense.hpp>
-#include <vsip/impl/point.hpp>
-#include <vsip/impl/point-fcn.hpp>
 #include <vsip/impl/domain-utils.hpp>
+#include <vsip/impl/length.hpp>
 #include "test.hpp"
 
 using namespace std;
 using namespace vsip;
 
-using vsip::impl::Point;
+using vsip::impl::Length;
 
 
 
 /***********************************************************************
   Definitions
 ***********************************************************************/
-
 template <typename       Order,
 	  dimension_type Dim>
 index_type
-to_index(Point<Dim> const& ext,
-	 Point<Dim> const& idx)
+to_index(Length<Dim> const& ext,
+	 Index<Dim>  const& idx)
 {
   if (Dim == 1)
     return idx[0];
@@ -47,7 +45,6 @@
 }
 	  
 
-
 template <typename       Order,
 	  typename       T,
 	  dimension_type Dim,
@@ -58,8 +55,8 @@
   Domain<Dim> const& dom,
   Func               fun)
 {
-  Point<Dim> ext = impl::extent_old(dom);
-  for (Point<Dim> idx; idx != ext; next(ext, idx))
+  Length<Dim> ext = impl::extent(dom);
+  for (Index<Dim> idx; valid(ext, idx); next(ext, idx))
   {
     index_type i = to_index<Order>(ext, idx);
     data[i] = fun(i);
@@ -67,7 +64,6 @@
 }
 
 
-
 template <typename       Order,
 	  typename       T,
 	  dimension_type Dim,
@@ -78,8 +74,8 @@
   Domain<Dim> const& dom,
   Func               fun)
 {
-  Point<Dim> ext = impl::extent_old(dom);
-  for (Point<Dim> idx; idx != ext; next(ext, idx))
+  Length<Dim> ext = impl::extent(dom);
+  for (Index<Dim> idx; valid(ext,idx); next(ext, idx))
   {
     index_type i = to_index<Order>(ext, idx);
     if (!equal(data[i], fun(i)))
@@ -89,7 +85,6 @@
 }
 
 
-
 template <typename       Order,
 	  typename       T,
 	  dimension_type Dim,
@@ -100,8 +95,8 @@
   Domain<Dim> const& dom,
   Func               fun)
 {
-  Point<Dim> ext = impl::extent_old(dom);
-  for (Point<Dim> idx; idx != ext; next(ext, idx))
+  Length<Dim> ext = impl::extent(dom);
+  for (Index<Dim> idx; valid(ext,idx); next(ext, idx))
   {
     index_type i = to_index<Order>(ext, idx);
     complex<T> val = fun(i);
@@ -111,7 +106,6 @@
 }
 
 
-
 template <typename       Order,
 	  typename       T,
 	  dimension_type Dim,
@@ -122,8 +116,8 @@
   Domain<Dim> const& dom,
   Func               fun)
 {
-  Point<Dim> ext = impl::extent_old(dom);
-  for (Point<Dim> idx; idx != ext; next(ext, idx))
+  Length<Dim> ext = impl::extent(dom);
+  for (Index<Dim> idx; valid(ext,idx); next(ext, idx))
   {
     index_type i = to_index<Order>(ext, idx);
     complex<T> val = fun(i);
@@ -135,7 +129,6 @@
 }
 
 
-
 template <typename       Order,
 	  typename       T,
 	  dimension_type Dim,
@@ -147,8 +140,8 @@
   Domain<Dim> const& dom,
   Func               fun)
 {
-  Point<Dim> ext = impl::extent_old(dom);
-  for (Point<Dim> idx; idx != ext; next(ext, idx))
+  Length<Dim> ext = impl::extent(dom);
+  for (Index<Dim> idx; valid(ext,idx); next(ext, idx))
   {
     index_type i = to_index<Order>(ext, idx);
     complex<T> val = fun(i);
@@ -158,7 +151,6 @@
 }
 
 
-
 template <typename       Order,
 	  typename       T,
 	  dimension_type Dim,
@@ -170,8 +162,8 @@
   Domain<Dim> const& dom,
   Func               fun)
 {
-  Point<Dim> ext = impl::extent_old(dom);
-  for (Point<Dim> idx; idx != ext; next(ext, idx))
+  Length<Dim> ext = impl::extent(dom);
+  for (Index<Dim> idx; valid(ext,idx); next(ext, idx))
   {
     index_type i = to_index<Order>(ext, idx);
     complex<T> val = fun(i);
@@ -182,8 +174,6 @@
   return true;
 }
 
-
-
 template <typename       Order,
 	  typename       Block,
 	  dimension_type Dim,
@@ -194,16 +184,14 @@
   Domain<Dim> const& dom,
   Func               fun)
 {
-  Point<Dim> ext = impl::extent_old(dom);
-  for (Point<Dim> idx; idx != ext; next(ext, idx))
+  Length<Dim> ext = impl::extent(dom);
+  for (Index<Dim> idx; valid(ext,idx); next(ext, idx))
   {
     index_type i = to_index<Order>(ext, idx);
     put(block, idx, fun(i));
   }
 }
 
-
-
 template <typename       Order,
 	  typename       Block,
 	  dimension_type Dim,
@@ -214,8 +202,8 @@
   Domain<Dim> const& dom,
   Func               fun)
 {
-  Point<Dim> ext = impl::extent_old(dom);
-  for (Point<Dim> idx; idx != ext; next(ext, idx))
+  Length<Dim> ext = impl::extent(dom);
+  for (Index<Dim> idx; valid(ext,idx); next(ext, idx))
   {
     index_type i = to_index<Order>(ext, idx);
     if (!equal(get(block, idx), fun(i)))
@@ -224,7 +212,6 @@
   return true;
 }
 
-
 template <typename T>
 class Filler
 {
Index: tests/util-par.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/util-par.hpp,v
retrieving revision 1.8
diff -u -r1.8 util-par.hpp
--- tests/util-par.hpp	27 Mar 2006 23:19:34 -0000	1.8
+++ tests/util-par.hpp	3 Apr 2006 15:26:15 -0000
@@ -20,6 +20,7 @@
 #include <vsip/vector.hpp>
 #include <vsip/matrix.hpp>
 #include <vsip/parallel.hpp>
+#include <vsip/domain.hpp>
 
 #include "output.hpp"
 #include "extdata-output.hpp"
@@ -276,8 +277,8 @@
   Increment(T delta) : delta_(delta) {}
 
   T operator()(T value,
-	       vsip::impl::Point<Dim> const&,
-	       vsip::impl::Point<Dim> const&)
+	       vsip::Index<Dim> const&,
+	       vsip::Index<Dim> const&)
     { return value + delta_; }
 
   // Member Data
@@ -294,19 +295,20 @@
 class Set_identity
 {
 public:
+
   Set_identity(vsip::Domain<Dim> const& dom, int k = 1, int o = 0)
     : dom_(dom), k_(k), o_(o) {}
 
   template <typename T>
   T operator()(T /*value*/,
-	       vsip::impl::Point<1> const& /*local*/,
-	       vsip::impl::Point<1> const& global)
+	       vsip::Index<1> const& /*local*/,
+	       vsip::Index<1> const& global)
     { return T(k_*global[0] + o_); }
 
   template <typename T>
   T operator()(T /*value*/,
-	       vsip::impl::Point<2> const& /*local*/,
-	       vsip::impl::Point<2> const& global)
+	       vsip::Index<2> const& /*local*/,
+	       vsip::Index<2> const& global)
   {
     vsip::index_type i = global[0]*dom_[1].length()+global[1];
     return T(k_*i+o_);
@@ -314,8 +316,8 @@
 
   template <typename T>
   T operator()(T /*value*/,
-	       vsip::impl::Point<3> const& /*local*/,
-	       vsip::impl::Point<3> const& global)
+	       vsip::Index<3> const& /*local*/,
+	       vsip::Index<3> const& global)
   {
     vsip::index_type i = global[0]*dom_[1].length()*dom_[2].length()
                        + global[1]*dom_[2].length()
@@ -343,10 +345,11 @@
 
   bool good() { return good_; }
 
+
   template <typename T>
   T operator()(T value,
-	       vsip::impl::Point<1> const& /*local*/,
-	       vsip::impl::Point<1> const& global)
+	       vsip::Index<1> const& /*local*/,
+	       vsip::Index<1> const& global)
   {
     int i = global[0];
     T expected = T(k_*i + o_);
@@ -363,8 +366,8 @@
 
   template <typename T>
   T operator()(T value,
-	       vsip::impl::Point<2> const& /*local*/,
-	       vsip::impl::Point<2> const& global)
+	       vsip::Index<2> const& /*local*/,
+	       vsip::Index<2> const& global)
   {
     int i = global[0]*dom_[1].length()+global[1];
     T expected = T(k_*i+o_);
@@ -383,8 +386,8 @@
 
   template <typename T>
   T operator()(T value,
-	       vsip::impl::Point<3> const& /*local*/,
-	       vsip::impl::Point<3> const& global)
+	       vsip::Index<3> const& /*local*/,
+	       vsip::Index<3> const& global)
   {
     int i = global[0]*dom_[1].length()*dom_[2].length()
           + global[1]*dom_[2].length()
Index: tests/view.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/view.cpp,v
retrieving revision 1.10
diff -u -r1.10 view.cpp
--- tests/view.cpp	20 Dec 2005 12:48:41 -0000	1.10
+++ tests/view.cpp	3 Apr 2006 15:26:15 -0000
@@ -20,17 +20,16 @@
 #include <vsip/support.hpp>
 #include <vsip/vector.hpp>
 #include <vsip/matrix.hpp>
-#include <vsip/impl/point.hpp>
 #include <vsip/domain.hpp>
-#include <vsip/impl/point-fcn.hpp>
+#include <vsip/impl/length.hpp>
+#include <vsip/impl/domain-utils.hpp>
 #include "test.hpp"
 #include "test-storage.hpp"
 
 using namespace std;
 using namespace vsip;
 
-using vsip::impl::Point;
-using vsip::impl::extent_old;
+using vsip::impl::Length;
 
 
 
@@ -348,6 +347,7 @@
 
 // Check that all elements of a view have the same const values
 
+
 template <typename View>
 bool
 check_view_const(
@@ -355,7 +355,8 @@
   typename View::value_type scalar)
 {
   dimension_type const dim = View::dim;
-  for (Point<dim> idx; idx != extent_old(view); next(extent_old(view), idx))
+  Length<dim> ext = extent(view);
+  for (Index<dim> idx; valid(ext,idx); next(ext, idx))
   {
     if (!equal(get(view, idx), scalar))
       return false;
Index: tests/vmmul.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/vmmul.cpp,v
retrieving revision 1.4
diff -u -r1.4 vmmul.cpp
--- tests/vmmul.cpp	20 Dec 2005 12:48:41 -0000	1.4
+++ tests/vmmul.cpp	3 Apr 2006 15:26:15 -0000
@@ -19,6 +19,8 @@
 #include <vsip/map.hpp>
 #include <vsip/parallel.hpp>
 #include <vsip/math.hpp>
+#include <vsip/domain.hpp>
+#include <vsip/impl/domain-utils.hpp>
 
 #include "test.hpp"
 #include "util-par.hpp"
@@ -87,8 +89,8 @@
 
   template <typename T>
   T operator()(T value,
-	       vsip::impl::Point<2> const& /*local*/,
-	       vsip::impl::Point<2> const& global)
+	       vsip::Index<2> const& /*local*/,
+	       vsip::Index<2> const& global)
   {
     vsip::index_type i = global[0]*dom_[1].length()+global[1];
     T expected = (VecDim == 0) ? T(global[1] * i) : T(global[0] * i);
Index: tests/parallel/block.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/parallel/block.cpp,v
retrieving revision 1.2
diff -u -r1.2 block.cpp
--- tests/parallel/block.cpp	27 Mar 2006 23:19:34 -0000	1.2
+++ tests/parallel/block.cpp	3 Apr 2006 15:26:15 -0000
@@ -19,6 +19,8 @@
 #include <vsip/map.hpp>
 #include <vsip/tensor.hpp>
 #include <vsip/parallel.hpp>
+#include <vsip/impl/length.hpp>
+#include <vsip/impl/domain-utils.hpp>
 
 #if TEST_OLD_PAR_ASSIGN
 #include <vsip/impl/par-assign.hpp>
@@ -32,8 +34,8 @@
 using namespace std;
 using namespace vsip;
 
-using vsip::impl::Point;
-using vsip::impl::extent_old;
+using vsip::impl::Length;
+using vsip::impl::extent;
 using vsip::impl::View_of_dim;
 
 
@@ -183,12 +185,12 @@
   if (local_processor() == 0) 
   {
     // On processor 0, local_view should be entire view.
-    test_assert(extent_old(local_view) == extent_old(dom));
+    test_assert(extent(local_view) == extent(dom));
 
     // Check that each value is correct.
     bool good = true;
-    for (Point<Dim> idx; idx != extent_old(local_view);
-	 next(extent_old(local_view), idx))
+    Length<Dim> ext = extent(local_view);
+    for (Index<Dim> idx; valid(ext,idx); next(ext, idx))
     {
       T expected_value = T();
       for (dimension_type d=0; d<Dim; ++d)
@@ -284,12 +286,12 @@
     typename view0_t::local_type local_view = view0.local();
 
     // Check that local_view is in fact the entire view.
-    test_assert(extent_old(local_view) == extent_old(dom));
+    test_assert(extent(local_view) == extent(dom));
 
     // Check that each value is correct.
     bool good = true;
-    for (Point<Dim> idx; idx != extent_old(local_view);
-	 next(extent_old(local_view), idx))
+    Length<Dim> ext = extent(local_view);
+    for (Index<Dim> idx; valid(ext,idx); next(ext, idx))
     {
       T expected_value = T();
       for (dimension_type d=0; d<Dim; ++d)
Index: tests/parallel/expr.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/parallel/expr.cpp,v
retrieving revision 1.2
diff -u -r1.2 expr.cpp
--- tests/parallel/expr.cpp	27 Mar 2006 23:19:35 -0000	1.2
+++ tests/parallel/expr.cpp	3 Apr 2006 15:26:15 -0000
@@ -18,6 +18,8 @@
 #include <vsip/map.hpp>
 #include <vsip/math.hpp>
 #include <vsip/parallel.hpp>
+#include <vsip/impl/length.hpp>
+#include <vsip/impl/domain-utils.hpp>
 
 #include "test.hpp"
 #include "output.hpp"
@@ -27,8 +29,10 @@
 using namespace std;
 using namespace vsip;
 
-using vsip::impl::Point;
-using vsip::impl::extent_old;
+using vsip::impl::Length;
+using vsip::impl::valid;
+using vsip::impl::extent;
+using vsip::impl::next;
 using vsip::impl::View_of_dim;
 
 
@@ -218,12 +222,12 @@
     typename view0_t::local_type local_view = chk1.local();
 
     // Check that local_view is in fact the entire view.
-    test_assert(extent_old(local_view) == extent_old(dom));
+    test_assert(extent(local_view) == extent(dom));
 
     // Check that each value is correct.
     bool good = true;
-    for (Point<Dim> idx; idx != extent_old(local_view);
-	 next(extent_old(local_view), idx))
+    Length<Dim> ext = extent(local_view);
+    for (Index<Dim> idx; valid(ext,idx); next(ext, idx))
     {
       T value = T();
       for (dimension_type d=0; d<Dim; ++d)
@@ -330,12 +334,12 @@
     typename view0_t::local_type local_view = chk1.local();
 
     // Check that local_view is in fact the entire view.
-    test_assert(extent_old(local_view) == extent_old(dom));
+    test_assert(extent(local_view) == extent(dom));
 
     // Check that each value is correct.
     bool good = true;
-    for (Point<Dim> idx; idx != extent_old(local_view);
-	 next(extent_old(local_view), idx))
+    Length<Dim> ext = extent(local_view);
+    for (Index<Dim> idx; valid(ext,idx); next(ext, idx))
     {
       T val = T();
       for (dimension_type d=0; d<Dim; ++d)
@@ -439,12 +443,12 @@
     typename view0_t::local_type local_view = chk.local();
 
     // Check that local_view is in fact the entire view.
-    test_assert(extent_old(local_view) == extent_old(dom));
+    test_assert(extent(local_view) == extent(dom));
 
     // Check that each value is correct.
     bool good = true;
-    for (Point<Dim> idx; idx != extent_old(local_view);
-	 next(extent_old(local_view), idx))
+    Length<Dim> ext = extent(local_view);
+    for (Index<Dim> idx; valid(ext,idx); next(ext, idx))
     {
       T expected_value = T();
       for (dimension_type d=0; d<Dim; ++d)
Index: tests/parallel/subviews.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/parallel/subviews.cpp,v
retrieving revision 1.2
diff -u -r1.2 subviews.cpp
--- tests/parallel/subviews.cpp	27 Mar 2006 23:19:35 -0000	1.2
+++ tests/parallel/subviews.cpp	3 Apr 2006 15:26:15 -0000
@@ -30,7 +30,6 @@
 using namespace std;
 using namespace vsip;
 
-using vsip::impl::Point;
 using vsip::impl::View_of_dim;
 
 
