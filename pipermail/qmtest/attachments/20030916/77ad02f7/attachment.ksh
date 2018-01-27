Index: ChangeLog
===================================================================
RCS file: /home/qm/Repository/qm/ChangeLog,v
retrieving revision 1.549
diff -u -r1.549 ChangeLog
--- ChangeLog	15 Sep 2003 20:26:40 -0000	1.549
+++ ChangeLog	16 Sep 2003 20:21:26 -0000
@@ -1,3 +1,10 @@
+2003-09-16  Stefan Seefeld  <stefan.seefeld@orthosoft.ca>
+
+	* qm/qmdist/command/install_data.py: Do not generate data_dir,
+	as this isn't reliable (windows installer).
+	* qm/__init__.py: Do not use predefined data_dir.
+	* qm/test/qmtest.py: Deduce data_dir from sys.argv[0].
+
 2003-09-15  Mark Mitchell  <mark@codesourcery.com>
 
 	* qm/extension.py (make_dom_document): Simplify.
Index: qm/__init__.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/__init__.py,v
retrieving revision 1.7
diff -u -r1.7 __init__.py
--- qm/__init__.py	27 Aug 2003 16:17:57 -0000	1.7
+++ qm/__init__.py	16 Sep 2003 20:21:26 -0000
@@ -21,15 +21,11 @@
 
 try:
     # The config file is created during "make install" by setup.py.
-    from qm.config import config, version
+    from qm.config import version
     version_info = tuple(string.split(version, '.'))
     """The version of QM as a tuple of '(major, minor, release)'."""
 except:
     # If qm.config was not available, we are running out of the source tree.
-    import os.path
-    class config:
-        data_dir=os.path.dirname(os.path.dirname(__file__))
-
     from qm.__version import version, version_info
 
 from qm.common import *
Index: qm/test/qmtest.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/qmtest.py,v
retrieving revision 1.24
diff -u -r1.24 qmtest.py
--- qm/test/qmtest.py	27 Aug 2003 16:17:57 -0000	1.24
+++ qm/test/qmtest.py	16 Sep 2003 20:21:29 -0000
@@ -21,6 +21,7 @@
 import os
 import os.path
 import sys
+import string
 
 # The Python interpreter will place the directory containing this
 # script in the default path to search for modules.  That is
@@ -35,7 +36,21 @@
 
 import sys
 import gc
+
+# This executable is supposed to live in ${QM_HOME}/bin (posix)
+# or ${QM_HOME}\Scripts (nt) so we deduce the QM_HOME variable
+# by stripping off the last two components of the path.
+#
+_qm_home = os.path.dirname(os.path.dirname(os.path.abspath(sys.argv[0])))
+os.environ['QM_HOME']=_qm_home
+
 import qm
+
+class config:
+    pass
+qm.config = config()
+qm.config.data_dir = os.path.join(_qm_home, 'share', 'qm')
+
 import qm.cmdline
 import qm.diagnostic
 import qm.platform
Index: qmdist/command/install_data.py
===================================================================
RCS file: /home/qm/Repository/qm/qmdist/command/install_data.py,v
retrieving revision 1.1
diff -u -r1.1 install_data.py
--- qmdist/command/install_data.py	9 Sep 2003 13:48:21 -0000	1.1
+++ qmdist/command/install_data.py	16 Sep 2003 20:21:29 -0000
@@ -33,14 +33,9 @@
         outf = open(config, "w")
         outf.write("#the old way...\n")
         outf.write("import os\n")
-        outf.write("os.environ['QM_HOME']='%s'\n"%(id.install_dir))
         outf.write("os.environ['QM_BUILD']='0'\n")
         outf.write("#the new way...\n")
         outf.write("version='%s'\n"%(self.distribution.get_version()))
         
-        outf.write("class config:\n")
-        outf.write("  data_dir='%s'\n"%(os.path.join(id.install_dir,
-                                                     'share',
-                                                     'qm')))
         outf.write("\n")
         self.outfiles.append(config)
