#ifndef FATTREE_H
	#define FATTREE_H



unsigned int    Lw;
unsigned int    Kw;
unsigned int    LKw;
unsigned int    RAw_FATTREE;
unsigned int    EAw_FATTREE;
unsigned int    NE_FATTREE;
unsigned int    NR_FATTREE;
unsigned int    DSTPw_FATTREE ;
unsigned int    MAX_P_FATTREE ;


unsigned int NPOS = powi( K, L-1);
unsigned int CHAN_PER_DIRECTION = (K * powi( L , L-1 )); //up or down
unsigned int CHAN_PER_LEVEL = 2*(K * powi( K , L-1 )); //up+down







inline void fatree_local_addr (unsigned int t1, unsigned int r1, unsigned int addr, unsigned int id){
	if (t1==1 ){
		router1[r1]->current_r_addr = addr;
		router1[r1]->current_r_id   = id;
	}
	else{
		router2[r1]->current_r_addr = addr;
		router2[r1]->current_r_id   = id;
	}

}


unsigned int fattree_addrencode( unsigned int pos, unsigned int k, unsigned int l){
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


unsigned int fattree_addrdecode(unsigned int addrencode , unsigned int k, unsigned int l){
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
			return fattree_addrencode(id, T1, T2);
}

unsigned int endp_addr_decoder (unsigned int code){
		return fattree_addrdecode(code, T1, T2);
}


void topology_init (void){
	unsigned int pos,level,port;

	Lw= Log2(L);
	Kw=Log2(K);
	LKw=L*Kw;
	RAw_FATTREE =  LKw + Lw;
	EAw_FATTREE  = LKw;
	NE_FATTREE = powi( K,L ); 
	NR_FATTREE = L * powi( K , L - 1 );  // total number of routers  
	DSTPw_FATTREE = K+1;
	MAX_P_FATTREE = 2*K;		
	#define NRL (NE/K) //number of router in  each layer     

    unsigned int num = 0;
	//connect all down input chanels
	for (level = 0; level<L-1; level=level+1) {// : level_c
	/* verilator lint_off WIDTH */
		unsigned int  LEAVE_L = L-1-level;
	/* verilator lint_on WIDTH */    
		//input chanel are numbered interleavely, the interleaev dep}s on level
		unsigned int ROUTERS_PER_NEIGHBORHOOD = powi(K,L-1-(level)); 
		unsigned int ROUTERS_PER_BRANCH = powi(K,L-1-(level+1)); 
		unsigned int LEVEL_OFFSET = ROUTERS_PER_NEIGHBORHOOD*K;
		for ( pos = 0; pos < NPOS; pos=pos+1 ) {// : pos_c
		    unsigned int ADRRENCODED=fattree_addrencode(pos,K,L);
		    unsigned int NEIGHBORHOOD = (pos/ROUTERS_PER_NEIGHBORHOOD);
		    unsigned int NEIGHBORHOOD_POS = pos % ROUTERS_PER_NEIGHBORHOOD;
		    for ( port = 0; port < K; port=port+1 ) {// : port_c
		        unsigned int LINK = 
		            ((level+1)*CHAN_PER_LEVEL - CHAN_PER_DIRECTION)  //which levellevel
		            +NEIGHBORHOOD* LEVEL_OFFSET   //region in level
		            +port*ROUTERS_PER_BRANCH*K //sub region in region
		            +(NEIGHBORHOOD_POS)%ROUTERS_PER_BRANCH*K //router in subregion
		            +(NEIGHBORHOOD_POS)/ROUTERS_PER_BRANCH; //port on router


		        unsigned int L2= (LINK+CHAN_PER_DIRECTION)/CHAN_PER_LEVEL;
		        unsigned int POS2 = ((LINK+CHAN_PER_DIRECTION) % CHAN_PER_LEVEL)/K;
		        unsigned int PORT2= (((LINK+CHAN_PER_DIRECTION) % CHAN_PER_LEVEL)  %K)+K;
		        unsigned int ID1 =NRL*level+pos;
		        unsigned int ID2 =NRL*L2 + POS2;
		        unsigned int POS_ADR_CODE2= fattree_addrencode(POS2,K,L);
		        unsigned int POS_ADR_CODE1= fattree_addrencode(pos,K,L);
		       
		
		     	
				
		       //fattree_connect(Ti(ID1),Ri(ID1),port,Ti(ID2),Ri(ID2),PORT2);
		        r2r_cnt_all[num] =(r2r_cnt_table_t){.id1=ID1, .t1=Ti(ID1), .r1=Ri(ID1), .p1=port, .id2=ID2, .t2=Ti(ID2), .r2=Ri(ID2), .p2=PORT2 };
		        unsigned int current_layer_addr = LEAVE_L;
		        unsigned int current_pos_addr   = ADRRENCODED;  
				unsigned int addr = (current_layer_addr << LKw)| current_pos_addr;       
		       
//printf( "[%u] = t1=%u, r1=%u, p1=%u, t2=%u, r2=%u, p2=%u \n",  num, r2r_cnt_all[num].t1, r2r_cnt_all[num].r1, r2r_cnt_all[num].p1, r2r_cnt_all[num].t2, r2r_cnt_all[num].r2, r2r_cnt_all[num].p2 );
				 //assign current_r_addr [ID1] = {current_layer_addr [ID1],current_pos_addr[ID1]};
				fatree_local_addr(Ti(ID1),Ri(ID1),  addr, ID1);


				if(level==L-2){// 
					current_layer_addr  =0;
		        	current_pos_addr = POS_ADR_CODE2;
					addr = (current_layer_addr << LKw)| current_pos_addr;           
		        	 //assign current_r_addr [ID2] = {current_layer_addr [ID2],current_pos_addr[ID2]};
					fatree_local_addr(Ti(ID2),Ri(ID2),  addr, ID2);
				}//if
		     num++;
		     }
		}
	} 

	R2R_TABLE_SIZ=num;

	for ( pos = 0; pos <  NE; pos=pos+1 ) {// : }points
		unsigned int RID= NRL*(L-1)+(pos/K);
		unsigned int RPORT = pos%K;
		//connected router encoded address
		unsigned int  CURRENTPOS=   fattree_addrencode(pos/K,K,L);
		
 
		//assign router_chan_out [RID][RPORT] =    chan_in_all [pos];                     
		//assign chan_out_all [pos] = router_chan_in [RID][RPORT]; 
		//assign er_addr [pos] = CURRENTPOS [RAw-1 : 0];
       
		r2e_cnt_all[pos].r1=Ri(RID);
		r2e_cnt_all[pos].p1=RPORT;
		er_addr [pos] = CURRENTPOS;

		//printf( "[%u] =r1=%u,p1=%u\n",pos,r2e_cnt_all[pos].r1,r2e_cnt_all[pos].p1);

		//connect_r2e(2,Ri(RID),RPORT,pos);     
   }
}



void topology_connect_r2r (int n){
	fattree_connect(r2r_cnt_all[n]);
}

void topology_connect_r2e (int n){
	connect_r2e(2,r2e_cnt_all[n].r1,r2e_cnt_all[n].p1,n);
}



/*
void topology_connect_all_nodes (void){

	unsigned int pos,level,port;
	unsigned int num = 0;
	
	for (level = 0; level<L-1; level=level+1) {// : level_c
		for ( pos = 0; pos < NPOS; pos=pos+1 ) {// : pos_c
		   for ( port = 0; port < K; port=port+1 ) {// : port_c		           
						
		        fattree_connect(r2r_cnt_all[num]);
		        num++;
		        	     
		     }
		}
	} 
     
   
	for ( pos = 0; pos <  NE; pos=pos+1 ) {// : }points
		
		
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
		if(tmp1!=tmp2) distance= (i+1)*2-1 ; //distance obtained based on the highest level index which differ

	}
	 return distance;
}





#endif
