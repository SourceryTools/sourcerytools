Index: GNUmakefile.in
===================================================================
RCS file: /home/qm/Repository/qm/GNUmakefile.in,v
retrieving revision 1.27
diff -u -r1.27 GNUmakefile.in
--- GNUmakefile.in	11 Aug 2003 06:43:16 -0000	1.27
+++ GNUmakefile.in	22 Aug 2003 14:24:06 -0000
@@ -170,9 +170,11 @@
 $(SCRIPTS): GNUmakefile
 	rm -rf $@
 	echo -e "@echo off\r" > $@
-	echo -e "set QM_HOME=C:\\progra~1\qm\r" >> $@
+	echo -n "set QM_HOME=$(NATPREFIX)" >> $@
+	echo -e "\r" >> $@
 	echo -e "set QM_BUILD=0\r" >> $@
-	echo -e "set PYTHONPATH=%C:\\Program Files\\QM\\$(RELLIBDIR);%PYTHONPATH%\r" >> $@
+	echo -n "set PYTHONPATH=$(NATPREFIX)\$(RELLIBDIR);%PYTHONPATH%" >> $@
+	echo -e "\r" >> $@
 	echo -n "$(PYTHONEXE)" \
                  \"%QM_HOME%\\$(RELLIBDIR)\\$(subst /,\\,$(basename $@)).py\" \
           >> $@
