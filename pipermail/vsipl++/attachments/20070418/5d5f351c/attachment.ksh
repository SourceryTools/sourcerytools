Index: ChangeLog
===================================================================
--- ChangeLog	(revision 169208)
+++ ChangeLog	(working copy)
@@ -1,3 +1,9 @@
+2007-04-18  Jules Bergmann  <jules@codesourcery.com>
+
+	* vendor/atlas/configure.ac: Handle unknown PowerPC architecture
+	  as G4.  Determine IA64 architecture mach type.  Distinguish
+	  between P4 and P4E mach types.  Improve pentium model check. 
+	
 2007-04-18  Don McCoy  <don@codesourcery.com>
 
 	* src/vsip/opt/expr/eval_fastconv.hpp: Added new evaluators
Index: vendor/atlas/configure.ac
===================================================================
--- vendor/atlas/configure.ac	(revision 167964)
+++ vendor/atlas/configure.ac	(working copy)
@@ -139,6 +139,7 @@
   mach="unknown"
 
   echo "linux arch $la"
+
   if test "$la" = "ppc"; then
     mach_is_ppc="true"
     model=`fgrep -m 1 cpu /proc/cpuinfo`
@@ -157,40 +158,72 @@
       mach="PPCG4"
     elif test "`echo $model | sed -n /PPC970FX/p`" != ""; then
       mach="PPCG5"
+    else
+      # Assume architecture is G4 (PPCG4).
+      # Pick G4 because we have architectural defaults for both
+      # with and without altivec.
+      AC_MSG_RESULT([Model '$model' not recognized for arch $la, assuming PowerPC g$])
+      mach="PPCG4"
     fi
-  fi
 
 	
   # SPARC
   # ALPHA
   # IA64
+  elif test "$la" = "ia64"; then
+    model=`fgrep -m 1 'family' /proc/cpuinfo`
+    if test "`echo $model | sed -n /Itanium 2/Ip`" != ""; then
+      mach="IA64Itan2"
+    else
+      mach="IA64Itan"
+    fi
   # X86
-  if test "$la" = "x86_32"; then
+  elif test "$la" = "x86_32"; then
     model=`fgrep -m 1 'model name' /proc/cpuinfo`
     if test "x$model" = "x"; then
       model=`fgrep -m 1 model /proc/cpuinfo`
     fi
 
-    if test "`echo $model | sed -n /Pentium/p`" != ""; then
-      if test "`echo $model | sed -n /III/p`" = "match"; then
+    if test "`echo $model | sed -n /Pentium/Ip`" != ""; then
+      if test "`echo $model | sed -n /III/Ip`" != ""; then
         mach="PIII"
-      elif test "`echo $model | sed -n '/ II/p'`" != ""; then
+      elif test "`echo $model | sed -n '/ II/Ip'`" != ""; then
         mach="PII"
-      elif test "`echo $model | sed -n '/Pro/p'`" != ""; then
+      elif test "`echo $model | sed -n '/Pro/Ip'`" != ""; then
         mach="PPRO"
-      elif test "`echo $model | sed -n '/MMX/p'`" != ""; then
+      elif test "`echo $model | sed -n '/MMX/Ip'`" != ""; then
         mach="P5MMX"
-      elif test "`echo $model | sed -n '/ 4 /p'`" != ""; then
+      elif test "`echo $model | sed -n '/ 4 /Ip'`" != ""; then
+        model_number=`fgrep -m 1 'model' /proc/cpuinfo | fgrep -v 'name'`
+	echo "MODEL_NUMBER: $model_number"
+        if test "`echo $model_number | sed -n '/3/Ip'`" != ""; then
+          mach="P4E"
+        elif test "`echo $model_number | sed -n '/4/Ip'`" != ""; then
+          mach="P4E"
+        else
+          mach="P4"
+        fi
+      elif test "`echo $model | sed -n '/ M /Ip'`" != ""; then
         mach="P4"
-      elif test "`echo $model | sed -n '/ M /p'`" != ""; then
+      fi
+    elif test "`echo $model | sed -n /Xeon/Ip`" != ""; then
+      model_number=`fgrep -m 1 'model' /proc/cpuinfo | fgrep -v 'name'`
+      echo "MODEL_NUMBER: $model_number"
+      if test "`echo $model_number | sed -n '/3/Ip'`" != ""; then
+        mach="P4E"
+      elif test "`echo $model_number | sed -n '/4/Ip'`" != ""; then
+        mach="P4E"
+      else
         mach="P4"
       fi
-    elif test "`echo $model | sed -n /XEON/p`" != ""; then
-      mach="P4"
-    elif test "`echo $model | sed -n '/Athlon/p'`" != ""; then
+    elif test "`echo $model | sed -n '/Athlon/Ip'`" != ""; then
       mach="ATHLON"
-    elif test "`echo $model | sed -n '/Opteron/p'`" != ""; then
+    elif test "`echo $model | sed -n '/Opteron/Ip'`" != ""; then
       mach="HAMMER32"
+    else
+      # Assume architecture is a Pentium (P5MMX)
+      AC_MSG_RESULT([Model '$model' not recognized for arch $la, assuming Pentium])
+      mach="P5MMX"
     fi
   elif test "$la" = "x86_64"; then
     model=`fgrep -m 1 'model name' /proc/cpuinfo`
@@ -281,7 +314,8 @@
 elif test "$mach_is_ppc" = "true"; then
   asmd="GAS_LINUX_PPC"
 else
-  AC_MSG_ERROR([cannot determine asm type.])
+  AC_MSG_RESULT([cannot determine asm type.])
+  asmd="none"
 fi
 
 AC_MSG_RESULT($asmd)
@@ -971,7 +1005,7 @@
       fi
       ;;
     PPCG4)
-      AC_MSG_ERROR([Linux/PPCG4 L2 cache size not implemented])
+      # AC_MSG_ERROR([Linux/PPCG4 L2 cache size not implemented])
       ;;
   esac
 elif test $os_name = "IRIX"; then
@@ -1376,6 +1410,11 @@
   ARCHDEFS="$ARCHDEFS -DATL_$asmd"
 fi
 
+case $mach in
+  IA64Itan | IA64Itan2 )
+    ARCHDEFS="$ARCHDEFS -DATL_MAXNREG=128"
+    ;;
+esac
 
 AC_SUBST(ARCHDEFS)
 
