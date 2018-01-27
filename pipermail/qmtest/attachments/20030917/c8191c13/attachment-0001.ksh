Index: ChangeLog
===================================================================
RCS file: /home/qm/Repository/qm/ChangeLog,v
retrieving revision 1.550
diff -u -r1.550 ChangeLog
--- ChangeLog	17 Sep 2003 19:15:52 -0000	1.550
+++ ChangeLog	18 Sep 2003 00:47:14 -0000
@@ -1,3 +1,10 @@
+2003-09-17  Stefan Seefeld  <seefeld@sympatico.ca>
+
+	* setup.py: Add check command.
+	* qmdist/command/check.py: New file.
+	* qm/__init__.py: Set QM_BUILD environment variable.
+	* qm/test/qmtest.py: Only define QM_HOME if it is not already defined.
+
 2003-09-16  Stefan Seefeld  <seefeld@sympatico.ca>
 
 	* qmdist/command/install_data.py: Do not generate data_dir,
Index: setup.py
===================================================================
RCS file: /home/qm/Repository/qm/setup.py,v
retrieving revision 1.4
diff -u -r1.4 setup.py
--- setup.py	9 Sep 2003 13:48:21 -0000	1.4
+++ setup.py	18 Sep 2003 00:47:14 -0000
@@ -20,8 +20,13 @@
 import string
 import glob
 
+########################################################################
+# imports
+########################################################################
+
 from qmdist.command.build_doc import build_doc
 from qmdist.command.install_data import install_data
+from qmdist.command.check import check
 
 def prefix(list, pref): return map(lambda x, p=pref: p + x, list)
 
@@ -53,7 +58,8 @@
 
 setup(cmdclass={'build_doc': build_doc,
                 #'build': qm_build,
-                'install_data': install_data},
+                'install_data': install_data,
+                'check': check},
       name="qm", 
       version="2.1",
       packages=packages,
Index: qm/__init__.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/__init__.py,v
retrieving revision 1.8
diff -u -r1.8 __init__.py
--- qm/__init__.py	17 Sep 2003 19:15:52 -0000	1.8
+++ qm/__init__.py	18 Sep 2003 00:47:14 -0000
@@ -17,16 +17,18 @@
 # imports
 ########################################################################
 
-import string
+import os, string
 
 try:
     # The config file is created during "make install" by setup.py.
     from qm.config import version
     version_info = tuple(string.split(version, '.'))
     """The version of QM as a tuple of '(major, minor, release)'."""
+    os.environ['QM_BUILD'] = '0'
 except:
     # If qm.config was not available, we are running out of the source tree.
     from qm.__version import version, version_info
+    os.environ['QM_BUILD'] = '1'
 
 from qm.common import *
 from qm.diagnostic import error, warning, message
Index: qm/test/qmtest.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/qmtest.py,v
retrieving revision 1.25
diff -u -r1.25 qmtest.py
--- qm/test/qmtest.py	17 Sep 2003 19:15:52 -0000	1.25
+++ qm/test/qmtest.py	18 Sep 2003 00:47:14 -0000
@@ -37,13 +37,15 @@
 import sys
 import gc
 
-# This executable is supposed to live in ${QM_HOME}/bin (posix)
-# or ${QM_HOME}\Scripts (nt) so we deduce the QM_HOME variable
-# by stripping off the last two components of the path.
-#
-_qm_home = os.path.dirname(os.path.dirname(os.path.abspath(sys.argv[0])))
-os.environ['QM_HOME']=_qm_home
-
+if not os.environ.get('QM_HOME'):
+    # This executable is supposed to live in ${QM_HOME}/bin (posix)
+    # or ${QM_HOME}\Scripts (nt) so we deduce the QM_HOME variable
+    # by stripping off the last two components of the path.
+    #
+    _qm_home = os.path.dirname(os.path.dirname(os.path.abspath(sys.argv[0])))
+    os.environ['QM_HOME']=_qm_home
+else:
+    _qm_home = os.environ['QM_HOME']
 import qm
 
 class config:
