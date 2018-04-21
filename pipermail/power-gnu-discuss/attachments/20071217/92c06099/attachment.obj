
MEMORY {

/* 64B of dram starting at 0x00000000 */

    dram_rsvd1   : ORIGIN = 0x40000000, LENGTH = 0
    dram_memory  : ORIGIN = 0x40000000, LENGTH = 32K
	stack_ram 	 : ORIGIN = 0x40008000, LENGTH = 0x1000 /*Danilo*/

/* 16MB of flash starting at 0xfe000000*/
	flash_rcw 	 : ORIGIN = 0x00000000, LENGTH = 0x8 /*Danilo*/
    flash_rsvd1  : ORIGIN = 0x00000008, LENGTH = 10
    flash_memory : ORIGIN = 0x00000018, LENGTH = 32k
    flash_rsvd2  : ORIGIN = 0x00000018, LENGTH = 0

/* alternate reset vector at 0xfff00100*/

    alt_reset    : ORIGIN = 0xfff00100, LENGTH = 256
}


/*CONSTANTS {

    heap_reserve = 4k
    stack_reserve = 4K

}*/

/*
// Program layout for starting in ROM, copying data to RAM,
// and continuing to execute out of ROM.
//

//
//   If you wish to install a reset vector handler on your system,
//   uncomment the following OPTION() directive and the reference
//   to the .reset section.
//   You may not want to do this if you are relying on preinstalled
//   firmware to initialize your system.
//
//   OPTION("-u __ghs_reset_handler")
*/

SECTIONS
{
     /*.reset                                         ABS : > dram_reset	*/

/*------------------------------------------------------------------------------
// RAM SECTIONS
//----------------------------------------------------------------------------*/
    /* Following sections used by GHS to allocate ZDA when optimization is enabled */
	
	/*.PPC.EMB.sdata0 	          		     :{ *(.PPC.EMB.sdata0) } > dram_memory
    .PPC.EMB.sbss0                           :{ *(.PPC.EMB.sdata0) } > dram_memory*/
	
    .data 						: { *(.data) } > dram_memory
    .bss 						: { *(.bss) } > dram_memory

    .sdata 						: { *(.sdata) } > dram_memory
    .sbss 						: { *(.sbss) } > dram_memory
    .sdata2						: { *(.sdata2) } > dram_memory

    /*.heap                  ALIGN(16) PAD(heap_reserve)  : > dram_memory
    .stack                 ALIGN(16) PAD(stack_reserve) : > dram_memory*/

/*------------------------------------------------------------------------------
// ROM SECTIONS
//----------------------------------------------------------------------------*/
	.rcw  						: {*(.rcw)} > flash_rcw
    .text						: { *(.text) } > flash_memory
    /* not available in gcc */
	.vletext					: { *(.vletext) } > flash_memory
    .syscall					: { *(.syscall) } > flash_memory

    .rodata		 				: { *(.rodata) } > flash_memory
	.rodata.str1.4				: {*(.rodata.str1.4)} > flash_memory
    .sdata2 					: { *(.sdata2) } > flash_memory

    .secinfo 					: { *(.secinfo) } > flash_memory
    .fixaddr 					: { *(.fixaddr) } > flash_memory
    .fixtype 					: { *(.fixtype) } > flash_memory

    /*.CROM.PPC.EMB.sdata0 	 	: { *(.CROM.PPC.EMB.sdata0) } > flash_memory*/
    .sdata  	          		: { *(.sdata) } > flash_memory
    .data 	            		: { *(.data) } > flash_memory
	
	
	
	
	
/*------------------------------------------------------------------------------
// These special symbols mark the bounds of RAM and ROM memory.
// They are used by the MULTI debugger.
//----------------------------------------------------------------------------*/
/*    __ghs_ramstart  = MEMADDR(dram_rsvd1);
    __ghs_ramend    = MEMENDADDR(dram_memory);
    __ghs_romstart  = MEMADDR(flash_rsvd1);
    __ghs_romend    = MEMENDADDR(flash_rsvd2);
*/
/*------------------------------------------------------------------------------
// These special symbols mark the bounds of RAM and ROM images of boot code.
// They are used by the GHS startup code (_start and __ghs_ind_crt0).
//----------------------------------------------------------------------------*/
/*    __ghs_rambootcodestart  = 0;
    __ghs_rambootcodeend    = 0;
    __ghs_rombootcodestart  = ADDR(.text);
    __ghs_rombootcodeend    = ENDADDR(.fixtype);*/
	
	
/* Stack area */
    .stack  : {*(.stack)} > stack_ram

/* Stack Address Parameters */
__SP_INIT      = 0x40008000 + 0x1000;
__SP_END       = 0x40008000;

__SRAM_CPY_START = ADDR(.data);
__ROM_COPY_SIZE  = ((SIZEOF(.data) + SIZEOF(.sdata)));
__DATA_ROM	= ADDR(.data);

_SDA_BASE_ = ADDR(.sdata) + 0x8000;   /*(+0x7FF0 for WindRiver)*/    
_SDA2_BASE_ = ADDR(.sdata2) + 0x8000; /*(+0x7FF0 for WindRiver)*/ 

}

