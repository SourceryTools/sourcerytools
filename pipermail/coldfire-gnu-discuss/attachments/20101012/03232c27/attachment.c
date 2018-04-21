#include <stdio.h>
#include <stdlib.h>
#include <sys/select.h>
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>
#include <pthread.h>

void* threadfunc( void *arg )
{

    char line[64]={0};
    int run = 1;
    int select_fd = 67;
    
    if( dup2( STDIN_FILENO, select_fd ) == -1 )
    {
        perror( "dup2()" );
        return NULL;
    }
    
    //close( STDIN_FILENO );
/*    int test1 = 33;
    int test3 = 127;*/
    int nfds = select_fd + 1;
/*    int test2 = 33;    
    test1 = random();
        test2 = random();
        fprintf( stderr, "%d - %d\n", test1, test2 );
        test3=test2;*/
    
    struct timeval to;
    fd_set rdfs;
    int retval = 0;
    
    while( run )
    {
        to.tv_sec = 5;
        to.tv_usec = 0;
        
        FD_ZERO(&rdfs);
        FD_SET(select_fd,&rdfs);        
        
        fprintf( stdout, "before select_fd=%d | nfds=%d | sec = %d | usec = %d\n", select_fd, nfds, to.tv_sec, to.tv_usec );
        retval = select( nfds, &rdfs, NULL, NULL, &to );
        fprintf( stdout, "after select_fd=%d | nfds=%d | sec = %d | usec = %d | retval = %d\n", select_fd, nfds, to.tv_sec, to.tv_usec, retval );
        
        if( retval > 0 )
        {
            if FD_ISSET(select_fd,&rdfs)
            {
                /* do something */
                read(select_fd, line, 64);
            }
            else
            {
                fprintf( stderr, "unhandled fd\n" );
                run = 0;
            }
        }
        else if( retval < 0 )
        {
            perror( "select()" );
            run = 0;
        }
    }

    return NULL;
}

int main( int argc, char** argv )
{
    pthread_t tid = 0;
    
    if( pthread_create( &tid, NULL, threadfunc, NULL ) != 0 )
    {
        perror( "pthread_create()" );
    }
    else
    {
        sleep(60);
    }
    
    return 0;
}
