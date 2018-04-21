Index: qm/test/report.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/report.py,v
retrieving revision 1.4
diff -u -r1.4 report.py
--- qm/test/report.py	4 Nov 2005 22:07:28 -0000	1.4
+++ qm/test/report.py	21 Jun 2006 15:08:45 -0000
@@ -24,6 +24,7 @@
 from qm.test.result import Result
 from qm.test.reader_test_run import ReaderTestRun
 import xml.sax
+import sys
 
 ########################################################################
 # Classes
@@ -35,7 +36,10 @@
 
     def __init__(self, output, database=None):
 
-        self.output = open(output, 'w+')
+        if output and output != '-':
+            self.output = open(output, 'w+')
+        else:
+            self.output = sys.stdout
         self.database = database
         self.__document = qm.xmlutil.create_dom_document(
             public_id="QMTest/Report",
@@ -209,10 +213,14 @@
             element.appendChild(child)
 
         # Report all items, sorted by kind.
-        for kind in [Result.TEST, Result.RESOURCE_SETUP, Result.RESOURCE_CLEANUP]:
-            for id in self.database.GetIds(kind, directory, False):
-                self._ReportItem(kind, id, self.database.SplitLabel(id)[1],
-                                 test_runs, element)
+        for id in self.database.GetIds('test', directory, False):
+            self._ReportItem('test', id, self.database.SplitLabel(id)[1],
+                             test_runs, element)
+        for id in self.database.GetIds('resource', directory, False):
+            self._ReportItem('resource_setup', id, self.database.SplitLabel(id)[1],
+                             test_runs, element)
+            self._ReportItem('resource_cleanup', id, self.database.SplitLabel(id)[1],
+                             test_runs, element)
         return element
 
 
