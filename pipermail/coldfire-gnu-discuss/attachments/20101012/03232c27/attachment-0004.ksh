
rpm/BUILD/test_select-1.0/a.out:     file format elf32-m68k


Disassembly of section .init:

80000450 <_init>:
80000450:	4e56 0000      	linkw %fp,#0
80000454:	2f0d           	movel %a5,%sp@-
80000456:	2a7c 0000 26e8 	moveal #9960,%a5
8000045c:	4bfb d8fa      	lea %pc@(80000458 <_init+0x8>,%a5:l),%a5
80000460:	4aad 0000      	tstl %a5@(0)
80000464:	6706           	beqs 8000046c <_init+0x1c>
80000466:	61ff 0000 0048 	bsrl 800004b0 <__gmon_start__@plt>
8000046c:	4eb9 8000 062c 	jsr 8000062c <frame_dummy>
80000472:	4eb9 8000 0928 	jsr 80000928 <__do_global_ctors_aux>
80000478:	2a6e fffc      	moveal %fp@(-4),%a5
8000047c:	4e5e           	unlk %fp
8000047e:	4e75           	rts

Disassembly of section .plt:

80000480 <__libc_start_main@plt-0x18>:
80000480:	203c 0000 2682 	movel #9858,%d0
80000486:	2f3b 08fa      	movel %pc@(80000482 <_init+0x32>,%d0:l),%sp@-
8000048a:	203c 0000 267c 	movel #9852,%d0
80000490:	207b 08fa      	moveal %pc@(8000048c <_init+0x3c>,%d0:l),%a0
80000494:	4ed0           	jmp %a0@
80000496:	4e71           	nop

80000498 <__libc_start_main@plt>:
80000498:	203c 0000 2672 	movel #9842,%d0
8000049e:	207b 08fa      	moveal %pc@(8000049a <__libc_start_main@plt+0x2>,%d0:l),%a0
800004a2:	4ed0           	jmp %a0@
800004a4:	2f3c 0000 0000 	movel #0,%sp@-
800004aa:	60ff ffff ffd4 	bral 80000480 <_init+0x30>

800004b0 <__gmon_start__@plt>:
800004b0:	203c 0000 265e 	movel #9822,%d0
800004b6:	207b 08fa      	moveal %pc@(800004b2 <__gmon_start__@plt+0x2>,%d0:l),%a0
800004ba:	4ed0           	jmp %a0@
800004bc:	2f3c 0000 000c 	movel #12,%sp@-
800004c2:	60ff ffff ffbc 	bral 80000480 <_init+0x30>

800004c8 <memset@plt>:
800004c8:	203c 0000 264a 	movel #9802,%d0
800004ce:	207b 08fa      	moveal %pc@(800004ca <memset@plt+0x2>,%d0:l),%a0
800004d2:	4ed0           	jmp %a0@
800004d4:	2f3c 0000 0018 	movel #24,%sp@-
800004da:	60ff ffff ffa4 	bral 80000480 <_init+0x30>

800004e0 <perror@plt>:
800004e0:	203c 0000 2636 	movel #9782,%d0
800004e6:	207b 08fa      	moveal %pc@(800004e2 <perror@plt+0x2>,%d0:l),%a0
800004ea:	4ed0           	jmp %a0@
800004ec:	2f3c 0000 0024 	movel #36,%sp@-
800004f2:	60ff ffff ff8c 	bral 80000480 <_init+0x30>

800004f8 <read@plt>:
800004f8:	203c 0000 2622 	movel #9762,%d0
800004fe:	207b 08fa      	moveal %pc@(800004fa <read@plt+0x2>,%d0:l),%a0
80000502:	4ed0           	jmp %a0@
80000504:	2f3c 0000 0030 	movel #48,%sp@-
8000050a:	60ff ffff ff74 	bral 80000480 <_init+0x30>

80000510 <pthread_create@plt>:
80000510:	203c 0000 260e 	movel #9742,%d0
80000516:	207b 08fa      	moveal %pc@(80000512 <pthread_create@plt+0x2>,%d0:l),%a0
8000051a:	4ed0           	jmp %a0@
8000051c:	2f3c 0000 003c 	movel #60,%sp@-
80000522:	60ff ffff ff5c 	bral 80000480 <_init+0x30>

80000528 <select@plt>:
80000528:	203c 0000 25fa 	movel #9722,%d0
8000052e:	207b 08fa      	moveal %pc@(8000052a <select@plt+0x2>,%d0:l),%a0
80000532:	4ed0           	jmp %a0@
80000534:	2f3c 0000 0048 	movel #72,%sp@-
8000053a:	60ff ffff ff44 	bral 80000480 <_init+0x30>

80000540 <fwrite@plt>:
80000540:	203c 0000 25e6 	movel #9702,%d0
80000546:	207b 08fa      	moveal %pc@(80000542 <fwrite@plt+0x2>,%d0:l),%a0
8000054a:	4ed0           	jmp %a0@
8000054c:	2f3c 0000 0054 	movel #84,%sp@-
80000552:	60ff ffff ff2c 	bral 80000480 <_init+0x30>

80000558 <fprintf@plt>:
80000558:	203c 0000 25d2 	movel #9682,%d0
8000055e:	207b 08fa      	moveal %pc@(8000055a <fprintf@plt+0x2>,%d0:l),%a0
80000562:	4ed0           	jmp %a0@
80000564:	2f3c 0000 0060 	movel #96,%sp@-
8000056a:	60ff ffff ff14 	bral 80000480 <_init+0x30>

80000570 <sleep@plt>:
80000570:	203c 0000 25be 	movel #9662,%d0
80000576:	207b 08fa      	moveal %pc@(80000572 <sleep@plt+0x2>,%d0:l),%a0
8000057a:	4ed0           	jmp %a0@
8000057c:	2f3c 0000 006c 	movel #108,%sp@-
80000582:	60ff ffff fefc 	bral 80000480 <_init+0x30>

80000588 <dup2@plt>:
80000588:	203c 0000 25aa 	movel #9642,%d0
8000058e:	207b 08fa      	moveal %pc@(8000058a <dup2@plt+0x2>,%d0:l),%a0
80000592:	4ed0           	jmp %a0@
80000594:	2f3c 0000 0078 	movel #120,%sp@-
8000059a:	60ff ffff fee4 	bral 80000480 <_init+0x30>

Disassembly of section .text:

800005a0 <_start>:
800005a0:	9dce           	subal %fp,%fp
800005a2:	201f           	movel %sp@+,%d0
800005a4:	204f           	moveal %sp,%a0
800005a6:	4857           	pea %sp@
800005a8:	4851           	pea %a1@
800005aa:	4879 8000 08cc 	pea 800008cc <__libc_csu_fini>
800005b0:	4879 8000 08d4 	pea 800008d4 <__libc_csu_init>
800005b6:	4850           	pea %a0@
800005b8:	2f00           	movel %d0,%sp@-
800005ba:	4879 8000 0882 	pea 80000882 <main>
800005c0:	61ff ffff fed6 	bsrl 80000498 <__libc_start_main@plt>
800005c6:	4afc           	illegal

800005c8 <__do_global_dtors_aux>:
800005c8:	4e56 0000      	linkw %fp,#0
800005cc:	2f0a           	movel %a2,%sp@-
800005ce:	2f02           	movel %d2,%sp@-
800005d0:	4a39 8000 2b58 	tstb 80002b58 <completed.5751>
800005d6:	6640           	bnes 80000618 <__do_global_dtors_aux+0x50>
800005d8:	243c 8000 2a28 	movel #-2147472856,%d2
800005de:	2039 8000 2b5a 	movel 80002b5a <dtor_idx.5753>,%d0
800005e4:	0482 8000 2a24 	subil #-2147472860,%d2
800005ea:	e482           	asrl #2,%d2
800005ec:	5382           	subql #1,%d2
800005ee:	b480           	cmpl %d0,%d2
800005f0:	631e           	blss 80000610 <__do_global_dtors_aux+0x48>
800005f2:	45f9 8000 2a24 	lea 80002a24 <__DTOR_LIST__>,%a2
800005f8:	5280           	addql #1,%d0
800005fa:	23c0 8000 2b5a 	movel %d0,80002b5a <dtor_idx.5753>
80000600:	2072 0c00      	moveal %a2@(00000000,%d0:l:4),%a0
80000604:	4e90           	jsr %a0@
80000606:	2039 8000 2b5a 	movel 80002b5a <dtor_idx.5753>,%d0
8000060c:	b480           	cmpl %d0,%d2
8000060e:	62e8           	bhis 800005f8 <__do_global_dtors_aux+0x30>
80000610:	7001           	moveq #1,%d0
80000612:	13c0 8000 2b58 	moveb %d0,80002b58 <completed.5751>
80000618:	242e fff8      	movel %fp@(-8),%d2
8000061c:	246e fffc      	moveal %fp@(-4),%a2
80000620:	4e5e           	unlk %fp
80000622:	4e75           	rts

80000624 <call___do_global_dtors_aux>:
80000624:	4e56 0000      	linkw %fp,#0
80000628:	4e5e           	unlk %fp
8000062a:	4e75           	rts

8000062c <frame_dummy>:
8000062c:	4e56 0000      	linkw %fp,#0
80000630:	4ab9 8000 2a2c 	tstl 80002a2c <__JCR_END__>
80000636:	6714           	beqs 8000064c <frame_dummy+0x20>
80000638:	41f9 0000 0000 	lea 0 <_init-0x80000450>,%a0
8000063e:	4a88           	tstl %a0
80000640:	670a           	beqs 8000064c <frame_dummy+0x20>
80000642:	4879 8000 2a2c 	pea 80002a2c <__JCR_END__>
80000648:	4e90           	jsr %a0@
8000064a:	588f           	addql #4,%sp
8000064c:	4e5e           	unlk %fp
8000064e:	4e75           	rts

80000650 <call_frame_dummy>:
80000650:	4e56 0000      	linkw %fp,#0
80000654:	4e5e           	unlk %fp
80000656:	4e75           	rts

80000658 <threadfunc>:
#include <sys/types.h>
#include <unistd.h>
#include <pthread.h>

void* threadfunc( void *arg )
{
80000658:	4e56 ff20      	linkw %fp,#-224
8000065c:	2f0a           	movel %a2,%sp@-
8000065e:	2f02           	movel %d2,%sp@-

    char line[64]={0};
80000660:	200e           	movel %fp,%d0
80000662:	0680 ffff ffa8 	addil #-88,%d0
80000668:	7240           	moveq #64,%d1
8000066a:	2f01           	movel %d1,%sp@-
8000066c:	42a7           	clrl %sp@-
8000066e:	2f00           	movel %d0,%sp@-
80000670:	4eb9 8000 04c8 	jsr 800004c8 <memset@plt>
80000676:	4fef 000c      	lea %sp@(12),%sp
    int run = 1;
8000067a:	a36e ffe8      	mov3ql #1,%fp@(-24)
    int select_fd = 67;
8000067e:	7043           	moveq #67,%d0
80000680:	2d40 ffec      	movel %d0,%fp@(-20)
    
    if( dup2( STDIN_FILENO, select_fd ) == -1 )
80000684:	2f2e ffec      	movel %fp@(-20),%sp@-
80000688:	42a7           	clrl %sp@-
8000068a:	4eb9 8000 0588 	jsr 80000588 <dup2@plt>
80000690:	508f           	addql #8,%sp
80000692:	a141           	mov3ql #-1,%d1
80000694:	b280           	cmpl %d0,%d1
80000696:	6614           	bnes 800006ac <threadfunc+0x54>
    {
        perror( "dup2()" );
80000698:	4879 8000 096e 	pea 8000096e <_IO_stdin_used+0x4>
8000069e:	4eb9 8000 04e0 	jsr 800004e0 <perror@plt>
800006a4:	588f           	addql #4,%sp
        return NULL;
800006a6:	4280           	clrl %d0
800006a8:	6000 01c8      	braw 80000872 <threadfunc+0x21a>
    }
    
    //close( STDIN_FILENO );
/*    int test1 = 33;
    int test3 = 127;*/
    int nfds = select_fd + 1;
800006ac:	242e ffec      	movel %fp@(-20),%d2
800006b0:	5282           	addql #1,%d2
800006b2:	2d42 fff0      	movel %d2,%fp@(-16)
        fprintf( stderr, "%d - %d\n", test1, test2 );
        test3=test2;*/
    
    struct timeval to;
    fd_set rdfs;
    int retval = 0;
800006b6:	42ae fff4      	clrl %fp@(-12)
    
    while( run )
800006ba:	6000 01ac      	braw 80000868 <threadfunc+0x210>
    {
        to.tv_sec = 5;
800006be:	ab6e ffa0      	mov3ql #5,%fp@(-96)
        to.tv_usec = 0;
800006c2:	42ae ffa4      	clrl %fp@(-92)
        
        FD_ZERO(&rdfs);
800006c6:	41ee ff20      	lea %fp@(-224),%a0
800006ca:	2d48 fffc      	movel %a0,%fp@(-4)
800006ce:	42ae fff8      	clrl %fp@(-8)
800006d2:	6012           	bras 800006e6 <threadfunc+0x8e>
800006d4:	222e fff8      	movel %fp@(-8),%d1
800006d8:	202e fffc      	movel %fp@(-4),%d0
800006dc:	2440           	moveal %d0,%a2
800006de:	42b2 1c00      	clrl %a2@(00000000,%d1:l:4)
800006e2:	52ae fff8      	addql #1,%fp@(-8)
800006e6:	701f           	moveq #31,%d0
800006e8:	b0ae fff8      	cmpl %fp@(-8),%d0
800006ec:	64e6           	bccs 800006d4 <threadfunc+0x7c>
        FD_SET(select_fd,&rdfs);        
800006ee:	202e ffec      	movel %fp@(-20),%d0
800006f2:	4a80           	tstl %d0
800006f4:	6c06           	bges 800006fc <threadfunc+0xa4>
800006f6:	0680 0000 001f 	addil #31,%d0
800006fc:	ea80           	asrl #5,%d0
800006fe:	2040           	moveal %d0,%a0
80000700:	e588           	lsll #2,%d0
80000702:	d08e           	addl %fp,%d0
80000704:	2440           	moveal %d0,%a2
80000706:	226a ff20      	moveal %a2@(-224),%a1
8000070a:	202e ffec      	movel %fp@(-20),%d0
8000070e:	0280 8000 001f 	andil #-2147483617,%d0
80000714:	4a80           	tstl %d0
80000716:	6c08           	bges 80000720 <threadfunc+0xc8>
80000718:	5380           	subql #1,%d0
8000071a:	72e0           	moveq #-32,%d1
8000071c:	8081           	orl %d1,%d0
8000071e:	5280           	addql #1,%d0
80000720:	a341           	mov3ql #1,%d1
80000722:	2401           	movel %d1,%d2
80000724:	e1aa           	lsll %d0,%d2
80000726:	2002           	movel %d2,%d0
80000728:	2209           	movel %a1,%d1
8000072a:	8280           	orl %d0,%d1
8000072c:	2008           	movel %a0,%d0
8000072e:	e588           	lsll #2,%d0
80000730:	d08e           	addl %fp,%d0
80000732:	2040           	moveal %d0,%a0
80000734:	2141 ff20      	movel %d1,%a0@(-224)
        
        fprintf( stdout, "before select_fd=%d | nfds=%d | sec = %d | usec = %d\n", select_fd, nfds, to.tv_sec, to.tv_usec );
80000738:	226e ffa4      	moveal %fp@(-92),%a1
8000073c:	206e ffa0      	moveal %fp@(-96),%a0
80000740:	223c 8000 0975 	movel #-2147481227,%d1
80000746:	2039 8000 2b50 	movel 80002b50 <__bss_start>,%d0
8000074c:	2f09           	movel %a1,%sp@-
8000074e:	2f08           	movel %a0,%sp@-
80000750:	2f2e fff0      	movel %fp@(-16),%sp@-
80000754:	2f2e ffec      	movel %fp@(-20),%sp@-
80000758:	2f01           	movel %d1,%sp@-
8000075a:	2f00           	movel %d0,%sp@-
8000075c:	4eb9 8000 0558 	jsr 80000558 <fprintf@plt>
80000762:	4fef 0018      	lea %sp@(24),%sp
        retval = select( nfds, &rdfs, NULL, NULL, &to );
80000766:	200e           	movel %fp,%d0
80000768:	0680 ffff ffa0 	addil #-96,%d0
8000076e:	2f00           	movel %d0,%sp@-
80000770:	42a7           	clrl %sp@-
80000772:	42a7           	clrl %sp@-
80000774:	200e           	movel %fp,%d0
80000776:	0680 ffff ff20 	addil #-224,%d0
8000077c:	2f00           	movel %d0,%sp@-
8000077e:	2f2e fff0      	movel %fp@(-16),%sp@-
80000782:	4eb9 8000 0528 	jsr 80000528 <select@plt>
80000788:	4fef 0014      	lea %sp@(20),%sp
8000078c:	2d40 fff4      	movel %d0,%fp@(-12)
        fprintf( stdout, "after select_fd=%d | nfds=%d | sec = %d | usec = %d | retval = %d\n", select_fd, nfds, to.tv_sec, to.tv_usec, retval );
80000790:	226e ffa4      	moveal %fp@(-92),%a1
80000794:	206e ffa0      	moveal %fp@(-96),%a0
80000798:	223c 8000 09ab 	movel #-2147481173,%d1
8000079e:	2039 8000 2b50 	movel 80002b50 <__bss_start>,%d0
800007a4:	2f2e fff4      	movel %fp@(-12),%sp@-
800007a8:	2f09           	movel %a1,%sp@-
800007aa:	2f08           	movel %a0,%sp@-
800007ac:	2f2e fff0      	movel %fp@(-16),%sp@-
800007b0:	2f2e ffec      	movel %fp@(-20),%sp@-
800007b4:	2f01           	movel %d1,%sp@-
800007b6:	2f00           	movel %d0,%sp@-
800007b8:	4eb9 8000 0558 	jsr 80000558 <fprintf@plt>
800007be:	4fef 001c      	lea %sp@(28),%sp
        
        if( retval > 0 )
800007c2:	4aae fff4      	tstl %fp@(-12)
800007c6:	6f00 0088      	blew 80000850 <threadfunc+0x1f8>
        {
            if FD_ISSET(select_fd,&rdfs)
800007ca:	202e ffec      	movel %fp@(-20),%d0
800007ce:	4a80           	tstl %d0
800007d0:	6c06           	bges 800007d8 <threadfunc+0x180>
800007d2:	0680 0000 001f 	addil #31,%d0
800007d8:	ea80           	asrl #5,%d0
800007da:	e588           	lsll #2,%d0
800007dc:	d08e           	addl %fp,%d0
800007de:	2440           	moveal %d0,%a2
800007e0:	222a ff20      	movel %a2@(-224),%d1
800007e4:	202e ffec      	movel %fp@(-20),%d0
800007e8:	0280 8000 001f 	andil #-2147483617,%d0
800007ee:	4a80           	tstl %d0
800007f0:	6c08           	bges 800007fa <threadfunc+0x1a2>
800007f2:	5380           	subql #1,%d0
800007f4:	74e0           	moveq #-32,%d2
800007f6:	8082           	orl %d2,%d0
800007f8:	5280           	addql #1,%d0
800007fa:	2401           	movel %d1,%d2
800007fc:	e0a2           	asrl %d0,%d2
800007fe:	2002           	movel %d2,%d0
80000800:	a341           	mov3ql #1,%d1
80000802:	c081           	andl %d1,%d0
80000804:	1000           	moveb %d0,%d0
80000806:	4a00           	tstb %d0
80000808:	671e           	beqs 80000828 <threadfunc+0x1d0>
            {
                /* do something */
                read(select_fd, line, 64);
8000080a:	4878 0040      	pea 40 <_init-0x80000410>
8000080e:	200e           	movel %fp,%d0
80000810:	0680 ffff ffa8 	addil #-88,%d0
80000816:	2f00           	movel %d0,%sp@-
80000818:	2f2e ffec      	movel %fp@(-20),%sp@-
8000081c:	4eb9 8000 04f8 	jsr 800004f8 <read@plt>
80000822:	4fef 000c      	lea %sp@(12),%sp
            }
            else
            {
                fprintf( stderr, "unhandled fd\n" );
                run = 0;
80000826:	6040           	bras 80000868 <threadfunc+0x210>
                /* do something */
                read(select_fd, line, 64);
            }
            else
            {
                fprintf( stderr, "unhandled fd\n" );
80000828:	2039 8000 2b54 	movel 80002b54 <stderr@@GLIBC_2.4>,%d0
8000082e:	2200           	movel %d0,%d1
80000830:	203c 8000 09ee 	movel #-2147481106,%d0
80000836:	2f01           	movel %d1,%sp@-
80000838:	4878 000d      	pea d <_init-0x80000443>
8000083c:	a367           	mov3ql #1,%sp@-
8000083e:	2f00           	movel %d0,%sp@-
80000840:	4eb9 8000 0540 	jsr 80000540 <fwrite@plt>
80000846:	4fef 0010      	lea %sp@(16),%sp
                run = 0;
8000084a:	42ae ffe8      	clrl %fp@(-24)
8000084e:	6018           	bras 80000868 <threadfunc+0x210>
            }
        }
        else if( retval < 0 )
80000850:	4aae fff4      	tstl %fp@(-12)
80000854:	6c12           	bges 80000868 <threadfunc+0x210>
        {
            perror( "select()" );
80000856:	4879 8000 09fc 	pea 800009fc <_IO_stdin_used+0x92>
8000085c:	4eb9 8000 04e0 	jsr 800004e0 <perror@plt>
80000862:	588f           	addql #4,%sp
            run = 0;
80000864:	42ae ffe8      	clrl %fp@(-24)
    
    struct timeval to;
    fd_set rdfs;
    int retval = 0;
    
    while( run )
80000868:	4aae ffe8      	tstl %fp@(-24)
8000086c:	6600 fe50      	bnew 800006be <threadfunc+0x66>
            perror( "select()" );
            run = 0;
        }
    }

    return NULL;
80000870:	4280           	clrl %d0
80000872:	2200           	movel %d0,%d1
}
80000874:	2041           	moveal %d1,%a0
80000876:	242e ff18      	movel %fp@(-232),%d2
8000087a:	246e ff1c      	moveal %fp@(-228),%a2
8000087e:	4e5e           	unlk %fp
80000880:	4e75           	rts

80000882 <main>:

int main( int argc, char** argv )
{
80000882:	4e56 fffc      	linkw %fp,#-4
    pthread_t tid = 0;
80000886:	42ae fffc      	clrl %fp@(-4)
    
    if( pthread_create( &tid, NULL, threadfunc, NULL ) != 0 )
8000088a:	42a7           	clrl %sp@-
8000088c:	4879 8000 0658 	pea 80000658 <threadfunc>
80000892:	42a7           	clrl %sp@-
80000894:	200e           	movel %fp,%d0
80000896:	5980           	subql #4,%d0
80000898:	2f00           	movel %d0,%sp@-
8000089a:	4eb9 8000 0510 	jsr 80000510 <pthread_create@plt>
800008a0:	4fef 0010      	lea %sp@(16),%sp
800008a4:	4a80           	tstl %d0
800008a6:	6710           	beqs 800008b8 <main+0x36>
    {
        perror( "pthread_create()" );
800008a8:	4879 8000 0a05 	pea 80000a05 <_IO_stdin_used+0x9b>
800008ae:	4eb9 8000 04e0 	jsr 800004e0 <perror@plt>
800008b4:	588f           	addql #4,%sp
800008b6:	600c           	bras 800008c4 <main+0x42>
    }
    else
    {
        sleep(60);
800008b8:	4878 003c      	pea 3c <_init-0x80000414>
800008bc:	4eb9 8000 0570 	jsr 80000570 <sleep@plt>
800008c2:	588f           	addql #4,%sp
    }
    
    return 0;
800008c4:	4280           	clrl %d0
}
800008c6:	4e5e           	unlk %fp
800008c8:	4e75           	rts
800008ca:	4e75           	rts

800008cc <__libc_csu_fini>:
800008cc:	4e56 0000      	linkw %fp,#0
800008d0:	4e5e           	unlk %fp
800008d2:	4e75           	rts

800008d4 <__libc_csu_init>:
800008d4:	4e56 ffe4      	linkw %fp,#-28
800008d8:	48d7 247c      	moveml %d2-%d6/%a2/%a5,%sp@
800008dc:	2a7c 0000 2262 	moveal #8802,%a5
800008e2:	4bfb d8fa      	lea %pc@(800008de <__libc_csu_init+0xa>,%a5:l),%a5
800008e6:	282e 0008      	movel %fp@(8),%d4
800008ea:	2a2e 000c      	movel %fp@(12),%d5
800008ee:	2c2e 0010      	movel %fp@(16),%d6
800008f2:	61ff ffff fb5c 	bsrl 80000450 <_init>
800008f8:	246d 0004      	moveal %a5@(4),%a2
800008fc:	262d fff8      	movel %a5@(-8),%d3
80000900:	968a           	subl %a2,%d3
80000902:	e483           	asrl #2,%d3
80000904:	6716           	beqs 8000091c <__libc_csu_init+0x48>
80000906:	4282           	clrl %d2
80000908:	2f06           	movel %d6,%sp@-
8000090a:	2f05           	movel %d5,%sp@-
8000090c:	2f04           	movel %d4,%sp@-
8000090e:	205a           	moveal %a2@+,%a0
80000910:	5282           	addql #1,%d2
80000912:	4e90           	jsr %a0@
80000914:	4fef 000c      	lea %sp@(12),%sp
80000918:	b682           	cmpl %d2,%d3
8000091a:	62ec           	bhis 80000908 <__libc_csu_init+0x34>
8000091c:	4cee 247c ffe4 	moveml %fp@(-28),%d2-%d6/%a2/%a5
80000922:	4e5e           	unlk %fp
80000924:	4e75           	rts
80000926:	4e75           	rts

80000928 <__do_global_ctors_aux>:
80000928:	4e56 0000      	linkw %fp,#0
8000092c:	a140           	mov3ql #-1,%d0
8000092e:	2079 8000 2a1c 	moveal 80002a1c <__CTOR_LIST__>,%a0
80000934:	2f0a           	movel %a2,%sp@-
80000936:	b088           	cmpl %a0,%d0
80000938:	6710           	beqs 8000094a <__do_global_ctors_aux+0x22>
8000093a:	45f9 8000 2a1c 	lea 80002a1c <__CTOR_LIST__>,%a2
80000940:	4e90           	jsr %a0@
80000942:	2062           	moveal %a2@-,%a0
80000944:	a140           	mov3ql #-1,%d0
80000946:	b088           	cmpl %a0,%d0
80000948:	66f6           	bnes 80000940 <__do_global_ctors_aux+0x18>
8000094a:	246e fffc      	moveal %fp@(-4),%a2
8000094e:	4e5e           	unlk %fp
80000950:	4e75           	rts

80000952 <call___do_global_ctors_aux>:
80000952:	4e56 0000      	linkw %fp,#0
80000956:	4e5e           	unlk %fp
80000958:	4e75           	rts
8000095a:	4e75           	rts

Disassembly of section .fini:

8000095c <_fini>:
8000095c:	4e56 0000      	linkw %fp,#0
80000960:	4eb9 8000 05c8 	jsr 800005c8 <__do_global_dtors_aux>
80000966:	4e5e           	unlk %fp
80000968:	4e75           	rts
