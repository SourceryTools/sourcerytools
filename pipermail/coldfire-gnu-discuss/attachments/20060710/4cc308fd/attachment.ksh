diff -ruN linux-2.6.10.orig/arch/m68k/coldfire/dma.c linux-2.6.10/arch/m68k/coldfire/dma.c
--- linux-2.6.10.orig/arch/m68k/coldfire/dma.c	2006-06-16 09:22:49.000000000 -0600
+++ linux-2.6.10/arch/m68k/coldfire/dma.c	2006-06-12 14:55:43.000000000 -0600
@@ -492,7 +492,7 @@
 		used_channel[channel] = -1;
 }
 
-static int __devinit
+int __devinit
 dma_init()
 {
 	int result;
diff -ruN linux-2.6.10.orig/arch/m68k/coldfire/head.S linux-2.6.10/arch/m68k/coldfire/head.S
--- linux-2.6.10.orig/arch/m68k/coldfire/head.S	2006-06-16 09:22:49.000000000 -0600
+++ linux-2.6.10/arch/m68k/coldfire/head.S	2006-06-16 11:19:03.000000000 -0600
@@ -316,10 +316,10 @@
 	
 
 	/* if you change this to some other value be sure to
-	make a matching change in paging_init (mcfmmu.h), the
+	make a matching change in paging_init (cf-mmu.c), the
 	initializing of zone_size[].  */
 
-	/* Map first 16 MB as code */
+	/* Map first 8 MB as code */
 	mmu_map	(PAGE_OFFSET+0*1024*1024),  (0*1024*1024), MMUOR_ITLB, 0, MMUTR_SG, MMUDR_SZ1M, MMUDR_IC,  MMUDR_SP, 0, 0, MMUDR_X, MMUDR_LK, %d0
 	mmu_map	(PAGE_OFFSET+1*1024*1024),  (1*1024*1024), MMUOR_ITLB, 0, MMUTR_SG, MMUDR_SZ1M, MMUDR_IC,  MMUDR_SP, 0, 0, MMUDR_X, MMUDR_LK, %d0
 	mmu_map	(PAGE_OFFSET+2*1024*1024),  (2*1024*1024), MMUOR_ITLB, 0, MMUTR_SG, MMUDR_SZ1M, MMUDR_IC,  MMUDR_SP, 0, 0, MMUDR_X, MMUDR_LK, %d0
@@ -328,33 +328,17 @@
 	mmu_map	(PAGE_OFFSET+5*1024*1024),  (5*1024*1024), MMUOR_ITLB, 0, MMUTR_SG, MMUDR_SZ1M, MMUDR_IC,  MMUDR_SP, 0, 0, MMUDR_X, MMUDR_LK, %d0
 	mmu_map	(PAGE_OFFSET+6*1024*1024),  (6*1024*1024), MMUOR_ITLB, 0, MMUTR_SG, MMUDR_SZ1M, MMUDR_IC,  MMUDR_SP, 0, 0, MMUDR_X, MMUDR_LK, %d0
 	mmu_map	(PAGE_OFFSET+7*1024*1024),  (7*1024*1024), MMUOR_ITLB, 0, MMUTR_SG, MMUDR_SZ1M, MMUDR_IC,  MMUDR_SP, 0, 0, MMUDR_X, MMUDR_LK, %d0
-	mmu_map	(PAGE_OFFSET+8*1024*1024),  (8*1024*1024), MMUOR_ITLB, 0, MMUTR_SG, MMUDR_SZ1M, MMUDR_IC,  MMUDR_SP, 0, 0, MMUDR_X, MMUDR_LK, %d0
-	mmu_map	(PAGE_OFFSET+9*1024*1024),  (9*1024*1024), MMUOR_ITLB, 0, MMUTR_SG, MMUDR_SZ1M, MMUDR_IC,  MMUDR_SP, 0, 0, MMUDR_X, MMUDR_LK, %d0
-	mmu_map	(PAGE_OFFSET+10*1024*1024), (10*1024*1024), MMUOR_ITLB, 0, MMUTR_SG, MMUDR_SZ1M, MMUDR_IC,  MMUDR_SP, 0, 0, MMUDR_X, MMUDR_LK, %d0
-	mmu_map	(PAGE_OFFSET+11*1024*1024), (11*1024*1024), MMUOR_ITLB, 0, MMUTR_SG, MMUDR_SZ1M, MMUDR_IC,  MMUDR_SP, 0, 0, MMUDR_X, MMUDR_LK, %d0
-	mmu_map	(PAGE_OFFSET+12*1024*1024), (12*1024*1024), MMUOR_ITLB, 0, MMUTR_SG, MMUDR_SZ1M, MMUDR_IC,  MMUDR_SP, 0, 0, MMUDR_X, MMUDR_LK, %d0
-	mmu_map	(PAGE_OFFSET+13*1024*1024), (13*1024*1024), MMUOR_ITLB, 0, MMUTR_SG, MMUDR_SZ1M, MMUDR_IC,  MMUDR_SP, 0, 0, MMUDR_X, MMUDR_LK, %d0
-	mmu_map	(PAGE_OFFSET+14*1024*1024), (14*1024*1024), MMUOR_ITLB, 0, MMUTR_SG, MMUDR_SZ1M, MMUDR_IC,  MMUDR_SP, 0, 0, MMUDR_X, MMUDR_LK, %d0
-	mmu_map	(PAGE_OFFSET+15*1024*1024), (15*1024*1024), MMUOR_ITLB, 0, MMUTR_SG, MMUDR_SZ1M, MMUDR_IC,  MMUDR_SP, 0, 0, MMUDR_X, MMUDR_LK, %d0
 
 	
-	/* Map first 16 MB as data too.  */
-	mmu_map	(PAGE_OFFSET+0*1024*1024),  (0*1024*1024), 0, 0, MMUTR_SG, MMUDR_SZ1M, MMUDR_DNCP/*CB*/, MMUDR_SP, MMUDR_R, MMUDR_W, 0, MMUDR_LK, %d0
-	mmu_map	(PAGE_OFFSET+1*1024*1024),  (1*1024*1024), 0, 0, MMUTR_SG, MMUDR_SZ1M, MMUDR_DNCP/*CB*/, MMUDR_SP, MMUDR_R, MMUDR_W, 0, MMUDR_LK, %d0
-	mmu_map	(PAGE_OFFSET+2*1024*1024),  (2*1024*1024), 0, 0, MMUTR_SG, MMUDR_SZ1M, MMUDR_DNCP/*CB*/, MMUDR_SP, MMUDR_R, MMUDR_W, 0, MMUDR_LK, %d0
-	mmu_map	(PAGE_OFFSET+3*1024*1024),  (3*1024*1024), 0, 0, MMUTR_SG, MMUDR_SZ1M, MMUDR_DNCP/*CB*/, MMUDR_SP, MMUDR_R, MMUDR_W, 0, MMUDR_LK, %d0
-	mmu_map	(PAGE_OFFSET+4*1024*1024),  (4*1024*1024), 0, 0, MMUTR_SG, MMUDR_SZ1M, MMUDR_DNCP/*CB*/, MMUDR_SP, MMUDR_R, MMUDR_W, 0, MMUDR_LK, %d0
-	mmu_map	(PAGE_OFFSET+5*1024*1024),  (5*1024*1024), 0, 0, MMUTR_SG, MMUDR_SZ1M, MMUDR_DNCP/*CB*/, MMUDR_SP, MMUDR_R, MMUDR_W, 0, MMUDR_LK, %d0
-	mmu_map	(PAGE_OFFSET+6*1024*1024),  (6*1024*1024), 0, 0, MMUTR_SG, MMUDR_SZ1M, MMUDR_DNCP/*CB*/, MMUDR_SP, MMUDR_R, MMUDR_W, 0, MMUDR_LK, %d0
-	mmu_map	(PAGE_OFFSET+7*1024*1024),  (7*1024*1024), 0, 0, MMUTR_SG, MMUDR_SZ1M, MMUDR_DNCP/*CB*/, MMUDR_SP, MMUDR_R, MMUDR_W, 0, MMUDR_LK, %d0
-	mmu_map	(PAGE_OFFSET+8*1024*1024),  (8*1024*1024), 0, 0, MMUTR_SG, MMUDR_SZ1M, MMUDR_DNCP/*CB*/, MMUDR_SP, MMUDR_R, MMUDR_W, 0, MMUDR_LK, %d0
-	mmu_map	(PAGE_OFFSET+9*1024*1024),  (9*1024*1024), 0, 0, MMUTR_SG, MMUDR_SZ1M, MMUDR_DNCP/*CB*/, MMUDR_SP, MMUDR_R, MMUDR_W, 0, MMUDR_LK, %d0
-	mmu_map	(PAGE_OFFSET+10*1024*1024), (10*1024*1024), 0, 0, MMUTR_SG, MMUDR_SZ1M, MMUDR_DNCP/*CB*/, MMUDR_SP, MMUDR_R, MMUDR_W, 0, MMUDR_LK, %d0
-	mmu_map	(PAGE_OFFSET+11*1024*1024), (11*1024*1024), 0, 0, MMUTR_SG, MMUDR_SZ1M, MMUDR_DNCP/*CB*/, MMUDR_SP, MMUDR_R, MMUDR_W, 0, MMUDR_LK, %d0
-	mmu_map	(PAGE_OFFSET+12*1024*1024), (12*1024*1024), 0, 0, MMUTR_SG, MMUDR_SZ1M, MMUDR_DNCP/*CB*/, MMUDR_SP, MMUDR_R, MMUDR_W, 0, MMUDR_LK, %d0
-	mmu_map	(PAGE_OFFSET+13*1024*1024), (13*1024*1024), 0, 0, MMUTR_SG, MMUDR_SZ1M, MMUDR_DNCP/*CB*/, MMUDR_SP, MMUDR_R, MMUDR_W, 0, MMUDR_LK, %d0
-	mmu_map	(PAGE_OFFSET+14*1024*1024), (14*1024*1024), 0, 0, MMUTR_SG, MMUDR_SZ1M, MMUDR_DNCP/*CB*/, MMUDR_SP, MMUDR_R, MMUDR_W, 0, MMUDR_LK, %d0
-	mmu_map	(PAGE_OFFSET+15*1024*1024), (15*1024*1024), 0, 0, MMUTR_SG, MMUDR_SZ1M, MMUDR_DNCP/*CB*/, MMUDR_SP, MMUDR_R, MMUDR_W, 0, MMUDR_LK, %d0
+	/* Map first 8 MB as data too.  */
+	mmu_map	(PAGE_OFFSET+0*1024*1024),  (0*1024*1024), 0, 0, MMUTR_SG, MMUDR_SZ1M, MMUDR_DNCP, MMUDR_SP, MMUDR_R, MMUDR_W, 0, MMUDR_LK, %d0
+	mmu_map	(PAGE_OFFSET+1*1024*1024),  (1*1024*1024), 0, 0, MMUTR_SG, MMUDR_SZ1M, MMUDR_DNCP, MMUDR_SP, MMUDR_R, MMUDR_W, 0, MMUDR_LK, %d0
+	mmu_map	(PAGE_OFFSET+2*1024*1024),  (2*1024*1024), 0, 0, MMUTR_SG, MMUDR_SZ1M, MMUDR_DNCP, MMUDR_SP, MMUDR_R, MMUDR_W, 0, MMUDR_LK, %d0
+	mmu_map	(PAGE_OFFSET+3*1024*1024),  (3*1024*1024), 0, 0, MMUTR_SG, MMUDR_SZ1M, MMUDR_DNCP, MMUDR_SP, MMUDR_R, MMUDR_W, 0, MMUDR_LK, %d0
+	mmu_map	(PAGE_OFFSET+4*1024*1024),  (4*1024*1024), 0, 0, MMUTR_SG, MMUDR_SZ1M, MMUDR_DNCP, MMUDR_SP, MMUDR_R, MMUDR_W, 0, MMUDR_LK, %d0
+	mmu_map	(PAGE_OFFSET+5*1024*1024),  (5*1024*1024), 0, 0, MMUTR_SG, MMUDR_SZ1M, MMUDR_DNCP, MMUDR_SP, MMUDR_R, MMUDR_W, 0, MMUDR_LK, %d0
+	mmu_map	(PAGE_OFFSET+6*1024*1024),  (6*1024*1024), 0, 0, MMUTR_SG, MMUDR_SZ1M, MMUDR_DNCP, MMUDR_SP, MMUDR_R, MMUDR_W, 0, MMUDR_LK, %d0
+	mmu_map	(PAGE_OFFSET+7*1024*1024),  (7*1024*1024), 0, 0, MMUTR_SG, MMUDR_SZ1M, MMUDR_DNCP, MMUDR_SP, MMUDR_R, MMUDR_W, 0, MMUDR_LK, %d0
 
 	
 
diff -ruN linux-2.6.10.orig/arch/m68k/kernel/signal.c linux-2.6.10/arch/m68k/kernel/signal.c
--- linux-2.6.10.orig/arch/m68k/kernel/signal.c	2006-06-16 09:22:49.000000000 -0600
+++ linux-2.6.10/arch/m68k/kernel/signal.c	2006-06-27 10:42:28.701001979 -0600
@@ -188,11 +188,7 @@
 	int sig;
 	struct siginfo *pinfo;
 	void *puc;
-#ifndef CONFIG_COLDFIRE
 	char retcode[8];
-#else /* CONFIG_COLDFIRE */
-	char retcode[16];	/* Extended since notb is not a ColdFire opcode */
-#endif /* CONFIG_COLDFIRE */
 	struct siginfo info;
 	struct ucontext uc;
 };
@@ -232,16 +228,25 @@
                       sc->sc_fpstate[3] == 0x60 ||
 		      sc->sc_fpstate[3] == 0xe0))
 		    goto out;
-	    } else
-		goto out;
+	    } else {
 
 #ifdef CONFIG_COLDFIRE
-		__asm__ volatile ("fmovem  %0,%/fp0-%/fp7\n\t"
-				  "fmoveml %1,%/fpcr/%/fpsr/%/fpiar\n\t"
-				  QCHIP_RESTORE_DIRECTIVE
-				  : /* no outputs */
-				  : "m" (*sc->sc_fpregs),
-				    "m" (*sc->sc_fpcntl));
+	    __asm__ volatile ("fmovem  %0,%/fp0-%/fp7\n\t"
+			      QCHIP_RESTORE_DIRECTIVE
+			      : /* no outputs */
+			      : "m" (sc->sc_fpregs[0][0])
+			      : "memory" );
+	    /* Restore floating point status registers */
+	    __asm__ volatile ("fmovel %0,%/fpiar" 
+			      : : "m" (sc->sc_fpcntl[0])
+			      : "memory" );
+	    __asm__ volatile ("fmovel %0,%/fpcr" 
+			      : : "m" (sc->sc_fpcntl[1])
+			      : "memory" );
+	    __asm__ volatile ("fmovel %0,%/fpsr" 
+			      : : "m" (sc->sc_fpcntl[2])
+			      : "memory" );
+
 #else /* CONFIG_COLDFIRE */
 	    __asm__ volatile (".chip 68k/68881\n\t"
 			      "fmovemx %0,%%fp0-%%fp1\n\t"
@@ -250,6 +255,7 @@
 			      : /* no outputs */
 			      : "m" (*sc->sc_fpregs), "m" (*sc->sc_fpcntl));
 #endif /* CONFIG_COLDFIRE */
+	    }
 	}
 #ifdef CONFIG_COLDFIRE
 	__asm__ volatile ("frestore %0\n\t"
@@ -314,27 +320,36 @@
 			      fpstate[3] == 0x60 ||
 			      fpstate[3] == 0xe0))
 				goto out;
-		} else
-			goto out;
-		if (__copy_from_user(&fpregs, &uc->uc_mcontext.fpregs,
+		} else {
+		    if (__copy_from_user(&fpregs, &uc->uc_mcontext.fpregs,
 				     sizeof(fpregs)))
 			goto out;
 #ifdef CONFIG_COLDFIRE
-		__asm__ volatile ("fmovem  %0,%/fp0-%/fp7\n\t"
-				  "fmoveml %1,%/fpcr/%/fpsr/%/fpiar\n\t"
-				  QCHIP_RESTORE_DIRECTIVE
-				  : /* no outputs */
-				  : "m" (*fpregs.f_fpregs),
-				    "m" (*fpregs.f_fpcntl));
+		    __asm__ volatile ("fmovem  %0,%/fp0-%/fp7\n\t"
+				      QCHIP_RESTORE_DIRECTIVE
+				      : /* no outputs */
+				      : "m" (fpregs.f_fpregs[0][0])
+				      : "memory" );
+		/* Restore floating point status registers */
+		    __asm__ volatile ("fmovel %0,%/fpiar" 
+				      : : "m" (fpregs.f_fpcntl[0])
+				      : "memory" );
+		    __asm__ volatile ("fmovel %0,%/fpcr" 
+				      : : "m" (fpregs.f_fpcntl[1])
+				      : "memory" );
+		    __asm__ volatile ("fmovel %0,%/fpsr" 
+				      : : "m" (fpregs.f_fpcntl[2])
+				      : "memory" );
 #else
-		__asm__ volatile (".chip 68k/68881\n\t"
-				  "fmovemx %0,%%fp0-%%fp7\n\t"
-				  "fmoveml %1,%%fpcr/%%fpsr/%%fpiar\n\t"
-				  ".chip 68k"
-				  : /* no outputs */
-				  : "m" (*fpregs.f_fpregs),
-				    "m" (*fpregs.f_fpcntl));
+		    __asm__ volatile (".chip 68k/68881\n\t"
+				      "fmovemx %0,%%fp0-%%fp7\n\t"
+				      "fmoveml %1,%%fpcr/%%fpsr/%%fpiar\n\t"
+				      ".chip 68k"
+				      : /* no outputs */
+				      : "m" (*fpregs.f_fpregs),
+				      "m" (*fpregs.f_fpcntl));
 #endif
+		}
 	}
 	if (context_size &&
 	    __copy_from_user(fpstate + 4, (long *)&uc->uc_fpstate + 1,
@@ -368,8 +383,19 @@
 
 	/* restore passed registers */
 	regs->d1 = context.sc_d1;
+	regs->d2 = context.sc_d2;
+	regs->d3 = context.sc_d3;
+	regs->d4 = context.sc_d4;
+	regs->d5 = context.sc_d5;
+	regs->d6 = context.sc_d6;
+	regs->d7 = context.sc_d7;
 	regs->a0 = context.sc_a0;
 	regs->a1 = context.sc_a1;
+	regs->a2 = context.sc_a2;
+	regs->a3 = context.sc_a3;
+	regs->a4 = context.sc_a4;
+	regs->a5 = context.sc_a5;
+	regs->a6 = context.sc_a6;
 	regs->sr = (regs->sr & 0xff00) | (context.sc_sr & 0xff);
 	regs->pc = context.sc_pc;
 	regs->orig_d0 = -1;		/* disable syscall checks */
@@ -645,8 +671,8 @@
 				sc->sc_fpstate[0x38] |= 1 << 3;
 		}
 #ifdef CONFIG_COLDFIRE
-                  __asm__ volatile ("fmovemd %/fp0-%/fp7,%0"
-                                  : : "m" (sc->sc_fpregs[0])
+                 __asm__ volatile ("fmovemd %/fp0-%/fp7,%0"
+                                  : : "m" (sc->sc_fpregs[0][0])
                                   : "memory");
                  __asm__ volatile ("fmovel %/fpiar,%0"
                                   : : "m" (sc->sc_fpcntl[0])
@@ -712,9 +738,8 @@
 				fpstate[0x38] |= 1 << 3;
 		}
 #ifdef CONFIG_COLDFIRE
-#warning COLDFIRE WARNING: Check the asm code operands here
-                  __asm__ volatile ("fmovemd %/fp0-%/fp7,%0"
-                                  : : "m" (*fpregs.f_fpregs)
+                 __asm__ volatile ("fmovemd %/fp0-%/fp7,%0"
+                                  : : "m" (fpregs.f_fpregs[0][0])
                                   : "memory");
                  __asm__ volatile ("fmovel %/fpiar,%0"
                                   : : "m" (fpregs.f_fpcntl[0])
@@ -751,8 +776,19 @@
 	sc->sc_usp = rdusp();
 	sc->sc_d0 = regs->d0;
 	sc->sc_d1 = regs->d1;
+	sc->sc_d2 = regs->d2;
+	sc->sc_d3 = regs->d3;
+	sc->sc_d4 = regs->d4;
+	sc->sc_d5 = regs->d5;
+	sc->sc_d6 = regs->d6;
+	sc->sc_d7 = regs->d7;
 	sc->sc_a0 = regs->a0;
 	sc->sc_a1 = regs->a1;
+	sc->sc_a2 = regs->a2;
+	sc->sc_a3 = regs->a3;
+	sc->sc_a4 = regs->a4;
+	sc->sc_a5 = regs->a5;
+	sc->sc_a6 = regs->a6;
 	sc->sc_sr = regs->sr;
 	sc->sc_pc = regs->pc;
 	sc->sc_formatvec = regs->format << 12 | regs->vector;
@@ -1009,12 +1045,9 @@
 			  (long *)(frame->retcode + 0));
 	err |= __put_user(0x4e40, (short *)(frame->retcode + 4));
 #else
-#warning COLDFIRE WARNING: NL: Check this
-	/* moveq #,d0; andi.l #,D0; trap #0 */
-	err |= __put_user(0x70AD0280,
-			  (long *)(frame->retcode + 0));
-	err |= __put_user(0x000000ff,(long *)(frame->retcode + 4));
-	err |= __put_user(0x4e40, (long *)(frame->retcode + 8));
+	/* movel #__NR_rt_sigreturn(0xAD),d0; trap #0 */
+	err |= __put_user(0x203c0000, (long *)(frame->retcode + 0));
+	err |= __put_user(0x00ad4e40, (long *)(frame->retcode + 4));
 #endif
 
 	if (err)
diff -ruN linux-2.6.10.orig/arch/m68k/kernel/sys_m68k.c linux-2.6.10/arch/m68k/kernel/sys_m68k.c
--- linux-2.6.10.orig/arch/m68k/kernel/sys_m68k.c	2004-12-24 14:34:01.000000000 -0700
+++ linux-2.6.10/arch/m68k/kernel/sys_m68k.c	2006-06-23 13:47:23.000000000 -0600
@@ -74,6 +74,13 @@
 	unsigned long prot, unsigned long flags,
 	unsigned long fd, unsigned long pgoff)
 {
+	/* Make shift for mmap2 should be 12, no matter the PAGE_SIZE is.
+	   Don't silently break if we're trying to map something we can't.
+	   Original FRV code. */
+	if (pgoff & ((1<<(PAGE_SHIFT-12))-1))
+		return -EINVAL;
+	pgoff >>= (PAGE_SHIFT - 12);
+
 	return do_mmap2(addr, len, prot, flags, fd, pgoff);
 }
 
diff -ruN linux-2.6.10.orig/arch/m68k/Makefile linux-2.6.10/arch/m68k/Makefile
--- linux-2.6.10.orig/arch/m68k/Makefile	2006-06-16 09:22:49.000000000 -0600
+++ linux-2.6.10/arch/m68k/Makefile	2006-06-16 09:19:33.000000000 -0600
@@ -145,4 +145,4 @@
 	$(call filechk,gen-asm-offsets)
 
 archclean:
-	rm -f vmlinux.gz vmlinux.bz2
+	rm -f vmlinux.gz vmlinux.bz2 vmlinux.bin
diff -ruN linux-2.6.10.orig/arch/m68k/mm/cf-mmu.c linux-2.6.10/arch/m68k/mm/cf-mmu.c
--- linux-2.6.10.orig/arch/m68k/mm/cf-mmu.c	2006-06-16 09:22:59.000000000 -0600
+++ linux-2.6.10/arch/m68k/mm/cf-mmu.c	2006-06-12 14:55:43.000000000 -0600
@@ -113,7 +113,7 @@
 	
 	current->mm = NULL;
 
-        zones_size[0] = (16*1024*1024) >> PAGE_SHIFT;
+        zones_size[0] = (8*1024*1024) >> PAGE_SHIFT;
 	zones_size[1] = (((unsigned long)high_memory - PAGE_OFFSET) >> PAGE_SHIFT) - zones_size[0];
 	zones_size[2] = 0;
 	free_area_init(zones_size);
diff -ruN linux-2.6.10.orig/include/asm-m68k/bitops.h linux-2.6.10/include/asm-m68k/bitops.h
--- linux-2.6.10.orig/include/asm-m68k/bitops.h	2006-06-16 09:22:50.000000000 -0600
+++ linux-2.6.10/include/asm-m68k/bitops.h	2006-06-14 10:06:11.000000000 -0600
@@ -30,9 +30,9 @@
 {
 	char retval;
         volatile char *p = &((volatile char *)vaddr)[(nr^31) >> 3];
-	__asm__ __volatile__ ("bset %2,%1; sne %0"
-	     : "=d" (retval), "+QU" (*p)
-	     : "di" (nr & 7));
+	__asm__ __volatile__ ("bset %2,(%4); sne %0"
+	     : "=d" (retval), "=m" (*p)
+	     : "di" (nr & 7), "m" (*p), "a" (p));
 	return retval;
 }
 
@@ -86,8 +86,8 @@
 static __inline__ void __constant_coldfire_set_bit(int nr, volatile void * vaddr)
 {
         volatile char *p = &((volatile char *)vaddr)[(nr^31) >> 3];
-	__asm__ __volatile__ ("bset %1,%0"
-	     : "+QU" (*p) : "di" (nr & 7));
+	__asm__ __volatile__ ("bset %1,(%3)"
+	     : "=m" (*p) : "di" (nr & 7), "m" (*p), "a" (p));
 }
 
 static __inline__ void __generic_coldfire_set_bit(int nr, volatile void * vaddr)
@@ -129,9 +129,9 @@
 	char retval;
         volatile char *p = &((volatile char *)vaddr)[(nr^31) >> 3];
 
-	__asm__ __volatile__ ("bclr %2,%1; sne %0"
-	     : "=d" (retval), "+QU" (*p)
-	     : "id" (nr & 7));
+	__asm__ __volatile__ ("bclr %2,(%4); sne %0"
+	     : "=d" (retval), "=m" (*p)
+	     : "id" (nr & 7), "m" (*p), "a" (p));
 
 	return retval;
 }
@@ -193,8 +193,8 @@
 static __inline__ void __constant_coldfire_clear_bit(int nr, volatile void * vaddr)
 {
         volatile char *p = &((volatile char *)vaddr)[(nr^31) >> 3];
-	__asm__ __volatile__ ("bclr %1,%0"
-	     : "+QU" (*p) : "id" (nr & 7));
+	__asm__ __volatile__ ("bclr %1,(%3)"
+	     : "=m" (*p) : "id" (nr & 7), "m" (*p), "a" (p));
 }
 
 static __inline__ void __generic_coldfire_clear_bit(int nr, volatile void * vaddr)
@@ -237,9 +237,9 @@
 	char retval;
         volatile char *p = &((volatile char *)vaddr)[(nr^31) >> 3];
 
-	__asm__ __volatile__ ("bchg %2,%1; sne %0"
-	     : "=d" (retval), "+QU" (*p)
-	     : "id" (nr & 7));
+	__asm__ __volatile__ ("bchg %2,(%4); sne %0"
+	     : "=d" (retval), "=m" (*p)
+	     : "id" (nr & 7), "m" (*p), "a" (p));
 
 	return retval;
 }
@@ -296,8 +296,8 @@
 static __inline__ void __constant_coldfire_change_bit(int nr, volatile void * vaddr)
 {
         volatile char *p = &((volatile char *)vaddr)[(nr^31) >> 3];
-	__asm__ __volatile__ ("bchg %1,%0"
-	     : "+QU" (*p) : "id" (nr & 7));
+	__asm__ __volatile__ ("bchg %1,(%3)"
+	     : "=m" (*p) : "id" (nr & 7), "m" (*p), "a" (p));
 }
 
 static __inline__ void __generic_coldfire_change_bit(int nr, volatile void * vaddr)
diff -ruN linux-2.6.10.orig/include/asm-m68k/cf_cacheflush.h linux-2.6.10/include/asm-m68k/cf_cacheflush.h
--- linux-2.6.10.orig/include/asm-m68k/cf_cacheflush.h	2006-06-16 09:22:49.000000000 -0600
+++ linux-2.6.10/include/asm-m68k/cf_cacheflush.h	2006-06-16 10:42:04.000000000 -0600
@@ -56,7 +56,16 @@
 
 /* Push the page at kernel virtual address and clear the icache */
 /* RZ: use cpush %bc instead of cpush %dc, cinv %ic */
-#define flush_page_to_ram(page) __flush_page_to_ram((void *) page_address(page))
+//#define flush_page_to_ram(page) __flush_page_to_ram((void *) page_address(page))
+#define flush_page_to_ram(page)				\
+({							\
+	unsigned long address = page_address(page);	\
+	if ((address >= PAGE_OFFSET) && 		\
+	    (address < PAGE_OFFSET + 8 * 1024 * 1024))	\
+		__flush_page_to_ram((void *) address);	\
+})
+
+
 extern inline void __flush_page_to_ram(void *address)
 {
   unsigned long set;
@@ -94,10 +103,9 @@
   }
 }
 
-#define flush_dcache_page(page)			do { } while (0)
-#define flush_icache_page(vma,pg)		do { } while (0)
-#define flush_icache_user_range(adr,len)	do { } while (0)
-/* NL */
+#define flush_dcache_page(page)				flush_page_to_ram(page)
+#define flush_icache_page(vma,pg)			flush_page_to_ram(pg)
+#define flush_icache_user_range(adr,len)		do { } while (0)
 #define flush_icache_user_page(vma,page,addr,len)	do { } while (0)
 
 /* Push n pages at kernel virtual address and clear the icache */
diff -ruN linux-2.6.10.orig/include/asm-m68k/setup.h linux-2.6.10/include/asm-m68k/setup.h
--- linux-2.6.10.orig/include/asm-m68k/setup.h	2006-06-16 09:22:49.000000000 -0600
+++ linux-2.6.10/include/asm-m68k/setup.h	2006-06-12 14:55:43.000000000 -0600
@@ -388,19 +388,19 @@
 #define COMMAND_LINE_SIZE	CL_SIZE
 
 #ifndef __ASSEMBLY__
-extern int m68k_num_memory;		/* # of memory blocks found (and used) */
-extern int m68k_realnum_memory;		/* real # of memory blocks found */
-extern struct mem_info m68k_memory[NUM_MEMINFO];/* memory description */
-
 struct mem_info {
 	unsigned long addr;		/* physical address of memory chunk */
 	unsigned long size;		/* length of memory chunk (in bytes) */
 };
+extern int m68k_num_memory;		/* # of memory blocks found (and used) */
+extern int m68k_realnum_memory;		/* real # of memory blocks found */
+extern struct mem_info m68k_memory[NUM_MEMINFO];/* memory description */
+
 #endif
 
 #ifdef CONFIG_COLDFIRE
-#define QCHIP_RESTORE_DIRECTIVE ".chip cfv4e"
-#define  CHIP_RESTORE_DIRECTIVE  .chip cfv4e
+#define QCHIP_RESTORE_DIRECTIVE ".chip 547x"
+#define  CHIP_RESTORE_DIRECTIVE  .chip 547x
 #else
 #define QCHIP_RESTORE_DIRECTIVE ".chip 68k"
 #define  CHIP_RESTORE_DIRECTIVE  .chip 68k
diff -ruN linux-2.6.10.orig/include/asm-m68k/sigcontext.h linux-2.6.10/include/asm-m68k/sigcontext.h
--- linux-2.6.10.orig/include/asm-m68k/sigcontext.h	2006-06-16 09:22:49.000000000 -0600
+++ linux-2.6.10/include/asm-m68k/sigcontext.h	2006-06-14 16:05:49.000000000 -0600
@@ -8,17 +8,32 @@
 	unsigned long  sc_usp;		/* old user stack pointer */
 	unsigned long  sc_d0;
 	unsigned long  sc_d1;
+#ifdef CONFIG_CFV4E
+	unsigned long  sc_d2;
+	unsigned long  sc_d3;
+	unsigned long  sc_d4;
+	unsigned long  sc_d5;
+	unsigned long  sc_d6;
+	unsigned long  sc_d7;
+#endif
 	unsigned long  sc_a0;
 	unsigned long  sc_a1;
+#ifdef CONFIG_CFV4E
+	unsigned long  sc_a2;
+	unsigned long  sc_a3;
+	unsigned long  sc_a4;
+	unsigned long  sc_a5;
+	unsigned long  sc_a6;
+#endif
 	unsigned short sc_sr;
 	unsigned long  sc_pc;
 	unsigned short sc_formatvec;
 #ifdef CONFIG_CFV4E
-	unsigned long  sc_fpregs[8*3];  /* room for 8 fp registers */
-	unsigned long  sc_fpcntl[4];
+	unsigned long  sc_fpregs[8][2];	 /* room for 8 fp registers */
+	unsigned long  sc_fpcntl[3];
 	unsigned char  sc_fpstate[FPSTATESIZE];
 #else /* CONFIG_CFV4E */
-	unsigned long  sc_fpregs[2*3];  /* room for two fp registers */
+	unsigned long  sc_fpregs[2*3];	/* room for two fp registers */
 	unsigned long  sc_fpcntl[3];
 	unsigned char  sc_fpstate[216];
 #endif /* CONFIG_CFV4E */
diff -ruN linux-2.6.10.orig/include/asm-m68k/uaccess.h linux-2.6.10/include/asm-m68k/uaccess.h
--- linux-2.6.10.orig/include/asm-m68k/uaccess.h	2006-06-16 09:22:49.000000000 -0600
+++ linux-2.6.10/include/asm-m68k/uaccess.h	2006-06-12 14:55:43.000000000 -0600
@@ -137,26 +137,30 @@
 #define get_user(x,ptr)                                         \
 ({								\
     int __gu_err;						\
-    typeof(*(ptr)) __gu_val;					\
+    unsigned long __gu_val;					\
+    unsigned long long __gu_val2;				\
     switch (sizeof(*(ptr))) {					\
     case 1:							\
 	__get_user_asm(__gu_err, __gu_val, ptr, b, "=d");	\
+	(x) = (typeof(*(ptr)))__gu_val;				\
 	break;							\
     case 2:							\
 	__get_user_asm(__gu_err, __gu_val, ptr, w, "=r");	\
+	(x) = (typeof(*(ptr)))__gu_val;				\
 	break;							\
     case 4:							\
 	__get_user_asm(__gu_err, __gu_val, ptr, l, "=r");	\
+	(x) = (typeof(*(ptr)))__gu_val;				\
 	break;							\
     case 8:                                                     \
         __gu_err = __constant_copy_from_user(&__gu_val, ptr, 8);  \
+	(x) = (typeof(*(ptr)))__gu_val2;			\
         break;                                                  \
     default:							\
 	__gu_val = 0;						\
 	__gu_err = __get_user_bad();				\
 	break;							\
     }								\
-    (x) = __gu_val;						\
     __gu_err;							\
 })
 #else /* CONFIG_COLDFIRE */
diff -ruN linux-2.6.10.orig/include/asm-m68k/ucontext.h linux-2.6.10/include/asm-m68k/ucontext.h
--- linux-2.6.10.orig/include/asm-m68k/ucontext.h	2004-12-24 14:35:50.000000000 -0700
+++ linux-2.6.10/include/asm-m68k/ucontext.h	2006-06-14 16:05:37.000000000 -0600
@@ -6,8 +6,12 @@
 typedef greg_t gregset_t[NGREG];
 
 typedef struct fpregset {
-	int f_fpcntl[3];
-	int f_fpregs[8*3];
+        int f_fpcntl[3];
+#ifdef CONFIG_CFV4E
+        int f_fpregs[8][2];
+#else
+        int f_fpregs[8*3];
+#endif
 } fpregset_t;
 
 struct mcontext {
diff -ruN linux-2.6.10.orig/include/linux/i2c.h linux-2.6.10/include/linux/i2c.h
--- linux-2.6.10.orig/include/linux/i2c.h	2006-06-16 09:22:49.000000000 -0600
+++ linux-2.6.10/include/linux/i2c.h	2006-06-12 14:55:43.000000000 -0600
@@ -55,7 +55,7 @@
 
 /* Transfer num messages.
  */
-extern int i2c_transfer(struct i2c_adapter *adap, struct i2c_msg msg[],int num);
+extern int i2c_transfer(struct i2c_adapter *adap, struct i2c_msg *msg, int num);
 
 /*
  * Some adapter types (i.e. PCF 8584 based ones) may support slave behaviuor. 
@@ -194,7 +194,7 @@
 	   to NULL. If an adapter algorithm can do SMBus access, set 
 	   smbus_xfer. If set to NULL, the SMBus protocol is simulated
 	   using common I2C messages */
-	int (*master_xfer)(struct i2c_adapter *adap,struct i2c_msg msgs[], 
+	int (*master_xfer)(struct i2c_adapter *adap,struct i2c_msg *msgs, 
 	                   int num);
 	int (*smbus_xfer) (struct i2c_adapter *adap, u16 addr, 
 	                   unsigned short flags, char read_write,

