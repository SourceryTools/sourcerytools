Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.245
diff -c -p -r1.245 ChangeLog
*** ChangeLog	16 Sep 2005 18:27:23 -0000	1.245
--- ChangeLog	16 Sep 2005 19:44:12 -0000
***************
*** 1,3 ****
--- 1,43 ----
+ 2005-09-16  Jules Bergmann  <jules@codesourcery.com>
+ 
+ 	Implement distributed user-storage.
+ 	* src/vsip/impl/distributed-block.hpp: User-storage functionality,
+ 	  pass admit, release through to subblock.
+ 	* src/vsip/dense.hpp: Add user-storage constructor for distributed
+ 	  blocks.
+ 	* tests/distributed-user-storage.cpp: Unit tests for distributed
+ 	  user-storage.
+ 
+ 	* src/vsip/impl/copy_chain.hpp (append_offset): New member function,
+ 	  append a chain, with an offset to each member.
+ 	* src/vsip/copy_chain.cpp (append_offset): Implement it.
+ 	* src/vsip/impl/par-chain-assign.hpp: Build send and recv lists
+ 	  relative to the base address of the subblock.  Offset those lists
+ 	  when message is sent.  Allows chain to be used even if location of
+ 	  storage changes, necessary for distributed user-storage blocks.
+ 	  Use dimension-ordering when building chain.  Clear req_list.
+ 	* src/vsip/impl/par-services-mpi.hpp (Chain_builder::add): Take
+ 	  offset instead of address for new chain element.
+ 	* src/vsip/impl/par-services-none.hpp (Chain_builder::add): Likewise.
+ 
+ 	* src/vsip/map.hpp (impl_local_only, impl_global_only): Delineate
+ 	  local vs global maps.
+ 	* src/vsip/impl/global_map.hpp (Local_or_global_map): New map
+ 	  for blocks that can be local or global, depending on how used.
+ 	* src/vsip/impl/local_map.hpp: Add constructor taking a
+ 	  Local_or_global_map.
+ 	
+ 	* src/vsip/impl/par-expr.hpp (Par_expr_block): Add missing block
+ 	  bits: dim, inc/decrement_count.
+ 	* src/vsip/impl/par-util.hpp: Add parallel support functions to
+ 	  get domain of local subblock and number of patches.
+ 
+ 	* src/vsip/impl/setup-assign.hpp: New file, implements early
+ 	  binding of serial and parallel assignments.
+ 
+ 	* tests/util.hpp (create_view): Add variant for user-storage views.
+ 	 
+ 	
  2005-09-16  Stefan Seefeld  <stefan@codesourcery.com>
  
  	* src/vsip/impl/fns_elementwise.hpp: Fix (work around)
Index: src/vsip/copy_chain.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/copy_chain.cpp,v
retrieving revision 1.2
diff -c -p -r1.2 copy_chain.cpp
*** src/vsip/copy_chain.cpp	25 Aug 2005 20:40:46 -0000	1.2
--- src/vsip/copy_chain.cpp	16 Sep 2005 19:44:12 -0000
*************** incr_ptr(void*& ptr, size_t offset)
*** 35,40 ****
--- 35,66 ----
    ptr = reinterpret_cast<void*>(reinterpret_cast<size_t>(ptr) + offset);
  }
  
+ inline void*
+ add_ptr(void* ptr1, void* ptr2)
+ {
+   VSIP_IMPL_STATIC_ASSERT(sizeof(void*) == sizeof(size_t));
+   return reinterpret_cast<void*>(reinterpret_cast<size_t>(ptr1) +
+ 				 reinterpret_cast<size_t>(ptr2));
+ }
+ 
+ 
+   // Append records from an existing chain, w/offset.
+ void
+ Copy_chain::append_offset(void* offset, Copy_chain chain)
+ {
+   rec_iterator cur = chain.chain_.begin();
+   rec_iterator end = chain.chain_.end();
+ 
+   for (; cur != end; ++cur)
+   {
+     this->chain_.push_back(Record(add_ptr(cur->start_, offset),
+ 				  cur->elem_size_, 
+ 				  cur->stride_, 
+ 				  cur->length_));
+   }
+   this->data_size_ += chain.data_size_;
+ }
+ 
  
  
  // Requires:
Index: src/vsip/dense.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/dense.hpp,v
retrieving revision 1.27
diff -c -p -r1.27 dense.hpp
*** src/vsip/dense.hpp	25 Aug 2005 20:40:46 -0000	1.27
--- src/vsip/dense.hpp	16 Sep 2005 19:44:12 -0000
*************** public:
*** 667,678 ****
        : base_type(dom, value, map)
      {}
  
!   // Hidden user-storage constructors.
!   // FIXME: User-storage for distributed blocks not defined by spec.
! private:
!   Dense(Domain<1> const& dom, T*const pointer, MapT const& map = MapT())
!     VSIP_THROW((std::bad_alloc));
  
    Dense(Domain<1> const& dom, uT*const pointer, MapT const& map = MapT())
      VSIP_THROW((std::bad_alloc));
  
--- 667,681 ----
        : base_type(dom, value, map)
      {}
  
!   Dense(Domain<1> const& dom, T* const pointer, MapT const& map = MapT())
!     VSIP_THROW((std::bad_alloc))
!       : base_type(dom, pointer, map)
!     {}
  
+   // User-storage for distributed blocks is not yet defined by the
+   // spec.  Hide these variants for explicit split and interleaved
+   // complex until parallel-spec is finished.
+ private:
    Dense(Domain<1> const& dom, uT*const pointer, MapT const& map = MapT())
      VSIP_THROW((std::bad_alloc));
  
*************** public:
*** 783,794 ****
        : base_type(dom, value, map)
      {}
  
!   // Hidden user-storage constructors.
!   // FIXME: User-storage for distributed blocks not defined by spec.
! private:
!   Dense(Domain<2> const& dom, T*const pointer, MapT const& map = MapT())
!     VSIP_THROW((std::bad_alloc));
  
    Dense(Domain<2> const& dom, uT*const pointer, MapT const& map = MapT())
      VSIP_THROW((std::bad_alloc));
  
--- 786,800 ----
        : base_type(dom, value, map)
      {}
  
!   Dense(Domain<2> const& dom, T* const pointer, MapT const& map = MapT())
!     VSIP_THROW((std::bad_alloc))
!       : base_type(dom, pointer, map)
!     {}
  
+   // User-storage for distributed blocks is not yet defined by the
+   // spec.  Hide these variants for explicit split and interleaved
+   // complex until parallel-spec is finished.
+ private:
    Dense(Domain<2> const& dom, uT*const pointer, MapT const& map = MapT())
      VSIP_THROW((std::bad_alloc));
  
*************** public:
*** 903,914 ****
        : base_type(dom, value, map)
      {}
  
!   // Hidden user-storage constructors.
!   // FIXME: User-storage for distributed blocks not defined by spec.
! private:
!   Dense(Domain<3> const& dom, T*const pointer, MapT const& map = MapT())
!     VSIP_THROW((std::bad_alloc));
  
    Dense(Domain<3> const& dom, uT*const pointer, MapT const& map = MapT())
      VSIP_THROW((std::bad_alloc));
  
--- 909,923 ----
        : base_type(dom, value, map)
      {}
  
!   Dense(Domain<3> const& dom, T* const pointer, MapT const& map = MapT())
!     VSIP_THROW((std::bad_alloc))
!       : base_type(dom, pointer, map)
!     {}
  
+   // User-storage for distributed blocks is not yet defined by the
+   // spec.  Hide these variants for explicit split and interleaved
+   // complex until parallel-spec is finished.
+ private:
    Dense(Domain<3> const& dom, uT*const pointer, MapT const& map = MapT())
      VSIP_THROW((std::bad_alloc));
  
*************** Dense_impl<Dim, T, OrderT, MapT>::admit(
*** 1418,1424 ****
  {
    // PROFILE: warn if already admitted
  
-   // FIXME: this could be much more efficient
    if (this->is_alloc() && update)
    {
      for (index_type i=0; i<this->size(); ++i)
--- 1427,1432 ----
*************** Dense_impl<Dim, T, OrderT, MapT>::releas
*** 1446,1452 ****
  {
    // PROFILE: warn if already released
  
-   // FIXME: this could be much more efficient
    if (this->is_alloc() && update)
    {
      for (index_type i=0; i<this->size(); ++i)
--- 1454,1459 ----
Index: src/vsip/map.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/map.hpp,v
retrieving revision 1.15
diff -c -p -r1.15 map.hpp
*** src/vsip/map.hpp	28 Aug 2005 00:22:39 -0000	1.15
--- src/vsip/map.hpp	16 Sep 2005 19:44:12 -0000
*************** public:
*** 102,107 ****
--- 102,109 ----
    typedef impl::Value_iterator<processor_type, unsigned> processor_iterator;
    typedef std::vector<processor_type> pvec_type;
  
+   static bool const impl_local_only  = false;
+   static bool const impl_global_only = true;
  
    // Constructors and destructor.
  public:
Index: src/vsip/impl/copy_chain.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/copy_chain.hpp,v
retrieving revision 1.2
diff -c -p -r1.2 copy_chain.hpp
*** src/vsip/impl/copy_chain.hpp	12 Aug 2005 13:39:47 -0000	1.2
--- src/vsip/impl/copy_chain.hpp	16 Sep 2005 19:44:12 -0000
*************** public:
*** 73,78 ****
--- 73,81 ----
      this->data_size_ += chain.data_size_;
    }
  
+   // Append records from an existing chain, w/offset.
+   void append_offset(void* offset, Copy_chain chain);
+ 
    // Copy data into buffer.
    void copy_into(void* dest, size_t size) const;
  
Index: src/vsip/impl/distributed-block.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/distributed-block.hpp,v
retrieving revision 1.13
diff -c -p -r1.13 distributed-block.hpp
*** src/vsip/impl/distributed-block.hpp	9 Sep 2005 11:55:00 -0000	1.13
--- src/vsip/impl/distributed-block.hpp	16 Sep 2005 19:44:12 -0000
*************** public:
*** 49,54 ****
--- 49,57 ----
  
    // Private compile-time values and types.
  private:
+   enum private_type {};
+   typedef typename impl::Complex_value_type<value_type, private_type>::type uT;
+ 
    typedef typename map_type::subblock_iterator subblock_iterator;
  
    // Constructors and destructor.
*************** public:
*** 62,74 ****
      map_.apply(dom);
      for (dimension_type d=0; d<dim; ++d)
        size_[d] = dom[d].length();
-     construct_subblock(false);
-   }
  
  
  
    Distributed_block(Domain<dim> const& dom, value_type value,
! 		   Map const& map = Map())
      : map_           (map),
        proc_          (map_.impl_rank()),
        sb_            (map_.impl_subblock()),
--- 65,100 ----
      map_.apply(dom);
      for (dimension_type d=0; d<dim; ++d)
        size_[d] = dom[d].length();
  
+     Domain<dim> sb_dom = 
+       (sb_ != no_subblock) ? map_.template get_subblock_dom<dim>(sb_)
+                            : empty_domain<dim>();
  
+     subblock_ = new Block(sb_dom);
+   }
  
    Distributed_block(Domain<dim> const& dom, value_type value,
! 		    Map const& map = Map())
!     : map_           (map),
!       proc_          (map_.impl_rank()),
!       sb_            (map_.impl_subblock()),
!       subblock_      (NULL)
!   {
!     map_.apply(dom);
!     for (dimension_type d=0; d<dim; ++d)
!       size_[d] = dom[d].length();
! 
!     Domain<dim> sb_dom = 
!       (sb_ != no_subblock) ? map_.template get_subblock_dom<dim>(sb_)
!                            : empty_domain<dim>();
! 
!     subblock_ = new Block(sb_dom, value);
!   }
! 
!   Distributed_block(
!     Domain<dim> const& dom, 
!     value_type* const  ptr,
!     Map const&         map = Map())
      : map_           (map),
        proc_          (map_.impl_rank()),
        sb_            (map_.impl_subblock()),
*************** public:
*** 77,83 ****
      map_.apply(dom);
      for (dimension_type d=0; d<dim; ++d)
        size_[d] = dom[d].length();
!     construct_subblock(true, value);
    }
  
  
--- 103,114 ----
      map_.apply(dom);
      for (dimension_type d=0; d<dim; ++d)
        size_[d] = dom[d].length();
! 
!     Domain<dim> sb_dom = 
!       (sb_ != no_subblock) ? map_.template get_subblock_dom<dim>(sb_)
!                            : empty_domain<dim>();
! 
!     subblock_ = new Block(sb_dom, ptr);
    }
  
  
*************** public:
*** 92,103 ****
      
    // Data accessors.
  public:
!   // FIXME: a get() is a broadcast.  The processor owning the index
!   //    broadcasts the value to the other processors in the map.
    value_type get(index_type /*idx*/) const VSIP_NOTHROW
    { VSIP_IMPL_THROW(impl::unimplemented("Distributed_block::get()")); }
  
!   // FIXME: a put() is executed only on the processor owning the index.
    void put(index_type /*idx*/, value_type /*val*/) VSIP_NOTHROW
    { VSIP_IMPL_THROW(impl::unimplemented("Distributed_block::put()")); }
  
--- 123,136 ----
      
    // Data accessors.
  public:
!   // get() on a distributed_block is a broadcast.  The processor
!   // owning the index broadcasts the value to the other processors in
!   // the map.
    value_type get(index_type /*idx*/) const VSIP_NOTHROW
    { VSIP_IMPL_THROW(impl::unimplemented("Distributed_block::get()")); }
  
!   // put() on a distributed_block is executed only on the processor
!   // owning the index.
    void put(index_type /*idx*/, value_type /*val*/) VSIP_NOTHROW
    { VSIP_IMPL_THROW(impl::unimplemented("Distributed_block::put()")); }
  
*************** public:
*** 128,143 ****
    subblock_iterator subblocks_end  () const VSIP_NOTHROW
      { return map_.subblocks_end(proc_); }
  
  
!   // Private implementation functions:
! private:
!   void construct_subblock(bool init, value_type value = value_type())
!   {
!     Domain<dim> sb_dom = 
!       (sb_ != no_subblock) ? map_.template get_subblock_dom<dim>(sb_)
!                            : empty_domain<dim>();
!     subblock_ = init ? new Block(sb_dom, value) : new Block(sb_dom);
!   }
  
    // Member data.
  public:
--- 161,200 ----
    subblock_iterator subblocks_end  () const VSIP_NOTHROW
      { return map_.subblocks_end(proc_); }
  
+   // User storage functions.
+ public:
+   void admit(bool update = true) VSIP_NOTHROW
+     { subblock_->admit(update); }
  
!   void release(bool update = true) VSIP_NOTHROW
!     { subblock_->release(update); }
! 
!   void release(bool update, value_type*& pointer) VSIP_NOTHROW
!     { VSIP_IMPL_THROW(impl::unimplemented("Distributed_block::release()")); }
!   void release(bool update, uT*& pointer) VSIP_NOTHROW
!     { VSIP_IMPL_THROW(impl::unimplemented("Distributed_block::release()")); }
!   void release(bool update, uT*& real_pointer, uT*& imag_pointer) VSIP_NOTHROW
!     { VSIP_IMPL_THROW(impl::unimplemented("Distributed_block::release()")); }
! 
!   void find(value_type*& pointer) VSIP_NOTHROW
!     { VSIP_IMPL_THROW(impl::unimplemented("Distributed_block::find()")); }
!   void find(uT*& pointer) VSIP_NOTHROW
!     { VSIP_IMPL_THROW(impl::unimplemented("Distributed_block::find()")); }
!   void find(uT*& real_pointer, uT*& imag_pointer) VSIP_NOTHROW
!     { VSIP_IMPL_THROW(impl::unimplemented("Distributed_block::find()")); }
! 
!   void rebind(value_type* pointer) VSIP_NOTHROW
!     { subblock_->rebind(pointer); }
!   void rebind(uT* pointer) VSIP_NOTHROW
!     { VSIP_IMPL_THROW(impl::unimplemented("Distributed_block::rebind()")); }
!   void rebind(uT* real_pointer, uT* imag_pointer) VSIP_NOTHROW
!     { VSIP_IMPL_THROW(impl::unimplemented("Distributed_block::rebind()")); }
! 
!   enum user_storage_type user_storage() const VSIP_NOTHROW
!   { return subblock_->user_storage(); }
! 
!   bool admitted() const VSIP_NOTHROW
!     { return subblock_->admitted(); }
  
    // Member data.
  public:
*************** assert_local(
*** 317,323 ****
  
  /// Get a local view of a subblock.
  
! /// FIXME: This needs to work for non-distributed views too.
  
  template <template <typename, typename> class View,
  	  typename                            T,
--- 374,415 ----
  
  /// Get a local view of a subblock.
  
! template <template <typename, typename> class View,
! 	  typename                            T,
! 	  typename                            Block,
! 	  typename                            MapT = typename Block::map_type>
! struct Get_local_view_class
! {
!   static
!   View<T, typename Distributed_local_block<Block>::type>
!   exec(
!     View<T, Block> v)
!   {
!     typedef typename Distributed_local_block<Block>::type block_t;
!     typedef typename View_block_storage<block_t>::type::equiv_type storage_t;
! 
!     storage_t blk = get_local_block(v.block());
!     return View<T, block_t>(blk);
!   }
! };
! 
! template <template <typename, typename> class View,
! 	  typename                            T,
! 	  typename                            Block>
! struct Get_local_view_class<View, T, Block, Local_map>
! {
!   static
!   View<T, typename Distributed_local_block<Block>::type>
!   exec(
!     View<T, Block> v)
!   {
!     typedef typename Distributed_local_block<Block>::type block_t;
!     assert((Type_equal<Block, block_t>::value));
!     return v;
!   }
! };
! 	  
! 
  
  template <template <typename, typename> class View,
  	  typename                            T,
*************** View<T, typename Distributed_local_block
*** 326,336 ****
  get_local_view(
    View<T, Block> v)
  {
!   typedef typename Distributed_local_block<Block>::type block_t;
!   typedef typename View_block_storage<block_t>::type::equiv_type storage_t;
! 
!   storage_t blk = get_local_block(v.block());
!   return View<T, block_t>(blk);
  }
  
  
--- 418,424 ----
  get_local_view(
    View<T, Block> v)
  {
!   return Get_local_view_class<View, T, Block>::exec(v);
  }
  
  
Index: src/vsip/impl/global_map.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/global_map.hpp,v
retrieving revision 1.4
diff -c -p -r1.4 global_map.hpp
*** src/vsip/impl/global_map.hpp	12 Jul 2005 11:58:06 -0000	1.4
--- src/vsip/impl/global_map.hpp	16 Sep 2005 19:44:12 -0000
*************** private:
*** 102,107 ****
--- 102,121 ----
    Domain<Dim> dom_;
  };
  
+ 
+ 
+ template <dimension_type Dim>
+ class Local_or_global_map : public Global_map<Dim>
+ {
+ public:
+   static bool const impl_local_only  = false;
+   static bool const impl_global_only = false;
+ 
+   // Constructor.
+ public:
+   Local_or_global_map() {}
+ };
+ 
  } // namespace vsip
  
  #endif // VSIP_IMPL_SERIAL_MAP_HPP
Index: src/vsip/impl/local_map.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/local_map.hpp,v
retrieving revision 1.2
diff -c -p -r1.2 local_map.hpp
*** src/vsip/impl/local_map.hpp	3 Sep 2005 02:31:38 -0000	1.2
--- src/vsip/impl/local_map.hpp	16 Sep 2005 19:44:12 -0000
***************
*** 27,32 ****
--- 27,35 ----
  namespace vsip
  {
  
+ template <dimension_type Dim>
+ class Local_or_global_map;
+ 
  class Local_map
  {
    // Compile-time typedefs.
*************** public:
*** 35,43 ****
--- 38,53 ----
    typedef impl::Value_iterator<processor_type, unsigned> processor_iterator;
    typedef impl::Communicator::pvec_type pvec_type;
  
+   static bool const impl_local_only  = true;
+   static bool const impl_global_only = false;
+ 
    // Constructor.
  public:
    Local_map() {}
+   // template <dimension_type Dim>
+   // Local_map(Global_map<Dim> const&) {}
+   template <dimension_type Dim>
+   Local_map(Local_or_global_map<Dim> const&) {}
  
    // Accessors.
  public:
Index: src/vsip/impl/par-chain-assign.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/par-chain-assign.hpp,v
retrieving revision 1.11
diff -c -p -r1.11 par-chain-assign.hpp
*** src/vsip/impl/par-chain-assign.hpp	9 Sep 2005 11:55:00 -0000	1.11
--- src/vsip/impl/par-chain-assign.hpp	16 Sep 2005 19:44:12 -0000
*************** namespace impl
*** 41,89 ****
  namespace par_chain_assign
  {
  
! template <typename ExtDataT>
  inline void
  chain_add(
    impl::Chain_builder& builder,
    ExtDataT&            ext,
    Domain<1> const&    dom)
  {
!   builder.add(ext.data() + dom.first()*ext.stride(0),
! 	    dom.stride() * ext.stride(0),
! 	    dom.length());
  }
  
  
  
! template <typename ExtDataT>
  inline void
  chain_add(
    impl::Chain_builder& builder,
    ExtDataT&            ext,
    Domain<2> const&    dom)
  {
!   builder.add(ext.data() + dom[0].first()*ext.stride(0)
! 	               + dom[1].first()*ext.stride(1),
! 	    dom[0].stride() * ext.stride(0), dom[0].length(),
! 	    dom[1].stride() * ext.stride(1), dom[1].length());
  }
  
  
  
! template <typename ExtDataT>
  inline void
  chain_add(
    impl::Chain_builder& builder,
    ExtDataT&            ext,
    Domain<3> const&    dom)
  {
!   for (index_type i = 0; i < dom[2].size(); ++i)
!   {
!     builder.add(ext.data() + dom[0].first()*ext.stride(0)
! 	                   + dom[1].first()*ext.stride(1)
! 		           + (dom[2].first()+i*dom[2].stride())*ext.stride(2),
! 	    dom[0].stride() * ext.stride(0), dom[0].length(),
! 	    dom[1].stride() * ext.stride(1), dom[1].length());
    }
  }
  
--- 41,111 ----
  namespace par_chain_assign
  {
  
! template <typename OrderT,
! 	  typename ExtDataT>
  inline void
  chain_add(
    impl::Chain_builder& builder,
    ExtDataT&            ext,
    Domain<1> const&    dom)
  {
!   typedef typename ExtDataT::value_type value_type;
! 
!   dimension_type const dim0 = OrderT::impl_dim0;
!   assert(dim0 == 0);
! 
!   builder.add<value_type>(sizeof(value_type) * dom.first()*ext.stride(dim0),
! 			  dom.stride() * ext.stride(dim0),
! 			  dom.length());
  }
  
  
  
! template <typename OrderT,
! 	  typename ExtDataT>
  inline void
  chain_add(
    impl::Chain_builder& builder,
    ExtDataT&            ext,
    Domain<2> const&    dom)
  {
!   typedef typename ExtDataT::value_type value_type;
! 
!   dimension_type const dim0 = OrderT::impl_dim0;
!   dimension_type const dim1 = OrderT::impl_dim1;
! 
!   builder.add<value_type>(
!               sizeof(value_type) * (dom[dim0].first()*ext.stride(dim0) +
! 				    dom[dim1].first()*ext.stride(dim1)),
! 	      dom[dim0].stride() * ext.stride(dim0), dom[dim0].length(),
! 	      dom[dim1].stride() * ext.stride(dim1), dom[dim1].length());
  }
  
  
  
! template <typename OrderT,
! 	  typename ExtDataT>
  inline void
  chain_add(
    impl::Chain_builder& builder,
    ExtDataT&            ext,
    Domain<3> const&    dom)
  {
!   typedef typename ExtDataT::value_type value_type;
! 
!   dimension_type const dim0 = OrderT::impl_dim0;
!   dimension_type const dim1 = OrderT::impl_dim1;
!   dimension_type const dim2 = OrderT::impl_dim2;
! 
!   for (index_type i = 0; i < dom[dim0].size(); ++i)
!   {
!     builder.add<value_type>(
!                 sizeof(value_type) *
! 		  ( (dom[dim0].first()+i*dom[dim0].stride())*ext.stride(dim0)
! 		  +  dom[dim1].first()                      *ext.stride(dim1)
! 		  +  dom[dim2].first()                      *ext.stride(dim2)),
! 		dom[dim1].stride() * ext.stride(dim1), dom[dim1].length(),
! 		dom[dim2].stride() * ext.stride(dim2), dom[dim2].length());
    }
  }
  
*************** class Chained_parallel_assign
*** 173,178 ****
--- 195,202 ----
    typedef typename Block1::map_type dst_appmap_t;
    typedef typename Block2::map_type src_appmap_t;
  
+   typedef typename Block_layout<Block1>::order_type dst_order_t;
+ 
    typedef typename src_appmap_t::subblock_iterator src_sb_iterator;
    typedef typename dst_appmap_t::subblock_iterator dst_sb_iterator;
  
*************** public:
*** 282,287 ****
--- 306,318 ----
  
    ~Chained_parallel_assign()
    {
+     // At destruction, the list of outstanding sends should be empty.
+     // This would be non-empty if:
+     //  - Chained_parallel_assign did not to clear the lists after
+     //    processing it (library design error), or
+     //  - User executed send() without a corresponding wait().
+     assert(req_list.size() == 0);
+ 
      par_chain_assign::cleanup_ext_array(src_am_.num_subblocks(), src_ext_);
      par_chain_assign::cleanup_ext_array(dst_am_.num_subblocks(), dst_ext_);
  
*************** Chained_parallel_assign<Dim, T1, T2, Blo
*** 465,471 ****
  	      Domain<dim> send_dom = domain(first(src_ldom) + offset,
  					    extent_old(intr));
  
! 	      par_chain_assign::chain_add(builder, *ext, send_dom);
  
  #if VSIP_IMPL_PCA_VERBOSE
  	      std::cout << "(" << rank << ") send "
--- 496,502 ----
  	      Domain<dim> send_dom = domain(first(src_ldom) + offset,
  					    extent_old(intr));
  
! 	      par_chain_assign::chain_add<dst_order_t>(builder, *ext, send_dom);
  
  #if VSIP_IMPL_PCA_VERBOSE
  	      std::cout << "(" << rank << ") send "
*************** Chained_parallel_assign<Dim, T1, T2, Blo
*** 569,575 ****
  	      Domain<dim> recv_dom = domain(first(dst_ldom) + offset,
  					    extent_old(intr));
  	      
! 	      par_chain_assign::chain_add(builder, *ext, recv_dom);
  	      
  #if VSIP_IMPL_PCA_VERBOSE
  	      std::cout << "(" << rank << ") recv "
--- 600,606 ----
  	      Domain<dim> recv_dom = domain(first(dst_ldom) + offset,
  					    extent_old(intr));
  	      
! 	      par_chain_assign::chain_add<dst_order_t>(builder, *ext, recv_dom);
  	      
  #if VSIP_IMPL_PCA_VERBOSE
  	      std::cout << "(" << rank << ") recv "
*************** Chained_parallel_assign<Dim, T1, T2, Blo
*** 707,715 ****
        {
  	src_ext_type* ext = src_ext_[(*sl_cur).subblock_];
  	ext->begin();
! 	// TODO: re-bottom chain if address changes.
! 	assert((*sl_cur).data_ == ext->data());
! 	builder.stitch((*sl_cur).chain_);
  	ext->end();
        }
      }
--- 738,744 ----
        {
  	src_ext_type* ext = src_ext_[(*sl_cur).subblock_];
  	ext->begin();
! 	builder.stitch(ext->data(), (*sl_cur).chain_);
  	ext->end();
        }
      }
*************** Chained_parallel_assign<Dim, T1, T2, Blo
*** 770,778 ****
        {
  	dst_ext_type* ext = dst_ext_[(*rl_cur).subblock_];
  	ext->begin();
! 	// TODO: re-bottom chain if address changes.
! 	assert((*rl_cur).data_ == ext->data());
! 	builder.stitch((*rl_cur).chain_);
  	ext->end();
        }
      }
--- 799,805 ----
        {
  	dst_ext_type* ext = dst_ext_[(*rl_cur).subblock_];
  	ext->begin();
! 	builder.stitch(ext->data(), (*rl_cur).chain_);
  	ext->end();
        }
      }
*************** Chained_parallel_assign<Dim, T1, T2, Blo
*** 848,853 ****
--- 875,881 ----
    {
      comm.wait(*cur);
    }
+   req_list.clear();
  }
  
  
Index: src/vsip/impl/par-expr.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/par-expr.hpp,v
retrieving revision 1.4
diff -c -p -r1.4 par-expr.hpp
*** src/vsip/impl/par-expr.hpp	28 Aug 2005 00:22:39 -0000	1.4
--- src/vsip/impl/par-expr.hpp	16 Sep 2005 19:44:12 -0000
*************** template <dimension_type Dim,
*** 60,65 ****
--- 60,67 ----
  class Par_expr_block : Non_copyable
  {
  public:
+   static dimension_type const dim = Dim;
+ 
    typedef typename BlockT::value_type           value_type;
    typedef typename BlockT::reference_type       reference_type;
    typedef typename BlockT::const_reference_type const_reference_type;
*************** public:
*** 85,90 ****
--- 87,95 ----
  public:
    length_type size() const VSIP_NOTHROW { return src_.block().size(); }
  
+   void increment_count() const VSIP_NOTHROW {}
+   void decrement_count() const VSIP_NOTHROW {}
+ 
    // Distributed Accessors
  public:
    local_block_type& get_local_block() const
Index: src/vsip/impl/par-services-mpi.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/par-services-mpi.hpp,v
retrieving revision 1.12
diff -c -p -r1.12 par-services-mpi.hpp
*** src/vsip/impl/par-services-mpi.hpp	28 Aug 2005 00:22:39 -0000	1.12
--- src/vsip/impl/par-services-mpi.hpp	16 Sep 2005 19:44:12 -0000
*************** public:
*** 118,141 ****
    }
  
    template <typename T>
!   void add(T* start, int stride, unsigned length)
    {
      MPI_Datatype vtype;
      chk(MPI_Type_vector(length, 1, stride, Mpi_datatype<T>::value(), &vtype));
      chk(MPI_Type_commit(&vtype));
  
-     MPI_Aint addr;
-     chk(MPI_Address(start, &addr));
- 
      lengths_.push_back(1);
!     offsets_.push_back(addr);
      types_.push_back(vtype);
  
      alltypes_.push_back(vtype);
    }
  
    template <typename T>
!   void add(T* start,
  	   int stride0, unsigned length0,
  	   int stride1, unsigned length1)
    {
--- 118,138 ----
    }
  
    template <typename T>
!   void add(ptrdiff_t offset, int stride, unsigned length)
    {
      MPI_Datatype vtype;
      chk(MPI_Type_vector(length, 1, stride, Mpi_datatype<T>::value(), &vtype));
      chk(MPI_Type_commit(&vtype));
  
      lengths_.push_back(1);
!     offsets_.push_back(offset);
      types_.push_back(vtype);
  
      alltypes_.push_back(vtype);
    }
  
    template <typename T>
!   void add(ptrdiff_t offset,
  	   int stride0, unsigned length0,
  	   int stride1, unsigned length1)
    {
*************** public:
*** 154,160 ****
      chk(MPI_Type_commit(&vtype1));
  
      MPI_Aint addr;
!     chk(MPI_Address(start, &addr));
  
      lengths_.push_back(1);
      offsets_.push_back(addr);
--- 151,157 ----
      chk(MPI_Type_commit(&vtype1));
  
      MPI_Aint addr;
!     chk(MPI_Address(offset, &addr));
  
      lengths_.push_back(1);
      offsets_.push_back(addr);
*************** public:
*** 164,179 ****
      alltypes_.push_back(vtype0);
  #else
      MPI_Datatype vtype0;
!     chk(MPI_Type_vector(length0, 1, stride0, Mpi_datatype<T>::value(), &vtype0));
      chk(MPI_Type_commit(&vtype0));
  
!     for (unsigned i=0; i<length1; ++i)
      {
-       MPI_Aint addr;
-       chk(MPI_Address(start + i*stride1, &addr));
- 
        lengths_.push_back(1);
!       offsets_.push_back(addr);
        types_.push_back(vtype0);
      }
      alltypes_.push_back(vtype0);
--- 161,173 ----
      alltypes_.push_back(vtype0);
  #else
      MPI_Datatype vtype0;
!     chk(MPI_Type_vector(length1, 1, stride1, Mpi_datatype<T>::value(), &vtype0));
      chk(MPI_Type_commit(&vtype0));
  
!     for (unsigned i=0; i<length0; ++i)
      {
        lengths_.push_back(1);
!       offsets_.push_back(offset + sizeof(T)*i*stride0);
        types_.push_back(vtype0);
      }
      alltypes_.push_back(vtype0);
*************** public:
*** 197,206 ****
      return type;
    }
  
!   void stitch(MPI_Datatype chain)
    {
      lengths_.push_back(1);
!     offsets_.push_back((MPI_Aint)MPI_BOTTOM);
      types_.push_back(chain);
    }
  
--- 191,203 ----
      return type;
    }
  
!   void stitch(void* base, MPI_Datatype chain)
    {
+     MPI_Aint addr;
+     chk(MPI_Address(base, &addr));
+ 
      lengths_.push_back(1);
!     offsets_.push_back(addr);
      types_.push_back(chain);
    }
  
Index: src/vsip/impl/par-services-none.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/par-services-none.hpp,v
retrieving revision 1.8
diff -c -p -r1.8 par-services-none.hpp
*** src/vsip/impl/par-services-none.hpp	25 Aug 2005 20:40:46 -0000	1.8
--- src/vsip/impl/par-services-none.hpp	16 Sep 2005 19:44:12 -0000
*************** public:
*** 57,74 ****
    {}
  
    template <typename T>
!   void add(T* start, int stride, unsigned length)
    {
      chain_.add(reinterpret_cast<void*>(start), sizeof(T), stride, length);
    }
  
    template <typename T>
!   void add(T* start,
  	   int stride0, unsigned length0,
  	   int stride1, unsigned length1)
    {
      for (unsigned i=0; i<length1; ++i)
!       chain_.add(reinterpret_cast<void*>(start + i*stride1),
  		 sizeof(T), stride0, length0);
    }
  
--- 57,74 ----
    {}
  
    template <typename T>
!   void add(ptrdiff_t start, int stride, unsigned length)
    {
      chain_.add(reinterpret_cast<void*>(start), sizeof(T), stride, length);
    }
  
    template <typename T>
!   void add(ptrdiff_t start,
  	   int stride0, unsigned length0,
  	   int stride1, unsigned length1)
    {
      for (unsigned i=0; i<length1; ++i)
!       chain_.add(reinterpret_cast<void*>(start + sizeof(T)*i*stride1),
  		 sizeof(T), stride0, length0);
    }
  
*************** public:
*** 77,84 ****
    Copy_chain get_chain()
    { return chain_; }
  
!   void stitch(Copy_chain chain)
!   { chain_.append(chain); }
  
    bool is_empty() const { return (chain_.size() == 0); }
  
--- 77,84 ----
    Copy_chain get_chain()
    { return chain_; }
  
!   void stitch(void* base, Copy_chain chain)
!   { chain_.append_offset(base, chain); }
  
    bool is_empty() const { return (chain_.size() == 0); }
  
Index: src/vsip/impl/par-util.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/par-util.hpp,v
retrieving revision 1.4
diff -c -p -r1.4 par-util.hpp
*** src/vsip/impl/par-util.hpp	5 Aug 2005 15:43:48 -0000	1.4
--- src/vsip/impl/par-util.hpp	16 Sep 2005 19:44:12 -0000
*************** foreach_patch(
*** 84,89 ****
--- 84,116 ----
  namespace detail
  {
  
+ // Return the subdomain of a view/map pair for a subblock.
+ 
+ template <typename ViewT>
+ inline Domain<ViewT::dim>
+ subblock_dom(
+   ViewT const&        view,
+   Local_map const&    /*map*/,
+   subblock_type       /*sb*/)
+ {
+   return block_domain<ViewT::dim>(view.block());
+ }
+ 
+ template <typename ViewT,
+ 	  typename MapT>
+ inline Domain<ViewT::dim>
+ subblock_dom(
+   ViewT const&     /*view*/,
+   MapT const&      map,
+   subblock_type    sb)
+ {
+   return map.template get_subblock_dom<ViewT::dim>(sb);
+ }
+ 
+ 
+ 
+ // Return the local domain of a view/map pair for a subblock/patch.
+ 
  template <typename ViewT>
  inline Domain<ViewT::dim>
  local_dom(
*************** local_dom(
*** 107,112 ****
--- 134,143 ----
    return map.template get_local_dom<ViewT::dim>(sb, p);
  }
  
+ 
+ 
+ // Return the global domain of a view/map pair for a subblock/patch.
+ 
  template <typename ViewT>
  inline Domain<ViewT::dim>
  global_dom(
*************** global_dom(
*** 132,137 ****
--- 163,179 ----
  
  } // namespace detail
  
+ 
+ 
+ template <typename ViewT>
+ Domain<ViewT::dim>
+ subblock_dom(
+   ViewT const&  view,
+   subblock_type sb)
+ {
+   return detail::subblock_dom(view, view.block().map(), sb);
+ }
+ 
  template <typename ViewT>
  Domain<ViewT::dim>
  local_dom(
*************** global_dom(
*** 155,160 ****
--- 197,223 ----
  
  
  template <typename ViewT>
+ length_type
+ my_patches(
+   ViewT const&  view)
+ {
+   return view.block().map().num_patches(view.block().map().impl_subblock());
+ }
+ 
+ 
+ 
+ template <typename ViewT>
+ Domain<ViewT::dim>
+ my_subblock_dom(
+   ViewT const&  view)
+ {
+   return detail::subblock_dom(view, view.block().map(),
+ 			      view.block().map().impl_subblock());
+ }
+ 
+ 
+ 
+ template <typename ViewT>
  Domain<ViewT::dim>
  my_local_dom(
    ViewT const&  view,
Index: src/vsip/impl/setup-assign.hpp
===================================================================
RCS file: src/vsip/impl/setup-assign.hpp
diff -N src/vsip/impl/setup-assign.hpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- src/vsip/impl/setup-assign.hpp	16 Sep 2005 19:44:12 -0000
***************
*** 0 ****
--- 1,261 ----
+ /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+ 
+ /** @file    vsip/impl/setup-assign.hpp
+     @author  Jules Bergmann
+     @date    2005-08-26
+     @brief   VSIPL++ Library: Early binding of an assignment.
+ 
+ */
+ 
+ #ifndef VSIP_IMPL_SETUP_ASSIGN_HPP
+ #define VSIP_IMPL_SETUP_ASSIGN_HPP
+ 
+ /***********************************************************************
+   Included Files
+ ***********************************************************************/
+ 
+ #include <vsip/impl/noncopyable.hpp>
+ #include <vsip/impl/block-traits.hpp>
+ #include <vsip/impl/par-expr.hpp>
+ #include <vsip/impl/par-chain-assign.hpp>
+ #include <vsip/impl/profile.hpp>
+ 
+ 
+ 
+ /***********************************************************************
+   Declarations
+ ***********************************************************************/
+ 
+ namespace vsip
+ {
+ 
+ class Setup_assign
+    : impl::Non_copyable
+ {
+ private:
+   class Holder_base
+   {
+   public:
+     virtual ~Holder_base();
+     virtual void exec() = 0;
+     virtual char* type() = 0;
+   };
+ 
+   class Null_holder : public Holder_base
+   {
+   public:
+     Null_holder() {}
+     ~Null_holder() {}
+     void exec() {}
+     char* type() { return "Null_holder"; }
+   };
+ 
+   template <dimension_type Dim,
+ 	    typename       DstBlock,
+ 	    typename       SrcBlock>
+   class Par_expr_holder : public Holder_base
+   {
+     typedef typename DstBlock::value_type value1_type;
+     typedef typename SrcBlock::value_type value2_type;
+   public:
+     Par_expr_holder(
+       typename impl::View_of_dim<Dim, value1_type, DstBlock>::type       dst,
+       typename impl::View_of_dim<Dim, value2_type, SrcBlock>::const_type src)
+       : par_expr_(dst, src)
+       {}
+ 
+     ~Par_expr_holder()
+       {}
+ 
+     void exec()
+     {
+       impl::profile::Scope_event ev("Par_expr_holder");
+       par_expr_();
+     }
+ 
+     char* type() { return "Par_expr_holder"; }
+ 
+ 
+     // Member data
+   private:
+     vsip::impl::Par_expr<Dim, DstBlock, SrcBlock> par_expr_;
+   };
+ 
+ 
+ 
+   template <dimension_type Dim,
+ 	    typename       DstBlock,
+ 	    typename       SrcBlock>
+   class Par_assign_holder : public Holder_base
+   {
+     typedef typename DstBlock::value_type value1_type;
+     typedef typename SrcBlock::value_type value2_type;
+   public:
+     Par_assign_holder(
+       typename impl::View_of_dim<Dim, value1_type, DstBlock>::type       dst,
+       typename impl::View_of_dim<Dim, value2_type, SrcBlock>::const_type src)
+       : par_assign_(dst, src)
+       {}
+ 
+     ~Par_assign_holder()
+       {}
+ 
+     void exec()
+     {
+       impl::profile::Scope_event ev("Par_assign_holder");
+       par_assign_();
+     }
+ 
+     char* type() { return "Par_assign_holder"; }
+ 
+ 
+     // Member data
+   private:
+     vsip::impl::Chained_parallel_assign<Dim,
+ 	value1_type, value2_type, DstBlock, SrcBlock> par_assign_;
+   };
+ 
+ 
+ 
+   template <dimension_type Dim,
+ 	    typename       DstBlock,
+ 	    typename       SrcBlock>
+   class Simple_par_expr_holder : public Holder_base
+   {
+     typedef typename DstBlock::value_type value1_type;
+     typedef typename SrcBlock::value_type value2_type;
+   public:
+     Simple_par_expr_holder(
+       typename impl::View_of_dim<Dim, value1_type, DstBlock>::type       dst,
+       typename impl::View_of_dim<Dim, value2_type, SrcBlock>::const_type src)
+       : dst_(dst), src_(src)
+       {}
+ 
+     ~Simple_par_expr_holder()
+       {}
+ 
+     void exec()
+     {
+       impl::profile::Scope_event ev("Simple_par_expr_holder");
+       par_expr_simple(dst_, src_);
+     }
+ 
+     char* type() { return "Simple_par_expr_holder"; }
+ 
+     // Member data
+   private:
+     typename impl::View_of_dim<Dim, value1_type, DstBlock>::type       dst_;
+     typename impl::View_of_dim<Dim, value2_type, SrcBlock>::const_type src_;
+   };
+ 
+ 
+ 
+   template <dimension_type Dim,
+ 	    typename       DstBlock,
+ 	    typename       SrcBlock>
+   class Ser_expr_holder : public Holder_base
+   {
+     typedef typename DstBlock::value_type value1_type;
+     typedef typename SrcBlock::value_type value2_type;
+   public:
+     Ser_expr_holder(
+       typename impl::View_of_dim<Dim, value1_type, DstBlock>::type       dst,
+       typename impl::View_of_dim<Dim, value2_type, SrcBlock>::const_type src)
+       : dst_(dst), src_(src)
+       {}
+ 
+     ~Ser_expr_holder()
+       {}
+ 
+     void exec()
+     {
+       impl::profile::Scope_event ev("Ser_expr_holder");
+       dst_ = src_;
+     }
+ 
+     char* type() { return "Ser_expr_holder"; }
+ 
+ 
+     // Member data
+   private:
+     typename impl::View_of_dim<Dim, value1_type, DstBlock>::type       dst_;
+     typename impl::View_of_dim<Dim, value2_type, SrcBlock>::const_type src_;
+   };
+ 
+   // Constructors.
+ public:
+    template <template <typename, typename> class View1,
+ 	     template <typename, typename> class View2,
+ 	     typename                            T1,
+ 	     typename                            Block1,
+ 	     typename                            T2,
+ 	     typename                            Block2>
+   Setup_assign(
+     View1<T1, Block1> dst,
+     View2<T2, Block2> src)
+   {
+     dimension_type const dim = View1<T1, Block1>::dim;
+ 
+     typedef typename Block1::map_type map1_type;
+     typedef typename Block2::map_type map2_type;
+ 
+     bool const is_local      = !map1_type::impl_global_only &&
+                                !map2_type::impl_global_only;
+     bool const is_rhs_simple = impl::Is_simple_distributed_block<Block2>::value;
+ 
+     if (is_local)
+       holder_ = new Ser_expr_holder<View1<T1, Block1>::dim, Block1, Block2>
+ 	                           (dst, src);
+     else if (impl::Is_par_same_map<map1_type, Block2>::value(dst.block().map(),
+ 						       src.block()))
+     {
+       if (dst.block().map().impl_subblock() != no_subblock)
+       {
+ 	typedef typename impl::Distributed_local_block<Block1>::type dst_lblock_type;
+ 	typedef typename impl::Distributed_local_block<Block2>::type src_lblock_type;
+ 
+ 	View1<T1, dst_lblock_type> dst_lview = get_local_view(dst);
+ 	View2<T2, src_lblock_type> src_lview = get_local_view(src);
+ 
+ 	holder_ = new Ser_expr_holder<dim, dst_lblock_type, src_lblock_type>
+ 	  (dst_lview, src_lview);
+       }
+       else
+ 	holder_ = new Null_holder();
+     }
+     else if (is_rhs_simple)
+     {
+       holder_ = new Par_assign_holder<View1<T1, Block1>::dim, Block1, Block2>
+ 	                           (dst, src);
+     }
+     else
+       holder_ = new Par_expr_holder<View1<T1, Block1>::dim, Block1, Block2>
+ 	                           (dst, src);
+   }
+ 
+   ~Setup_assign() 
+   { delete holder_; }
+ 
+   void operator()()
+   { 
+     impl::profile::Scope_event ev("Setup_assign");
+     holder_->exec();
+   }
+ 
+   char* impl_type()
+   {
+     return holder_->type();
+   }
+   
+ // Member Data
+ private:
+   Holder_base* holder_;
+ 
+ };
+ 
+ Setup_assign::Holder_base::~Holder_base()
+ {}
+ 
+ } // namespace vsip
+ 
+ #endif // VSIP_IMPL_SETUP_ASSIGN_HPP
Index: tests/distributed-user-storage.cpp
===================================================================
RCS file: tests/distributed-user-storage.cpp
diff -N tests/distributed-user-storage.cpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- tests/distributed-user-storage.cpp	16 Sep 2005 19:44:13 -0000
***************
*** 0 ****
--- 1,198 ----
+ /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+ 
+ /** @file    tests/distributed-user-storage.cpp
+     @author  Jules Bergmann
+     @date    2005-09-14
+     @brief   VSIPL++ Library: Unit tests for distributed blocks user-storage.
+ */
+ 
+ /***********************************************************************
+   Included Files
+ ***********************************************************************/
+ 
+ #include <iostream>
+ #include <cassert>
+ 
+ #include <vsip/initfin.hpp>
+ #include <vsip/support.hpp>
+ #include <vsip/dense.hpp>
+ #include <vsip/map.hpp>
+ #include <vsip/impl/par-util.hpp>
+ #include <vsip/impl/setup-assign.hpp>
+ 
+ #include "test.hpp"
+ #include "util.hpp"
+ 
+ using namespace std;
+ using namespace vsip;
+ 
+ using vsip::impl::View_of_dim;
+ 
+ 
+ 
+ /***********************************************************************
+   Definitions
+ ***********************************************************************/
+ 
+ // test1: 
+ //  - Create distribute user-storage block with NULL ptr,
+ //  - Bind buffers (using get_subblock_dom to determine size).
+ //  -
+ 
+ template <typename       T,
+ 	  dimension_type Dim,
+ 	  typename       MapT>
+ void
+ test1(
+   Domain<Dim> const& dom,
+   MapT               dist_map,
+   bool               use_sa)
+ {
+   typedef Map<Block_dist, Block_dist> root_map_t;
+ 
+   typedef typename impl::Row_major<Dim>::type order_type;
+ 
+   typedef Dense<Dim, T, order_type, root_map_t> root_block_t;
+   typedef Dense<Dim, T, order_type, MapT>       dist_block_t;
+ 
+   typedef typename View_of_dim<Dim, T, root_block_t>::type root_view_t;
+   typedef typename View_of_dim<Dim, T, dist_block_t>::type dist_view_t;
+ 
+ 
+   root_map_t  root_map(Block_dist(1), Block_dist(1));
+ 
+   // root: root view.
+   root_view_t root(create_view<root_view_t>(dom, T(0), root_map));
+ 
+   // dist: distributed view, w/user-storage.
+   dist_view_t dist(create_view<dist_view_t>(dom, static_cast<T*>(0),dist_map));
+ 
+   Setup_assign root_dist(root, dist);
+   Setup_assign dist_root(dist, root);
+ 
+   // Initially, dist is not admitted.
+   assert(dist.block().admitted() == false);
+ 
+   // Find out how big the local subdomain is.
+   Domain<Dim> subdom = my_subblock_dom(dist);
+ 
+   // cout << "size: " << subdom.size() << endl;
+ 
+   length_type loop = 5;
+   T** data = new T*[loop];
+ 
+   for (index_type iter=0; iter<loop; ++iter)
+   {
+     // cout << "iter " << iter << endl;
+ 
+     // allocate data that this processor owns.
+     data[iter] = 0;
+     if (subdom.size() > 0)
+       data[iter] = new T[subdom.size()];
+ 
+     dist.block().rebind(data[iter]);
+ 
+     // Put some data in buffer.
+     for (index_type p=0; p<my_patches(dist); ++p)
+     {
+       Domain<Dim> l_dom = my_local_dom(dist, p);
+       Domain<Dim> g_dom = my_global_dom(dist, p);
+ 
+       for (index_type i=0; i<l_dom[0].size(); ++i)
+       {
+ 	index_type li = l_dom.impl_nth(i);
+ 	index_type gi = g_dom.impl_nth(i);
+ 
+ 	// cout << "  data[" << li << "] = " << T(iter*gi) << endl;
+ 
+ 	data[iter][li] = T(iter*gi);
+       }
+     }
+ 
+     // admit the block
+     dist.block().admit(true);
+     assert(dist.block().admitted() == true);
+ 
+     // assign to root
+     if (use_sa)
+       root_dist();
+     else
+       root = dist;
+ 
+     // On the root processor ...
+     if (root_map.impl_rank() == 0)
+     {
+       typename root_view_t::local_type l_root = get_local_view(root);
+ 
+       // ... check that root is correct.
+       for (index_type i=0; i<l_root.size(); ++i)
+ 	assert(equal(l_root(i), T(iter*i)));
+ 
+       // ... set values for the round trip
+       for (index_type i=0; i<l_root.size(); ++i)
+ 	l_root(i) = T(iter*i+1);
+     }
+ 
+     // assign back to dist
+     if (use_sa)
+       dist_root();
+     else
+       dist = root;
+ 
+     // release the block
+     dist.block().release(true);
+     assert(dist.block().admitted() == false);
+ 
+     // Check the data in buffer.
+     for (index_type p=0; p<my_patches(dist); ++p)
+     {
+       Domain<Dim> l_dom = my_local_dom(dist, p);
+       Domain<Dim> g_dom = my_global_dom(dist, p);
+       
+       for (index_type i=0; i<l_dom[0].size(); ++i)
+       {
+ 	index_type li = l_dom.impl_nth(i);
+ 	index_type gi = g_dom.impl_nth(i);
+ 	
+ 	assert(equal(data[iter][li], T(iter*gi+1)));
+       }
+     }
+   }
+ 
+   for (index_type iter=0; iter<loop; ++iter)
+     if (data[iter]) delete[] data[iter];
+   delete[] data;
+ }
+ 
+ 
+ 
+ 
+ int
+ main(int argc, char** argv)
+ {
+   vsipl init(argc, argv);
+ 
+ #if 0
+   // Enable this section for easier debugging.
+   impl::Communicator comm = impl::default_communicator();
+   pid_t pid = getpid();
+ 
+   cout << "rank: "   << comm.rank()
+        << "  size: " << comm.size()
+        << "  pid: "  << pid
+        << endl;
+ 
+   // Stop each process, allow debugger to be attached.
+   if (comm.rank() == 0) fgetc(stdin);
+   comm.barrier();
+   cout << "start\n";
+ #endif
+ 
+   processor_type np = num_processors();
+ 
+   Map<Block_dist>  map1 = Map<Block_dist>(Block_dist(np));
+   Map<Cyclic_dist> map2 = Map<Cyclic_dist>(Cyclic_dist(np));
+ 
+   test1<float>(Domain<1>(10), map1, true);
+   test1<float>(Domain<1>(10), map2, true);
+ }
Index: tests/util.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/util.hpp,v
retrieving revision 1.2
diff -c -p -r1.2 util.hpp
*** tests/util.hpp	12 Jul 2005 11:58:06 -0000	1.2
--- tests/util.hpp	16 Sep 2005 19:44:13 -0000
*************** create_view(
*** 55,60 ****
--- 55,80 ----
  template <typename View,
  	  typename Map>
  inline View
+ create_view(
+   vsip::Domain<1> const&      dom,
+   typename View::value_type * ptr,
+   Map const&                  map)
+ {
+   typedef typename View::block_type block_type;
+ 
+   block_type* block = new block_type(dom, ptr, map);
+   View view(*block);
+   block->decrement_count();
+   return view;
+ }
+ 
+ 
+ 
+ // Utility function to generalize creation of a view from a domain.
+ 
+ template <typename View,
+ 	  typename Map>
+ inline View
  create_view(vsip::Domain<2> const& dom, Map const& map)
  {
    return View(dom[0].length(), dom[1].length(), map);
