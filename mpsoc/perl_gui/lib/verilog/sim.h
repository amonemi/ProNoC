#ifndef SIM_SYSTEM_H
	#define SIM_SYSTEM_H
 
 #include <stdio.h> 
 #include <stdlib.h> 
 #include "aemb/core.hh" 
 
 /*  Altera_single_port_ram0   */ 
 #define ALTERA_SINGLE_PORT_RAM0_BASE_ADDR0 		 	0X00000000
 #define ALTERA_SINGLE_PORT_RAM0_BASE_ADDR 		 	ALTERA_SINGLE_PORT_RAM0_BASE_ADDR0
 
 
 /*  aeMB0   */ 
 
 
 /*  clk_source0   */ 
 
 
 /*  timer0   */ 
 #define TIMER0_BASE_ADDR0 		 	0X96000000
 #define TIMER0_BASE_ADDR 		 	TIMER0_BASE_ADDR0
 #define TIMER0_TCSR0	   			(*((volatile unsigned int *) (TIMER0_BASE_ADDR	)))
		
/*
//timer control register
TCSR0
bit
6-3	:	clk_dev_ctrl
3	:	timer_isr
2	:	rst_on_cmp_value
1	:	int_enble_on_cmp_value
0	:	timer enable 
*/	
	#define TIMER0_TLR0	   			(*((volatile unsigned int *) (TIMER0_BASE_ADDR+4	)))
	#define TIMER0_TCMP0	   			(*((volatile unsigned int *) (TIMER0_BASE_ADDR+8	)))
#ifndef	TIMER_EN
	#define TIMER_EN			(1 << 0)
	#define TIMER_INT_EN			(1 << 1)
	#define TIMER_RST_ON_CMP		(1 << 2)
#endif
 
 
 /*  wishbone_bus0   */ 
 #endif
