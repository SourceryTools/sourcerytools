#ifndef _AUTOPILOT_INIT_H_
#define _AUTOPILOT_INIT_H_

void autopilot_init (void) {
 
 volatile int *sram_read_cycle_time  = (int(*)) 0x81000000;
 volatile int *sram_write_cycle_time = (int(*)) 0x82000000;
  
 volatile int *sram_burst_size_cnfgreg = (int(*)) 0x80000000;
 volatile int *sram_burst_wrcyc_tim    = (int(*)) 0x82000000;
 volatile int *sram_burst_init_latency = (int(*)) 0x83000000;
 volatile int *sram_mod_cnfgreg 	   = (int(*)) 0x88000000;
  
 volatile int *async_confg = (int(*)) 0x89000010; // Configuration Address for Async Configuration
 volatile int *page_confg  = (int(*)) 0x89000090; // Configuration Address for Page  Mode Configuration
 volatile int *burst_confg = (int(*)) 0x89081C14; // Configuration Address for Burst Mode Configuration

 mux_sel_register = 0x00000180;
 
 BAUD1			= Baud115200;
 BAUD2			= Baud9600;
 I2C_BPS		= onehun_Kbps;
 SPI_BPS		= onehun_Kbps;
 PWM_CLKFREQ	= PWM_Clock;
 PWM1_DUTYCYC	= PWM_TC_300hz;
 PWM2_DUTYCYC	= PWM_TC_300hz;
 UART1_CONFIG	= 0x00001E00; //Setiing the read threshold register to thirty bytes.
 UART2_CONFIG	= 0x00001E00; //Setting the read threshold register to thirty bytes.
 CLKGEN_EVECFG	= (Source_Clk/(9600*16)) * 10 * 16; //0x0000BEB4; //BAUD2 * 10 * 15;// Initializing the GenCLK module even clock to be its UART baud X 5
  
 
 // INITIALIZING CLOCK GENERATORS
 
 EvenCLK_divisor_Reg	= CLKGEN_EVECFG; 
 
 SeqLeth 		        = 1152 - 1; // C Sequence Length                                                                             576 -1;//
 NumXdiv_P 	            = 503 - 1;  // B # of times to divide by P                                                                   185 -1;//
 IntDivr 		        = 14 - 1;   // N ( Integer divisor, found by rounding M up ) should always be P+1                             60 -1;// 
 RelDivrM_Flor          = 13 - 1;   // P ( The greatest integer that is less than the real divisor M )should always be N-1strtclk_mod 59 -1;// 		= 1; // Starting the GenCLK module. 
 
 pwm_clk_gen	  		= PWM_CLKFREQ;   
 pwm1_dutycycle 		= PWM1_DUTYCYC;
 pwm2_dutycycle 		= PWM2_DUTYCYC;
 	 
 i2c_clk_gen			= 25; //I2C_BPS;   // Initializing the I2C clock generator to 100Kbps
 spi_clk_gen			= 25; //SPI_BPS;  // Initializing the SPI clock generator to 100Kbps
 baud_gen1				= BAUD1;   // Initializing the UART1 clock generator to 100Kbps
 baud_gen2				= BAUD2;  // Initializing the UART2 clock generator to 100Kbps
 	
    			   		
 seven_segment_display  = 0;
 
 
  // Initializing UARTs
 
 rs232_config_reg1 = UART1_CONFIG; //byte write and non-inverted output with 1 stop bit
 rs232_config_reg2 = UART2_CONFIG; //byte write and non-inverted

 //************************** Initializing Sensors ****************************
 
 init_gps();
 init_accel();
 init_gyro(); 
 
 //****************************************************************************
 
 
 // Setting up the SRAM controller
 
 *sram_read_cycle_time  = 1;
 *sram_write_cycle_time = 1;
 
 sram_wr_data_fifo = 7;  // WRITTING THE DATA ASSOCIATED WITH THE WRITES ABOVE TO THE DATA FIFO
 sram_wr_data_fifo = 7;  // WRITTING THE DATA ASSOCIATED WITH THE WRITES ABOVE TO THE DATA FIFO
 
 *burst_confg = 1;
 sram_wr_data_fifo = 0; // DUMMY WRITE
                                  
 *sram_burst_size_cnfgreg = 1; // ISSUING A WRITE TRANSACTION TO THE "" REGISTER
 *sram_burst_wrcyc_tim 	  = 1; // ISSUING A WRITE TRANSACTION TO THE "" REGISTER
 *sram_burst_init_latency = 1; // ISSUING A WRITE TRANSACTION TO THE "" REGISTER
 *sram_mod_cnfgreg 		  = 1; // ISSUING A WRITE TRANSACTION TO THE "" REGISTER
 
 sram_wr_data_fifo = 32; // WRITTING THE DATA ASSOCIATED WITH THE WRITES ABOVE TO THE DATA FIFO
 sram_wr_data_fifo = 7;  // WRITTING THE DATA ASSOCIATED WITH THE WRITES ABOVE TO THE DATA FIFO
 sram_wr_data_fifo = 5;  // WRITTING THE DATA ASSOCIATED WITH THE WRITES ABOVE TO THE DATA FIFO
 sram_wr_data_fifo = 2;  // WRITTING THE DATA ASSOCIATED WITH THE WRITES ABOVE TO THE DATA FIFO

 
 // Initializing the Pulse Width Modulators 
 calculated1_dutycycle = encoder1_dutycycle;  
 calculated2_dutycycle = encoder2_dutycycle;
 
 // Initializing the MACAW MAC
 
 mac_ssid				 = 0x121B;//
 brcst_id				 = 0xFF;  //
 mac_rm_ssid			 = 0x1C;  //
 mac_tx_trmtime			 = 0x2F;  //
 mac_txbyte_cnt			 = 0x08;  // 
 mac_my_backoff_time     = 48;    // The size of the largest packet DS/DATA
 mac_local_backoff_time  = 48;    //
 mac_remote_backoff_time = 48;    //
 mac_exch_seq_cntr       = 0x00;  //
 mac_retry_cntr          = 0x00;  //
 mac_cfg_retry			 = 0;
 
 mac_cts_timeout 		 = 0xFFF; //	
 mac_ds_timeout          = 24; 	  //
 mac_data_timeout        = 0xFFF; //
 mac_ack_timeout         = 0xFFF; //
   	
 
 led_register = 0;
 mux_sel_register = 0x00000000;
	

}
#endif