`include "pronoc_def.v"
/**************************************
 * Module: router_bypass
 * Date:2021-11-14  
 * Author: alireza     
 *
 * Description: 
 *   This file contains HDL modules that can be added
 *   to NoC router to provide multicasting
 ***************************************/

/************************************
*     look_ahead_routing
*************************************/
module multicast_routing # (
    parameter NOC_ID=0,
    parameter SW_LOC=0,    
    parameter P=5
)(
    current_r_addr,  //current router  address
    dest_e_addr,  // destination endpoint address        
    destport        
);
    `NOC_CONF    
    input   [RAw-1 : 0]  current_r_addr;
    input   [DAw-1 : 0]  dest_e_addr;
    output  [DSTPw-1 : 0] destport;
    generate
    /* verilator lint_off WIDTH */    
    if(TOPOLOGY=="MESH") begin: mesh
    /* verilator lint_on WIDTH */    
        multicast_routing_mesh #(
            .NOC_ID(NOC_ID),
            .P(P) ,
            .SW_LOC(SW_LOC)        
        ) routing (
            .current_r_addr(current_r_addr),  //current router  address
            .dest_e_addr(dest_e_addr),  // destination endpoint address        
            .destport(destport)        
        );
    /* verilator lint_off WIDTH */    
    end else if (TOPOLOGY == "FMESH") begin : fmesh 
    /* verilator lint_on WIDTH */
        multicast_routing_fmesh #(
            .NOC_ID(NOC_ID),
            .P(P) ,
            .SW_LOC(SW_LOC)        
        ) routing (
            .current_r_addr(current_r_addr),  //current router  address
            .dest_e_addr(dest_e_addr),  // destination endpoint address        
            .destport(destport)        
        );
    /* verilator lint_off WIDTH */    
    end else if (TOPOLOGY == "STAR") begin : star
    /* verilator lint_on WIDTH */
        multicast_routing_star #(
            .NOC_ID(NOC_ID),
            .P(P) ,
            .SW_LOC(SW_LOC)        
        ) routing (
            .current_r_addr(current_r_addr),  //current router  address
            .dest_e_addr(dest_e_addr),  // destination endpoint address        
            .destport(destport)        
        );
    end 
    `ifdef SIMULATION
    else begin 
        initial begin 
            $display ("ERROR: Multicast/Broadcast is not yet supported for %s Topology",TOPOLOGY);
            $finish;
        end
    end
    `endif
    endgenerate
endmodule


module multicast_routing_mesh    #(
    parameter NOC_ID=0,
    parameter SW_LOC=0,   
    parameter P=5
)(
    current_r_addr,  //current router  address
    dest_e_addr,  // destination endpoint address        
    destport        
);   
    
    `NOC_CONF
    
    input   [RAw-1 : 0]  current_r_addr;
    input   [DAw-1 : 0]  dest_e_addr;
    output  [DSTPw-1 : 0] destport;
    
    localparam
        RXw = log2(NX),   
        RYw = log2(NY),  
        EXw = RXw,
        EYw = RYw;
    
    //mask gen. x_plus: all rows larger than current router x address are asserted.
    wire [NX-1 : 0] x_plus,x_minus;
    //mask generation. Only the corresponding bits to destination located in current column are asserted in each mask     
    wire [NE-1 : 0] y_plus,y_min;
    //Only one-bit is asserted for each local_p[i]
    wire [NE-1 : 0] local_p [NL-1 : 0];
    wire   [RXw-1 : 0]  current_rx;
    wire   [RYw-1 : 0]  current_ry;                  
    mesh_tori_router_addr_decode #(
        .TOPOLOGY(TOPOLOGY),
        .T1(T1),
        .T2(T2),
        .T3(T3),
        .RAw(RAw)
    ) router_addr_decode (
        .r_addr(current_r_addr),
        .rx(current_rx),
        .ry(current_ry),
        .valid( )
    );
    wire [NX-1 : 0] row_has_any_dest;
    wire [NE-1 : 0] dest_mcast_all_endp;            
    mcast_dest_list_decode #(
        .NOC_ID(NOC_ID)
    ) decode (
        .dest_e_addr(dest_e_addr),
        .dest_o(dest_mcast_all_endp),
        .row_has_any_dest(row_has_any_dest),
        .is_unicast()
    );
    genvar i,j;
    generate 
    for(i=0; i< NX; i=i+1) begin : X_
        assign x_plus[i]  = (current_rx    >    i);
        /* verilator lint_off UNSIGNED */
        assign x_minus[i] = (current_rx    <    i);
        /* verilator lint_on UNSIGNED */
    end
    //get all endp addresses located in the same x
    for(i=0; i< NE; i=i+1) begin : endpoints
        //Endpoint decoded address
        localparam                        
            Y_LOC = ((i/NL) / NX ), 
            X_LOC = ((i/NL) % NX ), 
            LL = (i % NL);
        localparam [RYw-1 : 0] YY = Y_LOC [RYw-1 : 0];
        localparam [RXw-1 : 0] XX = X_LOC [RXw-1 : 0];
        /* verilator lint_off CMPCONST */
        assign y_plus[i]  = (current_rx    ==    XX) && (current_ry >  YY);
        /* verilator lint_on CMPCONST */
        /* verilator lint_off UNSIGNED */
        assign y_min[i]   = (current_rx    ==    XX) && (current_ry <  YY);
        /* verilator lint_on UNSIGNED */
        for(j=0;j<NL;j++)begin : lp
            assign local_p[j][i] = (current_rx    ==    XX) && (current_ry == YY) && (LL == j);
        end //j       
    end //i    
    wire goto_north = |(y_plus  & dest_mcast_all_endp);
    wire goto_south = |(y_min   & dest_mcast_all_endp);
    wire goto_east  = |(x_minus & row_has_any_dest);
    wire goto_west  = |(x_plus  & row_has_any_dest);
    wire [NL-1 : 0] goto_local;
    for(i=0; i< NL; i=i+1) begin : endps
        assign goto_local[i] = |(local_p[i] & dest_mcast_all_endp);// will be synthesized as single bit assign
    end//for
    reg [4 : 0] destport_tmp;
    always @(*) begin 
        destport_tmp = {5{1'b0}};
        destport_tmp[LOCAL]=goto_local[LOCAL];                
        if     (SW_LOC == SOUTH) destport_tmp [NORTH] = goto_north;
        else if(SW_LOC == NORTH) destport_tmp [SOUTH] = goto_south;
        else if(SW_LOC == WEST)begin 
            destport_tmp [NORTH] = goto_north;
            destport_tmp [SOUTH] = goto_south;
            destport_tmp [EAST ] = goto_east;                    
        end
        else if(SW_LOC == EAST) begin 
            destport_tmp [NORTH] = goto_north;
            destport_tmp [SOUTH] = goto_south;
            destport_tmp [WEST ] = goto_west;                    
        end
        else if(SW_LOC == LOCAL || SW_LOC > SOUTH) begin
            destport_tmp [NORTH] = goto_north;
            destport_tmp [SOUTH] = goto_south;
            destport_tmp [EAST]  = goto_east;
            destport_tmp [WEST]  = goto_west;
        end                            
    end
    localparam MSB_DSTP = (DSTPw-1 < SOUTH)? DSTPw-1: SOUTH;
    assign destport [MSB_DSTP : 0] =destport_tmp;
    for(i=1;i<NL;i++) begin :other_local
        assign destport[MSB_DSTP+i]=goto_local[i];            
    end    
    endgenerate
endmodule

module multicast_routing_star #(
    parameter NOC_ID=0,
    parameter SW_LOC=0,    
    parameter P=5
)(
    current_r_addr,  //current router  address
    dest_e_addr,  // destination endpoint address        
    destport        
);
    `NOC_CONF
    input   [RAw-1 : 0]  current_r_addr;
    input   [DAw-1 : 0]  dest_e_addr;
    output  [DSTPw-1 : 0]  destport;
    
    mcast_dest_list_decode # (
        .NOC_ID(NOC_ID)
    ) decode (
        .dest_e_addr(dest_e_addr),
        .dest_o(destport),
        .row_has_any_dest(),
        .is_unicast()
    );
endmodule


module multicast_routing_fmesh #(
    parameter NOC_ID=0,
    parameter SW_LOC=0,    
    parameter P=5
) (
    current_r_addr,  //current router  address
    dest_e_addr,  // destination endpoint address        
    destport        
);
    
    `NOC_CONF
    input   [RAw-1 : 0]  current_r_addr;
    input   [DAw-1 : 0]  dest_e_addr;
    output  [DSTPw-1 : 0]  destport;
    localparam Pw = log2(MAX_P_FMESH);
    
    localparam        
        RXw = log2(NX),   
        RYw = log2(NY),  
        EXw = RXw,
        EYw = RYw;
    wire   [RXw-1 : 0]  current_rx;
    wire   [RYw-1 : 0]  current_ry;   
    //mask gen. x_plus: all rows larger than current router x address are asserted.
    wire [NX-1 : 0] x_plus,x_minus;
    //mask generation. Only the corresponding bits to destination located in current column are asserted in each mask     
    wire [NE-1 : 0] y_plus,y_min;
    //Only one-bit is asserted for each local_p[i]
    wire [NE-1 : 0] local_p [MAX_P_FMESH-1 : 0];
    mesh_tori_router_addr_decode #(
        .TOPOLOGY(TOPOLOGY),
        .T1(T1),
        .T2(T2),
        .T3(T3),
        .RAw(RAw)
    )router_addr_decode(
        .r_addr(current_r_addr),
        .rx(current_rx),
        .ry(current_ry),
        .valid( )
    );
    
    wire [NX-1 : 0] row_has_any_dest;
    wire [NE-1 : 0] dest_mcast_all_endp;            
        
    mcast_dest_list_decode # (
        .NOC_ID(NOC_ID)
    ) decode (
        .dest_e_addr(dest_e_addr),
        .dest_o(dest_mcast_all_endp),
        .row_has_any_dest(row_has_any_dest),
        .is_unicast()
    );
    
    genvar i,j;
    generate 
    for(i=0; i< NX; i=i+1) begin : X_
        assign x_plus[i]  = (current_rx    >    i);
        /* verilator lint_off UNSIGNED */
        assign x_minus[i] = (current_rx    <    i);
        /* verilator lint_on UNSIGNED */
    end
    //get all endp addresses located in the same x
    for(i=0; i< NE; i=i+1) begin : endpoints
        //Endpoint decoded address
        localparam 
            ADR = fmesh_addrencode(i),            
            XX = ADR [NXw -1 : 0],
            YY = ADR [NXw+NYw-1 : NXw], 
            PP = ADR [NXw+NYw+Pw-1 : NXw+NYw];             
        /* verilator lint_off CMPCONST */
        assign y_plus[i]  = (current_rx    ==    XX) && (current_ry >  YY);
        /* verilator lint_on CMPCONST */
        /* verilator lint_off UNSIGNED */
        assign y_min[i]   = (current_rx    ==    XX) && (current_ry <  YY);
        /* verilator lint_on UNSIGNED */
        for(j=0;j<MAX_P_FMESH;j++)begin : lp
            assign local_p[j][i] = (current_rx    ==    XX) && (current_ry == YY) && (PP == j);
        end        
    end//for ne
    wire [MAX_P_FMESH-1 : 0] goto_local;
    for(i=0; i<MAX_P_FMESH ; i=i+1) begin : endps
        assign goto_local[i] = |(local_p[i] & dest_mcast_all_endp);// will be synthesized as single bit assign
    end//for    
    
    wire goto_north = (|(y_plus  & dest_mcast_all_endp)) | goto_local[NORTH];
    wire goto_south = (|(y_min   & dest_mcast_all_endp)) | goto_local[SOUTH];
    wire goto_east  = (|(x_minus & row_has_any_dest))    | goto_local[EAST];
    wire goto_west  = (|(x_plus  & row_has_any_dest))    | goto_local[WEST];
    
    reg [4 : 0] destport_tmp;
    always @(*) begin 
        destport_tmp = {DSTPw{1'b0}};
        destport_tmp[LOCAL]=goto_local[LOCAL];                
        if     (SW_LOC == SOUTH)begin 
            destport_tmp [NORTH] = goto_north ;
            destport_tmp [EAST]  = goto_east;
            destport_tmp [WEST]  = goto_west;
        end
        else if(SW_LOC == NORTH) begin 
            destport_tmp [SOUTH] = goto_south ;
            destport_tmp [EAST]  = goto_east;
            destport_tmp [WEST]  = goto_west;
        end
        else if(SW_LOC == WEST)begin 
            destport_tmp [NORTH] = goto_north ;
            destport_tmp [SOUTH] = goto_south;
            destport_tmp [EAST ] = goto_east;                    
        end
        else if(SW_LOC == EAST) begin 
            destport_tmp [NORTH] = goto_north;
            destport_tmp [SOUTH] = goto_south;
            destport_tmp [WEST ] = goto_west;                    
        end
        else if(SW_LOC == LOCAL || SW_LOC > SOUTH) begin
            destport_tmp [NORTH] = goto_north;
            destport_tmp [SOUTH] = goto_south;
            destport_tmp [EAST]  = goto_east;
            destport_tmp [WEST]  = goto_west;
        end                            
    end
    localparam MSB_DSTP = (DSTPw-1 < SOUTH)? DSTPw-1: SOUTH;
    assign destport [MSB_DSTP : 0] =destport_tmp;
    for(i=1;i<NL;i++) begin :other_local
        assign destport[MSB_DSTP+i]=goto_local[i];            
    end        
    endgenerate    
endmodule


module mcast_dest_list_decode #(
    parameter NOC_ID=0
) (
    dest_e_addr,
    dest_o,
    row_has_any_dest,
    is_unicast
);
    
    `NOC_CONF
    input  [DAw-1 :0]  dest_e_addr;
    output [NE-1 : 0]  dest_o;
    output [NX-1 : 0] row_has_any_dest;
    output is_unicast;
    wire   [MCASTw-1 : 0] mcast_dst_coded;
    
    genvar i;
    generate
        /* verilator lint_off WIDTH */     
        if(TOPOLOGY == "STAR") begin :star
        /* verilator lint_on WIDTH */         
            assign mcast_dst_coded=dest_e_addr;
        end else begin :no_star
            assign {row_has_any_dest,mcast_dst_coded}=dest_e_addr;
        end
    /* verilator lint_off WIDTH */     
    if(CAST_TYPE == "MULTICAST_FULL") begin : full
    /* verilator lint_on WIDTH */ 
        assign dest_o = mcast_dst_coded;
        assign is_unicast = 1'b0;
    /* verilator lint_off WIDTH */     
    end else if (CAST_TYPE == "MULTICAST_PARTIAL") begin : partial
    /* verilator lint_on WIDTH */ 
        wire not_in_cast_list ;
        wire [EAw-1 : 0] unicast_code;
        assign {unicast_code,not_in_cast_list} = mcast_dst_coded  [EAw : 0];
        wire [NE-1 : 0]  dest_o_multi;
        reg  [NE-1 : 0]  dest_o_uni;
        wire [NEw-1 : 0] unicast_id;
        assign is_unicast = not_in_cast_list;
        endp_addr_decoder  #(
            .TOPOLOGY (TOPOLOGY),
            .T1(T1),
            .T2(T2),
            .T3(T3),
            .EAw(EAw),
            .NE(NE)
        )  decoder (
            .code(unicast_code),
            .id(unicast_id)                
        );            
        
        always @(*)begin 
            dest_o_uni = {NE{1'b0}};
            dest_o_uni[unicast_id]=1'b1;
        end
        
        for(i=0; i< NE; i=i+1) begin : endpoints
            localparam MCAST_ID = endp_id_to_mcast_id(i);
            assign dest_o_multi [i] = (MCAST_ENDP_LIST[i]==1'b1)? mcast_dst_coded[MCAST_ID+1] : 1'b0;                
        end
        assign dest_o = (not_in_cast_list)? dest_o_uni : dest_o_multi;
    /* verilator lint_off WIDTH */     
    end else if (CAST_TYPE == "BROADCAST_FULL") begin : bcast_full
    /* verilator lint_on WIDTH */ 
        wire not_broad_casted;
        wire [EAw-1 : 0] unicast_code;
        assign {unicast_code,not_broad_casted} = mcast_dst_coded;
        assign is_unicast =not_broad_casted;
        wire [NE-1 : 0]  dest_o_multi;
        reg  [NE-1 : 0]  dest_o_uni;
        wire [NEw-1 : 0] unicast_id;        
        endp_addr_decoder  #(
            .TOPOLOGY (TOPOLOGY),
            .T1(T1),
            .T2(T2),
            .T3(T3),
            .EAw(EAw),
            .NE(NE)
        ) decoder (
            .code(unicast_code),
            .id(unicast_id)                
        );            
        
        always @(*)begin 
            dest_o_uni = {NE{1'b0}};
            dest_o_uni[unicast_id]=1'b1;
        end
        
        assign dest_o = (not_broad_casted)? dest_o_uni : {NE{1'b1}};
    end else begin //BCAST_PARTIAL
        wire not_broad_casted;
        wire [EAw-1 : 0] unicast_code;
        assign {unicast_code,not_broad_casted} = mcast_dst_coded;
        assign is_unicast =not_broad_casted;
        wire [NE-1 : 0]  dest_o_multi;
        reg  [NE-1 : 0]  dest_o_uni;
        wire [NEw-1 : 0] unicast_id;
        
        endp_addr_decoder  #(
            .TOPOLOGY (TOPOLOGY),
            .T1(T1),
            .T2(T2),
            .T3(T3),
            .EAw(EAw),
            .NE(NE)
        ) decoder (
            .code(unicast_code),
            .id(unicast_id)                
        );            
        
        always @(*)begin 
            dest_o_uni = {NE{1'b0}};
            dest_o_uni[unicast_id]=1'b1;
        end
        assign dest_o = (not_broad_casted)? dest_o_uni : MCAST_ENDP_LIST;
    end
    endgenerate        
endmodule


module multicast_chan_in_process #(
    parameter NOC_ID=0,
    parameter SW_LOC=0,    
    parameter P=5
)(
    endp_port,
    current_r_addr,
    chan_in,
    chan_out,
    clk
);  
    
    `NOC_CONF
    input endp_port;
    input   [RAw-1 : 0]  current_r_addr;
    input   flit_chanel_t chan_in;
    input   clk;
    output  flit_chanel_t chan_out;
    
    wire  [MCASTw-1 : 0]  mcast_dst_coded;
    wire  [NE-1 : 0] dest_mcast_all_endp;
    wire  [NX-1 : 0] row_has_any_dest,row_has_any_dest_in;    
    wire  [DSTPw-1 : 0] destport,destport_o;    
    
    hdr_flit_t hdr_flit;
    header_flit_info #(
        .NOC_ID (NOC_ID)
    ) extract (
        .flit(chan_in.flit),
        .hdr_flit(hdr_flit),        
        .data_o()
    );
    
    mcast_dest_list_decode #(
        .NOC_ID(NOC_ID)
    ) decoder (
        .dest_e_addr(hdr_flit.dest_e_addr),
        .dest_o(dest_mcast_all_endp),
        .row_has_any_dest(row_has_any_dest_in),
        .is_unicast()
    );
    
    localparam MCASTw_= (MCASTw < DAw ) ? MCASTw : DAw;
    assign mcast_dst_coded = hdr_flit.dest_e_addr[MCASTw_-1:0];    
    wire [DAw-1 : 0] dest_e_addr;
    genvar i;
    generate 
    if(TOPOLOGY == "MESH") begin : mesh_
        assign  dest_e_addr = {row_has_any_dest,mcast_dst_coded};
        if(SW_LOC == LOCAL || SW_LOC > SOUTH) begin :endp
            wire [NE/NX-1 : 0] endp_mask [NX-1 : 0];        
            for(i=0; i< NE; i=i+1) begin : endpoints
                //Endpoint decoded address                
                localparam 
                    MCAST_ID = endp_id_to_mcast_id(i),
                    YY = ((i/NL) / NX ), 
                    XX = ((i/NL) % NX ), 
                    LL = (i % NL),
                    PP = YY*NL + LL;
                assign endp_mask [XX] [PP] = dest_mcast_all_endp [i];            
            end
            for(i=0;i<NX; i++) begin : X_
                assign row_has_any_dest[i] =| endp_mask[i];            
            end    
            reg   [DSTPw-1 : 0] destport_tmp;
            always @(*) begin 
                destport_tmp = destport;
                if(SELF_LOOP_EN   == "NO") destport_tmp [ SW_LOC ] = 1'b0; 
            end
            assign destport_o = destport_tmp;
        end else begin : no_endp
            assign  row_has_any_dest =      row_has_any_dest_in;
            assign  destport_o = destport;
        end
    end //mesh     
    /* verilator lint_off WIDTH */ 
    else if (TOPOLOGY == "FMESH" ) begin :fmesh_
    /* verilator lint_on WIDTH */ 
        assign  dest_e_addr = {row_has_any_dest,mcast_dst_coded};
        localparam MAX_ENDP_NUM_IN_SAME_ROW = NY * NL + NY + 2;
        localparam ENDP_NUM_IN_MIDLE_ROW = NY * NL + 2;
        localparam Pw = log2(MAX_P_FMESH);
        wire [NX-1 : 0] row_has_any_dest_endp_port;    
        wire [NY*NL-1 : 0] endp_mask [NX-1 : 0];        
        for(i=0; i< NE; i=i+1) begin : endpoints
            //Endpoint decoded address                
            localparam 
                ADR = fmesh_addrencode(i),                    
                XX = ADR [NXw -1 : 0],
                YY = ADR [NXw+NYw-1 : NXw], 
                PP = ADR [NXw+NYw+Pw-1 : NXw+NYw]; 
            if(PP == LOCAL || PP > SOUTH) begin 
                localparam MM = (PP==LOCAL) ? YY*NL : (YY*NL) + PP - SOUTH;
                assign endp_mask [XX] [MM] = dest_mcast_all_endp [i];
            end
        end
        wire [NX-1 : 0] north_endps;
        wire [NY-1 : 0] west_endps;
        wire [NX-1 : 0] south_endps;
        wire [NY-1 : 0] east_endps;
        assign {    east_endps,    west_endps ,south_endps ,north_endps}  = dest_mcast_all_endp [NE-1 : NY*NL*NX];
        
        for(i=0;i<NX; i++) begin : X_
            if(i==0) assign row_has_any_dest_endp_port[i] =(| endp_mask[i]) | ( |west_endps)  | north_endps[i] | south_endps[i];
            else if (i==NX-1) assign row_has_any_dest_endp_port[i] =(| endp_mask[i]) | ( |east_endps)  | north_endps[i] | south_endps[i];
            else assign row_has_any_dest_endp_port[i] =(| endp_mask[i]) |  north_endps[i] | south_endps[i];
        end    
        reg   [DSTPw-1 : 0] destport_tmp;
        always @(*) begin 
            destport_tmp = destport;
            if(SELF_LOOP_EN   == "NO") destport_tmp [ SW_LOC ] = 1'b0; 
        end
        assign  destport_o = (endp_port) ?    destport : destport_tmp ;
        assign  row_has_any_dest = (endp_port) ? row_has_any_dest_endp_port : row_has_any_dest_in;
    /* verilator lint_off WIDTH */ 
    end else if (TOPOLOGY == "STAR" ) begin :star_
    /* verilator lint_on WIDTH */ 
        assign  destport_o =    destport;
        assign  dest_e_addr =   mcast_dst_coded;
    end   
    
    multicast_routing
    #(
        .NOC_ID(NOC_ID),
        .P(P) ,
        .SW_LOC(SW_LOC)        
    )routing(
        .current_r_addr(current_r_addr),  //current router  address
        .dest_e_addr(dest_e_addr),  // destination endpoint address        
        .destport(destport)        
    );  
    always @(*) begin 
        chan_out=chan_in;
        if(chan_in.flit.hdr_flag == 1'b1) begin
            chan_out.flit [E_DST_MSB : E_DST_LSB] = dest_e_addr;
            chan_out.flit [DST_P_MSB : DST_P_LSB] = destport_o;                
        end
    end    
    `ifdef SIMULATION    
    if(DEBUG_EN) begin :debg
        always @(posedge clk) begin 
            /* verilator lint_off WIDTH */ 
            if(CAST_TYPE == "MULTICAST_FULL" || CAST_TYPE == "MULTICAST_PARTIAL")
            /* verilator lint_on WIDTH */ 
            if(chan_in.flit_wr  == 1'b1 && chan_in.flit.hdr_flag == 1'b1 && mcast_dst_coded == {MCASTw{1'b0}}) begin 
                $display ("%t: ERROR: A multicast packet is injected to the NoC with zero mcast_dst_coded filed %m ",$time);
                $finish;
            end
            
            if(chan_in.flit_wr  == 1'b1 && chan_in.flit.hdr_flag == 1'b1 && dest_mcast_all_endp == {NE{1'b0}}) begin 
                $display ("%t: ERROR: A multicast packet is injected to the NoC without any set destination %m ",$time);
                $finish;
            end
            if(chan_in.flit_wr  == 1'b1 && chan_in.flit.hdr_flag == 1'b1 && destport_o == {DSTPw{1'b0}}) begin 
                $display ("%t: ERROR: Routing module did not set any destination port for an injected multicast packet %m ",$time);
                $finish;
            end
        end
    end//debug
    `endif
    endgenerate
endmodule


module multicast_dst_sel # (
    parameter NOC_ID=0
)(
    destport_in,
    destport_out    
);
    `NOC_CONF
    input  [DSTPw-1 : 0] destport_in;
    output [DSTPw-1 : 0] destport_out; 
    wire  [DSTPw-1 : 0] arb_in, arb_out;
    
    function integer mesh_tori_pririty_order;
    input integer x;
    begin
        case(x)
            0 : mesh_tori_pririty_order = EAST;
            1 : mesh_tori_pririty_order = WEST;
            2 : mesh_tori_pririty_order = NORTH;
            3 : mesh_tori_pririty_order = SOUTH;
            4 : mesh_tori_pririty_order = LOCAL;    
            default : mesh_tori_pririty_order =x;
        endcase
    end
    endfunction // pririty_order
    
    function integer ring_lin_pririty_order;
    input integer x;
    begin
        case(x)
            0 : ring_lin_pririty_order = FORWARD;
            1 : ring_lin_pririty_order = BACKWARD;
            2 : ring_lin_pririty_order = LOCAL;                
            default : ring_lin_pririty_order =x;
        endcase
    end
    endfunction // pririty_order
    
    genvar i;
    generate 
    for (i=0; i<DSTPw;i++) begin : lp
        localparam PR = 
            /* verilator lint_off WIDTH */ 
            (TOPOLOGY == "MESH" || TOPOLOGY == "TORUS" || TOPOLOGY == "FMESH"  )?  mesh_tori_pririty_order(i):
            (TOPOLOGY == "RING" || TOPOLOGY == "LINE") ? ring_lin_pririty_order(i) : i;
            /* verilator lint_on WIDTH */                                
        assign arb_in[i] = destport_in[PR];
        assign destport_out [PR] = arb_out[i];
    end
    endgenerate
    
    fixed_priority_arbiter #(
        .ARBITER_WIDTH     (DSTPw), 
        .HIGH_PRORITY_BIT  ("LSB")
    ) fixed_priority_arbiter (
        .request           (arb_in), 
        .grant             (arb_out), 
        .any_grant         (   )
    );
endmodule