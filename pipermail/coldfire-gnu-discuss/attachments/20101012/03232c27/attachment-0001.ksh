#NO_APP
	.file	"test_select.c"
	.section	.debug_abbrev,"",@progbits
.Ldebug_abbrev0:
	.section	.debug_info,"",@progbits
.Ldebug_info0:
	.section	.debug_line,"",@progbits
.Ldebug_line0:
	.text
.Ltext0:
	.cfi_sections	.debug_frame
	.section	.rodata.str1.1,"aMS",@progbits,1
.LC0:
	.string	"pthread_create()"
	.text
	.align	2
	.globl	main
	.type	main, @function
main:
.LFB21:
	.file 1 "test_select.c"
	.loc 1 72 0
	.cfi_startproc
.LVL0:
	link.w %fp,#-4
.LCFI0:
	.cfi_def_cfa 14, 8
	.cfi_offset 14, -8
	.loc 1 73 0
	move.l %fp,%a0
	clr.l -(%a0)
.LVL1:
	.loc 1 75 0
	clr.l -(%sp)
	pea threadfunc
	clr.l -(%sp)
	move.l %a0,-(%sp)
	.cfi_escape 0x2e,0x10
	jsr pthread_create
	lea (16,%sp),%sp
	tst.l %d0
	jne .L6
	.loc 1 81 0
	pea 60.w
	.cfi_escape 0x2e,0x4
	jsr sleep
	addq.l #4,%sp
	.loc 1 85 0
	unlk %fp
	clr.l %d0
	rts
.L6:
	.loc 1 77 0
	pea .LC0
	jsr perror
	addq.l #4,%sp
	.loc 1 85 0
	unlk %fp
	clr.l %d0
	rts
	.cfi_endproc
.LFE21:
	.size	main, .-main
	.section	.rodata.str1.1
.LC1:
	.string	"dup2()"
.LC2:
	.string	"before select_fd=%d | nfds=%d | sec = %d | usec = %d\n"
.LC3:
	.string	"after select_fd=%d | nfds=%d | sec = %d | usec = %d | retval = %d\n"
.LC4:
	.string	"unhandled fd\n"
.LC5:
	.string	"select()"
	.text
	.align	2
	.globl	threadfunc
	.type	threadfunc, @function
threadfunc:
.LFB20:
	.loc 1 10 0
	.cfi_startproc
.LVL2:
	link.w %fp,#-228
.LCFI1:
	.cfi_def_cfa 14, 8
	.cfi_offset 14, -8
	movem.l #7228,(%sp)
	.loc 1 12 0
	pea 64.w
	move.l %fp,%d2
	.cfi_offset 12, -212
	.cfi_offset 11, -216
	.cfi_offset 10, -220
	.cfi_offset 5, -224
	.cfi_offset 4, -228
	.cfi_offset 3, -232
	.cfi_offset 2, -236
	clr.l -(%sp)
	add.l #-72,%d2
	move.l %d2,-(%sp)
	.cfi_escape 0x2e,0xc
	jsr memset
	.loc 1 16 0
	pea 67.w
	clr.l -(%sp)
	.cfi_escape 0x2e,0x8
	jsr dup2
	lea (20,%sp),%sp
	mov3q.l #-1,%d1
	cmp.l %d0,%d1
	jeq .L21
	move.l %fp,%d4
	move.l %fp,%d5
	add.l #-200,%d4
	lea fprintf,%a2
	subq.l #8,%d5
	lea select,%a3
	.loc 1 53 0
	lea read,%a4
.LVL3:
.L19:
	.loc 1 19 0
	move.l %d4,%a0
.L11:
.LBB2:
	.loc 1 41 0
	clr.l (%a0)+
	cmp.l %a0,%d2
	jne .L11
.LBE2:
	.loc 1 44 0
	clr.l -(%sp)
	.loc 1 42 0
	moveq #8,%d0
	.loc 1 44 0
	mov3q.l #5,-(%sp)
	pea 68.w
	pea 67.w
	pea .LC2
	move.l stdout,-(%sp)
	.loc 1 42 0
	or.l %d0,-192(%fp)
	.loc 1 38 0
	mov3q.l #5,-8(%fp)
	.loc 1 39 0
	clr.l -4(%fp)
	.loc 1 44 0
	.cfi_escape 0x2e,0x18
	jsr (%a2)
	.loc 1 45 0
	move.l %d5,-(%sp)
	clr.l -(%sp)
	clr.l -(%sp)
	move.l %d4,-(%sp)
	pea 68.w
	.cfi_escape 0x2e,0x14
	jsr (%a3)
	.loc 1 46 0
	lea (40,%sp),%sp
	move.l %d0,(%sp)
	.loc 1 45 0
	move.l %d0,%d3
	.loc 1 46 0
	move.l -4(%fp),-(%sp)
	move.l -8(%fp),-(%sp)
	pea 68.w
	pea 67.w
	pea .LC3
	move.l stdout,-(%sp)
	.cfi_escape 0x2e,0x1c
	jsr (%a2)
	.loc 1 48 0
	lea (28,%sp),%sp
	tst.l %d3
	jle .L12
	.loc 1 50 0
	moveq #8,%d0
	and.l -192(%fp),%d0
	jeq .L13
	.loc 1 53 0
	pea 64.w
	move.l %d2,-(%sp)
	pea 67.w
	.cfi_escape 0x2e,0xc
	jsr (%a4)
	lea (12,%sp),%sp
	.loc 1 19 0
	move.l %d4,%a0
	jra .L11
.L13:
	.loc 1 57 0
	move.l stderr,-(%sp)
	pea 13.w
	mov3q.l #1,-(%sp)
	pea .LC4
	.cfi_escape 0x2e,0x10
	jsr fwrite
	lea (16,%sp),%sp
	.loc 1 69 0
	movem.l -228(%fp),#7228
.LVL4:
	unlk %fp
	clr.l %d0
	sub.l %a0,%a0
	rts
.LVL5:
.L12:
	.loc 1 61 0
	tst.l %d3
	jeq .L19
	.loc 1 63 0
	pea .LC5
	.cfi_escape 0x2e,0x4
	jsr perror
	addq.l #4,%sp
	.loc 1 69 0
	movem.l -228(%fp),#7228
.LVL6:
	unlk %fp
	clr.l %d0
	sub.l %a0,%a0
	rts
.L21:
	.loc 1 18 0
	pea .LC1
	jsr perror
	.loc 1 19 0
	addq.l #4,%sp
	.loc 1 69 0
	movem.l -228(%fp),#7228
	unlk %fp
	clr.l %d0
	sub.l %a0,%a0
	rts
	.cfi_endproc
.LFE20:
	.size	threadfunc, .-threadfunc
.Letext0:
	.section	.debug_loc,"",@progbits
.Ldebug_loc0:
.LLST0:
	.long	.LFB21-.Ltext0
	.long	.LCFI0-.Ltext0
	.word	0x2
	.byte	0x7f
	.sleb128 4
	.long	.LCFI0-.Ltext0
	.long	.LFE21-.Ltext0
	.word	0x2
	.byte	0x7e
	.sleb128 8
	.long	0x0
	.long	0x0
.LLST1:
	.long	.LFB20-.Ltext0
	.long	.LCFI1-.Ltext0
	.word	0x2
	.byte	0x7f
	.sleb128 4
	.long	.LCFI1-.Ltext0
	.long	.LFE20-.Ltext0
	.word	0x2
	.byte	0x7e
	.sleb128 8
	.long	0x0
	.long	0x0
.LLST2:
	.long	.LVL3-.Ltext0
	.long	.LVL4-.Ltext0
	.word	0x1
	.byte	0x53
	.long	.LVL5-.Ltext0
	.long	.LVL6-.Ltext0
	.word	0x1
	.byte	0x53
	.long	0x0
	.long	0x0
	.file 2 "/opt/freescale/usr/local/gcc-4.4.217-eglibc-2.11.217/m68k-linux/lib/gcc/m68k-linux-gnu/4.4.1/include/stddef.h"
	.file 3 "/home/wehrmann/Perforce/depot/projekte/OEBB-FAS/Software/dev/awh/rootfs/usr/lib//include/bits/types.h"
	.file 4 "/home/wehrmann/Perforce/depot/projekte/OEBB-FAS/Software/dev/awh/rootfs/usr/lib//include/libio.h"
	.file 5 "/home/wehrmann/Perforce/depot/projekte/OEBB-FAS/Software/dev/awh/rootfs/usr/lib//include/stdio.h"
	.file 6 "/home/wehrmann/Perforce/depot/projekte/OEBB-FAS/Software/dev/awh/rootfs/usr/lib//include/bits/time.h"
	.file 7 "/home/wehrmann/Perforce/depot/projekte/OEBB-FAS/Software/dev/awh/rootfs/usr/lib//include/sys/select.h"
	.file 8 "/home/wehrmann/Perforce/depot/projekte/OEBB-FAS/Software/dev/awh/rootfs/usr/lib//include/bits/pthreadtypes.h"
	.section	.debug_info
	.long	0x48f
	.word	0x2
	.long	.Ldebug_abbrev0
	.byte	0x4
	.uleb128 0x1
	.long	.LASF70
	.byte	0x1
	.long	.LASF71
	.long	.LASF72
	.long	.Ltext0
	.long	.Letext0
	.long	.Ldebug_line0
	.uleb128 0x2
	.long	.LASF8
	.byte	0x2
	.byte	0xd3
	.long	0x30
	.uleb128 0x3
	.byte	0x4
	.byte	0x7
	.long	.LASF0
	.uleb128 0x3
	.byte	0x1
	.byte	0x8
	.long	.LASF1
	.uleb128 0x3
	.byte	0x2
	.byte	0x7
	.long	.LASF2
	.uleb128 0x3
	.byte	0x4
	.byte	0x7
	.long	.LASF3
	.uleb128 0x3
	.byte	0x1
	.byte	0x6
	.long	.LASF4
	.uleb128 0x3
	.byte	0x2
	.byte	0x5
	.long	.LASF5
	.uleb128 0x4
	.byte	0x4
	.byte	0x5
	.string	"int"
	.uleb128 0x3
	.byte	0x8
	.byte	0x5
	.long	.LASF6
	.uleb128 0x3
	.byte	0x8
	.byte	0x7
	.long	.LASF7
	.uleb128 0x2
	.long	.LASF9
	.byte	0x3
	.byte	0x38
	.long	0x61
	.uleb128 0x2
	.long	.LASF10
	.byte	0x3
	.byte	0x8d
	.long	0x85
	.uleb128 0x3
	.byte	0x4
	.byte	0x5
	.long	.LASF11
	.uleb128 0x2
	.long	.LASF12
	.byte	0x3
	.byte	0x8e
	.long	0x6f
	.uleb128 0x5
	.byte	0x4
	.byte	0x7
	.uleb128 0x2
	.long	.LASF13
	.byte	0x3
	.byte	0x95
	.long	0x85
	.uleb128 0x2
	.long	.LASF14
	.byte	0x3
	.byte	0x97
	.long	0x85
	.uleb128 0x6
	.byte	0x4
	.uleb128 0x7
	.byte	0x4
	.long	0xb8
	.uleb128 0x3
	.byte	0x1
	.byte	0x6
	.long	.LASF15
	.uleb128 0x8
	.long	.LASF45
	.byte	0x94
	.byte	0x5
	.byte	0x2d
	.long	0x27f
	.uleb128 0x9
	.long	.LASF16
	.byte	0x4
	.word	0x110
	.long	0x5a
	.byte	0x2
	.byte	0x23
	.uleb128 0x0
	.uleb128 0x9
	.long	.LASF17
	.byte	0x4
	.word	0x115
	.long	0xb2
	.byte	0x2
	.byte	0x23
	.uleb128 0x4
	.uleb128 0x9
	.long	.LASF18
	.byte	0x4
	.word	0x116
	.long	0xb2
	.byte	0x2
	.byte	0x23
	.uleb128 0x8
	.uleb128 0x9
	.long	.LASF19
	.byte	0x4
	.word	0x117
	.long	0xb2
	.byte	0x2
	.byte	0x23
	.uleb128 0xc
	.uleb128 0x9
	.long	.LASF20
	.byte	0x4
	.word	0x118
	.long	0xb2
	.byte	0x2
	.byte	0x23
	.uleb128 0x10
	.uleb128 0x9
	.long	.LASF21
	.byte	0x4
	.word	0x119
	.long	0xb2
	.byte	0x2
	.byte	0x23
	.uleb128 0x14
	.uleb128 0x9
	.long	.LASF22
	.byte	0x4
	.word	0x11a
	.long	0xb2
	.byte	0x2
	.byte	0x23
	.uleb128 0x18
	.uleb128 0x9
	.long	.LASF23
	.byte	0x4
	.word	0x11b
	.long	0xb2
	.byte	0x2
	.byte	0x23
	.uleb128 0x1c
	.uleb128 0x9
	.long	.LASF24
	.byte	0x4
	.word	0x11c
	.long	0xb2
	.byte	0x2
	.byte	0x23
	.uleb128 0x20
	.uleb128 0x9
	.long	.LASF25
	.byte	0x4
	.word	0x11e
	.long	0xb2
	.byte	0x2
	.byte	0x23
	.uleb128 0x24
	.uleb128 0x9
	.long	.LASF26
	.byte	0x4
	.word	0x11f
	.long	0xb2
	.byte	0x2
	.byte	0x23
	.uleb128 0x28
	.uleb128 0x9
	.long	.LASF27
	.byte	0x4
	.word	0x120
	.long	0xb2
	.byte	0x2
	.byte	0x23
	.uleb128 0x2c
	.uleb128 0x9
	.long	.LASF28
	.byte	0x4
	.word	0x122
	.long	0x2bd
	.byte	0x2
	.byte	0x23
	.uleb128 0x30
	.uleb128 0x9
	.long	.LASF29
	.byte	0x4
	.word	0x124
	.long	0x2c3
	.byte	0x2
	.byte	0x23
	.uleb128 0x34
	.uleb128 0x9
	.long	.LASF30
	.byte	0x4
	.word	0x126
	.long	0x5a
	.byte	0x2
	.byte	0x23
	.uleb128 0x38
	.uleb128 0x9
	.long	.LASF31
	.byte	0x4
	.word	0x12a
	.long	0x5a
	.byte	0x2
	.byte	0x23
	.uleb128 0x3c
	.uleb128 0x9
	.long	.LASF32
	.byte	0x4
	.word	0x12c
	.long	0x7a
	.byte	0x2
	.byte	0x23
	.uleb128 0x40
	.uleb128 0x9
	.long	.LASF33
	.byte	0x4
	.word	0x130
	.long	0x3e
	.byte	0x2
	.byte	0x23
	.uleb128 0x44
	.uleb128 0x9
	.long	.LASF34
	.byte	0x4
	.word	0x131
	.long	0x4c
	.byte	0x2
	.byte	0x23
	.uleb128 0x46
	.uleb128 0x9
	.long	.LASF35
	.byte	0x4
	.word	0x132
	.long	0x2c9
	.byte	0x2
	.byte	0x23
	.uleb128 0x47
	.uleb128 0x9
	.long	.LASF36
	.byte	0x4
	.word	0x136
	.long	0x2d9
	.byte	0x2
	.byte	0x23
	.uleb128 0x48
	.uleb128 0x9
	.long	.LASF37
	.byte	0x4
	.word	0x13f
	.long	0x8c
	.byte	0x2
	.byte	0x23
	.uleb128 0x4c
	.uleb128 0x9
	.long	.LASF38
	.byte	0x4
	.word	0x148
	.long	0xb0
	.byte	0x2
	.byte	0x23
	.uleb128 0x54
	.uleb128 0x9
	.long	.LASF39
	.byte	0x4
	.word	0x149
	.long	0xb0
	.byte	0x2
	.byte	0x23
	.uleb128 0x58
	.uleb128 0x9
	.long	.LASF40
	.byte	0x4
	.word	0x14a
	.long	0xb0
	.byte	0x2
	.byte	0x23
	.uleb128 0x5c
	.uleb128 0x9
	.long	.LASF41
	.byte	0x4
	.word	0x14b
	.long	0xb0
	.byte	0x2
	.byte	0x23
	.uleb128 0x60
	.uleb128 0x9
	.long	.LASF42
	.byte	0x4
	.word	0x14c
	.long	0x25
	.byte	0x2
	.byte	0x23
	.uleb128 0x64
	.uleb128 0x9
	.long	.LASF43
	.byte	0x4
	.word	0x14e
	.long	0x5a
	.byte	0x2
	.byte	0x23
	.uleb128 0x68
	.uleb128 0x9
	.long	.LASF44
	.byte	0x4
	.word	0x150
	.long	0x2df
	.byte	0x2
	.byte	0x23
	.uleb128 0x6c
	.byte	0x0
	.uleb128 0xa
	.long	.LASF73
	.byte	0x4
	.byte	0xb4
	.uleb128 0x8
	.long	.LASF46
	.byte	0xc
	.byte	0x4
	.byte	0xba
	.long	0x2bd
	.uleb128 0xb
	.long	.LASF47
	.byte	0x4
	.byte	0xbb
	.long	0x2bd
	.byte	0x2
	.byte	0x23
	.uleb128 0x0
	.uleb128 0xb
	.long	.LASF48
	.byte	0x4
	.byte	0xbc
	.long	0x2c3
	.byte	0x2
	.byte	0x23
	.uleb128 0x4
	.uleb128 0xb
	.long	.LASF49
	.byte	0x4
	.byte	0xc0
	.long	0x5a
	.byte	0x2
	.byte	0x23
	.uleb128 0x8
	.byte	0x0
	.uleb128 0x7
	.byte	0x4
	.long	0x286
	.uleb128 0x7
	.byte	0x4
	.long	0xbf
	.uleb128 0xc
	.long	0xb8
	.long	0x2d9
	.uleb128 0xd
	.long	0x97
	.byte	0x0
	.byte	0x0
	.uleb128 0x7
	.byte	0x4
	.long	0x27f
	.uleb128 0xc
	.long	0xb8
	.long	0x2ef
	.uleb128 0xd
	.long	0x97
	.byte	0x27
	.byte	0x0
	.uleb128 0x8
	.long	.LASF50
	.byte	0x8
	.byte	0x6
	.byte	0x46
	.long	0x318
	.uleb128 0xb
	.long	.LASF51
	.byte	0x6
	.byte	0x47
	.long	0x9a
	.byte	0x2
	.byte	0x23
	.uleb128 0x0
	.uleb128 0xb
	.long	.LASF52
	.byte	0x6
	.byte	0x48
	.long	0xa5
	.byte	0x2
	.byte	0x23
	.uleb128 0x4
	.byte	0x0
	.uleb128 0x2
	.long	.LASF53
	.byte	0x7
	.byte	0x37
	.long	0x85
	.uleb128 0xe
	.byte	0x80
	.byte	0x7
	.byte	0x44
	.long	0x33a
	.uleb128 0xb
	.long	.LASF54
	.byte	0x7
	.byte	0x4b
	.long	0x33a
	.byte	0x2
	.byte	0x23
	.uleb128 0x0
	.byte	0x0
	.uleb128 0xc
	.long	0x318
	.long	0x34a
	.uleb128 0xd
	.long	0x97
	.byte	0x1f
	.byte	0x0
	.uleb128 0x2
	.long	.LASF55
	.byte	0x7
	.byte	0x4e
	.long	0x323
	.uleb128 0x2
	.long	.LASF56
	.byte	0x8
	.byte	0x25
	.long	0x45
	.uleb128 0xc
	.long	0xb8
	.long	0x370
	.uleb128 0xd
	.long	0x97
	.byte	0x3f
	.byte	0x0
	.uleb128 0xf
	.byte	0x1
	.long	.LASF59
	.byte	0x1
	.byte	0x47
	.byte	0x1
	.long	0x5a
	.long	.LFB21
	.long	.LFE21
	.long	.LLST0
	.long	0x3b8
	.uleb128 0x10
	.long	.LASF57
	.byte	0x1
	.byte	0x47
	.long	0x5a
	.byte	0x2
	.byte	0x91
	.sleb128 0
	.uleb128 0x10
	.long	.LASF58
	.byte	0x1
	.byte	0x47
	.long	0x3b8
	.byte	0x2
	.byte	0x91
	.sleb128 4
	.uleb128 0x11
	.string	"tid"
	.byte	0x1
	.byte	0x49
	.long	0x355
	.byte	0x2
	.byte	0x78
	.sleb128 -4
	.byte	0x0
	.uleb128 0x7
	.byte	0x4
	.long	0xb2
	.uleb128 0xf
	.byte	0x1
	.long	.LASF60
	.byte	0x1
	.byte	0x9
	.byte	0x1
	.long	0xb0
	.long	.LFB20
	.long	.LFE20
	.long	.LLST1
	.long	0x465
	.uleb128 0x12
	.string	"arg"
	.byte	0x1
	.byte	0x9
	.long	0xb0
	.byte	0x2
	.byte	0x91
	.sleb128 0
	.uleb128 0x13
	.long	.LASF61
	.byte	0x1
	.byte	0xc
	.long	0x360
	.byte	0x3
	.byte	0x7e
	.sleb128 -72
	.uleb128 0x14
	.string	"run"
	.byte	0x1
	.byte	0xd
	.long	0x5a
	.uleb128 0x15
	.long	.LASF62
	.byte	0x1
	.byte	0xe
	.long	0x5a
	.uleb128 0x15
	.long	.LASF63
	.byte	0x1
	.byte	0x19
	.long	0x5a
	.uleb128 0x11
	.string	"to"
	.byte	0x1
	.byte	0x20
	.long	0x2ef
	.byte	0x2
	.byte	0x7e
	.sleb128 -8
	.uleb128 0x13
	.long	.LASF64
	.byte	0x1
	.byte	0x21
	.long	0x34a
	.byte	0x3
	.byte	0x7e
	.sleb128 -200
	.uleb128 0x16
	.long	.LASF65
	.byte	0x1
	.byte	0x22
	.long	0x5a
	.long	.LLST2
	.uleb128 0x17
	.long	.LBB2
	.long	.LBE2
	.uleb128 0x14
	.string	"__i"
	.byte	0x1
	.byte	0x29
	.long	0x30
	.uleb128 0x15
	.long	.LASF66
	.byte	0x1
	.byte	0x29
	.long	0x465
	.byte	0x0
	.byte	0x0
	.uleb128 0x7
	.byte	0x4
	.long	0x34a
	.uleb128 0x18
	.long	.LASF67
	.byte	0x5
	.byte	0x91
	.long	0x2c3
	.byte	0x1
	.byte	0x1
	.uleb128 0x18
	.long	.LASF68
	.byte	0x5
	.byte	0x92
	.long	0x2c3
	.byte	0x1
	.byte	0x1
	.uleb128 0x18
	.long	.LASF69
	.byte	0x5
	.byte	0x93
	.long	0x2c3
	.byte	0x1
	.byte	0x1
	.byte	0x0
	.section	.debug_abbrev
	.uleb128 0x1
	.uleb128 0x11
	.byte	0x1
	.uleb128 0x25
	.uleb128 0xe
	.uleb128 0x13
	.uleb128 0xb
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x1b
	.uleb128 0xe
	.uleb128 0x11
	.uleb128 0x1
	.uleb128 0x12
	.uleb128 0x1
	.uleb128 0x10
	.uleb128 0x6
	.byte	0x0
	.byte	0x0
	.uleb128 0x2
	.uleb128 0x16
	.byte	0x0
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.byte	0x0
	.byte	0x0
	.uleb128 0x3
	.uleb128 0x24
	.byte	0x0
	.uleb128 0xb
	.uleb128 0xb
	.uleb128 0x3e
	.uleb128 0xb
	.uleb128 0x3
	.uleb128 0xe
	.byte	0x0
	.byte	0x0
	.uleb128 0x4
	.uleb128 0x24
	.byte	0x0
	.uleb128 0xb
	.uleb128 0xb
	.uleb128 0x3e
	.uleb128 0xb
	.uleb128 0x3
	.uleb128 0x8
	.byte	0x0
	.byte	0x0
	.uleb128 0x5
	.uleb128 0x24
	.byte	0x0
	.uleb128 0xb
	.uleb128 0xb
	.uleb128 0x3e
	.uleb128 0xb
	.byte	0x0
	.byte	0x0
	.uleb128 0x6
	.uleb128 0xf
	.byte	0x0
	.uleb128 0xb
	.uleb128 0xb
	.byte	0x0
	.byte	0x0
	.uleb128 0x7
	.uleb128 0xf
	.byte	0x0
	.uleb128 0xb
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.byte	0x0
	.byte	0x0
	.uleb128 0x8
	.uleb128 0x13
	.byte	0x1
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0xb
	.uleb128 0xb
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x1
	.uleb128 0x13
	.byte	0x0
	.byte	0x0
	.uleb128 0x9
	.uleb128 0xd
	.byte	0x0
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0x5
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x38
	.uleb128 0xa
	.byte	0x0
	.byte	0x0
	.uleb128 0xa
	.uleb128 0x16
	.byte	0x0
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.byte	0x0
	.byte	0x0
	.uleb128 0xb
	.uleb128 0xd
	.byte	0x0
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x38
	.uleb128 0xa
	.byte	0x0
	.byte	0x0
	.uleb128 0xc
	.uleb128 0x1
	.byte	0x1
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x1
	.uleb128 0x13
	.byte	0x0
	.byte	0x0
	.uleb128 0xd
	.uleb128 0x21
	.byte	0x0
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x2f
	.uleb128 0xb
	.byte	0x0
	.byte	0x0
	.uleb128 0xe
	.uleb128 0x13
	.byte	0x1
	.uleb128 0xb
	.uleb128 0xb
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x1
	.uleb128 0x13
	.byte	0x0
	.byte	0x0
	.uleb128 0xf
	.uleb128 0x2e
	.byte	0x1
	.uleb128 0x3f
	.uleb128 0xc
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x27
	.uleb128 0xc
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x11
	.uleb128 0x1
	.uleb128 0x12
	.uleb128 0x1
	.uleb128 0x40
	.uleb128 0x6
	.uleb128 0x1
	.uleb128 0x13
	.byte	0x0
	.byte	0x0
	.uleb128 0x10
	.uleb128 0x5
	.byte	0x0
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x2
	.uleb128 0xa
	.byte	0x0
	.byte	0x0
	.uleb128 0x11
	.uleb128 0x34
	.byte	0x0
	.uleb128 0x3
	.uleb128 0x8
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x2
	.uleb128 0xa
	.byte	0x0
	.byte	0x0
	.uleb128 0x12
	.uleb128 0x5
	.byte	0x0
	.uleb128 0x3
	.uleb128 0x8
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x2
	.uleb128 0xa
	.byte	0x0
	.byte	0x0
	.uleb128 0x13
	.uleb128 0x34
	.byte	0x0
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x2
	.uleb128 0xa
	.byte	0x0
	.byte	0x0
	.uleb128 0x14
	.uleb128 0x34
	.byte	0x0
	.uleb128 0x3
	.uleb128 0x8
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.byte	0x0
	.byte	0x0
	.uleb128 0x15
	.uleb128 0x34
	.byte	0x0
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.byte	0x0
	.byte	0x0
	.uleb128 0x16
	.uleb128 0x34
	.byte	0x0
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x2
	.uleb128 0x6
	.byte	0x0
	.byte	0x0
	.uleb128 0x17
	.uleb128 0xb
	.byte	0x1
	.uleb128 0x11
	.uleb128 0x1
	.uleb128 0x12
	.uleb128 0x1
	.byte	0x0
	.byte	0x0
	.uleb128 0x18
	.uleb128 0x34
	.byte	0x0
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x3f
	.uleb128 0xc
	.uleb128 0x3c
	.uleb128 0xc
	.byte	0x0
	.byte	0x0
	.byte	0x0
	.section	.debug_pubnames,"",@progbits
	.long	0x26
	.word	0x2
	.long	.Ldebug_info0
	.long	0x493
	.long	0x370
	.string	"main"
	.long	0x3be
	.string	"threadfunc"
	.long	0x0
	.section	.debug_aranges,"",@progbits
	.long	0x1c
	.word	0x2
	.long	.Ldebug_info0
	.byte	0x4
	.byte	0x0
	.word	0x0
	.word	0x0
	.long	.Ltext0
	.long	.Letext0-.Ltext0
	.long	0x0
	.long	0x0
	.section	.debug_str,"MS",@progbits,1
.LASF29:
	.string	"_chain"
.LASF9:
	.string	"__quad_t"
.LASF62:
	.string	"select_fd"
.LASF45:
	.string	"_IO_FILE"
.LASF51:
	.string	"tv_sec"
.LASF27:
	.string	"_IO_save_end"
.LASF5:
	.string	"short int"
.LASF8:
	.string	"size_t"
.LASF37:
	.string	"_offset"
.LASF21:
	.string	"_IO_write_ptr"
.LASF16:
	.string	"_flags"
.LASF23:
	.string	"_IO_buf_base"
.LASF65:
	.string	"retval"
.LASF28:
	.string	"_markers"
.LASF18:
	.string	"_IO_read_end"
.LASF61:
	.string	"line"
.LASF4:
	.string	"signed char"
.LASF53:
	.string	"__fd_mask"
.LASF54:
	.string	"__fds_bits"
.LASF69:
	.string	"stderr"
.LASF6:
	.string	"long long int"
.LASF36:
	.string	"_lock"
.LASF11:
	.string	"long int"
.LASF60:
	.string	"threadfunc"
.LASF33:
	.string	"_cur_column"
.LASF64:
	.string	"rdfs"
.LASF49:
	.string	"_pos"
.LASF58:
	.string	"argv"
.LASF48:
	.string	"_sbuf"
.LASF32:
	.string	"_old_offset"
.LASF1:
	.string	"unsigned char"
.LASF57:
	.string	"argc"
.LASF63:
	.string	"nfds"
.LASF7:
	.string	"long long unsigned int"
.LASF0:
	.string	"unsigned int"
.LASF46:
	.string	"_IO_marker"
.LASF35:
	.string	"_shortbuf"
.LASF12:
	.string	"__off64_t"
.LASF20:
	.string	"_IO_write_base"
.LASF44:
	.string	"_unused2"
.LASF17:
	.string	"_IO_read_ptr"
.LASF24:
	.string	"_IO_buf_end"
.LASF15:
	.string	"char"
.LASF59:
	.string	"main"
.LASF66:
	.string	"__arr"
.LASF47:
	.string	"_next"
.LASF38:
	.string	"__pad1"
.LASF39:
	.string	"__pad2"
.LASF40:
	.string	"__pad3"
.LASF41:
	.string	"__pad4"
.LASF42:
	.string	"__pad5"
.LASF2:
	.string	"short unsigned int"
.LASF72:
	.string	"/home/wehrmann/Perforce/depot/projekte/OEBB-FAS/Software/dev/awh/rpm/BUILD/test_select-1.0"
.LASF3:
	.string	"long unsigned int"
.LASF22:
	.string	"_IO_write_end"
.LASF13:
	.string	"__time_t"
.LASF30:
	.string	"_fileno"
.LASF50:
	.string	"timeval"
.LASF10:
	.string	"__off_t"
.LASF52:
	.string	"tv_usec"
.LASF26:
	.string	"_IO_backup_base"
.LASF67:
	.string	"stdin"
.LASF71:
	.string	"test_select.c"
.LASF31:
	.string	"_flags2"
.LASF43:
	.string	"_mode"
.LASF19:
	.string	"_IO_read_base"
.LASF34:
	.string	"_vtable_offset"
.LASF25:
	.string	"_IO_save_base"
.LASF70:
	.string	"GNU C 4.4.1"
.LASF14:
	.string	"__suseconds_t"
.LASF55:
	.string	"fd_set"
.LASF56:
	.string	"pthread_t"
.LASF68:
	.string	"stdout"
.LASF73:
	.string	"_IO_lock_t"
	.ident	"GCC: (Sourcery G++ Lite 4.4-217) 4.4.1"
	.section	.note.GNU-stack,"",@progbits
