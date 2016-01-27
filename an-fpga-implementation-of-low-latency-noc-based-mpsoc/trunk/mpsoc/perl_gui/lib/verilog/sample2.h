#ifndef SAMPLE2_SYSTEM_H
	#define SAMPLE2_SYSTEM_H
 
 #include <stdio.h> 
 #include <stdlib.h> 
 #include "aemb/core.hh" 
 
 /*  Altera_ram0   */ 
 #define ALTERA_RAM0_BASE_ADDR0 		 	0X00000000
 #define ALTERA_RAM0_BASE_ADDR 		 	ALTERA_RAM0_BASE_ADDR0
 
 
 /*  aeMB0   */ 
 
 
 /*  clk_source0   */ 
 
 
 /*  gpi0   */ 
 #define GPI0_BASE_ADDR0 		 	0X91000000
 #define GPI0_BASE_ADDR 		 	GPI0_BASE_ADDR0
    


#define GPI0_READ_REG   (*((volatile unsigned int *) (GPI0_BASE_ADDR+8)))
   
 
#define GPI0_READ()  	 GPI0_READ_REG	
 
 
 /*  gpo0   */ 
 #define GPO0_BASE_ADDR0 		 	0X91000020
 #define GPO0_BASE_ADDR 		 	GPO0_BASE_ADDR0
 
	#define	 GPO0_WRITE_REG	   		(*((volatile unsigned int *) (GPO0_BASE_ADDR+4)))
	#define 	GPO0_WRITE(value)		       GPO0_WRITE_REG=value	


 
 
 /*  jtag_intfc0   */ 
 #define JTAG_INTFC0_BASE_ADDR0 		 	0X90000000
 #define JTAG_INTFC0_BASE_ADDR 		 	JTAG_INTFC0_BASE_ADDR0
 
 
 /*  ni0   */ 
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
 
 
 /*  bus   */ 
 #endif
