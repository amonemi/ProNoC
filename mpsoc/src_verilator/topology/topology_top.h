#ifndef TOPOLOGY_TOP_H
#define TOPOLOGY_TOP_H

    unsigned int    R2R_TABLE_SIZ =0;

    #define CNT_R2R_SIZ  (NR * MAX_P)     //((NR1+NR2+1)*(K+1))
    #define CNT_R2E_SIZ  (NE+1)

    typedef struct R2R_CNT_TABLE {
        unsigned int id1;
        unsigned int t1;
        unsigned int r1;
        unsigned int p1;
        unsigned int id2;
        unsigned int t2;
        unsigned int r2;
        unsigned int p2;
    } r2r_cnt_table_t;

    r2r_cnt_table_t r2r_cnt_all[CNT_R2R_SIZ];

    typedef struct R2E_CNT_TABLE {
        unsigned int r1;
        unsigned int p1;
    } r2e_cnt_table_t;

    r2e_cnt_table_t r2e_cnt_all[CNT_R2E_SIZ];

    #ifndef FLAT_MODE
    int get_router_num (int NR_num, int NR_id){
        int offset=0;
        if(NR_num* sizeof(int) > sizeof(router_NRs)){
                fprintf(stderr,"ERROR: NR%u is not defined\n",NR_num);
                exit(1);
        }
        while (NR_num > 1) {
            NR_num-=1;
            offset += router_NRs[NR_num];
        }
        return offset + NR_id;    
    }    
    #endif

    unsigned int er_addr [NE+1]; 
    char start_i=0;
    char start_o[NE+1]={0};

    unsigned int Log2 (unsigned int n){
        unsigned int l=1;
        while((0x1<<l) < n)l++;
        return l;
    }

    unsigned int powi (unsigned int x, unsigned int y){ // x^y
        unsigned int i;        
        unsigned int pow=1;
        for (int i = 0; i <y; i=i+1 ) {
            pow=pow * x;
        }
        return pow;    
    }

    unsigned int sum_powi (unsigned int x, unsigned int y){//x^(y-1) + x^(y-2) + ...+ 1;
        unsigned int i; 
        unsigned int sum = 0;
        for (i = 0; i < y; i=i+1){
            sum = sum + powi( x, i );
          }   
        return sum;
    }

#if defined (IS_FATTREE) || defined (IS_TREE)
        inline unsigned int  Ti( unsigned int id){
          return (id < NR1)? 1 : 2;
        }
        inline unsigned int Ri(unsigned int id){
            return  (id < NR1)? id : id-NR1;
        }
        
        #define     K T1
        #define     L T2 
        



        inline void fattree_connect ( r2r_cnt_table_t in){
            unsigned int t1 = in.t1;
            unsigned int r1 = in.r1; 
            unsigned int p1 = in.p1; 
            unsigned int t2 = in.t2; 
            unsigned int r2 = in.r2;
            unsigned int p2 = in.p2;

            if (t1==1 && t2 == 1) {
                conect_r2r(1,r1,p1,1,r2,p2);
                conect_r2r(1,r2,p2,1,r1,p1);
            }
            else if (t1==1 && t2 == 2) {
                conect_r2r(1,r1,p1,2,r2,p2);
                conect_r2r(2,r2,p2,1,r1,p1);
            }
            else if (t1==2 && t2 == 1){
                conect_r2r(2,r1,p1,1,r2,p2);
                conect_r2r(1,r2,p2,2,r1,p1);
            }
            else{
                conect_r2r(2,r1,p1,2,r2,p2);
                conect_r2r(2,r2,p2,2,r1,p1);
            }
        }
#endif

    


    #if defined (IS_MESH) || defined (IS_FMESH) || defined (IS_TORUS) || defined (IS_LINE) || defined (IS_RING )




        #include "mesh.h"
    #elif  defined (IS_FATTREE)
        #include "fattree.h"
    #elif  defined (IS_TREE)
        #include "tree.h"
    #elif  defined (IS_STAR)
        #include "star.h"
    #else
        //custom not coded
        unsigned int endp_addr_encoder ( unsigned int id){
            return id;
        }

        unsigned int endp_addr_decoder (unsigned int code){
            return code;
        }
        #include "custom.h"

    #endif


#endif

