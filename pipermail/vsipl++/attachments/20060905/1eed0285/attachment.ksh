Index: ChangeLog
===================================================================
--- ChangeLog	(revision 148422)
+++ ChangeLog	(working copy)
@@ -1,3 +1,36 @@
+2006-09-05  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/dense.hpp (Dense): Add implementation constructor
+	  to construct an admit/release block from a User_storage
+	  object.
+	* src/vsip/impl/extdata.hpp: Add size() method to Ext_data.
+	* src/vsip/impl/replicated_map.hpp: Replace incorrect usage of
+	  no_processor with no_rank.
+	* src/vsip/impl/pas/block.hpp: Add support for split-complex.
+	* src/vsip/impl/pas/param.hpp: Use PAS_RDMA (set in Linux pas.pc)
+	  to determine if Linux or MCOE parameters should be used.
+	* src/vsip/impl/pas/par_assign_direct.hpp: Add support for
+	  split-complex.
+	* src/vsip/impl/pas/services.hpp: Fix auto_ptr usage that
+	  GreenHills didn't like.
+	* src/vsip/impl/pas/par_assign.hpp: Add support for split-complex.
+	* src/vsip/impl/block-traits.hpp: Add Block_root trait and
+	  block_root() function to extract root block for a subblock.
+	* src/vsip/impl/proxy_local_block.hpp: Change impl_offset return
+	  type from long to stride_type.
+	* src/vsip/impl/subblock.hpp: Define Block_root and block_root
+	  specializations.
+	* tests/parallel/corner-turn.cpp: Generalize to cover additional
+	  types and sizes.
+	* tests/parallel/subviews.cpp: Fix typos that limited generality
+	  of coverage.  Add coverage for complex subviews.
+	* tests/parallel/block.cpp: Add rudimentary coverage for
+	  Replicated_map.
+	* benchmarks/fftm.cpp: Fix log() ambiguity on GreenHills.
+	* examples/mercury/mcoe-setup.sh: Add options to enable
+	  loop fusion (and disable SAL, although should only be
+	  used for benchmarking loop fusion).
+	
 2006-09-05  Don McCoy  <don@codesourcery.com>
 
 	* src/vsip/impl/simd/eval-generic.hpp: Added layout policies for SIMD
Index: src/vsip/dense.hpp
===================================================================
--- src/vsip/dense.hpp	(revision 148422)
+++ src/vsip/dense.hpp	(working copy)
@@ -93,6 +93,13 @@
     : format_(format), data_(data)
   { assert(format == array_format); }
 
+  // This constructor is provided so that User_storage<T> and
+  // User_storage<complex<T> > can be interchanged, however it
+  // should not be called.
+  User_storage(user_storage_type format, T* real, T* /*imag*/)
+    : format_(format), data_(real)
+  { assert(0); }
+
   // Accessors.
 public:
   user_storage_type format() const { return format_; }
@@ -579,7 +586,8 @@
   // const_data_type impl_data() const VSIP_NOTHROW { return storage_.data(); }
   stride_type impl_stride(dimension_type D, dimension_type d)
     const VSIP_NOTHROW;
-  long impl_offset() VSIP_NOTHROW
+
+  stride_type impl_offset() VSIP_NOTHROW
   { return 0; }
 
   // Hidden copy constructor and assignment.
@@ -650,6 +658,14 @@
       : base_type(dom, impl::User_storage<T>(split_format,
 					     real_pointer, imag_pointer), map)
     {}
+
+  // Internal user storage constructor.
+  Dense(Domain<1> const&             dom,
+	impl::User_storage<T> const& data,
+	map_type const&              map = map_type())
+    VSIP_THROW((std::bad_alloc))
+      : base_type(dom, data, map)
+    {}
 };
 
 
@@ -749,6 +765,14 @@
 					     real_pointer, imag_pointer), map)
     {}
 
+  // Internal user storage constructor.
+  Dense(Domain<2> const&             dom,
+	impl::User_storage<T> const& data,
+	map_type const&              map = map_type())
+    VSIP_THROW((std::bad_alloc))
+      : base_type(dom, data, map)
+    {}
+
   // 1-dim Data Accessors.
   using base_type::get;
   using base_type::put;
@@ -868,6 +892,14 @@
 					     real_pointer, imag_pointer), map)
     {}
 
+  // Internal user storage constructor.
+  Dense(Domain<3> const&             dom,
+	impl::User_storage<T> const& data,
+	map_type const&              map = map_type())
+    VSIP_THROW((std::bad_alloc))
+      : base_type(dom, data, map)
+    {}
+
   // 1-dim Data Accessors.
   using base_type::get;
   using base_type::put;
@@ -1018,7 +1050,7 @@
 	  typename       MapT>
 struct Distributed_local_block<Dense<Dim, T, OrderT, MapT> >
 {
-  // We could determine the local block by just chaning the map
+  // We could determine the local block by just changing the map
   // to serial:
   //   typedef Dense<Dim, T, OrderT, Local_map> type;
 
@@ -1061,7 +1093,7 @@
 	  typename       T,
 	  typename       OrderT,
 	  typename       MapT>
-inline Dense<Dim, T, OrderT, Local_map>&
+inline typename Dense<Dim, T, OrderT, MapT>::local_block_type&
 get_local_block(
   Dense<Dim, T, OrderT, MapT> const& block)
 {
Index: src/vsip/impl/extdata.hpp
===================================================================
--- src/vsip/impl/extdata.hpp	(revision 148422)
+++ src/vsip/impl/extdata.hpp	(working copy)
@@ -213,6 +213,8 @@
     { return blk->impl_stride(dim, d); }
   length_type	size  (Block* blk, dimension_type d) const
     { return blk->size(dim, d); }
+  length_type	size  (Block* blk) const
+    { return blk->size(); }
 };
 
 
@@ -282,6 +284,8 @@
     { return blk->impl_stride(dim, d); }
   length_type	size  (Block* blk, dimension_type d) const
     { return blk->size(dim, d); }
+  length_type	size  (Block* blk) const
+    { return blk->size(); }
 };
 
 
@@ -467,6 +471,8 @@
     { return use_direct_ ? blk->impl_stride(dim, d) : layout_.stride(d); }
   length_type	size  (Block* blk, dimension_type d) const
     { return use_direct_ ? blk->size(dim, d) : blk->size(Block::dim, d); }
+  length_type	size  (Block* blk) const
+    { return blk->size(); }
 
   // Member data.
 private:
@@ -561,6 +567,8 @@
     { return layout_.stride(d); }
   length_type	size  (Block* blk, dimension_type d) const
     { return blk->size(Block::dim, d); }
+  length_type	size  (Block* blk) const
+    { return blk->size(); }
 
   // Member data.
 private:
@@ -745,6 +753,9 @@
   length_type size(dimension_type d) const
     { return ext_.size  (blk_.get(), d); }
 
+  length_type size() const
+    { return ext_.size  (blk_.get()); }
+
   int cost() const
     { return ext_.cost(); }
 
Index: src/vsip/impl/replicated_map.hpp
===================================================================
--- src/vsip/impl/replicated_map.hpp	(revision 148422)
+++ src/vsip/impl/replicated_map.hpp	(working copy)
@@ -185,7 +185,7 @@
   {
     for (index_type i=0; i<this->num_processors(); ++i)
       if (data_->pset_.get(i) == pr) return i;
-    return no_processor;
+    return no_rank;
   }
 
 
Index: src/vsip/impl/pas/block.hpp
===================================================================
--- src/vsip/impl/pas/block.hpp	(revision 148422)
+++ src/vsip/impl/pas/block.hpp	(working copy)
@@ -24,6 +24,7 @@
 #include <vsip/impl/dist.hpp>
 #include <vsip/impl/get_local_view.hpp>
 #include <vsip/impl/proxy_local_block.hpp>
+#include <vsip/impl/pas/offset.hpp>
 
 #define VSIP_IMPL_PAS_BLOCK_VERBOSE 0
 
@@ -41,8 +42,12 @@
 namespace pas
 {
 
+
+
+
 template <typename       T,
 	  typename       OrderT,
+	  typename       ComplexFmt,
 	  dimension_type Dim,
 	  typename       MapT>
 void
@@ -56,7 +61,7 @@
   PAS_buffer**             buffer)
 {
   PAS_data_spec        data_spec = pas::Pas_datatype<T>::value();
-  unsigned long const  alignment = 0; // indicates PAS default alignment
+  unsigned long const  alignment = VSIP_IMPL_PAS_ALIGNMENT;
   long                 rc;
 
   long const           no_flag = 0;
@@ -73,7 +78,21 @@
   PAS_layout_handle    layout_handle[gdo_dim];
   PAS_partition_handle partition[gdo_dim];
   PAS_overlap_handle   zero_overlap;
+  long                 distribution_flag;
+  long                 components;
 
+  if (Type_equal<ComplexFmt, Cmplx_split_fmt>::value &&
+      Is_complex<T>::value)
+  {
+    components = 2;
+    distribution_flag = PAS_SPLIT;
+  }
+  else
+  {
+    components = 1;
+    distribution_flag = PAS_ATOMIC;
+  }
+
   pas_overlap_create(
     PAS_OVERLAP_PAD_ZEROS, 
     0,				// num_positions
@@ -163,7 +182,7 @@
     partition,			// array of partition spec per dim
     layout_handle,		// layout spec
     0,				// buffer_offset
-    PAS_ATOMIC,			// flags
+    distribution_flag,		// ATOMIC or SPLIT
     &dist_handle);		// returned distribution handle
   VSIP_IMPL_CHECK_RC(rc,"pas_distribution_create");
 
@@ -180,7 +199,7 @@
     map.impl_ll_pset(),		// process set
     local_nbytes,		// allocation size
     alignment,			// alignment
-    1,				// max split buffer components
+    components,			// max split buffer components
     PAS_ZERO,			// flags
     &pbuf_handle);		// returned pbuf handle
   VSIP_IMPL_CHECK_RC(rc,"pas_pbuf_create");
@@ -201,6 +220,11 @@
       0,			// channel for mapping
       buffer);			// allocated buffer ptr
     VSIP_IMPL_CHECK_RC(rc,"pas_buffer_alloc");
+
+    if (distribution_flag == PAS_ATOMIC)
+      assert((*buffer)->num_virt_addrs == 1);
+    else
+      assert((*buffer)->num_virt_addrs == 2);
   }
   else
     *buffer = NULL;
@@ -255,6 +279,11 @@
   typedef typename Block_layout<local_block_type>::layout_type local_LP;
   typedef Proxy_local_block<Dim, T, local_LP>        proxy_local_block_type;
 
+  static long const components =
+    (Type_equal<impl_complex_type, Cmplx_split_fmt>::value &&
+     Is_complex<T>::value)
+    ? 2 : 1;
+
   // Private compile-time values and types.
 private:
   enum private_type {};
@@ -265,8 +294,9 @@
     Domain<dim> sb_dom = 
       (sb_ != no_subblock) ? map_.template impl_subblock_domain<dim>(sb_)
                            : empty_domain<dim>();
+    Domain<dim> sb_dom_0 = map_.template impl_subblock_domain<dim>(0);
 
-    pas::pbuf_create<T, OrderT>(
+    pas::pbuf_create<T, OrderT, impl_complex_type>(
       tag_,
       dom,
       map_,
@@ -334,8 +364,61 @@
       }
 
 
-      subblock_ = new local_block_type(sb_dom,
-				       (T*)pas_buffer_->virt_addr_list[0]);
+      assert(pas_buffer_->num_virt_addrs == components);
+
+      if (Type_equal<impl_complex_type, Cmplx_split_fmt>::value &&
+	  Is_complex<T>::value)
+      {
+	typedef typename Scalar_of<T>::type scalar_type;
+	assert(pas_buffer_->elem_nbytes           == sizeof(T));
+	assert(pas_buffer_->elem_component_nbytes == sizeof(scalar_type));
+
+#if VSIP_IMPL_PAS_BLOCK_VERBOSE
+	// Check that the offset of the imaginary data (PAS' second
+	// component) is consistent.
+
+	// First, make sure that a scalar_type evenly divides the
+	// alignment.
+	assert(VSIP_IMPL_PAS_ALIGNMENT % sizeof(scalar_type) == 0);
+
+	// Second, compute the padding and expected offset.
+	size_t t_alignment = (VSIP_IMPL_PAS_ALIGNMENT / sizeof(scalar_type));
+	size_t offset      = sb_dom_0.size();
+	size_t extra       = offset % t_alignment;
+
+	// If not naturally aligned (extra != 0), pad by t_alignment - extra.
+	if (extra) offset += (t_alignment - extra);
+
+	std::cout << "offset " << tag_ << ":"
+		  << " dom: " << sb_dom
+		  << " size: " << sb_dom.size()
+		  << " real: "
+		  << (scalar_type*)pas_buffer_->virt_addr_list[1] -
+	             (scalar_type*)pas_buffer_->virt_addr
+		  << "  expected: " << offset 
+		  << "  (extra: " << extra << ")"
+		  << std::endl;
+
+	assert(offset = ( (scalar_type*)pas_buffer_->virt_addr_list[1] -
+			  (scalar_type*)pas_buffer_->virt_addr ));
+#endif
+
+	Offset<impl_complex_type, T>::check_imag_offset(
+			sb_dom_0.size(),
+			(scalar_type*)pas_buffer_->virt_addr_list[1] -
+			(scalar_type*)pas_buffer_->virt_addr);
+	       
+	subblock_ = new local_block_type(sb_dom,
+			impl::User_storage<T>(split_format, 
+				(scalar_type*)pas_buffer_->virt_addr_list[0],
+				(scalar_type*)pas_buffer_->virt_addr_list[1]));
+      }
+      else
+      {
+	subblock_ = new local_block_type(sb_dom,
+			impl::User_storage<T>(array_format, 
+				(T*)pas_buffer_->virt_addr_list[0]));
+      }
       subblock_->admit(false);
     }
     else
@@ -698,9 +781,18 @@
   PAS_pbuf_handle impl_ll_pbuf() VSIP_NOTHROW
   { return pbuf_handle_; }
 
-  long impl_offset() VSIP_NOTHROW
-  { return 0; }
+  // Provide component offset (real-component, imaginary-component)
+  // Used by Direct_pas_assign algorithm when using split-complex.
+public:
+  typedef Offset<impl_complex_type, T> offset_traits;
+  typedef typename offset_traits::type offset_type;
 
+  offset_type impl_component_offset() const VSIP_NOTHROW
+  {
+    Domain<dim> sb_dom_0 = map_.template impl_subblock_domain<dim>(0);
+    return offset_traits::create(sb_dom_0.size());
+  }
+
   // Member data.
 private:
   map_type                 map_;
@@ -712,10 +804,8 @@
   bool                     admitted_;
   
   long                    tag_;
-public:
   PAS_global_data_handle  gdo_handle_;
   PAS_distribution_handle dist_handle_;
-private:
   PAS_pbuf_handle         pbuf_handle_;
   PAS_buffer*             pas_buffer_;
 };
Index: src/vsip/impl/pas/param.hpp
===================================================================
--- src/vsip/impl/pas/param.hpp	(revision 148422)
+++ src/vsip/impl/pas/param.hpp	(working copy)
@@ -15,20 +15,32 @@
 ***********************************************************************/
 
 // Set VSIP_IMPL_PAS_XR to 1 when using PAS for Linux
-#define VSIP_IMPL_PAS_XR                        1
-#define VSIP_IMPL_PAS_XR_SET_PORTNUM            0
-#define VSIP_IMPL_PAS_XR_SET_ADAPTERNAME        1
-#define VSIP_IMPL_PAS_XR_SET_SHMKEY             1
-#define VSIP_IMPL_PAS_XR_SET_PIR                0
-#define VSIP_IMPL_PAS_XR_SET_RMD                0
-#define VSIP_IMPL_PAS_XR_SET_UDAPL_MAX_RECVS    0
-#define VSIP_IMPL_PAS_XR_SET_UDAPL_MAX_REQUESTS 0
+#if PAS_RDMA
+#  define VSIP_IMPL_PAS_XR                        1
+#else
+#  define VSIP_IMPL_PAS_XR                        0
+#endif
 
-#define VSIP_IMPL_PAS_USE_INTERRUPT() 1
-#define VSIP_IMPL_PAS_XFER_ENGINE PAS_DMA
-#define VSIP_IMPL_PAS_XR_ADAPTERNAME "ib0" /* Commonly used with Mercury XR9 */
-#define VSIP_IMPL_PAS_XR_SHMKEY 1918
+#if VSIP_IMPL_PAS_XR
+#  define VSIP_IMPL_PAS_XR_SET_PORTNUM            0
+#  define VSIP_IMPL_PAS_XR_SET_ADAPTERNAME        1
+#  define VSIP_IMPL_PAS_XR_SET_SHMKEY             1
+#  define VSIP_IMPL_PAS_XR_SET_PIR                0
+#  define VSIP_IMPL_PAS_XR_SET_RMD                0
+#  define VSIP_IMPL_PAS_XR_SET_UDAPL_MAX_RECVS    0
+#  define VSIP_IMPL_PAS_XR_SET_UDAPL_MAX_REQUESTS 0
 
+#  define VSIP_IMPL_PAS_USE_INTERRUPT() 1
+#  define VSIP_IMPL_PAS_XFER_ENGINE PAS_DMA
+#  define VSIP_IMPL_PAS_XR_ADAPTERNAME "ib0" /* Commonly used with Mercury XR9 */
+#  define VSIP_IMPL_PAS_XR_SHMKEY 1918
+#else
+#  define VSIP_IMPL_PAS_USE_INTERRUPT() 0
+#  define VSIP_IMPL_PAS_XFER_ENGINE PAS_DMA
+#endif
+
+#define VSIP_IMPL_PAS_ALIGNMENT 16
+
 #if VSIP_IMPL_PAS_USE_INTERRUPT()
 #  define VSIP_IMPL_PAS_SEM_GIVE_AFTER PAS_SEM_GIVE_INTERRUPT_AFTER
 #else
Index: src/vsip/impl/pas/par_assign_direct.hpp
===================================================================
--- src/vsip/impl/pas/par_assign_direct.hpp	(revision 148422)
+++ src/vsip/impl/pas/par_assign_direct.hpp	(working copy)
@@ -23,6 +23,7 @@
 #include <vsip/impl/profile.hpp>
 #include <vsip/impl/par_assign.hpp>
 #include <vsip/impl/par_assign_common.hpp>
+#include <vsip/impl/pas/offset.hpp>
 
 #define VSIP_IMPL_PCA_VERBOSE 0
 
@@ -41,10 +42,51 @@
 namespace par_chain_assign
 {
 
+template <typename MsgRecord>
+void
+msg_push(
+  std::vector<MsgRecord>& list,
+  processor_type          proc,
+  index_type              src_msg_offset,
+  index_type              dst_msg_offset,
+  stride_type             src_pbuf_offset,
+  stride_type             dst_pbuf_offset,
+  length_type             size)
+{
+  list.push_back(MsgRecord(proc,
+			   src_msg_offset + src_pbuf_offset,
+			   dst_msg_offset + dst_pbuf_offset,
+			   size));
+}
+
+template <typename MsgRecord>
+void
+msg_push(
+  std::vector<MsgRecord>&             list,
+  processor_type                      proc,
+  index_type                          src_msg_offset,
+  index_type                          dst_msg_offset,
+  std::pair<stride_type, stride_type> src_pbuf_offset,
+  std::pair<stride_type, stride_type> dst_pbuf_offset,
+  length_type                         size)
+{
+  list.push_back(MsgRecord(proc,
+			   src_msg_offset + src_pbuf_offset.first,
+			   dst_msg_offset + dst_pbuf_offset.first,
+			   size));
+  list.push_back(MsgRecord(proc,
+			   src_msg_offset + src_pbuf_offset.second,
+			   dst_msg_offset + dst_pbuf_offset.second,
+			   size));
+}
+
+
+
 template <typename OrderT,
 	  typename MsgRecord,
 	  typename SrcExtDataT,
-	  typename DstExtDataT>
+	  typename DstExtDataT,
+	  typename OffsetT>
 inline void
 msg_add(
   std::vector<MsgRecord>& list,
@@ -54,8 +96,10 @@
   Domain<1> const&        src_dom,
   Domain<1> const&        dst_dom,
   Domain<1> const&        intr,
-  long                    src_pbuf_offset,
-  long                    dst_pbuf_offset)
+  stride_type             src_offset,
+  stride_type             dst_offset,
+  OffsetT                 src_comp_offset,
+  OffsetT                 dst_comp_offset)
 {
   dimension_type const dim  = 1;
   dimension_type const dim0 = OrderT::impl_dim0;
@@ -64,29 +108,30 @@
   stride_type src_stride = src_ext.stride(dim0);
   stride_type dst_stride = dst_ext.stride(dim0);
 
-  Index<dim>  src_offset = first(intr) - first(src_dom);
-  Index<dim>  dst_offset = first(intr) - first(dst_dom);
+  Index<dim>  src_index = first(intr) - first(src_dom);
+  Index<dim>  dst_index = first(intr) - first(dst_dom);
 
-  index_type real_src_offset = src_offset[0] * src_stride + src_pbuf_offset;
-  index_type real_dst_offset = dst_offset[0] * dst_stride + dst_pbuf_offset;
+  index_type src_msg_offset = src_index[0] * src_stride + src_offset;
+  index_type dst_msg_offset = dst_index[0] * dst_stride + dst_offset;
 
   length_type size = intr.length();
 
   if (intr.stride() == 1 && src_stride == 1 && dst_stride == 1)
   {
-    list.push_back(MsgRecord(proc, 
-			      real_src_offset,
-			      real_dst_offset,
-			      size));
+    msg_push(list, proc,
+	     src_msg_offset, dst_msg_offset,
+	     src_comp_offset, dst_comp_offset,
+	     size);
   }
   else
   {
     for (index_type i=0; i<size; ++i)
     {
-      list.push_back(MsgRecord(proc, 
-				real_src_offset + i*src_stride*intr.stride(),
-				real_dst_offset + i*dst_stride*intr.stride(),
-				1));
+      msg_push(list, proc,
+	       src_msg_offset + i*src_stride*intr.stride(),
+	       dst_msg_offset + i*dst_stride*intr.stride(),
+	       src_comp_offset, dst_comp_offset,
+	       1);
     }
   }
 }
@@ -95,7 +140,8 @@
 template <typename OrderT,
 	  typename MsgRecord,
 	  typename SrcExtDataT,
-	  typename DstExtDataT>
+	  typename DstExtDataT,
+	  typename OffsetT>
 inline void
 msg_add(
   std::vector<MsgRecord>& list,
@@ -105,23 +151,25 @@
   Domain<2> const&        src_dom,
   Domain<2> const&        dst_dom,
   Domain<2> const&        intr,
-  long                    src_pbuf_offset,
-  long                    dst_pbuf_offset)
+  stride_type             src_offset,
+  stride_type             dst_offset,
+  OffsetT                 src_comp_offset,
+  OffsetT                 dst_comp_offset)
 {
   dimension_type const dim = 2;
 
   dimension_type const dim0 = OrderT::impl_dim0;
   dimension_type const dim1 = OrderT::impl_dim1;
 
-  Index<dim>  src_offset = first(intr) - first(src_dom);
-  Index<dim>  dst_offset = first(intr) - first(dst_dom);
+  Index<dim>  src_index = first(intr) - first(src_dom);
+  Index<dim>  dst_index = first(intr) - first(dst_dom);
 
-  index_type real_src_offset = src_offset[dim0] * src_ext.stride(dim0) 
-                             + src_offset[dim1] * src_ext.stride(dim1)
-                             + src_pbuf_offset;
-  index_type real_dst_offset = dst_offset[dim0] * dst_ext.stride(dim0) 
-                             + dst_offset[dim1] * dst_ext.stride(dim1)
-                             + dst_pbuf_offset;
+  index_type src_msg_offset = src_index[dim0] * src_ext.stride(dim0) 
+                            + src_index[dim1] * src_ext.stride(dim1)
+                            + src_offset;
+  index_type dst_msg_offset = dst_index[dim0] * dst_ext.stride(dim0) 
+                            + dst_index[dim1] * dst_ext.stride(dim1)
+                            + dst_offset;
 
   length_type size = intr[dim1].length();
 
@@ -130,24 +178,25 @@
     if (intr[dim1].stride() == 1 && src_ext.stride(dim1) == 1 &&
 	dst_ext.stride(dim1) == 1)
     {
-      list.push_back(MsgRecord(proc, 
-			       real_src_offset,
-			       real_dst_offset,
-			       size));
+      msg_push(list, proc,
+	       src_msg_offset, dst_msg_offset,
+	       src_comp_offset, dst_comp_offset,
+	       size);
     }
     else
     {
       for (index_type j=0; j<size; ++j)
       {
-	list.push_back(MsgRecord(proc, 
-		real_src_offset + j*src_ext.stride(dim1)*intr[dim1].stride(),
-		real_dst_offset + j*dst_ext.stride(dim1)*intr[dim1].stride(),
-		1));
+	msg_push(list, proc,
+		 src_msg_offset + j*src_ext.stride(dim1)*intr[dim1].stride(),
+		 dst_msg_offset + j*dst_ext.stride(dim1)*intr[dim1].stride(),
+		 src_comp_offset, dst_comp_offset,
+		 1);
       }
     }
     
-    real_src_offset += intr[dim0].stride() * src_ext.stride(dim0);
-    real_dst_offset += intr[dim0].stride() * dst_ext.stride(dim0);
+    src_msg_offset += intr[dim0].stride() * src_ext.stride(dim0);
+    dst_msg_offset += intr[dim0].stride() * dst_ext.stride(dim0);
   }
 }
 
@@ -166,8 +215,10 @@
   Domain<3> const&        src_dom,
   Domain<3> const&        dst_dom,
   Domain<3> const&        intr,
-  long                    src_pbuf_offset,
-  long                    dst_pbuf_offset)
+  stride_type             src_offset,
+  stride_type             dst_offset,
+  long                    src_comp_offset,
+  long                    dst_comp_offset)
 {
   dimension_type const dim = 3;
 
@@ -175,51 +226,52 @@
   dimension_type const dim1 = OrderT::impl_dim1;
   dimension_type const dim2 = OrderT::impl_dim2;
 
-  Index<dim>  src_offset = first(intr) - first(src_dom);
-  Index<dim>  dst_offset = first(intr) - first(dst_dom);
+  Index<dim>  src_index = first(intr) - first(src_dom);
+  Index<dim>  dst_index = first(intr) - first(dst_dom);
 
-  index_type real_src_offset = src_offset[dim0] * src_ext.stride(dim0) 
-                             + src_offset[dim1] * src_ext.stride(dim1)
-                             + src_offset[dim2] * src_ext.stride(dim2)
-                             + src_pbuf_offset;
-  index_type real_dst_offset = dst_offset[dim0] * dst_ext.stride(dim0) 
-                             + dst_offset[dim1] * dst_ext.stride(dim1)
-                             + dst_offset[dim2] * dst_ext.stride(dim2)
-                             + dst_pbuf_offset;
+  index_type src_msg_offset = src_index[dim0] * src_ext.stride(dim0) 
+                            + src_index[dim1] * src_ext.stride(dim1)
+                            + src_index[dim2] * src_ext.stride(dim2)
+                            + src_offset;
+  index_type dst_msg_offset = dst_index[dim0] * dst_ext.stride(dim0) 
+                            + dst_index[dim1] * dst_ext.stride(dim1)
+                            + dst_index[dim2] * dst_ext.stride(dim2)
+                            + dst_offset;
 
   length_type size = intr[dim2].length();
 
   for (index_type i=0; i<intr[dim0].size(); ++i)
   {
-    index_type real_src_offset_1 = real_src_offset;
-    index_type real_dst_offset_1 = real_dst_offset;
+    index_type src_msg_offset_1 = src_msg_offset;
+    index_type dst_msg_offset_1 = dst_msg_offset;
 
     for (index_type j=0; j<intr[dim1].size(); ++j)
     {
       if (intr[dim2].stride() == 1 && src_ext.stride(dim2) == 1 &&
 	  dst_ext.stride(dim2) == 1)
       {
-	list.push_back(MsgRecord(proc, 
-				 real_src_offset_1,
-				 real_dst_offset_1,
-				 size));
+	msg_push(list, proc,
+		 src_msg_offset_1, dst_msg_offset_1,
+		 src_comp_offset, dst_comp_offset,
+		 size);
       }
       else
       {
 	for (index_type k=0; k<size; ++k)
 	{
-	  list.push_back(MsgRecord(proc, 
-		real_src_offset_1 + k*src_ext.stride(dim2)*intr[dim2].stride(),
-		real_dst_offset_1 + k*dst_ext.stride(dim2)*intr[dim2].stride(),
-		1));
+	  msg_push(list, proc,
+		src_msg_offset_1 + k*src_ext.stride(dim2)*intr[dim2].stride(),
+		dst_msg_offset_1 + k*dst_ext.stride(dim2)*intr[dim2].stride(),
+		src_comp_offset, dst_comp_offset,
+		1);
 	}
       }
     
-      real_src_offset_1 += intr[dim1].stride() * src_ext.stride(dim1);
-      real_dst_offset_1 += intr[dim1].stride() * dst_ext.stride(dim1);
+      src_msg_offset_1 += intr[dim1].stride() * src_ext.stride(dim1);
+      dst_msg_offset_1 += intr[dim1].stride() * dst_ext.stride(dim1);
     }
-    real_src_offset += intr[dim0].stride() * src_ext.stride(dim0);
-    real_dst_offset += intr[dim0].stride() * dst_ext.stride(dim0);
+    src_msg_offset += intr[dim0].stride() * src_ext.stride(dim0);
+    dst_msg_offset += intr[dim0].stride() * dst_ext.stride(dim0);
   }
 }
 
@@ -464,8 +516,17 @@
   length_type dsize  = dst_am_.impl_working_size();
   // std::min(dst_am_.num_subblocks(), dst_am_.impl_pvec().size());
 
-  long src_pbuf_offset = src_.local().block().impl_offset();
+  typedef typename Offset<typename Block_layout<Block1>::complex_type,
+                          T1>::type dst_offset_type;
+  typedef typename Offset<typename Block_layout<Block2>::complex_type,
+                          T2>::type src_offset_type;
 
+  stride_type src_offset = src_.local().block().impl_offset();
+  src_offset_type src_comp_offset = block_root(src_.block())
+                                        .impl_component_offset();
+  dst_offset_type dst_comp_offset = block_root(dst_.block())
+                                        .impl_component_offset();
+
 #if VSIP_IMPL_PCA_VERBOSE >= 1
     std::cout << "[" << rank << "] "
 	      << "build_send_list(dsize: " << dsize
@@ -506,7 +567,7 @@
 
 	proxy_local_block_type proxy = get_local_proxy(dst_.block(), dst_sb);
 	Ext_data<proxy_local_block_type> proxy_ext(proxy);
-	long dst_pbuf_offset = proxy.impl_offset();
+	stride_type dst_offset = proxy.impl_offset();
 
 	for (index_type dp=0; dp<num_patches(dst_, dst_sb); ++dp)
 	{
@@ -527,8 +588,9 @@
 		proxy_ext,
 		proc,
 		src_dom, dst_dom, intr,
-		src_pbuf_offset,
-		dst_pbuf_offset);
+		src_offset, dst_offset,
+		src_comp_offset,
+		dst_comp_offset);
 
 #if VSIP_IMPL_PCA_VERBOSE >= 2
 	      std::cout << "(" << rank << ") send "
@@ -674,6 +736,13 @@
 #endif
   typedef typename std::vector<Msg_record>::iterator sl_iterator;
 
+  size_t elem_size;
+
+  if (Is_split_block<Block1>::value)
+    elem_size = sizeof(typename Scalar_of<T1>::type);
+  else
+    elem_size = sizeof(T1);
+
   sl_iterator msg    = send_list.begin();
   sl_iterator sl_end = send_list.end();
   if (msg != sl_end)
@@ -683,11 +752,11 @@
       rc = pas_move_nbytes(
 	src_pnum,
 	src_pbuf,
-	sizeof(T1)*(*msg).src_offset_,
+	elem_size*(*msg).src_offset_,
 	(*msg).proc_,		// dst_pnum
 	dst_pbuf,
-	sizeof(T1)*(*msg).dst_offset_,
-	sizeof(T1)*(*msg).size_,
+	elem_size*(*msg).dst_offset_,
+	elem_size*(*msg).size_,
 	0,
 	pull_flags | PAS_PUSH | VSIP_IMPL_PAS_XFER_ENGINE,
 	NULL);
Index: src/vsip/impl/pas/services.hpp
===================================================================
--- src/vsip/impl/pas/services.hpp	(revision 148422)
+++ src/vsip/impl/pas/services.hpp	(working copy)
@@ -221,7 +221,7 @@
     assert(rc == CE_SUCCESS);
     delete[] pnums;
 
-    bcast_ = std::auto_ptr<pas::Broadcast>(new pas::Broadcast(impl_ll_pset()));
+    bcast_.reset(new pas::Broadcast(impl_ll_pset()));
   }
 
   void initialize(long rank, long size)
@@ -243,7 +243,7 @@
     assert(rc == CE_SUCCESS);
     delete[] pnums;
 
-    bcast_ = std::auto_ptr<pas::Broadcast>(new pas::Broadcast(impl_ll_pset()));
+    bcast_.reset(new pas::Broadcast(impl_ll_pset()));
   }
 
   void cleanup()
Index: src/vsip/impl/pas/par_assign.hpp
===================================================================
--- src/vsip/impl/pas/par_assign.hpp	(revision 148422)
+++ src/vsip/impl/pas/par_assign.hpp	(working copy)
@@ -82,6 +82,9 @@
     long  dst_npnums;
     unsigned long  all_npnums;
 
+    long  max_components = Block1::components > Block2::components ?
+                           Block1::components : Block2::components;
+
     pas_pset_get_pnums_list(src_pset, &src_pnums, &src_npnums);
     pas_pset_get_pnums_list(dst_pset, &dst_pnums, &dst_npnums);
     all_pnums = pas_pset_combine(src_pnums, dst_pnums, PAS_PSET_UNION,
@@ -122,8 +125,8 @@
 	  0, 
 	  all_pset,
 	  local_nbytes,
-	  1,
-	  1,
+	  0,			// Default alignment
+	  max_components,
 	  PAS_ZERO,
 	  &tmp_pbuf_);
 	assert(rc == CE_SUCCESS);
Index: src/vsip/impl/block-traits.hpp
===================================================================
--- src/vsip/impl/block-traits.hpp	(revision 148422)
+++ src/vsip/impl/block-traits.hpp	(working copy)
@@ -128,6 +128,23 @@
 
 
 
+/// Traits class to determine the root block for a stack of subblocks.
+
+template <typename BlockT>
+struct Block_root
+{
+  typedef BlockT type;
+};
+
+template <typename BlockT>
+BlockT const&
+block_root(BlockT const& block)
+{
+  return block;
+}
+
+
+
 /// Data Access Tags.
 
 /// These are used in the Block_layout trait to select the appropriate
Index: src/vsip/impl/proxy_local_block.hpp
===================================================================
--- src/vsip/impl/proxy_local_block.hpp	(revision 148422)
+++ src/vsip/impl/proxy_local_block.hpp	(working copy)
@@ -59,8 +59,8 @@
 
   // Direct_data interface.
 public:
-  long impl_offset() VSIP_NOTHROW
-    { return 0; }
+  stride_type impl_offset() VSIP_NOTHROW
+  { return 0; }
 
   // NO // impl_data_type       impl_data()       VSIP_NOTHROW
 
Index: src/vsip/impl/subblock.hpp
===================================================================
--- src/vsip/impl/subblock.hpp	(revision 148422)
+++ src/vsip/impl/subblock.hpp	(working copy)
@@ -386,7 +386,7 @@
   par_ll_pbuf_type impl_ll_pbuf() VSIP_NOTHROW
   { return blk_->impl_ll_pbuf(); }
 
-  long impl_offset() VSIP_NOTHROW
+  stride_type impl_offset() VSIP_NOTHROW
   {
     stride_type offset = blk_->impl_offset();
     for (dimension_type d=0; d<dim; ++d)
@@ -432,6 +432,22 @@
   : By_value_block_storage<Subset_block<Block> >
 {};
 
+
+template <typename BlockT>
+struct Block_root<Subset_block<BlockT> >
+{
+  typedef typename Block_root<BlockT>::type type;
+};
+
+template <typename       BlockT>
+typename Block_root<Subset_block<BlockT> >::type const&
+block_root(Subset_block<BlockT> const& block)
+{
+  return block_root(block.impl_block());
+}
+
+
+
 template <typename Block>
 struct Block_layout<Subset_block<Block> >
 {
@@ -885,8 +901,10 @@
   par_ll_pbuf_type impl_ll_pbuf() VSIP_NOTHROW
   { return blk_->impl_ll_pbuf(); }
 
-  long impl_offset() VSIP_NOTHROW
-  { return blk_->impl_offset() + index_*blk_->impl_stride(Block::dim, D); }
+  stride_type impl_offset() VSIP_NOTHROW
+  {
+    return blk_->impl_offset() + index_*blk_->impl_stride(Block::dim, D);
+  }
 
   data_type       impl_data()       VSIP_NOTHROW
   {
@@ -1076,11 +1094,11 @@
   par_ll_pbuf_type impl_ll_pbuf() VSIP_NOTHROW
   { return blk_->impl_ll_pbuf(); }
 
-  long impl_offset() VSIP_NOTHROW
+  stride_type impl_offset() VSIP_NOTHROW
   {
-    return + blk_->impl_offset()
-           + index1_*blk_->impl_stride(Block::dim, D1)
-           + index2_*blk_->impl_stride(Block::dim, D2);
+    return blk_->impl_offset()
+	 + index1_*blk_->impl_stride(Block::dim, D1)
+	 + index2_*blk_->impl_stride(Block::dim, D2);
   }
 
   data_type       impl_data()       VSIP_NOTHROW
@@ -1222,6 +1240,23 @@
 
 
 
+template <typename       BlockT,
+	  dimension_type Dim>
+struct Block_root<Sliced_block<BlockT, Dim> >
+{
+  typedef typename Block_root<BlockT>::type type;
+};
+
+template <typename       BlockT,
+	  dimension_type Dim>
+typename Block_root<Sliced_block<BlockT, Dim> >::type const&
+block_root(Sliced_block<BlockT, Dim> const& block)
+{
+  return block_root(block.impl_block());
+}
+
+
+
 template <typename       Block,
 	  dimension_type Dim>
 struct Block_layout<Sliced_block<Block, Dim> >
@@ -1254,6 +1289,25 @@
 
 
 
+template <typename       BlockT,
+	  dimension_type D1,
+	  dimension_type D2> 
+struct Block_root<Sliced2_block<BlockT, D1, D2> >
+{
+  typedef typename Block_root<BlockT>::type type;
+};
+
+template <typename       BlockT,
+	  dimension_type D1,
+	  dimension_type D2> 
+typename Block_root<Sliced2_block<BlockT, D1, D2> >::type const&
+block_root(Sliced2_block<BlockT, D1, D2> const& block)
+{
+  return block_root(block.impl_block());
+}
+
+
+
 template <typename       Block,
 	  dimension_type D1,
 	  dimension_type D2> 
Index: tests/parallel/corner-turn.cpp
===================================================================
--- tests/parallel/corner-turn.cpp	(revision 148422)
+++ tests/parallel/corner-turn.cpp	(working copy)
@@ -33,37 +33,17 @@
   Definitions
 ***********************************************************************/
 
-int
-main(int argc, char** argv)
+template <typename T>
+void
+corner_turn(
+  length_type rows,
+  length_type cols)
 {
-  vsipl vpp(argc, argv);
-
-#if 0
-  // Enable this section for easier debugging.
-  impl::Communicator comm = impl::default_communicator();
-  pid_t pid = getpid();
-
-  cout << "rank: "   << comm.rank()
-       << "  size: " << comm.size()
-       << "  pid: "  << pid
-       << endl;
-
-  // Stop each process, allow debugger to be attached.
-  if (comm.rank() == 0) fgetc(stdin);
-  comm.barrier();
-  cout << "start\n";
-#endif
-
-  typedef float T;
-
-  typedef Map<Block_dist, Block_dist> map_type;
+  typedef Map<Block_dist, Block_dist>      map_type;
   typedef Dense<2, T, row2_type, map_type> block_type;
 
   processor_type np   = num_processors();
 
-  length_type rows = 32;
-  length_type cols = 64;
-
   map_type root_map(1, 1);
   map_type row_map (np, 1);
   map_type col_map (1, np);
@@ -77,7 +57,7 @@
   {
     // cout << local_processor() << "/" << np << ": initializing " << endl;
     for (index_type r=0; r<rows; ++r)
-      for (index_type c=0; c<rows; ++c)
+      for (index_type c=0; c<cols; ++c)
 	src.local().put(r, c, T(r*cols+c));
   }
 
@@ -89,10 +69,47 @@
   {
     // cout << local_processor() << "/" << np << ": checking " << endl;
     for (index_type r=0; r<rows; ++r)
-      for (index_type c=0; c<rows; ++c)
+      for (index_type c=0; c<cols; ++c)
 	test_assert(equal(src.local().get(r, c),
 			  dst.local().get(r, c)));
   }
+}
 
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
+  corner_turn<float>(32, 64);
+
+  corner_turn<complex<float> >(32, 64);
+  corner_turn<complex<float> >(31, 15);
+
+  corner_turn<complex<float> >(11, 1);
+  corner_turn<complex<float> >(11, 2);
+  corner_turn<complex<float> >(11, 3);
+  corner_turn<complex<float> >(11, 4);
+  corner_turn<complex<float> >(11, 5);
+  corner_turn<complex<float> >(11, 6);
+  corner_turn<complex<float> >(11, 7);
+
   return 0;
 }
Index: tests/parallel/subviews.cpp
===================================================================
--- tests/parallel/subviews.cpp	(revision 148422)
+++ tests/parallel/subviews.cpp	(working copy)
@@ -140,11 +140,11 @@
 
   get_np_square(np, nr, nc);
 
-  test_row_sum<float>(dom, Map<>(Block_dist(np), Block_dist(1)));
-  test_row_sum<float>(dom, Map<>(Block_dist(1),  Block_dist(np)));
-  test_row_sum<float>(dom, Map<>(Block_dist(nr), Block_dist(nc)));
+  test_row_sum<T>(dom, Map<>(Block_dist(np), Block_dist(1)));
+  test_row_sum<T>(dom, Map<>(Block_dist(1),  Block_dist(np)));
+  test_row_sum<T>(dom, Map<>(Block_dist(nr), Block_dist(nc)));
 
-  test_row_sum<float>(dom, Global_map<2>());
+  test_row_sum<T>(dom, Global_map<2>());
 }
 
 
@@ -253,9 +253,9 @@
 
   get_np_square(np, nr, nc);
 
-  test_col_sum<float>(dom, Map<>(Block_dist(np), Block_dist(1)));
-  test_col_sum<float>(dom, Map<>(Block_dist(1),  Block_dist(np)));
-  test_col_sum<float>(dom, Map<>(Block_dist(nr), Block_dist(nc)));
+  test_col_sum<T>(dom, Map<>(Block_dist(np), Block_dist(1)));
+  test_col_sum<T>(dom, Map<>(Block_dist(1),  Block_dist(np)));
+  test_col_sum<T>(dom, Map<>(Block_dist(nr), Block_dist(nc)));
 }
 
 
@@ -632,6 +632,7 @@
   bool do_tmat = false;
   bool do_tvec = false;
   bool do_all  = false;
+  bool verbose = true;
 
   int cnt = 0;
 
@@ -669,15 +670,25 @@
   get_np_square(np, nr, nc);
 
   if (do_all || do_mrow)
-    cases_row_sum<float>(Domain<2>(4, 15));
+  {
+    if (verbose) cout <<  "mrow" << std::endl;
+    // cases_row_sum<float>          (Domain<2>(4, 15));
+    cases_row_sum<complex<float> >(Domain<2>(4, 5));
+  }
 
   if (do_all || do_mcol)
-    cases_col_sum<float>(Domain<2>(15, 4));
+  {
+    if (verbose) cout <<  "mcol" << std::endl;
+    cases_col_sum<float>          (Domain<2>(15, 4));
+    cases_col_sum<complex<float> >(Domain<2>(3, 4));
+  }
 
   if (do_all || do_tmat)
   {
+    if (verbose) cout <<  "tmat" << std::endl;
     // small cases
-    cases_tensor_m_sum<float, 0>(Domain<3>(4, 6, 8));
+    cases_tensor_m_sum<float,          0>(Domain<3>(4, 6, 8));
+    cases_tensor_m_sum<complex<float>, 0>(Domain<3>(4, 3, 2));
 #if VSIP_IMPL_TEST_LEVEL >= 2
     cases_tensor_m_sum<float, 0>(Domain<3>(6, 4, 8));
     cases_tensor_m_sum<float, 0>(Domain<3>(8, 6, 4));
@@ -692,7 +703,9 @@
 
   if (do_all || do_tvec)
   {
-    cases_tensor_v_sum<float, 0>(Domain<3>(4, 6, 8));
+    if (verbose) cout <<  "tvec" << std::endl;
+    cases_tensor_v_sum<float,          0>(Domain<3>(4, 6, 8));
+    cases_tensor_v_sum<complex<float>, 0>(Domain<3>(4, 3, 2));
 #if VSIP_IMPL_TEST_LEVEL >= 2
     cases_tensor_v_sum<float, 1>(Domain<3>(4, 6, 8));
     cases_tensor_v_sum<float, 2>(Domain<3>(4, 6, 8));
Index: tests/parallel/block.cpp
===================================================================
--- tests/parallel/block.cpp	(revision 148422)
+++ tests/parallel/block.cpp	(working copy)
@@ -492,6 +492,11 @@
 			 Global_map<1>(),
 			 loop);
 
+  test_par_assign<float>(Domain<1>(16),
+			 Replicated_map<1>(),
+			 Replicated_map<1>(),
+			 loop);
+
   // Vector Serial -> Block_dist
   // std::cout << "Global_map<1> -> Map<Block_dist>\n" << std::flush;
   test_par_assign<float>(Domain<1>(16),
Index: benchmarks/fftm.cpp
===================================================================
--- benchmarks/fftm.cpp	(revision 148422)
+++ benchmarks/fftm.cpp	(working copy)
@@ -44,7 +44,7 @@
 int
 fft_ops(length_type len)
 {
-  return int(5 * len * std::log(len) / std::log(2));
+  return int(5 * len * std::log((float)len) / std::log(2.f));
 }
 
 
Index: examples/mercury/mcoe-setup.sh
===================================================================
--- examples/mercury/mcoe-setup.sh	(revision 148422)
+++ examples/mercury/mcoe-setup.sh	(working copy)
@@ -23,6 +23,7 @@
 #   comm="ser"			# set to (ser)ial or (par)allel.
 #   fmt="inter"			# set to (inter)leaved or (split).
 #   opt="y"			# (y) for optimized flags, (n) for debug flags.
+#   simd_loop_fusion="y"	# (y) for SIMD loop fusion, (n) for not.
 #   builtin_simd="y"		# (y) for builtin SIMD routines, (n) for not.
 #   pflags="-t ppc7400_le"	# processor architecture
 #   fft="sal,builtin"		# FFT backend(s)
@@ -48,10 +49,18 @@
   opt="y"			# (y) for optimized flags, (n) for debug flags.
 fi
 
+if test "x$simd_loop_fusion" = x; then
+  simd_loop_fusion="y"		# (y) for SIMD loop fusion, (n) for not.
+fi
+
 if test "x$builtin_simd" = x; then
-  builtin_simd="y"			# (y) for builtin SIMD, (n) for not.
+  builtin_simd="y"		# (y) for builtin SIMD, (n) for not.
 fi
 
+if test "x$sal" = x; then
+  sal="y"			# (y) to use SAL, (n) to not.
+fi
+
 if test "x$exceptions" = x; then
   exceptions="n"		# (y) for exceptions, (n) for not.
 fi
@@ -118,6 +127,14 @@
   cfg_flags="$cfg_flags --with-builtin-simd-routines=generic"
 fi
 
+if test $simd_loop_fusion = "y"; then
+  cfg_flags="$cfg_flags --enable-simd-loop-fusion"
+fi
+
+if test $sal = "y"; then
+  cfg_flags="$cfg_flags --enable-sal"
+fi
+
 if test $exceptions = "n"; then
   cxxflags="$cxxflags --no_exceptions"
   cfg_flags="$cfg_flags --disable-exceptions"
@@ -136,7 +153,6 @@
 $dir/configure					\
 	--prefix=$prefix			\
 	--host=powerpc				\
-	--enable-sal				\
 	--enable-fft=$fft			\
 	--with-fftw3-cflags="-O2"		\
 	--with-complex=$fmt			\
