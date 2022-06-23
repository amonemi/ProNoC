`include "pronoc_def.v"
/**********************************************************************
 **	File:  flit_buffer.v
 **    
 **	Copyright (C) 2014-2017  Alireza Monemi
 **    
 **	This file is part of ProNoC 
 **
 **	ProNoC ( stands for Prototype Network-on-chip)  is free software: 
 **	you can redistribute it and/or modify it under the terms of the GNU
 **	Lesser General Public License as published by the Free Software Foundation,
 **	either version 2 of the License, or (at your option) any later version.
 **
 ** 	ProNoC is distributed in the hope that it will be useful, but WITHOUT
 ** 	ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 ** 	or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General
 ** 	Public License for more details.
 **
 ** 	You should have received a copy of the GNU Lesser General Public
 ** 	License along with ProNoC. If not, see <http:**www.gnu.org/licenses/>.
 **
 **
 **	Description: 
 **	Input buffer module. All VCs located in the same router 
 **	input port share one single FPGA BRAM 
 **
 **************************************************************/


module flit_buffer 
		import pronoc_pkg::*;  
	#(
		parameter B =4,
		parameter SSA_EN="YES" // "YES" , "NO"       
		)	
		(
			din,     // Data in
			vc_num_wr,//write virtual channel   
			vc_num_rd,//read virtual channel    
			wr_en,   // Write enable
			rd_en,   // Read the next word
			dout,    // Data out
			vc_not_empty,
			reset,
			clk,
			ssa_rd,
        
			//for multicast
			multiple_dest, // incr rd-sub
			sub_rd_ptr_ld,  // load rd_ptr to sub_rd_pt  
			flit_is_tail
		);

   
   
    
	localparam      
		Bw      =   (B==1)? 1 : log2(B),
		BV      =   B   *   V,
		BVw              =   log2(BV),              
		Vw               =  (V==1)? 1 : log2(V),
		DEPTHw           =   log2(B+1),
		BwV              =   Bw * V,
		BVwV             =   BVw * V,               
		RESTw = Fw -2-V , 
		PTRw = ((2**Bw)==B)? Bw : BVw, // if B is power of 2 PTRw is Bw else is BVw
		ARRAYw = PTRw * V,
		/* verilator lint_off WIDTH */ 
		RAM_DATA_WIDTH   = (PCK_TYPE == "MULTI_FLIT")? Fw - V :  Fw - V -2;
	/* verilator lint_on WIDTH */ 
    	
    	
    
    
	input  [Fw-1      :0]   din;     // Data in
	input  [V-1       :0]   vc_num_wr;//write virtual chanel   
	input  [V-1       :0]   vc_num_rd;//read virtual chanel    
	input                   wr_en;   // Write enable
	input                   rd_en;   // Read the next word
	output [Fw-1       :0]  dout;    // Data out
	output [V-1        :0]  vc_not_empty;
	input                   reset;
	input                   clk;
	input  [V-1        :0]  ssa_rd;   
	input  [V-1        :0]  multiple_dest;
	input  [V-1        :0]  sub_rd_ptr_ld;       
	output [V-1 : 0]        flit_is_tail; 				    
       
    
	//pointers
	wire [PTRw- 1     :   0] rd_ptr [V-1          :0];
	wire [PTRw- 1     :   0] wr_ptr [V-1          :0];    
	reg  [PTRw- 1     :   0] rd_ptr_next [V-1          :0];
	reg  [PTRw- 1     :   0] wr_ptr_next [V-1          :0];
	reg  [PTRw- 1     :   0] sub_rd_ptr_next [V-1          :0];
	wire [PTRw- 1     :   0] sub_rd_ptr [V-1          :0];    	
	wire [PTRw-1      :   0] ptr_tmp  [V-1 : 0];
	wire [ARRAYw-1    :   0] rd_ptr_array;
	wire [ARRAYw-1    :   0] wr_ptr_array;    
   
               
	wire  [RAM_DATA_WIDTH-1     :   0] fifo_ram_din;
	wire  [RAM_DATA_WIDTH-1     :   0] fifo_ram_dout;
	wire  [V-1                  :   0] wr;
	wire  [V-1                  :   0] rd;  
	wire  [DEPTHw-1             :   0] depth      [V-1            :0];
	reg   [DEPTHw-1             :   0] depth_next [V-1            :0];
	wire  [DEPTHw-1             :   0] sub_depth       [V-1            :0];  
	reg   [DEPTHw-1             :   0] sub_depth_next  [V-1            :0];  
    
    
	reg   [B-1 : 0] tail_fifo [V-1 : 0];    
	wire  [1  : 0] flgs_in, flgs_out;
	wire  [V-1: 0] vc_in;
	wire  [RESTw-1 :0      ] flit_rest_in,flit_rest_out;
	wire  [V-1       :   0] sub_rd;
	wire  [V-1       :   0] sub_restore;
    
	assign  wr  =   (wr_en)?  vc_num_wr : {V{1'b0}};
   
  

	genvar i;

	generate 
	/* verilator lint_off WIDTH */ 
		if (CAST_TYPE != "UNICAST") begin 
			/* verilator lint_on WIDTH */ 
			assign  sub_rd  =  (rd_en)?  vc_num_rd  : ssa_rd; 
			assign  sub_restore = sub_rd_ptr_ld; 
			assign  rd  =   (rd_en)?  vc_num_rd & ~multiple_dest : ssa_rd & ~multiple_dest;		    	
		end else begin : unicast
			assign  rd  =   (rd_en)?  vc_num_rd : ssa_rd;    	
		end
	
		/* verilator lint_off WIDTH */ 
		if (PCK_TYPE == "MULTI_FLIT") begin :multi
			/* verilator lint_on WIDTH */    
			assign {flgs_in,vc_in,flit_rest_in}=din;    
			assign fifo_ram_din = {flgs_in,flit_rest_in};
			assign {flgs_out,flit_rest_out} = fifo_ram_dout;
			assign dout = {flgs_out,{V{1'bX}},flit_rest_out};    
		end else begin : single
			assign fifo_ram_din = din[RAM_DATA_WIDTH-1     :   0];
			assign dout = {2'b11,{V{1'bX}},fifo_ram_dout};    
		end
    	
    	
		for(i=0;i<V;i=i+1) begin :V_
			assign  wr_ptr_array[(i+1)*PTRw- 1        :   i*PTRw]   =       wr_ptr[i];  
			
			/* verilator lint_off WIDTH */ 
			if (CAST_TYPE != "UNICAST") begin 
				/* verilator lint_on WIDTH */ 
				assign  rd_ptr_array[(i+1)*PTRw- 1 :   i*PTRw]   =       sub_rd_ptr[i]; 
				localparam RESET_TO = ((2**Bw)==B)? 0 : B*i;
				pronoc_register #(.W(PTRw),.RESET_TO(RESET_TO)) reg4 (.in(sub_rd_ptr_next[i]), .out(sub_rd_ptr[i]), .reset(reset), .clk(clk));
				
				
				pronoc_register #(.W(DEPTHw)) sub_depth_reg (.in(sub_depth_next[i] ), .out(sub_depth [i]), .reset(reset), .clk(clk));
				always @ (*)begin 
					sub_depth_next  [i] = sub_depth   [i];
					if(sub_restore[i]) sub_depth_next  [i]= depth_next[i];
					else if (wr[i] & ~sub_rd[i]) sub_depth_next [i] = sub_depth[i] + 1'h1;
					else if (~wr[i] & sub_rd[i]) sub_depth_next [i] = sub_depth[i] - 1'h1;    
				end//always
				
				assign  vc_not_empty    [i] =   (sub_depth[i] > 0);
				
				
				
				
			end else begin : unicast
				assign  rd_ptr_array[(i+1)*PTRw- 1 :   i*PTRw]   =       rd_ptr[i];   
				assign  vc_not_empty    [i] =   (depth[i] > 0);
			end    	
		end//for
      	
 	   	
    

		if((2**Bw)==B)begin :pow2
			/*****************      
          Buffer width is power of 2
			 ******************/
	
			wire [Bw-1     :    0]  vc_wr_addr;
			wire [Bw-1     :    0]  vc_rd_addr; 
			wire [Vw-1     :    0]  wr_select_addr;
			wire [Vw-1     :    0]  rd_select_addr; 
			wire [Bw+Vw-1  :    0]  wr_addr;
			wire [Bw+Vw-1  :    0]  rd_addr;	    
    
			assign  wr_addr =   {wr_select_addr,vc_wr_addr};
			assign  rd_addr =   {rd_select_addr,vc_rd_addr};
    
        
			onehot_mux_1D #(
					.W(Bw),
					.N(V) 
				)
				wr_ptr_mux
				(
					.in(wr_ptr_array),
					.out(vc_wr_addr),
					.sel(vc_num_wr)
				);   
	        
	    
			onehot_mux_1D #(
					.W(Bw),
					.N(V) 
				)
				rd_ptr_mux
				(
					.in(rd_ptr_array),
					.out(vc_rd_addr),
					.sel(vc_num_rd)
				);    
	    
			one_hot_to_bin #(
					.ONE_HOT_WIDTH(V)    
				)
				wr_vc_start_addr
				(
					.one_hot_code(vc_num_wr),
					.bin_code(wr_select_addr)
				);
	    
			one_hot_to_bin #(
					.ONE_HOT_WIDTH(V)    
				)
				rd_vc_start_addr
				(
					.one_hot_code(vc_num_rd),
					.bin_code(rd_select_addr)
				);
	
			fifo_ram    #(
					.DATA_WIDTH (RAM_DATA_WIDTH),
					.ADDR_WIDTH (BVw ),
					.SSA_EN(SSA_EN)       
				)
				the_queue
				(
					.wr_data(fifo_ram_din), 
					.wr_addr(wr_addr[BVw-1  :   0]),
					.rd_addr(rd_addr[BVw-1  :   0]),
					.wr_en(wr_en),
					.rd_en(rd_en),
					.clk(clk),
					.rd_data(fifo_ram_dout)
				);  

			for(i=0;i<V;i=i+1) begin :loop0
    	
				always @(posedge clk) begin
					if(wr[i]) tail_fifo[i][wr_ptr[i]] <= din[Fw-2];
				end     	
          
				pronoc_register #(.W(Bw    )) reg1 (.in(rd_ptr_next[i]), .out(rd_ptr[i]), .reset(reset), .clk(clk));
				pronoc_register #(.W(Bw    )) reg2 (.in(wr_ptr_next[i]), .out(wr_ptr[i]), .reset(reset), .clk(clk));
				pronoc_register #(.W(DEPTHw)) reg3 (.in(depth_next[i] ), .out(depth [i]), .reset(reset), .clk(clk));
	          

				always @ (*)begin 
					rd_ptr_next [i] = rd_ptr  [i];
					wr_ptr_next [i] = wr_ptr  [i];
					depth_next  [i] = depth   [i];
	        
					if (wr[i]  ) wr_ptr_next [i] = wr_ptr [i]+ 1'h1;
					if (rd[i]  ) rd_ptr_next [i] = rd_ptr [i]+ 1'h1;
					if (wr[i] & ~rd[i]) depth_next [i] = depth[i] + 1'h1;
					else if (~wr[i] & rd[i]) depth_next [i] = depth[i] - 1'h1;
	    
				end//always

				/* verilator lint_off WIDTH */ 
				if (CAST_TYPE != "UNICAST") begin :multicast
					/* verilator lint_on WIDTH */ 	      
					always @ (*)begin 
						sub_rd_ptr_next[i] = sub_rd_ptr[i];
						if (sub_restore[i]) sub_rd_ptr_next[i] = rd_ptr_next [i];
						else if(sub_rd[i])  sub_rd_ptr_next[i] = sub_rd_ptr[i]+ 1'h1;        		
					end	        	
	        	
					/* verilator lint_off WIDTH */
					assign  flit_is_tail[i] = (PCK_TYPE == "MULTI_FLIT")? tail_fifo[i][sub_rd_ptr[i]]  : 1'b1;
					/* verilator lint_on WIDTH */
	        	
        	
				end else begin : unicast
	        	
					/* verilator lint_off WIDTH */
					assign  flit_is_tail[i] = (PCK_TYPE == "MULTI_FLIT")?  tail_fifo[i][rd_ptr[i]] : 1'b1;
					/* verilator lint_on WIDTH */
				end
			end//for
    
    
    
		end  else begin :no_pow2    
			/*****************      
    	Buffer width is not power of 2
			 ******************/
			// memory address
			wire [BVw- 1    :   0]  wr_addr;
			wire [BVw- 1    :   0]  rd_addr;
			for(i=0;i<V;i=i+1) begin :V_   
    
				pronoc_register #(.W(BVw),.RESET_TO(B*i)) reg1 (.in(rd_ptr_next[i]), .out(rd_ptr[i]), .reset(reset), .clk(clk));
				pronoc_register #(.W(BVw),.RESET_TO(B*i)) reg2 (.in(wr_ptr_next[i]), .out(wr_ptr[i]), .reset(reset), .clk(clk));
				pronoc_register #(.W(DEPTHw)            ) reg3 (.in(depth_next[i] ), .out(depth [i]), .reset(reset), .clk(clk));         
    
     		        
				always @(posedge clk) begin
					/* verilator lint_off WIDTH */ 
					if(wr[i]) tail_fifo[i][wr_ptr[i]-(B*i)] <= din[Fw-2];
					/* verilator lint_on WIDTH */
				end    
        
				always @ (*) begin 
					rd_ptr_next [i] = rd_ptr  [i];
					wr_ptr_next [i] = wr_ptr  [i];
					depth_next  [i] = depth   [i];
					/* verilator lint_off WIDTH */ 
					if (wr[i] ) wr_ptr_next[i] =(wr_ptr[i]==(B*(i+1))-1)? (B*i) : wr_ptr [i]+ 1'h1;
					if (rd[i] ) rd_ptr_next[i] =(rd_ptr[i]==(B*(i+1))-1)? (B*i) : rd_ptr [i]+ 1'h1;
					/* verilator lint_on WIDTH */ 
					if (wr[i] & ~rd[i]) depth_next [i] = depth[i] + 1'h1;
					else if (~wr[i] & rd[i]) depth_next [i] = depth[i] - 1'h1;
				end//always  
         	
        
        
				/* verilator lint_off WIDTH */ 
				if (CAST_TYPE != "UNICAST") begin :multicast
				/* verilator lint_on WIDTH */ 
        	
					
					
      
					always @ (*)begin 
						sub_rd_ptr_next[i] = sub_rd_ptr[i];
						if (sub_restore[i]) sub_rd_ptr_next[i] = rd_ptr_next [i];
						/* verilator lint_off WIDTH */ 
						else if(sub_rd[i])  sub_rd_ptr_next[i] = (sub_rd_ptr[i]==(B*(i+1))-1)? (B*i) : sub_rd_ptr [i]+ 1'h1; 
						/* verilator lint_on WIDTH */ 
					end        	
        	
					/* verilator lint_off WIDTH */ 
					assign  ptr_tmp [i] = sub_rd_ptr[i]-(B*i);
					assign  flit_is_tail[i] = (PCK_TYPE == "MULTI_FLIT")?  tail_fifo[i][ptr_tmp [i]] :1'b1;
					/* verilator lint_on WIDTH */ 
        	      	
        	
				end else begin : unicast
					/* verilator lint_off WIDTH */ 
					assign  flit_is_tail[i] = (PCK_TYPE == "MULTI_FLIT")?  tail_fifo[i][rd_ptr[i]-(B*i)] : 1'b1;
					/* verilator lint_on WIDTH */ 
				end
			end//FOR
    
    
			onehot_mux_1D #(
					.W(BVw),
					.N(V)        
				)
				wr_mux
				(
					.in(wr_ptr_array),
					.out(wr_addr),
					.sel(vc_num_wr)
				);
	    
			onehot_mux_1D #(
					.W(BVw),
					.N(V)        
				)
				rd_mux
				(
					.in(rd_ptr_array),
					.out(rd_addr),
					.sel(vc_num_rd)
				);
	    
			fifo_ram_mem_size #(
					.DATA_WIDTH (RAM_DATA_WIDTH),
					.MEM_SIZE (BV ),
					.SSA_EN(SSA_EN)       
				)
				the_queue
				(
					.wr_data        (fifo_ram_din), 
					.wr_addr        (wr_addr),
					.rd_addr        (rd_addr),
					.wr_en          (wr_en),
					.rd_en          (rd_en),
					.clk            (clk),
					.rd_data        (fifo_ram_dout)
				);  
		end
	endgenerate
    
    
    
    
  

	//synthesis translate_off
	//synopsys  translate_off
    
	
    
	generate
		
		if(DEBUG_EN) begin :dbg 
			always @(posedge clk) begin	       
				if(wr_en && vc_num_wr == {V{1'b0}})begin 
					$display("%t: ERROR: Attempt to write when no wr VC is asserted: %m",$time);
					$finish;
				end
				if(rd_en && vc_num_rd == {V{1'b0}})begin
					$display("%t: ERROR: Attempt to read when no rd VC is asserted: %m",$time);
					$finish;
				end
			end    
		end //DEBUG_EN
	
	
		for(i=0;i<V;i=i+1) begin :loop0
	
			/* verilator lint_off WIDTH */ 
			if (CAST_TYPE != "UNICAST") begin :multicast
				/* verilator lint_on WIDTH */ 	 
	
				
			
				always @(posedge clk) begin          
					if (wr[i] && (sub_depth[i] == B [DEPTHw-1 : 0]) && !sub_rd[i]) begin
						$display("%t: ERROR: Attempt to write to full FIFO:FIFO size is %d. %m",$time,B);
						$finish;
					end   
					/* verilator lint_off WIDTH */
					if (sub_rd[i] && (sub_depth[i] == {DEPTHw{1'b0}} &&  SSA_EN !="YES"  ))begin 
						/* verilator lint_on WIDTH */
						$display("%t: ERROR: Attempt to read an empty FIFO: %m",$time);
						$finish;
					end  
					/* verilator lint_off WIDTH */
					if (sub_rd[i] && !wr[i] && (sub_depth[i] == {DEPTHw{1'b0}} &&  SSA_EN =="YES" ))begin 
						/* verilator lint_on WIDTH */
						$display("%t: ERROR: Attempt to read an empty FIFO: %m",$time);
						$finish;
					end  
				end//always	
			end	//multicast
	
	
			always @(posedge clk) begin	          
				if (wr[i] && (depth[i] == B [DEPTHw-1 : 0]) && !rd[i])begin
					$display("%t: ERROR: Attempt to write to full FIFO:FIFO size is %d. %m",$time,B);
					$finish;
				end    
				/* verilator lint_off WIDTH */
				if (rd[i] && (depth[i] == {DEPTHw{1'b0}} &&  SSA_EN !="YES"  ))begin
					/* verilator lint_on WIDTH */
					$display("%t: ERROR: Attempt to read an empty FIFO: %m",$time);
					$finish;
				end   
				/* verilator lint_off WIDTH */
				if (rd[i] && !wr[i] && (depth[i] == {DEPTHw{1'b0}} &&  SSA_EN =="YES" ))begin 
					/* verilator lint_on WIDTH */	
					$display("%t: ERROR: Attempt to read an empty FIFO: %m",$time);
					$finish;
				end                
				//if (wr_en)       $display($time, " %h is written on fifo ",din);
			end//always
		end//for	
	endgenerate 
	//synopsys  translate_on
	//synthesis translate_on	














endmodule 



/****************************

     fifo_ram

 *****************************/



module fifo_ram     #(
		parameter DATA_WIDTH    = 32,
		parameter ADDR_WIDTH    = 8,
		parameter SSA_EN="YES" // "YES" , "NO"       
		)
		(
		wr_data,        
		wr_addr,
		rd_addr,
		wr_en,
		rd_en,
		clk,
		rd_data
		);  
    
    
	input [DATA_WIDTH-1         :       0]  wr_data;        
	input [ADDR_WIDTH-1         :       0]  wr_addr;
	input [ADDR_WIDTH-1         :       0]  rd_addr;
	input                                   wr_en;
	input                                   rd_en;
	input                                   clk;
	output [DATA_WIDTH-1   :       0]       rd_data;
    
    

	reg [DATA_WIDTH-1:0] memory_rd_data; 
	// memory
	reg [DATA_WIDTH-1:0] queue [2**ADDR_WIDTH-1:0] /* synthesis ramstyle = "no_rw_check , M9K" */;
	always @(posedge clk ) begin
		if (wr_en)
			queue[wr_addr] <= wr_data;
		if (rd_en)
			memory_rd_data <=  queue[rd_addr];
	end
	
 

	 	 
	 
	
	 
	generate 
	/* verilator lint_off WIDTH */
		if(SSA_EN =="YES") begin :predict
			/* verilator lint_on WIDTH */
			//add bypass
			reg [DATA_WIDTH-1:0]  bypass_reg;
			reg rd_en_delayed;
			always @(posedge clk ) begin
				bypass_reg 	<=wr_data;
				rd_en_delayed	<=rd_en;
			end
		  
			assign rd_data = (rd_en_delayed)? memory_rd_data  : bypass_reg;
		  
		  
    
		end else begin : no_predict
			assign rd_data =  memory_rd_data;
		end
	endgenerate
endmodule



/*********************
 *
 *   fifo_ram_mem_size
 *
 **********************/


module fifo_ram_mem_size     #(
		parameter DATA_WIDTH  = 32,
		parameter MEM_SIZE    = 200,
		parameter SSA_EN  = "YES" // "YES" , "NO"       
		)
		(
		wr_data,        
		wr_addr,
		rd_addr,
		wr_en,
		rd_en,
		clk,
		rd_data
		); 
     
    
	function integer log2;
		input integer number; begin   
			log2=(number <=1) ? 1: 0;    
			while(2**log2<number) begin    
				log2=log2+1;    
			end 	   
		end   
	endfunction // log2 

	localparam ADDR_WIDTH=log2(MEM_SIZE);
    
	input  [DATA_WIDTH-1         :       0]  wr_data;       
	input  [ADDR_WIDTH-1         :       0]  wr_addr;
	input  [ADDR_WIDTH-1         :       0]  rd_addr;
	input                                    wr_en;
	input                                    rd_en;
	input                                    clk;
	output [DATA_WIDTH-1        :       0]   rd_data;
    
    
     
    
    
    
	reg [DATA_WIDTH-1:0] memory_rd_data; 
	// memory
	reg [DATA_WIDTH-1:0] queue [MEM_SIZE-1:0] /* synthesis ramstyle = "no_rw_check , M9K" */;
	always @(posedge clk ) begin
		if (wr_en)
			queue[wr_addr] <= wr_data;
		if (rd_en)
			memory_rd_data <=  queue[rd_addr];
	end
         
	generate 
	/* verilator lint_off WIDTH */
		if(SSA_EN =="YES") begin :predict
			/* verilator lint_on WIDTH */
			//add bypass
			reg [DATA_WIDTH-1:0]  bypass_reg;
			reg rd_en_delayed;
			always @(posedge clk ) begin
				bypass_reg     <=wr_data;
				rd_en_delayed  <=rd_en;
			end
          
			assign rd_data = (rd_en_delayed)? memory_rd_data  : bypass_reg;
          
          
    
		end else begin : no_predict
			assign rd_data =  memory_rd_data;
		end
	endgenerate
endmodule
    
    



/**********************************

An small  First Word Fall Through FIFO. The code will use LUTs
    and  optimized for low LUTs utilization.

 **********************************/


module fwft_fifo #(
		parameter DATA_WIDTH = 2,
		parameter MAX_DEPTH = 2,
		parameter IGNORE_SAME_LOC_RD_WR_WARNING="YES" // "YES" , "NO" 
		)
		(
		input [DATA_WIDTH-1:0] din,     // Data in
		input          wr_en,   // Write enable
		input          rd_en,   // Read the next word
		output [DATA_WIDTH-1:0]  dout,    // Data out
		output         full,
		output         nearly_full,
		output          recieve_more_than_0,
		output          recieve_more_than_1,
		input          reset,
		input          clk
    
		);
    
   
	function integer log2;
		input integer number; begin   
			log2=(number <=1) ? 1: 0;    
			while(2**log2<number) begin    
				log2=log2+1;    
			end 	   
		end   
	endfunction // log2 
    

    
	localparam DEPTH_DATA_WIDTH = log2(MAX_DEPTH +1);
	localparam MUX_SEL_WIDTH     = log2(MAX_DEPTH-1);
    
	wire                                        out_ld ;
	wire    [DATA_WIDTH-1                   :   0] dout_next;
	wire[DEPTH_DATA_WIDTH-1         :   0]  depth;
	reg [DEPTH_DATA_WIDTH-1         :   0]  depth_next;
	reg [DATA_WIDTH-1:0]  dout_next_ld;
    
	genvar i;
	generate 
    
		if(MAX_DEPTH>2) begin :mwb2
			wire    [MUX_SEL_WIDTH-1    :   0] mux_sel;
			wire    [DEPTH_DATA_WIDTH-1 :   0] depth_2;
			wire                               empty;
			wire                               out_sel ;
			if(DATA_WIDTH>1) begin :wb1
				wire    [MAX_DEPTH-2        :   0] mux_in  [DATA_WIDTH-1       :0];
				wire    [DATA_WIDTH-1       :   0] mux_out;
				reg     [MAX_DEPTH-2        :   0] shiftreg [DATA_WIDTH-1      :0];
       
				for(i=0;i<DATA_WIDTH; i=i+1) begin : lp
					always @(posedge clk ) begin 
						//if (reset) begin 
						//  shiftreg[i] <= {MAX_DEPTH{1'b0}};
						//end else begin
						if(wr_en) shiftreg[i] <= {shiftreg[i][MAX_DEPTH-3   :   0]  ,din[i]};
						//end
					end
               
					assign mux_in[i]    = shiftreg[i];
					assign mux_out[i]   = mux_in[i][mux_sel];
					assign dout_next[i] = (out_sel) ? mux_out[i] : din[i];  
				end //for
       
       
			end else begin :w1
				wire    [MAX_DEPTH-2        :   0] mux_in;
				wire    mux_out;
				reg     [MAX_DEPTH-2        :   0] shiftreg; 
       
				always @(posedge clk ) begin 
					if(wr_en) shiftreg <= {shiftreg[MAX_DEPTH-3   :   0]  ,din};
				end
               
				assign mux_in    = shiftreg;
				assign mux_out   = mux_in[mux_sel];
				assign dout_next = (out_sel) ? mux_out : din;  
        
       
       
       
			end
        
            
			assign full                         = depth == MAX_DEPTH [DEPTH_DATA_WIDTH-1            :   0];
			assign nearly_full              = depth >= MAX_DEPTH [DEPTH_DATA_WIDTH-1            :   0] -1'b1;
			assign empty     = depth == {DEPTH_DATA_WIDTH{1'b0}};
			assign recieve_more_than_0  = ~ empty;
			assign recieve_more_than_1  = ~( depth == {DEPTH_DATA_WIDTH{1'b0}} ||  depth== 1 );
			assign out_sel                  = (recieve_more_than_1)  ? 1'b1 : 1'b0;
			assign out_ld                       = (depth !=0 )?  rd_en : wr_en;
			assign depth_2                      = depth - 2;       
			assign mux_sel                  = depth_2[MUX_SEL_WIDTH-1   :   0]  ;   
   
		end else if  ( MAX_DEPTH == 2) begin :mw2   
        
			reg     [DATA_WIDTH-1       :   0] register;
            
        
			always @(posedge clk ) begin 
				if(wr_en) register <= din;
			end //always
        
			assign full             = depth == MAX_DEPTH [DEPTH_DATA_WIDTH-1            :   0];
			assign nearly_full      = depth >= MAX_DEPTH [DEPTH_DATA_WIDTH-1            :   0] -1'b1;
			assign out_ld           = (depth !=0 )?  rd_en : wr_en;
			assign recieve_more_than_0  =  (depth != {DEPTH_DATA_WIDTH{1'b0}});
			assign recieve_more_than_1  = ~( depth == 0 ||  depth== 1 );
			assign dout_next        = (recieve_more_than_1) ? register  : din;  
   
   
		end else begin :mw1 // MAX_DEPTH == 1 
			assign out_ld       = wr_en;
			assign dout_next    =   din;
			assign full         = depth == MAX_DEPTH [DEPTH_DATA_WIDTH-1            :   0];
			assign nearly_full= 1'b1;
			assign recieve_more_than_0 = full;
			assign recieve_more_than_1 = 1'b0;
		end


    
	endgenerate
    
    
	pronoc_register #(.W(DEPTH_DATA_WIDTH)) reg1 (.in(depth_next), .out(depth), .reset(reset), .clk(clk));
	pronoc_register #(.W(DATA_WIDTH))       reg2 (.in(dout_next_ld), .out(dout ), .reset(reset), .clk(clk));
   
	always @ (*)begin 
		depth_next  =  depth;
		dout_next_ld   =  dout;
		if (wr_en & ~rd_en) depth_next  =  depth + 1'h1;
		else if (~wr_en & rd_en) depth_next  =  depth - 1'h1;  
		if (out_ld) dout_next_ld = dout_next;
	end//always
    
       
   
        
	//synthesis translate_off
	//synopsys  translate_off
	always @(posedge clk)
	begin
         
		if (wr_en & ~rd_en & full) begin
			$display("%t: ERROR: Attempt to write to full FIFO:FIFO size is %d. %m",$time,MAX_DEPTH);
			$finish;
		end
		/* verilator lint_off WIDTH */
		if (rd_en & !recieve_more_than_0 & IGNORE_SAME_LOC_RD_WR_WARNING == "NO") begin
			$display("%t ERROR: Attempt to read an empty FIFO: %m", $time);
			$finish;
		end
		if (rd_en & ~wr_en & !recieve_more_than_0 & (IGNORE_SAME_LOC_RD_WR_WARNING == "YES")) begin
			$display("%t ERROR: Attempt to read an empty FIFO: %m", $time);
			$finish;
		end
		/* verilator lint_on WIDTH */
           
	end // always @ (posedge clk)
    
	//synopsys  translate_on
	//synthesis translate_on  




endmodule   










/*********************

    fwft_fifo_with_output_clear
    each individual output bit has 
    its own clear signal

 **********************/





module fwft_fifo_with_output_clear #(
		parameter DATA_WIDTH = 2,
		parameter MAX_DEPTH = 2,
		parameter IGNORE_SAME_LOC_RD_WR_WARNING="NO" // "YES" , "NO" 
		)
		(
		din,     // Data in
		wr_en,   // Write enable
		rd_en,   // Read the next word
		dout,    // Data out
		full,
		nearly_full,
		recieve_more_than_0,
		recieve_more_than_1,
		reset,
		clk,
		clear
    
		);
    
	input   [DATA_WIDTH-1:0] din;     
	input          wr_en;
	input          rd_en;
	output  [DATA_WIDTH-1:0]  dout;
	output         full;
	output         nearly_full;
	output         recieve_more_than_0;
	output         recieve_more_than_1;
	input          reset;
	input          clk;
	input    [DATA_WIDTH-1:0]  clear;    
  
	function integer log2;
		input integer number; begin   
			log2=(number <=1) ? 1: 0;    
			while(2**log2<number) begin    
				log2=log2+1;    
			end 	   
		end   
	endfunction // log2 
    
	localparam DEPTH_DATA_WIDTH = log2(MAX_DEPTH +1);
	localparam MUX_SEL_WIDTH     = log2(MAX_DEPTH-1);
    
	wire out_ld;
	wire [DATA_WIDTH-1 : 0] dout_next;
	wire [DEPTH_DATA_WIDTH-1 : 0]  depth;
	reg  [DEPTH_DATA_WIDTH-1 : 0]  depth_next;
	reg  [DATA_WIDTH-1:0]  dout_next_ld;
     
	genvar i;
	generate     
		if(MAX_DEPTH>2) begin :mwb2
			wire    [MUX_SEL_WIDTH-1    :   0] mux_sel;
			wire    [DEPTH_DATA_WIDTH-1 :   0] depth_2;
			wire                               empty;
			wire                               out_sel ;
			if(DATA_WIDTH>1) begin :wb1
				wire    [MAX_DEPTH-2        :   0] mux_in  [DATA_WIDTH-1       :0];
				wire    [DATA_WIDTH-1       :   0] mux_out;
				reg     [MAX_DEPTH-2        :   0] shiftreg [DATA_WIDTH-1      :0];
       
				for(i=0;i<DATA_WIDTH; i=i+1) begin : lp
					always @(posedge clk ) begin 
						//if (reset) begin 
						//  shiftreg[i] <= {MAX_DEPTH{1'b0}};
						//end else begin
						if(wr_en) shiftreg[i] <= {shiftreg[i][MAX_DEPTH-3   :   0]  ,din[i]};
						//end
					end
               
					assign mux_in[i]    = shiftreg[i];
					assign mux_out[i]   = mux_in[i][mux_sel];
					assign dout_next[i] = (out_sel) ? mux_out[i] : din[i];  
				end //for       
       
			end else begin :w1
				wire    [MAX_DEPTH-2        :   0] mux_in;
				wire    mux_out;
				reg     [MAX_DEPTH-2        :   0] shiftreg; 
       
				always @(posedge clk ) begin 
					if(wr_en) shiftreg <= {shiftreg[MAX_DEPTH-3   :   0]  ,din};
				end
            
				assign mux_in    = shiftreg;
				assign mux_out   = mux_in[mux_sel];
				assign dout_next = (out_sel) ? mux_out : din;  
 
			end
       
			assign full = depth == MAX_DEPTH [DEPTH_DATA_WIDTH-1            :   0];
			assign nearly_full = depth >= MAX_DEPTH [DEPTH_DATA_WIDTH-1            :   0] -1'b1;
			assign empty  = depth == {DEPTH_DATA_WIDTH{1'b0}};
			assign recieve_more_than_0  = ~ empty;
			assign recieve_more_than_1  = ~( depth == {DEPTH_DATA_WIDTH{1'b0}} ||  depth== 1 );
			assign out_sel  = (recieve_more_than_1)  ? 1'b1 : 1'b0;
			assign out_ld = (depth !=0 )?  rd_en : wr_en;
			assign depth_2 = depth-'d2;       
			assign mux_sel = depth_2[MUX_SEL_WIDTH-1   :   0]  ;   
   
		end else if  ( MAX_DEPTH == 2) begin :mw2   
        
			reg     [DATA_WIDTH-1       :   0] register;            
        
			always @(posedge clk ) begin 
				if(wr_en) register <= din;
			end //always
        
			assign full = depth == MAX_DEPTH [DEPTH_DATA_WIDTH-1            :   0];
			assign nearly_full = depth >= MAX_DEPTH [DEPTH_DATA_WIDTH-1            :   0] -1'b1;
			assign out_ld = (depth !=0 )?  rd_en : wr_en;
			assign recieve_more_than_0  =  (depth != {DEPTH_DATA_WIDTH{1'b0}});
			assign recieve_more_than_1  = ~( depth == 0 ||  depth== 1 );
			assign dout_next = (recieve_more_than_1) ? register  : din;     
   
		end else begin :mw1 // MAX_DEPTH == 1 
			assign out_ld       = wr_en;
			assign dout_next    =   din;
			assign full         = depth == MAX_DEPTH [DEPTH_DATA_WIDTH-1            :   0];
			assign nearly_full= 1'b1;
			assign recieve_more_than_0 = full;
			assign recieve_more_than_1 = 1'b0;
		end    
	endgenerate




	pronoc_register #(.W(DEPTH_DATA_WIDTH)) reg1 (.in(depth_next), .out(depth), .reset(reset), .clk(clk));
	pronoc_register #(.W(DATA_WIDTH))       reg2 (.in(dout_next_ld), .out(dout ), .reset(reset), .clk(clk));
   
	always @ (*)begin 
		depth_next  =  depth;
		if (wr_en & ~rd_en) depth_next  =  depth + 1'h1;
		else if (~wr_en & rd_en) depth_next  =  depth - 1'h1;       
	end//always


          
	generate 
		for(i=0;i<DATA_WIDTH; i=i+1) begin : lp
			always @(*)begin
				dout_next_ld[i] = dout[i];
				if (clear[i]) dout_next_ld[i]   = 1'b0;
				else if (out_ld) dout_next_ld[i]   = dout_next[i];           
			end//always
		end
	endgenerate
       
	//synthesis translate_off
	//synopsys  translate_off
	always @(posedge clk)

	begin
		if(~reset)begin
			if (wr_en && ~rd_en && full) begin
				$display("%t: ERROR: Attempt to write to full FIFO:FIFO size is %d. %m",$time,MAX_DEPTH);
				$finish;
			end
			/* verilator lint_off WIDTH */
			if (rd_en && !recieve_more_than_0 && IGNORE_SAME_LOC_RD_WR_WARNING == "NO") begin
				$display("%t ERROR: Attempt to read an empty FIFO: %m", $time);
				$finish;
			end
			if (rd_en && ~wr_en && !recieve_more_than_0 && IGNORE_SAME_LOC_RD_WR_WARNING == "YES") begin
				$display("%t ERROR: Attempt to read an empty FIFO: %m", $time);
				$finish;
			end
			/* verilator lint_on WIDTH */
		end// ~reset
	end // always @ (posedge clk)
   
	//synopsys  translate_on
	//synthesis translate_on  
endmodule   









module fwft_fifo_bram #(
		parameter DATA_WIDTH = 2,
		parameter MAX_DEPTH = 2,
		parameter IGNORE_SAME_LOC_RD_WR_WARNING="YES" // "YES" , "NO" 
		)
		(
		input [DATA_WIDTH-1:0] din,     // Data in
		input          wr_en,   // Write enable
		input          rd_en,   // Read the next word
		output [DATA_WIDTH-1:0]  dout,    // Data out
		output         full,
		output         nearly_full,
		output         recieve_more_than_0,
		output         recieve_more_than_1,
		input          reset,
		input          clk
    
		);
    
   
	function integer log2;
		input integer number; begin   
			log2=(number <=1) ? 1: 0;    
			while(2**log2<number) begin    
				log2=log2+1;    
			end       
		end   
	endfunction // log2 
    

    
	localparam DEPTH_DATA_WIDTH = log2(MAX_DEPTH +1);
    
	reg  valid_next;  
	wire valid;
	wire pass_din_to_out_reg, out_reg_wr_en, bram_out_is_valid_next;
	wire bram_out_is_valid;
	wire bram_empty, bram_rd_en, bram_wr_en;
	wire [DATA_WIDTH-1 : 0] bram_dout;
	wire [DATA_WIDTH-1 : 0] out_reg;
	reg  [DATA_WIDTH-1 : 0] out_reg_next;
     
	assign dout = (bram_out_is_valid)?  bram_dout : out_reg;

  
	assign  pass_din_to_out_reg = (wr_en & ~valid)| // a write has been recived while the reg_flit is not valid
		(wr_en & valid & bram_empty & rd_en); //or its valid but bram is empty and its got a read request

	assign bram_rd_en = (rd_en & ~bram_empty);
	assign bram_wr_en = (pass_din_to_out_reg)?  1'b0 :wr_en ; //make sure not write on the Bram if the reg fifo is empty 
 
   
	assign  out_reg_wr_en = pass_din_to_out_reg | bram_out_is_valid;    

	assign  bram_out_is_valid_next = (bram_rd_en )? (rd_en &  ~bram_empty): 1'b0;
    
   
	always @(*) begin
		valid_next = valid;
		if(out_reg_wr_en) valid_next =1'b1;
		else if( bram_empty & rd_en) valid_next =1'b0;
	end   
    
    
	bram_based_fifo  #(
			.Dw(DATA_WIDTH),//data_width
			.B(MAX_DEPTH)// buffer num
		)bram_fifo(
			.din(din),   
			.wr_en(bram_wr_en), 
			.rd_en(bram_rd_en), 
			.dout(bram_dout),  
			.full(),
			.nearly_full(),
			.empty(bram_empty),
			.reset(reset),
			.clk(clk)
		);
    
	wire [DEPTH_DATA_WIDTH-1         :   0]  depth;
	reg  [DEPTH_DATA_WIDTH-1         :   0]  depth_next;
   
   
	pronoc_register #(.W(DATA_WIDTH)      ) reg1 (.in(out_reg_next           ), .out(out_reg), .reset(reset), .clk(clk));
	pronoc_register #(.W(1)               ) reg2 (.in(valid_next             ), .out(valid), .reset(reset), .clk(clk));
	pronoc_register #(.W(1)               ) reg3 (.in(bram_out_is_valid_next ), .out(bram_out_is_valid), .reset(reset), .clk(clk));
	pronoc_register #(.W(DEPTH_DATA_WIDTH)) reg4 (.in(depth_next             ), .out(depth), .reset(reset), .clk(clk));
   
   
   
	always @(*) begin 
		out_reg_next = out_reg; 
		depth_next   = depth;
		if (wr_en & ~rd_en) depth_next =   depth + 1'h1;
		else if (~wr_en & rd_en) depth_next  = depth - 1'h1;  
		if(pass_din_to_out_reg) out_reg_next = din;
		if(bram_out_is_valid)   out_reg_next = bram_dout; 
	end  
    
       
          
      
	wire empty;    
	assign full                         = depth == MAX_DEPTH [DEPTH_DATA_WIDTH-1            :   0];
	assign nearly_full              = depth >= MAX_DEPTH [DEPTH_DATA_WIDTH-1            :   0] -1'b1;
	assign empty     = depth == {DEPTH_DATA_WIDTH{1'b0}};
	assign recieve_more_than_0  = ~ empty;
	assign recieve_more_than_1  = ~( depth == {DEPTH_DATA_WIDTH{1'b0}} ||  depth== 1 );
       
         
        
        
	//synthesis translate_off
	//synopsys  translate_off
	always @(posedge clk)
	begin
		if (wr_en & ~rd_en & full) begin
			$display("%t: ERROR: Attempt to write to full FIFO:FIFO size is %d. %m",$time,MAX_DEPTH);
			$finish;
		end
		/* verilator lint_off WIDTH */
		if (rd_en & !recieve_more_than_0 & IGNORE_SAME_LOC_RD_WR_WARNING == "NO") begin
			$display("%t ERROR: Attempt to read an empty FIFO: %m", $time);
			$finish;
		end
		if (rd_en & ~wr_en & !recieve_more_than_0 & (IGNORE_SAME_LOC_RD_WR_WARNING == "YES")) begin
			$display("%t ERROR: Attempt to read an empty FIFO: %m", $time);
			$finish;
		end
		/* verilator lint_on WIDTH */           
	end // always @ (posedge clk)
    
	//synopsys  translate_on
	//synthesis translate_on  




endmodule   









/**********************************

            bram_based_fifo

 *********************************/


module bram_based_fifo  #(
		parameter Dw = 72,//data_width
		parameter B  = 10// buffer num
		)(
		din,   
		wr_en, 
		rd_en, 
		dout,  
		full,
		nearly_full,
		empty,
		reset,
		clk
		);

 
	function integer log2;
		input integer number; begin   
			log2=(number <=1) ? 1: 0;    
			while(2**log2<number) begin    
				log2=log2+1;    
			end 	   
		end   
	endfunction // log2 

	localparam  B_1 = B-1,
		Bw = log2(B),
		DEPTHw=log2(B+1);
	localparam  [Bw-1   :   0] Bint =   B_1[Bw-1    :   0];

	input [Dw-1:0] din;     // Data in
	input          wr_en;   // Write enable
	input          rd_en;   // Read the next word

	output reg [Dw-1:0]  dout;    // Data out
	output         full;
	output         nearly_full;
	output         empty;

	input          reset;
	input          clk;



	reg [Dw-1       :   0] queue [B-1 : 0] /* synthesis ramstyle = "no_rw_check" */;
	reg [Bw- 1      :   0] rd_ptr;
	reg [Bw- 1      :   0] wr_ptr;
	reg [DEPTHw-1   :   0] depth;

	// Sample the data
	always @(posedge clk)
	begin
		if (wr_en)
			queue[wr_ptr] <= din;
		if (rd_en)
			dout <=   queue[rd_ptr];
	end

	always @(posedge clk)
	begin
		if (reset) begin
			rd_ptr <= {Bw{1'b0}};
			wr_ptr <= {Bw{1'b0}};
			depth  <= {DEPTHw{1'b0}};
		end
		else begin
			if (wr_en) wr_ptr <= (wr_ptr==Bint)? {Bw{1'b0}} : wr_ptr + 1'b1;
			if (rd_en) rd_ptr <= (rd_ptr==Bint)? {Bw{1'b0}} : rd_ptr + 1'b1;
			if (wr_en & ~rd_en) depth <=  depth + 1'b1;
			else if (~wr_en & rd_en) depth <=  depth - 1'b1;
		end
	end

	//assign dout = queue[rd_ptr];
	localparam  [DEPTHw-1   :   0] Bint2 =   B_1[DEPTHw-1   :   0];


	assign full = depth == B [DEPTHw-1   :   0];
	assign nearly_full = depth >=Bint2; //  B-1
	assign empty = depth == {DEPTHw{1'b0}};

	//synthesis translate_off
	//synopsys  translate_off
	always @(posedge clk)
	begin
		if(~reset)begin
			if (wr_en && depth == B[DEPTHw-1   :   0] && !rd_en) begin
				$display(" %t: ERROR: Attempt to write to full FIFO: %m",$time);
				$finish;
			end   
			if (rd_en && depth == {DEPTHw{1'b0}}) begin
				$display("%t: ERROR: Attempt to read an empty FIFO: %m",$time);
				$finish;
			end
		end//~reset
	end
	//synopsys  translate_on
	//synthesis translate_on

endmodule // fifo

