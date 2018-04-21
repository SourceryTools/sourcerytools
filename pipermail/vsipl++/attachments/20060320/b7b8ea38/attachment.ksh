--- old-work/benchmarks/loop.hpp	2006-03-20 19:34:23.000000000 +0000
+++ new-work/benchmarks/loop.hpp	2006-03-20 19:34:23.000000000 +0000
@@ -23,6 +23,29 @@
 #include <vsip/map.hpp>
 #include <vsip/parallel.hpp>
 
+#if VSIP_IMPL_SOURCERY_VPP
+#  define PARALLEL_LOOP 1
+#else
+#  define PARALLEL_LOOP 0
+#endif
+
+#if PARALLEL_LOOP
+#  define COMMUNICATOR_TYPE      vsip::impl::Communicator
+#  define PROCESSOR_TYPE         vsip::processor_type
+#  define DEFAULT_COMMUNICATOR() vsip_::impl::default_communicator
+#  define RANK(comm)             comm.rank()
+#  define BARRIER(comm)          comm.barrier()
+#  define NUM_PROCESSORS()       vsip::num_processors()
+#  define LOCAL(view)            view.local()
+#else
+#  define COMMUNICATOR_TYPE      int
+#  define PROCESSOR_TYPE         int
+#  define DEFAULT_COMMUNICATOR() 0
+#  define RANK(comm)             0
+#  define NUM_PROCESSORS()       1
+#  define LOCAL(view)            view
+#endif
+
 
 
 /***********************************************************************
@@ -168,15 +191,20 @@
   unsigned const n_time = samples_;
   char     filename[256];
 
-  vsip::impl::Communicator comm  = vsip::impl::default_communicator();
-  vsip::processor_type     rank  = comm.rank();
-  vsip::processor_type     nproc = vsip::num_processors();
+  COMMUNICATOR_TYPE comm  = DEFAULT_COMMUNICATOR();
+  PROCESSOR_TYPE    rank  = RANK(comm);
+  PROCESSOR_TYPE    nproc = NUM_PROCESSORS();
 
   std::vector<float> mtime(n_time);
 
+#if DO_PARALLEL
   Vector<float, Dense<1, float, row1_type, Map<> > >
     dist_time(nproc, Map<>(nproc));
   Vector<float, Dense<1, float, row1_type, Global_map<1> > > glob_time(nproc);
+#else
+  Vector<float, Dense<1, float, row1_type> > dist_time(nproc);
+  Vector<float, Dense<1, float, row1_type> > glob_time(nproc);
+#endif
 
   loop = (1 << loop_start_);
   M    = (1 << cal_);
@@ -185,16 +213,16 @@
   while (1)
   {
     // printf("%d: calib %5d\n", rank, loop);
-    comm.barrier();
+    BARRIER(comm);
     fcn(M, loop, time);
-    comm.barrier();
+    BARRIER(comm);
 
-    dist_time.local().put(0, time);
+    LOCAL(dist_time).put(0, time);
     glob_time = dist_time;
 
     Index<1> idx;
 
-    time = maxval(glob_time.local(), idx);
+    time = maxval(LOCAL(glob_time), idx);
 
     if (time <= 0.01) time = 0.01;
     // printf("%d: time %f\n", rank, time);
@@ -235,16 +263,16 @@
 
     for (unsigned i=0; i<n_time; ++i)
     {
-      comm.barrier();
+      BARRIER(comm);
       fcn(M, loop, time);
-      comm.barrier();
+      BARRIER(comm);
 
-      dist_time.local().put(0, time);
+      LOCAL(dist_time).put(0, time);
       glob_time = dist_time;
 
       Index<1> idx;
 
-      mtime[i] = maxval(glob_time.local(), idx);
+      mtime[i] = maxval(LOCAL(glob_time), idx);
     }
 
     if (this->do_prof_)

