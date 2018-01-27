#ifndef _INIT_GPS_H_
#define _INIT_GPS_H_
							
void init_gps( void )
{
	
	char  gps_cnfg_data[47];
	char *cnfg_arr_ptr;
	
	
	//********************NEMA MESSAGE CONFIGURATION ARRAY*************************//
	
	gps_cnfg_data[0] = 0xA0;   
	gps_cnfg_data[1] = 0xA1;
	gps_cnfg_data[2] = 0x00;
	
	gps_cnfg_data[3] = 0x09;
		
	gps_cnfg_data[4] = 0x08;  // Message ID	 
	gps_cnfg_data[5] = 0x01;  // Enable  GGA Messages
	gps_cnfg_data[6] = 0x00;  // Disable GSA Messages
	gps_cnfg_data[7] = 0x00;  // Disable GSV Messages
	gps_cnfg_data[8] = 0x00;  // Disable GLL Messages
	gps_cnfg_data[9] = 0x00;  // Disable RMC Messages
	gps_cnfg_data[10] = 0x00; // Disable VTG Messages
	gps_cnfg_data[11] = 0x00; // Disable ZDA Messages
	gps_cnfg_data[12] = 0x01; // ATTRIBUTES -- Store data to SRAM and FLASH

	gps_cnfg_data[13] = 0x08;
	gps_cnfg_data[14] = 0x0D;
	gps_cnfg_data[15] = 0x0A;
	
	//*****************************************************************************//

	//********************MESSAGE TYPE CONFIGURATION ARRAY*************************//
	
	gps_cnfg_data[16] = 0xA0;   
	gps_cnfg_data[17] = 0xA1;
	gps_cnfg_data[18] = 0x00;
	
	gps_cnfg_data[19] = 0x03;
		
	gps_cnfg_data[20] = 0x09;  // Message ID	 
	gps_cnfg_data[21] = 0x02;  // Enable  Binary Messages
	gps_cnfg_data[22] = 0x01;  // ATTRIBUTES -- Store data to SRAM and FLASH

	gps_cnfg_data[23] = 0x09;
	gps_cnfg_data[24] = 0x0D;
	gps_cnfg_data[25] = 0x0A;
	
	//*****************************************************************************//
	
	
	//********************SYSTEM POSITION RATE CONFIGURATION ARRAY*************************//

	gps_cnfg_data[26] = 0xA0;   
	gps_cnfg_data[27] = 0xA1;
	gps_cnfg_data[28] = 0x00;
	
	gps_cnfg_data[29] = 0x03;
		
	gps_cnfg_data[30] = 0x0E;  // Message ID	 
	gps_cnfg_data[31] = 0x0A;  // Update Rate 10hz
	gps_cnfg_data[32] = 0x01;  // ATTRIBUTES -- Store data to SRAM and FLASH
	
	gps_cnfg_data[33] = 0x0F;  //
	gps_cnfg_data[34] = 0x0D;  //
	gps_cnfg_data[35] = 0x0A;  //
	
	//***********************************************************************************//
	
	
	//********************SERIAL PORT CONFIGURATION ARRAY*************************//

	gps_cnfg_data[36] = 0xA0;   
	gps_cnfg_data[37] = 0xA1;
	gps_cnfg_data[38] = 0x00;
	
	gps_cnfg_data[39] = 0x04;
		
	gps_cnfg_data[40] = 0x05;  // Message ID	 
	gps_cnfg_data[41] = 0x00;  // Update Rate 10hz
	gps_cnfg_data[42] = 0x05;  // Bit Rate 115200kbps
	gps_cnfg_data[43] = 0x01;  // ATTRIBUTES -- Store data to SRAM and FLASH
	
	gps_cnfg_data[44] = 0x05;  //
	gps_cnfg_data[45] = 0x0D;  //
	gps_cnfg_data[46] = 0x0A;  //
	
	//****************************************************************************//
	
	 for ( int i = 0; i <= 46; i++ ) {
		 
		  rs232_uart1 = gps_cnfg_data[i];
	 }		
	
}     
#endif