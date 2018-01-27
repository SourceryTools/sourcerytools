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
# the scripts
include qm/test/qmtest.py
# the data
recursive-include   zope-dtml *
recursive-include   share *
recursive-include   templates *
recursive-include   doc *
recursive-include   benchmarks *
recursive-include   tests *
recursive-include   scripts *

# but not...
global-exclude */CVS/*
