2005-07-22  Mark Mitchell  <mark@codesourcery.com>

	* qm/test/cmdline.py (QMTest.list_long_option_spec): New variable.
	(QMTest.list_recursive_option_spec): Likewise.
	(QMTest.commands_spec): Add "ls".
	(QMTest.Execute): Support "ls".
	(QMTest.__ExecuteList): New method.
	* qm/test/datbase.py (Database.GetExtensions): New method.
	* qm/test/doc/reference.xml: Describe "qmtest ls".

Index: qm/test/cmdline.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/cmdline.py,v
retrieving revision 1.109
diff -c -5 -p -r1.109 cmdline.py
*** qm/test/cmdline.py	21 Jul 2005 08:10:13 -0000	1.109
--- qm/test/cmdline.py	22 Jul 2005 17:46:27 -0000
*************** class QMTest:
*** 301,311 ****
--- 301,324 ----
          "output",
          "FILE",
          "Write test report to FILE (- for stdout)."
          )
  
+     list_long_option_spec = (
+         "l",
+         "long",
+         None,
+         "Use a detailed output format."
+         )
  
+     list_recursive_option_spec = (
+         "R",
+         "recursive",
+         None,
+         "Recursively list the contents of directories."
+         )
+     
      # Groups of options that should not be used together.
      conflicting_option_specs = (
          ( output_option_spec, no_output_option_spec ),
          ( concurrent_option_spec, targets_option_spec ),
          ( extension_output_option_spec, extension_id_option_spec ),
*************** resource classes, etc.  The parameter to
*** 413,422 ****
--- 426,454 ----
           "",
           "Display usage summary.",
           ()
           ),
  
+         ("ls",
+          "List database contents.",
+          "[ NAME ...  ]",
+          """
+          List items stored in the database.
+ 
+          If no arguments are provided, the contents of the root
+          directory of the database are displayed.  Otherwise, each of
+          the database is searched for each of the NAMEs.  If the item
+          found is a directory then the contents of the directory are
+          displayed.
+          """,
+          (
+            help_option_spec,
+            list_long_option_spec,
+            list_recursive_option_spec,
+          ),
+          ),
+          
          ("register",
           "Register an extension class.",
           "KIND CLASS",
           """
  Register an extension class with QMTest.  KIND is the kind of extension
*************** Valid formats are %s.
*** 679,688 ****
--- 711,721 ----
          method = {
              "create" : self.__ExecuteCreate,
              "create-target" : self.__ExecuteCreateTarget,
              "extensions" : self.__ExecuteExtensions,
              "gui" : self.__ExecuteServer,
+             "ls" : self.__ExecuteList,
              "register" : self.__ExecuteRegister,
              "remote" : self.__ExecuteRemote,
              "run" : self.__ExecuteRun,
              "report" : self.__ExecuteReport,
              "summarize": self.__ExecuteSummarize,
*************** Valid formats are %s.
*** 1109,1118 ****
--- 1142,1216 ----
              self._stdout.write(qm.structured_text.to_text(description))
  
          return 0
              
  
+     def __ExecuteList(self):
+         """List the contents of the database."""
+ 
+         database = self.GetDatabase()
+ 
+         long_format = self.HasCommandOption("long")
+         recursive = self.HasCommandOption("recursive")
+ 
+         # If no arguments are specified, list the root directory.
+         args = self.__arguments or ("",)
+ 
+         # Get all the extensions to list.
+         extensions = {}
+         for arg in args:
+             extension = database.GetExtension(arg)
+             if not extension:
+                 raise QMException, qm.error("no such ID", id = arg)
+             if isinstance(extension, qm.test.directory_suite.DirectorySuite):
+                 extensions.update(database.GetExtensions(arg, recursive))
+             else:
+                 extensions[arg] = extension
+ 
+         # Get the labels for the extensions, in alphabetical order.
+         ids = extensions.keys()
+         ids.sort()
+ 
+         # In the short format, just print the labels.
+         if not long_format:
+             for id in ids:
+                 print >> sys.stdout, id
+             return 0
+ 
+         # In the long format, print three columns: the extension kind,
+         # class name, and the label.  We make two passes over the
+         # extensions so that the output will be tidy. In the first pass,
+         # calculate the width required for the first two columns in the
+         # output.  The actual output occurs in the second pass.
+         longest_kind = 0
+         longest_class = 0
+         for i in (0, 1):
+             for id in ids:
+                 extension = extensions[id]
+                 if isinstance(extension,
+                               qm.test.directory_suite.DirectorySuite):
+                     kind = "directory"
+                     class_name = ""
+                 else:
+                     kind = extension.__class__.kind
+                     class_name = extension.GetClassName()
+                     
+                 if i == 0:
+                     kind_len = len(kind) + 1
+                     if kind_len > longest_kind:
+                         longest_kind = kind_len
+                     class_len = len(class_name) + 1
+                     if class_len > longest_class:
+                         longest_class = class_len
+                 else:
+                     print >> sys.stdout, \
+                           "%-*s%-*s%s" % (longest_kind, kind,
+                                           longest_class, class_name, id)
+ 
+         return 0
+         
+         
      def __ExecuteRegister(self):
          """Register a new extension class."""
  
          # Make sure that the KIND and CLASS were specified.
          if (len(self.__arguments) != 2):
Index: qm/test/database.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/database.py,v
retrieving revision 1.44
diff -c -5 -p -r1.44 database.py
*** qm/test/database.py	21 Jul 2005 08:10:14 -0000	1.44
--- qm/test/database.py	22 Jul 2005 17:46:27 -0000
*************** class Database(qm.extension.Extension):
*** 631,641 ****
          except NoSuchSuiteError:
              pass
  
          return None
          
!             
      def RemoveExtension(self, id, kind):
          """Remove the extension 'id' from the database.
  
          'id' -- A label for the 'Extension' instance stored in the
          database.
--- 631,664 ----
          except NoSuchSuiteError:
              pass
  
          return None
          
! 
!     def GetExtensions(self, directory, scan_subdirs):
!         """Return the extensions in 'directory'.
! 
!         'directory' -- The name of a directory.
! 
!         'scan_subdirs' -- True if (and only if) subdirectories of
!         'directory' should be scanned.
! 
!         returns -- A dictionary mapping labels to 'Extension'
!         instances.  The dictionary contains all extensions in
!         'directory', and, if 'scan_subdirs' is true, its
!         subdirectories."""
!         
!         extensions = {}
!         
!         for kind in self.ITEM_KINDS:
!             ids = self.GetIds(kind, directory, scan_subdirs)
!             for id in ids:
!                 extensions[id] = self.GetExtension(id)
! 
!         return extensions
!                 
!                       
      def RemoveExtension(self, id, kind):
          """Remove the extension 'id' from the database.
  
          'id' -- A label for the 'Extension' instance stored in the
          database.
Index: qm/test/doc/reference.xml
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/doc/reference.xml,v
retrieving revision 1.42
diff -c -5 -p -r1.42 reference.xml
*** qm/test/doc/reference.xml	21 Jul 2005 08:10:14 -0000	1.42
--- qm/test/doc/reference.xml	22 Jul 2005 17:46:28 -0000
***************
*** 1169,1178 ****
--- 1169,1244 ----
      </variablelist>
     </section>
  
    </section> <!-- sec-testcmd-extensions -->
  
+   <section id="sec-testcmd-ls">
+    <title><command>&qmtest-cmd; ls</command></title>
+ 
+    <section>
+     <title>Summary</title>
+     <para>List the contents of the test database.</para>
+    </section>
+ 
+    <section>
+     <title>Synopsis</title>
+     <cmdsynopsis>
+      <command>&qmtest-cmd; ls</command>
+      <arg choice="opt" rep="repeat">
+       <replaceable>option</replaceable>
+      </arg>
+      <arg choice="opt" rep="repeat">
+       <replaceable>name</replaceable>
+      </arg>
+     </cmdsynopsis>
+    </section>
+ 
+    <section>
+     <title>Description</title>
+ 
+     <para>The <command>&qmtest-cmd; ls</command> lists the contents of
+     the database, just as the UNIX <command>ls</command> command lists the
+     contents of the filesystem.  If this command is used with no
+     options, QMTest will list the names of the entries in the root
+     directory of the test database.  If one or more names are
+     supplied, then QMTest will list those items, rather than the root
+     directory.  If a name refers to a directory, then the contents of
+     that directory will be displayed.</para>
+ 
+     <para>The <command>ls</command> command accepts these
+     options:</para>
+ 
+     <variablelist>
+      <varlistentry>
+       <term>
+        <option>-l</option>
+       </term>
+       <term>
+        <option>&dashdash;long</option> 
+       </term>
+       <listitem>
+        <para>Use a detailed output format that displays the kind and
+        extension class associated with each item.</para>
+       </listitem>
+      </varlistentry>
+ 
+      <varlistentry>
+       <term>
+        <option>-R</option>
+       </term>
+       <term>
+        <option>&dashdash;recursive</option> 
+       </term>
+       <listitem>
+        <para>Recursively list the contents of directories.</para>
+       </listitem>
+      </varlistentry>
+     </variablelist>
+    </section>
+ 
+   </section> <!-- sec-testcmd-ls -->
+ 
    <section id="sec-testcmd-register">
     <title><command>&qmtest-cmd; register</command></title>
  
     <section>
      <title>Summary</title>
