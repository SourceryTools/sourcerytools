Index: ChangeLog
===================================================================
RCS file: /home/qm/Repository/qm/ChangeLog,v
retrieving revision 1.536
diff -u -r1.536 ChangeLog
--- ChangeLog	20 Aug 2003 19:43:28 -0000	1.536
+++ ChangeLog	25 Aug 2003 20:05:31 -0000
@@ -1,3 +1,10 @@
+2003-08-25  Stefan Seefeld  <seefeld@sympatico.ca>
+
+	* setup.py: New file.
+	* qm/__init__.py: import qm.config for data path and version info
+	* qm/test/base.py: add config.data_dir + '/test/classes' to search path
+	* qm/test/qmtest.py: insert magic number so this becomes a real script
+
 2003-08-20  Mark Mitchell  <mark@codesourcery.com>
 
 	* qm/test/cmdline.py (QMTest.__ExecuteCreate): Return 2 for
Index: qm/__init__.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/__init__.py,v
retrieving revision 1.6
diff -u -r1.6 __init__.py
--- qm/__init__.py	10 Aug 2003 21:31:58 -0000	1.6
+++ qm/__init__.py	25 Aug 2003 20:05:31 -0000
@@ -17,7 +17,27 @@
 # imports
 ########################################################################
 
-from qm.__version import version, version_info
+import string
+
+try:
+    # this file was generated during the build
+    from qm.config import config, version
+    version_info = tuple(string.split(version, '.'))
+    """The version of QM as a tuple of (major, minor, release)."""
+except:
+    # for now insert dummy values here so qmtest can still be
+    # built and installed the old way. To be removed eventually...
+    import os.path
+    class config:
+        data_dir=os.path.dirname(os.path.dirname(__file__))
+
+    #print 'insert a meaningful error message here explaining'
+    #print 'the user not to run qmtest from the source tree'
+    #import sys
+    #sys.exit(-1)
+
+    from qm.__version import version, version_info
+
 from qm.common import *
 from qm.diagnostic import error, warning, message
 
Index: qm/test/base.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/base.py,v
retrieving revision 1.89
diff -u -r1.89 base.py
--- qm/test/base.py	1 Aug 2003 19:47:43 -0000	1.89
+++ qm/test/base.py	25 Aug 2003 20:05:32 -0000
@@ -132,7 +132,10 @@
                     (database_path))
         
     # Search the builtin directory, too.
+    # the old way...
     dirs.append(os.path.join(os.path.dirname(__file__), "classes"))
+    # ...and the new one
+    dirs.append(os.path.join(qm.config.data_dir, 'test', 'classes'))
 
     return dirs
 
Index: qm/test/qmtest.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/qmtest.py,v
retrieving revision 1.23
diff -u -r1.23 qmtest.py
--- qm/test/qmtest.py	20 Aug 2003 19:43:28 -0000	1.23
+++ qm/test/qmtest.py	25 Aug 2003 20:05:32 -0000
@@ -1,3 +1,5 @@
+#! /usr/bin/env python
+
 ########################################################################
 #
 # File:   qmtest.py
