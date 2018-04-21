Index: tests/ref-impl/ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vsipl++/implementation/tests/ChangeLog,v
retrieving revision 1.21
diff -c -p -r1.21 ChangeLog
*** tests/ref-impl/ChangeLog	15 Sep 2005 14:49:07 -0000	1.21
--- tests/ref-impl/ChangeLog	19 Sep 2005 02:11:45 -0000
***************
*** 1,3 ****
--- 1,8 ----
+ 2005-09-18  Jules Bergmann  <jules@codesourcery.com>
+ 
+ 	* tests/ref-impl/view-math.cpp: Replace call to C-VSIPL
+ 	  vsip_hypot_f with local function.
+ 
  2005-09-15  Jules Bergmann  <jules@codesourcery.com>
  
  	* tests/ref-impl/view-math.cpp: Fix bug with land test (should use
Index: tests/ref-impl/view-math.cpp
===================================================================
RCS file: /home/cvs/Repository/vsipl++/implementation/tests/view-math.cpp,v
retrieving revision 1.5
diff -c -p -r1.5 view-math.cpp
*** tests/ref-impl/view-math.cpp	15 Sep 2005 14:49:07 -0000	1.5
--- tests/ref-impl/view-math.cpp	19 Sep 2005 02:11:45 -0000
*************** using namespace vsip;
*** 49,54 ****
--- 49,61 ----
    Function Definitions
  ***********************************************************************/
  
+ template <typename T>
+ T
+ test_hypot(T x, T y)
+ {
+   return std::sqrt(x * x + y * y);
+ }
+ 
  // -------------------------------------------------------------------- //
  // test vector combinations
  template <typename					T,
*************** struct tc_hypot
*** 832,839 ****
        storR.view = hypot(stor1.view, stor2.view);
  
        insist(equal(get_origin(storR.view),
! 		   vsip_hypot_f(TestRig<T1>::test_value1(),
! 				TestRig<T2>::test_value2())));
     }
  };
  
--- 839,846 ----
        storR.view = hypot(stor1.view, stor2.view);
  
        insist(equal(get_origin(storR.view),
! 		   test_hypot(TestRig<T1>::test_value1(),
! 			      TestRig<T2>::test_value2())));
     }
  };
  
