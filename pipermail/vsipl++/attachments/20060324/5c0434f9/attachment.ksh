Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.419
diff -u -r1.419 ChangeLog
--- ChangeLog	23 Mar 2006 15:06:11 -0000	1.419
+++ ChangeLog	24 Mar 2006 12:35:39 -0000
@@ -1,3 +1,8 @@
+2006-03-24  Jules Bergmann  <jules@codesourcery.com>
+
+	* benchmarks/loop.hpp: Fix macro typo.  Fix Wall warnings.
+	  Use different loop variables for nested loops.
+
 2006-03-23  Stefan Seefeld  <stefan@codesourcery.com>
 
 	* tests/QMTest/vpp_database.py: Make 'parallel_service' a global
Index: benchmarks/loop.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/loop.hpp,v
retrieving revision 1.12
diff -u -r1.12 loop.hpp
--- benchmarks/loop.hpp	21 Mar 2006 15:53:09 -0000	1.12
+++ benchmarks/loop.hpp	24 Mar 2006 12:35:39 -0000
@@ -190,7 +190,6 @@
   float    time;
   double   growth;
   unsigned const n_time = samples_;
-  char     filename[256];
 
   COMMUNICATOR_TYPE comm  = DEFAULT_COMMUNICATOR();
   PROCESSOR_TYPE    rank  = RANK(comm);
@@ -198,7 +197,7 @@
 
   std::vector<float> mtime(n_time);
 
-#if DO_PARALLEL
+#if PARALLEL_LOOP
   Vector<float, Dense<1, float, row1_type, Map<> > >
     dist_time(nproc, Map<>(nproc));
   Vector<float, Dense<1, float, row1_type, Global_map<1> > > glob_time(nproc);
@@ -254,7 +253,7 @@
     printf("# start_loop       : %lu\n", (unsigned long) loop);
   }
 
-#if DO_PARALLEL
+#if PARALLEL_LOOP
   if (this->do_prof_)
     vsip::impl::profile::prof->set_mode(vsip::impl::profile::pm_accum);
 #endif
@@ -264,7 +263,7 @@
   {
     M = (1 << i);
 
-    for (unsigned i=0; i<n_time; ++i)
+    for (unsigned j=0; j<n_time; ++j)
     {
       BARRIER(comm);
       fcn(M, loop, time);
@@ -275,12 +274,13 @@
 
       Index<1> idx;
 
-      mtime[i] = maxval(LOCAL(glob_time), idx);
+      mtime[j] = maxval(LOCAL(glob_time), idx);
     }
 
-#if DO_PARALLEL
+#if PARALLEL_LOOP
     if (this->do_prof_)
     {
+      char     filename[256];
       sprintf(filename, "vprof.%lu.out", (unsigned long) M);
       vsip::impl::profile::prof->dump(filename);
     }
@@ -353,7 +353,7 @@
   PROCESSOR_TYPE    rank  = RANK(comm);
   PROCESSOR_TYPE    nproc = NUM_PROCESSORS();
 
-#if DO_PARALLEL
+#if PARALLEL_LOOP
   Vector<float, Dense<1, float, row1_type, Map<> > >
     dist_time(nproc, Map<>(nproc));
   Vector<float, Dense<1, float, row1_type, Global_map<1> > > glob_time(nproc);
@@ -382,7 +382,7 @@
     printf("# start_loop       : %lu\n", (unsigned long) loop);
   }
 
-#if DO_PARALLEL
+#if PARALLEL_LOOP
   if (this->do_prof_)
     vsip::impl::profile::prof->set_mode(vsip::impl::profile::pm_accum);
 #endif
