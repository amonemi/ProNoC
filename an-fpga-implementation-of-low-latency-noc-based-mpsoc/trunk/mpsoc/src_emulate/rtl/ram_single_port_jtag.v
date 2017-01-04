

module ram_single_port_jtag #(
	parameter Dw	=32, 
	parameter Aw	=10,
	parameter BENw	=4,
	parameter JTAG_INDEX= 2 //use for programming the memory at run time
	
)
(
    clk,
    reset,	
    //memory interface
    data_a,
    addr_a,
    we_a,
    byteena_a,
    q_a
   
);
    input		    clk;
    input		    reset;
    input   [Dw-1   :   0]  data_a;
    input   [Aw-1   :   0]  addr_a;
    input		    we_a;
    input   [BENw-1 :	0]  byteena_a;
    output  [Dw-1   :   0]  q_a;
     
    function integer log2;
      input integer number; begin   
         log2=0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end    
      end   
   endfunction // log2 
 	
	//jtag connected to the second port
	wire   [Dw-1   :   0]  data_b;
	wire   [Aw-1   :   0]  addr_b;
	wire		       we_b;
	wire   [Dw-1   :   0]  q_b;

	
	
	
	 
	 
	 
	

	reg jtag_ack;
	wire jtag_we_o, jtag_stb_o;

	localparam Sw= log2(Aw+1);

	vjtag_wb #(
		.VJTAG_INDEX(JTAG_INDEX),
		.DW(Dw),
		.AW(Aw),
		.SW(Sw),
	
		//wishbone port parameters
	    	.M_Aw(Aw)
	    
	

	)vjtag_inst(
		.clk(clk),
		.reset(reset),	
		.status_i(Aw), // Jtag can read memory size as status
	
		 //wishbone master interface signals
		.m_sel_o(),
		.m_dat_o(data_b),
		.m_addr_o(addr_b),
		.m_cti_o(),
		.m_stb_o(jtag_stb_o),
		.m_cyc_o(),
		.m_we_o(jtag_we_o),
		.m_dat_i(q_b),
		.m_ack_i(jtag_ack)    
	   
	
	);

	assign we_b = jtag_stb_o & jtag_we_o;

	always @(posedge clk )begin 
		jtag_ack<=jtag_stb_o;	
	end





	

	localparam  RAM_ID = {"ENABLE_RUNTIME_MOD=NO"};
	

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
		.width_byteena_a(BENw)
	
	) ram_inst(
		.clock0			(clk),
		
		.address_a		(addr_a),
		.wren_a			(we_a),
		.data_a			(data_a),
		.q_a			(q_a),
		.byteena_a      	(byteena_a),		 
		
		
		.address_b		(addr_b),
		.wren_b			(we_b),
		.data_b			(data_b),
		.q_b			(q_b),
		.byteena_b		(1'b1),		
		

		.rden_a 		(1'b1),
		.rden_b			(1'b1),
		.clock1			(1'b1),
		.clocken0 		(1'b1),
		.clocken1 		(1'b1),
		.clocken2 		(1'b1),
		.clocken3 		(1'b1),
		.aclr0			(1'b0),
		.aclr1			(1'b0),		
		.addressstall_a		(1'b0),
		.addressstall_b 	(1'b0),
		.eccstatus		(    )
	);




	
	

endmodule
