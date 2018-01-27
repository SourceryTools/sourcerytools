Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.486
diff -u -r1.486 ChangeLog
--- ChangeLog	15 May 2006 23:03:50 -0000	1.486
+++ ChangeLog	25 May 2006 14:53:37 -0000
@@ -1,3 +1,13 @@
+2006-05-25  Jules Bergmann  <jules@codesourcery.com>
+
+	* VERSIONS (V_1_1): Document tag for 1.1 release.
+	* configure.ac (--disable-fft): Treat as a synonym for '--enable-fft='.
+	* doc/quickstart/quickstart.xml: Fix typos in Mercury configuration
+	  notes.
+	* scripts/package.py: Disable configuration of lapack when building
+	  documentation.
+	* scripts/release.sh: Bump version to 1.1.
+
 2006-05-15  Jules Bergmann  <jules@codesourcery.com>
 	
 	* src/vsip/impl/fft.hpp: Add include for vsip/impl/profile.
Index: VERSIONS
===================================================================
RCS file: /home/cvs/Repository/vpp/VERSIONS,v
retrieving revision 1.6
diff -u -r1.6 VERSIONS
--- VERSIONS	27 Apr 2006 01:21:21 -0000	1.6
+++ VERSIONS	25 May 2006 14:53:37 -0000
@@ -26,3 +26,5 @@
 
 V_20060426
 	Preview release made on 26 Apr 2006.  Initial Solaris support.
+
+V_1_1	1.1 release (May 15, 2006)
Index: configure.ac
===================================================================
RCS file: /home/cvs/Repository/vpp/configure.ac,v
retrieving revision 1.105
diff -u -r1.105 configure.ac
--- configure.ac	14 May 2006 20:57:05 -0000	1.105
+++ configure.ac	25 May 2006 14:53:37 -0000
@@ -501,6 +501,11 @@
 fft_backends=`echo "${enable_fft}" | \
                 sed -e 's/[[ 	,]][[ 	,]]*/ /g' -e 's/,$//'`
 
+# '--disable-fft' is a synonym for an empty list of backends ('--enable-fft=')
+if test "$fft_backends" = "no"; then
+  fft_backends=""
+fi
+
 enable_fftw3="no"
 enable_ipp_fft="no"
 enable_sal_fft="no"
Index: doc/quickstart/quickstart.xml
===================================================================
RCS file: /home/cvs/Repository/vpp/doc/quickstart/quickstart.xml,v
retrieving revision 1.32
diff -u -r1.32 quickstart.xml
--- doc/quickstart/quickstart.xml	14 May 2006 07:47:12 -0000	1.32
+++ doc/quickstart/quickstart.xml	25 May 2006 14:53:37 -0000
@@ -1086,14 +1086,14 @@
        <para>
 	This selects the <option>c</option> (create archive if it
 	does not exist) and <option>r</option> (replace files in
-	archive) flags for the <program>armc</program> archiver.
-	<program>armc</program> does not support the <option>u</option>
-	(only replace files if they are an update).
+	archive) flags for the <option>armc</option> archiver.
+	<option>armc</option> does not support the <option>u</option>
+        flag (only replace files if they are an update).
        </para>
       </listitem>
 
       <listitem>
-       <para><option>CXXFLAGS="--no_explicit_include -Ospeed -Onotailrecursion -t <replaceable>architecture</replaceable> --no_exceptions -DNDEBUG --diag_suppress 177,550</option></para>
+       <para><option>CXXFLAGS="--no_implicit_include -Onotailrecursion -t <replaceable>architecture</replaceable> --no_exceptions -Ospeed --max_inlining -DNDEBUG --diag_suppress 177,550</option></para>
        <para>
         These are the recommended flags for compiling Sourcery VSIPL++
         with the GreenHills C++ compiler on the Mercury platform.
Index: scripts/package.py
===================================================================
RCS file: /home/cvs/Repository/vpp/scripts/package.py,v
retrieving revision 1.1
diff -u -r1.1 package.py
--- scripts/package.py	10 May 2006 14:08:53 -0000	1.1
+++ scripts/package.py	25 May 2006 14:53:37 -0000
@@ -204,7 +204,8 @@
     try:
         os.chdir(abs_builddir)
         # Dummy configuration to set up the test database
-        configure('--enable-maintainer-mode', '--enable-fft=')
+        configure('--enable-maintainer-mode', '--enable-fft=',
+                  '--with-lapack=no')
         os.makedirs(abs_distdir)
         os.chdir(abs_distdir)
         spawn(['tar', 'xvfj', abs_packagefile])
Index: scripts/release.sh
===================================================================
RCS file: /home/cvs/Repository/vpp/scripts/release.sh,v
retrieving revision 1.11
diff -u -r1.11 release.sh
--- scripts/release.sh	11 May 2006 14:41:53 -0000	1.11
+++ scripts/release.sh	25 May 2006 14:53:37 -0000
@@ -46,7 +46,7 @@
 debug="yes"
 cvs_tag="HEAD"
 pkg_opts=""
-version="1.0"
+version="1.1"
 host=`hostname`
 
 while getopts "w:d:c:p:P:C:t:D:T:s" arg; do
