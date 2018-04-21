Index: qm/test/result.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/result.py,v
retrieving revision 1.21
diff -u -r1.21 result.py
--- qm/test/result.py	2 Oct 2003 16:23:22 -0000	1.21
+++ qm/test/result.py	29 Oct 2003 15:34:23 -0000
@@ -316,7 +316,7 @@
         element.setAttribute("id", self.GetId())
         element.setAttribute("kind", self.GetKind())
         element.setAttribute("outcome", str(self.GetOutcome()))
-        # Add a property element for each property.
+        # Add an annotation element for each annotation.
         keys = self.keys()
         keys.sort()
         for key in keys:
Index: qm/test/share/dtds/result.dtd
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/share/dtds/result.dtd,v
retrieving revision 1.6
diff -u -r1.6 result.dtd
--- qm/test/share/dtds/result.dtd	2 Oct 2003 16:23:22 -0000	1.6
+++ qm/test/share/dtds/result.dtd	29 Oct 2003 15:34:23 -0000
@@ -23,7 +23,6 @@
 <!ATTLIST annotation key CDATA #REQUIRED>
 
 <!-- The result of executing a test or resource.  -->
-<!ELEMENT result property*>
 <!ATTLIST result id CDATA #REQUIRED
                  kind (test | resource) #REQUIRED
                  outcome (PASS | FAIL | ERROR | UNTESTED) #REQUIRED>
