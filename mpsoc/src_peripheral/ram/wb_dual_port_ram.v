/**********************************************************************
**	File:  wb_dual_port_ram.v
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
**	wishbone based dual port ram 
**	
**
*******************************************************************/ 



`timescale 1ns / 1ps



module wb_dual_port_ram #(
	parameter INITIAL_EN= "NO",
    parameter MEM_CONTENT_FILE_NAME= "ram0",// ram initial file name
    parameter INIT_FILE_PATH = "path_to/sw", // The sw folder path. It will be used for finding initial file. The path will be rewriten by the top module. 
	parameter Dw=32, //RAM data_width in bits
	parameter Aw=10, //RAM address width
	parameter BYTE_WR_EN= "YES",//"YES","NO"
	parameter FPGA_VENDOR= "ALTERA",//"ALTERA","GENERIC"
	parameter RAM_INDEX=0, // use for initialing
	// wishbon bus param
	parameter   PORT_A_BURST_MODE= "DISABLED", // "DISABLED" , "ENABLED" wisbone bus burst mode 
	parameter   PORT_B_BURST_MODE= "DISABLED", // "DISABLED" , "ENABLED" wisbone bus burst mode 
	parameter 	TAGw   =   3,
	parameter	SELw   =   Dw/8,
	parameter	CTIw   =   3,
	parameter	BTEw   =   2 
	
	)
	(
	    clk,
	    reset,
	
	    //wishbone bus port one interafces
	    sa_dat_i,
	    sa_sel_i,
	    sa_addr_i,  
	    sa_tag_i,
	    sa_cti_i,
	    sa_bte_i,
	    sa_stb_i,
	    sa_cyc_i,
	    sa_we_i,    
	    sa_dat_o,
	    sa_ack_o,
	    sa_err_o,
	    sa_rty_o,



	    //wishbone bus port two interfaces
	    sb_dat_i,
	    sb_sel_i,
	    sb_addr_i,  
	    sb_tag_i,
	    sb_cti_i,
	    sb_bte_i,
	    sb_stb_i,
	    sb_cyc_i,
	    sb_we_i,    
	    sb_dat_o,
	    sb_ack_o,
	    sb_err_o,
	    sb_rty_o
	    
	);

	function integer log2;
	input integer number; begin   
	log2=0;    
	while(2**log2<number) begin    
	    log2=log2+1;    
	end    
	end   
	endfunction // log2 
	
    function   [15:0]i2s;   
    input   integer c;  integer i;  integer tmp; begin 
    tmp =0; 
    for (i=0; i<2; i=i+1'b1) begin 
			tmp =  tmp +    (((c % 10)   + 6'd48) << i*8); 
			c       =   c/10; 
    end 
    i2s = tmp[15:0];
    end     
    endfunction //i2s

localparam	BYTE_ENw= ( BYTE_WR_EN == "YES")? Dw/8 : 1;

    

	input                  clk;
	input                  reset;
    
     
   
	
     //wishbone bus interface
	input       [Dw-1       :   0]      sa_dat_i,sb_dat_i;
	input       [SELw-1     :   0]      sa_sel_i,sb_sel_i;
	input       [Aw-1       :   0]      sa_addr_i,sb_addr_i;  
	input       [TAGw-1     :   0]      sa_tag_i,sb_tag_i;
	input                               sa_stb_i,sb_stb_i;
	input                               sa_cyc_i,sb_cyc_i;
	input                               sa_we_i,sb_we_i;
	input       [CTIw-1     :   0]      sa_cti_i,sb_cti_i;
	input       [BTEw-1     :   0]      sa_bte_i,sb_bte_i;
    
	output      [Dw-1       :   0]      sa_dat_o,sb_dat_o;
	output                              sa_ack_o,sb_ack_o;
	output                              sa_err_o,sb_err_o;
	output                              sa_rty_o,sb_rty_o;
    




   
    wire   [Dw-1   :   0]  data_a,data_b;
    wire   [Aw-1   :   0]  addr_a,addr_b;
    wire               we_a,we_b;
    wire   [Dw-1    :   0]  q_a,q_b;
    

`ifdef VERILATOR // verilatore does not recognize altsyncram
    localparam FPGA_VENDOR_MDFY= "GENERIC";
`else 
    `ifdef MODEL_TECH
        localparam FPGA_VENDOR_MDFY= "GENERIC";
    `else
       localparam FPGA_VENDOR_MDFY= FPGA_VENDOR;
    `endif
`endif


	localparam MEM_NAME = (FPGA_VENDOR_MDFY== "ALTERA")? {MEM_CONTENT_FILE_NAME,".mif"} : 
							{MEM_CONTENT_FILE_NAME,".hex"}; //Generic


	localparam INIT_FILE =  {INIT_FILE_PATH,"/RAM/",MEM_NAME};

	
   
        
    wb_bram_ctrl #(
        .Dw(Dw),
        .Aw(Aw),
        .BURST_MODE(PORT_A_BURST_MODE),
        .SELw(SELw),
        .CTIw(CTIw),
        .BTEw(BTEw)
    )
   ctrl_a
   (
        .clk(clk),
        .reset(reset),
        .d(data_a),
        .addr(addr_a),
        .we(we_a),
        .q(q_a),
        .sa_dat_i(sa_dat_i),
        .sa_sel_i(sa_sel_i),
        .sa_addr_i(sa_addr_i),
        .sa_stb_i(sa_stb_i),
        .sa_cyc_i(sa_cyc_i),
        .sa_we_i(sa_we_i),
        .sa_cti_i(sa_cti_i),
        .sa_bte_i(sa_bte_i),
        .sa_dat_o(sa_dat_o),
        .sa_ack_o(sa_ack_o),
        .sa_err_o(sa_err_o),
        .sa_rty_o(sa_rty_o)
   );
   
   
    wb_bram_ctrl #(
        .Dw(Dw),
        .Aw(Aw),
        .BURST_MODE(PORT_B_BURST_MODE),
        .SELw(SELw),
        .CTIw(CTIw),
        .BTEw(BTEw)
    )
    ctrl_b
    (
        .clk(clk),
        .reset(reset),
        .d(data_b),
        .addr(addr_b),
        .we(we_b),
        .q(q_b),
        .sa_dat_i(sb_dat_i),
        .sa_sel_i(sb_sel_i),
        .sa_addr_i(sb_addr_i),
        .sa_stb_i(sb_stb_i),
        .sa_cyc_i(sb_cyc_i),
        .sa_we_i(sb_we_i),
        .sa_cti_i(sb_cti_i),
        .sa_bte_i(sa_bte_i),
        .sa_dat_o(sb_dat_o),
        .sa_ack_o(sb_ack_o),
        .sa_err_o(sb_err_o),
        .sa_rty_o(sb_rty_o)
   );
        
     

    generate 
    if(FPGA_VENDOR_MDFY=="ALTERA")begin:altera_fpga
    	localparam  RAM_ID ={"ENABLE_RUNTIME_MOD=NO"};
         // aletra dual port ram 
    		altsyncram #(
    			.operation_mode("BIDIR_DUAL_PORT"),
    			.address_reg_b("CLOCK0"),
    			.wrcontrol_wraddress_reg_b("CLOCK0"),
    			.indata_reg_b("CLOCK0"),
    			.outdata_reg_a("UNREGISTERED"),
    			.outdata_reg_b("UNREGISTERED"),
    			.width_a(Dw),
    			.width_b(Dw),
    			.lpm_hint(RAM_ID),
    			.read_during_write_mode_mixed_ports("DONT_CARE"),
    			.widthad_a(Aw),
    			.widthad_b(Aw),
    			.width_byteena_a(BYTE_ENw),
    			.init_file(INIT_FILE)
    	
    		) ram_inst
    		(
    			.clock0(clk),
     			.address_a(addr_a),
    			.wren_a(we_a),
    			.data_a(data_a),
    			.q_a(q_a),
    			.byteena_a(sa_sel_i),		 
    		    		
    			.address_b(addr_b),
    			.wren_b(we_b),
    			.data_b(data_b),
    			.q_b(q_b),
    			.byteena_b(1'b1),	    		
    
    			.rden_a(1'b1),
    			.rden_b(1'b1),
    			.clock1(1'b1),
    			.clocken0(1'b1),
    			.clocken1(1'b1),
    			.clocken2(1'b1),
    			.clocken3(1'b1),
    			.aclr0(1'b0),
    			.aclr1(1'b0),		
    			.addressstall_a(1'b0),
    			.addressstall_b(1'b0),
    			.eccstatus(   )
    
    		);
    
    	
    end
    
    else if(FPGA_VENDOR_MDFY=="GENERIC")begin:generic_ram
    	
    		
    
        generic_dual_port_ram #(
            .Dw(Dw),
            .Aw(Aw),
            .BYTE_WR_EN(BYTE_WR_EN),
			.INITIAL_EN(INITIAL_EN),
			.INIT_FILE(INIT_FILE) 
        )
        ram_inst
        (
            .data_a(data_a), 
    		.data_b(data_b),
    		.addr_a(addr_a),
    		.addr_b(addr_b),
    		.byteena_a(sa_sel_i),
    		.byteena_b({BYTE_ENw{1'b1}}),
    		.we_a(we_a),
    		.we_b(we_b),
    		.clk(clk),
    		.q_a(q_a),
    		.q_b(q_b)
    			
    	);   
    	
    end //Generic
    
        
    endgenerate



endmodule










