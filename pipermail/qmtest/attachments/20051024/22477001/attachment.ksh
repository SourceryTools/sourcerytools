2005-10-23  Mark Mitchell  <mark@codesourcery.com>

	* qm/test/base.py (load_outcomes): Adjust documentation.
	(load_results): Permit file parameter to be an extension
	descriptor.
	* qm/test/cmdline.py (QMTest.commands_spec): Add --output
	option to "qmtest summarize".
	(QMTest.__ExecuteSummarize): Use self.results_file_name.  Adjust
	call to load_results.  Pass result of --output option to
	__GetResultStreams.
	(QMTest.__ExecuteRun): Use self.results_file_name.  Pass results
	file name to __GetResultStreams.
	(QMTest.__GetExpectedOutcomes): Adjust call to load_outcomes.
	(QMTest.__FilterTestsToRun): Likewise.
	(QMTest.__GetResultStreams): Add output_file parameter.  Create a
	file result stream appropriate.
	* qm/test/report.py (ReportGenerator._CreateResultStreams): Adjust
	call to load_results.
	* qm/test/classes/dir_run_database.py (DirRunDatabase.__init__):
	Likewise.
	* qm/test/doc/manual.xml: Use DocBook 4.2.  Provide a URL for the
	DocBook DTD.
	* qm/test/doc/reference.xml: Document -o option to summarize and
	extended descriptor syntax for input file.

Index: qm/test/base.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/base.py,v
retrieving revision 1.102
diff -c -5 -p -r1.102 base.py
*** qm/test/base.py	14 Sep 2005 13:24:46 -0000	1.102
--- qm/test/base.py	24 Oct 2005 07:13:52 -0000
*************** def get_resource_class(class_name, datab
*** 308,335 ****
      'class_name'."""
      
      return get_extension_class(class_name, 'resource', database)
  
  
- def load_outcomes(file, database):
-     """Load test outcomes from a file.
- 
-     'file' -- The file object from which to read the results.
- 
-     'database' -- The current database.
- 
-     returns -- A map from test IDs to outcomes."""
- 
-     results = load_results(file, database)
-     outcomes = {}
-     for r in results:
-         # Keep test outcomes only.
-         if r.GetKind() == Result.TEST:
-             outcomes[r.GetId()] = r.GetOutcome()
-     return outcomes
- 
- 
  def get_extension_classes(kind, database = None):
      """Return the extension classes for the given 'kind'.
  
      'kind' -- The kind of extensions being sought.  The value must be
      one of the 'extension_kinds'.
--- 308,317 ----
*************** def get_extension_classes(kind, database
*** 352,379 ****
      
      
  def load_results(file, database):
      """Read test results from a file.
  
!     'file' -- The file object from which to read the results.
  
      'database' -- The current database.
  
      returns -- A 'ResultReader' object, or raises an exception if no
      appropriate reader is available."""
  
!     # Find the first FileResultStream that will accept this file.
!     for c in get_extension_classes("result_reader", database):
!         if issubclass(c, FileResultReader):
!             try:
!                 return c({"file" : file})
!             except FileResultReader.InvalidFile:
!                 # Go back to the beginning of the file.
!                 file.seek(0)
          
!     raise FileResultReader.InvalidFile, \
!           "not a valid results file"
  
  
  def _result_from_dom(node):
      """Extract a result from a DOM node.
  
--- 334,402 ----
      
      
  def load_results(file, database):
      """Read test results from a file.
  
!     'file' -- The filename or file object from which to read the
!     results.  If 'file' is not a string, then it is must be a seekable
!     file object, and this function will look for a 'FileResultReader'
!     that accepts the file.  If 'file' is a string, then it is treated as
!     either a filename or as an extension descriptor.
  
      'database' -- The current database.
  
      returns -- A 'ResultReader' object, or raises an exception if no
      appropriate reader is available."""
  
!     f = None
!     if isinstance(file, types.StringTypes):
!         if os.path.exists(file):
!             f = open(file, "rb")
!     else:
!         f = file
!     if f:
!         # Find the first FileResultStream that will accept this file.
!         for c in get_extension_classes("result_reader", database):
!             if issubclass(c, FileResultReader):
!                 try:
!                     return c({"file" : f})
!                 except FileResultReader.InvalidFile:
!                     # Go back to the beginning of the file.
!                     f.seek(0)
!     if not isinstance(file, types.StringTypes):
!         raise FileResultReader.InvalidFile, \
!               "not a valid results file"
!     if database:
!         extension_loader = database.GetExtension
!     else:
!         extension_loader = None
!     class_loader = lambda n: get_extension_class(n,
!                                                  "result_reader",
!                                                  database)
!     cl, args = qm.extension.parse_descriptor(file,
!                                              class_loader,
!                                              extension_loader)
!     return cl(args)
          
! 
! def load_outcomes(file, database):
!     """Load test outcomes from a file.
! 
!     'file' -- The file object from which to read the results.  See
!     'load_results' for details.
! 
!     'database' -- The current database.
! 
!     returns -- A map from test IDs to outcomes."""
! 
!     results = load_results(file, database)
!     outcomes = {}
!     for r in results:
!         # Keep test outcomes only.
!         if r.GetKind() == Result.TEST:
!             outcomes[r.GetId()] = r.GetOutcome()
!     return outcomes
  
  
  def _result_from_dom(node):
      """Extract a result from a DOM node.
  
Index: qm/test/cmdline.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/cmdline.py,v
retrieving revision 1.115
diff -c -5 -p -r1.115 cmdline.py
*** qm/test/cmdline.py	18 Oct 2005 18:37:19 -0000	1.115
--- qm/test/cmdline.py	24 Oct 2005 07:13:52 -0000
*************** Use the '--format' option to specify the
*** 578,587 ****
--- 578,588 ----
  Valid formats are %s.
           """ % _make_comma_separated_string(summary_formats, "and"),
           ( help_option_spec,
             format_option_spec,
             outcomes_option_spec,
+            output_option_spec,
             result_stream_spec)
           ),
  
          ]
  
*************** Valid formats are %s.
*** 1419,1429 ****
      def __ExecuteSummarize(self):
          """Read in test run results and summarize."""
  
          # If no results file is specified, use a default value.
          if len(self.__arguments) == 0:
!             results_path = "results.qmr"
          else:
              results_path = self.__arguments[0]
  
          database = self.GetDatabaseIfAvailable()
  
--- 1420,1430 ----
      def __ExecuteSummarize(self):
          """Read in test run results and summarize."""
  
          # If no results file is specified, use a default value.
          if len(self.__arguments) == 0:
!             results_path = self.results_file_name
          else:
              results_path = self.__arguments[0]
  
          database = self.GetDatabaseIfAvailable()
  
*************** Valid formats are %s.
*** 1451,1473 ****
              # Don't show any results by test suite though.
              filter = 0
  
          # Get an iterator over the results.
          try:
!             results = base.load_results(open(results_path, "rb"),
!                                         database)
          except (IOError, xml.sax.SAXException), exception:
              raise QMException, \
                    qm.error("invalid results file",
                             path=results_path,
                             problem=str(exception))
  
          any_unexpected_outcomes = 0
  
          # Compute the list of result streams to which output should be
          # written.
!         streams = self.__GetResultStreams()
  
          # Send the annotations through.
          for s in streams:
              s.WriteAllAnnotations(results.GetAnnotations())
  
--- 1452,1473 ----
              # Don't show any results by test suite though.
              filter = 0
  
          # Get an iterator over the results.
          try:
!             results = base.load_results(results_path, database)
          except (IOError, xml.sax.SAXException), exception:
              raise QMException, \
                    qm.error("invalid results file",
                             path=results_path,
                             problem=str(exception))
  
          any_unexpected_outcomes = 0
  
          # Compute the list of result streams to which output should be
          # written.
!         streams = self.__GetResultStreams(self.GetCommandOption("output"))
  
          # Send the annotations through.
          for s in streams:
              s.WriteAllAnnotations(results.GetAnnotations())
  
*************** Valid formats are %s.
*** 1627,1645 ****
              result_file_name = None
          else:
              result_file_name = self.GetCommandOption("output")
              if result_file_name is None:
                  # By default, write results to a default file.
!                 result_file_name = "results.qmr"
! 
!         if result_file_name is not None:
!             rs = (self.GetFileResultStreamClass()
!                   ({ "filename" : result_file_name}))
!             result_streams.append(rs)
  
          # Handle the --result-stream options.
!         result_streams.extend(self.__GetResultStreams())
  
          # Handle the --annotate options.
          for name, value in self.__GetAnnotateOptions().iteritems():
              for rs in result_streams:
                  rs.WriteAnnotation(name, value)
--- 1627,1640 ----
              result_file_name = None
          else:
              result_file_name = self.GetCommandOption("output")
              if result_file_name is None:
                  # By default, write results to a default file.
!                 result_file_name = self.results_file_name
  
          # Handle the --result-stream options.
!         result_streams.extend(self.__GetResultStreams(result_file_name))
  
          # Handle the --annotate options.
          for name, value in self.__GetAnnotateOptions().iteritems():
              for rs in result_streams:
                  rs.WriteAnnotation(name, value)
*************** Valid formats are %s.
*** 1802,1812 ****
              if not outcomes_file_name:
                  self.__expected_outcomes = {}
              else:
                  try:
                      self.__expected_outcomes \
!                          = base.load_outcomes(open(outcomes_file_name, "rb"),
                                                self.GetDatabaseIfAvailable())
                  except IOError, e:
                      raise qm.cmdline.CommandError, str(e)
  
          return self.__expected_outcomes
--- 1797,1807 ----
              if not outcomes_file_name:
                  self.__expected_outcomes = {}
              else:
                  try:
                      self.__expected_outcomes \
!                          = base.load_outcomes(outcomes_file_name,
                                                self.GetDatabaseIfAvailable())
                  except IOError, e:
                      raise qm.cmdline.CommandError, str(e)
  
          return self.__expected_outcomes
*************** Valid formats are %s.
*** 1825,1835 ****
          # The --rerun option indicates that only failing tests should
          # be rerun.
          rerun_file_name = self.GetCommandOption("rerun")
          if rerun_file_name:
              # Load the outcomes from the file specified.
!             outcomes = base.load_outcomes(open(rerun_file_name, "rb"),
                                            self.GetDatabase())
              expectations = self.__GetExpectedOutcomes()
              # We can avoid treating the no-expectation case as special
              # by creating an empty map.
              if expectations is None:
--- 1820,1830 ----
          # The --rerun option indicates that only failing tests should
          # be rerun.
          rerun_file_name = self.GetCommandOption("rerun")
          if rerun_file_name:
              # Load the outcomes from the file specified.
!             outcomes = base.load_outcomes(rerun_file_name,
                                            self.GetDatabase())
              expectations = self.__GetExpectedOutcomes()
              # We can avoid treating the no-expectation case as special
              # by creating an empty map.
              if expectations is None:
*************** Valid formats are %s.
*** 1855,1867 ****
              raise qm.cmdline.CommandError, \
                    qm.error("invalid extension kind",
                             kind = kind)
  
                         
!     def __GetResultStreams(self):
          """Return the result streams to use.
  
          returns -- A list of 'ResultStream' objects, as indicated by the
          user."""
  
          database = self.GetDatabaseIfAvailable()
  
--- 1850,1865 ----
              raise qm.cmdline.CommandError, \
                    qm.error("invalid extension kind",
                             kind = kind)
  
                         
!     def __GetResultStreams(self, output_file):
          """Return the result streams to use.
  
+         'output_file' -- If not 'None', the name of a file to which
+         the standard results file format should be written.
+         
          returns -- A list of 'ResultStream' objects, as indicated by the
          user."""
  
          database = self.GetDatabaseIfAvailable()
  
*************** Valid formats are %s.
*** 1896,1905 ****
--- 1894,1910 ----
              if opt == "result-stream":
                  ec, as = qm.extension.parse_descriptor(opt_arg, f)
                  as.update(arguments)
                  result_streams.append(ec(as))
  
+         # If there is an output file, create a standard results file on
+         # that file.
+         if output_file is not None:
+             rs = (self.GetFileResultStreamClass()
+                   ({ "filename" : output_file}))
+             result_streams.append(rs)
+ 
          return result_streams
      
  ########################################################################
  # Functions
  ########################################################################
Index: qm/test/report.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/report.py,v
retrieving revision 1.2
diff -c -5 -p -r1.2 report.py
*** qm/test/report.py	31 May 2005 15:48:37 -0000	1.2
--- qm/test/report.py	24 Oct 2005 07:13:52 -0000
*************** class ReportGenerator:
*** 92,112 ****
          returns -- A list of pairs of ResultStream / Expectation objects."""
  
          results = []
          for result_file, exp_file in input:
              try:
!                 result = base.load_results(open(result_file, "rb"), self.database)
              except IOError, e:
                  raise PythonException("Error reading '%s'"%result_file,
                                        IOError, e)
              except xml.sax.SAXException, e:
                  raise PythonException("Error loading '%s'"%result_file,
                                        xml.sax.SAXException, e)
              exp = {}
              if exp_file:
                  try:
!                     exp_reader = base.load_results(open(exp_file, "rb"),
                                                     self.database)
                      for e in exp_reader:
                          if e.GetKind() == Result.TEST:
                              outcome = e.GetOutcome()
                              cause = e.get('qmtest.cause')
--- 92,112 ----
          returns -- A list of pairs of ResultStream / Expectation objects."""
  
          results = []
          for result_file, exp_file in input:
              try:
!                 result = base.load_results(result_file, self.database)
              except IOError, e:
                  raise PythonException("Error reading '%s'"%result_file,
                                        IOError, e)
              except xml.sax.SAXException, e:
                  raise PythonException("Error loading '%s'"%result_file,
                                        xml.sax.SAXException, e)
              exp = {}
              if exp_file:
                  try:
!                     exp_reader = base.load_results(exp_file,
                                                     self.database)
                      for e in exp_reader:
                          if e.GetKind() == Result.TEST:
                              outcome = e.GetOutcome()
                              cause = e.get('qmtest.cause')
Index: qm/test/classes/dir_run_database.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/classes/dir_run_database.py,v
retrieving revision 1.1
diff -c -5 -p -r1.1 dir_run_database.py
*** qm/test/classes/dir_run_database.py	14 Sep 2005 13:24:46 -0000	1.1
--- qm/test/classes/dir_run_database.py	24 Oct 2005 07:13:52 -0000
*************** class DirRunDatabase(RunDatabase):
*** 46,56 ****
          self.__runs = []
          # Read through all the .qmr files.
          for f in glob(os.path.join(directory, "*.qmr")):
              try:
                  # Create the ResultReader corresponding to f.
!                 reader = base.load_results(open(f, 'rb'), database)
                  run = ReaderTestRun(reader)
              except:
                  # If anything goes wrong reading the file, just skip
                  # it.
                  continue
--- 46,56 ----
          self.__runs = []
          # Read through all the .qmr files.
          for f in glob(os.path.join(directory, "*.qmr")):
              try:
                  # Create the ResultReader corresponding to f.
!                 reader = base.load_results(f, database)
                  run = ReaderTestRun(reader)
              except:
                  # If anything goes wrong reading the file, just skip
                  # it.
                  continue
Index: qm/test/doc/manual.xml
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/doc/manual.xml,v
retrieving revision 1.10
diff -c -5 -p -r1.10 manual.xml
*** qm/test/doc/manual.xml	21 Jul 2005 10:49:16 -0000	1.10
--- qm/test/doc/manual.xml	24 Oct 2005 07:13:52 -0000
***************
*** 13,23 ****
    the Software Carpentry Open Publication License, which is available at:
  
      http://www.software-carpentry.com/openpub-license.html
  
  -->
! <!DOCTYPE book PUBLIC "-//OASIS//DTD DocBook XML V4.1.2//EN"
  [
    <!-- Internal DTD subset.  Only entities should be defined here. -->
  
    <!-- Include the QM common DTD module.  -->
  
--- 13,24 ----
    the Software Carpentry Open Publication License, which is available at:
  
      http://www.software-carpentry.com/openpub-license.html
  
  -->
! <!DOCTYPE book PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
!                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd"
  [
    <!-- Internal DTD subset.  Only entities should be defined here. -->
  
    <!-- Include the QM common DTD module.  -->
  
Index: qm/test/doc/reference.xml
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/doc/reference.xml,v
retrieving revision 1.45
diff -c -5 -p -r1.45 reference.xml
*** qm/test/doc/reference.xml	14 Oct 2005 18:12:46 -0000	1.45
--- qm/test/doc/reference.xml	24 Oct 2005 07:13:52 -0000
***************
*** 1532,1563 ****
        <term><option>-o</option> <replaceable>file</replaceable></term>
        <term>
         <option>&dashdash;output</option> <replaceable>file</replaceable> 
        </term>
        <listitem>
!        <para>Write full test results to <replaceable>file</replaceable>.
!        Specify "<literal>-</literal>" (a hyphen) to write results to
!        standard output.  If neither this option nor
!        <option>&dashdash;no-output</option> is specified, the results
!        are written to the file named <filename>results.qmr</filename>
!        in the current directory.</para>
        </listitem>
       </varlistentry>
  
       <varlistentry>
        <term><option>-O</option> <replaceable>file</replaceable></term>
        <term>
         <option>&dashdash;outcomes</option> <replaceable>file</replaceable>
        </term>
        <listitem>
         <para>Treat <replaceable>file</replaceable> as a set of
!        expected outcomes.  The <replaceable>file</replaceable> must
!        have be a results file created either by <command>&qmtest-cmd;
!        run</command>, or by saving results in the graphical user interface.
!        &qmtest; will expect the results of the current test run to
!        match those specified in the <replaceable>file</replaceable>
!        and will highlight differences from those results.</para>
        </listitem>
       </varlistentry> 
  
       <varlistentry>
        <term><option>&dashdash;random</option></term>
--- 1532,1570 ----
        <term><option>-o</option> <replaceable>file</replaceable></term>
        <term>
         <option>&dashdash;output</option> <replaceable>file</replaceable> 
        </term>
        <listitem>
!        <para>
!         Write full test results to <replaceable>file</replaceable>, in
!         QMTest's machine-readable file format.  Use a 
!         "<literal>-</literal>" (a hyphen) to write results to 
!         the standard output.  If neither this option nor
!         <option>&dashdash;no-output</option> is specified, the results
!         are written to the file named <filename>results.qmr</filename>
!         in the current directory.
!        </para>
        </listitem>
       </varlistentry>
  
       <varlistentry>
        <term><option>-O</option> <replaceable>file</replaceable></term>
        <term>
         <option>&dashdash;outcomes</option> <replaceable>file</replaceable>
        </term>
        <listitem>
         <para>Treat <replaceable>file</replaceable> as a set of
!        expected outcomes.  The <replaceable>file</replaceable> is
!        usually a results file created either by using the 
!        <command>&qmtest-cmd; run</command> or by saving results in the
!        graphical user interface.  If <replaceable>file</replaceable>
!        does not appear to be such a file, it is interpreted as an
!        extension descriptor, as described in <xref
!        linkend="sec-testcmd-create"/>.  QMTest will expect the results
!        of the current test run to match those specified in the
!        <replaceable>file</replaceable> and will highlight differences
!        from those results.</para>
        </listitem>
       </varlistentry> 
  
       <varlistentry>
        <term><option>&dashdash;random</option></term>
***************
*** 1661,1684 ****
      <cmdsynopsis>
       <command>&qmtest-cmd; summarize</command>
       <arg choice="opt" rep="repeat">
        <replaceable>option</replaceable>
       </arg>
!      <group choice="opt" rep="repeat">
!       <arg choice="plain"><replaceable>test-name</replaceable></arg>
!       <arg choice="plain"><replaceable>suite-name</replaceable></arg>
       </group>
      </cmdsynopsis>
     </section>
  
     <section>
      <title>Description</title>
!     <para>The <command>&qmtest-cmd; summarize</command> extracts
!     information stored in a results file and displays this information
!     on the console.  The information is formatted just as if the tests
!     had just been run, but &qmtest; does not actually run the
!     tests.</para>
  
      <para>The <command>summarize</command> command accepts the
      following options:</para>
  
      <variablelist>
--- 1668,1708 ----
      <cmdsynopsis>
       <command>&qmtest-cmd; summarize</command>
       <arg choice="opt" rep="repeat">
        <replaceable>option</replaceable>
       </arg>
!      <group choice="opt">
!       <arg choice="req"><replaceable>results-file</replaceable></arg>
!       <group choice="opt" rep="repeat">
!        <arg choice="plain"><replaceable>test-name</replaceable></arg>
!        <arg choice="plain"><replaceable>suite-name</replaceable></arg>
!       </group>
       </group>
      </cmdsynopsis>
     </section>
  
     <section>
      <title>Description</title>
!     <para>
!      The <command>&qmtest-cmd; summarize</command> extracts information
!      stored in the <replaceable>results-file</replaceable> (or
!      <filename>results.qmr</filename>, if no
!      <replaceable>results-file</replaceable> is specified) and displays
!      this information on the console.  The information is formatted
!      just as if the tests had been run with <command>qmtest
!      run</command>, but, instead of actually running the tests,
!      QMTest reads the results from the
!      <replaceable>results-file</replaceable>.
!     </para>
! 
!     <para>
!      If the <replaceable>results-file</replaceable> is not a valid
!      results file, it is interpreted as an extension descriptor,
!      as described in <xref linkend="sec-testcmd-create"/>.  You can
!      use the descriptor syntax to read results stored in formats that
!      are not &quot;built-in&quot; to QMTest.
!     </para>
  
      <para>The <command>summarize</command> command accepts the
      following options:</para>
  
      <variablelist>
***************
*** 1693,1702 ****
--- 1717,1741 ----
         <command>qmtest run</command> command.</para>
        </listitem>
       </varlistentry>
    
       <varlistentry>
+       <term><option>-o</option> <replaceable>file</replaceable></term>
+       <term>
+        <option>&dashdash;output</option> <replaceable>file</replaceable> 
+       </term>
+       <listitem>
+        <para>
+         Write full test results to <replaceable>file</replaceable>, in
+         QMTest's machine-readable file format.  Use a 
+         "<literal>-</literal>" (a hyphen) to write results to 
+         the standard output.
+        </para>
+       </listitem>
+      </varlistentry>
+ 
+      <varlistentry>
        <term><option>-O</option> <replaceable>file</replaceable></term>
        <term>
         <option>&dashdash;outcomes</option> <replaceable>file</replaceable>
        </term>
        <listitem>
