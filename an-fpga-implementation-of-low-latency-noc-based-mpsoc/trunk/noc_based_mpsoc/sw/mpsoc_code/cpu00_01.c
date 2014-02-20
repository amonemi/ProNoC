#include "orsocdef.h"
#include <stdlib.h>
#include "system.h"

#define BUFFER_SIZE				31

unsigned int buffer [BUFFER_SIZE];

#define DES_X	2
#define DES_Y	1
#define DES_ADDR core_addr(DES_X, DES_Y) 		

void delay(unsigned int);






int main()
{
	unsigned int status=0;
	int i;
 
	while(1){
		for (i=1;i<BUFFER_SIZE;i++) buffer [i] = i;
		buffer [0]= DES_ADDR ;
		send_pck (buffer,BUFFER_SIZE);
		wait_for_sending_pck();

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

