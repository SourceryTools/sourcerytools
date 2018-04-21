Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.421
diff -u -r1.421 ChangeLog
--- ChangeLog	27 Mar 2006 23:19:34 -0000	1.421
+++ ChangeLog	28 Mar 2006 14:44:09 -0000
@@ -1,3 +1,13 @@
+2006-03-28  Jules Bergmann  <jules@codesourcery.com>
+
+	* configure.ac (CLAPACK_NOOPT): New substitution, non-optimized
+	  version of CFLAGS.  Used to pass -m32/-m64 flags.
+	* vendor/clapack/SRC/make.inc.in: Use CLAPACK_NOOPT for non-optimized
+	  files.
+	* tests/parallel/replicated_data.cpp: Remove debug code.
+	* scripts/release.sh: Fix getopts handling of -s option (was
+	  expecting OPTARG).
+
 2006-03-24  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip/dense.hpp: Rename implementation par support functions
Index: configure.ac
===================================================================
RCS file: /home/cvs/Repository/vpp/configure.ac,v
retrieving revision 1.90
diff -u -r1.90 configure.ac
--- configure.ac	22 Mar 2006 21:50:41 -0000	1.90
+++ configure.ac	28 Mar 2006 14:44:09 -0000
@@ -1464,6 +1464,17 @@
 	fi
 	AC_SUBST(LAPACK_NOOPT)
 
+	# Determine flags for CLAPACK_NOOPT, used for compiling with no
+	# optimization
+        if expr "$CFLAGS" : ".*-m32" > /dev/null; then
+	  CLAPACK_NOOPT="-m32"
+        elif expr "$CFLAGS" : ".*-m64" > /dev/null; then
+	  CLAPACK_NOOPT="-m64"
+	else
+	  CLAPACK_NOOPT=""
+	fi
+	AC_SUBST(CLAPACK_NOOPT)
+
         lapack_found="builtin"
         break
       else
Index: scripts/release.sh
===================================================================
RCS file: /home/cvs/Repository/vpp/scripts/release.sh,v
retrieving revision 1.6
diff -u -r1.6 release.sh
--- scripts/release.sh	7 Mar 2006 02:15:22 -0000	1.6
+++ scripts/release.sh	28 Mar 2006 14:44:09 -0000
@@ -48,7 +48,7 @@
 pkg_opts=""
 version="1.0"
 
-while getopts "w:d:c:p:C:t:D:T:s:" arg; do
+while getopts "w:d:c:p:C:t:D:T:s" arg; do
     case $arg in
 	w)
 	    what=$OPTARG
Index: tests/parallel/replicated_data.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/parallel/replicated_data.cpp,v
retrieving revision 1.1
diff -u -r1.1 replicated_data.cpp
--- tests/parallel/replicated_data.cpp	27 Mar 2006 23:19:35 -0000	1.1
+++ tests/parallel/replicated_data.cpp	28 Mar 2006 14:44:09 -0000
@@ -23,7 +23,6 @@
 
 #include "test.hpp"
 #include "output.hpp"
-#include "debug.hpp"
 
 using namespace std;
 using namespace vsip;
@@ -34,16 +33,6 @@
   Definitions
 ***********************************************************************/
 
-void msg(char* text)
-{
-  impl::default_communicator().barrier();
-  if (local_processor() == 0)
-    std::cout << text << std::endl;
-  impl::default_communicator().barrier();
-}
-
-
-
 // Test comm using replicated view as source (to non-replicated view)
 
 template <typename T>
Index: vendor/clapack/SRC/make.inc.in
===================================================================
RCS file: /home/cvs/Repository/clapack/SRC/make.inc.in,v
retrieving revision 1.2
diff -u -r1.2 make.inc.in
--- vendor/clapack/SRC/make.inc.in	22 Mar 2006 21:50:55 -0000	1.2
+++ vendor/clapack/SRC/make.inc.in	28 Mar 2006 14:44:10 -0000
@@ -28,7 +28,7 @@
 CFLAGS    = @CLAPACK_CFLAGS@
 LOADER    = $(CC)
 LOADOPTS  = $(CFLAGS)
-NOOPT     = 
+NOOPT     = @CLAPACK_NOOPT@
 DRVCFLAGS = $(CFLAGS)
 F2CCFLAGS = $(CFLAGS)
 #
