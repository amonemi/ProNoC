#include "orsocdef.h"
#include <stdlib.h>
#include "addr_map.h"
//#include "aemb/core.hh"


unsigned int buffer [BUFFER_SIZE];

#define DES_X	3
#define DES_Y	1
#define DES_ADDR core_addr(DES_X, DES_Y) 		

void delay(unsigned int);


int main()
{
unsigned int status=0;
	int i;
 *led_ptr = 0x0001;
 while(1){
	
	
	 *led_ptr =  *led_ptr +1;
	//	delay ( 10);

	for (i=1;i<15;i++) {
		buffer [i] = i*2;
	}




	buffer [0]= DES_ADDR ;
	*nic_wr_ptr = (unsigned int) (&buffer[0]) + (BUFFER_SIZE<<19);
	while (!(status & NIC_WR_DONE_LOC)) status = *nic_st_ptr ;

	// usleep(1000000);
	// *led_ptr = 0x0000;
//delay ( 10);
	 //usleep(1000000);


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

