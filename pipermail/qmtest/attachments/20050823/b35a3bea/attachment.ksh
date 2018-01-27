2005-08-23  Mark Mitchell  <mark@codesourcery.com>

	* qm/test/base.py (FileResultReader): Import it.
	(get_extension_classes): New function.
	(load_results): Let FileResultReaders decided if they understand
	the file format, rather than hard-coding the decision here.
	* qm/test/cmdline.py (QMTest.GetDatabaseIfAvailable): New method.
	Use it throughout, where appropriate.
	(QMTest.__ExecuteSummarize): Permit execution without a database.
	(QMTest.__GetResultStreams): Likewise.
	* qm/test/file_result_reader.py (FileResultReader.InvalidFile):
	New class.
	* qm/test/result_stream.py (ResultStream.arguments): Remove unused
	"database" argument.
	* qm/test/classes/classes.qmc: Add dejagnu_stream.DejaGNUReader.
	* qm/test/classes/dejagnu_test.py (DejaGNUTest.ERROR): Fix typo.
	(DejaGNUTest.__outcome_map): Rename to ...
	(DejaGNUTest.outcome_map): ... this.  Fill in all entries.
	(DejaGNUTest._RecordDejaGNUOutcome): Adjust.
	* qm/test/classes/pickle_result_stream.py
	(PickleResultReader.__init__): Raise InvalidFile if appropriate.
	* qm/test/classes/xml_result_stream.py (XMLResultReader.__init__):
	Likewise.
	* qm/test/classes/dejagnu_stream.py (DejaGNUReader): New class.

Index: qm/test/base.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/base.py,v
retrieving revision 1.100
diff -c -5 -p -r1.100 base.py
*** qm/test/base.py	13 Jun 2005 22:41:18 -0000	1.100
--- qm/test/base.py	24 Aug 2005 02:47:14 -0000
*************** import cPickle
*** 21,30 ****
--- 21,31 ----
  import cStringIO
  import os
  import qm
  import qm.attachment
  from   qm.common import *
+ from   qm.test.file_result_reader import FileResultReader
  import qm.platform
  import qm.structured_text
  from   qm.test.context import *
  from   qm.test.result import *
  import qm.xmlutil
*************** def load_outcomes(file, database):
*** 325,359 ****
          if r.GetKind() == Result.TEST:
              outcomes[r.GetId()] = r.GetOutcome()
      return outcomes
  
  
  def load_results(file, database):
      """Read test results from a file.
  
      'file' -- The file object from which to read the results.
  
      'database' -- The current database.
  
!     returns -- A 'ResultReader' object."""
  
!     # For backwards compatibility, look at the first few bytes of the
!     # file to see if it is an XML results file.
!     tag = file.read(5)
!     file.seek(0)
!     
!     if tag == "<?xml":
!         reader_cls = \
!          get_extension_class("xml_result_stream.XMLResultReader",
!                              "result_reader",
!                              database)
!     else:
!         reader_cls = \
!          get_extension_class("pickle_result_stream.PickleResultReader",
!                              "result_reader",
!                              database)
!     return reader_cls({"file": file})
  
  
  def _result_from_dom(node):
      """Extract a result from a DOM node.
  
--- 326,379 ----
          if r.GetKind() == Result.TEST:
              outcomes[r.GetId()] = r.GetOutcome()
      return outcomes
  
  
+ def get_extension_classes(kind, database = None):
+     """Return the extension classes for the given 'kind'.
+ 
+     'kind' -- The kind of extensions being sought.  The value must be
+     one of the 'extension_kinds'.
+ 
+     'database' -- If not 'None', the test 'Database' in use.
+ 
+     returns -- A list of the available extension classes of the
+     indicated 'kind'."""
+ 
+     classes = []
+     directories = get_extension_directories(kind, database)
+     for d in directories:
+         names = get_extension_class_names_in_directory(d)[kind]
+         d_classes = [get_extension_class_from_directory(n, kind, d,
+                                                         directories)
+                      for n in names]
+         classes.extend(d_classes)
+ 
+     return classes
+     
+     
  def load_results(file, database):
      """Read test results from a file.
  
      'file' -- The file object from which to read the results.
  
      'database' -- The current database.
  
!     returns -- A 'ResultReader' object, or raises an exception if no
!     appropriate reader is available."""
  
!     # Find the first FileResultStream that will accept this file.
!     for c in get_extension_classes("result_reader", database):
!         if issubclass(c, FileResultReader):
!             try:
!                 return c({"file" : file})
!             except FileResultReader.InvalidFile:
!                 # Go back to the beginning of the file.
!                 file.seek(0)
!         
!     raise FileResultReader.InvalidFile, \
!           "not a valid results file"
  
  
  def _result_from_dom(node):
      """Extract a result from a DOM node.
  
Index: qm/test/cmdline.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/cmdline.py,v
retrieving revision 1.110
diff -c -5 -p -r1.110 cmdline.py
*** qm/test/cmdline.py	22 Jul 2005 18:03:04 -0000	1.110
--- qm/test/cmdline.py	24 Aug 2005 02:47:15 -0000
*************** Valid formats are %s.
*** 723,737 ****
  
          return method()
  
  
      def GetDatabase(self):
!         """Return the test database to use."""
  
          return database.get_database()
  
  
      def GetTargetFileName(self):
          """Return the path to the file containing target specifications.
  
          returns -- The path to the file containing target specifications."""
  
--- 723,752 ----
  
          return method()
  
  
      def GetDatabase(self):
!         """Return the test database to use.
! 
!         returns -- The 'Database' to use for this execution.  Raises an
!         exception if no 'Database' is available."""
  
          return database.get_database()
  
  
+     def GetDatabaseIfAvailable(self):
+         """Return the test database to use.
+ 
+         returns -- The 'Database' to use for this execution, or 'None'
+         if no 'Database' is available."""
+ 
+         try:
+             return self.GetDatabase()
+         except:
+             return None
+ 
+     
      def GetTargetFileName(self):
          """Return the path to the file containing target specifications.
  
          returns -- The path to the file containing target specifications."""
  
*************** Valid formats are %s.
*** 881,901 ****
  
          returns -- The 'ResultStream' class used for results files."""
  
          return get_extension_class(self.__file_result_stream_class_name,
                                     "result_stream",
!                                    self.GetDatabase())
  
      def GetTextResultStreamClass(self):
          """Return the 'ResultStream' class used for textual feedback.
  
          returns -- the 'ResultStream' class used for textual
          feedback."""
  
          return get_extension_class(self.__text_result_stream_class_name,
                                     "result_stream",
!                                    self.GetDatabase())
          
  
      def __GetAttributeOptions(self):
          """Return the attributes specified on the command line.
  
--- 896,916 ----
  
          returns -- The 'ResultStream' class used for results files."""
  
          return get_extension_class(self.__file_result_stream_class_name,
                                     "result_stream",
!                                    self.GetDatabaseIfAvailable())
  
      def GetTextResultStreamClass(self):
          """Return the 'ResultStream' class used for textual feedback.
  
          returns -- the 'ResultStream' class used for textual
          feedback."""
  
          return get_extension_class(self.__text_result_stream_class_name,
                                     "result_stream",
!                                    self.GetDatabaseIfAvailable())
          
  
      def __GetAttributeOptions(self):
          """Return the attributes specified on the command line.
  
*************** Valid formats are %s.
*** 922,935 ****
          if len(self.__arguments) != 2:
              self.__WriteCommandHelp("create")
              return 2
  
          # Figure out what database (if any) we are using.
!         try:
!             database = self.GetDatabase()
!         except:
!             database = None
          
          # Get the extension kind.
          kind = self.__arguments[0]
          self.__CheckExtensionKind(kind)
  
--- 937,947 ----
          if len(self.__arguments) != 2:
              self.__WriteCommandHelp("create")
              return 2
  
          # Figure out what database (if any) we are using.
!         database = self.GetDatabaseIfAvailable()
          
          # Get the extension kind.
          kind = self.__arguments[0]
          self.__CheckExtensionKind(kind)
  
*************** Valid formats are %s.
*** 1100,1116 ****
  
          # Check that the right number of arguments are present.
          if len(self.__arguments) != 0:
              self.__WriteCommandHelp("extensions")
              return 2
!             
!         try:
!             database = self.GetDatabase()
!         except:
!             # If the database could not be opened that's OK; this
!             # command can be used without a database.
!             database = None
  
          # Figure out what kinds of extensions we're going to list.
          kind = self.GetCommandOption("kind")
          if kind:
              self.__CheckExtensionKind(kind)
--- 1112,1123 ----
  
          # Check that the right number of arguments are present.
          if len(self.__arguments) != 0:
              self.__WriteCommandHelp("extensions")
              return 2
! 
!         database = self.GetDatabaseIfAvailable()
  
          # Figure out what kinds of extensions we're going to list.
          kind = self.GetCommandOption("kind")
          if kind:
              self.__CheckExtensionKind(kind)
*************** Valid formats are %s.
*** 1229,1242 ****
                             class_name = class_name)
          module, name = class_name.split('.')
  
          # Try to load the database.  It may provide additional
          # directories to search.
!         try:
!             database = self.GetDatabase()
!         except:
!             database = None
          # Hunt through all of the extension class directories looking
          # for an appropriately named module.
          found = None
          directories = get_extension_directories(kind, database,
                                                  self.__db_path)
--- 1236,1246 ----
                             class_name = class_name)
          module, name = class_name.split('.')
  
          # Try to load the database.  It may provide additional
          # directories to search.
!         database = self.GetDatabaseIfAvailable()
          # Hunt through all of the extension class directories looking
          # for an appropriately named module.
          found = None
          directories = get_extension_directories(kind, database,
                                                  self.__db_path)
*************** Valid formats are %s.
*** 1311,1329 ****
          if len(self.__arguments) == 0:
              results_path = "results.qmr"
          else:
              results_path = self.__arguments[0]
  
          # The remaining arguments, if any, are test and suite IDs.
          id_arguments = self.__arguments[1:]
          # Are there any?
          if len(id_arguments) > 0:
              filter = 1
              # Expand arguments into test IDs.
              try:
!                 test_ids, suite_ids \
!                           = self.GetDatabase().ExpandIds(id_arguments)
              except (qm.test.database.NoSuchTestError,
                      qm.test.database.NoSuchSuiteError), exception:
                  raise qm.cmdline.CommandError, \
                        qm.error("no such ID", id=str(exception))
              except ValueError, exception:
--- 1315,1337 ----
          if len(self.__arguments) == 0:
              results_path = "results.qmr"
          else:
              results_path = self.__arguments[0]
  
+         database = self.GetDatabaseIfAvailable()
+ 
          # The remaining arguments, if any, are test and suite IDs.
          id_arguments = self.__arguments[1:]
          # Are there any?
          if len(id_arguments) > 0:
              filter = 1
              # Expand arguments into test IDs.
              try:
!                 if database:
!                     test_ids = database.ExpandIds(id_arguments)[0]
!                 else:
!                     test_ids = id_arguments
              except (qm.test.database.NoSuchTestError,
                      qm.test.database.NoSuchSuiteError), exception:
                  raise qm.cmdline.CommandError, \
                        qm.error("no such ID", id=str(exception))
              except ValueError, exception:
*************** Valid formats are %s.
*** 1331,1346 ****
                        qm.error("no such ID", id=str(exception))
          else:
              # No IDs specified.  Show all test and resource results.
              # Don't show any results by test suite though.
              filter = 0
-             suite_ids = []
  
          # Get an iterator over the results.
          try:
              results = base.load_results(open(results_path, "rb"),
!                                         self.GetDatabase())
          except (IOError, xml.sax.SAXException), exception:
              raise QMException, \
                    qm.error("invalid results file",
                             path=results_path,
                             problem=str(exception))
--- 1339,1353 ----
                        qm.error("no such ID", id=str(exception))
          else:
              # No IDs specified.  Show all test and resource results.
              # Don't show any results by test suite though.
              filter = 0
  
          # Get an iterator over the results.
          try:
              results = base.load_results(open(results_path, "rb"),
!                                         database)
          except (IOError, xml.sax.SAXException), exception:
              raise QMException, \
                    qm.error("invalid results file",
                             path=results_path,
                             problem=str(exception))
*************** Valid formats are %s.
*** 1348,1358 ****
          any_unexpected_outcomes = 0
  
          # Compute the list of result streams to which output should be
          # written.
          streams = self.__GetResultStreams()
!         
          # Send the annotations through.
          for s in streams:
              s.WriteAllAnnotations(results.GetAnnotations())
  
          # Get the expected outcomes.
--- 1355,1365 ----
          any_unexpected_outcomes = 0
  
          # Compute the list of result streams to which output should be
          # written.
          streams = self.__GetResultStreams()
! 
          # Send the annotations through.
          for s in streams:
              s.WriteAllAnnotations(results.GetAnnotations())
  
          # Get the expected outcomes.
*************** Valid formats are %s.
*** 1447,1460 ****
              self.__WriteCommandHelp("report")
              return 2
  
          # If the database can be loaded, use it to find all
          # available tests.
!         try:
!             database = self.GetDatabase()
!         except:
!             database = None
  
          report_generator = ReportGenerator(output, database)
          report_generator.GenerateReport(self.__arguments)
          
  
--- 1454,1464 ----
              self.__WriteCommandHelp("report")
              return 2
  
          # If the database can be loaded, use it to find all
          # available tests.
!         database = self.GetDatabaseIfAvailable()
  
          report_generator = ReportGenerator(output, database)
          report_generator.GenerateReport(self.__arguments)
          
  
*************** Valid formats are %s.
*** 1671,1681 ****
                  self.__expected_outcomes = {}
              else:
                  try:
                      self.__expected_outcomes \
                           = base.load_outcomes(open(outcomes_file_name, "rb"),
!                                               self.GetDatabase())
                  except IOError, e:
                      raise qm.cmdline.CommandError, str(e)
  
          return self.__expected_outcomes
          
--- 1675,1685 ----
                  self.__expected_outcomes = {}
              else:
                  try:
                      self.__expected_outcomes \
                           = base.load_outcomes(open(outcomes_file_name, "rb"),
!                                               self.GetDatabaseIfAvailable())
                  except IOError, e:
                      raise qm.cmdline.CommandError, str(e)
  
          return self.__expected_outcomes
          
*************** Valid formats are %s.
*** 1729,1745 ****
          """Return the result streams to use.
  
          returns -- A list of 'ResultStream' objects, as indicated by the
          user."""
  
!         database = self.GetDatabase()
  
          result_streams = []
  
          arguments = {
              "expected_outcomes" : self.__GetExpectedOutcomes(),
-             "database" : database,
              }
          
          # Look up the summary format.
          format = self.GetCommandOption("format", "")
          if format and format not in self.summary_formats:
--- 1733,1748 ----
          """Return the result streams to use.
  
          returns -- A list of 'ResultStream' objects, as indicated by the
          user."""
  
!         database = self.GetDatabaseIfAvailable()
  
          result_streams = []
  
          arguments = {
              "expected_outcomes" : self.__GetExpectedOutcomes(),
              }
          
          # Look up the summary format.
          format = self.GetCommandOption("format", "")
          if format and format not in self.summary_formats:
Index: qm/test/file_result_reader.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/file_result_reader.py,v
retrieving revision 1.1
diff -c -5 -p -r1.1 file_result_reader.py
*** qm/test/file_result_reader.py	3 Jul 2003 19:32:04 -0000	1.1
--- qm/test/file_result_reader.py	24 Aug 2005 02:47:15 -0000
***************
*** 15,25 ****
  
  ########################################################################
  # Imports
  ########################################################################
  
! import qm.fields
  from qm.test.result_reader import ResultReader
  import sys
  
  ########################################################################
  # Classes
--- 15,26 ----
  
  ########################################################################
  # Imports
  ########################################################################
  
! from qm.fields import TextField, PythonField
! from qm.common import QMException
  from qm.test.result_reader import ResultReader
  import sys
  
  ########################################################################
  # Classes
*************** class FileResultReader(ResultReader):
*** 32,63 ****
      reader classes that read results from a single file.  The file
      from which results should be read can be specified using either
      the 'filename' argument or the 'file' argument.  The latter is for
      use by QMTest internally."""
  
  
      arguments = [
!         qm.fields.TextField(
              name = "filename",
              title = "File Name",
              description = """The name of the file.
  
              All results will be read from the file indicated.  If no
              filename is specified, or the filename specified is "-",
              the standard input will be used.""",
              verbatim = "true",
              default_value = ""),
!         qm.fields.PythonField(
              name = "file"),
      ]
  
      _is_binary_file = 0
!     """If true, the file written is a binary file.
  
      This flag can be overridden by derived classes."""
      
      def __init__(self, arguments):
  
          super(FileResultReader, self).__init__(arguments)
  
          if not self.file:
              if self.filename and self.filename != "-":
--- 33,80 ----
      reader classes that read results from a single file.  The file
      from which results should be read can be specified using either
      the 'filename' argument or the 'file' argument.  The latter is for
      use by QMTest internally."""
  
+     class InvalidFile(QMException):
+         """An 'InvalidFile' exception indicates an incorrect file format.
  
+         If the constructor for a 'FileResultStream' detects an invalid
+         file, it must raise an instance of this exception."""
+ 
+         pass
+ 
+         
+     
      arguments = [
!         TextField(
              name = "filename",
              title = "File Name",
              description = """The name of the file.
  
              All results will be read from the file indicated.  If no
              filename is specified, or the filename specified is "-",
              the standard input will be used.""",
              verbatim = "true",
              default_value = ""),
!         PythonField(
              name = "file"),
      ]
  
      _is_binary_file = 0
!     """If true, results are stored in a binary format.
  
      This flag can be overridden by derived classes."""
      
      def __init__(self, arguments):
+         """Construct a new 'FileResultReader'.
+ 
+         'arguments' -- As for 'ResultReader'.
+ 
+         If the file provided is not in the input format expected by this
+         result reader, the derived class '__init__' function must raise
+         an 'InvalidStream' exception."""
  
          super(FileResultReader, self).__init__(arguments)
  
          if not self.file:
              if self.filename and self.filename != "-":
Index: qm/test/result_stream.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/result_stream.py,v
retrieving revision 1.9
diff -c -5 -p -r1.9 result_stream.py
*** qm/test/result_stream.py	23 Jun 2005 14:07:31 -0000	1.9
--- qm/test/result_stream.py	24 Aug 2005 02:47:15 -0000
*************** class ResultStream(qm.extension.Extensio
*** 40,51 ****
      kind = "result_stream"
  
      arguments = [
          qm.fields.PythonField(
             name = "expected_outcomes"),
-         qm.fields.PythonField(
-            name = "database"),
          ]
      
      def WriteAnnotation(self, key, value):
          """Output an annotation for this run.
  
--- 40,49 ----
Index: qm/test/classes/classes.qmc
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/classes/classes.qmc,v
retrieving revision 1.19
diff -c -5 -p -r1.19 classes.qmc
*** qm/test/classes/classes.qmc	13 Jun 2005 22:41:19 -0000	1.19
--- qm/test/classes/classes.qmc	24 Aug 2005 02:47:15 -0000
***************
*** 1,7 ****
--- 1,8 ----
  <?xml version="1.0" ?>
  <class-directory>
+  <class kind="result_reader" name="dejagnu_stream.DejaGNUReader"/>
   <class kind="result_reader" name="pickle_result_stream.PickleResultReader"/>
   <class kind="result_reader" name="sql_result_stream.SQLResultReader"/>
   <class kind="result_reader" name="xml_result_stream.XMLResultReader"/>
   <class kind="result_stream" name="dejagnu_stream.DejaGNUStream"/>
   <class kind="result_stream" name="pickle_result_stream.PickleResultStream"/>
Index: qm/test/classes/dejagnu_test.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/classes/dejagnu_test.py,v
retrieving revision 1.4
diff -c -5 -p -r1.4 dejagnu_test.py
*** qm/test/classes/dejagnu_test.py	15 Mar 2004 23:31:36 -0000	1.4
--- qm/test/classes/dejagnu_test.py	24 Aug 2005 02:47:15 -0000
*************** class DejaGNUTest(Test, DejaGNUBase):
*** 45,71 ****
      PASS = "PASS"
      FAIL = "FAIL"
      XPASS = "XPASS"
      XFAIL = "XFAIL"
      WARNING = "WARNING"
!     ERROR = "ERROR",
      UNTESTED = "UNTESTED"
      UNRESOLVED = "UNRESOLVED"
      UNSUPPORTED = "UNSUPPORTED"
  
      dejagnu_outcomes = (
          PASS, FAIL, XPASS, XFAIL, WARNING, ERROR, UNTESTED,
          UNRESOLVED, UNSUPPORTED
          )
      """The DejaGNU test outcomes."""
      
!     __outcome_map = {
!         PASS : None,
          FAIL : Result.FAIL,
!         XPASS : None,
          XFAIL : Result.FAIL,
!         WARNING : None,
          ERROR : Result.ERROR,
          UNTESTED : Result.UNTESTED,
          UNRESOLVED : Result.UNTESTED,
          UNSUPPORTED : Result.UNTESTED
          }
--- 45,71 ----
      PASS = "PASS"
      FAIL = "FAIL"
      XPASS = "XPASS"
      XFAIL = "XFAIL"
      WARNING = "WARNING"
!     ERROR = "ERROR"
      UNTESTED = "UNTESTED"
      UNRESOLVED = "UNRESOLVED"
      UNSUPPORTED = "UNSUPPORTED"
  
      dejagnu_outcomes = (
          PASS, FAIL, XPASS, XFAIL, WARNING, ERROR, UNTESTED,
          UNRESOLVED, UNSUPPORTED
          )
      """The DejaGNU test outcomes."""
      
!     outcome_map = {
!         PASS : Result.PASS,
          FAIL : Result.FAIL,
!         XPASS : Result.PASS,
          XFAIL : Result.FAIL,
!         WARNING : Result.PASS,
          ERROR : Result.ERROR,
          UNTESTED : Result.UNTESTED,
          UNRESOLVED : Result.UNTESTED,
          UNSUPPORTED : Result.UNTESTED
          }
*************** class DejaGNUTest(Test, DejaGNUBase):
*** 200,211 ****
          # Create an annotation corresponding to the DejaGNU outcome.
          key = "%s%d" % (self.RESULT_PREFIX, self.__next_result)
          self.__next_result += 1
          result[key] = outcome + ": " + message
          # If the test was passing until now, give it a new outcome.
!         new_outcome = self.__outcome_map[outcome]
!         if (new_outcome and result.GetOutcome() == Result.PASS):
              result.SetOutcome(new_outcome)
              result[Result.CAUSE] = message
          
  
      def _Unresolved(self, result, message):
--- 200,213 ----
          # Create an annotation corresponding to the DejaGNU outcome.
          key = "%s%d" % (self.RESULT_PREFIX, self.__next_result)
          self.__next_result += 1
          result[key] = outcome + ": " + message
          # If the test was passing until now, give it a new outcome.
!         new_outcome = self.outcome_map[outcome]
!         if (new_outcome
!             and new_outcome != Result.PASS
!             and result.GetOutcome() == Result.PASS):
              result.SetOutcome(new_outcome)
              result[Result.CAUSE] = message
          
  
      def _Unresolved(self, result, message):
Index: qm/test/classes/pickle_result_stream.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/classes/pickle_result_stream.py,v
retrieving revision 1.8
diff -c -5 -p -r1.8 pickle_result_stream.py
*** qm/test/classes/pickle_result_stream.py	31 Mar 2004 10:32:45 -0000	1.8
--- qm/test/classes/pickle_result_stream.py	24 Aug 2005 02:47:15 -0000
*************** class PickleResultReader(FileResultReade
*** 185,196 ****
  
          # Check for a version number
          try:
              version = self.__unpickler.load()
          except (EOFError, cPickle.UnpicklingError):
!             # This file is empty, no more handling needed.
!             return
          
          if not isinstance(version, int):
              # Version 0 file, no version number; in fact, we're
              # holding a 'Result'.  So we have no metadata to load and
              # should just rewind.
--- 185,196 ----
  
          # Check for a version number
          try:
              version = self.__unpickler.load()
          except (EOFError, cPickle.UnpicklingError):
!             raise FileResultReader.InvalidFile, \
!                   "file is not a pickled result stream"
          
          if not isinstance(version, int):
              # Version 0 file, no version number; in fact, we're
              # holding a 'Result'.  So we have no metadata to load and
              # should just rewind.
Index: qm/test/classes/xml_result_stream.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/classes/xml_result_stream.py,v
retrieving revision 1.6
diff -c -5 -p -r1.6 xml_result_stream.py
*** qm/test/classes/xml_result_stream.py	2 Oct 2003 16:23:22 -0000	1.6
--- qm/test/classes/xml_result_stream.py	24 Aug 2005 02:47:15 -0000
*************** class XMLResultReader(FileResultReader):
*** 86,95 ****
--- 86,102 ----
  
      def __init__(self, arguments):
  
          super(XMLResultReader, self).__init__(arguments)
  
+         # Make sure that this file really is an XML result stream.
+         tag = self.file.read(5)
+         if tag != "<?xml":
+             raise FileResultReader.InvalidFile, \
+                   "file is not an XML result stream"
+         self.file.seek(0)
+ 
          document = qm.xmlutil.load_xml(self.file)
          node = document.documentElement
          results = node.getElementsByTagName("result")
          self.__node_iterator = iter(results)
  
Index: qm/test/classes/dejagnu_stream.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/classes/dejagnu_stream.py,v
retrieving revision 1.2
diff -c -5 -p -r1.2 dejagnu_stream.py
*** qm/test/classes/dejagnu_stream.py	2 Jun 2003 23:49:47 -0000	1.2
--- qm/test/classes/dejagnu_stream.py	24 Aug 2005 02:47:15 -0000
***************
*** 18,27 ****
--- 18,29 ----
  ########################################################################
  
  from   dejagnu_test import DejaGNUTest
  import qm.fields
  from   qm.test.file_result_stream import FileResultStream
+ from   qm.test.result import Result
+ from   qm.test.file_result_reader import FileResultReader
  
  ########################################################################
  # Classes
  ########################################################################
  
*************** class DejaGNUStream(FileResultStream):
*** 123,127 ****
--- 125,190 ----
                  desc = "# of %s" % self.__outcome_descs[o]
                  self.file.write(desc)
                  if len(desc) < 24:
                      self.file.write("\t")
                  self.file.write("\t%d\n" % self.__outcomes[o])
+ 
+ 
+ 
+ class DejaGNUReader(FileResultReader):
+     """A 'DejaGNUReader' reads a DejaGNU log file.
+ 
+     The DejaGNU log file may then be processed by QMTest.  For
+     example, QMTest may generate results in an alternative format, or
+     display them in the QMTest GUI.  Therefore, this reader may be
+     used to obtain the benefits of QMTest's reporting characteristics,
+     when using a legacy DejaGNU testsuite.
+ 
+     Unfortunately, DejaGNU log files are relativley unstructured.
+     Therefore, this result reader uses heuristics that may not always
+     be 100% robust.  Therefore, for optimal behavior, DejaGNU
+     testsuites should be converted to QMTest testsuites."""
+ 
+     def __init__(self, arguments):
+ 
+         # Initialize the base class.
+         super(DejaGNUReader, self).__init__(arguments)
+         # DejaGNU files start with "Test Run".
+         if self.file.read(len("Test Run")) != "Test Run":
+             raise FileResultReader.InvalidFile, \
+                   "file is not a DejaGNU result stream"
+         self.file.seek(0)
+ 
+         
+     def GetResult(self):
+ 
+         # Assume that there are no more results in the file.
+         dejagnu_outcome = None
+         # Scan ahead until we find a line that gives data about the
+         # next result.
+         while self.file:
+             # Read the next line of the file.
+             line = self.file.next()
+             # Each test result is printed on a line by itself,
+             # beginning with the DejaGNU outcome.  For example:
+             #   PASS: g++.dg/compat/eh/template1 cp_compat_y_tst.o compile
+             dejagnu_outcome = None
+             for o in DejaGNUTest.dejagnu_outcomes:
+                 # Ignore WARNING; those are not really test results.
+                 if o != DejaGNUTest.WARNING and line.startswith(o):
+                     o_len = len(o)
+                     if line[o_len:o_len + 2] == ": ":
+                         dejagnu_outcome = o
+                     break
+             if dejagnu_outcome:
+                 break
+         # If we could not find any more result lines, then we have
+         # read all of the results in the file.
+         if not dejagnu_outcome:
+             return None
+         # Translate the DejaGNU outcome into a QMTest outcome.
+         qmtest_outcome = DejaGNUTest.outcome_map[dejagnu_outcome]
+         # The "name" of the test is the portion of the line following
+         # the colon.
+         test_id = line[len(dejagnu_outcome) + 2:].strip()
+         # Construct the result.
+         return Result(Result.TEST, test_id, qmtest_outcome)
