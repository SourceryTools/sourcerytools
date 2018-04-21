#include "stdio.h"
#include "stdlib.h"
#include "math.h"
#include "global.h"
#include "../Quik_Silva_Lib/i2c_handler.h"
#include "init_accel.h"
#include "init_gps.h"
#include "init_gyro.h"
#include "autopilot_init.h"
#include "CalAxisOrie.h"
#include "retrSnrData.h"


            
//#include "wrbytes2port.h"
//#include "hex2str.h"
//#include "str2hex.h"
//#include "strcomp.h"
//#include "retrcmd.h"
//#include "setbitrate.h"
//#include "crestr.h"
//#include "retrstrptr.h"
//#include "retrnbitrate.h"
//#include "setbitrate.h"
//#include "setfunc.h"
//#include "getfunc.h"
//#include "spp_cmdprc.h"
//#include "uPC_cmdprc.h"

using namespace std;


main() {
	
char *wrdnqueue_rdptr, *wrdnqueue_wrptr, *wrdnqueue_ptr, wrdsnqueue[100];
	
	//wrdnqueue_ptr 	= &wrdsnqueue[0];	
	wrdnqueue_rdptr = &wrdsnqueue[0];//&wrdnqueue_ptr;
	wrdnqueue_wrptr = &wrdsnqueue[0];//&wrdnqueue_ptr;

	autopilot_init();
	
	while(1) {	
		
		retrSnrData(wrdnqueue_rdptr,wrdnqueue_wrptr);
		
		if ( wrdnqueue_rdptr > wrdnqueue_wrptr ) { //Check to see if all of the reads have been served
		
			//wrdnqueue_ptr 	= &wrdsnqueue[0];	
			wrdnqueue_rdptr = &wrdsnqueue[0];//&wrdnqueue_ptr;
			wrdnqueue_wrptr = &wrdsnqueue[0];//&wrdnqueue_ptr;
		}				
	}	
}