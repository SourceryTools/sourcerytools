Index: qm/test/share/dtml/result.dtml
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/share/dtml/result.dtml,v
retrieving revision 1.4
diff -u -r1.4 result.dtml
--- qm/test/share/dtml/result.dtml	6 Nov 2002 19:38:50 -0000	1.4
+++ qm/test/share/dtml/result.dtml	13 Nov 2002 12:41:05 -0000
@@ -51,6 +51,13 @@
   </dtml-in>
  </table>
 
+  <dtml-var expr="GenerateStartScript()">
+   function run_test() {
+    location = '<dtml-var "MakeRunUrl()">';
+   }
+  <dtml-var expr="GenerateEndScript()">
+
+
  <dtml-var expr="GenerateEndBody()">
 </html>
 
Index: qm/test/web/web.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/web/web.py,v
retrieving revision 1.51
diff -u -r1.51 web.py
--- qm/test/web/web.py	6 Nov 2002 19:38:50 -0000	1.51
+++ qm/test/web/web.py	13 Nov 2002 12:41:05 -0000
@@ -873,6 +873,16 @@
 
         QMTestPage.__init__(self, "result.dtml", server)
         self.result = result
+        self.run_menu_items.append(("This Test", "run_test();"))
+
+    def MakeRunUrl(self):
+        """Return the URL for running the test, corresponding to this result."""
+
+        return qm.web.WebRequest("run-tests",
+                                 base=self.request,
+                                 ids=self.result.GetId()) \
+               .AsUrl()
+        
         
 
 
@@ -1012,7 +1022,7 @@
 
         
     def MakeRunUrl(self):
-        """Return the URL for editing this item."""
+        """Return the URL for running this item."""
 
         return qm.web.WebRequest("run-tests",
                                  base=self.request,
