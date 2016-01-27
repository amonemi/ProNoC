module sim_25p #(
 	parameter	CORE_ID=0 ,
	parameter	aeMB0_AEMB_MUL= 1 ,
	parameter	aeMB0_AEMB_BSF= 1 ,
	parameter	led_PORT_WIDTH=	1 ,
	parameter	nn_NY= 2 ,
	parameter	nn_NX= 2 ,
	parameter	nn_V= 4 ,
	parameter	nn_B= 4 ,
	parameter	nn_DEBUG_EN=   1 ,
	parameter	nn_ROUTE_NAME="XY"      ,
	parameter	nn_TOPOLOGY=    "MESH"
)(
	aeMB0_sys_ena_i, 
	ss_clk_in, 
	ss_reset_in, 
	led_port_io, 
	nn_credit_in, 
	nn_credit_out, 
	nn_current_x, 
	nn_current_y, 
	nn_flit_in, 
	nn_flit_in_wr, 
	nn_flit_out, 
	nn_flit_out_wr
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
  	localparam	ram_Aw=13;
	localparam	ram_FPGA_FAMILY="ALTERA";
	localparam	ram_RAM_TAG_STRING="00";
	localparam	ram_TAGw=3;
	localparam	ram_Dw=32;
	localparam	ram_SELw=4;

 	localparam	aeMB0_AEMB_XWB= 7;
	localparam	aeMB0_AEMB_IDX= 6;
	localparam	aeMB0_AEMB_IWB= 32;
	localparam	aeMB0_AEMB_ICH= 11;
	localparam	aeMB0_AEMB_DWB= 32;

 
 	localparam	led_Dw=	32;
	localparam	led_Aw=   2;
	localparam	led_SELw=	4;

 	localparam	nn_Dw=32;
	localparam	nn_TAGw=   3;
	localparam	nn_M_Aw=32;
	localparam	nn_Fpay= 32;
	localparam	nn_SELw=   4    ;
	localparam	nn_ROUTE_TYPE=   (nn_ROUTE_NAME == "XY" || nn_ROUTE_NAME == "TRANC_XY" )?    "DETERMINISTIC" : 
			            (nn_ROUTE_NAME == "DUATO" || nn_ROUTE_NAME == "TRANC_DUATO" )?   "FULL_ADAPTIVE": "PAR_ADAPTIVE" ;
	localparam	nn_P= 5;
	localparam	nn_S_Aw=   3;
	localparam	nn_Fw=2 + nn_V + nn_Fpay;
	localparam	nn_Xw=log2( nn_NX );
	localparam	nn_Yw=log2( nn_NY );

 	localparam	bus_S=3;
	localparam	bus_M=3;
	localparam	bus_Aw=	32;
	localparam	bus_TAGw=	3    ;
	localparam	bus_SELw=	4;
	localparam	bus_Dw=	32;

 
//Wishbone slave base address based on instance name
 	localparam 	ram_BASE_ADDR	=	32'h00000000;
 	localparam 	ram_END_ADDR	=	32'h00003fff;
 	localparam 	led_BASE_ADDR	=	32'h24400000;
 	localparam 	led_END_ADDR	=	32'h24400007;
 	localparam 	nn_BASE_ADDR	=	32'h2e000000;
 	localparam 	nn_END_ADDR	=	32'h2e000007;
 
 
//Wishbone slave base address based on module name. 
 	localparam 	Altera_ram0_BASE_ADDR	=	32'h00000000;
 	localparam 	Altera_ram0_END_ADDR	=	32'h00003fff;
 	localparam 	gpio0_BASE_ADDR	=	32'h24400000;
 	localparam 	gpio0_END_ADDR	=	32'h24400007;
 	localparam 	ni0_BASE_ADDR	=	32'h2e000000;
 	localparam 	ni0_END_ADDR	=	32'h2e000007;
 
 	input			aeMB0_sys_ena_i;

 	input			ss_clk_in;
 	input			ss_reset_in;

 	inout	 [ led_PORT_WIDTH-1     :   0    ] led_port_io;

 	input	 [ nn_V-1    :   0    ] nn_credit_in;
 	output	 [ nn_V-1:   0    ] nn_credit_out;
 	input	 [ nn_Xw-1   :   0    ] nn_current_x;
 	input	 [ nn_Yw-1   :   0    ] nn_current_y;
 	input	 [ nn_Fw-1   :   0    ] nn_flit_in;
 	input			nn_flit_in_wr;
 	output	 [ nn_Fw-1   :   0    ] nn_flit_out;
 	output			nn_flit_out_wr;

 	wire			 aeMB0_plug_clk_0_clk_i;
 	wire			 aeMB0_plug_wb_master_1_ack_i;
 	wire	[ 31:0 ] aeMB0_plug_wb_master_1_adr_o;
 	wire			 aeMB0_plug_wb_master_1_cyc_o;
 	wire	[ 31:0 ] aeMB0_plug_wb_master_1_dat_i;
 	wire	[ 31:0 ] aeMB0_plug_wb_master_1_dat_o;
 	wire			 aeMB0_plug_wb_master_1_err_i;
 	wire			 aeMB0_plug_wb_master_1_rty_i;
 	wire	[ 3:0 ] aeMB0_plug_wb_master_1_sel_o;
 	wire			 aeMB0_plug_wb_master_1_stb_o;
 	wire	[ 2:0 ] aeMB0_plug_wb_master_1_tag_o;
 	wire			 aeMB0_plug_wb_master_1_we_o;
 	wire			 aeMB0_plug_wb_master_0_ack_i;
 	wire	[ 31:0 ] aeMB0_plug_wb_master_0_adr_o;
 	wire			 aeMB0_plug_wb_master_0_cyc_o;
 	wire	[ 31:0 ] aeMB0_plug_wb_master_0_dat_i;
 	wire	[ 31:0 ] aeMB0_plug_wb_master_0_dat_o;
 	wire			 aeMB0_plug_wb_master_0_err_i;
 	wire			 aeMB0_plug_wb_master_0_rty_i;
 	wire	[ 3:0 ] aeMB0_plug_wb_master_0_sel_o;
 	wire			 aeMB0_plug_wb_master_0_stb_o;
 	wire	[ 2:0 ] aeMB0_plug_wb_master_0_tag_o;
 	wire			 aeMB0_plug_wb_master_0_we_o;
 	wire			 aeMB0_plug_reset_0_reset_i;

 	wire			 ss_socket_clk_0_clk_o;
 	wire			 ss_socket_reset_0_reset_o;

 	wire			 led_plug_clk_0_clk_i;
 	wire			 led_plug_reset_0_reset_i;
 	wire			 led_plug_wb_slave_0_ack_o;
 	wire	[ led_Aw-1       :   0 ] led_plug_wb_slave_0_adr_i;
 	wire	[ led_Dw-1       :   0 ] led_plug_wb_slave_0_dat_i;
 	wire	[ led_Dw-1       :   0 ] led_plug_wb_slave_0_dat_o;
 	wire			 led_plug_wb_slave_0_err_o;
 	wire			 led_plug_wb_slave_0_rty_o;
 	wire	[ led_SELw-1     :   0 ] led_plug_wb_slave_0_sel_i;
 	wire			 led_plug_wb_slave_0_stb_i;
 	wire			 led_plug_wb_slave_0_we_i;

 	wire			 nn_plug_clk_0_clk_i;
 	wire			 nn_plug_wb_master_0_ack_i;
 	wire	[ nn_M_Aw-1          :   0 ] nn_plug_wb_master_0_adr_o;
 	wire			 nn_plug_wb_master_0_cyc_o;
 	wire	[ nn_Dw-1           :  0 ] nn_plug_wb_master_0_dat_i;
 	wire	[ nn_Dw-1            :   0 ] nn_plug_wb_master_0_dat_o;
 	wire			 nn_plug_wb_master_0_err_i;
 	wire			 nn_plug_wb_master_0_rty_i;
 	wire	[ nn_SELw-1          :   0 ] nn_plug_wb_master_0_sel_o;
 	wire			 nn_plug_wb_master_0_stb_o;
 	wire	[ nn_TAGw-1          :   0 ] nn_plug_wb_master_0_tag_o;
 	wire			 nn_plug_wb_master_0_we_o;
 	wire			 nn_plug_reset_0_reset_i;
 	wire			 nn_plug_wb_slave_0_ack_o;
 	wire	[ nn_S_Aw-1     :   0 ] nn_plug_wb_slave_0_adr_i;
 	wire			 nn_plug_wb_slave_0_cyc_i;
 	wire	[ nn_Dw-1       :   0 ] nn_plug_wb_slave_0_dat_i;
 	wire	[ nn_Dw-1       :   0 ] nn_plug_wb_slave_0_dat_o;
 	wire			 nn_plug_wb_slave_0_err_o;
 	wire			 nn_plug_wb_slave_0_rty_o;
 	wire	[ nn_SELw-1     :   0 ] nn_plug_wb_slave_0_sel_i;
 	wire			 nn_plug_wb_slave_0_stb_i;
 	wire	[ nn_TAGw-1     :   0 ] nn_plug_wb_slave_0_tag_i;
 	wire			 nn_plug_wb_slave_0_we_i;

 	wire			 bus_plug_clk_0_clk_i;
 	wire	[ bus_M-1        :   0 ] bus_socket_wb_master_array_ack_o;
 	wire			 bus_socket_wb_master_2_ack_o;
 	wire			 bus_socket_wb_master_1_ack_o;
 	wire			 bus_socket_wb_master_0_ack_o;
 	wire	[ (bus_Aw*bus_M)-1      :   0 ] bus_socket_wb_master_array_adr_i;
 	wire	[ bus_Aw-1      :   0 ] bus_socket_wb_master_2_adr_i;
 	wire	[ bus_Aw-1      :   0 ] bus_socket_wb_master_1_adr_i;
 	wire	[ bus_Aw-1      :   0 ] bus_socket_wb_master_0_adr_i;
 	wire	[ bus_M-1        :   0 ] bus_socket_wb_master_array_cyc_i;
 	wire			 bus_socket_wb_master_2_cyc_i;
 	wire			 bus_socket_wb_master_1_cyc_i;
 	wire			 bus_socket_wb_master_0_cyc_i;
 	wire	[ (bus_Dw*bus_M)-1      :   0 ] bus_socket_wb_master_array_dat_i;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_master_2_dat_i;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_master_1_dat_i;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_master_0_dat_i;
 	wire	[ (bus_Dw*bus_M)-1      :   0 ] bus_socket_wb_master_array_dat_o;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_master_2_dat_o;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_master_1_dat_o;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_master_0_dat_o;
 	wire	[ bus_M-1        :   0 ] bus_socket_wb_master_array_err_o;
 	wire			 bus_socket_wb_master_2_err_o;
 	wire			 bus_socket_wb_master_1_err_o;
 	wire			 bus_socket_wb_master_0_err_o;
 	wire	[ bus_Aw-1       :   0 ] bus_socket_wb_addr_map_0_grant_addr;
 	wire	[ bus_M-1        :   0 ] bus_socket_wb_master_array_rty_o;
 	wire			 bus_socket_wb_master_2_rty_o;
 	wire			 bus_socket_wb_master_1_rty_o;
 	wire			 bus_socket_wb_master_0_rty_o;
 	wire	[ (bus_SELw*bus_M)-1    :   0 ] bus_socket_wb_master_array_sel_i;
 	wire	[ bus_SELw-1    :   0 ] bus_socket_wb_master_2_sel_i;
 	wire	[ bus_SELw-1    :   0 ] bus_socket_wb_master_1_sel_i;
 	wire	[ bus_SELw-1    :   0 ] bus_socket_wb_master_0_sel_i;
 	wire	[ bus_M-1        :   0 ] bus_socket_wb_master_array_stb_i;
 	wire			 bus_socket_wb_master_2_stb_i;
 	wire			 bus_socket_wb_master_1_stb_i;
 	wire			 bus_socket_wb_master_0_stb_i;
 	wire	[ (bus_TAGw*bus_M)-1    :   0 ] bus_socket_wb_master_array_tag_i;
 	wire	[ bus_TAGw-1    :   0 ] bus_socket_wb_master_2_tag_i;
 	wire	[ bus_TAGw-1    :   0 ] bus_socket_wb_master_1_tag_i;
 	wire	[ bus_TAGw-1    :   0 ] bus_socket_wb_master_0_tag_i;
 	wire	[ bus_M-1        :   0 ] bus_socket_wb_master_array_we_i;
 	wire			 bus_socket_wb_master_2_we_i;
 	wire			 bus_socket_wb_master_1_we_i;
 	wire			 bus_socket_wb_master_0_we_i;
 	wire			 bus_plug_reset_0_reset_i;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_slave_array_ack_i;
 	wire			 bus_socket_wb_slave_2_ack_i;
 	wire			 bus_socket_wb_slave_1_ack_i;
 	wire			 bus_socket_wb_slave_0_ack_i;
 	wire	[ (bus_Aw*bus_S)-1      :   0 ] bus_socket_wb_slave_array_adr_o;
 	wire	[ bus_Aw-1      :   0 ] bus_socket_wb_slave_2_adr_o;
 	wire	[ bus_Aw-1      :   0 ] bus_socket_wb_slave_1_adr_o;
 	wire	[ bus_Aw-1      :   0 ] bus_socket_wb_slave_0_adr_o;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_slave_array_cyc_o;
 	wire			 bus_socket_wb_slave_2_cyc_o;
 	wire			 bus_socket_wb_slave_1_cyc_o;
 	wire			 bus_socket_wb_slave_0_cyc_o;
 	wire	[ (bus_Dw*bus_S)-1      :   0 ] bus_socket_wb_slave_array_dat_i;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_2_dat_i;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_1_dat_i;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_0_dat_i;
 	wire	[ (bus_Dw*bus_S)-1      :   0 ] bus_socket_wb_slave_array_dat_o;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_2_dat_o;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_1_dat_o;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_0_dat_o;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_slave_array_err_i;
 	wire			 bus_socket_wb_slave_2_err_i;
 	wire			 bus_socket_wb_slave_1_err_i;
 	wire			 bus_socket_wb_slave_0_err_i;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_slave_array_rty_i;
 	wire			 bus_socket_wb_slave_2_rty_i;
 	wire			 bus_socket_wb_slave_1_rty_i;
 	wire			 bus_socket_wb_slave_0_rty_i;
 	wire	[ (bus_SELw*bus_S)-1    :   0 ] bus_socket_wb_slave_array_sel_o;
 	wire	[ bus_SELw-1    :   0 ] bus_socket_wb_slave_2_sel_o;
 	wire	[ bus_SELw-1    :   0 ] bus_socket_wb_slave_1_sel_o;
 	wire	[ bus_SELw-1    :   0 ] bus_socket_wb_slave_0_sel_o;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_addr_map_0_sel_one_hot;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_slave_array_stb_o;
 	wire			 bus_socket_wb_slave_2_stb_o;
 	wire			 bus_socket_wb_slave_1_stb_o;
 	wire			 bus_socket_wb_slave_0_stb_o;
 	wire	[ (bus_TAGw*bus_S)-1    :   0 ] bus_socket_wb_slave_array_tag_o;
 	wire	[ bus_TAGw-1    :   0 ] bus_socket_wb_slave_2_tag_o;
 	wire	[ bus_TAGw-1    :   0 ] bus_socket_wb_slave_1_tag_o;
 	wire	[ bus_TAGw-1    :   0 ] bus_socket_wb_slave_0_tag_o;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_slave_array_we_o;
 	wire			 bus_socket_wb_slave_2_we_o;
 	wire			 bus_socket_wb_slave_1_we_o;
 	wire			 bus_socket_wb_slave_0_we_o;

 prog_ram_single_port #(
 		.Aw(ram_Aw),
		.FPGA_FAMILY(ram_FPGA_FAMILY),
		.RAM_TAG_STRING(ram_RAM_TAG_STRING),
		.TAGw(ram_TAGw),
		.Dw(ram_Dw),
		.SELw(ram_SELw)
	)  ram 	(
	);
 aeMB_top #(
 		.AEMB_XWB(aeMB0_AEMB_XWB),
		.AEMB_IDX(aeMB0_AEMB_IDX),
		.AEMB_MUL(aeMB0_AEMB_MUL),
		.AEMB_IWB(aeMB0_AEMB_IWB),
		.AEMB_BSF(aeMB0_AEMB_BSF),
		.AEMB_ICH(aeMB0_AEMB_ICH),
		.AEMB_DWB(aeMB0_AEMB_DWB)
	)  aeMB0 	(
		.clk(aeMB0_plug_clk_0_clk_i),
		.dwb_ack_i(aeMB0_plug_wb_master_1_ack_i),
		.dwb_adr_o(aeMB0_plug_wb_master_1_adr_o),
		.dwb_cyc_o(aeMB0_plug_wb_master_1_cyc_o),
		.dwb_dat_i(aeMB0_plug_wb_master_1_dat_i),
		.dwb_dat_o(aeMB0_plug_wb_master_1_dat_o),
		.dwb_err_i(aeMB0_plug_wb_master_1_err_i),
		.dwb_rty_i(aeMB0_plug_wb_master_1_rty_i),
		.dwb_sel_o(aeMB0_plug_wb_master_1_sel_o),
		.dwb_stb_o(aeMB0_plug_wb_master_1_stb_o),
		.dwb_tag_o(aeMB0_plug_wb_master_1_tag_o),
		.dwb_wre_o(aeMB0_plug_wb_master_1_we_o),
		.iwb_ack_i(aeMB0_plug_wb_master_0_ack_i),
		.iwb_adr_o(aeMB0_plug_wb_master_0_adr_o),
		.iwb_cyc_o(aeMB0_plug_wb_master_0_cyc_o),
		.iwb_dat_i(aeMB0_plug_wb_master_0_dat_i),
		.iwb_dat_o(aeMB0_plug_wb_master_0_dat_o),
		.iwb_err_i(aeMB0_plug_wb_master_0_err_i),
		.iwb_rty_i(aeMB0_plug_wb_master_0_rty_i),
		.iwb_sel_o(aeMB0_plug_wb_master_0_sel_o),
		.iwb_stb_o(aeMB0_plug_wb_master_0_stb_o),
		.iwb_tag_o(aeMB0_plug_wb_master_0_tag_o),
		.iwb_wre_o(aeMB0_plug_wb_master_0_we_o),
		.reset(aeMB0_plug_reset_0_reset_i),
		.sys_ena_i(aeMB0_sys_ena_i),
		.sys_int_i()
	);
 clk_source  ss 	(
		.clk_in(ss_clk_in),
		.clk_out(ss_socket_clk_0_clk_o),
		.reset_in(ss_reset_in),
		.reset_out(ss_socket_reset_0_reset_o)
	);
 gpio #(
 		.PORT_WIDTH(led_PORT_WIDTH),
		.Dw(led_Dw),
		.Aw(led_Aw),
		.SELw(led_SELw)
	)  led 	(
		.clk(led_plug_clk_0_clk_i),
		.port_io(led_port_io),
		.reset(led_plug_reset_0_reset_i),
		.sa_ack_o(led_plug_wb_slave_0_ack_o),
		.sa_addr_i(led_plug_wb_slave_0_adr_i),
		.sa_dat_i(led_plug_wb_slave_0_dat_i),
		.sa_dat_o(led_plug_wb_slave_0_dat_o),
		.sa_err_o(led_plug_wb_slave_0_err_o),
		.sa_rty_o(led_plug_wb_slave_0_rty_o),
		.sa_sel_i(led_plug_wb_slave_0_sel_i),
		.sa_stb_i(led_plug_wb_slave_0_stb_i),
		.sa_we_i(led_plug_wb_slave_0_we_i)
	);
 ni #(
 		.NY(nn_NY),
		.NX(nn_NX),
		.V(nn_V),
		.B(nn_B),
		.Dw(nn_Dw),
		.DEBUG_EN(nn_DEBUG_EN),
		.TAGw(nn_TAGw),
		.M_Aw(nn_M_Aw),
		.ROUTE_NAME(nn_ROUTE_NAME),
		.Fpay(nn_Fpay),
		.SELw(nn_SELw),
		.ROUTE_TYPE(nn_ROUTE_TYPE),
		.P(nn_P),
		.S_Aw(nn_S_Aw),
		.TOPOLOGY(nn_TOPOLOGY)
	)  nn 	(
		.clk(nn_plug_clk_0_clk_i),
		.credit_in(nn_credit_in),
		.credit_out(nn_credit_out),
		.current_x(nn_current_x),
		.current_y(nn_current_y),
		.flit_in(nn_flit_in),
		.flit_in_wr(nn_flit_in_wr),
		.flit_out(nn_flit_out),
		.flit_out_wr(nn_flit_out_wr),
		.irq(),
		.m_ack_i(nn_plug_wb_master_0_ack_i),
		.m_addr_o(nn_plug_wb_master_0_adr_o),
		.m_cyc_o(nn_plug_wb_master_0_cyc_o),
		.m_dat_i(nn_plug_wb_master_0_dat_i),
		.m_dat_o(nn_plug_wb_master_0_dat_o),
		.m_err_i(nn_plug_wb_master_0_err_i),
		.m_rty_i(nn_plug_wb_master_0_rty_i),
		.m_sel_o(nn_plug_wb_master_0_sel_o),
		.m_stb_o(nn_plug_wb_master_0_stb_o),
		.m_tag_o(nn_plug_wb_master_0_tag_o),
		.m_we_o(nn_plug_wb_master_0_we_o),
		.reset(nn_plug_reset_0_reset_i),
		.s_ack_o(nn_plug_wb_slave_0_ack_o),
		.s_addr_i(nn_plug_wb_slave_0_adr_i),
		.s_cyc_i(nn_plug_wb_slave_0_cyc_i),
		.s_dat_i(nn_plug_wb_slave_0_dat_i),
		.s_dat_o(nn_plug_wb_slave_0_dat_o),
		.s_err_o(nn_plug_wb_slave_0_err_o),
		.s_rty_o(nn_plug_wb_slave_0_rty_o),
		.s_sel_i(nn_plug_wb_slave_0_sel_i),
		.s_stb_i(nn_plug_wb_slave_0_stb_i),
		.s_tag_i(nn_plug_wb_slave_0_tag_i),
		.s_we_i(nn_plug_wb_slave_0_we_i)
	);
 wishbone_bus #(
 		.S(bus_S),
		.M(bus_M),
		.Aw(bus_Aw),
		.TAGw(bus_TAGw),
		.SELw(bus_SELw),
		.Dw(bus_Dw)
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
 

 
 	assign  aeMB0_plug_clk_0_clk_i = ss_socket_clk_0_clk_o;
 	assign  aeMB0_plug_wb_master_1_ack_i = bus_socket_wb_master_1_ack_o;
 	assign  bus_socket_wb_master_1_adr_i  = aeMB0_plug_wb_master_1_adr_o;
 	assign  bus_socket_wb_master_1_cyc_i  = aeMB0_plug_wb_master_1_cyc_o;
 	assign  aeMB0_plug_wb_master_1_dat_i = bus_socket_wb_master_1_dat_o;
 	assign  bus_socket_wb_master_1_dat_i  = aeMB0_plug_wb_master_1_dat_o;
 	assign  aeMB0_plug_wb_master_1_err_i = bus_socket_wb_master_1_err_o;
 	assign  aeMB0_plug_wb_master_1_rty_i = bus_socket_wb_master_1_rty_o;
 	assign  bus_socket_wb_master_1_sel_i  = aeMB0_plug_wb_master_1_sel_o;
 	assign  bus_socket_wb_master_1_stb_i  = aeMB0_plug_wb_master_1_stb_o;
 	assign  bus_socket_wb_master_1_tag_i  = aeMB0_plug_wb_master_1_tag_o;
 	assign  bus_socket_wb_master_1_we_i  = aeMB0_plug_wb_master_1_we_o;
 	assign  aeMB0_plug_wb_master_0_ack_i = bus_socket_wb_master_0_ack_o;
 	assign  bus_socket_wb_master_0_adr_i  = aeMB0_plug_wb_master_0_adr_o;
 	assign  bus_socket_wb_master_0_cyc_i  = aeMB0_plug_wb_master_0_cyc_o;
 	assign  aeMB0_plug_wb_master_0_dat_i = bus_socket_wb_master_0_dat_o;
 	assign  bus_socket_wb_master_0_dat_i  = aeMB0_plug_wb_master_0_dat_o;
 	assign  aeMB0_plug_wb_master_0_err_i = bus_socket_wb_master_0_err_o;
 	assign  aeMB0_plug_wb_master_0_rty_i = bus_socket_wb_master_0_rty_o;
 	assign  bus_socket_wb_master_0_sel_i  = aeMB0_plug_wb_master_0_sel_o;
 	assign  bus_socket_wb_master_0_stb_i  = aeMB0_plug_wb_master_0_stb_o;
 	assign  bus_socket_wb_master_0_tag_i  = aeMB0_plug_wb_master_0_tag_o;
 	assign  bus_socket_wb_master_0_we_i  = aeMB0_plug_wb_master_0_we_o;
 	assign  aeMB0_plug_reset_0_reset_i = ss_socket_reset_0_reset_o;

 

 
 	assign  led_plug_clk_0_clk_i = ss_socket_clk_0_clk_o;
 	assign  led_plug_reset_0_reset_i = ss_socket_reset_0_reset_o;
 	assign  bus_socket_wb_slave_0_ack_i  = led_plug_wb_slave_0_ack_o;
 	assign  led_plug_wb_slave_0_adr_i = bus_socket_wb_slave_0_adr_o;
 	assign  led_plug_wb_slave_0_dat_i = bus_socket_wb_slave_0_dat_o;
 	assign  bus_socket_wb_slave_0_dat_i  = led_plug_wb_slave_0_dat_o;
 	assign  bus_socket_wb_slave_0_err_i  = led_plug_wb_slave_0_err_o;
 	assign  bus_socket_wb_slave_0_rty_i  = led_plug_wb_slave_0_rty_o;
 	assign  led_plug_wb_slave_0_sel_i = bus_socket_wb_slave_0_sel_o;
 	assign  led_plug_wb_slave_0_stb_i = bus_socket_wb_slave_0_stb_o;
 	assign  led_plug_wb_slave_0_we_i = bus_socket_wb_slave_0_we_o;

 
 	assign  nn_plug_clk_0_clk_i = ss_socket_clk_0_clk_o;
 	assign  nn_plug_wb_master_0_ack_i = bus_socket_wb_master_2_ack_o;
 	assign  bus_socket_wb_master_2_adr_i  = nn_plug_wb_master_0_adr_o;
 	assign  bus_socket_wb_master_2_cyc_i  = nn_plug_wb_master_0_cyc_o;
 	assign  nn_plug_wb_master_0_dat_i = bus_socket_wb_master_2_dat_o;
 	assign  bus_socket_wb_master_2_dat_i  = nn_plug_wb_master_0_dat_o;
 	assign  nn_plug_wb_master_0_err_i = bus_socket_wb_master_2_err_o;
 	assign  nn_plug_wb_master_0_rty_i = bus_socket_wb_master_2_rty_o;
 	assign  bus_socket_wb_master_2_sel_i  = nn_plug_wb_master_0_sel_o;
 	assign  bus_socket_wb_master_2_stb_i  = nn_plug_wb_master_0_stb_o;
 	assign  bus_socket_wb_master_2_tag_i  = nn_plug_wb_master_0_tag_o;
 	assign  bus_socket_wb_master_2_we_i  = nn_plug_wb_master_0_we_o;
 	assign  nn_plug_reset_0_reset_i = ss_socket_reset_0_reset_o;
 	assign  bus_socket_wb_slave_1_ack_i  = nn_plug_wb_slave_0_ack_o;
 	assign  nn_plug_wb_slave_0_adr_i = bus_socket_wb_slave_1_adr_o;
 	assign  nn_plug_wb_slave_0_cyc_i = bus_socket_wb_slave_1_cyc_o;
 	assign  nn_plug_wb_slave_0_dat_i = bus_socket_wb_slave_1_dat_o;
 	assign  bus_socket_wb_slave_1_dat_i  = nn_plug_wb_slave_0_dat_o;
 	assign  bus_socket_wb_slave_1_err_i  = nn_plug_wb_slave_0_err_o;
 	assign  bus_socket_wb_slave_1_rty_i  = nn_plug_wb_slave_0_rty_o;
 	assign  nn_plug_wb_slave_0_sel_i = bus_socket_wb_slave_1_sel_o;
 	assign  nn_plug_wb_slave_0_stb_i = bus_socket_wb_slave_1_stb_o;
 	assign  nn_plug_wb_slave_0_tag_i = bus_socket_wb_slave_1_tag_o;
 	assign  nn_plug_wb_slave_0_we_i = bus_socket_wb_slave_1_we_o;

 
 	assign  bus_plug_clk_0_clk_i = ss_socket_clk_0_clk_o;
 	assign  bus_plug_reset_0_reset_i = ss_socket_reset_0_reset_o;

 	assign {bus_socket_wb_master_2_ack_o ,bus_socket_wb_master_1_ack_o ,bus_socket_wb_master_0_ack_o} =bus_socket_wb_master_array_ack_o;
 	assign bus_socket_wb_master_array_adr_i ={bus_socket_wb_master_2_adr_i ,bus_socket_wb_master_1_adr_i ,bus_socket_wb_master_0_adr_i};
 	assign bus_socket_wb_master_array_cyc_i ={bus_socket_wb_master_2_cyc_i ,bus_socket_wb_master_1_cyc_i ,bus_socket_wb_master_0_cyc_i};
 	assign bus_socket_wb_master_array_dat_i ={bus_socket_wb_master_2_dat_i ,bus_socket_wb_master_1_dat_i ,bus_socket_wb_master_0_dat_i};
 	assign {bus_socket_wb_master_2_dat_o ,bus_socket_wb_master_1_dat_o ,bus_socket_wb_master_0_dat_o} =bus_socket_wb_master_array_dat_o;
 	assign {bus_socket_wb_master_2_err_o ,bus_socket_wb_master_1_err_o ,bus_socket_wb_master_0_err_o} =bus_socket_wb_master_array_err_o;
 	assign {bus_socket_wb_master_2_rty_o ,bus_socket_wb_master_1_rty_o ,bus_socket_wb_master_0_rty_o} =bus_socket_wb_master_array_rty_o;
 	assign bus_socket_wb_master_array_sel_i ={bus_socket_wb_master_2_sel_i ,bus_socket_wb_master_1_sel_i ,bus_socket_wb_master_0_sel_i};
 	assign bus_socket_wb_master_array_stb_i ={bus_socket_wb_master_2_stb_i ,bus_socket_wb_master_1_stb_i ,bus_socket_wb_master_0_stb_i};
 	assign bus_socket_wb_master_array_tag_i ={bus_socket_wb_master_2_tag_i ,bus_socket_wb_master_1_tag_i ,bus_socket_wb_master_0_tag_i};
 	assign bus_socket_wb_master_array_we_i ={bus_socket_wb_master_2_we_i ,bus_socket_wb_master_1_we_i ,bus_socket_wb_master_0_we_i};
 	assign bus_socket_wb_slave_array_ack_i ={bus_socket_wb_slave_2_ack_i ,bus_socket_wb_slave_1_ack_i ,bus_socket_wb_slave_0_ack_i};
 	assign {bus_socket_wb_slave_2_adr_o ,bus_socket_wb_slave_1_adr_o ,bus_socket_wb_slave_0_adr_o} =bus_socket_wb_slave_array_adr_o;
 	assign {bus_socket_wb_slave_2_cyc_o ,bus_socket_wb_slave_1_cyc_o ,bus_socket_wb_slave_0_cyc_o} =bus_socket_wb_slave_array_cyc_o;
 	assign bus_socket_wb_slave_array_dat_i ={bus_socket_wb_slave_2_dat_i ,bus_socket_wb_slave_1_dat_i ,bus_socket_wb_slave_0_dat_i};
 	assign {bus_socket_wb_slave_2_dat_o ,bus_socket_wb_slave_1_dat_o ,bus_socket_wb_slave_0_dat_o} =bus_socket_wb_slave_array_dat_o;
 	assign bus_socket_wb_slave_array_err_i ={bus_socket_wb_slave_2_err_i ,bus_socket_wb_slave_1_err_i ,bus_socket_wb_slave_0_err_i};
 	assign bus_socket_wb_slave_array_rty_i ={bus_socket_wb_slave_2_rty_i ,bus_socket_wb_slave_1_rty_i ,bus_socket_wb_slave_0_rty_i};
 	assign {bus_socket_wb_slave_2_sel_o ,bus_socket_wb_slave_1_sel_o ,bus_socket_wb_slave_0_sel_o} =bus_socket_wb_slave_array_sel_o;
 	assign {bus_socket_wb_slave_2_stb_o ,bus_socket_wb_slave_1_stb_o ,bus_socket_wb_slave_0_stb_o} =bus_socket_wb_slave_array_stb_o;
 	assign {bus_socket_wb_slave_2_tag_o ,bus_socket_wb_slave_1_tag_o ,bus_socket_wb_slave_0_tag_o} =bus_socket_wb_slave_array_tag_o;
 	assign {bus_socket_wb_slave_2_we_o ,bus_socket_wb_slave_1_we_o ,bus_socket_wb_slave_0_we_o} =bus_socket_wb_slave_array_we_o;

 
//Wishbone slave address match
 /* ram wb_slave 0 */
 	assign bus_socket_wb_addr_map_0_sel_one_hot[2]= ((bus_socket_wb_addr_map_0_grant_addr >= ram_BASE_ADDR)   & (bus_socket_wb_addr_map_0_grant_addr< ram_END_ADDR));
 /* led wb_slave 0 */
 	assign bus_socket_wb_addr_map_0_sel_one_hot[0]= ((bus_socket_wb_addr_map_0_grant_addr >= led_BASE_ADDR)   & (bus_socket_wb_addr_map_0_grant_addr< led_END_ADDR));
 /* nn wb_slave 0 */
 	assign bus_socket_wb_addr_map_0_sel_one_hot[1]= ((bus_socket_wb_addr_map_0_grant_addr >= nn_BASE_ADDR)   & (bus_socket_wb_addr_map_0_grant_addr< nn_END_ADDR));
 endmodule

