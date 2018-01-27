? benchmarks/hpec-corner-turn.cpp
Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.449
diff -u -r1.449 ChangeLog
--- ChangeLog	1 May 2006 19:36:25 -0000	1.449
+++ ChangeLog	2 May 2006 15:14:54 -0000
@@ -1,3 +1,9 @@
+2006-05-02  Jules Bergmann  <jules@codesourcery.com>
+
+	* benchmarks/GNUmakefile.inc.in: Update libvsip location.
+	* benchmarks/dot.cpp: Fix Wall warning.
+	* benchmarks/mcopy_ipp.cpp: Likewise.
+
 2006-05-01  Stefan Seefeld  <stefan@codesourcery.com>
 
 	* configure.ac: Add support for multiple FFT backends.
Index: benchmarks/GNUmakefile.inc.in
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/GNUmakefile.inc.in,v
retrieving revision 1.4
diff -u -r1.4 GNUmakefile.inc.in
--- benchmarks/GNUmakefile.inc.in	20 Jan 2006 21:49:58 -0000	1.4
+++ benchmarks/GNUmakefile.inc.in	2 May 2006 15:14:54 -0000
@@ -66,8 +66,8 @@
 clean::
 	rm -f $(benchmarks_cxx_exes)
 
-$(benchmarks_cxx_exes_def_build): %$(EXEEXT) : %.$(OBJEXT) benchmarks/main.$(OBJEXT) src/vsip/libvsip.a
+$(benchmarks_cxx_exes_def_build): %$(EXEEXT) : %.$(OBJEXT) benchmarks/main.$(OBJEXT) lib/libvsip.a
 	$(CXX) $(LDFLAGS) -o $@ $^ $(LIBS) || rm -f $@
 
-$(benchmarks_cxx_statics_def_build): %.static$(EXEEXT) : %.$(OBJEXT) benchmarks/main.$(OBJEXT) src/vsip/libvsip.a
+$(benchmarks_cxx_statics_def_build): %.static$(EXEEXT) : %.$(OBJEXT) benchmarks/main.$(OBJEXT) lib/libvsip.a
 	$(CXX) -static $(LDFLAGS) -o $@ $^ $(LIBS) || rm -f $@
Index: benchmarks/dot.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/dot.cpp,v
retrieving revision 1.3
diff -u -r1.3 dot.cpp
--- benchmarks/dot.cpp	7 Mar 2006 20:09:35 -0000	1.3
+++ benchmarks/dot.cpp	2 May 2006 15:14:54 -0000
@@ -55,7 +55,7 @@
   {
     Vector<T>   A (size, T());
     Vector<T>   B (size, T());
-    T r;
+    T r = T();
 
     A(0) = T(3);
     B(0) = T(4);
Index: benchmarks/mcopy_ipp.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/mcopy_ipp.cpp,v
retrieving revision 1.2
diff -u -r1.2 mcopy_ipp.cpp
--- benchmarks/mcopy_ipp.cpp	7 Mar 2006 20:09:35 -0000	1.2
+++ benchmarks/mcopy_ipp.cpp	2 May 2006 15:14:54 -0000
@@ -460,8 +460,6 @@
 int
 test(Loop1P& loop, int what)
 {
-  processor_type np = num_processors();
-
   typedef row2_type rt;
   typedef col2_type ct;
 
