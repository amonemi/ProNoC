/**********************************************************************
**	File:  wb_bram_ctrl.v
**	   
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
**	memory wishbone bus interface controller
**	
**
*******************************************************************/ 



`timescale	 1ns/1ps

module wb_bram_ctrl #(
    parameter Dw=32, //RAM data_width in bits
    parameter Aw=10, //RAM address width

    // wishbon bus param
    parameter BURST_MODE = "DISABLED", // "DISABLED" , "ENABLED" wisbone bus burst mode 
    parameter SELw = Dw/8,
    parameter CTIw = 3,
    parameter BTEw = 2 
)(
    clk,
    reset,
    
     //wishbone bus interface
    sa_dat_i,
    sa_sel_i,
    sa_addr_i,  
    sa_cti_i, 
    sa_bte_i,  
    sa_stb_i,
    sa_cyc_i,
    sa_we_i,    
    sa_dat_o,
    sa_ack_o,
    sa_err_o,
    sa_rty_o,
    
    // BRAM interface 
    d,
    addr,
    we,
    q
      

);

    input            clk;
    input            reset;
    
   // BRAM interface 
    output   [Dw-1   :   0]  d;
    output   [Aw-1   :   0]  addr;
    output                 we;
    input  [Dw-1    :   0]  q;

// Wishbone bus interface
    input       [Dw-1       :   0]      sa_dat_i;
    input       [SELw-1     :   0]      sa_sel_i;
    input       [Aw-1       :   0]      sa_addr_i;  
    
    input                      sa_stb_i;
    input                      sa_cyc_i;
    input                      sa_we_i;
    input       [CTIw-1     :   0]      sa_cti_i;
    input       [BTEw-1     :   0]      sa_bte_i;
    
    
    output     [Dw-1       :   0]      sa_dat_o;
    output                    sa_ack_o;
    output                     sa_err_o;
    output                     sa_rty_o;

    wire sa_ack;
    
    
    // 3'b100 is reserved in wb4 interface. It is used for ni
   // wire sa_ack_ni_burst =   sa_stb_i ; //the ack is registerd inside the master in burst mode 
  //  assign sa_ack_o = (sa_cti_i == 3'b100 ) ?  sa_ack_ni_burst: sa_ack;
    
    assign sa_ack_o =  sa_ack;

    generate if (BURST_MODE== "ENABLED") begin : burst_wb

        wb_burst_bram_ctrl #(
         	.Dw(Dw),
         	.Aw(Aw),
         	.SELw(SELw),
         	.CTIw(CTIw),
         	.BTEw(BTEw)
        )
        bram_ctrl
        (
         	.clk(clk),
         	.reset(reset),
         	.d(d),
         	.addr(addr),
         	.we(we),
         	.q(q),
         	.sa_dat_i(sa_dat_i),
         	.sa_sel_i(sa_sel_i),
         	.sa_addr_i(sa_addr_i),
         	.sa_stb_i(sa_stb_i),
         	.sa_cyc_i(sa_cyc_i),
         	.sa_we_i(sa_we_i),
         	.sa_cti_i(sa_cti_i),
            .sa_bte_i(sa_bte_i),
         	.sa_dat_o(sa_dat_o),
         	.sa_ack_o(sa_ack),
         	.sa_err_o(sa_err_o),
         	.sa_rty_o(sa_rty_o)
     );

    end else begin : no_burst


     assign sa_dat_o =   q;
     assign d     =   sa_dat_i ;
     assign addr     =   sa_addr_i;
     assign we       =   sa_stb_i &  sa_we_i;
     assign sa_err_o =   1'b0;
     assign sa_rty_o =   1'b0; 
     
     reg ack; 
     assign sa_ack = ack;
     
     always @(posedge clk ) begin
         if(reset) begin 
          ack  <= 1'b0;
         end else begin 
          ack  <= (~sa_ack_o) & sa_stb_i;
         end     
     end

    end
    endgenerate

endmodule









module wb_burst_bram_ctrl #(
	
	parameter Dw=32, //RAM data_width in bits
	parameter Aw=10, //RAM address width

	// wishbon bus param
	parameter	SELw   = Dw/8,
	parameter	CTIw   = 3,
	parameter   BTEw   = 2
	
)(
	clk,
	reset,
	
	 //wishbone bus interface
	sa_dat_i,
	sa_sel_i,
	sa_addr_i,	
	sa_cti_i,
	sa_bte_i,  	
	sa_stb_i,
	sa_cyc_i,
	sa_we_i,    
	sa_dat_o,
	sa_ack_o,
	sa_err_o,
	sa_rty_o,
	
	// BRAM interface 
	d,
	addr,
	we,
	q
		 

);

    `define UDLY  1 

	input            clk;
	input            reset;
    
   // BRAM interface 
	output   [Dw-1   :   0]  d;
	output   [Aw-1   :   0]  addr;
	output						 we;
	input  [Dw-1 	:   0]  q;

   
	
	// Wishbone bus interface
	input       [Dw-1       :   0]      sa_dat_i;
	input       [SELw-1     :   0]      sa_sel_i;
	input       [Aw-1       :   0]      sa_addr_i;  
	
	input                      sa_stb_i;
	input                      sa_cyc_i;
	input                      sa_we_i;
	input       [CTIw-1     :   0]      sa_cti_i;
	input       [BTEw-1     :   0]      sa_bte_i;
	
    
	output  reg   [Dw-1       :   0]      sa_dat_o;
	output  reg                  sa_ack_o;
	output  reg                   sa_err_o;
	output  reg                   sa_rty_o;

	

    //Burst Type Extension for Incrementing and Decrementing bursts
    localparam [1:0]
        LINEAR  = 2'b00,
        FOUR_BEAT =2'b01,
        EIGHT_BEAT=2'b10,
        SIXTEEN_BEAT =2'b11;
     
	

  
   
   
   localparam [2:0] ST_IDLE  = 3'b000,
			ST_BURST = 3'b001,
			ST_END   = 3'b010,
			ST_SUBRD = 3'b100,
			ST_SUB   = 3'b101,
			ST_SUBWR = 3'b110;
   
   
      
	 
	 /*----------------------------------------------------------------------
	  Internal Nets and Registers
	  ----------------------------------------------------------------------*/
	 wire [Dw-1:0] data;      // Data read from RAM
	 reg 			 write_enable; // RAM write enable
	 reg [Dw-1:0]  write_data, write_data_d;   // RAM write data
	 reg [Aw+1:0]  pmi_address,  pmi_address_nxt;
	 reg [Aw+1:0]  adr_linear_incr,adr_4_beat,adr_8_beat,adr_16_beat;
	 
	 reg [Aw-1:0]  read_address, write_address;   
	 reg 			 sa_ack_o_nxt;
	 reg [Dw-1:0]  read_data;
	// reg 			 read_enable;
	 reg 			 raw_hazard, raw_hazard_nxt;
	 reg [Dw-1:0]  sa_dat_i_d;
	 reg [3:0] 		 sa_sel_i_d;
	 reg 			 delayed_write;
	 
	 wire [Aw+1 : 0] addr_init = {sa_addr_i,2'b00};
	 /*----------------------------------------------------------------------
	  State Machine
	  ----------------------------------------------------------------------*/
	 reg [2:0] state, state_nxt;
	 
	 always @(*)
	   case (state)
	     ST_IDLE:
	       if (sa_stb_i && sa_cyc_i && (sa_ack_o == 1'b0))
		 if(sa_cti_i ==3'b100)
			state_nxt = ST_IDLE;
		 else if ((sa_cti_i == 3'b000) || (sa_cti_i == 3'b111) )
		   state_nxt = ST_END;
		 else
		   if (sa_we_i && (sa_sel_i != 4'b1111))
		     state_nxt = ST_SUBRD;
		   else
		     state_nxt = ST_BURST;
	       else
		 state_nxt = state;
	     
	     ST_BURST:
	       if (sa_cti_i == 3'b111)
		 state_nxt = ST_IDLE;
	       else
		 state_nxt = state;
	     
	     ST_SUBRD:
	       state_nxt = ST_SUB;
	     
	     ST_SUB:
	       if (sa_cti_i == 3'b111)
		 state_nxt = ST_SUBWR;
	       else
		 state_nxt = state;
	     
	     default:
	       state_nxt = ST_IDLE;
	   endcase
	 
	 /*----------------------------------------------------------------------
	  
	  ----------------------------------------------------------------------*/
	 always @(*)
	   if ((state == ST_SUB) && (read_address == write_address))
	     raw_hazard_nxt = 1'b1;
	   else
	     raw_hazard_nxt = 1'b0;
	 
	 /*----------------------------------------------------------------------
	  Set up read to EBR
	  ----------------------------------------------------------------------*/
	 always @(*)
	   begin
	   /*
	      if ((sa_we_i == 1'b0)
		  || (sa_we_i
		      && (((state == ST_IDLE) && ((sa_cti_i == 3'b000) || (sa_cti_i == 3'b111) || (sa_sel_i != 4'b1111)))
			  || (state == ST_SUBRD)
			  || ((state == ST_SUB) && (raw_hazard_nxt == 1'b0)))))
		read_enable = 1'b1;
	      else
		read_enable = 1'b0;
	      */
	      read_data = raw_hazard ? write_data_d : data;
	   end
	 
	 /*----------------------------------------------------------------------
	  Set up write to EBR
	  ----------------------------------------------------------------------*/
	 always @(*)
	   begin
	      if ((sa_we_i
		   && (// Word Burst Write (first write in a sequence)
		       ((state == ST_IDLE) 
			&& sa_cyc_i && sa_stb_i && (sa_cti_i != 3'b000) && (sa_cti_i !=3'b100) && (sa_cti_i != 3'b111) && (sa_sel_i == 4'b1111))
		       // Single Write
		       || (state == ST_END)
		       // Burst Write (all writes beyond first write)
		       || (state == ST_BURST)))
		  // Sub-Word Burst Write
		  || ((state == ST_SUB) || (state == ST_SUBWR)))
		write_enable = 1'b1;
	      else
		write_enable = 1'b0;

	      if ((state == ST_SUBRD) || (state == ST_SUB) || (state == ST_SUBWR))
		delayed_write = 1'b1;
	      else
		delayed_write = 1'b0;
	      
	      write_data[7:0]   = (delayed_write
				   ? (sa_sel_i_d[0] ? sa_dat_i_d[7:0] : read_data[7:0])
				   : (sa_sel_i[0] ? sa_dat_i[7:0] : data[7:0]));
	      write_data[15:8]  = (delayed_write
				   ? (sa_sel_i_d[1] ? sa_dat_i_d[15:8] : read_data[15:8])
				   : (sa_sel_i[1] ? sa_dat_i[15:8] : data[15:8]));
	      write_data[23:16] = (delayed_write
				   ? (sa_sel_i_d[2] ? sa_dat_i_d[23:16] : read_data[23:16])
				   : (sa_sel_i[2] ? sa_dat_i[23:16] : data[23:16]));
	      write_data[31:24] = (delayed_write
				   ? (sa_sel_i_d[3] ? sa_dat_i_d[31:24] : read_data[31:24])
				   : (sa_sel_i[3] ? sa_dat_i[31:24] : data[31:24]));
	   end
	 
	 
    /*----------------------------------------------------------------------
	Set up address to EBR
	----------------------------------------------------------------------*/
	always @(*) begin
        if (// First address of any access is obtained from Wishbone signals
		  (state == ST_IDLE)
		  // Read for a Sub-Word Wishbone Burst Write
		  || (state == ST_SUB)) read_address = sa_addr_i;
        else read_address = pmi_address[Aw+1:2];
	      
        if ((state == ST_SUB) || (state == ST_SUBWR))  write_address = pmi_address[Aw+1:2];
        else write_address = sa_addr_i;
	      
        // Keep track of first address and subsequently increment it by 4
        // bytes on a burst read
	    if (sa_we_i) begin
	        //pmi_address_nxt = sa_addr_i[Aw+1:0];
            adr_linear_incr= addr_init;
            adr_4_beat= addr_init;
            adr_8_beat= addr_init;
            adr_16_beat=addr_init;
	    end else
            if (state == ST_IDLE)
                if ((sa_sel_i == 4'b1000) || (sa_sel_i == 4'b0100) || (sa_sel_i == 4'b0010) || (sa_sel_i == 4'b0001))begin 
		            //pmi_address_nxt = sa_addr_i[Aw+1:0] + 1'b1;
		            adr_linear_incr= addr_init + 1'b1;
                    adr_4_beat= {addr_init[Aw+1 :4], addr_init[3:0] + 1'b1};
                    adr_8_beat= {addr_init[Aw+1 :5], addr_init[4:0] + 1'b1};
                    adr_16_beat={addr_init[Aw+1 :6], addr_init[5:0] + 1'b1};
                end else if ((sa_sel_i == 4'b1100) || (sa_sel_i == 4'b0011))begin 
                    //pmi_address_nxt = {(sa_addr_i[Aw+1:1] + 1'b1), 1'b0};
                    adr_linear_incr= {(addr_init[Aw+1:1]  + 1'b1), 1'b0};
                    adr_4_beat= {addr_init[Aw+1 :4], {addr_init[3:1] +1'b1},1'b0};
                    adr_8_beat= {addr_init[Aw+1 :5], {addr_init[4:1] +1'b1},1'b0};
                    adr_16_beat={addr_init[Aw+1 :6], {addr_init[5:1] +1'b1},1'b0};           
               end else begin 
		           //pmi_address_nxt = {(sa_addr_i[Aw+1:2] + 1'b1), 2'b00};
		            adr_linear_incr= {(addr_init[Aw+1:2]  + 1'b1), 2'b00};
		            adr_4_beat= {addr_init[Aw+1 :4], {addr_init[3:2] +1'b1},2'b00};
                    adr_8_beat= {addr_init[Aw+1 :5], {addr_init[4:2] +1'b1},2'b00};
                    adr_16_beat={addr_init[Aw+1 :6], {addr_init[5:2] +1'b1},2'b00};                       
		       end
		  else
    		  if ((sa_sel_i == 4'b1000) || (sa_sel_i == 4'b0100) || (sa_sel_i == 4'b0010) || (sa_sel_i == 4'b0001))begin 
                    //pmi_address_nxt_linear_incr = pmi_address + 1'b1;
                    adr_linear_incr= pmi_address + 1'b1;
                    adr_4_beat= {pmi_address[Aw+1 :4], pmi_address[3:0] + 1'b1};
                    adr_8_beat= {pmi_address[Aw+1 :5], pmi_address[4:0] + 1'b1};
                    adr_16_beat={pmi_address[Aw+1 :6], pmi_address[5:0] + 1'b1};      
    		  end else if ((sa_sel_i == 4'b1100) || (sa_sel_i == 4'b0011)) begin 
    		       // pmi_address_nxt = {pmi_address[Aw+1:1] + 1'b1), 1'b0};
    		        adr_linear_incr= {(pmi_address[Aw+1:1] + 1'b1), 1'b0};
    		        adr_4_beat= {pmi_address[Aw+1 :4], {pmi_address[3:1] + 1'b1},1'b0};
                    adr_8_beat= {pmi_address[Aw+1 :5], {pmi_address[4:1] + 1'b1},1'b0};
                    adr_16_beat={pmi_address[Aw+1 :6], {pmi_address[5:1] + 1'b1},1'b0}; 
    		  end else begin
                    //pmi_address_nxt_linear_incr = {(pmi_address[Aw+1:2] + 1'b1), 2'b00};
                    adr_linear_incr= {(pmi_address[Aw+1:2] + 1'b1), 2'b00};
                    adr_4_beat= {pmi_address[Aw+1 :4], {pmi_address[3:2] +1'b1},2'b00};
                    adr_8_beat= {pmi_address[Aw+1 :5], {pmi_address[4:2] +1'b1},2'b00};
                    adr_16_beat={pmi_address[Aw+1 :6], {pmi_address[5:2] +1'b1},2'b00};   
    		  end
	   end
	   
	   
	 
	   
	   always @(*)begin 
	       case(sa_bte_i)
                LINEAR:      pmi_address_nxt = adr_linear_incr;
                FOUR_BEAT:   pmi_address_nxt = adr_4_beat;
                EIGHT_BEAT:  pmi_address_nxt = adr_8_beat;
                SIXTEEN_BEAT:pmi_address_nxt = adr_16_beat;
    	   endcase
	  end
	   
	 
	 /*----------------------------------------------------------------------
	  Set up outgoing wishbone signals
	  ----------------------------------------------------------------------*/
	 always @(*)
	   begin
	      if (((state == ST_IDLE) && sa_cyc_i && sa_stb_i && (sa_ack_o == 1'b0))
		  || (state == ST_BURST)
		  || (state == ST_SUBRD)
		  || (state == ST_SUB))
		sa_ack_o_nxt = 1'b1;
	      else
		sa_ack_o_nxt = 1'b0;
	      
	      sa_dat_o = data;
	      sa_rty_o = 1'b0;
	      sa_err_o = 1'b0;
	   end
	 
	 /*----------------------------------------------------------------------
	  Sequential Logic
	  ----------------------------------------------------------------------*/
	 always @(posedge clk)
	   if (reset)
	     begin
		sa_ack_o <= #`UDLY 1'b0;
		sa_dat_i_d <= #`UDLY 0;
		sa_sel_i_d <= #`UDLY 0;
		state <= #`UDLY ST_IDLE;
		pmi_address <= #`UDLY 0;
		write_data_d <= #`UDLY 0;
		raw_hazard <= #`UDLY 0;
	     end
	   else
	     begin
		sa_ack_o <= #`UDLY sa_ack_o_nxt;
		sa_dat_i_d <= #`UDLY sa_dat_i;
		sa_sel_i_d <= #`UDLY sa_sel_i;
		state <= #`UDLY state_nxt;
		pmi_address <= #`UDLY pmi_address_nxt;
		write_data_d <= #`UDLY write_data;
		raw_hazard <= #`UDLY raw_hazard_nxt;
	     end
	 

	

	
	assign d 	= write_data;
	assign addr=(write_enable)? write_address : read_address;
	assign we 	= write_enable; 
	assign data= q;
	
	
	
endmodule
