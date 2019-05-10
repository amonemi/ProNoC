#ifndef TRAFFIC_SYNTHETIC_H
#define TRAFFIC_SYNTHETIC_H


#include "topology.h"


extern int TRAFFIC_TYPE;
extern int HOTSPOT_NUM;
extern char * TRAFFIC;
extern unsigned char  NEw;



typedef struct HOTSPOT_NODE {
	int  ip_num;
	char send_enable;
	int  percentage; // x10	
} hotspot_st;

hotspot_st * hotspots;
	


// number, b:bit location  W: number width log2(num)
int getBit(int num, int b, int W)
{
	while(b<0) b+=W; 
	b%=W;
	return (num >> b) & 0x1;
}

// number; b:bit location;  W: number width log2(num); v: 1 assert the bit, 0 deassert the bit; 
void setBit(int *num, int b,   int W, int v)
{
    while(b<0) b+=W; 
	b%=W;
    int mask = 1 << b;
    //printf("b=%d\n", b);
	if (v == 0)*num  = *num & ~mask; // assert bit
    else *num = *num | mask; // deassert bit
      
}

			 



unsigned int pck_dst_gen_2D (unsigned int core_num){
	//for mesh-tori
	unsigned int current_l,current_x, current_y;
	unsigned int dest_l,dest_x,dest_y;
	mesh_tori_addrencod_sep(core_num,&current_x,&current_y,&current_l);

	unsigned int rnd=0;
	unsigned int rnd100=0;
	unsigned int max_percent=100/HOTSPOT_NUM;
	int i;

	if((strcmp (TRAFFIC,"RANDOM")==0) || (strcmp (TRAFFIC,"random")==0)){
		do{
			rnd=rand()%NE;
		}while (rnd==core_num); // get a random IP core, make sure its not same as sender core
       return endp_addr_encoder(rnd);
	}	

	if ((strcmp(TRAFFIC,"HOTSPOT")==0) || (strcmp (TRAFFIC,"hot spot")==0)){
		unsigned int rnd1000=0;
		do{
			rnd=rand()%NE;
		}while (rnd==core_num); // get a random IP core, make sure its not same as sender core
		rnd1000=rand()%1000; // generate a random number between 0 & 1000
		for (i=0;i<HOTSPOT_NUM; i++){
			if ( hotspots[i].send_enable == 0 && core_num ==hotspots[i].ip_num){
				rnd = core_num; // turn off the core
				return endp_addr_encoder(rnd);
			}
		}
		for (i=0;i<HOTSPOT_NUM; i++){
			if (rnd1000 < hotspots[i].percentage && core_num !=hotspots[i].ip_num) {
				rnd = hotspots[i].ip_num;
				return endp_addr_encoder(rnd);
			}
		}
		return endp_addr_encoder(rnd);
	}

	if(( strcmp(TRAFFIC ,"TRANSPOSE1")==0)|| (strcmp (TRAFFIC,"transposed 1")==0)){
		 dest_x = T1-current_y-1;
		 dest_y = T2-current_x-1;
		 dest_l = T3-current_l-1;
		 return mesh_tori_addr_join(dest_x,dest_y,dest_l);
	}

	if(( strcmp(TRAFFIC ,"TRANSPOSE2")==0)|| (strcmp (TRAFFIC,"transposed 2")==0)){
		dest_x = current_y;
		dest_y = current_x;
		dest_l = current_l;
		return mesh_tori_addr_join(dest_x,dest_y,dest_l);
	}

	if(( strcmp(TRAFFIC ,"BIT_REVERSE")==0)|| (strcmp (TRAFFIC,"bit reverse")==0)){
		//di = sb−i−1
		int tmp=0;
		for(i=0; i< NEw; i++)  setBit(&tmp , i, NEw, getBit(core_num, NEw-i-1, NEw));
		return endp_addr_encoder(tmp);
	}

	if(( strcmp(TRAFFIC ,"BIT_COMPLEMENT") ==0)|| (strcmp (TRAFFIC,"bit complement")==0)){
		int tmp=0;
		for(i=0; i< NEw; i++)  setBit(&tmp , i, NEw, getBit(core_num, i, NEw)==0);
		return endp_addr_encoder(tmp);
	}

	if(( strcmp(TRAFFIC ,"TORNADO") == 0)|| (strcmp (TRAFFIC,"tornado")==0)){
		//[(x+(k/2-1)) mod k, (y+(k/2-1)) mod k],
			dest_x = ((current_x + ((T1/2)-1))%T1);
			dest_y = ((current_y + ((T2/2)-1))%T2);
			dest_l = current_l;
			return mesh_tori_addr_join(dest_x,dest_y,dest_l);
     }

    if(( strcmp(TRAFFIC ,"SHUFFLE") == 0)|| (strcmp (TRAFFIC,"shuffle")==0)){
		//di = si−1 mod b
		int tmp=0;
		for(i=0; i< NEw; i++)  setBit(&tmp , i, NEw, getBit(core_num, i-1, NEw));
		return endp_addr_encoder(tmp);
     }

    if(( strcmp(TRAFFIC ,"BIT_ROTATION") == 0)|| (strcmp (TRAFFIC,"bit rotation")==0)){
		//di = si+1 mod b
		int tmp=0;
		for(i=0; i< NEw; i++)  setBit(&tmp , i, NEw, getBit(core_num, i+1, NEw));
		return endp_addr_encoder(tmp);
     }

    if(( strcmp(TRAFFIC ,"NEIGHBOR") == 0)|| (strcmp (TRAFFIC,"neighbor")==0)){
		//dx = sx + 1 mod k
		 dest_x = (current_x + 1)%T1;
		 dest_y = (current_y + 1)%T2;
		 dest_l = current_l;
		 return mesh_tori_addr_join(dest_x,dest_y,dest_l);
     }    
     
     if( strcmp(TRAFFIC ,"CUSTOM") == 0){
		//[(x+(k/2-1)) mod k, (y+(k/2-1)) mod k],
		if(current_x ==0 && current_y == 0 && current_l==0 ){
           // dest_x =  T1-1;
           // dest_y =  T2-1;
           // dest_l =  T3-1;
			 dest_x =  0;
			 dest_y =  0;
			 dest_l =  1;
            return mesh_tori_addr_join(dest_x,dest_y,dest_l);
		}// make it invalid
        dest_x = current_x;
        dest_y = current_y;
        dest_l = current_l;
        return mesh_tori_addr_join(dest_x,dest_y,dest_l);

     }  

		 printf ("traffic %s is an unsupported traffic pattern\n",TRAFFIC);
		 dest_x = current_x;
		 dest_y = current_y;
		 dest_l = current_l;
		 return mesh_tori_addr_join(dest_x,dest_y,dest_l);
}




unsigned int pck_dst_gen_1D (unsigned int core_num){

	unsigned int rnd=0;
	unsigned int rnd100=0;
	unsigned int max_percent=100/HOTSPOT_NUM;
	int i;
	
	
	if((strcmp (TRAFFIC,"RANDOM")==0) || (strcmp (TRAFFIC,"random")==0)){
		do{
			rnd=rand()%NE;
		}while (rnd==core_num); // get a random IP core, make sure its not same as sender core

		return endp_addr_encoder(rnd);
	}
	
	if ((strcmp(TRAFFIC,"HOTSPOT")==0) || (strcmp (TRAFFIC,"hot spot")==0)){
		unsigned int rnd1000=0;
		int i;
		do{
			rnd=rand()%NE;
		}while (rnd==core_num); // get a random IP core, make sure its not same as sender core
		rnd1000=rand()%1000; // generate a random number between 0 & 1000
		for (i=0;i<HOTSPOT_NUM; i++){
			if ( hotspots[i].send_enable == 0 && core_num ==hotspots[i].ip_num){
				rnd = core_num; // turn off the core
				return endp_addr_encoder(rnd);
			}
		}
		
		for (i=0;i<HOTSPOT_NUM; i++){
			if (rnd1000 < hotspots[i].percentage && core_num !=hotspots[i].ip_num) {
				rnd = hotspots[i].ip_num;
				return endp_addr_encoder(rnd % NE );
			}
		}
		return endp_addr_encoder(rnd % NE );
	} 
	
	
	if(( strcmp(TRAFFIC ,"TRANSPOSE1")==0)|| (strcmp (TRAFFIC,"transposed 1")==0)){
		  return endp_addr_encoder(NE-core_num-1);
	} 
	if(( strcmp(TRAFFIC ,"TRANSPOSE2")==0)|| (strcmp (TRAFFIC,"transposed 2")==0)){
		 return endp_addr_encoder(NE-core_num-1);
	} 
	
	if(( strcmp(TRAFFIC ,"BIT_REVERSE")==0)|| (strcmp (TRAFFIC,"bit reverse")==0)){
		int tmp=0;
		for(i=0; i< NEw; i++)  setBit(&tmp , i, NEw, getBit(core_num, NEw-i-1, NEw));
		return endp_addr_encoder(tmp);
	 } 
	 
	 if(( strcmp(TRAFFIC ,"BIT_COMPLEMENT") ==0)|| (strcmp (TRAFFIC,"bit complement")==0)){
		 int tmp=0;
		 for(i=0; i< NEw; i++)  setBit(&tmp , i, NEw, getBit(core_num, i, NEw)==0);
		 return endp_addr_encoder(tmp%NE);
	 }  
	 
	 if(( strcmp(TRAFFIC ,"TORNADO") == 0)|| (strcmp (TRAFFIC,"tornado")==0)){
		//[(x+(k/2-1)) mod k, (y+(k/2-1)) mod k],
		 return endp_addr_encoder((core_num + ((NE/2)-1))%NE);
     }

     if(( strcmp(TRAFFIC ,"SHUFFLE") == 0)|| (strcmp (TRAFFIC,"shuffle")==0)){
		//di = si−1 mod b
		int tmp=0;
		for(i=0; i< NEw; i++)  setBit(&tmp , i, NEw, getBit(core_num, i-1, NEw));
		return endp_addr_encoder(tmp%NE);
	 }

     if(( strcmp(TRAFFIC ,"BIT_ROTATION") == 0)|| (strcmp (TRAFFIC,"bit rotation")==0)){
		//di = si+1 mod b
		int tmp=0;
		for(i=0; i< NEw; i++)  setBit(&tmp , i, NEw, getBit(core_num, i+1, NEw));
		return endp_addr_encoder(tmp%NE);

     }

     if(( strcmp(TRAFFIC ,"NEIGHBOR") == 0)|| (strcmp (TRAFFIC,"neighbor")==0)){
		//dx = sx + 1 mod k
    	 return endp_addr_encoder((core_num + 1)%NE);
	 }
     
     if( strcmp(TRAFFIC ,"CUSTOM") == 0){
		//[(x+(k/2-1)) mod k, (y+(k/2-1)) mod k],
		if(core_num ==2  )	 return  endp_addr_encoder(6);
		return endp_addr_encoder(core_num);
	 }

	 printf ("traffic %s is an unsupported traffic pattern\n",TRAFFIC);
	 return  endp_addr_encoder(core_num);
}


unsigned int rnd_between (unsigned int a, unsigned int b){
	unsigned int rnd,diff,min;
	if(a==b) return a;
	diff= (a<b) ?  b-a+1 : a-b+1;
	min= (a<b) ?  a : b;
	rnd = (rand() % diff) +  min;
	return rnd;
}






#endif
