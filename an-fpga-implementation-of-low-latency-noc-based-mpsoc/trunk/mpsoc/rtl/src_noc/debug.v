`timescale 1ns / 1ps

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
    reg  [V-1 : 0] hdr_passed, hdr_passed_next;
    wire [V-1 : 0] single_flit_pck;
    
    assign  vc_num_hdr_wr =(hdr_flg_in & flit_in_wr) ?    vc_num_in : 0;
    assign  vc_num_tail_wr =(tail_flg_in & flit_in_wr)?    vc_num_in : 0;
    assign  vc_num_bdy_wr =({hdr_flg_in,tail_flg_in} == 2'b00 && flit_in_wr)?    vc_num_in : 0;
    assign  single_flit_pck = vc_num_hdr_wr & vc_num_tail_wr;
    always @(*)begin
        hdr_passed_next = (hdr_passed | vc_num_hdr_wr) & ~vc_num_tail_wr; 
    end
    
    // synthesis translate_off
    always @ (posedge clk or posedge reset) begin 
        if(reset)  begin 
            hdr_passed <= 0;
            
        end else begin 
           
            hdr_passed     <= hdr_passed_next;
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
            
        end//else
    end//always
    // synthesis translate_on
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
    parameter EAw=4    
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
    input [EAw-1 : 0] dest_e_addr_in,src_e_addr_in;
    input [DSTPw-1 : 0]  destport_in; 
    
    localparam
      NX = T1,
      NY = T2,
      RXw = log2(NX),    // number of node in x axis
      RYw = log2(NY),
      EXw = log2(NX),    // number of node in x axis
      EYw = log2(NY);   // number of node in y axis
    
    
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
    )
    r_addr_decode
    (
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
    )
    dst_addr_decode
    (
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
    )
    src_addr_decode
    (
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
 // synthesis translate_off 
generate

/* verilator lint_off WIDTH */
if(ROUTE_TYPE == "DETERMINISTIC")begin :dtrmn
/* verilator lint_on WIDTH */  
    
   
    always@( posedge clk)begin 
        if(flit_in_wr & hdr_flg_in )   
               if( destport_in[1:0]==2'b11) begin 
                    $display ( "%t\t  ERROR: destport port %x is illegal for determistic routing.  %m",$time,destport_in );                   
                    $finish;
               end
        end//if
    end//always
    
    
/* verilator lint_off WIDTH */
if(ROUTE_TYPE == "FULL_ADAPTIVE")begin :full_adpt
/* verilator lint_on WIDTH */    
      
        reg [V-1 : 0] not_empty;
        always@( posedge clk or posedge reset) begin
            if(reset) begin
               not_empty <=0;
            end else begin 
               if(hdr_flg_in & flit_in_wr) begin
                    not_empty <= not_empty | vc_num_in;
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
                if((flit_is_tail & ivc_num_getting_sw_grant)>0)begin
                    not_empty <= not_empty & ~ivc_num_getting_sw_grant;
                end//tail wr out
            end//reset
        end//always
    end //SW_LOC


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
               if((current_x <low_x) | (current_x > high_x) | (current_y <low_y) | (current_y > high_y) )  
                    if(flit_in_wr & hdr_flg_in )begin 
                        $display ( "%t\t  ERROR: non_minimal routing %m",$time );
                        $finish;
                    end
                    
        end
           
    
    end// mesh  
  endgenerate
  
  // synthesis translate_on
  
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
    )
    addr_decode
    (
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
  // synthesis translate_off 
        always @(posedge clk) begin 
        /* verilator lint_off WIDTH */ 
                if(current_rx == {RXw{1'b0}}         && flit_out_wr_all[WEST]) $display ( "%t\t  ERROR: a packet is going to the WEST in a router located in first column in mesh topology %m",$time ); 
                if(current_rx == T1-1     && flit_out_wr_all[EAST]) $display ( "%t\t   ERROR: a packet is going to the EAST in a router located in last column in mesh topology %m",$time ); 
                if(current_ry == {RYw{1'b0}}         && flit_out_wr_all[NORTH])$display ( "%t\t  ERROR: a packet is going to the NORTH in a router located in first row in mesh topology %m",$time ); 
                if(current_ry == T2-1    && flit_out_wr_all[SOUTH])$display ( "%t\t  ERROR: a packet is going to the SOUTH in a router located in last row in mesh topology %m",$time); 
      /* verilator lint_on WIDTH */ 
        end//always
  // synthesis translate_on  
endmodule


/*******************
 * 
 * *****************/
 
 module check_destination_addr #(
    parameter TOPOLOGY = "MESH",
    parameter T1=2,
    parameter T2=2,
    parameter T3=2,
    parameter T4=2,
    parameter EAw=2,
    parameter SELF_LOOP_EN="NO"
 )(
     dest_is_valid,
     dest_e_addr,
     current_e_addr    
 );
 
    input [EAw-1 : 0]  dest_e_addr,current_e_addr;
    output dest_is_valid;
 
    // general rules
    /* verilator lint_off WIDTH */
    wire valid_dst  = (SELF_LOOP_EN   == "NO")? dest_e_addr  !=  current_e_addr : 1'b1;
    /* verilator lint_on WIDTH */
    wire valid;
    generate
    /* verilator lint_off WIDTH */ 
    if(TOPOLOGY=="MESH" || TOPOLOGY == "TORUS" || TOPOLOGY=="RING" || TOPOLOGY == "LINE") begin : mesh        
   /* verilator lint_on WIDTH */ 
        mesh_tori_endp_addr_decode #(
        	.TOPOLOGY(TOPOLOGY),
        	.T1(T1),
        	.T2(T2),
        	.T3(T3),
        	.EAw(EAw)
        )
        mesh_tori_endp_addr_decode(
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
)
(
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
       )
       addr_encoder
       (
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
        ) 
        addr_encoder
        (
            .id(id),
            .code(code)
        );
     end else if (TOPOLOGY == "FMESH") begin :fmesh
        fmesh_addr_encoder #(
            .NX(T1),
            .NY(T2),
            .NL(T3),
            .NE(NE),
            .EAw(EAw)
        )
        addr_encoder
        (
        .id(id),
        .code(code)
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
        )
        (
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
            .NX    (T1   ), 
            .NY    (T2   ), 
            .NL    (T3   ), 
            .NE    (NE   ), 
            .EAw   (EAw  )
            ) addr_coder (
            .id    (id   ), 
            .code  (code ));
     end else if (TOPOLOGY == "FMESH") begin :fmesh
        fmesh_addr_coder #(
            .NX(T1),
            .NY(T2),
            .NL(T3),
            .NE(NE),
            .EAw(EAw)
        )
        addr_coder
        (
        .id(id),
        .code(code)
        );
            
    end else begin :custom
     
        assign id = code;
     
    end
    endgenerate
endmodule  
  

