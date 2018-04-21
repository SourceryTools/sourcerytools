Index: qm/test/result.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/result.py,v
retrieving revision 1.20
diff -u -r1.20 result.py
--- qm/test/result.py	22 Sep 2003 04:53:48 -0000	1.20
+++ qm/test/result.py	1 Oct 2003 13:43:56 -0000
@@ -315,7 +315,9 @@
         element = document.createElement("result")
         element.setAttribute("id", self.GetId())
         element.setAttribute("kind", self.GetKind())
-        # Create and add an element for the outcome.
+        element.setAttribute("outcome", str(self.GetOutcome()))
+        # Create and add an element for the outcome,
+        # for backward compatibility.
         outcome_element = document.createElement("outcome")
         text = document.createTextNode(str(self.GetOutcome()))
         outcome_element.appendChild(text)
Index: qm/test/classes/xml_result_stream.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/classes/xml_result_stream.py,v
retrieving revision 1.5
diff -u -r1.5 xml_result_stream.py
--- qm/test/classes/xml_result_stream.py	22 Sep 2003 04:53:48 -0000	1.5
+++ qm/test/classes/xml_result_stream.py	1 Oct 2003 13:43:58 -0000
@@ -124,7 +124,11 @@
 
         assert node.tagName == "result"
         # Extract the outcome.
-        outcome = qm.xmlutil.get_child_text(node, "outcome").strip()
+        outcome = node.getAttribute("outcome")
+        # If the outcome doesn't exist as an attribute, fall back
+        # to the outcome child node.
+        if not outcome:
+            outcome = qm.xmlutil.get_child_text(node, "outcome").strip()
         # Extract the test ID.
         test_id = node.getAttribute("id")
         kind = node.getAttribute("kind")
Index: qm/test/share/dtds/result.dtd
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/share/dtds/result.dtd,v
retrieving revision 1.5
diff -u -r1.5 result.dtd
--- qm/test/share/dtds/result.dtd	22 Sep 2003 04:53:48 -0000	1.5
+++ qm/test/share/dtds/result.dtd	1 Oct 2003 13:43:58 -0000
@@ -25,7 +25,8 @@
 <!-- The result of executing a test or resource.  -->
 <!ELEMENT result (outcome, property*)>
 <!ATTLIST result id CDATA #REQUIRED
-                 kind (test | resource) #REQUIRED>
+                 kind (test | resource) #REQUIRED
+                 outcome (PASS | FAIL | ERROR | UNTESTED) #REQUIRED>
 
 <!-- The outcome of a test or resource.  -->
 <!ELEMENT outcome (#PCDATA)>
