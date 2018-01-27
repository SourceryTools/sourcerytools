
Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.398
diff -c -p -r1.398 ChangeLog
*** ChangeLog	23 Feb 2006 08:21:17 -0000	1.398
--- ChangeLog	3 Mar 2006 21:31:02 -0000
***************
*** 1,3 ****
--- 1,7 ----
+ 2006-03-03  Don McCoy  <don@codesourcery.com>
+ 	* src/vsip/impl/profile.hpp: added members zero() and ticks()
+ 	  for the case where no timer is used.
+ 
  2006-02-23  Don McCoy  <don@codesourcery.com>
  
          * src/vsip/profile.cpp: corrected cases where 'stamp_type'
Index: src/vsip/impl/profile.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/profile.hpp,v
retrieving revision 1.12
diff -c -p -r1.12 profile.hpp
*** src/vsip/impl/profile.hpp	23 Feb 2006 08:21:17 -0000	1.12
--- src/vsip/impl/profile.hpp	3 Mar 2006 21:31:03 -0000
*************** struct No_time
*** 70,79 ****
--- 70,81 ----
  
    typedef int stamp_type;
    static void sample(stamp_type& time) { time = 0; }
+   static stamp_type zero() { return stamp_type(); }
    static stamp_type f_clocks_per_sec() { return 1; }
    static stamp_type add(stamp_type , stamp_type) { return 0; }
    static stamp_type sub(stamp_type , stamp_type) { return 0; }
    static float seconds(stamp_type) { return 0.f; }
+   static unsigned long ticks(stamp_type time) { return (unsigned long)time; }
  
    static stamp_type clocks_per_sec;
  };
