`include "pronoc_def.v"
/**************************************
* Module: debug
* Date:2019-04-01  
* Author: alireza     
*
* Description: this file contain modules which are used for error checking/debiging of the NoC. 
***************************************/

//check if flits are recived in correct order in a VC

module check_flit_chanel_type_is_in_order #(
    parameter V=4,
    parameter PCK_TYPE = "SINGLE_FLIT",
    parameter MIN_PCK_SIZE=2
)(
    hdr_flg_in,
    flit_in_wr,
    tail_flg_in,
    vc_num_in,    
    clk,
    reset 
);
    input clk, reset;
    input hdr_flg_in, tail_flg_in, flit_in_wr;
    input [V-1 : 0] vc_num_in;
    
    wire [V-1 : 0] vc_num_hdr_wr, vc_num_tail_wr,vc_num_bdy_wr ;
    wire [V-1 : 0] hdr_passed;
    reg  [V-1 : 0] hdr_passed_next;
    wire [V-1 : 0] single_flit_pck;
    
    assign  vc_num_hdr_wr =(hdr_flg_in & flit_in_wr) ?    vc_num_in : 0;
    assign  vc_num_tail_wr =(tail_flg_in & flit_in_wr)?    vc_num_in : 0;
    assign  vc_num_bdy_wr =({hdr_flg_in,tail_flg_in} == 2'b00 && flit_in_wr)?    vc_num_in : 0;
    assign  single_flit_pck = vc_num_hdr_wr & vc_num_tail_wr;
    always @(*)begin
        hdr_passed_next = (hdr_passed | vc_num_hdr_wr) & ~vc_num_tail_wr; 
    end
    
    `ifdef SIMULATION
    pronoc_register #(
        .W(V)          
    ) reg2 ( 
        .in(hdr_passed_next),
        .reset(reset),    
        .clk(clk),      
        .out(hdr_passed)
    );   
    always @ (posedge clk ) begin 
        if(( hdr_passed & vc_num_hdr_wr)>0  )begin 
            $display("%t ERROR: a header flit is received in  an active IVC %m",$time);               
            $finish;
        end
        if((~hdr_passed & vc_num_tail_wr & ~single_flit_pck )>0 ) begin 
            $display("%t ERROR: a tail flit is received in an inactive IVC %m",$time);                
            $finish;
        end                
        if ((~hdr_passed & vc_num_bdy_wr    )>0)begin 
            $display("%t ERROR: a body flit is received in an inactive IVC %m",$time);                
            $finish;
        end
        /* verilator lint_off WIDTH */
        if((PCK_TYPE == "SINGLE_FLIT") &  flit_in_wr & ~(hdr_flg_in &  tail_flg_in )) begin 
            $display("%t ERROR: both tail and header flit flags must be asserted in SINGLE_FLIT mode %m",$time);
            $finish;
        end 
        /* verilator lint_on WIDTH */
        if( (MIN_PCK_SIZE !=1) &  flit_in_wr & hdr_flg_in &  tail_flg_in ) begin 
            $display("%t ERROR: A single flit packet is injected while the minimum packet size is set to %d.  %m",$time,MIN_PCK_SIZE);
            $finish;
        end
        //TODO check that the injected packet size meets the MIN_PCK_SIZE            
    end//always
    `endif
endmodule


module debug_mesh_tori_route_ckeck #(
    parameter T1=4,
    parameter T2=4,
    parameter T3=4,
    parameter ROUTE_TYPE = "FULL_ADAPTIVE",
    parameter V=4,
    parameter AVC_ATOMIC_EN=1,
    parameter SW_LOC = 0,
    parameter [V-1 : 0] ESCAP_VC_MASK= 4'b0001,
    parameter TOPOLOGY="MESH",
    parameter DSTPw=4,
    parameter RAw=4,
    parameter EAw=4,
    parameter DAw=EAw
)(
    reset,
    clk,
    hdr_flg_in,
    flit_in_wr,
    flit_is_tail,
    ivc_num_getting_sw_grant,
    vc_num_in,
    current_r_addr,
    dest_e_addr_in,
    src_e_addr_in,
    destport_in  
);

    function integer log2;
    input integer number; begin   
        log2=(number <=1) ? 1: 0;    
        while(2**log2<number) begin    
            log2=log2+1;    
        end        
    end   
    endfunction // log2 
    
    input reset,clk;
    input hdr_flg_in , flit_in_wr;
    input [V-1 : 0] vc_num_in, flit_is_tail,  ivc_num_getting_sw_grant;
    input [RAw-1 : 0] current_r_addr;
    input [DAw-1 : 0] dest_e_addr_in;
    input [EAw-1 : 0] src_e_addr_in;
    input [DSTPw-1 : 0]  destport_in; 
    
    localparam
        NX = T1,
        NY = T2,
        RXw = log2(NX),    // number of node in x axis
        RYw = (TOPOLOGY=="RING" || TOPOLOGY == "LINE") ? 1 : log2(NY),
        EXw = log2(NX),    // number of node in x axis
        EYw = (TOPOLOGY=="RING" || TOPOLOGY == "LINE") ? 1 : log2(NY);   // number of node in y axis
    
    wire [RXw-1 : 0] current_x;
    wire [EXw-1 : 0] x_dst_in,x_src_in;
    wire [RYw-1 : 0] current_y;
    wire [EYw-1 : 0] y_dst_in,y_src_in;      
    
    mesh_tori_router_addr_decode #(
        .TOPOLOGY(TOPOLOGY),
        .T1(T1),
        .T2(T2),
        .T3(T3),
        .RAw(RAw)
    ) r_addr_decode  (
        .r_addr(current_r_addr),
        .rx(current_x),
        .ry(current_y),
        .valid()
    );
    
    mesh_tori_endp_addr_decode #(
        .TOPOLOGY(TOPOLOGY),
        .T1(T1),
        .T2(T2),
        .T3(T3),
        .EAw(EAw)
    ) dst_addr_decode (
        .e_addr(dest_e_addr_in),
        .ex(x_dst_in),
        .ey(y_dst_in),
        .el( ),
        .valid()
    );
    
    mesh_tori_endp_addr_decode #(
        .TOPOLOGY(TOPOLOGY),
        .T1(T1),
        .T2(T2),
        .T3(T3),
        .EAw(EAw)
    ) src_addr_decode  (
        .e_addr(src_e_addr_in),
        .ex(x_src_in),
        .ey(y_src_in),
        .el( ),
        .valid()
    );
    
    localparam  
        LOCAL =  0, 
        NORTH =  2,  
        SOUTH =  4; 

    `ifdef SIMULATION 
    generate
    /* verilator lint_off WIDTH */
    if(ROUTE_TYPE == "DETERMINISTIC")begin :dtrmn
    /* verilator lint_on WIDTH */  
        always@( posedge clk) begin 
            if(flit_in_wr & hdr_flg_in )   
                if( destport_in[1:0]==2'b11) begin 
                    $display ( "%t\t  ERROR: destport port %x is illegal for determistic routing.  %m",$time,destport_in );                   
                    $finish;
                end
            end//if
        end//always
    /* verilator lint_off WIDTH */
    if(ROUTE_TYPE == "FULL_ADAPTIVE") begin :full_adpt
    /* verilator lint_on WIDTH */    
        wire [V-1 : 0] not_empty;
        reg  [V-1 : 0] not_empty_next;
        pronoc_register #(
            .W(V)          
        ) reg2 ( 
            .in(not_empty_next),
            .reset(reset),    
            .clk(clk),      
            .out(not_empty)
        );
        always@(*) begin
            not_empty_next = not_empty;
            if(hdr_flg_in & flit_in_wr) begin
                not_empty_next = not_empty | vc_num_in;
            end//hdr_wr_in
            if((flit_is_tail & ivc_num_getting_sw_grant)>0)begin
                not_empty_next = not_empty & ~ivc_num_getting_sw_grant;
            end//tail wr out
        end//always
        always@( posedge clk ) begin
            if(hdr_flg_in & flit_in_wr) begin
                if( ((AVC_ATOMIC_EN==1)&& (SW_LOC!= LOCAL)) || (SW_LOC== NORTH) || (SW_LOC== SOUTH) )begin   
                    if((vc_num_in  & ~ESCAP_VC_MASK)>0) begin // adaptive VCs
                        if( (not_empty & vc_num_in)>0) $display("%t  :Error AVC allocated nonatomicly in %d port %m",$time,SW_LOC);
                    end
                end//( AVC_ATOMIC_EN || SW_LOC== NORTH || SW_LOC== SOUTH )
                if((vc_num_in  & ESCAP_VC_MASK)>0 && (SW_LOC== SOUTH || SW_LOC== NORTH) )  begin // escape vc
                    // if (a & b) $display("%t  :Error EVC allocation violate subfunction routing rules %m",$time);
                    if ((current_x - x_dst_in) !=0 && (current_y- y_dst_in) !=0) $display("%t  :Error EVC allocation violate subfunction routing rules src_x=%d src_y=%d dst_x%d   dst_y=%d %m",$time,x_src_in, y_src_in, x_dst_in,y_dst_in);
                end                     
            end//hdr_wr_in            
        end//always
    end 
    /* verilator lint_off WIDTH */ 
    if(TOPOLOGY=="MESH")begin :mesh
    /* verilator lint_on WIDTH */
        wire  [EXw-1 : 0] low_x,high_x;
        wire  [EYw-1 : 0] low_y,high_y;    
        assign low_x = (x_src_in < x_dst_in)?  x_src_in : x_dst_in;
        assign low_y = (y_src_in < y_dst_in)?  y_src_in : y_dst_in;
        assign high_x = (x_src_in < x_dst_in)?  x_dst_in : x_src_in;
        assign high_y = (y_src_in < y_dst_in)?  y_dst_in : y_src_in;
        always@( posedge clk)begin 
            if((current_x <low_x) | (current_x > high_x) | (current_y <low_y) | (current_y > high_y) )  begin
                if(flit_in_wr & hdr_flg_in )begin 
                    $display ( "%t\t  ERROR: non_minimal routing %m",$time );
                    $finish;
                end
            end
        end
    end// mesh  
    endgenerate
    `endif  
endmodule


module debug_mesh_edges #(
    parameter T1=2,
    parameter T2=2,
    parameter T3=3,
    parameter T4=3,
    parameter RAw=4,
    parameter P=5
)(
    clk,
    current_r_addr,
    flit_out_wr_all
);

    function integer log2;
    input integer number; begin   
        log2=(number <=1) ? 1: 0;    
        while(2**log2<number) begin    
            log2=log2+1;    
        end        
    end   
    endfunction // log2 
    input clk;
    input  [RAw-1 :  0]  current_r_addr;
    input  [P-1 :  0]  flit_out_wr_all;
    
    localparam 
        RXw = log2(T1),    // number of node in x axis
        RYw = log2(T2);    // number of node in y axis
    
    wire [RXw-1 : 0] current_rx;
    wire [RYw-1 : 0] current_ry;
    
    mesh_tori_router_addr_decode #(
        .TOPOLOGY("MESH"),
        .T1(T1),
        .T2(T2),
        .T3(T3),
        .RAw(RAw)
    ) addr_decode (
        .r_addr(current_r_addr),
        .rx(current_rx),
        .ry(current_ry),
        .valid()
    );
    
    localparam
        EAST = 1,
        NORTH = 2,
        WEST = 3,
        SOUTH = 4;
    `ifdef SIMULATION
    always @(posedge clk) begin 
    /* verilator lint_off WIDTH */ 
        if(current_rx == {RXw{1'b0}}         && flit_out_wr_all[WEST]) $display ( "%t\t  ERROR: a packet is going to the WEST in a router located in first column in mesh topology %m",$time ); 
        if(current_rx == T1-1     && flit_out_wr_all[EAST]) $display ( "%t\t   ERROR: a packet is going to the EAST in a router located in last column in mesh topology %m",$time ); 
        if(current_ry == {RYw{1'b0}}         && flit_out_wr_all[NORTH])$display ( "%t\t  ERROR: a packet is going to the NORTH in a router located in first row in mesh topology %m",$time ); 
        if(current_ry == T2-1    && flit_out_wr_all[SOUTH])$display ( "%t\t  ERROR: a packet is going to the SOUTH in a router located in last row in mesh topology %m",$time); 
    /* verilator lint_on WIDTH */ 
    end//always
    `endif  
endmodule


module check_destination_addr #(
    parameter NOC_ID=0,
    parameter TOPOLOGY = "MESH",
    parameter T1=2,
    parameter T2=2,
    parameter T3=2,
    parameter T4=2,
    parameter EAw=2,
    parameter DAw=2,
    parameter SELF_LOOP_EN=0,
    parameter CAST_TYPE = "UNICAST",
    parameter NE=8
)(
    dest_is_valid,
    dest_e_addr,
    current_e_addr
);

    input [DAw-1 : 0]  dest_e_addr;
    input [EAw-1 : 0]  current_e_addr;
    output dest_is_valid;
    // general rules
    /* verilator lint_off WIDTH */
    wire valid_dst  = (SELF_LOOP_EN == 0)? dest_e_addr  !=  current_e_addr : 1'b1;
    /* verilator lint_on WIDTH */
    wire valid;
    generate
    if(CAST_TYPE != "UNICAST") begin
        wire [NE-1 : 0] dest_mcast_all_endp;
        mcast_dest_list_decode #(
            .NOC_ID(NOC_ID)
        ) decode (
            .dest_e_addr(dest_e_addr),
            .dest_o(dest_mcast_all_endp),
            .row_has_any_dest( ),
            .is_unicast()
        );
        //wire valid_dst_multi_r1  = (SELF_LOOP_EN   == 0) ? ~(dest_mcast_all_endp[current_e_addr] == 1'b1) : 1'b1;
        wire valid_dst_multi_r2  = ~(dest_mcast_all_endp == {NE{1'b0}}); // there should be atleast one asserted destination
        assign  dest_is_valid =  valid_dst_multi_r2;// & valid_dst_multi_r1 ;  
    end else     
    /* verilator lint_off WIDTH */ 
    if(TOPOLOGY=="MESH" || TOPOLOGY == "TORUS" || TOPOLOGY=="RING" || TOPOLOGY == "LINE") begin : mesh        
   /* verilator lint_on WIDTH */ 
        mesh_tori_endp_addr_decode #(
            .TOPOLOGY(TOPOLOGY),
            .T1(T1),
            .T2(T2),
            .T3(T3),
            .EAw(EAw)
        ) mesh_tori_endp_addr_decode (
            .e_addr(dest_e_addr),
            .ex(),
            .ey(),
            .el(),
            .valid(valid)
        );
        assign  dest_is_valid = valid_dst & valid;
    end else begin : tree
        assign  dest_is_valid = valid_dst;    
    end
    endgenerate
endmodule


module  endp_addr_encoder #(
    parameter TOPOLOGY ="MESH",
    parameter T1=4,
    parameter T2=4,
    parameter T3=4,
    parameter EAw=4,
    parameter NE=16
)(
    id,
    code
);    

    function integer log2;
    input integer number; begin   
        log2=(number <=1) ? 1: 0;    
        while(2**log2<number) begin    
            log2=log2+1;    
        end        
    end   
    endfunction // log2 
    
    localparam NEw= log2(NE);
    
    input [NEw-1 :0] id;
    output [EAw-1 : 0] code;
    
    generate 
    /* verilator lint_off WIDTH */ 
    if(TOPOLOGY == "FATTREE" || TOPOLOGY == "TREE" ) begin : tree
    /* verilator lint_on WIDTH */ 
        fattree_addr_encoder #(
            .K(T1),
            .L(T2)
        ) addr_encoder (
        .id(id),
        .code(code)
        );
    /* verilator lint_off WIDTH */ 
    end else if  (TOPOLOGY == "MESH" || TOPOLOGY == "TORUS" || TOPOLOGY == "RING" || TOPOLOGY == "LINE") begin :tori
    /* verilator lint_on WIDTH */ 
        mesh_tori_addr_encoder #(
            .NX(T1),
            .NY(T2),
            .NL(T3),
            .NE(NE),
            .EAw(EAw),
            .TOPOLOGY(TOPOLOGY)
        )  addr_encoder  (
            .id(id),
            .code(code)
        );
    /* verilator lint_off WIDTH */ 
    end else if (TOPOLOGY == "FMESH") begin :fmesh
    /* verilator lint_on WIDTH */ 
        fmesh_addr_encoder #(
            .NX(T1),
            .NY(T2),
            .NL(T3),
            .NE(NE),
            .EAw(EAw)
        ) addr_encoder (
            .id(id),
            .code(code)
        );
    /* verilator lint_off WIDTH */ 
    end else if (TOPOLOGY == "MULTI_MESH") begin :mmesh
    /* verilator lint_on WIDTH */ 
        multimesh_address_encoder addr_encoder (
            .rid_in(id),
            .addr_st_o(code)
        );
    end else begin :custom
        assign code =id;
    end
    endgenerate
endmodule


module endp_addr_decoder  #(
    parameter TOPOLOGY ="MESH",
    parameter T1=4,
    parameter T2=4,
    parameter T3=4,
    parameter EAw=4,
    parameter NE=16
) (
    id,
    code
);

    function integer log2;
    input integer number; begin
        log2=(number <=1) ? 1: 0;
        while(2**log2<number) begin
            log2=log2+1;
        end
    end
    endfunction // log2 
    
    localparam NEw= log2(NE);
    output [NEw-1 :0] id;
    input  [EAw-1 : 0] code;
    generate 
    /* verilator lint_off WIDTH */ 
    if(TOPOLOGY == "FATTREE" || TOPOLOGY == "TREE" ) begin : tree
    /* verilator lint_on WIDTH */ 
        fattree_addr_decoder #(
            .K(T1),
            .L(T2)
        )decoder(
            .id(id),
            .code(code)
        );
    /* verilator lint_off WIDTH */     
    end else if  (TOPOLOGY == "MESH" || TOPOLOGY == "TORUS" || TOPOLOGY == "RING" || TOPOLOGY == "LINE") begin :tori
    /* verilator lint_on WIDTH */      
        mesh_tori_addr_coder #(
            .TOPOLOGY(TOPOLOGY),
            .NX    (T1   ), 
            .NY    (T2   ), 
            .NL    (T3   ), 
            .NE    (NE   ), 
            .EAw   (EAw  )
        ) addr_coder (
            .id    (id   ), 
            .code  (code )
        );
      /* verilator lint_off WIDTH */          
    end else if (TOPOLOGY == "FMESH") begin :fmesh
      /* verilator lint_on WIDTH */   
        fmesh_addr_coder #(
            .NX(T1),
            .NY(T2),
            .NL(T3),
            .NE(NE),
            .EAw(EAw)
        ) addr_coder (
            .id(id),
            .code(code)
        );
    /* verilator lint_off WIDTH */ 
    end else if (TOPOLOGY == "MULTI_MESH") begin 
    /* verilator lint_on WIDTH */ 
        multimesh_address_decoder addr_coder (
            .rid_out(id),
            .addr_st_i(code)
        );
    end else begin :custom
        assign id = code;
    end
    endgenerate
endmodule  


module check_pck_size #(
    parameter NOC_ID=0,
    parameter V=2,
    parameter MIN_PCK_SIZE=2,
    parameter Fw=36,
    parameter DAw=4,
    parameter CAST_TYPE="UNICAST",
    parameter NE=4,
    parameter B=4,
    parameter LB=4
)(
    hdr_flg_in,
    flit_in_wr,
    tail_flg_in,
    vc_num_in,  
    dest_e_addr_in,
    clk,
    reset  
);

    input clk, reset;
    input hdr_flg_in, tail_flg_in, flit_in_wr;
    input [V-1 : 0] vc_num_in;
    input [DAw-1: 0] dest_e_addr_in;
    wire [NE-1 : 0] dest_mcast_all_endp [V-1 : 0];
    wire [31 : 0] pck_size_counter [V-1: 0];
    reg  [31 : 0] pck_size_counter_next [V-1: 0];
    wire [DAw-1 : 0] dest_e_addr [V-1:0];
    wire [V-1 : 0] vc_hdr_wr_en;
    wire [V-1 : 0] onehot;
    localparam MIN_B =  (B<LB)? B : LB;       
    `ifdef SIMULATION
    genvar i;
    generate 
    for (i=0;i<V;i=i+1) begin :V_
        always @(*) begin 
            pck_size_counter_next [i] = pck_size_counter [i];
            if (vc_num_in == i)begin 
                if(flit_in_wr) begin  
                    if(hdr_flg_in) pck_size_counter_next[i]= 1;
                    else pck_size_counter_next[i]=pck_size_counter[i]+1;      
                end 
            end
        end     
        
        pronoc_register #(.W(32)) reg1(
            .in     (pck_size_counter_next[i]), 
            .reset  (reset ), 
            .clk    (clk   ), 
            .out    (pck_size_counter[i]   )
        );
        
        always @(posedge clk) begin 
            if (vc_num_in == i)begin 
                if(flit_in_wr & tail_flg_in) begin 
                    if( pck_size_counter_next[i] < MIN_PCK_SIZE) begin 
                        $display ( "%t\t  ERROR: A packet is injected to the router with packet size (%d flits) that is smaller than MIN_PCK_SIZE (%d flits) parameter  %m",$time,pck_size_counter_next[i],MIN_PCK_SIZE);
                        $finish;
                    end
                end       
            end
        end
        
        /* verilator lint_off WIDTH */   
        if(CAST_TYPE!="UNICAST") begin
        /* verilator lint_on WIDTH */   
        //Check that the size of multicast/broadcast packets <= buffer size
            assign vc_hdr_wr_en [i] = flit_in_wr & hdr_flg_in & (vc_num_in == i);
            pronoc_register_ld_en #(.W(DAw)) reg2(
                .in     (dest_e_addr_in), 
                .reset  (reset ), 
                .clk    (clk   ), 
                .ld     (vc_hdr_wr_en [i] ),
                .out    (dest_e_addr[i])
            );
            
            mcast_dest_list_decode #(
                .NOC_ID(NOC_ID)
            ) decode (
                .dest_e_addr(dest_e_addr[i]),
                .dest_o(dest_mcast_all_endp[i]),
                .row_has_any_dest(),
                .is_unicast()
            ); 
            
            is_onehot0 #(
                .IN_WIDTH(NE)    
            ) one_h (
                .in(dest_mcast_all_endp[i]),
                .result(onehot[i])
            );
            always @(posedge clk) begin 
                if (vc_num_in == i)begin 
                    if(flit_in_wr & ~onehot[i])begin 
                        if(pck_size_counter_next[i]>MIN_B) begin 
                            $display ( "%t\t  ERROR: A multicast packet is injected to the router with packet size (%d flits) that is larger than the minimum router buffer size (%d flits) parameter  %m",$time,pck_size_counter_next[i],MIN_B);
                            $finish;
                        end// size
                    end//flit_wr
                end//vc_num
            end//always
        end//multicast
    end  //for
    endgenerate
    `endif
endmodule
