Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.273
diff -c -p -r1.273 ChangeLog
*** ChangeLog	26 Sep 2005 20:11:05 -0000	1.273
--- ChangeLog	26 Sep 2005 20:22:36 -0000
***************
*** 1,5 ****
--- 1,13 ----
  2005-09-26  Jules Bergmann  <jules@codesourcery.com>
  
+ 	* src/vsip/math.hpp: Include expr_generator_block.hpp
+ 	* src/vsip/selgen.hpp: New file, implement ramp.
+ 	* src/vsip/impl/expr_generator_block.hpp: New file, generator
+ 	  expression block.
+ 	* tests/selgen-ramp.cpp: New file, tests for ramp().
+ 
+ 2005-09-26  Jules Bergmann  <jules@codesourcery.com>
+ 
  	* src/vsip/impl/vmmul.hpp: New file, implements vmmul.
  	* src/vsip/math.hpp: Inlcude vmmul.hpp.
  	* tests/vmmul.cpp: New file, unit tests for vmmul.
Index: src/vsip/math.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/math.hpp,v
retrieving revision 1.12
diff -c -p -r1.12 math.hpp
*** src/vsip/math.hpp	26 Sep 2005 20:11:05 -0000	1.12
--- src/vsip/math.hpp	26 Sep 2005 20:22:36 -0000
***************
*** 18,23 ****
--- 18,24 ----
  #include <vsip/impl/promote.hpp>
  #include <vsip/impl/math-enum.hpp>
  #include <vsip/impl/fns_scalar.hpp>
+ #include <vsip/impl/expr_generator_block.hpp>
  #include <vsip/impl/expr_unary_block.hpp>
  #include <vsip/impl/expr_binary_block.hpp>
  #include <vsip/impl/expr_scalar_block.hpp>
Index: src/vsip/selgen.hpp
===================================================================
RCS file: src/vsip/selgen.hpp
diff -N src/vsip/selgen.hpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- src/vsip/selgen.hpp	26 Sep 2005 20:22:36 -0000
***************
*** 0 ****
--- 1,90 ----
+ /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+ 
+ /** @file    vsip/selgen.hpp
+     @author  Jules Bergmann
+     @date    2005-08-15
+     @brief   VSIPL++ Library: Selection functions.
+ 
+ */
+ 
+ #ifndef VSIP_SELGEN_HPP
+ #define VSIP_SELGEN_HPP
+ 
+ /***********************************************************************
+   Included Files
+ ***********************************************************************/
+ 
+ #include <vsip/impl/block-traits.hpp>
+ #include <vsip/impl/expr_generator_block.hpp>
+ #include <vsip/vector.hpp>
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
+ namespace impl
+ {
+ 
+ /// Generator functor for ramp.
+ 
+ template <typename T>
+ class Ramp_generator
+ {
+   // Typedefs.
+ public:
+   typedef T result_type;
+ 
+   // Constructor.
+ public:
+   Ramp_generator(T a, T b) : a_(a), b_(b) {}
+ 
+ 
+   // Operator
+ public:
+   T operator()(index_type i) const
+   {
+     return a_ + T(i)*b_;
+   }
+ 
+   // Member data.
+ private:
+   T a_;
+   T b_;
+ };
+ 
+ } // namespace vsip::impl
+ 
+ 
+ 
+ /// Generate a linear ramp.
+ 
+ /// Requires
+ ///   LEN to be output vector size (LEN > 0)
+ 
+ template <typename T>
+ const_Vector<T, impl::Generator_expr_block<1, impl::Ramp_generator<T> > const>
+ ramp(
+   T           a,
+   T           b,
+   length_type len)
+ VSIP_NOTHROW
+ {
+   assert(len > 0);
+ 
+   typedef impl::Ramp_generator<T>                             generator_type;
+   typedef impl::Generator_expr_block<1, generator_type> const block_type;
+ 
+   generator_type gen(a, b);
+   block_type     block(impl::Length<1>(len), gen);
+ 
+   return const_Vector<T, block_type>(block);
+ }
+ 
+ } // namespace vsip
+ 
+ #endif // VSIP_SELGEN_HPP
Index: src/vsip/impl/expr_generator_block.hpp
===================================================================
RCS file: src/vsip/impl/expr_generator_block.hpp
diff -N src/vsip/impl/expr_generator_block.hpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- src/vsip/impl/expr_generator_block.hpp	26 Sep 2005 20:22:36 -0000
***************
*** 0 ****
--- 1,275 ----
+ /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+ 
+ /** @file    vsip/impl/expr_generator_block.hpp
+     @author  Jules Bergmann
+     @date    2005-08-15
+     @brief   VSIPL++ Library: "Generator" expression block class templates.
+ */
+ 
+ #ifndef VSIP_IMPL_EXPR_GENERATOR_BLOCK_HPP
+ #define VSIP_IMPL_EXPR_GENERATOR_BLOCK_HPP
+ 
+ /***********************************************************************
+   Included Files
+ ***********************************************************************/
+ 
+ #include <vsip/support.hpp>
+ #include <vsip/impl/block-traits.hpp>
+ #include <vsip/impl/noncopyable.hpp>
+ #include <vsip/impl/length.hpp>
+ #include <vsip/impl/local_map.hpp>
+ 
+ namespace vsip
+ {
+ namespace impl
+ {
+ 
+ /***********************************************************************
+   Declarations
+ ***********************************************************************/
+ 
+ /// Expression template block for Generator expressions.
+ ///
+ /// Requires:
+ ///   DIM to be a dimension with range 0 < D <= VSIP_MAX_DIMENSION
+ ///   GENERATOR to be a functor class with the following members:
+ ///      OPERATOR()() to compute a value based given indices.
+ ///      RESULT_TYPE to be the result type of operator()()
+ 
+ template <dimension_type Dim,
+ 	  typename       Generator>
+ class Generator_expr_block
+   : public Generator,
+     public Non_assignable
+ {
+   // Compile-time values and typedefs.
+ public:
+   static dimension_type const dim = Dim;
+   typedef typename Generator::result_type value_type;
+ 
+   typedef value_type&         reference_type;
+   typedef value_type const&   const_reference_type;
+ #if VSIP_IMPL_GENERATOR_USE_LOCAL_OR_GLOBAL
+   typedef Local_or_global_map<Dim> map_type;
+ #else
+   typedef Local_map           map_type;
+ #endif
+ 
+ 
+   // Constructors.
+ public:
+   Generator_expr_block(Length<Dim> size)
+     : size_(size) {}
+   Generator_expr_block(Length<Dim> size, Generator const& op)
+     : Generator(op), size_(size) {}
+ 
+ 
+   // Accessors.
+ public:
+   length_type size() const VSIP_NOTHROW
+   { return total_size(size_); }
+ 
+   length_type size(dimension_type block_dim, dimension_type d)
+     const VSIP_NOTHROW
+   { assert(block_dim == Dim); return size_[d]; }
+ 
+   void increment_count() const VSIP_NOTHROW {}
+   void decrement_count() const VSIP_NOTHROW {}
+   map_type const& map() const VSIP_NOTHROW { return map_;}
+ 
+   value_type get(index_type i) const;
+   value_type get(index_type i, index_type j) const;
+   value_type get(index_type i, index_type j, index_type k) const;
+ 
+   // copy-constructor: default is OK.
+ 
+   // Member data.
+ private:
+   Length<Dim> size_;
+   map_type    map_;
+ };
+ 
+ 
+ 
+ /// Specialize Is_expr_block for generator expr blocks.
+ 
+ template <dimension_type Dim,
+ 	  typename       Generator>
+ struct Is_expr_block<Generator_expr_block<Dim, Generator> >
+ { static bool const value = true; };
+ 
+ 
+ 
+ /// Specialize View_block_storage to control how views store generator
+ /// expression template blocks.
+ 
+ template <dimension_type Dim,
+ 	  typename       Generator>
+ struct View_block_storage<const Generator_expr_block<Dim, Generator> >
+   : By_value_block_storage<const Generator_expr_block<Dim, Generator> >
+ {};
+ 
+ 
+ 
+ template <dimension_type Dim,
+ 	  typename       Generator>
+ struct View_block_storage<Generator_expr_block<Dim, Generator> >
+ {
+   // No typedef provided.
+ };
+ 
+ 
+ 
+ /***********************************************************************
+   Distributed Traits
+ ***********************************************************************/
+ 
+ // NOTE: Distributed_local_block needs to be defined for const
+ // Generator_expr_block, not regular Generator_expr_block.
+ 
+ template <dimension_type Dim,
+ 	  typename       Generator>
+ struct Distributed_local_block<Generator_expr_block<Dim, Generator> const>
+ {
+   typedef Generator_expr_block<Dim, Generator> const type;
+ };
+ 
+ 
+ 
+ template <dimension_type Dim,
+ 	  typename       Generator>
+ Generator_expr_block<Dim, Generator> const&
+ get_local_block(
+   Generator_expr_block<Dim, Generator> const& block)
+ {
+   return block;
+ }
+ 
+ 
+ 
+ template <dimension_type Dim,
+ 	  typename       Generator>
+ void
+ assert_local(
+   Generator_expr_block<Dim, Generator> const& /*block*/,
+   subblock_type                               /*sb*/)
+ {
+ }
+ 
+ 
+ 
+ template <typename       CombineT,
+ 	  dimension_type Dim,
+ 	  typename       Generator>
+ struct Combine_return_type<CombineT,
+ 			   Generator_expr_block<Dim, Generator> const>
+ {
+ #if 1
+   typedef Generator_expr_block<Dim, Generator> const block_type;
+   typedef typename CombineT::template return_type<block_type>::type
+ 		type;
+   typedef typename CombineT::template tree_type<block_type>::type
+ 		tree_type;
+ #else
+   typedef Generator_expr_block<Dim, Generator> const tree_type;
+   typedef tree_type type;
+ #endif
+ };
+ 
+ 
+ 
+ template <typename       CombineT,
+ 	  dimension_type Dim,
+ 	  typename       Generator>
+ struct Combine_return_type<CombineT, Generator_expr_block<Dim, Generator> >
+ {
+ #if 1
+   typedef Generator_expr_block<Dim, Generator> block_type;
+   typedef typename CombineT::template return_type<block_type>::type
+ 		type;
+   typedef typename CombineT::template tree_type<block_type>::type
+ 		tree_type;
+ #else
+   typedef Generator_expr_block<Dim, Generator> const tree_type;
+   typedef tree_type type;
+ #endif
+ };
+ 
+ 
+ 
+ template <typename       CombineT,
+ 	  dimension_type Dim,
+ 	  typename       Generator>
+ typename Combine_return_type<CombineT,
+ 			     Generator_expr_block<Dim, Generator> const>::type
+ apply_combine(
+   CombineT const&                             combine,
+   Generator_expr_block<Dim, Generator> const& block)
+ {
+ #if 1
+   return combine.apply_const(block);
+ #else
+   typedef typename Combine_return_type<
+     CombineT,
+     Generator_expr_block<Dim, Generator> const>::type
+ 		block_type;
+ 
+   return block;
+ #endif
+ }
+ 
+ 
+ 
+ template <typename       VisitorT,
+ 	  dimension_type Dim,
+ 	  typename       Generator>
+ void
+ apply_leaf(
+   VisitorT const&                             /*visitor*/,
+   Generator_expr_block<Dim, Generator> const& /*block*/)
+ {
+   // No-op
+ }
+ 
+ 
+ // Is_par_same_map primary case works for Generator_expr_block.
+ 
+ 
+ 
+ /***********************************************************************
+   Definitions
+ ***********************************************************************/
+ 
+ template <dimension_type Dim,
+ 	  typename       Generator>
+ inline typename Generator_expr_block<Dim, Generator>::value_type
+ Generator_expr_block<Dim, Generator>::get(index_type i) const
+ {
+   return (*this)(i);
+ }
+ 
+ template <dimension_type Dim,
+ 	  typename       Generator>
+ inline typename Generator_expr_block<Dim, Generator>::value_type
+ Generator_expr_block<Dim, Generator>::get(
+   index_type i,
+   index_type j) const
+ {
+   return (*this)(i, j);
+ }
+ 
+ template <dimension_type Dim,
+ 	  typename       Generator>
+ inline typename Generator_expr_block<Dim, Generator>::value_type
+ Generator_expr_block<Dim, Generator>::get(
+   index_type i,
+   index_type j,
+   index_type k) const
+ {
+   return (*this)(i, j, k);
+ }
+ 
+ } // namespace vsip::impl
+ } // namespace vsip
+ 
+ #endif // VSIP_IMPL_EXPR_GENERATOR_BLOCK_HPP
Index: tests/selgen-ramp.cpp
===================================================================
RCS file: tests/selgen-ramp.cpp
diff -N tests/selgen-ramp.cpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- tests/selgen-ramp.cpp	26 Sep 2005 20:22:36 -0000
***************
*** 0 ****
--- 1,69 ----
+ /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+ 
+ /** @file    tests/selgen-ramp.cpp
+     @author  Jules Bergmann
+     @date    2005-08-15
+     @brief   VSIPL++ Library: Unit tests for ramp.
+ */
+ 
+ /***********************************************************************
+   Included Files
+ ***********************************************************************/
+ 
+ 
+ #include <iostream>
+ #include <cassert>
+ #include <vsip/support.hpp>
+ #include <vsip/initfin.hpp>
+ #include <vsip/vector.hpp>
+ #include <vsip/selgen.hpp>
+ 
+ #include "test.hpp"
+ 
+ using namespace std;
+ using namespace vsip;
+ 
+ 
+ 
+ /***********************************************************************
+   Definitions
+ ***********************************************************************/
+ 
+ template <typename T>
+ void
+ test_ramp(T a, T b, length_type len)
+ {
+   Vector<T> vec = ramp(a, b, len);
+ 
+   for (index_type i=0; i<len; ++i)
+     assert(equal(a + T(i)*b,
+ 		 vec.get(i)));
+ }
+ 
+ 
+ 
+ void
+ ramp_cases()
+ {
+   test_ramp<int>(0,  1, 10);
+   test_ramp<int>(5, -2, 10);
+ 
+   test_ramp<unsigned int>(0, 1, 10);
+   test_ramp<unsigned int>(5, 2, 10);
+ 
+   test_ramp<float>(0.f,   1.f, 10);
+   test_ramp<float>(1.5f, -1.f, 10);
+ 
+   test_ramp<complex<float> >(complex<float>(), complex<float>(1.f, 0.f), 10);
+   test_ramp<complex<float> >(complex<float>(), complex<float>(-1.f, 0.5f), 10);
+ }
+ 
+ 
+ 
+ int
+ main()
+ {
+   vsipl init;
+ 
+   ramp_cases();
+ }
