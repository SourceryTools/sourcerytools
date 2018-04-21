Index: INSTALL.unix
===================================================================
RCS file: /home/pooma/Repository/r2/INSTALL.unix,v
retrieving revision 1.28
retrieving revision 1.29
diff -u -u -r1.28 -r1.29
--- INSTALL.unix	12 Jan 2003 16:16:15 -0000	1.28
+++ INSTALL.unix	19 Aug 2004 20:23:45 -0000	1.29
@@ -1,7 +1,7 @@
 /*******************************************************************
  *                                                                 *
  *       POOMA build and installation instructions for UNIX        *
- *                          Version 2.4.0                          *
+ *                          Version 2.4.1                          *
  *                                                                 *
  *******************************************************************
  *    For release notes, see README.                               *
@@ -26,42 +26,25 @@
                 SUPPORTED PLATFORMS AND COMPILERS:
                 ----------------------------------
 
-POOMA version 2.4.0 has been ported to the following platforms and
+POOMA version 2.4.1 has been ported to the following platforms and
 compilers; please find the instructions for your platform within this
 document and follow the steps.
 
-	o SGI IRIX 6.X, with the Kuck and Associates KCC compiler
-	  (v3.3d or later, including 3.4x)
-	o SGI IRIX 6.X, with the GCC compiler
-	  (v2.95 or greater)
-	o SGI IRIX 6.X, with SGI C++ 7.3 or later compiler
-	  (without patch 3659!)
-	o Linux, with the Kuck and Associates KCC compiler
-	  (v3.3d or later, including 3.4x)
 	o Linux, with the GCC compiler
-	  (v2.95 or greater)
+	  (v3.3 or greater)
 	o Linux, with the Intel icpc compiler
-	  (v6.0 or greater)
+	  (v7.2 or greater)
 
 More information about the compilers above can be obtained from
 the following URLs:
 
         o GCC Home Page (GCC):            http://gcc.gnu.org
-        o Silicon Graphics (SGI C++):     http://www.sgi.com
 	o Intel (icpc):                   http://www.intel.com
-	o The Kuck and Associates (KCC) is no longer available.
 
 On Unix machines, POOMA can be compiled with one or more optional
 packages. The currently available optional packages are:
 
-	o SMARTS, for multithreaded parallelism and dataflow analysis
-
-	o PDT, for static analysis of source code 
-
-	o TAU, for automatic source code profiling
-
-	o PAWS, for run-time coupling of parallel data structures with
-          other parallel programs.
+	o Cheetah, for message passing or shared memory parallelism
 
 When compiling with other packages, be sure to check the section on known
 problems section at the end of this document.  Some combinations of packages
@@ -76,7 +59,7 @@
 Since you're reading this file, you've successfully expanded the .tgz
 file you downloaded from the net.
 
-You should notice the following files/folders inside of pooma-2.4.0:
+You should notice the following files/folders inside of pooma-2.4.1:
 
    configure ..................... used for Unix builds
    CREDITS ....................... the people who developed POOMA and this CD
@@ -120,12 +103,12 @@
 directories.  To build POOMA for a given "suite" you set the environment
 variable POOMASUITE to the name of that suite and then execute make at
 the top level.  Basic configurations for various systems and compilers
-are found in the config/arch directory (for example LINUXKCC.conf contains
-definitions for building with the KAI compiler on Linux systems).  You
+are found in the config/arch directory (for example LINUXgcc.conf contains
+definitions for building with the GCC compiler on Linux systems).  You
 should start by finding one of the .conf files that most closely matches
 your system and possibly editing the definitions in it where they are
-incorrect.  (You may also copy a .conf file and use the new name as an
-option to configure.)
+incorrect.  You may also copy a .conf file and use the new name as an
+option to configure.
 
 In general, the configure command will look like:
 
@@ -144,64 +127,5 @@
 
 In addition, configure may look at several environment variables,
 SMARTSDIR, CHEETAHDIR, TAUDIR, PDTDIR etc. to find the locations of other
-installed packages.
-
-To see some examples of building POOMA for different systems look at
-some of the following files.  These files are scripts that assume you have
-downloaded the tar'd distributions of all the necessary packages to one
-location and want to build them in place:
-
-scripts/buildPoomaLinuxEgcs     - build pooma and an example on Linux
-scripts/buildPoomaSGI           - build pooma and an example on IRIX
-scripts/buildPoomaCheetaLinux   - build pooma with Cheetah
-scripts/buildPoomaCheetaTauSGI  - build pooma with Cheetah and Tau
-
-The SMARTS distribution also comes with some scripts that demonstrate
-building pooma with smarts.
-
-
-* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
-
-               NOTES ON KNOWN PROBLEMS:
-               ------------------------
-
-Linux with RedHat 6 (and possibly other distributions):
--------------------------------------------------------
-We have observed an odd problem with gmake on RedHat 6 installations,
-where a target will be built successfully, but then gmake will attempt 
-to build one more incorrectly specified target.  The latter should not 
-happen, but does.  It will just print a strange error message and
-exit, but will not affect the target that was actually built
-properly.  If you see such behavior, add the '-r' flag to your 'gmake'
-commands, to turn off implicit build rules in GNU make.  This should
-prevent these errors from happening.
-
-KCC 3.4d compiler:
-------------------
-We have run across some compiler bugs triggered by our developer test
-codes.  These bugs have been reported but are not yet resolved.
-
-GCC compiler:
---------------
-Some codes may cause the GCC v2.95 compiler to exhaust virtual memory while
-compiling, leading to an error message from g++ such as "Cannot allocate
-XXX bytes", where XXX is some number.  This is especially common when
-compiling with optimization turned on.  Two possible solutions are to
-turn down the level of optimization (by modifying the optimization settings
-in the appropriate .conf file) or to break the code up into smaller 
-source code files.
-
-Using more recent versions of GCC (3.2 and up) is recommended and will fix
-this particular and many other problems. Note that GCC v3.0 and v3.1 generate
-wrong code under certain circumstances when using optimization. Use of them
-is not recommended.
-
-
-Using SMARTS:
--------------
-
-SMARTS places particular requirements on the thread-safety of the compilers
-used.  See the SMARTS documentation for details, but in some situations this
-may restrict your choice of build options.  (For example, with KCC 3.4g, the
-thread-safe version requires that exceptions be turned on.)
-
+installed packages.  Refer to the configure script for further information
+in case of problems.
Index: README
===================================================================
RCS file: /home/pooma/Repository/r2/README,v
retrieving revision 1.63
retrieving revision 1.64
diff -u -u -r1.63 -r1.64
--- README	11 Jul 2002 21:28:52 -0000	1.63
+++ README	19 Aug 2004 20:23:45 -0000	1.64
@@ -1,3 +1,44 @@
+
+POOMA is a C++ library supporting element-wise, data-parallel, and stencil-based
+physics computations using one or more processors.  The library automatically
+handles all interprocessor communication, obviating the need for any explicit
+communication code and enabling the same program to be run on one or thousands
+of processors.  The library supports high-level syntax close to mathematical or
+algorithmic syntax, easing the conversion from algorithms to code.  POOMA,
+originally developed at Los Alamos National Laboratory to support nuclear
+simulations, is now used throughout the physics establishment around the world.
+
+
+////////////////////////////////////////////////////////////////////
+
+RELEASE NOTES v2.4.1
+
+////////////////////////////////////////////////////////////////////
+
+Version 2.4.1 cleans up the codebase to be ISO C++ conformant.  As
+such an ISO C++ conforming compiler and standard library is recommended,
+but still compilers close to that may be supported (gcc 3.3 and Intel 7.2
+are).
+
+Most visible enhancements in this release are the addition of native
+MPI support for message passing parallelism and OpenMP support for
+thread parallelism.  MPI support was tested with the MPICH and LAM MPI
+implementations, OpenMP support was tested with the Intel compiler
+on ia32 and ia64 architectures.  Message passing parallelism through
+using the Cheetah library is still supported.
+
+Numerous restrictions on the use of Arrays, Fields and expressions in
+certain constructs were lifted.  Also may bugs were fixed and performance
+was improved.
+
+The status of POOMA particles, especially parallel particles, is
+undetermined.  So is the status of thread parallelism based on the
+SMARTS library.
+
+Support libraries for POOMA such as Cheetah, SMARTS and PETE can be
+obtained from http://www.pooma.com/.
+
+
 ////////////////////////////////////////////////////////////////////
 
 RELEASE NOTES v2.4.0
