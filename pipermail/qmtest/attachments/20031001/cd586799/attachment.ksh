Index: qm/test/result.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/result.py,v
retrieving revision 1.20
diff -u -r1.20 result.py
--- qm/test/result.py	22 Sep 2003 04:53:48 -0000	1.20
+++ qm/test/result.py	1 Oct 2003 19:09:27 -0000
@@ -315,11 +315,7 @@
         element = document.createElement("result")
         element.setAttribute("id", self.GetId())
         element.setAttribute("kind", self.GetKind())
-        # Create and add an element for the outcome.
-        outcome_element = document.createElement("outcome")
-        text = document.createTextNode(str(self.GetOutcome()))
-        outcome_element.appendChild(text)
-        element.appendChild(outcome_element)
+        element.setAttribute("outcome", str(self.GetOutcome()))
         # Add a property element for each property.
         keys = self.keys()
         keys.sort()
Index: qm/test/classes/xml_result_stream.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/classes/xml_result_stream.py,v
retrieving revision 1.5
diff -u -r1.5 xml_result_stream.py
--- qm/test/classes/xml_result_stream.py	22 Sep 2003 04:53:48 -0000	1.5
+++ qm/test/classes/xml_result_stream.py	1 Oct 2003 19:09:31 -0000
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
+++ qm/test/share/dtds/result.dtd	1 Oct 2003 19:09:31 -0000
@@ -23,9 +23,10 @@
 <!ATTLIST annotation key CDATA #REQUIRED>
 
 <!-- The result of executing a test or resource.  -->
-<!ELEMENT result (outcome, property*)>
+<!ELEMENT result property*>
 <!ATTLIST result id CDATA #REQUIRED
-                 kind (test | resource) #REQUIRED>
+                 kind (test | resource) #REQUIRED
+                 outcome (PASS | FAIL | ERROR | UNTESTED) #REQUIRED>
 
 <!-- The outcome of a test or resource.  -->
 <!ELEMENT outcome (#PCDATA)>
Index: tests/results_files/README
===================================================================
RCS file: /home/qm/Repository/qm/tests/results_files/README,v
retrieving revision 1.1
diff -u -r1.1 README
--- tests/results_files/README	9 Aug 2003 05:15:02 -0000	1.1
+++ tests/results_files/README	1 Oct 2003 19:09:33 -0000
@@ -23,3 +23,9 @@
        -- More complicated file layout containing metadata.
        -- 'Result's no longer use the standard pickling mechanism.
      -> result_class_v1-file_format_v1-pickling_format_v1.qmr
+  -- XML result file format v2.
+     -> xml_results_v2.qmr
+  -- XML result file format v3.
+       -- The 'outcome' is now provided as an attribute of the
+          'result' element.
+     -> xml_results_v3.qmr
