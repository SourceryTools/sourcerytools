2005-10-24  Mark Mitchell  <mark@codesourcery.com>

	* qm/test/classes/dejagnu_stream.py (cgi): Import it.
	(re): Likewise.
	(sets.Set): Likewise.
	(DejaGNUReader): Add combined mode.  Add expectations-generation
	mode.

Index: qm/test/classes/dejagnu_stream.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/classes/dejagnu_stream.py,v
retrieving revision 1.3
diff -c -5 -p -r1.3 dejagnu_stream.py
*** qm/test/classes/dejagnu_stream.py	24 Aug 2005 02:48:30 -0000	1.3
--- qm/test/classes/dejagnu_stream.py	24 Oct 2005 07:25:44 -0000
***************
*** 15,29 ****
--- 15,32 ----
  
  ########################################################################
  # Imports
  ########################################################################
  
+ import cgi
  from   dejagnu_test import DejaGNUTest
  import qm.fields
  from   qm.test.file_result_stream import FileResultStream
  from   qm.test.result import Result
  from   qm.test.file_result_reader import FileResultReader
+ import re
+ from   sets import Set
  
  ########################################################################
  # Classes
  ########################################################################
  
*************** class DejaGNUReader(FileResultReader):
*** 142,164 ****
      Unfortunately, DejaGNU log files are relativley unstructured.
      Therefore, this result reader uses heuristics that may not always
      be 100% robust.  Therefore, for optimal behavior, DejaGNU
      testsuites should be converted to QMTest testsuites."""
  
      def __init__(self, arguments):
  
          # Initialize the base class.
          super(DejaGNUReader, self).__init__(arguments)
          # DejaGNU files start with "Test Run".
          if self.file.read(len("Test Run")) != "Test Run":
              raise FileResultReader.InvalidFile, \
                    "file is not a DejaGNU result stream"
          self.file.seek(0)
  
-         
      def GetResult(self):
  
          # Assume that there are no more results in the file.
          dejagnu_outcome = None
          # Scan ahead until we find a line that gives data about the
          # next result.
          while self.file:
--- 145,258 ----
      Unfortunately, DejaGNU log files are relativley unstructured.
      Therefore, this result reader uses heuristics that may not always
      be 100% robust.  Therefore, for optimal behavior, DejaGNU
      testsuites should be converted to QMTest testsuites."""
  
+     arguments = [
+         qm.fields.BooleanField(
+             name = "is_combined",
+             title = "Combined Format?",
+             description=\
+             """True if multiple results for the same test should be combined.
+ 
+             DejaGNU will sometimes print multiple results for the same
+             test.  For example, when testing a compiler, DejaGNU may
+             issue one result indicating whether or not a file was
+             successfully compiled and another result indicating
+             whether or not the file was successfully executed.  When
+             using the combined format, these two results will be treated as
+             subparts of a single test.  When not using the combined
+             format, these results will be treated as separate
+             tests.
+ 
+             The combined format is the default.  However, if you want
+             to see statistics that precisely match DejaGNU, you should
+             not use the combined format.""",
+             default_value="true",
+             ),
+         qm.fields.BooleanField(
+             name = "expectations",
+             title = "GenerateExpectations?",
+             description=\
+             """True if expected (not actual) results should be generated.
+ 
+             In this mode, the actual results will be ignored.
+             Instead, a results file indicated expected failures as
+             actual failures will be generated.""",
+             default_value="false",
+             ),
+         ]
+             
+     __id_regexp = re.compile("^[^:]*:[\\s]*(?P<id>[^\\s]*)")
+     """A regular expression for determining test names.
+ 
+     When applied to an outcome line from DejaGNU, this regular
+     expression's 'id' field gives the name of the test, in the
+     combined mode."""
+     
+     __cause_regexp = re.compile("\\((?P<cause>.*)\\)\\s*$")
+     """A regular expression for determining failure causes.
+ 
+     When applied to an outcome line from DejaGNU, this regular
+     expression's 'cause' field gives the cause of the failure."""
+     
      def __init__(self, arguments):
  
          # Initialize the base class.
          super(DejaGNUReader, self).__init__(arguments)
          # DejaGNU files start with "Test Run".
          if self.file.read(len("Test Run")) != "Test Run":
              raise FileResultReader.InvalidFile, \
                    "file is not a DejaGNU result stream"
          self.file.seek(0)
+         self.test_ids = Set()
+         if self.__UseCombinedMode():
+             test_id, dejagnu_outcome, cause = self.__NextOutcome()
+             if test_id:
+                 self.__next_result = Result(Result.TEST, test_id)
+                 self.__UpdateResult(self.__next_result,
+                                     dejagnu_outcome,
+                                     cause)
+ 
  
      def GetResult(self):
  
+         if self.__UseCombinedMode():
+             result = self.__next_result
+             if not result:
+                 return None
+             self.__next_result = None
+         else:
+             result = None
+         while True:
+             test_id, dejagnu_outcome, cause = self.__NextOutcome()
+             # If there are no more results, stop.
+             if not test_id:
+                 break
+             if self.__UseCombinedMode() and test_id != result.GetId():
+                 self.__next_result = Result(Result.TEST, test_id)
+                 self.__UpdateResult(self.__next_result,
+                                     dejagnu_outcome,
+                                     cause)
+                 break
+             elif not self.__UseCombinedMode():
+                 result = Result(Result.TEST, test_id)
+             self.__UpdateResult(result, dejagnu_outcome, cause)
+             if not self.__UseCombinedMode():
+                 break
+         return result
+ 
+ 
+     def __NextOutcome(self):
+         """The next DejaGNU outcome in the file.
+ 
+         returns -- A triplet ('test_id', 'outcome', 'cause').  The
+         'test_id' is the name of the test.  The 'outcome' is the
+         DejaGNU outcome (one of the 'DejaGNUTest.dejagnu_outcomes').
+         The 'cause' is a string giving the cause (if known) of
+         failure, if the test did not pass."""
+ 
          # Assume that there are no more results in the file.
          dejagnu_outcome = None
          # Scan ahead until we find a line that gives data about the
          # next result.
          while self.file:
*************** class DejaGNUReader(FileResultReader):
*** 178,190 ****
              if dejagnu_outcome:
                  break
          # If we could not find any more result lines, then we have
          # read all of the results in the file.
          if not dejagnu_outcome:
!             return None
          # Translate the DejaGNU outcome into a QMTest outcome.
!         qmtest_outcome = DejaGNUTest.outcome_map[dejagnu_outcome]
!         # The "name" of the test is the portion of the line following
!         # the colon.
!         test_id = line[len(dejagnu_outcome) + 2:].strip()
!         # Construct the result.
!         return Result(Result.TEST, test_id, qmtest_outcome)
--- 272,362 ----
              if dejagnu_outcome:
                  break
          # If we could not find any more result lines, then we have
          # read all of the results in the file.
          if not dejagnu_outcome:
!             return None, None, None
!         # Extract the name of the test.
!         if self.__UseCombinedMode():
!             match = self.__id_regexp.search(line)
!             test_id = match.group("id")
!         else:
!             test_id = line[len(dejagnu_outcome) + 2:].strip()
!         # Extract the cause of faiulre.
!         cause = None
!         if "execution test" in line:
!             cause = "Compiled program behaved incorrectly."
!         else:
!             match = self.__cause_regexp.search(line)
!             if match:
!                 cause = match.group("cause").capitalize()
!                 if cause and cause[-1] != ".":
!                     cause += "."
!             elif dejagnu_outcome == DejaGNUTest.UNSUPPORTED:
!                 cause = "Test is not applicable on this platform."
!         return test_id, dejagnu_outcome, cause
!         
!     
!     def __UpdateResult(self, result, dejagnu_outcome, cause):
!         """Update 'result' as indicated.
! 
!         'result' -  A 'Result', which may contain information from
!         previous DejaGNU tests, in the combined mode.
! 
!         'dejagnu_outcome' -- The DejaGNU outcome (one of the
!         'DejaGNUTest.dejagnu_outcomes') that applies to this
!         'result'.
! 
!         'cause' -- The cause of failure, if known.
! 
!         The 'result' is modified to reflect the new outcome and
!         cause.  Results can only get worse, in the sense that if
!         reuslt has an outcome of 'Result.FAIL' upon entry to this
!         return, it will never have an outcome of 'Result.PASS' upon
!         return."""
!                        
          # Translate the DejaGNU outcome into a QMTest outcome.
!         if self.__GenerateExpectations():
!             if dejagnu_outcome in (DejaGNUTest.XFAIL,
!                                    DejaGNUTest.XPASS):
!                 qmtest_outcome = Result.FAIL
!             elif dejagnu_outcome == DejaGNUTest.UNSUPPORTED:
!                 qmtest_outcome = Result.UNTESTED
!             else:
!                 qmtest_outcome = Result.PASS
!         else:
!             qmtest_outcome = DejaGNUTest.outcome_map[dejagnu_outcome]
!         # Update the QMTest result for this test, based on the
!         # DejaGNU result.
!         if qmtest_outcome == Result.ERROR:
!             result.SetOutcome(Result.ERROR)
!         elif (qmtest_outcome == Result.UNTESTED
!               and result.GetOutcome() != Result.ERROR):
!             result.SetOutcome(Result.UNTESTED)
!         elif (qmtest_outcome == Result.FAIL
!               and result.GetOutcome() not in (Result.ERROR,
!                                               Result.UNTESTED)):
!             result.SetOutcome(Result.FAIL)
!         if qmtest_outcome != Result.PASS and cause:
!             old_cause = result.GetCause()
!             if old_cause:
!                 old_cause = "  "
!             old_cause += cgi.escape(cause)
!             result.SetCause(old_cause)
! 
! 
!     def __UseCombinedMode(self):
!         """Returns true in the combined mode.
! 
!         returns -- True iff results should be read in the combined
!         mode."""
! 
!         return self.is_combined == "true"
! 
! 
!     def __GenerateExpectations(self):
!         """Returns true if expected results should be generated.
! 
!         returns -- True iff the results generated should reflect
!         expectations, rather than actual results."""
! 
!         return self.expectations == "true"
