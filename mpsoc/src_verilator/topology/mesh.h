#ifndef MESH_H
#define MESH_H

#define  LOCAL      0
#define  EAST       1
#define  NORTH      2
#define  SOUTH      4
//ring line
#define  FORWARD    1
#define  BACKWARD   2

#define UP          5
#define DOWN        6

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
#endif

#if defined (IS_LINE) || defined (IS_RING )
    #define  WEST       BACKWARD
    #define R2R_CHANELS_MESH_TORI   2
#else 
    #define  WEST       3
    #if defined (IS_MESH_3D)
        #define R2R_CHANELS_MESH_TORI   6
    #else
        #define R2R_CHANELS_MESH_TORI   4
    #endif //IS_MESH_3D
#endif

#define router_id(x,y,z) (((z) * Y_MAX * X_MAX) + ((y) * X_MAX) + x)
#define endp_id(x,y,z,l) ((router_id(x,y,z) * L_MAX) + l)

unsigned int nxw=0;
unsigned int nyw=0;
unsigned int nzw=0;
unsigned int maskx=0;
unsigned int masky=0;
unsigned int maskz=0;

void regular_topo_Eid_to_coords(unsigned int EID, unsigned int * x, unsigned int * y, unsigned int * z, unsigned int * l){
    (*l) = EID % L_MAX;
    unsigned int RID = EID / L_MAX;
    (*x) = RID % X_MAX;
    (*y) = (RID / X_MAX) % Y_MAX;
    (*z) = RID / (X_MAX * Y_MAX);
}

unsigned int regular_topo_coords_to_Eaddr(unsigned int x, unsigned int y, unsigned int z, unsigned int l){
    unsigned int code=x;
    unsigned int shift =nxw;
    if(Y_MAX > 1) {
        code|=y<<shift;
        shift+=nyw;
    } 
    if(Z_MAX > 1) {
        code|=z<<shift;
        shift+=nzw;
    }if(L_MAX > 1) {
        code|=l<<shift;
    }
    return code;
}

void regular_topo_Eaddr_to_coords(unsigned int code, unsigned int *x, unsigned int *y, unsigned int *z, unsigned int *l){
    (*x) = code &  maskx;
    code>>=nxw;
    if(Y_MAX > 1) {
        (*y) = code &  masky;
        code>>=nyw;
    } else (*y)=0;
    if(Z_MAX > 1) {
        (*z) = code &  maskz;
        code>>=nzw;
    } else (*z)=0;
    (*l) = code;
}

unsigned int reqular_topo_addr_encode (unsigned int id){
    unsigned int y, x, z, l;
    regular_topo_Eid_to_coords(id,&x,&y,&z,&l);
    return regular_topo_coords_to_Eaddr(x,y,z,l);
}

unsigned int regular_topo_addr_decoder (unsigned int code){
    unsigned int y, x, z, l;
    regular_topo_Eaddr_to_coords(code,&x,&y,&z,&l);
    return endp_id(x,y,z,l);
}

unsigned int fmesh_endp_addr_decoder (unsigned int code){
    unsigned int x, y, z, p;
    regular_topo_Eaddr_to_coords(code,&x,&y,&z,&p);
    if(p== LOCAL)   return ((y*T1)+x)*T3;
    if(p > SOUTH)   return ((y*T1)+x)*T3+(p-SOUTH);
    if(p== NORTH)   return ((T1*T2*T3) + x);
    if(p== SOUTH)   return ((T1*T2*T3) + T1 + x);
    if(p== WEST )   return ((T1*T2*T3) + 2*T1 + y);
    if(p== EAST )   return ((T1*T2*T3) + 2*T1 + T2 + y);
    return 0;//should not reach here
}

void fmesh_addrencod_sep(unsigned int id, unsigned int *x, unsigned int *y, unsigned int *p){
    unsigned int  l, diff,mul,addrencode;
    mul  = T1*T2*T3;
    if(id < mul) {
        *y = ((id/T3) / T1 );
        *x = ((id/T3) % T1 );
        l = (id % T3);
        *p = (l==0)? LOCAL : 4+l;
    }else{
        diff = id -  mul ;
        if( diff <  T1) { //top mesh edge
            *y = 0;
            *x = diff;
            *p = NORTH;
        } else if  ( diff < 2* T1) { //bottom mesh edge
            *y = T2-1;
            *x = diff-T1;
            *p = SOUTH;
        } else if  ( diff < (2* T1) + T2 ) { //left mesh edge
            *y = diff - (2* T1);
            *x = 0;
            *p = WEST;
        } else { //right mesh edge
            *y = diff - (2* T1) -T2;
            *x = T1-1;
            *p = EAST;
        }
    }
}

unsigned int fmesh_addrencode(unsigned int id){
    unsigned int  y, x, p, addrencode;
    fmesh_addrencod_sep(id, &x, &y, &p);
    addrencode = ( p<<(nxw+nyw) | (y<<nxw) | x);
    return addrencode;
}

unsigned int endp_addr_encoder ( unsigned int id){
        #if defined (IS_FMESH)
            return fmesh_addrencode(id);
        #else 
            return reqular_topo_addr_encode(id);
        #endif
}

unsigned int endp_addr_decoder (unsigned int code){
    #if defined (IS_FMESH)
    return fmesh_endp_addr_decoder (code);
    #else 
    return regular_topo_addr_decoder (code);
    #endif
}

static inline void topology_connect_r2r (int n){
    //printf("%d,%d -> %d,%d\n",r2r_cnt_all[n].r1, r2r_cnt_all[n].p1,r2r_cnt_all[n].r2,r2r_cnt_all[n].p2);
    conect_r2r(1,r2r_cnt_all[n].r1,r2r_cnt_all[n].p1,1,r2r_cnt_all[n].r2,r2r_cnt_all[n].p2);
}

static inline void topology_connect_r2e (int n){
    //printf ("%d,%d -> %d\n",r2e_cnt_all[n].r1,r2e_cnt_all[n].p1,n);
    connect_r2e(1,r2e_cnt_all[n].r1,r2e_cnt_all[n].p1,n);
}

#define fill_r2r_cnt(T1,R1,P1,T2,R2,P2)    (r2r_cnt_table_t){.id1=R1,.t1=T1,.r1=R1,.p1=P1,.id2=R2,.t2=T2,.r2=R2,.p2=P2}


static inline void topology_edge_connect(unsigned id1, unsigned id2, unsigned int p1, unsigned int p2, unsigned int fmesh_id,unsigned int R_ADDR, unsigned *num) {
    #if defined (IS_MESH) || defined (IS_MESH_3D) || defined (IS_LINE)
        connect_r2gnd(1,id1,p1);
    #elif defined (IS_TORUS) || defined (IS_RING) 
        r2r_cnt_all[*num]=fill_r2r_cnt(1,id1,p1,1,id2,p2);
        (*num)++;
    #elif defined (IS_FMESH) 
        r2e_cnt_all[fmesh_id].r1=id1;
        r2e_cnt_all[fmesh_id].p1=p1;
        er_addr [fmesh_id] = R_ADDR;
    #endif//topology
}

void topology_init(void){
    nxw=Log2(X_MAX);
    nyw=Log2(Y_MAX);
    nzw=Log2(Z_MAX);
    
    maskx = (0x1<<nxw)-1;
    masky = (0x1<<nyw)-1;
    maskz = (0x1<<nzw)-1;
    
    unsigned int num=0;
    unsigned int  x,y,z,l;
    #ifndef FLAT_MODE
    for (z=0; z<Z_MAX; z++) {
        for (y=0; y<Y_MAX;  y++) {
            for (x=0; x<X_MAX; x++) {
                unsigned int ROUTER_NUM =router_id(x,y,z);
                unsigned int R_ADDR =(z<<(nxw+nyw)) + (y<<nxw) + x;
                router1[ROUTER_NUM]->current_r_addr = R_ADDR;
                router1[ROUTER_NUM]->current_r_id   = ROUTER_NUM;
                unsigned int FMESH_EAST_ID  = T1*T2*T3 + 2*T1 + T2 + y;
                unsigned int FMESH_WEST_ID  = T1*T2*T3 + 2*T1 + y;
                unsigned int FMESH_SOUTH_ID = T1*T2*T3 + T1 + x;
                unsigned int FMESH_NORTH_ID = T1*T2*T3 + x;
                // endpoint(s) connection
                for  (l=0; l<L_MAX; l++) {// :locals
                    unsigned int ENDPID = endp_id(x,y,z,l);
                    unsigned int LOCALP = (l==0) ? l : l + R2R_CHANELS_MESH_TORI; // first local port is connected to router port 0. The rest are connected at the }
                    r2e_cnt_all[ENDPID].r1=router_id(x,y,z);
                    r2e_cnt_all[ENDPID].p1=LOCALP;
                    er_addr [ENDPID] = R_ADDR;
                }// locals
                
                if(x < X_MAX-1) r2r_cnt_all[num++]=fill_r2r_cnt(1,router_id(x,y,z),EAST,1,router_id(x+1,y,z),WEST);
                else topology_edge_connect(ROUTER_NUM,router_id(0,y,z),EAST, WEST, FMESH_EAST_ID, R_ADDR, &num);
                
                if(x>0) r2r_cnt_all[num++]=fill_r2r_cnt(1,ROUTER_NUM,WEST,1,router_id((x-1),y,z),EAST);
                else topology_edge_connect(ROUTER_NUM, router_id((X_MAX-1),y,z), WEST, EAST, FMESH_WEST_ID, R_ADDR, &num);
                
                if(Y_MAX==1) continue;
                if (y < Y_MAX-1) r2r_cnt_all[num++] = fill_r2r_cnt(1, ROUTER_NUM, SOUTH, 1, router_id(x, y + 1, z), NORTH);
                else topology_edge_connect(ROUTER_NUM, router_id(x, 0, z), SOUTH, NORTH, FMESH_SOUTH_ID, R_ADDR, &num);
                
                if (y>0) r2r_cnt_all[num++] = fill_r2r_cnt(1, ROUTER_NUM, NORTH, 1, router_id(x, y - 1, z), SOUTH);
                else topology_edge_connect(ROUTER_NUM, router_id(x, (Y_MAX-1), z), NORTH, SOUTH, FMESH_NORTH_ID, R_ADDR, &num);
                if(Z_MAX==1) continue;
                if (z < Z_MAX-1) r2r_cnt_all[num++] = fill_r2r_cnt(1, router_id(x, y, z), UP, 1, router_id(x, y, z + 1), DOWN);
                else    connect_r2gnd(1,ROUTER_NUM,UP);
                if (z > 0)  r2r_cnt_all[num++] = fill_r2r_cnt(1, ROUTER_NUM, DOWN, 1, router_id(x, y, z - 1), UP);
                else connect_r2gnd(1,ROUTER_NUM,DOWN);
            }//y
        }//x
    }//z
    #endif //FLAT_MODE
    R2R_TABLE_SIZ=num;
}


unsigned int get_mah_distance ( unsigned int id1, unsigned int id2){
    #if defined (IS_FMESH)
        unsigned int x1,y1,p1,x2,y2,p2;
        fmesh_addrencod_sep       ( id1, &x1, &y1, &p1);
        fmesh_addrencod_sep       ( id2, &x2, &y2, &p2);
        unsigned int z1=0;
        unsigned int z2=0;
    #else
        unsigned int x1,y1,z1,l1,x2,y2,z2,l2;
        regular_topo_Eid_to_coords(id1, &x1, &y1, &z1, &l1);
        regular_topo_Eid_to_coords(id2, &x2, &y2, &z2, &l2);
    #endif
    unsigned int x_diff = (x1 > x2) ? (x1 - x2) : (x2 - x1);
    unsigned int y_diff = (y1 > y2) ? (y1 - y2) : (y2 - y1);
    unsigned int z_diff = (z1 > z2) ? (z1 - z2) : (z2 - z1);
    return x_diff + y_diff + z_diff;
}

#endif