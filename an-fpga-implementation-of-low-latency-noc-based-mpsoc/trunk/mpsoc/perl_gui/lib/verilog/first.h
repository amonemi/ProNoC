#ifndef FIRST_SYSTEM_H
	#define FIRST_SYSTEM_H
 
 #include <stdio.h> 
 #include <stdlib.h> 
 #include "aemb/core.hh" 
 
 /*  ram   */ 
 #define RAM_BASE_ADDR0 		 	0X00000000
 #define RAM_BASE_ADDR 		 	RAM_BASE_ADDR0
 
 
 /*  aeMB   */ 
 
 
 /*  src   */ 
 
 
 /*  gpo   */ 
 #define GPO_BASE_ADDR0 		 	0X91000000
 #define GPO_BASE_ADDR 		 	GPO_BASE_ADDR0
 
	#define	 GPO_WRITE_REG	   		(*((volatile unsigned int *) (GPO_BASE_ADDR+4)))
	#define 	GPO_WRITE(value)		       GPO_WRITE_REG=value	


 
 
 /*  int_ctrl   */ 
 #define INT_CTRL_BASE_ADDR0 		 	0X9e000000
 #define INT_CTRL_BASE_ADDR 		 	INT_CTRL_BASE_ADDR0
 
	#define	 INT_CTRL_MER		       (*((volatile unsigned int *) (INT_CTRL_BASE_ADDR	)))
	#define	INT_CTRL_IER			(*((volatile unsigned int *) (INT_CTRL_BASE_ADDR+4	)))
	#define 	INT_CTRL_IAR			(*((volatile unsigned int *) (INT_CTRL_BASE_ADDR+8	)))
	#define 	INT_CTRL_IPR			(*((volatile unsigned int *) (INT_CTRL_BASE_ADDR+12	)))
 
 
 /*  ni0   */ 
 //intrrupt flag location
  #define NI0_INT (1<<0)
 #define NI0_BASE_ADDR0 		 	0Xb8000000
 #define NI0_BASE_ADDR 		 	NI0_BASE_ADDR0
 	 #define NI0_CLASS_IN_HDR_WIDTH      8
         #define NI0_DEST_IN_HDR_WIDTH       8
         #define NI0_X_Y_IN_HDR_WIDTH        4
        
	#define	NI0_BUSY			(1<<0)
	#define	NI0_WR_DONE			(1<<1)
	#define	NI0_RD_DONE			(1<<2)
	#define 	NI0_RD_OVR_ERR			(1<<3)
	#define	NI0_RD_NPCK_ERR			(1<<4)
	#define	NI0_HAS_PCK			(1<<5)
	#define	NI0_ALL_VCS_FULL		(1<<6)
	#define	NI0_WR_DONE_INT_EN		(1<<7)
	#define	NI0_RD_DONE_INT_EN		(1<<8)
	#define	NI0_RSV_PCK_INT_EN		(1<<9)
	#define	NI0_WR_DONE_ISR			(1<<10)
	#define	NI0_RD_DONE_ISR			(1<<11)
	#define	NI0_RSV_PCK_ISR			(1<<12)
	
		
	
	#define NI0_PTR_WIDTH			19
	#define	NI0_PCK_SIZE_WIDTH		13


	#define NI0_RD			   	(*((volatile unsigned int *) (NI0_BASE_ADDR	)))
	#define NI0_WR			   	(*((volatile unsigned int *) (NI0_BASE_ADDR+4)))
	#define NI0_ST	   			(*((volatile unsigned int *) (NI0_BASE_ADDR+8)))

	#define NI0_HDR_DEST_CORE_ADDR(DES_X, DES_Y)	((DES_X << NI0_X_Y_IN_HDR_WIDTH) | DES_Y)<<(2*NI0_X_Y_IN_HDR_WIDTH)	
	#define NI0_HDR_CLASS(pck_class)			(pck_class << ( NI0_DEST_IN_HDR_WIDTH+  (4* NI0_X_Y_IN_HDR_WIDTH)))

	
	#define NI0_wait_for_sending_pck()		while (!(NI0_ST & NI0_WR_DONE))
	#define NI0_wait_for_reading_pck()		while (!(NI0_ST & NI0_RD_DONE))

	#define NI0_wait_for_getting_pck()		while (!(NI0_ST & NI0_HAS_PCK))

/*****************************************
void  send_pck (unsigned int * pck_buffer, unsigned int data_size);
sending a packet through NoC network;
(unsigned int des_x,unsigned int des_y : destination core address;
unsigned int * pck_buffer : the buffer which hold the packet; The data must start from buff[1];
unsigned int data_size     : the size of data which wanted to be sent out in word = packet_size-1;
unsigned int class  

****************************************/
	inline void  NI0_send_pck (unsigned int des_x, unsigned int des_y, volatile unsigned int * pck_buffer, unsigned int data_size, unsigned int pck_class){
		pck_buffer [0]		= 	NI0_HDR_DEST_CORE_ADDR(des_x, des_y) | NI0_HDR_CLASS(pck_class) ;
		NI0_WR = (unsigned int) (& pck_buffer [0]) + (data_size<<NI0_PTR_WIDTH);
		NI0_wait_for_sending_pck();

	}

/*******************************************
void  save_pck	(volatile unsigned int * pck_buffer, unsigned int buffer_size);
save a received packet on pck_buffer
unsigned int * pck_buffer: the buffer for storing the packet; The read data start from buff[1]; 
********************************************/
	inline void  NI0_save_pck	(volatile unsigned int * pck_buffer, unsigned int buffer_size){
		NI0_RD = (unsigned int) (& pck_buffer [0]) + (buffer_size<<NI0_PTR_WIDTH);
		NI0_wait_for_reading_pck();
	}
 
 
 /*  timer   */ 
 //intrrupt flag location
  #define TIMER_INT (1<<1)
 #define TIMER_BASE_ADDR0 		 	0X96000000
 #define TIMER_BASE_ADDR 		 	TIMER_BASE_ADDR0
 #define TIMER_TCSR0	   			(*((volatile unsigned int *) (TIMER_BASE_ADDR	)))
		
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
	#define TIMER_TLR0	   			(*((volatile unsigned int *) (TIMER_BASE_ADDR+4	)))
	#define TIMER_TCMP0	   			(*((volatile unsigned int *) (TIMER_BASE_ADDR+8	)))
#ifndef	TIMER_EN
	#define TIMER_EN			(1 << 0)
	#define TIMER_INT_EN			(1 << 1)
	#define TIMER_RST_ON_CMP		(1 << 2)
#endif
 
 
 /*  wishbone_bus   */ 
 #endif
