Index: src/vsip/math.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/math.hpp,v
retrieving revision 1.11
diff -c -p -r1.11 math.hpp
*** src/vsip/math.hpp	19 Sep 2005 21:06:46 -0000	1.11
--- src/vsip/math.hpp	23 Sep 2005 20:58:09 -0000
***************
*** 30,35 ****
--- 30,36 ----
  #include <vsip/impl/reductions-idx.hpp>
  #include <vsip/impl/matvec.hpp>
  #include <vsip/impl/matvec-prod.hpp>
+ #include <vsip/impl/vmmul.hpp>
  
  
  
Index: src/vsip/impl/vmmul.hpp
===================================================================
RCS file: src/vsip/impl/vmmul.hpp
diff -N src/vsip/impl/vmmul.hpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- src/vsip/impl/vmmul.hpp	23 Sep 2005 20:58:09 -0000
***************
*** 0 ****
--- 1,167 ----
+ /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+ 
+ /** @file    vsip/impl/vmmul.hpp
+     @author  Jules Bergmann
+     @date    2005-08-15
+     @brief   VSIPL++ Library: vector-matrix multiply
+ 
+ */
+ 
+ #ifndef VSIP_IMPL_VMMUL_HPP
+ #define VSIP_IMPL_VMMUL_HPP
+ 
+ /***********************************************************************
+   Included Files
+ ***********************************************************************/
+ 
+ #include <vsip/impl/block-traits.hpp>
+ #include <vsip/vector.hpp>
+ #include <vsip/matrix.hpp>
+ #include <vsip/impl/promote.hpp>
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
+ template <dimension_type Dim>
+ class Vmmul_class;
+ 
+ template <>
+ struct Vmmul_class<0>
+ {
+   template <typename T0,
+ 	     typename T1,
+ 	     typename T2,
+ 	     typename Block0,
+ 	     typename Block1,
+ 	     typename Block2>
+   static void exec(
+     const_Vector<T0, Block0> v,
+     const_Matrix<T1, Block1> m,
+     Matrix<T2, Block2>       res,
+     row2_type)
+   {
+     assert(v.size() == m.size(1));
+ 
+     // multiply rows of m by v (row-major)
+     for (index_type r=0; r<m.size(0); ++r)
+       res.row(r) = v * m.row(r);
+   }
+ 
+   template <typename T0,
+ 	     typename T1,
+ 	     typename T2,
+ 	     typename Block0,
+ 	     typename Block1,
+ 	     typename Block2>
+   static void exec(
+     const_Vector<T0, Block0> v,
+     const_Matrix<T1, Block1> m,
+     Matrix<T2, Block2>       res,
+     col2_type)
+   {
+     assert(v.size() == m.size(1));
+ 
+     // multiply rows of m by v (col-major)
+     for (index_type c=0; c<m.size(1); ++c)
+       res.col(c) = v.get(c) * m.col(c);
+   }
+ };
+ 
+ 
+ 
+ template <>
+ struct Vmmul_class<1>
+ {
+   template <typename T0,
+ 	    typename T1,
+ 	    typename T2,
+ 	    typename Block0,
+ 	    typename Block1,
+ 	    typename Block2>
+   static void exec(
+     const_Vector<T0, Block0> v,
+     const_Matrix<T1, Block1> m,
+     Matrix<T2, Block2>       res,
+     col2_type)
+   {
+     assert(v.size() == m.size(0));
+ 
+     // multiply cols of m by v (col-major)
+     for (index_type c=0; c<m.size(1); ++c)
+       res.col(c) = v * m.col(c);
+   }
+ 
+   template <typename T0,
+ 	    typename T1,
+ 	    typename T2,
+ 	    typename Block0,
+ 	    typename Block1,
+ 	    typename Block2>
+   static void exec(
+     const_Vector<T0, Block0> v,
+     const_Matrix<T1, Block1> m,
+     Matrix<T2, Block2>       res,
+     row2_type)
+   {
+     assert(v.size() == m.size(0));
+ 
+     // multiply cols of m by v (col-major)
+     for (index_type r=0; r<m.size(0); ++r)
+       res.row(r) = v.get(r) * m.row(r);
+   }
+ };
+ 
+ 
+ 
+ /// Traits class to determines return type for vmmul.
+ 
+ template <typename T0,
+ 	  typename T1,
+ 	  typename Block1>
+ struct Vmmul_traits
+ {
+   typedef typename vsip::Promotion<T0, T1>::type    value_type;
+   typedef typename Block_layout<Block1>::order_type order_type;
+   typedef Dense<2, value_type, order_type>          block_type;
+   typedef Matrix<value_type, block_type>            view_type;
+ };
+ 
+ } // namespace vsip::impl
+ 
+ 
+ 
+ /// Vector-matrix element-wise multiplication
+ 
+ template <dimension_type Dim,
+ 	  typename       T0,
+ 	  typename       T1,
+ 	  typename       Block0,
+ 	  typename       Block1>
+ typename vsip::impl::Vmmul_traits<T0, T1, Block1>::view_type
+ vmmul(
+   const_Vector<T0, Block0> v,
+   const_Matrix<T1, Block1> m)
+ VSIP_NOTHROW
+ {
+   typedef vsip::impl::Vmmul_traits<T0, T1, Block1> traits;
+   typedef typename traits::order_type order_type;
+ 
+   typename traits::view_type res(m.size(0), m.size(1));
+ 
+   vsip::impl::Vmmul_class<Dim>::exec(v, m, res, order_type());
+ 
+   return res;
+ }
+ 
+ } // namespace vsip
+ 
+ #endif // VSIP_IMPL_VMMUL_HPP
Index: tests/vmmul.cpp
===================================================================
RCS file: tests/vmmul.cpp
diff -N tests/vmmul.cpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- tests/vmmul.cpp	23 Sep 2005 20:58:09 -0000
***************
*** 0 ****
--- 1,81 ----
+ /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+ 
+ /** @file    tests/vmmul.cpp
+     @author  Jules Bergmann
+     @date    2005-08-15
+     @brief   VSIPL++ Library: Unit tests for vector-matrix multiply.
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
+ #include <vsip/impl/vmmul.hpp>
+ 
+ #include "test.hpp"
+ #include "plainblock.hpp"
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
+ template <dimension_type Dim,
+ 	  typename       OrderT,
+ 	  typename       T>
+ void
+ test_vmmul(
+   length_type rows,
+   length_type cols)
+ {
+   Matrix<T, Dense<2, T, OrderT> > m(rows, cols);
+   Vector<T> v(Dim == 0 ? cols : rows);
+ 
+   for (index_type r=0; r<rows; ++r)
+     for (index_type c=0; c<cols; ++c)
+       m(r, c) = T(r*cols+c);
+ 
+   v = ramp(T(), T(1), v.size());
+ 
+   Matrix<T> res = vmmul<Dim>(v, m);
+   
+   for (index_type r=0; r<rows; ++r)
+     for (index_type c=0; c<cols; ++c)
+       if (Dim == 0)
+ 	assert(equal(res(r, c), T(c * (r*cols+c))));
+       else
+ 	assert(equal(res(r, c), T(r * (r*cols+c))));
+ }
+ 
+ 
+ 
+ void
+ vmmul_cases()
+ {
+   test_vmmul<0, row2_type, float>(5, 7);
+   test_vmmul<0, col2_type, float>(5, 7);
+   test_vmmul<1, row2_type, float>(5, 7);
+   test_vmmul<1, col2_type, float>(5, 7);
+ }
+ 
+ 
+ 
+ int
+ main()
+ {
+   vsipl init;
+ 
+   vmmul_cases();
+ }
