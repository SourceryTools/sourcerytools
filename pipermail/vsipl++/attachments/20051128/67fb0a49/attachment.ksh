Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.313
diff -c -p -r1.313 ChangeLog
*** ChangeLog	22 Nov 2005 22:43:46 -0000	1.313
--- ChangeLog	28 Nov 2005 16:05:59 -0000
***************
*** 1,3 ****
--- 1,10 ----
+ 2005-11-28 Jules Bergmann  <jules@codesourcery.com>
+ 
+ 	* src/vsip/impl/extdata.hpp (is_direct_ok): Merge if statements to
+ 	  avoid GHS warnings about unreachable statements.
+ 	* configure.ac: Set configure's internal variables for object and
+ 	  executable extenions.
+ 	
  2005-11-22  Stefan Seefeld  <stefan@codesourcery.com>
  
  	* src/vsip/complex.hpp: Fix for ghs.
Index: configure.ac
===================================================================
RCS file: /home/cvs/Repository/vpp/configure.ac,v
retrieving revision 1.49
diff -c -p -r1.49 configure.ac
*** configure.ac	14 Nov 2005 15:00:42 -0000	1.49
--- configure.ac	28 Nov 2005 16:06:00 -0000
*************** AC_CANONICAL_HOST
*** 154,162 ****
--- 154,165 ----
  AC_PROG_CXX
  if test "x$obj_ext" != "x"; then
    OBJEXT="$obj_ext"
+   ac_cv_objext="$obj_ext"
  fi
  if test "x$exe_ext" != "x"; then
    EXEEXT="$exe_ext"
+   ac_exeext=".$exe_ext"
+   ac_cv_exeext=".$exe_ext"
  fi
  if test "$CXX" == "cxppc"; then
    CXXDEP="$CXX -Make"
Index: src/vsip/impl/extdata.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/extdata.hpp,v
retrieving revision 1.15
diff -c -p -r1.15 extdata.hpp
*** src/vsip/impl/extdata.hpp	28 Sep 2005 19:07:27 -0000	1.15
--- src/vsip/impl/extdata.hpp	28 Nov 2005 16:06:00 -0000
*************** is_direct_ok(BlockT const& block)
*** 299,306 ****
    if (!Type_equal<complex_type, typename LP::complex_type>::value ||
        !Type_equal<order_type, typename LP::order_type>::value)
      return false;
! 
!   if (Type_equal<typename LP::pack_type, Stride_unit>::value)
    {
      if (LP::dim == 1)
        return block.impl_stride(1, 0) == 1;
--- 299,305 ----
    if (!Type_equal<complex_type, typename LP::complex_type>::value ||
        !Type_equal<order_type, typename LP::order_type>::value)
      return false;
!   else if (Type_equal<typename LP::pack_type, Stride_unit>::value)
    {
      if (LP::dim == 1)
        return block.impl_stride(1, 0) == 1;
*************** is_direct_ok(BlockT const& block)
*** 351,360 ****
  	(block.impl_stride(3, dim1) * sizeof(value_type)) % align == 0 &&
  	(block.impl_stride(3, dim0) * sizeof(value_type)) % align == 0;
    }
!   else if (Type_equal<typename LP::pack_type, Stride_unknown>::value)
      return true;
! 
!   assert(0);
  }
  
  
--- 350,360 ----
  	(block.impl_stride(3, dim1) * sizeof(value_type)) % align == 0 &&
  	(block.impl_stride(3, dim0) * sizeof(value_type)) % align == 0;
    }
!   else /* if (Type_equal<typename LP::pack_type, Stride_unknown>::value) */
!   {
!     assert((Type_equal<typename LP::pack_type, Stride_unknown>::value));
      return true;
!   }
  }
  
  
