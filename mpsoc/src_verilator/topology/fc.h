#ifndef FC_H
#define FC_H

unsigned int fc_router_addr (unsigned int id){
    return id / T2;
}

unsigned int fc_local_addr (unsigned int id){
    return id % T2;
}

unsigned int fc_port_to_router (unsigned int current_r, unsigned int dest_r){
    return (dest_r < current_r) ? dest_r : dest_r - 1;
}

unsigned int endp_addr_encoder (unsigned int id){
    unsigned int raw = Log2(T1);
    unsigned int r = fc_router_addr(id);
    unsigned int l = fc_local_addr(id);
    return (l << raw) | r;
}

unsigned int endp_addr_decoder (unsigned int code){
    unsigned int raw = Log2(T1);
    unsigned int law = Log2(T2);
    unsigned int r = code & ((0x1 << raw) - 1);
    unsigned int l = (code >> raw) & ((0x1 << law) - 1);
    if(T2 == 1) return r;
    return (r * T2) + l;
}

void topology_init (void){
    unsigned int r, rr, l, num = 0;
    #ifndef FLAT_MODE
    for (r = 0; r < NR; r++) {
        router1[r]->current_r_addr = r;
        router1[r]->current_r_id   = r;
    }
    #endif
    for (r = 0; r < NR; r++) {
        for (rr = 0; rr < NR; rr++) {
            if(r == rr) continue;
            r2r_cnt_all[num] = (r2r_cnt_table_t){
                .id1 = r,
                .t1  = 1,
                .r1  = r,
                .p1  = fc_port_to_router(r, rr),
                .id2 = rr,
                .t2  = 1,
                .r2  = rr,
                .p2  = fc_port_to_router(rr, r)
            };
            num++;
        }
        for (l = 0; l < T2; l++) {
            unsigned int EID = (r * T2) + l;
            r2e_cnt_all[EID].r1 = r;
            r2e_cnt_all[EID].p1 = (NR - 1) + l;
            er_addr[EID] = r;
        }
    }
    R2R_TABLE_SIZ = num;
}

void topology_connect_r2r (int n){
    conect_r2r(
        1, r2r_cnt_all[n].r1, r2r_cnt_all[n].p1,
        1, r2r_cnt_all[n].r2, r2r_cnt_all[n].p2
    );
}

void topology_connect_r2e (int n){
    connect_r2e(1, r2e_cnt_all[n].r1, r2e_cnt_all[n].p1, n);
}

unsigned int get_mah_distance (unsigned int id1, unsigned int id2){
    return (fc_router_addr(id1) == fc_router_addr(id2)) ? 1 : 2;
}

#endif
