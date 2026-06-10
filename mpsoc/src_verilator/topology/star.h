#ifndef STAR_H
    #define STAR_H

void topology_connect_all_nodes_old (void){
    unsigned int pos;
    for ( pos = 0; pos <  NE; pos=pos+1 ) {// : endpoints   
        //assign router_chan_out [0][pos] =   chan_in_all [pos];
        //assign chan_out_all [pos]         =   router_chan_in [0][pos];
        connect_r2e(1,0,pos,pos); 
        er_addr [pos] = 0;        
    }//pos 
}

void topology_connect_r2r (unsigned int n){

}

void topology_connect_r2e (unsigned int n){
    connect_r2e(1,0,n,n);
}

unsigned int endp_addr_encoder ( unsigned int id){
    return id;
}

unsigned int endp_addr_decoder (unsigned int code){
    return code;
}

void topology_init (void){
    #ifndef FLAT_MODE
    router1[0]->current_r_addr = 0;
    router1[0]->current_r_id   = 0;
    for ( int pos = 0; pos <  NE; pos=pos+1 ) {// : endpoints
        er_addr [pos] = 0;
    }
    #endif
}

#endif

