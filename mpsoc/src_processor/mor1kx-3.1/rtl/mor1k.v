
module mor1k #(
    parameter OPTION_OPERAND_WIDTH=32,
    parameter IRQ_NUM=32

)(

    clk,
    rst,
    cpu_en,

    // Wishbone interface
    iwbm_adr_o,
    iwbm_stb_o,
    iwbm_cyc_o,
    iwbm_sel_o,
    iwbm_we_o,
    iwbm_cti_o,
    iwbm_bte_o,
    iwbm_dat_o,
    iwbm_err_i,
    iwbm_ack_i,
    iwbm_dat_i,
    iwbm_rty_i,

    dwbm_adr_o,
    dwbm_stb_o,
    dwbm_cyc_o,
    dwbm_sel_o,
    dwbm_we_o,
    dwbm_cti_o,
    dwbm_bte_o,
    dwbm_dat_o,
    dwbm_err_i,
    dwbm_ack_i,
    dwbm_dat_i,
    dwbm_rty_i,
    
    irq_i
    

);


    input                clk;
    input                rst;

    // Wishbone interface
    output [31:0]         iwbm_adr_o;
    output                iwbm_stb_o;
    output                iwbm_cyc_o;
    output [3:0]          iwbm_sel_o;
    output                iwbm_we_o;
    output [2:0]          iwbm_cti_o;
    output [1:0]          iwbm_bte_o;
    output [31:0]         iwbm_dat_o;
    input                 iwbm_err_i;
    input                 iwbm_ack_i;
    input [31:0]          iwbm_dat_i;
    input                 iwbm_rty_i;

    output [31:0]         dwbm_adr_o;
    output                dwbm_stb_o;
    output                dwbm_cyc_o;
    output [3:0]          dwbm_sel_o;
    output                dwbm_we_o;
    output [2:0]          dwbm_cti_o;
    output [1:0]          dwbm_bte_o;
    output [31:0]         dwbm_dat_o;
    input                 dwbm_err_i;
    input                 dwbm_ack_i;
    input [31:0]          dwbm_dat_i;
    input                 dwbm_rty_i;
    input [IRQ_NUM-1:0]   irq_i;
    input                 cpu_en;
    
    
    
    
     // Debug interface
    wire [15:0]          du_addr_i= 16'd0;
    wire                 du_stb_i=1'd0;
    wire [OPTION_OPERAND_WIDTH-1:0]  du_dat_i={OPTION_OPERAND_WIDTH{1'b0}};
    wire                 du_we_i=1'b0;
   
    // Stall control from debug interface
    wire                 du_stall_i=~cpu_en;
   // wire                du_stall_o,
  
  wire [31:0] dadr_o,iadr_o;
   assign iwbm_adr_o= {2'b00,iadr_o[31:2]};
   assign dwbm_adr_o= {2'b00,dadr_o[31:2]};
   



mor1kx #(
	.FEATURE_DEBUGUNIT("ENABLED"),
	.FEATURE_CMOV("ENABLED"),
	.FEATURE_INSTRUCTIONCACHE("ENABLED"),
	.OPTION_ICACHE_BLOCK_WIDTH(5),
	.OPTION_ICACHE_SET_WIDTH(8),
	.OPTION_ICACHE_WAYS(2),
	.OPTION_ICACHE_LIMIT_WIDTH(32),
	.FEATURE_IMMU("ENABLED"),
	.FEATURE_DATACACHE("ENABLED"),
	.OPTION_DCACHE_BLOCK_WIDTH(5),
	.OPTION_DCACHE_SET_WIDTH(8),
	.OPTION_DCACHE_WAYS(2),
	.OPTION_DCACHE_LIMIT_WIDTH(31),
	.FEATURE_DMMU("ENABLED"),
	.OPTION_PIC_TRIGGER("LATCHED_LEVEL"),

	.IBUS_WB_TYPE("B3_REGISTERED_FEEDBACK"),
	.DBUS_WB_TYPE("B3_REGISTERED_FEEDBACK"),
	.OPTION_CPU0("CAPPUCCINO")
	//.OPTION_RESET_PC(32'hf0000000)
) 
mor1kx0 
(
    .iwbm_adr_o(iadr_o),
    .iwbm_stb_o(iwbm_stb_o),
    .iwbm_cyc_o(iwbm_cyc_o),
    .iwbm_sel_o(iwbm_sel_o),
    .iwbm_we_o(iwbm_we_o),
    .iwbm_cti_o(iwbm_cti_o),
    .iwbm_bte_o(iwbm_bte_o),
    .iwbm_dat_o(iwbm_dat_o),
    .iwbm_err_i(iwbm_err_i),
    .iwbm_ack_i(iwbm_ack_i),
    .iwbm_dat_i(iwbm_dat_i),
    .iwbm_rty_i(iwbm_rty_i),
    
    
    .dwbm_adr_o(dadr_o),
    .dwbm_stb_o(dwbm_stb_o),
    .dwbm_cyc_o(dwbm_cyc_o),
    .dwbm_sel_o(dwbm_sel_o),
    .dwbm_we_o(dwbm_we_o),
    .dwbm_cti_o(dwbm_cti_o),
    .dwbm_bte_o(dwbm_bte_o),
    .dwbm_dat_o(dwbm_dat_o),
    .dwbm_err_i(dwbm_err_i),
    .dwbm_ack_i(dwbm_ack_i),
    .dwbm_dat_i(dwbm_dat_i),
    .dwbm_rty_i(dwbm_rty_i),

	.clk(clk),
	.rst(rst),

	

	.avm_d_address_o (),
	.avm_d_byteenable_o (),
	.avm_d_read_o (),
	.avm_d_readdata_i (32'h00000000),
	.avm_d_burstcount_o (),
	.avm_d_write_o (),
	.avm_d_writedata_o (),
	.avm_d_waitrequest_i (1'b0),
	.avm_d_readdatavalid_i (1'b0),

	.avm_i_address_o (),
	.avm_i_byteenable_o (),
	.avm_i_read_o (),
	.avm_i_readdata_i (32'h00000000),
	.avm_i_burstcount_o (),
	.avm_i_waitrequest_i (1'b0),
	.avm_i_readdatavalid_i (1'b0),

	.irq_i(irq_i),

	.traceport_exec_valid_o  (),
	.traceport_exec_pc_o     (),
	.traceport_exec_insn_o   (),
	.traceport_exec_wbdata_o (),
	.traceport_exec_wbreg_o  (),
	.traceport_exec_wben_o   (),

	.multicore_coreid_i   (32'd0),
	.multicore_numcores_i (32'd0),

	.snoop_adr_i (32'd0),
	.snoop_en_i  (1'b0),

	.du_addr_i(du_addr_i),
    .du_stb_i(du_stb_i),
    .du_dat_i(du_dat_i),
    .du_we_i(du_we_i),
    .du_dat_o( ),
    .du_ack_o( ),
    .du_stall_i(du_stall_i),
    .du_stall_o( )
);


endmodule

