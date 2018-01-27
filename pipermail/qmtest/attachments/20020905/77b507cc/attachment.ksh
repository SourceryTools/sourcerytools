diff --exclude GNUmakefile --exclude 'config.*' --exclude configure --exclude '*~' --exclude TAGS --exclude '*.o' --exclude '*.pyo' --exclude '*.a' --exclude '*.so' --exclude qm.spec --exclude contrib/qmtest --exclude .cvsignore -ruN ../qm-1.1.5/GNUmakefile.in ../qm-1.1.5-carifio/GNUmakefile.in
--- ../qm-1.1.5/GNUmakefile.in	Sat Mar  9 13:43:29 2002
+++ ../qm-1.1.5-carifio/GNUmakefile.in	Thu Sep  5 12:57:03 2002
@@ -13,6 +13,10 @@
 #
 ########################################################################
 
+# [carifio 9/2/02]
+# Get the current QM_VERSION
+include version
+
 # The QM Tools that are being built in this version of QM.
 QM_TOOLS	:= $(notdir \
                      $(filter qm/test qm/track, \
@@ -409,3 +413,36 @@
 	$(INSTALL_DATA) "qm/test/share/tutorial/tdb/QMTest/configuration" \
 	  "$(INSTALLSHAREDIR)/tutorial/test/tdb/QMTest/configuration"
 endif
+
+
+# [carifio 9/2/02]
+# Programming aids for external developers.
+# See:
+#    $ info emacs tags
+# for more info on the emacs tags package.
+# Usage: ./configure; make tags
+
+.PHONY: tags
+tags:
+	@echo Creating $(PWD)/TAGS
+	find . -name \*.py | etags -
+
+# Usage: ./configure; ... ; make diff
+# Need to figure out what else to exclude, for example cvs stuff.
+.PHONY: diff
+mymods := $(notdir $(PWD))
+diff:
+	diff \
+		--exclude GNUmakefile \
+		--exclude config.\* \
+		--exclude configure \
+		--exclude \*~ \
+		--exclude TAGS \
+		--exclude \*.o \
+		--exclude \*.pyo \
+		--exclude \*.a \
+		--exclude \*.so \
+		--exclude qm.spec \
+		--exclude contrib/qmtest \
+		--exclude .cvsignore \
+		-ruN  ../qm-$(QM_VERSION) ../$(mymods) > ../$(mymods).patch
diff --exclude GNUmakefile --exclude 'config.*' --exclude configure --exclude '*~' --exclude TAGS --exclude '*.o' --exclude '*.pyo' --exclude '*.a' --exclude '*.so' --exclude qm.spec --exclude contrib/qmtest --exclude .cvsignore -ruN ../qm-1.1.5/configure.in ../qm-1.1.5-carifio/configure.in
--- ../qm-1.1.5/configure.in	Tue May 14 19:31:43 2002
+++ ../qm-1.1.5-carifio/configure.in	Thu Sep  5 12:53:00 2002
@@ -207,10 +207,12 @@
 dnl Generate results
 dnl ####################################################################
 
+dnl [carifio 9/5/02] Added contrib/qmtest
 AC_OUTPUT(
   GNUmakefile
   qm.spec
   qm/setup_path.py
+  contrib/qmtest
 )
 
 dnl ####################################################################
diff --exclude GNUmakefile --exclude 'config.*' --exclude configure --exclude '*~' --exclude TAGS --exclude '*.o' --exclude '*.pyo' --exclude '*.a' --exclude '*.so' --exclude qm.spec --exclude contrib/qmtest --exclude .cvsignore -ruN ../qm-1.1.5/contrib/qmtest.conf ../qm-1.1.5-carifio/contrib/qmtest.conf
--- ../qm-1.1.5/contrib/qmtest.conf	Wed Dec 31 19:00:00 1969
+++ ../qm-1.1.5-carifio/contrib/qmtest.conf	Tue Sep  3 15:33:48 2002
@@ -0,0 +1,7 @@
+# Configuration file for qmtest service startup script.
+# Uncomment out a variable and assign it. Use bash syntax
+# QMTEST_DB=<pathname>
+# QMTEST_PORT=<positive integer>
+# QMTEST_LOG=<pathname, probably /var/log/something.log>
+# QMTEST_PIDFILE=<pathname, probably /var/run/qmtest.pid>
+# QMTEST_WAIT=<positive integer, number of seconds to wait on startup, probably 60>
diff --exclude GNUmakefile --exclude 'config.*' --exclude configure --exclude '*~' --exclude TAGS --exclude '*.o' --exclude '*.pyo' --exclude '*.a' --exclude '*.so' --exclude qm.spec --exclude contrib/qmtest --exclude .cvsignore -ruN ../qm-1.1.5/contrib/qmtest.in ../qm-1.1.5-carifio/contrib/qmtest.in
--- ../qm-1.1.5/contrib/qmtest.in	Wed Dec 31 19:00:00 1969
+++ ../qm-1.1.5-carifio/contrib/qmtest.in	Thu Sep  5 12:48:07 2002
@@ -0,0 +1,110 @@
+#!/bin/bash
+
+# Mike Carifio <carifio@usys.com>
+# 8/15/02
+# RedHat style startup script for qmtest gui service.
+# Generated from contrib/qmtest.in
+# Uses ${prefix}/etc/qmtest.conf if it exists
+
+prefix=@prefix@
+exec_prefix=@exec_prefix@
+
+. /etc/rc.d/init.d/functions
+
+# Default action is start
+action=${1:-start}
+# [carifio] How do I get autoconf to insert the right name (qmtest) for the shell script?
+myself=$(basename $0)
+# Assumes --pidfile option...
+pidfile=${QMTEST_PIDFILE:-/var/run/${myself}.pid}
+qmtest=@bindir@/${myself}
+conf=@sysconfdir@/${myself}.conf
+
+case "$action" in
+  start)
+	[ -f "${conf}" ] && . ${conf}
+	# Hokey way to default the database
+	db=${QMTEST_DB:-$(find /home/${myself} -name QMTest -print|head -n1|xargs dirname)}
+	port=${QMTEST_PORT:-8888}
+	# Does your process have the privs to bind a port lower than 1024?
+	[ ${port} -lt 1024 -a $(id -u) -ne 0 ] && \
+	    echo "$(whomai) doesn't have the privs to set a port less than 1024?" 1>&2
+	logfile=${QMTEST_LOG:-/var/log/${myself}.log}
+	rm -f ${pidfile}
+	# Try to connect to connection $(hostname):${port}.
+	# Interpret 'Connection refused' error as the connection
+	#   being available for use. No a foolproof test...
+	if @PYTHON@ - $(hostname) ${port} <<EOF
+import socket, sys, errno
+s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
+try:
+  s.connect((sys.argv[1], int(sys.argv[2])))
+  s.close()
+  sys.exit(0)
+except socket.error, e:
+  sys.exit(e[0] == errno.ECONNREFUSED)
+EOF
+        then
+	    echo -n "$(hostname):${port} appears in use."
+	    echo_failure
+	    echo
+	    exit 1
+        fi
+
+	${qmtest} -D ${db} gui \
+		--address $(hostname) --port ${port} --no-browse \
+		--log-file ${logfile} --pidfile ${pidfile} &
+
+	# Keep looking for pid file until you run out of time or find it, whichever
+	# comes first.
+	seconds=${QMTEST_WAIT:-60}
+	while [ ${seconds} -gt 0 ] ; do
+		if [ -f ${pidfile} ] ; then 
+		    echo -n "${qmtest} starting with pid $(<${pidfile})"
+		    echo_success
+		    echo
+		    exit 0
+		fi
+		sleep 1 
+		echo -n "."
+		let seconds=seconds-1
+       done
+       echo
+       echo -n "${qmtest} didn't start? Pid unknown."
+       echo_failure
+       echo
+       exit 1
+       ;;
+  stop)
+	# Should respond TERM signal
+	[ -f ${pidfile} ] && kill -TERM $(<${pidfile})
+	rm -f ${pidfile}
+	echo
+	echo -n "${qmtest} stopped."
+	echo_success
+	echo
+	;;
+  reload|restart)
+	$0 stop
+	$0 start
+	;;
+  status)
+	if [ ! -f ${pidfile} ] ; then
+	    echo "${myself} isn't running." 2>&1
+	    exit 0
+	fi
+	if checkpid $(<${pidfile})
+	then
+	    echo "${myself} still running (pid $(<${pidfile}))" 2>&1
+	    exit 0
+	else
+	    echo "Pid (pid $(<${pidfile})) lies: ${myself} not running." 2>&1
+	    exit 1
+	fi
+	;;
+  *)
+	echo "Usage: ${myself} {start|stop|restart|reload|status}"
+	exit 1
+esac
+
+exit 0
diff --exclude GNUmakefile --exclude 'config.*' --exclude configure --exclude '*~' --exclude TAGS --exclude '*.o' --exclude '*.pyo' --exclude '*.a' --exclude '*.so' --exclude qm.spec --exclude contrib/qmtest --exclude .cvsignore -ruN ../qm-1.1.5/qm/build/lib/qm/platform_unix.py ../qm-1.1.5-carifio/qm/build/lib/qm/platform_unix.py
--- ../qm-1.1.5/qm/build/lib/qm/platform_unix.py	Sat Mar  9 13:43:29 2002
+++ ../qm-1.1.5-carifio/qm/build/lib/qm/platform_unix.py	Tue Sep  3 15:33:15 2002
@@ -89,7 +89,9 @@
         if signal_name is not None:
             message = message + " (%s)" % signal_name
         # Initialize the base class.
-        RuntimeError.__init__(self, message)
+        # [carifio 9/3/02] RuntimeError is the wrong base class?
+        # RuntimeError.__init__(self, message)
+        common.QMException.__init__(self, message)
         # Store the signal number.
         self.__signal_number = signal_number
 
diff --exclude GNUmakefile --exclude 'config.*' --exclude configure --exclude '*~' --exclude TAGS --exclude '*.o' --exclude '*.pyo' --exclude '*.a' --exclude '*.so' --exclude qm.spec --exclude contrib/qmtest --exclude .cvsignore -ruN ../qm-1.1.5/qm/build/lib/qm/test/cmdline.py ../qm-1.1.5-carifio/qm/build/lib/qm/test/cmdline.py
--- ../qm-1.1.5/qm/build/lib/qm/test/cmdline.py	Thu Mar 14 01:41:07 2002
+++ ../qm-1.1.5-carifio/qm/build/lib/qm/test/cmdline.py	Thu Sep  5 12:49:05 2002
@@ -34,6 +34,7 @@
 import string
 import sys
 import whrandom
+import signal
 
 ########################################################################
 # variables
@@ -63,6 +64,13 @@
     
     results_file_name = "results.qmr"
     """The default name of a file containing results."""
+
+    # [carifio 9/2/02]
+    # Does it make any sense to configure this value per platform?
+    # Either to compute it a runtime or alternatively to substitute it
+    #   using configure? I don't know...
+    pid_path_name = "/var/run/qmtest.pid"
+    """The default path for the pid file (see http://www.pathname.com/fhs/2.2/fhs-5.13.html)"""
     
     help_option_spec = (
         "h",
@@ -190,6 +198,23 @@
         "Set a database attribute."
         )
 
+    # [carifio 9/2/02]
+    # --pidfile /a/path/filename.pid
+    # The default is pid_path_name (/var/run/qmtest.pid).
+    # The user can override the placement of the pid file for platforms
+    #   that don't adhere to the filesystem hierarchy standard.
+    # I don't know why they'd want to, but not every distro adheres to the
+    #   standard (?).
+    pidfile_option_spec = (
+        "p",
+        "pidfile",
+        # what value should this be?
+        "FILE",
+        "File to retain the for use by /etc/rc.d/init.d/qmtestsrvr."
+        )
+
+
+
     # Groups of options that should not be used together.
     conflicting_option_specs = (
         ( output_option_spec, no_output_option_spec ),
@@ -225,7 +250,8 @@
            log_file_option_spec,
            no_browser_option_spec,
            port_option_spec,
-           targets_option_spec
+           targets_option_spec,
+           pidfile_option_spec
            )
          ),
 
@@ -852,8 +878,36 @@
         message = qm.message("server url", url=url)
         qm.common.print_message(0, message + "\n")
 
+        # [carifio 8/28/02] add pidfile stuff
+        # Note that you always write a qmtest.pid file somewhere, either
+        #   where the user indicates or in the default location.
+        # Should the pid file be deleted when qmtest exits? I don't
+        #   think so. This is how the /etc/rc.d/init.d/qmtest status works.
+        if self.HasCommandOption("pidfile"):
+            self.pid_path_name = self.GetCommandOption("pidfile")
+        try:
+            pid_file = open(self.pid_path_name, "w", 0);
+            pid_file.write(str(os.getpid()))
+            pid_file.close()
+        except IOError, (errno, strerr):
+            qm.common.print_message(0, "Could not write %s; errno = %s, %s; pid %d not saved; continuing...\n"
+                                    % (self.pid_path_name, errno, strerr, os.getpid()));
+        except:
+            # Better way to deal with unexpected error?
+            qm.common.print_message(0, "Count not write %s; %s" % (self.pid_path_name, sys.exc_info()));
+            
+
+
         # Accept requests.
-        server.Run()
+        # Respond to a signal.SIGTERM by shutting down cleanly.
+        try:
+            server.Run()
+        except qm.platform.SignalException, se:
+            if se.GetSignalNumber() == signal.SIGTERM:
+                # clean up TERM signal
+                # Put rest of actions here.
+                qm.common.print_message(0, "Responding to SIGTERM by shutting down cleanly...\n");
+
 
 ########################################################################
 # functions
diff --exclude GNUmakefile --exclude 'config.*' --exclude configure --exclude '*~' --exclude TAGS --exclude '*.o' --exclude '*.pyo' --exclude '*.a' --exclude '*.so' --exclude qm.spec --exclude contrib/qmtest --exclude .cvsignore -ruN ../qm-1.1.5/qm/platform_unix.py ../qm-1.1.5-carifio/qm/platform_unix.py
--- ../qm-1.1.5/qm/platform_unix.py	Sat Mar  9 13:43:29 2002
+++ ../qm-1.1.5-carifio/qm/platform_unix.py	Tue Sep  3 15:33:15 2002
@@ -89,7 +89,9 @@
         if signal_name is not None:
             message = message + " (%s)" % signal_name
         # Initialize the base class.
-        RuntimeError.__init__(self, message)
+        # [carifio 9/3/02] RuntimeError is the wrong base class?
+        # RuntimeError.__init__(self, message)
+        common.QMException.__init__(self, message)
         # Store the signal number.
         self.__signal_number = signal_number
 
diff --exclude GNUmakefile --exclude 'config.*' --exclude configure --exclude '*~' --exclude TAGS --exclude '*.o' --exclude '*.pyo' --exclude '*.a' --exclude '*.so' --exclude qm.spec --exclude contrib/qmtest --exclude .cvsignore -ruN ../qm-1.1.5/qm/test/cmdline.py ../qm-1.1.5-carifio/qm/test/cmdline.py
--- ../qm-1.1.5/qm/test/cmdline.py	Thu Mar 14 01:41:07 2002
+++ ../qm-1.1.5-carifio/qm/test/cmdline.py	Thu Sep  5 12:49:05 2002
@@ -34,6 +34,7 @@
 import string
 import sys
 import whrandom
+import signal
 
 ########################################################################
 # variables
@@ -63,6 +64,13 @@
     
     results_file_name = "results.qmr"
     """The default name of a file containing results."""
+
+    # [carifio 9/2/02]
+    # Does it make any sense to configure this value per platform?
+    # Either to compute it a runtime or alternatively to substitute it
+    #   using configure? I don't know...
+    pid_path_name = "/var/run/qmtest.pid"
+    """The default path for the pid file (see http://www.pathname.com/fhs/2.2/fhs-5.13.html)"""
     
     help_option_spec = (
         "h",
@@ -190,6 +198,23 @@
         "Set a database attribute."
         )
 
+    # [carifio 9/2/02]
+    # --pidfile /a/path/filename.pid
+    # The default is pid_path_name (/var/run/qmtest.pid).
+    # The user can override the placement of the pid file for platforms
+    #   that don't adhere to the filesystem hierarchy standard.
+    # I don't know why they'd want to, but not every distro adheres to the
+    #   standard (?).
+    pidfile_option_spec = (
+        "p",
+        "pidfile",
+        # what value should this be?
+        "FILE",
+        "File to retain the for use by /etc/rc.d/init.d/qmtestsrvr."
+        )
+
+
+
     # Groups of options that should not be used together.
     conflicting_option_specs = (
         ( output_option_spec, no_output_option_spec ),
@@ -225,7 +250,8 @@
            log_file_option_spec,
            no_browser_option_spec,
            port_option_spec,
-           targets_option_spec
+           targets_option_spec,
+           pidfile_option_spec
            )
          ),
 
@@ -852,8 +878,36 @@
         message = qm.message("server url", url=url)
         qm.common.print_message(0, message + "\n")
 
+        # [carifio 8/28/02] add pidfile stuff
+        # Note that you always write a qmtest.pid file somewhere, either
+        #   where the user indicates or in the default location.
+        # Should the pid file be deleted when qmtest exits? I don't
+        #   think so. This is how the /etc/rc.d/init.d/qmtest status works.
+        if self.HasCommandOption("pidfile"):
+            self.pid_path_name = self.GetCommandOption("pidfile")
+        try:
+            pid_file = open(self.pid_path_name, "w", 0);
+            pid_file.write(str(os.getpid()))
+            pid_file.close()
+        except IOError, (errno, strerr):
+            qm.common.print_message(0, "Could not write %s; errno = %s, %s; pid %d not saved; continuing...\n"
+                                    % (self.pid_path_name, errno, strerr, os.getpid()));
+        except:
+            # Better way to deal with unexpected error?
+            qm.common.print_message(0, "Count not write %s; %s" % (self.pid_path_name, sys.exc_info()));
+            
+
+
         # Accept requests.
-        server.Run()
+        # Respond to a signal.SIGTERM by shutting down cleanly.
+        try:
+            server.Run()
+        except qm.platform.SignalException, se:
+            if se.GetSignalNumber() == signal.SIGTERM:
+                # clean up TERM signal
+                # Put rest of actions here.
+                qm.common.print_message(0, "Responding to SIGTERM by shutting down cleanly...\n");
+
 
 ########################################################################
 # functions
diff --exclude GNUmakefile --exclude 'config.*' --exclude configure --exclude '*~' --exclude TAGS --exclude '*.o' --exclude '*.pyo' --exclude '*.a' --exclude '*.so' --exclude qm.spec --exclude contrib/qmtest --exclude .cvsignore -ruN ../qm-1.1.5/qm/test/qmtest ../qm-1.1.5-carifio/qm/test/qmtest
--- ../qm-1.1.5/qm/test/qmtest	Tue Aug  6 14:37:52 2002
+++ ../qm-1.1.5-carifio/qm/test/qmtest	Wed Dec 31 19:00:00 1969
@@ -1,218 +0,0 @@
-#! /bin/sh 
-
-########################################################################
-#
-# File:   qm.sh
-# Author: Mark Mitchell
-# Date:   10/04/2001
-#
-# Contents:
-#   QM script.
-#
-# Copyright (c) 2001, 2002 by CodeSourcery, LLC.  All rights reserved. 
-#
-# For license terms see the file COPYING.
-#
-########################################################################
-
-########################################################################
-# Notes
-########################################################################
-
-# This script must be extremely portable.  It should run on all UNIX
-# platforms without modification.
-# 
-# The following commands are used by this script and are assumed
-# to be in the PATH:
-#
-#   basename
-#   dirname
-#   expr
-#   pwd
-#   sed
-#   test
-#   true
-
-########################################################################
-# Functions
-########################################################################
-
-# Prints an error message indicating that the QM installation could
-# not be found and exits with a non-zero exit code.
-
-qm_could_not_find_qm() {
-cat >&2 <<EOF
-error: Could not find the QM installation.
-
-       Set the QM_HOME environment variable to the directory 
-       in which you installed QM.
-EOF
-
-    exit 1
-}
-
-# Returns true if $1 is an absolute path.
-
-qm_is_absolute_path() {
-    expr "$1" : '/.*$' > /dev/null 2>&1
-}
-
-# Returns true if $1 contains at least one directory separator.
-
-qm_contains_dirsep() {
-    expr "$1" : '.*/' > /dev/null 2>&1
-}
-
-# Prints out the components that make up the colon-separated path
-# given by $1.
-
-qm_split_path() {
-    echo $1 | sed -e 's|:| |g'
-}
-
-########################################################################
-# Main Program
-########################################################################
-
-# Find the root of the QM installation in the following way:
-#
-# 1. If the QM_HOME environment variable is set, its value is
-#    used unconditionally.
-#
-# 2. Otherwise, determine the path to this script.  If $0 is
-#    an absolute path, that value is used.  Otherwise, search
-#    the PATH environment variable just as the shell would do.
-#
-#    Having located this script, iterate up through the directories
-#    that contain $0 until we find a directory containing `lib/qm' or
-#    file called `qm/qm.sh'.  (It is not sufficient to simply apply
-#    'dirname' twice because of pathological cases like
-#    `./././bin/qmtest.sh'.)  This directory is the root of the
-#    installation.  In the former case, we have found an installed
-#    QM; in the latter we have found a build directory where QM
-#    is being developed.
-#
-# After determining the root of the QM installation, set the QM_HOME
-# environment variable to that value.  If we have found QM in the
-# build directory, set the QM_BUILD environment variable to 1.  
-# Otherwise, set it to 0.
-
-# Assume that QM is not running out of the build directory.
-QM_BUILD=0
-# Assume that we should run Python with optimization turned on, unless
-# other flags have been explicitly specified.
-if test x"${QM_PYTHON_FLAGS}" = x; then
-  QM_PYTHON_FLAGS="-O"
-fi
-
-# Check to see if QM_HOME is set.
-if test x"${QM_HOME}" = x; then
-    # Find the path to this script.  Set qm_path to the absolute
-    # path to this script.
-    if qm_is_absolute_path "$0"; then
-	# If $0 is an absolute path, use it.
-	qm_path="$0"
-    elif qm_contains_dirsep "$0"; then
-	# If $0 is something like `./qmtest', transform it into
-	# an absolute path.
-	qm_path="`pwd`/$0"
-    else
-	# Otherwise, search the PATH.
-	for d in `qm_split_path "${PATH}"`; do
-	    if test -f "${d}/$0"; then
-		qm_path="${d}/$0"
-		break
-	    fi
-	done
-
-	# If we did not find this script, then we must give up.
-	if test x"${qm_path}" = x; then
-	    qm_could_not_find_qm
-	fi
-
-	# If the path we have found is a relative path, make it
-	# an absolute path.
-	if ! qm_is_absolute_path "${qm_path}"; then
-	    qm_path="`pwd`/${qm_path}"
-	fi
-    fi
-
-    # Iterate through the directories containing this script.
-    while true; do
-	# Go the next containing directory.  We do this at the
-	# beginning of the loop because $qm_path is the path
-	# to the script, not a directory containing it, on the
-	# first iteration.
-	qm_path=`dirname ${qm_path}`
-	# If there is a subdirectory called `lib/qm', then 
-	# we have found the root of the QM installation.
-	if test -d "${qm_path}/lib/qm"; then
-	    QM_HOME="${qm_path}"
-	    break
-	fi
-	# Alternatively, if we have find a file called `qm/qm.sh',
-	# then we have found the root of the QM build directory.
-	if test -f "${qm_path}/qm/qm.sh"; then
-	    QM_HOME="${qm_path}"
-	    QM_BUILD=1
-	    break
-	fi
-	# If we have reached the root directory, then we have run
-	# out of places to look.
-	if test "x${qm_path}" = x/; then
-	    qm_could_not_find_qm
-	fi
-    done
-fi
-
-# Export QM_HOME so that we can find it from within Python.
-export QM_HOME
-# Export QM_BUILD so that QM knows where to look for other modules.
-export QM_BUILD
-
-# Decide which Python installation to use in the following way:
-#
-# 1. If ${QM_PYTHON} exists, use it.
-#
-# 2. Otherwise, If ${QM_HOME}/bin/python exists, use it.
-#
-# 3. Otherwise, if /usr/bin/python2 exists, use it.
-#    
-#    Red Hat's python2 RPM installs Python in /usr/bin/python2, so
-#    as not to conflict with the "python" RPM which installs 
-#    Python 1.5 as /usr/bin/python.  QM requires Python 2, and we
-#    do not want every user to have to set QM_PYTHON, so we must
-#    look for /usr/bin/python2 specially.
-#
-# 4. Otherwise, use whatever `python' is in the path.
-#
-# Set qm_python to this value.
-
-if test "x${QM_PYTHON}" != x; then
-    qm_python="${QM_PYTHON}"
-elif test -f "${QM_HOME}/bin/python"; then
-    qm_python="${QM_HOME}/bin/python"
-elif test -f "/usr/bin/python2"; then
-    qm_python="/usr/bin/python2"
-else
-    qm_python="python"
-fi
-
-# Figure out where to find the main Python script.
-if test ${QM_BUILD} -eq 0; then
-    qm_libdir="${QM_HOME}/lib/qm/qm"
-else
-    qm_libdir="${QM_HOME}/qm"
-fi
-qm_script=`basename $0`
-
-case ${qm_script} in
-    qmtest | qmtest-remote) qm_script_dir=test;;
-    qmtrack) qm_script_dir=track;;
-esac
-
-qm_script="${qm_libdir}/${qm_script_dir}/${qm_script}.py"
-
-# Start the python interpreter, passing it all of the arguments
-# present on our command line.
-exec "${qm_python}" ${QM_PYTHON_FLAGS} "${qm_script}" "$@"
