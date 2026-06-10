#ifndef BINTREE_H
#define BINTREE_H
#define ROOT_L  (L-1) 
#define ROOT_ID  0

unsigned int    Lw;
unsigned int    Kw;
unsigned int    LKw; 

unsigned int bintree_addrencode( unsigned int pos, unsigned int k, unsigned int l){
    unsigned int pow,i,tmp=0;
    unsigned int addrencode=0;
    unsigned int kw=0;
    while((0x1<<kw) < k)kw++;
    pow=1;
    for (i = 0; i <l; i=i+1 ) {
        tmp=(pos/pow);
        tmp=tmp%k;
        tmp=tmp<<(i)*kw;
        addrencode=addrencode | tmp;
        pow=pow * k;
    }
    return addrencode;
}

unsigned int bintree_addrdecode(unsigned int addrencode , unsigned int k, unsigned int l){
    unsigned int kw=0;
    unsigned int mask=0;
    unsigned int pow,i,tmp;
    unsigned int pos=0;
    while((0x1<<kw) < k){
        kw++;
        mask<<=1;
        mask|=0x1;
    }
    pow=1;
    for (i = 0; i <l; i=i+1 ) {
        tmp = addrencode & mask;
        tmp=(tmp*pow);
        pos= pos + tmp;
        pow=pow * k;
        addrencode>>=kw;
    }
    return pos;
}

unsigned int endp_addr_encoder ( unsigned int id){
    return bintree_addrencode(id, T1, T2);
}

unsigned int endp_addr_decoder (unsigned int code){
    return bintree_addrdecode(code, T1, T2);
}

void topology_init (void){
    Lw=Log2(L);
    Kw=Log2(K);
    LKw=L*Kw; 
    #ifndef FLAT_MODE
    //assign current_layer_addr [ROOT_ID] = ROOT_L;
    //assign current_pos_addr [ROOT_ID] = {LKw{1'b0}}; 
    unsigned int addr = ROOT_L << LKw; 
    router1[ROOT_ID]->current_r_addr = addr; 
    router1[ROOT_ID]->current_r_id   = ROOT_ID;
    unsigned int pos,level;
    unsigned int num = 0;
    //connect all up connections
    for (level = 1; level<L; level=level+1) { // : level_c        
        unsigned int L1 = L-1-level;
        unsigned int level2= level - 1;
        unsigned int L2 = L-1-level2;
        unsigned int NPOS = powi(K,level); // number of routers in this level
        for ( pos = 0; pos < NPOS; pos=pos+1 ) { // : pos_c
            unsigned int ID1 = sum_powi ( K,level) + pos;        
            unsigned int BINTREE_EQ_POS1 = pos* powi(K,L1);
            unsigned int ADR_CODE1=bintree_addrencode(BINTREE_EQ_POS1,K,L);       
            unsigned int POS2 = pos /K ;
            unsigned int ID2 = sum_powi ( K,level-1) + (pos/K);
            unsigned int PORT2= pos % K;  
            unsigned int BINTREE_EQ_POS2 = POS2*powi(K,L2);
            unsigned int ADR_CODE2=bintree_addrencode(BINTREE_EQ_POS2,K,L);
            // node_connection('Router[id1][k] to router[id2][pos%k];  
            //assign  router_chan_out [ID1][K] = router_chan_in [ID2][PORT2];
            //assign  router_chan_out [ID2][PORT2]= router_chan_in[ID1][K];  
            //bintree_connect(Ti(ID1),Ri(ID1),port,Ti(ID2),Ri(ID2),PORT2);
            r2r_cnt_all[num] =(r2r_cnt_table_t){.id1=ID1, .t1=Ti(ID1), .r1=Ri(ID1), .p1=K,.id2=ID2, .t2=Ti(ID2), .r2=Ri(ID2), .p2=PORT2 };                
            unsigned int current_layer_addr  = L1;
            unsigned int current_pos_addr    = ADR_CODE1;         
            //assign current_r_addr [ID1] = {current_layer_addr [ID1],current_pos_addr[ID1]};
            unsigned int addr = (current_layer_addr << LKw)| current_pos_addr;    
            router2[Ri(ID1)]->current_r_addr = addr;
            router2[Ri(ID1)]->current_r_id   = ID1;
            //printf( "[%u] =(addr=%x), t1=%u, r1=%u, p1=%u, t2=%u, r2=%u, p2=%u \n",  num,addr, r2r_cnt_all[num].t1, r2r_cnt_all[num].r1, r2r_cnt_all[num].p1, r2r_cnt_all[num].t2, r2r_cnt_all[num].r2, r2r_cnt_all[num].p2 );
            num++;
        }// pos
    } //level
    R2R_TABLE_SIZ=num;
    // connect }points 
    for ( pos = 0; pos <  NE; pos=pos+1 ) { // : }points
        //  node_connection T[pos] R[rid][pos %k];
        unsigned int RID= sum_powi(K,L-1)+(pos/K);
        unsigned int RPORT = pos%K;
        unsigned int CURRENTPOS=   bintree_addrencode(pos/K,K,L);
        //assign router_chan_out [RID][RPORT] =    chan_in_all [pos];                     
        //assign chan_out_all [pos] = router_chan_in [RID][RPORT];
        r2e_cnt_all[pos].r1=Ri(RID);
        r2e_cnt_all[pos].p1=RPORT;
        er_addr [pos] = CURRENTPOS;
    } //pos 
    #endif  //FLAT_MODE 
}

void topology_connect_r2r (int n){
    fattree_connect(r2r_cnt_all[n]);
}

void topology_connect_r2e (int n){
    connect_r2e(2,r2e_cnt_all[n].r1,r2e_cnt_all[n].p1,n);
}

/*
void topology_connect_all_nodes (void){
    unsigned int pos,level;
    unsigned int num=0;
    //connect all up connections
    for (level = 1; level<L; level=level+1) { // : level_c
        unsigned int NPOS = powi(K,level); // number of routers in this level
        for ( pos = 0; pos < NPOS; pos=pos+1 ) { // : pos_c
            fattree_connect(r2r_cnt_all[num]); 
            num++;   
        }// pos
    } //level
    // connect }points 
    for ( pos = 0; pos <  NE; pos=pos+1 ) { // : }points
        connect_r2e(2,r2e_cnt_all[pos].r1,r2e_cnt_all[pos].p1,pos);
    }
}
*/

unsigned int get_mah_distance ( unsigned int id1, unsigned int id2){
    unsigned int k =T1;
    unsigned int l =T2;
    unsigned int pow,tmp1,tmp2;
    unsigned int distance=0;
    pow=1;
    for (unsigned int i = 0; i <l; i=i+1 ) {
        tmp1=(id1/pow);
        tmp2=(id2/pow);
        tmp1=tmp1 % k;
        tmp2=tmp2 % k;
        pow=pow * k;
        if(tmp1!=tmp2) distance= (i+1)*2-1; //distance obtained based on the highest level index which differ
    }
    return distance;
}

#endif