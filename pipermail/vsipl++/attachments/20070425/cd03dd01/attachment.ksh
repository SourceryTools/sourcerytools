Index: ChangeLog
===================================================================
--- ChangeLog	(revision 169480)
+++ ChangeLog	(working copy)
@@ -1,5 +1,22 @@
 2007-04-22  Jules Bergmann  <jules@codesourcery.com>
+
+	* configure.ac: Fix typos with exception option handling.
 	
+	* LICNESE.Commercial: New file, commercial license for Sourcery
+	  VSIPL++.
+	* LICENSE: Refer to LICENSE.Commercial.
+	
+	* scripts/config: New packages for Cell BE and MCOE.
+	
+	* src/vsip/core/ops_info.hpp (vsip::impl::signal): Rename to
+	  vsip::impl::signal_detail to make GHS C++ happy.
+	* src/vsip/core/signal/fir.hpp: Likewise.
+	* src/vsip/core/signal/iir.hpp: Likewise.
+	* src/vsip/core/signal/conv.hpp: Likewise.
+	* src/vsip/core/signal/corr.hpp: Likewise.
+	
+2007-04-22  Jules Bergmann  <jules@codesourcery.com>
+	
 	* scripts/package.py (read_config_dir): Use Source class to
 	  describe source configuration.  Add 'include' function to
 	  nest cfg files.
Index: configure.ac
===================================================================
--- configure.ac	(revision 169365)
+++ configure.ac	(working copy)
@@ -628,7 +628,7 @@
                      not supported by the compiler]) ])
      fi
 else
-  has_exceptions=1
+  has_exceptions=0
 fi
 
 if test "$enable_exceptions" = "probe"; then
@@ -2605,7 +2605,7 @@
 AC_MSG_NOTICE(Summary)
 AC_MSG_RESULT([Build in maintainer-mode:                $maintainer_mode])
 AC_MSG_RESULT([Using config suffix:                     $suffix])
-AC_MSG_RESULT([Exceptions enabled:                      $exceptions_status])
+AC_MSG_RESULT([Exceptions enabled:                      $exception_status])
 AC_MSG_RESULT([With mpi enabled:                        $enable_mpi])
 AC_MSG_RESULT([With PAS enabled:                        $enable_pas])
 if test "$PAR_SERVICE" != "none"; then
Index: LICENSE.Commercial
===================================================================
--- LICENSE.Commercial	(revision 0)
+++ LICENSE.Commercial	(revision 0)
@@ -0,0 +1,326 @@
+Sourcery VSIPL++ License Agreement
+
+1. Parties.  The parties to this Agreement are you, the licensee
+("You" or "Licensee") and CodeSourcery.  If You are not acting on
+behalf of Yourself as an individual, then "You" means Your company or
+Organization.
+
+2. Definitions.
+
+2.1. "Authorized Users."  The developers for whom license fees are
+fully paid by Licensee and that are authorized to use the Software.
+The number of Authorized Users is provided on the Confidential Price
+Quotation.  This number may be increased by Licensee from time-to-time
+by purchasing additional licenses as provided below.
+
+2.2. "Composite Product(s)."  Software and/or hardware
+products produced by Licensee for distribution hereunder that result
+from the integration and merger of Licensee products with Software
+licensed and provided by CodeSourcery hereunder.
+
+2.3. "Effective Date."  The date on which Licensee executes this
+Agreement or the date on which CodeSourcery gives Licensee access to
+CodeSourcery's electronic support system, whichever is later.
+
+2.4. "Proprietary Rights."  All rights in and to copyrights, rights to
+register copyrights, trade secrets, inventions, patents, patent
+rights, trademarks, trademark rights, confidential and proprietary
+information protected under contract or otherwise under law, and other
+similar rights or interests in intellectual or industrial property.
+
+2.5. "Software."  Libraries, in source code and binary form, and
+documentation referred to as Sourcery VSIPL++(tm) (the "Software"),
+including any Updates thereto.
+
+2.6. "Supported Platforms."  The set of host and target platforms for
+which CodeSourcery will provide support under this Agreement as set
+forth on the Confidential Price Quotation.
+
+3. License to Software for Internal Use.  Subject to the terms and
+conditions hereof, and only for the term hereof, CodeSourcery hereby
+grants to Licensee, and Licensee hereby accepts, a limited,
+non-exclusive license under the Proprietary Rights of CodeSourcery to
+install and use the Software by the Authorized Users for internal use.
+
+4. Integration and Merger License.  Subject to the terms and
+conditions hereof, and only for the term hereof, CodeSourcery hereby
+grants to Licensee the right and license to create derivative works
+based on the Software to create Composite Product(s), using the
+Software to be provided by CodeSourcery, provided that a Composite
+Product may not be a signal- or image-processing toolkit or library
+and must provide substantially different functionality than the
+Software.
+
+5. Distribution License.  Subject to the terms and conditions hereof
+and only for the term hereof, CodeSourcery hereby grants to Licensee
+the right and license to use, reproduce, publicly display, publish,
+and distribute the Composite Product(s) in object code form only,
+throughout Licensee's normal distribution channels.
+
+6. Subscription Term.  This Agreement shall have a term of one (1)
+year.  The initial subscription term of this Agreement shall commence
+as of the Effective Date hereof and shall continue for a period of one
+(1) year.  The initial subscription term shall automatically renew for
+successive one (1) year terms unless either party notifies the other
+in writing not less than ninety (90) days prior to the expiration of
+the current term of its intention not to renew.
+
+7. Updates.  During the term of this Agreement, Licensee may download,
+free of charge, any new version(s), update(s), or upgrade(s)
+("Updates") to the Software that CodeSourcery makes available through
+CodeSourcery's electronic support system at such times as may be
+determined by CodeSourcery in its sole discretion.
+
+8. License And Technical Support Fees.  License fees and technical
+support fees are combined under this Agreement and are payable
+annually, in advance, within thirty (30) days of the Effective Date.
+The fee for the initial subscription term is provided on the
+Confidential Price Quotation, and the renewal fees shall increase by
+3% annually.  Renewal fees are due and payable on each anniversary of
+the Effective Date.  All fees are non-refundable and are exclusive of
+sales or use taxes and any levy imposed on the transportation or use
+of the Software.  Licensee shall pay all such charges either as levied
+by taxing authorities or as invoiced by CodeSourcery.
+
+9. Purchase of Additional Licenses.  If Licensee purchases license
+rights for additional Authorized Users, such additional licenses shall
+be governed by the terms and conditions hereof.  Except as may be
+expressly provided on the Confidential Price Quotation, pricing for
+additional licenses shall be in accordance with CodeSourcery's
+then-current price list, which may be updated by CodeSourcery from
+time to time, pro- rated as appropriate for the remainder of the
+current subscription term.  Licensee agrees that, absent
+CodeSourcery's express written acceptance thereof, the terms and
+conditions contained in any purchase order or other document issued by
+Licensee to CodeSourcery for the purchase of additional licenses,
+shall not be binding on CodeSourcery to the extent that such terms and
+conditions are additional to or inconsistent with those contained in
+this Agreement.
+ 
+10. Technical Support.
+
+10.1. Scope of Support.  CodeSourcery shall assist Licensee in
+installing and using the Software in binary form.  CodeSourcery shall
+correct defects in the Software reported by Customer, subject to the
+limitations set forth below.  CodeSourcery shall impose no limit on
+the number of support requests made by Licensee.
+
+10.2. Electronic Support System.  Licensee shall make all support
+requests via CodeSourcery's electronic support system, and
+CodeSourcery shall respond via the same electronic support system.
+Licensee shall appoint up to two Technical Contacts, who will be
+provided access to CodeSourcery's electronic support system.  Licensee
+may replace either or both of the Technical Contacts from time to time
+by written notification to CodeSourcery.  CodeSourcery will not accept
+support requests by telephone or other means.
+
+10.3. Response Time.  CodeSourcery's electronic support system will
+provide Licensee with an immediate acknowledgement of the support
+request (including a unique tracking number) by electronic mail.
+CodeSourcery shall respond to all support requests within one business
+day, except in extraordinary circumstances.  CodeSourcery shall
+attempt to resolve all support requests within three business days.
+
+10.4. No Guarantee of Resolution.  CodeSourcery does not guarantee
+that it will be able to resolve all support requests.  Without
+limitation, CodeSourcery may, in its sole discretion, determine that a
+defect in the Software is too difficult to correct, or than any
+correction would likely risk the introduction of additional defects,
+or that the defect is not likely to be encountered often enough to be
+worthy of correction, or that the defect is insufficiently severe to
+be worthy of correction.
+
+10.5. Support for Previous Versions.  After the release of an Update
+for a Supported Platform, CodeSourcery shall provide support for
+previous version(s) of the Software for a period of six (6) months.
+CodeSourcery will have no obligation to provide support after this
+period.
+
+11. Termination.
+
+11.1. Grounds for Termination.  CodeSourcery may terminate this
+Agreement upon thirty (30) days written notice of a material breach of
+this Agreement if such breach is not cured; provided that the
+distribution of the Software in source code form will be deemed a
+material breach that cannot be cured.
+
+11.2. Effects of Expiration or Termination.  Upon the expiration or
+termination hereof, Licensee shall cease distributing Composite
+Product(s) incorporating the Software.  Notwithstanding anything to
+the contrary contained herein, sublicenses for all Composite
+Product(s) in any form, including any derivative works based on
+Software, granted by Licensee prior to the expiration date or the
+effective date of termination of this Agreement shall remain in full
+force and effect following such dates.
+
+11.3. Continuing Obligations.  The following obligations shall survive
+the expiration or termination hereof: (i) any and all warranty
+disclaimers or limitations of liability herein, (ii) any covenant
+granted herein for the purpose of determining ownership of, or
+protecting, the Proprietary Rights, or any remedy for breach thereof,
+and (iii) the payment of taxes, duties, or any fees to CodeSourcery
+hereunder.
+
+12. Confidentiality of Licensed Software.  Licensee acknowledges
+CodeSourcery's claim that the Software embodies valuable trade secrets
+consisting of algorithms, logic, design, and coding methodology
+proprietary to CodeSourcery.  Licensee shall safeguard the
+confidentiality of the Software, using the same standard of care which
+Licensee uses for its similar confidential materials, but in no event
+less than reasonable care.  Licensee shall not: (i) distribute,
+transfer, loan, rent, or provide access to the Software, except as
+provided herein; or (ii) remove or add any Proprietary Rights notice
+associated with the Software without the express written permission of
+CodeSourcery.
+
+13. Assignment and Transfers.  Licensee may not transfer any rights
+under this Agreement without the prior written consent of
+CodeSourcery, which consent shall not be unreasonably withheld.  A
+condition to any transfer or assignment shall be that the recipient
+agrees to the terms of this Agreement.  Any attempted transfer or
+assignment in violation of this provision shall be null and void.
+
+14. Ownership.  CodeSourcery owns the Software and all Proprietary
+Rights embodied therein, including copyrights and valuable trade
+secrets embodied in its design and coding methodology.  The Software
+is protected by United States copyright laws and international treaty
+provisions.  CodeSourcery also owns all rights, title and interest in
+and with respect to its trade names, domain names, trade dress, logos,
+trademarks, service marks, and other similar rights or interests in
+intellectual property.  This Agreement provides Licensee only a
+limited use license, and no ownership of any intellectual property.
+
+15. Warranty Disclaimer; Limitation of Liability.  CODESOURCERY
+PROVIDES THE SOFTWARE "AS-IS".  CODESOURCERY DOES NOT MAKE ANY
+WARRANTY OF ANY KIND, EXPRESS OR IMPLIED.  CODESOURCERY SPECIFICALLY
+DISCLAIMS THE IMPLIED WARRANTIES OF TITLE, NON- INFRINGEMENT,
+MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, SYSTEM INTEGRATION,
+AND DATA ACCURACY.  THERE IS NO WARRANTY OR GUARANTEE THAT THE
+OPERATION OF THE SOFTWARE WILL BE UNINTERRUPTED, ERROR-FREE, OR
+VIRUS-FREE, OR THAT THE SOFTWARE WILL MEET ANY PARTICULAR CRITERIA OF
+PERFORMANCE, QUALITY, ACCURACY, PURPOSE, OR NEED.  LICENSEE ASSUMES
+THE ENTIRE RISK OF SELECTION, INSTALLATION, AND USE OF THE SOFTWARE.
+THIS DISCLAIMER OF WARRANTY CONSTITUTES AN ESSENTIAL PART OF THIS
+AGREEMENT.  NO USE OF THE SOFTWARE IS AUTHORIZED HEREUNDER EXCEPT
+UNDER THIS DISCLAIMER.
+
+16. Local Law.  If implied warranties may not be disclaimed under
+applicable law, then ANY IMPLIED WARRANTIES ARE LIMITED IN DURATION TO
+THE PERIOD REQUIRED BY APPLICABLE LAW.
+
+17. Limitation of Liability.  INDEPENDENT OF THE FORGOING PROVISIONS,
+IN NO EVENT AND UNDER NO LEGAL THEORY, INCLUDING WITHOUT LIMITATION,
+TORT, CONTRACT, OR STRICT PRODUCTS LIABILITY, SHALL EITHER PARTY BE
+LIABLE TO THE OTHER OR ANY OTHER PERSON FOR ANY INDIRECT, SPECIAL,
+INCIDENTAL, OR CONSEQUENTIAL DAMAGES OF ANY KIND, INCLUDING WITHOUT
+LIMITATION, DAMAGES FOR LOSS OF GOODWILL, WORK STOPPAGE, COMPUTER
+MALFUNCTION, OR ANY OTHER KIND OF COMMERCIAL DAMAGE, EVEN IF THE PARTY
+HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.  THIS LIMITATION
+SHALL NOT APPLY TO LIABILITY FOR DEATH OR PERSONAL INJURY TO THE
+EXTENT PROHIBITED BY APPLICABLE LAW.  IN NO EVENT SHALL CODESOURCERY'S
+LIABILITY FOR ACTUAL DAMAGES FOR ANY CAUSE WHATSOEVER, AND REGARDLESS
+OF THE FORM OF ACTION, EXCEED THE AMOUNT PAID BY LICENSE UNDER THIS
+AGREEMENT DURING THE APPLICABLE SUBSCRIPTION TERM.
+
+18. Non-Exclusive Licenses.  The licenses granted herein are
+non-exclusive.  CodeSourcery may compete with Licensee, and
+CodeSourcery may grant licenses to third parties who may compete with
+Licensee.
+
+19. Reservation of Rights.  All rights not expressly granted to
+Licensee herein are expressly reserved by CodeSourcery.
+
+20. Export Controls.  Licensee agrees to comply with all export laws
+and restrictions and regulations of the United States or foreign
+agencies or authorities, and not to export or re-export the Software
+or any direct product thereof in violation of any such restrictions,
+laws or regulations, or without all necessary approvals.  As
+applicable, each party shall obtain and bear all expenses relating to
+any necessary licenses and/or exemptions with respect to its own
+export of the Software from the U.S.  Neither the Software nor the
+underlying information or technology may be electronically transmitted
+or otherwise exported or re-exported (i) into Cuba, Iran, Iraq, Libya,
+North Korea, Sudan, Syria or any other country subject to U.S. trade
+sanctions covering the Software, to individuals or entities controlled
+by such countries, or to nationals or residents of such countries
+other than nationals who are lawfully admitted permanent residents of
+countries not subject to such sanctions; or (ii) to anyone on the
+U.S. Treasury Department's list of Specially Designated Nationals and
+Blocked Persons or the U.S. Commerce Department's Table of Denial
+Orders.  Licensee is responsible for complying with any local laws in
+Licensee's jurisdiction which might impact Licensee's right to import,
+export or use the Software, and Licensee represents that Licensee has
+complied with any regulations or registration procedures required by
+applicable law to make this license enforceable.
+
+21. Severability.  If any provision of this Agreement is declared
+invalid or unenforceable, such provision shall be deemed modified to
+the extent necessary and possible to render it valid and enforceable.
+In any event, the unenforceability or invalidity of any provision
+shall not affect any other provision of this Agreement, and this
+Agreement shall continue in full force and effect, and be construed
+and enforced, as if such provision had not been included, or had been
+modified as above provided, as the case may be.
+
+22. Arbitration.  Except for actions to protect intellectual property
+rights and to enforce an arbitrator's decision hereunder, all
+disputes, controversies, or claims arising out of or relating to this
+Agreement or a breach thereof shall be submitted to and finally
+resolved by arbitration under the rules of the American Arbitration
+Association ("AAA") then in effect. There shall be one arbitrator, and
+such arbitrator shall be chosen by mutual agreement of the parties in
+accordance with AAA rules. The arbitration shall take place in Granite
+Bay, California, and may be conducted by telephone or online. The
+arbitrator shall apply the laws of the State of California, USA to all
+issues in dispute. The controversy or claim shall be arbitrated on an
+individual basis, and shall not be consolidated in any arbitration
+with any claim or controversy of any other party. The findings of the
+arbitrator shall be final and binding on the parties, and may be
+entered in any court of competent jurisdiction for
+enforcement. Enforcements of any award or judgment shall be governed
+by the United Nations Convention on the Recognition and Enforcement of
+Foreign Arbitral Awards. Should either party file an action contrary
+to this provision, the other party may recover attorney's fees and
+costs up to $1000.00.
+
+23. U.S. Government End-Users. The Software is a "commercial item," as
+that term is defined in 48 C.F.R. 2.101 (Oct. 1995), consisting of
+"commercial computer software" and "commercial computer software
+documentation," as such terms are used in 48 C.F.R.  12.212
+(Sept. 1995). Consistent with 48 C.F.R. 12.212 and 48
+C.F.R. 227.7202-1 through 227.7202-4 (June 1995), all U.S. Government
+End Users acquire the Software with only those rights set forth
+herein.
+
+24. Jurisdiction And Venue.  The courts of Placer County in the State
+of California, USA and the nearest U.S. District Court shall be the
+exclusive jurisdiction and venue for all legal proceedings relating to
+this Agreement.
+
+25. Independent Contractors.  The relationship of the parties is that
+of independent contractor, and nothing herein shall be construed to
+create a partnership, joint venture, franchise, employment, or agency
+relationship between the parties.  Licensee shall have no authority to
+enter into agreements of any kind on behalf of CodeSourcery and shall
+not have the power or authority to bind or obligate CodeSourcery in
+any manner to any third party.
+
+26. Force Majeure.  Neither CodeSourcery nor Licensee shall be liable
+for damages for any delay or failure of delivery arising out of causes
+beyond their reasonable control and without their fault or negligence,
+including, but not limited to, Acts of God, acts of civil or military
+authority, fires, riots, wars, embargoes, or communications failures.
+
+27. Miscellaneous.  This Agreement constitutes the entire
+understanding of the parties with respect to the subject matter of
+this Agreement and merges all prior communications, representations,
+and agreements. This Agreement may be modified only by a written
+agreement signed by the parties.  If any provision of this Agreement
+is held to be unenforceable for any reason, such provision shall be
+reformed only to the extent necessary to make it enforceable.  This
+Agreement shall be construed under the laws of the State of
+California, USA, excluding rules regarding conflicts of law.  The
+application the United Nations Convention of Contracts for the
+International Sale of Goods is expressly excluded.  This license is
+written in English, and English is its controlling language.
+
Index: LICENSE
===================================================================
--- LICENSE	(revision 167964)
+++ LICENSE	(working copy)
@@ -2,9 +2,10 @@
 
 1) Commercial Optimized Implementation
 
-  The entire library is available under the terms of a commercial license.  
-  Please contact CodeSourcery (1-888-776-0262 or sales@codesourcery.com) 
-  for details.
+  The entire library is available under the terms of a commercial license,
+  described in the file LICENSE.Commercial.  Please contact CodeSourcery
+  (1-888-776-0262 or sales@codesourcery.com) for details on obtaining
+  rights to use the library under this license.
 
 2) GPL Optimized Implementation
 
Index: scripts/config
===================================================================
--- scripts/config	(revision 167964)
+++ scripts/config	(working copy)
@@ -55,6 +55,7 @@
 pas_dir = '/usr/local/tools/vpp-1.0/pas'
 
 cvsip_dir = '/usr/local/tools/vpp-1.0'
+cvsip_dir = '/home/jules/csl/src/tvcpp/debug'
 
 
 
@@ -466,6 +467,248 @@
 
 
 ########################################################################
+# Cell BE Package
+########################################################################
+
+cbe_cc     = 'ppu-gcc'
+cbe_cxx    = 'ppu-g++'
+cbe_common = ['--enable-timer=power_tb',
+	      '--with-complex=split',
+	      '--disable-fft-long-double']
+
+
+cbe32_sdk_dir = '/scratch/jules/cell-sdk'
+cbe32_mpi_dir = '/usr/local/tools/sdk'
+cbe32_flags_generic = ['-m32', '-mcpu=cell', '-maltivec']
+cbe32_mpi = ['--enable-mpi=openmpi', '--with-mpi-prefix=%s'%cbe32_mpi_dir]
+
+cbe64_sdk_dir = '/scratch/jules/cell-sdk-64'
+cbe64_mpi_dir = '/usr/local/tools/sdk-INVALID'
+cbe64_flags_generic = ['-m64', '-mcpu=cell', '-maltivec']
+cbe64_mpi = ['--enable-mpi=openmpi', '--with-mpi-prefix=%s'%cbe64_mpi_dir]
+
+class CellBE(Package):
+
+    class Ser32Release(Configuration):
+	builtin_libdir = 'ppc32'
+	libdir         = 'ppc32/ser'
+        suffix = '-32-ser'
+        options = ['CC=%s'%cbe_cc,
+	           'CXX=%s'%cbe_cxx,
+	           'CXXFLAGS="%s"'%' '.join(release + cbe32_flags_generic),
+                   'CFLAGS="%s"'%' '.join(['-O2'] + cbe32_flags_generic),
+                   'FFLAGS="%s"'%' '.join(cbe32_flags_generic),
+                   'LDFLAGS="%s"'%' '.join(cbe32_flags_generic),
+                   '--with-cbe-sdk-prefix=%s'%cbe32_sdk_dir,
+		   '--enable-fft=builtin',
+		   '--with-lapack=no',
+                  ] + nompi + cbe_common + simd
+
+    class Ser32Debug(Configuration):
+	builtin_libdir = 'ppc32'
+	libdir         = 'ppc32/ser-debug'
+        suffix = '-32-ser-debug'
+        options = ['CC=%s'%cbe_cc,
+	           'CXX=%s'%cbe_cxx,
+	           'CXXFLAGS="%s"'%' '.join(cbe32_flags_generic),
+                   'CFLAGS="%s"'%' '.join(cbe32_flags_generic),
+                   'FFLAGS="%s"'%' '.join(cbe32_flags_generic),
+                   'LDFLAGS="%s"'%' '.join(cbe32_flags_generic),
+                   '--with-cbe-sdk-prefix=%s'%cbe32_sdk_dir,
+		   '--enable-fft=builtin',
+		   '--with-lapack=no',
+                  ] + nompi + cbe_common + simd
+
+    class Par32Release(Configuration):
+	builtin_libdir = 'ppc32'
+	libdir         = 'ppc32/par'
+        suffix = '-32-par'
+        options = ['CC=%s'%cbe_cc,
+	           'CXX=%s'%cbe_cxx,
+	           'CXXFLAGS="%s"'%' '.join(release + cbe32_flags_generic),
+                   'CFLAGS="%s"'%' '.join(['-O2'] + cbe32_flags_generic),
+                   'FFLAGS="%s"'%' '.join(cbe32_flags_generic),
+                   'LDFLAGS="%s"'%' '.join(cbe32_flags_generic),
+                   '--with-cbe-sdk-prefix=%s'%cbe32_sdk_dir,
+		   '--enable-fft=builtin',
+		   '--with-lapack=no',
+                  ] + cbe32_mpi + cbe_common + simd
+
+    class Par32Debug(Configuration):
+	builtin_libdir = 'ppc32'
+	libdir         = 'ppc32/par-debug'
+        suffix = '-32-par-debug'
+        options = ['CC=%s'%cbe_cc,
+	           'CXX=%s'%cbe_cxx,
+	           'CXXFLAGS="%s"'%' '.join(cbe32_flags_generic),
+                   'CFLAGS="%s"'%' '.join(cbe32_flags_generic),
+                   'FFLAGS="%s"'%' '.join(cbe32_flags_generic),
+                   'LDFLAGS="%s"'%' '.join(cbe32_flags_generic),
+                   '--with-cbe-sdk-prefix=%s'%cbe32_sdk_dir,
+		   '--enable-fft=builtin',
+		   '--with-lapack=no',
+                  ] + cbe32_mpi + cbe_common + simd
+
+    suffix = '-linux'
+    host = 'cbe'
+  
+    ser_32_relase     = Ser32Release
+    ser_32_debug      = Ser32Debug
+    par_32_relase     = Par32Release
+    par_32_debug      = Par32Debug
+
+
+
+########################################################################
+# MCOE Package
+########################################################################
+
+# Processor Flags.
+mcoe_ppc_flags_proc   = ['-t ppc7447']
+mcoe_ppc_flags_common = ['--no_implicit_include',
+		         '--no_exceptions']
+
+mcoe_ppc_flags_dbg = mcoe_ppc_flags_proc + mcoe_ppc_flags_common + [
+		     '-g']
+
+mcoe_ppc_flags_opt = mcoe_ppc_flags_proc + mcoe_ppc_flags_common + [
+		     '-Ospeed',
+		     '-Onotailrecursion',
+		     '--max_inlining',
+		     '-DNDEBUG',
+		     '--diag_suppress 177,550']
+
+common_mcoe = ['--enable-timer=mcoe_tmr']
+
+mcoe_ppc_flags_ld = mcoe_ppc_flags_proc
+
+small_tests = ' '.join(['check_config.cpp',
+	           'convolution.cpp',
+	           'coverage_binary.cpp',
+	           'dense.cpp',
+	           'domain.cpp',
+	           'fft_be.cpp',
+	           'fftm.cpp',
+	           'fir.cpp',
+	           'matrix-transpose.cpp',
+	           'matrix.cpp',
+	           'matvec.cpp',
+	           'reductions.cpp',
+	           'solver-qr.cpp',
+	           'vector.cpp',
+	           'vmmul.cpp',
+	           'parallel/corner-turn.cpp',
+	           'parallel/expr.cpp',
+	           'parallel/fftm.cpp'])
+
+class MondoMC(Package):
+
+    class SerDebug(Configuration):
+        # tests_ids = small_tests
+	builtin_libdir = 'ppc7447'
+	libdir = 'ppc7447/ser-debug'
+        suffix = '-ser-debug'
+        options = ['CC=ccmc',
+		   'CXX=ccmc++',
+		   'CXXFLAGS="%s"'%' '.join(mcoe_ppc_flags_dbg),
+                   'CFLAGS="%s"'%' '.join(mcoe_ppc_flags_dbg),
+                   'LDFLAGS="%s"'%' '.join(mcoe_ppc_flags_ld),
+		   '--host=powerpc',
+		   '--enable-fft=sal,builtin',
+		   '--with-fftw3-cflags=-O2',
+		   '--with-complex=split',
+		   '--with-lapack=no',
+		   '--enable-sal',
+		   '--disable-mpi',
+		   '--disable-pas',
+		   '--disable-simd-loop-fusion',
+		   '--disable-exceptions',
+		   '--with-qmtest-commandhost=xrun.sh',
+		   '--with-test-level=0',
+		   '--with-builtin-simd-routines=generic',
+                  ] + common_mcoe
+
+    class SerRelease(Configuration):
+        # tests_ids = small_tests
+	builtin_libdir = 'ppc7447'
+	libdir = 'ppc7447/ser'
+        suffix = '-ser'
+        options = ['CC=ccmc',
+		   'CXX=ccmc++',
+		   'CXXFLAGS="%s"'%' '.join(mcoe_ppc_flags_opt),
+                   'CFLAGS="%s"'%' '.join(mcoe_ppc_flags_opt),
+                   'LDFLAGS="%s"'%' '.join(mcoe_ppc_flags_ld),
+		   '--host=powerpc',
+		   '--enable-fft=sal,builtin',
+		   '--with-fftw3-cflags=-O2',
+		   '--with-complex=split',
+		   '--with-lapack=no',
+		   '--enable-sal',
+		   '--disable-mpi',
+		   '--disable-pas',
+		   '--disable-simd-loop-fusion',
+		   '--disable-exceptions',
+		   '--with-qmtest-commandhost=xrun.sh',
+		   '--with-test-level=0',
+		   '--with-builtin-simd-routines=generic',
+                  ] + common_mcoe
+
+    class PasDebug(Configuration):
+        # tests_ids = small_tests
+	builtin_libdir = 'ppc7447'
+	libdir = 'ppc7447/pas-debug'
+        suffix = '-pas-debug'
+        options = ['CC=ccmc',
+		   'CXX=ccmc++',
+		   'CXXFLAGS="%s"'%' '.join(mcoe_ppc_flags_dbg),
+                   'CFLAGS="%s"'%' '.join(mcoe_ppc_flags_dbg),
+                   'LDFLAGS="%s"'%' '.join(mcoe_ppc_flags_ld),
+		   '--host=powerpc',
+		   '--enable-fft=sal,builtin',
+		   '--with-fftw3-cflags=-O2',
+		   '--with-complex=split',
+		   '--with-lapack=no',
+		   '--enable-sal',
+		   '--disable-mpi',
+		   '--enable-pas',
+		   '--disable-simd-loop-fusion',
+		   '--disable-exceptions',
+		   '--with-qmtest-commandhost=xrun-pas.sh',
+		   '--with-test-level=0',
+		   '--with-builtin-simd-routines=generic',
+                  ] + common_mcoe
+
+    class PasRelease(Configuration):
+        # tests_ids = small_tests
+	builtin_libdir = 'ppc7447'
+	libdir = 'ppc7447/pas'
+        suffix = '-pas'
+        options = ['CC=ccmc',
+		   'CXX=ccmc++',
+		   'CXXFLAGS="%s"'%' '.join(mcoe_ppc_flags_opt),
+                   'CFLAGS="%s"'%' '.join(mcoe_ppc_flags_opt),
+                   'LDFLAGS="%s"'%' '.join(mcoe_ppc_flags_ld),
+		   '--host=powerpc',
+		   '--enable-fft=sal,builtin',
+		   '--with-fftw3-cflags=-O2',
+		   '--with-complex=split',
+		   '--with-lapack=no',
+		   '--enable-sal',
+		   '--disable-mpi',
+		   '--enable-pas',
+		   '--disable-simd-loop-fusion',
+		   '--disable-exceptions',
+		   '--with-qmtest-commandhost=xrun.sh',
+		   '--with-test-level=0',
+		   '--with-builtin-simd-routines=generic',
+                  ] + common_mcoe
+
+    suffix = '-mcoe'
+    host = 'ppc'
+
+
+
+########################################################################
 # Test Packages
 ########################################################################
 
Index: src/vsip/core/signal/fir.hpp
===================================================================
--- src/vsip/core/signal/fir.hpp	(revision 168761)
+++ src/vsip/core/signal/fir.hpp	(working copy)
@@ -63,8 +63,9 @@
       length_type input_size,
       length_type decimation = 1)
     VSIP_THROW((std::bad_alloc))
-    : accumulator_type(impl::signal::Description<1, T>::tag("Fir", input_size), 
-                       impl::signal::Op_count_fir<T>::value
+    : accumulator_type(impl::signal_detail::Description<1, T>::tag(
+			 "Fir", input_size), 
+                       impl::signal_detail::Op_count_fir<T>::value
                        (backend::order(kernel.size()), input_size, decimation)),
 #ifdef VSIP_IMPL_REF_IMPL
       backend_(new impl::cvsip::Fir_impl<T, S, C>
Index: src/vsip/core/signal/iir.hpp
===================================================================
--- src/vsip/core/signal/iir.hpp	(revision 168761)
+++ src/vsip/core/signal/iir.hpp	(working copy)
@@ -38,8 +38,9 @@
   template <typename Block0, typename Block1>
   Iir(const_Matrix<T, Block0> b, const_Matrix<T, Block1> a, length_type i)
     VSIP_THROW((std::bad_alloc))
-  : accumulator_type(impl::signal::Description<1, T>::tag("Iir", i), 
-                     impl::signal::Op_count_iir<T>::value(i, a.size(0))),
+  : accumulator_type(impl::signal_detail::Description<1, T>::tag("Iir", i), 
+                     impl::signal_detail::Op_count_iir<T>::value(i,
+								 a.size(0))),
     b_(b.size(0), b.size(1)),
     a_(a.size(0), a.size(1)),
     w_(b_.size(0), 2, T()),
Index: src/vsip/core/signal/conv.hpp
===================================================================
--- src/vsip/core/signal/conv.hpp	(revision 168761)
+++ src/vsip/core/signal/conv.hpp	(working copy)
@@ -102,13 +102,13 @@
 	      Domain<dim> const&   input_size,
 	      length_type          decimation = 1)
     VSIP_THROW((std::bad_alloc))
-      : accumulator_type(impl::signal::Description<dim, T>::tag
+      : accumulator_type(impl::signal_detail::Description<dim, T>::tag
                          ("Convolution",
                           impl::extent(impl::conv_output_size
                                        (Supp, view_domain(filter_coeffs), 
                                         input_size, decimation)),
                           impl::extent(filter_coeffs)),
-                         impl::signal::Op_count_conv<dim, T>::value
+                         impl::signal_detail::Op_count_conv<dim, T>::value
                          (impl::extent(impl::conv_output_size
                                        (Supp, view_domain(filter_coeffs),
                                         input_size, decimation)),
Index: src/vsip/core/signal/corr.hpp
===================================================================
--- src/vsip/core/signal/corr.hpp	(revision 168761)
+++ src/vsip/core/signal/corr.hpp	(working copy)
@@ -89,10 +89,10 @@
   Correlation(Domain<dim> const&   ref_size,
 	      Domain<dim> const&   input_size)
     VSIP_THROW((std::bad_alloc))
-      : accumulator_type(impl::signal::Description<dim, T>::tag
+      : accumulator_type(impl::signal_detail::Description<dim, T>::tag
                          ("Correlation",
                           impl::extent(input_size), impl::extent(ref_size)),
-                         impl::signal::Op_count_corr<dim, T>::value
+                         impl::signal_detail::Op_count_corr<dim, T>::value
                          (impl::extent(input_size), impl::extent(ref_size))),
         base_type(ref_size, input_size)
   {}
Index: src/vsip/core/ops_info.hpp
===================================================================
--- src/vsip/core/ops_info.hpp	(revision 168761)
+++ src/vsip/core/ops_info.hpp	(working copy)
@@ -100,7 +100,7 @@
 } // namespace fft
 
 
-namespace signal
+namespace signal_detail
 {
 
 template <dimension_type D,
@@ -180,7 +180,7 @@
   } 
 };
 
-} // namespace signal
+} // namespace signal_detail
 
 
 namespace matvec
