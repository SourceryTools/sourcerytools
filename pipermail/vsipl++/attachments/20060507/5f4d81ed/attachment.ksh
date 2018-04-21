
Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.457
diff -c -p -r1.457 ChangeLog
*** ChangeLog	7 May 2006 19:54:08 -0000	1.457
--- ChangeLog	7 May 2006 20:06:06 -0000
***************
*** 1,3 ****
--- 1,8 ----
+ 2006-05-07  Don McCoy  <don@codesourcery.com>
+ 
+ 	* src/vsip/impl/sal/solver_lu.hpp: Corrected an error in the
+ 	  initialization of the reciprocals vector in the copy constructor.
+ 
  2006-05-07  Jules Bergmann  <jules@codesourcery.com>
  
  	* src/vsip/impl/rt_extdata.hpp: Make data, stride, size, and
Index: src/vsip/impl/sal/solver_lu.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/sal/solver_lu.hpp,v
retrieving revision 1.2
diff -c -p -r1.2 solver_lu.hpp
*** src/vsip/impl/sal/solver_lu.hpp	7 May 2006 19:38:36 -0000	1.2
--- src/vsip/impl/sal/solver_lu.hpp	7 May 2006 20:06:06 -0000
*************** VSIP_THROW((std::bad_alloc))
*** 356,365 ****
  {
    data_ = lu.data_;
    for (index_type i=0; i<length_; ++i)
-   {
      ipiv_[i] = lu.ipiv_[i];
!     recip_ = lu.recip_;
!   }
  }
  
  
--- 356,363 ----
  {
    data_ = lu.data_;
    for (index_type i=0; i<length_; ++i)
      ipiv_[i] = lu.ipiv_[i];
!   recip_ = lu.recip_;
  }
  
  
