Index: qm/test/cmdline.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/cmdline.py,v
retrieving revision 1.118
diff -u -r1.118 cmdline.py
--- qm/test/cmdline.py	1 Dec 2005 21:13:10 -0000	1.118
+++ qm/test/cmdline.py	17 Jul 2006 13:28:17 -0000
@@ -31,6 +31,7 @@
 from   qm.test.execution_engine import *
 from   qm.test.result_stream import ResultStream
 from   qm.test.runnable import Runnable
+from   qm.test.suite import Suite
 from   qm.test.report import ReportGenerator
 from   qm.test.classes.dir_run_database import *
 from   qm.trace import *
@@ -1053,9 +1054,9 @@
         if extension_id is not None:
             # Create the extension instance.  Objects derived from
             # Runnable require magic additional arguments.
-            if issubclass(extension_class, Runnable):
-                extras = { Runnable.EXTRA_ID : extension_id, 
-                           Runnable.EXTRA_DATABASE : database }
+            if issubclass(extension_class, (Runnable, Suite)):
+                extras = { 'qmtest_id' : extension_id, 
+                           'qmtest_database' : database }
             else:
                 extras = {}
             extension = extension_class(arguments, **extras)
@@ -1283,8 +1284,15 @@
             extension = database.GetExtension(arg)
             if not extension:
                 raise QMException, qm.error("no such ID", id = arg)
-            if isinstance(extension, qm.test.directory_suite.DirectorySuite):
-                extensions.update(database.GetExtensions(arg, recursive))
+            if isinstance(extension, qm.test.suite.Suite):
+                if recursive:
+                    test_ids, suite_ids = extension.GetAllTestAndSuiteIds()
+                    extensions.update([(i, database.GetExtension(i))
+                                       for i in test_ids + suite_ids])
+                else:
+                    ids = extension.GetTestIds() + extension.GetSuiteIds()
+                    extensions.update([(i, database.GetExtension(i))
+                                       for i in ids])
             else:
                 extensions[arg] = extension
 
