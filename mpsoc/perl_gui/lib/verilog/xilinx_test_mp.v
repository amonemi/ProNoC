
/**************************************************************************
**	WARNING: THIS IS AN AUTO-GENERATED FILE. CHANGES TO IT ARE LIKELY TO BE
**	OVERWRITTEN AND LOST. Rename this file if you wish to do any modification.
****************************************************************************/


/**********************************************************************
**	File: xilinx_test_mp.v
**    
**	Copyright (C) 2014-2019  Alireza Monemi
**    
**	This file is part of ProNoC 1.9.1 
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
******************************************************************************/ 

module soc #(
 	parameter	CORE_ID=0,
	parameter	SW_LOC="target_dir/sw1"
)(
	MP_T0_led_port_o, 
	MP_T0_ram_jtag_to_wb, 
	MP_T0_ram_wb_to_jtag, 
	MP_T1_led_port_o, 
	MP_T1_ram_jtag_to_wb, 
	MP_T1_ram_wb_to_jtag, 
	MP_T2_led_port_o, 
	MP_T2_ram_jtag_to_wb, 
	MP_T2_ram_wb_to_jtag, 
	MP_T3_led_port_o, 
	MP_T3_ram_jtag_to_wb, 
	MP_T3_ram_wb_to_jtag, 
	MP_enable0, 
	pll_clk_in, 
	pll_reset_in
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
              for (i=0; i<2; i=i+1) begin 
              tmp =  tmp +    (((c % 10)   + 48) << i*8); 
                  c       =   c/10; 
              end 
              i2s = tmp[15:0];
          end     
     endfunction //i2s
   	localparam	MP_T3_cpu_FEATURE_DATACACHE="ENABLED";
	localparam	MP_T3_cpu_FEATURE_DMMU="ENABLED";
	localparam	MP_T3_cpu_FEATURE_IMMU="ENABLED";
	localparam	MP_T3_cpu_FEATURE_INSTRUCTIONCACHE="ENABLED";
	localparam	MP_T3_cpu_IRQ_NUM=32;
	localparam	MP_T3_cpu_OPTION_DCACHE_SNOOP="ENABLED";
	localparam	MP_T3_cpu_OPTION_OPERAND_WIDTH=32;
	localparam	MP_T3_led_PORT_WIDTH=   1;
	localparam	MP_T3_ram_Aw=14;
	localparam	MP_T3_ram_Dw=32;
	localparam	MP_T3_ram_FPGA_VENDOR="XILINX";
	localparam	MP_T3_ram_J2WBw=(MP_T3_ram_JTAG_CONNECT== "XILINX_JTAG_WB") ? 1+1+MP_T3_ram_JDw+MP_T3_ram_JAw : 1;
	localparam	MP_T3_ram_JAw=32;
	localparam	MP_T3_ram_JDw=MP_T3_ram_Dw;
	localparam	MP_T3_ram_JINDEXw=8;
	localparam	MP_T3_ram_JSTATUSw=8;
	localparam	MP_T3_ram_JTAG_CONNECT="XILINX_JTAG_WB";
	localparam	MP_T3_ram_WB2Jw=(MP_T3_ram_JTAG_CONNECT== "XILINX_JTAG_WB") ? 1+MP_T3_ram_JSTATUSw+MP_T3_ram_JINDEXw+1+MP_T3_ram_JDw  : 1;
	localparam	MP_T3_timer_PRESCALER_WIDTH=8;

 	localparam	pll_CLKOUT_NUM=1;
	localparam	pll_BANDWIDTH="OPTIMIZED";
	localparam	pll_CLKFBOUT_MULT=5;
	localparam	pll_CLKFBOUT_PHASE=0.0;
	localparam	pll_CLKIN1_PERIOD=0.0;
	localparam	pll_CLKOUT0_DIVIDE=1;
	localparam	pll_CLKOUT1_DIVIDE=1;
	localparam	pll_CLKOUT2_DIVIDE=1;
	localparam	pll_CLKOUT3_DIVIDE=1;
	localparam	pll_CLKOUT4_DIVIDE=1;
	localparam	pll_CLKOUT5_DIVIDE=1;
	localparam	pll_CLKOUT0_DUTY_CYCLE=0.5;
	localparam	pll_CLKOUT1_DUTY_CYCLE=0.5;
	localparam	pll_CLKOUT2_DUTY_CYCLE=0.5;
	localparam	pll_CLKOUT3_DUTY_CYCLE=0.5;
	localparam	pll_CLKOUT4_DUTY_CYCLE=0.5;
	localparam	pll_CLKOUT5_DUTY_CYCLE=0.5;
	localparam	pll_CLKOUT0_PHASE=0.0;
	localparam	pll_CLKOUT1_PHASE=0.0;
	localparam	pll_CLKOUT2_PHASE=0.0;
	localparam	pll_CLKOUT3_PHASE=0.0;
	localparam	pll_CLKOUT4_PHASE=0.0;
	localparam	pll_CLKOUT5_PHASE=0.0;
	localparam	pll_DIVCLK_DIVIDE=1;
	localparam	pll_REF_JITTER1=0.0;
	localparam	pll_STARTUP_WAIT="FALSE";

 
//Wishbone slave base address based on instance name
 
 
//Wishbone slave base address based on module name. 
 
 	output	 [ MP_T0_led_PORT_WIDTH-1     :   0    ] MP_T0_led_port_o;
 	input	 [ MP_T0_ram_J2WBw-1 : 0    ] MP_T0_ram_jtag_to_wb;
 	output	 [ MP_T0_ram_WB2Jw-1 : 0    ] MP_T0_ram_wb_to_jtag;
 	output	 [ MP_T1_led_PORT_WIDTH-1     :   0    ] MP_T1_led_port_o;
 	input	 [ MP_T1_ram_J2WBw-1 : 0    ] MP_T1_ram_jtag_to_wb;
 	output	 [ MP_T1_ram_WB2Jw-1 : 0    ] MP_T1_ram_wb_to_jtag;
 	output	 [ MP_T2_led_PORT_WIDTH-1     :   0    ] MP_T2_led_port_o;
 	input	 [ MP_T2_ram_J2WBw-1 : 0    ] MP_T2_ram_jtag_to_wb;
 	output	 [ MP_T2_ram_WB2Jw-1 : 0    ] MP_T2_ram_wb_to_jtag;
 	output	 [ MP_T3_led_PORT_WIDTH-1     :   0    ] MP_T3_led_port_o;
 	input	 [ MP_T3_ram_J2WBw-1 : 0    ] MP_T3_ram_jtag_to_wb;
 	output	 [ MP_T3_ram_WB2Jw-1 : 0    ] MP_T3_ram_wb_to_jtag;
 	input			MP_enable0;

 	input			pll_clk_in;
 	input			pll_reset_in;

  	wire			 MP_plug_clk_1_clk_i;
 	wire			 MP_plug_clk_0_clk_i;
 	wire			 MP_plug_reset_0_reset_i;

  	wire	[ pll_CLKOUT_NUM-1: 0 ] pll_socket_clk_array_clk_o;
 	wire			 pll_socket_clk_0_clk_o;
 	wire			 pll_socket_reset_0_reset_o;

 MP #(
 		.T3_cpu_FEATURE_DATACACHE(MP_T3_cpu_FEATURE_DATACACHE),
		.T3_cpu_FEATURE_DMMU(MP_T3_cpu_FEATURE_DMMU),
		.T3_cpu_FEATURE_IMMU(MP_T3_cpu_FEATURE_IMMU),
		.T3_cpu_FEATURE_INSTRUCTIONCACHE(MP_T3_cpu_FEATURE_INSTRUCTIONCACHE),
		.T3_cpu_IRQ_NUM(MP_T3_cpu_IRQ_NUM),
		.T3_cpu_OPTION_DCACHE_SNOOP(MP_T3_cpu_OPTION_DCACHE_SNOOP),
		.T3_cpu_OPTION_OPERAND_WIDTH(MP_T3_cpu_OPTION_OPERAND_WIDTH),
		.T3_led_PORT_WIDTH(MP_T3_led_PORT_WIDTH),
		.T3_ram_Aw(MP_T3_ram_Aw),
		.T3_ram_Dw(MP_T3_ram_Dw),
		.T3_ram_FPGA_VENDOR(MP_T3_ram_FPGA_VENDOR),
		.T3_ram_J2WBw(MP_T3_ram_J2WBw),
		.T3_ram_JAw(MP_T3_ram_JAw),
		.T3_ram_JDw(MP_T3_ram_JDw),
		.T3_ram_JINDEXw(MP_T3_ram_JINDEXw),
		.T3_ram_JSTATUSw(MP_T3_ram_JSTATUSw),
		.T3_ram_JTAG_CONNECT(MP_T3_ram_JTAG_CONNECT),
		.T3_ram_WB2Jw(MP_T3_ram_WB2Jw),
		.T3_timer_PRESCALER_WIDTH(MP_T3_timer_PRESCALER_WIDTH)
	)  MP 	(
		.T0_led_port_o(MP_T0_led_port_o),
		.T0_ram_jtag_to_wb(MP_T0_ram_jtag_to_wb),
		.T0_ram_wb_to_jtag(MP_T0_ram_wb_to_jtag),
		.T1_led_port_o(MP_T1_led_port_o),
		.T1_ram_jtag_to_wb(MP_T1_ram_jtag_to_wb),
		.T1_ram_wb_to_jtag(MP_T1_ram_wb_to_jtag),
		.T2_led_port_o(MP_T2_led_port_o),
		.T2_ram_jtag_to_wb(MP_T2_ram_jtag_to_wb),
		.T2_ram_wb_to_jtag(MP_T2_ram_wb_to_jtag),
		.T3_led_port_o(MP_T3_led_port_o),
		.T3_ram_jtag_to_wb(MP_T3_ram_jtag_to_wb),
		.T3_ram_wb_to_jtag(MP_T3_ram_wb_to_jtag),
		.clk1(MP_plug_clk_1_clk_i),
		.enable0(MP_enable0),
		.hhh(MP_plug_clk_0_clk_i),
		.reset0(MP_plug_reset_0_reset_i)
	);
 xilinx_pll_base #(
 		.CLKOUT_NUM(pll_CLKOUT_NUM),
		.BANDWIDTH(pll_BANDWIDTH),
		.CLKFBOUT_MULT(pll_CLKFBOUT_MULT),
		.CLKFBOUT_PHASE(pll_CLKFBOUT_PHASE),
		.CLKIN1_PERIOD(pll_CLKIN1_PERIOD),
		.CLKOUT0_DIVIDE(pll_CLKOUT0_DIVIDE),
		.CLKOUT1_DIVIDE(pll_CLKOUT1_DIVIDE),
		.CLKOUT2_DIVIDE(pll_CLKOUT2_DIVIDE),
		.CLKOUT3_DIVIDE(pll_CLKOUT3_DIVIDE),
		.CLKOUT4_DIVIDE(pll_CLKOUT4_DIVIDE),
		.CLKOUT5_DIVIDE(pll_CLKOUT5_DIVIDE),
		.CLKOUT0_DUTY_CYCLE(pll_CLKOUT0_DUTY_CYCLE),
		.CLKOUT1_DUTY_CYCLE(pll_CLKOUT1_DUTY_CYCLE),
		.CLKOUT2_DUTY_CYCLE(pll_CLKOUT2_DUTY_CYCLE),
		.CLKOUT3_DUTY_CYCLE(pll_CLKOUT3_DUTY_CYCLE),
		.CLKOUT4_DUTY_CYCLE(pll_CLKOUT4_DUTY_CYCLE),
		.CLKOUT5_DUTY_CYCLE(pll_CLKOUT5_DUTY_CYCLE),
		.CLKOUT0_PHASE(pll_CLKOUT0_PHASE),
		.CLKOUT1_PHASE(pll_CLKOUT1_PHASE),
		.CLKOUT2_PHASE(pll_CLKOUT2_PHASE),
		.CLKOUT3_PHASE(pll_CLKOUT3_PHASE),
		.CLKOUT4_PHASE(pll_CLKOUT4_PHASE),
		.CLKOUT5_PHASE(pll_CLKOUT5_PHASE),
		.DIVCLK_DIVIDE(pll_DIVCLK_DIVIDE),
		.REF_JITTER1(pll_REF_JITTER1),
		.STARTUP_WAIT(pll_STARTUP_WAIT)
	)  pll 	(
		.clk_in(pll_clk_in),
		.clk_out(pll_socket_clk_array_clk_o),
		.reset_in(pll_reset_in),
		.reset_out(pll_socket_reset_0_reset_o)
	);
 
 	assign  MP_plug_clk_1_clk_i = pll_socket_clk_0_clk_o;
 	assign  MP_plug_clk_0_clk_i = pll_socket_clk_0_clk_o;
 	assign  MP_plug_reset_0_reset_i = pll_socket_reset_0_reset_o;

 

 	assign pll_socket_clk_0_clk_o = pll_socket_clk_array_clk_o;

 
//Wishbone slave address match
 endmodule

