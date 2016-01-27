

#include "led_blink.h"

void delay ( unsigned int );

int main(){
	unsigned int i=0;
	LED_WRITE(0);

	while(1){
		i++;
		delay(5000);
		LED_WRITE(i);
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

