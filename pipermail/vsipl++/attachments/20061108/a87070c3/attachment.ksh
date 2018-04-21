Index: ChangeLog
===================================================================
--- ChangeLog	(revision 154175)
+++ ChangeLog	(working copy)
@@ -1,3 +1,57 @@
+2006-11-08  Jules Bergmann  <jules@codesourcery.com>
+
+	Share PAS dynamic_xfer object for assignments.  Fix bug where not
+	all psets were closed.
+	* src/vsip/initfin.hpp (vsipl): Add accessor function for par_service.
+	* src/vsip/opt/pas/block.hpp: Use VSIP_IMPL_CHECK_RC to check
+	  PAS return codes instead of assert.
+	* src/vsip/opt/pas/assign_direct.hpp: Likewise.
+	* src/vsip/opt/pas/assign_eb.hpp: Likewise.  Add missing close
+	  for all_pset.
+	* src/vsip/opt/pas/assign.hpp: Likewise.  Use shared dynamic_xfer.
+	* src/vsip/opt/pas/param.hpp: Add _PAS_SHARE_DYNAMIC_XFER
+	  to control sharing of dynamic_xfer for PAS.
+	* src/vsip/opt/pas/services.hpp: Use VSIP_IMPL_CHECK_RC.  Create
+	  and destroy shared dynamic_xfer.
+	* src/vsip/map.hpp: Check if map is applied before returning
+	  applied pset.
+	
+	Support MCOE TMR timer.
+	* configure.ac (--enable-timer): Add option mcoe_tmr.
+	* src/vsip/opt/profile.cpp: Add timer policy for MCOE TMR timer.
+	* src/vsip/opt/profile.hpp: Add timer policy for MCOE TMR timer.
+	  New _PROFILER_PAR macro to control profiling in parallel/comms.
+	  Add reset() method to P_acc_timer.
+	* src/vsip/core/setup_assign.hpp: Control profiling with
+	  _PROFILING_FEATURE_ENABLED / _PROFILE_FEATURE macros.
+	* examples/mercury/mcoe-setup.sh: Make mcoe_tmr timer policy the
+	  default.
+	
+	* src/vsip/opt/expr/serial_dispatch.hpp: If ops_per_point are
+	  0, record bytes written instead.
+
+	* benchmarks/copy.cpp: Add option to sync between setup_assign
+	  construction and execution.  Merge create_map functionality
+	  into ...
+	* benchmarks/create_map.hpp: ... here.
+	* benchmarks/loop.hpp: Add riob_per_sec and data_per_set metrics.
+	  Allow loop count to be fixed.  Use non-decreasing loop count
+	  calibration to avoid oscillations.
+	* benchmarks/main.cpp: Add argument processing for fix_loop, and
+	  for riob and data metrics.
+	* benchmarks/fft_sal.cpp: Add coverage for in-place, interleaved-
+	  complex, and inverse FFTs.
+	* benchmarks/vmul.cpp: Split out common classes and parallel cases.
+	* benchmarks/vmul.hpp: New file, common classes for vmul and vmul_par.
+	* benchmarks/vmul_par.cpp: New file, parallel vmul cases.
+	* benchmarks/sumval.cpp: Add get/put sumval case.
+	* benchmarks/sumval_simd.cpp: New file, sumval benchmark using SIMD.
+	* benchmarks/memwrite.cpp: New file, memory write bandwidth benchmark.
+	* benchmarks/memwrite_sal.cpp: New file, memory write bandwidth
+	  benchmark using SAL.
+	* benchmarks/memwrite_simd.cpp: New file, memory write bandwidth
+	  benchmark using SIMD.
+	
 2006-11-07  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip/core/signal/corr_common.hpp: Add macro to control
Index: src/vsip/initfin.hpp
===================================================================
--- src/vsip/initfin.hpp	(revision 154174)
+++ src/vsip/initfin.hpp	(working copy)
@@ -64,6 +64,9 @@
   /// Destructor.
   ~vsipl() VSIP_NOTHROW;
 
+  static impl::Par_service* impl_par_service()
+  { return par_service_; }
+
 private:
   // These are declared to prevent the compiler from synthesizing
   // default definitions; they are deliberately left undefined.
Index: src/vsip/core/setup_assign.hpp
===================================================================
--- src/vsip/core/setup_assign.hpp	(revision 154174)
+++ src/vsip/core/setup_assign.hpp	(working copy)
@@ -25,6 +25,18 @@
 
 
 /***********************************************************************
+  Macors
+***********************************************************************/
+
+#if (VSIP_IMPL_PROFILER & VSIP_IMPL_PROFILER_PAR)
+#  define VSIP_IMPL_PROFILING_FEATURE_ENABLED   1
+#else
+#  define VSIP_IMPL_PROFILING_FEATURE_ENABLED   0
+#endif
+
+
+
+/***********************************************************************
   Declarations
 ***********************************************************************/
 
@@ -71,7 +83,8 @@
 
     void exec()
     {
-      impl::profile::Scope_event ev("Par_expr_holder");
+      VSIP_IMPL_PROFILE_FEATURE(impl::profile::Scope_event ev(
+	"Par_expr_holder"));
       par_expr_();
     }
 
@@ -105,7 +118,8 @@
 
     void exec()
     {
-      impl::profile::Scope_event ev("Par_assign_holder");
+      VSIP_IMPL_PROFILE_FEATURE(impl::profile::Scope_event
+	ev("Par_assign_holder"));
       par_assign_();
     }
 
@@ -140,7 +154,8 @@
 
     void exec()
     {
-      impl::profile::Scope_event ev("Simple_par_expr_holder");
+      VSIP_IMPL_PROFILE_FEATURE(impl::profile::Scope_event
+        ev("Simple_par_expr_holder"));
       par_expr_simple(dst_, src_);
     }
 
Index: src/vsip/opt/profile.cpp
===================================================================
--- src/vsip/opt/profile.cpp	(revision 154174)
+++ src/vsip/opt/profile.cpp	(working copy)
@@ -103,6 +103,11 @@
 }
 #endif // (VSIP_IMPL_PROFILE_TIMER == 4)
 
+#if (VSIP_IMPL_PROFILE_TIMER == 5)
+Mcoe_tmr_time::stamp_type Mcoe_tmr_time::clocks_per_sec;
+TMR_ts Mcoe_tmr_time::time0;
+#endif // (VSIP_IMPL_PROFILE_TIMER == 5)
+
 Profiler* prof;
 
 class SetupProf
Index: src/vsip/opt/pas/block.hpp
===================================================================
--- src/vsip/opt/pas/block.hpp	(revision 154174)
+++ src/vsip/opt/pas/block.hpp	(working copy)
@@ -161,7 +161,7 @@
 
   long real_num_procs;
   rc = pas_pset_get_npnums(map.impl_ll_pset(), &real_num_procs);
-  assert(rc == CE_SUCCESS);
+  VSIP_IMPL_CHECK_RC(rc, "pas_pset_get_npnums");
 
   // Check that we've dropped the same number of processors
   // from both the pset and the group dims.
Index: src/vsip/opt/pas/assign_eb.hpp
===================================================================
--- src/vsip/opt/pas/assign_eb.hpp	(revision 154174)
+++ src/vsip/opt/pas/assign_eb.hpp	(working copy)
@@ -89,7 +89,8 @@
     pas_pset_get_pnums_list(dst_pset, &dst_pnums, &dst_npnums);
     all_pnums = pas_pset_combine(src_pnums, dst_pnums, PAS_PSET_UNION,
 				 &all_npnums);
-    pas_pset_create(all_pnums, 0, &all_pset);
+    rc = pas_pset_create(all_pnums, 0, &all_pset);
+    VSIP_IMPL_CHECK_RC(rc, "pas_pset_create");
 
     free(src_pnums);
     free(dst_pnums);
@@ -113,7 +114,7 @@
 	pas::Pas_datatype<T1>::value(),
 	0,
 	&local_nbytes);
-      assert(rc == CE_SUCCESS);
+      VSIP_IMPL_CHECK_RC(rc, "pas_distribution_calc_tmp_local_nbytes");
 #if VERBOSE
       std::cout << "[" << local_processor() << "] "
 		<< "local_nbytes = " << local_nbytes << std::endl;
@@ -129,13 +130,13 @@
 	  max_components,
 	  PAS_ZERO,
 	  &tmp_pbuf_);
-	assert(rc == CE_SUCCESS);
+	VSIP_IMPL_CHECK_RC(rc, "pas_pbuf_create");
 	
 	rc = pas_move_desc_create(reserved_flags, &move_desc_);
-	assert(rc == CE_SUCCESS);
+	VSIP_IMPL_CHECK_RC(rc, "pas_move_desc_create");
 
 	rc = pas_move_desc_set_tmp_pbuf(move_desc_, tmp_pbuf_, 0);
-	assert(rc == CE_SUCCESS);
+	VSIP_IMPL_CHECK_RC(rc, "pas_move_desc_set_tmp_pbuf");
 
 	pull_flags_ = PAS_WAIT;
       }
@@ -155,8 +156,10 @@
 		    pull_flags_ | VSIP_IMPL_PAS_XFER_ENGINE |
 		    VSIP_IMPL_PAS_SEM_GIVE_AFTER,
 		    &xfer_handle_); 
-      assert(rc == CE_SUCCESS);
+      VSIP_IMPL_CHECK_RC(rc, "pas_push_setup");
     }
+    rc = pas_pset_close(all_pset, 0);
+    VSIP_IMPL_CHECK_RC(rc, "pas_pset_close");
   }
 
   ~Par_assign()
@@ -169,16 +172,16 @@
     if (pas_pset_is_member(src_pset))
     {
       rc = pas_xfer_free(xfer_handle_);
-      assert(rc == CE_SUCCESS);
+      VSIP_IMPL_CHECK_RC(rc, "pas_xfer_free");
     }
 
     if (move_desc_ != NULL)
     {
       rc = pas_move_desc_destroy(move_desc_, reserved_flags);
-      assert(rc == CE_SUCCESS);
+      VSIP_IMPL_CHECK_RC(rc, "pas_move_desc_destroy");
       
       rc = pas_pbuf_destroy(tmp_pbuf_, reserved_flags);
-      assert(rc == CE_SUCCESS);
+      VSIP_IMPL_CHECK_RC(rc, "pas_pbuf_destroy");
     }
   }
 
@@ -225,7 +228,7 @@
 		    xfer_handle_,
 		    PAS_WAIT,
 		    NULL);
-      assert(rc == CE_SUCCESS);
+      VSIP_IMPL_CHECK_RC(rc, "pas_xfer_start");
 #if VERBOSE
       std::cout << "[" << local_processor() << "] "
 		<< "push done" << std::endl << std::flush;
Index: src/vsip/opt/pas/assign_direct.hpp
===================================================================
--- src/vsip/opt/pas/assign_direct.hpp	(revision 154174)
+++ src/vsip/opt/pas/assign_direct.hpp	(working copy)
@@ -760,7 +760,7 @@
 	0,
 	pull_flags | PAS_PUSH | VSIP_IMPL_PAS_XFER_ENGINE,
 	NULL);
-      assert(rc == CE_SUCCESS);
+      VSIP_IMPL_CHECK_RC(rc, "pas_move_nbytes");
     }
   }
   pas::semaphore_give(dst_pset, ready_sem_index_);
Index: src/vsip/opt/pas/param.hpp
===================================================================
--- src/vsip/opt/pas/param.hpp	(revision 154174)
+++ src/vsip/opt/pas/param.hpp	(working copy)
@@ -47,18 +47,21 @@
 #  define VSIP_IMPL_PAS_HEAP_SIZE 0x100000
 #endif
 
+#define VSIP_IMPL_PAS_SHARE_DYNAMIC_XFER 1
+
 #if VSIP_IMPL_PAS_USE_INTERRUPT()
 #  define VSIP_IMPL_PAS_SEM_GIVE_AFTER PAS_SEM_GIVE_INTERRUPT_AFTER
 #else
 #  define VSIP_IMPL_PAS_SEM_GIVE_AFTER PAS_SEM_GIVE_AFTER
 #endif
 
-#define VSIP_IMPL_CHECK_RC(rc, where)                                    \
- if (rc !=  CE_SUCCESS) {                                      \
-     err_print(rc, ERR_GET_ALL);                               \
-     printf("CE%ld %s L%d\n", ce_getid(), where, __LINE__);    \
-     exit(1); }
+#define VSIP_IMPL_CHECK_RC(rc, where)					\
+  if (rc != CE_SUCCESS)							\
+  {									\
+     err_print(rc, ERR_GET_ALL);					\
+     printf("CE%ld %s %s L%d\n", ce_getid(), where, __FILE__, __LINE__);\
+     assert(0);								\
+     abort();								\
+  }
 
-
-
 #endif // VSIP_IMPL_PAS_PARAM_HPP
Index: src/vsip/opt/pas/services.hpp
===================================================================
--- src/vsip/opt/pas/services.hpp	(revision 154174)
+++ src/vsip/opt/pas/services.hpp	(working copy)
@@ -220,7 +220,7 @@
       pnums[i] = pvec_[i];
     pnums[size_] = PAS_PNUMS_TERM;
     long rc = pas_pset_create(pnums, 0, &pset_);
-    assert(rc == CE_SUCCESS);
+    VSIP_IMPL_CHECK_RC(rc, "pas_pset_create");
     delete[] pnums;
 
     bcast_.reset(new pas::Broadcast(impl_ll_pset()));
@@ -242,7 +242,7 @@
       pnums[i] = pvec_[i];
     pnums[size_] = PAS_PNUMS_TERM;
     long rc = pas_pset_create(pnums, 0, &pset_);
-    assert(rc == CE_SUCCESS);
+    VSIP_IMPL_CHECK_RC(rc, "pas_pset_create");
     delete[] pnums;
 
     bcast_.reset(new pas::Broadcast(impl_ll_pset()));
@@ -252,7 +252,7 @@
   {
     bcast_.reset(0);
     long rc = pas_pset_close(pset_, 0);
-    assert(rc == CE_SUCCESS);
+    VSIP_IMPL_CHECK_RC(rc, "pas_pset_close");
   }
 
   ~Communicator()
@@ -266,7 +266,7 @@
   void barrier() const
   {
     long rc = pas_barrier_sync(pset_, 0, PAS_YIELD | PAS_DMA);
-    assert(rc == CE_SUCCESS);
+    VSIP_IMPL_CHECK_RC(rc, "pas_barrier_sync");
   }
 
   template <typename T>
@@ -326,7 +326,7 @@
   copy[pvec.size()] = PAS_PNUMS_TERM;
 
   long rc = pas_pset_create(&copy[0], 0, &pset);
-  assert(rc == CE_SUCCESS);
+  VSIP_IMPL_CHECK_RC(rc, "pas_pset_create");
 }
 
 
@@ -335,7 +335,7 @@
 destroy_ll_pset(par_ll_pset_type& pset)
 {
   long rc = pas_pset_close(pset, 0);
-  assert(rc == CE_SUCCESS);
+  VSIP_IMPL_CHECK_RC(rc, "destroy_ll_pset");
 }
 
 
@@ -355,7 +355,7 @@
 }
 
 
-/// Par_service class for when no services are available.
+/// Par_service class for when using PAS parallel services.
 
 class Par_service
 {
@@ -479,13 +479,23 @@
       rc = pas_net_open(net_handle_);
       VSIP_IMPL_CHECK_RC(rc,"pas_net_open");
 
+#if VSIP_IMPL_PAS_SHARE_DYNAMIC_XFER == 1
+      rc = pas_dynamic_xfer_create(size, 3, 0, &dynamic_xfer_);
+      VSIP_IMPL_CHECK_RC(rc, "pas_dynamic_xfer_create");
+#endif
+
       default_communicator_.initialize(rank, size);
     }
 
   ~Par_service()
     {
+      long rc;
+#if VSIP_IMPL_PAS_SHARE_DYNAMIC_XFER == 1
+      rc = pas_dynamic_xfer_destroy(dynamic_xfer_, 0);
+      VSIP_IMPL_CHECK_RC(rc, "pas_dynamic_xfer_destroy");
+#endif
       default_communicator_.cleanup();
-      long rc = pas_net_close(net_handle_);
+      rc = pas_net_close(net_handle_);
       VSIP_IMPL_CHECK_RC(rc, "pas_net_close");
       valid_ = 0;
     }
@@ -495,11 +505,19 @@
       return default_communicator_;
     }
 
+#if VSIP_IMPL_PAS_SHARE_DYNAMIC_XFER == 1
+  PAS_dynamic_xfer_handle dynamic_xfer() const
+  { return dynamic_xfer_; }
+#endif
+
 private:
   static communicator_type default_communicator_;
 
   int			   valid_;
   PAS_net_handle           net_handle_;
+#if VSIP_IMPL_PAS_SHARE_DYNAMIC_XFER == 1
+  PAS_dynamic_xfer_handle dynamic_xfer_;
+#endif
 };
 
 
Index: src/vsip/opt/pas/assign.hpp
===================================================================
--- src/vsip/opt/pas/assign.hpp	(revision 154174)
+++ src/vsip/opt/pas/assign.hpp	(working copy)
@@ -89,7 +89,8 @@
     pas_pset_get_pnums_list(dst_pset, &dst_pnums, &dst_npnums);
     all_pnums = pas_pset_combine(src_pnums, dst_pnums, PAS_PSET_UNION,
 				 &all_npnums);
-    pas_pset_create(all_pnums, 0, &all_pset);
+    rc = pas_pset_create(all_pnums, 0, &all_pset);
+    VSIP_IMPL_CHECK_RC(rc, "pas_pset_create");
 
     free(src_pnums);
     free(dst_pnums);
@@ -101,8 +102,12 @@
     move_desc_  = NULL;
     push_flags_ = PAS_WAIT;
 
+#if VSIP_IMPL_PAS_SHARE_DYNAMIC_XFER == 1
+    dynamic_xfer_ = vsip::vsipl::impl_par_service()->dynamic_xfer();
+#else
     rc = pas_dynamic_xfer_create(num_processors(), 3, 0, &dynamic_xfer_);
-    assert(rc == CE_SUCCESS);
+    VSIP_IMPL_CHECK_RC(rc, "pas_dynamic_xfer_create");
+#endif
 
     // Setup tmp buffer
     if (pas_pset_is_member(all_pset))
@@ -115,7 +120,7 @@
 	pas::Pas_datatype<T1>::value(),
 	0,
 	&local_nbytes);
-      assert(rc == CE_SUCCESS);
+    VSIP_IMPL_CHECK_RC(rc, "pas_distributions_calc_tmp_local_nbytes");
 #if VERBOSE
       std::cout << "[" << local_processor() << "] "
 		<< "local_nbytes = " << local_nbytes << std::endl;
@@ -131,15 +136,18 @@
 	  max_components,
 	  PAS_ZERO,
 	  &tmp_pbuf_);
-	assert(rc == CE_SUCCESS);
+	VSIP_IMPL_CHECK_RC(rc, "pas_pbuf_create");
 	
 	rc = pas_move_desc_create(reserved_flags, &move_desc_);
-	assert(rc == CE_SUCCESS);
+	VSIP_IMPL_CHECK_RC(rc, "pas_move_desc_create");
 
 	rc = pas_move_desc_set_tmp_pbuf(move_desc_, tmp_pbuf_, 0);
-	assert(rc == CE_SUCCESS);
+	VSIP_IMPL_CHECK_RC(rc, "pas_move_desc_set_tmp_pbuf");
       }
     }
+
+    rc = pas_pset_close(all_pset, 0);
+    VSIP_IMPL_CHECK_RC(rc, "pas_pset_close");
   }
 
   ~Par_assign()
@@ -150,14 +158,16 @@
     if (move_desc_ != NULL)
     {
       rc = pas_move_desc_destroy(move_desc_, reserved_flags);
-      assert(rc == CE_SUCCESS);
+      VSIP_IMPL_CHECK_RC(rc, "pas_move_desc_destroy");
       
       rc = pas_pbuf_destroy(tmp_pbuf_, reserved_flags);
-      assert(rc == CE_SUCCESS);
+      VSIP_IMPL_CHECK_RC(rc, "pas_pbuf_destroy");
     }
 
+#if VSIP_IMPL_PAS_SHARE_DYNAMIC_XFER == 0
     rc = pas_dynamic_xfer_destroy(dynamic_xfer_, 0);
-    assert(rc == CE_SUCCESS);
+    VSIP_IMPL_CHECK_RC(rc, "pas_dynamic_xfer_destroy");
+#endif
   }
 
 
@@ -209,7 +219,7 @@
 		    push_flags_ | VSIP_IMPL_PAS_XFER_ENGINE |
 		    VSIP_IMPL_PAS_SEM_GIVE_AFTER,
 		    NULL); 
-      assert(rc == CE_SUCCESS);
+      VSIP_IMPL_CHECK_RC(rc, "pas_push");
 #if VERBOSE
       std::cout << "[" << local_processor() << "] "
 		<< "push done" << std::endl << std::flush;
Index: src/vsip/opt/profile.hpp
===================================================================
--- src/vsip/opt/profile.hpp	(revision 154174)
+++ src/vsip/opt/profile.hpp	(working copy)
@@ -28,12 +28,17 @@
 #  include <time.h>
 #endif
 
+#if (VSIP_IMPL_PROFILE_TIMER == 5)
+#  include <mcos.h>
+#endif
+
 /// Different operations that may be profiled, each is referred to
 /// as a 'feature'.
 #define VSIP_IMPL_PROFILER_SIGNAL   1
 #define VSIP_IMPL_PROFILER_MATVEC   2
 #define VSIP_IMPL_PROFILER_FNS      4
 #define VSIP_IMPL_PROFILER_USER     8
+#define VSIP_IMPL_PROFILER_PAR     16
 
 // Each may be enabled or disabled by defining a mask on the build 
 // command line that is a combination of the above values.  The absence
@@ -108,10 +113,11 @@
 ///
 /// The following timers are provided:
 ///  - No_time
-///  - Posix_time
-///  - PosixRealTime
-///  - Pentium_tsc_time - pentium timestamp counter
-///  - X86_64_tsc_time - pentium timestamp counter
+///  - Posix_time       - Posix clock()
+///  - Posix_real_time  - Posix clock_gettime(CLOCK_REALTIME, ...)
+///  - Pentium_tsc_time - pentium timestamp counter (ia32 asm)
+///  - X86_64_tsc_time  - pentium timestamp counter (x86_64 asm)
+///  - Mcoe_tmr_time    - MCOE tmr timer.
 
 struct No_time
 {
@@ -249,7 +255,6 @@
     { unsigned a, d; __asm__ __volatile__("rdtsc": "=a" (a), "=d" (d));
       time = ((stamp_type)a) | (((stamp_type)d) << 32); }
   static stamp_type zero() { return stamp_type(); }
-  static stamp_type f_clocks_per_sec() { return 3600000000LL; }
   static stamp_type add(stamp_type A, stamp_type B) { return A + B; }
   static stamp_type sub(stamp_type A, stamp_type B) { return A - B; }
   static float seconds(stamp_type time) { return (float)time / (float)clocks_per_sec; }
@@ -261,10 +266,76 @@
 };
 #endif // (VSIP_IMPL_PROFILE_TIMER == 4)
 
+#if (VSIP_IMPL_PROFILE_TIMER == 5)
+struct Mcoe_tmr_time
+{
+  typedef TMR_timespec stamp_type;
 
+  static bool const valid = true; 
+  static char* name() { return "Mcoe_tmr_time"; }
+  static void init()
+  {
+    tmr_timestamp(&time0); 
+    clocks_per_sec.tv_sec = 1;
+    clocks_per_sec.tv_nsec = 0;
+  }
 
+  static clockid_t const clock = CLOCK_REALTIME;
 
+  static void sample(stamp_type& time)
+  {
+    TMR_ts tmp;
+    tmr_timestamp(&tmp); 
+    tmr_diff(time0, tmp, 0L, &time);
+  }
 
+  static stamp_type zero() { return stamp_type(); }
+  // static stamp_type clocks_per_sec() { return CLOCKS_PER_SEC; }
+  static stamp_type add(stamp_type A, stamp_type B)
+  {
+    stamp_type res;
+    res.tv_nsec = A.tv_nsec + B.tv_nsec;
+    res.tv_sec  = A.tv_sec  + B.tv_sec;
+    if (res.tv_nsec >= 1000000000LL)
+    {
+      res.tv_nsec -= 1000000000LL;
+      res.tv_sec  += 1;
+    }
+    return res;
+  }
+
+  static stamp_type sub(stamp_type A, stamp_type B)
+  {
+    stamp_type res;
+    if (A.tv_nsec >= B.tv_nsec)
+    {
+      res.tv_nsec = A.tv_nsec - B.tv_nsec;
+      res.tv_sec  = A.tv_sec  - B.tv_sec;
+    }
+    else
+    {
+      res.tv_nsec = 1000000000LL - (B.tv_nsec - A.tv_nsec);
+      res.tv_sec  = A.tv_sec  - B.tv_sec - 1;
+    }
+    return res;
+  }
+
+  static float seconds(stamp_type time)
+    { return (float)(time.tv_sec) + (float)(time.tv_nsec) / 1e9; }
+
+  static unsigned long ticks(stamp_type time)
+    { return (unsigned long)(time.tv_sec * 1e9) + (unsigned long)time.tv_nsec; }
+  static bool is_zero(stamp_type const& stamp)
+    { return stamp.tv_nsec == 0 && stamp.tv_sec == 0; }
+
+  static stamp_type clocks_per_sec;
+  static TMR_ts time0;
+};
+#endif // (VSIP_IMPL_PROFILE_TIMER == 5)
+
+
+
+
 #if   (VSIP_IMPL_PROFILE_TIMER == 1)
 typedef Posix_time       DefaultTime;
 #elif (VSIP_IMPL_PROFILE_TIMER == 2)
@@ -273,6 +344,8 @@
 typedef Pentium_tsc_time DefaultTime;
 #elif (VSIP_IMPL_PROFILE_TIMER == 4)
 typedef X86_64_tsc_time DefaultTime;
+#elif (VSIP_IMPL_PROFILE_TIMER == 5)
+typedef Mcoe_tmr_time DefaultTime;
 #else // default choice if undefined or zero
 typedef No_time        DefaultTime;
 #endif
@@ -320,7 +393,7 @@
   unsigned	count_;
 
 public:
-  P_acc_timer() { total_ = stamp_type(); count_ = 0; }
+  P_acc_timer() { this->reset(); }
 
   stamp_type start() { TP::sample(start_); return start_; }
   stamp_type stop()
@@ -331,6 +404,9 @@
     return stop_;
   }
 
+  void reset()
+  { total_ = stamp_type(); count_ = 0; }
+
   stamp_type raw_delta() const { return TP::sub(stop_, start_); }
   float delta() const { return TP::seconds(TP::sub(stop_, start_)); }
   float total() const { return TP::seconds(total_); }
Index: src/vsip/opt/expr/serial_dispatch.hpp
===================================================================
--- src/vsip/opt/expr/serial_dispatch.hpp	(revision 154174)
+++ src/vsip/opt/expr/serial_dispatch.hpp	(working copy)
@@ -71,8 +71,14 @@
 	    typename SrcBlock>
   Eval_profile_policy(DstBlock const&, SrcBlock const& src)
     : event_( Expr_op_name<EvalExpr, SrcBlock>::tag(src), 
-              Expr_ops_per_point<SrcBlock>::value * 
-                Expr_ops_per_point<SrcBlock>::size(src) )
+              Expr_ops_per_point<SrcBlock>::value == 0
+	        // If ops_per_point is 0, then assume that operations
+	        // is a copy and record the number of bytes written.
+	        ? sizeof(typename DstBlock::value_type) *
+                  Expr_ops_per_point<SrcBlock>::size(src) 
+	        // Otherwise, record the number of flops.
+                : Expr_ops_per_point<SrcBlock>::value * 
+                  Expr_ops_per_point<SrcBlock>::size(src) )
   {}
 
 private:
Index: src/vsip/map.hpp
===================================================================
--- src/vsip/map.hpp	(revision 154174)
+++ src/vsip/map.hpp	(working copy)
@@ -289,7 +289,7 @@
 
   // Implementation functions.
   impl::par_ll_pset_type impl_ll_pset() const VSIP_NOTHROW
-    { return applied_pset_; }
+    { assert(this->impl_is_applied()); return applied_pset_; }
   impl_pvec_type const& impl_pvec() const { return data_->pvec_; }
   impl::Communicator&   impl_comm() const { return data_->comm_; }
   bool                  impl_is_applied() const { return dim_ != 0; }
Index: configure.ac
===================================================================
--- configure.ac	(revision 154174)
+++ configure.ac	(working copy)
@@ -331,7 +331,7 @@
 
 AC_ARG_ENABLE([timer],
   AS_HELP_STRING([--enable-timer=type],
-                 [Set profile timer type.  Choices include none, posix, realtime, pentiumtsc, x86_64_tsc [[none]].]),,
+                 [Set profile timer type.  Choices include none, posix, realtime, pentiumtsc, x86_64_tsc, mcoe_tmr [[none]].]),,
   [enable_timer=none])
 
 AC_ARG_ENABLE([cpu_mhz],
@@ -2087,6 +2087,17 @@
     [AC_MSG_ERROR(GNU in-line assembly for x86_64 rdtsc not supported.)] )
   AC_DEFINE_UNQUOTED(VSIP_IMPL_PROFILE_TIMER, 4,
     [Profile timer (1: Posix, 2: Posix realtime, 3: ia32 TSC, 4: x86_64 TSC).])
+elif test "$enable_timer" == "mcoe_tmr"; then
+  AC_MSG_CHECKING([if MCOE TMR timer is available.])
+  AC_LINK_IFELSE(
+    [AC_LANG_PROGRAM([[#include <mcos.h>]],
+		     [[TMR_ts ts;
+                       tmr_timestamp(&ts);]])],
+    [AC_MSG_RESULT(yes)],
+    [AC_MSG_ERROR(MCOE TMR timer not found.)] )
+
+  AC_DEFINE_UNQUOTED(VSIP_IMPL_PROFILE_TIMER, 5,
+    [Profile timer (1: Posix, 2: Posix realtime, 3: ia32 TSC, 4: x86_64 TSC).])
 fi
 
 
Index: benchmarks/create_map.hpp
===================================================================
--- benchmarks/create_map.hpp	(revision 154174)
+++ benchmarks/create_map.hpp	(working copy)
@@ -31,29 +31,56 @@
 struct Create_map<Dim, vsip::Local_map>
 {
   typedef vsip::Local_map type;
-  static type exec() { return type(); }
+  static type exec(char) { return type(); }
 };
 
 template <vsip::dimension_type Dim>
 struct Create_map<Dim, vsip::Global_map<Dim> >
 {
   typedef vsip::Global_map<Dim> type;
-  static type exec() { return type(); }
+  static type exec(char) { return type(); }
 };
 
 template <typename Dist0, typename Dist1, typename Dist2>
 struct Create_map<1, vsip::Map<Dist0, Dist1, Dist2> >
 {
   typedef vsip::Map<Dist0, Dist1, Dist2> type;
-  static type exec() { return type(vsip::num_processors()); }
+  static type exec(char type)
+  {
+    length_type np = num_processors();
+    switch(type)
+    {
+    default:
+    case 'a':
+      // 'a' - all processors
+      return Map<>(num_processors());
+    case '1':
+      // '1' - first processor
+      return Map<>(1);
+    case '2':
+    {
+      // '2' - last processor
+      Vector<processor_type> pset(1); pset.put(0, np-1);
+      return Map<>(pset, 1);
+    }
+    case 'b':
+    {
+      // 'b' - non-root processors
+      Vector<processor_type> pset(np-1);
+      for (index_type i=0; i<np; ++i)
+	pset.put(i, i+1);
+      return Map<>(pset, np-1);
+    }
+    }
+  }
 };
 
 template <vsip::dimension_type Dim,
 	  typename             MapT>
 MapT
-create_map()
+create_map(char type)
 {
-  return Create_map<Dim, MapT>::exec();
+  return Create_map<Dim, MapT>::exec(type);
 }
 
 
Index: benchmarks/copy.cpp
===================================================================
--- benchmarks/copy.cpp	(revision 154174)
+++ benchmarks/copy.cpp	(working copy)
@@ -25,6 +25,7 @@
 
 #include <vsip_csl/test.hpp>
 #include "loop.hpp"
+#include "create_map.hpp"
 
 using namespace vsip;
 using namespace vsip_csl;
@@ -77,6 +78,9 @@
     }
     
     vsip::impl::profile::Timer t1;
+
+    if (pre_sync_)
+      vsip::impl::default_communicator().barrier();
     
     t1.start();
     for (index_type l=0; l<loop; ++l)
@@ -92,22 +96,20 @@
     time = t1.delta();
   }
 
-  t_vcopy(SrcMapT src_map, DstMapT dst_map)
-    : src_map_(src_map), dst_map_(dst_map)
+  t_vcopy(SrcMapT src_map, DstMapT dst_map, bool pre_sync)
+    : src_map_(src_map), dst_map_(dst_map), pre_sync_(pre_sync)
   {}
 
   // Member data.
   SrcMapT	src_map_;
   DstMapT	dst_map_;
+  bool          pre_sync_;
 };
 
 
 
-
-
-
 /***********************************************************************
-  Vector copy - Chained_assign
+  Vector copy - Par_assign ImplTag (setup amortized to zero)
 ***********************************************************************/
 
 template <typename T,
@@ -141,6 +143,10 @@
     vsip::impl::Par_assign<dim, T, T, dst_block_t, src_block_t,
                            ParAssignImpl>
       cpa(Z, A);
+
+    if (pre_sync_)
+      vsip::impl::default_communicator().barrier();
+
     t1.start();
     for (index_type l=0; l<loop; ++l)
     {
@@ -157,17 +163,22 @@
     time = t1.delta();
   }
 
-  t_vcopy(SrcMapT src_map, DstMapT dst_map)
-    : src_map_(src_map), dst_map_(dst_map)
+  t_vcopy(SrcMapT src_map, DstMapT dst_map, bool pre_sync)
+    : src_map_(src_map), dst_map_(dst_map), pre_sync_(pre_sync)
   {}
 
   // Member data.
   SrcMapT	src_map_;
   DstMapT	dst_map_;
+  bool          pre_sync_;
 };
 
 
 
+/***********************************************************************
+  Vector copy - Par_assign ImplTag (setup not amortized)
+***********************************************************************/
+
 template <typename T,
 	  typename SrcMapT,
 	  typename DstMapT,
@@ -196,6 +207,9 @@
     
     vsip::impl::profile::Timer t1;
 
+    if (pre_sync_)
+      vsip::impl::default_communicator().barrier();
+
     t1.start();
     for (index_type l=0; l<loop; ++l)
     {
@@ -215,13 +229,14 @@
     time = t1.delta();
   }
 
-  t_vcopy(SrcMapT src_map, DstMapT dst_map)
-    : src_map_(src_map), dst_map_(dst_map)
+  t_vcopy(SrcMapT src_map, DstMapT dst_map, bool pre_sync)
+    : src_map_(src_map), dst_map_(dst_map), pre_sync_(pre_sync)
   {}
 
   // Member data.
   SrcMapT	src_map_;
   DstMapT	dst_map_;
+  bool          pre_sync_;
 };
 
 
@@ -257,6 +272,9 @@
     vsip::impl::profile::Timer t1;
 
     Setup_assign expr(Z, A);
+
+    if (pre_sync_)
+      vsip::impl::default_communicator().barrier();
     
     t1.start();
     for (index_type l=0; l<loop; ++l)
@@ -272,12 +290,14 @@
     time = t1.delta();
   }
 
-  t_vcopy(SrcMapT src_map, DstMapT dst_map)
-    : src_map_(src_map), dst_map_(dst_map) {}
+  t_vcopy(SrcMapT src_map, DstMapT dst_map, bool pre_sync)
+    : src_map_(src_map), dst_map_(dst_map), pre_sync_(pre_sync)
+  {}
 
   // Member data.
   SrcMapT	src_map_;
   DstMapT	dst_map_;
+  bool          pre_sync_;
 };
 
 
@@ -292,7 +312,7 @@
 {
   typedef t_vcopy<T, Local_map, Local_map, ImplTag> base_type;
   t_vcopy_local()
-    : base_type(Local_map(), Local_map()) 
+    : base_type(Local_map(), Local_map(), false) 
   {}
 };
 
@@ -302,47 +322,19 @@
 {
   typedef t_vcopy<T, Map<>, Map<>, ImplTag> base_type;
   t_vcopy_root()
-    : base_type(Map<>(), Map<>()) 
+    : base_type(Map<>(), Map<>(), false)
   {}
 };
 
-inline Map<>
-create_map(char type)
-{
-  length_type np = num_processors();
-  switch(type)
-  {
-  default:
-  case 'a':
-    // 'a' - all processors
-    return Map<>(num_processors());
-  case '1':
-    // '1' - first processor
-    return Map<>(1);
-  case '2':
-  {
-    // '2' - last processor
-    Vector<processor_type> pset(1); pset.put(0, np-1);
-    return Map<>(pset, 1);
-  }
-  case 'b':
-  {
-    // 'b' - non-root processors
-    Vector<processor_type> pset(np-1);
-    for (index_type i=0; i<np; ++i)
-      pset.put(i, i+1);
-    return Map<>(pset, np-1);
-  }
-  }
-}
-
 template <typename T,
 	  typename ImplTag>
 struct t_vcopy_redist : t_vcopy<T, Map<>, Map<>, ImplTag>
 {
   typedef t_vcopy<T, Map<>, Map<>, ImplTag> base_type;
-  t_vcopy_redist(char src_dist, char dst_dist)
-    : base_type(create_map(src_dist), create_map(dst_dist))
+  t_vcopy_redist(char src_dist, char dst_dist, bool pre_sync)
+    : base_type(create_map<1, Map<> >(src_dist),
+		create_map<1, Map<> >(dst_dist),
+		pre_sync)
   {}
 };
 
@@ -359,6 +351,8 @@
 test(Loop1P& loop, int what)
 {
   typedef float F;
+
+  // Typedefs for parallel assignment algorithms.
 #if VSIP_IMPL_PAR_SERVICE == 1
   typedef vsip::impl::Chained_assign  Ca;
   typedef vsip::impl::Blkvec_assign   Bva;
@@ -368,6 +362,9 @@
   typedef vsip::impl::Direct_pas_assign Pa_d;
 #endif
 
+  // typedef fors pre-sync barrier policy.
+  bool const ps = (loop.user_param_) ? true : false;
+
   switch (what)
   {
   case  1: loop(t_vcopy_local<float, Impl_assign>()); break;
@@ -379,97 +376,97 @@
   case  4: loop(t_vcopy_root<float, Impl_pa<Pa> >()); break;
 #endif
 
-  case 10: loop(t_vcopy_redist<float, Impl_assign>('1', '1')); break;
-  case 11: loop(t_vcopy_redist<float, Impl_assign>('1', 'a'));  break;
-  case 12: loop(t_vcopy_redist<float, Impl_assign>('a', '1')); break;
-  case 13: loop(t_vcopy_redist<float, Impl_assign>('a', 'a'));  break;
-  case 14: loop(t_vcopy_redist<float, Impl_assign>('1', '2')); break;
-  case 15: loop(t_vcopy_redist<float, Impl_assign>('1', 'b')); break;
+  case 10: loop(t_vcopy_redist<float, Impl_assign>('1', '1', ps)); break;
+  case 11: loop(t_vcopy_redist<float, Impl_assign>('1', 'a', ps));  break;
+  case 12: loop(t_vcopy_redist<float, Impl_assign>('a', '1', ps)); break;
+  case 13: loop(t_vcopy_redist<float, Impl_assign>('a', 'a', ps));  break;
+  case 14: loop(t_vcopy_redist<float, Impl_assign>('1', '2', ps)); break;
+  case 15: loop(t_vcopy_redist<float, Impl_assign>('1', 'b', ps)); break;
 
-  case 16: loop(t_vcopy_redist<complex<float>, Impl_assign>('1', '2')); break;
+  case 16: loop(t_vcopy_redist<complex<float>, Impl_assign>('1', '2', ps)); break;
 
-  case 20: loop(t_vcopy_redist<float, Impl_sa>('1', '1')); break;
-  case 21: loop(t_vcopy_redist<float, Impl_sa>('1', 'a')); break;
-  case 22: loop(t_vcopy_redist<float, Impl_sa>('a', '1')); break;
-  case 23: loop(t_vcopy_redist<float, Impl_sa>('a', 'a')); break;
-  case 24: loop(t_vcopy_redist<float, Impl_sa>('1', '2')); break;
-  case 25: loop(t_vcopy_redist<float, Impl_sa>('1', 'b')); break;
+  case 20: loop(t_vcopy_redist<float, Impl_sa>('1', '1', ps)); break;
+  case 21: loop(t_vcopy_redist<float, Impl_sa>('1', 'a', ps)); break;
+  case 22: loop(t_vcopy_redist<float, Impl_sa>('a', '1', ps)); break;
+  case 23: loop(t_vcopy_redist<float, Impl_sa>('a', 'a', ps)); break;
+  case 24: loop(t_vcopy_redist<float, Impl_sa>('1', '2', ps)); break;
+  case 25: loop(t_vcopy_redist<float, Impl_sa>('1', 'b', ps)); break;
 
-  case 26: loop(t_vcopy_redist<complex<float>, Impl_sa>('1', '2')); break;
+  case 26: loop(t_vcopy_redist<complex<float>, Impl_sa>('1', '2', ps)); break;
 
 #if VSIP_IMPL_PAR_SERVICE == 1
 
-  case 100: loop(t_vcopy_redist<F, Impl_pa<Ca> >('1', '1')); break;
-  case 101: loop(t_vcopy_redist<F, Impl_pa<Ca> >('1', 'a')); break;
-  case 102: loop(t_vcopy_redist<F, Impl_pa<Ca> >('a', '1')); break;
-  case 103: loop(t_vcopy_redist<F, Impl_pa<Ca> >('a', 'a')); break;
-  case 104: loop(t_vcopy_redist<F, Impl_pa<Ca> >('1', '2')); break;
-  case 105: loop(t_vcopy_redist<F, Impl_pa<Ca> >('1', 'b')); break;
+  case 100: loop(t_vcopy_redist<F, Impl_pa<Ca> >('1', '1', ps)); break;
+  case 101: loop(t_vcopy_redist<F, Impl_pa<Ca> >('1', 'a', ps)); break;
+  case 102: loop(t_vcopy_redist<F, Impl_pa<Ca> >('a', '1', ps)); break;
+  case 103: loop(t_vcopy_redist<F, Impl_pa<Ca> >('a', 'a', ps)); break;
+  case 104: loop(t_vcopy_redist<F, Impl_pa<Ca> >('1', '2', ps)); break;
+  case 105: loop(t_vcopy_redist<F, Impl_pa<Ca> >('1', 'b', ps)); break;
 
-  case 110: loop(t_vcopy_redist<F, Impl_pa<Bva> >('1', '1')); break;
-  case 111: loop(t_vcopy_redist<F, Impl_pa<Bva> >('1', 'a')); break;
-  case 112: loop(t_vcopy_redist<F, Impl_pa<Bva> >('a', '1')); break;
-  case 113: loop(t_vcopy_redist<F, Impl_pa<Bva> >('a', 'a')); break;
-  case 114: loop(t_vcopy_redist<F, Impl_pa<Bva> >('1', '2')); break;
-  case 115: loop(t_vcopy_redist<F, Impl_pa<Bva> >('1', 'b')); break;
+  case 110: loop(t_vcopy_redist<F, Impl_pa<Bva> >('1', '1', ps)); break;
+  case 111: loop(t_vcopy_redist<F, Impl_pa<Bva> >('1', 'a', ps)); break;
+  case 112: loop(t_vcopy_redist<F, Impl_pa<Bva> >('a', '1', ps)); break;
+  case 113: loop(t_vcopy_redist<F, Impl_pa<Bva> >('a', 'a', ps)); break;
+  case 114: loop(t_vcopy_redist<F, Impl_pa<Bva> >('1', '2', ps)); break;
+  case 115: loop(t_vcopy_redist<F, Impl_pa<Bva> >('1', 'b', ps)); break;
 
-  case 150: loop(t_vcopy_redist<F, Impl_pa_na<Ca> >('1', '1')); break;
-  case 151: loop(t_vcopy_redist<F, Impl_pa_na<Ca> >('1', 'a')); break;
-  case 152: loop(t_vcopy_redist<F, Impl_pa_na<Ca> >('a', '1')); break;
-  case 153: loop(t_vcopy_redist<F, Impl_pa_na<Ca> >('a', 'a')); break;
-  case 154: loop(t_vcopy_redist<F, Impl_pa_na<Ca> >('1', '2')); break;
-  case 155: loop(t_vcopy_redist<F, Impl_pa_na<Ca> >('1', 'b')); break;
+  case 150: loop(t_vcopy_redist<F, Impl_pa_na<Ca> >('1', '1', ps)); break;
+  case 151: loop(t_vcopy_redist<F, Impl_pa_na<Ca> >('1', 'a', ps)); break;
+  case 152: loop(t_vcopy_redist<F, Impl_pa_na<Ca> >('a', '1', ps)); break;
+  case 153: loop(t_vcopy_redist<F, Impl_pa_na<Ca> >('a', 'a', ps)); break;
+  case 154: loop(t_vcopy_redist<F, Impl_pa_na<Ca> >('1', '2', ps)); break;
+  case 155: loop(t_vcopy_redist<F, Impl_pa_na<Ca> >('1', 'b', ps)); break;
 
-  case 160: loop(t_vcopy_redist<F, Impl_pa_na<Bva> >('1', '1')); break;
-  case 161: loop(t_vcopy_redist<F, Impl_pa_na<Bva> >('1', 'a')); break;
-  case 162: loop(t_vcopy_redist<F, Impl_pa_na<Bva> >('a', '1')); break;
-  case 163: loop(t_vcopy_redist<F, Impl_pa_na<Bva> >('a', 'a')); break;
-  case 164: loop(t_vcopy_redist<F, Impl_pa_na<Bva> >('1', '2')); break;
-  case 165: loop(t_vcopy_redist<F, Impl_pa_na<Bva> >('1', 'b')); break;
+  case 160: loop(t_vcopy_redist<F, Impl_pa_na<Bva> >('1', '1', ps)); break;
+  case 161: loop(t_vcopy_redist<F, Impl_pa_na<Bva> >('1', 'a', ps)); break;
+  case 162: loop(t_vcopy_redist<F, Impl_pa_na<Bva> >('a', '1', ps)); break;
+  case 163: loop(t_vcopy_redist<F, Impl_pa_na<Bva> >('a', 'a', ps)); break;
+  case 164: loop(t_vcopy_redist<F, Impl_pa_na<Bva> >('1', '2', ps)); break;
+  case 165: loop(t_vcopy_redist<F, Impl_pa_na<Bva> >('1', 'b', ps)); break;
 
 #elif VSIP_IMPL_PAR_SERVICE == 2
 
-  case 200: loop(t_vcopy_redist<F, Impl_pa<Pa> >('1', '1')); break;
-  case 201: loop(t_vcopy_redist<F, Impl_pa<Pa> >('1', 'a')); break;
-  case 202: loop(t_vcopy_redist<F, Impl_pa<Pa> >('a', '1')); break;
-  case 203: loop(t_vcopy_redist<F, Impl_pa<Pa> >('a', 'a')); break;
-  case 204: loop(t_vcopy_redist<F, Impl_pa<Pa> >('1', '2')); break;
-  case 205: loop(t_vcopy_redist<F, Impl_pa<Pa> >('1', 'b')); break;
+  case 200: loop(t_vcopy_redist<F, Impl_pa<Pa> >('1', '1', ps)); break;
+  case 201: loop(t_vcopy_redist<F, Impl_pa<Pa> >('1', 'a', ps)); break;
+  case 202: loop(t_vcopy_redist<F, Impl_pa<Pa> >('a', '1', ps)); break;
+  case 203: loop(t_vcopy_redist<F, Impl_pa<Pa> >('a', 'a', ps)); break;
+  case 204: loop(t_vcopy_redist<F, Impl_pa<Pa> >('1', '2', ps)); break;
+  case 205: loop(t_vcopy_redist<F, Impl_pa<Pa> >('1', 'b', ps)); break;
 
-  case 210: loop(t_vcopy_redist<F, Impl_pa<Pa_eb> >('1', '1')); break;
-  case 211: loop(t_vcopy_redist<F, Impl_pa<Pa_eb> >('1', 'a')); break;
-  case 212: loop(t_vcopy_redist<F, Impl_pa<Pa_eb> >('a', '1')); break;
-  case 213: loop(t_vcopy_redist<F, Impl_pa<Pa_eb> >('a', 'a')); break;
-  case 214: loop(t_vcopy_redist<F, Impl_pa<Pa_eb> >('1', '2')); break;
-  case 215: loop(t_vcopy_redist<F, Impl_pa<Pa_eb> >('1', 'b')); break;
+  case 210: loop(t_vcopy_redist<F, Impl_pa<Pa_eb> >('1', '1', ps)); break;
+  case 211: loop(t_vcopy_redist<F, Impl_pa<Pa_eb> >('1', 'a', ps)); break;
+  case 212: loop(t_vcopy_redist<F, Impl_pa<Pa_eb> >('a', '1', ps)); break;
+  case 213: loop(t_vcopy_redist<F, Impl_pa<Pa_eb> >('a', 'a', ps)); break;
+  case 214: loop(t_vcopy_redist<F, Impl_pa<Pa_eb> >('1', '2', ps)); break;
+  case 215: loop(t_vcopy_redist<F, Impl_pa<Pa_eb> >('1', 'b', ps)); break;
 
-  case 220: loop(t_vcopy_redist<F, Impl_pa<Pa_d> >('1', '1')); break;
-  case 221: loop(t_vcopy_redist<F, Impl_pa<Pa_d> >('1', 'a')); break;
-  case 222: loop(t_vcopy_redist<F, Impl_pa<Pa_d> >('a', '1')); break;
-  case 223: loop(t_vcopy_redist<F, Impl_pa<Pa_d> >('a', 'a')); break;
-  case 224: loop(t_vcopy_redist<F, Impl_pa<Pa_d> >('1', '2')); break;
-  case 225: loop(t_vcopy_redist<F, Impl_pa<Pa_d> >('1', 'b')); break;
+  case 220: loop(t_vcopy_redist<F, Impl_pa<Pa_d> >('1', '1', ps)); break;
+  case 221: loop(t_vcopy_redist<F, Impl_pa<Pa_d> >('1', 'a', ps)); break;
+  case 222: loop(t_vcopy_redist<F, Impl_pa<Pa_d> >('a', '1', ps)); break;
+  case 223: loop(t_vcopy_redist<F, Impl_pa<Pa_d> >('a', 'a', ps)); break;
+  case 224: loop(t_vcopy_redist<F, Impl_pa<Pa_d> >('1', '2', ps)); break;
+  case 225: loop(t_vcopy_redist<F, Impl_pa<Pa_d> >('1', 'b', ps)); break;
 
-  case 250: loop(t_vcopy_redist<F, Impl_pa_na<Pa> >('1', '1')); break;
-  case 251: loop(t_vcopy_redist<F, Impl_pa_na<Pa> >('1', 'a')); break;
-  case 252: loop(t_vcopy_redist<F, Impl_pa_na<Pa> >('a', '1')); break;
-  case 253: loop(t_vcopy_redist<F, Impl_pa_na<Pa> >('a', 'a')); break;
-  case 254: loop(t_vcopy_redist<F, Impl_pa_na<Pa> >('1', '2')); break;
-  case 255: loop(t_vcopy_redist<F, Impl_pa_na<Pa> >('1', 'b')); break;
+  case 250: loop(t_vcopy_redist<F, Impl_pa_na<Pa> >('1', '1', ps)); break;
+  case 251: loop(t_vcopy_redist<F, Impl_pa_na<Pa> >('1', 'a', ps)); break;
+  case 252: loop(t_vcopy_redist<F, Impl_pa_na<Pa> >('a', '1', ps)); break;
+  case 253: loop(t_vcopy_redist<F, Impl_pa_na<Pa> >('a', 'a', ps)); break;
+  case 254: loop(t_vcopy_redist<F, Impl_pa_na<Pa> >('1', '2', ps)); break;
+  case 255: loop(t_vcopy_redist<F, Impl_pa_na<Pa> >('1', 'b', ps)); break;
 
-  case 260: loop(t_vcopy_redist<F, Impl_pa_na<Pa_eb> >('1', '1')); break;
-  case 261: loop(t_vcopy_redist<F, Impl_pa_na<Pa_eb> >('1', 'a')); break;
-  case 262: loop(t_vcopy_redist<F, Impl_pa_na<Pa_eb> >('a', '1')); break;
-  case 263: loop(t_vcopy_redist<F, Impl_pa_na<Pa_eb> >('a', 'a')); break;
-  case 264: loop(t_vcopy_redist<F, Impl_pa_na<Pa_eb> >('1', '2')); break;
-  case 265: loop(t_vcopy_redist<F, Impl_pa_na<Pa_eb> >('1', 'b')); break;
+  case 260: loop(t_vcopy_redist<F, Impl_pa_na<Pa_eb> >('1', '1', ps)); break;
+  case 261: loop(t_vcopy_redist<F, Impl_pa_na<Pa_eb> >('1', 'a', ps)); break;
+  case 262: loop(t_vcopy_redist<F, Impl_pa_na<Pa_eb> >('a', '1', ps)); break;
+  case 263: loop(t_vcopy_redist<F, Impl_pa_na<Pa_eb> >('a', 'a', ps)); break;
+  case 264: loop(t_vcopy_redist<F, Impl_pa_na<Pa_eb> >('1', '2', ps)); break;
+  case 265: loop(t_vcopy_redist<F, Impl_pa_na<Pa_eb> >('1', 'b', ps)); break;
 
-  case 270: loop(t_vcopy_redist<F, Impl_pa_na<Pa_d> >('1', '1')); break;
-  case 271: loop(t_vcopy_redist<F, Impl_pa_na<Pa_d> >('1', 'a')); break;
-  case 272: loop(t_vcopy_redist<F, Impl_pa_na<Pa_d> >('a', '1')); break;
-  case 273: loop(t_vcopy_redist<F, Impl_pa_na<Pa_d> >('a', 'a')); break;
-  case 274: loop(t_vcopy_redist<F, Impl_pa_na<Pa_d> >('1', '2')); break;
-  case 275: loop(t_vcopy_redist<F, Impl_pa_na<Pa_d> >('1', 'b')); break;
+  case 270: loop(t_vcopy_redist<F, Impl_pa_na<Pa_d> >('1', '1', ps)); break;
+  case 271: loop(t_vcopy_redist<F, Impl_pa_na<Pa_d> >('1', 'a', ps)); break;
+  case 272: loop(t_vcopy_redist<F, Impl_pa_na<Pa_d> >('a', '1', ps)); break;
+  case 273: loop(t_vcopy_redist<F, Impl_pa_na<Pa_d> >('a', 'a', ps)); break;
+  case 274: loop(t_vcopy_redist<F, Impl_pa_na<Pa_d> >('1', '2', ps)); break;
+  case 275: loop(t_vcopy_redist<F, Impl_pa_na<Pa_d> >('1', 'b', ps)); break;
 #endif
 
 
@@ -490,13 +487,18 @@
       << "  -23 -- float dist copy      (all  -> all)\n"
       << "  -24 -- float point-to-point (p0   -> p1)\n"
       << "  -25 -- float scatter2       (root -> all non-root)\n"
-      << " Using low-level Par_assign directly:\n"
-      << "  -30 -- float root copy      (root -> root)\n"
-      << "  -31 -- float scatter        (root -> all)\n"
-      << "  -32 -- float gather         (all  -> root)\n"
-      << "  -33 -- float dist copy      (all  -> all)\n"
-      << "  -34 -- float point-to-point (p0   -> p1)\n"
-      << "  -35 -- float scatter2       (root -> all non-root)\n"
+      << "\n MPI low-level Par_assign directly:\n"
+      << "  -100-105 -- Chained_assign\n"
+      << "  -110-115 -- Blkvec_assign\n"
+      << "  -150-155 -- Chained_assign (non-amortized setup)\n"
+      << "  -160-165 -- Blkvec_assign (non-amortized setup)\n"
+      << "\n PAS low-level Par_assign directly:\n"
+      << "  -200-205 -- Pas_assign\n"
+      << "  -210-215 -- Pas_assign_eb\n"
+      << "  -220-225 -- Direct_pas_assign\n"
+      << "  -250-255 -- Pas_assign (non-amortized setup)\n"
+      << "  -260-265 -- Pas_assign_eb (non-amortized setup)\n"
+      << "  -270-275 -- Direct_pas_assign (non-amortized setup)\n"
       ;
 
   default:
Index: benchmarks/loop.hpp
===================================================================
--- benchmarks/loop.hpp	(revision 154174)
+++ benchmarks/loop.hpp	(working copy)
@@ -14,6 +14,7 @@
   Included Files
 ***********************************************************************/
 
+#include <iostream>
 #include <algorithm>
 #include <vector>
 
@@ -59,7 +60,9 @@
   ops_per_sec,
   iob_per_sec,
   wiob_per_sec,
+  riob_per_sec,
   all_per_sec,
+  data_per_sec,
   secs_per_pt
 };
 
@@ -104,7 +107,8 @@
     stop_	 (21),
     cal_	 (4),
     do_cal_      (true),
-    loop_start_	 (10),
+    fix_loop_    (false),
+    loop_start_	 (1),
     samples_	 (1),
     goal_sec_	 (1.0),
     metric_      (pts_per_sec),
@@ -146,6 +150,7 @@
   unsigned	stop_;		// loop stop power-of-two
   int	 	cal_;		// calibration power-of-two
   bool          do_cal_;	// perform calibration
+  bool          fix_loop_;	// use fixed loop count for each size.
   int	 	loop_start_;
   unsigned	samples_;
   double        goal_sec_;	// measurement goal (in seconds)
@@ -200,6 +205,11 @@
     double ops = (double)M * fcn.wiob_per_point(M) * loop;
     return ops / (time * 1e6);
   }
+  else if (m == riob_per_sec)
+  {
+    double ops = (double)M * fcn.riob_per_point(M) * loop;
+    return ops / (time * 1e6);
+  }
   else if (m == secs_per_pt)
   {
     double pts = (double)M * loop;
@@ -257,69 +267,73 @@
   using vsip::Map;
   using vsip::Global_map;
   Vector<float, Dense<1, float, row1_type, Map<> > >
-    dist_time(nproc, Map<>(nproc));
+      dist_time(nproc, Map<>(nproc));
   Vector<float, Dense<1, float, row1_type, Global_map<1> > > glob_time(nproc);
 #else
   Vector<float, Dense<1, float, row1_type> > dist_time(nproc);
   Vector<float, Dense<1, float, row1_type> > glob_time(nproc);
 #endif
 
-  loop = (1 << loop_start_);
+  loop = loop_start_;
   M    = this->m_value(cal_);
 
   // calibrate --------------------------------------------------------
-  if (do_cal_)
+  if (do_cal_ && !fix_loop_)
   {
-  while (1)
-  {
-    // printf("%d: calib %5d\n", rank, loop);
-    BARRIER(comm);
-    fcn(M, loop, time);
-    BARRIER(comm);
+    float factor;
+    float factor_thresh = 1.05;
+    do 
+    {
+      BARRIER(comm);
+      fcn(M, loop, time);
+      BARRIER(comm);
 
-    LOCAL(dist_time).put(0, time);
-    glob_time = dist_time;
+      LOCAL(dist_time).put(0, time);
+      glob_time = dist_time;
 
-    Index<1> idx;
+      Index<1> idx;
 
-    time = maxval(LOCAL(glob_time), idx);
+      time = maxval(LOCAL(glob_time), idx);
 
-    if (time <= 0.01) time = 0.01;
-    // printf("%d: time %f\n", rank, time);
+      if (time <= 0.01) time = 0.01;
 
-    float factor = goal_sec_ / time;
-    if (factor < 1.0) factor += 0.1 * (1.0 - factor);
-    if ( loop == (size_t)(factor * loop) )
-      break;          // Avoid getting stuck when factor ~= 1 and loop is small
-    else
+      factor = goal_sec_ / time;
       loop = (size_t)(factor * loop);
-    if ( loop == 0 ) 
-      loop = 1; 
-    if ( loop == 1 )  // Quit if loop cannot get smaller
-      break;
-
-    if (factor >= 0.75 && factor <= 1.25)
-      break;
+      // printf("%d: time: %f  factor: %f  loop: %d\n", rank,time,factor,loop);
+      if ( loop == 0 ) 
+        loop = 1; 
+    } while (factor >= factor_thresh);
   }
-  }
 
   if (rank == 0)
   {
-    printf("# what             : %s (%d)\n", fcn.what(), what_);
-    printf("# nproc            : %d\n", (int)nproc);
-    printf("# ops_per_point(1) : %d\n", (int)fcn.ops_per_point(1));
-    printf("# riob_per_point(1): %d\n", fcn.riob_per_point(1));
-    printf("# wiob_per_point(1): %d\n", fcn.wiob_per_point(1));
-    printf("# metric           : %s\n",
-	   metric_ == pts_per_sec  ? "pts_per_sec" :
-	   metric_ == ops_per_sec  ? "ops_per_sec" :
-	   metric_ == iob_per_sec  ? "iob_per_sec" :
-	   metric_ == wiob_per_sec ? "wiob_per_sec" :
-	   metric_ == secs_per_pt  ? "secs_per_pt" :
-	                             "*unknown*");
-    if (this->note_)
-      printf("# note: %s\n", this->note_);
-    printf("# start_loop       : %lu\n", (unsigned long) loop);
+    if (metric_ == data_per_sec)
+    {
+      std::cout << "what," << fcn.what() << "," << what_ << std::endl;
+      std::cout << "nproc," << nproc << std::endl;
+      std::cout << "size,med,min,max,mem/pt,ops/pt,riob/pt,wiob/pt,loop,time"
+		<< std::endl;
+    }
+    else
+    {
+      printf("# what             : %s (%d)\n", fcn.what(), what_);
+      printf("# nproc            : %d\n", (int)nproc);
+      printf("# ops_per_point(1) : %d\n", (int)fcn.ops_per_point(1));
+      printf("# riob_per_point(1): %d\n", fcn.riob_per_point(1));
+      printf("# wiob_per_point(1): %d\n", fcn.wiob_per_point(1));
+      printf("# metric           : %s\n",
+	     metric_ == pts_per_sec  ? "pts_per_sec" :
+	     metric_ == ops_per_sec  ? "ops_per_sec" :
+	     metric_ == iob_per_sec  ? "iob_per_sec" :
+	     metric_ == riob_per_sec ? "riob_per_sec" :
+	     metric_ == wiob_per_sec ? "wiob_per_sec" :
+	     metric_ == data_per_sec ? "data_per_sec" :
+	     metric_ == secs_per_pt  ? "secs_per_pt" :
+	                               "*unknown*");
+      if (this->note_)
+	printf("# note: %s\n", this->note_);
+      printf("# start_loop       : %lu\n", (unsigned long) loop);
+    }
   }
 
 #if PARALLEL_LOOP
@@ -373,6 +387,18 @@
 	       this->metric(fcn, M, loop, mtime[(n_time-1)/2], pts_per_sec),
 	       this->metric(fcn, M, loop, mtime[(n_time-1)/2], ops_per_sec),
 	       this->metric(fcn, M, loop, mtime[(n_time-1)/2], iob_per_sec));
+      else if (this->metric_ == data_per_sec)
+	printf("%ld,%f,%f,%f,%f,%f,%f,%f,%ld,%f",
+	       (unsigned long) L,
+	       this->metric(fcn, M, loop, mtime[(n_time-1)/2], pts_per_sec),
+	       this->metric(fcn, M, loop, mtime[n_time-1],     pts_per_sec),
+	       this->metric(fcn, M, loop, mtime[0],            pts_per_sec),
+	       (float)fcn.mem_per_point(M),
+	       (float)fcn.ops_per_point(M),
+	       (float)fcn.riob_per_point(M),
+	       (float)fcn.wiob_per_point(M),
+	       (unsigned long)loop,
+	       mtime[(n_time-1)/2]);
       else if (n_time > 1)
 	// Note: max time is min op/s, and min time is max op/s
 	printf("%7lu %f %f %f", (unsigned long) L,
@@ -392,14 +418,17 @@
 
     time = mtime[(n_time-1)/2];
 
-    growth = 2.0 * fcn.ops_per_point(2*M) / fcn.ops_per_point(M);
-    time = time * growth;
+    if (!fix_loop_)
+    {
+      growth = 2.0 * fcn.ops_per_point(2*M) / fcn.ops_per_point(M);
+      time = time * growth;
 
-    float factor = goal_sec_ / time;
-    if (factor < 1.0) factor += 0.1 * (1.0 - factor);
-    loop = (int)(factor * loop);
+      float factor = goal_sec_ / time;
+      if (factor < 1.0) factor += 0.1 * (1.0 - factor);
+      loop = (int)(factor * loop);
 
-    if (loop < 1) loop = 1;
+      if (loop < 1) loop = 1;
+    }
   }
 }
 
@@ -432,7 +461,7 @@
   Vector<float, Dense<1, float, row1_type> > glob_time(nproc);
 #endif
 
-  loop = (1 << loop_start_);
+  loop = loop_start_;
 
   if (rank == 0)
   {
@@ -445,7 +474,9 @@
 	   metric_ == pts_per_sec  ? "pts_per_sec" :
 	   metric_ == ops_per_sec  ? "ops_per_sec" :
 	   metric_ == iob_per_sec  ? "iob_per_sec" :
+	   metric_ == riob_per_sec ? "riob_per_sec" :
 	   metric_ == wiob_per_sec ? "wiob_per_sec" :
+	   metric_ == data_per_sec ? "data_per_sec" :
 	   metric_ == secs_per_pt  ? "secs_per_pt" :
 	                             "*unknown*");
     if (this->note_)
Index: benchmarks/fft_sal.cpp
===================================================================
--- benchmarks/fft_sal.cpp	(revision 154174)
+++ benchmarks/fft_sal.cpp	(working copy)
@@ -88,10 +88,66 @@
     long eflag = 0;  // no caching hints
     fft_ziptx(&setup, &inout, 1, &tmp, size, dir, eflag);
   }
+
+  static void scale(
+    type        data,
+    length_type size,
+    float       s)
+  {
+    vsmulx(data.realp, 1, &s, data.realp, 1, size, 0);
+    vsmulx(data.imagp, 1, &s, data.imagp, 1, size, 0);
+  }
+
 };
 
 
 
+template <>
+struct sal_fft<complex<float>, Cmplx_inter_fmt>
+{
+  typedef COMPLEX* type;
+
+  static type to_ptr(std::complex<float>* ptr)
+  {
+    return (type)ptr;
+  }
+
+  static void fftop(
+    FFT_setup& setup,
+    type in,
+    type out,
+    type tmp,
+    int  size,
+    int  dir)
+  {
+    long eflag = 0;  // no caching hints
+    fft_coptx(&setup, in, 2, out, 2, tmp, size, dir, eflag);
+  }
+
+  static void fftip(
+    FFT_setup& setup,
+    type inout,
+    type tmp,
+    int  size,
+    int  dir)
+  {
+    long eflag = 0;  // no caching hints
+    fft_ciptx(&setup, inout, 2, tmp, size, dir, eflag);
+  }
+
+  static void scale(
+    type        data,
+    length_type size,
+    float       s)
+  {
+    float *d = reinterpret_cast<float*>(data);
+    vsmulx(d, 1, &s, d, 1, 2 * size, 0);
+  }
+
+};
+
+
+
 inline unsigned long
 ilog2(length_type size)    // assume size = 2^n, != 0, return n.
 {
@@ -112,6 +168,8 @@
 	  typename ComplexFmt>
 struct t_fft_op
 {
+  typedef impl::Scalar_of<T>::type scalar_type;
+
   char* what() { return "t_fft_op"; }
   int ops_per_point(length_type len)  { return fft_ops(len); }
   int riob_per_point(length_type) { return -1*(int)sizeof(T); }
@@ -135,6 +193,7 @@
     unsigned long nbytes  = 0;
     long          options = 0;
     long          dir     = FFT_FORWARD;
+    scalar_type   factor  = scalar_type(1) / size;
 
     fft_setup(log2N, options, &setup, &nbytes);
 
@@ -151,10 +210,23 @@
       typename traits::type tmp_ptr = traits::to_ptr(ext_tmp.data());
       typename traits::type Z_ptr = traits::to_ptr(ext_Z.data());
     
-      t1.start();
-      for (index_type l=0; l<loop; ++l)
-	traits::fftop(setup, A_ptr, Z_ptr, tmp_ptr, log2N, dir);
-      t1.stop();
+      if (!scale_)
+      {
+	t1.start();
+	for (index_type l=0; l<loop; ++l)
+	  traits::fftop(setup, A_ptr, Z_ptr, tmp_ptr, log2N, dir);
+	t1.stop();
+      }
+      else
+      {
+	t1.start();
+	for (index_type l=0; l<loop; ++l)
+	{
+	  traits::fftop(setup, A_ptr, Z_ptr, tmp_ptr, log2N, dir);
+	  traits::scale(Z_ptr, size, factor); 
+	}
+	t1.stop();
+      }
     }
     
     if (!equal(Z.get(0), T(scale_ ? 1 : size)))
@@ -175,11 +247,13 @@
 };
 
 
-#if 0
+
 template <typename T,
-	  int      no_times>
+	  typename ComplexFmt>
 struct t_fft_ip
 {
+  typedef impl::Scalar_of<T>::type scalar_type;
+
   char* what() { return "t_fft_ip"; }
   int ops_per_point(length_type len)  { return fft_ops(len); }
   int riob_per_point(length_type) { return -1*(int)sizeof(T); }
@@ -188,23 +262,66 @@
 
   void operator()(length_type size, length_type loop, float& time)
   {
-    Vector<T>   A(size, T(0));
+    typedef sal_fft<T, ComplexFmt> traits;
 
-    typedef Fft<const_Vector, T, T, fft_fwd, by_reference, no_times, alg_time>
-      fft_type;
+    typedef impl::Layout<1, row1_type, Stride_unit_dense, ComplexFmt> LP;
+    typedef impl::Fast_block<1, T, LP, Local_map> block_type;
 
-    fft_type fft(Domain<1>(size), scale_ ? (1.f/size) : 1.f);
+    Vector<T, block_type>   A  (size, T());
+    Vector<T, block_type>   tmp(size, T());
 
+    unsigned long log2N = ilog2(size);
+
+    FFT_setup     setup;
+    unsigned long nbytes  = 0;
+    long          options = 0;
+    long          dir     = FFT_FORWARD;
+    scalar_type   factor  = scalar_type(1) / size;
+
+    fft_setup(log2N, options, &setup, &nbytes);
+
+    A = T(0);
+
     vsip::impl::profile::Timer t1;
+
+    {
+      Ext_data<block_type> ext_A(A.block(), SYNC_IN);
+      Ext_data<block_type> ext_tmp(tmp.block(), SYNC_IN);
+
+      typename traits::type A_ptr = traits::to_ptr(ext_A.data());
+      typename traits::type tmp_ptr = traits::to_ptr(ext_tmp.data());
     
-    t1.start();
-    for (index_type l=0; l<loop; ++l)
-      fft(A);
-    t1.stop();
+      if (!scale_)
+      {
+	t1.start();
+	for (index_type l=0; l<loop; ++l)
+	  traits::fftip(setup, A_ptr, tmp_ptr, log2N, dir);
+	t1.stop();
+	// Check answer
+	A = T(1);
+	traits::fftip(setup, A_ptr, tmp_ptr, log2N, dir);
+      }
+      else
+      {
+	t1.start();
+	for (index_type l=0; l<loop; ++l)
+	{
+	  traits::fftip(setup, A_ptr, tmp_ptr, log2N, dir);
+	  traits::scale(A_ptr, size, factor); 
+	}
+	t1.stop();
+	// Check answer
+	A = T(1);
+	traits::fftip(setup, A_ptr, tmp_ptr, log2N, dir);
+	traits::scale(A_ptr, size, factor); 
+      }
+    }
     
-    if (!equal(A.get(0), T(0)))
+    if (!equal(A.get(0), T(scale_ ? 1 : size)))
     {
       std::cout << "t_fft_ip: ERROR" << std::endl;
+      std::cout << "  got     : " << A.get(0) << std::endl;
+      std::cout << "  expected: " << T(scale_ ? 1 : size) << std::endl;
       abort();
     }
     
@@ -216,7 +333,6 @@
   // Member data
   bool scale_;
 };
-#endif
 
 
 
@@ -234,10 +350,15 @@
   switch (what)
   {
   case  1: loop(t_fft_op<complex<float>, Cmplx_split_fmt>(false)); break;
-    // case  2: loop(t_fft_ip<complex<float>, Cmplx_split_fmt>(false)); break;
+  case  2: loop(t_fft_ip<complex<float>, Cmplx_split_fmt>(false)); break;
   case  5: loop(t_fft_op<complex<float>, Cmplx_split_fmt>(true)); break;
-      // case  6: loop(t_fft_ip<complex<float>, Cmplx_split_fmt>(true)); break;
+  case  6: loop(t_fft_ip<complex<float>, Cmplx_split_fmt>(true)); break;
 
+  case 11: loop(t_fft_op<complex<float>, Cmplx_inter_fmt>(false)); break;
+  case 12: loop(t_fft_ip<complex<float>, Cmplx_inter_fmt>(false)); break;
+  case 15: loop(t_fft_op<complex<float>, Cmplx_inter_fmt>(true)); break;
+  case 16: loop(t_fft_ip<complex<float>, Cmplx_inter_fmt>(true)); break;
+
   default: return 0;
   }
   return 1;
Index: benchmarks/vmul.cpp
===================================================================
--- benchmarks/vmul.cpp	(revision 154174)
+++ benchmarks/vmul.cpp	(working copy)
@@ -14,675 +14,17 @@
 #include <iostream>
 
 #include <vsip/initfin.hpp>
-#include <vsip/support.hpp>
-#include <vsip/math.hpp>
-#include <vsip/random.hpp>
-#include <vsip/selgen.hpp>
-#include <vsip/core/setup_assign.hpp>
-#include "benchmarks.hpp"
 
+#include "vmul.hpp"
+
 using namespace vsip;
 
 
-template <vsip::dimension_type Dim,
-	  typename             MapT>
-struct Create_map {};
 
-template <vsip::dimension_type Dim>
-struct Create_map<Dim, vsip::Local_map>
-{
-  typedef vsip::Local_map type;
-  static type exec() { return type(); }
-};
-
-template <vsip::dimension_type Dim>
-struct Create_map<Dim, vsip::Global_map<Dim> >
-{
-  typedef vsip::Global_map<Dim> type;
-  static type exec() { return type(); }
-};
-
-template <typename Dist0, typename Dist1, typename Dist2>
-struct Create_map<1, vsip::Map<Dist0, Dist1, Dist2> >
-{
-  typedef vsip::Map<Dist0, Dist1, Dist2> type;
-  static type exec() { return type(vsip::num_processors()); }
-};
-
-template <vsip::dimension_type Dim,
-	  typename             MapT>
-MapT
-create_map()
-{
-  return Create_map<Dim, MapT>::exec();
-}
-
-
-// Sync Policy: use barrier.
-
-struct Barrier
-{
-  Barrier() : comm_(DEFAULT_COMMUNICATOR()) {}
-
-  void sync() { BARRIER(comm_); }
-
-  COMMUNICATOR_TYPE& comm_;
-};
-
-
-
-// Sync Policy: no barrier.
-
-struct No_barrier
-{
-  No_barrier() {}
-
-  void sync() {}
-};
-
-
-
-
-
 /***********************************************************************
-  Definitions - vector element-wise multiply
+  Definitions
 ***********************************************************************/
 
-// Elementwise vector-multiply, non-distributed (explicit Local_map)
-// This is equivalent to t_vmul1<T, Local_map>.
-
-template <typename T>
-struct t_vmul1_nonglobal
-{
-  char* what() { return "t_vmul1_nonglobal"; }
-  int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
-  int riob_per_point(length_type) { return 2*sizeof(T); }
-  int wiob_per_point(length_type) { return 1*sizeof(T); }
-  int mem_per_point(length_type)  { return 3*sizeof(T); }
-
-  void operator()(length_type size, length_type loop, float& time)
-    VSIP_IMPL_NOINLINE
-  {
-    typedef Dense<1, T, row1_type, Local_map> block_type;
-
-    Vector<T, block_type> A(size, T());
-    Vector<T, block_type> B(size, T());
-    Vector<T, block_type> C(size);
-
-    Rand<T> gen(0, 0);
-    A = gen.randu(size);
-    B = gen.randu(size);
-
-    A.put(0, T(3));
-    B.put(0, T(4));
-
-    vsip::impl::profile::Timer t1;
-    
-    t1.start();
-    for (index_type l=0; l<loop; ++l)
-      C = A * B;
-    t1.stop();
-    
-    for (index_type i=0; i<size; ++i)
-      test_assert(equal(C.get(i), A.get(i) * B.get(i)));
-    
-    time = t1.delta();
-  }
-};
-
-
-
-// Element-wise vector-multiply.  Supports distributed views, using
-// implicit data-parallelism.
-
-template <typename T,
-	  typename MapT = Local_map,
-	  typename SP   = No_barrier>
-struct t_vmul1
-{
-  char* what() { return "t_vmul1"; }
-  int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
-  int riob_per_point(length_type) { return 2*sizeof(T); }
-  int wiob_per_point(length_type) { return 1*sizeof(T); }
-  int mem_per_point(length_type)  { return 3*sizeof(T); }
-
-  void operator()(length_type size, length_type loop, float& time)
-    VSIP_IMPL_NOINLINE
-  {
-    typedef Dense<1, T, row1_type, MapT> block_type;
-
-    MapT map = create_map<1, MapT>();
-
-    Vector<T, block_type> A(size, T(), map);
-    Vector<T, block_type> B(size, T(), map);
-    Vector<T, block_type> C(size,      map);
-
-    Rand<T> gen(0, 0);
-    // A, B, and C have the same map.
-    for (index_type i=0; i<C.local().size(); ++i)
-    {
-      A.local().put(i, gen.randu());
-      B.local().put(i, gen.randu());
-    }
-    A.put(0, T(3));
-    B.put(0, T(4));
-
-    vsip::impl::profile::Timer t1;
-    SP sp;
-    
-    t1.start();
-    sp.sync();
-    for (index_type l=0; l<loop; ++l)
-      C = A * B;
-    sp.sync();
-    t1.stop();
-    
-    for (index_type i=0; i<C.local().size(); ++i)
-      test_assert(equal(C.local().get(i),
-			A.local().get(i) * B.local().get(i)));
-    
-    time = t1.delta();
-  }
-};
-
-
-
-
-// Element-wise vector-multiply.  Supports distributed views, using
-// in-loop local views.
-
-template <typename T,
-	  typename MapT = Local_map,
-	  typename SP   = No_barrier>
-struct t_vmul1_local
-{
-  char* what() { return "t_vmul1"; }
-  int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
-  int riob_per_point(length_type) { return 2*sizeof(T); }
-  int wiob_per_point(length_type) { return 1*sizeof(T); }
-  int mem_per_point(length_type)  { return 3*sizeof(T); }
-
-  void operator()(length_type size, length_type loop, float& time)
-    VSIP_IMPL_NOINLINE
-  {
-    typedef Dense<1, T, row1_type, MapT> block_type;
-
-    MapT map = create_map<1, MapT>();
-
-    Vector<T, block_type> A(size, T(), map);
-    Vector<T, block_type> B(size, T(), map);
-    Vector<T, block_type> C(size,      map);
-
-    Rand<T> gen(0, 0);
-    A = gen.randu(size);
-    B = gen.randu(size);
-
-    A.put(0, T(3));
-    B.put(0, T(4));
-
-    vsip::impl::profile::Timer t1;
-    SP sp;
-    
-    t1.start();
-    sp.sync();
-    for (index_type l=0; l<loop; ++l)
-      C.local() = A.local() * B.local();
-    sp.sync();
-    t1.stop();
-    
-    for (index_type i=0; i<size; ++i)
-      test_assert(equal(C.get(i), A.get(i) * B.get(i)));
-    
-    time = t1.delta();
-  }
-};
-
-
-
-// Element-wise vector-multiply.  Supports distributed views, using
-// early local views.
-
-template <typename T,
-	  typename MapT = Local_map,
-	  typename SP   = No_barrier>
-struct t_vmul1_early_local
-{
-  char* what() { return "t_vmul1_early_local"; }
-  int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
-  int riob_per_point(length_type) { return 2*sizeof(T); }
-  int wiob_per_point(length_type) { return 1*sizeof(T); }
-  int mem_per_point(length_type)  { return 3*sizeof(T); }
-
-  void operator()(length_type size, length_type loop, float& time)
-    VSIP_IMPL_NOINLINE
-  {
-    typedef Dense<1, T, row1_type, MapT> block_type;
-
-    MapT map = create_map<1, MapT>();
-
-    Vector<T, block_type> A(size, T(), map);
-    Vector<T, block_type> B(size, T(), map);
-    Vector<T, block_type> C(size,      map);
-
-    Rand<T> gen(0, 0);
-    A = gen.randu(size);
-    B = gen.randu(size);
-
-    A.put(0, T(3));
-    B.put(0, T(4));
-
-    vsip::impl::profile::Timer t1;
-    SP sp;
-    
-    t1.start();
-    typename Vector<T, block_type>::local_type A_local = A.local();
-    typename Vector<T, block_type>::local_type B_local = B.local();
-    typename Vector<T, block_type>::local_type C_local = C.local();
-    sp.sync();
-    for (index_type l=0; l<loop; ++l)
-      C_local = A_local * B_local;
-    sp.sync();
-    t1.stop();
-    
-    for (index_type i=0; i<size; ++i)
-      test_assert(equal(C.get(i), A.get(i) * B.get(i)));
-    
-    time = t1.delta();
-  }
-};
-
-
-
-// Element-wise vector-multiply.  Supports distributed views, using
-// Setup_assign.
-
-template <typename T,
-	  typename MapT = Local_map,
-	  typename SP   = No_barrier>
-struct t_vmul1_sa
-{
-  char* what() { return "t_vmul1_sa"; }
-  int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
-  int riob_per_point(length_type) { return 2*sizeof(T); }
-  int wiob_per_point(length_type) { return 1*sizeof(T); }
-  int mem_per_point(length_type)  { return 3*sizeof(T); }
-
-  void operator()(length_type size, length_type loop, float& time)
-    VSIP_IMPL_NOINLINE
-  {
-    typedef Dense<1, T, row1_type, MapT> block_type;
-
-    MapT map = create_map<1, MapT>();
-
-    Vector<T, block_type> A(size, T(), map);
-    Vector<T, block_type> B(size, T(), map);
-    Vector<T, block_type> C(size,      map);
-
-    Rand<T> gen(0, 0);
-    A = gen.randu(size);
-    B = gen.randu(size);
-
-    A.put(0, T(3));
-    B.put(0, T(4));
-
-
-    vsip::impl::profile::Timer t1;
-    SP sp;
-    
-    Setup_assign expr(C, A*B);
-    t1.start();
-    sp.sync();
-    for (index_type l=0; l<loop; ++l)
-      expr();
-    sp.sync();
-    t1.stop();
-
-    for (index_type i=0; i<size; ++i)
-      test_assert(equal(C.get(i), A.get(i) * B.get(i)));
-    
-    time = t1.delta();
-  }
-};
-
-
-
-template <typename T>
-struct t_vmul_ip1
-{
-  char* what() { return "t_vmul_ip1"; }
-  int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
-  int riob_per_point(length_type) { return 2*sizeof(T); }
-  int wiob_per_point(length_type) { return 1*sizeof(T); }
-  int mem_per_point(length_type)  { return 3*sizeof(T); }
-
-  void operator()(length_type size, length_type loop, float& time)
-    VSIP_IMPL_NOINLINE
-  {
-    Vector<T>   A(size, T(1));
-    Vector<T>   C(size);
-    Vector<T>   chk(size);
-
-    Rand<T> gen(0, 0);
-    chk = gen.randu(size);
-    C = chk;
-
-    vsip::impl::profile::Timer t1;
-    
-    t1.start();
-    for (index_type l=0; l<loop; ++l)
-      C *= A;
-    t1.stop();
-    
-    for (index_type i=0; i<size; ++i)
-      test_assert(equal(chk.get(i), C.get(i)));
-    
-    time = t1.delta();
-  }
-};
-
-
-
-template <typename T>
-struct t_vmul_dom1
-{
-  char* what() { return "t_vmul_dom1"; }
-  int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
-  int riob_per_point(length_type) { return 2*sizeof(T); }
-  int wiob_per_point(length_type) { return 1*sizeof(T); }
-  int mem_per_point(length_type)  { return 3*sizeof(T); }
-
-  void operator()(length_type size, length_type loop, float& time)
-    VSIP_IMPL_NOINLINE
-  {
-    Vector<T>   A(size, T());
-    Vector<T>   B(size, T());
-    Vector<T>   C(size);
-
-    Rand<T> gen(0, 0);
-    A = gen.randu(size);
-    B = gen.randu(size);
-
-    A.put(0, T(3));
-    B.put(0, T(4));
-
-    Domain<1> dom(size);
-    
-    vsip::impl::profile::Timer t1;
-    
-    t1.start();
-    for (index_type l=0; l<loop; ++l)
-      C(dom) = A(dom) * B(dom);
-    t1.stop();
-    
-    for (index_type i=0; i<size; ++i)
-      test_assert(equal(C.get(i), A.get(i) * B.get(i)));
-    
-    time = t1.delta();
-  }
-};
-
-
-#ifdef VSIP_IMPL_SOURCERY_VPP
-template <typename T, typename ComplexFmt>
-struct t_vmul2
-{
-  char* what() { return "t_vmul2"; }
-  int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
-  int riob_per_point(length_type) { return 2*sizeof(T); }
-  int wiob_per_point(length_type) { return 1*sizeof(T); }
-  int mem_per_point(length_type)  { return 3*sizeof(T); }
-
-  void operator()(length_type size, length_type loop, float& time)
-    VSIP_IMPL_NOINLINE
-  {
-    typedef impl::Layout<1, row1_type, impl::Stride_unit_dense, ComplexFmt>
-		LP;
-    typedef impl::Fast_block<1, T, LP> block_type;
-
-    Vector<T, block_type> A(size, T());
-    Vector<T, block_type> B(size, T());
-    Vector<T, block_type> C(size);
-
-    A.put(0, T(3));
-    B.put(0, T(4));
-    
-    vsip::impl::profile::Timer t1;
-    
-    t1.start();
-    for (index_type l=0; l<loop; ++l)
-      C = A * B;
-    t1.stop();
-    
-    if (!equal(C.get(0), T(12)))
-    {
-      std::cout << "t_vmul2: ERROR" << std::endl;
-      abort();
-    }
-    
-    time = t1.delta();
-  }
-};
-#endif // VSIP_IMPL_SOURCERY_VPP
-
-
-/***********************************************************************
-  Definitions - real * complex vector element-wise multiply
-***********************************************************************/
-
-template <typename T>
-struct t_rcvmul1
-{
-  char* what() { return "t_rcvmul1"; }
-  int ops_per_point(length_type)  { return 2*vsip::impl::Ops_info<T>::mul; }
-  int riob_per_point(length_type) { return sizeof(T) + sizeof(complex<T>); }
-  int wiob_per_point(length_type) { return 1*sizeof(complex<T>); }
-  int mem_per_point(length_type)  { return 1*sizeof(T)+2*sizeof(complex<T>); }
-
-  void operator()(length_type size, length_type loop, float& time)
-    VSIP_IMPL_NOINLINE
-  {
-    Vector<complex<T> > A(size);
-    Vector<T>           B(size);
-    Vector<complex<T> > C(size);
-
-    Rand<complex<T> > cgen(0, 0);
-    Rand<T>           sgen(0, 0);
-
-    A = cgen.randu(size);
-    B = sgen.randu(size);
-
-    vsip::impl::profile::Timer t1;
-    
-    t1.start();
-    for (index_type l=0; l<loop; ++l)
-      C = B * A;
-    t1.stop();
-    
-    for (index_type i=0; i<size; ++i)
-      test_assert(equal(C.get(i), A.get(i) * B.get(i)));
-    
-    time = t1.delta();
-  }
-};
-
-
-
-// Benchmark scalar-view vector multiply (Scalar * View)
-
-template <typename ScalarT,
-	  typename T>
-struct t_svmul1
-{
-  char* what() { return "t_svmul1"; }
-  int ops_per_point(length_type)
-  { if (sizeof(ScalarT) == sizeof(T))
-      return vsip::impl::Ops_info<T>::mul;
-    else
-      return 2*vsip::impl::Ops_info<ScalarT>::mul;
-  }
-  int riob_per_point(length_type) { return 1*sizeof(T); }
-  int wiob_per_point(length_type) { return 1*sizeof(T); }
-  int mem_per_point(length_type)  { return 2*sizeof(T); }
-
-  void operator()(length_type size, length_type loop, float& time)
-  {
-    Vector<T>   A(size, T());
-    Vector<T>   C(size);
-
-    ScalarT alpha = ScalarT(3);
-
-    Rand<T>     gen(0, 0);
-    A = gen.randu(size);
-    A.put(0, T(4));
-
-    vsip::impl::profile::Timer t1;
-    
-    t1.start();
-    for (index_type l=0; l<loop; ++l)
-      C = alpha * A;
-    t1.stop();
-    
-    for (index_type i=0; i<size; ++i)
-      test_assert(equal(C.get(i), alpha * A.get(i)));
-    
-    time = t1.delta();
-  }
-};
-
-
-
-// Benchmark scalar-view vector multiply (Scalar * View)
-
-template <typename T>
-struct t_svmul2
-{
-  char* what() { return "t_svmul2"; }
-  int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
-  int riob_per_point(length_type) { return 1*sizeof(T); }
-  int wiob_per_point(length_type) { return 1*sizeof(T); }
-  int mem_per_point(length_type)  { return 2*sizeof(T); }
-
-  void operator()(length_type size, length_type loop, float& time)
-  {
-    Vector<T>   A(size, T());
-    Vector<T>   C(size);
-
-    T alpha = T(3);
-
-    A.put(0, T(4));
-    
-    vsip::impl::profile::Timer t1;
-    
-    t1.start();
-    for (index_type l=0; l<loop; ++l)
-      C = A * alpha;
-    t1.stop();
-
-    test_assert(equal(C.get(0), T(12)));
-    
-    time = t1.delta();
-  }
-};
-
-
-
-// Benchmark scalar-view vector multiply w/literal (Scalar * View)
-
-template <typename T>
-struct t_svmul3
-{
-  char* what() { return "t_svmul3"; }
-  int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
-  int riob_per_point(length_type) { return 1*sizeof(T); }
-  int wiob_per_point(length_type) { return 1*sizeof(T); }
-  int mem_per_point(length_type)  { return 2*sizeof(T); }
-
-  void operator()(length_type size, length_type loop, float& time)
-  {
-    Vector<T>   A(size, T());
-    Vector<T>   C(size);
-
-    A.put(0, T(4));
-    
-    vsip::impl::profile::Timer t1;
-    
-    t1.start();
-    for (index_type l=0; l<loop; ++l)
-      C = 3.f * A;
-    t1.stop();
-
-    test_assert(equal(C.get(0), T(12)));
-    
-    time = t1.delta();
-  }
-};
-
-
-
-// Benchmark scalar-view vector multiply w/literal (Scalar * View)
-
-template <typename T,
-	  typename DataMapT  = Local_map,
-	  typename CoeffMapT = Local_map,
-	  typename SP        = No_barrier>
-struct t_svmul4
-{
-  char* what() { return "t_svmul4"; }
-  int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
-  int riob_per_point(length_type) { return 1*sizeof(T); }
-  int wiob_per_point(length_type) { return 1*sizeof(T); }
-  int mem_per_point(length_type)  { return 2*sizeof(T); }
-
-  void operator()(length_type size, length_type loop, float& time)
-  {
-    typedef Dense<1, T, row1_type, DataMapT>  block_type;
-    typedef Dense<1, T, row1_type, CoeffMapT> coeff_block_type;
-
-    DataMapT  map_data  = create_map<1, DataMapT>();
-    CoeffMapT map_coeff = create_map<1, CoeffMapT>();
-
-    Vector<T, block_type>       A(size, T(), map_data);
-    Vector<T, block_type>       C(size,      map_data);
-    Vector<T, coeff_block_type> K(size, T(), map_coeff);
-
-    // ramp does not work for distributed assignments (060726)
-    // A = cos(ramp(0.f, 0.15f*3.14159f, size));
-    for (index_type i=0; i<A.local().size(); ++i)
-    {
-      index_type g_i = global_from_local_index(A, 0, i);
-      A.local().put(i, cos(T(g_i)*0.15f*3.14159f));
-    }
-
-    // ramp does not work for distributed assignments (060726)
-    // K = cos(ramp(0.f, 0.25f*3.14159f, size));
-    for (index_type i=0; i<K.local().size(); ++i)
-    {
-      index_type g_i = global_from_local_index(K, 0, i);
-      K.local().put(i, cos(T(g_i)*0.25f*3.14159f));
-    }
-
-    T alpha;
-
-    vsip::impl::profile::Timer t1;
-    
-    t1.start();
-    for (index_type l=0; l<loop; ++l)
-    {
-      alpha = K.get(1);
-      C = alpha * A;
-    }
-    t1.stop();
-
-    alpha = K.get(1);
-    for (index_type i=0; i<C.local().size(); ++i)
-      test_assert(equal(C.local().get(i), A.local().get(i) * alpha));
-    
-    time = t1.delta();
-  }
-};
-
-
-
 void
 defaults(Loop1P&)
 {
@@ -721,24 +63,6 @@
   case  31: loop(t_vmul_ip1<float>()); break;
   case  32: loop(t_vmul_ip1<complex<float> >()); break;
 
-  case  91: loop(t_vmul1_nonglobal<        float  >()); break;
-  case  92: loop(t_vmul1_nonglobal<complex<float> >()); break;
-
-  case 101: loop(t_vmul1<        float , Map<> >()); break;
-  case 102: loop(t_vmul1<complex<float>, Map<> >()); break;
-
-  case 111: loop(t_vmul1<        float , Map<>, Barrier>()); break;
-  case 112: loop(t_vmul1<complex<float>, Map<>, Barrier>()); break;
-
-  case 121: loop(t_vmul1_local<        float  >()); break;
-  case 122: loop(t_vmul1_local<complex<float> >()); break;
-
-  case 131: loop(t_vmul1_early_local<        float  >()); break;
-  case 132: loop(t_vmul1_early_local<complex<float> >()); break;
-
-  case 141: loop(t_vmul1_sa<        float  >()); break;
-  case 142: loop(t_vmul1_sa<complex<float> >()); break;
-
   case 0:
     std::cout
       << "vmul -- vector multiplication\n"
@@ -760,20 +84,6 @@
       << "  -22 -- t_vmul_dom1\n"
       << "  -31 -- t_vmul_ip1\n"
       << "  -32 -- t_vmul_ip1\n"
-
-      << "  -91 -- Vector<        float > * Vector<        float > NONGLOBAL\n"
-      << "  -92 -- Vector<complex<float>> * Vector<complex<float>> NONGLOBAL\n"
-
-      << " -101 -- Vector<        float > * Vector<        float > PAR\n"
-      << " -102 -- Vector<complex<float>> * Vector<complex<float>> PAR\n"
-      << " -111 -- Vector<        float > * Vector<        float > PAR sync\n"
-      << " -112 -- Vector<complex<float>> * Vector<complex<float>> PAR sync\n"
-      << " -121 -- Vector<        float > * Vector<        float > PAR local\n"
-      << " -122 -- Vector<complex<float>> * Vector<complex<float>> PAR local\n"
-      << " -131 -- Vector<        float > * Vector<        float > PAR early local\n"
-      << " -132 -- Vector<complex<float>> * Vector<complex<float>> PAR early local\n"
-      << " -141 -- Vector<        float > * Vector<        float > PAR setup assign\n"
-      << " -142 -- Vector<complex<float>> * Vector<complex<float>> PAR setup assign\n"
       ;
 
   default:
Index: benchmarks/main.cpp
===================================================================
--- benchmarks/main.cpp	(revision 154174)
+++ benchmarks/main.cpp	(working copy)
@@ -65,6 +65,8 @@
       loop.cal_ = atoi(argv[++i]);
     else if (!strcmp(argv[i], "-loop_start"))
       loop.loop_start_ = atoi(argv[++i]);
+    else if (!strcmp(argv[i], "-fix_loop"))
+      loop.fix_loop_ = true;
     else if (!strcmp(argv[i], "-samples"))
       loop.samples_ = atoi(argv[++i]);
     else if (!strcmp(argv[i], "-ms"))
@@ -83,8 +85,12 @@
       loop.metric_ = iob_per_sec;
     else if (!strcmp(argv[i], "-wiob"))
       loop.metric_ = wiob_per_sec;
+    else if (!strcmp(argv[i], "-riob"))
+      loop.metric_ = riob_per_sec;
     else if (!strcmp(argv[i], "-all"))
       loop.metric_ = all_per_sec;
+    else if (!strcmp(argv[i], "-data"))
+      loop.metric_ = data_per_sec;
     else if (!strcmp(argv[i], "-lat"))
       loop.metric_ = secs_per_pt;
     else if (!strcmp(argv[i], "-linear"))
@@ -118,6 +124,12 @@
       std::cerr << "ERROR: Unknown argument: " << argv[i] << std::endl;
   }
 
+  if (loop.metric_ == data_per_sec && loop.samples_ < 3)
+  {
+    std::cerr << "ERROR: -samples must be >= 3 when using -data" << std::endl;
+    exit(-1);
+  }
+
   if (verbose)
   {
     std::cout << "what = " << what << std::endl;
Index: benchmarks/vmul.hpp
===================================================================
--- benchmarks/vmul.hpp	(revision 0)
+++ benchmarks/vmul.hpp	(revision 0)
@@ -0,0 +1,686 @@
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    benchmarks/vmul.hpp
+    @author  Jules Bergmann
+    @date    2005-07-11
+    @brief   VSIPL++ Library: Benchmarks for vector multiply.
+
+*/
+
+#ifndef VSIP_BENCHMARKS_VMUL_HPP
+#define VSIP_BENCHMARKS_VMUL_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/support.hpp>
+#include <vsip/math.hpp>
+#include <vsip/random.hpp>
+#include <vsip/selgen.hpp>
+#include <vsip/core/setup_assign.hpp>
+
+#include "benchmarks.hpp"
+
+using namespace vsip;
+
+
+
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
+template <vsip::dimension_type Dim,
+	  typename             MapT>
+struct Create_map {};
+
+template <vsip::dimension_type Dim>
+struct Create_map<Dim, vsip::Local_map>
+{
+  typedef vsip::Local_map type;
+  static type exec() { return type(); }
+};
+
+template <vsip::dimension_type Dim>
+struct Create_map<Dim, vsip::Global_map<Dim> >
+{
+  typedef vsip::Global_map<Dim> type;
+  static type exec() { return type(); }
+};
+
+template <typename Dist0, typename Dist1, typename Dist2>
+struct Create_map<1, vsip::Map<Dist0, Dist1, Dist2> >
+{
+  typedef vsip::Map<Dist0, Dist1, Dist2> type;
+  static type exec() { return type(vsip::num_processors()); }
+};
+
+template <vsip::dimension_type Dim,
+	  typename             MapT>
+MapT
+create_map()
+{
+  return Create_map<Dim, MapT>::exec();
+}
+
+
+// Sync Policy: use barrier.
+
+struct Barrier
+{
+  Barrier() : comm_(DEFAULT_COMMUNICATOR()) {}
+
+  void sync() { BARRIER(comm_); }
+
+  COMMUNICATOR_TYPE& comm_;
+};
+
+
+
+// Sync Policy: no barrier.
+
+struct No_barrier
+{
+  No_barrier() {}
+
+  void sync() {}
+};
+
+
+
+
+
+/***********************************************************************
+  Definitions - vector element-wise multiply
+***********************************************************************/
+
+// Elementwise vector-multiply, non-distributed (explicit Local_map)
+// This is equivalent to t_vmul1<T, Local_map>.
+
+template <typename T>
+struct t_vmul1_nonglobal
+{
+  char* what() { return "t_vmul1_nonglobal"; }
+  int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
+  int riob_per_point(length_type) { return 2*sizeof(T); }
+  int wiob_per_point(length_type) { return 1*sizeof(T); }
+  int mem_per_point(length_type)  { return 3*sizeof(T); }
+
+  void operator()(length_type size, length_type loop, float& time)
+    VSIP_IMPL_NOINLINE
+  {
+    typedef Dense<1, T, row1_type, Local_map> block_type;
+
+    Vector<T, block_type> A(size, T());
+    Vector<T, block_type> B(size, T());
+    Vector<T, block_type> C(size);
+
+    Rand<T> gen(0, 0);
+    A = gen.randu(size);
+    B = gen.randu(size);
+
+    A.put(0, T(3));
+    B.put(0, T(4));
+
+    vsip::impl::profile::Timer t1;
+    
+    t1.start();
+    for (index_type l=0; l<loop; ++l)
+      C = A * B;
+    t1.stop();
+    
+    for (index_type i=0; i<size; ++i)
+      test_assert(equal(C.get(i), A.get(i) * B.get(i)));
+    
+    time = t1.delta();
+  }
+};
+
+
+
+// Element-wise vector-multiply.  Supports distributed views, using
+// implicit data-parallelism.
+
+template <typename T,
+	  typename MapT = Local_map,
+	  typename SP   = No_barrier>
+struct t_vmul1
+{
+  char* what() { return "t_vmul1"; }
+  int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
+  int riob_per_point(length_type) { return 2*sizeof(T); }
+  int wiob_per_point(length_type) { return 1*sizeof(T); }
+  int mem_per_point(length_type)  { return 3*sizeof(T); }
+
+  void operator()(length_type size, length_type loop, float& time)
+    VSIP_IMPL_NOINLINE
+  {
+    typedef Dense<1, T, row1_type, MapT> block_type;
+
+    MapT map = create_map<1, MapT>();
+
+    Vector<T, block_type> A(size, T(), map);
+    Vector<T, block_type> B(size, T(), map);
+    Vector<T, block_type> C(size,      map);
+
+    Rand<T> gen(0, 0);
+    // A, B, and C have the same map.
+    for (index_type i=0; i<C.local().size(); ++i)
+    {
+      A.local().put(i, gen.randu());
+      B.local().put(i, gen.randu());
+    }
+    A.put(0, T(3));
+    B.put(0, T(4));
+
+    vsip::impl::profile::Timer t1;
+    SP sp;
+    
+    t1.start();
+    sp.sync();
+    for (index_type l=0; l<loop; ++l)
+      C = A * B;
+    sp.sync();
+    t1.stop();
+    
+    for (index_type i=0; i<C.local().size(); ++i)
+      test_assert(equal(C.local().get(i),
+			A.local().get(i) * B.local().get(i)));
+    
+    time = t1.delta();
+  }
+};
+
+
+
+
+// Element-wise vector-multiply.  Supports distributed views, using
+// in-loop local views.
+
+template <typename T,
+	  typename MapT = Local_map,
+	  typename SP   = No_barrier>
+struct t_vmul1_local
+{
+  char* what() { return "t_vmul1"; }
+  int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
+  int riob_per_point(length_type) { return 2*sizeof(T); }
+  int wiob_per_point(length_type) { return 1*sizeof(T); }
+  int mem_per_point(length_type)  { return 3*sizeof(T); }
+
+  void operator()(length_type size, length_type loop, float& time)
+    VSIP_IMPL_NOINLINE
+  {
+    typedef Dense<1, T, row1_type, MapT> block_type;
+
+    MapT map = create_map<1, MapT>();
+
+    Vector<T, block_type> A(size, T(), map);
+    Vector<T, block_type> B(size, T(), map);
+    Vector<T, block_type> C(size,      map);
+
+    Rand<T> gen(0, 0);
+    A = gen.randu(size);
+    B = gen.randu(size);
+
+    A.put(0, T(3));
+    B.put(0, T(4));
+
+    vsip::impl::profile::Timer t1;
+    SP sp;
+    
+    t1.start();
+    sp.sync();
+    for (index_type l=0; l<loop; ++l)
+      C.local() = A.local() * B.local();
+    sp.sync();
+    t1.stop();
+    
+    for (index_type i=0; i<size; ++i)
+      test_assert(equal(C.get(i), A.get(i) * B.get(i)));
+    
+    time = t1.delta();
+  }
+};
+
+
+
+// Element-wise vector-multiply.  Supports distributed views, using
+// early local views.
+
+template <typename T,
+	  typename MapT = Local_map,
+	  typename SP   = No_barrier>
+struct t_vmul1_early_local
+{
+  char* what() { return "t_vmul1_early_local"; }
+  int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
+  int riob_per_point(length_type) { return 2*sizeof(T); }
+  int wiob_per_point(length_type) { return 1*sizeof(T); }
+  int mem_per_point(length_type)  { return 3*sizeof(T); }
+
+  void operator()(length_type size, length_type loop, float& time)
+    VSIP_IMPL_NOINLINE
+  {
+    typedef Dense<1, T, row1_type, MapT> block_type;
+
+    MapT map = create_map<1, MapT>();
+
+    Vector<T, block_type> A(size, T(), map);
+    Vector<T, block_type> B(size, T(), map);
+    Vector<T, block_type> C(size,      map);
+
+    Rand<T> gen(0, 0);
+    A = gen.randu(size);
+    B = gen.randu(size);
+
+    A.put(0, T(3));
+    B.put(0, T(4));
+
+    vsip::impl::profile::Timer t1;
+    SP sp;
+    
+    t1.start();
+    typename Vector<T, block_type>::local_type A_local = A.local();
+    typename Vector<T, block_type>::local_type B_local = B.local();
+    typename Vector<T, block_type>::local_type C_local = C.local();
+    sp.sync();
+    for (index_type l=0; l<loop; ++l)
+      C_local = A_local * B_local;
+    sp.sync();
+    t1.stop();
+    
+    for (index_type i=0; i<size; ++i)
+      test_assert(equal(C.get(i), A.get(i) * B.get(i)));
+    
+    time = t1.delta();
+  }
+};
+
+
+
+// Element-wise vector-multiply.  Supports distributed views, using
+// Setup_assign.
+
+template <typename T,
+	  typename MapT = Local_map,
+	  typename SP   = No_barrier>
+struct t_vmul1_sa
+{
+  char* what() { return "t_vmul1_sa"; }
+  int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
+  int riob_per_point(length_type) { return 2*sizeof(T); }
+  int wiob_per_point(length_type) { return 1*sizeof(T); }
+  int mem_per_point(length_type)  { return 3*sizeof(T); }
+
+  void operator()(length_type size, length_type loop, float& time)
+    VSIP_IMPL_NOINLINE
+  {
+    typedef Dense<1, T, row1_type, MapT> block_type;
+
+    MapT map = create_map<1, MapT>();
+
+    Vector<T, block_type> A(size, T(), map);
+    Vector<T, block_type> B(size, T(), map);
+    Vector<T, block_type> C(size,      map);
+
+    Rand<T> gen(0, 0);
+    A = gen.randu(size);
+    B = gen.randu(size);
+
+    A.put(0, T(3));
+    B.put(0, T(4));
+
+
+    vsip::impl::profile::Timer t1;
+    SP sp;
+    
+    Setup_assign expr(C, A*B);
+    t1.start();
+    sp.sync();
+    for (index_type l=0; l<loop; ++l)
+      expr();
+    sp.sync();
+    t1.stop();
+
+    for (index_type i=0; i<size; ++i)
+      test_assert(equal(C.get(i), A.get(i) * B.get(i)));
+    
+    time = t1.delta();
+  }
+};
+
+
+
+template <typename T>
+struct t_vmul_ip1
+{
+  char* what() { return "t_vmul_ip1"; }
+  int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
+  int riob_per_point(length_type) { return 2*sizeof(T); }
+  int wiob_per_point(length_type) { return 1*sizeof(T); }
+  int mem_per_point(length_type)  { return 3*sizeof(T); }
+
+  void operator()(length_type size, length_type loop, float& time)
+    VSIP_IMPL_NOINLINE
+  {
+    Vector<T>   A(size, T(1));
+    Vector<T>   C(size);
+    Vector<T>   chk(size);
+
+    Rand<T> gen(0, 0);
+    chk = gen.randu(size);
+    C = chk;
+
+    vsip::impl::profile::Timer t1;
+    
+    t1.start();
+    for (index_type l=0; l<loop; ++l)
+      C *= A;
+    t1.stop();
+    
+    for (index_type i=0; i<size; ++i)
+      test_assert(equal(chk.get(i), C.get(i)));
+    
+    time = t1.delta();
+  }
+};
+
+
+
+template <typename T>
+struct t_vmul_dom1
+{
+  char* what() { return "t_vmul_dom1"; }
+  int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
+  int riob_per_point(length_type) { return 2*sizeof(T); }
+  int wiob_per_point(length_type) { return 1*sizeof(T); }
+  int mem_per_point(length_type)  { return 3*sizeof(T); }
+
+  void operator()(length_type size, length_type loop, float& time)
+    VSIP_IMPL_NOINLINE
+  {
+    Vector<T>   A(size, T());
+    Vector<T>   B(size, T());
+    Vector<T>   C(size);
+
+    Rand<T> gen(0, 0);
+    A = gen.randu(size);
+    B = gen.randu(size);
+
+    A.put(0, T(3));
+    B.put(0, T(4));
+
+    Domain<1> dom(size);
+    
+    vsip::impl::profile::Timer t1;
+    
+    t1.start();
+    for (index_type l=0; l<loop; ++l)
+      C(dom) = A(dom) * B(dom);
+    t1.stop();
+    
+    for (index_type i=0; i<size; ++i)
+      test_assert(equal(C.get(i), A.get(i) * B.get(i)));
+    
+    time = t1.delta();
+  }
+};
+
+
+#ifdef VSIP_IMPL_SOURCERY_VPP
+template <typename T, typename ComplexFmt>
+struct t_vmul2
+{
+  char* what() { return "t_vmul2"; }
+  int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
+  int riob_per_point(length_type) { return 2*sizeof(T); }
+  int wiob_per_point(length_type) { return 1*sizeof(T); }
+  int mem_per_point(length_type)  { return 3*sizeof(T); }
+
+  void operator()(length_type size, length_type loop, float& time)
+    VSIP_IMPL_NOINLINE
+  {
+    typedef impl::Layout<1, row1_type, impl::Stride_unit_dense, ComplexFmt>
+		LP;
+    typedef impl::Fast_block<1, T, LP> block_type;
+
+    Vector<T, block_type> A(size, T());
+    Vector<T, block_type> B(size, T());
+    Vector<T, block_type> C(size);
+
+    A.put(0, T(3));
+    B.put(0, T(4));
+    
+    vsip::impl::profile::Timer t1;
+    
+    t1.start();
+    for (index_type l=0; l<loop; ++l)
+      C = A * B;
+    t1.stop();
+    
+    test_assert(equal(C.get(0), T(12)));
+    
+    time = t1.delta();
+  }
+};
+#endif // VSIP_IMPL_SOURCERY_VPP
+
+
+/***********************************************************************
+  Definitions - real * complex vector element-wise multiply
+***********************************************************************/
+
+template <typename T>
+struct t_rcvmul1
+{
+  char* what() { return "t_rcvmul1"; }
+  int ops_per_point(length_type)  { return 2*vsip::impl::Ops_info<T>::mul; }
+  int riob_per_point(length_type) { return sizeof(T) + sizeof(complex<T>); }
+  int wiob_per_point(length_type) { return 1*sizeof(complex<T>); }
+  int mem_per_point(length_type)  { return 1*sizeof(T)+2*sizeof(complex<T>); }
+
+  void operator()(length_type size, length_type loop, float& time)
+    VSIP_IMPL_NOINLINE
+  {
+    Vector<complex<T> > A(size);
+    Vector<T>           B(size);
+    Vector<complex<T> > C(size);
+
+    Rand<complex<T> > cgen(0, 0);
+    Rand<T>           sgen(0, 0);
+
+    A = cgen.randu(size);
+    B = sgen.randu(size);
+
+    vsip::impl::profile::Timer t1;
+    
+    t1.start();
+    for (index_type l=0; l<loop; ++l)
+      C = B * A;
+    t1.stop();
+    
+    for (index_type i=0; i<size; ++i)
+      test_assert(equal(C.get(i), A.get(i) * B.get(i)));
+    
+    time = t1.delta();
+  }
+};
+
+
+
+// Benchmark scalar-view vector multiply (Scalar * View)
+
+template <typename ScalarT,
+	  typename T>
+struct t_svmul1
+{
+  char* what() { return "t_svmul1"; }
+  int ops_per_point(length_type)
+  { if (sizeof(ScalarT) == sizeof(T))
+      return vsip::impl::Ops_info<T>::mul;
+    else
+      return 2*vsip::impl::Ops_info<ScalarT>::mul;
+  }
+  int riob_per_point(length_type) { return 1*sizeof(T); }
+  int wiob_per_point(length_type) { return 1*sizeof(T); }
+  int mem_per_point(length_type)  { return 2*sizeof(T); }
+
+  void operator()(length_type size, length_type loop, float& time)
+  {
+    Vector<T>   A(size, T());
+    Vector<T>   C(size);
+
+    ScalarT alpha = ScalarT(3);
+
+    Rand<T>     gen(0, 0);
+    A = gen.randu(size);
+    A.put(0, T(4));
+
+    vsip::impl::profile::Timer t1;
+    
+    t1.start();
+    for (index_type l=0; l<loop; ++l)
+      C = alpha * A;
+    t1.stop();
+    
+    for (index_type i=0; i<size; ++i)
+      test_assert(equal(C.get(i), alpha * A.get(i)));
+    
+    time = t1.delta();
+  }
+};
+
+
+
+// Benchmark scalar-view vector multiply (Scalar * View)
+
+template <typename T>
+struct t_svmul2
+{
+  char* what() { return "t_svmul2"; }
+  int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
+  int riob_per_point(length_type) { return 1*sizeof(T); }
+  int wiob_per_point(length_type) { return 1*sizeof(T); }
+  int mem_per_point(length_type)  { return 2*sizeof(T); }
+
+  void operator()(length_type size, length_type loop, float& time)
+  {
+    Vector<T>   A(size, T());
+    Vector<T>   C(size);
+
+    T alpha = T(3);
+
+    A.put(0, T(4));
+    
+    vsip::impl::profile::Timer t1;
+    
+    t1.start();
+    for (index_type l=0; l<loop; ++l)
+      C = A * alpha;
+    t1.stop();
+
+    test_assert(equal(C.get(0), T(12)));
+    
+    time = t1.delta();
+  }
+};
+
+
+
+// Benchmark scalar-view vector multiply w/literal (Scalar * View)
+
+template <typename T>
+struct t_svmul3
+{
+  char* what() { return "t_svmul3"; }
+  int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
+  int riob_per_point(length_type) { return 1*sizeof(T); }
+  int wiob_per_point(length_type) { return 1*sizeof(T); }
+  int mem_per_point(length_type)  { return 2*sizeof(T); }
+
+  void operator()(length_type size, length_type loop, float& time)
+  {
+    Vector<T>   A(size, T());
+    Vector<T>   C(size);
+
+    A.put(0, T(4));
+    
+    vsip::impl::profile::Timer t1;
+    
+    t1.start();
+    for (index_type l=0; l<loop; ++l)
+      C = 3.f * A;
+    t1.stop();
+
+    test_assert(equal(C.get(0), T(12)));
+    
+    time = t1.delta();
+  }
+};
+
+
+
+// Benchmark scalar-view vector multiply w/literal (Scalar * View)
+
+template <typename T,
+	  typename DataMapT  = Local_map,
+	  typename CoeffMapT = Local_map,
+	  typename SP        = No_barrier>
+struct t_svmul4
+{
+  char* what() { return "t_svmul4"; }
+  int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
+  int riob_per_point(length_type) { return 1*sizeof(T); }
+  int wiob_per_point(length_type) { return 1*sizeof(T); }
+  int mem_per_point(length_type)  { return 2*sizeof(T); }
+
+  void operator()(length_type size, length_type loop, float& time)
+  {
+    typedef Dense<1, T, row1_type, DataMapT>  block_type;
+    typedef Dense<1, T, row1_type, CoeffMapT> coeff_block_type;
+
+    DataMapT  map_data  = create_map<1, DataMapT>();
+    CoeffMapT map_coeff = create_map<1, CoeffMapT>();
+
+    Vector<T, block_type>       A(size, T(), map_data);
+    Vector<T, block_type>       C(size,      map_data);
+    Vector<T, coeff_block_type> K(size, T(), map_coeff);
+
+    // ramp does not work for distributed assignments (060726)
+    // A = cos(ramp(0.f, 0.15f*3.14159f, size));
+    for (index_type i=0; i<A.local().size(); ++i)
+    {
+      index_type g_i = global_from_local_index(A, 0, i);
+      A.local().put(i, cos(T(g_i)*0.15f*3.14159f));
+    }
+
+    // ramp does not work for distributed assignments (060726)
+    // K = cos(ramp(0.f, 0.25f*3.14159f, size));
+    for (index_type i=0; i<K.local().size(); ++i)
+    {
+      index_type g_i = global_from_local_index(K, 0, i);
+      K.local().put(i, cos(T(g_i)*0.25f*3.14159f));
+    }
+
+    T alpha;
+
+    vsip::impl::profile::Timer t1;
+    
+    t1.start();
+    for (index_type l=0; l<loop; ++l)
+    {
+      alpha = K.get(1);
+      C = alpha * A;
+    }
+    t1.stop();
+
+    alpha = K.get(1);
+    for (index_type i=0; i<C.local().size(); ++i)
+      test_assert(equal(C.local().get(i), A.local().get(i) * alpha));
+    
+    time = t1.delta();
+  }
+};
+
+#endif // VSIP_BENCHMARKS_VMUL_HPP
Index: benchmarks/memwrite.cpp
===================================================================
--- benchmarks/memwrite.cpp	(revision 0)
+++ benchmarks/memwrite.cpp	(revision 0)
@@ -0,0 +1,116 @@
+/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    benchmarks/memwrite.cpp
+    @author  Jules Bergmann
+    @date    2006-10-12
+    @brief   VSIPL++ Library: Benchmark for memory write bandwidth.
+
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/math.hpp>
+#include <vsip/random.hpp>
+#include <vsip/opt/profile.hpp>
+
+#include <vsip_csl/test.hpp>
+#include "loop.hpp"
+
+using namespace vsip;
+using namespace vsip_csl;
+
+
+
+/***********************************************************************
+  VSIPL++ memwrite
+***********************************************************************/
+
+template <typename T>
+struct t_memwrite1
+{
+  char* what() { return "t_memwrite1"; }
+  int ops_per_point(length_type)  { return 1; }
+  int riob_per_point(length_type) { return 0; }
+  int wiob_per_point(length_type) { return 1*sizeof(T); }
+  int mem_per_point(length_type)  { return 1*sizeof(T); }
+
+  void operator()(length_type size, length_type loop, float& time)
+  {
+    Vector<T>   view(size, T());
+    T           val = T(1);
+    
+    vsip::impl::profile::Timer t1;
+    
+    t1.start();
+    for (index_type l=0; l<loop; ++l)
+      view = val;
+    t1.stop();
+
+    for(index_type i=0; i<size; ++i)
+      test_assert(equal(view.get(i), val));
+    
+    time = t1.delta();
+  }
+};
+
+
+
+// explicit loop
+
+template <typename T>
+struct t_memwrite_expl
+{
+  char* what() { return "t_memwrite_expl"; }
+  int ops_per_point(length_type)  { return 1; }
+  int riob_per_point(length_type) { return 0; }
+  int wiob_per_point(length_type) { return 1*sizeof(T); }
+  int mem_per_point(length_type)  { return 1*sizeof(T); }
+
+  void operator()(length_type size, length_type loop, float& time)
+  {
+    Vector<T>   view(size, T());
+    T           val = T(1);
+    
+    vsip::impl::profile::Timer t1;
+    
+    t1.start();
+    for (index_type l=0; l<loop; ++l)
+      for (index_type i=0; i<size; ++i)
+	view.put(i, val);
+    t1.stop();
+
+    for(index_type i=0; i<size; ++i)
+      test_assert(equal(view.get(i), val));
+    
+    time = t1.delta();
+  }
+};
+
+
+
+
+
+
+void
+defaults(Loop1P&)
+{
+}
+
+
+
+int
+test(Loop1P& loop, int what)
+{
+  switch (what)
+  {
+  case   1: loop(t_memwrite1<float>()); break;
+  case   2: loop(t_memwrite_expl<float>()); break;
+
+  default: return 0;
+  }
+  return 1;
+}
Index: benchmarks/memwrite_simd.cpp
===================================================================
--- benchmarks/memwrite_simd.cpp	(revision 0)
+++ benchmarks/memwrite_simd.cpp	(revision 0)
@@ -0,0 +1,174 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    benchmarks/memwrite_simd.cpp
+    @author  Jules Bergmann
+    @date    2006-10-13
+    @brief   VSIPL++ Library: Benchmark for SIMD memory write.
+
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <iostream>
+#include <complex>
+
+#include <vsip/random.hpp>
+#include <vsip/opt/simd/simd.hpp>
+#include <vsip/opt/profile.hpp>
+#include <vsip/opt/extdata.hpp>
+#include <vsip/opt/ops_info.hpp>
+
+#include "loop.hpp"
+#include "benchmarks.hpp"
+
+using namespace std;
+using namespace vsip;
+
+using impl::Stride_unit_dense;
+using impl::Cmplx_inter_fmt;
+using impl::Cmplx_split_fmt;
+
+
+
+/***********************************************************************
+  Definitions - vector element-wise multiply
+***********************************************************************/
+
+template <typename T,
+	  typename ComplexFmt = Cmplx_inter_fmt>
+struct t_memwrite_simd
+{
+  char* what() { return "t_memwrite_simd"; }
+  int ops_per_point(size_t)  { return 1; }
+  int riob_per_point(size_t) { return 1*sizeof(float); }
+  int wiob_per_point(size_t) { return 1*sizeof(float); }
+  int mem_per_point(size_t)  { return 2*sizeof(float); }
+
+  void operator()(size_t size, size_t loop, float& time)
+  {
+    typedef vsip::impl::simd::Simd_traits<T> S;
+    typedef typename S::simd_type            simd_type;
+
+    typedef impl::Layout<1, row1_type, Stride_unit_dense, Cmplx_inter_fmt> LP;
+    typedef impl::Fast_block<1, T, LP, Local_map> block_type;
+
+    Vector<T, block_type>   Z(size, T(2));
+    T val = T(3);
+
+    vsip::impl::profile::Timer t1;
+
+    {
+      impl::Ext_data<block_type> ext_z(Z.block(), impl::SYNC_OUT);
+    
+      T* pZ = ext_z.data();
+    
+      t1.start();
+      for (size_t l=0; l<loop; ++l)
+      {
+	T* ptr = pZ;
+	simd_type reg0 = S::load_scalar_all(val);
+	for (index_type i=0; i<size; i+=S::vec_size)
+        {
+	  S::store(ptr, reg0);
+	  ptr += S::vec_size;
+	}
+      }
+      t1.stop();
+    }
+    
+    for (index_type i=0; i<size; ++i)
+      test_assert(Z.get(i) == val);
+    
+    time = t1.delta();
+  }
+};
+
+
+
+template <typename T,
+	  typename ComplexFmt = Cmplx_inter_fmt>
+struct t_memwrite_simd_r4
+{
+  char* what() { return "t_memwrite_simd_r4"; }
+  int ops_per_point(size_t)  { return 1; }
+  int riob_per_point(size_t) { return 1*sizeof(float); }
+  int wiob_per_point(size_t) { return 1*sizeof(float); }
+  int mem_per_point(size_t)  { return 2*sizeof(float); }
+
+  void operator()(size_t size, size_t loop, float& time)
+  {
+    typedef vsip::impl::simd::Simd_traits<T> S;
+    typedef typename S::simd_type            simd_type;
+
+    typedef impl::Layout<1, row1_type, Stride_unit_dense, Cmplx_inter_fmt> LP;
+    typedef impl::Fast_block<1, T, LP, Local_map> block_type;
+
+    Vector<T, block_type>   Z(size, T(2));
+    T val = T(3);
+
+    vsip::impl::profile::Timer t1;
+
+    {
+      impl::Ext_data<block_type> ext_z(Z.block(), impl::SYNC_OUT);
+    
+      T* pZ = ext_z.data();
+    
+      t1.start();
+      for (size_t l=0; l<loop; ++l)
+      {
+	T* ptr = pZ;
+	simd_type reg0 = S::load_scalar_all(val);
+
+	length_type n = size;
+
+	while (n >= 4*S::vec_size)
+	{
+	  S::store(ptr + 0*S::vec_size, reg0);
+	  S::store(ptr + 1*S::vec_size, reg0);
+	  S::store(ptr + 2*S::vec_size, reg0);
+	  S::store(ptr + 3*S::vec_size, reg0);
+	  ptr += 4*S::vec_size;
+	  n   -= 4*S::vec_size;
+	}
+
+	while (n >= S::vec_size)
+	{
+	  S::store(ptr + 0*S::vec_size, reg0);
+	  ptr += 1*S::vec_size;
+	  n   -= 1*S::vec_size;
+	}
+      }
+      t1.stop();
+    }
+    
+    for (index_type i=0; i<size; ++i)
+      test_assert(Z.get(i) == val);
+    
+    time = t1.delta();
+  }
+};
+
+
+
+
+
+
+void
+defaults(Loop1P&)
+{
+}
+
+
+
+void
+test(Loop1P& loop, int what)
+{
+  typedef complex<float> cf_type;
+  switch (what)
+  {
+  case  1: loop(t_memwrite_simd<float>()); break;
+  case  2: loop(t_memwrite_simd_r4<float>()); break;
+  }
+}
Index: benchmarks/sumval.cpp
===================================================================
--- benchmarks/sumval.cpp	(revision 154174)
+++ benchmarks/sumval.cpp	(working copy)
@@ -25,6 +25,10 @@
 
 
 
+/***********************************************************************
+  VSIPL++ sumval
+***********************************************************************/
+
 template <typename T>
 struct t_sumval1
 {
@@ -101,6 +105,58 @@
 
 
 
+/***********************************************************************
+  get/put sumval
+***********************************************************************/
+
+template <typename T>
+struct t_sumval_gp
+{
+  char* what() { return "t_sumval_gp"; }
+  int ops_per_point(length_type)  { return 1; }
+  int riob_per_point(length_type) { return sizeof(T); }
+  int wiob_per_point(length_type) { return 0; }
+  int mem_per_point(length_type)  { return 1*sizeof(T); }
+
+  void operator()(length_type size, length_type loop, float& time)
+  {
+    Vector<T>   view(size, T());
+    T           val = T();
+    
+    Rand<T>     gen(0, 0);
+
+    if (init_ == 0)
+      view = gen.randu(size);
+    else if (init_ == 1)
+      view(0) = T(2);
+    else if (init_ == 2)
+      view(size-1) = T(2);
+    
+    vsip::impl::profile::Timer t1;
+    
+    t1.start();
+    for (index_type l=0; l<loop; ++l)
+    {
+      val = T();
+      for (index_type i=0; i<size; ++i)
+	val += view.get(i);
+    }
+    t1.stop();
+
+    if (init_ == 1 || init_ == 2)
+      test_assert(equal(val, T(2)));
+    
+    time = t1.delta();
+  }
+
+  t_sumval_gp(int init) : init_(init) {}
+
+  // member data.
+  int init_;
+};
+
+
+
 void
 defaults(Loop1P&)
 {
@@ -119,6 +175,8 @@
 
   case  11: loop(t_sumval1<int>(0)); break;
 
+  case  21: loop(t_sumval_gp<float>(0)); break;
+
   case 101: loop(t_sumval2<float>()); break;
   default: return 0;
   }
Index: benchmarks/sumval_simd.cpp
===================================================================
--- benchmarks/sumval_simd.cpp	(revision 0)
+++ benchmarks/sumval_simd.cpp	(revision 0)
@@ -0,0 +1,371 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    benchmarks/sumval_simd.cpp
+    @author  Jules Bergmann
+    @date    2006-10-13
+    @brief   VSIPL++ Library: Benchmark for SIMD sumval.
+
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <iostream>
+#include <complex>
+
+#include <vsip/random.hpp>
+#include <vsip/opt/simd/simd.hpp>
+#include <vsip/opt/profile.hpp>
+#include <vsip/opt/extdata.hpp>
+#include <vsip/opt/ops_info.hpp>
+
+#include "loop.hpp"
+#include "benchmarks.hpp"
+
+using namespace std;
+using namespace vsip;
+
+using impl::Stride_unit_dense;
+using impl::Cmplx_inter_fmt;
+using impl::Cmplx_split_fmt;
+
+
+
+/***********************************************************************
+  SIMD sumval (overhead included)
+***********************************************************************/
+
+template <typename T,
+	  typename ComplexFmt = Cmplx_inter_fmt>
+struct t_sumval_simd
+{
+  typedef vsip::impl::simd::Simd_traits<T> S;
+  typedef typename S::simd_type            simd_type;
+
+  char* what() { return "t_sumval_simd"; }
+  int ops_per_point(size_t)  { return 1; }
+  int riob_per_point(size_t) { return 1*sizeof(float); }
+  int wiob_per_point(size_t) { return 1*sizeof(float); }
+  int mem_per_point(size_t)  { return 2*sizeof(float); }
+
+  void use(simd_type) {}
+
+  void operator()(size_t size, size_t loop, float& time)
+  {
+    typedef impl::Layout<1, row1_type, Stride_unit_dense, Cmplx_inter_fmt> LP;
+    typedef impl::Fast_block<1, T, LP, Local_map> block_type;
+
+    Vector<T, block_type>   Z(size, T(2));
+    T res;
+
+    vsip::impl::profile::Timer t1;
+
+    {
+      impl::Ext_data<block_type> ext_z(Z.block(), impl::SYNC_OUT);
+    
+      T* pZ = ext_z.data();
+      T psum[S::vec_size];
+
+      t1.start();
+      for (size_t l=0; l<loop; ++l)
+      {
+	T* ptr = pZ;
+	simd_type vsum = S::zero();
+	simd_type reg0;
+	for (index_type i=0; i<size; i+=S::vec_size)
+        {
+	  reg0 = S::load(ptr);
+	  vsum = S::add(vsum, reg0);
+	  ptr += S::vec_size;
+	}
+	S::store(psum, vsum);
+	res = psum[0];
+	for (index_type i=1; i<S::vec_size; i+=1)
+	  res += psum[i];
+      }
+      
+      t1.stop();
+    }
+
+    test_assert(res == T(size*2));
+
+    
+    time = t1.delta();
+  }
+};
+
+
+
+/***********************************************************************
+  SIMD sumval (overhead not included)
+***********************************************************************/
+
+template <typename T,
+	  typename ComplexFmt = Cmplx_inter_fmt>
+struct t_sumval_simd_no // no-overheads
+{
+  typedef vsip::impl::simd::Simd_traits<T> S;
+  typedef typename S::simd_type            simd_type;
+
+  char* what() { return "t_sumval_simd"; }
+  int ops_per_point(size_t)  { return 1; }
+  int riob_per_point(size_t) { return 1*sizeof(float); }
+  int wiob_per_point(size_t) { return 1*sizeof(float); }
+  int mem_per_point(size_t)  { return 2*sizeof(float); }
+
+  void use(simd_type) {}
+
+  void operator()(size_t size, size_t loop, float& time)
+  {
+    typedef impl::Layout<1, row1_type, Stride_unit_dense, Cmplx_inter_fmt> LP;
+    typedef impl::Fast_block<1, T, LP, Local_map> block_type;
+
+    Vector<T, block_type>   Z(size, T(2));
+    T res;
+
+    vsip::impl::profile::Timer t1;
+
+    {
+      impl::Ext_data<block_type> ext_z(Z.block(), impl::SYNC_OUT);
+    
+      T* pZ = ext_z.data();
+      T psum[S::vec_size];
+
+      simd_type vsum = S::zero();
+      simd_type reg0;
+
+      t1.start();
+      for (size_t l=0; l<loop; ++l)
+      {
+	T* ptr = pZ;
+	vsum = S::zero();
+	for (index_type i=0; i<size; i+=S::vec_size)
+        {
+	  reg0 = S::load(ptr);
+	  vsum = S::add(vsum, reg0);
+	  ptr += S::vec_size;
+	}
+      }
+      t1.stop();
+
+      // These overheads aren't included in timing.
+      S::store(psum, vsum);
+      res = psum[0];
+      for (index_type i=1; i<S::vec_size; i+=1)
+	res += psum[i];
+    }
+
+    test_assert(res == T(size*2));
+    
+    time = t1.delta();
+  }
+};
+
+
+
+/***********************************************************************
+  SIMD sumval (overhead included, loop unrolled 4 times)
+***********************************************************************/
+
+template <typename T,
+	  typename ComplexFmt = Cmplx_inter_fmt>
+struct t_sumval_simd_r4
+{
+  char* what() { return "t_sumval_simd_r4"; }
+  int ops_per_point(size_t)  { return 1; }
+  int riob_per_point(size_t) { return 1*sizeof(float); }
+  int wiob_per_point(size_t) { return 1*sizeof(float); }
+  int mem_per_point(size_t)  { return 2*sizeof(float); }
+
+  void operator()(size_t size, size_t loop, float& time)
+  {
+    typedef vsip::impl::simd::Simd_traits<T> S;
+    typedef typename S::simd_type            simd_type;
+
+    typedef impl::Layout<1, row1_type, Stride_unit_dense, Cmplx_inter_fmt> LP;
+    typedef impl::Fast_block<1, T, LP, Local_map> block_type;
+
+    Vector<T, block_type>   Z(size, T(2));
+    T res;
+
+    vsip::impl::profile::Timer t1;
+
+    {
+      impl::Ext_data<block_type> ext_z(Z.block(), impl::SYNC_OUT);
+    
+      T* pZ = ext_z.data();
+      T psum[S::vec_size];
+    
+      t1.start();
+      for (size_t l=0; l<loop; ++l)
+      {
+	T* ptr = pZ;
+	simd_type reg0;
+	simd_type reg1;
+	simd_type reg2;
+	simd_type reg3;
+	simd_type vsum0 = S::zero();
+	simd_type vsum1 = S::zero();
+	simd_type vsum2 = S::zero();
+	simd_type vsum3 = S::zero();
+
+	length_type n = size;
+
+	while (n >= 4*S::vec_size)
+	{
+	  reg0 = S::load(ptr + 0*S::vec_size);
+	  reg1 = S::load(ptr + 1*S::vec_size);
+	  reg2 = S::load(ptr + 2*S::vec_size);
+	  reg3 = S::load(ptr + 3*S::vec_size);
+	  vsum0 = S::add(reg0, vsum0);
+	  vsum1 = S::add(reg1, vsum1);
+	  vsum2 = S::add(reg2, vsum2);
+	  vsum3 = S::add(reg3, vsum3);
+	  ptr += 4*S::vec_size;
+	  n   -= 4*S::vec_size;
+	}
+
+	while (n >= S::vec_size)
+	{
+	  reg0 = S::load(ptr + 0*S::vec_size);
+	  vsum0 = S::add(reg0, vsum0);
+	  ptr += 1*S::vec_size;
+	  n   -= 1*S::vec_size;
+	}
+
+	vsum0 = S::add(vsum0, vsum1);
+	vsum2 = S::add(vsum2, vsum3);
+	vsum0 = S::add(vsum0, vsum2);
+
+	S::store(psum, vsum0);
+	res = psum[0];
+	for (index_type i=1; i<S::vec_size; i+=1)
+	  res += psum[i];
+      }
+      t1.stop();
+    }
+    
+    test_assert(res == T(size*2));
+    
+    time = t1.delta();
+  }
+};
+
+
+
+/***********************************************************************
+  SIMD sumval (overhead not included, loop unrolled 4 times)
+***********************************************************************/
+
+template <typename T,
+	  typename ComplexFmt = Cmplx_inter_fmt>
+struct t_sumval_simd_r4_no
+{
+  char* what() { return "t_sumval_simd_r4_no"; }
+  int ops_per_point(size_t)  { return 1; }
+  int riob_per_point(size_t) { return 1*sizeof(float); }
+  int wiob_per_point(size_t) { return 1*sizeof(float); }
+  int mem_per_point(size_t)  { return 2*sizeof(float); }
+
+  void operator()(size_t size, size_t loop, float& time)
+  {
+    typedef vsip::impl::simd::Simd_traits<T> S;
+    typedef typename S::simd_type            simd_type;
+
+    typedef impl::Layout<1, row1_type, Stride_unit_dense, Cmplx_inter_fmt> LP;
+    typedef impl::Fast_block<1, T, LP, Local_map> block_type;
+
+    Vector<T, block_type>   Z(size, T(2));
+    T res;
+
+    vsip::impl::profile::Timer t1;
+
+    {
+      impl::Ext_data<block_type> ext_z(Z.block(), impl::SYNC_OUT);
+    
+      T* pZ = ext_z.data();
+      T psum[S::vec_size];
+
+      simd_type reg0;
+      simd_type reg1;
+      simd_type reg2;
+      simd_type reg3;
+      simd_type vsum0 = S::zero();
+      simd_type vsum1 = S::zero();
+      simd_type vsum2 = S::zero();
+      simd_type vsum3 = S::zero();
+      
+      t1.start();
+      for (size_t l=0; l<loop; ++l)
+      {
+	T* ptr = pZ;
+
+	length_type n = size;
+
+	vsum0 = S::zero();
+	vsum1 = S::zero();
+	vsum2 = S::zero();
+	vsum3 = S::zero();
+
+	while (n >= 4*S::vec_size)
+	{
+	  reg0 = S::load(ptr + 0*S::vec_size);
+	  reg1 = S::load(ptr + 1*S::vec_size);
+	  reg2 = S::load(ptr + 2*S::vec_size);
+	  reg3 = S::load(ptr + 3*S::vec_size);
+	  vsum0 = S::add(reg0, vsum0);
+	  vsum1 = S::add(reg1, vsum1);
+	  vsum2 = S::add(reg2, vsum2);
+	  vsum3 = S::add(reg3, vsum3);
+	  ptr += 4*S::vec_size;
+	  n   -= 4*S::vec_size;
+	}
+
+	while (n >= S::vec_size)
+	{
+	  reg0 = S::load(ptr + 0*S::vec_size);
+	  vsum0 = S::add(reg0, vsum0);
+	  ptr += 1*S::vec_size;
+	  n   -= 1*S::vec_size;
+	}
+      }
+      t1.stop();
+
+      vsum0 = S::add(vsum0, vsum1);
+      vsum2 = S::add(vsum2, vsum3);
+      vsum0 = S::add(vsum0, vsum2);
+
+      S::store(psum, vsum0);
+      res = psum[0];
+      for (index_type i=1; i<S::vec_size; i+=1)
+	res += psum[i];
+    }
+    
+    test_assert(res == T(size*2));
+    
+    time = t1.delta();
+  }
+};
+
+
+
+void
+defaults(Loop1P&)
+{
+}
+
+
+
+void
+test(Loop1P& loop, int what)
+{
+  typedef complex<float> cf_type;
+  switch (what)
+  {
+  case   1: loop(t_sumval_simd<float>()); break;
+  case   2: loop(t_sumval_simd_r4<float>()); break;
+  case 101: loop(t_sumval_simd_no<float>()); break;
+  case 102: loop(t_sumval_simd_r4_no<float>()); break;
+  }
+}
Index: benchmarks/vmul_par.cpp
===================================================================
--- benchmarks/vmul_par.cpp	(revision 0)
+++ benchmarks/vmul_par.cpp	(revision 0)
@@ -0,0 +1,86 @@
+/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    benchmarks/vmul_par.cpp
+    @author  Jules Bergmann
+    @date    2006-10-12
+    @brief   VSIPL++ Library: Benchmark for parallel vector multiply cases.
+
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <iostream>
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/math.hpp>
+#include <vsip/random.hpp>
+#include <vsip/selgen.hpp>
+#include <vsip/core/setup_assign.hpp>
+
+#include "vmul.hpp"
+#include "benchmarks.hpp"
+
+using namespace vsip;
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+void
+defaults(Loop1P&)
+{
+}
+
+
+
+int
+test(Loop1P& loop, int what)
+{
+  switch (what)
+  {
+  case  92: loop(t_vmul1_nonglobal<complex<float> >()); break;
+
+  case 101: loop(t_vmul1<        float , Map<> >()); break;
+  case 102: loop(t_vmul1<complex<float>, Map<> >()); break;
+
+  case 111: loop(t_vmul1<        float , Map<>, Barrier>()); break;
+  case 112: loop(t_vmul1<complex<float>, Map<>, Barrier>()); break;
+
+  case 121: loop(t_vmul1_local<        float  >()); break;
+  case 122: loop(t_vmul1_local<complex<float> >()); break;
+
+  case 131: loop(t_vmul1_early_local<        float  >()); break;
+  case 132: loop(t_vmul1_early_local<complex<float> >()); break;
+
+  case 141: loop(t_vmul1_sa<        float  >()); break;
+  case 142: loop(t_vmul1_sa<complex<float> >()); break;
+
+  case 0:
+    std::cout
+      << "vmul -- vector multiplication\n"
+
+      << "  -91 -- Vector<        float > * Vector<        float > NONGLOBAL\n"
+      << "  -92 -- Vector<complex<float>> * Vector<complex<float>> NONGLOBAL\n"
+
+      << " -101 -- Vector<        float > * Vector<        float > PAR\n"
+      << " -102 -- Vector<complex<float>> * Vector<complex<float>> PAR\n"
+      << " -111 -- Vector<        float > * Vector<        float > PAR sync\n"
+      << " -112 -- Vector<complex<float>> * Vector<complex<float>> PAR sync\n"
+      << " -121 -- Vector<        float > * Vector<        float > PAR local\n"
+      << " -122 -- Vector<complex<float>> * Vector<complex<float>> PAR local\n"
+      << " -131 -- Vector<        float > * Vector<        float > PAR early local\n"
+      << " -132 -- Vector<complex<float>> * Vector<complex<float>> PAR early local\n"
+      << " -141 -- Vector<        float > * Vector<        float > PAR setup assign\n"
+      << " -142 -- Vector<complex<float>> * Vector<complex<float>> PAR setup assign\n"
+      ;
+
+  default:
+    return 0;
+  }
+  return 1;
+}
Index: benchmarks/memwrite_sal.cpp
===================================================================
--- benchmarks/memwrite_sal.cpp	(revision 0)
+++ benchmarks/memwrite_sal.cpp	(revision 0)
@@ -0,0 +1,102 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    benchmarks/memwrite_sal.cpp
+    @author  Jules Bergmann
+    @date    2006-10-12
+    @brief   VSIPL++ Library: Benchmark for SAL memory write.
+
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <iostream>
+#include <complex>
+
+#include <vsip/random.hpp>
+#include <vsip/opt/profile.hpp>
+#include <vsip/opt/extdata.hpp>
+#include <vsip/opt/ops_info.hpp>
+#include <sal.h>
+
+#include "loop.hpp"
+#include "benchmarks.hpp"
+
+using namespace std;
+using namespace vsip;
+
+using impl::Stride_unit_dense;
+using impl::Cmplx_inter_fmt;
+using impl::Cmplx_split_fmt;
+
+
+
+/***********************************************************************
+  Definitions - vector element-wise multiply
+***********************************************************************/
+
+template <typename T,
+	  typename ComplexFmt = Cmplx_inter_fmt>
+struct t_memwrite_sal;
+
+template <typename ComplexFmt>
+struct t_memwrite_sal<float, ComplexFmt>
+{
+  typedef float T;
+
+  char* what() { return "t_memwrite_sal"; }
+  int ops_per_point(size_t)  { return 1; }
+  int riob_per_point(size_t) { return 1*sizeof(float); }
+  int wiob_per_point(size_t) { return 1*sizeof(float); }
+  int mem_per_point(size_t)  { return 2*sizeof(float); }
+
+  void operator()(size_t size, size_t loop, float& time)
+  {
+    typedef impl::Layout<1, row1_type, Stride_unit_dense, Cmplx_inter_fmt> LP;
+    typedef impl::Fast_block<1, T, LP, Local_map> block_type;
+
+    Vector<T, block_type>   Z(size, T(2));
+    T val = T(3);
+
+    vsip::impl::profile::Timer t1;
+
+    {
+      impl::Ext_data<block_type> ext_z(Z.block(), impl::SYNC_OUT);
+    
+      T* pZ = ext_z.data();
+    
+      t1.start();
+      for (size_t l=0; l<loop; ++l)
+	vfillx(&val, pZ, 1, size, 0);
+      t1.stop();
+    }
+    
+    for (index_type i=0; i<size; ++i)
+      test_assert(Z.get(i) == val);
+    
+    time = t1.delta();
+  }
+};
+
+
+
+
+
+
+void
+defaults(Loop1P&)
+{
+}
+
+
+
+void
+test(Loop1P& loop, int what)
+{
+  typedef complex<float> cf_type;
+  switch (what)
+  {
+  case  1: loop(t_memwrite_sal<float>()); break;
+  }
+}
Index: examples/mercury/mcoe-setup.sh
===================================================================
--- examples/mercury/mcoe-setup.sh	(revision 154174)
+++ examples/mercury/mcoe-setup.sh	(working copy)
@@ -142,6 +142,11 @@
   cfg_flags="$cfg_flags --disable-exceptions"
 fi
 
+# select timer
+if test "x$timer" = "x"; then
+  # timer=realtime
+  timer=mcoe_tmr
+fi
 
 #########################################################################
 # export environment variables
@@ -174,4 +179,4 @@
 	--with-lapack=no			\
 	$cfg_flags				\
 	--with-test-level=$testlevel		\
-	--enable-timer=realtime
+	--enable-timer=$timer
