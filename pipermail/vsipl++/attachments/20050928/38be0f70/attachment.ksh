Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.279
diff -c -p -r1.279 ChangeLog
*** ChangeLog	28 Sep 2005 04:33:34 -0000	1.279
--- ChangeLog	28 Sep 2005 18:52:21 -0000
***************
*** 1,3 ****
--- 1,10 ----
+ 2005-09-28  Jules Bergmann  <jules@codesourcery.com>
+ 
+ 	* src/vsip/impl/block-traits.hpp (View_block_storage):
+ 	  Add 'With_rp' template typedef to specify ref-count policy.
+ 	* src/vsip/impl/extdata.hpp: Use View_block_storage::With_rp to
+ 	  apply ref-count policy for block being held.
+ 
  2005-09-27  Nathan Myers  <ncm@codesourcery.com>
  
  	* tests/extdata-fft.cpp, tests/fft.cpp, tests/fftm-par.cpp,
Index: src/vsip/impl/block-traits.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/block-traits.hpp,v
retrieving revision 1.13
diff -c -p -r1.13 block-traits.hpp
*** src/vsip/impl/block-traits.hpp	15 Sep 2005 11:14:57 -0000	1.13
--- src/vsip/impl/block-traits.hpp	28 Sep 2005 18:52:21 -0000
*************** struct By_ref_block_storage
*** 49,54 ****
--- 49,60 ----
    typedef Ref_counted_ptr<Block> type;
    typedef Block&                 plain_type;
    typedef Block const&           expr_type;
+ 
+   template <typename RP>
+   struct With_rp
+   {
+     typedef RPPtr<Block, RP> type;
+   };
  };
  
  template <typename Block>
*************** struct By_value_block_storage
*** 57,62 ****
--- 63,74 ----
    typedef Stored_value<Block> type;
    typedef Block               plain_type;
    typedef Block               expr_type;
+ 
+   template <typename RP>
+   struct With_rp
+   {
+     typedef Stored_value<Block> type;
+   };
  };
  
  template <typename Block>
Index: src/vsip/impl/extdata.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/extdata.hpp,v
retrieving revision 1.14
diff -c -p -r1.14 extdata.hpp
*** src/vsip/impl/extdata.hpp	16 Sep 2005 22:03:20 -0000	1.14
--- src/vsip/impl/extdata.hpp	28 Sep 2005 18:52:21 -0000
*************** public:
*** 711,717 ****
  
    // Member data.
  private:
!   typename View_block_storage<Block>::type blk_;
    ext_type         ext_;
    sync_action_type sync_;
  };
--- 711,718 ----
  
    // Member data.
  private:
!   typename View_block_storage<Block>::template With_rp<RP>::type
! 		   blk_;
    ext_type         ext_;
    sync_action_type sync_;
  };
*************** public:
*** 768,774 ****
  
    // Member data.
  private:
!   typename View_block_storage<Block>::type blk_;
    ext_type         ext_;
    sync_action_type sync_;
  };
--- 769,776 ----
  
    // Member data.
  private:
!   typename View_block_storage<Block>::template With_rp<RP>::type
! 		   blk_;
    ext_type         ext_;
    sync_action_type sync_;
  };
