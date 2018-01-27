Index: configure.ac
===================================================================
--- configure.ac	(revision 145152)
+++ configure.ac	(working copy)
@@ -762,7 +762,6 @@
   # LIBS just before AC_OUTPUT.
 
   LATE_LIBS="$FFTW3_LIBS $LATE_LIBS"
-  INT_LDFLAGS="-L$curdir/vendor/fftw/lib $INT_LDFLAGS"
   CPPFLAGS="-I$includedir/fftw3 $CPPFLAGS"
   LDFLAGS="-L$libdir/fftw3 $LDFLAGS"
 fi
Index: benchmarks/GNUmakefile.inc.in
===================================================================
--- benchmarks/GNUmakefile.inc.in	(revision 145152)
+++ benchmarks/GNUmakefile.inc.in	(working copy)
@@ -81,8 +81,8 @@
 clean::
 	rm -f $(benchmarks_cxx_exes)
 
-$(benchmarks_cxx_exes_def_build): %$(EXEEXT) : %.$(OBJEXT) benchmarks/main.$(OBJEXT) lib/libvsip.a
-	$(CXX) $(LDFLAGS) -o $@ $^ $(LIBS) || rm -f $@
+$(benchmarks_cxx_exes_def_build): %$(EXEEXT) : %.$(OBJEXT) benchmarks/main.$(OBJEXT) $(libs)
+	$(CXX) $(LDFLAGS) -o $@ $^ -Llib -lvsip $(LIBS) || rm -f $@
 
-$(benchmarks_cxx_statics_def_build): %.static$(EXEEXT) : %.$(OBJEXT) benchmarks/main.$(OBJEXT) lib/libvsip.a
-	$(CXX) -static $(LDFLAGS) -o $@ $^ $(LIBS) || rm -f $@
+$(benchmarks_cxx_statics_def_build): %.static$(EXEEXT) : %.$(OBJEXT) benchmarks/main.$(OBJEXT) $(libs)
+	$(CXX) -static $(LDFLAGS) -o $@ $^ -Llib -lvsip $(LIBS) || rm -f $@
 
