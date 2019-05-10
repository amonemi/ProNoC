
// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on


/**********************************************************************
**    File:  mesh_torus_noc.v
**    
**    Copyright (C) 2014-2017  Alireza Monemi
**    
**    This file is part of ProNoC 
**
**    ProNoC ( stands for Prototype Network-on-chip)  is free software: 
**    you can redistribute it and/or modify it under the terms of the GNU
**    Lesser General Public License as published by the Free Software Foundation,
**    either version 2 of the License, or (at your option) any later version.
**
**     ProNoC is distributed in the hope that it will be useful, but WITHOUT
**     ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
**     or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General
**     Public License for more details.
**
**     You should have received a copy of the GNU Lesser General Public
**     License along with ProNoC. If not, see <http:**www.gnu.org/licenses/>.
**
**
**    Description: 
**    the NoC top module. It generate one of the mesh, torus, ring, or line  topologies by 
**    connecting routers  
**
**************************************************************/




`define START_LOC(port_num,width)       (width*(port_num+1)-1)
`define END_LOC(port_num,width)            (width*port_num)
`define router_id(x,y)                         ((y * NX) +    x)
`define endp_id(x,y,l)                         ((y * NX) +    x) * NL + l 
`define SELECT_WIRE(x,y,port,width)    `router_id(x,y)] [`START_LOC(port,width) : `END_LOC(port,width )


module mesh_torus_noc_connection (
   
    reset,
    clk, 
    router_flit_out_all,
    router_flit_out_we_all,    
    router_credit_in_all,
    
    router_flit_in_all,
    router_flit_in_we_all,
    router_credit_out_all,                    
    router_congestion_in_all,    
    router_congestion_out_all,   
    
    ni_flit_in,   
    ni_flit_in_wr, 
    ni_credit_out,
    ni_flit_out,   
    ni_flit_out_wr,  
    ni_credit_in,
    start_i,      
    er_addr, 
    current_r_addr,
    start_o
   
);

  

                    
                      
       `define  INCLUDE_PARAM
    `include"parameter.v"          
                      
     `define INCLUDE_TOPOLOGY_LOCALPARAM
    `include "topology_localparam.v"
    

    localparam CONGw= (CONGESTION_INDEX==3)?  3:
                      (CONGESTION_INDEX==5)?  3:
                      (CONGESTION_INDEX==7)?  3:
                      (CONGESTION_INDEX==9)?  3:
                      (CONGESTION_INDEX==10)? 4:
                      (CONGESTION_INDEX==12)? 3:2;
                      
       
    localparam
        PV = V * MAX_P,
        Fw = 2+V+Fpay, //flit width;    
        PFw = MAX_P * Fw,
        NEFw = NE * Fw,
        NEV = NE * V,
        CONG_ALw = CONGw * MAX_P; // congestion width per router         
        
      
    
    input reset,clk;    
    
                  
                    
                    
                   
    output [PFw-1 : 0] router_flit_out_all [NR-1 :0];
    output [MAX_P-1 : 0] router_flit_out_we_all [NR-1 :0];    
    input [PV-1 : 0] router_credit_in_all [NR-1 :0];
    
    input [PFw-1 : 0] router_flit_in_all [NR-1 :0];
    input [MAX_P-1 : 0] router_flit_in_we_all [NR-1 :0];
    output [PV-1 : 0] router_credit_out_all [NR-1 :0];                    
    input [CONG_ALw-1: 0] router_congestion_in_all[NR-1 :0];    
    output [CONG_ALw-1: 0] router_congestion_out_all [NR-1 :0];   
    
    
    input [Fw-1 : 0] ni_flit_in [NE-1 :0];   
    input [NE-1 : 0] ni_flit_in_wr; 
    output [V-1 : 0] ni_credit_out [NE-1 :0];
    output [Fw-1 : 0] ni_flit_out [NE-1 :0];   
    output [NE-1 : 0] ni_flit_out_wr;  
    input [V-1 : 0] ni_credit_in [NE-1 :0];   


    input start_i;  
    
    output [RAw-1 : 0] er_addr [NE-1 : 0]; 
    output [RAw-1 : 0] current_r_addr [NR-1 : 0];

  
    output [NE-1 : 0] start_o;

     // mesh torus            
    localparam
        EAST   =       1, 
        NORTH  =       2,  
        WEST   =       3,  
        SOUTH  =       4;
    //ring line            
    localparam 
        FORWARD =  1,
        BACKWARD=  2;


genvar x,y,l;
generate 
    /* verilator lint_off WIDTH */ 
    if( TOPOLOGY == "RING" || TOPOLOGY == "LINE") begin : ring_line 
    /* verilator lint_on WIDTH */ 
        for  (x=0;   x<NX; x=x+1) begin :ring_loop
		/* verilator lint_off WIDTH */ 
            	localparam [RAw-1: 0] R_ADDR_1D =  x; 
		/* verilator lint_on WIDTH */ 
            	
    		assign current_r_addr [x] = R_ADDR_1D;                
 		        
        
            if(x    <   NX-1) begin: not_last_node
            
                assign  router_flit_out_all [`SELECT_WIRE(x,0,FORWARD,Fw)] = router_flit_in_all [`SELECT_WIRE((x+1),0,BACKWARD,Fw)];
                assign  router_credit_out_all [`SELECT_WIRE(x,0,FORWARD,V)] = router_credit_in_all [`SELECT_WIRE((x+1),0,BACKWARD,V)];
                assign  router_flit_out_we_all [x][FORWARD] = router_flit_in_we_all [`router_id((x+1),0)][BACKWARD];
                assign  router_congestion_out_all [`SELECT_WIRE(x,0,FORWARD,CONGw)]  = router_congestion_in_all [`SELECT_WIRE((x+1),0,BACKWARD,CONGw)];
            end else begin :last_node
                /* verilator lint_off WIDTH */ 
                if(TOPOLOGY == "LINE") begin : line_last_x
                /* verilator lint_on WIDTH */ 
                    assign  router_flit_out_all [`SELECT_WIRE(x,0,FORWARD,Fw)] = {Fw{1'b0}};
                    assign  router_credit_out_all [`SELECT_WIRE(x,0,FORWARD,V)] = {V{1'b0}};
                    assign  router_flit_out_we_all [x][FORWARD] = 1'b0;
                    assign  router_congestion_out_all [`SELECT_WIRE(x,0,FORWARD,CONGw)] = {CONGw{1'b0}};                
                end else begin : ring_last_x
                    assign  router_flit_out_all [`SELECT_WIRE(x,0,FORWARD,Fw)] =   router_flit_in_all [`SELECT_WIRE(0,0,BACKWARD,Fw)];
                    assign  router_credit_out_all [`SELECT_WIRE(x,0,FORWARD,V)] =   router_credit_in_all [`SELECT_WIRE(0,0,BACKWARD,V)];
                    assign  router_flit_out_we_all [x][FORWARD]  =   router_flit_in_we_all [`router_id(0,0)][BACKWARD];
                    assign  router_congestion_out_all [`SELECT_WIRE(x,0,FORWARD,CONGw)]  = router_congestion_in_all [`SELECT_WIRE(0,0,BACKWARD,CONGw)];
                end
            end 
            
            if(x>0)begin :not_first_x
                assign  router_flit_out_all [`SELECT_WIRE(x,0,BACKWARD,Fw)] = router_flit_in_all [`SELECT_WIRE((x-1),0,FORWARD,Fw)];
                assign  router_credit_out_all [`SELECT_WIRE(x,0,BACKWARD,V)] =  router_credit_in_all [`SELECT_WIRE((x-1),0,FORWARD,V)] ;
                assign  router_flit_out_we_all [x][BACKWARD] =   router_flit_in_we_all [`router_id((x-1),0)][FORWARD];
                assign  router_congestion_out_all[`SELECT_WIRE(x,0,BACKWARD,CONGw)] =   router_congestion_in_all [`SELECT_WIRE((x-1),0,FORWARD,CONGw)];
            end else begin :first_x
                /* verilator lint_off WIDTH */ 
                if(TOPOLOGY == "LINE") begin : line_first_x
                /* verilator lint_on WIDTH */ 
                    assign  router_flit_out_all [`SELECT_WIRE(x,0,BACKWARD,Fw)] = {Fw{1'b0}};
                    assign  router_credit_out_all [`SELECT_WIRE(x,0,BACKWARD,V)] = {V{1'b0}};
                    assign  router_flit_out_we_all [x][BACKWARD] = 1'b0;
                    assign  router_congestion_out_all[`SELECT_WIRE(x,0,BACKWARD,CONGw)] = {CONGw{1'b0}};
                 end else begin : ring_first_x
                    assign  router_flit_out_all [`SELECT_WIRE(x,0,BACKWARD,Fw)] = router_flit_in_all [`SELECT_WIRE((NX-1),0,FORWARD,Fw)] ;
                    assign  router_credit_out_all [`SELECT_WIRE(x,0,BACKWARD,V)] = router_credit_in_all [`SELECT_WIRE((NX-1),0,FORWARD,V)] ;
                    assign  router_flit_out_we_all [x][BACKWARD] = router_flit_in_we_all [`router_id((NX-1),0)][FORWARD];
                    assign  router_congestion_out_all[`SELECT_WIRE(x,0,BACKWARD,CONGw)] = router_congestion_in_all [`SELECT_WIRE((NX-1),0,FORWARD,CONGw)];
                end
            end            
            
            // connect local ports
            for  (l=0;   l<NL; l=l+1) begin :locals
                localparam ENDPID = `endp_id(x,0,l); 
                localparam LOCALP = (l==0) ? l : l + R2R_CHANNELS_MESH_TORI; // first local port is connected to router port 0. The rest are connected at the end  
                
		assign er_addr [ENDPID] = R_ADDR_1D;   

                assign router_flit_out_all [`SELECT_WIRE(x,0,LOCALP,Fw)] =    ni_flit_in [ENDPID];
                assign router_credit_out_all [`SELECT_WIRE(x,0,LOCALP,V)] =    ni_credit_in [ENDPID];
                assign router_flit_out_we_all [`router_id(x,0)][LOCALP] =    ni_flit_in_wr [ENDPID];
                assign router_congestion_out_all[`SELECT_WIRE(x,0,LOCALP,CONGw)] =   {CONGw{1'b0}};              
            
                assign ni_flit_out [ENDPID] = router_flit_in_all [`SELECT_WIRE(x,0,LOCALP,Fw)];
                assign ni_flit_out_wr [ENDPID] = router_flit_in_we_all[`router_id(x,0)][LOCALP];
                assign ni_credit_out [ENDPID] = router_credit_in_all [`SELECT_WIRE(x,0,LOCALP,V)];                             
                   
                          
                
            end// locals
            
                
       end//x    
    
    
    end else begin :mesh_torus
        for (y=0;    y<NY;    y=y+1) begin: y_loop
            for (x=0;    x<NX; x=x+1) begin :x_loop
	    /* verilator lint_off WIDTH */ 
            localparam [RAw-1: 0] R_ADDR = (y<<NXw) + x; 
            /* verilator lint_on WIDTH */ 
            localparam IP_NUM    =    (y * NX) +    x;
            
    /*
    in [x,y][east] <------  out [x+1 ,y  ][west] ;
    in [x,y][north] <------ out [x   ,y-1][south] ;
    in [x,y][west] <------  out [x-1 ,y  ][east] ;
    in [x,y][south] <------ out [x   ,y+1][north] ;
    */    
       
    		
    		assign current_r_addr [IP_NUM] = R_ADDR;
        
            if(x    <    NX-1) begin: not_last_x
                assign    router_flit_out_all [`SELECT_WIRE(x,y,EAST,Fw)] = router_flit_in_all [`SELECT_WIRE((x+1),y,WEST,Fw)];
                assign    router_credit_out_all [`SELECT_WIRE(x,y,EAST,V)] = router_credit_in_all [`SELECT_WIRE((x+1),y,WEST,V)];
                assign    router_flit_out_we_all [`router_id(x,y)][EAST] = router_flit_in_we_all [`router_id((x+1),y)][WEST];
                assign    router_congestion_out_all [`SELECT_WIRE(x,y,EAST,CONGw)]  = router_congestion_in_all [`SELECT_WIRE((x+1),y,WEST,CONGw)];
            end else begin :last_x
                /* verilator lint_off WIDTH */ 
                if(TOPOLOGY == "MESH") begin :last_x_mesh
                /* verilator lint_on WIDTH */ 
                    assign    router_flit_out_all [`SELECT_WIRE(x,y,EAST,Fw)] =    {Fw{1'b0}};
                    assign    router_credit_out_all [`SELECT_WIRE(x,y,EAST,V)] =    {V{1'b0}};
                    assign    router_flit_out_we_all [`router_id(x,y)][EAST] =    1'b0;
                    assign    router_congestion_out_all [`SELECT_WIRE(x,y,EAST,CONGw)]  = {CONGw{1'b0}};
                /* verilator lint_off WIDTH */ 
                end else if(TOPOLOGY == "TORUS") begin : last_x_torus
                /* verilator lint_on WIDTH */ 
                    assign    router_flit_out_all [`SELECT_WIRE(x,y,EAST,Fw)] =    router_flit_in_all [`SELECT_WIRE(0,y,WEST,Fw)];
                    assign    router_credit_out_all [`SELECT_WIRE(x,y,EAST,V)] =    router_credit_in_all [`SELECT_WIRE(0,y,WEST,V)];
                    assign    router_flit_out_we_all [`router_id(x,y)][EAST] =    router_flit_in_we_all [`router_id(0,y)][WEST];
                    assign    router_congestion_out_all [`SELECT_WIRE(x,y,EAST,CONGw)]  = router_congestion_in_all [`SELECT_WIRE(0,y,WEST,CONGw)];
                end //topology
            end 
            
        
            if(y>0) begin : not_first_y
                assign    router_flit_out_all [`SELECT_WIRE(x,y,NORTH,Fw)] =    router_flit_in_all [`SELECT_WIRE(x,(y-1),SOUTH,Fw)];
                assign    router_credit_out_all [`SELECT_WIRE(x,y,NORTH,V)] =  router_credit_in_all [`SELECT_WIRE(x,(y-1),SOUTH,V)];
                assign    router_flit_out_we_all [`router_id(x,y)][NORTH] =    router_flit_in_we_all [`router_id(x,(y-1))][SOUTH];
                assign    router_congestion_out_all [`SELECT_WIRE(x,y,NORTH,CONGw)]   =     router_congestion_in_all [`SELECT_WIRE(x,(y-1),SOUTH,CONGw)];
            end else begin :first_y
                /* verilator lint_off WIDTH */ 
                if(TOPOLOGY == "MESH") begin : first_y_mesh
                /* verilator lint_on WIDTH */ 
                    assign     router_flit_out_all [`SELECT_WIRE(x,y,NORTH,Fw)] =    {Fw{1'b0}};
                    assign    router_credit_out_all [`SELECT_WIRE(x,y,NORTH,V)] =    {V{1'b0}};
                    assign    router_flit_out_we_all [`router_id(x,y)][NORTH] =    1'b0;
                    assign    router_congestion_out_all [`SELECT_WIRE(x,y,NORTH,CONGw)]   =     {CONGw{1'b0}};
                /* verilator lint_off WIDTH */ 
                end else if(TOPOLOGY == "TORUS") begin :first_y_torus
                /* verilator lint_on WIDTH */ 
                    assign    router_flit_out_all [`SELECT_WIRE(x,y,NORTH,Fw)] =    router_flit_in_all [`SELECT_WIRE(x,(NY-1),SOUTH,Fw)];
                    assign    router_credit_out_all [`SELECT_WIRE(x,y,NORTH,V)] =  router_credit_in_all [`SELECT_WIRE(x,(NY-1),SOUTH,V)];
                    assign    router_flit_out_we_all [`router_id(x,y)][NORTH] =    router_flit_in_we_all [`router_id(x,(NY-1))][SOUTH];
                    assign    router_congestion_out_all [`SELECT_WIRE(x,y,NORTH,CONGw)]   =     router_congestion_in_all [`SELECT_WIRE(x,(NY-1),SOUTH,CONGw)];
                end//topology
            end//y>0
            
            
            if(x>0)begin :not_first_x
                assign    router_flit_out_all [`SELECT_WIRE(x,y,WEST,Fw)] =    router_flit_in_all [`SELECT_WIRE((x-1),y,EAST,Fw)] ;
                assign    router_credit_out_all [`SELECT_WIRE(x,y,WEST,V)] =  router_credit_in_all [`SELECT_WIRE((x-1),y,EAST,V)] ;
                assign    router_flit_out_we_all [`router_id(x,y)][WEST] =    router_flit_in_we_all [`router_id((x-1),y)][EAST];
                assign    router_congestion_out_all [`SELECT_WIRE(x,y,WEST,CONGw)]   =     router_congestion_in_all [`SELECT_WIRE((x-1),y,EAST,CONGw)];
            end else begin :first_x
                /* verilator lint_off WIDTH */ 
                if(TOPOLOGY == "MESH") begin :first_x_mesh
                /* verilator lint_on WIDTH */ 
                    assign    router_flit_out_all [`SELECT_WIRE(x,y,WEST,Fw)] =  {Fw{1'b0}};
                    assign    router_credit_out_all [`SELECT_WIRE(x,y,WEST,V)] =    {V{1'b0}};
                    assign    router_flit_out_we_all [`router_id(x,y)][WEST] =    1'b0;
                    assign    router_congestion_out_all [`SELECT_WIRE(x,y,WEST,CONGw)]   =     {CONGw{1'b0}};
                /* verilator lint_off WIDTH */                
                end else if(TOPOLOGY == "TORUS") begin :first_x_torus
                /* verilator lint_on WIDTH */ 
                    assign    router_flit_out_all [`SELECT_WIRE(x,y,WEST,Fw)] =    router_flit_in_all [`SELECT_WIRE((NX-1),y,EAST,Fw)] ;
                    assign    router_credit_out_all [`SELECT_WIRE(x,y,WEST,V)] =  router_credit_in_all [`SELECT_WIRE((NX-1),y,EAST,V)] ;
                    assign    router_flit_out_we_all [`router_id(x,y)][WEST] =    router_flit_in_we_all [`router_id((NX-1),y)][EAST];
                    assign    router_congestion_out_all [`SELECT_WIRE(x,y,WEST,CONGw)]   =     router_congestion_in_all [`SELECT_WIRE((NX-1),y,EAST,CONGw)];
                end//topology
            end    
            
            if(y    <    NY-1) begin : firsty
                assign    router_flit_out_all [`SELECT_WIRE(x,y,SOUTH,Fw)] =    router_flit_in_all [`SELECT_WIRE(x,(y+1),NORTH,Fw)];
                assign    router_credit_out_all [`SELECT_WIRE(x,y,SOUTH,V)] =     router_credit_in_all [`SELECT_WIRE(x,(y+1),NORTH,V)];
                assign    router_flit_out_we_all [`router_id(x,y)][SOUTH] =    router_flit_in_we_all [`router_id(x,(y+1))][NORTH];
                assign    router_congestion_out_all [`SELECT_WIRE(x,y,SOUTH,CONGw)]   =     router_congestion_in_all [`SELECT_WIRE(x,(y+1),NORTH,CONGw)];
            end else     begin : lasty
                /* verilator lint_off WIDTH */ 
                if(TOPOLOGY == "MESH") begin :ly_mesh
                /* verilator lint_on WIDTH */ 
                    assign    router_flit_out_all [`SELECT_WIRE(x,y,4,Fw)] =  {Fw{1'b0}};
                    assign    router_credit_out_all [`SELECT_WIRE(x,y,4,V)] =    {V{1'b0}};
                    assign    router_flit_out_we_all [`router_id(x,y)][4] =    1'b0;
                    assign    router_congestion_out_all [`SELECT_WIRE(x,y,4,CONGw)]   =     {CONGw{1'b0}};    
                /* verilator lint_off WIDTH */ 
                end else if(TOPOLOGY == "TORUS") begin :ly_torus
                /* verilator lint_on WIDTH */ 
                    assign    router_flit_out_all [`SELECT_WIRE(x,y,SOUTH,Fw)] =    router_flit_in_all [`SELECT_WIRE(x,0,NORTH,Fw)];
                    assign    router_credit_out_all [`SELECT_WIRE(x,y,SOUTH,V)] =     router_credit_in_all [`SELECT_WIRE(x,0,NORTH,V)];
                    assign    router_flit_out_we_all [`router_id(x,y)][SOUTH] =    router_flit_in_we_all [`router_id(x,0)][NORTH];
                    assign    router_congestion_out_all [`SELECT_WIRE(x,y,SOUTH,CONGw)]   =     router_congestion_in_all [`SELECT_WIRE(x,0,NORTH,CONGw)];
                end//topology
            end          
        
        
            // endpoint(s) connection
            // connect local ports
            for  (l=0;   l<NL; l=l+1) begin :locals
                localparam ENDPID = `endp_id(x,y,l); 
                localparam LOCALP = (l==0) ? l : l + R2R_CHANNELS_MESH_TORI; // first local port is connected to router port 0. The rest are connected at the end  
		              
                assign er_addr [ENDPID] = R_ADDR;                
		
                assign router_flit_out_all [`SELECT_WIRE(x,y,LOCALP,Fw)] =    ni_flit_in [ENDPID];
                assign router_credit_out_all [`SELECT_WIRE(x,y,LOCALP,V)] =    ni_credit_in [ENDPID];
                assign router_flit_out_we_all [`router_id(x,y)][LOCALP] =    ni_flit_in_wr [ENDPID];
                assign router_congestion_out_all[`SELECT_WIRE(x,y,LOCALP,CONGw)] =   {CONGw{1'b0}};              
            
                assign ni_flit_out [ENDPID] = router_flit_in_all [`SELECT_WIRE(x,y,LOCALP,Fw)];
                assign ni_flit_out_wr [ENDPID] = router_flit_in_we_all[`router_id(x,y)][LOCALP];
                assign ni_credit_out [ENDPID] = router_credit_in_all [`SELECT_WIRE(x,y,LOCALP,V)];                             
                            
               
                              
            end// locals                 
    
            end //y
        end //x
    end// mesh_torus  


      
    
endgenerate

 start_delay_gen #(
        .NC(NE)

    )delay_gen
    (
        .clk(clk),
        .reset(reset),
        .start_i(start_i),
        .start_o(start_o)
    );

endmodule




module start_delay_gen #(
    parameter NC     =    64 //number of cores

)(
    clk,
    reset,
    start_i,
    start_o
);

    input reset,clk,start_i;
    output [NC-1    :    0] start_o;
    reg start_i_reg;
    wire start;
    wire cnt_increase;
    reg  [NC-1    :    0] start_o_next;
    reg [NC-1    :    0] start_o_reg;
    
    assign start= start_i_reg|start_i;

    always @(*)begin 
        if(NC[0]==1'b0)begin // odd
            start_o_next={start_o[NC-3:0],start_o[NC-2],start};
        end else begin //even
            start_o_next={start_o[NC-3:0],start_o[NC-1],start};
        
        end    
    end
    
    reg [2:0] counter;
    assign cnt_increase=(counter==3'd0);
    always @(posedge clk or posedge reset) begin 
        if(reset) begin             
            start_o_reg <= {NC{1'b0}};
            start_i_reg <= 1'b0;
            counter <= 3'd0;
        end else begin 
            counter <= counter+3'd1;
            start_i_reg <= start_i;
            if(cnt_increase | start) start_o_reg <= start_o_next;
            

        end//reset
    end //always

    assign start_o=(cnt_increase | start)? start_o_reg : {NC{1'b0}};

endmodule


