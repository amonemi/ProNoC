module jtag_test #(
    	parameter	ni_B= 4 ,
	parameter	ni_NX= 2 ,
	parameter	ni_NY= 2 ,
	parameter	ni_RAM_WIDTH_IN_WORD=   13 ,
	parameter	ni_ROUTE_NAME=    "XY"      ,
	parameter	ni_TOPOLOGY=    "MESH" ,
	parameter	ni_V= 4
)(
	clk_source_clk_in, 
	clk_source_reset_in, 
	jtag_altera_irq, 
	jtag_altera_led, 
	ni_credit_in, 
	ni_credit_out, 
	ni_current_x, 
	ni_current_y, 
	ni_flit_in, 
	ni_flit_in_wr, 
	ni_flit_out, 
	ni_flit_out_wr, 
	ni_irq
);
  
  	function integer log2;
  		input integer number; begin	
          	log2=0;	
          	while(2**log2<number) begin	
        		  	log2=log2+1;	
         		end	
        		end	
     	endfunction // log2 
  
 	localparam	jtag_altera_BASE_ADDR= 32'h100;
	localparam	jtag_altera_Dw=   32;
	localparam	jtag_altera_IDEAL=1;
	localparam	jtag_altera_M_Aw=   jtag_altera_RAM_WIDTH_IN_WORD;
	localparam	jtag_altera_NI_BASE_ADDR= 32'h0;
	localparam	jtag_altera_NI_PTR_WIDTH=	  19;
	localparam	jtag_altera_PTR_WIDTH=   jtag_altera_NI_PTR_WIDTH-2;
	localparam	jtag_altera_RAM_WIDTH_IN_WORD=   13;
	localparam	jtag_altera_RD_RAM_TAG=;
	localparam	jtag_altera_SELw=   4;
	localparam	jtag_altera_ST_NUM=4;
	localparam	jtag_altera_S_Aw=   3;
	localparam	jtag_altera_TAGw=   3;
	localparam	jtag_altera_WAIT_1=4;
	localparam	jtag_altera_WAIT_NI_DONE=8;
	localparam	jtag_altera_WRITE_NI=2;
	localparam	jtag_altera_WR_RAM_TAG=;
	localparam	jtag_altera_WR_RAMw=8;

 	localparam	ni_DEBUG_EN=   1;
	localparam	ni_Dw=   32;
	localparam	ni_Fpay= 32;
	localparam	ni_Fw=2 + ni_V + ni_Fpay;
	localparam	ni_M_Aw=   ni_RAM_WIDTH_IN_WORD;
	localparam	ni_NI_PCK_SIZE_WIDTH= 13;
	localparam	ni_NI_PTR_WIDTH=19;
	localparam	ni_P= 5;
	localparam	ni_ROUTE_TYPE=   (ni_ROUTE_NAME == "XY" || ni_ROUTE_NAME == "TRANC_XY" )?    "DETERMINISTIC" : 
			            (ni_ROUTE_NAME == "DUATO" || ni_ROUTE_NAME == "TRANC_DUATO" )?   "FULL_ADAPTIVE": "PAR_ADAPTIVE" ;
	localparam	ni_SELw=   4    ;
	localparam	ni_S_Aw=   3;
	localparam	ni_TAGw=   3;
	localparam	ni_Xw=log2( ni_NX );
	localparam	ni_Yw=log2( ni_NY );

 	localparam	bus_Aw=	32;
	localparam	bus_Dw=	32;
	localparam	bus_M=2;
	localparam	bus_S=2;
	localparam	bus_SELw=	4;
	localparam	bus_TAGw=	3    ;

 	input			clk_source_clk_in;
 	input			clk_source_reset_in;

 	output			jtag_altera_irq;
 	output			jtag_altera_led;

 	input	 [ ni_V-1    :   0    ] ni_credit_in;
 	output	 [ ni_V-1:   0    ] ni_credit_out;
 	input	 [ ni_Xw-1   :   0    ] ni_current_x;
 	input	 [ ni_Yw-1   :   0    ] ni_current_y;
 	input	 [ ni_Fw-1   :   0    ] ni_flit_in;
 	input			ni_flit_in_wr;
 	output	 [ ni_Fw-1   :   0    ] ni_flit_out;
 	output			ni_flit_out_wr;
 	output			ni_irq;

 	wire			 clk_source_socket_clk_0_clk_o;
 	wire			 clk_source_socket_reset_0_reset_o;

 	wire			 jtag_altera_plug_clk_0_clk_i;
 	wire			 jtag_altera_plug_wb_master_0_ack_i;
 	wire	[ jtag_altera_M_Aw-1          :   0 ] jtag_altera_plug_wb_master_0_adr_o;
 	wire			 jtag_altera_plug_wb_master_0_cyc_o;
 	wire	[ jtag_altera_Dw-1           :  0 ] jtag_altera_plug_wb_master_0_dat_i;
 	wire	[ jtag_altera_Dw-1            :   0 ] jtag_altera_plug_wb_master_0_dat_o;
 	wire			 jtag_altera_plug_wb_master_0_err_i;
 	wire			 jtag_altera_plug_wb_master_0_rty_i;
 	wire	[ jtag_altera_SELw-1          :   0 ] jtag_altera_plug_wb_master_0_sel_o;
 	wire			 jtag_altera_plug_wb_master_0_stb_o;
 	wire	[ jtag_altera_TAGw-1          :   0 ] jtag_altera_plug_wb_master_0_tag_o;
 	wire			 jtag_altera_plug_wb_master_0_we_o;
 	wire			 jtag_altera_plug_reset_0_reset_i;
 	wire			 jtag_altera_plug_wb_slave_0_ack_o;
 	wire	[ jtag_altera_S_Aw-1     :   0 ] jtag_altera_plug_wb_slave_0_adr_i;
 	wire			 jtag_altera_plug_wb_slave_0_cyc_i;
 	wire	[ jtag_altera_Dw-1       :   0 ] jtag_altera_plug_wb_slave_0_dat_i;
 	wire	[ jtag_altera_Dw-1       :   0 ] jtag_altera_plug_wb_slave_0_dat_o;
 	wire			 jtag_altera_plug_wb_slave_0_err_o;
 	wire			 jtag_altera_plug_wb_slave_0_rty_o;
 	wire	[ jtag_altera_SELw-1     :   0 ] jtag_altera_plug_wb_slave_0_sel_i;
 	wire			 jtag_altera_plug_wb_slave_0_stb_i;
 	wire	[ jtag_altera_TAGw-1     :   0 ] jtag_altera_plug_wb_slave_0_tag_i;
 	wire			 jtag_altera_plug_wb_slave_0_we_i;

 	wire			 ni_plug_clk_0_clk_i;
 	wire			 ni_plug_wb_master_0_ack_i;
 	wire	[ ni_M_Aw-1          :   0 ] ni_plug_wb_master_0_adr_o;
 	wire			 ni_plug_wb_master_0_cyc_o;
 	wire	[ ni_Dw-1           :  0 ] ni_plug_wb_master_0_dat_i;
 	wire	[ ni_Dw-1            :   0 ] ni_plug_wb_master_0_dat_o;
 	wire			 ni_plug_wb_master_0_err_i;
 	wire			 ni_plug_wb_master_0_rty_i;
 	wire	[ ni_SELw-1          :   0 ] ni_plug_wb_master_0_sel_o;
 	wire			 ni_plug_wb_master_0_stb_o;
 	wire	[ ni_TAGw-1          :   0 ] ni_plug_wb_master_0_tag_o;
 	wire			 ni_plug_wb_master_0_we_o;
 	wire			 ni_plug_reset_0_reset_i;
 	wire			 ni_plug_wb_slave_0_ack_o;
 	wire	[ ni_S_Aw-1     :   0 ] ni_plug_wb_slave_0_adr_i;
 	wire			 ni_plug_wb_slave_0_cyc_i;
 	wire	[ ni_Dw-1       :   0 ] ni_plug_wb_slave_0_dat_i;
 	wire	[ ni_Dw-1       :   0 ] ni_plug_wb_slave_0_dat_o;
 	wire			 ni_plug_wb_slave_0_err_o;
 	wire			 ni_plug_wb_slave_0_rty_o;
 	wire	[ ni_SELw-1     :   0 ] ni_plug_wb_slave_0_sel_i;
 	wire			 ni_plug_wb_slave_0_stb_i;
 	wire	[ ni_TAGw-1     :   0 ] ni_plug_wb_slave_0_tag_i;
 	wire			 ni_plug_wb_slave_0_we_i;

 	wire			 bus_plug_clk_0_clk_i;
 	wire	[ bus_M-1        :   0 ] bus_socket_wb_master_array_ack_o;
 	wire			 bus_socket_wb_master_1_ack_o;
 	wire			 bus_socket_wb_master_0_ack_o;
 	wire	[ (bus_Aw*bus_M)-1      :   0 ] bus_socket_wb_master_array_adr_i;
 	wire	[ bus_Aw-1      :   0 ] bus_socket_wb_master_1_adr_i;
 	wire	[ bus_Aw-1      :   0 ] bus_socket_wb_master_0_adr_i;
 	wire	[ bus_M-1        :   0 ] bus_socket_wb_master_array_cyc_i;
 	wire			 bus_socket_wb_master_1_cyc_i;
 	wire			 bus_socket_wb_master_0_cyc_i;
 	wire	[ (bus_Dw*bus_M)-1      :   0 ] bus_socket_wb_master_array_dat_i;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_master_1_dat_i;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_master_0_dat_i;
 	wire	[ (bus_Dw*bus_M)-1      :   0 ] bus_socket_wb_master_array_dat_o;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_master_1_dat_o;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_master_0_dat_o;
 	wire	[ bus_M-1        :   0 ] bus_socket_wb_master_array_err_o;
 	wire			 bus_socket_wb_master_1_err_o;
 	wire			 bus_socket_wb_master_0_err_o;
 	wire	[ bus_Aw-1       :   0 ] bus_socket_wb_addr_map_0_grant_addr;
 	wire	[ bus_M-1        :   0 ] bus_socket_wb_master_array_rty_o;
 	wire			 bus_socket_wb_master_1_rty_o;
 	wire			 bus_socket_wb_master_0_rty_o;
 	wire	[ (bus_SELw*bus_M)-1    :   0 ] bus_socket_wb_master_array_sel_i;
 	wire	[ bus_SELw-1    :   0 ] bus_socket_wb_master_1_sel_i;
 	wire	[ bus_SELw-1    :   0 ] bus_socket_wb_master_0_sel_i;
 	wire	[ bus_M-1        :   0 ] bus_socket_wb_master_array_stb_i;
 	wire			 bus_socket_wb_master_1_stb_i;
 	wire			 bus_socket_wb_master_0_stb_i;
 	wire	[ (bus_TAGw*bus_M)-1    :   0 ] bus_socket_wb_master_array_tag_i;
 	wire	[ bus_TAGw-1    :   0 ] bus_socket_wb_master_1_tag_i;
 	wire	[ bus_TAGw-1    :   0 ] bus_socket_wb_master_0_tag_i;
 	wire	[ bus_M-1        :   0 ] bus_socket_wb_master_array_we_i;
 	wire			 bus_socket_wb_master_1_we_i;
 	wire			 bus_socket_wb_master_0_we_i;
 	wire			 bus_plug_reset_0_reset_i;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_slave_array_ack_i;
 	wire			 bus_socket_wb_slave_1_ack_i;
 	wire			 bus_socket_wb_slave_0_ack_i;
 	wire	[ (bus_Aw*bus_S)-1      :   0 ] bus_socket_wb_slave_array_adr_o;
 	wire	[ bus_Aw-1      :   0 ] bus_socket_wb_slave_1_adr_o;
 	wire	[ bus_Aw-1      :   0 ] bus_socket_wb_slave_0_adr_o;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_slave_array_cyc_o;
 	wire			 bus_socket_wb_slave_1_cyc_o;
 	wire			 bus_socket_wb_slave_0_cyc_o;
 	wire	[ (bus_Dw*bus_S)-1      :   0 ] bus_socket_wb_slave_array_dat_i;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_1_dat_i;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_0_dat_i;
 	wire	[ (bus_Dw*bus_S)-1      :   0 ] bus_socket_wb_slave_array_dat_o;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_1_dat_o;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_0_dat_o;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_slave_array_err_i;
 	wire			 bus_socket_wb_slave_1_err_i;
 	wire			 bus_socket_wb_slave_0_err_i;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_slave_array_rty_i;
 	wire			 bus_socket_wb_slave_1_rty_i;
 	wire			 bus_socket_wb_slave_0_rty_i;
 	wire	[ (bus_SELw*bus_S)-1    :   0 ] bus_socket_wb_slave_array_sel_o;
 	wire	[ bus_SELw-1    :   0 ] bus_socket_wb_slave_1_sel_o;
 	wire	[ bus_SELw-1    :   0 ] bus_socket_wb_slave_0_sel_o;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_addr_map_0_sel_one_hot;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_slave_array_stb_o;
 	wire			 bus_socket_wb_slave_1_stb_o;
 	wire			 bus_socket_wb_slave_0_stb_o;
 	wire	[ (bus_TAGw*bus_S)-1    :   0 ] bus_socket_wb_slave_array_tag_o;
 	wire	[ bus_TAGw-1    :   0 ] bus_socket_wb_slave_1_tag_o;
 	wire	[ bus_TAGw-1    :   0 ] bus_socket_wb_slave_0_tag_o;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_slave_array_we_o;
 	wire			 bus_socket_wb_slave_1_we_o;
 	wire			 bus_socket_wb_slave_0_we_o;

 clk_source  clk_source 	(
		.clk_in(clk_source_clk_in),
		.clk_out(clk_source_socket_clk_0_clk_o),
		.reset_in(clk_source_reset_in),
		.reset_out(clk_source_socket_reset_0_reset_o)
	);
 jtag #(
 		.BASE_ADDR(jtag_altera_BASE_ADDR),
		.Dw(jtag_altera_Dw),
		.IDEAL(jtag_altera_IDEAL),
		.M_Aw(jtag_altera_M_Aw),
		.NI_BASE_ADDR(jtag_altera_NI_BASE_ADDR),
		.NI_PTR_WIDTH(jtag_altera_NI_PTR_WIDTH),
		.PTR_WIDTH(jtag_altera_PTR_WIDTH),
		.RAM_WIDTH_IN_WORD(jtag_altera_RAM_WIDTH_IN_WORD),
		.RD_RAM_TAG(jtag_altera_RD_RAM_TAG),
		.SELw(jtag_altera_SELw),
		.ST_NUM(jtag_altera_ST_NUM),
		.S_Aw(jtag_altera_S_Aw),
		.TAGw(jtag_altera_TAGw),
		.WAIT_1(jtag_altera_WAIT_1),
		.WAIT_NI_DONE(jtag_altera_WAIT_NI_DONE),
		.WRITE_NI(jtag_altera_WRITE_NI),
		.WR_RAM_TAG(jtag_altera_WR_RAM_TAG),
		.WR_RAMw(jtag_altera_WR_RAMw)
	)  jtag_altera 	(
		.clk(jtag_altera_plug_clk_0_clk_i),
		.irq(jtag_altera_irq),
		.led(jtag_altera_led),
		.m_ack_i(jtag_altera_plug_wb_master_0_ack_i),
		.m_addr_o(jtag_altera_plug_wb_master_0_adr_o),
		.m_cyc_o(jtag_altera_plug_wb_master_0_cyc_o),
		.m_dat_i(jtag_altera_plug_wb_master_0_dat_i),
		.m_dat_o(jtag_altera_plug_wb_master_0_dat_o),
		.m_err_i(jtag_altera_plug_wb_master_0_err_i),
		.m_rty_i(jtag_altera_plug_wb_master_0_rty_i),
		.m_sel_o(jtag_altera_plug_wb_master_0_sel_o),
		.m_stb_o(jtag_altera_plug_wb_master_0_stb_o),
		.m_tag_o(jtag_altera_plug_wb_master_0_tag_o),
		.m_we_o(jtag_altera_plug_wb_master_0_we_o),
		.reset(jtag_altera_plug_reset_0_reset_i),
		.s_ack_o(jtag_altera_plug_wb_slave_0_ack_o),
		.s_addr_i(jtag_altera_plug_wb_slave_0_adr_i),
		.s_cyc_i(jtag_altera_plug_wb_slave_0_cyc_i),
		.s_dat_i(jtag_altera_plug_wb_slave_0_dat_i),
		.s_dat_o(jtag_altera_plug_wb_slave_0_dat_o),
		.s_err_o(jtag_altera_plug_wb_slave_0_err_o),
		.s_rty_o(jtag_altera_plug_wb_slave_0_rty_o),
		.s_sel_i(jtag_altera_plug_wb_slave_0_sel_i),
		.s_stb_i(jtag_altera_plug_wb_slave_0_stb_i),
		.s_tag_i(jtag_altera_plug_wb_slave_0_tag_i),
		.s_we_i(jtag_altera_plug_wb_slave_0_we_i)
	);
 ni #(
 		.B(ni_B),
		.DEBUG_EN(ni_DEBUG_EN),
		.Dw(ni_Dw),
		.Fpay(ni_Fpay),
		.M_Aw(ni_M_Aw),
		.NI_PCK_SIZE_WIDTH(ni_NI_PCK_SIZE_WIDTH),
		.NI_PTR_WIDTH(ni_NI_PTR_WIDTH),
		.NX(ni_NX),
		.NY(ni_NY),
		.P(ni_P),
		.RAM_WIDTH_IN_WORD(ni_RAM_WIDTH_IN_WORD),
		.ROUTE_NAME(ni_ROUTE_NAME),
		.ROUTE_TYPE(ni_ROUTE_TYPE),
		.SELw(ni_SELw),
		.S_Aw(ni_S_Aw),
		.TAGw(ni_TAGw),
		.TOPOLOGY(ni_TOPOLOGY),
		.V(ni_V)
	)  ni 	(
		.clk(ni_plug_clk_0_clk_i),
		.credit_in(ni_credit_in),
		.credit_out(ni_credit_out),
		.current_x(ni_current_x),
		.current_y(ni_current_y),
		.flit_in(ni_flit_in),
		.flit_in_wr(ni_flit_in_wr),
		.flit_out(ni_flit_out),
		.flit_out_wr(ni_flit_out_wr),
		.irq(ni_irq),
		.m_ack_i(ni_plug_wb_master_0_ack_i),
		.m_addr_o(ni_plug_wb_master_0_adr_o),
		.m_cyc_o(ni_plug_wb_master_0_cyc_o),
		.m_dat_i(ni_plug_wb_master_0_dat_i),
		.m_dat_o(ni_plug_wb_master_0_dat_o),
		.m_err_i(ni_plug_wb_master_0_err_i),
		.m_rty_i(ni_plug_wb_master_0_rty_i),
		.m_sel_o(ni_plug_wb_master_0_sel_o),
		.m_stb_o(ni_plug_wb_master_0_stb_o),
		.m_tag_o(ni_plug_wb_master_0_tag_o),
		.m_we_o(ni_plug_wb_master_0_we_o),
		.reset(ni_plug_reset_0_reset_i),
		.s_ack_o(ni_plug_wb_slave_0_ack_o),
		.s_addr_i(ni_plug_wb_slave_0_adr_i),
		.s_cyc_i(ni_plug_wb_slave_0_cyc_i),
		.s_dat_i(ni_plug_wb_slave_0_dat_i),
		.s_dat_o(ni_plug_wb_slave_0_dat_o),
		.s_err_o(ni_plug_wb_slave_0_err_o),
		.s_rty_o(ni_plug_wb_slave_0_rty_o),
		.s_sel_i(ni_plug_wb_slave_0_sel_i),
		.s_stb_i(ni_plug_wb_slave_0_stb_i),
		.s_tag_i(ni_plug_wb_slave_0_tag_i),
		.s_we_i(ni_plug_wb_slave_0_we_i)
	);
 wishbone_bus #(
 		.Aw(bus_Aw),
		.Dw(bus_Dw),
		.M(bus_M),
		.S(bus_S),
		.SELw(bus_SELw),
		.TAGw(bus_TAGw)
	)  bus 	(
		.clk(bus_plug_clk_0_clk_i),
		.m_ack_o_all(bus_socket_wb_master_array_ack_o),
		.m_adr_i_all(bus_socket_wb_master_array_adr_i),
		.m_cyc_i_all(bus_socket_wb_master_array_cyc_i),
		.m_dat_i_all(bus_socket_wb_master_array_dat_i),
		.m_dat_o_all(bus_socket_wb_master_array_dat_o),
		.m_err_o_all(bus_socket_wb_master_array_err_o),
		.m_grant_addr(bus_socket_wb_addr_map_0_grant_addr),
		.m_rty_o_all(bus_socket_wb_master_array_rty_o),
		.m_sel_i_all(bus_socket_wb_master_array_sel_i),
		.m_stb_i_all(bus_socket_wb_master_array_stb_i),
		.m_tag_i_all(bus_socket_wb_master_array_tag_i),
		.m_we_i_all(bus_socket_wb_master_array_we_i),
		.reset(bus_plug_reset_0_reset_i),
		.s_ack_i_all(bus_socket_wb_slave_array_ack_i),
		.s_adr_o_all(bus_socket_wb_slave_array_adr_o),
		.s_cyc_o_all(bus_socket_wb_slave_array_cyc_o),
		.s_dat_i_all(bus_socket_wb_slave_array_dat_i),
		.s_dat_o_all(bus_socket_wb_slave_array_dat_o),
		.s_err_i_all(bus_socket_wb_slave_array_err_i),
		.s_rty_i_all(bus_socket_wb_slave_array_rty_i),
		.s_sel_o_all(bus_socket_wb_slave_array_sel_o),
		.s_sel_one_hot(bus_socket_wb_addr_map_0_sel_one_hot),
		.s_stb_o_all(bus_socket_wb_slave_array_stb_o),
		.s_tag_o_all(bus_socket_wb_slave_array_tag_o),
		.s_we_o_all(bus_socket_wb_slave_array_we_o)
	);
 

 
 	assign  jtag_altera_plug_clk_0_clk_i = clk_source_socket_clk_0_clk_o;
 	assign  jtag_altera_plug_wb_master_0_ack_i = bus_socket_wb_master_1_ack_o;
 	assign  bus_socket_wb_master_1_adr_i  = jtag_altera_plug_wb_master_0_adr_o;
 	assign  bus_socket_wb_master_1_cyc_i  = jtag_altera_plug_wb_master_0_cyc_o;
 	assign  jtag_altera_plug_wb_master_0_dat_i = bus_socket_wb_master_1_dat_o;
 	assign  bus_socket_wb_master_1_dat_i  = jtag_altera_plug_wb_master_0_dat_o;
 	assign  jtag_altera_plug_wb_master_0_err_i = bus_socket_wb_master_1_err_o;
 	assign  jtag_altera_plug_wb_master_0_rty_i = bus_socket_wb_master_1_rty_o;
 	assign  bus_socket_wb_master_1_sel_i  = jtag_altera_plug_wb_master_0_sel_o;
 	assign  bus_socket_wb_master_1_stb_i  = jtag_altera_plug_wb_master_0_stb_o;
 	assign  bus_socket_wb_master_1_tag_i  = jtag_altera_plug_wb_master_0_tag_o;
 	assign  bus_socket_wb_master_1_we_i  = jtag_altera_plug_wb_master_0_we_o;
 	assign  jtag_altera_plug_reset_0_reset_i = clk_source_socket_reset_0_reset_o;
 	assign  bus_socket_wb_slave_1_ack_i  = jtag_altera_plug_wb_slave_0_ack_o;
 	assign  jtag_altera_plug_wb_slave_0_adr_i = bus_socket_wb_slave_1_adr_o;
 	assign  jtag_altera_plug_wb_slave_0_cyc_i = bus_socket_wb_slave_1_cyc_o;
 	assign  jtag_altera_plug_wb_slave_0_dat_i = bus_socket_wb_slave_1_dat_o;
 	assign  bus_socket_wb_slave_1_dat_i  = jtag_altera_plug_wb_slave_0_dat_o;
 	assign  bus_socket_wb_slave_1_err_i  = jtag_altera_plug_wb_slave_0_err_o;
 	assign  bus_socket_wb_slave_1_rty_i  = jtag_altera_plug_wb_slave_0_rty_o;
 	assign  jtag_altera_plug_wb_slave_0_sel_i = bus_socket_wb_slave_1_sel_o;
 	assign  jtag_altera_plug_wb_slave_0_stb_i = bus_socket_wb_slave_1_stb_o;
 	assign  jtag_altera_plug_wb_slave_0_tag_i = bus_socket_wb_slave_1_tag_o;
 	assign  jtag_altera_plug_wb_slave_0_we_i = bus_socket_wb_slave_1_we_o;

 
 	assign  ni_plug_clk_0_clk_i = clk_source_socket_clk_0_clk_o;
 	assign  ni_plug_wb_master_0_ack_i = bus_socket_wb_master_0_ack_o;
 	assign  bus_socket_wb_master_0_adr_i  = ni_plug_wb_master_0_adr_o;
 	assign  bus_socket_wb_master_0_cyc_i  = ni_plug_wb_master_0_cyc_o;
 	assign  ni_plug_wb_master_0_dat_i = bus_socket_wb_master_0_dat_o;
 	assign  bus_socket_wb_master_0_dat_i  = ni_plug_wb_master_0_dat_o;
 	assign  ni_plug_wb_master_0_err_i = bus_socket_wb_master_0_err_o;
 	assign  ni_plug_wb_master_0_rty_i = bus_socket_wb_master_0_rty_o;
 	assign  bus_socket_wb_master_0_sel_i  = ni_plug_wb_master_0_sel_o;
 	assign  bus_socket_wb_master_0_stb_i  = ni_plug_wb_master_0_stb_o;
 	assign  bus_socket_wb_master_0_tag_i  = ni_plug_wb_master_0_tag_o;
 	assign  bus_socket_wb_master_0_we_i  = ni_plug_wb_master_0_we_o;
 	assign  ni_plug_reset_0_reset_i = clk_source_socket_reset_0_reset_o;
 	assign  bus_socket_wb_slave_0_ack_i  = ni_plug_wb_slave_0_ack_o;
 	assign  ni_plug_wb_slave_0_adr_i = bus_socket_wb_slave_0_adr_o;
 	assign  ni_plug_wb_slave_0_cyc_i = bus_socket_wb_slave_0_cyc_o;
 	assign  ni_plug_wb_slave_0_dat_i = bus_socket_wb_slave_0_dat_o;
 	assign  bus_socket_wb_slave_0_dat_i  = ni_plug_wb_slave_0_dat_o;
 	assign  bus_socket_wb_slave_0_err_i  = ni_plug_wb_slave_0_err_o;
 	assign  bus_socket_wb_slave_0_rty_i  = ni_plug_wb_slave_0_rty_o;
 	assign  ni_plug_wb_slave_0_sel_i = bus_socket_wb_slave_0_sel_o;
 	assign  ni_plug_wb_slave_0_stb_i = bus_socket_wb_slave_0_stb_o;
 	assign  ni_plug_wb_slave_0_tag_i = bus_socket_wb_slave_0_tag_o;
 	assign  ni_plug_wb_slave_0_we_i = bus_socket_wb_slave_0_we_o;

 
 	assign  bus_plug_clk_0_clk_i = clk_source_socket_clk_0_clk_o;
 	assign  bus_plug_reset_0_reset_i = clk_source_socket_reset_0_reset_o;

 	assign {bus_socket_wb_master_1_ack_o ,bus_socket_wb_master_0_ack_o} =bus_socket_wb_master_array_ack_o;
 	assign bus_socket_wb_master_array_adr_i ={bus_socket_wb_master_1_adr_i ,bus_socket_wb_master_0_adr_i};
 	assign bus_socket_wb_master_array_cyc_i ={bus_socket_wb_master_1_cyc_i ,bus_socket_wb_master_0_cyc_i};
 	assign bus_socket_wb_master_array_dat_i ={bus_socket_wb_master_1_dat_i ,bus_socket_wb_master_0_dat_i};
 	assign {bus_socket_wb_master_1_dat_o ,bus_socket_wb_master_0_dat_o} =bus_socket_wb_master_array_dat_o;
 	assign {bus_socket_wb_master_1_err_o ,bus_socket_wb_master_0_err_o} =bus_socket_wb_master_array_err_o;
 	assign {bus_socket_wb_master_1_rty_o ,bus_socket_wb_master_0_rty_o} =bus_socket_wb_master_array_rty_o;
 	assign bus_socket_wb_master_array_sel_i ={bus_socket_wb_master_1_sel_i ,bus_socket_wb_master_0_sel_i};
 	assign bus_socket_wb_master_array_stb_i ={bus_socket_wb_master_1_stb_i ,bus_socket_wb_master_0_stb_i};
 	assign bus_socket_wb_master_array_tag_i ={bus_socket_wb_master_1_tag_i ,bus_socket_wb_master_0_tag_i};
 	assign bus_socket_wb_master_array_we_i ={bus_socket_wb_master_1_we_i ,bus_socket_wb_master_0_we_i};
 	assign bus_socket_wb_slave_array_ack_i ={bus_socket_wb_slave_1_ack_i ,bus_socket_wb_slave_0_ack_i};
 	assign {bus_socket_wb_slave_1_adr_o ,bus_socket_wb_slave_0_adr_o} =bus_socket_wb_slave_array_adr_o;
 	assign {bus_socket_wb_slave_1_cyc_o ,bus_socket_wb_slave_0_cyc_o} =bus_socket_wb_slave_array_cyc_o;
 	assign bus_socket_wb_slave_array_dat_i ={bus_socket_wb_slave_1_dat_i ,bus_socket_wb_slave_0_dat_i};
 	assign {bus_socket_wb_slave_1_dat_o ,bus_socket_wb_slave_0_dat_o} =bus_socket_wb_slave_array_dat_o;
 	assign bus_socket_wb_slave_array_err_i ={bus_socket_wb_slave_1_err_i ,bus_socket_wb_slave_0_err_i};
 	assign bus_socket_wb_slave_array_rty_i ={bus_socket_wb_slave_1_rty_i ,bus_socket_wb_slave_0_rty_i};
 	assign {bus_socket_wb_slave_1_sel_o ,bus_socket_wb_slave_0_sel_o} =bus_socket_wb_slave_array_sel_o;
 	assign {bus_socket_wb_slave_1_stb_o ,bus_socket_wb_slave_0_stb_o} =bus_socket_wb_slave_array_stb_o;
 	assign {bus_socket_wb_slave_1_tag_o ,bus_socket_wb_slave_0_tag_o} =bus_socket_wb_slave_array_tag_o;
 	assign {bus_socket_wb_slave_1_we_o ,bus_socket_wb_slave_0_we_o} =bus_socket_wb_slave_array_we_o;

 
//Wishbone slave address match
 /* jtag_altera wb_slave 0 */
 	assign bus_socket_wb_addr_map_0_sel_one_hot[1]= ((bus_socket_wb_addr_map_0_grant_addr >= 32'h24000000)   & (bus_socket_wb_addr_map_0_grant_addr< 32'h2400003f));
 /* ni wb_slave 0 */
 	assign bus_socket_wb_addr_map_0_sel_one_hot[0]= ((bus_socket_wb_addr_map_0_grant_addr >= 32'h2e000000)   & (bus_socket_wb_addr_map_0_grant_addr< 32'h2e000007));
 endmodule

