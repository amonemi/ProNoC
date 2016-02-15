

#include "gcd_test.h"

void delay ( unsigned int );


const unsigned int seven_seg_tab [16] = {0x3F,0x06,0x5B,0x4F,0x66,0x6D,0x7D,0x07,0x7F,0x6F,0x77,0x7C,0x39,0x5E, 0x79,0x71};

void desplay_num( unsigned int num){
	unsigned int value=0x0000;
	int i;
	for (i=0;i<4;i++){
 		value<<=7;
		value |= (~seven_seg_tab[(num&0xF000)>>12]&0x7F);
		num<<=4;
		
	}
	
	GPO_WRITE(value);

}

unsigned int in1[5]={100,200,55,266,88};
unsigned int in2[5]={10,46,555,1024,55};



int main(){
	unsigned int i=0;
	desplay_num(0);
	unsigned int gcd=0;

	for (i=0;i<5; i++){
		GCD_IN1_WRITE(in1[i]) ;
		GCD_IN2_WRITE(in2[i]) ;
		while (GCD_DONE_READ()!=1);
		gcd = GCD_GCD_READ();
		desplay_num(gcd);
		delay(50000000);

	}


	while(1){
		i++;
		delay(5000000);
		GPO_WRITE(0xFFFFFFF);
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

