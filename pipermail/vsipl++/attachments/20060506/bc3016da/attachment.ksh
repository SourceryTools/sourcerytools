Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.451
diff -u -r1.451 ChangeLog
--- ChangeLog	3 May 2006 18:43:09 -0000	1.451
+++ ChangeLog	6 May 2006 19:49:02 -0000
@@ -1,3 +1,12 @@
+2006-05-06  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/block-copy.hpp: Add run-time block copy.
+	* src/vsip/impl/extdata.hpp: Fix typo in comment.
+	* src/vsip/impl/layout.hpp: Add run-time layout definitions.
+	* src/vsip/impl/rt_extdata.hpp: New file, implements run-time
+	  external data access (Rt_ext_data).
+	* tests/rt_extdata.cpp: New file, unit-tests for rt_extdata.
+	
 2006-05-02  Jules Bergmann  <jules@codesourcery.com>
 
 	* configure.ac: Add --with-lapack=acml option to use AMD Core Math
Index: src/vsip/impl/block-copy.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/block-copy.hpp,v
retrieving revision 1.12
diff -u -r1.12 block-copy.hpp
--- src/vsip/impl/block-copy.hpp	4 Apr 2006 02:21:12 -0000	1.12
+++ src/vsip/impl/block-copy.hpp	6 May 2006 19:49:02 -0000
@@ -71,6 +71,155 @@
 };
 
 
+
+/// Implementation class to copy block data into/out-of of regular memory,
+/// with layout determined at run-time.
+
+/// Requires:
+///   DIM is the dimension of the run-time layout.
+///   BLOCK is a block type,
+///   ISCOMPLEX indicates whether the value type is complex
+///
+/// ISCOMPLEX is used to specialize the implementation so that functions
+/// can be overloaded for split and interleaved arguments.
+
+template <dimension_type Dim,
+	  typename       Block,
+	  bool           IsComplex>
+struct Rt_block_copy_impl;
+
+/// Specialization for blocks with complex value_types.
+
+template <dimension_type Dim,
+	  typename       Block>
+struct Rt_block_copy_impl<Dim, Block, true>
+{
+  typedef Applied_layout<Rt_layout<Dim> > LP;
+
+  typedef Storage<Cmplx_inter_fmt, typename Block::value_type>
+	  inter_storage_type;
+  typedef Storage<Cmplx_split_fmt, typename Block::value_type>
+	  split_storage_type;
+
+  typedef typename inter_storage_type::type inter_ptr_type;
+  typedef typename split_storage_type::type split_ptr_type;
+
+  typedef Rt_pointer<typename Block::value_type> rt_ptr_type;
+
+  static void copy_in (Block* block, LP const& layout, inter_ptr_type data)
+  {
+    Length<Dim> ext = extent<Dim>(*block);
+
+    for (Index<Dim> idx; valid(ext, idx); next(ext, idx))
+      inter_storage_type::put(data, layout.index(idx), get(*block, idx));
+  }
+
+  static void copy_in (Block* block, LP const& layout, split_ptr_type data)
+  {
+    Length<Dim> ext = extent<Dim>(*block);
+
+    for (Index<Dim> idx; valid(ext, idx); next(ext, idx))
+      split_storage_type::put(data, layout.index(idx), get(*block, idx));
+  }
+
+  static void copy_in (Block* block, LP const& layout, rt_ptr_type data)
+  {
+    if (complex_format(layout) == cmplx_inter_fmt)
+      copy_in(block, layout, data.as_inter());
+    else
+      copy_in(block, layout, data.as_split());
+  }
+
+  static void copy_out(Block* block, LP const& layout, inter_ptr_type data)
+  {
+    Length<Dim> ext = extent<Dim>(*block);
+
+    for (Index<Dim> idx; valid(ext, idx); next(ext, idx))
+      put(*block, idx, inter_storage_type::get(data, layout.index(idx)));
+  }
+
+  static void copy_out(Block* block, LP const& layout, split_ptr_type data)
+  {
+    Length<Dim> ext = extent<Dim>(*block);
+
+    for (Index<Dim> idx; valid(ext, idx); next(ext, idx))
+      put(*block, idx, split_storage_type::get(data, layout.index(idx)));
+  }
+
+  static void copy_out(Block* block, LP const& layout, rt_ptr_type data)
+  {
+    if (complex_format(layout) == cmplx_inter_fmt)
+      copy_out(block, layout, data.as_inter());
+    else
+      copy_out(block, layout, data.as_split());
+  }
+};
+
+
+
+/// Specialization for blocks with non-complex value_types.
+
+template <dimension_type Dim,
+	  typename       Block>
+struct Rt_block_copy_impl<Dim, Block, false>
+{
+  typedef Applied_layout<Rt_layout<Dim> > LP;
+
+  typedef Storage<Cmplx_inter_fmt, typename Block::value_type>
+	  inter_storage_type;
+
+  typedef typename inter_storage_type::type inter_ptr_type;
+  typedef Rt_pointer<typename Block::value_type> rt_ptr_type;
+
+
+  static void copy_in (Block* block, LP const& layout, inter_ptr_type data)
+  {
+    Length<Dim> ext = extent<Dim>(*block);
+
+    for (Index<Dim> idx; valid(ext, idx); next(ext, idx))
+      inter_storage_type::put(data, layout.index(idx), get(*block, idx));
+  }
+
+  static void copy_in (Block* block, LP const& layout, rt_ptr_type data)
+  {
+    assert(complex_format(layout) == cmplx_inter_fmt);
+    copy_in(block, layout, data.as_inter());
+  }
+
+  static void copy_out(Block* block, LP const& layout, inter_ptr_type data)
+  {
+    Length<Dim> ext = extent<Dim>(*block);
+
+    for (Index<Dim> idx; valid(ext, idx); next(ext, idx))
+      put(*block, idx, inter_storage_type::get(data, layout.index(idx)));
+  }
+
+  static void copy_out(Block* block, LP const& layout, rt_ptr_type data)
+  {
+    assert(complex_format(layout) == cmplx_inter_fmt);
+    copy_out(block, layout, data.as_inter());
+  }
+};
+
+
+
+/// Utility class to copy block data into/out-of of regular memory,
+/// with layout determined at run-time.
+
+/// Requires:
+///   DIM is the dimension of the run-time layout,
+///   BLOCK is a block type.
+
+template <dimension_type Dim,
+	  typename       Block>
+struct Rt_block_copy
+  : Rt_block_copy_impl<Dim, Block,
+		    vsip::impl::Is_complex<typename Block::value_type>::value>
+{
+};
+
+
+
 template <dimension_type Dim,
 	  typename       BlockT,
 	  typename       OrderT  = typename Block_layout<BlockT>::order_type,
Index: src/vsip/impl/extdata.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/extdata.hpp,v
retrieving revision 1.19
diff -u -r1.19 extdata.hpp
--- src/vsip/impl/extdata.hpp	4 Apr 2006 02:21:12 -0000	1.19
+++ src/vsip/impl/extdata.hpp	6 May 2006 19:49:02 -0000
@@ -848,4 +848,4 @@
 } // namespace vsip::impl
 } // namespace vsip
 
-#endif // VSIP_IMPL_EXTDATA2_HPP
+#endif // VSIP_IMPL_EXTDATA_HPP
Index: src/vsip/impl/layout.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/layout.hpp,v
retrieving revision 1.20
diff -u -r1.20 layout.hpp
--- src/vsip/impl/layout.hpp	4 Apr 2006 02:21:13 -0000	1.20
+++ src/vsip/impl/layout.hpp	6 May 2006 19:49:02 -0000
@@ -18,6 +18,7 @@
 #include <vsip/domain.hpp>
 #include <vsip/impl/length.hpp>
 #include <vsip/impl/aligned_allocator.hpp>
+#include <vsip/impl/metaprogramming.hpp>
 
 
 using vsip::Index;
@@ -32,6 +33,107 @@
 namespace impl
 {
 
+/// Class to represent either a interleaved-pointer or a split-pointer.
+
+/// Primary definition handles non-complex types.  Functions
+/// corresponding to split-pointer cause a runtime error, since
+/// "split" does not make sense for non-complex types.
+
+template <typename T>
+class Rt_pointer
+{
+  // Constructors
+public:
+  // Default constructor creates a NULL pointer.
+  Rt_pointer() : ptr_(0) {}
+
+  Rt_pointer(T* ptr) : ptr_(ptr) {}
+  Rt_pointer(std::pair<T*, T*> const&) { assert(0); }
+
+
+  // Accessors.
+public:
+  T*               as_inter() { return ptr_; }
+  std::pair<T*,T*> as_split() { assert(0); return std::pair<T*,T*>(0,0); }
+
+  bool is_null() { return ptr_ == 0; }
+
+  // Member data.
+private:
+  T* ptr_;
+};
+
+
+
+/// Specialization for complex types.  Whether a Rt_pointer refers to a
+/// interleaved or split pointer is determined by the using code.
+/// (However, when initializing an interleaved pointer, ptr1_ is set
+/// to NULL).
+
+template <typename T>
+class Rt_pointer<complex<T> >
+{
+  // Constructors.
+public:
+  // Default constructor creates a NULL pointer.
+  Rt_pointer() : ptr0_(0), ptr1_(0) {}
+
+  Rt_pointer(complex<T>* ptr)
+    : ptr0_(reinterpret_cast<T*>(ptr)), ptr1_(0)
+  {}
+
+  Rt_pointer(std::pair<T*, T*> const& ptr)
+    : ptr0_(ptr.first), ptr1_(ptr.second)
+  {}
+
+  // Acccessors
+public:
+  complex<T>*       as_inter() { return reinterpret_cast<complex<T>*>(ptr0_); }
+  std::pair<T*, T*> as_split() { return std::pair<T*,T*>(ptr0_, ptr1_); }
+
+  bool is_null() { return ptr0_ == 0; }
+
+  // Member data.
+private:
+  T* ptr0_;
+  T* ptr1_;
+};
+
+
+
+/// Runtime dimension-order (corresponds to compile-time tuples).
+
+/// Member names are chosen to correspond to tuple's.
+
+class Rt_tuple
+{
+  // Constructors.
+public:
+  Rt_tuple()
+    : impl_dim0(0), impl_dim1(1), impl_dim2(2)
+  {}
+
+  Rt_tuple(dimension_type d0, dimension_type d1, dimension_type d2)
+    : impl_dim0(d0), impl_dim1(d1), impl_dim2(d2)
+  {}
+
+  // Convenience constructor from a compile-time tuple.
+  template <dimension_type D0,
+	    dimension_type D1,
+	    dimension_type D2>
+  Rt_tuple(tuple<D0, D1, D2>)
+    : impl_dim0(D0), impl_dim1(D1), impl_dim2(D2)
+  {}
+
+  // Member data.
+public:
+  dimension_type impl_dim0;
+  dimension_type impl_dim1;
+  dimension_type impl_dim2;
+};
+
+
+
 struct Any_type;
 
 
@@ -60,6 +162,17 @@
 { static bool const is_ct_unit_stride = true; };
 
 
+/// Runtime packing format enum.
+
+enum rt_pack_type
+{
+  stride_unknown,
+  stride_unit,
+  stride_unit_dense,
+  stride_unit_align
+};
+
+
 
 template <typename PackFmt>
 struct Is_stride_unit_align
@@ -86,6 +199,14 @@
 struct Cmplx_inter_fmt {};
 struct Cmplx_split_fmt {};
 
+/// Runtime complex format enum.
+
+enum rt_complex_type
+{
+  cmplx_split_fmt,
+  cmplx_inter_fmt
+};
+
 
 
 /// Validity check for packing format tags.
@@ -137,9 +258,13 @@
 	  typename       PackType,
 	  typename	 ComplexType = Cmplx_inter_fmt>
 struct Layout
-  : Valid_pack_type<PackType>,
-    Valid_order<Order>,
-    Valid_complex_fmt<ComplexType>
+  : Valid_pack_type<PackType>
+  , Valid_order<Order>
+#if !(defined(__GNUC__) && __GNUC__ < 4)
+  // G++ 3.4.4 enters an infinite loop processing this compile-time
+  // assertion (060505).  G++ 4.1 is OK.
+  , Valid_complex_fmt<ComplexType>
+#endif
 {
   static dimension_type const dim = D;
   typedef PackType    pack_type;
@@ -149,6 +274,25 @@
 
 
 
+/// Runtime layout class encapsulating:
+///  - Dimension,
+///  - Dimension ordering,
+///  - Packing format,
+///  - Complex format.
+
+template <dimension_type Dim>
+struct Rt_layout
+{
+  static dimension_type const dim = Dim;
+
+  rt_pack_type      pack;
+  Rt_tuple          order;
+  rt_complex_type   complex;
+  unsigned          align;	// Only valid if pack == stride_unit_align
+};
+
+
+
 /// Applied_layout takes the layout policies encapsulated by a
 /// Layout and applys them to map multi-dimensional indices into
 /// memory offsets.
@@ -724,6 +868,109 @@
 
 
 
+/// Applied run-time layout.
+
+template <dimension_type Dim>
+class Applied_layout<Rt_layout<Dim> >
+{
+public:
+  static dimension_type const dim = Dim;
+
+public:
+
+  // Construct Applied_layout object.
+  //
+  // Requires
+  //   LAYOUT to be the run-time layout.
+  //   EXTENT to be the extent of the data to layout.
+  //   ELEM_SIZE to be the size of a data element (in bytes).
+
+  Applied_layout(
+    Rt_layout<Dim> const& layout,
+    Length<Dim> const&    extent,
+    length_type           elem_size = 1)
+    : layout_(layout)
+  {
+    assert(layout_.align == 0 || layout_.align % elem_size == 0);
+
+    for (dimension_type d=0; d<Dim; ++d)
+      size_[d] = extent[d];
+
+    if (Dim == 3)
+    {
+      stride_[layout_.order.impl_dim2] = 1;
+      stride_[layout_.order.impl_dim1] = size_[layout_.order.impl_dim2];
+      if (layout_.align != 0 &&
+	  (elem_size*stride_[layout_.order.impl_dim1]) % layout_.align != 0)
+	stride_[layout_.order.impl_dim1] +=
+	  (layout_.align/elem_size -
+	   stride_[layout_.order.impl_dim1]%layout_.align);
+      stride_[layout_.order.impl_dim0] = size_[layout_.order.impl_dim1] *
+	                                 stride_[layout_.order.impl_dim1];
+    }
+    else if (Dim == 2)
+    {
+      stride_[layout_.order.impl_dim1] = 1;
+      stride_[layout_.order.impl_dim0] = size_[layout_.order.impl_dim1];
+
+      if (layout_.align != 0 &&
+	  (elem_size*stride_[layout_.order.impl_dim0]) % layout_.align != 0)
+	stride_[layout_.order.impl_dim0] +=
+	  (layout_.align/elem_size -
+	   stride_[layout_.order.impl_dim0]%layout_.align);
+    }
+    else  // (Dim == 1)
+    {
+      stride_[layout_.order.impl_dim0] = 1;
+    }
+  }
+
+  index_type index(Index<Dim> idx)
+    const VSIP_NOTHROW
+  {
+    if (Dim == 3)
+    {
+      assert(idx[0] < size_[0] && idx[1] < size_[1] && idx[2] < size_[2]);
+      return idx[layout_.order.impl_dim0]*stride_[layout_.order.impl_dim0] +
+	     idx[layout_.order.impl_dim1]*stride_[layout_.order.impl_dim1] + 
+	     idx[layout_.order.impl_dim2];
+    }
+    else if (Dim == 2)
+    {
+      assert(idx[0] < size_[0] && idx[1] < size_[1]);
+      return idx[layout_.order.impl_dim0]*stride_[layout_.order.impl_dim0] +
+	     idx[layout_.order.impl_dim1];
+    }
+    else // (Dim == 1)
+    {
+      assert(idx[0] < size_[0]);
+      return idx[0];
+    }
+  }
+
+  stride_type stride(dimension_type d)
+    const VSIP_NOTHROW
+  {
+    return stride_[d];
+  }
+
+  length_type size(dimension_type d)
+    const VSIP_NOTHROW
+  { return size_[d]; }
+
+  length_type total_size()
+    const VSIP_NOTHROW
+  { return size_[layout_.order.impl_dim0] * stride_[layout_.order.impl_dim0]; }
+
+public:
+  Rt_layout<Dim> const layout_;
+private:
+  length_type size_  [Dim];
+  stride_type stride_[Dim];
+};
+
+
+
 /// Storage: abstracts storage of data, in particular handling the storage
 /// of split complex data.
 
@@ -950,6 +1197,174 @@
 
 
 
+// Allocated storage, with complex format determined at run-time.
+
+template <typename T,
+	  typename AllocT = vsip::impl::Aligned_allocator<T> >
+class Rt_allocated_storage
+{
+  // Compile-time values and types.
+public:
+  // typedef Storage<ComplexFmt, T> storage_type;
+
+  typedef Rt_pointer<T> type;
+  typedef Rt_pointer<T> const_type;
+  // typedef typename storage_type::type       type;
+  // typedef typename storage_type::const_type const_type;
+  // typedef typename storage_type::alloc_type alloc_type;
+
+  enum state_type
+  {
+    alloc_data,
+    user_data,
+    no_data
+  };
+
+  // Constructors and destructor.
+public:
+  static Rt_pointer<T> allocate_(
+    AllocT const&   /*arg_alloc*/,
+    length_type     size,
+    rt_complex_type cformat)
+  {
+    if (cformat == cmplx_inter_fmt)
+    {
+      return Rt_pointer<T>(alloc_align<T>(VSIP_IMPL_ALLOC_ALIGNMENT, size));
+    }
+    else
+    {
+      typedef typename Scalar_of<T>::type scalar_type;
+      return Rt_pointer<T>(std::pair<scalar_type*, scalar_type*>(
+	alloc_align<scalar_type>(VSIP_IMPL_ALLOC_ALIGNMENT, size),
+	alloc_align<scalar_type>(VSIP_IMPL_ALLOC_ALIGNMENT, size)));
+    }
+  }
+
+  static void deallocate_(
+    Rt_pointer<T>   ptr,
+    rt_complex_type cformat,
+    length_type     /*size*/,
+    AllocT const&   /*arg_alloc*/)
+  {
+    if (cformat == cmplx_inter_fmt)
+    {
+      free_align(ptr.as_inter());
+    }
+    else
+    {
+      free_align(ptr.as_split().first);
+      free_align(ptr.as_split().second);
+    }
+  }
+
+  // Potentially "split" an interleaved buffer into two segments
+  // of equal size, if split format is requested and user provides
+  // an interleaved buffer.
+  static Rt_pointer<T> partition_(
+    rt_complex_type cformat,
+    Rt_pointer<T>   buffer,
+    length_type     size)
+  {
+    if (cformat == cmplx_split_fmt && Is_complex<T>::value &&
+	buffer.as_split().second == 0)
+    {
+      // We're allocating split-storage but user gave us
+      // interleaved storage.
+      typedef typename Scalar_of<T>::type scalar_type;
+      scalar_type* ptr = reinterpret_cast<scalar_type*>(buffer.as_inter());
+      return Rt_pointer<T>(std::pair<scalar_type*, scalar_type*>(
+			     ptr, ptr + size));
+    }
+    else
+    {
+      // Check that user didn't give us split-storage when we wanted
+      // interleaved.  We can't fix this, but we can through an
+      // exception.
+      assert(!(cformat == cmplx_inter_fmt && Is_complex<T>::value &&
+	       buffer.as_split().second != 0));
+      return buffer;
+    }
+  }
+
+  Rt_allocated_storage(length_type     size,
+		       rt_complex_type cformat,
+		       type            buffer = type(),
+		       AllocT const&   alloc  = AllocT())
+    VSIP_THROW((std::bad_alloc))
+    : cformat_(cformat),
+      alloc_ (alloc),
+      state_ (size == 0         ? no_data   :
+	      buffer.is_null()  ? alloc_data
+		                : user_data),
+      data_  (state_ == alloc_data ? allocate_(alloc_, size, cformat_) :
+	      state_ == user_data  ? partition_(cformat, buffer, size)
+	                           : type())
+  {}
+
+  Rt_allocated_storage(length_type   size,
+		       rt_complex_type cformat,
+		       T               val,
+		       type            buffer = type(),
+		       AllocT const& alloc  = AllocT())
+  VSIP_THROW((std::bad_alloc))
+    : cformat_(cformat),
+      alloc_ (alloc),
+      state_ (size == 0         ? no_data   :
+	      buffer.is_null() ? alloc_data
+		                : user_data),
+      data_  (state_ == alloc_data ? allocate_(alloc_, size, cformat_) :
+	      state_ == user_data  ? partition_(cformat, buffer, size)
+	                           : type())
+  {
+    if (cformat == cmplx_inter_fmt)
+    {
+      typedef Storage<Cmplx_inter_fmt, T> inter_storage_type;
+      for (index_type i=0; i<size; ++i)
+	inter_storage_type::put(data_.as_inter(), i, val);
+    }
+    else /* (cformat == cmplx_split_fmt) */
+    {
+      typedef Storage<Cmplx_split_fmt, T> split_storage_type;
+      for (index_type i=0; i<size; ++i)
+	split_storage_type::put(data_.as_inter(), i, val);
+    }
+  }
+
+  ~Rt_allocated_storage()
+  {
+    // it using class's responsiblity to call deallocate().
+    if (state_ == alloc_data)
+      assert(data_.is_null());
+  }
+
+  // Accessors.
+public:
+  void rebind(length_type size, type buffer);
+
+  void deallocate(length_type size)
+  {
+    if (state_ == alloc_data)
+    {
+      deallocate_(data_, cformat_, size, alloc_);
+      data_ = type();
+    }
+  }
+
+  bool is_alloc() const { return state_ == alloc_data; }
+
+  type       data()       { return data_; }
+  const_type data() const { return data_; }
+
+  // Member data.
+private:
+  rt_complex_type cformat_;
+  AllocT          alloc_;
+  state_type      state_;
+  type            data_;
+};
+
+
+
 /***********************************************************************
   Definitions
 ***********************************************************************/
Index: src/vsip/impl/rt_extdata.hpp
===================================================================
RCS file: src/vsip/impl/rt_extdata.hpp
diff -N src/vsip/impl/rt_extdata.hpp
--- /dev/null	1 Jan 1970 00:00:00 -0000
+++ src/vsip/impl/rt_extdata.hpp	6 May 2006 19:49:02 -0000
@@ -0,0 +1,406 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/impl/rt_extdata.hpp
+    @author  Jules Bergmann
+    @date    2005-05-03
+    @brief   VSIPL++ Library: Runtime Direct Data Access.
+
+*/
+
+#ifndef VSIP_IMPL_RT_EXTDATA_HPP
+#define VSIP_IMPL_RT_EXTDATA_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/impl/extdata.hpp>
+
+
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
+template <dimension_type D,
+	  typename       Order,
+	  typename       PackType,
+	  typename	 ComplexType>
+inline rt_complex_type
+complex_format(Layout<D, Order, PackType, ComplexType>)
+{
+  if (Type_equal<ComplexType, Cmplx_inter_fmt>::value)
+    return cmplx_inter_fmt;
+  else
+    return cmplx_split_fmt;
+}
+
+
+
+template <dimension_type D>
+inline rt_complex_type
+complex_format(Rt_layout<D> const& rtl)
+{
+  return rtl.complex;
+}
+
+
+
+template <dimension_type D>
+inline rt_complex_type
+complex_format(Applied_layout<Rt_layout<D> > const& appl)
+{
+  return appl.layout_.complex;
+}
+
+
+
+template <dimension_type D,
+	  typename       Order,
+	  typename       PackType,
+	  typename	 ComplexType>
+inline rt_pack_type
+pack_format(Layout<D, Order, PackType, ComplexType>)
+{
+  if      (Type_equal<PackType, Stride_unknown>::value)
+    return stride_unknown;
+  else if (Type_equal<PackType, Stride_unit>::value)
+    return stride_unit;
+  else if (Type_equal<PackType, Stride_unit_dense>::value)
+    return stride_unit_dense;
+  else /* if (Type_equal<PackType, Stride_unit_align>::value) */
+    return stride_unit_align;
+}
+
+
+
+template <dimension_type D>
+inline rt_pack_type
+pack_format(Rt_layout<D> const& rtl)
+{
+  return rtl.pack;
+}
+
+
+
+template <dimension_type D,
+	  typename       Order,
+	  typename       PackType,
+	  typename	 ComplexType>
+inline unsigned
+layout_alignment(Layout<D, Order, PackType, ComplexType>)
+{
+  return Is_stride_unit_align<PackType>::align;
+}
+
+
+
+template <dimension_type D>
+inline unsigned
+layout_alignment(Rt_layout<D> const& rtl)
+{
+  return rtl.align;
+}
+
+
+template <dimension_type D,
+	  typename       OrderType,
+	  typename       PackType,
+	  typename	 ComplexType>
+inline dimension_type
+layout_nth_dim(
+  Layout<D, OrderType, PackType, ComplexType> const&,
+  dimension_type const d)
+{
+  if      (d == 0) return OrderType::impl_dim0;
+  else if (d == 1) return OrderType::impl_dim1;
+  else /*if (d == 2)*/ return OrderType::impl_dim2;
+}
+
+
+
+template <dimension_type D>
+inline dimension_type
+layout_nth_dim(Rt_layout<D> const& rtl, dimension_type const d)
+{
+  if      (d == 0) return rtl.order.impl_dim0;
+  else if (d == 1) return rtl.order.impl_dim1;
+  else /*if (d == 2)*/ return rtl.order.impl_dim2;
+}
+
+
+
+namespace data_access
+{
+
+/// Determine if direct access is OK at runtime for a given block.
+
+template <typename BlockT,
+	  typename LayoutT>
+bool
+is_direct_ok(
+  BlockT const&  block,
+  LayoutT const& layout)
+{
+  typedef typename BlockT::value_type                value_type;
+  typedef typename Block_layout<BlockT>::layout_type block_layout_type;
+
+  dimension_type const dim = LayoutT::dim;
+
+  block_layout_type block_layout;
+
+  dimension_type const dim0 = layout_nth_dim(block_layout, 0);
+  dimension_type const dim1 = layout_nth_dim(block_layout, 1);
+  dimension_type const dim2 = layout_nth_dim(block_layout, 2);
+
+  if (complex_format(block_layout) != complex_format(layout))
+    return false;
+
+  for (dimension_type d=0; d<dim; ++d)
+    if (layout_nth_dim(block_layout, d) != layout_nth_dim(layout, d))
+      return false;
+
+  if (pack_format(layout) == stride_unit)
+  {
+    if (dim == 1)
+      return block.impl_stride(1, 0) == 1;
+    else if (dim == 2)
+      return block.impl_stride(2, dim1) == 1;
+    else /* if (dim == 3) */
+      return block.impl_stride(3, dim2) == 1;
+  }
+  else if (pack_format(layout) == stride_unit_dense)
+  {
+    if (dim == 1)
+      return block.impl_stride(1, 0) == 1;
+    else if (dim == 2)
+      return    block.impl_stride(2, dim1) == 1
+	     && (   block.impl_stride(2, dim0) ==
+		       static_cast<stride_type>(block.size(2, dim1))
+		 || block.size(2, dim0) == 1);
+    else /* if (dim == 3) */
+    {
+
+      bool ok2 = (block.impl_stride(3, dim2) == 1);
+      bool ok1 = (block.impl_stride(3, dim1) ==
+		  static_cast<stride_type>(block.size(3, dim2)))
+	|| (block.size(3, dim1) == 1 && block.size(3, dim0) == 1);
+      bool ok0 = (block.impl_stride(3, dim0) ==
+		  static_cast<stride_type>(block.size(3, dim1) *
+					   block.size(3, dim2)))
+	|| block.size(3, dim0) == 1;
+
+      return ok0 && ok1 && ok2;
+    }
+  }
+  else if (pack_format(layout) == stride_unit_align)
+  {
+    // unsigned align = Is_stride_unit_align<typename LP::pack_type>::align;
+    unsigned align = layout_alignment(layout);
+
+    if (!data_access::is_aligned_to(block.impl_data(), align))
+      return false;
+
+    if (dim == 1)
+      return block.impl_stride(1, 0) == 1;
+    else if (dim == 2)
+      return block.impl_stride(2, dim1) == 1 &&
+	((block.impl_stride(2, dim0) * sizeof(value_type)) % align == 0);
+    else /* if (LP::dim == 3) */
+      return 
+	block.impl_stride(3, dim2) == 1 &&
+	(block.impl_stride(3, dim1) * sizeof(value_type)) % align == 0 &&
+	(block.impl_stride(3, dim0) * sizeof(value_type)) % align == 0;
+  }
+  else /* if (Type_equal<typename LP::pack_type, Stride_unknown>::value) */
+  {
+    assert(pack_format(layout) == stride_unknown);
+    return true;
+  }
+}
+
+
+
+/// Run-time low-level data access class.
+
+/// Requires
+///   AT to be an access-type tag,
+///   BLOCK to be a VSIPL++ block type,
+///   DIM to be the dimension of the desired run-time layout.
+
+template <typename       AT,
+	  typename       Block,
+	  dimension_type Dim>
+class Rt_low_level_data_access;
+
+
+
+/// Specialization for low-level direct data access.
+
+/// Depending on the requested run-time layout, data will either be
+/// accessed directly, or will be copied into a temporary buffer.
+///
+/// Requires:
+///   BLOCK to be a block that supports direct access via member
+///     functions impl_data() and impl_stride().  Access to these
+///     members can be protected by making Low_level_data_access a friend
+///     class to the block.
+///   DIM to be the dimension of the desired run-time layout.
+
+template <typename       Block,
+	  dimension_type Dim>
+class Rt_low_level_data_access<Direct_access_tag, Block, Dim>
+{
+  // Compile time typedefs.
+public:
+  static dimension_type const dim = Dim;
+
+  typedef typename Block::value_type value_type;
+  typedef Rt_allocated_storage<value_type> storage_type;
+  typedef Rt_pointer<value_type> raw_ptr_type;
+
+  // Compile- and run-time properties.
+public:
+  static int   const CT_Cost          = 2;
+  static bool  const CT_Mem_not_req   = false;
+  static bool  const CT_Xfer_not_req  = false;
+
+  static int    cost         (Block const& block, Rt_layout<Dim> const& rtl)
+    { return is_direct_ok(block, rtl) ? 0 : 2; }
+
+  static size_t mem_required (Block const& block, Rt_layout<Dim> const& )
+    { return sizeof(typename Block::value_type) * block.size(); }
+  static size_t xfer_required(Block const& , Rt_layout<Dim> const& )
+    { return !CT_Xfer_not_req; }
+
+  // Constructor and destructor.
+public:
+  Rt_low_level_data_access(
+    Block&                blk,
+    Rt_layout<Dim> const& rtl,
+    raw_ptr_type          buffer = NULL)
+  : use_direct_(is_direct_ok(blk, rtl)),
+    app_layout_(rtl, extent<dim>(blk), sizeof(value_type)),
+    storage_   (use_direct_ ? 0 : app_layout_.total_size(), rtl.complex, buffer)
+  {}
+
+  ~Rt_low_level_data_access()
+    { storage_.deallocate(app_layout_.total_size()); }
+
+  void begin(Block* blk, bool sync)
+  {
+    if (!use_direct_ && sync)
+      Rt_block_copy<2, Block>::copy_in(blk, app_layout_, storage_.data());
+  }
+
+  void end(Block* blk, bool sync)
+  {
+    if (!use_direct_ && sync)
+      Rt_block_copy<2, Block>::copy_out(blk, app_layout_, storage_.data());
+  }
+
+  int cost() const { return use_direct_ ? 0 : 2; }
+
+  // Direct data acessors.
+public:
+  raw_ptr_type	data(Block* blk)
+  { return use_direct_ ? raw_ptr_type(blk->impl_data()) : storage_.data(); }
+  stride_type	stride(Block* blk, dimension_type d)
+    { return use_direct_ ? blk->impl_stride(dim, d) : app_layout_.stride(d);  }
+  length_type	size  (Block* blk, dimension_type d)
+    { return use_direct_ ? blk->size(dim, d) : blk->size(Block::dim, d); }
+
+  // Member data.
+private:
+  bool                            use_direct_;
+  Applied_layout<Rt_layout<Dim> > app_layout_;
+  storage_type                    storage_;
+};
+
+} // namespace vsip::impl::data_access
+
+
+
+/// Run-time high-level data access class.  Provides data access to data
+/// stored in blocks, using an appropriate low-level data interface.
+
+/// Requires:
+///   BLOCK is a block type.
+///   DIM is the dimension of the run-time layout policy for data access.
+///   RP is a reference counting policy.
+
+template <typename       Block,
+	  dimension_type Dim,
+	  typename       RP  = No_count_policy>
+class Rt_ext_data
+{
+  // Compile time typedefs.
+public:
+  typedef typename Block_layout<Block>::access_type              AT;
+  typedef data_access::Rt_low_level_data_access<AT, Block, Dim>  ext_type;
+  typedef typename Block::value_type                             value_type;
+  typedef Rt_pointer<value_type>                                 raw_ptr_type;
+
+
+  // Compile- and run-time properties.
+public:
+  static int   const CT_Cost          = ext_type::CT_Cost;
+  static bool  const CT_Mem_not_req   = ext_type::CT_Mem_not_req;
+  static bool  const CT_Xfer_not_req  = ext_type::CT_Xfer_not_req;
+
+
+  // Constructor and destructor.
+public:
+  Rt_ext_data(Block&                block,
+	      Rt_layout<Dim> const& rtl,
+	      sync_action_type      sync   = SYNC_INOUT,
+	      raw_ptr_type          buffer = 0 /*storage_type::null()*/)
+    : blk_    (&block),
+      rtl_    (rtl),
+      ext_    (block, rtl_, buffer),
+      sync_   (sync)
+    { ext_.begin(blk_.get(), sync_ & SYNC_IN); }
+
+  Rt_ext_data(Block const&          block,
+	      Rt_layout<Dim> const& rtl,
+	      sync_action_type      sync,
+	      raw_ptr_type          buffer = 0 /*storage_type::null()*/)
+    : blk_ (&const_cast<Block&>(block)),
+      rtl_    (rtl),
+      ext_ (const_cast<Block&>(block), rtl_, buffer),
+      sync_(sync)
+  {
+    assert(sync != SYNC_OUT && sync != SYNC_INOUT);
+    ext_.begin(blk_.get(), sync_ & SYNC_IN);
+  }
+
+  ~Rt_ext_data()
+    { ext_.end(blk_.get(), sync_ & SYNC_OUT); }
+
+  // Direct data acessors.
+public:
+  raw_ptr_type	data  ()                 { return ext_.data  (blk_.get()); }
+  stride_type	stride(dimension_type d) { return ext_.stride(blk_.get(), d); }
+  length_type	size  (dimension_type d) { return ext_.size  (blk_.get(), d); }
+
+  int           cost  ()                 { return ext_.cost(); }
+
+  // Member data.
+private:
+  typename View_block_storage<Block>::template With_rp<RP>::type
+		   blk_;
+  Rt_layout<Dim>   rtl_;
+  ext_type         ext_;
+  sync_action_type sync_;
+};
+
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_IMPL_RT_EXTDATA_HPP
Index: tests/rt_extdata.cpp
===================================================================
RCS file: tests/rt_extdata.cpp
diff -N tests/rt_extdata.cpp
--- /dev/null	1 Jan 1970 00:00:00 -0000
+++ tests/rt_extdata.cpp	6 May 2006 19:49:02 -0000
@@ -0,0 +1,296 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    tests/rt_extdata.cpp
+    @author  Jules Bergmann
+    @date    2006-05-03
+    @brief   VSIPL++ Library: Unit-test for run-time external data access.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/vector.hpp>
+#include <vsip/matrix.hpp>
+#include <vsip/map.hpp>
+#include <vsip/impl/rt_extdata.hpp>
+
+#include "test.hpp"
+
+using namespace vsip;
+
+using vsip::impl::Rt_layout;
+using vsip::impl::Rt_tuple;
+using vsip::impl::rt_pack_type;
+using vsip::impl::rt_complex_type;
+using vsip::impl::Storage;
+using vsip::impl::Cmplx_inter_fmt;
+using vsip::impl::Cmplx_split_fmt;
+using vsip::impl::Rt_ext_data;
+using vsip::impl::Applied_layout;
+using vsip::impl::Length;
+
+using vsip::impl::stride_unit_dense;
+using vsip::impl::stride_unit_align;
+using vsip::impl::cmplx_inter_fmt;
+using vsip::impl::cmplx_split_fmt;
+using vsip::impl::SYNC_INOUT;
+
+using vsip::impl::extent;
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+// Test run-time external data access (assuming that data is either
+// not complex or is interleaved-complex).
+
+template <typename T,
+	  typename LayoutT>
+void
+t_rtex(
+  Domain<2> const& dom,
+  Rt_tuple         order,
+  rt_pack_type     pack,
+  int              cost,
+  bool             alloc)
+{
+  length_type rows = dom[0].size();
+  length_type cols = dom[1].size();
+  typedef impl::Fast_block<2, T, LayoutT> block_type;
+  Matrix<T, block_type> mat(rows, cols);
+
+  for (index_type r=0; r<rows; ++r)
+    for (index_type c=0; c<cols; ++c)
+      mat(r, c) = T(100*r + c);
+
+  Rt_layout<2>                  rt_layout;
+
+  rt_layout.pack    = pack;
+  rt_layout.order   = order; 
+  rt_layout.complex = cmplx_inter_fmt;
+  rt_layout.align   = (pack == stride_unit_align) ? 16 : 0;
+
+  // Pre-allocate temporary buffer.
+  T* buffer = 0;
+  if (alloc)
+  {
+    vsip::impl::Length<2> ext = extent<2>(mat.block());
+    Applied_layout<Rt_layout<2> > app_layout(rt_layout, ext, sizeof(T));
+    length_type size = app_layout.total_size();
+    buffer = new T[size];
+  }
+
+  {
+    Rt_ext_data<block_type, 2> ext(mat.block(), rt_layout, SYNC_INOUT, buffer);
+
+    T* ptr = ext.data().as_inter();
+
+    if (alloc && cost != 0)
+      test_assert(ptr == buffer);
+
+#if VERBOSE
+    std::cout << "-----------------------------------------------" << std::endl;
+    std::cout << "cost: " << ext.cost() << std::endl;
+
+    for (index_type i=0; i<rows*cols; ++i)
+      std::cout << i << ": " << ptr[i] << std::endl;
+#endif
+
+    test_assert(cost == ext.cost());
+
+    for (index_type r=0; r<rows; ++r)
+      for (index_type c=0; c<cols; ++c)
+      {
+	test_assert(equal(ptr[r*ext.stride(0) + c*ext.stride(1)],
+			  mat.get(r, c)));
+	ptr[r*ext.stride(0) + c*ext.stride(1)] = T(100*c + r);
+      }
+  }
+
+  if (alloc)
+    delete[] buffer;
+
+  for (index_type r=0; r<rows; ++r)
+    for (index_type c=0; c<cols; ++c)
+      test_assert(equal(mat.get(r, c), T(100*c + r)));
+}
+
+
+
+// Test run-time external data access (assuming that data is complex,
+// either interleaved or split).
+
+template <typename T,
+	  typename LayoutT>
+void
+t_rtex_c(
+  Domain<2> const& dom,
+  Rt_tuple         order,
+  rt_pack_type     pack,
+  rt_complex_type  cformat,
+  int              cost,
+  bool             alloc)
+{
+  length_type rows = dom[0].size();
+  length_type cols = dom[1].size();
+  typedef impl::Fast_block<2, T, LayoutT> block_type;
+  Matrix<T, block_type> mat(rows, cols);
+
+  for (index_type r=0; r<rows; ++r)
+    for (index_type c=0; c<cols; ++c)
+      mat(r, c) = T(100*r + c);
+
+  Rt_layout<2>                  rt_layout;
+
+  rt_layout.pack    = pack;
+  rt_layout.order   = order; 
+  rt_layout.complex = cformat;
+  rt_layout.align   = (pack == stride_unit_align) ? 16 : 0;
+
+  // Pre-allocate temporary buffer.
+  T* buffer = 0;
+  if (alloc)
+  {
+    vsip::impl::Length<2> ext = extent<2>(mat.block());
+    Applied_layout<Rt_layout<2> > app_layout(rt_layout, ext, sizeof(T));
+    length_type size = app_layout.total_size();
+    buffer = new T[size];
+  }
+
+  {
+    Rt_ext_data<block_type, 2> ext(mat.block(), rt_layout, SYNC_INOUT, buffer);
+
+#if VERBOSE
+    std::cout << "-----------------------------------------------" << std::endl;
+    std::cout << "cost: " << ext.cost() << std::endl;
+#endif
+
+    test_assert(cost == ext.cost());
+
+    if (rt_layout.complex == cmplx_inter_fmt)
+    {
+      T* ptr = ext.data().as_inter();
+#if VERBOSE
+      for (index_type i=0; i<rows*cols; ++i)
+	std::cout << i << ": " << ptr[i] << std::endl;
+#endif
+      if (alloc && cost != 0)
+	test_assert(ptr == buffer);
+
+      for (index_type r=0; r<rows; ++r)
+	for (index_type c=0; c<cols; ++c)
+	{
+	  test_assert(equal(ptr[r*ext.stride(0) + c*ext.stride(1)],
+			    mat.get(r, c)));
+	  ptr[r*ext.stride(0) + c*ext.stride(1)] = T(100*c + r);
+	}
+    }
+    else /* rt_layout.complex == cmplx_split_fmt */
+    {
+      typedef Storage<Cmplx_split_fmt, T> storage_type;
+      typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
+      std::pair<scalar_type*,scalar_type*> ptr = ext.data().as_split();
+#if VERBOSE
+      for (index_type i=0; i<rows*cols; ++i)
+	std::cout << i << ": " << ptr.first[i] << "," << ptr.second[i]
+		  << std::endl;
+#endif
+      if (alloc && cost != 0) 
+	test_assert(reinterpret_cast<T*>(ptr.first) == buffer);
+
+      for (index_type r=0; r<rows; ++r)
+	for (index_type c=0; c<cols; ++c)
+	{
+	  test_assert(
+	    equal(storage_type::get(ptr, r*ext.stride(0) + c*ext.stride(1)),
+		  mat.get(r, c)));
+	  storage_type::put(ptr, r*ext.stride(0) + c*ext.stride(1),
+			    T(100*c + r));
+	}
+    }
+  }
+
+  if (alloc)
+    delete[] buffer;
+
+  for (index_type r=0; r<rows; ++r)
+    for (index_type c=0; c<cols; ++c)
+      test_assert(equal(mat.get(r, c), T(100*c + r)));
+
+}
+			
+
+  
+
+template <typename T>
+void
+test(
+  Domain<2> const& d,		// size of matrix
+  bool             a)		// pre-allocate buffer or not.
+{
+  typedef complex<T> CT;
+
+  using vsip::impl::Layout;
+  using vsip::impl::Stride_unit_dense;
+  using vsip::impl::Cmplx_inter_fmt;
+
+  Rt_tuple r2_v = Rt_tuple(row2_type());
+  Rt_tuple c2_v = Rt_tuple(col2_type());
+
+  typedef row2_type r2_t;
+  typedef col2_type c2_t;
+
+  typedef Stride_unit_dense sud_t;
+
+  typedef Cmplx_inter_fmt cif_t;
+  typedef Cmplx_split_fmt csf_t;
+
+  rt_pack_type sud_v = stride_unit_dense;
+
+  rt_complex_type cif_v = cmplx_inter_fmt;
+  rt_complex_type csf_v = cmplx_split_fmt;
+
+  t_rtex<T, Layout<2, r2_t, sud_t, cif_t> >(d, r2_v, sud_v, 0, a);
+  t_rtex<T, Layout<2, r2_t, sud_t, cif_t> >(d, c2_v, sud_v, 2, a);
+  t_rtex<T, Layout<2, c2_t, sud_t, cif_t> >(d, r2_v, sud_v, 2, a);
+  t_rtex<T, Layout<2, c2_t, sud_t, cif_t> >(d, c2_v, sud_v, 0, a);
+
+  t_rtex_c<CT, Layout<2, r2_t, sud_t, cif_t> > (d, r2_v, sud_v, cif_v, 0, a);
+  t_rtex_c<CT, Layout<2, r2_t, sud_t, cif_t> > (d, c2_v, sud_v, cif_v, 2, a);
+  t_rtex_c<CT, Layout<2, r2_t, sud_t, cif_t> > (d, r2_v, sud_v, csf_v, 2, a);
+  t_rtex_c<CT, Layout<2, r2_t, sud_t, cif_t> > (d, c2_v, sud_v, csf_v, 2, a);
+
+  t_rtex_c<CT, Layout<2, r2_t, sud_t, csf_t> > (d, r2_v, sud_v, cif_v, 2, a);
+  t_rtex_c<CT, Layout<2, r2_t, sud_t, csf_t> > (d, c2_v, sud_v, cif_v, 2, a);
+  t_rtex_c<CT, Layout<2, r2_t, sud_t, csf_t> > (d, r2_v, sud_v, csf_v, 0, a);
+  t_rtex_c<CT, Layout<2, r2_t, sud_t, csf_t> > (d, c2_v, sud_v, csf_v, 2, a);
+
+  t_rtex_c<CT, Layout<2, c2_t, sud_t, cif_t> > (d, r2_v, sud_v, cif_v, 2, a);
+  t_rtex_c<CT, Layout<2, c2_t, sud_t, cif_t> > (d, c2_v, sud_v, cif_v, 0, a);
+  t_rtex_c<CT, Layout<2, c2_t, sud_t, cif_t> > (d, r2_v, sud_v, csf_v, 2, a);
+  t_rtex_c<CT, Layout<2, c2_t, sud_t, cif_t> > (d, c2_v, sud_v, csf_v, 2, a);
+
+  t_rtex_c<CT, Layout<2, c2_t, sud_t, csf_t> > (d, r2_v, sud_v, cif_v, 2, a);
+  t_rtex_c<CT, Layout<2, c2_t, sud_t, csf_t> > (d, c2_v, sud_v, cif_v, 2, a);
+  t_rtex_c<CT, Layout<2, c2_t, sud_t, csf_t> > (d, r2_v, sud_v, csf_v, 2, a);
+  t_rtex_c<CT, Layout<2, c2_t, sud_t, csf_t> > (d, c2_v, sud_v, csf_v, 0, a);
+}
+
+
+
+int
+main(int argc, char** argv)
+{
+  vsipl init(argc, argv);
+
+  test<short>(Domain<2>(4, 8), true);
+  test<int>(Domain<2>(4, 8), true);
+  test<float>(Domain<2>(4, 8), true);
+  test<double>(Domain<2>(4, 8), true);
+}
+
