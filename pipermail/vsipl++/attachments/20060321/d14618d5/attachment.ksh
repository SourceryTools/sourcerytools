Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.412
diff -u -r1.412 ChangeLog
--- ChangeLog	21 Mar 2006 15:51:43 -0000	1.412
+++ ChangeLog	21 Mar 2006 18:16:03 -0000
@@ -1,3 +1,19 @@
+2006-03-21  Jules Bergmann  <jules@codesourcery.com>
+
+	* VERSIONS (V_060306, V_060307): Document tags used for preview
+	  release to LM.
+	* configure.ac (--with-mpi-prefix, --with-mpi-prefix64): Don't
+	  clobber value of --enable-mpi.
+	* doc/quickstart/quickstart.xml: Fix typo in recommended Mercury/
+	  Greenhills flags.
+	* examples/example1.cpp: Add missing include for vsip/math.hpp
+	* examples/mercury/mcoe-setup.sh: Use "=" instead of "==" for
+	  test.  "=" is more portable.
+	* src/vsip/support.hpp: Remove unnecessary Vector forward decl.
+	* src/vsip/impl/distributed-block.hpp: Fix typo in header guard.
+	* src/vsip/impl/lvalue-proxy.hpp (operator=): Pass complex value
+	  as const reference.
+
 2006-03-20  Don McCoy  <don@codesourcery.com>
 
 	* configure.ac: added #define for VSIP_IMPL_SOURCERY_VPP.
Index: VERSIONS
===================================================================
RCS file: /home/cvs/Repository/vpp/VERSIONS,v
retrieving revision 1.4
diff -u -r1.4 VERSIONS
--- VERSIONS	27 Jan 2006 13:13:09 -0000	1.4
+++ VERSIONS	21 Mar 2006 18:16:03 -0000
@@ -13,3 +13,8 @@
 V_1_0b	1.0 rc3. (Jan 22, 2005) This was released to the public as
 	version 1.0.
 
+V_060306
+	Preview release made on 6 Mar 2006 with initial Mercury support.
+
+V_060307
+	Preview release made on 7 Mar 2006 with initial Mercury support.
Index: configure.ac
===================================================================
RCS file: /home/cvs/Repository/vpp/configure.ac,v
retrieving revision 1.88
diff -u -r1.88 configure.ac
--- configure.ac	21 Mar 2006 15:52:23 -0000	1.88
+++ configure.ac	21 Mar 2006 18:16:03 -0000
@@ -80,15 +80,12 @@
 AC_ARG_WITH(mpi_prefix,
   AS_HELP_STRING([--with-mpi-prefix=PATH],
                  [Specify the installation prefix of the MPI library.  Headers
-                  must be in PATH/include; libraries in PATH/lib.]),
-  dnl If the user specified --with-mpi-prefix, they mean to use MPI for sure.
-  [enable_mpi=yes])
+                  must be in PATH/include; libraries in PATH/lib.]),)
+
 AC_ARG_WITH(mpi_prefix64,
   AS_HELP_STRING([--with-mpi-prefix64=PATH],
                  [Specify the installation prefix of the MPI library.  Headers
-                  must be in PATH/include64; libraries in PATH/lib64.]),
-  dnl If the user specified --with-mpi-prefix64, they mean to use MPI for sure.
-  [enable_mpi=yes])
+                  must be in PATH/include64; libraries in PATH/lib64.]),)
 
 ### Mercury Scientific Algorithm (SAL)
 AC_ARG_ENABLE([sal],
@@ -791,6 +788,19 @@
 # Find the parallel service library, if enabled.
 # At present, only MPI is supported.
 #
+
+# If the user specified an MPI prefix, they definitely want MPI.
+# However, we need to avoid overwriting the value of $enable_mpi
+# if the user set it (i.e. '--enable-mpi=mpipro').
+
+if test -n "$with_mpi_prefix" -o -n "$with_mpi_prefix64"; then
+  if test "$enable_mpi" == "no"; then
+    AC_MSG_RESULT([MPI disabled, but MPI prefix given.])
+  elif test "$enable_mpi" == "probe"; then
+    enable_mpi="yes"
+  fi
+fi
+
 if test "$enable_mpi" != "no"; then
   vsipl_par_service=1
 
Index: doc/quickstart/quickstart.xml
===================================================================
RCS file: /home/cvs/Repository/vpp/doc/quickstart/quickstart.xml,v
retrieving revision 1.26
diff -u -r1.26 quickstart.xml
--- doc/quickstart/quickstart.xml	7 Mar 2006 02:15:22 -0000	1.26
+++ doc/quickstart/quickstart.xml	21 Mar 2006 18:16:03 -0000
@@ -1026,7 +1026,7 @@
       </listitem>
 
       <listitem>
-       <para><option>CXXFLAGS="--no_explicit_include -Ospeed -Onotailrecursion-t <replaceable>architecture</replaceable> --no_exceptions -DNDEBUG --diag_suppress 177,550</option></para>
+       <para><option>CXXFLAGS="--no_explicit_include -Ospeed -Onotailrecursion -t <replaceable>architecture</replaceable> --no_exceptions -DNDEBUG --diag_suppress 177,550</option></para>
        <para>
         These are the recommended flags for compiling Sourcery VSIPL++
         with the GreenHills C++ compiler on the Mercury platform.
Index: examples/example1.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/examples/example1.cpp,v
retrieving revision 1.1
diff -u -r1.1 example1.cpp
--- examples/example1.cpp	25 May 2005 16:46:11 -0000	1.1
+++ examples/example1.cpp	21 Mar 2006 18:16:03 -0000
@@ -14,6 +14,7 @@
 #include <iostream>
 #include <vsip/initfin.hpp>
 #include <vsip/vector.hpp>
+#include <vsip/math.hpp>
 
 /***********************************************************************
   Type Definitions
Index: examples/mercury/mcoe-setup.sh
===================================================================
RCS file: /home/cvs/Repository/vpp/examples/mercury/mcoe-setup.sh,v
retrieving revision 1.1
diff -u -r1.1 mcoe-setup.sh
--- examples/mercury/mcoe-setup.sh	7 Mar 2006 02:15:22 -0000	1.1
+++ examples/mercury/mcoe-setup.sh	21 Mar 2006 18:16:03 -0000
@@ -31,14 +31,14 @@
 
 #########################################################################
 
-if test $comm == "par"; then
+if test $comm = "par"; then
   par_opt="--enable-mpi=mpipro"
 else
   par_opt="--disable-mpi"
 fi
 
 base="$pflags --no_exceptions --no_implicit_include"
-if test $opt == "y"; then
+if test $opt = "y"; then
   cxxflags="$base     -Ospeed -Onotailrecursion --max_inlining"
   cxxflags="$cxxflags -DNDEBUG --diag_suppress 177,550"
 else
Index: src/vsip/support.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/support.hpp,v
retrieving revision 1.27
diff -u -r1.27 support.hpp
--- src/vsip/support.hpp	3 Mar 2006 14:30:53 -0000	1.27
+++ src/vsip/support.hpp	21 Mar 2006 18:16:03 -0000
@@ -294,7 +294,6 @@
 
 
 // Support functions [support.functions].
-template <typename T, typename Block> class Vector;
 
 /// Return the total number of processors executing the program.
 length_type num_processors() VSIP_NOTHROW;
Index: src/vsip/vector.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/vector.hpp,v
retrieving revision 1.37
diff -u -r1.37 vector.hpp
--- src/vsip/vector.hpp	3 Mar 2006 14:30:53 -0000	1.37
+++ src/vsip/vector.hpp	21 Mar 2006 18:16:03 -0000
@@ -30,7 +30,7 @@
 #include <vsip/impl/par-chain-assign.hpp>
 #include <vsip/impl/dispatch-assign.hpp>
 #include <vsip/impl/lvalue-proxy.hpp>
-#include <vsip/math.hpp>
+// #include <vsip/math.hpp>
 
 /***********************************************************************
   Declarations
Index: src/vsip/impl/distributed-block.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/distributed-block.hpp,v
retrieving revision 1.18
diff -u -r1.18 distributed-block.hpp
--- src/vsip/impl/distributed-block.hpp	3 Mar 2006 14:30:53 -0000	1.18
+++ src/vsip/impl/distributed-block.hpp	21 Mar 2006 18:16:03 -0000
@@ -7,8 +7,8 @@
 
 */
 
-#ifndef VSIP_IMPL_DISTRIBUTED_MAP_HPP
-#define VSIP_IMPL_DISTRIBUTED_MAP_HPP
+#ifndef VSIP_IMPL_DISTRIBUTED_BLOCK_HPP
+#define VSIP_IMPL_DISTRIBUTED_BLOCK_HPP
 
 /***********************************************************************
   Included Files
@@ -543,4 +543,4 @@
 } // namespace vsip
 
 
-#endif // VSIP_IMPL_DISTRIBUTED_MAP_HPP
+#endif // VSIP_IMPL_DISTRIBUTED_BLOCK_HPP
Index: src/vsip/impl/lvalue-proxy.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/lvalue-proxy.hpp,v
retrieving revision 1.7
diff -u -r1.7 lvalue-proxy.hpp
--- src/vsip/impl/lvalue-proxy.hpp	3 Mar 2006 14:30:53 -0000	1.7
+++ src/vsip/impl/lvalue-proxy.hpp	21 Mar 2006 18:16:03 -0000
@@ -181,7 +181,7 @@
   /// is not necessary.
 
   /// Write access, by assignment from the value type.
-  Lvalue_proxy& operator= (value_type v)
+  Lvalue_proxy& operator= (value_type const& v)
   {
     this->base_type::operator=(v);
     lvalue_detail::put(block_, coord_, v);
