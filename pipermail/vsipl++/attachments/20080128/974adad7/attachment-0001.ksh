Index: vendor/fftw/kernel/timer.c
===================================================================
--- vendor/fftw/kernel/timer.c	(revision 185668)
+++ vendor/fftw/kernel/timer.c	(working copy)
@@ -38,7 +38,30 @@
 crude_time X(get_crude_time)(void)
 {
      crude_time tv;
+/* 080128: powerpc-eabi simulator on windows does not support gettimeofday
+ *         or clock (the powerpc-eabi simulator on linux supports both).
+ *         Calling gettimeofday results in a:
+ *            'do_call() unimplemented call gettimeofday'
+ *         error.
+ *
+ *         However, FFTW uses this to make sure the planning time
+ *         limit isn't exceeded.  Since the powerpc-eabi doesn't have
+ *         a hires timer, all planning is done in ESTIMATE mode which
+ *         ignores the planning time limit.  Hence, we can elide calls
+ *         to gettimeofday on powerpc-eabi without loss of
+ *         functionality.
+ *
+ *         Defining GETTIMEOFDAY_BROKEN causes a 0 time to be returned.
+ *
+ *         From VSIPL++, this is set at configure time like so:
+ *           --with-fftw3-cflags="-DGETTIMEOFDAY_BROKEN"
+ */
+#if defined(GETTIMEOFDAY_BROKEN)
+     tv.tv_sec  = 0;
+     tv.tv_usec = 0;
+#else
      gettimeofday(&tv, 0);
+#endif
      return tv;
 }
 
@@ -48,7 +71,12 @@
 double X(elapsed_since)(crude_time t0)
 {
      crude_time t1;
+#if defined(GETTIMEOFDAY_BROKEN)
+     t1.tv_sec  = 0;
+     t1.tv_usec = 0;
+#else
      gettimeofday(&t1, 0);
+#endif
      return elapsed_sec(t1, t0);
 }
 
Index: vendor/fftw/ChangeLog.csl
===================================================================
--- vendor/fftw/ChangeLog.csl	(revision 185668)
+++ vendor/fftw/ChangeLog.csl	(working copy)
@@ -1,3 +1,8 @@
+2008-01-28  Jules Bergmann  <jules@codesourcery.com>
+
+	* kernel/timer.c (GETTIMEOFDAY_BROKEN): New macro to work around
+	  unimplemented gettimeofday/clock on window's powerpc-eabi sim.
+
 2007-10-25  Jules Bergmann  <jules@codesourcery.com>
 
 	Merge changes from trunk-3.0.
