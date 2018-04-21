2005-10-23  Mark Mitchell  <mark@codesourcery.com>

	* qm/test/result_stream.py (qm.test.result.Result): Import it.
	(ResultStream._GetExpectedOutcome): New method.
	* qm/test/classes/text_result_stream.py
	(TextResultStream.WriteResult): Use it.
	(TextResultStream.DisplayResult): Treat Result.CAUSE annotation as
	HTML.

Index: qm/test/result_stream.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/result_stream.py,v
retrieving revision 1.10
diff -c -5 -p -r1.10 result_stream.py
*** qm/test/result_stream.py	24 Aug 2005 02:48:30 -0000	1.10
--- qm/test/result_stream.py	24 Oct 2005 05:50:28 -0000
***************
*** 18,27 ****
--- 18,28 ----
  ########################################################################
  
  import qm
  import qm.extension
  import qm.fields
+ from   qm.test.result import Result
  
  ########################################################################
  # classes
  ########################################################################
  
*************** class ResultStream(qm.extension.Extensio
*** 92,97 ****
  
          Derived class methods may override this method.  They should,
          however, invoke this version before returning."""
          
          pass
!         
--- 93,110 ----
  
          Derived class methods may override this method.  They should,
          however, invoke this version before returning."""
          
          pass
! 
! 
!     def _GetExpectedOutcome(self, test_id):
!         """Return the outcome expected for 'test_id'.
! 
!         returns -- The outcome (one of the elements of
!         'Result.outcomes') expected for 'test_id'.  The expected
!         outcome is taken from the 'expected_outcomes' provided when
!         constructing this result stream, if available.  If no expected
!         outcome is available the default value ('Result.PASS') will be
!         returned."""
! 
!         return self.expected_outcomes.get(test_id, Result.PASS)
Index: qm/test/classes/text_result_stream.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/classes/text_result_stream.py,v
retrieving revision 1.8
diff -c -5 -p -r1.8 text_result_stream.py
*** qm/test/classes/text_result_stream.py	31 Mar 2004 10:32:45 -0000	1.8
--- qm/test/classes/text_result_stream.py	24 Oct 2005 05:50:28 -0000
*************** class TextResultStream(FileResultStream)
*** 168,179 ****
              outcome = result.GetOutcome()
              self.__outcome_counts[outcome] += 1
              # Remember tests with unexpected results so that we can
              # display them at the end of the run.
              test_id = result.GetId()
!             expected_outcome \
!                 = self.expected_outcomes.get(result.GetId(), Result.PASS)
              if self.format != "stats" and outcome != expected_outcome:
                  self.__unexpected_outcome_counts[outcome] += 1
                  self.__unexpected_test_results.append(result)
          else:
              if (self.format != "stats"
--- 168,178 ----
              outcome = result.GetOutcome()
              self.__outcome_counts[outcome] += 1
              # Remember tests with unexpected results so that we can
              # display them at the end of the run.
              test_id = result.GetId()
!             expected_outcome = self._GetExpectedOutcome(result.GetId())
              if self.format != "stats" and outcome != expected_outcome:
                  self.__unexpected_outcome_counts[outcome] += 1
                  self.__unexpected_test_results.append(result)
          else:
              if (self.format != "stats"
*************** class TextResultStream(FileResultStream)
*** 382,393 ****
                  self._WriteOutcome(id_, kind, outcome)
          else:
              self._WriteOutcome(id_, kind, outcome)
  
          # Print the cause of the failure.
!         if result.has_key(Result.CAUSE):
!             self.file.write('    ' + result[Result.CAUSE] + '\n')
              
          self.file.write('\n')
  
  
      def _DisplayAnnotations(self, result):
--- 381,395 ----
                  self._WriteOutcome(id_, kind, outcome)
          else:
              self._WriteOutcome(id_, kind, outcome)
  
          # Print the cause of the failure.
!         cause = result.GetCause()
!         if cause:
!             cause = qm.common.html_to_text(cause)
!             for l in cause.splitlines():
!                 self.file.write("    " + l + "\n")
              
          self.file.write('\n')
  
  
      def _DisplayAnnotations(self, result):
