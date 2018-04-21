2003-10-14  Mark Mitchell  <mark@codesourcery.com>

	* GNUmakefile.in: Sipmlify drastically, relying on distutils to do
	all of the work.
	* setup.py: Tidy.  Add support for DTML files and other missing
	GUI functionality.
	* qm/__init__.py: Pull in data_dir from the configuration file.
	* qm/common.py (get_share_directory): Use it.
	(get_doc_directory): Likewise.
	* qm/qm.sh: Remove.
	* qm/test/.cvsignore: Remove qmtest and qmtest.bat.
	* qm/test/base.py (get_extension_directories): Use
	get_share_directory to find test classes.
	* qm/test/cmdline.py (QMTest.__init__): Add 'path' argument.
	* qm/test/qmtest.py: Rename to ...
	* qm/test/qmtest: ... this.  Add logic to allow QMTest to find its
	own modules.
	* qm/test/doc/reference.xml: Remove QM_PYTHON.
	* qmdist/command/__init__.py (get_relative_path): New function.
	* qmdist/command/check.py: Revise to reference "qmtest", not
	"qmtest.py".
	* qmdist/command/install_data.py (install_data.run): Output
	data_dir as a relative path.
	* qmdist/command/install_scripts.py: New file.
	* NEWS: Update.
		
Index: GNUmakefile.in
===================================================================
RCS file: /home/sc/Repository/qm/GNUmakefile.in,v
retrieving revision 1.29
diff -c -5 -p -r1.29 GNUmakefile.in
*** GNUmakefile.in	29 Sep 2003 07:03:04 -0000	1.29
--- GNUmakefile.in	14 Oct 2003 21:42:28 -0000
*************** QM_TOOLS	:= $(notdir \
*** 22,215 ****
  NULLSTRING	:=
  SPACE		:= $(NULLSTRING) # This comment needs to be here.
  
  TOPDIR		= @top_srcdir@
  
- PYTHONDOCDIRS	= qm
- 
  # Python configuration.
  PYTHONBIN	= @PYTHON@
  PYTHON 		= PYTHONPATH=$(subst $(SPACE),:,$(PYTHONDIRS)) \
  		  $(PYTHONBIN) -O
  PYTHON_PLATFORM = @PYTHON_PLATFORM@
  PYTHONDIRS	= $(TOPDIR)
  
- # Python packages with installation scripts.
- PYTHON_PACKAGES = qm
- # The names of rules to install the PYTHON_PACKAGES.
- PYTHON_PACKAGES_INSTALL = $(PYTHON_PACKAGES:=-install)
- 
- # The scripts that are run to start QM.
- SCRIPTS = $(foreach tool,$(QM_TOOLS),qm/$(tool)/qm$(tool)$(SCRIPT_EXT))
- 
- # The DTD catalog.
- DTD_CATALOG := share/xml/CATALOG
- # The common DTDs.
- COMMON_DTDS := $(wildcard share/xml/*.mod)
- # The tool-specific DTDs.	
- TOOL_DTDS := $(foreach tool, \
- 	       $(QM_TOOLS), \
-                $(wildcard qm/$(tool)/share/dtds/*.dtd))
- # The tool-specific DTDs, copied to the common XML directory.
- COPIED_TOOL_DTDS := $(foreach dtd,$(TOOL_DTDS),share/xml/$(notdir $(dtd)))
- # All the DTDs.
- DTDS := $(COMMON_DTDS) $(COPIED_TOOL_DTDS)
- 
  # Whether or not we should generate documentation.
  DOCUMENTATION = @DOCUMENTATION@
- # Whether or not we should install documentation.
- INSTALL_DOCUMENTATION = @INSTALL_DOCUMENTATION@
- 
- # Jade configuration,
- JADE = @JADE@
- JADEEXTRA = @XML_DCL@
- JADECMD = \
- 	$(JADE) $(foreach dir,$(SGMLDIRS),-D$(dir)) \
- 	-t $(1) -d ../../../doc/qm-$(1).dsl \
- 	$(JADEEXTRA)
- 
- # The directory containing the Docbook DTD.
- SGMLDIRS      += @DOCBOOK_DTD@
- # Modular DSSSL stylesheet configuration.  The system identifiers are
- # specified as relative paths, so the base of the stylesheet
- # installation needs to be provided.
- SGMLDIRS      += @DOCBOOK_STYLESHEETS@ 
- 
- # The HTML user manuals.
- HTML_MANUALS	= $(foreach tool,$(QM_TOOLS),qm/$(tool)/doc/html/index.html)
- 
- # The TeX user manuals.
- TEX_MANUALS     = $(foreach tool,$(QM_TOOLS),qm/$(tool)/doc/print/manual.tex)
- 
- # The PDF user manuals.
- PDF_MANUALS     = $(foreach tool,$(QM_TOOLS),qm/$(tool)/doc/print/manual.pdf)
  
  # Tidy configuration.
  TIDY 		= @TIDY@
  TIDYFLAGS	= -wrap 72 -i --indent-spaces 1
  
  # HappyDoc configuration.
  HAPPYDOC	= @HAPPYDOC@
  
- # The install program.
- INSTALL		= @top_srcdir@/install-sh -c
- INSTALL_DATA    = $(INSTALL) -m 644
- INSTALL_DIR     = $(INSTALL) -d -m 755
- INSTALL_PROGRAM = $(INSTALL)
- INSTALL_SCRIPT  = $(INSTALL_PROGRAM)
- 
  # Places to install things.
  prefix		= @prefix@
  exec_prefix	= @exec_prefix@
! INSTALLBINDIR	= @bindir@
! INSTALLLIBDIR	= @libdir@/qm
! INSTALLSHAREDIR	= @datadir@/qm
! INSTALLDOCDIR   = @datadir@/doc/qm
! INSTALLINCDIR   = @includedir@
! 
! ifneq ($(PYTHON_PLATFORM),win32)
! NATPREFIX       := $(prefix)
! PYTHON_PKG_PREFIX := $(shell $(PYTHON) -c "import distutils.sysconfig; print distutils.sysconfig.get_python_lib(prefix='$(NATPREFIX)')")
! RELLIBDIR := $(shell expr "$(PYTHON_PKG_PREFIX)" : '$(NATPREFIX)\(.*\)')
! else
! NATPREFIX       := $(shell cygpath -a -w "$(prefix)")
! PYTHON_PKG_PREFIX := $(NATPREFIX)\lib
! RELLIBDIR       := lib
! endif
! 
! # Distutils requires relative paths on Windows.  For consistency,
! # we use the same technique everywhere.
! RELSHAREDIR := $(shell expr "$(INSTALLSHAREDIR)" : '$(prefix)\(.*\)')
! RELINCDIR := $(shell expr "$(INSTALLINCDIR)" : '$(prefix)\(.*\)')
! # Depending on how the user typed their prefix, there may now be slashes
! # left at the beginning of the supposedly relative paths, so we remove
! # those:
! RELLIBDIR := $(shell echo "$(RELLIBDIR)" | sed 's|^/*||')
! RELSHAREDIR := $(shell echo "$(RELSHAREDIR)" | sed 's|^/*||')
! RELINCDIR := $(shell echo "$(RELINCDIR)" | sed 's|^/*||')
! 
! ifeq ($(PYTHON_PLATFORM),win32)
! SCRIPT_EXT = .bat
! else
! SCRIPT_EXT =
! endif
! 
! ########################################################################
! # Main Rules
! ########################################################################
! 
! all: \
! 	$(PYTHON_PACKAGES) \
! 	$(SCRIPTS) \
! 	$(DTD_CATALOG) \
! 	doc
! 
! # Regenerate files that are generated by configure.
! 
! %: %.in
! 	./config.status
  
  ########################################################################
  # Build Rules
  ########################################################################
  
! # Build the Python packages.
! .PHONY: $(PYTHON_PACKAGES)
! 
! $(PYTHON_PACKAGES):
! 	cd $@ && $(PYTHON) ./setup.py -q build
  
! # Generate executable scripts.
! ifneq ($(PYTHON_PLATFORM),win32)
! $(SCRIPTS): qm/qm.sh GNUmakefile
! 	rm -rf $@
! 	sed -e "s#@@@RELLIBDIR@@@#$(RELLIBDIR)/qm#" < qm/qm.sh > $@
! 	chmod a-w $@
! 	chmod a+x $@
  else
! PYTHONEXE = `@PYTHON@ -c "import sys; print sys.prefix"`\\python
! $(SCRIPTS): GNUmakefile
! 	rm -rf $@
! 	echo -e "@echo off\r" > $@
! 	echo -e "set QM_HOME=C:\\progra~1\qm\r" >> $@
! 	echo -e "set PYTHONPATH=%C:\\Program Files\\QM\\$(RELLIBDIR);%PYTHONPATH%\r" >> $@
! 	echo -n "$(PYTHONEXE)" \
!                  \"%QM_HOME%\\$(RELLIBDIR)\\$(subst /,\\,$(basename $@)).py\" \
!           >> $@
! 	echo -e " %1 %2 %3 %4 %5 %6 %7 %8 %9\r" >> $@
  endif
  
! $(DTD_CATALOG): $(DTDS)
! 	rm -f $@
! 	echo "-- This file is automatically generated.  Do not edit. --" \
! 	  >> $@
! 	for x in $^; do \
! 	  name=`expr "\`grep NAME $$x\`" : '<!-- NAME: \(.*\) -->'`; \
! 	    echo 'PUBLIC "-//Software Carpentry//'$$name'//EN" \
! 	      "'`basename $$x`'"' \
! 	      >> $@; \
! 	done
! 
! $(COPIED_TOOL_DTDS): $(TOOL_DTDS)
! 	cp $(filter %$(notdir $@), $^) $@
  
  clean::
! 	for x in $(PYTHON_PACKAGES); do \
! 	  (cd $$x && $(PYTHON) ./setup.py clean); \
! 	done
! ifeq ($(DOCUMENTATION),yes)
! 	for tool in $(QM_TOOLS); do \
! 	  rm -rf qm/$$tool/doc/html qm/$$tool/doc/print; \
! 	done
! endif
! 	rm -f $(SCRIPTS)
  
  distclean: clean
  	rm -f GNUmakefile config.cache config.status config.log
  	rm -f qm/__version.py 
  	rm -f qm.spec
  
  # Run tests.
  .PHONY: check check-serial check-threads check-processes check-rsh
  
  # The check-rsh target is not included here because it requires
  # networking support.
--- 22,104 ----
  NULLSTRING	:=
  SPACE		:= $(NULLSTRING) # This comment needs to be here.
  
  TOPDIR		= @top_srcdir@
  
  # Python configuration.
  PYTHONBIN	= @PYTHON@
  PYTHON 		= PYTHONPATH=$(subst $(SPACE),:,$(PYTHONDIRS)) \
  		  $(PYTHONBIN) -O
  PYTHON_PLATFORM = @PYTHON_PLATFORM@
  PYTHONDIRS	= $(TOPDIR)
  
  # Whether or not we should generate documentation.
  DOCUMENTATION = @DOCUMENTATION@
  
  # Tidy configuration.
  TIDY 		= @TIDY@
  TIDYFLAGS	= -wrap 72 -i --indent-spaces 1
  
  # HappyDoc configuration.
  HAPPYDOC	= @HAPPYDOC@
  
  # Places to install things.
  prefix		= @prefix@
  exec_prefix	= @exec_prefix@
! datadir		= @datadir@
! libdir		= @libdir@
! bindir		= @bindir@
  
  ########################################################################
  # Build Rules
  ########################################################################
  
! .PHONY: all
! all:
! ifeq ($(DOCUMENTATION), yes)
! 	$(PYTHON) ./setup.py build_doc
! endif
! 	$(PYTHON) ./setup.py build
  
! # Build internal documentation.
! ifneq ($(HAPPYDOC),)
! doc-python:
! 	$(PYTHON) $(HAPPYDOC) qm
  else
! doc-python:
! 	@echo "The Python happydoc package is not available."
! 	@exit 1
  endif
  
! # Regenerate files that are generated by configure.
! %: %.in
! 	./config.status
  
  clean::
! 	$(PYTHON) ./setup.py clean -a
  
  distclean: clean
  	rm -f GNUmakefile config.cache config.status config.log
  	rm -f qm/__version.py 
  	rm -f qm.spec
  
+ ########################################################################
+ # Installation Rules
+ ########################################################################
+ 
+ .PHONY: install
+ install: all
+ 	$(PYTHON) ./setup.py install -O1 \
+ 		--prefix="$(prefix)" \
+ 		--install-data="$(datadir)" \
+ 		--install-lib="$(libdir)" \
+ 		--install-scripts="$(bindir)"
+ 
+ ########################################################################
+ # Testing Rules
+ ########################################################################
+ 
  # Run tests.
  .PHONY: check check-serial check-threads check-processes check-rsh
  
  # The check-rsh target is not included here because it requires
  # networking support.
*************** check-rsh: all
*** 248,460 ****
  	qm/test/qmtest -D tests run -T tests/QMTest/rsh_target \
  		$(QMTESTFLAGS) \
  		-c qmtest_path=`pwd`/qm/test/qmtest \
  		-c qmtest_target=`pwd`/tests/QMTest/rsh_target
  
- ########################################################################
- # Documentation Rules
- ########################################################################
- 
- .PHONY: doc
- 
- ifeq ($(DOCUMENTATION), yes)
- doc: doc-html doc-print
- else
- # If we are not building documentation, there is nothing to do.
- doc:
- endif
- 
- doc-html: $(HTML_MANUALS)
- 
- $(HTML_MANUALS): \
- 	%/html/index.html : \
- 	%/manual.xml %/introduction.xml %/tour.xml %/reference.xml
- 	mkdir -p $(dir $@)
- 	(cd $(dir $<) && \
- 	  $(call JADECMD,sgml) $(notdir $<)) || \
- 	  (rm -rf $(dir $@) && false)
- ifneq ($(TIDY),no)
- 	for f in $(dir $@)*.html; \
- 	do \
- 	  HTML_TIDY=/dev/null \
- 		$(TIDY) $(TIDYFLAGS) -f /dev/null -asxml -modify $${f}; \
- 	  true; \
- 	done 
- endif
- 
- .PHONY: doc-print
- 
- doc-print: $(PDF_MANUALS)
  
- # Jade places the output TeX source file in the current directory, so
- # move it where we want it afterwards.
- #
- # We have to change -- into -{-} so that TeX does not generate long 
- # dashes.  This is a bug in Jade.
- 
- $(TEX_MANUALS): \
- 	%/print/manual.tex : \
- 	%/manual.xml %/introduction.xml %/tour.xml %/reference.xml
- 	mkdir -p $(dir $@)
- 	(cd $(dir $<) && \
- 	  $(call JADECMD,tex) $(notdir $<)) || \
-           (rm -rf $(dir $@) && false)
- 	sed -e 's|--|-{-}|g' < \
-           $(dir $<)$(notdir $@) > $@
- 	rm $(dir $<)$(notdir $@)
- 
- # Process the TeX file to PDF, in the print directory.  
- %.pdf: %.tex 
- 	cd `dirname $@`; \
- 	  pdfjadetex $(notdir $<); \
- 	  pdfjadetex $(notdir $<); \
- 	  pdfjadetex $(notdir $<)
- 
- .PHONY: doc-python
- 
- ifneq ($(HAPPYDOC),)
- doc-python: $(PYTHONDOCDIRS)
- 	for dir in $(PYTHONDOCDIRS); do \
- 	    $(PYTHON) $(HAPPYDOC) $${dir}; \
- 	done
- else
- doc-python:
- endif
- 
- ########################################################################
- # Installation Rules
- ########################################################################
- 
- # Install everything.
- .PHONY: install
- 
- install: \
- 	$(PYTHON_PACKAGES_INSTALL) \
- 	doc-install \
- 	scripts-install \
- 	share-install \
- 	lib-install
- 
- # Install Python packages that use distutils.
- .PHONY: $(PYTHON_PACKAGES_INSTALL)
- 
- # Unfortunately, Python's Distutils do not set permissons on on the
- # installed files appropriately.  There is little we can do about this.
- #
- # The "root" option is undocumented, but apparently necessary, when
- # using relative paths for --install-purelib and such.
- $(PYTHON_PACKAGES_INSTALL):
- 	cd $(@:-install=) && \
- 		$(PYTHON) ./setup.py install -O1 \
- 	        --prefix="$(NATPREFIX)" --root="$(NATPREFIX)" \
- 		--install-purelib="$(RELLIBDIR)" \
-                 --install-platlib="$(RELLIBDIR)" \
-                 --install-scripts="$(RELSHAREDIR)" \
- 		--install-data="$(RELSHAREDIR)" \
-                 --install-headers="$(RELINCDIR)"
- 
- # Install documentation.
- .PHONY: doc-install
- 
- ifeq ($(INSTALL_DOCUMENTATION),yes)
- doc-install:
- 	$(INSTALL_DIR) "$(INSTALLDOCDIR)"
- 	$(INSTALL_DATA) README "$(INSTALLDOCDIR)"
- 	$(INSTALL_DATA) COPYING "$(INSTALLDOCDIR)"
- 	for tool in $(QM_TOOLS); do \
- 		$(INSTALL_DIR) "$(INSTALLDOCDIR)/$$tool/html"; \
- 		for x in qm/$$tool/doc/html/*.html; do \
- 			$(INSTALL_DATA) $$x "$(INSTALLDOCDIR)/$$tool/html"; \
- 		done \
- 	done
- 	for tool in $(QM_TOOLS); do \
- 		$(INSTALL_DIR) "$(INSTALLDOCDIR)/$$tool/pdf"; \
- 		$(INSTALL_DATA) qm/$$tool/doc/print/manual.pdf \
- 		"$(INSTALLDOCDIR)/$$tool/pdf"; \
- 	done
- else
- doc-install:
- 	@echo "Documentation is unavailable and will not be installed."
- 	@echo "Online help will be unavailable."
- 	@echo "Configure with --enable-maintainer-mode to build documentation."
- endif
- 
- # Install scripts.
- .PHONY: scripts-install
- 
- scripts-install:
- 	$(INSTALL_DIR) "$(INSTALLBINDIR)"
- 	for script in $(SCRIPTS); do \
- 	  $(INSTALL_SCRIPT) "$$script" "$(INSTALLBINDIR)"; \
- 	done
- 
- # Install the lib directory.
- 
- .PHONY: lib-install
- 
- # Create the extension class directories.
- lib-install:
- 	for tool in $(QM_TOOLS); do \
- 	  if test -f qm/$$tool/classes/classes.qmc; then \
- 	    $(INSTALL_DIR) "$(PYTHON_PKG_PREFIX)/qm/$$tool/classes"; \
- 	    $(INSTALL_DATA) qm/$$tool/classes/classes.qmc \
- 	      "$(PYTHON_PKG_PREFIX)/qm/$$tool/classes/classes.qmc"; \
- 	  fi; \
- 	done
- 
- # Install the share directory.
- .PHONY: share-install
- 
- share-install: dtml-install messages-install
- 	for x in `find share \( -name '*.txt' -o -name '*.dtml' \
- 		  -o -name '*.css' -o -name '*.js' \
- 		  -o -name '*.gif' -o -name 'CATALOG' \
- 		  -o -name '*.dtd' -o -name '*.mod' \)`; do \
- 		y=`expr "$$x" : 'share/\(.*\)'`; \
- 		$(INSTALL_DIR) "$(INSTALLSHAREDIR)/`dirname $$y`"; \
- 		$(INSTALL_DATA) "$$x" "$(INSTALLSHAREDIR)/$$y"; \
- 	done
- 
- # Install DTML for each tool.
- .PHONY: dtml-install
- 
- dtml-install:
- 	for tool in $(QM_TOOLS); do \
- 	  $(INSTALL_DIR) "$(INSTALLSHAREDIR)/dtml"; \
- 	  $(INSTALL_DIR) "$(INSTALLSHAREDIR)/dtml/$$tool"; \
- 	  for x in qm/$$tool/share/dtml/*.dtml; do \
- 	    $(INSTALL_DATA) "$$x" \
- 	      "$(INSTALLSHAREDIR)/dtml/$$tool/`basename $$x`"; \
- 	  done; \
- 	done
- 
- # Install messages for each tool.
- .PHONY: messages-install
- 
- messages-install:
- 	for tool in $(QM_TOOLS); do \
- 	  $(INSTALL_DIR) "$(INSTALLSHAREDIR)/messages"; \
- 	  $(INSTALL_DIR) "$(INSTALLSHAREDIR)/messages/$$tool"; \
- 	  for x in qm/$$tool/share/messages/*.txt; do \
- 	    $(INSTALL_DATA) "$$x" \
- 	      "$(INSTALLSHAREDIR)/messages/$$tool/`basename $$x`"; \
- 	  done; \
- 	done
- 
- # Install the QMTest tutorial.
- ifneq (,$(findstring test,$(QM_TOOLS)))
- share-install: test-tutorial-install
- 
- .PHONY: test-tutorial-install
- 
- test-tutorial-install:
- 	$(INSTALL_DIR) "$(INSTALLSHAREDIR)/tutorial"
- 	$(INSTALL_DIR) "$(INSTALLSHAREDIR)/tutorial/test"
- 	$(INSTALL_DIR) "$(INSTALLSHAREDIR)/tutorial/test/tdb"
- 	for x in qm/test/share/tutorial/tdb/*.qmt; do \
- 	  $(INSTALL_DATA) "$$x" \
- 	    "$(INSTALLSHAREDIR)/tutorial/test/tdb/`basename $$x`"; \
- 	done
- 	$(INSTALL_DIR) "$(INSTALLSHAREDIR)/tutorial/test/tdb/QMTest"
- 	$(INSTALL_DATA) "qm/test/share/tutorial/tdb/QMTest/configuration" \
- 	  "$(INSTALLSHAREDIR)/tutorial/test/tdb/QMTest/configuration"
- endif
--- 137,142 ----
Index: setup.py
===================================================================
RCS file: /home/sc/Repository/qm/setup.py,v
retrieving revision 1.5
diff -c -5 -p -r1.5 setup.py
*** setup.py	30 Sep 2003 12:44:20 -0000	1.5
--- setup.py	14 Oct 2003 21:42:28 -0000
***************
*** 11,36 ****
  #
  # For license terms see the file COPYING.
  #
  ########################################################################
  
! from distutils.core import setup
  import sys
  import os
  import os.path
  import string
  import glob
  
  ########################################################################
! # imports
  ########################################################################
  
! from qmdist.command.build_doc import build_doc
! from qmdist.command.install_data import install_data
! from qmdist.command.check import check
  
! def prefix(list, pref): return map(lambda x, p=pref: p + x, list)
  
  packages=['qm',
            'qm/external',
            'qm/external/DocumentTemplate',
            'qm/test',
--- 11,77 ----
  #
  # For license terms see the file COPYING.
  #
  ########################################################################
  
! ########################################################################
! # Imports
! ########################################################################
! 
! from   distutils.core import setup
  import sys
  import os
  import os.path
  import string
  import glob
+ from   qmdist.command.build_doc import build_doc
+ from   qmdist.command.install_data import install_data
+ from   qmdist.command.install_scripts import install_scripts
+ from   qmdist.command.check import check
  
  ########################################################################
! # Functions
  ########################################################################
  
! def prefix(list, pref):
! 
!     return map(lambda x, p=pref: os.path.join(p, x), list)
! 
! 
! def files_with_ext(dir, ext):
!     """Return all files in 'dir' with a particular extension.
! 
!     'dir' -- The name of a directory.
! 
!     'ext' -- The extension.
  
!     returns -- A sequence consisting of the filenames in 'dir' whose
!     extension is 'ext'."""
! 
!     return prefix(filter(lambda f: f.endswith(ext),
!                          os.listdir(dir)),
!                   dir)
! 
! 
! def select_share_files(share_files, dir, files):
!     """Find installable files in 'dir'.
! 
!     'share_files' -- A dictionary mapping directories to lists of file
!     names.
! 
!     'dir' -- The directory in which the 'files' are located.
! 
!     'files' -- A list of the files contained in 'dir'."""
!     
!     exts = (".txt", ".dtml", ".css", ".js", ".gif", ".dtd", ".mod")
!     files = filter(lambda f: \
!                      f == "CATALOG" or (os.path.splitext(f)[1] in exts),
!                    files)
!     if files:
!         files = prefix(files, dir)
!         dir = os.path.join("qm", dir[len("share/"):])
!         share_files[dir] = files
  
  packages=['qm',
            'qm/external',
            'qm/external/DocumentTemplate',
            'qm/test',
*************** messages=['help.txt', 'diagnostics.txt']
*** 46,81 ****
  
  html_docs = []
  print_docs = []
  
  if not os.path.isdir(os.path.normpath('qm/test/doc/html')):
!     print """Warning: to include documentation into the package please run
!          the \'build_doc\' command first."""
  
  else:
!     html_docs = filter(lambda f: f[-5:] == '.html',
                         os.listdir(os.path.normpath('qm/test/doc/html')))
!     print_docs = ['manual.tex', 'manual.pdf']
  
  setup(cmdclass={'build_doc': build_doc,
-                 #'build': qm_build,
                  'install_data': install_data,
                  'check': check},
        name="qm", 
        version="2.1",
        packages=packages,
!       scripts=['qm/test/qmtest.py'],
!       data_files=[('share/qm/test/classes',
!                    prefix(classes,'qm/test/classes/')),
!                   ('share/qm/diagnostics',
!                    prefix(diagnostics,'share/diagnostics/')),
!                   ('share/qm/messages/test',
!                    prefix(messages,'qm/test/share/messages/')),
!                   ('share/qm/doc/html',
!                    prefix(html_docs, 'qm/test/doc/html/')),
!                   ('share/qm/doc/print',
!                    prefix(print_docs, 'qm/test/doc/print/'))])
  
  ########################################################################
  # Local Variables:
  # mode: python
  # indent-tabs-mode: nil
--- 87,136 ----
  
  html_docs = []
  print_docs = []
  
  if not os.path.isdir(os.path.normpath('qm/test/doc/html')):
!     print """Warning: to include documentation run the
!              \'build_doc\' command first."""
  
  else:
!     html_docs = filter(lambda f: f.endswith(".html"),
                         os.listdir(os.path.normpath('qm/test/doc/html')))
!     print_docs = [ 'manual.pdf']
! 
! tutorial_files = files_with_ext("qm/test/share/tutorial/tdb", ".qmt")
! test_dtml_files = files_with_ext("qm/test/share/dtml", ".dtml")
! 
! share_files = {}
! os.path.walk("share", select_share_files, share_files)
  
  setup(cmdclass={'build_doc': build_doc,
                  'install_data': install_data,
+                 'install_scripts' : install_scripts,
                  'check': check},
        name="qm", 
        version="2.1",
        packages=packages,
!       scripts=['qm/test/qmtest'],
!       data_files=[('qm/test/classes',
!                    prefix(classes, 'qm/test/classes')),
!                   ('qm/messages/test',
!                    prefix(messages, 'qm/test/share/messages')),
!                   # DTML files for the GUI.
!                   ("qm/dtml/test", test_dtml_files),
!                   # The documentation.
!                   ('qm/doc', ('README', 'COPYING')),
!                   ('qm/doc/test/html',
!                    prefix(html_docs, 'qm/test/doc/html')),
!                   ('qm/doc/test/print',
!                    prefix(print_docs, 'qm/test/doc/print')),
!                   # The tutorial.
!                   ("qm/tutorial/test/tdb", tutorial_files),
!                   ("qm/tutorial/test/tdb/QMTest",
!                    ("qm/test/share/tutorial/tdb/QMTest/configuration",))]
!                  # The files from the top-level "share" directory.
!                  + share_files.items())
  
  ########################################################################
  # Local Variables:
  # mode: python
  # indent-tabs-mode: nil
Index: qm/__init__.py
===================================================================
RCS file: /home/sc/Repository/qm/qm/__init__.py,v
retrieving revision 1.9
diff -c -5 -p -r1.9 __init__.py
*** qm/__init__.py	29 Sep 2003 07:03:04 -0000	1.9
--- qm/__init__.py	14 Oct 2003 21:42:28 -0000
*************** import string
*** 21,37 ****
  from qm.common import *
  from qm.diagnostic import error, warning, message
  
  try:
      # The config file is created during "make install" by setup.py.
!     from qm.config import version
      version_info = tuple(string.split(version, '.'))
      """The version of QM as a tuple of '(major, minor, release)'."""
  except:
      # If qm.config was not available, we are running out of the source tree.
      common.is_installed = 0
      from qm.__version import version, version_info
      
  ########################################################################
  # Local Variables:
  # mode: python
  # indent-tabs-mode: nil
--- 21,38 ----
  from qm.common import *
  from qm.diagnostic import error, warning, message
  
  try:
      # The config file is created during "make install" by setup.py.
!     from qm.config import version, data_dir
      version_info = tuple(string.split(version, '.'))
      """The version of QM as a tuple of '(major, minor, release)'."""
  except:
      # If qm.config was not available, we are running out of the source tree.
      common.is_installed = 0
      from qm.__version import version, version_info
+     data_dir = "share"
      
  ########################################################################
  # Local Variables:
  # mode: python
  # indent-tabs-mode: nil
Index: qm/common.py
===================================================================
RCS file: /home/sc/Repository/qm/qm/common.py,v
retrieving revision 1.74
diff -c -5 -p -r1.74 common.py
*** qm/common.py	29 Sep 2003 07:03:04 -0000	1.74
--- qm/common.py	14 Oct 2003 21:42:29 -0000
*************** import gzip
*** 27,36 ****
--- 27,37 ----
  import imp
  import lock
  import operator
  import os
  import os.path
+ import qm
  import quopri
  import re
  import socket
  import string
  import sys
*************** class RcConfiguration(ConfigParser.Confi
*** 220,244 ****
  ########################################################################
  
  def get_share_directory(*components):
      """Return the path to a file in the QM data file directory."""
  
!     home_dir = os.environ["QM_HOME"]
!     if not is_installed:
!         return os.path.join(home_dir, "share", *components)
!     else:
!         return os.path.join(home_dir, "share", "qm", *components)
  
  
  def get_doc_directory(*components):
      """Return a path to a file in the QM documentation file directory."""
  
-     home_dir = os.environ["QM_HOME"]
      if not is_installed:
!         return os.path.join(home_dir, "qm", *components)
      else:
!         return os.path.join(home_dir, "share", "doc", "qm", *components)
  
  
  def format_exception(exc_info):
      """Format an exception as structured text.
  
--- 221,240 ----
  ########################################################################
  
  def get_share_directory(*components):
      """Return the path to a file in the QM data file directory."""
  
!     return os.path.join(qm.prefix, qm.data_dir, *components)
  
  
  def get_doc_directory(*components):
      """Return a path to a file in the QM documentation file directory."""
  
      if not is_installed:
!         return os.path.join(qm.prefix, "qm", *components)
      else:
!         return os.path.join(get_share_directory("doc"), *components)
  
  
  def format_exception(exc_info):
      """Format an exception as structured text.
  
Index: qm/qm.sh
===================================================================
RCS file: qm/qm.sh
diff -N qm/qm.sh
*** qm/qm.sh	29 Sep 2003 07:03:04 -0000	1.16
--- /dev/null	1 Jan 1970 00:00:00 -0000
***************
*** 1,241 ****
- #! /bin/sh 
- 
- ########################################################################
- #
- # File:   qm.sh
- # Author: Mark Mitchell
- # Date:   10/04/2001
- #
- # Contents:
- #   QM script.
- #
- # Copyright (c) 2001, 2002 by CodeSourcery, LLC.  All rights reserved. 
- #
- # For license terms see the file COPYING.
- #
- ########################################################################
- 
- ########################################################################
- # Notes
- ########################################################################
- 
- # This script must be extremely portable.  It should run on all UNIX
- # platforms without modification.
- # 
- # The following commands are used by this script and are assumed
- # to be in the PATH:
- #
- #   basename
- #   dirname
- #   expr
- #   pwd
- #   sed
- #   test
- #   true
- 
- ########################################################################
- # Variables
- ########################################################################
- 
- # Set by the makefile:
- qm_rel_libdir=@@@RELLIBDIR@@@
- 
- ########################################################################
- # Functions
- ########################################################################
- 
- # Prints an error message indicating that the QM installation could
- # not be found and exits with a non-zero exit code.
- 
- qm_could_not_find_qm() {
- cat >&2 <<EOF
- error: Could not find the QM installation.
- 
-        Set the QM_HOME environment variable to the directory 
-        in which you installed QM.
- EOF
- 
-     exit 1
- }
- 
- # Returns true if $1 is an absolute path.
- 
- qm_is_absolute_path() {
-     expr "$1" : '/.*$' > /dev/null 2>&1
- }
- 
- # Returns true if $1 contains at least one directory separator.
- 
- qm_contains_dirsep() {
-     expr "$1" : '.*/' > /dev/null 2>&1
- }
- 
- # Prints out the components that make up the colon-separated path
- # given by $1.
- 
- qm_split_path() {
-     echo $1 | sed -e 's|:| |g'
- }
- 
- ########################################################################
- # Main Program
- ########################################################################
- 
- # Find the root of the QM installation in the following way:
- #
- # 1. If the QM_HOME environment variable is set, its value is
- #    used unconditionally.
- #
- # 2. Otherwise, determine the path to this script.  If $0 is
- #    an absolute path, that value is used.  Otherwise, search
- #    the PATH environment variable just as the shell would do.
- #
- #    Having located this script, iterate up through the directories
- #    that contain $0 until we find a directory containing
- #    $qm_rel_libdir or file called `qm/qm.sh'.  (It is not sufficient
- #    to simply apply 'dirname' twice because of pathological cases
- #    like `./././bin/qmtest.sh'.)  This directory is the root of the
- #    installation.  In the former case, we have found an installed QM;
- #    in the latter we have found a build directory where QM is being
- #    developed.
- #
- # After determining the root of the QM installation, set the QM_HOME
- # environment variable to that value.
- #
- # Set QM_PATH to the path to this script.
- 
- # Check to see if QM_HOME is set.
- if test x"${QM_HOME}" = x; then
-     # Find the path to this script.  Set qm_path to the absolute
-     # path to this script.
-     if qm_is_absolute_path "$0"; then
- 	# If $0 is an absolute path, use it.
- 	QM_PATH="$0"
-     elif qm_contains_dirsep "$0"; then
- 	# If $0 is something like `./qmtest', transform it into
- 	# an absolute path.
- 	QM_PATH="`pwd`/$0"
-     else
- 	# Otherwise, search the PATH.
- 	for d in `qm_split_path "${PATH}"`; do
- 	    if test -f "${d}/$0"; then
- 		QM_PATH="${d}/$0"
- 		break
- 	    fi
- 	done
- 
- 	# If we did not find this script, then we must give up.
- 	if test x"${QM_PATH}" = x; then
- 	    qm_could_not_find_qm
- 	fi
- 
- 	# If the path we have found is a relative path, make it
- 	# an absolute path.
- 	if ! qm_is_absolute_path "${QM_PATH}"; then
- 	    QM_PATH="`pwd`/${QM_PATH}"
- 	fi
-     fi
- 
-     # Iterate through the directories containing this script.
-     QM_HOME=`dirname "${QM_PATH}"`
-     while true; do
- 	# If there is a subdirectory called $qm_rel_libdir, then 
- 	# we have found the root of the QM installation.
- 	if test -d "${QM_HOME}/${qm_rel_libdir}"; then
- 	    break
- 	fi
- 	# Alternatively, if we have find a file called `qm/qm.sh',
- 	# then we have found the root of the QM build directory.
- 	if test -f "${QM_HOME}/qm/qm.sh"; then
- 	    break
- 	fi
- 	# If we have reached the root directory, then we have run
- 	# out of places to look.
- 	if test "x${QM_HOME}" = x/; then
- 	    qm_could_not_find_qm
- 	fi
- 	# Go the next containing directory.
- 	QM_HOME=`dirname "${QM_HOME}"`
-     done
- fi
- 
- # Figure out whether or not we are running out of the build directory.
- if test -f "${QM_HOME}/qm/qm.sh"; then
-     qm_build=1
- else
-     qm_build=0
- fi
- 
- if test ${qm_build} -eq 0; then
-     QM_PATH=$QM_HOME/bin/qmtest
- else
-     QM_PATH=$QM_HOME/qm/test/qmtest
- fi
- 
- # Export QM_HOME and QM_PATH so that we can find them from within Python.
- export QM_HOME
- export QM_PATH
- 
- # When running QMTest from the build environment, run Python without
- # optimization.  In a production environment, use optimization.
- if test x"${QM_PYTHON_FLAGS}" = x; then
-     if test ${qm_build} -eq 1; then
-         QM_PYTHON_FLAGS=""
-     else
-         QM_PYTHON_FLAGS="-O"
-     fi
- fi
- 
- # Decide which Python installation to use in the following way:
- #
- # 1. If ${QM_PYTHON} exists, use it.
- #
- # 2. Otherwise, If ${QM_HOME}/bin/python exists, use it.
- #
- # 3. Otherwise, if /usr/bin/python2 exists, use it.
- #    
- #    Red Hat's "python2" RPM installs Python in /usr/bin/python2, so
- #    as not to conflict with the "python" RPM which installs 
- #    Python 1.5 as /usr/bin/python.  QM requires Python 2, and we
- #    do not want every user to have to set QM_PYTHON, so we must
- #    look for /usr/bin/python2 specially.
- #
- # 4. Otherwise, use whatever "python" is in the path.
- #
- # Set qm_python to this value.
- 
- if test "x${QM_PYTHON}" != x; then
-     qm_python="${QM_PYTHON}"
- elif test -f "${QM_HOME}/bin/python"; then
-     qm_python="${QM_HOME}/bin/python"
- elif test -f "/usr/bin/python2"; then
-     qm_python="/usr/bin/python2"
- else
-     qm_python="python"
- fi
- 
- # Figure out where to find the main Python script.
- if test ${qm_build} -eq 0; then
-     qm_libdir="${QM_HOME}/${qm_rel_libdir}"
- else
-     qm_libdir="${QM_HOME}/qm"
- fi
- qm_script=`basename $0`
- 
- # Just in case we installed into a weird place:
- qm_python_path_dir=`expr "${qm_libdir}" : '\(.*\)/qm'`
- PYTHONPATH=${qm_python_path_dir}:$PYTHONPATH
- export PYTHONPATH
- 
- case ${qm_script} in
-     qmtest) qm_script_dir=test;;
-     qmtrack) qm_script_dir=track;;
- esac
- 
- qm_script="${qm_libdir}/${qm_script_dir}/${qm_script}.py"
- 
- # Start the python interpreter, passing it all of the arguments
- # present on our command line.  It would be nice to be able to
- # issue an error message if that does not work, beyond that which
- # the shell issues, but exec does not return on failure.
- exec "${qm_python}" ${QM_PYTHON_FLAGS} "${qm_script}" "$@"
--- 0 ----
Index: qm/test/.cvsignore
===================================================================
RCS file: /home/sc/Repository/qm/qm/test/.cvsignore,v
retrieving revision 1.5
diff -c -5 -p -r1.5 .cvsignore
*** qm/test/.cvsignore	29 Jul 2003 20:22:43 -0000	1.5
--- qm/test/.cvsignore	14 Oct 2003 21:42:29 -0000
***************
*** 1,4 ****
  *.pyc
- qmtest
- qmtest.bat
  *.pyo
--- 1,2 ----
Index: qm/test/base.py
===================================================================
RCS file: /home/sc/Repository/qm/qm/test/base.py,v
retrieving revision 1.93
diff -c -5 -p -r1.93 base.py
*** qm/test/base.py	2 Oct 2003 16:35:35 -0000	1.93
--- qm/test/base.py	14 Oct 2003 21:42:29 -0000
*************** def get_extension_directories(kind, data
*** 108,124 ****
      if database:
          dirs.append(database.GetConfigurationDirectory())
      elif database_path:
          dirs.append(qm.test.database.get_configuration_directory
                      (database_path))
!         
!     # When running from the source tree, we look for path relative
!     # to this file.
!     dirs.append(os.path.join(os.path.dirname(__file__), "classes"))
!     # In an installed version of QMTest, the config object tells us
!     # where to look.
!     dirs.append(os.path.join(qm.config.data_dir, 'test', 'classes'))
  
      return dirs
  
  
  def get_extension_class_names_in_directory(directory):
--- 108,126 ----
      if database:
          dirs.append(database.GetConfigurationDirectory())
      elif database_path:
          dirs.append(qm.test.database.get_configuration_directory
                      (database_path))
! 
!     if qm.common.is_installed:
!         # In an installed version of QMTest, the config object tells us
!         # where to look.
!         dirs.append(qm.common.get_share_directory('test', 'classes'))
!     else:
!         # When running from the source tree, we look for path relative
!         # to this file.
!         dirs.append(os.path.join(os.path.dirname(__file__), "classes"))
  
      return dirs
  
  
  def get_extension_class_names_in_directory(directory):
Index: qm/test/cmdline.py
===================================================================
RCS file: /home/sc/Repository/qm/qm/test/cmdline.py,v
retrieving revision 1.101
diff -c -5 -p -r1.101 cmdline.py
*** qm/test/cmdline.py	28 Sep 2003 21:08:02 -0000	1.101
--- qm/test/cmdline.py	14 Oct 2003 21:42:30 -0000
*************** Valid formats are %s.
*** 480,496 ****
      """The string printed when the --version option is used.
  
      There is one fill-in, for a string, which should contain the version
      number."""
      
!     def __init__(self, argument_list):
          """Construct a new QMTest.
  
          Parses the argument list but does not execute the command.
  
          'argument_list' -- The arguments to QMTest, not including the
!         initial argv[0]."""
  
          global _the_qmtest
          
          _the_qmtest = self
          
--- 480,498 ----
      """The string printed when the --version option is used.
  
      There is one fill-in, for a string, which should contain the version
      number."""
      
!     def __init__(self, argument_list, path):
          """Construct a new QMTest.
  
          Parses the argument list but does not execute the command.
  
          'argument_list' -- The arguments to QMTest, not including the
!         initial argv[0].
! 
!         'path' -- The path to the QMTest executable."""
  
          global _the_qmtest
          
          _the_qmtest = self
          
*************** Valid formats are %s.
*** 515,525 ****
            self.__command_options,
            self.__arguments
            ) = components
  
          # If available, record the path to the qmtest executable.
!         self.__qmtest_path = os.environ.get("QM_PATH")
          
          # We have not yet loaded the database.
          self.__database = None
          # We have not yet computed the set of available targets.
          self.targets = None
--- 517,527 ----
            self.__command_options,
            self.__arguments
            ) = components
  
          # If available, record the path to the qmtest executable.
!         self.__qmtest_path = path
          
          # We have not yet loaded the database.
          self.__database = None
          # We have not yet computed the set of available targets.
          self.targets = None
Index: qm/test/qmtest
===================================================================
RCS file: qm/test/qmtest
diff -N qm/test/qmtest
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- qm/test/qmtest	14 Oct 2003 21:42:30 -0000
***************
*** 0 ****
--- 1,179 ----
+ #! /usr/bin/env python
+ 
+ ########################################################################
+ #
+ # File:   qmtest
+ # Author: Alex Samuel
+ # Date:   2001-03-15
+ #
+ # Contents:
+ #   QMTest command line application.
+ #
+ # Copyright (c) 2001, 2002, 2003 by CodeSourcery, LLC.  All rights reserved. 
+ #
+ # For license terms see the file COPYING.
+ #
+ ########################################################################
+ 
+ ########################################################################
+ # Imports
+ ########################################################################
+ 
+ import errno
+ import gc
+ import os
+ import os.path
+ import sys
+ import string
+ import traceback
+ 
+ # The Python interpreter will place the directory containing this
+ # script in the default path to search for modules.  That is
+ # unncessary for QMTest, and harmful, since then "import resource"
+ # imports the resource module in QMTest, not the global module of
+ # the same name.
+ sys.path = sys.path[1:]
+ 
+ rel_prefix = os.path.join(os.pardir, os.pardir)
+ """The relative path to the installation prefix.
+ 
+ This string gives the relative path from the directory containing this
+ script to the installation directory.  The value above is correct when
+ QMTest is being run out of the source tree.  When QMTest is installed,
+ this value is updated appropriately."""
+ 
+ rel_libdir = ""
+ """The relative path from the prefix to the library directory.
+ 
+ This path gives the relative path from the prefix to the library
+ directory.  The value above is correct when QMTest is being run out of
+ the source tree.  When QMTest is installed, this value is updated
+ appropriately."""
+ 
+ # Get the path to this script.
+ qm_path = os.path.abspath(sys.argv[0])
+ 
+ # Get the root of the QMTest installation.
+ qm_home = os.environ.get("QM_HOME")
+ if qm_home is None:
+     # Get the path to the installation directory.
+     qm_home = os.path.normpath(os.path.join(os.path.dirname(qm_path),
+                                             rel_prefix))
+ 
+ # Update sys.path so that we can find the rest of QMTest.
+ libdir = os.path.normpath(os.path.join(qm_home, rel_libdir))
+ if libdir not in sys.path:
+     sys.path.insert(0, libdir)
+ 
+ import qm
+ 
+ # Set the prefix variable so that the rest of QMTest can find
+ # documentation files, test classes, and so forth.
+ qm.prefix = qm_home
+ 
+ import qm.cmdline
+ import qm.diagnostic
+ import qm.platform
+ import qm.structured_text
+ import qm.test.cmdline
+ 
+ ########################################################################
+ # Functions
+ ########################################################################
+ 
+ def print_error_message(message):
+     prefix = "qmtest: error: "
+     message = qm.structured_text.to_text(str(message),
+                                          indent=len(prefix))
+     message = prefix + message[len(prefix):]
+     sys.stderr.write(message)
+ 
+ 
+ _required_python_version = (2, 2)
+ def check_python_version():
+     """Check to see if the Python interpreter in use is acceptable.
+ 
+     If the Python interpreter is not sufficiently recent, issue an
+     error message and exit."""
+ 
+     version_str = ".".join([str(num) for num in _required_python_version])
+     message = "Python " + version_str + " or higher is required.\n"
+     message += "Set QM_PYTHON to an appropriate Python interpreter.\n"
+     try:
+         if sys.version_info < _required_python_version:
+             print_error_message(message)
+             sys.exit(1)
+     except AttributeError:
+         print_error_message(message)
+         sys.exit(1)
+ 
+ 
+ def main():
+     """Run QMTest.
+ 
+     returns -- The exit code that should be provided to the operating
+     system."""
+     
+     # Make sure our Python is recent enough.
+     check_python_version()
+ 
+     # Parse the command line.
+     command = qm.test.cmdline.QMTest(sys.argv[1:], qm_path)
+ 
+     # Execute the command.
+     exit_code = command.Execute()
+ 
+     return exit_code
+     
+ ########################################################################
+ # script
+ ########################################################################
+ 
+ # Assume that something will go wrong.
+ exit_code = 2
+ 
+ try:
+     # Set the program name.
+     qm.common.program_name = "QMTest"
+ 
+     # Load messages.
+     qm.diagnostic.load_messages("test")
+ 
+     # Load RC options.
+     qm.rc.Load("test")
+ 
+     try:
+         exit_code = main()
+     except qm.cmdline.CommandError, msg:
+         print_error_message(msg)
+         sys.stderr.write(
+             "Run 'qmtest --help' to get instructions about how to use QMTest.\n")
+     except qm.common.QMException, msg:
+         print_error_message(msg)
+     except NotImplementedError:
+         exc_info = sys.exc_info()
+         method_name = traceback.extract_tb(exc_info[2])[-1][2]
+         print_error_message(qm.message("not implemented",
+                                        method_name = method_name))
+         sys.stderr.write(qm.common.format_traceback(exc_info))
+     except KeyboardInterrupt:
+         sys.stderr.write("\nqmtest: Interrupted.\n")
+     except qm.platform.SignalException, se:
+         # SIGTERM indicates a request to shut down.  Other signals
+         # should be handled earlier.
+         if se.GetSignalNumber() != signal.SIGTERM:
+             raise
+ finally:
+     # Collect garbage so that any "__del__" methods with externally
+     # visible side-effects are executed.
+     del qm.test.cmdline._the_qmtest
+     gc.collect()
+ 
+ # End the program.
+ sys.exit(exit_code)
+ 
+ ########################################################################
+ # Local Variables:
+ # mode: python
+ # indent-tabs-mode: nil
+ # End:
Index: qm/test/qmtest.py
===================================================================
RCS file: qm/test/qmtest.py
diff -N qm/test/qmtest.py
*** qm/test/qmtest.py	22 Sep 2003 04:53:48 -0000	1.26
--- /dev/null	1 Jan 1970 00:00:00 -0000
***************
*** 1,161 ****
- #! /usr/bin/env python
- 
- ########################################################################
- #
- # File:   qmtest.py
- # Author: Alex Samuel
- # Date:   2001-03-15
- #
- # Contents:
- #   QMTest command line application.
- #
- # Copyright (c) 2001, 2002, 2003 by CodeSourcery, LLC.  All rights reserved. 
- #
- # For license terms see the file COPYING.
- #
- ########################################################################
- 
- # Set up the Python module lookup path to find QM.
- 
- import errno
- import os
- import os.path
- import sys
- import string
- 
- # The Python interpreter will place the directory containing this
- # script in the default path to search for modules.  That is
- # unncessary for QMTest, and harmful, since then "import resource"
- # imports the resource module in QMTest, not the global module of
- # the same name.
- sys.path = sys.path[1:]
- 
- ########################################################################
- # imports
- ########################################################################
- 
- import sys
- import gc
- 
- # This executable is supposed to live in ${QM_HOME}/bin (posix)
- # or ${QM_HOME}\Scripts (nt) so we deduce the QM_HOME variable
- # by stripping off the last two components of the path.
- _qm_home = os.environ.get("QM_HOME",
-                           os.path.dirname(os.path.dirname(os.path.abspath
-                                                           (sys.argv[0]))))
- os.environ['QM_HOME']=_qm_home
- 
- import qm
- 
- class config:
-     pass
- qm.config = config()
- qm.config.data_dir = os.path.join(_qm_home, 'share', 'qm')
- 
- import qm.cmdline
- import qm.diagnostic
- import qm.platform
- import qm.structured_text
- import qm.test.cmdline
- import traceback
- 
- ########################################################################
- # functions
- ########################################################################
- 
- def print_error_message(message):
-     prefix = "qmtest: error: "
-     message = qm.structured_text.to_text(str(message),
-                                          indent=len(prefix))
-     message = prefix + message[len(prefix):]
-     sys.stderr.write(message)
- 
- 
- _required_python_version = (2, 2)
- def check_python_version():
-     """Check to see if the Python interpreter in use is acceptable.
- 
-     If the Python interpreter is not sufficiently recent, issue an
-     error message and exit."""
- 
-     version_str = ".".join([str(num) for num in _required_python_version])
-     message = "Python " + version_str + " or higher is required.\n"
-     message += "Set QM_PYTHON to an appropriate Python interpreter.\n"
-     try:
-         if sys.version_info < _required_python_version:
-             print_error_message(message)
-             sys.exit(1)
-     except AttributeError:
-         print_error_message(message)
-         sys.exit(1)
- 
- 
- def main():
-     """Run QMTest.
- 
-     returns -- The exit code that should be provided to the operating
-     system."""
-     
-     # Make sure our Python is recent enough.
-     check_python_version()
- 
-     # Parse the command line.
-     command = qm.test.cmdline.QMTest(sys.argv[1:])
- 
-     # Execute the command.
-     exit_code = command.Execute()
- 
-     return exit_code
-     
- ########################################################################
- # script
- ########################################################################
- 
- # Assume that something will go wrong.
- exit_code = 2
- 
- try:
-     # Set the program name.
-     qm.common.program_name = "QMTest"
- 
-     # Load messages.
-     qm.diagnostic.load_messages("test")
- 
-     # Load RC options.
-     qm.rc.Load("test")
- 
-     try:
-         exit_code = main()
-     except qm.cmdline.CommandError, msg:
-         print_error_message(msg)
-         sys.stderr.write(
-             "Run 'qmtest --help' to get instructions about how to use QMTest.\n")
-     except qm.common.QMException, msg:
-         print_error_message(msg)
-     except NotImplementedError:
-         exc_info = sys.exc_info()
-         method_name = traceback.extract_tb(exc_info[2])[-1][2]
-         print_error_message(qm.message("not implemented",
-                                        method_name = method_name))
-         sys.stderr.write(qm.common.format_traceback(exc_info))
-     except KeyboardInterrupt:
-         sys.stderr.write("\nqmtest: Interrupted.\n")
-     except qm.platform.SignalException, se:
-         # SIGTERM indicates a request to shut down.  Other signals
-         # should be handled earlier.
-         if se.GetSignalNumber() != signal.SIGTERM:
-             raise
- finally:
-     # Collect garbage so that any "__del__" methods with externally
-     # visible side-effects are executed.
-     del qm.test.cmdline._the_qmtest
-     gc.collect()
- 
- # End the program.
- sys.exit(exit_code)
- 
- ########################################################################
- # Local Variables:
- # mode: python
- # indent-tabs-mode: nil
- # End:
--- 0 ----
Index: qm/test/doc/reference.xml
===================================================================
RCS file: /home/sc/Repository/qm/qm/test/doc/reference.xml,v
retrieving revision 1.33
diff -c -5 -p -r1.33 reference.xml
*** qm/test/doc/reference.xml	29 Sep 2003 00:41:07 -0000	1.33
--- qm/test/doc/reference.xml	14 Oct 2003 21:42:31 -0000
***************
*** 1451,1477 ****
    <para>&qmtest; recognizes the following environment variables:</para>
  
    <variablelist>
     <varlistentry>
      <term>
-      <envar>QM_PYTHON</envar>
-     </term>
-     <listitem>
-      <para>If this environment variable is set, &qmtest; uses it as as
-      the path to the Python interpreter.  If this environment variable
-      is not set, &qmtest; looks for a file named
-      <filename>python</filename> in the <filename>bin</filename>
-      directory where QM is installed.  If this file does not exist,
-      but <filename>/usr/bin/python2</filename> exists, &qmtest;
-      will use that path.  Otherwise, &qmtest; searches for
-      <filename>python</filename> in the directories listed in the
-      <envar>PATH</envar> environment variable.</para>
-     </listitem>
-    </varlistentry>
- 
-    <varlistentry>
-     <term>
       <envar>QMTEST_CLASS_PATH</envar>
      </term>
      <listitem>
       <para>If this environment variable is set, it should contain a
       list of directories in the same format as used for the system's
--- 1451,1460 ----
Index: qmdist/command/__init__.py
===================================================================
RCS file: /home/sc/Repository/qm/qmdist/command/__init__.py,v
retrieving revision 1.1
diff -c -5 -p -r1.1 __init__.py
*** qmdist/command/__init__.py	9 Sep 2003 13:48:21 -0000	1.1
--- qmdist/command/__init__.py	14 Oct 2003 21:53:32 -0000
***************
*** 0 ****
--- 1,40 ----
+ ########################################################################
+ #
+ # File:   __init__.py
+ # Author: Mark Mitchell
+ # Date:   2003-10-14
+ #
+ # Contents:
+ #   Support functions for installation scripts.
+ #
+ # Copyright (c) 2003 by CodeSourcery, LLC.  All rights reserved. 
+ #
+ # For license terms see the file COPYING.
+ #
+ ########################################################################
+ 
+ ########################################################################
+ # Imports
+ ########################################################################
+ 
+ import os.path
+ 
+ ########################################################################
+ # Functions
+ ########################################################################
+ 
+ def get_relative_path(dir1, dir2):
+     """Return the relative path from 'dir1' to 'dir2'.
+ 
+     'dir1' -- The path to a directory.
+ 
+     'dir2' -- The path to a directory.
+     
+     returns -- The relative path from 'dir1' to 'dir2'."""
+ 
+     rel_path = ""
+     while not dir2.startswith(dir1):
+         rel_path = os.path.join(os.pardir, rel_path)
+         dir1 = os.path.dirname(dir1)
+ 
+     return os.path.join(rel_path, dir2[len(dir1) + 1:])
Index: qmdist/command/check.py
===================================================================
RCS file: /home/sc/Repository/qm/qmdist/command/check.py,v
retrieving revision 1.1
diff -c -5 -p -r1.1 check.py
*** qmdist/command/check.py	30 Sep 2003 12:44:20 -0000	1.1
--- qmdist/command/check.py	14 Oct 2003 21:53:32 -0000
*************** class check(Command):
*** 64,81 ****
              self.threads = 1
              self.processes = 1
              self.rsh = 1
  
  
!     qmtest = 'qm/test/qmtest.py'
  
      def check_serial(self):
          """Perform serial tests."""
  
          cmd = [check.qmtest,
                 '-D', 'tests', 'run', '-c',
!                norm('qmtest_path=qm/test/qmtest.py')]
          spawn(cmd)
  
      def check_threads(self):
          """Perform threaded tests."""
  
--- 64,81 ----
              self.threads = 1
              self.processes = 1
              self.rsh = 1
  
  
!     qmtest = 'qm/test/qmtest'
  
      def check_serial(self):
          """Perform serial tests."""
  
          cmd = [check.qmtest,
                 '-D', 'tests', 'run', '-c',
!                norm('qmtest_path=qm/test/qmtest')]
          spawn(cmd)
  
      def check_threads(self):
          """Perform threaded tests."""
  
*************** class check(Command):
*** 86,96 ****
                 'thread', 'thread_target.ThreadTarget']
          spawn(cmd)
          cmd = [check.qmtest,
                 '-D', 'tests', 'run',
                 '-T', norm('tests/QMTest/thread_target'),
!                '-c', 'qmtest_path=%s'%norm('qm/test/qmtest.py'),
                 '-c', 'qmtest_target=%s'%norm('tests/QMTest/thread_target')]
          spawn(cmd)
  
      def check_processes(self):
          """Perform sub-processed tests."""
--- 86,96 ----
                 'thread', 'thread_target.ThreadTarget']
          spawn(cmd)
          cmd = [check.qmtest,
                 '-D', 'tests', 'run',
                 '-T', norm('tests/QMTest/thread_target'),
!                '-c', 'qmtest_path=%s'%norm('qm/test/qmtest'),
                 '-c', 'qmtest_target=%s'%norm('tests/QMTest/thread_target')]
          spawn(cmd)
  
      def check_processes(self):
          """Perform sub-processed tests."""
*************** class check(Command):
*** 102,112 ****
                 'process', 'process_target.ProcessTarget']
          spawn(cmd)
          cmd = [check.qmtest,
                 '-D', 'tests', 'run',
                 '-T', norm('tests/QMTest/process_target'),
!                '-c', 'qmtest_path=%s'%norm('qm/test/qmtest.py'),
                 '-c', 'qmtest_target=%s'%norm('tests/QMTest/process_target')]
          spawn(cmd)
  
      def check_rsh(self):
          """Perform tests over a remote shell."""
--- 102,112 ----
                 'process', 'process_target.ProcessTarget']
          spawn(cmd)
          cmd = [check.qmtest,
                 '-D', 'tests', 'run',
                 '-T', norm('tests/QMTest/process_target'),
!                '-c', 'qmtest_path=%s'%norm('qm/test/qmtest'),
                 '-c', 'qmtest_target=%s'%norm('tests/QMTest/process_target')]
          spawn(cmd)
  
      def check_rsh(self):
          """Perform tests over a remote shell."""
*************** class check(Command):
*** 119,129 ****
                 'rsh', 'rsh_target.RSHTarget']
          spawn(cmd)
          cmd = [check.qmtest,
                 '-D', 'tests', 'run',
                 '-T', norm('tests/QMTest/rsh_target'),
!                '-c', 'qmtest_path=%s'%norm('%s/qm/test/qmtest.py'%os.getcwd()),
                 '-c', 'qmtest_target=%s'%norm('%s/tests/QMTest/rsh_target'%os.getcwd())]
          spawn(cmd)
  
  
      def run(self):
--- 119,129 ----
                 'rsh', 'rsh_target.RSHTarget']
          spawn(cmd)
          cmd = [check.qmtest,
                 '-D', 'tests', 'run',
                 '-T', norm('tests/QMTest/rsh_target'),
!                '-c', 'qmtest_path=%s'%norm('%s/qm/test/qmtest'%os.getcwd()),
                 '-c', 'qmtest_target=%s'%norm('%s/tests/QMTest/rsh_target'%os.getcwd())]
          spawn(cmd)
  
  
      def run(self):
Index: qmdist/command/install_data.py
===================================================================
RCS file: /home/sc/Repository/qm/qmdist/command/install_data.py,v
retrieving revision 1.3
diff -c -5 -p -r1.3 install_data.py
*** qmdist/command/install_data.py	29 Sep 2003 07:03:04 -0000	1.3
--- qmdist/command/install_data.py	14 Oct 2003 21:53:32 -0000
***************
*** 11,37 ****
  #
  # For license terms see the file COPYING.
  #
  ########################################################################
  
! from distutils.command import install_data as base
  import os
  
  class install_data(base.install_data):
      """Extends 'install_data' by generating a config module.
  
      This module contains data only available at installation time,
      such as installation paths for data files."""
  
      def run(self):
!         """Run this command."""
          
!         id = self.distribution.get_command_obj('install_data')
          il = self.distribution.get_command_obj('install_lib')
!         base.install_data.run(self)
          config = os.path.join(il.install_dir, 'qm/config.py')
          self.announce("generating %s" %(config))
          outf = open(config, "w")
!         outf.write("version='%s'\n"%(self.distribution.get_version()))
!         
          outf.write("\n")
          self.outfiles.append(config)
--- 11,53 ----
  #
  # For license terms see the file COPYING.
  #
  ########################################################################
  
! ########################################################################
! # Imports
! ########################################################################
! 
! from   distutils.command import install_data as base
  import os
+ from   qmdist.command import get_relative_path
+ 
+ ########################################################################
+ # Classes
+ ########################################################################
  
  class install_data(base.install_data):
      """Extends 'install_data' by generating a config module.
  
      This module contains data only available at installation time,
      such as installation paths for data files."""
  
      def run(self):
! 
!         # Do the standard installation.
!         base.install_data.run(self)
          
!         i = self.distribution.get_command_obj('install')
          il = self.distribution.get_command_obj('install_lib')
! 
          config = os.path.join(il.install_dir, 'qm/config.py')
          self.announce("generating %s" %(config))
          outf = open(config, "w")
!         outf.write("version='%s'\n" % (self.distribution.get_version()))
!         # Compute the path to the data directory.
!         data_dir = os.path.join(self.install_dir, "qm")
!         # Encode the relative path from the installation prefix to the
!         # data directory.
!         outf.write("data_dir='%s'\n"
!                    % get_relative_path (i.prefix, data_dir))
          outf.write("\n")
          self.outfiles.append(config)
Index: qmdist/command/install_scripts.py
===================================================================
RCS file: qmdist/command/install_scripts.py
diff -N qmdist/command/install_scripts.py
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- qmdist/command/install_scripts.py	14 Oct 2003 21:53:32 -0000
***************
*** 0 ****
--- 1,58 ----
+ ########################################################################
+ #
+ # File:   install_scripts.py
+ # Author: Mark Mitchell
+ # Date:   2003-10-14
+ #
+ # Contents:
+ #   Command to install scripts.
+ #
+ # Copyright (c) 2003 by CodeSourcery, LLC.  All rights reserved. 
+ #
+ # For license terms see the file COPYING.
+ #
+ ########################################################################
+ 
+ ########################################################################
+ # Imports
+ ########################################################################
+ 
+ from   distutils.command import install_scripts as base
+ import os
+ from   qmdist.command import get_relative_path
+ import re
+ import sys
+ 
+ ########################################################################
+ # Classes
+ ########################################################################
+ 
+ class install_scripts(base.install_scripts):
+     """Handle installation of Python scripts."""
+ 
+     def run(self):
+ 
+         # Do the standard installation.
+         base.install_scripts.run(self)
+ 
+         # Postprocess the main QMTest Python script.
+         qmtest_file = os.path.join(self.install_dir, "qmtest")
+         qmtest_script = open(qmtest_file).read()
+ 
+         # Encode the relative path from that script to the top of the
+         # installation directory.
+         i = self.distribution.get_command_obj('install')
+         rel_prefix = get_relative_path(self.install_dir, i.prefix)
+         assignment = 'rel_prefix = "%s"' % rel_prefix
+         qmtest_script = re.sub("rel_prefix = .*", assignment,
+                                qmtest_script)
+         # Encode the relative path from the prefix to the library
+         # directory.
+         il = self.distribution.get_command_obj('install_lib')
+         rel_libdir = get_relative_path(i.prefix, il.install_dir)
+         assignment = 'rel_libdir = "%s"' % rel_libdir
+         qmtest_script = re.sub("rel_libdir = .*", assignment,
+                                qmtest_script)
+ 
+         # Write the script back out.
+         open(qmtest_file, "w").write(qmtest_script)
