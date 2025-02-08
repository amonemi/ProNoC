`include "pronoc_def.v"
/**************************************
* Module: localparameter
* Date:2019-04-08  
* Author: alireza     
*
* Description: 
***************************************/
`ifdef INCLUDE_TOPOLOGY_LOCALPARAM
     //MESH, TORUS Topology p=5           
    localparam    
        LOCAL   =   0,
        EAST    =   1,
        NORTH   =   2, 
        WEST    =   3,
        SOUTH   =   4;
    
    //LINE RING Topology p=3           
    localparam  
        FORWARD =  1,
        BACKWARD=  2;
    
    function automatic integer log2;
    input integer number;
    begin   
        log2=(number <=1) ? 1: 0;    
        while(2**log2<number) begin    
            log2=log2+1;    
        end       
    end   
    endfunction // log2 
    
    function automatic integer powi; // x^y
    input integer x,y;
    integer i;
    begin //compute x to the y
        powi=1;
        for (i = 0; i <y; i=i+1 ) begin 
            powi=powi * x;
        end
    end   
    endfunction // powi
    
    function automatic integer  sum_powi;//x^(y-1) + x^(y-2) + ...+ 1;
    input integer x,y;
    integer i;
    begin 
        sum_powi = 0;
        for (i = 0; i < y; i=i+1)begin
            sum_powi = sum_powi + powi( x, i );
        end
    end   
    endfunction // sum_powi
    
    // get the port num and return the port located at streight direction. If there is no strieght port return  router_port_num. 
    function automatic integer strieght_port;
    input integer router_port_num;  //router port num
    input integer current_port;
    begin 
        /* verilator lint_off WIDTH */ 
        if(TOPOLOGY == "MESH" || TOPOLOGY == "FMESH" || TOPOLOGY == "TORUS") begin 
        /* verilator lint_on WIDTH */ 
            strieght_port = 
                (current_port== EAST)?  WEST:
                (current_port== WEST)?  EAST:
                (current_port== SOUTH)? NORTH:
                (current_port== NORTH)? SOUTH:
                                 router_port_num; //DISABLED;
        end
        /* verilator lint_off WIDTH */ 
        else if (TOPOLOGY ==  "RING" || TOPOLOGY ==  "LINE") begin 
        /* verilator lint_on WIDTH */ 
            strieght_port = 
                (current_port== FORWARD )? BACKWARD:
                (current_port== BACKWARD)? FORWARD:
                                           router_port_num; //DISABLED;
        end
        /* verilator lint_off WIDTH */ 
        else if (TOPOLOGY == "FATTREE" ) begin 
        /* verilator lint_on WIDTH */ 
             if(router_port_num[0]==1'b0) begin //even port num
                    strieght_port =   (current_port < (router_port_num/2) )?
                    (router_port_num/2)+ current_port : 
                    current_port - (router_port_num/2);
            end else begin 
                strieght_port = (current_port == (router_port_num-1)/2) ?  router_port_num: //DISABLED;
                                (current_port < ((router_port_num+1)/2))? ((router_port_num+1)/2)+ current_port : 
                                                                            current_port - ((router_port_num+1)/2);
            end
        end else begin 
            strieght_port = router_port_num; //DISABLED;
        end
    end
    endfunction
    
    function automatic integer port_buffer_size;
    input integer router_port_num;  //router port num
    begin
        port_buffer_size = B;
        /* verilator lint_off WIDTH */ 
        if(TOPOLOGY == "MESH" || TOPOLOGY == "FMESH" || TOPOLOGY == "TORUS" || TOPOLOGY ==  "RING" || TOPOLOGY ==  "LINE")begin 
        /* verilator lint_on WIDTH */ 
            if (router_port_num == 0 || router_port_num > 4 ) port_buffer_size = LB;
        end        
    end
    endfunction

    /*******************
    *   "RING"  "LINE"  "MESH" TORUS" "FMESH"
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
        R2R_CHANELS_MESH_TORI=  (TOPOLOGY=="RING" || TOPOLOGY=="LINE")? 2 : 4,   
        R2E_CHANELS_MESH_TORI= NL,    
        RAw_MESH_TORI = ( TOPOLOGY == "RING" || TOPOLOGY == "LINE")? NXw : NXw + NYw,
        EAw_MESH_TORI = (NL==1) ? RAw_MESH_TORI : RAw_MESH_TORI + NLw,
        NR_MESH_TORI = (TOPOLOGY=="RING" || TOPOLOGY=="LINE")? NX : NX*NY,
        NE_MESH_TORI = NR_MESH_TORI * NL,
        MAX_P_MESH_TORI = R2R_CHANELS_MESH_TORI + R2E_CHANELS_MESH_TORI,
        DSTPw_MESH_TORI = R2R_CHANELS_MESH_TORI; // P-1
        /* verilator lint_on WIDTH */    
    
    /****************
    *  FMESH
    **************/
    localparam    
        NE_FMESH = NE_MESH_TORI + 2 * (NX+NY),
        NR_FMESH = NR_MESH_TORI,
        MAX_P_FMESH = 4 + NL, 
        EAw_FMESH = RAw_MESH_TORI + log2(MAX_P_FMESH);
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
        NR_FATTREE = L * powi( K , L - 1 ),  // total number of routers  
        ROUTE_TYPE_FATTREE = "DETERMINISTIC",
        DSTPw_FATTREE = K+1,
        MAX_P_FATTREE = 2*K,
        DAw_MCAST_FATTREE= powi( K,L); 
    /**********************
    *      TREE
    *********************/
    localparam 
        ROUTE_TYPE_TREE = "DETERMINISTIC",
        NE_TREE = powi( K,L ),  //total number of endpoints
        NR_TREE = sum_powi ( K,L ),  // total number of routers  
        RAw_TREE =  LKw + Lw,
        EAw_TREE  =  LKw,
        DSTPw_TREE = log2(K+1),
        MAX_P_TREE = K+1,
        DAw_MCAST_TREE= DAw_MCAST_FATTREE; 
    /*********************
    *  STAR
    *******************/
    localparam 
        ROUTE_TYPE_STAR = "DETERMINISTIC",
        NE_STAR = T1,  //total number of endpoints
        NR_STAR = 1,  // total number of routers  
        RAw_STAR = 1,
        EAw_STAR  =  log2(NE_STAR),
        DSTPw_STAR = (CAST_TYPE!= "UNICAST")? NE_STAR :EAw_STAR,
        MAX_P_STAR = NE_STAR,
        DAw_MCAST_STAR= NE_STAR;            
    /************************
    *  CUSTOM - made by netmaker
    ***********************/
    localparam 
        ROUTE_TYPE_CUSTOM = "DETERMINISTIC",
        NE_CUSTOM  = T1,  //total number of endpoints
        NR_CUSTOM  = T2,  // total number of routers  
        EAw_CUSTOM = log2(NE_CUSTOM),
        RAw_CUSTOM = log2(NR_CUSTOM),
        MAX_P_CUSTOM = T3,
        DSTPw_CUSTOM = log2(MAX_P_CUSTOM);
    /* verilator lint_off WIDTH */ 
    localparam
        PPSw = PPSw_MESH_TORI,    
        // maximum number of port in a router in the topology
        MAX_P =
            (TOPOLOGY == "FATTREE")? MAX_P_FATTREE:
            (TOPOLOGY == "TREE")?  MAX_P_TREE:
            (TOPOLOGY == "RING" || TOPOLOGY == "LINE" || TOPOLOGY == "MESH" || TOPOLOGY == "TORUS")? MAX_P_MESH_TORI:
            (TOPOLOGY == "FMESH")? MAX_P_MESH_TORI:
            (TOPOLOGY == "STAR") ? MAX_P_STAR:
            MAX_P_CUSTOM, 
        // destination port width in header flit           
        DSTPw =
           // Each asserted bit indicats that the flit should be sent to that port
            (TOPOLOGY == "FATTREE")? DSTPw_FATTREE:
            (TOPOLOGY == "TREE")?  DSTPw_TREE:
            (CAST_TYPE!= "UNICAST")? MAX_P: 
            (TOPOLOGY == "RING" || TOPOLOGY == "LINE" || TOPOLOGY == "MESH" || TOPOLOGY == "TORUS")? DSTPw_MESH_TORI:
            (TOPOLOGY == "FMESH")? DSTPw_MESH_TORI:
            (TOPOLOGY == "STAR") ? DSTPw_STAR:
            DSTPw_CUSTOM,
        //router address width        
        RAw =
            (TOPOLOGY == "FATTREE")? RAw_FATTREE:
            (TOPOLOGY == "TREE")?  RAw_TREE:
            (TOPOLOGY == "RING" || TOPOLOGY == "LINE" || TOPOLOGY == "MESH" || TOPOLOGY == "TORUS")? RAw_MESH_TORI:
            (TOPOLOGY == "FMESH")? RAw_MESH_TORI:
            (TOPOLOGY == "STAR") ? RAw_STAR:
            RAw_CUSTOM,
        //endpoint address width
        EAw =
            (TOPOLOGY == "FATTREE")? EAw_FATTREE:
            (TOPOLOGY == "TREE")?  EAw_TREE:
            (TOPOLOGY == "RING" || TOPOLOGY == "LINE" || TOPOLOGY == "MESH" || TOPOLOGY == "TORUS")? EAw_MESH_TORI:
            (TOPOLOGY == "FMESH")? EAw_FMESH:
            (TOPOLOGY == "STAR") ? EAw_STAR:
            EAw_CUSTOM,           
        // total number of endpoints         
        NE =
            (TOPOLOGY == "FATTREE")? NE_FATTREE:
            (TOPOLOGY == "TREE")?  NE_TREE:
            (TOPOLOGY == "RING" || TOPOLOGY == "LINE" || TOPOLOGY == "MESH" || TOPOLOGY == "TORUS")? NE_MESH_TORI:
            (TOPOLOGY == "FMESH")? NE_FMESH: 
            (TOPOLOGY == "STAR")? NE_STAR:
            NE_CUSTOM,
            
       //Destination endpoint(s) address width
        DAw_OFFSETw  =  (TOPOLOGY=="MESH" || TOPOLOGY=="TORUS" ||  TOPOLOGY=="FMESH")?  NX : 0, 
        MCAST_PRTLw = mcast_partial_width( MCAST_ENDP_LIST),
        MCASTw =
            (CAST_TYPE == "MULTICAST_FULL") ? NE :
            (CAST_TYPE == "MULTICAST_PARTIAL" && EAw >= MCAST_PRTLw) ? EAw +1 : 
            (CAST_TYPE == "MULTICAST_PARTIAL" && EAw <  MCAST_PRTLw) ? MCAST_PRTLw +1 :
            EAw +1, //broadcast
        DAw =  
            (CAST_TYPE == "UNICAST") ?   EAw:
            MCASTw +  DAw_OFFSETw,            
        //total number of routers        
        NR =
            (TOPOLOGY == "FATTREE")? NR_FATTREE:
            (TOPOLOGY == "TREE")?  NR_TREE:
            (TOPOLOGY == "RING" || TOPOLOGY == "LINE" || TOPOLOGY == "MESH" || TOPOLOGY == "TORUS")? NR_MESH_TORI:  
            (TOPOLOGY == "FMESH")? NR_FMESH: 
            (TOPOLOGY == "STAR") ? NR_STAR:
            NR_CUSTOM, 
        //routing algorithm type    
        ROUTE_TYPE =
            (TOPOLOGY == "FATTREE")? ROUTE_TYPE_FATTREE:
            (TOPOLOGY == "TREE")?  ROUTE_TYPE_TREE:
            (TOPOLOGY == "RING" || TOPOLOGY == "LINE" || TOPOLOGY == "MESH" || TOPOLOGY == "TORUS")? ROUTE_TYPE_MESH_TORI:
            (TOPOLOGY == "FMESH")? ROUTE_TYPE_MESH_TORI:
            (TOPOLOGY == "STAR") ? ROUTE_TYPE_STAR:
            ROUTE_TYPE_CUSTOM;
    /* verilator lint_on WIDTH */         
    function automatic integer mcast_id_to_endp_id;
    input integer  mcast_id;
    reg [NE-1 : 0] mcast_list;
    integer  k;
    begin
        mcast_list =MCAST_ENDP_LIST;
        mcast_id_to_endp_id=0;
        k=0;
        /* verilator lint_off WIDTH */ 
        if (CAST_TYPE == "MULTICAST_FULL")begin 
        /* verilator lint_on WIDTH */ 
            mcast_id_to_endp_id =mcast_id;
        end else begin
            while( k!=mcast_id+1) begin              
                if( mcast_list[mcast_id_to_endp_id]==1'b1) begin 
                    k=k+1;            
                end
                mcast_id_to_endp_id= mcast_id_to_endp_id+1;       
            end
        end
    end
    endfunction
    
    function automatic integer endp_id_to_mcast_id;
    input integer  endp_id;
    reg [NE-1 : 0] mcast_list;
    integer i;       
    begin
         /* verilator lint_off WIDTH */ 
        if (CAST_TYPE == "MULTICAST_FULL") begin
         /* verilator lint_on WIDTH */ 
            endp_id_to_mcast_id = endp_id;
        end else begin
            mcast_list =MCAST_ENDP_LIST;
            endp_id_to_mcast_id=0;
            for (i=0;i<endp_id;i=i+1) begin 
                if( mcast_list[i]==1'b1) endp_id_to_mcast_id=endp_id_to_mcast_id+1;
            end
            end
    end
    endfunction  
    
    function automatic integer mcast_partial_width;
    input [NE-1 : 0] p;
    integer i;      
    begin 
        mcast_partial_width=0;
        for (i=0;i<NE;i=i+1) begin
            if (p [i]==1'b1) mcast_partial_width=mcast_partial_width+1;
        end
    end   
    endfunction    
    
    function automatic  integer fmesh_addrencode; 
    input integer in;
    integer  y, x, l,p, diff,mul;
    begin
        mul  = NX*NY*NL;            
        if(in < mul) begin 
            y = ((in/NL) / NX ); 
            x = ((in/NL) % NX ); 
            l = (in % NL); 
            p = (l==0)? LOCAL : 4+l;            
        end else begin      
            diff = in -  mul ;
            if( diff <  NX) begin //top mesh edge 
                y = 0;
                x = diff;
                p = NORTH;
            end else if  ( diff < 2* NX) begin //bottom mesh edge 
                y = NY-1;
                x = diff-NX;
                p = SOUTH;
            end else if  ( diff < (2* NX)+NY ) begin //left mesh edge 
                y = diff - (2* NX);
                x = 0;
                p = WEST;
            end else begin //right mesh edge 
                y = diff - (2* NX) -NY;
                x = NX-1;
                p = EAST; 
            end
        end//else 
            fmesh_addrencode = ( p<<(NXw+NYw) | (y<<NXw) | x);      
    end   
    endfunction // addrencode    
    
    function automatic  integer fmesh_router_id; 
    input integer x,y;
    begin
        fmesh_router_id=((y * NX) +  x);
    end
    endfunction
    
    function automatic  integer fmesh_endp_id; 
    input integer x,y,l;
    begin
        fmesh_endp_id=((y * NX) + x) * NL + l ;
    end
    endfunction
    
    `ifdef SIMULATION
    /* verilator lint_off WIDTH */
    task display_noc_parameters;  
    begin
        //print_parameter 
        $display ("NoC parameters:----------------");
        $display ("\tTopology: %s",TOPOLOGY);
        $display ("\tRouting algorithm: %s",ROUTE_NAME);
        $display ("\tVC_per port: %0d", V);
        $display ("\tNon-local port buffer_width per VC: %0d", B);
        $display ("\tLocal port buffer_width per VC: %0d", LB);
        if(TOPOLOGY=="MESH" || TOPOLOGY=="TORUS" || TOPOLOGY == "FMESH")begin
            $display ("\tRouter num in row: %0d",T1);
            $display ("\tRouter num in column: %0d",T2);
            $display ("\tEndpoint num per router: %0d",T3);
        end else if (TOPOLOGY=="RING" || TOPOLOGY == "LINE") begin
            $display ("\tTotal Router num: %0d",T1);
            $display ("\tEndpoint num per router: %0d",T3);
        end else if (TOPOLOGY == "TREE" ||  TOPOLOGY == "FATTREE")begin
            $display ("\tK: %0d",T1);
            $display ("\tL: %0d",T2);
        end else begin //CUSTOM
            $display ("\tTotal Endpoints number: %0d",T1);
            $display ("\tTotal Routers number: %0d",T2);
        end
        $display ("\tNumber of Class: %0d", C);
        $display ("\tFlit data width: %0d", Fpay);
        $display ("\tVC reallocation mechanism: %s",  VC_REALLOCATION_TYPE);
        $display ("\tVC/sw combination mechanism: %s", COMBINATION_TYPE);
        $display ("\tAVC_ATOMIC_EN:%0d", AVC_ATOMIC_EN);
        $display ("\tCongestion Index:%0d",CONGESTION_INDEX);
        $display ("\tADD_PIPREG_AFTER_CROSSBAR:%0d",ADD_PIPREG_AFTER_CROSSBAR);
        $display ("\tSSA_EN enabled:%s",SSA_EN);
        $display ("\tSwitch allocator arbitration type:%s",SWA_ARBITER_TYPE);
        $display ("\tMinimum supported packet size:%0d flit(s)",MIN_PCK_SIZE);
        $display ("\tLoop back is enabled:%s",SELF_LOOP_EN);
        $display ("\tNumber of multihop bypass (SMART max):%0d",SMART_MAX);
        $display ("\tCastying type:%s.",CAST_TYPE);
        if (CAST_TYPE == "MULTICAST_PARTIAL" || CAST_TYPE == "BROADCAST_PARTIAL")begin
            $display ("\tNumber of nodes in Cast list:%d",   MCAST_PRTLw);
            $display ("\tCAST LIST:%b", MCAST_ENDP_LIST);
        end 
        $display ("NoC parameters:----------------");
    end
    endtask
    /* verilator lint_on WIDTH */
    `endif //SIMULATION
`endif