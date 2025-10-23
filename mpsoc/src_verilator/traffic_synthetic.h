#ifndef TRAFFIC_SYNTHETIC_H
#define TRAFFIC_SYNTHETIC_H


#define INJECT_OFF -1

//#include "topology.h"

#if defined (IS_LINE) || defined (IS_RING )
    #define X_MAX  T1
    #define Y_MAX  1
    #define Z_MAX  1
    #define L_MAX  T3
#elif defined (IS_MESH_3D)
    #define X_MAX  T1
    #define Y_MAX  T2
    #define Z_MAX  T3
    #define L_MAX  T4
#elif defined (IS_TORUS) || defined (IS_MESH) || defined (IS_FMESH)
    #define X_MAX  T1
    #define Y_MAX  T2
    #define Z_MAX  1
    #define L_MAX  T3
#else 
    #define X_MAX  NE
    #define Y_MAX  1
    #define Z_MAX  1
    #define L_MAX  1
    #define UNREGULAR_TOPO
#endif



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
// printf("mcast_list_array[%u]=%u\n",i,mcast_list_array[i]);
    }
// printf("mcastw=%u\n",MCAST_PRTLw);
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


unsigned int pck_dst_gen_return_func (unsigned int dest_x,unsigned int dest_y,unsigned int dest_z,unsigned int dest_l){
#ifdef UNREGULAR_TOPO
    return endp_addr_encoder(dest_x);
#else 
    return regular_topo_coords_to_Eaddr(dest_x,dest_y,dest_z,dest_l);
#endif
}

unsigned int pck_dst_gen_synthetic (unsigned int core_num, unsigned char * inject_en){
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
    
    if(( strcmp(TRAFFIC ,"CUSTOM") == 0)|| (strcmp (TRAFFIC,"custom")==0)){
        if (custom_traffic_table[core_num]== INJECT_OFF){
            *inject_en=0;
            return INJECT_OFF;
        }
        return endp_addr_encoder(custom_traffic_table[core_num]);
    } 
    unsigned int current_l, current_x, current_y, current_z;
    unsigned int dest_l,dest_x, dest_y, dest_z;
#ifdef UNREGULAR_TOPO
    current_l=0; current_x=0; current_y=0; current_z=0;
    current_x = core_num;
#else 
    regular_topo_Eid_to_coords(core_num, &current_x, &current_y, &current_z, &current_l);
#endif
    if(( strcmp(TRAFFIC ,"TRANSPOSE1")==0)|| (strcmp (TRAFFIC,"transposed 1")==0)){
        dest_x =
            (Z_MAX==1 && Y_MAX==1) ? (X_MAX-current_x-1) :
            (Y_MAX-current_y-1) % X_MAX;
        dest_y =
            ( Z_MAX==1 ) ? ((X_MAX-current_x-1) % Y_MAX) : 
            ((Z_MAX-current_z-1)  % Y_MAX);
        dest_z = (X_MAX-current_x-1) % Z_MAX;
        dest_l = L_MAX-current_l-1;
        return pck_dst_gen_return_func(dest_x,dest_y,dest_z,dest_l);
    }
    if(( strcmp(TRAFFIC ,"TRANSPOSE2")==0)|| (strcmp (TRAFFIC,"transposed 2")==0)){
        dest_x =
            (Z_MAX==1 && Y_MAX==1)? X_MAX-current_x-1:  //same as transposed 1
            current_y % X_MAX;
        dest_y =
            ( Z_MAX==1)? (current_x % Y_MAX) : 
            current_z  % Y_MAX;
        dest_z = dest_x % Z_MAX;
        dest_l = L_MAX-current_l-1;
        return pck_dst_gen_return_func(dest_x,dest_y,dest_z,dest_l);
    }
    if(( strcmp(TRAFFIC ,"TORNADO") == 0)|| (strcmp (TRAFFIC,"tornado")==0)){
        //[(x+(k/2-1)) mod k, (y+(k/2-1)) mod k],
        dest_x = ((current_x + ((X_MAX/2)-1))%X_MAX);
        dest_y =(Y_MAX==1)? 0 : ((current_y + ((Y_MAX/2)-1))%Y_MAX);
        dest_z =(Z_MAX==1)? 0 : ((current_z + ((Z_MAX/2)-1))%Z_MAX);
        dest_l =(L_MAX==1)? 0 : ((current_l + ((L_MAX/2)-1))%L_MAX);
        return pck_dst_gen_return_func(dest_x,dest_y,dest_z,dest_l);
    }
    if(( strcmp(TRAFFIC ,"NEIGHBOR") == 0)|| (strcmp (TRAFFIC,"neighbor")==0)){
        //dx = sx + 1 mod k
        dest_x = (current_x + 1)%X_MAX;
        dest_y = (current_y + 1)%Y_MAX;
        dest_z = (current_z + 1)%Z_MAX;
        dest_l = current_l;
        return pck_dst_gen_return_func(dest_x,dest_y,dest_z,dest_l);
    }
    
    fprintf (stderr,"ERROR: traffic %s is an unsupported traffic pattern\n",TRAFFIC);
    *inject_en=0;
    return INJECT_OFF;
}

#endif
