Index: ChangeLog
===================================================================
RCS file: /home/qm/Repository/qm/ChangeLog,v
retrieving revision 1.704
diff -u -r1.704 ChangeLog
--- ChangeLog	7 Mar 2006 14:20:40 -0000	1.704
+++ ChangeLog	2 Jun 2006 12:54:47 -0000
@@ -1,3 +1,14 @@
+2006-06-02  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* qm/extension.py: Raise AttributeError instead of AssertionError when
+	wrong attributes are passed.
+	* qm/common.py: Add parse_string_list function.
+	* qm/test/context.py: Add Context.GetStringList method.
+	* qm/test/classes/compiler.py: Add optional ldflags argument to
+	Compiler constructor.
+	* qm/test/classes/compiler_test.py: Fix _RemoveDirectory()
+	* qm/test/classes/compilation_test.py: Add ExecutableTest.
+
 2006-03-07  Stefan Seefeld  <stefan@codesourcery.com>
 
 	* qm/test/classes/compiler_table.py: Fix search for host
Index: qm/common.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/common.py,v
retrieving revision 1.88
diff -u -r1.88 common.py
--- qm/common.py	25 Aug 2004 10:11:38 -0000	1.88
+++ qm/common.py	2 Jun 2006 12:54:47 -0000
@@ -638,6 +638,51 @@
         raise ValueError, value
 
     
+def parse_string_list(value):
+    """Parse a string list.
+
+    'value' -- A string.
+
+    returns -- A list of strings.
+
+    raises -- 'ValueError' if 'value' contains unbalanced quotes."""
+
+    # If the string doesn't contain quotes, simply split it.
+    if "'" not in value and '"' not in value:
+        return value.split()
+    # Else split it manually at non-quoted whitespace only.
+    breaks = []
+    esc = False
+    quoted_1 = False # in '' quotes
+    quoted_2 = False # in "" quotes
+    value.strip()
+    # Find all non-quoted space.
+    for i, c in enumerate(value):
+        if c == '\\':
+            esc = not esc
+            continue
+        elif c == "'":
+            if not esc and not quoted_2:
+                quoted_1 = not quoted_1
+        elif c == '"':
+            if not esc and not quoted_1:
+                quoted_2 = not quoted_2
+        elif c in [' ', '\t']:
+            # This is a breakpoint if it is neither quoted nor escaped.
+            if not (quoted_1 or quoted_2 or esc):
+                breaks.append(i)
+        esc = False
+    # Make sure quotes are matched.
+    if quoted_1 or quoted_2 or esc:
+        raise ValueError, value
+    string_list = []
+    start = 0
+    for end in breaks:
+        string_list.append(value[start:end])
+        start = end
+    string_list.append(value[start:])
+    return [s.strip() for s in string_list if s not in [' ', '\t']] 
+
     
 # No 'time.strptime' on non-UNIX systems, so use this instead.  This
 # version is more forgiving, anyway, and uses our standardized timestamp
Index: qm/extension.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/extension.py,v
retrieving revision 1.20
diff -u -r1.20 extension.py
--- qm/extension.py	1 Dec 2005 08:27:12 -0000	1.20
+++ qm/extension.py	2 Jun 2006 12:54:48 -0000
@@ -151,7 +151,8 @@
         if __debug__:
             dictionary = get_class_arguments_as_dictionary(self.__class__)
             for a, v in arguments.items():
-                assert dictionary.has_key(a)
+                if not dictionary.has_key(a):
+                    raise AttributeError, a
         
         # Remember the arguments provided.
         self.__dict__.update(arguments)
Index: qm/test/context.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/context.py,v
retrieving revision 1.17
diff -u -r1.17 context.py
--- qm/test/context.py	31 May 2005 15:48:37 -0000	1.17
+++ qm/test/context.py	2 Jun 2006 12:54:48 -0000
@@ -155,6 +155,36 @@
             raise ContextException(key, "invalid boolean context var")
         
 
+    def GetStringList(self, key, default = None):
+        """Return the list of strings associated with 'key'.
+
+        'key' -- A string.
+
+        'default' -- A default list.
+
+        If there is no value associated with 'key' and default is not
+        'None', then the boolean value associated with default is
+        used.  If there is no value associated with 'key' and default
+        is 'None', an exception is raised.
+
+        The value associated with 'key' must be a string.  If not, an
+        exception is raised.  If the value is a string, but does not
+        correspond to a boolean value, an exception is raised.
+        """
+        
+        valstr = self.get(key)
+        if valstr is None:
+            if default is None:
+                raise ContextException(key)
+            else:
+                return default
+
+        try:
+            return qm.common.parse_string_list(valstr)
+        except ValueError:
+            raise ContextException(key, "invalid string list context var")
+
+
     def GetTemporaryDirectory(self):
         """Return the path to the a temporary directory.
 
Index: qm/test/classes/classes.qmc
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/classes/classes.qmc,v
retrieving revision 1.22
diff -u -r1.22 classes.qmc
--- qm/test/classes/classes.qmc	26 Oct 2005 02:55:21 -0000	1.22
+++ qm/test/classes/classes.qmc	2 Jun 2006 12:54:48 -0000
@@ -12,7 +12,7 @@
  <class kind="result_stream" name="tet_stream.TETStream"/>
  <class kind="resource" name="temporary.TempDirectoryResource"/>
  <class kind="resource" name="compiler_table.CompilerTable"/>
- <class kind="resource" name="compilation_test.SimpleCompiledResource"/>
+ <class kind="resource" name="compilation_test.CompiledResource"/>
  <class kind="target" name="process_target.ProcessTarget"/>
  <class kind="target" name="rsh_target.RSHTarget"/>
  <class kind="target" name="serial_target.SerialTarget"/>
@@ -26,7 +26,8 @@
  <class kind="test" name="python.ExceptionTest"/>
  <class kind="test" name="python.ExecTest"/>
  <class kind="test" name="python.StringExceptionTest"/>
- <class kind="test" name="compilation_test.SimpleCompilationTest"/>
+ <class kind="test" name="compilation_test.CompilationTest"/>
+ <class kind="test" name="compilation_test.ExecutableTest"/>
  <class kind="label" name="file_label.FileLabel"/>
  <class kind="label" name="python_label.PythonLabel"/>
  <class kind="suite" name="explicit_suite.ExplicitSuite"/>
Index: qm/test/classes/compilation_test.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/classes/compilation_test.py,v
retrieving revision 1.1
diff -u -r1.1 compilation_test.py
--- qm/test/classes/compilation_test.py	26 Oct 2005 02:55:21 -0000	1.1
+++ qm/test/classes/compilation_test.py	2 Jun 2006 12:54:48 -0000
@@ -5,8 +5,9 @@
 # Date:   2005-10-17
 #
 # Contents:
-#   SimpleCompilationTest
-#   SimpleCompiledResource
+#   CompilationTest
+#   CompiledResource
+#   ExecutableTest
 #
 # Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. 
 #
@@ -16,19 +17,48 @@
 
 from compiler_test import CompilationStep, CompilerTest
 from   qm.fields import *
+from   qm.test.database import get_database
 from   qm.test.result import *
 from   qm.test.test import *
 from   qm.test.resource import *
+import qm.executable
+from   qm.extension import parse_descriptor
+from   qm.test.base import get_extension_class
 from   compiler import Compiler
 from   local_host import LocalHost
 
+
+def _get_host(context, variable):
+    """Get a host instance according to a particular context variable.
+    Return a default 'LocalHost' host if the variable is undefined.
+
+    'context' -- The context to read the host descriptor from.
+
+    'variable' -- The name to which the host descriptor is bound.
+
+    returns -- A Host instance.
+
+    """
+
+    target_desc = context.get(variable)
+    if target_desc is None:
+        target = LocalHost({})
+    else:
+        f = lambda n: get_extension_class(n, "host", get_database())
+        host_class, arguments = parse_descriptor(target_desc.strip(), f)
+        target = host_class(arguments)
+    return target
+
+
 ########################################################################
 # Classes
 ########################################################################
 
-class SimpleCompilationTest(CompilerTest):
-    """A SimpleCompilationTest compiles source files and optionally runs the
-    generated executable."""
+class CompilationTest(CompilerTest):
+    """A CompilationTest compiles and optionally runs an executable.
+    CompilationTest allows simple cross-testing. To run the executable on
+    anything other than localhost, specify a Host descriptor by means of the
+    context variable 'CompilationTest.target'."""
 
     options = SetField(TextField(description="""Test-specific options to pass to the compiler."""))
     source_files = SetField(TextField(description="Source files to be compiled."))
@@ -41,16 +71,18 @@
 
         self._MakeDirectory(context)
         CompilerTest.Run(self, context, result)
-        self._RemoveDirectory(context, result)
+        if self.execute:
+            self._RemoveDirectory(context, result)
 
 
     def _GetCompiler(self, context):
         """The name of the compiler executable is taken from the context variable
-        'SimpleCompileTest.compiler_path'."""
+        'CompilationTest.compiler_path'."""
 
-        name = context["SimpleCompilationTest.compiler_path"]
-        options = context.get("SimpleCompilationTest.compiler_options", [])
-        return Compiler(name, options)
+        name = context["CompilationTest.compiler_path"]
+        options = context.GetStringList("CompilationTest.compiler_options", [])
+        ldflags = context.GetStringList("CompilationTest.compiler_ldflags", [])
+        return Compiler(name, options, ldflags)
 
 
     def _GetCompilationSteps(self, context):
@@ -68,8 +100,7 @@
 
     def _GetTarget(self, context):
 
-        # Run the executable locally.
-        return LocalHost({})
+        return _get_host(context, "CompilationTest.target")
         
 
     def _CheckOutput(self, context, result, prefix, output, diagnostics):
@@ -80,9 +111,8 @@
         return True
 
 
-class SimpleCompiledResource(Resource):
-    """A SimpleCompiledResource compiles source files into an executable which then
-    is available for execution to dependent test instances."""
+class CompiledResource(Resource):
+    """A CompiledResource compiles an executable."""
 
     options = SetField(TextField(description="Resource-specific options to pass to the compiler."))
     source_files = SetField(TextField(description="Source files to be compiled."))
@@ -91,17 +121,38 @@
 
     def SetUp(self, context, result):
 
-        compiler = SimpleCompilationTest({'options':self.options,
+        self._context = context
+        self._compiler = CompilationTest({'options':self.options,
                                           'source_files':self.source_files,
                                           'executable':self.executable,
-                                          'execute':False})
+                                          'execute':False},
+                                         qmtest_id = self.GetId(),
+                                         qmtest_database = self.GetDatabase())
         
-        compiler.Run(self, context, result)
-        context['SimpleCompiledResource.executable'] = self.executable
+        self._compiler.Run(context, result)
+        directory = self._compiler._GetDirectory(context)
+        self._executable = os.path.join(directory, self.executable)
+        context['CompiledResource.executable'] = self._executable
         
 
     def CleanUp(self, result):
 
-        # Whether or not to clean up (i.e. remove the executable) is best
-        # expressed via the context.
-        pass
+        self._compiler._RemoveDirectory(self._context, result)
+
+
+class ExecutableTest(Test):
+    """An ExecuableTest runs an executable from a CompiledResource.
+    ExecutableTest allows simple cross-testing. To run the executable on
+    anything other than localhost, specify a Host descriptor by means of the
+    context variable 'ExecutableTest.host'."""
+
+    args = SetField(TextField(description="Arguments to pass to the executable."))
+
+    def Run(self, context, result):
+
+        executable = context['CompiledResource.executable']
+        host = _get_host(context, 'ExecutableTest.host')
+        status, output = host.UploadAndRun(executable, self.args)
+        if not result.CheckExitStatus('ExecutableTest.', 'Program', status):
+            result.Fail('Unexpected exit_code')        
+
Index: qm/test/classes/compiler.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/classes/compiler.py,v
retrieving revision 1.5
diff -u -r1.5 compiler.py
--- qm/test/classes/compiler.py	1 Dec 2005 06:56:22 -0000	1.5
+++ qm/test/classes/compiler.py	2 Jun 2006 12:54:48 -0000
@@ -96,18 +96,21 @@
     modes = [ MODE_COMPILE, MODE_ASSEMBLE, MODE_LINK, MODE_PREPROCESS ]
     """The available compilation modes."""
 
-    def __init__(self, path, options=None):
+    def __init__(self, path, options=None, ldflags=None):
         """Construct a new 'Compiler'.
 
         'path' -- A string giving the location of the compiler
         executable.
 
         'options' -- A list of strings indicating options to the
-        compiler, or 'None' if there are no options."""
+        compiler, or 'None' if there are no options.
+
+        'ldflags' -- A list of strings indicating ld flags to the
+        compiler, or 'None' if there are no flags."""
 
         self._path = path
-        self._ldflags = []
         self.SetOptions(options or [])
+        self.SetLDFlags(ldflags or [])
             
 
     def Compile(self, mode, files, dir, options = [], output = None,
Index: qm/test/classes/compiler_test.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/classes/compiler_test.py,v
retrieving revision 1.5
diff -u -r1.5 compiler_test.py
--- qm/test/classes/compiler_test.py	1 Dec 2005 07:31:06 -0000	1.5
+++ qm/test/classes/compiler_test.py	2 Jun 2006 12:54:48 -0000
@@ -16,7 +16,7 @@
 from   compiler import *
 from   qm.test.result import *
 from   qm.test.test import *
-import os, string
+import os, string, dircache
 
 ########################################################################
 # Classes
@@ -92,9 +92,19 @@
         Otherwise, the directory is left behind to allow investigation
         of the reasons behind the test failure."""
 
+        def removedir(directory, dir = True):
+            for n in dircache.listdir(directory):
+                name = os.path.join(directory, n)
+                if os.path.isfile(name):
+                    os.remove(name)
+                elif os.path.isdir(name):
+                    removedir(name)
+            if dir: os.rmdir(directory)
+
         if result.GetOutcome() == Result.PASS:
             try:
-                dir = self._GetDirectory(context)
+                directory = self._GetDirectory(context)
+                removedir(directory, False)
                 os.removedirs(directory)
             except:
                 # If the directory cannot be removed, that is no
