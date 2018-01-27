Index: benchmarks/loop.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/loop.hpp,v
retrieving revision 1.14
diff -c -p -r1.14 loop.hpp
*** benchmarks/loop.hpp	3 Apr 2006 19:17:15 -0000	1.14
--- benchmarks/loop.hpp	5 Apr 2006 18:33:10 -0000
*************** enum output_metric
*** 58,64 ****
    ops_per_sec,
    iob_per_sec,
    wiob_per_sec,
!   all_per_sec
  };
  
  
--- 58,65 ----
    ops_per_sec,
    iob_per_sec,
    wiob_per_sec,
!   all_per_sec,
!   secs_per_pt
  };
  
  
*************** Loop1P::metric(
*** 168,173 ****
--- 169,179 ----
      double ops = (double)M * fcn.wiob_per_point(M) * loop;
      return ops / (time * 1e6);
    }
+   else if (m == secs_per_pt)
+   {
+     double pts = (double)M * loop;
+     return (time * 1e6) / pts;
+   }
    else
      return 0.f;
  }
*************** Loop1P::sweep(Functor fcn)
*** 246,251 ****
--- 252,258 ----
  	   metric_ == ops_per_sec  ? "ops_per_sec" :
  	   metric_ == iob_per_sec  ? "iob_per_sec" :
  	   metric_ == wiob_per_sec ? "wiob_per_sec" :
+ 	   metric_ == secs_per_pt  ? "secs_per_pt" :
  	                             "*unknown*");
      if (this->note_)
        printf("# note: %s\n", this->note_);
*************** Loop1P::steady(Functor fcn)
*** 375,380 ****
--- 382,388 ----
  	   metric_ == ops_per_sec  ? "ops_per_sec" :
  	   metric_ == iob_per_sec  ? "iob_per_sec" :
  	   metric_ == wiob_per_sec ? "wiob_per_sec" :
+ 	   metric_ == secs_per_pt  ? "secs_per_pt" :
  	                             "*unknown*");
      if (this->note_)
        printf("# note: %s\n", this->note_);
Index: benchmarks/main.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/main.cpp,v
retrieving revision 1.8
diff -c -p -r1.8 main.cpp
*** benchmarks/main.cpp	21 Mar 2006 15:53:09 -0000	1.8
--- benchmarks/main.cpp	5 Apr 2006 18:33:24 -0000
*************** main(int argc, char** argv)
*** 79,84 ****
--- 79,86 ----
        loop.metric_ = wiob_per_sec;
      else if (!strcmp(argv[i], "-all"))
        loop.metric_ = all_per_sec;
+     else if (!strcmp(argv[i], "-lat"))
+       loop.metric_ = secs_per_pt;
      else if (!strcmp(argv[i], "-mem"))
        loop.lhs_ = lhs_mem;
      else if (!strcmp(argv[i], "-prof"))
