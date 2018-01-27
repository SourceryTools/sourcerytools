2004-02-08  Mark Mitchell  <mark@codesourcery.com>

	* qm/test/web/web.py (ShowSuitePage.MakeDeleteScript): Return the
	result of MakeConfirmationDialog.

Index: qm/test/web/web.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/web/web.py,v
retrieving revision 1.81
diff -c -5 -p -r1.81 web.py
*** qm/test/web/web.py	15 Jan 2004 06:11:46 -0000	1.81
--- qm/test/web/web.py	8 Feb 2004 20:53:30 -0000
*************** class ShowSuitePage(QMTestPage):
*** 1194,1204 ****
                                       base_request=self.request,
                                       id=suite_id)
          message = """
          <p>Are you sure you want to delete the suite %s?</p>
          """ % suite_id
!         self.server.MakeConfirmationDialog(message, delete_url)
  
          
          
  class StorageResultsStream(ResultStream):
      """A 'StorageResultsStream' stores results.
--- 1194,1204 ----
                                       base_request=self.request,
                                       id=suite_id)
          message = """
          <p>Are you sure you want to delete the suite %s?</p>
          """ % suite_id
!         return self.server.MakeConfirmationDialog(message, delete_url)
  
          
          
  class StorageResultsStream(ResultStream):
      """A 'StorageResultsStream' stores results.
