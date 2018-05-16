
#include "ram_test.h"


// a simple delay function
void delay ( unsigned int num ){
	
	while (num>0){ 
		num--;
		nop(); // asm volatile ("nop");
	}
	return;

}

int main(){
	while(1){
		
	

	}

return 0;
}

