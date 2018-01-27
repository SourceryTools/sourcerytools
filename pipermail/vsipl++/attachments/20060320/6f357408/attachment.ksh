
Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.411
diff -c -p -r1.411 ChangeLog
*** ChangeLog	16 Mar 2006 03:27:10 -0000	1.411
--- ChangeLog	21 Mar 2006 00:16:54 -0000
***************
*** 1,3 ****
--- 1,21 ----
+ 2006-03-20  Don McCoy  <don@codesourcery.com>
+ 
+ 	* configure.ac: added #define for VSIP_IMPL_SOURCERY_VPP.
+ 	* benchmarks/benchmarks.hpp: new file.  encapsulates resources 
+ 	  needed to run benchmarks.  provides some resources for 
+ 	  linking against the reference implementation.
+ 	* benchmarks/loop.hpp: used macros to make parallel-specific
+ 	  code work when linking against serial-only implementations.
+ 	* benchmarks/main.cpp: change to use benchmarks.hpp instead
+ 	  of several separate includes.
+ 	* benchmarks/make.standalone: Fixed a bug where it would
+ 	  not recognize that PREFIX was set on the command line.
+ 	  Fixed include paths and build targets.
+ 	* benchmarks/vmul.cpp: change to use benchmarks.hpp instead
+ 	  of several separate includes.  removed implementation-
+ 	  specific functionality where possible and used the new
+ 	  SOURCERY_VPP macro where not.
+ 
  2006-03-15  Stefan Seefeld  <stefan@codesourcery.com>
  
  	* tests/*: Move various tests into subdirectories.
Index: configure.ac
===================================================================
RCS file: /home/cvs/Repository/vpp/configure.ac,v
retrieving revision 1.87
diff -c -p -r1.87 configure.ac
*** configure.ac	9 Mar 2006 05:44:58 -0000	1.87
--- configure.ac	21 Mar 2006 00:16:54 -0000
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
--- benchmarks/benchmarks.hpp	21 Mar 2006 00:16:54 -0000
***************
*** 0 ****
--- 1,278 ----
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
+ #include "loop.hpp"
+ #include "ops_info.hpp"
+ 
+ #ifdef VSIP_IMPL_SOURCERY_VPP
+ 
+ // Sourcery VSIPL++ provides certain resources such as system 
+ // timers that are needed for running the benchmarks.
+ 
+ #include <vsip/impl/profile.hpp>
+ #include <../tests/test.hpp>
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
+ 
+ #undef  VSIP_IMPL_NOINLINE
+ #define VSIP_IMPL_NOINLINE
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
Index: benchmarks/loop.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/loop.hpp,v
retrieving revision 1.11
diff -c -p -r1.11 loop.hpp
*** benchmarks/loop.hpp	3 Mar 2006 14:30:53 -0000	1.11
--- benchmarks/loop.hpp	21 Mar 2006 00:16:54 -0000
***************
*** 17,27 ****
  #include <algorithm>
  #include <vector>
  
! #include <vsip/impl/profile.hpp>
  #include <vsip/vector.hpp>
  #include <vsip/math.hpp>
! #include <vsip/map.hpp>
! #include <vsip/parallel.hpp>
  
  
  
--- 17,51 ----
  #include <algorithm>
  #include <vector>
  
! //#include <vsip/impl/profile.hpp>
  #include <vsip/vector.hpp>
  #include <vsip/math.hpp>
! 
! #ifdef VSIP_IMPL_SOURCERY_VPP
! #  define PARALLEL_LOOP 1
! #else
! #  define PARALLEL_LOOP 0
! #endif
! 
! #if PARALLEL_LOOP
! #  include <vsip/map.hpp>
! #  include <vsip/parallel.hpp>
! #  define COMMUNICATOR_TYPE      vsip::impl::Communicator
! #  define PROCESSOR_TYPE         vsip::processor_type
! #  define DEFAULT_COMMUNICATOR() vsip::impl::default_communicator()
! #  define RANK(comm)             comm.rank()
! #  define BARRIER(comm)          comm.barrier()
! #  define NUM_PROCESSORS()       vsip::num_processors()
! #  define LOCAL(view)            view.local()
! #else
! #  define COMMUNICATOR_TYPE      int
! #  define PROCESSOR_TYPE         int
! #  define DEFAULT_COMMUNICATOR() 0
! #  define RANK(comm)             0
! #  define BARRIER(comm)
! #  define NUM_PROCESSORS()       1
! #  define LOCAL(view)            view
! #endif
  
  
  
*************** Loop1P::sweep(Functor fcn)
*** 168,182 ****
    unsigned const n_time = samples_;
    char     filename[256];
  
!   vsip::impl::Communicator comm  = vsip::impl::default_communicator();
!   vsip::processor_type     rank  = comm.rank();
!   vsip::processor_type     nproc = vsip::num_processors();
  
    std::vector<float> mtime(n_time);
  
    Vector<float, Dense<1, float, row1_type, Map<> > >
      dist_time(nproc, Map<>(nproc));
    Vector<float, Dense<1, float, row1_type, Global_map<1> > > glob_time(nproc);
  
    loop = (1 << loop_start_);
    M    = (1 << cal_);
--- 192,211 ----
    unsigned const n_time = samples_;
    char     filename[256];
  
!   COMMUNICATOR_TYPE comm  = DEFAULT_COMMUNICATOR();
!   PROCESSOR_TYPE    rank  = RANK(comm);
!   PROCESSOR_TYPE    nproc = NUM_PROCESSORS();
  
    std::vector<float> mtime(n_time);
  
+ #if DO_PARALLEL
    Vector<float, Dense<1, float, row1_type, Map<> > >
      dist_time(nproc, Map<>(nproc));
    Vector<float, Dense<1, float, row1_type, Global_map<1> > > glob_time(nproc);
+ #else
+   Vector<float, Dense<1, float, row1_type> > dist_time(nproc);
+   Vector<float, Dense<1, float, row1_type> > glob_time(nproc);
+ #endif
  
    loop = (1 << loop_start_);
    M    = (1 << cal_);
*************** Loop1P::sweep(Functor fcn)
*** 185,200 ****
    while (1)
    {
      // printf("%d: calib %5d\n", rank, loop);
!     comm.barrier();
      fcn(M, loop, time);
!     comm.barrier();
  
!     dist_time.local().put(0, time);
      glob_time = dist_time;
  
      Index<1> idx;
  
!     time = maxval(glob_time.local(), idx);
  
      if (time <= 0.01) time = 0.01;
      // printf("%d: time %f\n", rank, time);
--- 214,229 ----
    while (1)
    {
      // printf("%d: calib %5d\n", rank, loop);
!     BARRIER(comm);
      fcn(M, loop, time);
!     BARRIER(comm);
  
!     LOCAL(dist_time).put(0, time);
      glob_time = dist_time;
  
      Index<1> idx;
  
!     time = maxval(LOCAL(glob_time), idx);
  
      if (time <= 0.01) time = 0.01;
      // printf("%d: time %f\n", rank, time);
*************** Loop1P::sweep(Functor fcn)
*** 225,232 ****
--- 254,263 ----
      printf("# start_loop       : %lu\n", (unsigned long) loop);
    }
  
+ #if DO_PARALLEL
    if (this->do_prof_)
      vsip::impl::profile::prof->set_mode(vsip::impl::profile::pm_accum);
+ #endif
  
    // for real ---------------------------------------------------------
    for (unsigned i=start_; i<=stop_; i++)
*************** Loop1P::sweep(Functor fcn)
*** 235,257 ****
  
      for (unsigned i=0; i<n_time; ++i)
      {
!       comm.barrier();
        fcn(M, loop, time);
!       comm.barrier();
  
!       dist_time.local().put(0, time);
        glob_time = dist_time;
  
        Index<1> idx;
  
!       mtime[i] = maxval(glob_time.local(), idx);
      }
  
      if (this->do_prof_)
      {
        sprintf(filename, "vprof.%lu.out", (unsigned long) M);
        vsip::impl::profile::prof->dump(filename);
      }
  
      std::sort(mtime.begin(), mtime.end());
  
--- 266,290 ----
  
      for (unsigned i=0; i<n_time; ++i)
      {
!       BARRIER(comm);
        fcn(M, loop, time);
!       BARRIER(comm);
  
!       LOCAL(dist_time).put(0, time);
        glob_time = dist_time;
  
        Index<1> idx;
  
!       mtime[i] = maxval(LOCAL(glob_time), idx);
      }
  
+ #if DO_PARALLEL
      if (this->do_prof_)
      {
        sprintf(filename, "vprof.%lu.out", (unsigned long) M);
        vsip::impl::profile::prof->dump(filename);
      }
+ #endif
  
      std::sort(mtime.begin(), mtime.end());
  
*************** Loop1P::steady(Functor fcn)
*** 316,328 ****
    size_t   loop, M;
    float    time;
  
!   vsip::impl::Communicator comm  = vsip::impl::default_communicator();
!   vsip::processor_type     rank  = comm.rank();
!   vsip::processor_type     nproc = vsip::num_processors();
  
    Vector<float, Dense<1, float, row1_type, Map<> > >
      dist_time(nproc, Map<>(nproc));
    Vector<float, Dense<1, float, row1_type, Global_map<1> > > glob_time(nproc);
  
    loop = (1 << loop_start_);
  
--- 349,366 ----
    size_t   loop, M;
    float    time;
  
!   COMMUNICATOR_TYPE comm  = DEFAULT_COMMUNICATOR();
!   PROCESSOR_TYPE    rank  = RANK(comm);
!   PROCESSOR_TYPE    nproc = NUM_PROCESSORS();
  
+ #if DO_PARALLEL
    Vector<float, Dense<1, float, row1_type, Map<> > >
      dist_time(nproc, Map<>(nproc));
    Vector<float, Dense<1, float, row1_type, Global_map<1> > > glob_time(nproc);
+ #else
+   Vector<float, Dense<1, float, row1_type> > dist_time(nproc);
+   Vector<float, Dense<1, float, row1_type> > glob_time(nproc);
+ #endif
  
    loop = (1 << loop_start_);
  
*************** Loop1P::steady(Functor fcn)
*** 344,367 ****
      printf("# start_loop       : %lu\n", (unsigned long) loop);
    }
  
    if (this->do_prof_)
      vsip::impl::profile::prof->set_mode(vsip::impl::profile::pm_accum);
  
    // for real ---------------------------------------------------------
    while (1)
    {
      M = (1 << start_);
  
!     comm.barrier();
      fcn(M, loop, time);
!     comm.barrier();
  
!     dist_time.local().put(0, time);
      glob_time = dist_time;
  
      Index<1> idx;
  
!     time = maxval(glob_time.local(), idx);
  
  #if 0
      if (this->do_prof_)
--- 382,407 ----
      printf("# start_loop       : %lu\n", (unsigned long) loop);
    }
  
+ #if DO_PARALLEL
    if (this->do_prof_)
      vsip::impl::profile::prof->set_mode(vsip::impl::profile::pm_accum);
+ #endif
  
    // for real ---------------------------------------------------------
    while (1)
    {
      M = (1 << start_);
  
!     BARRIER(comm);
      fcn(M, loop, time);
!     BARRIER(comm);
  
!     LOCAL(dist_time).put(0, time);
      glob_time = dist_time;
  
      Index<1> idx;
  
!     time = maxval(LOCAL(glob_time), idx);
  
  #if 0
      if (this->do_prof_)
Index: benchmarks/main.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/main.cpp,v
retrieving revision 1.7
diff -c -p -r1.7 main.cpp
*** benchmarks/main.cpp	3 Mar 2006 14:30:53 -0000	1.7
--- benchmarks/main.cpp	21 Mar 2006 00:16:54 -0000
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
--- benchmarks/make.standalone	21 Mar 2006 00:16:54 -0000
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
! tests   := $(patsubst %.cpp, %.test,      $(sources))
  
  statics := $(patsubst %.cpp, %.static$(EXEEXT),  $(sources))
  
--- 69,79 ----
  	    $(shell $(PC) --variable=cxxflags )
  LIBS     := $(shell $(PC) --libs         )
  
  
  sources := $(wildcard *.cpp)
  objects := $(patsubst %.cpp, %.$(OBJEXT), $(sources))
  exes    := $(patsubst %.cpp, %$(EXEEXT),  $(sources))
! headers := $(wildcard *.hpp)
  
  statics := $(patsubst %.cpp, %.static$(EXEEXT),  $(sources))
  
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
  
  
  
--- 86,105 ----
  # Targets
  ########################################################################
  
! all: $(exes_def_build) $(headers)
! 
! check: $(exes_def_build) $(headers)
  
! main.$(OBJEXT): $(headers)
  
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
--- benchmarks/vmul.cpp	21 Mar 2006 00:16:54 -0000
***************
*** 17,32 ****
  #include <vsip/support.hpp>
  #include <vsip/math.hpp>
  #include <vsip/random.hpp>
! #include <vsip/impl/profile.hpp>
! 
! #include "test.hpp"
! #include "loop.hpp"
! #include "ops_info.hpp"
  
  using namespace vsip;
  
  
- 
  /***********************************************************************
    Definitions - vector element-wise multiply
  ***********************************************************************/
--- 17,27 ----
  #include <vsip/support.hpp>
  #include <vsip/math.hpp>
  #include <vsip/random.hpp>
! #include "benchmarks.hpp"
  
  using namespace vsip;
  
  
  /***********************************************************************
    Definitions - vector element-wise multiply
  ***********************************************************************/
*************** struct t_vmul1
*** 51,59 ****
      A = gen.randu(size);
      B = gen.randu(size);
  
!     A(0) = T(3);
!     B(0) = T(4);
!     
      vsip::impl::profile::Timer t1;
      
      t1.start();
--- 46,54 ----
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
--- 56,69 ----
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
--- 99,105 ----
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
      
--- 127,134 ----
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
--- 139,159 ----
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
      
--- 174,181 ----
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
--- 184,199 ----
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
--- 226,236 ----
      
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
--- 264,271 ----
  
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
--- 274,280 ----
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
      
--- 300,306 ----
  
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
--- 309,315 ----
        C = A * alpha;
      t1.stop();
  
!     test_assert(equal(C.get(0), T(12)));
      
      time = t1.delta();
    }
*************** test(Loop1P& loop, int what)
*** 336,343 ****
--- 331,340 ----
    {
    case  1: loop(t_vmul1<float>()); break;
    case  2: loop(t_vmul1<complex<float> >()); break;
+ #ifdef VSIP_IMPL_SOURCERY_VPP
    case  3: loop(t_vmul2<complex<float>, impl::Cmplx_inter_fmt>()); break;
    case  4: loop(t_vmul2<complex<float>, impl::Cmplx_split_fmt>()); break;
+ #endif
    case  5: loop(t_rcvmul1<float>()); break;
  
    case 11: loop(t_svmul1<float,          float>()); break;
