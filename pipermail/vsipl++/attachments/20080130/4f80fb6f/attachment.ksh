Index: ChangeLog
===================================================================
--- ChangeLog	(revision 192266)
+++ ChangeLog	(working copy)
@@ -1,3 +1,19 @@
+2008-01-30  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/core/check_config_body.hpp: New file, body of
+	  {app,library}_config function.
+	* src/vsip/core/check_config.cpp: Use check_config_body.hpp.
+	* src/vsip/core/check_config.hpp (app_config): New function to
+	  check configuration at application build time.
+	* tests/check_config.cpp: Test app_config.
+	
+	* scripts/package.py (prefix-not-in-tarball): New option to allow
+	  part of installation prefix to be excluded from the tarball path.
+	* scripts/release.sh: Adjust prefix to /opt/sourceryvsipl++-VERSION.
+	* scripts/config: Adjust configure parameters that have been
+	  renamed.  Adjust host names.  Add Power (powerpc-linux-gnu)
+	  binary package. 
+
 2008-01-29  Stefan Seefeld  <stefan@codesourcery.com>
 
 	* synopsis.py.in: Cleanup.
Index: configure.ac
===================================================================
--- configure.ac	(revision 191870)
+++ configure.ac	(working copy)
@@ -51,18 +51,17 @@
 # can be shared by different variants (parallel vs serial, IPP/MKL vs
 # builtin) in the same binary package.
 AC_ARG_ENABLE(shared-acconfig,
-  AS_HELP_STRING([--disable-shared-acconfig],
-                 [Do not attempt to make acconfig.hpp that can be shared
-	 	  by different configurations.  If you are configuring
-		  Sourcery VSIPL++ for use from eclipse and do not want
-		  to copy over a large number of defines, you should use
-		  this option.]),
+  AS_HELP_STRING([--enable-shared-acconfig],
+                 [Attempt to make acconfig.hpp that can be shared
+	 	  by different configurations.  Use this if you want
+                  to share a common set of header files for multiple
+                  Sourcery VSIPL++ configurations.]),
   [case x"$enableval" in
     xyes) neutral_acconfig="y" ;;
     xno)  neutral_acconfig="n" ;;
-    *)   AC_MSG_ERROR([Invalid argument to --disable-shared-acconfig.])
+    *)   AC_MSG_ERROR([Invalid argument to --enable-shared-acconfig.])
    esac],
-  [neutral_acconfig="y"])
+  [neutral_acconfig="n"])
  
 AC_ARG_WITH(suffix,
   AS_HELP_STRING([--with-suffix=SUFFIX],
Index: doc/quickstart/quickstart.xml
===================================================================
--- doc/quickstart/quickstart.xml	(revision 192236)
+++ doc/quickstart/quickstart.xml	(working copy)
@@ -1327,19 +1327,15 @@
      </varlistentry>
 
      <varlistentry>
-      <term><option>--disable-shared-acconfig</option></term>
+      <term><option>--enable-shared-acconfig</option></term>
       <listitem>
        <para>
-        Do not generate a acconfig.hpp that can be shared by
-	different configurations.  Instead generate an acconfig.hpp
-	file that can only be used by this configuration.
+        Generate an acconfig.hpp that can be shared by different
+        configurations by putting macros on the compiler command line.
+	This is useful when building binary packages.
 
-	By default, a sharable acconfig.hpp is generated.  However,
-	this requires putting macros on the compiler command line,
-	which can be unwieldy unless automated by use of pkg-config.
-
-	This option is useful when building for a platform that
-	does not have or support pkg-config, such as Eclipse.
+	Normally an acconfig.hpp file is generated that can only be
+	used by one configuration.
        </para>
       </listitem>
      </varlistentry>
