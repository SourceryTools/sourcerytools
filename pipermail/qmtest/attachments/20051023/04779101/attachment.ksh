2005-10-23  Mark Mitchell  <mark@codesourcery.com>

	* qm/test/result.py (Result.SetOutcome): Use SetCause.
	(Result.SetCause): New method.
	(Result.NoteException): Use SetCause.

Index: qm/test/result.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/result.py,v
retrieving revision 1.27
diff -c -5 -p -r1.27 result.py
*** qm/test/result.py	10 Jun 2005 20:55:25 -0000	1.27
--- qm/test/result.py	24 Oct 2005 05:43:39 -0000
*************** class Result:
*** 218,228 ****
          of annotations."""
  
          assert outcome in Result.outcomes
          self.__outcome = outcome
          if cause:
!             self[Result.CAUSE] = cause
          self.Annotate(annotations)
  
  
      def Annotate(self, annotations):
          """Add 'annotations' to the current set of annotations."""
--- 218,228 ----
          of annotations."""
  
          assert outcome in Result.outcomes
          self.__outcome = outcome
          if cause:
!             self.SetCause(cause)
          self.Annotate(annotations)
  
  
      def Annotate(self, annotations):
          """Add 'annotations' to the current set of annotations."""
*************** class Result:
*** 259,269 ****
          if self.has_key(Result.CAUSE):
              return self[Result.CAUSE]
          else:
              return ""
      
!         
      def Quote(self, string):
          """Return a version of string suitable for an annotation value.
  
          Performs appropriate quoting for a string that should be taken
          verbatim; this includes HTML entity escaping, and addition of
--- 259,278 ----
          if self.has_key(Result.CAUSE):
              return self[Result.CAUSE]
          else:
              return ""
      
! 
!     def SetCause(self, cause):
!         """Set the cause of failure.
! 
!         'cause' -- A string indicating the cause of failure.  Like all
!         annotations, 'cause' will be interested as HTML."""
! 
!         self[Result.CAUSE] = cause
! 
! 
      def Quote(self, string):
          """Return a version of string suitable for an annotation value.
  
          Performs appropriate quoting for a string that should be taken
          verbatim; this includes HTML entity escaping, and addition of
*************** class Result:
*** 310,321 ****
          # For a 'ContextException', indicate which context variable
          # was invalid.
          if exception_type is ContextException:
              self["qmtest.context_variable"] = exc_info[1].key
              
!         self.SetOutcome(outcome)
!         self[Result.CAUSE] = cause
          self[Result.EXCEPTION] \
              = self.Quote("%s: %s" % exc_info[:2])
          self[Result.TRACEBACK] \
              = self.Quote(qm.format_traceback(exc_info))
  
--- 319,329 ----
          # For a 'ContextException', indicate which context variable
          # was invalid.
          if exception_type is ContextException:
              self["qmtest.context_variable"] = exc_info[1].key
              
!         self.SetOutcome(outcome, cause)
          self[Result.EXCEPTION] \
              = self.Quote("%s: %s" % exc_info[:2])
          self[Result.TRACEBACK] \
              = self.Quote(qm.format_traceback(exc_info))
  
