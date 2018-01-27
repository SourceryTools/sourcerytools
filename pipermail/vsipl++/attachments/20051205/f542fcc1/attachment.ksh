Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.322
diff -c -p -r1.322 ChangeLog
*** ChangeLog	5 Dec 2005 19:46:40 -0000	1.322
--- ChangeLog	5 Dec 2005 20:22:35 -0000
***************
*** 1,5 ****
--- 1,11 ----
  2005-12-05 Jules Bergmann  <jules@codesourcery.com>
  
+ 	* src/vsip/support.hpp: Correct return type in declaration of
+ 	  num_processors().  Move processor_set() declaration to ...
+ 	* src/vsip/parallel.hpp: ... here.
+ 	
+ 2005-12-05 Jules Bergmann  <jules@codesourcery.com>
+ 
  	Fix issue #95
  	* src/vsip/impl/eval-blas.hpp: Perform row-major outer product
  	  without changing input vectors.
Index: src/vsip/parallel.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/parallel.hpp,v
retrieving revision 1.1
diff -c -p -r1.1 parallel.hpp
*** src/vsip/parallel.hpp	26 Sep 2005 20:11:05 -0000	1.1
--- src/vsip/parallel.hpp	5 Dec 2005 20:22:35 -0000
***************
*** 14,20 ****
--- 14,29 ----
    Included Files
  ***********************************************************************/
  
+ #include <vsip/vector.hpp>
  #include <vsip/impl/setup-assign.hpp>
  #include <vsip/impl/par-util.hpp>
  
+ 
+ 
+ /***********************************************************************
+   Declarations
+ ***********************************************************************/
+ 
+ Vector<processor_type> processor_set();
+ 
  #endif // VSIP_PARALLEL_HPP
Index: src/vsip/support.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/support.hpp,v
retrieving revision 1.24
diff -c -p -r1.24 support.hpp
*** src/vsip/support.hpp	5 Dec 2005 19:19:18 -0000	1.24
--- src/vsip/support.hpp	5 Dec 2005 20:22:35 -0000
*************** const dimension_type dim2 = 2;		///< Thi
*** 280,289 ****
  
  
  // Support functions [support.functions].
  
  /// Return the total number of processors executing the program.
! processor_type num_processors() VSIP_NOTHROW;
! //FIXME// Vector<processor_type> processor_set();
  processor_type local_processor() VSIP_NOTHROW;
  
  } // namespace vsip
--- 280,290 ----
  
  
  // Support functions [support.functions].
+ template <typename T, typename Block> class Vector;
  
  /// Return the total number of processors executing the program.
! length_type num_processors() VSIP_NOTHROW;
! // processor_set() defined in parallel.hpp
  processor_type local_processor() VSIP_NOTHROW;
  
  } // namespace vsip
