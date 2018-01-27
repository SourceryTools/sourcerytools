Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.303
diff -c -p -r1.303 ChangeLog
*** ChangeLog	11 Nov 2005 00:07:59 -0000	1.303
--- ChangeLog	11 Nov 2005 13:50:40 -0000
***************
*** 1,3 ****
--- 1,14 ----
+ 2005-11-11 Jules Bergmann  <jules@codesourcery.com>
+ 
+ 	* configure.ac (VSIP_IMPL_FIX_MISSING_ABS): New define, set if
+ 	  missing std::abs overloads for float and double.
+ 	* src/vsip/impl/fns_scalar.hpp (mag, magsq): Use abs_detail::abs
+ 	  instead of std::abs.  Set abs_detail::abs based on
+ 	  VSIP_IMPL_FIX_MISSING_ABS.
+ 	* src/vsip/impl/general_dispatch.hpp: When dispatch fail, throw
+ 	  exception rather than assert.
+ 	* tests/test.hpp: Use vsip::mag instead of std::abs.
+ 	
  2005-11-10  Don McCoy  <don@codesourcery.com>
  
  	* tests/matvec-prod.cpp: Re-arranged tests to avoid running tests
Index: configure.ac
===================================================================
RCS file: /home/cvs/Repository/vpp/configure.ac,v
retrieving revision 1.48
diff -c -p -r1.48 configure.ac
*** configure.ac	10 Nov 2005 05:44:02 -0000	1.48
--- configure.ac	11 Nov 2005 13:50:40 -0000
*************** int main(int, char **)
*** 208,213 ****
--- 208,261 ----
  [AC_MSG_RESULT(yes)],
  [AC_MSG_ERROR([Incompatible std::complex types detected!])])
  
+ 
+ #
+ # Check for the std::abs(float) and std::abs(double) overloads.
+ #
+ # GreenHills <cmath> defines ::abs(float) and ::abs(double), but does
+ # not place them into the std namespace when targeting mercury (when
+ # _MC_EXEC is defined).
+ 
+ # First check if std::abs handles float and double:
+ AC_MSG_CHECKING([for std::abs(float) and std::abs(double).])
+ have_abs_float="no"
+ AC_COMPILE_IFELSE([
+ #include <cmath>
+ 
+ int main(int, char **)
+ {
+   float f1 = 1.f;
+   f1 = std::abs(f1); 
+   double d1 = 1.0;
+   d1 = std::abs(d1); 
+ }
+ ],
+ [have_abs_float="std"
+  AC_MSG_RESULT(yes)],
+ [AC_MSG_RESULT([missing!])])
+ 
+ if test "$have_abs_float" = "no"; then
+   # next check for them in ::
+   AC_MSG_CHECKING([for ::abs(float) and ::abs(double).])
+   AC_COMPILE_IFELSE([
+ #include <cmath>
+ 
+ int main(int, char **)
+ {
+   float f1 = 1.f;
+   f1 = ::abs(f1); 
+   double d1 = 1.0;
+   d1 = ::abs(d1); 
+ }
+ ],
+   [have_abs_float="global"
+    AC_MSG_RESULT(yes)],
+   [AC_MSG_ERROR([missing!])])
+   AC_DEFINE_UNQUOTED(VSIP_IMPL_FIX_MISSING_ABS, 1,
+       [Define to use both ::abs and std::abs for vsip::mag.])
+ fi
+ 
+ 
  #
  # Check for the exp10 function.  
  #
Index: src/vsip/impl/fns_scalar.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/fns_scalar.hpp,v
retrieving revision 1.13
diff -c -p -r1.13 fns_scalar.hpp
*** src/vsip/impl/fns_scalar.hpp	10 Nov 2005 05:44:02 -0000	1.13
--- src/vsip/impl/fns_scalar.hpp	11 Nov 2005 13:50:40 -0000
*************** template <typename T>
*** 110,124 ****
  inline T 
  lnot(T t) VSIP_NOTHROW { return !t;}
  
  template <typename T>
  inline typename impl::Scalar_of<T>::type 
! mag(T t) VSIP_NOTHROW { return std::abs(t);}
  
  template <typename T>
  inline typename impl::Scalar_of<T>::type 
  magsq(T t) VSIP_NOTHROW 
  {
!   typename impl::Scalar_of<T>::type tmp(std::abs(t)); 
    return tmp*tmp;
  }
  
--- 110,137 ----
  inline T 
  lnot(T t) VSIP_NOTHROW { return !t;}
  
+ namespace abs_detail
+ {
+ 
+ // GreenHills <cmath> defines ::abs(float) and ::abs(double), but does
+ // not place them into the std namespace when targeting mercury (when
+ // _MC_EXEC is defined).
+ 
+ #if VSIP_IMPL_FIX_MISSING_ABS
+ using ::abs;
+ #endif
+ using std::abs;
+ } // namespace abs_detail
+ 
  template <typename T>
  inline typename impl::Scalar_of<T>::type 
! mag(T t) VSIP_NOTHROW { return abs_detail::abs(t);}
  
  template <typename T>
  inline typename impl::Scalar_of<T>::type 
  magsq(T t) VSIP_NOTHROW 
  {
!   typename impl::Scalar_of<T>::type tmp(abs_detail::abs(t)); 
    return tmp*tmp;
  }
  
Index: src/vsip/impl/general_dispatch.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/general_dispatch.hpp,v
retrieving revision 1.2
diff -c -p -r1.2 general_dispatch.hpp
*** src/vsip/impl/general_dispatch.hpp	11 Nov 2005 00:08:21 -0000	1.2
--- src/vsip/impl/general_dispatch.hpp	11 Nov 2005 13:50:41 -0000
*************** struct General_dispatch<OpTag, Return_sc
*** 177,183 ****
      if (EvalExpr::rt_valid(op1, op2))
        return EvalExpr::exec(op1, op2);
      else
!       assert(0);
    }
  };
  
--- 177,183 ----
      if (EvalExpr::rt_valid(op1, op2))
        return EvalExpr::exec(op1, op2);
      else
!       VSIP_IMPL_THROW(impl::unimplemented("General_dispatch failed"));
    }
  };
  
*************** struct General_dispatch<OpTag, DstBlock,
*** 341,347 ****
      if (EvalExpr::rt_valid(res, param1, op1, op2, param2))
        EvalExpr::exec(res, param1, op1, op2, param2);
      else
!       assert(0);
    }
  };
  
--- 341,347 ----
      if (EvalExpr::rt_valid(res, param1, op1, op2, param2))
        EvalExpr::exec(res, param1, op1, op2, param2);
      else
!       VSIP_IMPL_THROW(impl::unimplemented("General_dispatch failed"));
    }
  };
  
Index: tests/test.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/test.hpp,v
retrieving revision 1.7
diff -c -p -r1.7 test.hpp
*** tests/test.hpp	27 Sep 2005 22:44:40 -0000	1.7
--- tests/test.hpp	11 Nov 2005 13:50:41 -0000
*************** almost_equal(
*** 40,54 ****
    T	rel_epsilon = 1e-4,
    T	abs_epsilon = 1e-6)
  {
!   if (std::abs(A - B) < abs_epsilon)
      return true;
  
    T relative_error;
  
!   if (std::abs(B) > std::abs(A))
!     relative_error = std::abs((A - B) / B);
    else
!     relative_error = std::abs((B - A) / A);
  
    return (relative_error <= rel_epsilon);
  }
--- 40,54 ----
    T	rel_epsilon = 1e-4,
    T	abs_epsilon = 1e-6)
  {
!   if (vsip::mag(A - B) < abs_epsilon)
      return true;
  
    T relative_error;
  
!   if (vsip::mag(B) > vsip::mag(A))
!     relative_error = vsip::mag((A - B) / B);
    else
!     relative_error = vsip::mag((B - A) / A);
  
    return (relative_error <= rel_epsilon);
  }
*************** almost_equal(
*** 63,77 ****
    T	rel_epsilon = 1e-4,
    T	abs_epsilon = 1e-6)
  {
!   if (std::abs(A - B) < abs_epsilon)
      return true;
  
    T relative_error;
  
!   if (std::abs(B) > std::abs(A))
!     relative_error = std::abs((A - B) / B);
    else
!     relative_error = std::abs((B - A) / A);
  
    return (relative_error <= rel_epsilon);
  }
--- 63,77 ----
    T	rel_epsilon = 1e-4,
    T	abs_epsilon = 1e-6)
  {
!   if (vsip::mag(A - B) < abs_epsilon)
      return true;
  
    T relative_error;
  
!   if (vsip::mag(B) > vsip::mag(A))
!     relative_error = vsip::mag((A - B) / B);
    else
!     relative_error = vsip::mag((B - A) / A);
  
    return (relative_error <= rel_epsilon);
  }
