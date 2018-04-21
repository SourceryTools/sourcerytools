===== config/Shared/include1.mk 1.1 vs edited =====
--- 1.1/r2/config/Shared/include1.mk	2002-05-13 17:47:19 +02:00
+++ edited/config/Shared/include1.mk	2004-05-31 17:06:53 +02:00
@@ -32,8 +32,7 @@
 ########################################################################
 
 ifndef NEXTDIR
-#	THISDIR :=$(subst /tmp_mnt,,$(shell pwd))
-	THISDIR :=$(shell pwd)
+	THISDIR := .
 	DIR_LIST :=$(THISDIR)
 else
 	DIR_LIST :=$(THISDIR)/$(NEXTDIR) $(DIR_LIST)
===== config/Shared/tail.mk 1.2 vs edited =====
--- 1.2/r2/config/Shared/tail.mk	2003-06-23 14:50:42 +02:00
+++ edited/config/Shared/tail.mk	2004-05-31 16:08:26 +02:00
@@ -57,7 +57,7 @@
 INFO_FILE            = $@_$(PASS).info
 
 # This is prepended to compile, link, archive, preprocess, etc rules.
-PRE_CMDLINE          = cd $(PROJECT_ROOT); TMPDIR=$(TMPDIR)/$(SUITE); $(TIME)
+PRE_CMDLINE          = TMPDIR=$(TMPDIR)/$(SUITE); $(TIME)
 
 # This is prepended to compile, link, archive, preprocess, etc rules.
 PDB_PRE_CMDLINE      = cd $(@D); TMPDIR=$(TMPDIR)/$(SUITE); $(TIME)
