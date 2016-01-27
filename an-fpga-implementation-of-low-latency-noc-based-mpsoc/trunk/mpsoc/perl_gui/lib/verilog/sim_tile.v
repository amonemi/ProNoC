module sim_tile #(
 	parameter	CORE_ID=0 ,
	parameter	ram_Dw=32 ,
	parameter	ram_Aw=10 ,
	parameter	aeMB_AEMB_MUL= 1 ,
	parameter	aeMB_AEMB_BSF= 1 ,
	parameter	Led_PORT_WIDTH=   1 ,
	parameter	ni_NY= 2 ,
	parameter	ni_NX= 2 ,
	parameter	ni_V= 4 ,
	parameter	ni_B= 4 ,
	parameter	ni_DEBUG_EN=   1 ,
	parameter	ni_ROUTE_NAME="XY"      ,
	parameter	ni_TOPOLOGY=    "MESH"
)(
	aeMB_sys_ena_i, 
	uart_dataavailable, 
	uart_readyfordata, 
	ss_clk_in, 
	ss_reset_in, 
	Led_port_o, 
	ni_credit_in, 
	ni_credit_out, 
	ni_current_x, 
	ni_current_y, 
	ni_flit_in, 
	ni_flit_in_wr, 
	ni_flit_out, 
	ni_flit_out_wr
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
  	localparam	ram_TAGw=3;
	localparam	ram_SELw=4;
	localparam	ram_RAM_TAG_STRING=i2s(CORE_ID);
	localparam	ram_WB_Aw=ram_Aw+2;

 	localparam	aeMB_AEMB_XWB= 7;
	localparam	aeMB_AEMB_IDX= 6;
	localparam	aeMB_AEMB_IWB= 32;
	localparam	aeMB_AEMB_ICH= 11;
	localparam	aeMB_AEMB_DWB= 32;

 
 
 	localparam	Led_Dw=    32;
	localparam	Led_Aw=    2;
	localparam	Led_TAGw=    3;
	localparam	Led_SELw=    4;

 	localparam	int_ctrl_INT_NUM= 3;
	localparam	int_ctrl_Dw=    32;
	localparam	int_ctrl_Aw= 3;
	localparam	int_ctrl_SELw= 4    ;

 	localparam	ni_Dw=32;
	localparam	ni_TAGw=   3;
	localparam	ni_M_Aw=32;
	localparam	ni_Fpay= 32;
	localparam	ni_SELw=   4    ;
	localparam	ni_ROUTE_TYPE=   (ni_ROUTE_NAME == "XY" || ni_ROUTE_NAME == "TRANC_XY" )?    "DETERMINISTIC" : 
			            (ni_ROUTE_NAME == "DUATO" || ni_ROUTE_NAME == "TRANC_DUATO" )?   "FULL_ADAPTIVE": "PAR_ADAPTIVE" ;
	localparam	ni_P= 5;
	localparam	ni_S_Aw=   3;
	localparam	ni_Fw=2 + ni_V + ni_Fpay;
	localparam	ni_Xw=log2( ni_NX );
	localparam	ni_Yw=log2( ni_NY );

 	localparam	timer_CNTw=32     ;
	localparam	timer_Dw=	32;
	localparam	timer_Aw= 3;
	localparam	timer_TAGw=3;
	localparam	timer_SELw=	4;

 	localparam	bus_S=6;
	localparam	bus_M=3;
	localparam	bus_Aw=	32;
	localparam	bus_TAGw=	3    ;
	localparam	bus_SELw=	4;
	localparam	bus_Dw=	32;

 
//Wishbone slave base address based on instance name
 	localparam 	ram_BASE_ADDR	=	32'h00000000;
 	localparam 	ram_END_ADDR	=	32'h000003ff;
 	localparam 	uart_BASE_ADDR	=	32'h24000000;
 	localparam 	uart_END_ADDR	=	32'h24000007;
 	localparam 	Led_BASE_ADDR	=	32'h24400000;
 	localparam 	Led_END_ADDR	=	32'h24400007;
 	localparam 	int_ctrl_BASE_ADDR	=	32'h27800000;
 	localparam 	int_ctrl_END_ADDR	=	32'h27800007;
 	localparam 	ni_BASE_ADDR	=	32'h2e000000;
 	localparam 	ni_END_ADDR	=	32'h2e000007;
 	localparam 	timer_BASE_ADDR	=	32'h25800000;
 	localparam 	timer_END_ADDR	=	32'h25800007;
 
 
//Wishbone slave base address based on module name. 
 	localparam 	Altera_single_port_ram0_BASE_ADDR	=	32'h00000000;
 	localparam 	Altera_single_port_ram0_END_ADDR	=	32'h000003ff;
 	localparam 	altera_jtag_uart0_BASE_ADDR	=	32'h24000000;
 	localparam 	altera_jtag_uart0_END_ADDR	=	32'h24000007;
 	localparam 	gpo0_BASE_ADDR	=	32'h24400000;
 	localparam 	gpo0_END_ADDR	=	32'h24400007;
 	localparam 	int_ctrl0_BASE_ADDR	=	32'h27800000;
 	localparam 	int_ctrl0_END_ADDR	=	32'h27800007;
 	localparam 	ni0_BASE_ADDR	=	32'h2e000000;
 	localparam 	ni0_END_ADDR	=	32'h2e000007;
 	localparam 	timer0_BASE_ADDR	=	32'h25800000;
 	localparam 	timer0_END_ADDR	=	32'h25800007;
 
 	input			aeMB_sys_ena_i;

 	output			uart_dataavailable;
 	output			uart_readyfordata;

 	input			ss_clk_in;
 	input			ss_reset_in;

 	output	 [ Led_PORT_WIDTH-1     :   0    ] Led_port_o;

 	input	 [ ni_V-1    :   0    ] ni_credit_in;
 	output	 [ ni_V-1:   0    ] ni_credit_out;
 	input	 [ ni_Xw-1   :   0    ] ni_current_x;
 	input	 [ ni_Yw-1   :   0    ] ni_current_y;
 	input	 [ ni_Fw-1   :   0    ] ni_flit_in;
 	input			ni_flit_in_wr;
 	output	 [ ni_Fw-1   :   0    ] ni_flit_out;
 	output			ni_flit_out_wr;

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

 	wire			 uart_plug_wb_slave_0_ack_o;
 	wire			 uart_plug_wb_slave_0_adr_i;
 	wire			 uart_plug_clk_0_clk_i;
 	wire			 uart_plug_wb_slave_0_cyc_i;
 	wire	[  31: 0 ] uart_plug_wb_slave_0_dat_i;
 	wire	[  31: 0 ] uart_plug_wb_slave_0_dat_o;
 	wire			 uart_plug_reset_0_reset_i;
 	wire			 uart_plug_wb_slave_0_stb_i;
 	wire			 uart_plug_interrupt_peripheral_0_int_o;
 	wire			 uart_plug_wb_slave_0_we_i;

 	wire			 ss_socket_clk_0_clk_o;
 	wire			 ss_socket_reset_0_reset_o;

 	wire			 Led_plug_clk_0_clk_i;
 	wire			 Led_plug_reset_0_reset_i;
 	wire			 Led_plug_wb_slave_0_ack_o;
 	wire	[ Led_Aw-1       :   0 ] Led_plug_wb_slave_0_adr_i;
 	wire			 Led_plug_wb_slave_0_cyc_i;
 	wire	[ Led_Dw-1       :   0 ] Led_plug_wb_slave_0_dat_i;
 	wire	[ Led_Dw-1       :   0 ] Led_plug_wb_slave_0_dat_o;
 	wire			 Led_plug_wb_slave_0_err_o;
 	wire			 Led_plug_wb_slave_0_rty_o;
 	wire	[ Led_SELw-1     :   0 ] Led_plug_wb_slave_0_sel_i;
 	wire			 Led_plug_wb_slave_0_stb_i;
 	wire	[ Led_TAGw-1     :   0 ] Led_plug_wb_slave_0_tag_i;
 	wire			 Led_plug_wb_slave_0_we_i;

 	wire			 int_ctrl_plug_clk_0_clk_i;
 	wire	[ int_ctrl_INT_NUM-1  :   0 ] int_ctrl_socket_interrupt_peripheral_array_int_i;
 	wire			 int_ctrl_socket_interrupt_peripheral_2_int_i;
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

 	wire			 ni_plug_clk_0_clk_i;
 	wire			 ni_plug_interrupt_peripheral_0_int_o;
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
 	wire			 bus_socket_wb_slave_5_ack_i;
 	wire			 bus_socket_wb_slave_4_ack_i;
 	wire			 bus_socket_wb_slave_3_ack_i;
 	wire			 bus_socket_wb_slave_2_ack_i;
 	wire			 bus_socket_wb_slave_1_ack_i;
 	wire			 bus_socket_wb_slave_0_ack_i;
 	wire	[ (bus_Aw*bus_S)-1      :   0 ] bus_socket_wb_slave_array_adr_o;
 	wire	[ bus_Aw-1      :   0 ] bus_socket_wb_slave_5_adr_o;
 	wire	[ bus_Aw-1      :   0 ] bus_socket_wb_slave_4_adr_o;
 	wire	[ bus_Aw-1      :   0 ] bus_socket_wb_slave_3_adr_o;
 	wire	[ bus_Aw-1      :   0 ] bus_socket_wb_slave_2_adr_o;
 	wire	[ bus_Aw-1      :   0 ] bus_socket_wb_slave_1_adr_o;
 	wire	[ bus_Aw-1      :   0 ] bus_socket_wb_slave_0_adr_o;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_slave_array_cyc_o;
 	wire			 bus_socket_wb_slave_5_cyc_o;
 	wire			 bus_socket_wb_slave_4_cyc_o;
 	wire			 bus_socket_wb_slave_3_cyc_o;
 	wire			 bus_socket_wb_slave_2_cyc_o;
 	wire			 bus_socket_wb_slave_1_cyc_o;
 	wire			 bus_socket_wb_slave_0_cyc_o;
 	wire	[ (bus_Dw*bus_S)-1      :   0 ] bus_socket_wb_slave_array_dat_i;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_5_dat_i;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_4_dat_i;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_3_dat_i;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_2_dat_i;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_1_dat_i;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_0_dat_i;
 	wire	[ (bus_Dw*bus_S)-1      :   0 ] bus_socket_wb_slave_array_dat_o;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_5_dat_o;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_4_dat_o;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_3_dat_o;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_2_dat_o;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_1_dat_o;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_0_dat_o;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_slave_array_err_i;
 	wire			 bus_socket_wb_slave_5_err_i;
 	wire			 bus_socket_wb_slave_4_err_i;
 	wire			 bus_socket_wb_slave_3_err_i;
 	wire			 bus_socket_wb_slave_2_err_i;
 	wire			 bus_socket_wb_slave_1_err_i;
 	wire			 bus_socket_wb_slave_0_err_i;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_slave_array_rty_i;
 	wire			 bus_socket_wb_slave_5_rty_i;
 	wire			 bus_socket_wb_slave_4_rty_i;
 	wire			 bus_socket_wb_slave_3_rty_i;
 	wire			 bus_socket_wb_slave_2_rty_i;
 	wire			 bus_socket_wb_slave_1_rty_i;
 	wire			 bus_socket_wb_slave_0_rty_i;
 	wire	[ (bus_SELw*bus_S)-1    :   0 ] bus_socket_wb_slave_array_sel_o;
 	wire	[ bus_SELw-1    :   0 ] bus_socket_wb_slave_5_sel_o;
 	wire	[ bus_SELw-1    :   0 ] bus_socket_wb_slave_4_sel_o;
 	wire	[ bus_SELw-1    :   0 ] bus_socket_wb_slave_3_sel_o;
 	wire	[ bus_SELw-1    :   0 ] bus_socket_wb_slave_2_sel_o;
 	wire	[ bus_SELw-1    :   0 ] bus_socket_wb_slave_1_sel_o;
 	wire	[ bus_SELw-1    :   0 ] bus_socket_wb_slave_0_sel_o;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_addr_map_0_sel_one_hot;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_slave_array_stb_o;
 	wire			 bus_socket_wb_slave_5_stb_o;
 	wire			 bus_socket_wb_slave_4_stb_o;
 	wire			 bus_socket_wb_slave_3_stb_o;
 	wire			 bus_socket_wb_slave_2_stb_o;
 	wire			 bus_socket_wb_slave_1_stb_o;
 	wire			 bus_socket_wb_slave_0_stb_o;
 	wire	[ (bus_TAGw*bus_S)-1    :   0 ] bus_socket_wb_slave_array_tag_o;
 	wire	[ bus_TAGw-1    :   0 ] bus_socket_wb_slave_5_tag_o;
 	wire	[ bus_TAGw-1    :   0 ] bus_socket_wb_slave_4_tag_o;
 	wire	[ bus_TAGw-1    :   0 ] bus_socket_wb_slave_3_tag_o;
 	wire	[ bus_TAGw-1    :   0 ] bus_socket_wb_slave_2_tag_o;
 	wire	[ bus_TAGw-1    :   0 ] bus_socket_wb_slave_1_tag_o;
 	wire	[ bus_TAGw-1    :   0 ] bus_socket_wb_slave_0_tag_o;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_slave_array_we_o;
 	wire			 bus_socket_wb_slave_5_we_o;
 	wire			 bus_socket_wb_slave_4_we_o;
 	wire			 bus_socket_wb_slave_3_we_o;
 	wire			 bus_socket_wb_slave_2_we_o;
 	wire			 bus_socket_wb_slave_1_we_o;
 	wire			 bus_socket_wb_slave_0_we_o;

 Altera_single_port_ram #(
 		.Dw(ram_Dw),
		.Aw(ram_Aw),
		.TAGw(ram_TAGw),
		.SELw(ram_SELw),
		.RAM_TAG_STRING(ram_RAM_TAG_STRING)
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
 		.AEMB_XWB(aeMB_AEMB_XWB),
		.AEMB_IDX(aeMB_AEMB_IDX),
		.AEMB_MUL(aeMB_AEMB_MUL),
		.AEMB_IWB(aeMB_AEMB_IWB),
		.AEMB_BSF(aeMB_AEMB_BSF),
		.AEMB_ICH(aeMB_AEMB_ICH),
		.AEMB_DWB(aeMB_AEMB_DWB)
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
 altera_jtag_uart_wb  uart 	(
		.ack_o(uart_plug_wb_slave_0_ack_o),
		.adr_i(uart_plug_wb_slave_0_adr_i),
		.clk(uart_plug_clk_0_clk_i),
		.cyc_i(uart_plug_wb_slave_0_cyc_i),
		.dat_i(uart_plug_wb_slave_0_dat_i),
		.dat_o(uart_plug_wb_slave_0_dat_o),
		.dataavailable(uart_dataavailable),
		.readyfordata(uart_readyfordata),
		.rst(uart_plug_reset_0_reset_i),
		.stb_i(uart_plug_wb_slave_0_stb_i),
		.wb_irq(uart_plug_interrupt_peripheral_0_int_o),
		.we_i(uart_plug_wb_slave_0_we_i)
	);
 clk_source  ss 	(
		.clk_in(ss_clk_in),
		.clk_out(ss_socket_clk_0_clk_o),
		.reset_in(ss_reset_in),
		.reset_out(ss_socket_reset_0_reset_o)
	);
 gpo #(
 		.PORT_WIDTH(Led_PORT_WIDTH),
		.Dw(Led_Dw),
		.Aw(Led_Aw),
		.TAGw(Led_TAGw),
		.SELw(Led_SELw)
	)  Led 	(
		.clk(Led_plug_clk_0_clk_i),
		.port_o(Led_port_o),
		.reset(Led_plug_reset_0_reset_i),
		.sa_ack_o(Led_plug_wb_slave_0_ack_o),
		.sa_addr_i(Led_plug_wb_slave_0_adr_i),
		.sa_cyc_i(Led_plug_wb_slave_0_cyc_i),
		.sa_dat_i(Led_plug_wb_slave_0_dat_i),
		.sa_dat_o(Led_plug_wb_slave_0_dat_o),
		.sa_err_o(Led_plug_wb_slave_0_err_o),
		.sa_rty_o(Led_plug_wb_slave_0_rty_o),
		.sa_sel_i(Led_plug_wb_slave_0_sel_i),
		.sa_stb_i(Led_plug_wb_slave_0_stb_i),
		.sa_tag_i(Led_plug_wb_slave_0_tag_i),
		.sa_we_i(Led_plug_wb_slave_0_we_i)
	);
 int_ctrl #(
 		.INT_NUM(int_ctrl_INT_NUM),
		.Dw(int_ctrl_Dw),
		.Aw(int_ctrl_Aw),
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
 		.NY(ni_NY),
		.NX(ni_NX),
		.V(ni_V),
		.B(ni_B),
		.Dw(ni_Dw),
		.DEBUG_EN(ni_DEBUG_EN),
		.TAGw(ni_TAGw),
		.M_Aw(ni_M_Aw),
		.ROUTE_NAME(ni_ROUTE_NAME),
		.Fpay(ni_Fpay),
		.SELw(ni_SELw),
		.ROUTE_TYPE(ni_ROUTE_TYPE),
		.P(ni_P),
		.S_Aw(ni_S_Aw),
		.TOPOLOGY(ni_TOPOLOGY)
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
		.irq(ni_plug_interrupt_peripheral_0_int_o),
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
 timer #(
 		.CNTw(timer_CNTw),
		.Dw(timer_Dw),
		.Aw(timer_Aw),
		.TAGw(timer_TAGw),
		.SELw(timer_SELw)
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
 
 	assign  ram_plug_clk_0_clk_i = ss_socket_clk_0_clk_o;
 	assign  ram_plug_reset_0_reset_i = ss_socket_reset_0_reset_o;
 	assign  bus_socket_wb_slave_3_ack_i  = ram_plug_wb_slave_0_ack_o;
 	assign  ram_plug_wb_slave_0_adr_i = bus_socket_wb_slave_3_adr_o[ram_Aw-1       :   0];
 	assign  ram_plug_wb_slave_0_cyc_i = bus_socket_wb_slave_3_cyc_o;
 	assign  ram_plug_wb_slave_0_dat_i = bus_socket_wb_slave_3_dat_o[ram_Dw-1       :   0];
 	assign  bus_socket_wb_slave_3_dat_i  = ram_plug_wb_slave_0_dat_o;
 	assign  bus_socket_wb_slave_3_err_i  = ram_plug_wb_slave_0_err_o;
 	assign  bus_socket_wb_slave_3_rty_i  = ram_plug_wb_slave_0_rty_o;
 	assign  ram_plug_wb_slave_0_sel_i = bus_socket_wb_slave_3_sel_o[ram_SELw-1     :   0];
 	assign  ram_plug_wb_slave_0_stb_i = bus_socket_wb_slave_3_stb_o;
 	assign  ram_plug_wb_slave_0_tag_i = bus_socket_wb_slave_3_tag_o[ram_TAGw-1     :   0];
 	assign  ram_plug_wb_slave_0_we_i = bus_socket_wb_slave_3_we_o;

 
 	assign  aeMB_plug_clk_0_clk_i = ss_socket_clk_0_clk_o;
 	assign  aeMB_plug_wb_master_1_ack_i = bus_socket_wb_master_2_ack_o;
 	assign  bus_socket_wb_master_2_adr_i  = aeMB_plug_wb_master_1_adr_o;
 	assign  bus_socket_wb_master_2_cyc_i  = aeMB_plug_wb_master_1_cyc_o;
 	assign  aeMB_plug_wb_master_1_dat_i = bus_socket_wb_master_2_dat_o[31:0];
 	assign  bus_socket_wb_master_2_dat_i  = aeMB_plug_wb_master_1_dat_o;
 	assign  aeMB_plug_wb_master_1_err_i = bus_socket_wb_master_2_err_o;
 	assign  aeMB_plug_wb_master_1_rty_i = bus_socket_wb_master_2_rty_o;
 	assign  bus_socket_wb_master_2_sel_i  = aeMB_plug_wb_master_1_sel_o;
 	assign  bus_socket_wb_master_2_stb_i  = aeMB_plug_wb_master_1_stb_o;
 	assign  bus_socket_wb_master_2_tag_i  = aeMB_plug_wb_master_1_tag_o;
 	assign  bus_socket_wb_master_2_we_i  = aeMB_plug_wb_master_1_we_o;
 	assign  aeMB_plug_wb_master_0_ack_i = bus_socket_wb_master_1_ack_o;
 	assign  bus_socket_wb_master_1_adr_i  = aeMB_plug_wb_master_0_adr_o;
 	assign  bus_socket_wb_master_1_cyc_i  = aeMB_plug_wb_master_0_cyc_o;
 	assign  aeMB_plug_wb_master_0_dat_i = bus_socket_wb_master_1_dat_o[31:0];
 	assign  bus_socket_wb_master_1_dat_i  = aeMB_plug_wb_master_0_dat_o;
 	assign  aeMB_plug_wb_master_0_err_i = bus_socket_wb_master_1_err_o;
 	assign  aeMB_plug_wb_master_0_rty_i = bus_socket_wb_master_1_rty_o;
 	assign  bus_socket_wb_master_1_sel_i  = aeMB_plug_wb_master_0_sel_o;
 	assign  bus_socket_wb_master_1_stb_i  = aeMB_plug_wb_master_0_stb_o;
 	assign  bus_socket_wb_master_1_tag_i  = aeMB_plug_wb_master_0_tag_o;
 	assign  bus_socket_wb_master_1_we_i  = aeMB_plug_wb_master_0_we_o;
 	assign  aeMB_plug_reset_0_reset_i = ss_socket_reset_0_reset_o;
 	assign  aeMB_plug_interrupt_cpu_0_int_i = int_ctrl_socket_interrupt_cpu_0_int_o;

 
 	assign  bus_socket_wb_slave_1_ack_i  = uart_plug_wb_slave_0_ack_o;
 	assign  uart_plug_wb_slave_0_adr_i = bus_socket_wb_slave_1_adr_o;
 	assign  uart_plug_clk_0_clk_i = ss_socket_clk_0_clk_o;
 	assign  uart_plug_wb_slave_0_cyc_i = bus_socket_wb_slave_1_cyc_o;
 	assign  uart_plug_wb_slave_0_dat_i = bus_socket_wb_slave_1_dat_o[ 31: 0];
 	assign  bus_socket_wb_slave_1_dat_i  = uart_plug_wb_slave_0_dat_o;
 	assign  uart_plug_reset_0_reset_i = ss_socket_reset_0_reset_o;
 	assign  uart_plug_wb_slave_0_stb_i = bus_socket_wb_slave_1_stb_o;
 	assign  int_ctrl_socket_interrupt_peripheral_0_int_i  = uart_plug_interrupt_peripheral_0_int_o;
 	assign  uart_plug_wb_slave_0_we_i = bus_socket_wb_slave_1_we_o;

 

 
 	assign  Led_plug_clk_0_clk_i = ss_socket_clk_0_clk_o;
 	assign  Led_plug_reset_0_reset_i = ss_socket_reset_0_reset_o;
 	assign  bus_socket_wb_slave_0_ack_i  = Led_plug_wb_slave_0_ack_o;
 	assign  Led_plug_wb_slave_0_adr_i = bus_socket_wb_slave_0_adr_o[Led_Aw-1       :   0];
 	assign  Led_plug_wb_slave_0_cyc_i = bus_socket_wb_slave_0_cyc_o;
 	assign  Led_plug_wb_slave_0_dat_i = bus_socket_wb_slave_0_dat_o[Led_Dw-1       :   0];
 	assign  bus_socket_wb_slave_0_dat_i  = Led_plug_wb_slave_0_dat_o;
 	assign  bus_socket_wb_slave_0_err_i  = Led_plug_wb_slave_0_err_o;
 	assign  bus_socket_wb_slave_0_rty_i  = Led_plug_wb_slave_0_rty_o;
 	assign  Led_plug_wb_slave_0_sel_i = bus_socket_wb_slave_0_sel_o[Led_SELw-1     :   0];
 	assign  Led_plug_wb_slave_0_stb_i = bus_socket_wb_slave_0_stb_o;
 	assign  Led_plug_wb_slave_0_tag_i = bus_socket_wb_slave_0_tag_o[Led_TAGw-1     :   0];
 	assign  Led_plug_wb_slave_0_we_i = bus_socket_wb_slave_0_we_o;

 
 	assign  int_ctrl_plug_clk_0_clk_i = ss_socket_clk_0_clk_o;
 	assign  int_ctrl_plug_reset_0_reset_i = ss_socket_reset_0_reset_o;
 	assign  bus_socket_wb_slave_5_ack_i  = int_ctrl_plug_wb_slave_0_ack_o;
 	assign  int_ctrl_plug_wb_slave_0_adr_i = bus_socket_wb_slave_5_adr_o[int_ctrl_Aw-1       :   0];
 	assign  int_ctrl_plug_wb_slave_0_dat_i = bus_socket_wb_slave_5_dat_o[int_ctrl_Dw-1       :   0];
 	assign  bus_socket_wb_slave_5_dat_i  = int_ctrl_plug_wb_slave_0_dat_o;
 	assign  bus_socket_wb_slave_5_err_i  = int_ctrl_plug_wb_slave_0_err_o;
 	assign  bus_socket_wb_slave_5_rty_i  = int_ctrl_plug_wb_slave_0_rty_o;
 	assign  int_ctrl_plug_wb_slave_0_sel_i = bus_socket_wb_slave_5_sel_o[int_ctrl_SELw-1     :   0];
 	assign  int_ctrl_plug_wb_slave_0_stb_i = bus_socket_wb_slave_5_stb_o;
 	assign  int_ctrl_plug_wb_slave_0_we_i = bus_socket_wb_slave_5_we_o;

 
 	assign  ni_plug_clk_0_clk_i = ss_socket_clk_0_clk_o;
 	assign  int_ctrl_socket_interrupt_peripheral_1_int_i  = ni_plug_interrupt_peripheral_0_int_o;
 	assign  ni_plug_wb_master_0_ack_i = bus_socket_wb_master_0_ack_o;
 	assign  bus_socket_wb_master_0_adr_i  = ni_plug_wb_master_0_adr_o;
 	assign  bus_socket_wb_master_0_cyc_i  = ni_plug_wb_master_0_cyc_o;
 	assign  ni_plug_wb_master_0_dat_i = bus_socket_wb_master_0_dat_o[ni_Dw-1           :  0];
 	assign  bus_socket_wb_master_0_dat_i  = ni_plug_wb_master_0_dat_o;
 	assign  ni_plug_wb_master_0_err_i = bus_socket_wb_master_0_err_o;
 	assign  ni_plug_wb_master_0_rty_i = bus_socket_wb_master_0_rty_o;
 	assign  bus_socket_wb_master_0_sel_i  = ni_plug_wb_master_0_sel_o;
 	assign  bus_socket_wb_master_0_stb_i  = ni_plug_wb_master_0_stb_o;
 	assign  bus_socket_wb_master_0_tag_i  = ni_plug_wb_master_0_tag_o;
 	assign  bus_socket_wb_master_0_we_i  = ni_plug_wb_master_0_we_o;
 	assign  ni_plug_reset_0_reset_i = ss_socket_reset_0_reset_o;
 	assign  bus_socket_wb_slave_2_ack_i  = ni_plug_wb_slave_0_ack_o;
 	assign  ni_plug_wb_slave_0_adr_i = bus_socket_wb_slave_2_adr_o[ni_S_Aw-1     :   0];
 	assign  ni_plug_wb_slave_0_cyc_i = bus_socket_wb_slave_2_cyc_o;
 	assign  ni_plug_wb_slave_0_dat_i = bus_socket_wb_slave_2_dat_o[ni_Dw-1       :   0];
 	assign  bus_socket_wb_slave_2_dat_i  = ni_plug_wb_slave_0_dat_o;
 	assign  bus_socket_wb_slave_2_err_i  = ni_plug_wb_slave_0_err_o;
 	assign  bus_socket_wb_slave_2_rty_i  = ni_plug_wb_slave_0_rty_o;
 	assign  ni_plug_wb_slave_0_sel_i = bus_socket_wb_slave_2_sel_o[ni_SELw-1     :   0];
 	assign  ni_plug_wb_slave_0_stb_i = bus_socket_wb_slave_2_stb_o;
 	assign  ni_plug_wb_slave_0_tag_i = bus_socket_wb_slave_2_tag_o[ni_TAGw-1     :   0];
 	assign  ni_plug_wb_slave_0_we_i = bus_socket_wb_slave_2_we_o;

 
 	assign  timer_plug_clk_0_clk_i = ss_socket_clk_0_clk_o;
 	assign  int_ctrl_socket_interrupt_peripheral_2_int_i  = timer_plug_interrupt_peripheral_0_int_o;
 	assign  timer_plug_reset_0_reset_i = ss_socket_reset_0_reset_o;
 	assign  bus_socket_wb_slave_4_ack_i  = timer_plug_wb_slave_0_ack_o;
 	assign  timer_plug_wb_slave_0_adr_i = bus_socket_wb_slave_4_adr_o[timer_Aw-1       :   0];
 	assign  timer_plug_wb_slave_0_cyc_i = bus_socket_wb_slave_4_cyc_o;
 	assign  timer_plug_wb_slave_0_dat_i = bus_socket_wb_slave_4_dat_o[timer_Dw-1       :   0];
 	assign  bus_socket_wb_slave_4_dat_i  = timer_plug_wb_slave_0_dat_o;
 	assign  bus_socket_wb_slave_4_err_i  = timer_plug_wb_slave_0_err_o;
 	assign  bus_socket_wb_slave_4_rty_i  = timer_plug_wb_slave_0_rty_o;
 	assign  timer_plug_wb_slave_0_sel_i = bus_socket_wb_slave_4_sel_o[timer_SELw-1     :   0];
 	assign  timer_plug_wb_slave_0_stb_i = bus_socket_wb_slave_4_stb_o;
 	assign  timer_plug_wb_slave_0_tag_i = bus_socket_wb_slave_4_tag_o[timer_TAGw-1     :   0];
 	assign  timer_plug_wb_slave_0_we_i = bus_socket_wb_slave_4_we_o;

 
 	assign  bus_plug_clk_0_clk_i = ss_socket_clk_0_clk_o;
 	assign  bus_plug_reset_0_reset_i = ss_socket_reset_0_reset_o;

 	assign int_ctrl_socket_interrupt_peripheral_array_int_i ={int_ctrl_socket_interrupt_peripheral_2_int_i ,int_ctrl_socket_interrupt_peripheral_1_int_i ,int_ctrl_socket_interrupt_peripheral_0_int_i};

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
 	assign bus_socket_wb_slave_array_ack_i ={bus_socket_wb_slave_5_ack_i ,bus_socket_wb_slave_4_ack_i ,bus_socket_wb_slave_3_ack_i ,bus_socket_wb_slave_2_ack_i ,bus_socket_wb_slave_1_ack_i ,bus_socket_wb_slave_0_ack_i};
 	assign {bus_socket_wb_slave_5_adr_o ,bus_socket_wb_slave_4_adr_o ,bus_socket_wb_slave_3_adr_o ,bus_socket_wb_slave_2_adr_o ,bus_socket_wb_slave_1_adr_o ,bus_socket_wb_slave_0_adr_o} =bus_socket_wb_slave_array_adr_o;
 	assign {bus_socket_wb_slave_5_cyc_o ,bus_socket_wb_slave_4_cyc_o ,bus_socket_wb_slave_3_cyc_o ,bus_socket_wb_slave_2_cyc_o ,bus_socket_wb_slave_1_cyc_o ,bus_socket_wb_slave_0_cyc_o} =bus_socket_wb_slave_array_cyc_o;
 	assign bus_socket_wb_slave_array_dat_i ={bus_socket_wb_slave_5_dat_i ,bus_socket_wb_slave_4_dat_i ,bus_socket_wb_slave_3_dat_i ,bus_socket_wb_slave_2_dat_i ,bus_socket_wb_slave_1_dat_i ,bus_socket_wb_slave_0_dat_i};
 	assign {bus_socket_wb_slave_5_dat_o ,bus_socket_wb_slave_4_dat_o ,bus_socket_wb_slave_3_dat_o ,bus_socket_wb_slave_2_dat_o ,bus_socket_wb_slave_1_dat_o ,bus_socket_wb_slave_0_dat_o} =bus_socket_wb_slave_array_dat_o;
 	assign bus_socket_wb_slave_array_err_i ={bus_socket_wb_slave_5_err_i ,bus_socket_wb_slave_4_err_i ,bus_socket_wb_slave_3_err_i ,bus_socket_wb_slave_2_err_i ,bus_socket_wb_slave_1_err_i ,bus_socket_wb_slave_0_err_i};
 	assign bus_socket_wb_slave_array_rty_i ={bus_socket_wb_slave_5_rty_i ,bus_socket_wb_slave_4_rty_i ,bus_socket_wb_slave_3_rty_i ,bus_socket_wb_slave_2_rty_i ,bus_socket_wb_slave_1_rty_i ,bus_socket_wb_slave_0_rty_i};
 	assign {bus_socket_wb_slave_5_sel_o ,bus_socket_wb_slave_4_sel_o ,bus_socket_wb_slave_3_sel_o ,bus_socket_wb_slave_2_sel_o ,bus_socket_wb_slave_1_sel_o ,bus_socket_wb_slave_0_sel_o} =bus_socket_wb_slave_array_sel_o;
 	assign {bus_socket_wb_slave_5_stb_o ,bus_socket_wb_slave_4_stb_o ,bus_socket_wb_slave_3_stb_o ,bus_socket_wb_slave_2_stb_o ,bus_socket_wb_slave_1_stb_o ,bus_socket_wb_slave_0_stb_o} =bus_socket_wb_slave_array_stb_o;
 	assign {bus_socket_wb_slave_5_tag_o ,bus_socket_wb_slave_4_tag_o ,bus_socket_wb_slave_3_tag_o ,bus_socket_wb_slave_2_tag_o ,bus_socket_wb_slave_1_tag_o ,bus_socket_wb_slave_0_tag_o} =bus_socket_wb_slave_array_tag_o;
 	assign {bus_socket_wb_slave_5_we_o ,bus_socket_wb_slave_4_we_o ,bus_socket_wb_slave_3_we_o ,bus_socket_wb_slave_2_we_o ,bus_socket_wb_slave_1_we_o ,bus_socket_wb_slave_0_we_o} =bus_socket_wb_slave_array_we_o;

 
//Wishbone slave address match
 /* ram wb_slave 0 */
 	assign bus_socket_wb_addr_map_0_sel_one_hot[3]= ((bus_socket_wb_addr_map_0_grant_addr >= ram_BASE_ADDR)   & (bus_socket_wb_addr_map_0_grant_addr< ram_END_ADDR));
 /* uart wb_slave 0 */
 	assign bus_socket_wb_addr_map_0_sel_one_hot[1]= ((bus_socket_wb_addr_map_0_grant_addr >= uart_BASE_ADDR)   & (bus_socket_wb_addr_map_0_grant_addr< uart_END_ADDR));
 /* Led wb_slave 0 */
 	assign bus_socket_wb_addr_map_0_sel_one_hot[0]= ((bus_socket_wb_addr_map_0_grant_addr >= Led_BASE_ADDR)   & (bus_socket_wb_addr_map_0_grant_addr< Led_END_ADDR));
 /* int_ctrl wb_slave 0 */
 	assign bus_socket_wb_addr_map_0_sel_one_hot[5]= ((bus_socket_wb_addr_map_0_grant_addr >= int_ctrl_BASE_ADDR)   & (bus_socket_wb_addr_map_0_grant_addr< int_ctrl_END_ADDR));
 /* ni wb_slave 0 */
 	assign bus_socket_wb_addr_map_0_sel_one_hot[2]= ((bus_socket_wb_addr_map_0_grant_addr >= ni_BASE_ADDR)   & (bus_socket_wb_addr_map_0_grant_addr< ni_END_ADDR));
 /* timer wb_slave 0 */
 	assign bus_socket_wb_addr_map_0_sel_one_hot[4]= ((bus_socket_wb_addr_map_0_grant_addr >= timer_BASE_ADDR)   & (bus_socket_wb_addr_map_0_grant_addr< timer_END_ADDR));
 endmodule

