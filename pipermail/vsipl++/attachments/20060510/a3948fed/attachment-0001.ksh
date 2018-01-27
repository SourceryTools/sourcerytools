
Index: doc/quickstart/quickstart.xml
===================================================================
RCS file: /home/cvs/Repository/vpp/doc/quickstart/quickstart.xml,v
retrieving revision 1.29
diff -c -p -r1.29 quickstart.xml
*** doc/quickstart/quickstart.xml	28 Apr 2006 23:25:43 -0000	1.29
--- doc/quickstart/quickstart.xml	11 May 2006 04:30:51 -0000
***************
*** 742,759 ****
       </varlistentry>
  
       <varlistentry>
!       <term><option>--with-fft=<replaceable>lib</replaceable></option></term>
        <listitem>
         <para>
          Search for and use the FFT library indicated by
          <replaceable>lib</replaceable> to perform FFTs.  Valid
! 	choices for <replaceable>lib</replaceable> include
! 	<option>fftw3</option>, <option>ipp</option>, and
!         <option>sal</option>, which select the FFTW3, IPP, and SAL
!         libraries respectively.  If no FFT library is to be used
!         (disabling Sourcery VSIPL++'s FFT functionality),
!         <option>none</option> should be chosen for
!         <replaceable>lib</replaceable>.
         </para>
        </listitem>
       </varlistentry>
--- 742,766 ----
       </varlistentry>
  
       <varlistentry>
!       <term><option>--enable-fft=<replaceable>lib</replaceable></option></term>
        <listitem>
         <para>
          Search for and use the FFT library indicated by
          <replaceable>lib</replaceable> to perform FFTs.  Valid
! 	choices for <replaceable>lib</replaceable> include 
! 	<option>fftw3</option>, <option>ipp</option>, and 
!         <option>sal</option>, which select FFTW3, IPP, and SAL
!         libraries respectively.  A fourth option, <option>builtin</option>,
!         selects the FFTW3 library that comes with Sourcery VSIPL++ (default).
!         This option should be used if an existing FFTW3 library is not available.
!         If no FFT library is to be used (disabling Sourcery VSIPL++'s FFT 
!         functionality), <option>no_fft</option> should be chosen for
!         <replaceable>lib</replaceable>.  Multiple libraries may be given as 
!         a comma separated list.  When performing an FFT, VSIPL++ will use the 
!         first library in the list that can support the FFT parameters.  For 
!         example, on Mercury systems <option>--enable-fft=sal,builtin</option> 
!         would use SAL's FFT when possible, falling back to VSIPL++'s builtin 
!         FFTW3 otherwise.
         </para>
        </listitem>
       </varlistentry>
***************
*** 795,802 ****
          <replaceable>lib</replaceable> to perform linear algebra
          (matrix-vector products and solvers).  Valid choices for
          <replaceable>lib</replaceable> include <option>mkl</option>,
! 	<option>atlas</option>, <option>generic</option>, and
! 	<option>builtin</option>.
         </para>
  
         <para>
--- 802,810 ----
          <replaceable>lib</replaceable> to perform linear algebra
          (matrix-vector products and solvers).  Valid choices for
          <replaceable>lib</replaceable> include <option>mkl</option>,
! 	<option>acml</option>, <option>atlas</option>, 
!         <option>generic</option>, <option>builtin</option>, and
! 	<option>fortran-builtin</option>.
         </para>
  
         <para>
***************
*** 804,809 ****
--- 812,821 ----
  	to perform linear algebra if found.
         </para>
         <para>
+         <option>acml</option> selects the AMD Core Math Library (ACML) to 
+         perform linear algebra if found.
+        </para>
+        <para>
          <option>atlas</option> selects the ATLAS library
  	to perform linear algebra if found.
         </para>
***************
*** 812,822 ****
  	(-llapack) to perform linear algebra if found.
         </para>
         <para>
!         <option>builtin</option> selects the builtin version of ATLAS
!         to perform linear algebra.  This option requires building
!         ATLAS which can take considerable time and is not supported
!         on all platforms.  It is only recommended if MKL, ATLAS, or
! 	a generic LAPACK or not already installed on the platform.
         </para>
        </listitem>
       </varlistentry>
--- 824,845 ----
  	(-llapack) to perform linear algebra if found.
         </para>
         <para>
!         <option>builtin</option> selects the builtin version of 
!         ATLAS/C-LAPACK to perform linear algebra.  This option 
!         requires building ATLAS which can take considerable time 
!         and is not supported on all platforms.  It is only recommended 
!         if MKL, ATLAS, or a generic LAPACK or not already installed on 
!         the platform.
!        </para>
!        <para>
!         <option>fortran-builtin</option> selects the builtin version
!         of ATLAS/F77-LAPACK to perform linear algebra.  Like the 
!         <option>builtin</option>, this option requires building ATLAS
!         as well.  In this case, it uses the FORTRAN version instead of
!         the C version of LAPACK.  Note this option requires the g2c
!         library and a fortran compiler.  Use the 
!         <option>--with-g2c-path=</option> option if this library is 
!         not installed in a standard location.
         </para>
        </listitem>
       </varlistentry>
***************
*** 833,838 ****
--- 856,879 ----
       </varlistentry>
  
       <varlistentry>
+       <term><option>--with-acml-prefix=<replaceable>directory</replaceable></option></term>
+       <listitem>
+        <para>
+ 	Search for ACML installation in
+ 	<replaceable>directory</replaceable> first.  ACML headers
+ 	should be in the <filename>include</filename> subdirectory of
+         the install directory, which depends on the exact version of
+         the library you have.  Similarly, ACML  libraries should
+ 	be in the <filename>lib</filename> subdirectory.  This option
+ 	has the effect of enabling ACML for lapack
+ 	(i.e. <option>--with-lapack=acml</option>).  This option is useful
+ 	if the ACML is installed in a non-standard location, or if multiple
+ 	ACML versions are installed.
+        </para>
+       </listitem>
+      </varlistentry>
+ 
+      <varlistentry>
        <term><option>--with-atlas-prefix=<replaceable>directory</replaceable></option></term>
        <listitem>
         <para>
