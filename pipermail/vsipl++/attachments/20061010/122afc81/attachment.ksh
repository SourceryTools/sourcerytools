Index: ChangeLog
===================================================================
--- ChangeLog	(revision 151172)
+++ ChangeLog	(working copy)
@@ -1,5 +1,9 @@
 2006-10-10  Jules Bergmann  <jules@codesourcery.com>
 
+	* examples/mercury/mcoe-setup.sh: Fix to work with solaris /bin/sh.
+
+2006-10-10  Jules Bergmann  <jules@codesourcery.com>
+
 	* src/vsip/impl/replicated_map.hpp (impl_local_from_global_domain):
 	  New function to translate local to global domain for map.
 	* src/vsip/impl/global_map.hpp (impl_local_from_global_domain):
Index: examples/mercury/mcoe-setup.sh
===================================================================
--- examples/mercury/mcoe-setup.sh	(revision 150732)
+++ examples/mercury/mcoe-setup.sh	(working copy)
@@ -143,14 +143,27 @@
 fi
 
 
-export CC=ccmc
-export CXX=ccmc++
-export CXXFLAGS=$cxxflags
-export AR=armc
-export AR_FLAGS=cr		# armc doesn't support 'u'pdate
-export LDFLAGS="$pflags"
+#########################################################################
+# export environment variables
 
+CC=ccmc
+CXX=ccmc++
+CXXFLAGS=$cxxflags
+AR=armc
+AR_FLAGS=cr		# armc doesn't support 'u'pdate
+LDFLAGS="$pflags"
 
+export CC
+export CXX
+export CXXFLAGS
+export AR
+export AR_FLAGS
+export LDFLAGS
+
+
+#########################################################################
+# run configure
+
 echo "$dir/configure"
 $dir/configure					\
 	--prefix=$prefix			\
