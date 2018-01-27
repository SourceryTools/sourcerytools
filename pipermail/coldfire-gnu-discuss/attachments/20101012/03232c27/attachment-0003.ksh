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
	.section	.rodata
.LC0:
	.string	"dup2()"
.LC1:
	.string	"before select_fd=%d | nfds=%d | sec = %d | usec = %d\n"
.LC2:
	.string	"after select_fd=%d | nfds=%d | sec = %d | usec = %d | retval = %d\n"
.LC3:
	.string	"unhandled fd\n"
.LC4:
	.string	"select()"
	.text
	.align	2
	.globl	threadfunc
	.type	threadfunc, @function
threadfunc:
.LFB1:
	.file 1 "test_select.c"
	.loc 1 10 0
	.cfi_startproc
	link.w %fp,#-224
.LCFI0:
	.cfi_def_cfa 14, 8
	.cfi_offset 14, -8
	move.l %a2,-(%sp)
	move.l %d2,-(%sp)
	.loc 1 12 0
	move.l %fp,%d0
	add.l #-88,%d0
	moveq #64,%d1
	move.l %d1,-(%sp)
	clr.l -(%sp)
	move.l %d0,-(%sp)
	.cfi_offset 2, -240
	.cfi_offset 10, -236
	.cfi_escape 0x2e,0xc
	jsr memset
	lea (12,%sp),%sp
	.loc 1 13 0
	mov3q.l #1,-24(%fp)
	.loc 1 14 0
	moveq #67,%d0
	move.l %d0,-20(%fp)
	.loc 1 16 0
	move.l -20(%fp),-(%sp)
	clr.l -(%sp)
	.cfi_escape 0x2e,0x8
	jsr dup2
	addq.l #8,%sp
	mov3q.l #-1,%d1
	cmp.l %d0,%d1
	jne .L2
	.loc 1 18 0
	pea .LC0
	.cfi_escape 0x2e,0x4
	jsr perror
	addq.l #4,%sp
	.loc 1 19 0
	clr.l %d0
	jra .L3
.L2:
	.loc 1 25 0
	move.l -20(%fp),%d2
	addq.l #1,%d2
	move.l %d2,-16(%fp)
	.loc 1 34 0
	clr.l -12(%fp)
	.loc 1 36 0
	jra .L4
.L14:
	.loc 1 38 0
	mov3q.l #5,-96(%fp)
	.loc 1 39 0
	clr.l -92(%fp)
.LBB2:
	.loc 1 41 0
	lea (-224,%fp),%a0
	move.l %a0,-4(%fp)
	clr.l -8(%fp)
	jra .L5
.L6:
	move.l -8(%fp),%d1
	move.l -4(%fp),%d0
	move.l %d0,%a2
	clr.l (%a2,%d1.l*4)
	addq.l #1,-8(%fp)
.L5:
	moveq #31,%d0
	cmp.l -8(%fp),%d0
	jcc .L6
.LBE2:
	.loc 1 42 0
	move.l -20(%fp),%d0
	tst.l %d0
	jge .L7
	add.l #31,%d0
.L7:
	asr.l #5,%d0
	move.l %d0,%a0
	lsl.l #2,%d0
	add.l %fp,%d0
	move.l %d0,%a2
	move.l -224(%a2),%a1
	move.l -20(%fp),%d0
	and.l #-2147483617,%d0
	tst.l %d0
	jge .L8
	subq.l #1,%d0
	moveq #-32,%d1
	or.l %d1,%d0
	addq.l #1,%d0
.L8:
	mov3q.l #1,%d1
	move.l %d1,%d2
	lsl.l %d0,%d2
	move.l %d2,%d0
	move.l %a1,%d1
	or.l %d0,%d1
	move.l %a0,%d0
	lsl.l #2,%d0
	add.l %fp,%d0
	move.l %d0,%a0
	move.l %d1,-224(%a0)
	.loc 1 44 0
	move.l -92(%fp),%a1
	move.l -96(%fp),%a0
	move.l #.LC1,%d1
	move.l stdout,%d0
	move.l %a1,-(%sp)
	move.l %a0,-(%sp)
	move.l -16(%fp),-(%sp)
	move.l -20(%fp),-(%sp)
	move.l %d1,-(%sp)
	move.l %d0,-(%sp)
	.cfi_escape 0x2e,0x18
	jsr fprintf
	lea (24,%sp),%sp
	.loc 1 45 0
	move.l %fp,%d0
	add.l #-96,%d0
	move.l %d0,-(%sp)
	clr.l -(%sp)
	clr.l -(%sp)
	move.l %fp,%d0
	add.l #-224,%d0
	move.l %d0,-(%sp)
	move.l -16(%fp),-(%sp)
	.cfi_escape 0x2e,0x14
	jsr select
	lea (20,%sp),%sp
	move.l %d0,-12(%fp)
	.loc 1 46 0
	move.l -92(%fp),%a1
	move.l -96(%fp),%a0
	move.l #.LC2,%d1
	move.l stdout,%d0
	move.l -12(%fp),-(%sp)
	move.l %a1,-(%sp)
	move.l %a0,-(%sp)
	move.l -16(%fp),-(%sp)
	move.l -20(%fp),-(%sp)
	move.l %d1,-(%sp)
	move.l %d0,-(%sp)
	.cfi_escape 0x2e,0x1c
	jsr fprintf
	lea (28,%sp),%sp
	.loc 1 48 0
	tst.l -12(%fp)
	jle .L9
	.loc 1 50 0
	move.l -20(%fp),%d0
	tst.l %d0
	jge .L10
	add.l #31,%d0
.L10:
	asr.l #5,%d0
	lsl.l #2,%d0
	add.l %fp,%d0
	move.l %d0,%a2
	move.l -224(%a2),%d1
	move.l -20(%fp),%d0
	and.l #-2147483617,%d0
	tst.l %d0
	jge .L11
	subq.l #1,%d0
	moveq #-32,%d2
	or.l %d2,%d0
	addq.l #1,%d0
.L11:
	move.l %d1,%d2
	asr.l %d0,%d2
	move.l %d2,%d0
	mov3q.l #1,%d1
	and.l %d1,%d0
	move.b %d0,%d0
	tst.b %d0
	jeq .L12
	.loc 1 53 0
	pea 64.w
	move.l %fp,%d0
	add.l #-88,%d0
	move.l %d0,-(%sp)
	move.l -20(%fp),-(%sp)
	.cfi_escape 0x2e,0xc
	jsr read
	lea (12,%sp),%sp
	.loc 1 58 0
	jra .L4
.L12:
	.loc 1 57 0
	move.l stderr,%d0
	move.l %d0,%d1
	move.l #.LC3,%d0
	move.l %d1,-(%sp)
	pea 13.w
	mov3q.l #1,-(%sp)
	move.l %d0,-(%sp)
	.cfi_escape 0x2e,0x10
	jsr fwrite
	lea (16,%sp),%sp
	.loc 1 58 0
	clr.l -24(%fp)
	jra .L4
.L9:
	.loc 1 61 0
	tst.l -12(%fp)
	jge .L4
	.loc 1 63 0
	pea .LC4
	.cfi_escape 0x2e,0x4
	jsr perror
	addq.l #4,%sp
	.loc 1 64 0
	clr.l -24(%fp)
.L4:
	.loc 1 36 0
	tst.l -24(%fp)
	jne .L14
	.loc 1 68 0
	clr.l %d0
.L3:
	move.l %d0,%d1
	.loc 1 69 0
	move.l %d1,%a0
	move.l -232(%fp),%d2
	move.l -228(%fp),%a2
	unlk %fp
	rts
	.cfi_endproc
.LFE1:
	.size	threadfunc, .-threadfunc
	.section	.rodata
.LC5:
	.string	"pthread_create()"
	.text
	.align	2
	.globl	main
	.type	main, @function
main:
.LFB2:
	.loc 1 72 0
	.cfi_startproc
	link.w %fp,#-4
.LCFI1:
	.cfi_def_cfa 14, 8
	.cfi_offset 14, -8
	.loc 1 73 0
	clr.l -4(%fp)
	.loc 1 75 0
	clr.l -(%sp)
	pea threadfunc
	clr.l -(%sp)
	move.l %fp,%d0
	subq.l #4,%d0
	move.l %d0,-(%sp)
	.cfi_escape 0x2e,0x10
	jsr pthread_create
	lea (16,%sp),%sp
	tst.l %d0
	jeq .L17
	.loc 1 77 0
	pea .LC5
	.cfi_escape 0x2e,0x4
	jsr perror
	addq.l #4,%sp
	jra .L18
.L17:
	.loc 1 81 0
	pea 60.w
	jsr sleep
	addq.l #4,%sp
.L18:
	.loc 1 84 0
	clr.l %d0
	.loc 1 85 0
	unlk %fp
	rts
	.cfi_endproc
.LFE2:
	.size	main, .-main
.Letext0:
	.section	.debug_loc,"",@progbits
.Ldebug_loc0:
.LLST0:
	.long	.LFB1-.Ltext0
	.long	.LCFI0-.Ltext0
	.word	0x2
	.byte	0x7f
	.sleb128 4
	.long	.LCFI0-.Ltext0
	.long	.LFE1-.Ltext0
	.word	0x2
	.byte	0x7e
	.sleb128 8
	.long	0x0
	.long	0x0
.LLST1:
	.long	.LFB2-.Ltext0
	.long	.LCFI1-.Ltext0
	.word	0x2
	.byte	0x7f
	.sleb128 4
	.long	.LCFI1-.Ltext0
	.long	.LFE2-.Ltext0
	.word	0x2
	.byte	0x7e
	.sleb128 8
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
	.long	0x491
	.word	0x2
	.long	.Ldebug_abbrev0
	.byte	0x4
	.uleb128 0x1
	.long	.LASF69
	.byte	0x1
	.long	.LASF70
	.long	.LASF71
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
	.long	.LASF72
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
	.long	.LASF63
	.byte	0x1
	.byte	0x9
	.byte	0x1
	.long	0xb0
	.long	.LFB1
	.long	.LFE1
	.long	.LLST0
	.long	0x426
	.uleb128 0x10
	.string	"arg"
	.byte	0x1
	.byte	0x9
	.long	0xb0
	.byte	0x2
	.byte	0x91
	.sleb128 0
	.uleb128 0x11
	.long	.LASF57
	.byte	0x1
	.byte	0xc
	.long	0x360
	.byte	0x3
	.byte	0x7e
	.sleb128 -88
	.uleb128 0x12
	.string	"run"
	.byte	0x1
	.byte	0xd
	.long	0x5a
	.byte	0x2
	.byte	0x7e
	.sleb128 -24
	.uleb128 0x11
	.long	.LASF58
	.byte	0x1
	.byte	0xe
	.long	0x5a
	.byte	0x2
	.byte	0x7e
	.sleb128 -20
	.uleb128 0x11
	.long	.LASF59
	.byte	0x1
	.byte	0x19
	.long	0x5a
	.byte	0x2
	.byte	0x7e
	.sleb128 -16
	.uleb128 0x12
	.string	"to"
	.byte	0x1
	.byte	0x20
	.long	0x2ef
	.byte	0x3
	.byte	0x7e
	.sleb128 -96
	.uleb128 0x11
	.long	.LASF60
	.byte	0x1
	.byte	0x21
	.long	0x34a
	.byte	0x3
	.byte	0x7e
	.sleb128 -224
	.uleb128 0x11
	.long	.LASF61
	.byte	0x1
	.byte	0x22
	.long	0x5a
	.byte	0x2
	.byte	0x7e
	.sleb128 -12
	.uleb128 0x13
	.long	.LBB2
	.long	.LBE2
	.uleb128 0x12
	.string	"__i"
	.byte	0x1
	.byte	0x29
	.long	0x30
	.byte	0x2
	.byte	0x7e
	.sleb128 -8
	.uleb128 0x11
	.long	.LASF62
	.byte	0x1
	.byte	0x29
	.long	0x426
	.byte	0x2
	.byte	0x7e
	.sleb128 -4
	.byte	0x0
	.byte	0x0
	.uleb128 0x7
	.byte	0x4
	.long	0x34a
	.uleb128 0xf
	.byte	0x1
	.long	.LASF64
	.byte	0x1
	.byte	0x47
	.byte	0x1
	.long	0x5a
	.long	.LFB2
	.long	.LFE2
	.long	.LLST1
	.long	0x474
	.uleb128 0x14
	.long	.LASF65
	.byte	0x1
	.byte	0x47
	.long	0x5a
	.byte	0x2
	.byte	0x91
	.sleb128 0
	.uleb128 0x14
	.long	.LASF66
	.byte	0x1
	.byte	0x47
	.long	0x474
	.byte	0x2
	.byte	0x91
	.sleb128 4
	.uleb128 0x12
	.string	"tid"
	.byte	0x1
	.byte	0x49
	.long	0x355
	.byte	0x2
	.byte	0x7e
	.sleb128 -4
	.byte	0x0
	.uleb128 0x7
	.byte	0x4
	.long	0xb2
	.uleb128 0x15
	.long	.LASF67
	.byte	0x5
	.byte	0x92
	.long	0x2c3
	.byte	0x1
	.byte	0x1
	.uleb128 0x15
	.long	.LASF68
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
	.uleb128 0x11
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
	.uleb128 0x12
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
	.uleb128 0x13
	.uleb128 0xb
	.byte	0x1
	.uleb128 0x11
	.uleb128 0x1
	.uleb128 0x12
	.uleb128 0x1
	.byte	0x0
	.byte	0x0
	.uleb128 0x14
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
	.long	0x495
	.long	0x370
	.string	"threadfunc"
	.long	0x42c
	.string	"main"
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
.LASF58:
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
.LASF61:
	.string	"retval"
.LASF28:
	.string	"_markers"
.LASF18:
	.string	"_IO_read_end"
.LASF57:
	.string	"line"
.LASF4:
	.string	"signed char"
.LASF53:
	.string	"__fd_mask"
.LASF54:
	.string	"__fds_bits"
.LASF68:
	.string	"stderr"
.LASF6:
	.string	"long long int"
.LASF36:
	.string	"_lock"
.LASF11:
	.string	"long int"
.LASF63:
	.string	"threadfunc"
.LASF33:
	.string	"_cur_column"
.LASF49:
	.string	"_pos"
.LASF66:
	.string	"argv"
.LASF48:
	.string	"_sbuf"
.LASF32:
	.string	"_old_offset"
.LASF1:
	.string	"unsigned char"
.LASF65:
	.string	"argc"
.LASF59:
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
.LASF64:
	.string	"main"
.LASF62:
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
.LASF71:
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
.LASF60:
	.string	"rdfs"
.LASF70:
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
.LASF69:
	.string	"GNU C 4.4.1"
.LASF14:
	.string	"__suseconds_t"
.LASF55:
	.string	"fd_set"
.LASF56:
	.string	"pthread_t"
.LASF67:
	.string	"stdout"
.LASF72:
	.string	"_IO_lock_t"
	.ident	"GCC: (Sourcery G++ Lite 4.4-217) 4.4.1"
	.section	.note.GNU-stack,"",@progbits
