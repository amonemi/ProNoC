module first #(
    	parameter	ram_Aw=15 ,
	parameter	ram_RAM_TAG_STRING="00" ,
	parameter	aeMB_AEMB_BSF= 1 ,
	parameter	aeMB_AEMB_MUL= 1 ,
	parameter	gpo_PORT_WIDTH=   1 ,
	parameter	ni0_NY= 2 ,
	parameter	ni0_NX= 2 ,
	parameter	ni0_V= 4 ,
	parameter	ni0_B= 4 ,
	parameter	ni0_ROUTE_NAME="XY"      ,
	parameter	ni0_TOPOLOGY=    "MESH"
)(
	aeMB_sys_ena_i, 
	src_clk_in, 
	src_reset_in, 
	gpo_port_o, 
	ni0_credit_in, 
	ni0_credit_out, 
	ni0_current_x, 
	ni0_current_y, 
	ni0_flit_in, 
	ni0_flit_in_wr, 
	ni0_flit_out, 
	ni0_flit_out_wr
);
  
  	function integer log2;
  		input integer number; begin	
          	log2=0;	
          	while(2**log2<number) begin	
        		  	log2=log2+1;	
         		end	
        		end	
     	endfunction // log2 
  	localparam	ram_Dw=32;
	localparam	ram_FPGA_FAMILY="ALTERA";
	localparam	ram_SELw=4;
	localparam	ram_TAGw=3;

 	localparam	aeMB_AEMB_DWB= 32;
	localparam	aeMB_AEMB_ICH= 11;
	localparam	aeMB_AEMB_IDX= 6;
	localparam	aeMB_AEMB_IWB= 32;
	localparam	aeMB_AEMB_XWB= 7;

 
 	localparam	gpo_Aw=    2;
	localparam	gpo_Dw=    32;
	localparam	gpo_SELw=    4;
	localparam	gpo_TAGw=    3;

 	localparam	int_ctrl_Aw= 3;
	localparam	int_ctrl_Dw=    32;
	localparam	int_ctrl_INT_NUM=2;
	localparam	int_ctrl_SELw= 4    ;

 	localparam	ni0_Dw=32;
	localparam	ni0_DEBUG_EN=   1;
	localparam	ni0_TAGw=   3;
	localparam	ni0_M_Aw=32;
	localparam	ni0_Fpay= 32;
	localparam	ni0_SELw=   4    ;
	localparam	ni0_ROUTE_TYPE=   (ni0_ROUTE_NAME == "XY" || ni0_ROUTE_NAME == "TRANC_XY" )?    "DETERMINISTIC" : 
			            (ni0_ROUTE_NAME == "DUATO" || ni0_ROUTE_NAME == "TRANC_DUATO" )?   "FULL_ADAPTIVE": "PAR_ADAPTIVE" ;
	localparam	ni0_P= 5;
	localparam	ni0_S_Aw=   3;
	localparam	ni0_Fw=2 + ni0_V + ni0_Fpay;
	localparam	ni0_Xw=log2( ni0_NX );
	localparam	ni0_Yw=log2( ni0_NY );

 	localparam	timer_Aw= 3;
	localparam	timer_CNTw=32     ;
	localparam	timer_Dw=	32;
	localparam	timer_SELw=	4;
	localparam	timer_TAGw=3;

 	localparam	wishbone_bus_Aw=	32;
	localparam	wishbone_bus_Dw=	32;
	localparam	wishbone_bus_M=3;
	localparam	wishbone_bus_S=5;
	localparam	wishbone_bus_SELw=	4;
	localparam	wishbone_bus_TAGw=	3    ;

 
//Wishbone slave base address based on instance name
 	localparam 	ram_BASE_ADDR	=	32'h00000000;
 	localparam 	ram_END_ADDR	=	32'h00003fff;
 	localparam 	gpo_BASE_ADDR	=	32'h24400000;
 	localparam 	gpo_END_ADDR	=	32'h24400007;
 	localparam 	int_ctrl_BASE_ADDR	=	32'h27800000;
 	localparam 	int_ctrl_END_ADDR	=	32'h27800007;
 	localparam 	ni0_BASE_ADDR	=	32'h2e000000;
 	localparam 	ni0_END_ADDR	=	32'h2e000007;
 	localparam 	timer_BASE_ADDR	=	32'h25800000;
 	localparam 	timer_END_ADDR	=	32'h25800007;
 
 
//Wishbone slave base address based on module name. 
 	localparam 	Altera_ram0_BASE_ADDR	=	32'h00000000;
 	localparam 	Altera_ram0_END_ADDR	=	32'h00003fff;
 	localparam 	gpo0_BASE_ADDR	=	32'h24400000;
 	localparam 	gpo0_END_ADDR	=	32'h24400007;
 	localparam 	int_ctrl0_BASE_ADDR	=	32'h27800000;
 	localparam 	int_ctrl0_END_ADDR	=	32'h27800007;
 	localparam 	timer0_BASE_ADDR	=	32'h25800000;
 	localparam 	timer0_END_ADDR	=	32'h25800007;
 
 	input			aeMB_sys_ena_i;

 	input			src_clk_in;
 	input			src_reset_in;

 	output	 [ gpo_PORT_WIDTH-1     :   0    ] gpo_port_o;

 	input	 [ ni0_V-1    :   0    ] ni0_credit_in;
 	output	 [ ni0_V-1:   0    ] ni0_credit_out;
 	input	 [ ni0_Xw-1   :   0    ] ni0_current_x;
 	input	 [ ni0_Yw-1   :   0    ] ni0_current_y;
 	input	 [ ni0_Fw-1   :   0    ] ni0_flit_in;
 	input			ni0_flit_in_wr;
 	output	 [ ni0_Fw-1   :   0    ] ni0_flit_out;
 	output			ni0_flit_out_wr;

 	wire			 ram_plug_clk_0_clk_i;
 	wire			 ram_plug_reset_0_reset_i;
 	wire			 ram_plug_wb_slave_0_ack_o;
 	wire	[ ram_Aw-1       :   0 ] ram_plug_wb_slave_0_adr_i;
 	wire			 ram_plug_wb_slave_0_cyc_i;
 	wire	[ ram_Dw-1       :   0 ] ram_plug_wb_slave_0_dat_i;
 	wire	[ ram_Dw-1       :   0 ] ram_plug_wb_slave_0_dat_o;
 	wire			 ram_plug_wb_slave_0_err_o;
 	wire			 ram_plug_wb_slave_0_rty_o;
 	wire	[ ram_SELw-1     :   0 ] ram_plug_wb_slave_0_sel_i;
 	wire			 ram_plug_wb_slave_0_stb_i;
 	wire	[ ram_TAGw-1     :   0 ] ram_plug_wb_slave_0_tag_i;
 	wire			 ram_plug_wb_slave_0_we_i;

 	wire			 aeMB_plug_clk_0_clk_i;
 	wire			 aeMB_plug_wb_master_1_ack_i;
 	wire	[ 31:0 ] aeMB_plug_wb_master_1_adr_o;
 	wire			 aeMB_plug_wb_master_1_cyc_o;
 	wire	[ 31:0 ] aeMB_plug_wb_master_1_dat_i;
 	wire	[ 31:0 ] aeMB_plug_wb_master_1_dat_o;
 	wire			 aeMB_plug_wb_master_1_err_i;
 	wire			 aeMB_plug_wb_master_1_rty_i;
 	wire	[ 3:0 ] aeMB_plug_wb_master_1_sel_o;
 	wire			 aeMB_plug_wb_master_1_stb_o;
 	wire	[ 2:0 ] aeMB_plug_wb_master_1_tag_o;
 	wire			 aeMB_plug_wb_master_1_we_o;
 	wire			 aeMB_plug_wb_master_0_ack_i;
 	wire	[ 31:0 ] aeMB_plug_wb_master_0_adr_o;
 	wire			 aeMB_plug_wb_master_0_cyc_o;
 	wire	[ 31:0 ] aeMB_plug_wb_master_0_dat_i;
 	wire	[ 31:0 ] aeMB_plug_wb_master_0_dat_o;
 	wire			 aeMB_plug_wb_master_0_err_i;
 	wire			 aeMB_plug_wb_master_0_rty_i;
 	wire	[ 3:0 ] aeMB_plug_wb_master_0_sel_o;
 	wire			 aeMB_plug_wb_master_0_stb_o;
 	wire	[ 2:0 ] aeMB_plug_wb_master_0_tag_o;
 	wire			 aeMB_plug_wb_master_0_we_o;
 	wire			 aeMB_plug_reset_0_reset_i;
 	wire			 aeMB_plug_interrupt_cpu_0_int_i;

 	wire			 src_socket_clk_0_clk_o;
 	wire			 src_socket_reset_0_reset_o;

 	wire			 gpo_plug_clk_0_clk_i;
 	wire			 gpo_plug_reset_0_reset_i;
 	wire			 gpo_plug_wb_slave_0_ack_o;
 	wire	[ gpo_Aw-1       :   0 ] gpo_plug_wb_slave_0_adr_i;
 	wire			 gpo_plug_wb_slave_0_cyc_i;
 	wire	[ gpo_Dw-1       :   0 ] gpo_plug_wb_slave_0_dat_i;
 	wire	[ gpo_Dw-1       :   0 ] gpo_plug_wb_slave_0_dat_o;
 	wire			 gpo_plug_wb_slave_0_err_o;
 	wire			 gpo_plug_wb_slave_0_rty_o;
 	wire	[ gpo_SELw-1     :   0 ] gpo_plug_wb_slave_0_sel_i;
 	wire			 gpo_plug_wb_slave_0_stb_i;
 	wire	[ gpo_TAGw-1     :   0 ] gpo_plug_wb_slave_0_tag_i;
 	wire			 gpo_plug_wb_slave_0_we_i;

 	wire			 int_ctrl_plug_clk_0_clk_i;
 	wire	[ int_ctrl_INT_NUM-1  :   0 ] int_ctrl_socket_interrupt_peripheral_array_int_i;
 	wire			 int_ctrl_socket_interrupt_peripheral_1_int_i;
 	wire			 int_ctrl_socket_interrupt_peripheral_0_int_i;
 	wire			 int_ctrl_socket_interrupt_cpu_0_int_o;
 	wire			 int_ctrl_plug_reset_0_reset_i;
 	wire			 int_ctrl_plug_wb_slave_0_ack_o;
 	wire	[ int_ctrl_Aw-1       :   0 ] int_ctrl_plug_wb_slave_0_adr_i;
 	wire	[ int_ctrl_Dw-1       :   0 ] int_ctrl_plug_wb_slave_0_dat_i;
 	wire	[ int_ctrl_Dw-1       :   0 ] int_ctrl_plug_wb_slave_0_dat_o;
 	wire			 int_ctrl_plug_wb_slave_0_err_o;
 	wire			 int_ctrl_plug_wb_slave_0_rty_o;
 	wire	[ int_ctrl_SELw-1     :   0 ] int_ctrl_plug_wb_slave_0_sel_i;
 	wire			 int_ctrl_plug_wb_slave_0_stb_i;
 	wire			 int_ctrl_plug_wb_slave_0_we_i;

 	wire			 ni0_plug_clk_0_clk_i;
 	wire			 ni0_plug_interrupt_peripheral_0_int_o;
 	wire			 ni0_plug_wb_master_0_ack_i;
 	wire	[ ni0_M_Aw-1          :   0 ] ni0_plug_wb_master_0_adr_o;
 	wire			 ni0_plug_wb_master_0_cyc_o;
 	wire	[ ni0_Dw-1           :  0 ] ni0_plug_wb_master_0_dat_i;
 	wire	[ ni0_Dw-1            :   0 ] ni0_plug_wb_master_0_dat_o;
 	wire			 ni0_plug_wb_master_0_err_i;
 	wire			 ni0_plug_wb_master_0_rty_i;
 	wire	[ ni0_SELw-1          :   0 ] ni0_plug_wb_master_0_sel_o;
 	wire			 ni0_plug_wb_master_0_stb_o;
 	wire	[ ni0_TAGw-1          :   0 ] ni0_plug_wb_master_0_tag_o;
 	wire			 ni0_plug_wb_master_0_we_o;
 	wire			 ni0_plug_reset_0_reset_i;
 	wire			 ni0_plug_wb_slave_0_ack_o;
 	wire	[ ni0_S_Aw-1     :   0 ] ni0_plug_wb_slave_0_adr_i;
 	wire			 ni0_plug_wb_slave_0_cyc_i;
 	wire	[ ni0_Dw-1       :   0 ] ni0_plug_wb_slave_0_dat_i;
 	wire	[ ni0_Dw-1       :   0 ] ni0_plug_wb_slave_0_dat_o;
 	wire			 ni0_plug_wb_slave_0_err_o;
 	wire			 ni0_plug_wb_slave_0_rty_o;
 	wire	[ ni0_SELw-1     :   0 ] ni0_plug_wb_slave_0_sel_i;
 	wire			 ni0_plug_wb_slave_0_stb_i;
 	wire	[ ni0_TAGw-1     :   0 ] ni0_plug_wb_slave_0_tag_i;
 	wire			 ni0_plug_wb_slave_0_we_i;

 	wire			 timer_plug_clk_0_clk_i;
 	wire			 timer_plug_interrupt_peripheral_0_int_o;
 	wire			 timer_plug_reset_0_reset_i;
 	wire			 timer_plug_wb_slave_0_ack_o;
 	wire	[ timer_Aw-1       :   0 ] timer_plug_wb_slave_0_adr_i;
 	wire			 timer_plug_wb_slave_0_cyc_i;
 	wire	[ timer_Dw-1       :   0 ] timer_plug_wb_slave_0_dat_i;
 	wire	[ timer_Dw-1       :   0 ] timer_plug_wb_slave_0_dat_o;
 	wire			 timer_plug_wb_slave_0_err_o;
 	wire			 timer_plug_wb_slave_0_rty_o;
 	wire	[ timer_SELw-1     :   0 ] timer_plug_wb_slave_0_sel_i;
 	wire			 timer_plug_wb_slave_0_stb_i;
 	wire	[ timer_TAGw-1     :   0 ] timer_plug_wb_slave_0_tag_i;
 	wire			 timer_plug_wb_slave_0_we_i;

 	wire			 wishbone_bus_plug_clk_0_clk_i;
 	wire	[ wishbone_bus_M-1        :   0 ] wishbone_bus_socket_wb_master_array_ack_o;
 	wire			 wishbone_bus_socket_wb_master_2_ack_o;
 	wire			 wishbone_bus_socket_wb_master_1_ack_o;
 	wire			 wishbone_bus_socket_wb_master_0_ack_o;
 	wire	[ (wishbone_bus_Aw*wishbone_bus_M)-1      :   0 ] wishbone_bus_socket_wb_master_array_adr_i;
 	wire	[ wishbone_bus_Aw-1      :   0 ] wishbone_bus_socket_wb_master_2_adr_i;
 	wire	[ wishbone_bus_Aw-1      :   0 ] wishbone_bus_socket_wb_master_1_adr_i;
 	wire	[ wishbone_bus_Aw-1      :   0 ] wishbone_bus_socket_wb_master_0_adr_i;
 	wire	[ wishbone_bus_M-1        :   0 ] wishbone_bus_socket_wb_master_array_cyc_i;
 	wire			 wishbone_bus_socket_wb_master_2_cyc_i;
 	wire			 wishbone_bus_socket_wb_master_1_cyc_i;
 	wire			 wishbone_bus_socket_wb_master_0_cyc_i;
 	wire	[ (wishbone_bus_Dw*wishbone_bus_M)-1      :   0 ] wishbone_bus_socket_wb_master_array_dat_i;
 	wire	[ wishbone_bus_Dw-1      :   0 ] wishbone_bus_socket_wb_master_2_dat_i;
 	wire	[ wishbone_bus_Dw-1      :   0 ] wishbone_bus_socket_wb_master_1_dat_i;
 	wire	[ wishbone_bus_Dw-1      :   0 ] wishbone_bus_socket_wb_master_0_dat_i;
 	wire	[ (wishbone_bus_Dw*wishbone_bus_M)-1      :   0 ] wishbone_bus_socket_wb_master_array_dat_o;
 	wire	[ wishbone_bus_Dw-1      :   0 ] wishbone_bus_socket_wb_master_2_dat_o;
 	wire	[ wishbone_bus_Dw-1      :   0 ] wishbone_bus_socket_wb_master_1_dat_o;
 	wire	[ wishbone_bus_Dw-1      :   0 ] wishbone_bus_socket_wb_master_0_dat_o;
 	wire	[ wishbone_bus_M-1        :   0 ] wishbone_bus_socket_wb_master_array_err_o;
 	wire			 wishbone_bus_socket_wb_master_2_err_o;
 	wire			 wishbone_bus_socket_wb_master_1_err_o;
 	wire			 wishbone_bus_socket_wb_master_0_err_o;
 	wire	[ wishbone_bus_Aw-1       :   0 ] wishbone_bus_socket_wb_addr_map_0_grant_addr;
 	wire	[ wishbone_bus_M-1        :   0 ] wishbone_bus_socket_wb_master_array_rty_o;
 	wire			 wishbone_bus_socket_wb_master_2_rty_o;
 	wire			 wishbone_bus_socket_wb_master_1_rty_o;
 	wire			 wishbone_bus_socket_wb_master_0_rty_o;
 	wire	[ (wishbone_bus_SELw*wishbone_bus_M)-1    :   0 ] wishbone_bus_socket_wb_master_array_sel_i;
 	wire	[ wishbone_bus_SELw-1    :   0 ] wishbone_bus_socket_wb_master_2_sel_i;
 	wire	[ wishbone_bus_SELw-1    :   0 ] wishbone_bus_socket_wb_master_1_sel_i;
 	wire	[ wishbone_bus_SELw-1    :   0 ] wishbone_bus_socket_wb_master_0_sel_i;
 	wire	[ wishbone_bus_M-1        :   0 ] wishbone_bus_socket_wb_master_array_stb_i;
 	wire			 wishbone_bus_socket_wb_master_2_stb_i;
 	wire			 wishbone_bus_socket_wb_master_1_stb_i;
 	wire			 wishbone_bus_socket_wb_master_0_stb_i;
 	wire	[ (wishbone_bus_TAGw*wishbone_bus_M)-1    :   0 ] wishbone_bus_socket_wb_master_array_tag_i;
 	wire	[ wishbone_bus_TAGw-1    :   0 ] wishbone_bus_socket_wb_master_2_tag_i;
 	wire	[ wishbone_bus_TAGw-1    :   0 ] wishbone_bus_socket_wb_master_1_tag_i;
 	wire	[ wishbone_bus_TAGw-1    :   0 ] wishbone_bus_socket_wb_master_0_tag_i;
 	wire	[ wishbone_bus_M-1        :   0 ] wishbone_bus_socket_wb_master_array_we_i;
 	wire			 wishbone_bus_socket_wb_master_2_we_i;
 	wire			 wishbone_bus_socket_wb_master_1_we_i;
 	wire			 wishbone_bus_socket_wb_master_0_we_i;
 	wire			 wishbone_bus_plug_reset_0_reset_i;
 	wire	[ wishbone_bus_S-1        :   0 ] wishbone_bus_socket_wb_slave_array_ack_i;
 	wire			 wishbone_bus_socket_wb_slave_4_ack_i;
 	wire			 wishbone_bus_socket_wb_slave_3_ack_i;
 	wire			 wishbone_bus_socket_wb_slave_2_ack_i;
 	wire			 wishbone_bus_socket_wb_slave_1_ack_i;
 	wire			 wishbone_bus_socket_wb_slave_0_ack_i;
 	wire	[ (wishbone_bus_Aw*wishbone_bus_S)-1      :   0 ] wishbone_bus_socket_wb_slave_array_adr_o;
 	wire	[ wishbone_bus_Aw-1      :   0 ] wishbone_bus_socket_wb_slave_4_adr_o;
 	wire	[ wishbone_bus_Aw-1      :   0 ] wishbone_bus_socket_wb_slave_3_adr_o;
 	wire	[ wishbone_bus_Aw-1      :   0 ] wishbone_bus_socket_wb_slave_2_adr_o;
 	wire	[ wishbone_bus_Aw-1      :   0 ] wishbone_bus_socket_wb_slave_1_adr_o;
 	wire	[ wishbone_bus_Aw-1      :   0 ] wishbone_bus_socket_wb_slave_0_adr_o;
 	wire	[ wishbone_bus_S-1        :   0 ] wishbone_bus_socket_wb_slave_array_cyc_o;
 	wire			 wishbone_bus_socket_wb_slave_4_cyc_o;
 	wire			 wishbone_bus_socket_wb_slave_3_cyc_o;
 	wire			 wishbone_bus_socket_wb_slave_2_cyc_o;
 	wire			 wishbone_bus_socket_wb_slave_1_cyc_o;
 	wire			 wishbone_bus_socket_wb_slave_0_cyc_o;
 	wire	[ (wishbone_bus_Dw*wishbone_bus_S)-1      :   0 ] wishbone_bus_socket_wb_slave_array_dat_i;
 	wire	[ wishbone_bus_Dw-1      :   0 ] wishbone_bus_socket_wb_slave_4_dat_i;
 	wire	[ wishbone_bus_Dw-1      :   0 ] wishbone_bus_socket_wb_slave_3_dat_i;
 	wire	[ wishbone_bus_Dw-1      :   0 ] wishbone_bus_socket_wb_slave_2_dat_i;
 	wire	[ wishbone_bus_Dw-1      :   0 ] wishbone_bus_socket_wb_slave_1_dat_i;
 	wire	[ wishbone_bus_Dw-1      :   0 ] wishbone_bus_socket_wb_slave_0_dat_i;
 	wire	[ (wishbone_bus_Dw*wishbone_bus_S)-1      :   0 ] wishbone_bus_socket_wb_slave_array_dat_o;
 	wire	[ wishbone_bus_Dw-1      :   0 ] wishbone_bus_socket_wb_slave_4_dat_o;
 	wire	[ wishbone_bus_Dw-1      :   0 ] wishbone_bus_socket_wb_slave_3_dat_o;
 	wire	[ wishbone_bus_Dw-1      :   0 ] wishbone_bus_socket_wb_slave_2_dat_o;
 	wire	[ wishbone_bus_Dw-1      :   0 ] wishbone_bus_socket_wb_slave_1_dat_o;
 	wire	[ wishbone_bus_Dw-1      :   0 ] wishbone_bus_socket_wb_slave_0_dat_o;
 	wire	[ wishbone_bus_S-1        :   0 ] wishbone_bus_socket_wb_slave_array_err_i;
 	wire			 wishbone_bus_socket_wb_slave_4_err_i;
 	wire			 wishbone_bus_socket_wb_slave_3_err_i;
 	wire			 wishbone_bus_socket_wb_slave_2_err_i;
 	wire			 wishbone_bus_socket_wb_slave_1_err_i;
 	wire			 wishbone_bus_socket_wb_slave_0_err_i;
 	wire	[ wishbone_bus_S-1        :   0 ] wishbone_bus_socket_wb_slave_array_rty_i;
 	wire			 wishbone_bus_socket_wb_slave_4_rty_i;
 	wire			 wishbone_bus_socket_wb_slave_3_rty_i;
 	wire			 wishbone_bus_socket_wb_slave_2_rty_i;
 	wire			 wishbone_bus_socket_wb_slave_1_rty_i;
 	wire			 wishbone_bus_socket_wb_slave_0_rty_i;
 	wire	[ (wishbone_bus_SELw*wishbone_bus_S)-1    :   0 ] wishbone_bus_socket_wb_slave_array_sel_o;
 	wire	[ wishbone_bus_SELw-1    :   0 ] wishbone_bus_socket_wb_slave_4_sel_o;
 	wire	[ wishbone_bus_SELw-1    :   0 ] wishbone_bus_socket_wb_slave_3_sel_o;
 	wire	[ wishbone_bus_SELw-1    :   0 ] wishbone_bus_socket_wb_slave_2_sel_o;
 	wire	[ wishbone_bus_SELw-1    :   0 ] wishbone_bus_socket_wb_slave_1_sel_o;
 	wire	[ wishbone_bus_SELw-1    :   0 ] wishbone_bus_socket_wb_slave_0_sel_o;
 	wire	[ wishbone_bus_S-1        :   0 ] wishbone_bus_socket_wb_addr_map_0_sel_one_hot;
 	wire	[ wishbone_bus_S-1        :   0 ] wishbone_bus_socket_wb_slave_array_stb_o;
 	wire			 wishbone_bus_socket_wb_slave_4_stb_o;
 	wire			 wishbone_bus_socket_wb_slave_3_stb_o;
 	wire			 wishbone_bus_socket_wb_slave_2_stb_o;
 	wire			 wishbone_bus_socket_wb_slave_1_stb_o;
 	wire			 wishbone_bus_socket_wb_slave_0_stb_o;
 	wire	[ (wishbone_bus_TAGw*wishbone_bus_S)-1    :   0 ] wishbone_bus_socket_wb_slave_array_tag_o;
 	wire	[ wishbone_bus_TAGw-1    :   0 ] wishbone_bus_socket_wb_slave_4_tag_o;
 	wire	[ wishbone_bus_TAGw-1    :   0 ] wishbone_bus_socket_wb_slave_3_tag_o;
 	wire	[ wishbone_bus_TAGw-1    :   0 ] wishbone_bus_socket_wb_slave_2_tag_o;
 	wire	[ wishbone_bus_TAGw-1    :   0 ] wishbone_bus_socket_wb_slave_1_tag_o;
 	wire	[ wishbone_bus_TAGw-1    :   0 ] wishbone_bus_socket_wb_slave_0_tag_o;
 	wire	[ wishbone_bus_S-1        :   0 ] wishbone_bus_socket_wb_slave_array_we_o;
 	wire			 wishbone_bus_socket_wb_slave_4_we_o;
 	wire			 wishbone_bus_socket_wb_slave_3_we_o;
 	wire			 wishbone_bus_socket_wb_slave_2_we_o;
 	wire			 wishbone_bus_socket_wb_slave_1_we_o;
 	wire			 wishbone_bus_socket_wb_slave_0_we_o;

 prog_ram_single_port #(
 		.Aw(ram_Aw),
		.Dw(ram_Dw),
		.FPGA_FAMILY(ram_FPGA_FAMILY),
		.RAM_TAG_STRING(ram_RAM_TAG_STRING),
		.SELw(ram_SELw),
		.TAGw(ram_TAGw)
	)  ram 	(
		.clk(ram_plug_clk_0_clk_i),
		.reset(ram_plug_reset_0_reset_i),
		.sa_ack_o(ram_plug_wb_slave_0_ack_o),
		.sa_addr_i(ram_plug_wb_slave_0_adr_i),
		.sa_cyc_i(ram_plug_wb_slave_0_cyc_i),
		.sa_dat_i(ram_plug_wb_slave_0_dat_i),
		.sa_dat_o(ram_plug_wb_slave_0_dat_o),
		.sa_err_o(ram_plug_wb_slave_0_err_o),
		.sa_rty_o(ram_plug_wb_slave_0_rty_o),
		.sa_sel_i(ram_plug_wb_slave_0_sel_i),
		.sa_stb_i(ram_plug_wb_slave_0_stb_i),
		.sa_tag_i(ram_plug_wb_slave_0_tag_i),
		.sa_we_i(ram_plug_wb_slave_0_we_i)
	);
 aeMB_top #(
 		.AEMB_BSF(aeMB_AEMB_BSF),
		.AEMB_DWB(aeMB_AEMB_DWB),
		.AEMB_ICH(aeMB_AEMB_ICH),
		.AEMB_IDX(aeMB_AEMB_IDX),
		.AEMB_IWB(aeMB_AEMB_IWB),
		.AEMB_MUL(aeMB_AEMB_MUL),
		.AEMB_XWB(aeMB_AEMB_XWB)
	)  aeMB 	(
		.clk(aeMB_plug_clk_0_clk_i),
		.dwb_ack_i(aeMB_plug_wb_master_1_ack_i),
		.dwb_adr_o(aeMB_plug_wb_master_1_adr_o),
		.dwb_cyc_o(aeMB_plug_wb_master_1_cyc_o),
		.dwb_dat_i(aeMB_plug_wb_master_1_dat_i),
		.dwb_dat_o(aeMB_plug_wb_master_1_dat_o),
		.dwb_err_i(aeMB_plug_wb_master_1_err_i),
		.dwb_rty_i(aeMB_plug_wb_master_1_rty_i),
		.dwb_sel_o(aeMB_plug_wb_master_1_sel_o),
		.dwb_stb_o(aeMB_plug_wb_master_1_stb_o),
		.dwb_tag_o(aeMB_plug_wb_master_1_tag_o),
		.dwb_wre_o(aeMB_plug_wb_master_1_we_o),
		.iwb_ack_i(aeMB_plug_wb_master_0_ack_i),
		.iwb_adr_o(aeMB_plug_wb_master_0_adr_o),
		.iwb_cyc_o(aeMB_plug_wb_master_0_cyc_o),
		.iwb_dat_i(aeMB_plug_wb_master_0_dat_i),
		.iwb_dat_o(aeMB_plug_wb_master_0_dat_o),
		.iwb_err_i(aeMB_plug_wb_master_0_err_i),
		.iwb_rty_i(aeMB_plug_wb_master_0_rty_i),
		.iwb_sel_o(aeMB_plug_wb_master_0_sel_o),
		.iwb_stb_o(aeMB_plug_wb_master_0_stb_o),
		.iwb_tag_o(aeMB_plug_wb_master_0_tag_o),
		.iwb_wre_o(aeMB_plug_wb_master_0_we_o),
		.reset(aeMB_plug_reset_0_reset_i),
		.sys_ena_i(aeMB_sys_ena_i),
		.sys_int_i(aeMB_plug_interrupt_cpu_0_int_i)
	);
 clk_source  src 	(
		.clk_in(src_clk_in),
		.clk_out(src_socket_clk_0_clk_o),
		.reset_in(src_reset_in),
		.reset_out(src_socket_reset_0_reset_o)
	);
 gpo #(
 		.Aw(gpo_Aw),
		.Dw(gpo_Dw),
		.PORT_WIDTH(gpo_PORT_WIDTH),
		.SELw(gpo_SELw),
		.TAGw(gpo_TAGw)
	)  gpo 	(
		.clk(gpo_plug_clk_0_clk_i),
		.port_o(gpo_port_o),
		.reset(gpo_plug_reset_0_reset_i),
		.sa_ack_o(gpo_plug_wb_slave_0_ack_o),
		.sa_addr_i(gpo_plug_wb_slave_0_adr_i),
		.sa_cyc_i(gpo_plug_wb_slave_0_cyc_i),
		.sa_dat_i(gpo_plug_wb_slave_0_dat_i),
		.sa_dat_o(gpo_plug_wb_slave_0_dat_o),
		.sa_err_o(gpo_plug_wb_slave_0_err_o),
		.sa_rty_o(gpo_plug_wb_slave_0_rty_o),
		.sa_sel_i(gpo_plug_wb_slave_0_sel_i),
		.sa_stb_i(gpo_plug_wb_slave_0_stb_i),
		.sa_tag_i(gpo_plug_wb_slave_0_tag_i),
		.sa_we_i(gpo_plug_wb_slave_0_we_i)
	);
 int_ctrl #(
 		.Aw(int_ctrl_Aw),
		.Dw(int_ctrl_Dw),
		.INT_NUM(int_ctrl_INT_NUM),
		.SELw(int_ctrl_SELw)
	)  int_ctrl 	(
		.clk(int_ctrl_plug_clk_0_clk_i),
		.int_i(int_ctrl_socket_interrupt_peripheral_array_int_i),
		.int_o(int_ctrl_socket_interrupt_cpu_0_int_o),
		.reset(int_ctrl_plug_reset_0_reset_i),
		.sa_ack_o(int_ctrl_plug_wb_slave_0_ack_o),
		.sa_addr_i(int_ctrl_plug_wb_slave_0_adr_i),
		.sa_dat_i(int_ctrl_plug_wb_slave_0_dat_i),
		.sa_dat_o(int_ctrl_plug_wb_slave_0_dat_o),
		.sa_err_o(int_ctrl_plug_wb_slave_0_err_o),
		.sa_rty_o(int_ctrl_plug_wb_slave_0_rty_o),
		.sa_sel_i(int_ctrl_plug_wb_slave_0_sel_i),
		.sa_stb_i(int_ctrl_plug_wb_slave_0_stb_i),
		.sa_we_i(int_ctrl_plug_wb_slave_0_we_i)
	);
 ni #(
 		.NY(ni0_NY),
		.NX(ni0_NX),
		.V(ni0_V),
		.B(ni0_B),
		.Dw(ni0_Dw),
		.DEBUG_EN(ni0_DEBUG_EN),
		.TAGw(ni0_TAGw),
		.M_Aw(ni0_M_Aw),
		.ROUTE_NAME(ni0_ROUTE_NAME),
		.Fpay(ni0_Fpay),
		.SELw(ni0_SELw),
		.ROUTE_TYPE(ni0_ROUTE_TYPE),
		.P(ni0_P),
		.S_Aw(ni0_S_Aw),
		.TOPOLOGY(ni0_TOPOLOGY)
	)  ni0 	(
		.clk(ni0_plug_clk_0_clk_i),
		.credit_in(ni0_credit_in),
		.credit_out(ni0_credit_out),
		.current_x(ni0_current_x),
		.current_y(ni0_current_y),
		.flit_in(ni0_flit_in),
		.flit_in_wr(ni0_flit_in_wr),
		.flit_out(ni0_flit_out),
		.flit_out_wr(ni0_flit_out_wr),
		.irq(ni0_plug_interrupt_peripheral_0_int_o),
		.m_ack_i(ni0_plug_wb_master_0_ack_i),
		.m_addr_o(ni0_plug_wb_master_0_adr_o),
		.m_cyc_o(ni0_plug_wb_master_0_cyc_o),
		.m_dat_i(ni0_plug_wb_master_0_dat_i),
		.m_dat_o(ni0_plug_wb_master_0_dat_o),
		.m_err_i(ni0_plug_wb_master_0_err_i),
		.m_rty_i(ni0_plug_wb_master_0_rty_i),
		.m_sel_o(ni0_plug_wb_master_0_sel_o),
		.m_stb_o(ni0_plug_wb_master_0_stb_o),
		.m_tag_o(ni0_plug_wb_master_0_tag_o),
		.m_we_o(ni0_plug_wb_master_0_we_o),
		.reset(ni0_plug_reset_0_reset_i),
		.s_ack_o(ni0_plug_wb_slave_0_ack_o),
		.s_addr_i(ni0_plug_wb_slave_0_adr_i),
		.s_cyc_i(ni0_plug_wb_slave_0_cyc_i),
		.s_dat_i(ni0_plug_wb_slave_0_dat_i),
		.s_dat_o(ni0_plug_wb_slave_0_dat_o),
		.s_err_o(ni0_plug_wb_slave_0_err_o),
		.s_rty_o(ni0_plug_wb_slave_0_rty_o),
		.s_sel_i(ni0_plug_wb_slave_0_sel_i),
		.s_stb_i(ni0_plug_wb_slave_0_stb_i),
		.s_tag_i(ni0_plug_wb_slave_0_tag_i),
		.s_we_i(ni0_plug_wb_slave_0_we_i)
	);
 timer #(
 		.Aw(timer_Aw),
		.CNTw(timer_CNTw),
		.Dw(timer_Dw),
		.SELw(timer_SELw),
		.TAGw(timer_TAGw)
	)  timer 	(
		.clk(timer_plug_clk_0_clk_i),
		.irq(timer_plug_interrupt_peripheral_0_int_o),
		.reset(timer_plug_reset_0_reset_i),
		.sa_ack_o(timer_plug_wb_slave_0_ack_o),
		.sa_addr_i(timer_plug_wb_slave_0_adr_i),
		.sa_cyc_i(timer_plug_wb_slave_0_cyc_i),
		.sa_dat_i(timer_plug_wb_slave_0_dat_i),
		.sa_dat_o(timer_plug_wb_slave_0_dat_o),
		.sa_err_o(timer_plug_wb_slave_0_err_o),
		.sa_rty_o(timer_plug_wb_slave_0_rty_o),
		.sa_sel_i(timer_plug_wb_slave_0_sel_i),
		.sa_stb_i(timer_plug_wb_slave_0_stb_i),
		.sa_tag_i(timer_plug_wb_slave_0_tag_i),
		.sa_we_i(timer_plug_wb_slave_0_we_i)
	);
 wishbone_bus #(
 		.Aw(wishbone_bus_Aw),
		.Dw(wishbone_bus_Dw),
		.M(wishbone_bus_M),
		.S(wishbone_bus_S),
		.SELw(wishbone_bus_SELw),
		.TAGw(wishbone_bus_TAGw)
	)  wishbone_bus 	(
		.clk(wishbone_bus_plug_clk_0_clk_i),
		.m_ack_o_all(wishbone_bus_socket_wb_master_array_ack_o),
		.m_adr_i_all(wishbone_bus_socket_wb_master_array_adr_i),
		.m_cyc_i_all(wishbone_bus_socket_wb_master_array_cyc_i),
		.m_dat_i_all(wishbone_bus_socket_wb_master_array_dat_i),
		.m_dat_o_all(wishbone_bus_socket_wb_master_array_dat_o),
		.m_err_o_all(wishbone_bus_socket_wb_master_array_err_o),
		.m_grant_addr(wishbone_bus_socket_wb_addr_map_0_grant_addr),
		.m_rty_o_all(wishbone_bus_socket_wb_master_array_rty_o),
		.m_sel_i_all(wishbone_bus_socket_wb_master_array_sel_i),
		.m_stb_i_all(wishbone_bus_socket_wb_master_array_stb_i),
		.m_tag_i_all(wishbone_bus_socket_wb_master_array_tag_i),
		.m_we_i_all(wishbone_bus_socket_wb_master_array_we_i),
		.reset(wishbone_bus_plug_reset_0_reset_i),
		.s_ack_i_all(wishbone_bus_socket_wb_slave_array_ack_i),
		.s_adr_o_all(wishbone_bus_socket_wb_slave_array_adr_o),
		.s_cyc_o_all(wishbone_bus_socket_wb_slave_array_cyc_o),
		.s_dat_i_all(wishbone_bus_socket_wb_slave_array_dat_i),
		.s_dat_o_all(wishbone_bus_socket_wb_slave_array_dat_o),
		.s_err_i_all(wishbone_bus_socket_wb_slave_array_err_i),
		.s_rty_i_all(wishbone_bus_socket_wb_slave_array_rty_i),
		.s_sel_o_all(wishbone_bus_socket_wb_slave_array_sel_o),
		.s_sel_one_hot(wishbone_bus_socket_wb_addr_map_0_sel_one_hot),
		.s_stb_o_all(wishbone_bus_socket_wb_slave_array_stb_o),
		.s_tag_o_all(wishbone_bus_socket_wb_slave_array_tag_o),
		.s_we_o_all(wishbone_bus_socket_wb_slave_array_we_o)
	);
 
 	assign  ram_plug_clk_0_clk_i = src_socket_clk_0_clk_o;
 	assign  ram_plug_reset_0_reset_i = src_socket_reset_0_reset_o;
 	assign  wishbone_bus_socket_wb_slave_0_ack_i  = ram_plug_wb_slave_0_ack_o;
 	assign  ram_plug_wb_slave_0_adr_i = wishbone_bus_socket_wb_slave_0_adr_o;
 	assign  ram_plug_wb_slave_0_cyc_i = wishbone_bus_socket_wb_slave_0_cyc_o;
 	assign  ram_plug_wb_slave_0_dat_i = wishbone_bus_socket_wb_slave_0_dat_o;
 	assign  wishbone_bus_socket_wb_slave_0_dat_i  = ram_plug_wb_slave_0_dat_o;
 	assign  wishbone_bus_socket_wb_slave_0_err_i  = ram_plug_wb_slave_0_err_o;
 	assign  wishbone_bus_socket_wb_slave_0_rty_i  = ram_plug_wb_slave_0_rty_o;
 	assign  ram_plug_wb_slave_0_sel_i = wishbone_bus_socket_wb_slave_0_sel_o;
 	assign  ram_plug_wb_slave_0_stb_i = wishbone_bus_socket_wb_slave_0_stb_o;
 	assign  ram_plug_wb_slave_0_tag_i = wishbone_bus_socket_wb_slave_0_tag_o;
 	assign  ram_plug_wb_slave_0_we_i = wishbone_bus_socket_wb_slave_0_we_o;

 
 	assign  aeMB_plug_clk_0_clk_i = src_socket_clk_0_clk_o;
 	assign  aeMB_plug_wb_master_1_ack_i = wishbone_bus_socket_wb_master_1_ack_o;
 	assign  wishbone_bus_socket_wb_master_1_adr_i  = aeMB_plug_wb_master_1_adr_o;
 	assign  wishbone_bus_socket_wb_master_1_cyc_i  = aeMB_plug_wb_master_1_cyc_o;
 	assign  aeMB_plug_wb_master_1_dat_i = wishbone_bus_socket_wb_master_1_dat_o;
 	assign  wishbone_bus_socket_wb_master_1_dat_i  = aeMB_plug_wb_master_1_dat_o;
 	assign  aeMB_plug_wb_master_1_err_i = wishbone_bus_socket_wb_master_1_err_o;
 	assign  aeMB_plug_wb_master_1_rty_i = wishbone_bus_socket_wb_master_1_rty_o;
 	assign  wishbone_bus_socket_wb_master_1_sel_i  = aeMB_plug_wb_master_1_sel_o;
 	assign  wishbone_bus_socket_wb_master_1_stb_i  = aeMB_plug_wb_master_1_stb_o;
 	assign  wishbone_bus_socket_wb_master_1_tag_i  = aeMB_plug_wb_master_1_tag_o;
 	assign  wishbone_bus_socket_wb_master_1_we_i  = aeMB_plug_wb_master_1_we_o;
 	assign  aeMB_plug_wb_master_0_ack_i = wishbone_bus_socket_wb_master_0_ack_o;
 	assign  wishbone_bus_socket_wb_master_0_adr_i  = aeMB_plug_wb_master_0_adr_o;
 	assign  wishbone_bus_socket_wb_master_0_cyc_i  = aeMB_plug_wb_master_0_cyc_o;
 	assign  aeMB_plug_wb_master_0_dat_i = wishbone_bus_socket_wb_master_0_dat_o;
 	assign  wishbone_bus_socket_wb_master_0_dat_i  = aeMB_plug_wb_master_0_dat_o;
 	assign  aeMB_plug_wb_master_0_err_i = wishbone_bus_socket_wb_master_0_err_o;
 	assign  aeMB_plug_wb_master_0_rty_i = wishbone_bus_socket_wb_master_0_rty_o;
 	assign  wishbone_bus_socket_wb_master_0_sel_i  = aeMB_plug_wb_master_0_sel_o;
 	assign  wishbone_bus_socket_wb_master_0_stb_i  = aeMB_plug_wb_master_0_stb_o;
 	assign  wishbone_bus_socket_wb_master_0_tag_i  = aeMB_plug_wb_master_0_tag_o;
 	assign  wishbone_bus_socket_wb_master_0_we_i  = aeMB_plug_wb_master_0_we_o;
 	assign  aeMB_plug_reset_0_reset_i = src_socket_reset_0_reset_o;
 	assign  aeMB_plug_interrupt_cpu_0_int_i = int_ctrl_socket_interrupt_cpu_0_int_o;

 

 
 	assign  gpo_plug_clk_0_clk_i = src_socket_clk_0_clk_o;
 	assign  gpo_plug_reset_0_reset_i = src_socket_reset_0_reset_o;
 	assign  wishbone_bus_socket_wb_slave_1_ack_i  = gpo_plug_wb_slave_0_ack_o;
 	assign  gpo_plug_wb_slave_0_adr_i = wishbone_bus_socket_wb_slave_1_adr_o;
 	assign  gpo_plug_wb_slave_0_cyc_i = wishbone_bus_socket_wb_slave_1_cyc_o;
 	assign  gpo_plug_wb_slave_0_dat_i = wishbone_bus_socket_wb_slave_1_dat_o;
 	assign  wishbone_bus_socket_wb_slave_1_dat_i  = gpo_plug_wb_slave_0_dat_o;
 	assign  wishbone_bus_socket_wb_slave_1_err_i  = gpo_plug_wb_slave_0_err_o;
 	assign  wishbone_bus_socket_wb_slave_1_rty_i  = gpo_plug_wb_slave_0_rty_o;
 	assign  gpo_plug_wb_slave_0_sel_i = wishbone_bus_socket_wb_slave_1_sel_o;
 	assign  gpo_plug_wb_slave_0_stb_i = wishbone_bus_socket_wb_slave_1_stb_o;
 	assign  gpo_plug_wb_slave_0_tag_i = wishbone_bus_socket_wb_slave_1_tag_o;
 	assign  gpo_plug_wb_slave_0_we_i = wishbone_bus_socket_wb_slave_1_we_o;

 
 	assign  int_ctrl_plug_clk_0_clk_i = src_socket_clk_0_clk_o;
 	assign  int_ctrl_plug_reset_0_reset_i = src_socket_reset_0_reset_o;
 	assign  wishbone_bus_socket_wb_slave_2_ack_i  = int_ctrl_plug_wb_slave_0_ack_o;
 	assign  int_ctrl_plug_wb_slave_0_adr_i = wishbone_bus_socket_wb_slave_2_adr_o;
 	assign  int_ctrl_plug_wb_slave_0_dat_i = wishbone_bus_socket_wb_slave_2_dat_o;
 	assign  wishbone_bus_socket_wb_slave_2_dat_i  = int_ctrl_plug_wb_slave_0_dat_o;
 	assign  wishbone_bus_socket_wb_slave_2_err_i  = int_ctrl_plug_wb_slave_0_err_o;
 	assign  wishbone_bus_socket_wb_slave_2_rty_i  = int_ctrl_plug_wb_slave_0_rty_o;
 	assign  int_ctrl_plug_wb_slave_0_sel_i = wishbone_bus_socket_wb_slave_2_sel_o;
 	assign  int_ctrl_plug_wb_slave_0_stb_i = wishbone_bus_socket_wb_slave_2_stb_o;
 	assign  int_ctrl_plug_wb_slave_0_we_i = wishbone_bus_socket_wb_slave_2_we_o;

 
 	assign  ni0_plug_clk_0_clk_i = src_socket_clk_0_clk_o;
 	assign  int_ctrl_socket_interrupt_peripheral_0_int_i  = ni0_plug_interrupt_peripheral_0_int_o;
 	assign  ni0_plug_wb_master_0_ack_i = wishbone_bus_socket_wb_master_2_ack_o;
 	assign  wishbone_bus_socket_wb_master_2_adr_i  = ni0_plug_wb_master_0_adr_o;
 	assign  wishbone_bus_socket_wb_master_2_cyc_i  = ni0_plug_wb_master_0_cyc_o;
 	assign  ni0_plug_wb_master_0_dat_i = wishbone_bus_socket_wb_master_2_dat_o;
 	assign  wishbone_bus_socket_wb_master_2_dat_i  = ni0_plug_wb_master_0_dat_o;
 	assign  ni0_plug_wb_master_0_err_i = wishbone_bus_socket_wb_master_2_err_o;
 	assign  ni0_plug_wb_master_0_rty_i = wishbone_bus_socket_wb_master_2_rty_o;
 	assign  wishbone_bus_socket_wb_master_2_sel_i  = ni0_plug_wb_master_0_sel_o;
 	assign  wishbone_bus_socket_wb_master_2_stb_i  = ni0_plug_wb_master_0_stb_o;
 	assign  wishbone_bus_socket_wb_master_2_tag_i  = ni0_plug_wb_master_0_tag_o;
 	assign  wishbone_bus_socket_wb_master_2_we_i  = ni0_plug_wb_master_0_we_o;
 	assign  ni0_plug_reset_0_reset_i = src_socket_reset_0_reset_o;
 	assign  wishbone_bus_socket_wb_slave_3_ack_i  = ni0_plug_wb_slave_0_ack_o;
 	assign  ni0_plug_wb_slave_0_adr_i = wishbone_bus_socket_wb_slave_3_adr_o;
 	assign  ni0_plug_wb_slave_0_cyc_i = wishbone_bus_socket_wb_slave_3_cyc_o;
 	assign  ni0_plug_wb_slave_0_dat_i = wishbone_bus_socket_wb_slave_3_dat_o;
 	assign  wishbone_bus_socket_wb_slave_3_dat_i  = ni0_plug_wb_slave_0_dat_o;
 	assign  wishbone_bus_socket_wb_slave_3_err_i  = ni0_plug_wb_slave_0_err_o;
 	assign  wishbone_bus_socket_wb_slave_3_rty_i  = ni0_plug_wb_slave_0_rty_o;
 	assign  ni0_plug_wb_slave_0_sel_i = wishbone_bus_socket_wb_slave_3_sel_o;
 	assign  ni0_plug_wb_slave_0_stb_i = wishbone_bus_socket_wb_slave_3_stb_o;
 	assign  ni0_plug_wb_slave_0_tag_i = wishbone_bus_socket_wb_slave_3_tag_o;
 	assign  ni0_plug_wb_slave_0_we_i = wishbone_bus_socket_wb_slave_3_we_o;

 
 	assign  timer_plug_clk_0_clk_i = src_socket_clk_0_clk_o;
 	assign  int_ctrl_socket_interrupt_peripheral_1_int_i  = timer_plug_interrupt_peripheral_0_int_o;
 	assign  timer_plug_reset_0_reset_i = src_socket_reset_0_reset_o;
 	assign  wishbone_bus_socket_wb_slave_4_ack_i  = timer_plug_wb_slave_0_ack_o;
 	assign  timer_plug_wb_slave_0_adr_i = wishbone_bus_socket_wb_slave_4_adr_o;
 	assign  timer_plug_wb_slave_0_cyc_i = wishbone_bus_socket_wb_slave_4_cyc_o;
 	assign  timer_plug_wb_slave_0_dat_i = wishbone_bus_socket_wb_slave_4_dat_o;
 	assign  wishbone_bus_socket_wb_slave_4_dat_i  = timer_plug_wb_slave_0_dat_o;
 	assign  wishbone_bus_socket_wb_slave_4_err_i  = timer_plug_wb_slave_0_err_o;
 	assign  wishbone_bus_socket_wb_slave_4_rty_i  = timer_plug_wb_slave_0_rty_o;
 	assign  timer_plug_wb_slave_0_sel_i = wishbone_bus_socket_wb_slave_4_sel_o;
 	assign  timer_plug_wb_slave_0_stb_i = wishbone_bus_socket_wb_slave_4_stb_o;
 	assign  timer_plug_wb_slave_0_tag_i = wishbone_bus_socket_wb_slave_4_tag_o;
 	assign  timer_plug_wb_slave_0_we_i = wishbone_bus_socket_wb_slave_4_we_o;

 
 	assign  wishbone_bus_plug_clk_0_clk_i = src_socket_clk_0_clk_o;
 	assign  wishbone_bus_plug_reset_0_reset_i = src_socket_reset_0_reset_o;

 	assign int_ctrl_socket_interrupt_peripheral_array_int_i ={int_ctrl_socket_interrupt_peripheral_1_int_i ,int_ctrl_socket_interrupt_peripheral_0_int_i};

 	assign {wishbone_bus_socket_wb_master_2_ack_o ,wishbone_bus_socket_wb_master_1_ack_o ,wishbone_bus_socket_wb_master_0_ack_o} =wishbone_bus_socket_wb_master_array_ack_o;
 	assign wishbone_bus_socket_wb_master_array_adr_i ={wishbone_bus_socket_wb_master_2_adr_i ,wishbone_bus_socket_wb_master_1_adr_i ,wishbone_bus_socket_wb_master_0_adr_i};
 	assign wishbone_bus_socket_wb_master_array_cyc_i ={wishbone_bus_socket_wb_master_2_cyc_i ,wishbone_bus_socket_wb_master_1_cyc_i ,wishbone_bus_socket_wb_master_0_cyc_i};
 	assign wishbone_bus_socket_wb_master_array_dat_i ={wishbone_bus_socket_wb_master_2_dat_i ,wishbone_bus_socket_wb_master_1_dat_i ,wishbone_bus_socket_wb_master_0_dat_i};
 	assign {wishbone_bus_socket_wb_master_2_dat_o ,wishbone_bus_socket_wb_master_1_dat_o ,wishbone_bus_socket_wb_master_0_dat_o} =wishbone_bus_socket_wb_master_array_dat_o;
 	assign {wishbone_bus_socket_wb_master_2_err_o ,wishbone_bus_socket_wb_master_1_err_o ,wishbone_bus_socket_wb_master_0_err_o} =wishbone_bus_socket_wb_master_array_err_o;
 	assign {wishbone_bus_socket_wb_master_2_rty_o ,wishbone_bus_socket_wb_master_1_rty_o ,wishbone_bus_socket_wb_master_0_rty_o} =wishbone_bus_socket_wb_master_array_rty_o;
 	assign wishbone_bus_socket_wb_master_array_sel_i ={wishbone_bus_socket_wb_master_2_sel_i ,wishbone_bus_socket_wb_master_1_sel_i ,wishbone_bus_socket_wb_master_0_sel_i};
 	assign wishbone_bus_socket_wb_master_array_stb_i ={wishbone_bus_socket_wb_master_2_stb_i ,wishbone_bus_socket_wb_master_1_stb_i ,wishbone_bus_socket_wb_master_0_stb_i};
 	assign wishbone_bus_socket_wb_master_array_tag_i ={wishbone_bus_socket_wb_master_2_tag_i ,wishbone_bus_socket_wb_master_1_tag_i ,wishbone_bus_socket_wb_master_0_tag_i};
 	assign wishbone_bus_socket_wb_master_array_we_i ={wishbone_bus_socket_wb_master_2_we_i ,wishbone_bus_socket_wb_master_1_we_i ,wishbone_bus_socket_wb_master_0_we_i};
 	assign wishbone_bus_socket_wb_slave_array_ack_i ={wishbone_bus_socket_wb_slave_4_ack_i ,wishbone_bus_socket_wb_slave_3_ack_i ,wishbone_bus_socket_wb_slave_2_ack_i ,wishbone_bus_socket_wb_slave_1_ack_i ,wishbone_bus_socket_wb_slave_0_ack_i};
 	assign {wishbone_bus_socket_wb_slave_4_adr_o ,wishbone_bus_socket_wb_slave_3_adr_o ,wishbone_bus_socket_wb_slave_2_adr_o ,wishbone_bus_socket_wb_slave_1_adr_o ,wishbone_bus_socket_wb_slave_0_adr_o} =wishbone_bus_socket_wb_slave_array_adr_o;
 	assign {wishbone_bus_socket_wb_slave_4_cyc_o ,wishbone_bus_socket_wb_slave_3_cyc_o ,wishbone_bus_socket_wb_slave_2_cyc_o ,wishbone_bus_socket_wb_slave_1_cyc_o ,wishbone_bus_socket_wb_slave_0_cyc_o} =wishbone_bus_socket_wb_slave_array_cyc_o;
 	assign wishbone_bus_socket_wb_slave_array_dat_i ={wishbone_bus_socket_wb_slave_4_dat_i ,wishbone_bus_socket_wb_slave_3_dat_i ,wishbone_bus_socket_wb_slave_2_dat_i ,wishbone_bus_socket_wb_slave_1_dat_i ,wishbone_bus_socket_wb_slave_0_dat_i};
 	assign {wishbone_bus_socket_wb_slave_4_dat_o ,wishbone_bus_socket_wb_slave_3_dat_o ,wishbone_bus_socket_wb_slave_2_dat_o ,wishbone_bus_socket_wb_slave_1_dat_o ,wishbone_bus_socket_wb_slave_0_dat_o} =wishbone_bus_socket_wb_slave_array_dat_o;
 	assign wishbone_bus_socket_wb_slave_array_err_i ={wishbone_bus_socket_wb_slave_4_err_i ,wishbone_bus_socket_wb_slave_3_err_i ,wishbone_bus_socket_wb_slave_2_err_i ,wishbone_bus_socket_wb_slave_1_err_i ,wishbone_bus_socket_wb_slave_0_err_i};
 	assign wishbone_bus_socket_wb_slave_array_rty_i ={wishbone_bus_socket_wb_slave_4_rty_i ,wishbone_bus_socket_wb_slave_3_rty_i ,wishbone_bus_socket_wb_slave_2_rty_i ,wishbone_bus_socket_wb_slave_1_rty_i ,wishbone_bus_socket_wb_slave_0_rty_i};
 	assign {wishbone_bus_socket_wb_slave_4_sel_o ,wishbone_bus_socket_wb_slave_3_sel_o ,wishbone_bus_socket_wb_slave_2_sel_o ,wishbone_bus_socket_wb_slave_1_sel_o ,wishbone_bus_socket_wb_slave_0_sel_o} =wishbone_bus_socket_wb_slave_array_sel_o;
 	assign {wishbone_bus_socket_wb_slave_4_stb_o ,wishbone_bus_socket_wb_slave_3_stb_o ,wishbone_bus_socket_wb_slave_2_stb_o ,wishbone_bus_socket_wb_slave_1_stb_o ,wishbone_bus_socket_wb_slave_0_stb_o} =wishbone_bus_socket_wb_slave_array_stb_o;
 	assign {wishbone_bus_socket_wb_slave_4_tag_o ,wishbone_bus_socket_wb_slave_3_tag_o ,wishbone_bus_socket_wb_slave_2_tag_o ,wishbone_bus_socket_wb_slave_1_tag_o ,wishbone_bus_socket_wb_slave_0_tag_o} =wishbone_bus_socket_wb_slave_array_tag_o;
 	assign {wishbone_bus_socket_wb_slave_4_we_o ,wishbone_bus_socket_wb_slave_3_we_o ,wishbone_bus_socket_wb_slave_2_we_o ,wishbone_bus_socket_wb_slave_1_we_o ,wishbone_bus_socket_wb_slave_0_we_o} =wishbone_bus_socket_wb_slave_array_we_o;

 
//Wishbone slave address match
 /* ram wb_slave 0 */
 	assign wishbone_bus_socket_wb_addr_map_0_sel_one_hot[0]= ((wishbone_bus_socket_wb_addr_map_0_grant_addr >= ram_BASE_ADDR)   & (wishbone_bus_socket_wb_addr_map_0_grant_addr< ram_END_ADDR));
 /* gpo wb_slave 0 */
 	assign wishbone_bus_socket_wb_addr_map_0_sel_one_hot[1]= ((wishbone_bus_socket_wb_addr_map_0_grant_addr >= gpo_BASE_ADDR)   & (wishbone_bus_socket_wb_addr_map_0_grant_addr< gpo_END_ADDR));
 /* int_ctrl wb_slave 0 */
 	assign wishbone_bus_socket_wb_addr_map_0_sel_one_hot[2]= ((wishbone_bus_socket_wb_addr_map_0_grant_addr >= int_ctrl_BASE_ADDR)   & (wishbone_bus_socket_wb_addr_map_0_grant_addr< int_ctrl_END_ADDR));
 /* ni0 wb_slave 0 */
 	assign wishbone_bus_socket_wb_addr_map_0_sel_one_hot[3]= ((wishbone_bus_socket_wb_addr_map_0_grant_addr >= ni0_BASE_ADDR)   & (wishbone_bus_socket_wb_addr_map_0_grant_addr< ni0_END_ADDR));
 /* timer wb_slave 0 */
 	assign wishbone_bus_socket_wb_addr_map_0_sel_one_hot[4]= ((wishbone_bus_socket_wb_addr_map_0_grant_addr >= timer_BASE_ADDR)   & (wishbone_bus_socket_wb_addr_map_0_grant_addr< timer_END_ADDR));
 endmodule

