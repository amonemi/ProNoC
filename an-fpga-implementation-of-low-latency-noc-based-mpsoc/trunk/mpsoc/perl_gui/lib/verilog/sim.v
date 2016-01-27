module sim #(
 	parameter	CORE_ID=0 ,
	parameter	Altera_single_port_ram0_Dw=32 ,
	parameter	Altera_single_port_ram0_Aw=10 ,
	parameter	Altera_single_port_ram0_RAM_TAG_STRING= I2S(CORE_NUM) ,
	parameter	aeMB0_AEMB_MUL= 1 ,
	parameter	aeMB0_AEMB_BSF= 1
)(
	aeMB0_sys_ena_i, 
	aeMB0_sys_int_i, 
	clk_source0_clk_in, 
	clk_source0_reset_in, 
	timer0_irq
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
  	localparam	Altera_single_port_ram0_TAGw=3;
	localparam	Altera_single_port_ram0_SELw=4;
	localparam	Altera_single_port_ram0_WB_Aw=Altera_single_port_ram0_Aw+2;

 	localparam	aeMB0_AEMB_XWB= 7;
	localparam	aeMB0_AEMB_IDX= 6;
	localparam	aeMB0_AEMB_IWB= 32;
	localparam	aeMB0_AEMB_ICH= 11;
	localparam	aeMB0_AEMB_DWB= 32;

 
 	localparam	timer0_CNTw=32     ;
	localparam	timer0_Dw=	32;
	localparam	timer0_Aw= 3;
	localparam	timer0_TAGw=3;
	localparam	timer0_SELw=	4;

 	localparam	wishbone_bus0_S=	4;
	localparam	wishbone_bus0_M=	4;
	localparam	wishbone_bus0_Aw=	32;
	localparam	wishbone_bus0_TAGw=	3    ;
	localparam	wishbone_bus0_SELw=	4;
	localparam	wishbone_bus0_Dw=	32;

 
//Wishbone slave base address based on instance name
 	localparam 	Altera_single_port_ram0_BASE_ADDR	=	32'h00000000;
 	localparam 	Altera_single_port_ram0_END_ADDR	=	32'h000003ff;
 	localparam 	timer0_BASE_ADDR	=	32'h25800000;
 	localparam 	timer0_END_ADDR	=	32'h25800007;
 
 
//Wishbone slave base address based on module name. 
 
 	input			aeMB0_sys_ena_i;
 	input			aeMB0_sys_int_i;

 	input			clk_source0_clk_in;
 	input			clk_source0_reset_in;

 	output			timer0_irq;

 	wire			 Altera_single_port_ram0_plug_clk_0_clk_i;
 	wire			 Altera_single_port_ram0_plug_reset_0_reset_i;
 	wire			 Altera_single_port_ram0_plug_wb_slave_0_ack_o;
 	wire	[ Altera_single_port_ram0_Aw-1       :   0 ] Altera_single_port_ram0_plug_wb_slave_0_adr_i;
 	wire			 Altera_single_port_ram0_plug_wb_slave_0_cyc_i;
 	wire	[ Altera_single_port_ram0_Dw-1       :   0 ] Altera_single_port_ram0_plug_wb_slave_0_dat_i;
 	wire	[ Altera_single_port_ram0_Dw-1       :   0 ] Altera_single_port_ram0_plug_wb_slave_0_dat_o;
 	wire			 Altera_single_port_ram0_plug_wb_slave_0_err_o;
 	wire			 Altera_single_port_ram0_plug_wb_slave_0_rty_o;
 	wire	[ Altera_single_port_ram0_SELw-1     :   0 ] Altera_single_port_ram0_plug_wb_slave_0_sel_i;
 	wire			 Altera_single_port_ram0_plug_wb_slave_0_stb_i;
 	wire	[ Altera_single_port_ram0_TAGw-1     :   0 ] Altera_single_port_ram0_plug_wb_slave_0_tag_i;
 	wire			 Altera_single_port_ram0_plug_wb_slave_0_we_i;

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

 	wire			 clk_source0_socket_clk_0_clk_o;
 	wire			 clk_source0_socket_reset_0_reset_o;

 	wire			 timer0_plug_clk_0_clk_i;
 	wire			 timer0_plug_reset_0_reset_i;
 	wire			 timer0_plug_wb_slave_0_ack_o;
 	wire	[ timer0_Aw-1       :   0 ] timer0_plug_wb_slave_0_adr_i;
 	wire			 timer0_plug_wb_slave_0_cyc_i;
 	wire	[ timer0_Dw-1       :   0 ] timer0_plug_wb_slave_0_dat_i;
 	wire	[ timer0_Dw-1       :   0 ] timer0_plug_wb_slave_0_dat_o;
 	wire			 timer0_plug_wb_slave_0_err_o;
 	wire			 timer0_plug_wb_slave_0_rty_o;
 	wire	[ timer0_SELw-1     :   0 ] timer0_plug_wb_slave_0_sel_i;
 	wire			 timer0_plug_wb_slave_0_stb_i;
 	wire	[ timer0_TAGw-1     :   0 ] timer0_plug_wb_slave_0_tag_i;
 	wire			 timer0_plug_wb_slave_0_we_i;

 	wire			 wishbone_bus0_plug_clk_0_clk_i;
 	wire	[ wishbone_bus0_M-1        :   0 ] wishbone_bus0_socket_wb_master_array_ack_o;
 	wire			 wishbone_bus0_socket_wb_master_3_ack_o;
 	wire			 wishbone_bus0_socket_wb_master_2_ack_o;
 	wire			 wishbone_bus0_socket_wb_master_1_ack_o;
 	wire			 wishbone_bus0_socket_wb_master_0_ack_o;
 	wire	[ (wishbone_bus0_Aw*wishbone_bus0_M)-1      :   0 ] wishbone_bus0_socket_wb_master_array_adr_i;
 	wire	[ wishbone_bus0_Aw-1      :   0 ] wishbone_bus0_socket_wb_master_3_adr_i;
 	wire	[ wishbone_bus0_Aw-1      :   0 ] wishbone_bus0_socket_wb_master_2_adr_i;
 	wire	[ wishbone_bus0_Aw-1      :   0 ] wishbone_bus0_socket_wb_master_1_adr_i;
 	wire	[ wishbone_bus0_Aw-1      :   0 ] wishbone_bus0_socket_wb_master_0_adr_i;
 	wire	[ wishbone_bus0_M-1        :   0 ] wishbone_bus0_socket_wb_master_array_cyc_i;
 	wire			 wishbone_bus0_socket_wb_master_3_cyc_i;
 	wire			 wishbone_bus0_socket_wb_master_2_cyc_i;
 	wire			 wishbone_bus0_socket_wb_master_1_cyc_i;
 	wire			 wishbone_bus0_socket_wb_master_0_cyc_i;
 	wire	[ (wishbone_bus0_Dw*wishbone_bus0_M)-1      :   0 ] wishbone_bus0_socket_wb_master_array_dat_i;
 	wire	[ wishbone_bus0_Dw-1      :   0 ] wishbone_bus0_socket_wb_master_3_dat_i;
 	wire	[ wishbone_bus0_Dw-1      :   0 ] wishbone_bus0_socket_wb_master_2_dat_i;
 	wire	[ wishbone_bus0_Dw-1      :   0 ] wishbone_bus0_socket_wb_master_1_dat_i;
 	wire	[ wishbone_bus0_Dw-1      :   0 ] wishbone_bus0_socket_wb_master_0_dat_i;
 	wire	[ (wishbone_bus0_Dw*wishbone_bus0_M)-1      :   0 ] wishbone_bus0_socket_wb_master_array_dat_o;
 	wire	[ wishbone_bus0_Dw-1      :   0 ] wishbone_bus0_socket_wb_master_3_dat_o;
 	wire	[ wishbone_bus0_Dw-1      :   0 ] wishbone_bus0_socket_wb_master_2_dat_o;
 	wire	[ wishbone_bus0_Dw-1      :   0 ] wishbone_bus0_socket_wb_master_1_dat_o;
 	wire	[ wishbone_bus0_Dw-1      :   0 ] wishbone_bus0_socket_wb_master_0_dat_o;
 	wire	[ wishbone_bus0_M-1        :   0 ] wishbone_bus0_socket_wb_master_array_err_o;
 	wire			 wishbone_bus0_socket_wb_master_3_err_o;
 	wire			 wishbone_bus0_socket_wb_master_2_err_o;
 	wire			 wishbone_bus0_socket_wb_master_1_err_o;
 	wire			 wishbone_bus0_socket_wb_master_0_err_o;
 	wire	[ wishbone_bus0_Aw-1       :   0 ] wishbone_bus0_socket_wb_addr_map_0_grant_addr;
 	wire	[ wishbone_bus0_M-1        :   0 ] wishbone_bus0_socket_wb_master_array_rty_o;
 	wire			 wishbone_bus0_socket_wb_master_3_rty_o;
 	wire			 wishbone_bus0_socket_wb_master_2_rty_o;
 	wire			 wishbone_bus0_socket_wb_master_1_rty_o;
 	wire			 wishbone_bus0_socket_wb_master_0_rty_o;
 	wire	[ (wishbone_bus0_SELw*wishbone_bus0_M)-1    :   0 ] wishbone_bus0_socket_wb_master_array_sel_i;
 	wire	[ wishbone_bus0_SELw-1    :   0 ] wishbone_bus0_socket_wb_master_3_sel_i;
 	wire	[ wishbone_bus0_SELw-1    :   0 ] wishbone_bus0_socket_wb_master_2_sel_i;
 	wire	[ wishbone_bus0_SELw-1    :   0 ] wishbone_bus0_socket_wb_master_1_sel_i;
 	wire	[ wishbone_bus0_SELw-1    :   0 ] wishbone_bus0_socket_wb_master_0_sel_i;
 	wire	[ wishbone_bus0_M-1        :   0 ] wishbone_bus0_socket_wb_master_array_stb_i;
 	wire			 wishbone_bus0_socket_wb_master_3_stb_i;
 	wire			 wishbone_bus0_socket_wb_master_2_stb_i;
 	wire			 wishbone_bus0_socket_wb_master_1_stb_i;
 	wire			 wishbone_bus0_socket_wb_master_0_stb_i;
 	wire	[ (wishbone_bus0_TAGw*wishbone_bus0_M)-1    :   0 ] wishbone_bus0_socket_wb_master_array_tag_i;
 	wire	[ wishbone_bus0_TAGw-1    :   0 ] wishbone_bus0_socket_wb_master_3_tag_i;
 	wire	[ wishbone_bus0_TAGw-1    :   0 ] wishbone_bus0_socket_wb_master_2_tag_i;
 	wire	[ wishbone_bus0_TAGw-1    :   0 ] wishbone_bus0_socket_wb_master_1_tag_i;
 	wire	[ wishbone_bus0_TAGw-1    :   0 ] wishbone_bus0_socket_wb_master_0_tag_i;
 	wire	[ wishbone_bus0_M-1        :   0 ] wishbone_bus0_socket_wb_master_array_we_i;
 	wire			 wishbone_bus0_socket_wb_master_3_we_i;
 	wire			 wishbone_bus0_socket_wb_master_2_we_i;
 	wire			 wishbone_bus0_socket_wb_master_1_we_i;
 	wire			 wishbone_bus0_socket_wb_master_0_we_i;
 	wire			 wishbone_bus0_plug_reset_0_reset_i;
 	wire	[ wishbone_bus0_S-1        :   0 ] wishbone_bus0_socket_wb_slave_array_ack_i;
 	wire			 wishbone_bus0_socket_wb_slave_3_ack_i;
 	wire			 wishbone_bus0_socket_wb_slave_2_ack_i;
 	wire			 wishbone_bus0_socket_wb_slave_1_ack_i;
 	wire			 wishbone_bus0_socket_wb_slave_0_ack_i;
 	wire	[ (wishbone_bus0_Aw*wishbone_bus0_S)-1      :   0 ] wishbone_bus0_socket_wb_slave_array_adr_o;
 	wire	[ wishbone_bus0_Aw-1      :   0 ] wishbone_bus0_socket_wb_slave_3_adr_o;
 	wire	[ wishbone_bus0_Aw-1      :   0 ] wishbone_bus0_socket_wb_slave_2_adr_o;
 	wire	[ wishbone_bus0_Aw-1      :   0 ] wishbone_bus0_socket_wb_slave_1_adr_o;
 	wire	[ wishbone_bus0_Aw-1      :   0 ] wishbone_bus0_socket_wb_slave_0_adr_o;
 	wire	[ wishbone_bus0_S-1        :   0 ] wishbone_bus0_socket_wb_slave_array_cyc_o;
 	wire			 wishbone_bus0_socket_wb_slave_3_cyc_o;
 	wire			 wishbone_bus0_socket_wb_slave_2_cyc_o;
 	wire			 wishbone_bus0_socket_wb_slave_1_cyc_o;
 	wire			 wishbone_bus0_socket_wb_slave_0_cyc_o;
 	wire	[ (wishbone_bus0_Dw*wishbone_bus0_S)-1      :   0 ] wishbone_bus0_socket_wb_slave_array_dat_i;
 	wire	[ wishbone_bus0_Dw-1      :   0 ] wishbone_bus0_socket_wb_slave_3_dat_i;
 	wire	[ wishbone_bus0_Dw-1      :   0 ] wishbone_bus0_socket_wb_slave_2_dat_i;
 	wire	[ wishbone_bus0_Dw-1      :   0 ] wishbone_bus0_socket_wb_slave_1_dat_i;
 	wire	[ wishbone_bus0_Dw-1      :   0 ] wishbone_bus0_socket_wb_slave_0_dat_i;
 	wire	[ (wishbone_bus0_Dw*wishbone_bus0_S)-1      :   0 ] wishbone_bus0_socket_wb_slave_array_dat_o;
 	wire	[ wishbone_bus0_Dw-1      :   0 ] wishbone_bus0_socket_wb_slave_3_dat_o;
 	wire	[ wishbone_bus0_Dw-1      :   0 ] wishbone_bus0_socket_wb_slave_2_dat_o;
 	wire	[ wishbone_bus0_Dw-1      :   0 ] wishbone_bus0_socket_wb_slave_1_dat_o;
 	wire	[ wishbone_bus0_Dw-1      :   0 ] wishbone_bus0_socket_wb_slave_0_dat_o;
 	wire	[ wishbone_bus0_S-1        :   0 ] wishbone_bus0_socket_wb_slave_array_err_i;
 	wire			 wishbone_bus0_socket_wb_slave_3_err_i;
 	wire			 wishbone_bus0_socket_wb_slave_2_err_i;
 	wire			 wishbone_bus0_socket_wb_slave_1_err_i;
 	wire			 wishbone_bus0_socket_wb_slave_0_err_i;
 	wire	[ wishbone_bus0_S-1        :   0 ] wishbone_bus0_socket_wb_slave_array_rty_i;
 	wire			 wishbone_bus0_socket_wb_slave_3_rty_i;
 	wire			 wishbone_bus0_socket_wb_slave_2_rty_i;
 	wire			 wishbone_bus0_socket_wb_slave_1_rty_i;
 	wire			 wishbone_bus0_socket_wb_slave_0_rty_i;
 	wire	[ (wishbone_bus0_SELw*wishbone_bus0_S)-1    :   0 ] wishbone_bus0_socket_wb_slave_array_sel_o;
 	wire	[ wishbone_bus0_SELw-1    :   0 ] wishbone_bus0_socket_wb_slave_3_sel_o;
 	wire	[ wishbone_bus0_SELw-1    :   0 ] wishbone_bus0_socket_wb_slave_2_sel_o;
 	wire	[ wishbone_bus0_SELw-1    :   0 ] wishbone_bus0_socket_wb_slave_1_sel_o;
 	wire	[ wishbone_bus0_SELw-1    :   0 ] wishbone_bus0_socket_wb_slave_0_sel_o;
 	wire	[ wishbone_bus0_S-1        :   0 ] wishbone_bus0_socket_wb_addr_map_0_sel_one_hot;
 	wire	[ wishbone_bus0_S-1        :   0 ] wishbone_bus0_socket_wb_slave_array_stb_o;
 	wire			 wishbone_bus0_socket_wb_slave_3_stb_o;
 	wire			 wishbone_bus0_socket_wb_slave_2_stb_o;
 	wire			 wishbone_bus0_socket_wb_slave_1_stb_o;
 	wire			 wishbone_bus0_socket_wb_slave_0_stb_o;
 	wire	[ (wishbone_bus0_TAGw*wishbone_bus0_S)-1    :   0 ] wishbone_bus0_socket_wb_slave_array_tag_o;
 	wire	[ wishbone_bus0_TAGw-1    :   0 ] wishbone_bus0_socket_wb_slave_3_tag_o;
 	wire	[ wishbone_bus0_TAGw-1    :   0 ] wishbone_bus0_socket_wb_slave_2_tag_o;
 	wire	[ wishbone_bus0_TAGw-1    :   0 ] wishbone_bus0_socket_wb_slave_1_tag_o;
 	wire	[ wishbone_bus0_TAGw-1    :   0 ] wishbone_bus0_socket_wb_slave_0_tag_o;
 	wire	[ wishbone_bus0_S-1        :   0 ] wishbone_bus0_socket_wb_slave_array_we_o;
 	wire			 wishbone_bus0_socket_wb_slave_3_we_o;
 	wire			 wishbone_bus0_socket_wb_slave_2_we_o;
 	wire			 wishbone_bus0_socket_wb_slave_1_we_o;
 	wire			 wishbone_bus0_socket_wb_slave_0_we_o;

 Altera_single_port_ram #(
 		.Dw(Altera_single_port_ram0_Dw),
		.Aw(Altera_single_port_ram0_Aw),
		.TAGw(Altera_single_port_ram0_TAGw),
		.SELw(Altera_single_port_ram0_SELw),
		.RAM_TAG_STRING(Altera_single_port_ram0_RAM_TAG_STRING)
	)  Altera_single_port_ram0 	(
		.clk(Altera_single_port_ram0_plug_clk_0_clk_i),
		.reset(Altera_single_port_ram0_plug_reset_0_reset_i),
		.sa_ack_o(Altera_single_port_ram0_plug_wb_slave_0_ack_o),
		.sa_addr_i(Altera_single_port_ram0_plug_wb_slave_0_adr_i),
		.sa_cyc_i(Altera_single_port_ram0_plug_wb_slave_0_cyc_i),
		.sa_dat_i(Altera_single_port_ram0_plug_wb_slave_0_dat_i),
		.sa_dat_o(Altera_single_port_ram0_plug_wb_slave_0_dat_o),
		.sa_err_o(Altera_single_port_ram0_plug_wb_slave_0_err_o),
		.sa_rty_o(Altera_single_port_ram0_plug_wb_slave_0_rty_o),
		.sa_sel_i(Altera_single_port_ram0_plug_wb_slave_0_sel_i),
		.sa_stb_i(Altera_single_port_ram0_plug_wb_slave_0_stb_i),
		.sa_tag_i(Altera_single_port_ram0_plug_wb_slave_0_tag_i),
		.sa_we_i(Altera_single_port_ram0_plug_wb_slave_0_we_i)
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
		.sys_int_i(aeMB0_sys_int_i)
	);
 clk_source  clk_source0 	(
		.clk_in(clk_source0_clk_in),
		.clk_out(clk_source0_socket_clk_0_clk_o),
		.reset_in(clk_source0_reset_in),
		.reset_out(clk_source0_socket_reset_0_reset_o)
	);
 timer #(
 		.CNTw(timer0_CNTw),
		.Dw(timer0_Dw),
		.Aw(timer0_Aw),
		.TAGw(timer0_TAGw),
		.SELw(timer0_SELw)
	)  timer0 	(
		.clk(timer0_plug_clk_0_clk_i),
		.irq(timer0_irq),
		.reset(timer0_plug_reset_0_reset_i),
		.sa_ack_o(timer0_plug_wb_slave_0_ack_o),
		.sa_addr_i(timer0_plug_wb_slave_0_adr_i),
		.sa_cyc_i(timer0_plug_wb_slave_0_cyc_i),
		.sa_dat_i(timer0_plug_wb_slave_0_dat_i),
		.sa_dat_o(timer0_plug_wb_slave_0_dat_o),
		.sa_err_o(timer0_plug_wb_slave_0_err_o),
		.sa_rty_o(timer0_plug_wb_slave_0_rty_o),
		.sa_sel_i(timer0_plug_wb_slave_0_sel_i),
		.sa_stb_i(timer0_plug_wb_slave_0_stb_i),
		.sa_tag_i(timer0_plug_wb_slave_0_tag_i),
		.sa_we_i(timer0_plug_wb_slave_0_we_i)
	);
 wishbone_bus #(
 		.S(wishbone_bus0_S),
		.M(wishbone_bus0_M),
		.Aw(wishbone_bus0_Aw),
		.TAGw(wishbone_bus0_TAGw),
		.SELw(wishbone_bus0_SELw),
		.Dw(wishbone_bus0_Dw)
	)  wishbone_bus0 	(
		.clk(wishbone_bus0_plug_clk_0_clk_i),
		.m_ack_o_all(wishbone_bus0_socket_wb_master_array_ack_o),
		.m_adr_i_all(wishbone_bus0_socket_wb_master_array_adr_i),
		.m_cyc_i_all(wishbone_bus0_socket_wb_master_array_cyc_i),
		.m_dat_i_all(wishbone_bus0_socket_wb_master_array_dat_i),
		.m_dat_o_all(wishbone_bus0_socket_wb_master_array_dat_o),
		.m_err_o_all(wishbone_bus0_socket_wb_master_array_err_o),
		.m_grant_addr(wishbone_bus0_socket_wb_addr_map_0_grant_addr),
		.m_rty_o_all(wishbone_bus0_socket_wb_master_array_rty_o),
		.m_sel_i_all(wishbone_bus0_socket_wb_master_array_sel_i),
		.m_stb_i_all(wishbone_bus0_socket_wb_master_array_stb_i),
		.m_tag_i_all(wishbone_bus0_socket_wb_master_array_tag_i),
		.m_we_i_all(wishbone_bus0_socket_wb_master_array_we_i),
		.reset(wishbone_bus0_plug_reset_0_reset_i),
		.s_ack_i_all(wishbone_bus0_socket_wb_slave_array_ack_i),
		.s_adr_o_all(wishbone_bus0_socket_wb_slave_array_adr_o),
		.s_cyc_o_all(wishbone_bus0_socket_wb_slave_array_cyc_o),
		.s_dat_i_all(wishbone_bus0_socket_wb_slave_array_dat_i),
		.s_dat_o_all(wishbone_bus0_socket_wb_slave_array_dat_o),
		.s_err_i_all(wishbone_bus0_socket_wb_slave_array_err_i),
		.s_rty_i_all(wishbone_bus0_socket_wb_slave_array_rty_i),
		.s_sel_o_all(wishbone_bus0_socket_wb_slave_array_sel_o),
		.s_sel_one_hot(wishbone_bus0_socket_wb_addr_map_0_sel_one_hot),
		.s_stb_o_all(wishbone_bus0_socket_wb_slave_array_stb_o),
		.s_tag_o_all(wishbone_bus0_socket_wb_slave_array_tag_o),
		.s_we_o_all(wishbone_bus0_socket_wb_slave_array_we_o)
	);
 
 	assign  Altera_single_port_ram0_plug_clk_0_clk_i = clk_source0_socket_clk_0_clk_o;
 	assign  Altera_single_port_ram0_plug_reset_0_reset_i = clk_source0_socket_reset_0_reset_o;
 	assign  wishbone_bus0_socket_wb_slave_0_ack_i  = Altera_single_port_ram0_plug_wb_slave_0_ack_o;
 	assign  Altera_single_port_ram0_plug_wb_slave_0_adr_i = wishbone_bus0_socket_wb_slave_0_adr_o;
 	assign  Altera_single_port_ram0_plug_wb_slave_0_cyc_i = wishbone_bus0_socket_wb_slave_0_cyc_o;
 	assign  Altera_single_port_ram0_plug_wb_slave_0_dat_i = wishbone_bus0_socket_wb_slave_0_dat_o;
 	assign  wishbone_bus0_socket_wb_slave_0_dat_i  = Altera_single_port_ram0_plug_wb_slave_0_dat_o;
 	assign  wishbone_bus0_socket_wb_slave_0_err_i  = Altera_single_port_ram0_plug_wb_slave_0_err_o;
 	assign  wishbone_bus0_socket_wb_slave_0_rty_i  = Altera_single_port_ram0_plug_wb_slave_0_rty_o;
 	assign  Altera_single_port_ram0_plug_wb_slave_0_sel_i = wishbone_bus0_socket_wb_slave_0_sel_o;
 	assign  Altera_single_port_ram0_plug_wb_slave_0_stb_i = wishbone_bus0_socket_wb_slave_0_stb_o;
 	assign  Altera_single_port_ram0_plug_wb_slave_0_tag_i = wishbone_bus0_socket_wb_slave_0_tag_o;
 	assign  Altera_single_port_ram0_plug_wb_slave_0_we_i = wishbone_bus0_socket_wb_slave_0_we_o;

 
 	assign  aeMB0_plug_clk_0_clk_i = clk_source0_socket_clk_0_clk_o;
 	assign  aeMB0_plug_wb_master_1_ack_i = wishbone_bus0_socket_wb_master_1_ack_o;
 	assign  wishbone_bus0_socket_wb_master_1_adr_i  = aeMB0_plug_wb_master_1_adr_o;
 	assign  wishbone_bus0_socket_wb_master_1_cyc_i  = aeMB0_plug_wb_master_1_cyc_o;
 	assign  aeMB0_plug_wb_master_1_dat_i = wishbone_bus0_socket_wb_master_1_dat_o;
 	assign  wishbone_bus0_socket_wb_master_1_dat_i  = aeMB0_plug_wb_master_1_dat_o;
 	assign  aeMB0_plug_wb_master_1_err_i = wishbone_bus0_socket_wb_master_1_err_o;
 	assign  aeMB0_plug_wb_master_1_rty_i = wishbone_bus0_socket_wb_master_1_rty_o;
 	assign  wishbone_bus0_socket_wb_master_1_sel_i  = aeMB0_plug_wb_master_1_sel_o;
 	assign  wishbone_bus0_socket_wb_master_1_stb_i  = aeMB0_plug_wb_master_1_stb_o;
 	assign  wishbone_bus0_socket_wb_master_1_tag_i  = aeMB0_plug_wb_master_1_tag_o;
 	assign  wishbone_bus0_socket_wb_master_1_we_i  = aeMB0_plug_wb_master_1_we_o;
 	assign  aeMB0_plug_wb_master_0_ack_i = wishbone_bus0_socket_wb_master_0_ack_o;
 	assign  wishbone_bus0_socket_wb_master_0_adr_i  = aeMB0_plug_wb_master_0_adr_o;
 	assign  wishbone_bus0_socket_wb_master_0_cyc_i  = aeMB0_plug_wb_master_0_cyc_o;
 	assign  aeMB0_plug_wb_master_0_dat_i = wishbone_bus0_socket_wb_master_0_dat_o;
 	assign  wishbone_bus0_socket_wb_master_0_dat_i  = aeMB0_plug_wb_master_0_dat_o;
 	assign  aeMB0_plug_wb_master_0_err_i = wishbone_bus0_socket_wb_master_0_err_o;
 	assign  aeMB0_plug_wb_master_0_rty_i = wishbone_bus0_socket_wb_master_0_rty_o;
 	assign  wishbone_bus0_socket_wb_master_0_sel_i  = aeMB0_plug_wb_master_0_sel_o;
 	assign  wishbone_bus0_socket_wb_master_0_stb_i  = aeMB0_plug_wb_master_0_stb_o;
 	assign  wishbone_bus0_socket_wb_master_0_tag_i  = aeMB0_plug_wb_master_0_tag_o;
 	assign  wishbone_bus0_socket_wb_master_0_we_i  = aeMB0_plug_wb_master_0_we_o;
 	assign  aeMB0_plug_reset_0_reset_i = clk_source0_socket_reset_0_reset_o;

 

 
 	assign  timer0_plug_clk_0_clk_i = clk_source0_socket_clk_0_clk_o;
 	assign  timer0_plug_reset_0_reset_i = clk_source0_socket_reset_0_reset_o;
 	assign  wishbone_bus0_socket_wb_slave_1_ack_i  = timer0_plug_wb_slave_0_ack_o;
 	assign  timer0_plug_wb_slave_0_adr_i = wishbone_bus0_socket_wb_slave_1_adr_o;
 	assign  timer0_plug_wb_slave_0_cyc_i = wishbone_bus0_socket_wb_slave_1_cyc_o;
 	assign  timer0_plug_wb_slave_0_dat_i = wishbone_bus0_socket_wb_slave_1_dat_o;
 	assign  wishbone_bus0_socket_wb_slave_1_dat_i  = timer0_plug_wb_slave_0_dat_o;
 	assign  wishbone_bus0_socket_wb_slave_1_err_i  = timer0_plug_wb_slave_0_err_o;
 	assign  wishbone_bus0_socket_wb_slave_1_rty_i  = timer0_plug_wb_slave_0_rty_o;
 	assign  timer0_plug_wb_slave_0_sel_i = wishbone_bus0_socket_wb_slave_1_sel_o;
 	assign  timer0_plug_wb_slave_0_stb_i = wishbone_bus0_socket_wb_slave_1_stb_o;
 	assign  timer0_plug_wb_slave_0_tag_i = wishbone_bus0_socket_wb_slave_1_tag_o;
 	assign  timer0_plug_wb_slave_0_we_i = wishbone_bus0_socket_wb_slave_1_we_o;

 
 	assign  wishbone_bus0_plug_clk_0_clk_i = clk_source0_socket_clk_0_clk_o;
 	assign  wishbone_bus0_plug_reset_0_reset_i = clk_source0_socket_reset_0_reset_o;

 	assign {wishbone_bus0_socket_wb_master_3_ack_o ,wishbone_bus0_socket_wb_master_2_ack_o ,wishbone_bus0_socket_wb_master_1_ack_o ,wishbone_bus0_socket_wb_master_0_ack_o} =wishbone_bus0_socket_wb_master_array_ack_o;
 	assign wishbone_bus0_socket_wb_master_array_adr_i ={wishbone_bus0_socket_wb_master_3_adr_i ,wishbone_bus0_socket_wb_master_2_adr_i ,wishbone_bus0_socket_wb_master_1_adr_i ,wishbone_bus0_socket_wb_master_0_adr_i};
 	assign wishbone_bus0_socket_wb_master_array_cyc_i ={wishbone_bus0_socket_wb_master_3_cyc_i ,wishbone_bus0_socket_wb_master_2_cyc_i ,wishbone_bus0_socket_wb_master_1_cyc_i ,wishbone_bus0_socket_wb_master_0_cyc_i};
 	assign wishbone_bus0_socket_wb_master_array_dat_i ={wishbone_bus0_socket_wb_master_3_dat_i ,wishbone_bus0_socket_wb_master_2_dat_i ,wishbone_bus0_socket_wb_master_1_dat_i ,wishbone_bus0_socket_wb_master_0_dat_i};
 	assign {wishbone_bus0_socket_wb_master_3_dat_o ,wishbone_bus0_socket_wb_master_2_dat_o ,wishbone_bus0_socket_wb_master_1_dat_o ,wishbone_bus0_socket_wb_master_0_dat_o} =wishbone_bus0_socket_wb_master_array_dat_o;
 	assign {wishbone_bus0_socket_wb_master_3_err_o ,wishbone_bus0_socket_wb_master_2_err_o ,wishbone_bus0_socket_wb_master_1_err_o ,wishbone_bus0_socket_wb_master_0_err_o} =wishbone_bus0_socket_wb_master_array_err_o;
 	assign {wishbone_bus0_socket_wb_master_3_rty_o ,wishbone_bus0_socket_wb_master_2_rty_o ,wishbone_bus0_socket_wb_master_1_rty_o ,wishbone_bus0_socket_wb_master_0_rty_o} =wishbone_bus0_socket_wb_master_array_rty_o;
 	assign wishbone_bus0_socket_wb_master_array_sel_i ={wishbone_bus0_socket_wb_master_3_sel_i ,wishbone_bus0_socket_wb_master_2_sel_i ,wishbone_bus0_socket_wb_master_1_sel_i ,wishbone_bus0_socket_wb_master_0_sel_i};
 	assign wishbone_bus0_socket_wb_master_array_stb_i ={wishbone_bus0_socket_wb_master_3_stb_i ,wishbone_bus0_socket_wb_master_2_stb_i ,wishbone_bus0_socket_wb_master_1_stb_i ,wishbone_bus0_socket_wb_master_0_stb_i};
 	assign wishbone_bus0_socket_wb_master_array_tag_i ={wishbone_bus0_socket_wb_master_3_tag_i ,wishbone_bus0_socket_wb_master_2_tag_i ,wishbone_bus0_socket_wb_master_1_tag_i ,wishbone_bus0_socket_wb_master_0_tag_i};
 	assign wishbone_bus0_socket_wb_master_array_we_i ={wishbone_bus0_socket_wb_master_3_we_i ,wishbone_bus0_socket_wb_master_2_we_i ,wishbone_bus0_socket_wb_master_1_we_i ,wishbone_bus0_socket_wb_master_0_we_i};
 	assign wishbone_bus0_socket_wb_slave_array_ack_i ={wishbone_bus0_socket_wb_slave_3_ack_i ,wishbone_bus0_socket_wb_slave_2_ack_i ,wishbone_bus0_socket_wb_slave_1_ack_i ,wishbone_bus0_socket_wb_slave_0_ack_i};
 	assign {wishbone_bus0_socket_wb_slave_3_adr_o ,wishbone_bus0_socket_wb_slave_2_adr_o ,wishbone_bus0_socket_wb_slave_1_adr_o ,wishbone_bus0_socket_wb_slave_0_adr_o} =wishbone_bus0_socket_wb_slave_array_adr_o;
 	assign {wishbone_bus0_socket_wb_slave_3_cyc_o ,wishbone_bus0_socket_wb_slave_2_cyc_o ,wishbone_bus0_socket_wb_slave_1_cyc_o ,wishbone_bus0_socket_wb_slave_0_cyc_o} =wishbone_bus0_socket_wb_slave_array_cyc_o;
 	assign wishbone_bus0_socket_wb_slave_array_dat_i ={wishbone_bus0_socket_wb_slave_3_dat_i ,wishbone_bus0_socket_wb_slave_2_dat_i ,wishbone_bus0_socket_wb_slave_1_dat_i ,wishbone_bus0_socket_wb_slave_0_dat_i};
 	assign {wishbone_bus0_socket_wb_slave_3_dat_o ,wishbone_bus0_socket_wb_slave_2_dat_o ,wishbone_bus0_socket_wb_slave_1_dat_o ,wishbone_bus0_socket_wb_slave_0_dat_o} =wishbone_bus0_socket_wb_slave_array_dat_o;
 	assign wishbone_bus0_socket_wb_slave_array_err_i ={wishbone_bus0_socket_wb_slave_3_err_i ,wishbone_bus0_socket_wb_slave_2_err_i ,wishbone_bus0_socket_wb_slave_1_err_i ,wishbone_bus0_socket_wb_slave_0_err_i};
 	assign wishbone_bus0_socket_wb_slave_array_rty_i ={wishbone_bus0_socket_wb_slave_3_rty_i ,wishbone_bus0_socket_wb_slave_2_rty_i ,wishbone_bus0_socket_wb_slave_1_rty_i ,wishbone_bus0_socket_wb_slave_0_rty_i};
 	assign {wishbone_bus0_socket_wb_slave_3_sel_o ,wishbone_bus0_socket_wb_slave_2_sel_o ,wishbone_bus0_socket_wb_slave_1_sel_o ,wishbone_bus0_socket_wb_slave_0_sel_o} =wishbone_bus0_socket_wb_slave_array_sel_o;
 	assign {wishbone_bus0_socket_wb_slave_3_stb_o ,wishbone_bus0_socket_wb_slave_2_stb_o ,wishbone_bus0_socket_wb_slave_1_stb_o ,wishbone_bus0_socket_wb_slave_0_stb_o} =wishbone_bus0_socket_wb_slave_array_stb_o;
 	assign {wishbone_bus0_socket_wb_slave_3_tag_o ,wishbone_bus0_socket_wb_slave_2_tag_o ,wishbone_bus0_socket_wb_slave_1_tag_o ,wishbone_bus0_socket_wb_slave_0_tag_o} =wishbone_bus0_socket_wb_slave_array_tag_o;
 	assign {wishbone_bus0_socket_wb_slave_3_we_o ,wishbone_bus0_socket_wb_slave_2_we_o ,wishbone_bus0_socket_wb_slave_1_we_o ,wishbone_bus0_socket_wb_slave_0_we_o} =wishbone_bus0_socket_wb_slave_array_we_o;

 
//Wishbone slave address match
 /* Altera_single_port_ram0 wb_slave 0 */
 	assign wishbone_bus0_socket_wb_addr_map_0_sel_one_hot[0]= ((wishbone_bus0_socket_wb_addr_map_0_grant_addr >= Altera_single_port_ram0_BASE_ADDR)   & (wishbone_bus0_socket_wb_addr_map_0_grant_addr< Altera_single_port_ram0_END_ADDR));
 /* timer0 wb_slave 0 */
 	assign wishbone_bus0_socket_wb_addr_map_0_sel_one_hot[1]= ((wishbone_bus0_socket_wb_addr_map_0_grant_addr >= timer0_BASE_ADDR)   & (wishbone_bus0_socket_wb_addr_map_0_grant_addr< timer0_END_ADDR));
 endmodule

