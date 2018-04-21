
Index: benchmarks/loop.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/loop.hpp,v
retrieving revision 1.16
diff -c -p -r1.16 loop.hpp
*** benchmarks/loop.hpp	12 Apr 2006 18:57:39 -0000	1.16
--- benchmarks/loop.hpp	13 Apr 2006 16:44:48 -0000
*************** enum range_type
*** 82,87 ****
--- 82,92 ----
    centered_range
  };
    
+ enum prog_type
+ {
+   geometric,
+   linear
+ };
  
  
  
*************** public:
*** 103,108 ****
--- 108,115 ----
      metric_      (pts_per_sec),
      lhs_         (lhs_pts),
      range_       (natural_range),
+     progression_ (geometric),
+     prog_scale_  (10),
      center_      (1000),
      note_        (0),
      do_prof_     (false),
*************** public:
*** 142,147 ****
--- 149,156 ----
    output_metric metric_;
    lhs_metric    lhs_;
    range_type    range_;
+   prog_type     progression_;
+   int           prog_scale_;
    unsigned      center_;	// center value if range_ == centered
    char*         note_;
    int           user_param_;
*************** Loop1P::metric(
*** 201,212 ****
  inline unsigned
  Loop1P::m_value(unsigned i)
  {
!   if (range_ == centered_range)
    {
!     if (i < 10) return center_ / (1 << (10-i));
!     else        return center_ * (1 << (i-10));
    }
-   else return (1 << i);
  }
  
  
--- 210,234 ----
  inline unsigned
  Loop1P::m_value(unsigned i)
  {
!   unsigned mid = (start_ + stop_) / 2;
!   switch ( progression_ )
    {
!   case linear:
!     if (range_ == centered_range)
!       return center_ + prog_scale_ * (i-mid);
!     else 
!       return prog_scale_ * i;
!     break;
!   case geometric:
!   default:
!     if (range_ == centered_range)
!     {
!       if (i < mid) return center_ / (1 << (mid-i));
!       else        return center_ * (1 << (i-mid));
!     }
!     else return (1 << i);
!     break;
    }
  }
  
  
Index: benchmarks/main.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/main.cpp,v
retrieving revision 1.10
diff -c -p -r1.10 main.cpp
*** benchmarks/main.cpp	12 Apr 2006 18:57:39 -0000	1.10
--- benchmarks/main.cpp	13 Apr 2006 16:44:48 -0000
*************** main(int argc, char** argv)
*** 81,86 ****
--- 81,96 ----
        loop.metric_ = all_per_sec;
      else if (!strcmp(argv[i], "-lat"))
        loop.metric_ = secs_per_pt;
+     else if (!strcmp(argv[i], "-linear"))
+     {
+       loop.progression_ = linear;
+       loop.prog_scale_ = atoi(argv[++i]);
+     }
+     else if (!strcmp(argv[i], "-center"))
+     {
+       loop.range_ = centered_range;
+       loop.center_ = atoi(argv[++i]);
+     }
      else if (!strcmp(argv[i], "-mem"))
        loop.lhs_ = lhs_mem;
      else if (!strcmp(argv[i], "-prof"))
