Index: doc/quickstart/quickstart.xml
===================================================================
RCS file: /home/cvs/Repository/vpp/doc/quickstart/quickstart.xml,v
retrieving revision 1.16
diff -c -p -r1.16 quickstart.xml
*** doc/quickstart/quickstart.xml	17 Sep 2005 21:52:23 -0000	1.16
--- doc/quickstart/quickstart.xml	5 Dec 2005 19:32:55 -0000
***************
*** 536,541 ****
--- 536,559 ----
       </varlistentry>
  
       <varlistentry>
+       <term><option>--prefix=<replaceable>directory</replaceable></option></term>
+       <listitem>
+        <para>
+ 	Install the library in <replaceable>directory</replaceable>.
+ 	Header files will be placed in a subdirectory of 
+ 	<replaceable>directory</replaceable> named
+ 	<filename>include</filename>; the library itself will be 
+ 	placed in <filename>lib</filename>.  You will need to have 
+ 	sufficient permissions to write to the installation directory.
+ 	The default installation directory is
+ 	<filename>/usr/local</filename>, which is usually not writable
+ 	by non-administrators; therefore, you may want to use your
+ 	home directory as an installation directory.   
+        </para> 
+       </listitem>
+      </varlistentry>
+ 
+      <varlistentry>
        <term><option>--disable-mpi</option></term>
        <listitem>
         <para>
***************
*** 552,558 ****
        <listitem>
         <para>
  	Search for MPI installation in
! 	<replaceable>directory</replaceable> first.  This option is
  	useful if MPI is installed in a non-standard location, or if
  	multiple MPI versions are installed.
         </para>
--- 570,578 ----
        <listitem>
         <para>
  	Search for MPI installation in
! 	<replaceable>directory</replaceable> first.  MPI headers should
!         be in <replaceable>directory/include</replaceable> and MPI
! 	libraries in <replaceable>director/lib</replaceable>.  This option is
  	useful if MPI is installed in a non-standard location, or if
  	multiple MPI versions are installed.
         </para>
***************
*** 560,581 ****
       </varlistentry>
  
       <varlistentry>
!       <term><option>--prefix=<replaceable>directory</replaceable></option></term>
        <listitem>
         <para>
! 	Install the library in <replaceable>directory</replaceable>.
! 	Header files will be placed in a subdirectory of 
! 	<replaceable>directory</replaceable> named
! 	<filename>include</filename>; the library itself will be 
! 	placed in <filename>lib</filename>.  You will need to have 
! 	sufficient permissions to write to the installation directory.
! 	The default installation directory is
! 	<filename>/usr/local</filename>, which is usually not writable
! 	by non-administrators; therefore, you may want to use your
! 	home directory as an installation directory.   
!        </para> 
        </listitem>
       </varlistentry>
      </variablelist>
     </para>
  
--- 580,848 ----
       </varlistentry>
  
       <varlistentry>
!       <term><option>--disable-exceptions</option></term>
        <listitem>
         <para>
! 	Do not use C++ exceptions.  Errors that would previously have
! 	generated an exception now cause an abort().  This option is
! 	useful if you want to build Sourcery VSIPL++ with a compiler
! 	that does not implement exceptions.  By default, exceptions
! 	are used.
!        </para>
!       </listitem>
!      </varlistentry>
! 
!      <varlistentry>
!       <term><option>--enable-ipp</option></term>
!       <listitem>
!        <para>
!         Enable the use of the Intel Performance Primitives (IPP)
! 	if found.  Enabling IPP will accelerate the performance of
! 	signal processing and view element-wise operations.
!        </para>
!       </listitem>
!      </varlistentry>
! 
!      <varlistentry>
!       <term><option>--with-ipp-prefix=<replaceable>directory</replaceable></option></term>
!       <listitem>
!        <para>
! 	Search for IPP installation in
! 	<replaceable>directory</replaceable> first.  IPP headers
! 	should be in the <filename>include</filename> subdirectory of
! 	<replaceable>directory</replaceable> and IPP libraries should
! 	be in the <filename>lib</filename> subdirectory.  This option
! 	has the effect of enabling IPP
! 	(i.e. <option>--enable-ipp</option>).  This option is useful
! 	if IPP is installed in a non-standard location, or if multiple
! 	IPP versions are installed.
!        </para>
!       </listitem>
!      </varlistentry>
! 
!      <varlistentry>
!       <term><option>--with-ipp-suffix=<replaceable>suffix</replaceable></option></term>
!       <listitem>
!        <para>
!         Use a processor specific version of the IPP libraries, as
!         indicated by <replacable>suffix</replacable>.  For example,
!         the suffix em64t will select IPP libraries specific to em64t
!         processors.  By default, non-suffix IPP libraries are used,
!         which determine the architecture at run-time and dynamically
!         load the appropriate processor-specific libraries.  This
!         option is useful if the automatic dispatcher is not able to
!         determine the correct architecture.
!        </para>
!       </listitem>
!      </varlistentry>
! 
!      <varlistentry>
!       <term><option>--with-fft=<replaceable>lib</replaceable></option></term>
!       <listitem>
!        <para>
!         Search for and use the FFT library indicated by
!         <replaceable>lib</replaceable> to perform FFTs.  Valid
! 	choices for <replaceable>lib</replaceable> include
! 	<option>fftw3</option> and <option>ipp</option>, which
! 	select the FFTW3 and IPP libraries respectively.
!        </para>
        </listitem>
       </varlistentry>
+ 
+      <varlistentry>
+       <term><option>--with-fftw3-prefix=<replaceable>directory</replaceable></option></term>
+       <listitem>
+        <para>
+ 	Search for FFTW3 installation in
+ 	<replaceable>directory</replaceable> first.  FFTW3 headers
+ 	should be in the <filename>include</filename> subdirectory of
+ 	<replaceable>directory</replaceable> and FFTW3 libraries should
+ 	be in the <filename>lib</filename> subdirectory.  This option
+ 	has the effect of enabling FFTW3 for FFTs
+ 	(i.e. <option>--with-fft=fftw3</option>).  This option is useful
+ 	if FFTW3 is installed in a non-standard location, or if multiple
+ 	FFTW3 versions are installed.
+        </para>
+       </listitem>
+      </varlistentry>
+ 
+      <varlistentry>
+       <term><option>--with-lapack</option></term>
+       <listitem>
+        <para>
+         Enable Sourcery VSIPL++ to search for an appropriate
+ 	LAPACK implementation on the platform.  If found, it
+ 	will be used to perform linear algebra (matrix-vector
+ 	products and solvers).
+        </para>
+       </listitem>
+      </varlistentry>
+ 
+      <varlistentry>
+       <term><option>--with-lapack=<replaceable>lib</replaceable></option></term>
+       <listitem>
+        <para>
+         Search for and use the LAPACK library indicated by
+         <replaceable>lib</replaceable> to perform linear algebra
+         (matrix-vector products and solvers).  Valid choices for
+         <replaceable>lib</replaceable> include <option>mkl</option>,
+ 	<option>atlas</option>, <option>generic</option>, and
+ 	<option>builtin</option>.
+        </para>
+ 
+        <para>
+         <option>mkl</option> selects the Intel Math Kernel Library (MKL)
+ 	to perform linear algebra if found.
+        </para>
+        <para>
+         <option>atlas</option> selects the ATLAS library
+ 	to perform linear algebra if found.
+        </para>
+        <para>
+         <option>generic</option> selects a generic LAPACK library
+ 	(-llapack) to perform linear algebra if found.
+        </para>
+        <para>
+         <option>builtin</option> selects the builtin version of ATLAS
+         to perform linear algebra.  This option requires building
+         ATLAS which can take considereable time and is not supported
+         on all platforms.  It is only recommended if MKL, ATLAS, or
+ 	a generic LAPACK or not already installed on the platform.
+        </para>
+       </listitem>
+      </varlistentry>
+ 
+      <varlistentry>
+       <term><option>--disable-builtin-atlas</option></term>
+       <listitem>
+        <para>
+         Disables the consideration of Sourcery VSIPL++'s builtin
+ 	ATLAS for performing linear algebra.  This option is useful
+ 	if building on a platform that is not supported by ATLAS.
+        </para>
+       </listitem>
+      </varlistentry>
+ 
+      <varlistentry>
+       <term><option>--with-atlas-prefix=<replaceable>directory</replaceable></option></term>
+       <listitem>
+        <para>
+ 	Search for ATLAS installation in
+ 	<replaceable>directory</replaceable> first.  ATLAS headers
+ 	should be in the <filename>include</filename> subdirectory of
+ 	<replaceable>directory</replaceable> and ATLAS libraries should
+ 	be in the <filename>lib</filename> subdirectory.  This option
+ 	has the effect of enabling ATLAS for lapack
+ 	(i.e. <option>--with-lapack=atlas</option>).  This option is useful
+ 	if ATLAS is installed in a non-standard location, or if multiple
+ 	ATLAS versions are installed.
+        </para>
+       </listitem>
+      </varlistentry>
+ 
+      <varlistentry>
+       <term><option>--with-mkl-prefix=<replaceable>directory</replaceable></option></term>
+       <listitem>
+        <para>
+ 	Search for MKL installation in
+ 	<replaceable>directory</replaceable> first.  MKL headers
+ 	should be in the <filename>include</filename> subdirectory of
+ 	<replaceable>directory</replaceable> and MKL libraries should
+ 	be in the <filename>lib/(arch)</filename> subdirectory.  This option
+ 	has the effect of enabling MKL for lapack
+ 	(i.e. <option>--with-lapack=mkl</option>).  This option is useful
+ 	if MKL is installed in a non-standard location, or if multiple
+ 	MKL versions are installed.
+        </para>
+       </listitem>
+      </varlistentry>
+ 
+      <varlistentry>
+       <term><option>--with-mkl-arch=<replaceable>architecture</replaceable></option></term>
+       <listitem>
+        <para>
+         Used in conjunction with <option>--with-mkl-prefix</option> to
+         specify which library subdirectory of MKL to use.  If
+ 	<option>--with-mkl-prefix=<replaceable>directory</replaceable></option>
+ 	is used to specify the MKL prefix, libraries are searched for
+ 	in <filename>directory/architecture</filename>.  By default
+ 	<replaceable>architecture</replaceable> is deduced based on
+ 	the platform.  This option is useful if this deduction is
+ 	incorrect.
+        </para>
+       </listitem>
+      </varlistentry>
+ 
+      <varlistentry>
+       <term><option>--disable-cblas</option></term>
+       <listitem>
+        <para>
+         Disables the use of the C BLAS API, forcing the use of the
+         Fortran BLAS API.  This option is useful if building on a
+         platform that does not provide the C BLAS API.
+        </para>
+       </listitem>
+      </varlistentry>
+ 
+      <varlistentry>
+       <term><option>--with-g2c-path=<replaceable>directory</replaceable></option></term>
+       <listitem>
+        <para>
+ 	Search for <filename>libg2c.a</filename> in
+ 	<replaceable>directory</replaceable> first.  This option is
+ 	useful if <filename>libg2c.a</filename> is installed in a
+ 	non-standard location, or if multiple versions are installed.
+        </para>
+       </listitem>
+      </varlistentry>
+ 
+      <varlistentry>
+       <term><option>--enable-profile-timer=<replaceable>timer</replaceable></option></term>
+       <listitem>
+        <para>
+         Use <replaceable>timer</replaceable> type of timer for
+         profiling. Valid choices for <replaceable>timer</replaceable>
+         include <option>none</option>, <option>posix</option>,
+         <option>realtime</option>, and <option>pentiumtsc</option>,
+         and <option>x86_64_tsc</option>.  By default no timer is used
+         (<option><replaceable>timer</replaceable>=none</option>
+        </para>
+ 
+        <para>
+         <option>none</option> disables profile timing.
+        </para>
+        <para>
+         <option>posix</option> selects the POSIX timer if present
+ 	on the system.
+        </para>
+        <para>
+         <option>realtime</option> selects the POSIX realtime timer if present
+ 	on the system.
+        </para>
+        <para>
+         <option>pentiumtsc</option> selects the Pentium time-stamp
+         counter (TSC) timer if present on the system.
+        </para>
+        <para>
+         <option>x86_64_tsc</option> selects the x86-64 (or em64t)
+         time-stamp counter (TSC) timer if present on the system.
+        </para>
+       </listitem>
+      </varlistentry>
+ 
+      <varlistentry>
+       <term><option>--enable-cpu-mhz=<replaceable>speed</replaceable></option></term>
+       <listitem>
+        <para>
+         Use <replaceable>speed</replaceable> MHz as the counter
+         frequency for the Pentium and x86-64 timestamp counters.  By
+         default, the counter frequency is queried from the operating
+         system at runtime.  This option is useful if the correct
+         counter frequency cannot be determined.
+        </para>
+       </listitem>
+      </varlistentry>
+ 
      </variablelist>
     </para>
  
