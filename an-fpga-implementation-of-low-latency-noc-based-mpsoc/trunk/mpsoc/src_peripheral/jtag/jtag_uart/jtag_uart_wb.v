module jtag_uart_wb #(
    parameter FPGA_VENDOR = "ALTERA",
    parameter SIM_BUFFER_SIZE   =100,  
    parameter SIM_WAIT_COUNT    =1000


)(
    reset,
    clk,
    irq,
    s_dat_i,
    s_sel_i,
    s_addr_i,  
    s_cti_i,
    s_stb_i,
    s_cyc_i,
    s_we_i,    
    s_dat_o,
    s_ack_o,
    RxD_din_sim,
    RxD_wr_sim,
    RxD_ready_sim
   
    
    

    
     

);

	localparam
		Dw            =   32,
		M_Aw          =   32,
		TAGw          =   3,
		SELw          =   4;
  


    input reset,clk;
//wishbone slave interface signals
    input   [Dw-1       :   0]      s_dat_i;
    input   [SELw-1     :   0]      s_sel_i;
    input    			    s_addr_i;  
    input   [TAGw-1     :   0]      s_cti_i;
    input                           s_stb_i;
    input                           s_cyc_i;
    input                           s_we_i;
    output irq;
    output  [Dw-1       :   0]  s_dat_o;
    output                     s_ack_o;


    
    
    input [7:0 ] RxD_din_sim;
    input RxD_wr_sim;
    output RxD_ready_sim;
    


generate 
if(FPGA_VENDOR=="ALTERA") begin :altera
`ifdef VERILATOR

	// code for simulation with verilator
  
	altera_simulator_UART #(
		.BUFFER_SIZE(SIM_BUFFER_SIZE),  
    		.WAIT_COUNT(SIM_WAIT_COUNT)    
	)
	Suart
	(
		.reset(reset),
		.clk(clk),
		.s_dat_i(s_dat_i),
		.s_sel_i(s_sel_i),
		.s_addr_i(s_addr_i),  
		.s_cti_i(s_cti_i),
		.s_stb_i(s_stb_i),
		.s_cyc_i(s_cyc_i),
		.s_we_i(s_we_i),    
		.s_dat_o(s_dat_o),
		.s_ack_o(s_ack_o),
		.RxD_din(RxD_din_sim),
		.RxD_wr(RxD_wr_sim),
		.RxD_ready(RxD_ready_sim)


	);
`else 
 `ifdef MODEL_TECH
	// code for simulation with modelsim
  
	altera_simulator_UART #(
		.BUFFER_SIZE(SIM_BUFFER_SIZE),  
    		.WAIT_COUNT(SIM_WAIT_COUNT)    
	)
	Suart
	(
		.reset(reset),
		.clk(clk),
		.s_dat_i(s_dat_i),
		.s_sel_i(s_sel_i),
		.s_addr_i(s_addr_i),  
		.s_cti_i(s_cti_i),
		.s_stb_i(s_stb_i),
		.s_cyc_i(s_cyc_i),
		.s_we_i(s_we_i),    
		.s_dat_o(s_dat_o),
		.s_ack_o(s_ack_o),
		.RxD_din(RxD_din_sim),
		.RxD_wr(RxD_wr_sim),
		.RxD_ready(RxD_ready_sim)


	);
 `else 
// code for synthesis

	altera_jtag_uart_wb Juart(
	  	.clk(clk),
		.rst(reset),
	  	.wb_irq(irq),
	  	.dat_o(s_dat_o),
	  	.ack_o(s_ack_o),
	  	.adr_i(s_addr_i),
	  	.stb_i(s_stb_i),
	  	.cyc_i(s_cyc_i),
	  	.we_i(s_we_i),
	  	.dat_i(s_dat_i),
	  	.dataavailable(),
	  	.readyfordata()
	);

	assign  RxD_ready_sim = 1'bX;


`endif
`endif
end
endgenerate

endmodule
