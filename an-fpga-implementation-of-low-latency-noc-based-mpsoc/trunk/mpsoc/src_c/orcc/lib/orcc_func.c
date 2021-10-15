


// a simple delay function
void delay ( unsigned int num ){
	
	while (num>0){ 
		num--;
		nop(); // asm volatile ("nop");
	}
	return;

}


#ifndef RANDOM_H
	#define RANDOM_H

// KISS is one random number generator according to three numbers.
static unsigned int x=123456789,y=234567891,z=345678912,w=456789123,c=0; 

unsigned int JKISS32() { 
    unsigned int t; 

    y ^= (y<<5); y ^= (y>>7); y ^= (y<<22); 

    t = z+w+c; z = w; c = t < 0; w = t&2147483647; 

    x += 1411392427; 

    return x + y + w; 
}

unsigned int rand(void){
	return JKISS32();
}

void srand(unsigned int seed){
	x^=seed; y+=seed; z^=seed; w-=seed;
}



#endif
