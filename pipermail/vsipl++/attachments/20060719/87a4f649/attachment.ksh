########################################################################
#
# File:   GNUmakefile.inc.in
# Author: Jules Bergmann
# Date:   2005-11-22
#
# Contents: Makefile fragment for vendor
#
########################################################################

########################################################################
# Variables
########################################################################


BUILD_ATLAS            := @BUILD_ATLAS@
BUILD_REF_LAPACK       := @BUILD_REF_LAPACK@
BUILD_REF_CLAPACK      := @BUILD_REF_CLAPACK@
BUILD_REF_CLAPACK_BLAS := @BUILD_REF_CLAPACK_BLAS@
BUILD_LIBF77           := @BUILD_LIBF77@

USE_ATLAS_LAPACK       := @USE_ATLAS_LAPACK@
USE_SIMPLE_LAPACK      := @USE_SIMPLE_LAPACK@

#### LIBS
vendor_ATLAS           := vendor/atlas/lib/libatlas.a
vendor_FLAPACK         := vendor/lapack/lapack.a
vendor_CLAPACK         := vendor/clapack/liblapack.a
vendor_MERGED_LAPACK   := vendor/atlas/lib/liblapack.a
vendor_PRE_LAPACK      := vendor/atlas/lib/libprelapack.a
vendor_CLAPACK_BLAS    := vendor/clapack/libblas.a
vendor_LIBF77          := vendor/clapack/F2CLIBS/libF77/libF77.a

########################################################################
################# BUILD PART ###########################################
########################################################################


ifdef BUILD_REF_LAPACK
all:: $(vendor_FLAPACK)
endif

ifdef BUILD_REF_LAPACK
all:: $(vendor_FLAPACK)
vendor_LAPACK := $(vendor_FLAPACK)
endif

ifdef BUILD_REF_CLAPACK
all:: $(vendor_CLAPACK)
vendor_LAPACK := $(vendor_CLAPACK)
endif

ifdef BUILD_REF_CLAPACK_BLAS
all:: $(vendor_CLAPACK_BLAS)
endif

ifdef BUILD_LIBF77
all:: $(vendor_LIBF77)
endif

ifdef BUILD_ATLAS
all:: $(vendor_ATLAS) $(vendor_MERGED_LAPACK)
endif

##### RULES
$(vendor_FLAPACK):
	@echo "Building FLAPACK (see flapack.build.log)"
	@make -C vendor/lapack/SRC all >& flapack.build.log

$(vendor_CLAPACK):
	@echo "Building CLAPACK (see clapack.build.log)"
	@make -C vendor/clapack/SRC all >& clapack.build.log

$(vendor_CLAPACK_BLAS):
	@echo "Building CLAPACK BLAS (see clapack.blas.build.log)"
	@make -C vendor/clapack/blas/SRC all >& clapack.blas.build.log

$(vendor_LIBF77):
	@echo "Building LIBF77 (see libF77.blas.build.log)"
	@make -C vendor/clapack/F2CLIBS/libF77 all >& libF77.blas.build.log

$(vendor_ATLAS):
	@echo "Building ATLAS (see atlas.build.log)"
	@make -C vendor/atlas build >& atlas.build.log

$(vendor_MERGED_LAPACK):
	@echo "Merging pre-lapack and reference lapack..."
	@mkdir -p vendor/atlas/lib/tmp
	@cd vendor/atlas/lib/tmp;ar x ../../../../$(vendor_PRE_LAPACK)
	@cp $(vendor_LAPACK) $(vendor_MERGED_LAPACK)
	@cd vendor/atlas/lib/tmp;ar r ../../../../$(vendor_MERGED_LAPACK) *
	@rm -rf vendor/atlas/lib/tmp


########################################################################
################# INSTALL PART #########################################
########################################################################

ifdef BUILD_LIBF77
install::
	$(INSTALL_DATA) $(vendor_LIBF77) $(DESTDIR)$(libdir)
endif

ifdef BUILD_REF_LAPACK
install::
	$(INSTALL_DATA) vendor/atlas/lib/libf77blas.a $(DESTDIR)$(libdir)
endif

ifdef USE_ATLAS_LAPACK
install::
	$(INSTALL_DATA) vendor/atlas/lib/libatlas.a   $(DESTDIR)$(libdir)
	$(INSTALL_DATA) vendor/atlas/lib/libcblas.a   $(DESTDIR)$(libdir)
	$(INSTALL_DATA) vendor/atlas/lib/liblapack.a  $(DESTDIR)$(libdir)
	$(INSTALL_DATA) vendor/atlas/lib/liblapack.a  $(DESTDIR)$(libdir)
	$(INSTALL_DATA) $(srcdir)/vendor/atlas/include/cblas.h $(DESTDIR)$(includedir)
endif

ifdef USE_SIMPLE_LAPACK
install::
	$(INSTALL_DATA) $(vendor_CLAPACK)      $(DESTDIR)$(libdir)
	$(INSTALL_DATA) $(vendor_CLAPACK_BLAS) $(DESTDIR)$(libdir)
	$(INSTALL_DATA) $(srcdir)/vendor/clapack/SRC/cblas.h $(DESTDIR)$(includedir)
endif


########################################################################


USE_BUILTIN_FFTW  := @USE_BUILTIN_FFTW@
USE_BUILTIN_FFTW_FLOAT := @USE_BUILTIN_FFTW_FLOAT@
USE_BUILTIN_FFTW_DOUBLE := @USE_BUILTIN_FFTW_DOUBLE@
USE_BUILTIN_FFTW_LONG_DOUBLE := @USE_BUILTIN_FFTW_LONG_DOUBLE@

########################################################################
# FFTW Rules
########################################################################

ifdef USE_BUILTIN_FFTW

ifdef USE_BUILTIN_FFTW_FLOAT
LIBFFTW_FLOAT := vendor/fftw3f/.libs/libfftw3f.a
$(LIBFFTW_FLOAT):
	@echo "Building FFTW float (see fftw-f.build.log)"
	@$(MAKE) -C vendor/fftw3f > fftw-f.build.log 2>&1
else
LIBFFTW_LONG_FLOAT :=
endif
ifdef USE_BUILTIN_FFTW_DOUBLE
LIBFFTW_DOUBLE := vendor/fftw3/.libs/libfftw3.a
$(LIBFFTW_DOUBLE):
	@echo "Building FFTW double (see fftw-d.build.log)"
	@$(MAKE) -C vendor/fftw3 > fftw-d.build.log 2>&1
else
LIBFFTW_DOUBLE :=
endif

ifdef USE_BUILTIN_FFTW_LONG_DOUBLE
LIBFFTW_LONG_DOUBLE := vendor/fftw3l/.libs/libfftw3l.a
$(LIBFFTW_LONG_DOUBLE):
	@echo "Building FFTW long double (see fftw-l.build.log)"
	@$(MAKE) -C vendor/fftw3l > fftw-l.build.log 2>&1
else
LIBFFTW_LONG_DOUBLE :=
endif

vendor_FFTW_LIBS := $(LIBFFTW_FLOAT) $(LIBFFTW_DOUBLE) $(LIBFFTW_LONG_DOUBLE)
libs += $(vendor_FFTW_LIBS) 

all:: $(vendor_FFTW_LIBS)
	@rm -rf vendor/fftw/include
	@mkdir -p vendor/fftw/include
	@ln -s $(srcdir)/vendor/fftw/api/fftw3.h vendor/fftw/include/fftw3.h
	@rm -rf vendor/fftw/lib
	@mkdir -p vendor/fftw/lib
	@for lib in $(vendor_FFTW_LIBS); do \
          ln -s `pwd`/$$lib vendor/fftw/lib/`basename $$lib`; \
          done

clean::
	@echo "Cleaning FFTW (see fftw.clean.log)"
	@rm -f fftw.clean.log
	@for ldir in $(subst .a,,$(subst lib/lib,,$(vendor_FFTW_LIBS))); do \
	  $(MAKE) -C vendor/$$ldir clean >> fftw.clean.log 2>&1; \
	  echo "$(MAKE) -C vendor/$$ldir clean "; done

        # note: configure script constructs vendor/fftw/ symlinks used here.
install:: $(vendor_FFTW_LIBS)
	@echo "Installing FFTW"
	$(INSTALL) -d $(DESTDIR)$(libdir)
	@for lib in $(vendor_FFTW_LIBS); do \
	  echo "$(INSTALL_DATA) $$lib  $(DESTDIR)$(libdir)"; \
	  $(INSTALL_DATA) $$lib  $(DESTDIR)$(libdir); done
	$(INSTALL) -d $(DESTDIR)$(includedir)
	$(INSTALL_DATA) $(srcdir)/vendor/fftw/api/fftw3.h $(DESTDIR)$(includedir)
endif
