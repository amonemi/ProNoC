/**************************************
* Module: localparameter
* Date:2019-04-08  
* Author: alireza     
*
* Description: 
***************************************/
 `ifdef     INCLUDE_TOPOLOGY_LOCALPARAM
 
     function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end       
      end   
    endfunction // log2 
    
     function integer powi; // x^y
        input integer x,y;
        integer i;begin //compute x to the y
        powi=1;
        for (i = 0; i <y; i=i+1 ) begin 
            powi=powi * x;
        end
        end   
    endfunction // powi
    
    
    function integer  sum_powi;//x^(y-1) + x^(y-2) + ...+ 1;
        input integer x,y;
        integer i;begin 
        sum_powi = 0;
        for (i = 0; i < y; i=i+1)begin
            sum_powi = sum_powi + powi( x, i );
       end
    end   
    endfunction // sum_powi
    
    
  

/*******************
*   "RING"  "LINE"  "MESH" TORUS"
******************/


/* verilator lint_off WIDTH */
//route type
localparam 
    NX = T1,
    NY = T2,    
    NL = T3,
    NXw = log2(NX),
    NYw= log2(NY),
    NLw= log2(NL),
    PPSw_MESH_TORI =4, //port presel width for adaptive routing
    
    /* verilator lint_off WIDTH */     
    ROUTE_TYPE_MESH_TORI = (ROUTE_NAME == "XY" || ROUTE_NAME == "TRANC_XY" )?    "DETERMINISTIC" : 
                               (ROUTE_NAME == "DUATO" || ROUTE_NAME == "TRANC_DUATO" )?   "FULL_ADAPTIVE": "PAR_ADAPTIVE",

    R2R_CHANNELS_MESH_TORI=  (TOPOLOGY=="RING" || TOPOLOGY=="LINE")? 2 : 4,   
    R2E_CHANNELS_MESH_TORI= NL,    
    RAw_MESH_TORI = ( TOPOLOGY == "RING" || TOPOLOGY == "LINE")? NXw : NXw + NYw,
    EAw_MESH_TORI = (NL==1) ? RAw_MESH_TORI : RAw_MESH_TORI + NLw,
    NR_MESH_TORI = (TOPOLOGY=="RING" || TOPOLOGY=="LINE")? NX : NX*NY,
    NE_MESH_TORI = NR_MESH_TORI * NL,
    MAX_P_MESH_TORI = R2R_CHANNELS_MESH_TORI + R2E_CHANNELS_MESH_TORI,
    DSTPw_MESH_TORI =   R2R_CHANNELS_MESH_TORI; // P-1
                       
    /* verilator lint_on WIDTH */                               
    
      
          
       
        
 
 /******************
  *     FATTREE
  * *****************/
localparam 
    K=T1,
    L=T2, 
    Lw=log2(L),
    Kw=log2(K),
    LKw=L*Kw,
    RAw_FATTREE =  LKw + Lw,
    EAw_FATTREE  = LKw,
    NE_FATTREE = powi( K,L ), 
    NR_FATTREE = L * powi( L , L - 1 ),  // total number of routers  
    ROUTE_TYPE_FATTREE = "DETERMINISTIC",
    DSTPw_FATTREE = K+1,
    MAX_P_FATTREE = 2*K;
        
   
        
/**********************
 *      TREE
 * ********************/
localparam 
    ROUTE_TYPE_TREE = "DETERMINISTIC",
    NE_TREE = powi( K,L ),  //total number of endpoints
    NR_TREE = sum_powi ( K,L ),  // total number of routers  
    RAw_TREE =  LKw + Lw,
    EAw_TREE  =  LKw,
    DSTPw_TREE = log2(K+1),
    MAX_P_TREE = K+1;
              
 
    /* verilator lint_off WIDTH */ 
    localparam
        PPSw = PPSw_MESH_TORI,    
         // destination port width in header flit           
        DSTPw= (TOPOLOGY == "FATTREE")? DSTPw_FATTREE:
               (TOPOLOGY == "TREE")?  DSTPw_TREE:
                DSTPw_MESH_TORI,
        //router address width        
        RAw =   (TOPOLOGY == "FATTREE")? RAw_FATTREE:
                (TOPOLOGY == "TREE")?  RAw_TREE:
                RAw_MESH_TORI,                
        //endpoint address width
        EAw =   (TOPOLOGY == "FATTREE")? EAw_FATTREE:
                (TOPOLOGY == "TREE")?  EAw_TREE:
                EAw_MESH_TORI,  
        // total number of endpoints         
        NE =   (TOPOLOGY == "FATTREE")? NE_FATTREE:
                (TOPOLOGY == "TREE")?  NE_TREE:
                NE_MESH_TORI, 
        //total number of routers        
        NR =   (TOPOLOGY == "FATTREE")? NR_FATTREE:
                (TOPOLOGY == "TREE")?  NR_TREE:
                NR_MESH_TORI,  
                
        ROUTE_TYPE =   (TOPOLOGY == "FATTREE")? ROUTE_TYPE_FATTREE:
                (TOPOLOGY == "TREE")?  ROUTE_TYPE_TREE:
                ROUTE_TYPE_MESH_TORI,
                
        MAX_P=  (TOPOLOGY == "FATTREE")? MAX_P_FATTREE:
                (TOPOLOGY == "TREE")?  MAX_P_TREE:
                MAX_P_MESH_TORI;               
       
    /* verilator lint_on WIDTH */         
 
 
   
 `endif


