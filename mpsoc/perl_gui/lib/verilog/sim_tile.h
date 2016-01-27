#ifndef SIM_TILE_SYSTEM_H
	#define SIM_TILE_SYSTEM_H
 
 #include <stdio.h> 
 #include <stdlib.h> 
 #include "aemb/core.hh" 
 
 /*  ram   */ 
 #define RAM_BASE_ADDR0 		 	0X00000000
 #define RAM_BASE_ADDR 		 	RAM_BASE_ADDR0
 
 
 /*  aeMB   */ 
 
 
 /*  uart   */ 
 //intrrupt flag location
  #define UART_INT (1<<0)
 #define UART_BASE_ADDR0 		 	0X90000000
 #define UART_BASE_ADDR 		 	UART_BASE_ADDR0
  #define UART_DATA_REG					(*((volatile unsigned int *) (UART_BASE_ADDR)))
 #define UART_CONTROL_REG				(*((volatile unsigned int *) (UART_BASE_ADDR+4)))
#define UART_CONTROL_WSPACE_MSK	0xFFFF0000
#define UART_DATA_RVALID_MSK			0x00008000
#define UART_DATA_DATA_MSK			0x000000FF

//////////////////////////////*basic function for jtag_uart*////////////////////////////////////////
void jtag_putchar(char ch);
char jtag_getchar(void);
void outbyte(char c){jtag_putchar(c);} //called in xil_printf();
char inbyte(){return jtag_getchar();}

void jtag_putchar(char ch){ //print one char from jtag_uart
	while((UART_CONTROL_REG&UART_CONTROL_WSPACE_MSK)==0);
	UART_DATA_REG=ch;
}

char jtag_getchar(void){ //get one char from jtag_uart
	unsigned int data;
	data=UART_DATA_REG;
	while(!(data & UART_DATA_RVALID_MSK)) //wait for terminal input
		data=UART_DATA_REG;
	return (data&UART_DATA_DATA_MSK);
}	

int jtag_scanstr(char* buf){ //scan string until <ENTER> to buf, return str length 
	char ch; unsigned int i=0;
	while(1){
		ch=jtag_getchar();
		if(ch=='\n') { buf[i]=0; jtag_putchar(ch); i++; break; } //ENTER
		else if(ch==127) { xil_printf("\b \b"); if(i>0) i--; } //backspace
		else { jtag_putchar(ch); buf[i]=ch; i++; } //valid
	}
	return i;
}

int jtag_scanint(int *num){ //return the scanned integer
	unsigned int curr_num,strlen,i=0;
	char* str=(char*)malloc(11); if(str==NULL) { xil_printf("malloc error\n");return 1; } //allocate memory
	strlen=jtag_scanstr(str); //scan str
	if(strlen>11) { xil_printf("overflows 32-bit integer value\n");return 1; } //check overflow
	*num=0;
	for(i=0;i<strlen;i++){ //str2int
		curr_num=(unsigned int)str[i]-'0';
		if(curr_num>9); //not integer: do nothing
		else *num=*num*10+curr_num;  //is integer
	}
	return 0;
}
/////////////////////////////*END: basic function for jtag_uart*////////////////////////////////////
 
 
 /*  ss   */ 
 
 
 /*  Led   */ 
 #define LED_BASE_ADDR0 		 	0X91000000
 #define LED_BASE_ADDR 		 	LED_BASE_ADDR0
 
	#define	 LED_WRITE_REG	   		(*((volatile unsigned int *) (LED_BASE_ADDR+4)))
	#define 	LED_WRITE(value)		       LED_WRITE_REG=value	


 
 
 /*  int_ctrl   */ 
 #define INT_CTRL_BASE_ADDR0 		 	0X9e000000
 #define INT_CTRL_BASE_ADDR 		 	INT_CTRL_BASE_ADDR0
 
	#define	 INT_CTRL_MER		       (*((volatile unsigned int *) (INT_CTRL_BASE_ADDR	)))
	#define	INT_CTRL_IER			(*((volatile unsigned int *) (INT_CTRL_BASE_ADDR+4	)))
	#define 	INT_CTRL_IAR			(*((volatile unsigned int *) (INT_CTRL_BASE_ADDR+8	)))
	#define 	INT_CTRL_IPR			(*((volatile unsigned int *) (INT_CTRL_BASE_ADDR+12	)))
 
 
 /*  ni   */ 
 //intrrupt flag location
  #define NI_INT (1<<1)
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
	
		
	
	#define NI_PTR_WIDTH			20
	#define	NI_PCK_SIZE_WIDTH		12

	#define NI_ST	   			(*((volatile unsigned int *) (NI_BASE_ADDR )))
	#define NI_RD			   	(*((volatile unsigned int *) (NI_BASE_ADDR+4 )))
	#define NI_WR			   	(*((volatile unsigned int *) (NI_BASE_ADDR+8)))
	





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
 
 
 /*  timer   */ 
 //intrrupt flag location
  #define TIMER_INT (1<<2)
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
 
 
 /*  bus   */ 
 #endif
