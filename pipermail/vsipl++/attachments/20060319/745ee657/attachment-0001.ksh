
Index: configure.ac
===================================================================
RCS file: /home/cvs/Repository/vpp/configure.ac,v
retrieving revision 1.87
diff -c -p -r1.87 configure.ac
*** configure.ac	9 Mar 2006 05:44:58 -0000	1.87
--- configure.ac	19 Mar 2006 22:40:25 -0000
*************** mkdir -p src/vsip/impl/simd
*** 1637,1642 ****
--- 1637,1648 ----
  
  
  #
+ # set to allow apps to test which VSIPL++ they are using
+ #
+ AC_DEFINE([VSIP_IMPL_SOURCERY_VPP], [], 
+           [Define to indicate this is CodeSourcery's VSIPL++.])
+ 
+ #
  # library
  #
  ARFLAGS="r"
Index: benchmarks/benchmarks.hpp
===================================================================
RCS file: benchmarks/benchmarks.hpp
diff -N benchmarks/benchmarks.hpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- benchmarks/benchmarks.hpp	19 Mar 2006 22:40:25 -0000
***************
*** 0 ****
--- 1,276 ----
+ /* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+ 
+ /** @file    benchmarks/benchmarks.hpp
+     @author  Don McCoy
+     @date    2006-03-16
+     @brief   VSIPL++ Library: Benchmark common definitions
+ 
+ */
+ 
+ #ifndef VSIP_IMPL_BENCHMARKS_HPP
+ #define VSIP_IMPL_BENCHMARKS_HPP
+ 
+ #ifdef VSIP_IMPL_SOURCERY_VPP
+ 
+ // Sourcery VSIPL++ provides certain resources such as system 
+ // timers that are needed for running the benchmarks.
+ 
+ #include <vsip/impl/profile.hpp>
+ #include <../tests/test.hpp>
+ #include "loop.hpp"
+ #include "ops_info.hpp"
+ 
+ #else
+ 
+ // when linking with non-sourcery versions of the lib, the
+ // definitions below provide a minimal set of these resources.
+ 
+ #include <time.h>
+ 
+ #include <cstdlib>
+ #include <cassert>
+ 
+ #include <vsip/support.hpp>
+ #include <vsip/complex.hpp>
+ #include <vsip/math.hpp>
+ 
+ #include "loop_ser.hpp"
+ #include "ops_info.hpp"
+ 
+ 
+ namespace vsip
+ {
+ namespace impl
+ {
+ namespace profile
+ {
+ 
+ struct Posix_time
+ {
+   static bool const valid = true; 
+   static char* name() { return "Posix_time"; }
+   static void init() { clocks_per_sec = CLOCKS_PER_SEC; }
+ 
+   typedef clock_t stamp_type;
+   static void sample(stamp_type& time) { time = clock(); }
+   static stamp_type zero() { return stamp_type(); }
+   static stamp_type f_clocks_per_sec() { return CLOCKS_PER_SEC; }
+   static stamp_type add(stamp_type A, stamp_type B) { return A + B; }
+   static stamp_type sub(stamp_type A, stamp_type B) { return A - B; }
+   static float seconds(stamp_type time) { return (float)time / CLOCKS_PER_SEC; }
+   static unsigned long ticks(stamp_type time) { return (unsigned long)time; }
+ 
+   static stamp_type clocks_per_sec;
+ };
+ 
+ 
+ /// Timer class that keeps start/stop times.
+ ///
+ /// Requires:
+ ///   TP is a timer policy.
+ 
+ template <typename TP>
+ class P_timer {
+ private:
+   typedef typename TP::stamp_type stamp_type;
+ 
+   stamp_type	start_;
+   stamp_type	stop_;
+ 
+ public:
+   P_timer() {}
+ 
+   void start() { TP::sample(start_); }
+   void stop()  { TP::sample(stop_);  }
+ 
+   stamp_type raw_delta() { return TP::sub(stop_, start_); }
+   float delta() { return TP::seconds(TP::sub(stop_, start_)); }
+ };
+ 
+ 
+ 
+ /// Timer class that accumulates across multiple start/stop times.
+ ///
+ /// Requires:
+ ///   TP is a timer policy.
+ 
+ template <typename TP>
+ class P_acc_timer {
+ private:
+   typedef typename TP::stamp_type stamp_type;
+ 
+   stamp_type	total_;
+   stamp_type	start_;
+   stamp_type	stop_;
+   unsigned	count_;
+ 
+ public:
+   P_acc_timer() { total_ = stamp_type(); count_ = 0; }
+ 
+   void start() { TP::sample(start_); }
+   void stop()
+   {
+     TP::sample(stop_);
+     total_ = TP::add(total_, TP::sub(stop_, start_));
+     count_ += 1;
+   }
+ 
+   stamp_type raw_delta() const { return TP::sub(stop_, start_); }
+   float delta() const { return TP::seconds(TP::sub(stop_, start_)); }
+   float total() const { return TP::seconds(total_); }
+   int   count() const { return count_; }
+ };
+ 
+ typedef Posix_time       DefaultTime;
+ 
+ typedef P_timer<DefaultTime>     Timer;
+ typedef P_acc_timer<DefaultTime> Acc_timer;
+ 
+ 
+ } // namespace vsip::impl::profile
+ } // namespace vsip::impl
+ } // namespace vsip
+ 
+ 
+ 
+ 
+ /// Compare two floating-point values for equality.
+ ///
+ /// Algorithm from:
+ ///    www.cygnus-software.com/papers/comparingfloats/comparingfloats.htm
+ 
+ template <typename T>
+ bool
+ almost_equal(
+   T	A,
+   T	B,
+   T	rel_epsilon = 1e-4,
+   T	abs_epsilon = 1e-6)
+ {
+   if (vsip::mag(A - B) < abs_epsilon)
+     return true;
+ 
+   T relative_error;
+ 
+   if (vsip::mag(B) > vsip::mag(A))
+     relative_error = vsip::mag((A - B) / B);
+   else
+     relative_error = vsip::mag((B - A) / A);
+ 
+   return (relative_error <= rel_epsilon);
+ }
+ 
+ 
+ 
+ template <typename T>
+ bool
+ almost_equal(
+   std::complex<T>	A,
+   std::complex<T>	B,
+   T	rel_epsilon = 1e-4,
+   T	abs_epsilon = 1e-6)
+ {
+   if (vsip::mag(A - B) < abs_epsilon)
+     return true;
+ 
+   T relative_error;
+ 
+   if (vsip::mag(B) > vsip::mag(A))
+     relative_error = vsip::mag((A - B) / B);
+   else
+     relative_error = vsip::mag((B - A) / A);
+ 
+   return (relative_error <= rel_epsilon);
+ }
+ 
+ 
+ 
+ /// Compare two values for equality.
+ template <typename T>
+ inline bool
+ equal(T val1, T val2)
+ {
+   return val1 == val2;
+ }
+ 
+ 
+ /// Compare two floating point values for equality within epsilon.
+ ///
+ /// Note: A fixed epsilon is not adequate for comparing the results
+ ///       of all floating point computations.  Epsilon should be choosen 
+ ///       based on the dynamic range of the computation.
+ template <>
+ inline bool
+ equal(float val1, float val2)
+ {
+   return almost_equal<float>(val1, val2);
+ }
+ 
+ 
+ 
+ /// Compare two floating point (double) values for equality within epsilon.
+ template <>
+ inline bool
+ equal(double val1, double val2)
+ {
+   return almost_equal<double>(val1, val2);
+ }
+ 
+ 
+ 
+ /// Compare two complex values for equality within epsilon.
+ 
+ template <typename T>
+ inline bool
+ equal(vsip::complex<T> val1, vsip::complex<T> val2)
+ {
+   return equal(val1.real(), val2.real()) &&
+          equal(val1.imag(), val2.imag());
+ }
+ 
+ 
+ 
+ 
+ void inline
+ test_assert_fail(
+   const char*  assertion,
+   const char*  file,
+   unsigned int line,
+   const char*  function)
+ {
+   fprintf(stderr, "TEST ASSERT FAIL: %s %s %d %s\n",
+ 	  assertion, file, line, function);
+   abort();
+ }
+ 
+ #if defined(__GNU__)
+ # if defined __cplusplus ? __GNUC_PREREQ (2, 6) : __GNUC_PREREQ (2, 4)
+ #   define TEST_ASSERT_FUNCTION    __PRETTY_FUNCTION__
+ # else
+ #  if defined __STDC_VERSION__ && __STDC_VERSION__ >= 199901L
+ #   define TEST_ASSERT_FUNCTION    __func__
+ #  else
+ #   define TEST_ASSERT_FUNCTION    ((__const char *) 0)
+ #  endif
+ # endif
+ #else
+ # define TEST_ASSERT_FUNCTION    ((__const char *) 0)
+ #endif
+ 
+ #ifdef __STDC__
+ #  define __TEST_STRING(e) #e
+ #else
+ #  define __TEST_STRING(e) "e"
+ #endif
+ 
+ #define test_assert(expr)						\
+   (static_cast<void>((expr) ? 0 :					\
+ 		     (test_assert_fail(__TEST_STRING(expr), __FILE__, __LINE__, \
+ 				       TEST_ASSERT_FUNCTION), 0)))
+ 
+ 
+ 
+ #endif // not VSIP_IMPL_SOURCERY_VPP
+ 
+ 
+ #endif // VSIP_IMPL_BENCHMARKS_HPP
Index: benchmarks/loop_ser.hpp
===================================================================
RCS file: benchmarks/loop_ser.hpp
diff -N benchmarks/loop_ser.hpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- benchmarks/loop_ser.hpp	19 Mar 2006 22:40:25 -0000
***************
*** 0 ****
--- 1,340 ----
+ /* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+ 
+ /** @file    loop_ser.hpp
+     @author  Don McCoy
+     @date    2006-03-19
+     @brief   VSIPL++ Library: Benchmark outer loop (serial version).
+ 
+ */
+ 
+ #ifndef CSL_LOOP_SER_HPP
+ #define CSL_LOOP_SER_HPP
+ 
+ /***********************************************************************
+   Included Files
+ ***********************************************************************/
+ 
+ #include <algorithm>
+ #include <vector>
+ 
+ 
+ #include <vsip/vector.hpp>
+ #include <vsip/math.hpp>
+ 
+ #include "benchmarks.hpp"
+ 
+ 
+ 
+ /***********************************************************************
+   Declarations
+ ***********************************************************************/
+ 
+ enum output_metric
+ {
+   pts_per_sec,
+   ops_per_sec,
+   iob_per_sec,
+   wiob_per_sec,
+   all_per_sec
+ };
+ 
+ 
+ enum lhs_metric
+ {
+   lhs_pts,
+   lhs_mem
+ };
+ 
+ enum bench_mode
+ {
+   steady_mode,
+   sweep_mode
+ };
+ 
+ 
+ // 1 Parameter Loop
+ class Loop1P
+ {
+ public:
+ 
+   // typedef void (TimingFunc)(int M, int loop, float* time, int calib);
+   // typedef boost::function<void(unsigned, unsigned, float*)>	TimingFunctor;
+ 
+   Loop1P() :
+     start_	 (2),
+     stop_	 (21),
+     cal_	 (4),
+     loop_start_	 (10),
+     samples_	 (1),
+     goal_sec_	 (1.0),
+     metric_      (pts_per_sec),
+     lhs_         (lhs_pts),
+     note_        (0),
+     do_prof_     (false),
+     what_        (0),
+     show_loop_   (false),
+     show_time_   (false),
+     mode_        (sweep_mode)
+   {}
+ 
+   template <typename Functor>
+   void sweep(Functor func);
+ 
+   template <typename Functor>
+   void steady(Functor func);
+ 
+   template <typename Functor>
+   void operator()(Functor func);
+ 
+   template <typename Functor>
+   float metric(Functor& fcn, size_t M, size_t loop, float time,
+ 	       output_metric m);
+ 
+   // Member data.
+ public:
+   unsigned	start_;		// loop start power-of-two
+   unsigned	stop_;		// loop stop power-of-two
+   int	 	cal_;		// calibration power-of-two
+   int	 	loop_start_;
+   unsigned	samples_;
+   double        goal_sec_;	// measurement goal (in seconds)
+   output_metric metric_;
+   lhs_metric    lhs_;
+   char*         note_;
+   int           user_param_;
+   bool          do_prof_;
+   int           what_;
+   bool          show_loop_;
+   bool          show_time_;
+   bench_mode    mode_;
+ };
+ 
+ 
+ 
+ /***********************************************************************
+   Definitions
+ ***********************************************************************/
+ 
+ template <typename Functor>
+ inline float
+ Loop1P::metric(
+   Functor&      fcn,
+   size_t        M,
+   size_t        loop,
+   float         time,
+   output_metric m)
+ {
+   if (m == pts_per_sec)
+   {
+     double pts = (double)M * loop;
+     return pts / (time * 1e6);
+   }
+   else if (m == ops_per_sec)
+   {
+     double ops = (double)M * fcn.ops_per_point(M) * loop;
+     return ops / (time * 1e6);
+   }
+   else if (m == iob_per_sec)
+   {
+     double ops = (double)M * (fcn.riob_per_point(M) + fcn.wiob_per_point(M))
+                            * loop;
+     return ops / (time * 1e6);
+   }
+   else if (m == wiob_per_sec)
+   {
+     double ops = (double)M * fcn.wiob_per_point(M) * loop;
+     return ops / (time * 1e6);
+   }
+   else
+     return 0.f;
+ }
+ 
+ 
+ 
+ template <typename Functor>
+ inline void
+ Loop1P::sweep(Functor fcn)
+ {
+   using vsip::Index;
+   using vsip::Vector;
+   using vsip::Dense;
+ 
+   size_t   loop, M;
+   float    time;
+   double   growth;
+   unsigned const n_time = samples_;
+ 
+   std::vector<float> mtime(n_time);
+ 
+   loop = (1 << loop_start_);
+   M    = (1 << cal_);
+ 
+   // calibrate --------------------------------------------------------
+   while (1)
+   {
+     // printf("%d: calib %5d\n", rank, loop);
+     fcn(M, loop, time);
+ 
+     if (time <= 0.01) time = 0.01;
+     // printf("%d: time %f\n", rank, time);
+ 
+     float factor = goal_sec_ / time;
+     if (factor < 1.0) factor += 0.1 * (1.0 - factor);
+     loop = (int)(factor * loop);
+ 
+     if (factor >= 0.75 && factor <= 1.25)
+       break;
+   }
+ 
+   {
+     printf("# what             : %s (%d)\n", fcn.what(), what_);
+     printf("# ops_per_point(1) : %d\n", (int)fcn.ops_per_point(1));
+     printf("# riob_per_point(1): %d\n", fcn.riob_per_point(1));
+     printf("# wiob_per_point(1): %d\n", fcn.wiob_per_point(1));
+     printf("# metric           : %s\n",
+ 	   metric_ == pts_per_sec  ? "pts_per_sec" :
+ 	   metric_ == ops_per_sec  ? "ops_per_sec" :
+ 	   metric_ == iob_per_sec  ? "iob_per_sec" :
+ 	   metric_ == wiob_per_sec ? "wiob_per_sec" :
+ 	                             "*unknown*");
+     if (this->note_)
+       printf("# note: %s\n", this->note_);
+     printf("# start_loop       : %lu\n", (unsigned long) loop);
+   }
+ 
+ 
+   // for real ---------------------------------------------------------
+   for (unsigned i=start_; i<=stop_; i++)
+   {
+     M = (1 << i);
+ 
+     for (unsigned i=0; i<n_time; ++i)
+     {
+       fcn(M, loop, time);
+ 
+       mtime[i] = time;
+     }
+ 
+     std::sort(mtime.begin(), mtime.end());
+ 
+     {
+       size_t L;
+       
+       if (this->lhs_ == lhs_mem)
+ 	L = M * fcn.mem_per_point(M);
+       else // (this->lhs_ == lhs_pts)
+ 	L = M;
+ 
+       if (this->metric_ == all_per_sec)
+ 	printf("%7ld %f %f %f", (unsigned long) L,
+ 	       this->metric(fcn, M, loop, mtime[(n_time-1)/2], pts_per_sec),
+ 	       this->metric(fcn, M, loop, mtime[(n_time-1)/2], ops_per_sec),
+ 	       this->metric(fcn, M, loop, mtime[(n_time-1)/2], iob_per_sec));
+       else if (n_time > 1)
+ 	// Note: max time is min op/s, and min time is max op/s
+ 	printf("%7lu %f %f %f", (unsigned long) L,
+ 	       this->metric(fcn, M, loop, mtime[(n_time-1)/2], metric_),
+ 	       this->metric(fcn, M, loop, mtime[n_time-1],     metric_),
+ 	       this->metric(fcn, M, loop, mtime[0],            metric_));
+       else
+ 	printf("%7lu %f", (unsigned long) L,
+ 	       this->metric(fcn, M, loop, mtime[0], metric_));
+       if (this->show_loop_)
+ 	printf("  %8lu", (unsigned long)loop);
+       if (this->show_time_)
+ 	printf("  %f", mtime[(n_time-1)/2]);
+       printf("\n");
+       fflush(stdout);
+     }
+ 
+     time = mtime[(n_time-1)/2];
+ 
+     growth = 2.0 * fcn.ops_per_point(2*M) / fcn.ops_per_point(M);
+     time = time * growth;
+ 
+     float factor = goal_sec_ / time;
+     if (factor < 1.0) factor += 0.1 * (1.0 - factor);
+     loop = (int)(factor * loop);
+ 
+     if (loop < 1) loop = 1;
+   }
+ }
+ 
+ 
+ 
+ template <typename Functor>
+ void
+ Loop1P::steady(Functor fcn)
+ {
+   using vsip::Index;
+   using vsip::Vector;
+   using vsip::Dense;
+ 
+   size_t   loop, M;
+   float    time;
+ 
+   loop = (1 << loop_start_);
+ 
+   {
+     printf("# what             : %s (%d)\n", fcn.what(), what_);
+     printf("# ops_per_point(1) : %d\n", (int)fcn.ops_per_point(1));
+     printf("# riob_per_point(1): %d\n", fcn.riob_per_point(1));
+     printf("# wiob_per_point(1): %d\n", fcn.wiob_per_point(1));
+     printf("# metric           : %s\n",
+ 	   metric_ == pts_per_sec  ? "pts_per_sec" :
+ 	   metric_ == ops_per_sec  ? "ops_per_sec" :
+ 	   metric_ == iob_per_sec  ? "iob_per_sec" :
+ 	   metric_ == wiob_per_sec ? "wiob_per_sec" :
+ 	                             "*unknown*");
+     if (this->note_)
+       printf("# note: %s\n", this->note_);
+     printf("# start_loop       : %lu\n", (unsigned long) loop);
+   }
+ 
+ 
+   // for real ---------------------------------------------------------
+   while (1)
+   {
+     M = (1 << start_);
+ 
+     fcn(M, loop, time);
+ 
+     {
+       if (this->metric_ == all_per_sec)
+ 	printf("%7ld %f %f %f", (unsigned long) M,
+ 	       this->metric(fcn, M, loop, time, pts_per_sec),
+ 	       this->metric(fcn, M, loop, time, ops_per_sec),
+ 	       this->metric(fcn, M, loop, time, iob_per_sec));
+       else
+ 	printf("%7lu %f", (unsigned long) M,
+ 	       this->metric(fcn, M, loop, time, metric_));
+       if (this->show_loop_)
+ 	printf("  %8lu", (unsigned long)loop);
+       if (this->show_time_)
+ 	printf("  %f", time);
+       printf("\n");
+       fflush(stdout);
+     }
+ 
+     float factor = goal_sec_ / time;
+     if (factor < 1.0) factor += 0.1 * (1.0 - factor);
+     loop = (int)(factor * loop);
+ 
+     if (loop < 1) loop = 1;
+   }
+ }
+ 
+ 
+ 
+ template <typename Functor>
+ inline void
+ Loop1P::operator()(
+   Functor fcn)
+ {
+   if (mode_ == steady_mode)
+     this->steady(fcn);
+   else
+     this->sweep(fcn);
+ }
+ 
+ #endif // CSL_LOOP_SER_HPP
Index: benchmarks/main.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/main.cpp,v
retrieving revision 1.7
diff -c -p -r1.7 main.cpp
*** benchmarks/main.cpp	3 Mar 2006 14:30:53 -0000	1.7
--- benchmarks/main.cpp	19 Mar 2006 22:40:25 -0000
***************
*** 14,23 ****
  #include <iostream>
  
  #include <vsip/initfin.hpp>
- #include <vsip/impl/profile.hpp>
  
! #include "test.hpp"
! #include "loop.hpp"
  
  using namespace vsip;
  
--- 14,21 ----
  #include <iostream>
  
  #include <vsip/initfin.hpp>
  
! #include "benchmarks.hpp"
  
  using namespace vsip;
  
Index: benchmarks/make.standalone
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/make.standalone,v
retrieving revision 1.2
diff -c -p -r1.2 make.standalone
*** benchmarks/make.standalone	27 Jan 2006 13:13:23 -0000	1.2
--- benchmarks/make.standalone	19 Mar 2006 22:40:25 -0000
*************** EXEEXT   =  
*** 56,62 ****
  # Variables in this section should not be modified.
  
  # Logic to call pkg-config with PREFIX, if specified.
! ifdef $PREFIX
     PC    = env PKG_CONFIG_PATH=$(PREFIX)/lib/pkgconfig \
  	   pkg-config --define-variable=prefix=$(PREFIX) $(PKG)
  else
--- 56,62 ----
  # Variables in this section should not be modified.
  
  # Logic to call pkg-config with PREFIX, if specified.
! ifdef PREFIX
     PC    = env PKG_CONFIG_PATH=$(PREFIX)/lib/pkgconfig \
  	   pkg-config --define-variable=prefix=$(PREFIX) $(PKG)
  else
*************** CXXFLAGS := $(shell $(PC) --cflags      
*** 69,81 ****
  	    $(shell $(PC) --variable=cxxflags )
  LIBS     := $(shell $(PC) --libs         )
  
- CXXFLAGS := $(CXXFLAGS) -I../tests
- 
  
  sources := $(wildcard *.cpp)
  objects := $(patsubst %.cpp, %.$(OBJEXT), $(sources))
  exes    := $(patsubst %.cpp, %$(EXEEXT),  $(sources))
- tests   := $(patsubst %.cpp, %.test,      $(sources))
  
  statics := $(patsubst %.cpp, %.static$(EXEEXT),  $(sources))
  
--- 69,78 ----
*************** exes_def_build := $(filter-out $(exes_sp
*** 88,104 ****
  # Targets
  ########################################################################
  
! all: $(tests)
  
! check: $(tests)
  
  vars:
  	@echo "CXX     : " $(CXX)
  	@echo "CXXFLAGS: " $(CXXFLAGS)
  	@echo "LIBS    : " $(LIBS)
  
  clean:
! 	rm -rf *.exe *.o
  
  
  
--- 85,102 ----
  # Targets
  ########################################################################
  
! all: $(exes_def_build)
  
! check: $(exes_def_build)
  
  vars:
+ 	@echo "PKG-CFG : " $(PC)
  	@echo "CXX     : " $(CXX)
  	@echo "CXXFLAGS: " $(CXXFLAGS)
  	@echo "LIBS    : " $(LIBS)
  
  clean:
! 	rm -rf $(exes_def_build) $(objects)
  
  
  
Index: benchmarks/vmul.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/vmul.cpp,v
retrieving revision 1.7
diff -c -p -r1.7 vmul.cpp
*** benchmarks/vmul.cpp	3 Mar 2006 14:30:53 -0000	1.7
--- benchmarks/vmul.cpp	19 Mar 2006 22:40:25 -0000
***************
*** 17,31 ****
  #include <vsip/support.hpp>
  #include <vsip/math.hpp>
  #include <vsip/random.hpp>
! #include <vsip/impl/profile.hpp>
! 
! #include "test.hpp"
! #include "loop.hpp"
! #include "ops_info.hpp"
  
  using namespace vsip;
  
  
  
  /***********************************************************************
    Definitions - vector element-wise multiply
--- 17,31 ----
  #include <vsip/support.hpp>
  #include <vsip/math.hpp>
  #include <vsip/random.hpp>
! #include "benchmarks.hpp"
  
  using namespace vsip;
  
  
+ #ifndef VSIP_IMPL_SOURCERY_VPP
+ #undef  VSIP_IMPL_NOINLINE
+ #define VSIP_IMPL_NOINLINE
+ #endif
  
  /***********************************************************************
    Definitions - vector element-wise multiply
*************** struct t_vmul1
*** 51,59 ****
      A = gen.randu(size);
      B = gen.randu(size);
  
!     A(0) = T(3);
!     B(0) = T(4);
!     
      vsip::impl::profile::Timer t1;
      
      t1.start();
--- 51,59 ----
      A = gen.randu(size);
      B = gen.randu(size);
  
!     A.put(0, T(3));
!     B.put(0, T(4));
! 
      vsip::impl::profile::Timer t1;
      
      t1.start();
*************** struct t_vmul1
*** 61,74 ****
        C = A * B;
      t1.stop();
      
!     if (!equal(C(0), T(12)))
      {
        std::cout << "t_vmul1: ERROR" << std::endl;
        abort();
      }
  
      for (index_type i=0; i<size; ++i)
!       test_assert(equal(C(i), A(i) * B(i)));
      
      time = t1.delta();
    }
--- 61,74 ----
        C = A * B;
      t1.stop();
      
!     if (!equal(C.get(0), T(12)))
      {
        std::cout << "t_vmul1: ERROR" << std::endl;
        abort();
      }
  
      for (index_type i=0; i<size; ++i)
!       test_assert(equal(C.get(i), A.get(i) * B.get(i)));
      
      time = t1.delta();
    }
*************** struct t_vmul_ip1
*** 104,110 ****
      t1.stop();
      
      for (index_type i=0; i<size; ++i)
!       test_assert(equal(chk(i), C(i)));
      
      time = t1.delta();
    }
--- 104,110 ----
      t1.stop();
      
      for (index_type i=0; i<size; ++i)
!       test_assert(equal(chk.get(i), C.get(i)));
      
      time = t1.delta();
    }
*************** struct t_vmul_dom1
*** 132,139 ****
      A = gen.randu(size);
      B = gen.randu(size);
  
!     A(0) = T(3);
!     B(0) = T(4);
  
      Domain<1> dom(size);
      
--- 132,139 ----
      A = gen.randu(size);
      B = gen.randu(size);
  
!     A.put(0, T(3));
!     B.put(0, T(4));
  
      Domain<1> dom(size);
      
*************** struct t_vmul_dom1
*** 144,164 ****
        C(dom) = A(dom) * B(dom);
      t1.stop();
      
!     if (!equal(C(0), T(12)))
      {
!       std::cout << "t_vmul1: ERROR" << std::endl;
        abort();
      }
  
      for (index_type i=0; i<size; ++i)
!       test_assert(equal(C(i), A(i) * B(i)));
      
      time = t1.delta();
    }
  };
  
  
! 
  template <typename T, typename ComplexFmt>
  struct t_vmul2
  {
--- 144,164 ----
        C(dom) = A(dom) * B(dom);
      t1.stop();
      
!     if (!equal(C.get(0), T(12)))
      {
!       std::cout << "t_vmul_dom1: ERROR" << std::endl;
        abort();
      }
  
      for (index_type i=0; i<size; ++i)
!       test_assert(equal(C.get(i), A.get(i) * B.get(i)));
      
      time = t1.delta();
    }
  };
  
  
! #ifdef VSIP_IMPL_SOURCERY_VPP
  template <typename T, typename ComplexFmt>
  struct t_vmul2
  {
*************** struct t_vmul2
*** 179,186 ****
      Vector<T, block_type> B(size, T());
      Vector<T, block_type> C(size);
  
!     A(0) = T(3);
!     B(0) = T(4);
      
      vsip::impl::profile::Timer t1;
      
--- 179,186 ----
      Vector<T, block_type> B(size, T());
      Vector<T, block_type> C(size);
  
!     A.put(0, T(3));
!     B.put(0, T(4));
      
      vsip::impl::profile::Timer t1;
      
*************** struct t_vmul2
*** 189,204 ****
        C = A * B;
      t1.stop();
      
!     if (!equal(C(0), T(12)))
      {
!       std::cout << "t_vmul1: ERROR" << std::endl;
        abort();
      }
      
      time = t1.delta();
    }
  };
! 
  
  
  /***********************************************************************
--- 189,204 ----
        C = A * B;
      t1.stop();
      
!     if (!equal(C.get(0), T(12)))
      {
!       std::cout << "t_vmul2: ERROR" << std::endl;
        abort();
      }
      
      time = t1.delta();
    }
  };
! #endif // VSIP_IMPL_SOURCERY_VPP
  
  
  /***********************************************************************
*************** struct t_rcvmul1
*** 231,241 ****
      
      t1.start();
      for (index_type l=0; l<loop; ++l)
!       C = A * B;
      t1.stop();
      
      for (index_type i=0; i<size; ++i)
!       test_assert(equal(C(i), A(i) * B(i)));
      
      time = t1.delta();
    }
--- 231,241 ----
      
      t1.start();
      for (index_type l=0; l<loop; ++l)
!       C = B * A;
      t1.stop();
      
      for (index_type i=0; i<size; ++i)
!       test_assert(equal(C.get(i), A.get(i) * B.get(i)));
      
      time = t1.delta();
    }
*************** struct t_svmul1
*** 269,276 ****
  
      Rand<T>     gen(0, 0);
      A = gen.randu(size);
!     A(0) = T(4);
!     
      vsip::impl::profile::Timer t1;
      
      t1.start();
--- 269,276 ----
  
      Rand<T>     gen(0, 0);
      A = gen.randu(size);
!     A.put(0, T(4));
! 
      vsip::impl::profile::Timer t1;
      
      t1.start();
*************** struct t_svmul1
*** 279,285 ****
      t1.stop();
      
      for (index_type i=0; i<size; ++i)
!       test_assert(equal(C(i), alpha * A(i)));
      
      time = t1.delta();
    }
--- 279,285 ----
      t1.stop();
      
      for (index_type i=0; i<size; ++i)
!       test_assert(equal(C.get(i), alpha * A.get(i)));
      
      time = t1.delta();
    }
*************** struct t_svmul2
*** 305,311 ****
  
      T alpha = T(3);
  
!     A(0) = T(4);
      
      vsip::impl::profile::Timer t1;
      
--- 305,311 ----
  
      T alpha = T(3);
  
!     A.put(0, T(4));
      
      vsip::impl::profile::Timer t1;
      
*************** struct t_svmul2
*** 314,320 ****
        C = A * alpha;
      t1.stop();
  
!     test_assert(equal(C(0), T(12)));
      
      time = t1.delta();
    }
--- 314,320 ----
        C = A * alpha;
      t1.stop();
  
!     test_assert(equal(C.get(0), T(12)));
      
      time = t1.delta();
    }
*************** test(Loop1P& loop, int what)
*** 336,343 ****
--- 336,345 ----
    {
    case  1: loop(t_vmul1<float>()); break;
    case  2: loop(t_vmul1<complex<float> >()); break;
+ #ifdef VSIP_IMPL_SOURCERY_VPP
    case  3: loop(t_vmul2<complex<float>, impl::Cmplx_inter_fmt>()); break;
    case  4: loop(t_vmul2<complex<float>, impl::Cmplx_split_fmt>()); break;
+ #endif
    case  5: loop(t_rcvmul1<float>()); break;
  
    case 11: loop(t_svmul1<float,          float>()); break;
