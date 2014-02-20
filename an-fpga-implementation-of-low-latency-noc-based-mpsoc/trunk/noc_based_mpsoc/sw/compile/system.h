#ifndef SYSTEM_H
	#define SYSTEM_H
	//define base addresses	
	#define RAM_BASE			0x00000000
	#define	NOC_BASE			0x40000000	
	#define	GPIO_BASE			0x41000000
	#define EXT_INT_BASE			0x42000000
	#define TIMER_BASE			0x43000000
	#define INT_CTRL_BASE			0x44000000	
	
	//GPIO
	#define GPIO_ADDR_TYPE_START		5
	#define GPIO_ADDR_PORT_WIDTH		5
	#define GPIO_ADDR_REG_WIDTH		5


	#define GPIO_IO_TYPE_NUM		0
	#define GPIO_I_TYPE_NUM			4
	#define GPIO_O_TYPE_NUM			8

	#define GPIO_DIR_REG			0
	#define GPIO_WRITE_REG			4
	#define GPIO_READ_REG			8

	
	#define GPIO_TYPE_LOC_START		 (GPIO_ADDR_REG_WIDTH + GPIO_ADDR_PORT_WIDTH)
	#define GPIO_PORT_LOC_START		 (GPIO_ADDR_REG_WIDTH+2)

	
	#define	GPIO_IO_BASE			(GPIO_BASE  + (GPIO_IO_TYPE_NUM		<<	GPIO_TYPE_LOC_START))
	#define GPIO_I_BASE			(GPIO_BASE  + (GPIO_I_TYPE_NUM		<<	GPIO_TYPE_LOC_START))
	#define GPIO_O_BASE			(GPIO_BASE  + (GPIO_O_TYPE_NUM		<<	GPIO_TYPE_LOC_START))

	#define gpio_io_dir_reg(port_num)	(*((volatile unsigned int *)  (GPIO_IO_BASE+(port_num << GPIO_PORT_LOC_START)+GPIO_DIR_REG)))
	#define gpio_io_wr_reg(port_num)	(*((volatile unsigned int *)  (GPIO_IO_BASE+(port_num << GPIO_PORT_LOC_START)+GPIO_WRITE_REG)))
	#define gpio_io_rd_reg(port_num)	(*((volatile unsigned int *)  (GPIO_IO_BASE+(port_num << GPIO_PORT_LOC_START)+GPIO_READ_REG)))	
	#define gpio_o_wr_reg(port_num)		(*((volatile unsigned int *)  (GPIO_O_BASE+(port_num << GPIO_PORT_LOC_START)+GPIO_WRITE_REG))) 
	#define gpio_i_rd_reg(port_num)		(*((volatile unsigned int *)  (GPIO_I_BASE+(port_num << GPIO_PORT_LOC_START)+GPIO_READ_REG)))		

	#define gpio_io_dir(port_num,val)	gpio_io_dir_reg(port_num)=val
	#define gpio_io_wr(port_num,val)	gpio_io_wr_reg(port_num)=val
	#define gpio_o_wr(port_num,val)		gpio_o_wr_reg(port_num)=val

	//EXT_INT
	#define EXT_INT_GER   		(*((volatile unsigned int *) (EXT_INT_BASE	)))
	#define EXT_INT_IER_RISE	(*((volatile unsigned int *) (EXT_INT_BASE+4	)))
	#define EXT_INT_IER_FALL	(*((volatile unsigned int *) (EXT_INT_BASE+8	)))
	#define EXT_INT_ISR 		(*((volatile unsigned int *) (EXT_INT_BASE+12	)))
	#define EXT_INT_RD   		(*((volatile unsigned int *) (EXT_INT_BASE+16	)))
	
	
	

	//TIMER
	
	#define TCSR0	   	(*((volatile unsigned int *) (TIMER_BASE	)))
		
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
	#define TLR0	   	(*((volatile unsigned int *) (TIMER_BASE+4	)))
	#define TCMP0	   	(*((volatile unsigned int *) (TIMER_BASE+8	)))
	
	#define TIMER_EN		1
	#define TIMER_INT_EN		2
	#define TIMER_RST_ON_CMP	4
	

	//INT CONTROLLER

	#define INTC_MER	(*((volatile unsigned int *) (INT_CTRL_BASE	)))
	#define INTC_IER	(*((volatile unsigned int *) (INT_CTRL_BASE+4	)))
	#define INTC_IAR	(*((volatile unsigned int *) (INT_CTRL_BASE+8	)))
	#define INTC_IPR	(*((volatile unsigned int *) (INT_CTRL_BASE+12	)))

	


	//NOC 
	#define X_Y_ADDR_WIDTH_IN_HDR			4
	#define NI_PTR_WIDTH				19
	#define	NI_PCK_SIZE_WIDTH			13
	#define	NIC_WR_DONE_LOC				1<<0
	#define	NIC_RD_DONE_LOC				1<<1
	#define NIC_RD_OVR_ERR_LOC			1<<2
	#define	NIC_RD_NPCK_ERR_LOC			1<<3
	#define	NIC_HAS_PCK_LOC				1<<4
	
	

	#define NIC_RD	   	(*((volatile unsigned int *) (NOC_BASE	)))
	#define NIC_WR	   	(*((volatile unsigned int *) (NOC_BASE+4)))
	#define NIC_ST	   	(*((volatile unsigned int *) (NOC_BASE+8)))

	

	#define core_addr(DES_X, DES_Y) 		((DES_X << X_Y_ADDR_WIDTH_IN_HDR) + DES_Y)<<(32-3-(2*X_Y_ADDR_WIDTH_IN_HDR))	
	inline void  send_pck (unsigned int * pck_buffer, unsigned int pck_size){
		NIC_WR = (unsigned int) (& pck_buffer [0]) + (pck_size<<NI_PTR_WIDTH);
	}
	inline void  save_pck	(unsigned int * pck_buffer, unsigned int pck_size){
		NIC_RD = (unsigned int) (& pck_buffer [0]) + (pck_size<<NI_PTR_WIDTH);
	}
	#define wait_for_sending_pck()			while (!(NIC_ST & NIC_WR_DONE_LOC))
	#define wait_for_getting_pck()			while (!(NIC_ST & NIC_HAS_PCK_LOC))



#endif
