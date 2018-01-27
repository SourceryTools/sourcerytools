// thread main function
void *threadfunc(void *arg)
{
    struct ldi_stream *stream = (struct ldi_stream*) arg;
    struct pollfd evt;

    evt.fd = stream->sound_dev;
    evt.events = POLLIN;
    evt.revents = 0;

    // register this thread with PJ
    pj_status_t status = pj_thread_register(
        "ldi thread", 
        stream->thread_desc, 
        &stream->pj_thread);

    pj_assert(status == PJ_SUCCESS);

    // real loop on LDI
    int select_fd;
    select_fd = stream->sound_dev;
    int nfds = select_fd + 1;

    stream->run = 1;

// fake loop for PC version
// simulate the 20ms clock
#ifdef __i386
    while( stream->run )
    {
        usleep( 20 * 1000 );
        onFDReadable(stream, stream->sound_dev);

    }
    return NULL;
#endif

    TRACE_("entering mainloop");
    struct timeval timeout;
    fd_set rdfds;
    int retval = 0;
    
    while(stream->run)
    {
//         evt.fd = stream->sound_dev;
//         evt.events = POLLIN;
//         evt.revents = 0;
            timeout.tv_sec = 5;
            timeout.tv_usec = 0;
            
        FD_ZERO(&rdfds);
        FD_SET(select_fd, &rdfds);
        
        // wait on /dev/ldisnd
        TRACE_("before select_fd=%d | nfds = %d", select_fd, nfds );
        retval = select( nfds, &rdfds, NULL, NULL, &timeout);
//         TRACE_("after select_fd=%d | nfds = %d", select_fd, nfds );
//                 retval = poll( &evt, 1, 5000 );
        if (retval > 0)
        {
            if FD_ISSET(select_fd, &rdfds)
            {
               // handle data
            //
            //  SET_MODUL_IO3_v3;
                onFDReadable(stream, select_fd);
            //   CLR_MODUL_IO3_v3;
            }
            else
            {
                TRACE_("unhandled FD\n");
                stream->run = 0;
            }
        }
        else if (retval < 0)
        {
            PERROR("select()");
            stream->run = 0;
        }
    }

    TRACE_("exiting mainloop");
    return NULL;
}

