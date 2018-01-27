
rpm/BUILD/test_select-1.0/a.out:     file format elf32-m68k


Disassembly of section .init:

80000450 <_init>:
80000450:	4e56 0000      	linkw %fp,#0
80000454:	2f0d           	movel %a5,%sp@-
80000456:	2a7c 0000 2604 	moveal #9732,%a5
8000045c:	4bfb d8fa      	lea %pc@(80000458 <_init+0x8>,%a5:l),%a5
80000460:	4aad 0000      	tstl %a5@(0)
80000464:	6706           	beqs 8000046c <_init+0x1c>
80000466:	61ff 0000 0048 	bsrl 800004b0 <__gmon_start__@plt>
8000046c:	4eb9 8000 062c 	jsr 8000062c <frame_dummy>
80000472:	4eb9 8000 0844 	jsr 80000844 <__do_global_ctors_aux>
80000478:	2a6e fffc      	moveal %fp@(-4),%a5
8000047c:	4e5e           	unlk %fp
8000047e:	4e75           	rts

Disassembly of section .plt:

80000480 <__libc_start_main@plt-0x18>:
80000480:	203c 0000 259e 	movel #9630,%d0
80000486:	2f3b 08fa      	movel %pc@(80000482 <_init+0x32>,%d0:l),%sp@-
8000048a:	203c 0000 2598 	movel #9624,%d0
80000490:	207b 08fa      	moveal %pc@(8000048c <_init+0x3c>,%d0:l),%a0
80000494:	4ed0           	jmp %a0@
80000496:	4e71           	nop

80000498 <__libc_start_main@plt>:
80000498:	203c 0000 258e 	movel #9614,%d0
8000049e:	207b 08fa      	moveal %pc@(8000049a <__libc_start_main@plt+0x2>,%d0:l),%a0
800004a2:	4ed0           	jmp %a0@
800004a4:	2f3c 0000 0000 	movel #0,%sp@-
800004aa:	60ff ffff ffd4 	bral 80000480 <_init+0x30>

800004b0 <__gmon_start__@plt>:
800004b0:	203c 0000 257a 	movel #9594,%d0
800004b6:	207b 08fa      	moveal %pc@(800004b2 <__gmon_start__@plt+0x2>,%d0:l),%a0
800004ba:	4ed0           	jmp %a0@
800004bc:	2f3c 0000 000c 	movel #12,%sp@-
800004c2:	60ff ffff ffbc 	bral 80000480 <_init+0x30>

800004c8 <memset@plt>:
800004c8:	203c 0000 2566 	movel #9574,%d0
800004ce:	207b 08fa      	moveal %pc@(800004ca <memset@plt+0x2>,%d0:l),%a0
800004d2:	4ed0           	jmp %a0@
800004d4:	2f3c 0000 0018 	movel #24,%sp@-
800004da:	60ff ffff ffa4 	bral 80000480 <_init+0x30>

800004e0 <perror@plt>:
800004e0:	203c 0000 2552 	movel #9554,%d0
800004e6:	207b 08fa      	moveal %pc@(800004e2 <perror@plt+0x2>,%d0:l),%a0
800004ea:	4ed0           	jmp %a0@
800004ec:	2f3c 0000 0024 	movel #36,%sp@-
800004f2:	60ff ffff ff8c 	bral 80000480 <_init+0x30>

800004f8 <read@plt>:
800004f8:	203c 0000 253e 	movel #9534,%d0
800004fe:	207b 08fa      	moveal %pc@(800004fa <read@plt+0x2>,%d0:l),%a0
80000502:	4ed0           	jmp %a0@
80000504:	2f3c 0000 0030 	movel #48,%sp@-
8000050a:	60ff ffff ff74 	bral 80000480 <_init+0x30>

80000510 <pthread_create@plt>:
80000510:	203c 0000 252a 	movel #9514,%d0
80000516:	207b 08fa      	moveal %pc@(80000512 <pthread_create@plt+0x2>,%d0:l),%a0
8000051a:	4ed0           	jmp %a0@
8000051c:	2f3c 0000 003c 	movel #60,%sp@-
80000522:	60ff ffff ff5c 	bral 80000480 <_init+0x30>

80000528 <select@plt>:
80000528:	203c 0000 2516 	movel #9494,%d0
8000052e:	207b 08fa      	moveal %pc@(8000052a <select@plt+0x2>,%d0:l),%a0
80000532:	4ed0           	jmp %a0@
80000534:	2f3c 0000 0048 	movel #72,%sp@-
8000053a:	60ff ffff ff44 	bral 80000480 <_init+0x30>

80000540 <fwrite@plt>:
80000540:	203c 0000 2502 	movel #9474,%d0
80000546:	207b 08fa      	moveal %pc@(80000542 <fwrite@plt+0x2>,%d0:l),%a0
8000054a:	4ed0           	jmp %a0@
8000054c:	2f3c 0000 0054 	movel #84,%sp@-
80000552:	60ff ffff ff2c 	bral 80000480 <_init+0x30>

80000558 <fprintf@plt>:
80000558:	203c 0000 24ee 	movel #9454,%d0
8000055e:	207b 08fa      	moveal %pc@(8000055a <fprintf@plt+0x2>,%d0:l),%a0
80000562:	4ed0           	jmp %a0@
80000564:	2f3c 0000 0060 	movel #96,%sp@-
8000056a:	60ff ffff ff14 	bral 80000480 <_init+0x30>

80000570 <sleep@plt>:
80000570:	203c 0000 24da 	movel #9434,%d0
80000576:	207b 08fa      	moveal %pc@(80000572 <sleep@plt+0x2>,%d0:l),%a0
8000057a:	4ed0           	jmp %a0@
8000057c:	2f3c 0000 006c 	movel #108,%sp@-
80000582:	60ff ffff fefc 	bral 80000480 <_init+0x30>

80000588 <dup2@plt>:
80000588:	203c 0000 24c6 	movel #9414,%d0
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
800005aa:	4879 8000 07e8 	pea 800007e8 <__libc_csu_fini>
800005b0:	4879 8000 07f0 	pea 800007f0 <__libc_csu_init>
800005b6:	4850           	pea %a0@
800005b8:	2f00           	movel %d0,%sp@-
800005ba:	4879 8000 0658 	pea 80000658 <main>
800005c0:	61ff ffff fed6 	bsrl 80000498 <__libc_start_main@plt>
800005c6:	4afc           	illegal

800005c8 <__do_global_dtors_aux>:
800005c8:	4e56 0000      	linkw %fp,#0
800005cc:	2f0a           	movel %a2,%sp@-
800005ce:	2f02           	movel %d2,%sp@-
800005d0:	4a39 8000 2a74 	tstb 80002a74 <completed.5751>
800005d6:	6640           	bnes 80000618 <__do_global_dtors_aux+0x50>
800005d8:	243c 8000 2944 	movel #-2147473084,%d2
800005de:	2039 8000 2a76 	movel 80002a76 <dtor_idx.5753>,%d0
800005e4:	0482 8000 2940 	subil #-2147473088,%d2
800005ea:	e482           	asrl #2,%d2
800005ec:	5382           	subql #1,%d2
800005ee:	b480           	cmpl %d0,%d2
800005f0:	631e           	blss 80000610 <__do_global_dtors_aux+0x48>
800005f2:	45f9 8000 2940 	lea 80002940 <__DTOR_LIST__>,%a2
800005f8:	5280           	addql #1,%d0
800005fa:	23c0 8000 2a76 	movel %d0,80002a76 <dtor_idx.5753>
80000600:	2072 0c00      	moveal %a2@(00000000,%d0:l:4),%a0
80000604:	4e90           	jsr %a0@
80000606:	2039 8000 2a76 	movel 80002a76 <dtor_idx.5753>,%d0
8000060c:	b480           	cmpl %d0,%d2
8000060e:	62e8           	bhis 800005f8 <__do_global_dtors_aux+0x30>
80000610:	7001           	moveq #1,%d0
80000612:	13c0 8000 2a74 	moveb %d0,80002a74 <completed.5751>
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
80000630:	4ab9 8000 2948 	tstl 80002948 <__JCR_END__>
80000636:	6714           	beqs 8000064c <frame_dummy+0x20>
80000638:	41f9 0000 0000 	lea 0 <_init-0x80000450>,%a0
8000063e:	4a88           	tstl %a0
80000640:	670a           	beqs 8000064c <frame_dummy+0x20>
80000642:	4879 8000 2948 	pea 80002948 <__JCR_END__>
80000648:	4e90           	jsr %a0@
8000064a:	588f           	addql #4,%sp
8000064c:	4e5e           	unlk %fp
8000064e:	4e75           	rts

80000650 <call_frame_dummy>:
80000650:	4e56 0000      	linkw %fp,#0
80000654:	4e5e           	unlk %fp
80000656:	4e75           	rts

80000658 <main>:

    return NULL;
}

int main( int argc, char** argv )
{
80000658:	4e56 fffc      	linkw %fp,#-4
    pthread_t tid = 0;
8000065c:	204e           	moveal %fp,%a0
8000065e:	42a0           	clrl %a0@-
    
    if( pthread_create( &tid, NULL, threadfunc, NULL ) != 0 )
80000660:	42a7           	clrl %sp@-
80000662:	4879 8000 06a0 	pea 800006a0 <threadfunc>
80000668:	42a7           	clrl %sp@-
8000066a:	2f08           	movel %a0,%sp@-
8000066c:	4eb9 8000 0510 	jsr 80000510 <pthread_create@plt>
80000672:	4fef 0010      	lea %sp@(16),%sp
80000676:	4a80           	tstl %d0
80000678:	6612           	bnes 8000068c <main+0x34>
    {
        perror( "pthread_create()" );
    }
    else
    {
        sleep(60);
8000067a:	4878 003c      	pea 3c <_init-0x80000414>
8000067e:	4eb9 8000 0570 	jsr 80000570 <sleep@plt>
80000684:	588f           	addql #4,%sp
    }
    
    return 0;
}
80000686:	4e5e           	unlk %fp
80000688:	4280           	clrl %d0
8000068a:	4e75           	rts
{
    pthread_t tid = 0;
    
    if( pthread_create( &tid, NULL, threadfunc, NULL ) != 0 )
    {
        perror( "pthread_create()" );
8000068c:	4879 8000 088a 	pea 8000088a <_IO_stdin_used+0x4>
80000692:	4eb9 8000 04e0 	jsr 800004e0 <perror@plt>
80000698:	588f           	addql #4,%sp
    {
        sleep(60);
    }
    
    return 0;
}
8000069a:	4e5e           	unlk %fp
8000069c:	4280           	clrl %d0
8000069e:	4e75           	rts

800006a0 <threadfunc>:
#include <sys/types.h>
#include <unistd.h>
#include <pthread.h>

void* threadfunc( void *arg )
{
800006a0:	4e56 ff1c      	linkw %fp,#-228
800006a4:	48d7 1c3c      	moveml %d2-%d5/%a2-%a4,%sp@

    char line[64]={0};
800006a8:	4878 0040      	pea 40 <_init-0x80000410>
800006ac:	240e           	movel %fp,%d2
800006ae:	42a7           	clrl %sp@-
800006b0:	0682 ffff ffb8 	addil #-72,%d2
800006b6:	2f02           	movel %d2,%sp@-
800006b8:	4eb9 8000 04c8 	jsr 800004c8 <memset@plt>
    int run = 1;
    int select_fd = 67;
    
    if( dup2( STDIN_FILENO, select_fd ) == -1 )
800006be:	4878 0043      	pea 43 <_init-0x8000040d>
800006c2:	42a7           	clrl %sp@-
800006c4:	4eb9 8000 0588 	jsr 80000588 <dup2@plt>
800006ca:	4fef 0014      	lea %sp@(20),%sp
800006ce:	a141           	mov3ql #-1,%d1
800006d0:	b280           	cmpl %d0,%d1
800006d2:	6700 00f6      	beqw 800007ca <threadfunc+0x12a>
800006d6:	280e           	movel %fp,%d4
800006d8:	2a0e           	movel %fp,%d5
800006da:	0684 ffff ff38 	addil #-200,%d4
800006e0:	45f9 8000 0558 	lea 80000558 <fprintf@plt>,%a2
800006e6:	5185           	subql #8,%d5
800006e8:	47f9 8000 0528 	lea 80000528 <select@plt>,%a3
        if( retval > 0 )
        {
            if FD_ISSET(select_fd,&rdfs)
            {
                /* do something */
                read(select_fd, line, 64);
800006ee:	49f9 8000 04f8 	lea 800004f8 <read@plt>,%a4
    int select_fd = 67;
    
    if( dup2( STDIN_FILENO, select_fd ) == -1 )
    {
        perror( "dup2()" );
        return NULL;
800006f4:	2044           	moveal %d4,%a0
    while( run )
    {
        to.tv_sec = 5;
        to.tv_usec = 0;
        
        FD_ZERO(&rdfs);
800006f6:	4298           	clrl %a0@+
800006f8:	b488           	cmpl %a0,%d2
800006fa:	66fa           	bnes 800006f6 <threadfunc+0x56>
        FD_SET(select_fd,&rdfs);        
        
        fprintf( stdout, "before select_fd=%d | nfds=%d | sec = %d | usec = %d\n", select_fd, nfds, to.tv_sec, to.tv_usec );
800006fc:	42a7           	clrl %sp@-
    {
        to.tv_sec = 5;
        to.tv_usec = 0;
        
        FD_ZERO(&rdfs);
        FD_SET(select_fd,&rdfs);        
800006fe:	7008           	moveq #8,%d0
        
        fprintf( stdout, "before select_fd=%d | nfds=%d | sec = %d | usec = %d\n", select_fd, nfds, to.tv_sec, to.tv_usec );
80000700:	ab67           	mov3ql #5,%sp@-
80000702:	4878 0044      	pea 44 <_init-0x8000040c>
80000706:	4878 0043      	pea 43 <_init-0x8000040d>
8000070a:	4879 8000 08a2 	pea 800008a2 <_IO_stdin_used+0x1c>
80000710:	2f39 8000 2a6c 	movel 80002a6c <__bss_start>,%sp@-
    {
        to.tv_sec = 5;
        to.tv_usec = 0;
        
        FD_ZERO(&rdfs);
        FD_SET(select_fd,&rdfs);        
80000716:	81ae ff40      	orl %d0,%fp@(-192)
    fd_set rdfs;
    int retval = 0;
    
    while( run )
    {
        to.tv_sec = 5;
8000071a:	ab6e fff8      	mov3ql #5,%fp@(-8)
        to.tv_usec = 0;
8000071e:	42ae fffc      	clrl %fp@(-4)
        
        FD_ZERO(&rdfs);
        FD_SET(select_fd,&rdfs);        
        
        fprintf( stdout, "before select_fd=%d | nfds=%d | sec = %d | usec = %d\n", select_fd, nfds, to.tv_sec, to.tv_usec );
80000722:	4e92           	jsr %a2@
        retval = select( nfds, &rdfs, NULL, NULL, &to );
80000724:	2f05           	movel %d5,%sp@-
80000726:	42a7           	clrl %sp@-
80000728:	42a7           	clrl %sp@-
8000072a:	2f04           	movel %d4,%sp@-
8000072c:	4878 0044      	pea 44 <_init-0x8000040c>
80000730:	4e93           	jsr %a3@
        fprintf( stdout, "after select_fd=%d | nfds=%d | sec = %d | usec = %d | retval = %d\n", select_fd, nfds, to.tv_sec, to.tv_usec, retval );
80000732:	4fef 0028      	lea %sp@(40),%sp
80000736:	2e80           	movel %d0,%sp@
        
        FD_ZERO(&rdfs);
        FD_SET(select_fd,&rdfs);        
        
        fprintf( stdout, "before select_fd=%d | nfds=%d | sec = %d | usec = %d\n", select_fd, nfds, to.tv_sec, to.tv_usec );
        retval = select( nfds, &rdfs, NULL, NULL, &to );
80000738:	2600           	movel %d0,%d3
        fprintf( stdout, "after select_fd=%d | nfds=%d | sec = %d | usec = %d | retval = %d\n", select_fd, nfds, to.tv_sec, to.tv_usec, retval );
8000073a:	2f2e fffc      	movel %fp@(-4),%sp@-
8000073e:	2f2e fff8      	movel %fp@(-8),%sp@-
80000742:	4878 0044      	pea 44 <_init-0x8000040c>
80000746:	4878 0043      	pea 43 <_init-0x8000040d>
8000074a:	4879 8000 08d8 	pea 800008d8 <_IO_stdin_used+0x52>
80000750:	2f39 8000 2a6c 	movel 80002a6c <__bss_start>,%sp@-
80000756:	4e92           	jsr %a2@
        
        if( retval > 0 )
80000758:	4fef 001c      	lea %sp@(28),%sp
8000075c:	4a83           	tstl %d3
8000075e:	6f48           	bles 800007a8 <threadfunc+0x108>
        {
            if FD_ISSET(select_fd,&rdfs)
80000760:	7008           	moveq #8,%d0
80000762:	c0ae ff40      	andl %fp@(-192),%d0
80000766:	6716           	beqs 8000077e <threadfunc+0xde>
            {
                /* do something */
                read(select_fd, line, 64);
80000768:	4878 0040      	pea 40 <_init-0x80000410>
8000076c:	2f02           	movel %d2,%sp@-
8000076e:	4878 0043      	pea 43 <_init-0x8000040d>
80000772:	4e94           	jsr %a4@
80000774:	4fef 000c      	lea %sp@(12),%sp
    int select_fd = 67;
    
    if( dup2( STDIN_FILENO, select_fd ) == -1 )
    {
        perror( "dup2()" );
        return NULL;
80000778:	2044           	moveal %d4,%a0
8000077a:	6000 ff7a      	braw 800006f6 <threadfunc+0x56>
                /* do something */
                read(select_fd, line, 64);
            }
            else
            {
                fprintf( stderr, "unhandled fd\n" );
8000077e:	2f39 8000 2a70 	movel 80002a70 <stderr@@GLIBC_2.4>,%sp@-
80000784:	4878 000d      	pea d <_init-0x80000443>
80000788:	a367           	mov3ql #1,%sp@-
8000078a:	4879 8000 091b 	pea 8000091b <_IO_stdin_used+0x95>
80000790:	4eb9 8000 0540 	jsr 80000540 <fwrite@plt>
80000796:	4fef 0010      	lea %sp@(16),%sp
            run = 0;
        }
    }

    return NULL;
}
8000079a:	4cee 1c3c ff1c 	moveml %fp@(-228),%d2-%d5/%a2-%a4
800007a0:	4e5e           	unlk %fp
800007a2:	4280           	clrl %d0
800007a4:	91c8           	subal %a0,%a0
800007a6:	4e75           	rts
            {
                fprintf( stderr, "unhandled fd\n" );
                run = 0;
            }
        }
        else if( retval < 0 )
800007a8:	4a83           	tstl %d3
800007aa:	6700 ff48      	beqw 800006f4 <threadfunc+0x54>
        {
            perror( "select()" );
800007ae:	4879 8000 0929 	pea 80000929 <_IO_stdin_used+0xa3>
800007b4:	4eb9 8000 04e0 	jsr 800004e0 <perror@plt>
800007ba:	588f           	addql #4,%sp
            run = 0;
        }
    }

    return NULL;
}
800007bc:	4cee 1c3c ff1c 	moveml %fp@(-228),%d2-%d5/%a2-%a4
800007c2:	4e5e           	unlk %fp
800007c4:	4280           	clrl %d0
800007c6:	91c8           	subal %a0,%a0
800007c8:	4e75           	rts
    int run = 1;
    int select_fd = 67;
    
    if( dup2( STDIN_FILENO, select_fd ) == -1 )
    {
        perror( "dup2()" );
800007ca:	4879 8000 089b 	pea 8000089b <_IO_stdin_used+0x15>
800007d0:	4eb9 8000 04e0 	jsr 800004e0 <perror@plt>
        return NULL;
800007d6:	588f           	addql #4,%sp
            run = 0;
        }
    }

    return NULL;
}
800007d8:	4cee 1c3c ff1c 	moveml %fp@(-228),%d2-%d5/%a2-%a4
800007de:	4e5e           	unlk %fp
800007e0:	4280           	clrl %d0
800007e2:	91c8           	subal %a0,%a0
800007e4:	4e75           	rts
800007e6:	4e75           	rts

800007e8 <__libc_csu_fini>:
800007e8:	4e56 0000      	linkw %fp,#0
800007ec:	4e5e           	unlk %fp
800007ee:	4e75           	rts

800007f0 <__libc_csu_init>:
800007f0:	4e56 ffe4      	linkw %fp,#-28
800007f4:	48d7 247c      	moveml %d2-%d6/%a2/%a5,%sp@
800007f8:	2a7c 0000 2262 	moveal #8802,%a5
800007fe:	4bfb d8fa      	lea %pc@(800007fa <__libc_csu_init+0xa>,%a5:l),%a5
80000802:	282e 0008      	movel %fp@(8),%d4
80000806:	2a2e 000c      	movel %fp@(12),%d5
8000080a:	2c2e 0010      	movel %fp@(16),%d6
8000080e:	61ff ffff fc40 	bsrl 80000450 <_init>
80000814:	246d 0004      	moveal %a5@(4),%a2
80000818:	262d fff8      	movel %a5@(-8),%d3
8000081c:	968a           	subl %a2,%d3
8000081e:	e483           	asrl #2,%d3
80000820:	6716           	beqs 80000838 <__libc_csu_init+0x48>
80000822:	4282           	clrl %d2
80000824:	2f06           	movel %d6,%sp@-
80000826:	2f05           	movel %d5,%sp@-
80000828:	2f04           	movel %d4,%sp@-
8000082a:	205a           	moveal %a2@+,%a0
8000082c:	5282           	addql #1,%d2
8000082e:	4e90           	jsr %a0@
80000830:	4fef 000c      	lea %sp@(12),%sp
80000834:	b682           	cmpl %d2,%d3
80000836:	62ec           	bhis 80000824 <__libc_csu_init+0x34>
80000838:	4cee 247c ffe4 	moveml %fp@(-28),%d2-%d6/%a2/%a5
8000083e:	4e5e           	unlk %fp
80000840:	4e75           	rts
80000842:	4e75           	rts

80000844 <__do_global_ctors_aux>:
80000844:	4e56 0000      	linkw %fp,#0
80000848:	a140           	mov3ql #-1,%d0
8000084a:	2079 8000 2938 	moveal 80002938 <__CTOR_LIST__>,%a0
80000850:	2f0a           	movel %a2,%sp@-
80000852:	b088           	cmpl %a0,%d0
80000854:	6710           	beqs 80000866 <__do_global_ctors_aux+0x22>
80000856:	45f9 8000 2938 	lea 80002938 <__CTOR_LIST__>,%a2
8000085c:	4e90           	jsr %a0@
8000085e:	2062           	moveal %a2@-,%a0
80000860:	a140           	mov3ql #-1,%d0
80000862:	b088           	cmpl %a0,%d0
80000864:	66f6           	bnes 8000085c <__do_global_ctors_aux+0x18>
80000866:	246e fffc      	moveal %fp@(-4),%a2
8000086a:	4e5e           	unlk %fp
8000086c:	4e75           	rts

8000086e <call___do_global_ctors_aux>:
8000086e:	4e56 0000      	linkw %fp,#0
80000872:	4e5e           	unlk %fp
80000874:	4e75           	rts
80000876:	4e75           	rts

Disassembly of section .fini:

80000878 <_fini>:
80000878:	4e56 0000      	linkw %fp,#0
8000087c:	4eb9 8000 05c8 	jsr 800005c8 <__do_global_dtors_aux>
80000882:	4e5e           	unlk %fp
80000884:	4e75           	rts
