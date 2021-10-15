// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

module BSCANE2_sim # (
parameter   JTAG_CHAIN  =4
)(
     output CAPTURE, // 1-bit output: CAPTURE output from TAP controller.
     output DRCK, // 1-bit output: Gated TCK output. When SEL is asserted, DRCK toggles when CAPTURE or SHIFT are asserted.
     output RESET, // 1-bit output: Reset output for TAP controller.
     output RUNTEST, // 1-bit output: Output asserted when TAP controller is in Run Test/Idle state.
     output SEL, // 1-bit output: USER instruction active output.
     output SHIFT, // 1-bit output: SHIFT output from TAP controller.
     output TCK, // 1-bit output: Test Clock output. Fabric connection to TAP Clock pin.
     output TDI, // 1-bit output: Test Data Input (TDI) output from TAP controller.
     output TMS, // 1-bit output: Test Mode Select output. Fabric connection to TAP.
     output UPDATE, // 1-bit output: UPDATE output from TAP controller
     input  TDO // 1-bit input: Test Data Output (TDO) input for USER function.
);


    wire    [2:0]  ir_out;
    wire    tdo;
    wire    [2:0]  ir_in;
    wire    tck;
    wire    tdi;
    wire    virtual_state_cdr;
    wire    virtual_state_cir;
    wire    virtual_state_e1dr;
    wire    virtual_state_e2dr;
    wire    virtual_state_pdr;
    wire    virtual_state_sdr;
    wire    virtual_state_udr;
    wire    virtual_state_uir;


    assign CAPTURE = virtual_state_cdr;
    assign DRCK = tck & (SEL & (CAPTURE | SHIFT)); // I am not using it. So I am not sure if the definition is correct
    assign RESET=1'b0;
    assign RUNTEST = 1'b0; // not used
    assign SEL = virtual_state_cdr | virtual_state_sdr | virtual_state_udr;
    assign SHIFT=virtual_state_sdr;
    assign TCK = tck;
    assign TDI = tdi;  
    assign TMS=1'b0;//not used by me
    assign UPDATE = virtual_state_udr;
    assign tdo = TDO;
    
    assign ir_out =ir_in;
    vjtag_sim #(
    
    	.VJTAG_INDEX(0)
    )
    the_vjtag_sim
    (
    	.ir_out(ir_out),
    	.tdo(tdo),
    	.ir_in(ir_in),
    	.tck(tck),
    	.tdi(tdi),
    	.virtual_state_cdr(virtual_state_cdr),
    	.virtual_state_cir(virtual_state_cir),
    	.virtual_state_e1dr(virtual_state_e1dr),
    	.virtual_state_e2dr(virtual_state_e2dr),
    	.virtual_state_pdr(virtual_state_pdr),
    	.virtual_state_sdr(virtual_state_sdr),
    	.virtual_state_udr(virtual_state_udr),
    	.virtual_state_uir(virtual_state_uir)
    );



endmodule



module vjtag_sim 
(
	ir_out,
	tdo,
	ir_in,
	tck,
	tdi,
	virtual_state_cdr,
	virtual_state_cir,
	virtual_state_e1dr,
	virtual_state_e2dr,
	virtual_state_pdr,
	virtual_state_sdr,
	virtual_state_udr,
	virtual_state_uir);

	input	[2:0]  ir_out;
	input	  tdo;
	output	[2:0]  ir_in;
	output	  tck;
	output	  tdi;
	output	  virtual_state_cdr;
	output	  virtual_state_cir;
	output	  virtual_state_e1dr;
	output	  virtual_state_e2dr;
	output	  virtual_state_pdr;
	output	  virtual_state_sdr;
	output	  virtual_state_udr;
	output	  virtual_state_uir;

	wire  sub_wire0;
	wire  sub_wire1;
	wire [2:0] sub_wire2;
	wire  sub_wire3;
	wire  sub_wire4;
	wire  sub_wire5;
	wire  sub_wire6;
	wire  sub_wire7;
	wire  sub_wire8;
	wire  sub_wire9;
	wire  sub_wire10;
	wire  virtual_state_cir = sub_wire0;
	wire  virtual_state_pdr = sub_wire1;
	wire [2:0] ir_in = sub_wire2[2:0];
	wire  tdi = sub_wire3;
	wire  virtual_state_udr = sub_wire4;
	wire  tck = sub_wire5;
	wire  virtual_state_e1dr = sub_wire6;
	wire  virtual_state_uir = sub_wire7;
	wire  virtual_state_cdr = sub_wire8;
	wire  virtual_state_e2dr = sub_wire9;
	wire  virtual_state_sdr = sub_wire10;


	parameter  VJTAG_INDEX=0;	
	
	/* 
    parameter SIM_ACTION = "((0,1,7,3),(0,2,ff,20),(0,1,6,3),(0,2,ffffffff,20),(0,2,1,20),(0,2,2,20),(0,2,3,20),(0,2,4,20))",  
    parameter SIM_N_SCAN=8,
    parameter SIM_SIM_LENGTH=198
	*/
    `define INCLUDE_SIM_INPUT
    `include "jtag_sim_input.v"
    
	sld_virtual_jtag	sld_virtual_jtag_component (
				.ir_out (ir_out),
				.tdo (tdo),
				.virtual_state_cir (sub_wire0),
				.virtual_state_pdr (sub_wire1),
				.ir_in (sub_wire2),
				.tdi (sub_wire3),
				.virtual_state_udr (sub_wire4),
				.tck (sub_wire5),
				.virtual_state_e1dr (sub_wire6),
				.virtual_state_uir (sub_wire7),
				.virtual_state_cdr (sub_wire8),
				.virtual_state_e2dr (sub_wire9),
				.virtual_state_sdr (sub_wire10)
				// synopsys translate_off
				,
				.jtag_state_cdr (),
				.jtag_state_cir (),
				.jtag_state_e1dr (),
				.jtag_state_e1ir (),
				.jtag_state_e2dr (),
				.jtag_state_e2ir (),
				.jtag_state_pdr (),
				.jtag_state_pir (),
				.jtag_state_rti (),
				.jtag_state_sdr (),
				.jtag_state_sdrs (),
				.jtag_state_sir (),
				.jtag_state_sirs (),
				.jtag_state_tlr (),
				.jtag_state_udr (),
				.jtag_state_uir (),
				.tms ()
				// synopsys translate_on
				);


	defparam
		sld_virtual_jtag_component.sld_auto_instance_index = "NO",
		sld_virtual_jtag_component.sld_instance_index = VJTAG_INDEX,
		sld_virtual_jtag_component.sld_ir_width = 3,
		sld_virtual_jtag_component.sld_sim_action = SIM_ACTION,
		sld_virtual_jtag_component.sld_sim_n_scan = SIM_N_SCAN,
		sld_virtual_jtag_component.sld_sim_total_length = SIM_LENGTH;


endmodule

