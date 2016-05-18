#define lcd_TEST_ENABLE
#include "lcd_test.h"


// a simple delay function
void delay ( unsigned int num ){
	
	while (num>0){ 
		num--;
		asm volatile ("nop");
	}
	return;

}

int main(){
	
	lcd_test();
	while(1){
	
	

	}

return 0;
}

