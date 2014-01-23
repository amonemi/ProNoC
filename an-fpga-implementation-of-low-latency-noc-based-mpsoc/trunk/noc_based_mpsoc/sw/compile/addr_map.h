#ifndef ADDR_MAP_H
	#define ADDR_MAP_H
	
	#define RAM_BASE			0x00000000
	#define	NOC_BASE			0x40000000	
	#define	GPIO_BASE			0x41000000	
	


	//NOC 
	#define	NIC_WR_DONE_LOC				1<<0
	#define	NIC_RD_DONE_LOC				1<<1
	#define NIC_RD_OVR_ERR_LOC			1<<2
	#define	NIC_RD_NPCK_ERR_LOC			1<<3
	#define	NIC_HAS_PCK_LOC				1<<4
	#define X_NODE_NUM_WIDTH			2
	#define Y_NODE_NUM_WIDTH			2
	#define BUFFER_SIZE				31

	volatile unsigned int *led_ptr 	  = (unsigned int*) (GPIO_BASE);
	volatile unsigned int *nic_rd_ptr = (unsigned int*) (NOC_BASE);
	volatile unsigned int *nic_wr_ptr = (unsigned int*) (NOC_BASE+4);
	volatile unsigned int *nic_st_ptr = (unsigned int*) (NOC_BASE+8);

	#define core_addr(DES_X, DES_Y) 		((DES_X << Y_NODE_NUM_WIDTH) + DES_Y)<<(32-3-Y_NODE_NUM_WIDTH-X_NODE_NUM_WIDTH)	






#endif
