#include "orsocdef.h"
#include <stdlib.h>
#include "addr_map.h"






void delay ( unsigned int  );

unsigned int buffer [BUFFER_SIZE];

int main(void){
	

	unsigned int status=0;
	int i;

 while(1){	
	while (!(status & NIC_HAS_PCK_LOC)) status = *nic_st_ptr ;
	 *led_ptr = 0xFFFF;
	 *nic_rd_ptr= (unsigned int) (&buffer[0]) + (BUFFER_SIZE<<19);
	 
	}
	return 0;
}


void delay ( unsigned int num ){
	while (num>0){ 
		num--;
		asm volatile ("nop");
	}
	return;
}

