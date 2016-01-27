#ifndef SECOND_SYSTEM_H
	#define SECOND_SYSTEM_H
 
 #include <stdio.h> 
 #include <stdlib.h> 
 #include "aemb/core.hh" 
 
 /*  ram   */ 
 #define RAM_BASE_ADDR0 		 	0X00000000
 #define RAM_BASE_ADDR 		 	RAM_BASE_ADDR0
 
 
 /*  aeMB0   */ 
 
 
 /*  ss   */ 
 
 
 /*  port   */ 
 #define PORT_BASE_ADDR0 		 	0X91000000
 #define PORT_BASE_ADDR 		 	PORT_BASE_ADDR0
    
#define PORT_DIR_REG   (*((volatile unsigned int *) (PORT_BASE_ADDR)))   
#define PORT_WRITE _REG  (*((volatile unsigned int *) (PORT_BASE_ADDR+4)))
#define PORT_READ_REG   (*((volatile unsigned int *) (PORT_BASE_ADDR+8)))
   
 #define PORT_DIR_SET(value)   PORT_DIR_REG=value	  
#define PORT_WRITE(value)  PORT_WRITE _REG=value	
#define PORT_READ()  	 PORT_READ_REG	
 
 
 /*  ni   */ 
 #define NI_BASE_ADDR0 		 	0Xb8000000
 #define NI_BASE_ADDR 		 	NI_BASE_ADDR0
 	 #define NI_CLASS_IN_HDR_WIDTH      8
         #define NI_DEST_IN_HDR_WIDTH       8
         #define NI_X_Y_IN_HDR_WIDTH        4
        
	#define	NI_BUSY			(1<<0)
	#define	NI_WR_DONE			(1<<1)
	#define	NI_RD_DONE			(1<<2)
	#define 	NI_RD_OVR_ERR			(1<<3)
	#define	NI_RD_NPCK_ERR			(1<<4)
	#define	NI_HAS_PCK			(1<<5)
	#define	NI_ALL_VCS_FULL		(1<<6)
	#define	NI_WR_DONE_INT_EN		(1<<7)
	#define	NI_RD_DONE_INT_EN		(1<<8)
	#define	NI_RSV_PCK_INT_EN		(1<<9)
	#define	NI_WR_DONE_ISR			(1<<10)
	#define	NI_RD_DONE_ISR			(1<<11)
	#define	NI_RSV_PCK_ISR			(1<<12)
	
		
	
	#define NI_PTR_WIDTH			19
	#define	NI_PCK_SIZE_WIDTH		13


	#define NI_RD			   	(*((volatile unsigned int *) (NI_BASE_ADDR	)))
	#define NI_WR			   	(*((volatile unsigned int *) (NI_BASE_ADDR+4)))
	#define NI_ST	   			(*((volatile unsigned int *) (NI_BASE_ADDR+8)))

	#define NI_HDR_DEST_CORE_ADDR(DES_X, DES_Y)	((DES_X << NI_X_Y_IN_HDR_WIDTH) | DES_Y)<<(2*NI_X_Y_IN_HDR_WIDTH)	
	#define NI_HDR_CLASS(pck_class)			(pck_class << ( NI_DEST_IN_HDR_WIDTH+  (4* NI_X_Y_IN_HDR_WIDTH)))

	
	#define NI_wait_for_sending_pck()		while (!(NI_ST & NI_WR_DONE))
	#define NI_wait_for_reading_pck()		while (!(NI_ST & NI_RD_DONE))

	#define NI_wait_for_getting_pck()		while (!(NI_ST & NI_HAS_PCK))

/*****************************************
void  send_pck (unsigned int * pck_buffer, unsigned int data_size);
sending a packet through NoC network;
(unsigned int des_x,unsigned int des_y : destination core address;
unsigned int * pck_buffer : the buffer which hold the packet; The data must start from buff[1];
unsigned int data_size     : the size of data which wanted to be sent out in word = packet_size-1;
unsigned int class  

****************************************/
	inline void  NI_send_pck (unsigned int des_x, unsigned int des_y, volatile unsigned int * pck_buffer, unsigned int data_size, unsigned int pck_class){
		pck_buffer [0]		= 	NI_HDR_DEST_CORE_ADDR(des_x, des_y) | NI_HDR_CLASS(pck_class) ;
		NI_WR = (unsigned int) (& pck_buffer [0]) + (data_size<<NI_PTR_WIDTH);
		NI_wait_for_sending_pck();

	}

/*******************************************
void  save_pck	(volatile unsigned int * pck_buffer, unsigned int buffer_size);
save a received packet on pck_buffer
unsigned int * pck_buffer: the buffer for storing the packet; The read data start from buff[1]; 
********************************************/
	inline void  NI_save_pck	(volatile unsigned int * pck_buffer, unsigned int buffer_size){
		NI_RD = (unsigned int) (& pck_buffer [0]) + (buffer_size<<NI_PTR_WIDTH);
		NI_wait_for_reading_pck();
	}
 
 
 /*  wishbone_bus0   */ 
 #endif
