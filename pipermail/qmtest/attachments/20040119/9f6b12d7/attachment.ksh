Index: qm/extension.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/extension.py,v
retrieving revision 1.13
diff -u -r1.13 extension.py
--- qm/extension.py	15 Sep 2003 20:26:40 -0000	1.13
+++ qm/extension.py	19 Jan 2004 04:35:04 -0000
@@ -17,6 +17,7 @@
 
 import os.path
 import qm
+from qm.fields import Field
 import StringIO
 import tokenize
 import xml
@@ -34,6 +35,41 @@
 
     'Extension' is an abstract class."""
 
+    class Type(type):
+
+        def __init__(cls, name, bases, dict):
+            """Generate an '_argument_dictionary' holding all the 'Field' objects.
+            Then replace 'Field' objects by their values for convenient use inside
+            the code."""
+
+            # list all base classes that are themselfs of type Extension
+            #
+            # 'Extension' isn't known at this point so all we can do to test
+            # is check that the __metaclass__ is the same as the one of 'cls'
+            hierarchy = [i for i in bases if \
+                         getattr(i, '__metaclass__', None) == cls.__metaclass__]
+            arguments = {}
+            for c in hierarchy:
+                arguments.update(c._argument_dictionary)
+            # now set arguments from class variables of type 'Field'
+            for i in dict:
+                if isinstance(dict[i], Field):
+                    arguments[i] = dict[i]
+
+            # BACKWARD COMPATIBILITY:
+            # inject all members of the 'arguments' list into the dict
+            for i in dict.get('arguments', []):
+                arguments[i.GetName()] = i
+
+            setattr(cls, '_argument_dictionary', arguments)
+            setattr(cls, '_argument_list', arguments.values())
+
+            # finally set default values
+            for i in arguments:
+                setattr(cls, i, arguments[i].GetDefaultValue())
+
+    __metaclass__ = Type
+
     arguments = [
         ]
     """A list of the arguments to the extension class.
@@ -53,20 +89,26 @@
     QMTest has 'test' and 'target' extension classes."""
     
     _argument_list = None
-    """A list of all the 'Field's in this class.
+    """OBSOLETE: this variable is created by metaclass.
+    
+    A list of all the 'Field's in this class.
 
     This list combines the complete list of 'arguments'.  'Field's
     appear in the order reached by a pre-order breadth-first traversal
     of the hierarchy, starting from the most derived class."""
     
     _argument_dictionary = None
-    """A map from argument names to 'Field' instances.
+    """OBSOLETE: this variable is created by the metaclass.
+
+    A map from argument names to 'Field' instances.
 
     A map from the names of arguments for this class to the
     corresponding 'Field'."""
 
     _allow_arg_names_matching_class_vars = None
-    """True if it is OK for fields to have the same name as class variables.
+    """OBSOLETE: The new design uses class vars for arguments.
+
+    True if it is OK for fields to have the same name as class variables.
 
     If this variable is set to true, it is OK for the 'arguments' to
     contain a field whose name is the same as a class variable.  That
@@ -78,7 +120,6 @@
     working, while preventing new extension classes from making the
     same mistake."""
 
-    
     def __init__(self, arguments):
         """Construct a new 'Extension'.
 
@@ -104,6 +145,10 @@
         # Remember the arguments provided.
         self.__dict__.update(arguments)
 
+    def GetArguments(self):
+        
+        return self._arguments
+
 
     def __getattr__(self, name):
 
@@ -127,37 +172,7 @@
 
     assert issubclass(extension_class, Extension)
 
-    arguments = extension_class.__dict__.get("_argument_list")
-    if arguments is None:
-        # There are no arguments yet.
-        arguments = []
-        dictionary = {}
-        # Start with the most derived class.
-        for c in extension_class.__mro__:
-            # Add the arguments from this class.
-            new_arguments = c.__dict__.get("arguments", [])
-            for a in new_arguments:
-                name = a.GetName()
-                # An extension class may not have an argument with the
-                # same name as a class variable.  That leads to
-                # serious confusion.
-                if (not extension_class._allow_arg_names_matching_class_vars
-                    and hasattr(extension_class, name)):
-                    raise qm.common.QMException, \
-                          qm.error("ext arg name matches class var",
-                                   class_name = extension_class.__name__,
-                                   argument_name = name)
-                # If we already have an entry for this name, then a
-                # derived class overrides this argument.
-                if not dictionary.has_key(name):
-                    arguments.append(a)
-                    dictionary[name] = a
-                    
-        extension_class._argument_list = arguments
-        extension_class._argument_dictionary = dictionary
-        
-    return arguments
-        
+    return extension_class.__dict__.get("_argument_list")
 
 def get_class_arguments_as_dictionary(extension_class):
     """Return the arguments associated with 'extension_class'.
@@ -170,11 +185,7 @@
 
     assert issubclass(extension_class, Extension)
 
-    if extension_class.__dict__.get("_argument_dictionary") is None:
-        get_class_arguments(extension_class)
-        
-    return extension_class._argument_dictionary
-        
+    return extension_class.__dict__.get("_argument_dictionary")
 
 def get_class_description(extension_class, brief=0):
     """Return a brief description of the extension class 'extension_class'.
Index: tests/xmldb/QMTest/test_inheritance.py
===================================================================
RCS file: /home/qm/Repository/qm/tests/xmldb/QMTest/test_inheritance.py,v
retrieving revision 1.2
diff -u -r1.2 test_inheritance.py
--- tests/xmldb/QMTest/test_inheritance.py	20 Dec 2002 19:33:53 -0000	1.2
+++ tests/xmldb/QMTest/test_inheritance.py	19 Jan 2004 04:35:06 -0000
@@ -40,16 +40,15 @@
                                computed = "true")
         ]
 
+    b = qm.fields.IntegerField(name = "b",
+                               default_value = 42)
 
     def Run(self, context, result):
 
-        args = qm.extension.get_class_arguments(Derived)
-        if args[0] != Derived.arguments[0]:
+        args = qm.extension.get_class_arguments_as_dictionary(Derived)
+        if args['a'] != Derived.arguments[0]:
             result.Fail("Incorrect argument.")
-        elif not args[0].IsComputed():
+        elif not args['a'].IsComputed():
             result.Fail("Argument is not computed.")
-        else:
-            for a in args[1:]:
-                if a.GetName() == "a":
-                    result.Fail('Two arguments named \"a\".')
-                        
+        elif self.b != args['b'].GetDefaultValue():
+            result.Fail("Argument 'b' has wrong value.")
