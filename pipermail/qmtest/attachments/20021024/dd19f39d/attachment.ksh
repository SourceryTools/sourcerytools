Index: qm/extension.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/extension.py,v
retrieving revision 1.3
diff -u -r1.3 extension.py
--- qm/extension.py	17 Oct 2002 20:38:15 -0000	1.3
+++ qm/extension.py	24 Oct 2002 11:38:20 -0000
@@ -298,7 +298,7 @@
     
         
 
-def parse_dom_element(element, class_loader):
+def parse_dom_element(element, class_loader, attachment_store=None):
     """Parse a DOM node representing an instance of 'Extension'.
 
     'element' -- A DOM node, of the format created by
@@ -338,7 +338,7 @@
             = filter(lambda e: e.nodeType == xml.dom.Node.ELEMENT_NODE,
                      argument_element.childNodes)[0]
         # Parse the value.
-        value = field.GetValueFromDomNode(value_node, None)
+        value = field.GetValueFromDomNode(value_node, attachment_store)
         # Remember it.
         arguments[name] = value
     
Index: qm/test/classes/xml_database.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/classes/xml_database.py,v
retrieving revision 1.3
diff -u -r1.3 xml_database.py
--- qm/test/classes/xml_database.py	17 Oct 2002 20:38:15 -0000	1.3
+++ qm/test/classes/xml_database.py	24 Oct 2002 11:38:20 -0000
@@ -89,6 +89,17 @@
 
     def WriteTest(self, test):
 
+        # Move all attachements to the attachement store for this database
+
+        for field in test.GetClassArguments():
+            if isinstance(field, qm.fields.AttachmentField):
+                attachment = test.GetArguments()[field.GetName()]
+                if attachment is not None:
+                    test.GetArguments()[field.GetName()] = \
+                         self.__store.Store(test.GetId(), attachment.GetMimeType(),
+                                            attachment.GetDescription(),
+                                            attachment.GetFileName(), attachment.GetData())
+                                
         # Generate the document.
         document = \
             qm.extension.make_dom_document(test.GetClass(),
@@ -202,7 +213,8 @@
         test_class, arguments \
             = (qm.extension.parse_dom_element
                (document.documentElement,
-                lambda n : qm.test.base.get_test_class(n, self)))
+                lambda n : qm.test.base.get_test_class(n, self),
+                self.__store))
         test_class_name = qm.extension.get_extension_class_name(test_class)
         # For backwards compatibility, look for "prerequisite" elements.
         for p in document.documentElement.getElementsByTagName("prerequisite"):
@@ -339,7 +351,8 @@
             mime_type,
             description,
             file_name,
-            location=data_file_path)
+            location=data_file_path,
+            store=self)
 
 
     # Implementation of base class methods.
@@ -370,8 +383,8 @@
         'file_name' -- The file name specified for the attachment."""
         
         # Convert the item's containing suite to a path.
-        parent_suite_id = self.SplitLabel(item_id)[0]
-        parent_suite_path = self._LabelToPath(parent_suite_id)
+        parent_suite_path = os.path.dirname(self.__database._GetPathFromLabel(item_id))
+
         # Construct a file name free of suspicious characters.
         base, extension = os.path.splitext(file_name)
         safe_file_name = qm.label.thunk(base) + extension
