`include "or1200_defines.v"

module or1200 #(
	parameter dw = `OR1200_OPERAND_WIDTH,
	parameter aw = `OR1200_OPERAND_WIDTH,
	parameter ppic_ints = `OR1200_PIC_INTS,
	parameter boot_adr = `OR1200_BOOT_ADR

)(
	clk,
	reset,
	en_i,
	pic_ints_i,
	iwb_ack_i,//normaltermination
	iwb_err_i,//terminationw/error
	iwb_rty_i,//terminationw/retry
	iwb_dat_i,//databus
	iwb_cyc_o,//cyclevalid
	iwb_adr_o,//addressbuss
	iwb_stb_o,//strobe
	iwb_we_o,//indicateswritetransfer
	iwb_sel_o,//byteselects
	iwb_dat_o,//databus
	iwb_cti_o,//cycletypeidentifier
	iwb_bte_o,//bursttypeextension

	dwb_ack_i,//normaltermination
	dwb_err_i,//terminationw/error
	dwb_rty_i,//terminationw/retry
	dwb_dat_i,//databus
	dwb_cyc_o,//cyclevalid
	dwb_adr_o,//addressbuss
	dwb_stb_o,//strobe
	dwb_we_o,//indicateswritetransfer
	dwb_sel_o,//byteselects
	dwb_dat_o,//databus
	dwb_cti_o,//cycletypeidentifier
	dwb_bte_o//bursttypeextension
);


	input			clk;
	input			reset;
	input			en_i;
	input	[ppic_ints-1:0]	pic_ints_i;

	//
	// Instruction WISHBONE interface
	//

	input			iwb_ack_i;	// normal termination	
	input			iwb_err_i;	// termination w/ error
	input			iwb_rty_i;	// termination w/ retry
	input	[dw-1:0]	iwb_dat_i;	// input data bus
	output			iwb_cyc_o;	// cycle valid output
	output	[aw-1:0]	iwb_adr_o;	// address bus outputs
	output			iwb_stb_o;	// strobe output
	output			iwb_we_o;	// indicates write transfer
	output	[3:0]		iwb_sel_o;	// byte select outputs
	output	[dw-1:0]	iwb_dat_o;	// output data bus
	output	[2:0]		iwb_cti_o;	// cycle type identifier
	output	[1:0]		iwb_bte_o;	// burst type extension
	

	//
	// Data WISHBONE interface
	//

	input			dwb_ack_i;	// normal termination
	input			dwb_err_i;	// termination w/ error
	input			dwb_rty_i;	// termination w/ retry
	input	[dw-1:0]	dwb_dat_i;	// input data bus	
	output			dwb_cyc_o;	// cycle valid output
	output	[aw-1:0]	dwb_adr_o;	// address bus outputs
	output			dwb_stb_o;	// strobe output
	output			dwb_we_o;	// indicates write transfer
	output	[3:0]		dwb_sel_o;	// byte select outputs
	output	[dw-1:0]	dwb_dat_o;	// output data bus
	output	[2:0]		dwb_cti_o;	// cycle type identifier
	output	[1:0]		dwb_bte_o;	// burst type extension
	
	wire [31:0] 				  dbg_dat_i;
	wire [31:0] 				  dbg_adr_i;
	wire 				  dbg_we_i;
	wire 				  dbg_stb_i;
	wire 				  dbg_ack_o;
	wire [31:0] 				  dbg_dat_o;
   
	wire 				  dbg_stall_i;
	wire 				  dbg_ewt_i;
	wire [3:0] 				  dbg_lss_o;
	wire [1:0] 				  dbg_is_o;
	wire [10:0] 				  dbg_wp_o;
	wire 				  dbg_bp_o;
	wire 				  dbg_rst;   

	wire cpustall = ~   en_i;


	wire [aw-1:0] dadr_o,iadr_o;

	or1200_top #(
		.dw(dw),
		.aw(aw),
		.ppic_ints(ppic_ints),
		.boot_adr(boot_adr)
	) 
	the_top
	(
	// Instruction bus, clocks, reset
	.iwb_clk_i			(clk),
	.iwb_rst_i			(reset),
	.iwb_ack_i			(iwb_ack_i),
	.iwb_err_i			(iwb_err_i),
	.iwb_rty_i			(iwb_rty_i),
	.iwb_dat_i			(iwb_dat_i),
	
	.iwb_cyc_o			(iwb_cyc_o),
	.iwb_adr_o			(iadr_o),
	.iwb_stb_o			(iwb_stb_o),
	.iwb_we_o			(iwb_we_o),
	.iwb_sel_o			(iwb_sel_o),
	.iwb_dat_o			(iwb_dat_o),
	.iwb_cti_o			(iwb_cti_o),
	.iwb_bte_o			(iwb_bte_o),
	
	// Data bus, clocks, reset            
	.dwb_clk_i			(clk),
	.dwb_rst_i			(reset),
	.dwb_ack_i			(dwb_ack_i),
	.dwb_err_i			(dwb_err_i),
	.dwb_rty_i			(dwb_rty_i),
	.dwb_dat_i			(dwb_dat_i),

	.dwb_cyc_o			(dwb_cyc_o),
	.dwb_adr_o			(dadr_o),
	.dwb_stb_o			(dwb_stb_o),
	.dwb_we_o			(dwb_we_o),
	.dwb_sel_o			(dwb_sel_o),
	.dwb_dat_o			(dwb_dat_o),
	.dwb_cti_o			(dwb_cti_o),
	.dwb_bte_o			(dwb_bte_o),
	
	// Debug interface ports
	.dbg_stall_i			(dbg_stall_i),
	//.dbg_ewt_i			(dbg_ewt_i),
	.dbg_ewt_i			(1'b0),
	.dbg_lss_o			(dbg_lss_o),
	.dbg_is_o			(dbg_is_o),
	.dbg_wp_o			(dbg_wp_o),
	.dbg_bp_o			(dbg_bp_o),

	.dbg_adr_i			(dbg_adr_i),      
	.dbg_we_i			(dbg_we_i ), 
	.dbg_stb_i			(dbg_stb_i),          
	.dbg_dat_i			(dbg_dat_i),
	.dbg_dat_o			(dbg_dat_o),
	.dbg_ack_o			(dbg_ack_o),
	
	.pm_clksd_o			(),
	.pm_dc_gate_o			(),
	.pm_ic_gate_o			(),
	.pm_dmmu_gate_o			(),
	.pm_immu_gate_o			(),
	.pm_tt_gate_o			(),
	.pm_cpu_gate_o			(),
	.pm_wakeup_o			(),
	.pm_lvolt_o			(),

	// Core clocks, resets
	.clk_i				(clk),
	.rst_i				(reset),
	
	.clmode_i			(2'b00),
	// Interrupts      
	.pic_ints_i			(pic_ints_i),
	.sig_tick			(),
	/*
	 .mbist_so_o			(),
	 .mbist_si_i			(0),
	 .mbist_ctrl_i			(0),
	 */

	.pm_cpustall_i			(cpustall)

	);


	assign dwb_adr_o= {2'b00,dadr_o[31:2]};
	assign iwb_adr_o= {2'b00,iadr_o[31:2]};

	assign dbg_adr_i = 0;   
	assign dbg_dat_i = 0;   
	assign dbg_stb_i = 0;   
	assign dbg_we_i = 0;
	assign dbg_stall_i = 0;

endmodule

