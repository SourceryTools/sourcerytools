Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.301
diff -c -p -r1.301 ChangeLog
*** ChangeLog	31 Oct 2005 15:57:46 -0000	1.301
--- ChangeLog	2 Nov 2005 13:01:46 -0000
***************
*** 1,3 ****
--- 1,42 ----
+ 2005-11-02 Jules Bergmann  <jules@codesourcery.com>
+ 
+ 	* src/vsip/impl/block-copy.hpp: Extend Block_fill to handle
+ 	  distributed blocks and 1-dim blocks.
+ 	* src/vsip/impl/block-traits.hpp: Add Is_par_reorg_ok trait.
+ 	* src/vsip/impl/dispatch-assign.hpp: Use Is_par_reorg_ok to determine
+ 	  if parallel expression can be reorganized.
+ 	* src/vsip/impl/dist.hpp: Add missing body for Whole_dist constructor.
+ 	* src/vsip/impl/distributed-block.hpp: Implement release and find
+ 	  for Distributed_block.
+ 	* src/vsip/impl/expr_binary_block.hpp: Specialize Is_par_reorg_ok
+ 	  for binary expressions.
+ 	* src/vsip/impl/expr_ternary_block.hpp: Define parallel traits
+ 	  and functions (Distributed_local_block, get_local_block,
+ 	  Combine_return_type, apply_combine, apply_leaf, Is_par_same_map,
+ 	  and Is_par_reorg_ok).
+ 	* src/vsip/impl/expr_unary_block.hpp: Likewise.
+ 	* src/vsip/impl/global_map.hpp: Specialize Is_global_only and
+ 	  Map_equal for Global_maps.
+ 	* src/vsip/impl/local_map.hpp: Specialize Is_local_only and
+ 	  Is_global_only for Local_maps.
+ 	* src/vsip/impl/map-traits.hpp: New file, traits for maps.
+ 	* src/vsip/impl/subblock.hpp (Diag_block): Use size() to compute
+ 	  size(1, 0).
+ 	* src/vsip/impl/vmmul.hpp: Use expression template block to evaluate
+ 	  vmmul.
+ 	* src/vsip/map.hpp: Add map_equiv, like op== but only requires
+ 	  processors match upto number of subblocks.  Use for Map_equal.
+ 	* src/vsip/vector.hpp: Use Block_fill for scalar assignment.
+ 	* tests/distributed-subviews.cpp (dump_map): Move from ...
+ 	* tests/util-par.hpp: ... to here.
+ 	* tests/util-par.hpp: Update dump_view to single subblock per
+ 	  processor.  Fix Check_identity to work with negative k.
+ 	* tests/extdata-output.hpp: Recognize Global_map, Local_map, and
+ 	  Local_or_global_map.
+ 	* tests/par_expr.cpp: Extend coverage to parallel expressions with
+ 	  unary and ternary operators.
+ 	* tests/vmmul.cpp: Add coverage for parallel vmmul cases.
+ 
  2005-10-31  Stefan Seefeld  <stefan@codesourcery.com>
  
  	* synopsis.py.in: New synopsis driver script.
Index: configure.ac
===================================================================
RCS file: /home/cvs/Repository/vpp/configure.ac,v
retrieving revision 1.46
diff -c -p -r1.46 configure.ac
*** configure.ac	31 Oct 2005 15:57:46 -0000	1.46
--- configure.ac	2 Nov 2005 13:01:47 -0000
*************** AC_ARG_WITH(atlas_prefix,
*** 100,106 ****
  
  AC_ARG_WITH(atlas_libdir,
    AS_HELP_STRING([--with-atlas-libdir=PATH],
!                  [specify the directory containing ATLAS librariews.
  	          (Enables LAPACK).]),
    [enable_lapack=atlas])
  
--- 100,106 ----
  
  AC_ARG_WITH(atlas_libdir,
    AS_HELP_STRING([--with-atlas-libdir=PATH],
!                  [specify the directory containing ATLAS libraries.
  	          (Enables LAPACK).]),
    [enable_lapack=atlas])
  
Index: src/vsip/map.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/map.hpp,v
retrieving revision 1.16
diff -c -p -r1.16 map.hpp
*** src/vsip/map.hpp	16 Sep 2005 21:51:08 -0000	1.16
--- src/vsip/map.hpp	2 Nov 2005 13:01:47 -0000
*************** bool
*** 87,92 ****
--- 87,100 ----
  operator==(Map<Dim0, Dim1, Dim2> const& map1,
  	   Map<Dim0, Dim1, Dim2> const& map2);
  
+ // Forward declaration.
+ template <typename Dim0,
+ 	  typename Dim1,
+ 	  typename Dim2>
+ bool
+ map_equiv(Map<Dim0, Dim1, Dim2> const& map1,
+ 	  Map<Dim0, Dim1, Dim2> const& map2);
+ 
  
  
  // Map class.
*************** public:
*** 163,168 ****
--- 171,177 ----
    impl::Communicator impl_comm() const { return comm_; }
    processor_type     impl_rank() const { return comm_.rank(); }
    length_type        impl_size() const { return comm_.size(); }
+   bool               impl_is_applied() const { return dim_ != 0; }
  
    length_type        impl_working_size() const
      { return std::min(this->num_subblocks(), this->pvec_.size()); }
*************** public:
*** 199,204 ****
--- 208,214 ----
    typedef Dist2 impl_dim2_type;
  
    friend bool operator==<>(Map const&, Map const&);
+   friend bool map_equiv<>(Map const&, Map const&);
  
  public:
    index_type     lookup_index(processor_type pr) const;
*************** operator==(Map<Dim0, Dim1, Dim2> const& 
*** 1024,1029 ****
--- 1034,1072 ----
  
  
  
+ template <typename Dim0,
+ 	  typename Dim1,
+ 	  typename Dim2>
+ bool
+ map_equiv(Map<Dim0, Dim1, Dim2> const& map1,
+ 	  Map<Dim0, Dim1, Dim2> const& map2) VSIP_NOTHROW
+ {
+   for (dimension_type d=0; d<VSIP_MAX_DIMENSION; ++d)
+   {
+     if (map1.distribution(d)      != map2.distribution(d) ||
+ 	map1.num_subblocks(d)     != map2.num_subblocks(d) ||
+ 	map1.cyclic_contiguity(d) != map2.cyclic_contiguity(d))
+       return false;
+   }
+ 
+   // implied by loop
+   assert(map1.num_subblocks() == map1.num_subblocks());
+ 
+   if (map1.comm_ != map2.comm_)
+     return false;
+ 
+   assert(map1.pvec_.size() >= map1.num_subblocks());
+   assert(map2.pvec_.size() >= map2.num_subblocks());
+ 
+   for (index_type i=0; i<map1.num_subblocks(); ++i)
+     if (map1.pvec_[i] != map2.pvec_[i])
+       return false;
+ 
+   return true;
+ }
+ 
+ 
+ 
  template <typename DimA0,
  	  typename DimA1,
  	  typename DimA2,
*************** struct Map_equal<Map<Dim0, Dim1, Dim2>, 
*** 1049,1055 ****
  {
    static bool value(Map<Dim0, Dim1, Dim2> const& map1,
  		    Map<Dim0, Dim1, Dim2> const& map2)
!     { return map1 == map2; }
  };
  
  
--- 1092,1098 ----
  {
    static bool value(Map<Dim0, Dim1, Dim2> const& map1,
  		    Map<Dim0, Dim1, Dim2> const& map2)
!     { return map_equiv(map1, map2); }
  };
  
  
Index: src/vsip/vector.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/vector.hpp,v
retrieving revision 1.33
diff -c -p -r1.33 vector.hpp
*** src/vsip/vector.hpp	7 Oct 2005 13:46:46 -0000	1.33
--- src/vsip/vector.hpp	2 Nov 2005 13:01:47 -0000
*************** public:
*** 223,237 ****
  
    Vector& operator=(const_reference_type val) VSIP_NOTHROW
    {
!     for (index_type i = 0; i < this->size(); i++)
!       this->put(i, val);
      return *this;
    }
    template <typename T0>
    Vector& operator=(T0 const& val) VSIP_NOTHROW
    {
!     for (index_type i = 0; i < this->size(); i++)
!       this->put(i, val);
      return *this;
    }
    template <typename T0, typename Block0>
--- 223,235 ----
  
    Vector& operator=(const_reference_type val) VSIP_NOTHROW
    {
!     vsip::impl::Block_fill<1, Block>::exec(this->block(), val);
      return *this;
    }
    template <typename T0>
    Vector& operator=(T0 const& val) VSIP_NOTHROW
    {
!     vsip::impl::Block_fill<1, Block>::exec(this->block(), val);
      return *this;
    }
    template <typename T0, typename Block0>
Index: src/vsip/impl/block-copy.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/block-copy.hpp,v
retrieving revision 1.8
diff -c -p -r1.8 block-copy.hpp
*** src/vsip/impl/block-copy.hpp	16 Sep 2005 22:03:20 -0000	1.8
--- src/vsip/impl/block-copy.hpp	2 Nov 2005 13:01:47 -0000
***************
*** 15,20 ****
--- 15,21 ----
  
  #include "vsip/impl/layout.hpp"
  #include "vsip/impl/block-traits.hpp"
+ #include "vsip/impl/map-traits.hpp"
  
  
  
*************** struct Block_copy
*** 71,82 ****
  
  
  template <dimension_type Dim,
! 	  typename       Block,
! 	  typename       Order = typename Block_layout<Block>::order_type>
  struct Block_fill;
  
  template <typename Block>
! struct Block_fill<2, Block, row2_type>
  {
    template <typename T>
    static void exec(Block& block, T const& val)
--- 72,110 ----
  
  
  template <dimension_type Dim,
! 	  typename       BlockT,
! 	  typename       OrderT  = typename Block_layout<BlockT>::order_type,
! 	  bool           IsGlobal = 
! 			    Is_global_only<typename BlockT::map_type>::value>
  struct Block_fill;
  
+ template <dimension_type Dim,
+ 	  typename       BlockT,
+ 	  typename       OrderT>
+ struct Block_fill<Dim, BlockT, OrderT, true>
+ {
+   template <typename T>
+   static void exec(BlockT& block, T const& val)
+   {
+     typedef typename Distributed_local_block<BlockT>::type local_block_type;
+     Block_fill<Dim, local_block_type>::exec(get_local_block(block), val);
+   }
+ };
+ 
+ template <typename BlockT,
+ 	  typename OrderT>
+ struct Block_fill<1, BlockT, OrderT, false>
+ {
+   template <typename T>
+   static void exec(BlockT& block, T const& val)
+   {
+     for (index_type i=0; i<block.size(1, 0); ++i)
+       block.put(i, val);
+   }
+ };
+ 
  template <typename Block>
! struct Block_fill<2, Block, row2_type, false>
  {
    template <typename T>
    static void exec(Block& block, T const& val)
*************** struct Block_fill<2, Block, row2_type>
*** 88,94 ****
  };
  
  template <typename Block>
! struct Block_fill<2, Block, col2_type>
  {
    template <typename T>
    static void exec(Block& block, T const& val)
--- 116,122 ----
  };
  
  template <typename Block>
! struct Block_fill<2, Block, col2_type, false>
  {
    template <typename T>
    static void exec(Block& block, T const& val)
Index: src/vsip/impl/block-traits.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/block-traits.hpp,v
retrieving revision 1.14
diff -c -p -r1.14 block-traits.hpp
*** src/vsip/impl/block-traits.hpp	28 Sep 2005 19:07:27 -0000	1.14
--- src/vsip/impl/block-traits.hpp	2 Nov 2005 13:01:47 -0000
*************** map_equal(Map1 const& map1, Map2 const& 
*** 225,230 ****
--- 225,235 ----
  
  
  
+ template <typename BlockT>
+ struct Is_par_reorg_ok
+ {
+   static bool const value = true;
+ };
  
  
  
Index: src/vsip/impl/dispatch-assign.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/dispatch-assign.hpp,v
retrieving revision 1.11
diff -c -p -r1.11 dispatch-assign.hpp
*** src/vsip/impl/dispatch-assign.hpp	15 Sep 2005 16:09:15 -0000	1.11
--- src/vsip/impl/dispatch-assign.hpp	2 Nov 2005 13:01:47 -0000
*************** struct Tag_illegal_mix_of_local_and_glob
*** 58,63 ****
--- 58,64 ----
  struct Tag_serial_assign;
  struct Tag_serial_expr;
  struct Tag_par_assign;
+ struct Tag_par_expr_noreorg;
  struct Tag_par_expr;
  
  
*************** struct Dispatch_assign_helper
*** 88,93 ****
--- 89,95 ----
                                      Is_local_map<map2_type>::value;
    static bool const is_rhs_expr   = Is_expr_block<Block2>::value;
    static bool const is_rhs_simple = Is_simple_distributed_block<Block2>::value;
+   static bool const is_rhs_reorg  = Is_par_reorg_ok<Block2>::value;
  
    static bool const is_lhs_split  =
      Type_equal<typename Block_layout<Block1>::complex_type,
*************** struct Dispatch_assign_helper
*** 107,113 ****
                                        As_type<Tag_serial_assign>,
    ITE_Type<is_local,                  As_type<Tag_serial_expr>,
    ITE_Type<is_rhs_simple,             As_type<Tag_par_assign>,
! 	                              As_type<Tag_par_expr> > > > >::type type;
  };
  
  template <dimension_type Dim,
--- 109,117 ----
                                        As_type<Tag_serial_assign>,
    ITE_Type<is_local,                  As_type<Tag_serial_expr>,
    ITE_Type<is_rhs_simple,             As_type<Tag_par_assign>,
!   ITE_Type<is_rhs_reorg,              As_type<Tag_par_expr>,
! 	                              As_type<Tag_par_expr_noreorg> > > > > >
! 		::type type;
  };
  
  template <dimension_type Dim,
*************** struct Dispatch_assign<Dim, Block1, Bloc
*** 358,363 ****
--- 362,399 ----
  
  
  
+ // Specialization for distributed expressions.
+ 
+ template <dimension_type Dim,
+ 	  typename       Block1,
+ 	  typename       Block2>
+ struct Dispatch_assign<Dim, Block1, Block2, Tag_par_expr_noreorg>
+ {
+   typedef typename Block1::map_type map1_type;
+ 
+   typedef typename View_of_dim<Dim, typename Block1::value_type,
+ 			     Block1>::type dst_type;
+   typedef typename View_of_dim<Dim, typename Block2::value_type,
+ 			     Block2>::const_type src_type;
+ 
+   static void exec(Block1& blk1, Block2 const& blk2)
+   {
+     if (Is_par_same_map<map1_type, Block2>::value(blk1.map(), blk2))
+     {
+       // Maps are same, no communication required.
+       dst_type dst(blk1);
+       src_type src(const_cast<Block2&>(blk2));
+       par_expr_simple(dst, src);
+     }
+     else
+     {
+       VSIP_IMPL_THROW(impl::unimplemented("Expression cannot be reorganized"));
+     }
+   }
+ };
+ 
+ 
+ 
  /***********************************************************************
    Definitions
  ***********************************************************************/
Index: src/vsip/impl/dist.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/dist.hpp,v
retrieving revision 1.8
diff -c -p -r1.8 dist.hpp
*** src/vsip/impl/dist.hpp	28 Aug 2005 00:22:39 -0000	1.8
--- src/vsip/impl/dist.hpp	2 Nov 2005 13:01:47 -0000
*************** class Whole_dist
*** 228,234 ****
  {
    // Constructors and destructor.
  public:
!   Whole_dist() VSIP_NOTHROW;
    ~Whole_dist() VSIP_NOTHROW {}
    
    // Default copy constructor and assignment are fine.
--- 228,234 ----
  {
    // Constructors and destructor.
  public:
!   Whole_dist() VSIP_NOTHROW {}
    ~Whole_dist() VSIP_NOTHROW {}
    
    // Default copy constructor and assignment are fine.
Index: src/vsip/impl/distributed-block.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/distributed-block.hpp,v
retrieving revision 1.14
diff -c -p -r1.14 distributed-block.hpp
*** src/vsip/impl/distributed-block.hpp	16 Sep 2005 21:51:08 -0000	1.14
--- src/vsip/impl/distributed-block.hpp	2 Nov 2005 13:01:47 -0000
*************** public:
*** 170,183 ****
      { subblock_->release(update); }
  
    void release(bool update, value_type*& pointer) VSIP_NOTHROW
!     { VSIP_IMPL_THROW(impl::unimplemented("Distributed_block::release()")); }
    void release(bool update, uT*& pointer) VSIP_NOTHROW
      { VSIP_IMPL_THROW(impl::unimplemented("Distributed_block::release()")); }
    void release(bool update, uT*& real_pointer, uT*& imag_pointer) VSIP_NOTHROW
      { VSIP_IMPL_THROW(impl::unimplemented("Distributed_block::release()")); }
  
    void find(value_type*& pointer) VSIP_NOTHROW
!     { VSIP_IMPL_THROW(impl::unimplemented("Distributed_block::find()")); }
    void find(uT*& pointer) VSIP_NOTHROW
      { VSIP_IMPL_THROW(impl::unimplemented("Distributed_block::find()")); }
    void find(uT*& real_pointer, uT*& imag_pointer) VSIP_NOTHROW
--- 170,183 ----
      { subblock_->release(update); }
  
    void release(bool update, value_type*& pointer) VSIP_NOTHROW
!     { subblock_->release(update, pointer); }
    void release(bool update, uT*& pointer) VSIP_NOTHROW
      { VSIP_IMPL_THROW(impl::unimplemented("Distributed_block::release()")); }
    void release(bool update, uT*& real_pointer, uT*& imag_pointer) VSIP_NOTHROW
      { VSIP_IMPL_THROW(impl::unimplemented("Distributed_block::release()")); }
  
    void find(value_type*& pointer) VSIP_NOTHROW
!     { subblock_->find(pointer); }
    void find(uT*& pointer) VSIP_NOTHROW
      { VSIP_IMPL_THROW(impl::unimplemented("Distributed_block::find()")); }
    void find(uT*& real_pointer, uT*& imag_pointer) VSIP_NOTHROW
Index: src/vsip/impl/expr_binary_block.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/expr_binary_block.hpp,v
retrieving revision 1.16
diff -c -p -r1.16 expr_binary_block.hpp
*** src/vsip/impl/expr_binary_block.hpp	16 Sep 2005 18:21:45 -0000	1.16
--- src/vsip/impl/expr_binary_block.hpp	2 Nov 2005 13:01:47 -0000
*************** template <typename                      
*** 200,213 ****
  struct Combine_return_type<CombineT,
  			   Binary_expr_block<D, Operator, LBlock, LType,
  					     RBlock, RType> >
! {
!   typedef Binary_expr_block<D, Operator,
! 		typename Combine_return_type<CombineT, LBlock>::tree_type,
! 		LType,
! 		typename Combine_return_type<CombineT, RBlock>::tree_type,
! 		RType> const tree_type;
!   typedef tree_type type;
! };
  
  
  
--- 200,209 ----
  struct Combine_return_type<CombineT,
  			   Binary_expr_block<D, Operator, LBlock, LType,
  					     RBlock, RType> >
! : Combine_return_type<CombineT,
! 		      Binary_expr_block<D, Operator, LBlock, LType,
! 					RBlock, RType> const>
! {};
  
  
  
*************** struct Is_par_same_map<MapT,
*** 279,284 ****
--- 275,296 ----
  
  
  
+ template <dimension_type                      Dim,
+ 	  template <typename, typename> class Operator,
+ 	  typename                            LBlock,
+ 	  typename                            LType,
+ 	  typename                            RBlock,
+ 	  typename                            RType>
+ struct Is_par_reorg_ok<Binary_expr_block<Dim, Operator,
+ 				      LBlock, LType,
+ 				      RBlock, RType> const>
+ {
+   static bool const value = Is_par_reorg_ok<LBlock>::value &&
+                             Is_par_reorg_ok<RBlock>::value;
+ };
+ 
+ 
+ 
  /***********************************************************************
    Definitions
  ***********************************************************************/
Index: src/vsip/impl/expr_ternary_block.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/expr_ternary_block.hpp,v
retrieving revision 1.7
diff -c -p -r1.7 expr_ternary_block.hpp
*** src/vsip/impl/expr_ternary_block.hpp	15 Sep 2005 11:14:57 -0000	1.7
--- src/vsip/impl/expr_ternary_block.hpp	2 Nov 2005 13:01:47 -0000
*************** struct View_block_storage<Ternary_expr_b
*** 135,140 ****
--- 135,333 ----
  
  
  /***********************************************************************
+   Parallel traits and functions
+ ***********************************************************************/
+ 
+ template <dimension_type D,
+ 	  template <typename, typename, typename> class Functor,
+ 	  typename Block1, typename Type1,
+ 	  typename Block2, typename Type2,
+ 	  typename Block3, typename Type3>
+ struct Distributed_local_block<
+   Ternary_expr_block<D, Functor,
+ 		     Block1, Type1,
+ 		     Block2, Type2,
+ 		     Block3, Type3> const>
+ {
+   typedef Ternary_expr_block<D, Functor,
+ 		typename Distributed_local_block<Block1>::type, Type1,
+ 		typename Distributed_local_block<Block2>::type, Type2,
+ 		typename Distributed_local_block<Block3>::type, Type3> const
+ 		type;
+ };
+ 
+ 
+ 
+ template <dimension_type D,
+ 	  template <typename, typename, typename> class Functor,
+ 	  typename Block1, typename Type1,
+ 	  typename Block2, typename Type2,
+ 	  typename Block3, typename Type3>
+ Ternary_expr_block<D, Functor,
+ 		typename Distributed_local_block<Block1>::type, Type1,
+ 		typename Distributed_local_block<Block2>::type, Type2,
+ 		typename Distributed_local_block<Block3>::type, Type3>
+ get_local_block(
+   Ternary_expr_block<D, Functor,
+ 		     Block1, Type1,
+ 		     Block2, Type2,
+ 		     Block3, Type3> const& block)
+ {
+   typedef Ternary_expr_block<D, Functor,
+ 		typename Distributed_local_block<Block1>::type, Type1,
+ 		typename Distributed_local_block<Block2>::type, Type2,
+ 		typename Distributed_local_block<Block3>::type, Type3>
+ 		  block_type;
+ 
+   return block_type(get_local_block(block.first()),
+ 		    get_local_block(block.second()),
+ 		    get_local_block(block.third()));
+ }
+ 
+ 
+ 
+ template <typename                  CombineT,
+ 	  dimension_type D,
+ 	  template <typename, typename, typename> class Functor,
+ 	  typename Block1, typename Type1,
+ 	  typename Block2, typename Type2,
+ 	  typename Block3, typename Type3>
+ struct Combine_return_type<CombineT,
+ 			   Ternary_expr_block<D, Functor,
+ 					      Block1, Type1,
+ 					      Block2, Type2,
+ 					      Block3, Type3> const>
+ {
+   typedef Ternary_expr_block<D, Functor,
+ 	typename Combine_return_type<CombineT, Block1>::tree_type, Type1,
+ 	typename Combine_return_type<CombineT, Block2>::tree_type, Type2,
+ 	typename Combine_return_type<CombineT, Block3>::tree_type, Type3>
+ 	const tree_type;
+   typedef tree_type type;
+ };
+ 
+ 
+ 
+ template <typename                  CombineT,
+ 	  dimension_type D,
+ 	  template <typename, typename, typename> class Functor,
+ 	  typename Block1, typename Type1,
+ 	  typename Block2, typename Type2,
+ 	  typename Block3, typename Type3>
+ struct Combine_return_type<CombineT,
+ 			   Ternary_expr_block<D, Functor,
+ 					      Block1, Type1,
+ 					      Block2, Type2,
+ 					      Block3, Type3> >
+   : Combine_return_type<CombineT,
+ 			Ternary_expr_block<D, Functor,
+ 					      Block1, Type1,
+ 					      Block2, Type2,
+ 					      Block3, Type3> const>
+ {};
+ 
+ 
+ 
+ template <typename                  CombineT,
+ 	  dimension_type D,
+ 	  template <typename, typename, typename> class Functor,
+ 	  typename Block1, typename Type1,
+ 	  typename Block2, typename Type2,
+ 	  typename Block3, typename Type3>
+ typename Combine_return_type<CombineT,
+ 			   Ternary_expr_block<D, Functor,
+ 					      Block1, Type1,
+ 					      Block2, Type2,
+ 					      Block3, Type3> const>::type
+ apply_combine(
+   CombineT const&                               combine,
+   Ternary_expr_block<D, Functor,
+                      Block1, Type1,
+                      Block2, Type2,
+                      Block3, Type3> const& block)
+ {
+   typedef typename Combine_return_type<
+     CombineT,
+     Ternary_expr_block<D, Functor,
+       Block1, Type1,
+       Block2, Type2,
+       Block3, Type3> const>::type
+ 		block_type;
+ 
+   return block_type(apply_combine(combine, block.first()),
+ 		    apply_combine(combine, block.second()),
+ 		    apply_combine(combine, block.third()));
+ }
+ 
+ 
+ 
+ template <typename                  VisitorT,
+ 	  dimension_type D,
+ 	  template <typename, typename, typename> class Functor,
+ 	  typename Block1, typename Type1,
+ 	  typename Block2, typename Type2,
+ 	  typename Block3, typename Type3>
+ void
+ apply_leaf(
+   VisitorT const&                               visitor,
+   Ternary_expr_block<D, Functor,
+                      Block1, Type1,
+                      Block2, Type2,
+                      Block3, Type3> const& block)
+ {
+   apply_leaf(visitor, block.first());
+   apply_leaf(visitor, block.second());
+   apply_leaf(visitor, block.third());
+ }
+ 
+ 
+ 
+ template <typename                  MapT,
+ 	  dimension_type D,
+ 	  template <typename, typename, typename> class Functor,
+ 	  typename Block1, typename Type1,
+ 	  typename Block2, typename Type2,
+ 	  typename Block3, typename Type3>
+ struct Is_par_same_map<MapT,
+ 		       Ternary_expr_block<D, Functor,
+ 					      Block1, Type1,
+ 					      Block2, Type2,
+ 					      Block3, Type3> const>
+ {
+   typedef Ternary_expr_block<D, Functor,
+ 			     Block1, Type1,
+ 			     Block2, Type2,
+ 			     Block3, Type3> const
+ 		block_type;
+ 
+   static bool value(MapT const& map, block_type& block)
+   {
+     return Is_par_same_map<MapT, Block1>::value(map, block.first()) &&
+            Is_par_same_map<MapT, Block2>::value(map, block.second()) &&
+            Is_par_same_map<MapT, Block3>::value(map, block.third());
+   }
+ };
+ 
+ 
+ 
+ template <dimension_type            D,
+ 	  template <typename, typename, typename> class Functor,
+ 	  typename Block1, typename Type1,
+ 	  typename Block2, typename Type2,
+ 	  typename Block3, typename Type3>
+ struct Is_par_reorg_ok<Ternary_expr_block<D, Functor,
+ 					      Block1, Type1,
+ 					      Block2, Type2,
+ 					      Block3, Type3> const>
+ {
+   static bool const value = Is_par_reorg_ok<Block1>::value &&
+                             Is_par_reorg_ok<Block2>::value &&
+                             Is_par_reorg_ok<Block3>::value;
+ };
+ 
+ 
+ 
+ /***********************************************************************
    Definitions
  ***********************************************************************/
  
Index: src/vsip/impl/expr_unary_block.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/expr_unary_block.hpp,v
retrieving revision 1.12
diff -c -p -r1.12 expr_unary_block.hpp
*** src/vsip/impl/expr_unary_block.hpp	16 Sep 2005 18:21:45 -0000	1.12
--- src/vsip/impl/expr_unary_block.hpp	2 Nov 2005 13:01:47 -0000
*************** struct View_block_storage<Unary_expr_blo
*** 109,114 ****
--- 109,248 ----
  
  
  /***********************************************************************
+   Parallel traits and functions
+ ***********************************************************************/
+ 
+ template <dimension_type            Dim,
+ 	  template <typename> class Op,
+ 	  typename                  Block,
+ 	  typename                  Type>
+ struct Distributed_local_block<
+   Unary_expr_block<Dim, Op, Block, Type> const>
+ {
+   typedef Unary_expr_block<Dim, Op,
+ 			   typename Distributed_local_block<Block>::type,
+ 			   Type> const
+ 		type;
+ };
+ 
+ 
+ 
+ template <dimension_type            Dim,
+ 	  template <typename> class Op,
+ 	  typename                  Block,
+ 	  typename                  Type>
+ Unary_expr_block<Dim, Op,
+ 		 typename Distributed_local_block<Block>::type, Type>
+ get_local_block(
+   Unary_expr_block<Dim, Op, Block, Type> const& block)
+ {
+   typedef Unary_expr_block<Dim, Op,
+ 		  typename Distributed_local_block<Block>::type, Type>
+ 		  block_type;
+ 
+   return block_type(get_local_block(block.op()));
+ }
+ 
+ 
+ 
+ template <typename                  CombineT,
+ 	  dimension_type            Dim,
+ 	  template <typename> class Op,
+ 	  typename                  Block,
+ 	  typename                  Type>
+ struct Combine_return_type<CombineT,
+ 			   Unary_expr_block<Dim, Op, Block, Type> const>
+ {
+   typedef Unary_expr_block<Dim, Op,
+ 		typename Combine_return_type<CombineT, Block>::tree_type,
+ 		Type> const tree_type;
+   typedef tree_type type;
+ };
+ 
+ 
+ 
+ template <typename                  CombineT,
+ 	  dimension_type            Dim,
+ 	  template <typename> class Op,
+ 	  typename                  Block,
+ 	  typename                  Type>
+ struct Combine_return_type<CombineT,
+ 			   Unary_expr_block<Dim, Op, Block, Type> >
+   : Combine_return_type<CombineT,
+ 			Unary_expr_block<Dim, Op, Block, Type> const>
+ {};
+ 
+ 
+ 
+ template <typename                  CombineT,
+ 	  dimension_type            Dim,
+ 	  template <typename> class Op,
+ 	  typename                  Block,
+ 	  typename                  Type>
+ typename Combine_return_type<CombineT,
+ 			     Unary_expr_block<Dim, Op,
+ 					      Block, Type> const>::type
+ apply_combine(
+   CombineT const&                               combine,
+   Unary_expr_block<Dim, Op, Block, Type> const& block)
+ {
+   typedef typename Combine_return_type<
+     CombineT,
+     Unary_expr_block<Dim, Op, Block, Type> const>::type
+ 		block_type;
+ 
+   return block_type(apply_combine(combine, block.op()));
+ }
+ 
+ 
+ 
+ template <typename                  VisitorT,
+ 	  dimension_type            Dim,
+ 	  template <typename> class Op,
+ 	  typename                  Block,
+ 	  typename                  Type>
+ void
+ apply_leaf(
+   VisitorT const&                               visitor,
+   Unary_expr_block<Dim, Op, Block, Type> const& block)
+ {
+   apply_leaf(visitor, block.op());
+ }
+ 
+ 
+ 
+ template <typename                  MapT,
+ 	  dimension_type            Dim,
+ 	  template <typename> class Op,
+ 	  typename                  Block,
+ 	  typename                  Type>
+ struct Is_par_same_map<MapT,
+ 		       const Unary_expr_block<Dim, Op,
+ 					      Block, Type> >
+ {
+   typedef const Unary_expr_block<Dim, Op,
+ 				 Block, Type> block_type;
+ 
+   static bool value(MapT const& map, block_type& block)
+   {
+     return Is_par_same_map<MapT, Block>::value(map, block.op());
+   }
+ };
+ 
+ 
+ 
+ template <dimension_type            Dim,
+ 	  template <typename> class Op,
+ 	  typename                  Block,
+ 	  typename                  Type>
+ struct Is_par_reorg_ok<Unary_expr_block<Dim, Op, Block, Type> const>
+ {
+   static bool const value = Is_par_reorg_ok<Block>::value;
+ };
+ 
+ 
+ 
+ /***********************************************************************
    Definitions
  ***********************************************************************/
  
Index: src/vsip/impl/global_map.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/global_map.hpp,v
retrieving revision 1.6
diff -c -p -r1.6 global_map.hpp
*** src/vsip/impl/global_map.hpp	19 Sep 2005 03:39:54 -0000	1.6
--- src/vsip/impl/global_map.hpp	2 Nov 2005 13:01:47 -0000
***************
*** 16,21 ****
--- 16,22 ----
  
  #include <vsip/impl/value-iterator.hpp>
  #include <vsip/impl/par-services.hpp>
+ #include <vsip/impl/map-traits.hpp>
  
  
  
*************** public:
*** 117,122 ****
--- 118,144 ----
    Local_or_global_map() {}
  };
  
+ namespace impl
+ {
+ 
+ /// Specialize global traits for Local_or_global_map.
+ 
+ template <dimension_type Dim>
+ struct Is_global_only<Local_or_global_map<Dim> >
+ { static bool const value = false; };
+ 
+ 
+ 
+ template <dimension_type Dim>
+ struct Map_equal<Global_map<Dim>, Global_map<Dim> >
+ {
+   static bool value(Global_map<Dim> const&,
+ 		    Global_map<Dim> const&)
+     { return true; }
+ };
+ 
+ } // namespace vsip::impl
+ 
  } // namespace vsip
  
  #endif // VSIP_IMPL_SERIAL_MAP_HPP
Index: src/vsip/impl/local_map.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/local_map.hpp,v
retrieving revision 1.4
diff -c -p -r1.4 local_map.hpp
*** src/vsip/impl/local_map.hpp	19 Sep 2005 03:39:54 -0000	1.4
--- src/vsip/impl/local_map.hpp	2 Nov 2005 13:01:47 -0000
***************
*** 17,22 ****
--- 17,23 ----
  #include <vsip/impl/block-traits.hpp>
  #include <vsip/impl/value-iterator.hpp>
  #include <vsip/impl/par-services.hpp>
+ #include <vsip/impl/map-traits.hpp>
  
  
  
*************** public:
*** 81,92 ****
      { assert(0); }
  
    template <dimension_type Dim2>
!   Domain<Dim2> get_global_dom(subblock_type sb, index_type patch)
      const VSIP_NOTHROW
      { assert(0); }
  
    template <dimension_type Dim2>
!   Domain<Dim2> get_local_dom (subblock_type sb, index_type patch)
      const VSIP_NOTHROW
      { assert(0); }
  
--- 82,93 ----
      { assert(0); }
  
    template <dimension_type Dim2>
!   Domain<Dim2> get_global_dom(subblock_type /*sb*/, index_type /*patch*/)
      const VSIP_NOTHROW
      { assert(0); }
  
    template <dimension_type Dim2>
!   Domain<Dim2> get_local_dom (subblock_type /*sb*/, index_type /*patch*/)
      const VSIP_NOTHROW
      { assert(0); }
  
*************** public:
*** 114,119 ****
--- 115,132 ----
  namespace impl
  {
  
+ /// Specialize local/global traits for Local_map.
+ 
+ template <>
+ struct Is_local_only<Local_map>
+ { static bool const value = true; };
+ 
+ template <>
+ struct Is_global_only<Local_map>
+ { static bool const value = false; };
+ 
+ 
+ 
  template < >
  struct Map_equal<Local_map,Local_map>
  {
Index: src/vsip/impl/map-traits.hpp
===================================================================
RCS file: src/vsip/impl/map-traits.hpp
diff -N src/vsip/impl/map-traits.hpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- src/vsip/impl/map-traits.hpp	2 Nov 2005 13:01:47 -0000
***************
*** 0 ****
--- 1,43 ----
+ /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+ 
+ /** @file    vsip/impl/block-traits.hpp
+     @author  Jules Bergmann
+     @date    2005-10-31
+     @brief   VSIPL++ Library: Map traits.
+ 
+     Traits for map types.
+ */
+ 
+ #ifndef VSIP_IMPL_MAP_TRAITS_HPP
+ #define VSIP_IMPL_MAP_TRAITS_HPP
+ 
+ /***********************************************************************
+   Included Files
+ ***********************************************************************/
+ 
+ 
+ 
+ /***********************************************************************
+   Declarations
+ ***********************************************************************/
+ 
+ namespace vsip
+ {
+ namespace impl
+ {
+ 
+ /// Traits class to determine if a map is serial or not.
+ 
+ template <typename MapT>
+ struct Is_local_only
+ { static bool const value = false; };
+ 
+ template <typename Map>
+ struct Is_global_only
+ { static bool const value = true; };
+ 
+ 
+ } // namespace vsip::impl
+ } // namespace vsip
+ 
+ #endif // VSIP_IMPL_MAP_TRAITS_HPP
Index: src/vsip/impl/subblock.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/subblock.hpp,v
retrieving revision 1.35
diff -c -p -r1.35 subblock.hpp
*** src/vsip/impl/subblock.hpp	31 Oct 2005 15:57:46 -0000	1.35
--- src/vsip/impl/subblock.hpp	2 Nov 2005 13:01:47 -0000
*************** class Diag_block 
*** 1542,1549 ****
    length_type size(dimension_type block_d, dimension_type d) const VSIP_NOTHROW
      { 
        assert(block_d == 1 && dim == 1 && d == 0);
!       return std::min( this->blk_->size(2, 0),
!         this->blk_->size(2, 1) );
      }
  
    // These are noops as Diag_block is held by-value.
--- 1542,1548 ----
    length_type size(dimension_type block_d, dimension_type d) const VSIP_NOTHROW
      { 
        assert(block_d == 1 && dim == 1 && d == 0);
!       return this->size();
      }
  
    // These are noops as Diag_block is held by-value.
Index: src/vsip/impl/vmmul.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/vmmul.hpp,v
retrieving revision 1.1
diff -c -p -r1.1 vmmul.hpp
*** src/vsip/impl/vmmul.hpp	26 Sep 2005 20:11:05 -0000	1.1
--- src/vsip/impl/vmmul.hpp	2 Nov 2005 13:01:47 -0000
*************** namespace vsip
*** 31,138 ****
  namespace impl
  {
  
! template <dimension_type Dim>
! class Vmmul_class;
  
! template <>
! struct Vmmul_class<0>
  {
!   template <typename T0,
! 	     typename T1,
! 	     typename T2,
! 	     typename Block0,
! 	     typename Block1,
! 	     typename Block2>
!   static void exec(
!     const_Vector<T0, Block0> v,
!     const_Matrix<T1, Block1> m,
!     Matrix<T2, Block2>       res,
!     row2_type)
!   {
!     assert(v.size() == m.size(1));
  
!     // multiply rows of m by v (row-major)
!     for (index_type r=0; r<m.size(0); ++r)
!       res.row(r) = v * m.row(r);
!   }
  
!   template <typename T0,
! 	     typename T1,
! 	     typename T2,
! 	     typename Block0,
! 	     typename Block1,
! 	     typename Block2>
!   static void exec(
!     const_Vector<T0, Block0> v,
!     const_Matrix<T1, Block1> m,
!     Matrix<T2, Block2>       res,
!     col2_type)
!   {
!     assert(v.size() == m.size(1));
  
!     // multiply rows of m by v (col-major)
!     for (index_type c=0; c<m.size(1); ++c)
!       res.col(c) = v.get(c) * m.col(c);
    }
  };
  
  
  
! template <>
! struct Vmmul_class<1>
  {
!   template <typename T0,
! 	    typename T1,
! 	    typename T2,
! 	    typename Block0,
! 	    typename Block1,
! 	    typename Block2>
!   static void exec(
!     const_Vector<T0, Block0> v,
!     const_Matrix<T1, Block1> m,
!     Matrix<T2, Block2>       res,
!     col2_type)
!   {
!     assert(v.size() == m.size(0));
  
-     // multiply cols of m by v (col-major)
-     for (index_type c=0; c<m.size(1); ++c)
-       res.col(c) = v * m.col(c);
-   }
  
-   template <typename T0,
- 	    typename T1,
- 	    typename T2,
- 	    typename Block0,
- 	    typename Block1,
- 	    typename Block2>
-   static void exec(
-     const_Vector<T0, Block0> v,
-     const_Matrix<T1, Block1> m,
-     Matrix<T2, Block2>       res,
-     row2_type)
-   {
-     assert(v.size() == m.size(0));
  
!     // multiply cols of m by v (col-major)
!     for (index_type r=0; r<m.size(0); ++r)
!       res.row(r) = v.get(r) * m.row(r);
    }
  };
  
  
  
  /// Traits class to determines return type for vmmul.
  
! template <typename T0,
! 	  typename T1,
! 	  typename Block1>
  struct Vmmul_traits
  {
!   typedef typename vsip::Promotion<T0, T1>::type    value_type;
!   typedef typename Block_layout<Block1>::order_type order_type;
!   typedef Dense<2, value_type, order_type>          block_type;
!   typedef Matrix<value_type, block_type>            view_type;
  };
  
  } // namespace vsip::impl
--- 31,280 ----
  namespace impl
  {
  
! /// Expression template block for vector-matrix multiply.
! /// Requires:
! ///   VECDIM to be a dimension of vector (0 or 1)
! ///   BLOCK0 to be a 1-Dim Block.
! ///   BLOCK1 to be a 2-Dim Block.
  
! template <dimension_type VecDim,
! 	  typename       Block0,
! 	  typename       Block1>
! class Vmmul_expr_block : public Non_assignable
  {
! public:
!   static dimension_type const dim = 2;
  
!   typedef typename Block0::value_type value0_type;
!   typedef typename Block1::value_type value1_type;
  
!   typedef typename Promotion<value0_type, value1_type>::type value_type;
! 
!   typedef value_type&               reference_type;
!   typedef value_type const&         const_reference_type;
!   typedef typename Block1::map_type map_type;
  
!   Vmmul_expr_block(Block0 const& vblk, Block1 const& mblk)
!     : vblk_(vblk), mblk_(mblk)
!   {}
! 
!   length_type size() const VSIP_NOTHROW { return mblk_.size(); }
!   length_type size(dimension_type Dim, dimension_type d) const VSIP_NOTHROW
!     { return mblk_.size(Dim, d); }
! 
! 
!   void increment_count() const VSIP_NOTHROW {}
!   void decrement_count() const VSIP_NOTHROW {}
!   map_type const& map() const VSIP_NOTHROW { return mblk_.map();}
! 
!   value_type get(index_type i, index_type j) const
!   {
!     if (VecDim == 0)
!       return vblk_.get(j) * mblk_.get(i, j);
!     else
!       return vblk_.get(i) * mblk_.get(i, j);
    }
+ 
+   Block0 const& get_vblk() const VSIP_NOTHROW { return vblk_; }
+   Block1 const& get_mblk() const VSIP_NOTHROW { return mblk_; }
+ 
+   // copy-constructor: default is OK.
+ 
+ private:
+   typename View_block_storage<Block0>::expr_type vblk_;
+   typename View_block_storage<Block1>::expr_type mblk_;
+ };
+ 
+ 
+ 
+ /// Specialize traits for Vmmul_expr_block.
+ 
+ template <dimension_type VecDim,
+ 	  typename       Block0,
+ 	  typename       Block1>
+ struct Is_expr_block<Vmmul_expr_block<VecDim, Block0, Block1> >
+ { static bool const value = true; };
+ 
+ template <dimension_type VecDim,
+ 	  typename       Block0,
+ 	  typename       Block1>
+ struct View_block_storage<Vmmul_expr_block<VecDim, Block0, Block1> const>
+   : By_value_block_storage<Vmmul_expr_block<VecDim, Block0, Block1> const>
+ {};
+ 
+ template <dimension_type VecDim,
+ 	  typename       Block0,
+ 	  typename       Block1>
+ struct Distributed_local_block<Vmmul_expr_block<VecDim, Block0, Block1> const>
+ {
+   typedef Vmmul_expr_block<VecDim,
+ 			   typename Distributed_local_block<Block0>::type,
+ 			   typename Distributed_local_block<Block1>::type>
+ 		const type;
  };
  
  
  
! template <typename       CombineT,
! 	  dimension_type VecDim,
! 	  typename       Block0,
! 	  typename       Block1>
! struct Combine_return_type<CombineT,
!                            Vmmul_expr_block<VecDim, Block0, Block1> const>
  {
!   typedef Vmmul_expr_block<VecDim,
!     typename Combine_return_type<CombineT, Block0>::tree_type,
!     typename Combine_return_type<CombineT, Block1>::tree_type>
! 		const tree_type;
!   typedef tree_type type;
! };
! 
! 
! 
! template <typename       CombineT,
! 	  dimension_type VecDim,
! 	  typename       Block0,
! 	  typename       Block1>
! struct Combine_return_type<CombineT,
!                            Vmmul_expr_block<VecDim, Block0, Block1> >
! {
!   typedef Vmmul_expr_block<VecDim,
!     typename Combine_return_type<CombineT, Block0>::tree_type,
!     typename Combine_return_type<CombineT, Block1>::tree_type>
! 		const tree_type;
!   typedef tree_type type;
! };
! 
! 
!   
! template <dimension_type VecDim,
! 	  typename       Block0,
! 	  typename       Block1>
! Vmmul_expr_block<VecDim, 
! 		 typename Distributed_local_block<Block0>::type,
! 		 typename Distributed_local_block<Block1>::type>
! get_local_block(
!   Vmmul_expr_block<VecDim, Block0, Block1> const& block)
! {
!   typedef Vmmul_expr_block<VecDim,
!                            typename Distributed_local_block<Block0>::type,
!                            typename Distributed_local_block<Block1>::type>
! 		block_type;
! 
!   return block_type(get_local_block(block.get_vblk()),
! 		    get_local_block(block.get_mblk()));
! }
! 
! 
! 
! template <typename       CombineT,
! 	  dimension_type VecDim,
! 	  typename       Block0,
! 	  typename       Block1>
! typename Combine_return_type<CombineT,
! 			     Vmmul_expr_block<VecDim, Block0, Block1> const>
! 		::type
! apply_combine(
!   CombineT const&                                 combine,
!   Vmmul_expr_block<VecDim, Block0, Block1> const& block)
! {
!   typedef typename Combine_return_type<
!     CombineT,
!     Vmmul_expr_block<VecDim, Block0, Block1> const>::type
! 		block_type;
! 
!   return block_type(apply_combine(combine, block.get_vblk()),
! 		    apply_combine(combine, block.get_mblk()));
! }
! 
! 
! 
! template <typename       VisitorT,
! 	  dimension_type VecDim,
! 	  typename       Block0,
! 	  typename       Block1>
! void
! apply_leaf(
!   VisitorT const&                                 visitor,
!   Vmmul_expr_block<VecDim, Block0, Block1> const& block)
! {
!   apply_leaf(visitor, block.get_vblk());
!   apply_leaf(visitor, block.get_mblk());
! }
  
  
  
! // Check vmmul parallel support conditions
! //
! // vector-matrix multiply works with the following mappings:
! // case 0:
! //  - All data mapped locally (Local_map) (*)
! // case 1:
! //  - vector data mapped global
! //    matrix data mapped without distribution only vector direction
! // case 2:
! //  - vector data mapped distributed,
! //    matrix data mapped with same distribution along vector direction,
! //       and no distribution perpendicular to vector.
! //  - vector and matrix mapped to single, single processor
! //
! 
! template <typename       MapT,
! 	  dimension_type VecDim,
! 	  typename       Block0,
! 	  typename       Block1>
! struct Is_par_same_map<MapT,
!                        Vmmul_expr_block<VecDim, Block0, Block1> const>
! {
!   typedef Vmmul_expr_block<VecDim, Block0, Block1> const block_type;
! 
!   static bool value(MapT const& map, block_type& block)
!   {
!     // Dispatch_assign only calls Is_par_same_map for distributed
!     // expressions.
!     assert(!Is_local_only<MapT>::value);
! 
!     return 
!       // Case 1: vector is global
!       (Is_par_same_map<Global_map<1>, Block0>::value(
! 			Global_map<1>(), block.get_vblk()) &&
!        map.num_subblocks(1-VecDim) == 1 &&
!        Is_par_same_map<MapT, Block1>::value(map, block.get_mblk())) ||
! 
!       // Case 2:
!       (map.num_subblocks(VecDim) == 1 &&
!        Is_par_same_map<typename Map_project_1<VecDim, MapT>::type, Block0>
! 	    ::value(Map_project_1<VecDim, MapT>::project(map, 0),
! 		    block.get_vblk()) &&
!        Is_par_same_map<MapT, Block1>::value(map, block.get_mblk()));
    }
  };
  
  
  
+ template <dimension_type VecDim,
+ 	  typename       Block0,
+ 	  typename       Block1>
+ struct Is_par_reorg_ok<Vmmul_expr_block<VecDim, Block0, Block1> const>
+ {
+   static bool const value = false;
+ };
+ 
+ 
+ 
+ 
  /// Traits class to determines return type for vmmul.
  
! template <dimension_type Dim,
! 	  typename       T0,
! 	  typename       T1,
! 	  typename       Block0,
! 	  typename       Block1>
  struct Vmmul_traits
  {
!   typedef typename vsip::Promotion<T0, T1>::type      value_type;
!   typedef const Vmmul_expr_block<Dim, Block0, Block1> block_type;
!   typedef Matrix<value_type, block_type>              view_type;
  };
  
  } // namespace vsip::impl
*************** template <dimension_type Dim,
*** 146,165 ****
  	  typename       T1,
  	  typename       Block0,
  	  typename       Block1>
! typename vsip::impl::Vmmul_traits<T0, T1, Block1>::view_type
  vmmul(
    const_Vector<T0, Block0> v,
    const_Matrix<T1, Block1> m)
  VSIP_NOTHROW
  {
!   typedef vsip::impl::Vmmul_traits<T0, T1, Block1> traits;
!   typedef typename traits::order_type order_type;
! 
!   typename traits::view_type res(m.size(0), m.size(1));
! 
!   vsip::impl::Vmmul_class<Dim>::exec(v, m, res, order_type());
  
!   return res;
  }
  
  } // namespace vsip
--- 288,304 ----
  	  typename       T1,
  	  typename       Block0,
  	  typename       Block1>
! typename vsip::impl::Vmmul_traits<Dim, T0, T1, Block0, Block1>::view_type
  vmmul(
    const_Vector<T0, Block0> v,
    const_Matrix<T1, Block1> m)
  VSIP_NOTHROW
  {
!   typedef impl::Vmmul_traits<Dim, T0, T1, Block0, Block1> traits;
!   typedef typename traits::block_type block_type;
!   typedef typename traits::view_type  view_type;
  
!   return view_type(block_type(v.block(), m.block()));
  }
  
  } // namespace vsip
Index: tests/distributed-subviews.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/distributed-subviews.cpp,v
retrieving revision 1.3
diff -c -p -r1.3 distributed-subviews.cpp
*** tests/distributed-subviews.cpp	19 Sep 2005 03:39:54 -0000	1.3
--- tests/distributed-subviews.cpp	2 Nov 2005 13:01:47 -0000
*************** using vsip::impl::View_of_dim;
*** 44,84 ****
  
  
  /***********************************************************************
-   Definitions
- ***********************************************************************/
- 
- template <dimension_type Dim,
- 	  typename       MapT>
- void
- dump_map(MapT const& map)
- {
-   typedef typename MapT::processor_iterator p_iter_t;
-   processor_type rank = map.impl_rank();
- 
-   std::ostringstream s;
-   s << map.impl_proc(0);
-   for (index_type i=1; i<map.impl_num_procs(); ++i)
-     s << "," << map.impl_proc(i);
- 
-   cout << rank << ": " << Type_name<MapT>::name()
-        << " [" << s.str() << "]"
-        << endl;
- 
-   for (subblock_type sb=0; sb<map.num_subblocks(); ++sb)
-   {
-     cout << "  sub " << sb << ": " << map.template get_global_dom<Dim>(sb, 0)
- 	 << " [";
-     for (p_iter_t p=map.processor_begin(sb); p != map.processor_end(sb); ++p)
-     {
-       cout << *p << " ";
-     }
-     cout << "]" << endl;
-   }
- }
- 
- 
- 
- /***********************************************************************
    Test row-subviews of distributed matrix
  ***********************************************************************/
  
--- 44,49 ----
Index: tests/extdata-output.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/extdata-output.hpp,v
retrieving revision 1.7
diff -c -p -r1.7 extdata-output.hpp
*** tests/extdata-output.hpp	12 Oct 2005 12:45:05 -0000	1.7
--- tests/extdata-output.hpp	2 Nov 2005 13:01:47 -0000
*************** struct Type_name<vsip::Map<Dist0, Dist1,
*** 214,219 ****
--- 214,245 ----
    }
  };
  
+ 
+ 
+ template <vsip::dimension_type Dim>
+ struct Type_name<vsip::Global_map<Dim> >
+ {
+   static std::string name()
+   {
+     std::ostringstream s;
+     s << "Global_map<" << Dim << ">";
+     return s.str();
+   }
+ };
+ 
+ template <vsip::dimension_type Dim>
+ struct Type_name<vsip::Local_or_global_map<Dim> >
+ {
+   static std::string name()
+   {
+     std::ostringstream s;
+     s << "Local_or_global_map<" << Dim << ">";
+     return s.str();
+   }
+ };
+ 
+ TYPE_NAME(vsip::Local_map, "Local_map")
+ 
  #undef TYPE_NAME
  
  
Index: tests/par_expr.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/par_expr.cpp,v
retrieving revision 1.7
diff -c -p -r1.7 par_expr.cpp
*** tests/par_expr.cpp	5 Aug 2005 15:43:48 -0000	1.7
--- tests/par_expr.cpp	2 Nov 2005 13:01:47 -0000
*************** test_distributed_expr(
*** 148,157 ****
    map0_t  map0(Block_dist(1), Block_dist(1));
  
    // Non-distributed view to check results.
!   view0_t chk(create_view<view0_t>(dom, map0));
  
    // Distributed views for actual parallel-expression.
!   view_res_t Z(create_view<view_res_t>(dom, T(0), map_res));
    view_op1_t A(create_view<view_op1_t>(dom, T(3), map_op1));
    view_op2_t B(create_view<view_op2_t>(dom, T(4), map_op2));
  
--- 148,161 ----
    map0_t  map0(Block_dist(1), Block_dist(1));
  
    // Non-distributed view to check results.
!   view0_t chk1(create_view<view0_t>(dom, map0));
!   view0_t chk2(create_view<view0_t>(dom, map0));
  
    // Distributed views for actual parallel-expression.
!   view_res_t Z1(create_view<view_res_t>(dom, T(0), map_res));
!   view_res_t Z2(create_view<view_res_t>(dom, T(0), map_res));
!   view_res_t Z3(create_view<view_res_t>(dom, T(0), map_res));
!   view_res_t Z4(create_view<view_res_t>(dom, T(0), map_res));
    view_op1_t A(create_view<view_op1_t>(dom, T(3), map_op1));
    view_op2_t B(create_view<view_op2_t>(dom, T(4), map_op2));
  
*************** test_distributed_expr(
*** 164,187 ****
  
    for (int l=0; l<loop; ++l)
    {
!     foreach_point(Z, Set_identity<Dim>(dom));
  
-     Z = A + B;
      // Calls:
      //    vsip::impl::par_expr(Z, A + B);
      // from dispatch_assign.hpp
  
      // Squirrel result away to check later.
!     chk = Z;
    }
  
  
    // Check results.
    comm.barrier();
  
    if (map_res.impl_rank() == 0) // rank(map_res) == 0
    {
!     typename view0_t::local_type local_view = get_local_view(chk);
  
      // Check that local_view is in fact the entire view.
      assert(extent_old(local_view) == extent_old(dom));
--- 168,211 ----
  
    for (int l=0; l<loop; ++l)
    {
!     foreach_point(Z1, Set_identity<Dim>(dom));
!     foreach_point(Z2, Set_identity<Dim>(dom));
! 
!     Z1 = A + B;
!     Z2 = B - A;
!     Z3 = -A;
!     Z4 = -(A - B);
  
      // Calls:
      //    vsip::impl::par_expr(Z, A + B);
      // from dispatch_assign.hpp
  
      // Squirrel result away to check later.
!     chk1 = Z1;
!     chk2 = Z2;
    }
  
  
    // Check results.
    comm.barrier();
  
+   Check_identity<Dim> checker1(dom, 5, 3);
+   foreach_point(chk1, checker1);
+   assert(checker1.good());
+ 
+   Check_identity<Dim> checker2(dom, 1, 1);
+   foreach_point(chk2, checker2);
+   foreach_point(Z2, checker2);
+   foreach_point(Z4, checker2);
+   assert(checker2.good());
+ 
+   Check_identity<Dim> checker3(dom, -2, -1);
+   foreach_point(Z3, checker3);
+   assert(checker3.good());
+ 
    if (map_res.impl_rank() == 0) // rank(map_res) == 0
    {
!     typename view0_t::local_type local_view = get_local_view(chk1);
  
      // Check that local_view is in fact the entire view.
      assert(extent_old(local_view) == extent_old(dom));
*************** test_distributed_expr(
*** 191,208 ****
      for (Point<Dim> idx; idx != extent_old(local_view);
  	 next(extent_old(local_view), idx))
      {
!       T expected_value = T();
        for (dimension_type d=0; d<Dim; ++d)
        {
! 	expected_value *= local_view.size(d);
! 	expected_value += idx[d];
        }
!       expected_value = T(5)*expected_value + T(3);
  
!       if (get(local_view, idx) != expected_value)
        {
  	cout << "FAIL: index: " << idx
! 	     << "  expected " << expected_value
  	     << "  got "      << get(local_view, idx)
  	     << endl;
  	good = false;
--- 215,233 ----
      for (Point<Dim> idx; idx != extent_old(local_view);
  	 next(extent_old(local_view), idx))
      {
!       T value = T();
        for (dimension_type d=0; d<Dim; ++d)
        {
! 	value *= local_view.size(d);
! 	value += idx[d];
        }
!       T expect1 = T(5)*value + T(3);
!       // T expect2 = T(1)*value + T(1);
  
!       if (get(local_view, idx) != expect1)
        {
  	cout << "FAIL: index: " << idx
! 	     << "  expected " << expect1
  	     << "  got "      << get(local_view, idx)
  	     << endl;
  	good = false;
*************** test_distributed_expr3(
*** 254,266 ****
    map0_t  map0(Block_dist(1), Block_dist(1));
  
    // Non-distributed view to check results.
!   view0_t chk(create_view<view0_t>(dom, map0));
  
    // Distributed views for actual parallel-expression.
!   view_res_t Z(create_view<view_res_t>(dom, T(0), map_res));
!   view_op1_t A(create_view<view_op1_t>(dom, T(3), map_op1));
!   view_op2_t B(create_view<view_op2_t>(dom, T(4), map_op2));
!   view_op3_t C(create_view<view_op3_t>(dom, T(5), map_op3));
  
    impl::Communicator comm = impl::default_communicator();
  
--- 279,293 ----
    map0_t  map0(Block_dist(1), Block_dist(1));
  
    // Non-distributed view to check results.
!   view0_t chk1(create_view<view0_t>(dom, map0));
!   view0_t chk2(create_view<view0_t>(dom, map0));
  
    // Distributed views for actual parallel-expression.
!   view_res_t Z1(create_view<view_res_t>(dom, T(0), map_res));
!   view_res_t Z2(create_view<view_res_t>(dom, T(0), map_res));
!   view_op1_t A (create_view<view_op1_t>(dom, T(3), map_op1));
!   view_op2_t B (create_view<view_op2_t>(dom, T(4), map_op2));
!   view_op3_t C (create_view<view_op3_t>(dom, T(5), map_op3));
  
    impl::Communicator comm = impl::default_communicator();
  
*************** test_distributed_expr3(
*** 270,284 ****
  
    for (int l=0; l<loop; ++l)
    {
!     foreach_point(Z, Set_identity<Dim>(dom));
  
!     Z = A * B + C;
      // Calls:
      //    vsip::impl::par_expr(Z, A + B);
      // from dispatch_assign.hpp
  
      // Squirrel result away to check later.
!     chk = Z;
    }
  
  
--- 297,314 ----
  
    for (int l=0; l<loop; ++l)
    {
!     foreach_point(Z1, Set_identity<Dim>(dom));
!     foreach_point(Z2, Set_identity<Dim>(dom));
  
!     Z1 = A * B + C;
!     Z2 = ma(A, B, C);
      // Calls:
      //    vsip::impl::par_expr(Z, A + B);
      // from dispatch_assign.hpp
  
      // Squirrel result away to check later.
!     chk1 = Z1;
!     chk2 = Z2;
    }
  
  
*************** test_distributed_expr3(
*** 287,293 ****
  
    if (map_res.impl_rank() == 0) 
    {
!     typename view0_t::local_type local_view = get_local_view(chk);
  
      // Check that local_view is in fact the entire view.
      assert(extent_old(local_view) == extent_old(dom));
--- 317,323 ----
  
    if (map_res.impl_rank() == 0) 
    {
!     typename view0_t::local_type local_view = get_local_view(chk1);
  
      // Check that local_view is in fact the entire view.
      assert(extent_old(local_view) == extent_old(dom));
*************** test_vector_assign(int loop)
*** 459,464 ****
--- 489,499 ----
  
    test_distributed_expr<T>(
      Domain<1>(16),
+     map1, map1, map2,
+     loop);
+ 
+   test_distributed_expr<T>(
+     Domain<1>(16),
      map3, map3, map3,
      loop);
  
Index: tests/util-par.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/util-par.hpp,v
retrieving revision 1.4
diff -c -p -r1.4 util-par.hpp
*** tests/util-par.hpp	26 Aug 2005 14:14:11 -0000	1.4
--- tests/util-par.hpp	2 Nov 2005 13:01:47 -0000
***************
*** 20,25 ****
--- 20,28 ----
  #include <vsip/vector.hpp>
  #include <vsip/matrix.hpp>
  
+ #include "output.hpp"
+ #include "extdata-output.hpp"
+ 
  
  
  /***********************************************************************
*************** dump_view(
*** 110,138 ****
    vsip::Vector<T, Block> view)
  {
    using vsip::index_type;
  
    typedef typename Block::map_type map_t;
!   typedef typename Block::local_block_type local_block_t;
  
-   Block&       block  = view.block();
    map_t const& am     = view.block().map();
  
-   typename map_t::subblock_iterator cur = block.subblocks_begin();
-   typename map_t::subblock_iterator end = block.subblocks_end();
- 
    msg(am, std::string(name) + " ------------------------------------------\n");
    std::cout << "(" << am.impl_rank() << "): dump_view(" << name << ")\n";
  
!   for (; cur != end; ++cur)
    {
!     vsip::Vector<T, local_block_t> local_view = get_local_view(view, *cur);
  
!     for (index_type p=0; p<am.num_patches(*cur); ++p)
      {
!       std::cout << "  subblock: " << *cur
  		<< "  patch: " << p << std::endl;
!       vsip::Domain<1> ldom = am.template get_local_dom<1>(*cur, p);
!       vsip::Domain<1> gdom = am.template get_global_dom<1>(*cur, p);
  
        for (index_type i=0; i<ldom.length(); ++i) 
        {
--- 113,145 ----
    vsip::Vector<T, Block> view)
  {
    using vsip::index_type;
+   using vsip::subblock_type;
+   using vsip::no_subblock;
+   using vsip::impl::Distributed_local_block;
  
    typedef typename Block::map_type map_t;
!   typedef typename Distributed_local_block<Block>::type local_block_t;
  
    map_t const& am     = view.block().map();
  
    msg(am, std::string(name) + " ------------------------------------------\n");
    std::cout << "(" << am.impl_rank() << "): dump_view(" << name << ")\n";
+   std::cout << "(" << am.impl_rank() << "):    map   "
+ 	    << Type_name<map_t>::name() << "\n";
+   std::cout << "(" << am.impl_rank() << "):    block "
+ 	    << Type_name<Block>::name() << "\n";
  
!   subblock_type sb = am.impl_subblock();
!   if (sb != no_subblock)
    {
!     vsip::Vector<T, local_block_t> local_view = get_local_view(view);
  
!     for (index_type p=0; p<am.num_patches(sb); ++p)
      {
!       std::cout << "  subblock: " << sb
  		<< "  patch: " << p << std::endl;
!       vsip::Domain<1> ldom = am.template get_local_dom<1>(sb, p);
!       vsip::Domain<1> gdom = am.template get_global_dom<1>(sb, p);
  
        for (index_type i=0; i<ldom.length(); ++i) 
        {
*************** dump_view(
*** 143,148 ****
--- 150,159 ----
        }
      }
    }
+   else
+   {
+     std::cout << "  no_subblock" << std::endl;
+   }
  
    msg(am, " ------------------------------------------\n");
  }
*************** dump_view(
*** 160,194 ****
  {
    using vsip::index_type;
    using vsip::dimension_type;
  
    dimension_type const dim = 2;
    typedef typename Block::map_type map_t;
!   typedef typename Block::local_block_type local_block_t;
  
-   Block&       block = view.block();
    map_t const& am    = view.block().map();
  
-   typename map_t::subblock_iterator cur = block.subblocks_begin();
-   typename map_t::subblock_iterator end = block.subblocks_end();
- 
    msg(am, std::string(name) + " ------------------------------------------\n");
    std::cout << "(" << am.impl_rank() << "): dump_view(Matrix " << name << ")\n";
  
!   for (; cur != end; ++cur)
    {
!     vsip::Matrix<T, local_block_t> local_view = get_local_view(view, *cur);
  
!     for (index_type p=0; p<am.num_patches(*cur); ++p)
      {
        char str[256];
        sprintf(str, "  lblock: %08lx", (unsigned long)&(local_view.block()));
  
!       std::cout << "  subblock: " << *cur
  	   << "  patch: " << p
  	   << str
  	   << std::endl;
!       vsip::Domain<dim> ldom = am.template get_local_dom<dim>(*cur, p);
!       vsip::Domain<dim> gdom = am.template get_global_dom<dim>(*cur, p);
  
        for (index_type r=0; r<ldom[0].length(); ++r) 
  	for (index_type c=0; c<ldom[1].length(); ++c) 
--- 171,205 ----
  {
    using vsip::index_type;
    using vsip::dimension_type;
+   using vsip::subblock_type;
+   using vsip::no_subblock;
+   using vsip::impl::Distributed_local_block;
  
    dimension_type const dim = 2;
    typedef typename Block::map_type map_t;
!   typedef typename Distributed_local_block<Block>::type local_block_t;
  
    map_t const& am    = view.block().map();
  
    msg(am, std::string(name) + " ------------------------------------------\n");
    std::cout << "(" << am.impl_rank() << "): dump_view(Matrix " << name << ")\n";
  
!   subblock_type sb = am.impl_subblock();
!   if (sb != no_subblock)
    {
!     vsip::Matrix<T, local_block_t> local_view = get_local_view(view);
  
!     for (index_type p=0; p<am.num_patches(sb); ++p)
      {
        char str[256];
        sprintf(str, "  lblock: %08lx", (unsigned long)&(local_view.block()));
  
!       std::cout << "  subblock: " << sb
  	   << "  patch: " << p
  	   << str
  	   << std::endl;
!       vsip::Domain<dim> ldom = am.template get_local_dom<dim>(sb, p);
!       vsip::Domain<dim> gdom = am.template get_global_dom<dim>(sb, p);
  
        for (index_type r=0; r<ldom[0].length(); ++r) 
  	for (index_type c=0; c<ldom[1].length(); ++c) 
*************** dump_view(
*** 199,205 ****
  	  index_type gr = gdom[0].impl_nth(r);
  	  index_type gc = gdom[1].impl_nth(c);
  
! 	  std::cout << "(" << am.impl_rank() << ") " << *cur << "/" << p
  	       << "    ["
  	       << lr << "," << lc << ":"
  	       << gr << "," << gc << "] = "
--- 210,216 ----
  	  index_type gr = gdom[0].impl_nth(r);
  	  index_type gc = gdom[1].impl_nth(c);
  
! 	  std::cout << "(" << am.impl_rank() << ") " << sb << "/" << p
  	       << "    ["
  	       << lr << "," << lc << ":"
  	       << gr << "," << gc << "] = "
*************** dump_view(
*** 208,218 ****
--- 219,268 ----
        }
      }
    }
+   else
+   {
+     std::cout << "  no_subblock" << std::endl;
+   }
+ 
    msg(am, " ------------------------------------------\n");
  }
  
  
  
+ template <vsip::dimension_type Dim,
+ 	  typename             MapT>
+ void
+ dump_map(MapT const& map)
+ {
+   typedef typename MapT::processor_iterator p_iter_t;
+   vsip::processor_type rank = map.impl_rank();
+ 
+   std::ostringstream s;
+   s << map.impl_proc(0);
+   for (vsip::index_type i=1; i<map.impl_num_procs(); ++i)
+     s << "," << map.impl_proc(i);
+ 
+   std::cout << rank << ": " << Type_name<MapT>::name()
+ 	    << " [" << s.str() << "]"
+ 	    << std::endl;
+ 
+   for (vsip::subblock_type sb=0; sb<map.num_subblocks(); ++sb)
+   {
+     std::cout << "  sub " << sb << ": ";
+     if (map.impl_is_applied())
+       std::cout << map.template get_global_dom<Dim>(sb, 0);
+     std::cout << " [";
+ 
+     for (p_iter_t p=map.processor_begin(sb); p != map.processor_end(sb); ++p)
+     {
+       std::cout << *p << " ";
+     }
+     std::cout << "]" << std::endl;
+   }
+ }
+ 
+ 
+ 
  // Function object to increment an element by a delta.  (Works with
  // foreach_point)
  
*************** class Check_identity
*** 287,306 ****
  {
  public:
    Check_identity(vsip::Domain<Dim> const& dom, int k = 1, int o = 0)
!     : dom_(dom), k_(k), o_(o) {}
  
    template <typename T>
    T operator()(T value,
  	       vsip::impl::Point<1> const& /*local*/,
  	       vsip::impl::Point<1> const& global)
    {
!     T expected = T(k_*global[0] + o_);
      if (value != expected)
      {
        std::cout << "Check_identity: MISCOMPARE" << std::endl
! 		<< "  global  = " << global[0] << std::endl
! 		<< "  expeted = " << expected << std::endl
! 		<< "  actual  = " << value << std::endl;
      }
      return value;
    }
--- 337,360 ----
  {
  public:
    Check_identity(vsip::Domain<Dim> const& dom, int k = 1, int o = 0)
!     : dom_(dom), k_(k), o_(o), good_(true) {}
! 
!   bool good() { return good_; }
  
    template <typename T>
    T operator()(T value,
  	       vsip::impl::Point<1> const& /*local*/,
  	       vsip::impl::Point<1> const& global)
    {
!     int i = global[0];
!     T expected = T(k_*i + o_);
      if (value != expected)
      {
        std::cout << "Check_identity: MISCOMPARE" << std::endl
! 		<< "  global   = " << global[0] << std::endl
! 		<< "  expected = " << expected << std::endl
! 		<< "  actual   = " << value << std::endl;
!       good_ = false;
      }
      return value;
    }
*************** public:
*** 310,325 ****
  	       vsip::impl::Point<2> const& /*local*/,
  	       vsip::impl::Point<2> const& global)
    {
!     vsip::index_type i = global[0]*dom_[1].length()+global[1];
      T expected = T(k_*i+o_);
  
      if (value != expected)
      {
        std::cout << "Check_identity: MISCOMPARE" << std::endl
! 		<< "  global  = " << global[0] << ", " << global[1] 
  		<< std::endl
! 		<< "  expeted = " << expected << std::endl
! 		<< "  actual  = " << value << std::endl;
      }
      return value;
    }
--- 364,380 ----
  	       vsip::impl::Point<2> const& /*local*/,
  	       vsip::impl::Point<2> const& global)
    {
!     int i = global[0]*dom_[1].length()+global[1];
      T expected = T(k_*i+o_);
  
      if (value != expected)
      {
        std::cout << "Check_identity: MISCOMPARE" << std::endl
! 		<< "  global   = " << global[0] << ", " << global[1] 
  		<< std::endl
! 		<< "  expected = " << expected << std::endl
! 		<< "  actual   = " << value << std::endl;
!       good_ = false;
      }
      return value;
    }
*************** public:
*** 329,346 ****
  	       vsip::impl::Point<3> const& /*local*/,
  	       vsip::impl::Point<3> const& global)
    {
!     vsip::index_type i = global[0]*dom_[1].length()*dom_[2].length()
!                        + global[1]*dom_[2].length()
!                        + global[2];
      T expected = T(k_*i+o_);
  
      if (value != expected)
      {
        std::cout << "Check_identity: MISCOMPARE" << std::endl
! 		<< "  global  = " << global[0] << ", " << global[1] 
  		<< std::endl
! 		<< "  expeted = " << expected << std::endl
! 		<< "  actual  = " << value << std::endl;
      }
      return value;
    }
--- 384,402 ----
  	       vsip::impl::Point<3> const& /*local*/,
  	       vsip::impl::Point<3> const& global)
    {
!     int i = global[0]*dom_[1].length()*dom_[2].length()
!           + global[1]*dom_[2].length()
!           + global[2];
      T expected = T(k_*i+o_);
  
      if (value != expected)
      {
        std::cout << "Check_identity: MISCOMPARE" << std::endl
! 		<< "  global   = " << global[0] << ", " << global[1] 
  		<< std::endl
! 		<< "  expected = " << expected << std::endl
! 		<< "  actual   = " << value << std::endl;
!       good_ = false;
      }
      return value;
    }
*************** private:
*** 349,354 ****
--- 405,411 ----
    vsip::Domain<Dim> dom_;
    int         k_;
    int         o_;
+   bool        good_;
  };
  
  #endif // VSIP_TESTS_UTIL_PAR_HPP
Index: tests/vmmul.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/vmmul.cpp,v
retrieving revision 1.1
diff -c -p -r1.1 vmmul.cpp
*** tests/vmmul.cpp	26 Sep 2005 20:11:06 -0000	1.1
--- tests/vmmul.cpp	2 Nov 2005 13:01:47 -0000
***************
*** 16,34 ****
  #include <vsip/support.hpp>
  #include <vsip/initfin.hpp>
  #include <vsip/vector.hpp>
! 
  #include <vsip/math.hpp>
  
  #include "test.hpp"
  #include "solver-common.hpp"
  
  using namespace std;
  using namespace vsip;
  
  
  
  /***********************************************************************
!   Definitions
  ***********************************************************************/
  
  template <dimension_type Dim,
--- 16,38 ----
  #include <vsip/support.hpp>
  #include <vsip/initfin.hpp>
  #include <vsip/vector.hpp>
! #include <vsip/map.hpp>
! #include <vsip/impl/global_map.hpp>
! #include <vsip/parallel.hpp>
  #include <vsip/math.hpp>
  
  #include "test.hpp"
+ #include "util-par.hpp"
  #include "solver-common.hpp"
  
+ 
  using namespace std;
  using namespace vsip;
  
  
  
  /***********************************************************************
!   Serial tests
  ***********************************************************************/
  
  template <dimension_type Dim,
*************** test_vmmul(
*** 49,55 ****
    v = test_ramp(T(), T(1), v.size());
  
    Matrix<T> res = vmmul<Dim>(v, m);
!   
    for (index_type r=0; r<rows; ++r)
      for (index_type c=0; c<cols; ++c)
        if (Dim == 0)
--- 53,59 ----
    v = test_ramp(T(), T(1), v.size());
  
    Matrix<T> res = vmmul<Dim>(v, m);
! 
    for (index_type r=0; r<rows; ++r)
      for (index_type c=0; c<cols; ++c)
        if (Dim == 0)
*************** vmmul_cases()
*** 71,80 ****
  
  
  
  int
! main()
  {
!   vsipl init;
  
    vmmul_cases();
  }
--- 75,204 ----
  
  
  
+ /***********************************************************************
+   Parallel tests
+ ***********************************************************************/
+ 
+ template <dimension_type VecDim,
+ 	  dimension_type Dim>
+ class Check_vmmul
+ {
+ public:
+   Check_vmmul(vsip::Domain<Dim> const& dom) : dom_(dom) {}
+ 
+   template <typename T>
+   T operator()(T value,
+ 	       vsip::impl::Point<2> const& /*local*/,
+ 	       vsip::impl::Point<2> const& global)
+   {
+     vsip::index_type i = global[0]*dom_[1].length()+global[1];
+     T expected = (VecDim == 0) ? T(global[1] * i) : T(global[0] * i);
+ 
+     if (value != expected)
+     {
+       std::cout << "Check_vmmul: MISCOMPARE" << std::endl
+ 		<< "  global  = " << global[0] << ", " << global[1] 
+ 		<< std::endl
+ 		<< "  expected = " << expected << std::endl
+ 		<< "  actual   = " << value << std::endl;
+     }
+     return value;
+   }
+ 
+ private:
+   vsip::Domain<Dim> dom_;
+ };
+ 
+ template <dimension_type Dim,
+ 	  typename       OrderT,
+ 	  typename       T,
+ 	  typename       VecMapT,
+ 	  typename       MatMapT>
+ void
+ test_par_vmmul(
+   VecMapT const& vec_map,
+   MatMapT const& mat_map,
+   length_type    rows,
+   length_type    cols)
+ {
+   Matrix<T, Dense<2, T, OrderT, MatMapT> >    m  (rows, cols, mat_map);
+   Matrix<T, Dense<2, T, OrderT, MatMapT> >    res(rows, cols, mat_map);
+   Vector<T, Dense<1, T, row1_type, VecMapT> > v(Dim == 0 ? cols : rows,
+ 						vec_map);
+ 
+   foreach_point(m, Set_identity<2>(Domain<2>(rows, cols)));
+   foreach_point(v, Set_identity<1>(Domain<1>(v.size())));
+ 
+   res = vmmul<Dim>(v, m);
+ 
+   foreach_point(res, Check_vmmul<Dim, 2>(Domain<2>(rows, cols)));
+ }
+ 
+ 
+ 
+ template <typename OrderT,
+ 	  typename T>
+ void
+ par_vmmul_cases()
+ {
+   processor_type np, nr, nc;
+ 
+   get_np_square(np, nr, nc);
+ 
+ 
+   // -------------------------------------------------------------------
+   // If vector is global (replicated on all processors),
+   // The matrix must not be distributed in the along the vector
+ 
+   Global_map<1> gmap;
+   Map<Block_dist, Block_dist> row_map(np, 1);
+   Map<Block_dist, Block_dist> col_map(1,  np);
+   Map<Block_dist, Block_dist> chk_map(nr, nc);
+ 
+   test_par_vmmul<0, OrderT, T>(gmap, row_map, 5, 7);
+   // test_par_vmmul<1, OrderT, T>(gmap, row_map, 4, 3); // dist along vector
+ 
+   // test_par_vmmul<0, OrderT, T>(gmap, col_map, 5, 7); // dist along vector
+   test_par_vmmul<1, OrderT, T>(gmap, col_map, 5, 7);
+ 
+   // test_par_vmmul<0, OrderT, T>(gmap, chk_map, 5, 7); // dist along vector
+   // test_par_vmmul<1, OrderT, T>(gmap, chk_map, 5, 7); // dist along vector
+ 
+   // -------------------------------------------------------------------
+   // If vector is distributed (not replicated),
+   // The matrix must
+   //    have the same distribution along the vector
+   //    not be distributed in the perpendicular to the vector
+ 
+   Map<Block_dist> vmap(np);
+ 
+   test_par_vmmul<0, OrderT, T>(vmap, col_map, 5, 7);
+   test_par_vmmul<1, OrderT, T>(vmap, row_map, 5, 7);
+ 
+   // -------------------------------------------------------------------
+   // If vector and matrix are both on single processor
+   for (processor_type p=0; p<np; ++p)
+   {
+     Vector<processor_type> pvec(1);
+     pvec(0) = p;
+     Map<Block_dist, Block_dist> p1_map(pvec, 1, 1); 
+ 
+     test_par_vmmul<0, OrderT, T>(p1_map, p1_map, 5, 7);
+     test_par_vmmul<1, OrderT, T>(p1_map, p1_map, 5, 7);
+   }
+ }
+ 
+ 
+ 
  int
! main(int argc, char** argv)
  {
!   vsipl init(argc, argv);
  
    vmmul_cases();
+ 
+   par_vmmul_cases<row2_type, float>();
+   par_vmmul_cases<col2_type, float>();
+   par_vmmul_cases<row2_type, complex<float> >();
+   par_vmmul_cases<col2_type, complex<float> >();
  }
