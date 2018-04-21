Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.253
diff -c -5 -p -r1.253 ChangeLog
*** ChangeLog	17 Sep 2005 19:04:28 -0000	1.253
--- ChangeLog	17 Sep 2005 19:56:38 -0000
***************
*** 1,7 ****
--- 1,21 ----
  2005-09-17  Mark Mitchell  <mark@codesourcery.com>
  
+ 	* GNUmakefile.in (JADE): Define to empty.
+ 	(PDFJADETEX): Likewise.
+ 	(XSLTPROCFLAGS): Rename to ...
+ 	(XSLTPROCFOFLAGS): ... this.
+ 	(%/html/index.html): Rename to ...
+ 	(%.html): ... this.
+ 	(%.fo): Use XLSTPROCFOFLAGS.
+ 	(%.pdf): Provide rule to copy from the srcdir.
+ 	(%.html): Likewise.
+ 	(GNUmakefile): Add more dependencies.
+ 	* configure.ac (JADE): Don't check for it.
+ 	(PDFJADETEX): Likewise.
+ 	* doc/GNUmakefile.inc.in (install): Handle chunked HTML files.
+ 	
  	* GNUmakefile.in (DOCBOOK_DTD): Remove.
  	(%/html/index.html): New rule.
  	* configure.ac: Remove conflicts.
  
  	* doc/quickstart/quickstart.xml: Add version variable.
Index: GNUmakefile.in
===================================================================
RCS file: /home/cvs/Repository/vpp/GNUmakefile.in,v
retrieving revision 1.20
diff -c -5 -p -r1.20 GNUmakefile.in
*** GNUmakefile.in	17 Sep 2005 19:04:28 -0000	1.20
--- GNUmakefile.in	17 Sep 2005 19:56:38 -0000
*************** MPI_LIBS := @MPI_LIBS@
*** 75,94 ****
  ### Documentation ### 
  
  # The Doxygen command.
  DOXYGEN := @DOXYGEN@ 
  # The command used to turn DocBook into TeX.
! JADE := @JADE@
  # The command used to turn TeX output by Jade into PDF.
! PDFJADETEX := @PDFJADETEX@
  # The command used to turn XSL-FO into PDF.
  XEP := @XEP@
  # The command used to turn DocBook into HTML or XSL-FO.
  XSLTPROC := @XSLTPROC@
  # If XEP is available, use the XEP extensions when generating XSL-FO.
  ifdef XEP
! XSLTPROCFLAGS := --string-param xep.extensions 1
  endif
  # The patch to the SGML declaration of XML.
  XML_DCL := xml.dcl
  
  ifdef XSLTPROC
--- 75,94 ----
  ### Documentation ### 
  
  # The Doxygen command.
  DOXYGEN := @DOXYGEN@ 
  # The command used to turn DocBook into TeX.
! JADE := 
  # The command used to turn TeX output by Jade into PDF.
! PDFJADETEX := 
  # The command used to turn XSL-FO into PDF.
  XEP := @XEP@
  # The command used to turn DocBook into HTML or XSL-FO.
  XSLTPROC := @XSLTPROC@
  # If XEP is available, use the XEP extensions when generating XSL-FO.
  ifdef XEP
! XSLTPROCFOFLAGS := --string-param xep.extensions 1
  endif
  # The patch to the SGML declaration of XML.
  XML_DCL := xml.dcl
  
  ifdef XSLTPROC
*************** dir_var  = $($(call norm_dir,$(1))$(2))
*** 192,213 ****
  		      $(call dir_var,$(dir $<),CXXFLAGS) $< \
  		      | sed "s|$(*F)\\.$(OBJEXT)[ :]*|$*\\.d $*\\.$(OBJEXT) : |g" > $@'
  
  ifdef XSLTPROC
  # Generate HTML from DocBook. 
! %/html/index.html: %.xml $(srcdir)/doc/csl-docbook/xsl/html/csl.xsl
! 	mkdir -p $(@D)
  	$(XSLTPROC) \
  	    --stringparam csl_docbook.root $(srcdir)/doc/csl-docbook \
! 	    --output $@ \
  	    $(srcdir)/doc/csl-docbook/xsl/html/csl.xsl \
  	    $<
  
  # Generate XSL-FO from DocBook.
  %.fo: %.xml $(srcdir)/doc/csl-docbook/xsl/fo/csl.xsl
  	mkdir -p $(@D)
! 	$(XSLTPROC) $(XSLTPROCFLAGS) \
  	    --stringparam csl_docbook.root $(srcdir)/doc/csl-docbook \
  	    --output $@ \
  	    $(srcdir)/doc/csl-docbook/xsl/fo/csl.xsl \
  	    $<
  
--- 192,215 ----
  		      $(call dir_var,$(dir $<),CXXFLAGS) $< \
  		      | sed "s|$(*F)\\.$(OBJEXT)[ :]*|$*\\.d $*\\.$(OBJEXT) : |g" > $@'
  
  ifdef XSLTPROC
  # Generate HTML from DocBook. 
! %.html: %.xml $(srcdir)/doc/csl-docbook/xsl/html/csl.xsl
! 	rm -rf $(@D)/html
! 	mkdir -p $(@D)/html
  	$(XSLTPROC) \
  	    --stringparam csl_docbook.root $(srcdir)/doc/csl-docbook \
! 	    --output $(@D)/html/index.html \
  	    $(srcdir)/doc/csl-docbook/xsl/html/csl.xsl \
  	    $<
+ 	touch $@
  
  # Generate XSL-FO from DocBook.
  %.fo: %.xml $(srcdir)/doc/csl-docbook/xsl/fo/csl.xsl
  	mkdir -p $(@D)
! 	$(XSLTPROC) $(XSLTPROCFOFLAGS) \
  	    --stringparam csl_docbook.root $(srcdir)/doc/csl-docbook \
  	    --output $@ \
  	    $(srcdir)/doc/csl-docbook/xsl/fo/csl.xsl \
  	    $<
  
*************** ifdef JADE
*** 231,240 ****
--- 233,263 ----
  %.pdf: %.jtex
  	$(srcdir)/doc/wraptex $(PDFJADETEX) $<
  endif
  endif
  
+ # If we do not have mechanisms for generating documentation, but the
+ # documentation is present in the source directory, copy it from
+ # there.
+ 
+ ifndef docbook_pdf
+ %.pdf: 
+ 	if test -r $(srcdir)/$@; then \
+ 		cp $(srcdir)/$@ $@; \
+ 	fi
+ endif
+ 
+ ifndef docbook_html
+ %.html:
+ 	rm -rf $(@D)/html
+ 	mkdir -p $(@D)/html
+ 	if test -r $(srcdir)/$(@D)/html; then \
+ 		cp -r $(srcdir)/$(@D)/html/*.html $(@D)/html \
+ 	fi
+ 	touch $@
+ endif
+ 
  ########################################################################
  # Standard Targets
  ########################################################################
  
  # Subdirectory Makefile fragments may add to the actions to be taken
*************** endif
*** 274,284 ****
  # These targets are targets that apply to the top-level directory, as
  # if it were a subdirectory.
  
  all:: GNUmakefile doc
  
! GNUmakefile: $(srcdir)/GNUmakefile.in config.status
  	./config.status
  
  config.status: $(srcdir)/configure
  	./config.status --recheck
  
--- 297,310 ----
  # These targets are targets that apply to the top-level directory, as
  # if it were a subdirectory.
  
  all:: GNUmakefile doc
  
! GNUmakefile: \
! 	$(srcdir)/GNUmakefile.in \
! 	$(wildcard $(srcdir)/*/GNUmakefile.inc.in) \
! 	config.status
  	./config.status
  
  config.status: $(srcdir)/configure
  	./config.status --recheck
  
Index: configure.ac
===================================================================
RCS file: /home/cvs/Repository/vpp/configure.ac,v
retrieving revision 1.35
diff -c -5 -p -r1.35 configure.ac
*** configure.ac	17 Sep 2005 19:04:28 -0000	1.35
--- configure.ac	17 Sep 2005 19:56:38 -0000
*************** fi
*** 653,664 ****
  
  #
  # Documentation
  #
  AC_CHECK_PROGS(DOXYGEN, doxygen)
- AC_CHECK_PROGS(JADE, openjade jade)
- AC_CHECK_PROGS(PDFJADETEX, pdfjadetex)
  AC_CHECK_PROGS(XSLTPROC, xsltproc)
  AC_CHECK_PROGS(XEP, xep.sh xep.bat)
  
  #
  # Installation
--- 653,662 ----
Index: doc/GNUmakefile.inc.in
===================================================================
RCS file: /home/cvs/Repository/vpp/doc/GNUmakefile.inc.in,v
retrieving revision 1.5
diff -c -5 -p -r1.5 GNUmakefile.inc.in
*** doc/GNUmakefile.inc.in	15 Sep 2005 08:04:27 -0000	1.5
--- doc/GNUmakefile.inc.in	17 Sep 2005 19:56:38 -0000
*************** clean::
*** 46,55 ****
  
  # Install the manuals.  They may be present in the build directory,
  # or, if we could not build them, in the source directory.
  install::
  	$(INSTALL) -d $(docdir)
! 	for x in $(doc_manuals) $(doc_manuals:%=$(srcdir)/%); do \
! 		if test -r $$x; then \
! 			$(INSTALL_DATA) $$x $(docdir); \
  		fi; \
  	done
--- 46,62 ----
  
  # Install the manuals.  They may be present in the build directory,
  # or, if we could not build them, in the source directory.
  install::
  	$(INSTALL) -d $(docdir)
! 	for f in $(doc_pdf_manuals); do \
! 		if test -r $$f; then \
! 			$(INSTALL_DATA) $$f $(docdir); \
  		fi; \
  	done
+ 	# HTML manuals go in their own subdirectories.
+ 	$(INSTALL) -d $(docdir)/html/quickstart
+ 	if test -r doc/quickstart/html/index.html; then \
+ 		$(INSTALL_DATA) doc/quickstart/html/*.html \
+ 			$(docdir)/html/quickstart; \
+ 	fi
+ 		
