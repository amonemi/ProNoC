#include "orsocdef.h"
#include <stdlib.h>
#include "addr_map.h"






void delay ( unsigned int  );


int main(void){
	 *led_ptr =  *led_ptr +1;
	 delay ( 10);
	 return 0;
}



void delay ( unsigned int num ){
	while (num>0){ 
		num--;
		asm volatile ("nop");
	}
	return;
}

