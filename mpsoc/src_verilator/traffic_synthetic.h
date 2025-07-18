#ifndef TRAFFIC_SYNTHETIC_H
#define TRAFFIC_SYNTHETIC_H


#define INJECT_OFF -1

//#include "topology.h"


extern int TRAFFIC_TYPE;
extern int HOTSPOT_NUM;
extern char * TRAFFIC;
extern unsigned char  NEw;

int custom_traffic_table[NE];

typedef struct HOTSPOT_NODE {
    int  ip_num;
    char send_enable;
    int  percentage; // x10
} hotspot_st;

hotspot_st * hotspots;
    
unsigned int pck_dst_gen_1D (unsigned int, unsigned char *);

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


unsigned int get_rnd_ip (unsigned int core_num){
    unsigned int rnd=rand()%NE;
    if(SELF_LOOP_EN) return rnd;
    //make sure its not same as sender core
    while (rnd==core_num)    rnd=rand()%NE;
    return rnd;
}

#if (defined (IS_MESH) || defined (IS_TORUS) || defined (IS_LINE) || defined (IS_RING) )

unsigned int pck_dst_gen_2D (unsigned int core_num, unsigned char * inject_en){
    //for mesh-tori
    unsigned int current_l,current_x, current_y;
    unsigned int dest_l,dest_x,dest_y;
    mesh_tori_addrencod_sep(core_num,&current_x,&current_y,&current_l);
    * inject_en=1;
    unsigned int rnd=0;
    unsigned int rnd100=0;
    unsigned int max_percent=100/HOTSPOT_NUM;
    int i;

    if((strcmp (TRAFFIC,"RANDOM")==0) || (strcmp (TRAFFIC,"random")==0)){
        //get a random IP core
        return endp_addr_encoder(get_rnd_ip(core_num));
    }    

    if ((strcmp(TRAFFIC,"HOTSPOT")==0) || (strcmp (TRAFFIC,"hot spot")==0)){
        unsigned int rnd1000=0;
        rnd=get_rnd_ip(core_num);

        rnd1000=rand()%1000; // generate a random number between 0 & 1000
        for (i=0;i<HOTSPOT_NUM; i++){
            if ( hotspots[i].send_enable == 0 && core_num ==hotspots[i].ip_num){
                //rnd = core_num; // turn off the core
                //return endp_addr_encoder(rnd);
                *inject_en=0;
                return INJECT_OFF;
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
     
     if(( strcmp(TRAFFIC ,"CUSTOM") == 0)|| (strcmp (TRAFFIC,"custom")==0)){
         if (custom_traffic_table[core_num]== INJECT_OFF){
             *inject_en=0;
             return INJECT_OFF;
         }
         return endp_addr_encoder(custom_traffic_table[core_num]);

     }  

         fprintf (stderr,"ERROR: traffic %s is an unsupported traffic pattern\n",TRAFFIC);
         *inject_en=0;
         return INJECT_OFF;

}

#else

    unsigned int pck_dst_gen_2D (unsigned int core_num, unsigned char * inject_en){
        return pck_dst_gen_1D (core_num,inject_en );
    }

#endif


unsigned int pck_dst_gen_1D (unsigned int core_num, unsigned char  *inject_en){

    unsigned int rnd=0;
    unsigned int rnd100=0;
    unsigned int max_percent=100/HOTSPOT_NUM;
    int i;
    
    *inject_en=1;
    if((strcmp (TRAFFIC,"RANDOM")==0) || (strcmp (TRAFFIC,"random")==0)){
         return endp_addr_encoder(get_rnd_ip(core_num));
    }
    
    if ((strcmp(TRAFFIC,"HOTSPOT")==0) || (strcmp (TRAFFIC,"hot spot")==0)){
        unsigned int rnd1000=0;
        int i;
        rnd=get_rnd_ip(core_num);
        rnd1000=rand()%1000; // generate a random number between 0 & 1000
        for (i=0;i<HOTSPOT_NUM; i++){
            if ( hotspots[i].send_enable == 0 && core_num ==hotspots[i].ip_num){
                *inject_en=0;
                return INJECT_OFF;
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
     
     if(( strcmp(TRAFFIC ,"CUSTOM") == 0)|| (strcmp (TRAFFIC,"custom")==0)){
         if (custom_traffic_table[core_num]== INJECT_OFF){
             *inject_en=0;
             return INJECT_OFF;
         }
          return endp_addr_encoder(custom_traffic_table[core_num]);

     }

     fprintf (stderr,"ERROR: traffic %s is an unsupported traffic pattern\n",TRAFFIC);
     *inject_en=0;
     return  INJECT_OFF;
}


unsigned int rnd_between (unsigned int a, unsigned int b){
    unsigned int rnd,diff,min;
    if(a==b) return a;
    diff= (a<b) ?  b-a+1 : a-b+1;
    min= (a<b) ?  a : b;
    rnd = (rand() % diff) +  min;
    return rnd;
}

char mcast_list[1024];

void reverse(char str1[], int index, int size)
{
    char temp;

    temp = str1[index];
    str1[index] = str1[size - index];
    str1[size - index] = temp;

    if (index == size / 2)
    {
        return;
    }
    reverse(str1, index + 1, size);
}

char * mcast_list_array;
unsigned int MCAST_PRTLw=0;

void mcast_init(){
    mcast_list_array = (char *) malloc(NE * sizeof(char));
    if (IS_MCAST_FULL){
        for(int i=0; i< NE; i++) {
            mcast_list_array[i]=1;
            MCAST_PRTLw=NE;
        }
        return;
    }
    //partial

    int hex=0;
    int bin=0;
    char * temp_str;
    temp_str = (char *) malloc(strlen(MCAST_ENDP_LIST) * sizeof(char));
    sscanf(MCAST_ENDP_LIST,"%s",temp_str );

    char * t = strstr(temp_str, "\'h");
    if(t) hex=1;
    else {
        t = strstr(temp_str, "\'b");
        if(t) bin=1;
    }
    if(hex==0 && bin == 0){
        fprintf (stderr,"ERROR: MCAST_ENDP_LIST (%s) is given in wrong format. Only hex ('h) and bin ('b) format is accepted. \n",MCAST_ENDP_LIST);
        exit(1);
    }

    t+=2;
    int size = strlen(t);
    reverse(t, 0, size - 1);

    int i=0;
    char u [2];
    u [1] =0;

    if(hex){
        for(i=0; i< size; i++) {
            unsigned int ch ;
            u[0] = t[i];
            sscanf(u , "%x", &ch);
            ch&=0xf;
               mcast_list_array[i*4  ] = (ch & 0x1);
            mcast_list_array[i*4+1] = (ch & 0x2)>>1;
            mcast_list_array[i*4+2] = (ch & 0x4)>>2;
            mcast_list_array[i*4+3] = (ch & 0x8)>>3;
        }
    }else if(bin){
        for(i=0; i< size; i++) {
            unsigned int ch ;
            u[0] = t[i];
            sscanf(u , "%x", &ch);
            ch&=0xf;
            mcast_list_array[i  ] = ch;
        }

    }

    for (i=0;i<NE;i++){
        if(mcast_list_array[i] ==1) MCAST_PRTLw++;
//    printf("mcast_list_array[%u]=%u\n",i,mcast_list_array[i]);
    }
//    printf("mcastw=%u\n",MCAST_PRTLw);

}


unsigned int  endp_id_to_mcast_id (unsigned int  endp_id){

        int i=0;
        if (IS_MCAST_FULL) return endp_id;
        int  id=0;
        for (i=0;i<endp_id;i++) {
                if( mcast_list_array[i]==1) id++;
        }
        return id;
}


#endif
