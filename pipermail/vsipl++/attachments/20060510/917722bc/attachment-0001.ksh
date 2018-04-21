? vendor/fftw/_darcs
Index: vendor/fftw/kernel/cycle.h
===================================================================
RCS file: /home/cvs/Repository/fftw/kernel/cycle.h,v
retrieving revision 1.1.1.1
diff -u -r1.1.1.1 cycle.h
--- vendor/fftw/kernel/cycle.h	1 Dec 2005 10:33:03 -0000	1.1.1.1
+++ vendor/fftw/kernel/cycle.h	11 May 2006 02:51:14 -0000
@@ -153,6 +153,29 @@
 
 #define HAVE_TICK_COUNTER
 #endif
+
+/* GreenHills */
+
+#if (defined(__ghs__) && defined(__powerpc__) || defined(__ppc__)) && !defined(HAVE_TICK_COUNTER)
+typedef unsigned long long ticks;
+
+static __inline__ ticks getticks(void)
+{
+     unsigned int tbl, tbu0, tbu1;
+
+     do {
+	  __asm__ __volatile__ ("mftbu %0" : "=r"(tbu0));
+	  __asm__ __volatile__ ("mftb %0" : "=r"(tbl));
+	  __asm__ __volatile__ ("mftbu %0" : "=r"(tbu1));
+     } while (tbu0 != tbu1);
+
+     return (((unsigned long long)tbu0) << 32) | tbl;
+}
+
+INLINE_ELAPSED(__inline__)
+
+#define HAVE_TICK_COUNTER
+#endif
 /*----------------------------------------------------------------*/
 /*
  * Pentium cycle counter 
Index: vendor/fftw/libbench2/Makefile.in
===================================================================
RCS file: /home/cvs/Repository/fftw/libbench2/Makefile.in,v
retrieving revision 1.1.1.1
diff -u -r1.1.1.1 Makefile.in
--- vendor/fftw/libbench2/Makefile.in	1 Dec 2005 10:33:07 -0000	1.1.1.1
+++ vendor/fftw/libbench2/Makefile.in	11 May 2006 02:51:14 -0000
@@ -224,7 +224,7 @@
 all: all-am
 
 .SUFFIXES:
-.SUFFIXES: .c .lo .o .obj
+.SUFFIXES: .c .lo .$(OBJEXT) .obj
 $(srcdir)/Makefile.in: @MAINTAINER_MODE_TRUE@ Makefile.am  $(top_srcdir)/configure.ac $(ACLOCAL_M4)
 	cd $(top_srcdir) && \
 	  $(AUTOMAKE) --gnu  libbench2/Makefile
@@ -279,7 +279,7 @@
 distclean-depend:
 	-rm -rf ./$(DEPDIR)
 
-.c.o:
+.c.$(OBJEXT):
 @am__fastdepCC_TRUE@	if $(COMPILE) -MT $@ -MD -MP -MF "$(DEPDIR)/$*.Tpo" \
 @am__fastdepCC_TRUE@	  -c -o $@ `test -f '$<' || echo '$(srcdir)/'`$<; \
 @am__fastdepCC_TRUE@	then mv "$(DEPDIR)/$*.Tpo" "$(DEPDIR)/$*.Po"; \
Index: vendor/fftw/libbench2/timer.c
===================================================================
RCS file: /home/cvs/Repository/fftw/libbench2/timer.c,v
retrieving revision 1.1.1.1
diff -u -r1.1.1.1 timer.c
--- vendor/fftw/libbench2/timer.c	1 Dec 2005 10:33:07 -0000	1.1.1.1
+++ vendor/fftw/libbench2/timer.c	11 May 2006 02:51:14 -0000
@@ -85,6 +85,25 @@
 #define HAVE_TIMER
 #endif
 
+#if !defined(HAVE_TIMER)
+typedef struct timespec mytime;
+
+static mytime get_time(void)
+{
+     struct timespec tv;
+     clock_gettime(CLOCK_REALTIME, &tv);
+     return tv;
+}
+
+static double elapsed(mytime t1, mytime t0)
+{
+     return (double)(t1.tv_sec - t0.tv_sec) +
+	  (double)(t1.tv_nsec - t0.tv_nsec) * 1.0E-9;
+}
+
+#define HAVE_TIMER
+#endif
+
 #ifndef HAVE_TIMER
 #error "timer not defined"
 #endif
Index: vendor/fftw/tests/Makefile.in
===================================================================
RCS file: /home/cvs/Repository/fftw/tests/Makefile.in,v
retrieving revision 1.1.1.1
diff -u -r1.1.1.1 Makefile.in
--- vendor/fftw/tests/Makefile.in	1 Dec 2005 10:33:07 -0000	1.1.1.1
+++ vendor/fftw/tests/Makefile.in	11 May 2006 02:51:14 -0000
@@ -214,7 +214,7 @@
 all: all-am
 
 .SUFFIXES:
-.SUFFIXES: .c .lo .o .obj
+.SUFFIXES: .c .lo .$(OBJEXT) .obj
 $(srcdir)/Makefile.in: @MAINTAINER_MODE_TRUE@ Makefile.am  $(top_srcdir)/configure.ac $(ACLOCAL_M4)
 	cd $(top_srcdir) && \
 	  $(AUTOMAKE) --gnu  tests/Makefile
@@ -243,7 +243,7 @@
 distclean-depend:
 	-rm -rf ./$(DEPDIR)
 
-.c.o:
+.c.$(OBJEXT):
 @am__fastdepCC_TRUE@	if $(COMPILE) -MT $@ -MD -MP -MF "$(DEPDIR)/$*.Tpo" \
 @am__fastdepCC_TRUE@	  -c -o $@ `test -f '$<' || echo '$(srcdir)/'`$<; \
 @am__fastdepCC_TRUE@	then mv "$(DEPDIR)/$*.Tpo" "$(DEPDIR)/$*.Po"; \
Index: vendor/fftw/tools/Makefile.in
===================================================================
RCS file: /home/cvs/Repository/fftw/tools/Makefile.in,v
retrieving revision 1.1.1.1
diff -u -r1.1.1.1 Makefile.in
--- vendor/fftw/tools/Makefile.in	1 Dec 2005 10:33:02 -0000	1.1.1.1
+++ vendor/fftw/tools/Makefile.in	11 May 2006 02:51:14 -0000
@@ -177,7 +177,7 @@
 @THREADS_TRUE@LIBFFTWTHREADS = $(top_builddir)/threads/libfftw3@PREC_SUFFIX@_threads.la
 
 fftw@PREC_SUFFIX@_wisdom_SOURCES = fftw-wisdom.c
-fftw@PREC_SUFFIX@_wisdom_LDADD = $(top_builddir)/tests/bench.o	\
+fftw@PREC_SUFFIX@_wisdom_LDADD = $(top_builddir)/tests/bench.$(OBJEXT)	\
 $(LIBFFTWTHREADS) $(top_builddir)/libfftw3@PREC_SUFFIX@.la	\
 $(top_builddir)/libbench2/libbench2.a $(THREADLIBS)
 
@@ -192,12 +192,12 @@
 fftw@PREC_SUFFIX@_wisdom_OBJECTS = \
 	$(am_fftw@PREC_SUFFIX@_wisdom_OBJECTS)
 @THREADS_TRUE@fftw@PREC_SUFFIX@_wisdom_DEPENDENCIES = \
-@THREADS_TRUE@	$(top_builddir)/tests/bench.o \
+@THREADS_TRUE@	$(top_builddir)/tests/bench.$(OBJEXT) \
 @THREADS_TRUE@	$(top_builddir)/threads/libfftw3@PREC_SUFFIX@_threads.la \
 @THREADS_TRUE@	$(top_builddir)/libfftw3@PREC_SUFFIX@.la \
 @THREADS_TRUE@	$(top_builddir)/libbench2/libbench2.a
 @THREADS_FALSE@fftw@PREC_SUFFIX@_wisdom_DEPENDENCIES = \
-@THREADS_FALSE@	$(top_builddir)/tests/bench.o \
+@THREADS_FALSE@	$(top_builddir)/tests/bench.$(OBJEXT) \
 @THREADS_FALSE@	$(top_builddir)/libfftw3@PREC_SUFFIX@.la \
 @THREADS_FALSE@	$(top_builddir)/libbench2/libbench2.a
 fftw@PREC_SUFFIX@_wisdom_LDFLAGS =
@@ -227,7 +227,7 @@
 	$(MAKE) $(AM_MAKEFLAGS) all-am
 
 .SUFFIXES:
-.SUFFIXES: .c .lo .o .obj
+.SUFFIXES: .c .lo .$(OBJEXT) .obj
 $(srcdir)/Makefile.in: @MAINTAINER_MODE_TRUE@ Makefile.am  $(top_srcdir)/configure.ac $(ACLOCAL_M4)
 	cd $(top_srcdir) && \
 	  $(AUTOMAKE) --gnu  tools/Makefile
@@ -301,7 +301,7 @@
 distclean-depend:
 	-rm -rf ./$(DEPDIR)
 
-.c.o:
+.c.$(OBJEXT):
 @am__fastdepCC_TRUE@	if $(COMPILE) -MT $@ -MD -MP -MF "$(DEPDIR)/$*.Tpo" \
 @am__fastdepCC_TRUE@	  -c -o $@ `test -f '$<' || echo '$(srcdir)/'`$<; \
 @am__fastdepCC_TRUE@	then mv "$(DEPDIR)/$*.Tpo" "$(DEPDIR)/$*.Po"; \
