########################################################################
#
# File:   MANIFEST.in
# Author: Stefan Seefeld
# Date:   2003-08-28
#
# Contents:
#   qmtest - Distutils distribution files
#
# Copyright (c) 2003 by CodeSourcery, LLC.  All rights reserved. 
#
# For license terms see the file COPYING.
#
########################################################################

include ChangeLog COPYING README TODO
include MANIFEST.in setup.py

# the modules
recursive-include   qm *.py
include             qm/config.py
# the scripts
include             qm/test/qmtest.py
# the docs
include             qm/test/doc/*.xml
include             qm/test/doc/html/*.html
include             qm/test/doc/print/manual.tex
include             qm/test/doc/print/manual.pdf
recursive-include   doc *
# the data
include             qm/test/classes/classes.qmc
recursive-include   qm/test/share *
recursive-include   share *
recursive-include   templates *
recursive-include   benchmarks *
recursive-include   tests *
recursive-include   scripts *
# build system extensions
recursive-include   qmdist *

# but not...
global-exclude */CVS/*
