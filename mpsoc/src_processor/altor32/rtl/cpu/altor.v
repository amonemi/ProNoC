module altor #(
	parameter BOOT_VECTOR=32'h00000000,
	parameter ISR_VECTOR =32'h00000000,
    	parameter ENABLE_ICACHE="ENABLED",
    	parameter ENABLE_DCACHE="ENABLED",
    	parameter REGISTER_FILE_TYPE="ALTERA",
	parameter SUPPORT_32REGS="ENABLED",
	parameter PIPELINED_FETCH="ENABLED"
   
)
(
    // General
    input               clk_i /*verilator public*/,
    input               rst_i /*verilator public*/,
    input               en_i /*verilator public*/,


    input               intr_i /*verilator public*/,
    input               nmi_i /*verilator public*/,
    output              fault_o /*verilator public*/,
    output              break_o /*verilator public*/,

    // Instruction memory
    output [31:0]       imem_addr_o /*verilator public*/,
    input [31:0]        imem_dat_i /*verilator public*/,
    output [2:0]        imem_cti_o /*verilator public*/,
    output              imem_cyc_o /*verilator public*/,
    output              imem_stb_o /*verilator public*/,
 //   input               imem_stall_i/*verilator public*/,
    input               imem_ack_i/*verilator public*/,  

    // Data memory
    output [31:0]       dmem_addr_o /*verilator public*/,
    output [31:0]       dmem_dat_o /*verilator public*/,
    input [31:0]        dmem_dat_i /*verilator public*/,
    output [3:0]        dmem_sel_o /*verilator public*/,
    output [2:0]        dmem_cti_o /*verilator public*/,
    output              dmem_cyc_o /*verilator public*/,
    output              dmem_we_o /*verilator public*/,
    output              dmem_stb_o /*verilator public*/,
   // input               dmem_stall_i/*verilator public*/,
    input               dmem_ack_i/*verilator public*/
);


	wire [31:0] i_addr_o,d_addr_o;
	wire imem_stall_i,dmem_stall_i;
	cpu
	#(
	    .BOOT_VECTOR(BOOT_VECTOR),
	    .ISR_VECTOR(ISR_VECTOR),
	    .REGISTER_FILE_TYPE(REGISTER_FILE_TYPE),
	    .ENABLE_ICACHE(ENABLE_ICACHE),
	    .ENABLE_DCACHE(ENABLE_DCACHE),
	    .SUPPORT_32REGS(SUPPORT_32REGS),
	    .PIPELINED_FETCH(SUPPORT_32REGS)
	)
	u1_cpu
	(
	    .clk_i(clk_i),
	    .rst_i(rst_i),

	    .intr_i(intr_i),
	    .nmi_i(nmi_i),
	    
	    // Status
	    .fault_o(fault_o),
	    .break_o(break_o),
	    
	    // Instruction memory
	    .imem_addr_o(i_addr_o),
	    .imem_dat_i(imem_dat_i),
	    .imem_cti_o(imem_cti_o),
	    .imem_cyc_o(imem_cyc_o),
	    .imem_stb_o(imem_stb_o),
	    .imem_stall_i(imem_stall_i),
	    .imem_ack_i(imem_ack_i),
	    
	    // Data memory
	    .dmem_addr_o(d_addr_o),
	    .dmem_dat_o(dmem_dat_o),
	    .dmem_dat_i(dmem_dat_i),
	    .dmem_sel_o(dmem_sel_o),
	    .dmem_cti_o(dmem_cti_o),
	    .dmem_cyc_o(dmem_cyc_o),
	    .dmem_we_o(dmem_we_o),
	    .dmem_stb_o(dmem_stb_o),
	    .dmem_stall_i(dmem_stall_i),
	    .dmem_ack_i(dmem_ack_i)
	);

	assign imem_addr_o= {2'b00,i_addr_o[31:2]};
	assign dmem_addr_o= {2'b00,d_addr_o[31:2]};

	reg imem_stb_o_delay,dmem_stb_o_delay;
	/*
	always @(posedge clk_i) begin
		if(rst_i) begin 
			imem_stb_o_delay<=1'b0;
			dmem_stb_o_delay<=1'b0;
		end else begin 
			imem_stb_o_delay<=imem_stb_o;
			dmem_stb_o_delay<=dmem_stb_o;
		end	
	end
	*/

	wire stall_i=~en_i;
	assign imem_stall_i = (imem_stb_o & ~imem_ack_i)|stall_i ;
	assign dmem_stall_i = (dmem_stb_o & ~dmem_ack_i)|stall_i ;

endmodule
