Index: GNUmakefile.in
===================================================================
RCS file: /home/qm/Repository/qm/GNUmakefile.in,v
retrieving revision 1.37
diff -u -r1.37 GNUmakefile.in
--- GNUmakefile.in	24 May 2004 20:37:41 -0000	1.37
+++ GNUmakefile.in	5 Jan 2005 22:17:17 -0000
@@ -59,9 +59,6 @@
 
 build:
 	$(PYTHON) ./setup.py build
-# The distutils shipped with Python versions prior to 2.3
-# buggily does not make these executable.
-	chmod 755 build/scripts-*/*
 
 doc:
 	$(PYTHON) ./setup.py build_doc
Index: setup.py
===================================================================
RCS file: /home/qm/Repository/qm/setup.py,v
retrieving revision 1.12
diff -u -r1.12 setup.py
--- setup.py	24 May 2004 20:37:41 -0000	1.12
+++ setup.py	5 Jan 2005 22:17:18 -0000
@@ -25,6 +25,7 @@
 import string
 import glob
 from   qmdist.command.build import build
+from   qmdist.command.build_scripts import build_scripts
 from   qmdist.command.build_doc import build_doc
 from   qmdist.command.install_data import install_data
 from   qmdist.command.install_lib import install_lib
@@ -111,6 +112,7 @@
       description="QMTest is an automated software test execution tool.",
       
       cmdclass={'build': build,
+                'build_scripts': build_scripts,
                 'build_doc': build_doc,
                 'install_data': install_data,
                 'install_lib': install_lib,
