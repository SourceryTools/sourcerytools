2005-10-25  Mark Mitchell  <mark@codesourcery.com>

	* qm/test/classes/dejagnu_stream.py (sets.Set): Don't import it.
	(DejaGNUReader.__init__): Don't set test_ids.

Index: qm/test/classes/dejagnu_stream.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/classes/dejagnu_stream.py,v
retrieving revision 1.6
diff -c -5 -p -r1.6 dejagnu_stream.py
*** qm/test/classes/dejagnu_stream.py	24 Oct 2005 07:46:05 -0000	1.6
--- qm/test/classes/dejagnu_stream.py	26 Oct 2005 00:18:26 -0000
*************** from   dejagnu_test import DejaGNUTest
*** 22,32 ****
  import qm.fields
  from   qm.test.file_result_stream import FileResultStream
  from   qm.test.result import Result
  from   qm.test.file_result_reader import FileResultReader
  import re
- from   sets import Set
  
  ########################################################################
  # Classes
  ########################################################################
  
--- 22,31 ----
*************** class DejaGNUReader(FileResultReader):
*** 202,212 ****
          # DejaGNU files start with "Test Run".
          if self.file.read(len("Test Run")) != "Test Run":
              raise FileResultReader.InvalidFile, \
                    "file is not a DejaGNU result stream"
          self.file.seek(0)
-         self.test_ids = Set()
          if self.__UseCombinedMode():
              test_id, dejagnu_outcome, cause = self.__NextOutcome()
              if test_id:
                  self.__next_result = Result(Result.TEST, test_id)
                  self.__UpdateResult(self.__next_result,
--- 201,210 ----
