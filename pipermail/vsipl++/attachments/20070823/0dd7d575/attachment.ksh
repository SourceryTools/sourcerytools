Index: ChangeLog
===================================================================
--- ChangeLog	(revision 179602)
+++ ChangeLog	(working copy)
@@ -1,3 +1,22 @@
+2007-08-23  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/core/subblock.hpp: Fix parent local domain query for
+	  Subset_maps.
+	* src/vsip/core/parallel/subset_map_decl.hpp: Correct computation
+	  of local domain.
+	* src/vsip/core/parallel/assign_chain.hpp: Expand diagnostic output
+	  (no change to functionality).
+	* src/vsip/opt/diag/extdata.hpp: Split helper Class_name into ...
+	* src/vsip/opt/diag/class_name.hpp: ... here, new file.
+	* src/vsip/opt/diag/view.hpp: New file, diagnostics for views.
+	* src/vsip/opt/diag/eval.hpp: Add support for Tag_par_expr in
+	  Dispatch_assign diagnostics.
+	* src/vsip_csl/output.hpp: Split domain output to ...
+	* src/vsip_csl/output/domain.hpp: ... here, new file.  Allows
+	  domain output to be used in contexts where view decls aren't yet
+	  available.
+	* tests/parallel/subviews.cpp: Turn verbosity off.
+
 2007-08-21  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip/opt/simd/expr_evaluator.hpp (Proxy_factory): Fix ct_valid
Index: src/vsip/core/subblock.hpp
===================================================================
--- src/vsip/core/subblock.hpp	(revision 178911)
+++ src/vsip/core/subblock.hpp	(working copy)
@@ -1441,7 +1441,15 @@
 
   static Domain<dim> parent_local_domain(BlockT const& block, index_type sb)
   {
+#if 0
+    // consider asking Subset_map about parent's local block,
+    // rather than asking the parent to recompute it.
     return block.map().template impl_parent_local_domain<dim>(sb);
+#else
+    index_type parent_sb = block.map().impl_parent_subblock(sb);
+    return block.impl_block().map().impl_local_from_global_domain(parent_sb,
+					block.impl_domain());
+#endif
   }
 };
 
Index: src/vsip/core/parallel/subset_map_decl.hpp
===================================================================
--- src/vsip/core/parallel/subset_map_decl.hpp	(revision 176624)
+++ src/vsip/core/parallel/subset_map_decl.hpp	(working copy)
@@ -207,9 +207,11 @@
   std::vector<index_type>   parent_sb_; // map: local sb -> parent sb
   std::vector<Length<Dim> > sb_ext_;
   std::vector<Domain<Dim> > parent_sdom_;	// parent subblock dom.
-  sb_vector_type            sb_patch_gd_;	// subblock-patch global dom
-  sb_vector_type            sb_patch_ld_;	// subblock-patch local dom
 
+  sb_vector_type            sb_patch_gd_;	// sb-patch global dom
+  sb_vector_type            sb_patch_ld_;	// sb-patch local dom
+  sb_vector_type            sb_patch_pld_;	// sb-patch parent local dom
+
   impl_pvec_type            pvec_;		// Grid function.
   Domain<Dim>               dom_;		// Applied domain.
   impl::par_ll_pset_type    ll_pset_;
@@ -236,6 +238,7 @@
   {
     p_vector_type g_vec;
     p_vector_type l_vec;
+    p_vector_type pl_vec;
     
     for (index_type p=0; p<map.impl_num_patches(sb); ++p)
     {
@@ -246,19 +249,31 @@
       Domain<Dim> intr;
       if (intersect(pg_dom, dom, intr))
       {
-	// my global/local subdomains for sb-p.
-	Domain<Dim> ml_dom = apply_intr(pl_dom, pg_dom, intr);
+	// Global domain represented by intersection.
 	Domain<Dim> mg_dom = subset_from_intr(dom, intr);
 
-	g_vec.push_back(mg_dom);
-	l_vec.push_back(ml_dom);
+	// Local domain.
+	Domain<Dim> ml_dom = normalize(intr);
+
+	// Subset of parent local domain represented by intersection
+	Domain<Dim> pl_dom_intr = apply_intr(pl_dom, pg_dom, intr);
+
+	g_vec.push_back (mg_dom);
+	l_vec.push_back (ml_dom);
+	pl_vec.push_back(pl_dom_intr);
       }
     }
 
     if (g_vec.size() > 0)
     {
+      if (g_vec.size() > 1)
+      {
+	VSIP_IMPL_THROW(impl::unimplemented(
+	    "Subset_map: Subviews creating multiple patches not supported."));
+      }
       sb_patch_gd_.push_back(g_vec);
       sb_patch_ld_.push_back(l_vec);
+      sb_patch_pld_.push_back(pl_vec);
       pvec_.push_back(map.impl_proc_from_rank(sb));
 
       Length<Dim> par_sb_ext = map.template impl_subblock_extent<Dim>(sb);
Index: src/vsip/core/parallel/assign_chain.hpp
===================================================================
--- src/vsip/core/parallel/assign_chain.hpp	(revision 176624)
+++ src/vsip/core/parallel/assign_chain.hpp	(working copy)
@@ -27,8 +27,12 @@
 #define VSIP_IMPL_PCA_ROTATE  0
 #define VSIP_IMPL_PCA_VERBOSE 0
 
+#if VSIP_IMPL_PCA_VERBOSE
+#  include <vsip_csl/output/domain.hpp>
+#endif
 
 
+
 /***********************************************************************
   Declarations
 ***********************************************************************/
@@ -646,12 +650,23 @@
 					    send_dom, recv_dom));
 
 #if VSIP_IMPL_PCA_VERBOSE >= 2
-	    std::cout << "(" << rank << ")"
+	    std::cout << "(" << rank << ") "
 		      << "copy src: " << src_sb << "/" << sp
 		      << " " << send_dom
 		      << "  dst: " << dst_sb << "/" << dp
 		      << " " << recv_dom
-		      << std::endl;
+		      << std::endl
+		      << "    "
+		      << "src_dom: " << src_dom
+		      << "  src_ldom: " << src_ldom
+		      << std::endl
+		      << "    "
+		      << "dst_dom: " << dst_dom
+		      << "  dst_ldom: " << dst_ldom
+		      << std::endl
+		      << "  intr: " << intr
+		      << std::endl
+	      ;
 #endif
 	  }
 	}
@@ -783,6 +798,9 @@
 	      << "src subblock: " << (*cl_cur).src_sb_ << " -> "
 	      << "dst subblock: " << (*cl_cur).dst_sb_ << std::endl
 	      << dst_lview((*cl_cur).dst_dom_);
+
+    // std::cout << "  from: " << (*cl_cur).src_dom_ << std::endl;
+    // std::cout << "  to  : " << (*cl_cur).dst_dom_ << std::endl;
 #endif
   }
 }
Index: src/vsip/opt/diag/extdata.hpp
===================================================================
--- src/vsip/opt/diag/extdata.hpp	(revision 179602)
+++ src/vsip/opt/diag/extdata.hpp	(working copy)
@@ -24,8 +24,10 @@
 #include <iostream>
 #include <iomanip>
 
+#include <vsip/opt/diag/class_name.hpp>
 
 
+
 /***********************************************************************
   Declarations
 ***********************************************************************/
@@ -40,20 +42,6 @@
 namespace diag_detail
 {
 
-// Helper class to return the name corresponding to a dispatch tag.
-
-template <typename T> 
-struct Class_name
-{
-  static std::string name() { return "unknown"; }
-};
-
-#define VSIP_IMPL_CLASS_NAME(TYPE)				\
-  template <>							\
-  struct Class_name<TYPE> {					\
-    static std::string name() { return "" # TYPE; }		\
-  };
-
 VSIP_IMPL_CLASS_NAME(Direct_access_tag)
 VSIP_IMPL_CLASS_NAME(Reorder_access_tag)
 VSIP_IMPL_CLASS_NAME(Copy_access_tag)
Index: src/vsip/opt/diag/view.hpp
===================================================================
--- src/vsip/opt/diag/view.hpp	(revision 0)
+++ src/vsip/opt/diag/view.hpp	(revision 0)
@@ -0,0 +1,254 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/diag/view.hpp
+    @author  Jules Bergmann
+    @date    2007-08-22
+    @brief   VSIPL++ Library: Diagnostics for views.
+*/
+
+#ifndef VSIP_OPT_DIAG_VIEW_HPP
+#define VSIP_OPT_DIAG_VIEW_HPP
+
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <iostream>
+#include <iomanip>
+#include <sstream>
+
+#include <vsip/opt/diag/class_name.hpp>
+
+
+
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
+namespace vsip
+{
+namespace impl
+{
+
+namespace diag_detail
+{
+
+template <dimension_type dim0,
+	  dimension_type dim1,
+	  dimension_type dim2>
+struct Class_name<tuple<dim0, dim1, dim2> >
+{
+  static std::string name()
+  {
+    std::ostringstream n;
+    n << "tuple<" << dim0 << ", " << dim1 << ", " << dim2 << ">";
+    return n.str();
+  }
+};
+
+VSIP_IMPL_CLASS_NAME(Block_dist);
+VSIP_IMPL_CLASS_NAME(Whole_dist);
+
+template <dimension_type Dim,
+	  typename       T,
+	  typename       OrderT,
+	  typename       MapT>
+struct Class_name<Dense<Dim, T, OrderT, MapT> >
+{
+  static std::string name()
+  {
+    std::ostringstream n;
+    n << "Dense<" << Dim << ", "
+      << Class_name<T>::name() << ", "
+      << Class_name<OrderT>::name() << ", "
+      << Class_name<MapT>::name() << ">";
+    return n.str();
+  }
+};
+
+template <typename BlockT>
+struct Class_name<Subset_block<BlockT> >
+{
+  static std::string name()
+  {
+    std::ostringstream n;
+    n << "Subset_block<"
+      << Class_name<BlockT>::name() << ">";
+    return n.str();
+  }
+};
+
+
+
+template <typename Dist0,
+	  typename Dist1,
+	  typename Dist2>
+struct Class_name<Map<Dist0, Dist1, Dist2> >
+{
+  static std::string name()
+  {
+    std::ostringstream n;
+    n << "Map<"
+      << Class_name<Dist0>::name() << ", "
+      << Class_name<Dist1>::name() << ", "
+      << Class_name<Dist2>::name() << ">";
+    return n.str();
+  }
+};
+
+template <dimension_type Dim>
+struct Class_name<Subset_map<Dim> >
+{
+  static std::string name()
+  {
+    std::ostringstream n;
+    n << "Subset_map<" << Dim << ">";
+    return n.str();
+  }
+};
+
+
+
+/// Write a vector to a stream.
+
+template <typename T,
+	  typename Block>
+inline
+std::ostream&
+output_view(
+  std::ostream&		       out,
+  vsip::const_Vector<T, Block> vec)
+{
+  for (vsip::index_type i=0; i<vec.size(); ++i)
+    out << "        index " << i << "    : " << vec.get(i) << "\n";
+  return out;
+}
+
+
+
+/// Write a matrix to a stream.
+
+template <typename T,
+	  typename Block>
+inline
+std::ostream&
+output_view(
+  std::ostream&		       out,
+  vsip::const_Matrix<T, Block> v)
+{
+  for (vsip::index_type r=0; r<v.size(0); ++r)
+  {
+    out << "        row " << r << "     :";
+    for (vsip::index_type c=0; c<v.size(1); ++c)
+      out << "  " << v.get(r, c);
+    out << std::endl;
+  }
+  return out;
+}
+
+} // namespace diag_detail
+
+template <typename ViewT>
+void
+diagnose_view(char const* str, ViewT view, bool display = false)
+{
+  using std::cout;
+  using std::endl;
+  using std::flush;
+  using vsip::impl::diag_detail::Class_name;
+
+  dimension_type const view_dim  = ViewT::dim;
+
+  typedef typename ViewT::block_type    block_type;
+  typedef typename block_type::map_type map_type;
+
+  dimension_type const block_dim = Block_layout<block_type>::dim;
+
+  map_type const& map = view.block().map();
+
+  impl::Communicator& comm = impl::default_communicator();
+
+  comm.barrier();
+  if (comm.rank() == 0)
+  {
+    cout << "diagnose_view(" << str << "):" << std::endl;
+
+    cout << "  General\n";
+    cout << "    view dim       : " << view_dim << "  (" << view.size(0);
+    for (dimension_type i=1; i<view_dim; ++i)
+      cout << ", " << view.size(i) ;
+    cout << ")\n";
+    
+    cout << "    block dim      : " << block_dim << "  ("
+	 << view.block().size(block_dim, 0);
+    for (dimension_type i=1; i<view_dim; ++i)
+      cout << ", " << view.block().size(block_dim, i) ;
+    cout << ")\n";
+    
+    cout << "    block_type     : " << Class_name<block_type>::name() << endl
+	 << "    map_type       : " << Class_name<map_type>::name() << endl
+      // << "    map typeid     : " << typeid(map_type).name() << endl
+      ;
+    
+    cout << "  Map info         : " << endl
+	 << "    subblocks      : " << map.num_subblocks() << endl
+	 << "    processors     : " << map.num_processors() << endl
+      ;
+    cout << flush;
+  }
+  comm.barrier();
+  for (index_type proc=0; proc<num_processors(); ++proc)
+  {
+    comm.barrier();
+    if (local_processor() == proc)
+    {
+      index_type sb = map.subblock(proc);
+      cout << "    * processor    : " << proc << endl;
+      if (sb != no_subblock)
+      {
+	cout << "      subblock     : " << sb << endl;
+	cout << "      subblock_dom : "
+	     << map.template impl_subblock_domain<block_dim>(sb) << endl;
+
+	typename ViewT::local_type l_view = view.local(); 
+	cout << "      local view   : " << view_dim << "  (" << l_view.size(0);
+	for (dimension_type i=1; i<view_dim; ++i)
+	  cout << ", " << l_view.size(i) ;
+	cout << ")\n";
+
+
+	cout << "      patches      : " << map.impl_num_patches(sb) << endl;
+	for (index_type p=0; p<map.impl_num_patches(sb); ++p)
+	{
+	  cout << "      - patch      : " << p << endl;
+	  cout << "        global_dom : "
+	       << map.template impl_global_domain<block_dim>(sb, p) << endl;
+	  cout << "        local_dom  : "
+	       << map.template impl_local_domain<block_dim>(sb, p) << endl;
+	}
+	if (display)
+	{
+	  diag_detail::output_view(cout, l_view);
+	}
+      }
+      else
+	cout << "      subblock     : no subblock\n";
+      cout << flush;
+    }
+  }
+  comm.barrier();
+
+}
+
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_OPT_DIAG_VIEW_HPP
Index: src/vsip/opt/diag/class_name.hpp
===================================================================
--- src/vsip/opt/diag/class_name.hpp	(revision 0)
+++ src/vsip/opt/diag/class_name.hpp	(revision 0)
@@ -0,0 +1,60 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/diag/class_name.hpp
+    @author  Jules Bergmann
+    @date    2007-03-06
+    @brief   VSIPL++ Library: Class name utility for diags.
+*/
+
+#ifndef VSIP_OPT_DIAG_CLASS_NAME_HPP
+#define VSIP_OPT_DIAG_CLASS_NAME_HPP
+
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <string>
+
+
+
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
+namespace vsip
+{
+namespace impl
+{
+namespace diag_detail
+{
+
+// Helper class to return the name corresponding to a dispatch tag.
+
+template <typename T> 
+struct Class_name
+{
+  static std::string name() { return "unknown"; }
+};
+
+#define VSIP_IMPL_CLASS_NAME(TYPE)				\
+  template <>							\
+  struct Class_name<TYPE> {					\
+    static std::string name() { return "" # TYPE; }		\
+  }
+
+VSIP_IMPL_CLASS_NAME(float);
+
+
+} // namespace vsip::impl::diag_detail
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_OPT_DIAG_EXTDATA_HPP
Index: src/vsip/opt/diag/eval.hpp
===================================================================
--- src/vsip/opt/diag/eval.hpp	(revision 179530)
+++ src/vsip/opt/diag/eval.hpp	(working copy)
@@ -420,7 +420,11 @@
   static void info(
     DstBlock&       /*dst*/,
     SrcBlock const& /*src*/)
-  {}
+  {
+    std::cout << "Diag_eval_dispatch_helper: DaTag not handled" << std::endl
+	      << "  DaTag: " << Dispatch_name<DaTag>::name() << std::endl
+      ;
+  }
 };
 
 
@@ -473,7 +477,6 @@
       stor1_t l_blk1 = get_local_block(blk1);
       stor2_t l_blk2 = get_local_block(blk2);
 
-      Dispatch_assign<Dim, block1_t, block2_t>::exec(l_blk1, l_blk2);
       std::cout << "LHS and RHS have same map -- local assignment\n";
 
       // Equivalent to:
@@ -493,6 +496,63 @@
   }
 };
 
+
+
+template <dimension_type Dim,
+	  typename       Block1,
+	  typename       Block2>
+struct Diag_eval_dispatch_helper<Dim, Block1, Block2, Tag_par_expr>
+{
+  typedef Dispatch_assign<Dim, Block1, Block2, Tag_par_expr> da_type;
+
+  typedef typename da_type::map1_type map1_type;
+  typedef typename da_type::dst_type  dst_type;
+  typedef typename da_type::src_type  src_type;
+
+  static void info(
+    Block1&       blk1,
+    Block2 const& blk2)
+  {
+    if (Is_par_same_map<Dim, map1_type, Block2>::value(blk1.map(), blk2))
+    {
+      // Maps are same, no communication required.
+      typedef typename Distributed_local_block<Block1>::type block1_t;
+      typedef typename Distributed_local_block<Block2>::type block2_t;
+      typedef typename View_block_storage<block1_t>::type::equiv_type stor1_t;
+      typedef typename View_block_storage<block2_t>::type::equiv_type stor2_t;
+
+      std::cout << "  parallel dim : " << Dim << "  (" << blk1.size(Dim, 0);
+      for (dimension_type i=1; i<Dim; ++i)
+	std::cout << ", " << blk1.size(Dim, i) ;
+      std::cout << ")\n";
+
+      stor1_t l_blk1 = get_local_block(blk1);
+      stor2_t l_blk2 = get_local_block(blk2);
+
+      std::cout << "  local dim    : " << Dim << "  (" << l_blk1.size(Dim, 0);
+      for (dimension_type i=1; i<Dim; ++i)
+	std::cout << ", " << l_blk1.size(Dim, i) ;
+      std::cout << ")\n";
+
+      std::cout << "LHS and RHS have same map -- local assignment\n";
+
+      // Equivalent to:
+      //   diagnose_eval_list_std(dst, src);
+      std::cout << "diagnose_eval_list" << std::endl
+		<< "  dst expr: " << typeid(stor1_t).name() << std::endl
+		<< "  src expr: " << typeid(stor2_t).name() << std::endl;
+      Diag_eval_list_helper<Dim, block1_t, block2_t,
+	                    vsip::impl::LibraryTagList>
+	::exec(l_blk1, l_blk2);
+    }
+    else
+    {
+      std::cout << "LHS and RHS have different maps\n";
+      std::cout << "(diagnostics not implemented yet)\n";
+    }
+  }
+};
+
 } // namespace vsip::impl::diag_detail
 
 
@@ -663,22 +723,28 @@
 {
   using std::cout;
   using std::endl;
-
+  using std::flush;
   using vsip::impl::diag_detail::Dispatch_name;
 
-  typedef typename DstViewT::block_type dst_block_type;
-  typedef typename SrcViewT::block_type src_block_type;
-  dimension_type const dim = SrcViewT::dim;
+  dimension_type const dim = DstViewT::dim;
 
+  typedef typename diag_detail::Block_of<dim, DstViewT>::type dst_block_type;
+  typedef typename diag_detail::Block_of<dim, SrcViewT>::type src_block_type;
+
   typedef Dispatch_assign_helper<dim, dst_block_type, src_block_type, false>
     dah;
 
   typedef typename dah::type dispatch_type;
 
   cout << "--------------------------------------------------------\n";
-  cout << "diagnose_eval_dispatch:" << std::endl
-       << "  dim: " << dim << std::endl
-       << "  DstBlockT    : " << typeid(dst_block_type).name() << endl
+  cout << "diagnose_eval_dispatch:" << std::endl;
+
+  cout << "  dim          : " << dim << "  (" << dst.size(0);
+  for (dimension_type i=1; i<dim; ++i)
+    cout << ", " << dst.size(i) ;
+  cout << ")\n";
+
+  cout << "  DstBlockT    : " << typeid(dst_block_type).name() << endl
        << "  SrcBlockT    : " << typeid(src_block_type).name() << endl
        << "  is_illegal   : " << (dah::is_illegal ? "true" : "false") << endl
        << "  is_rhs_expr  : " << (dah::is_rhs_expr ? "true" : "false") << endl
@@ -693,9 +759,12 @@
   cout << "--------------------------------------------------------\n";
 
   diag_detail::Diag_eval_dispatch_helper<dim, dst_block_type, src_block_type,
-    dispatch_type>::info(dst.block(), src.block());
+    dispatch_type>
+    ::info(diag_detail::Block_of<dim, DstViewT>::block(dst),
+	   diag_detail::Block_of<dim, SrcViewT>::block(src));
 
   cout << "--------------------------------------------------------\n";
+  cout << flush;
 }
 
 
Index: src/vsip_csl/output.hpp
===================================================================
--- src/vsip_csl/output.hpp	(revision 176624)
+++ src/vsip_csl/output.hpp	(working copy)
@@ -18,12 +18,15 @@
 ***********************************************************************/
 
 #include <iostream>
+
 #include <vsip/domain.hpp>
 #include <vsip/vector.hpp>
 #include <vsip/matrix.hpp>
 
+#include <vsip_csl/output/domain.hpp>
 
 
+
 namespace vsip_csl
 {
 
@@ -31,54 +34,6 @@
   Definitions
 ***********************************************************************/
 
-/// Write a Domain<1> object to an output stream.
-
-inline
-std::ostream&
-operator<<(
-  std::ostream&		 out,
-  vsip::Domain<1> const& dom)
-  VSIP_NOTHROW
-{
-  out << "("
-      << dom.first() << ","
-      << dom.stride() << ","
-      << dom.length() << ")";
-  return out;
-}
-
-
-
-/// Write a Domain<2> object to an output stream.
-
-inline
-std::ostream&
-operator<<(
-  std::ostream&		 out,
-  vsip::Domain<2> const& dom)
-  VSIP_NOTHROW
-{
-  out << "(" << dom[0] << ", " << dom[1] << ")";
-  return out;
-}
-
-
-
-/// Write a Domain<3> object to an output stream.
-
-inline
-std::ostream&
-operator<<(
-  std::ostream&		 out,
-  vsip::Domain<3> const& dom)
-  VSIP_NOTHROW
-{
-  out << "(" << dom[0] << ", " << dom[1] << ", " << dom[2] << ")";
-  return out;
-}
-
-
-
 /// Write a vector to a stream.
 
 template <typename T,
@@ -118,48 +73,6 @@
   return out;
 }
 
-
-/// Write an Index to a stream.
-
-template <vsip::dimension_type Dim>
-inline
-std::ostream&
-operator<<(
-  std::ostream&		        out,
-  vsip::Index<Dim> const& idx)
-  VSIP_NOTHROW
-{
-  out << "(";
-  for (vsip::dimension_type d=0; d<Dim; ++d)
-  {
-    if (d > 0) out << ", ";
-    out << idx[d];
-  }
-  out << ")";
-  return out;
-}
-
-
-/// Write a Length to a stream.
-
-template <vsip::dimension_type Dim>
-inline
-std::ostream&
-operator<<(
-  std::ostream&		         out,
-  vsip::impl::Length<Dim> const& idx)
-  VSIP_NOTHROW
-{
-  out << "(";
-  for (vsip::dimension_type d=0; d<Dim; ++d)
-  {
-    if (d > 0) out << ", ";
-    out << idx[d];
-  }
-  out << ")";
-  return out;
-}
-
 } // namespace vsip
 
 #endif // VSIP_CSL_OUTPUT_HPP
Index: src/vsip_csl/output/domain.hpp
===================================================================
--- src/vsip_csl/output/domain.hpp	(revision 0)
+++ src/vsip_csl/output/domain.hpp	(revision 0)
@@ -0,0 +1,129 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip_csl/output/domain.hpp
+    @author  Jules Bergmann
+    @date    2007-08-22
+    @brief   VSIPL++ CodeSourcery Library: Output utilities for domains.
+*/
+
+#ifndef VSIP_CSL_OUTPUT_DOMAIN_HPP
+#define VSIP_CSL_OUTPUT_DOMAIN_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <iostream>
+
+#include <vsip/domain.hpp>
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
+/// Write a Domain<1> object to an output stream.
+
+inline
+std::ostream&
+operator<<(
+  std::ostream&		 out,
+  vsip::Domain<1> const& dom)
+  VSIP_NOTHROW
+{
+  out << "("
+      << dom.first() << ","
+      << dom.stride() << ","
+      << dom.length() << ")";
+  return out;
+}
+
+
+
+/// Write a Domain<2> object to an output stream.
+
+inline
+std::ostream&
+operator<<(
+  std::ostream&		 out,
+  vsip::Domain<2> const& dom)
+  VSIP_NOTHROW
+{
+  out << "(" << dom[0] << ", " << dom[1] << ")";
+  return out;
+}
+
+
+
+/// Write a Domain<3> object to an output stream.
+
+inline
+std::ostream&
+operator<<(
+  std::ostream&		 out,
+  vsip::Domain<3> const& dom)
+  VSIP_NOTHROW
+{
+  out << "(" << dom[0] << ", " << dom[1] << ", " << dom[2] << ")";
+  return out;
+}
+
+
+
+/// Write an Index to a stream.
+
+template <vsip::dimension_type Dim>
+inline
+std::ostream&
+operator<<(
+  std::ostream&		        out,
+  vsip::Index<Dim> const& idx)
+  VSIP_NOTHROW
+{
+  out << "(";
+  for (vsip::dimension_type d=0; d<Dim; ++d)
+  {
+    if (d > 0) out << ", ";
+    out << idx[d];
+  }
+  out << ")";
+  return out;
+}
+
+
+
+namespace impl
+{
+
+/// Write a Length to a stream.
+
+template <vsip::dimension_type Dim>
+inline
+std::ostream&
+operator<<(
+  std::ostream&		         out,
+  vsip::impl::Length<Dim> const& idx)
+  VSIP_NOTHROW
+{
+  out << "(";
+  for (vsip::dimension_type d=0; d<Dim; ++d)
+  {
+    if (d > 0) out << ", ";
+    out << idx[d];
+  }
+  out << ")";
+  return out;
+}
+
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_CSL_OUTPUT_HPP
Index: tests/parallel/subviews.cpp
===================================================================
--- tests/parallel/subviews.cpp	(revision 173072)
+++ tests/parallel/subviews.cpp	(working copy)
@@ -636,7 +636,7 @@
   bool do_tmat = false;
   bool do_tvec = false;
   bool do_all  = false;
-  bool verbose = true;
+  bool verbose = false;
 
   int cnt = 0;
 
