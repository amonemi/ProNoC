module tang (
	clk,
	reset ,
	sim_tile_0_Led_port_o ,
	sim_tile_0_uart_dataavailable ,
	sim_tile_0_uart_readyfordata ,
	sim_tile_1_Led_port_o ,
	sim_tile_1_uart_dataavailable ,
	sim_tile_1_uart_readyfordata ,
	sim_tile_2_Led_port_o ,
	sim_tile_2_uart_dataavailable ,
	sim_tile_2_uart_readyfordata ,
	sim_tile_3_Led_port_o ,
	sim_tile_3_uart_dataavailable ,
	sim_tile_3_uart_readyfordata ,
	sim_tile_4_Led_port_o ,
	sim_tile_4_uart_dataavailable ,
	sim_tile_4_uart_readyfordata ,
	sim_tile_5_Led_port_o ,
	sim_tile_5_uart_dataavailable ,
	sim_tile_5_uart_readyfordata ,
	sim_tile_6_Led_port_o ,
	sim_tile_6_uart_dataavailable ,
	sim_tile_6_uart_readyfordata ,
	sim_tile_7_Led_port_o ,
	sim_tile_7_uart_dataavailable ,
	sim_tile_7_uart_readyfordata ,
	sim_tile_8_Led_port_o ,
	sim_tile_8_uart_dataavailable ,
	sim_tile_8_uart_readyfordata ,
	processors_en
);
 
//functions	
	function integer log2;
		input integer number; begin   
			log2=0;    
			while(2**log2<number) begin    
				log2=log2+1;    
			end    
	end   
	endfunction // log2 
    
	function integer CORE_NUM;
		input integer x,y;
		begin
			CORE_NUM = ((y * NX) +  x);
		end
	endfunction
    
        

	localparam	Fw      =   2+V+Fpay,
				NC      =   NX*NY,  //flit width; 
				Xw      =   log2(NX),
				Yw      =   log2(NY) , 
				Cw      =   (C>1)? log2(C): 1,
				NCw     =   log2(NC),
				NCV     =   NC  * V,
				NCFw    =   NC  * Fw;
	 
//SOC parameters
 
	 //Parameter setting for sim_tile  located in tile: 0 
	 localparam sim_tile_0_Led_PORT_WIDTH=1;
	 localparam sim_tile_0_aeMB_AEMB_BSF= 1;
	 localparam sim_tile_0_aeMB_AEMB_MUL= 1;
	 localparam sim_tile_0_ram_Aw=13;
	 localparam sim_tile_0_ram_Dw=32;
 
	 //Parameter setting for sim_tile  located in tile: 1 
	 localparam sim_tile_1_Led_PORT_WIDTH=1;
	 localparam sim_tile_1_aeMB_AEMB_BSF= 1;
	 localparam sim_tile_1_aeMB_AEMB_MUL= 1;
	 localparam sim_tile_1_ram_Aw=13;
	 localparam sim_tile_1_ram_Dw=32;
 
	 //Parameter setting for sim_tile  located in tile: 2 
	 localparam sim_tile_2_Led_PORT_WIDTH=1;
	 localparam sim_tile_2_aeMB_AEMB_BSF= 1;
	 localparam sim_tile_2_aeMB_AEMB_MUL= 1;
	 localparam sim_tile_2_ram_Aw=13;
	 localparam sim_tile_2_ram_Dw=32;
 
	 //Parameter setting for sim_tile  located in tile: 3 
	 localparam sim_tile_3_Led_PORT_WIDTH=1;
	 localparam sim_tile_3_aeMB_AEMB_BSF= 1;
	 localparam sim_tile_3_aeMB_AEMB_MUL= 1;
	 localparam sim_tile_3_ram_Aw=13;
	 localparam sim_tile_3_ram_Dw=32;
 
	 //Parameter setting for sim_tile  located in tile: 4 
	 localparam sim_tile_4_Led_PORT_WIDTH=1;
	 localparam sim_tile_4_aeMB_AEMB_BSF= 1;
	 localparam sim_tile_4_aeMB_AEMB_MUL= 1;
	 localparam sim_tile_4_ram_Aw=13;
	 localparam sim_tile_4_ram_Dw=32;
 
	 //Parameter setting for sim_tile  located in tile: 5 
	 localparam sim_tile_5_Led_PORT_WIDTH=1;
	 localparam sim_tile_5_aeMB_AEMB_BSF= 1;
	 localparam sim_tile_5_aeMB_AEMB_MUL= 1;
	 localparam sim_tile_5_ram_Aw=13;
	 localparam sim_tile_5_ram_Dw=32;
 
	 //Parameter setting for sim_tile  located in tile: 6 
	 localparam sim_tile_6_Led_PORT_WIDTH=1;
	 localparam sim_tile_6_aeMB_AEMB_BSF= 1;
	 localparam sim_tile_6_aeMB_AEMB_MUL= 1;
	 localparam sim_tile_6_ram_Aw=13;
	 localparam sim_tile_6_ram_Dw=32;
 
	 //Parameter setting for sim_tile  located in tile: 7 
	 localparam sim_tile_7_Led_PORT_WIDTH=1;
	 localparam sim_tile_7_aeMB_AEMB_BSF= 1;
	 localparam sim_tile_7_aeMB_AEMB_MUL= 1;
	 localparam sim_tile_7_ram_Aw=13;
	 localparam sim_tile_7_ram_Dw=32;
 
	 //Parameter setting for sim_tile  located in tile: 8 
	 localparam sim_tile_8_Led_PORT_WIDTH=1;
	 localparam sim_tile_8_aeMB_AEMB_BSF= 1;
	 localparam sim_tile_8_aeMB_AEMB_MUL= 1;
	 localparam sim_tile_8_ram_Aw=13;
	 localparam sim_tile_8_ram_Dw=32;
 
 

//NoC parameters
 	localparam P= 5;
 	localparam NX=3;
 	localparam NY=3;
 	localparam V=2;
 	localparam B=4;
 	localparam Fpay=32;
 	localparam TOPOLOGY="MESH";
 	localparam ROUTE_NAME="XY";
 	localparam VC_REALLOCATION_TYPE="NONATOMIC";
 	localparam COMBINATION_TYPE="COMB_NONSPEC";
 	localparam MUX_TYPE="BINARY";
 	localparam C=0;
 	localparam CONGESTION_INDEX=3;
 	localparam DEBUG_EN=0;
 	localparam ADD_PIPREG_AFTER_CROSSBAR=1'b0;
 	localparam ADD_PIPREG_BEFORE_CROSSBAR=1'b0;
 	localparam FIRST_ARBITER_EXT_P_EN=0;
 	localparam ROUTE_TYPE=(ROUTE_NAME == "XY" || ROUTE_NAME == "TRANC_XY" )?    "DETERMINISTIC" : 
			 (ROUTE_NAME == "DUATO" || ROUTE_NAME == "TRANC_DUATO" )?   "FULL_ADAPTIVE": "PAR_ADAPTIVE";
 	localparam AVC_ATOMIC_EN=0;
 	localparam ROUTE_SUBFUNC="XY";
 	localparam CLASS_SETTING={V{1'b1}};
 	localparam [1	:0] ESCAP_VC_MASK=1;
  	localparam  CVw=(C==0)? V : C * V;
 
//IO
	input	clk,reset;
 	output	 [ sim_tile_0_Led_PORT_WIDTH-1     :   0    ] sim_tile_0_Led_port_o;
 	output			sim_tile_0_uart_dataavailable;
 	output			sim_tile_0_uart_readyfordata;
 	output	 [ sim_tile_1_Led_PORT_WIDTH-1     :   0    ] sim_tile_1_Led_port_o;
 	output			sim_tile_1_uart_dataavailable;
 	output			sim_tile_1_uart_readyfordata;
 	output	 [ sim_tile_2_Led_PORT_WIDTH-1     :   0    ] sim_tile_2_Led_port_o;
 	output			sim_tile_2_uart_dataavailable;
 	output			sim_tile_2_uart_readyfordata;
 	output	 [ sim_tile_3_Led_PORT_WIDTH-1     :   0    ] sim_tile_3_Led_port_o;
 	output			sim_tile_3_uart_dataavailable;
 	output			sim_tile_3_uart_readyfordata;
 	output	 [ sim_tile_4_Led_PORT_WIDTH-1     :   0    ] sim_tile_4_Led_port_o;
 	output			sim_tile_4_uart_dataavailable;
 	output			sim_tile_4_uart_readyfordata;
 	output	 [ sim_tile_5_Led_PORT_WIDTH-1     :   0    ] sim_tile_5_Led_port_o;
 	output			sim_tile_5_uart_dataavailable;
 	output			sim_tile_5_uart_readyfordata;
 	output	 [ sim_tile_6_Led_PORT_WIDTH-1     :   0    ] sim_tile_6_Led_port_o;
 	output			sim_tile_6_uart_dataavailable;
 	output			sim_tile_6_uart_readyfordata;
 	output	 [ sim_tile_7_Led_PORT_WIDTH-1     :   0    ] sim_tile_7_Led_port_o;
 	output			sim_tile_7_uart_dataavailable;
 	output			sim_tile_7_uart_readyfordata;
 	output	 [ sim_tile_8_Led_PORT_WIDTH-1     :   0    ] sim_tile_8_Led_port_o;
 	output			sim_tile_8_uart_dataavailable;
 	output			sim_tile_8_uart_readyfordata;
 	 input processors_en; 
	
//NoC ports                
	wire [Fw-1      :   0]  ni_flit_out                 [NC-1           :0];   
	wire [NC-1      :   0]  ni_flit_out_wr; 
	wire [V-1       :   0]  ni_credit_in                [NC-1           :0];
	wire [Fw-1      :   0]  ni_flit_in                  [NC-1           :0];   
	wire [NC-1      :   0]  ni_flit_in_wr;  
	wire [V-1       :   0]  ni_credit_out               [NC-1           :0];    
	wire [NCFw-1    :   0]  flit_out_all;
	wire [NC-1      :   0]  flit_out_wr_all;
	wire [NCV-1     :   0]  credit_in_all;
	wire [NCFw-1    :   0]  flit_in_all;
	wire [NC-1      :   0]  flit_in_wr_all;  
	wire [NCV-1     :   0]  credit_out_all;
	wire 					noc_clk,noc_reset;
    
    
//NoC
 	noc #(
 		.V(V) ,
		.P(P) ,
		.B(B) ,
		.NX(NX) ,
		.NY(NY) ,
		.C(C) ,
		.Fpay(Fpay) ,
		.MUX_TYPE(MUX_TYPE) ,
		.VC_REALLOCATION_TYPE(VC_REALLOCATION_TYPE) ,
		.COMBINATION_TYPE(COMBINATION_TYPE) ,
		.FIRST_ARBITER_EXT_P_EN(FIRST_ARBITER_EXT_P_EN) ,
		.TOPOLOGY(TOPOLOGY) ,
		.ROUTE_TYPE(ROUTE_TYPE) ,
		.ROUTE_NAME(ROUTE_NAME) ,
		.CONGESTION_INDEX(CONGESTION_INDEX) ,
		.DEBUG_EN(DEBUG_EN) ,
		.ROUTE_SUBFUNC(ROUTE_SUBFUNC) ,
		.AVC_ATOMIC_EN(AVC_ATOMIC_EN) ,
		.ADD_PIPREG_AFTER_CROSSBAR(ADD_PIPREG_AFTER_CROSSBAR) ,
		.ADD_PIPREG_BEFORE_CROSSBAR(ADD_PIPREG_BEFORE_CROSSBAR) ,
		.CVw(CVw) ,
		.CLASS_SETTING(CLASS_SETTING) ,
		.ESCAP_VC_MASK(ESCAP_VC_MASK) 
	)
	the_noc
	(
 		.reset(noc_reset) ,
		.clk(noc_clk) ,
		.flit_out_all(flit_out_all) ,
		.flit_out_wr_all(flit_out_wr_all) ,
		.credit_in_all(credit_in_all) ,
		.flit_in_all(flit_in_all) ,
		.flit_in_wr_all(flit_in_wr_all) ,
		.credit_out_all(credit_out_all) 
	);

 	
	clk_source  src 	(
		.clk_in(clk),
		.clk_out(noc_clk),
		.reset_in(reset),
		.reset_out(noc_reset)
	);    
 	

//NoC port assignment
  genvar x,y;
  generate 
    for (x=0;   x<NX; x=x+1) begin :x_loop1
        for (y=0;   y<NY;   y=y+1) begin: y_loop1
                localparam IP_NUM   =   ((y * NX) +  x);           
             
           
            assign  ni_flit_in      [IP_NUM] =   flit_out_all    [(IP_NUM+1)*Fw-1    : IP_NUM*Fw];   
            assign  ni_flit_in_wr   [IP_NUM] =   flit_out_wr_all [IP_NUM]; 
            assign  credit_in_all   [(IP_NUM+1)*V-1 : IP_NUM*V]     =   ni_credit_out   [IP_NUM];  
            assign  flit_in_all     [(IP_NUM+1)*Fw-1    : IP_NUM*Fw]    =   ni_flit_out     [IP_NUM];
            assign  flit_in_wr_all  [IP_NUM] =   ni_flit_out_wr  [IP_NUM];
            assign  ni_credit_in    [IP_NUM] =   credit_out_all  [(IP_NUM+1)*V-1 : IP_NUM*V];
  
    
           
            
                        
        end
    end
endgenerate

 

 // Tile:0 (x=0,y=0)
   	sim_tile #(
 		.CORE_ID(0) ,
		.ni_B(B) ,
		.ni_DEBUG_EN(DEBUG_EN) ,
		.ni_NX(NX) ,
		.ni_NY(NY) ,
		.ni_ROUTE_NAME(ROUTE_NAME) ,
		.ni_TOPOLOGY(TOPOLOGY) ,
		.ni_V(V) ,
		.Led_PORT_WIDTH(sim_tile_0_Led_PORT_WIDTH) ,
		.aeMB_AEMB_BSF(sim_tile_0_aeMB_AEMB_BSF) ,
		.aeMB_AEMB_MUL(sim_tile_0_aeMB_AEMB_MUL) ,
		.ram_Aw(sim_tile_0_ram_Aw) ,
		.ram_Dw(sim_tile_0_ram_Dw) 
	)the_sim_tile_0(
 
		.Led_port_o(sim_tile_0_Led_port_o) , 
		.uart_dataavailable(sim_tile_0_uart_dataavailable) , 
		.uart_readyfordata(sim_tile_0_uart_readyfordata) , 
		.ss_clk_in(clk) , 
		.aeMB_sys_ena_i(processors_en) , 
		.ss_reset_in(reset) , 
		.ni_credit_in(ni_credit_in[0]) , 
		.ni_credit_out(ni_credit_out[0]) , 
		.ni_current_x(2'd0) , 
		.ni_current_y(2'd0) , 
		.ni_flit_in(ni_flit_in[0]) , 
		.ni_flit_in_wr(ni_flit_in_wr[0]) , 
		.ni_flit_out(ni_flit_out[0]) , 
		.ni_flit_out_wr(ni_flit_out_wr[0]) 
	);
 

 // Tile:1 (x=1,y=0)
   	sim_tile #(
 		.CORE_ID(1) ,
		.ni_B(B) ,
		.ni_DEBUG_EN(DEBUG_EN) ,
		.ni_NX(NX) ,
		.ni_NY(NY) ,
		.ni_ROUTE_NAME(ROUTE_NAME) ,
		.ni_TOPOLOGY(TOPOLOGY) ,
		.ni_V(V) ,
		.Led_PORT_WIDTH(sim_tile_1_Led_PORT_WIDTH) ,
		.aeMB_AEMB_BSF(sim_tile_1_aeMB_AEMB_BSF) ,
		.aeMB_AEMB_MUL(sim_tile_1_aeMB_AEMB_MUL) ,
		.ram_Aw(sim_tile_1_ram_Aw) ,
		.ram_Dw(sim_tile_1_ram_Dw) 
	)the_sim_tile_1(
 
		.Led_port_o(sim_tile_1_Led_port_o) , 
		.uart_dataavailable(sim_tile_1_uart_dataavailable) , 
		.uart_readyfordata(sim_tile_1_uart_readyfordata) , 
		.ss_clk_in(clk) , 
		.aeMB_sys_ena_i(processors_en) , 
		.ss_reset_in(reset) , 
		.ni_credit_in(ni_credit_in[1]) , 
		.ni_credit_out(ni_credit_out[1]) , 
		.ni_current_x(2'd1) , 
		.ni_current_y(2'd0) , 
		.ni_flit_in(ni_flit_in[1]) , 
		.ni_flit_in_wr(ni_flit_in_wr[1]) , 
		.ni_flit_out(ni_flit_out[1]) , 
		.ni_flit_out_wr(ni_flit_out_wr[1]) 
	);
 

 // Tile:2 (x=2,y=0)
   	sim_tile #(
 		.CORE_ID(2) ,
		.ni_B(B) ,
		.ni_DEBUG_EN(DEBUG_EN) ,
		.ni_NX(NX) ,
		.ni_NY(NY) ,
		.ni_ROUTE_NAME(ROUTE_NAME) ,
		.ni_TOPOLOGY(TOPOLOGY) ,
		.ni_V(V) ,
		.Led_PORT_WIDTH(sim_tile_2_Led_PORT_WIDTH) ,
		.aeMB_AEMB_BSF(sim_tile_2_aeMB_AEMB_BSF) ,
		.aeMB_AEMB_MUL(sim_tile_2_aeMB_AEMB_MUL) ,
		.ram_Aw(sim_tile_2_ram_Aw) ,
		.ram_Dw(sim_tile_2_ram_Dw) 
	)the_sim_tile_2(
 
		.Led_port_o(sim_tile_2_Led_port_o) , 
		.uart_dataavailable(sim_tile_2_uart_dataavailable) , 
		.uart_readyfordata(sim_tile_2_uart_readyfordata) , 
		.ss_clk_in(clk) , 
		.aeMB_sys_ena_i(processors_en) , 
		.ss_reset_in(reset) , 
		.ni_credit_in(ni_credit_in[2]) , 
		.ni_credit_out(ni_credit_out[2]) , 
		.ni_current_x(2'd2) , 
		.ni_current_y(2'd0) , 
		.ni_flit_in(ni_flit_in[2]) , 
		.ni_flit_in_wr(ni_flit_in_wr[2]) , 
		.ni_flit_out(ni_flit_out[2]) , 
		.ni_flit_out_wr(ni_flit_out_wr[2]) 
	);
 

 // Tile:3 (x=0,y=1)
   	sim_tile #(
 		.CORE_ID(3) ,
		.ni_B(B) ,
		.ni_DEBUG_EN(DEBUG_EN) ,
		.ni_NX(NX) ,
		.ni_NY(NY) ,
		.ni_ROUTE_NAME(ROUTE_NAME) ,
		.ni_TOPOLOGY(TOPOLOGY) ,
		.ni_V(V) ,
		.Led_PORT_WIDTH(sim_tile_3_Led_PORT_WIDTH) ,
		.aeMB_AEMB_BSF(sim_tile_3_aeMB_AEMB_BSF) ,
		.aeMB_AEMB_MUL(sim_tile_3_aeMB_AEMB_MUL) ,
		.ram_Aw(sim_tile_3_ram_Aw) ,
		.ram_Dw(sim_tile_3_ram_Dw) 
	)the_sim_tile_3(
 
		.Led_port_o(sim_tile_3_Led_port_o) , 
		.uart_dataavailable(sim_tile_3_uart_dataavailable) , 
		.uart_readyfordata(sim_tile_3_uart_readyfordata) , 
		.ss_clk_in(clk) , 
		.aeMB_sys_ena_i(processors_en) , 
		.ss_reset_in(reset) , 
		.ni_credit_in(ni_credit_in[3]) , 
		.ni_credit_out(ni_credit_out[3]) , 
		.ni_current_x(2'd0) , 
		.ni_current_y(2'd1) , 
		.ni_flit_in(ni_flit_in[3]) , 
		.ni_flit_in_wr(ni_flit_in_wr[3]) , 
		.ni_flit_out(ni_flit_out[3]) , 
		.ni_flit_out_wr(ni_flit_out_wr[3]) 
	);
 

 // Tile:4 (x=1,y=1)
   	sim_tile #(
 		.CORE_ID(4) ,
		.ni_B(B) ,
		.ni_DEBUG_EN(DEBUG_EN) ,
		.ni_NX(NX) ,
		.ni_NY(NY) ,
		.ni_ROUTE_NAME(ROUTE_NAME) ,
		.ni_TOPOLOGY(TOPOLOGY) ,
		.ni_V(V) ,
		.Led_PORT_WIDTH(sim_tile_4_Led_PORT_WIDTH) ,
		.aeMB_AEMB_BSF(sim_tile_4_aeMB_AEMB_BSF) ,
		.aeMB_AEMB_MUL(sim_tile_4_aeMB_AEMB_MUL) ,
		.ram_Aw(sim_tile_4_ram_Aw) ,
		.ram_Dw(sim_tile_4_ram_Dw) 
	)the_sim_tile_4(
 
		.Led_port_o(sim_tile_4_Led_port_o) , 
		.uart_dataavailable(sim_tile_4_uart_dataavailable) , 
		.uart_readyfordata(sim_tile_4_uart_readyfordata) , 
		.ss_clk_in(clk) , 
		.aeMB_sys_ena_i(processors_en) , 
		.ss_reset_in(reset) , 
		.ni_credit_in(ni_credit_in[4]) , 
		.ni_credit_out(ni_credit_out[4]) , 
		.ni_current_x(2'd1) , 
		.ni_current_y(2'd1) , 
		.ni_flit_in(ni_flit_in[4]) , 
		.ni_flit_in_wr(ni_flit_in_wr[4]) , 
		.ni_flit_out(ni_flit_out[4]) , 
		.ni_flit_out_wr(ni_flit_out_wr[4]) 
	);
 

 // Tile:5 (x=2,y=1)
   	sim_tile #(
 		.CORE_ID(5) ,
		.ni_B(B) ,
		.ni_DEBUG_EN(DEBUG_EN) ,
		.ni_NX(NX) ,
		.ni_NY(NY) ,
		.ni_ROUTE_NAME(ROUTE_NAME) ,
		.ni_TOPOLOGY(TOPOLOGY) ,
		.ni_V(V) ,
		.Led_PORT_WIDTH(sim_tile_5_Led_PORT_WIDTH) ,
		.aeMB_AEMB_BSF(sim_tile_5_aeMB_AEMB_BSF) ,
		.aeMB_AEMB_MUL(sim_tile_5_aeMB_AEMB_MUL) ,
		.ram_Aw(sim_tile_5_ram_Aw) ,
		.ram_Dw(sim_tile_5_ram_Dw) 
	)the_sim_tile_5(
 
		.Led_port_o(sim_tile_5_Led_port_o) , 
		.uart_dataavailable(sim_tile_5_uart_dataavailable) , 
		.uart_readyfordata(sim_tile_5_uart_readyfordata) , 
		.ss_clk_in(clk) , 
		.aeMB_sys_ena_i(processors_en) , 
		.ss_reset_in(reset) , 
		.ni_credit_in(ni_credit_in[5]) , 
		.ni_credit_out(ni_credit_out[5]) , 
		.ni_current_x(2'd2) , 
		.ni_current_y(2'd1) , 
		.ni_flit_in(ni_flit_in[5]) , 
		.ni_flit_in_wr(ni_flit_in_wr[5]) , 
		.ni_flit_out(ni_flit_out[5]) , 
		.ni_flit_out_wr(ni_flit_out_wr[5]) 
	);
 

 // Tile:6 (x=0,y=2)
   	sim_tile #(
 		.CORE_ID(6) ,
		.ni_B(B) ,
		.ni_DEBUG_EN(DEBUG_EN) ,
		.ni_NX(NX) ,
		.ni_NY(NY) ,
		.ni_ROUTE_NAME(ROUTE_NAME) ,
		.ni_TOPOLOGY(TOPOLOGY) ,
		.ni_V(V) ,
		.Led_PORT_WIDTH(sim_tile_6_Led_PORT_WIDTH) ,
		.aeMB_AEMB_BSF(sim_tile_6_aeMB_AEMB_BSF) ,
		.aeMB_AEMB_MUL(sim_tile_6_aeMB_AEMB_MUL) ,
		.ram_Aw(sim_tile_6_ram_Aw) ,
		.ram_Dw(sim_tile_6_ram_Dw) 
	)the_sim_tile_6(
 
		.Led_port_o(sim_tile_6_Led_port_o) , 
		.uart_dataavailable(sim_tile_6_uart_dataavailable) , 
		.uart_readyfordata(sim_tile_6_uart_readyfordata) , 
		.ss_clk_in(clk) , 
		.aeMB_sys_ena_i(processors_en) , 
		.ss_reset_in(reset) , 
		.ni_credit_in(ni_credit_in[6]) , 
		.ni_credit_out(ni_credit_out[6]) , 
		.ni_current_x(2'd0) , 
		.ni_current_y(2'd2) , 
		.ni_flit_in(ni_flit_in[6]) , 
		.ni_flit_in_wr(ni_flit_in_wr[6]) , 
		.ni_flit_out(ni_flit_out[6]) , 
		.ni_flit_out_wr(ni_flit_out_wr[6]) 
	);
 

 // Tile:7 (x=1,y=2)
   	sim_tile #(
 		.CORE_ID(7) ,
		.ni_B(B) ,
		.ni_DEBUG_EN(DEBUG_EN) ,
		.ni_NX(NX) ,
		.ni_NY(NY) ,
		.ni_ROUTE_NAME(ROUTE_NAME) ,
		.ni_TOPOLOGY(TOPOLOGY) ,
		.ni_V(V) ,
		.Led_PORT_WIDTH(sim_tile_7_Led_PORT_WIDTH) ,
		.aeMB_AEMB_BSF(sim_tile_7_aeMB_AEMB_BSF) ,
		.aeMB_AEMB_MUL(sim_tile_7_aeMB_AEMB_MUL) ,
		.ram_Aw(sim_tile_7_ram_Aw) ,
		.ram_Dw(sim_tile_7_ram_Dw) 
	)the_sim_tile_7(
 
		.Led_port_o(sim_tile_7_Led_port_o) , 
		.uart_dataavailable(sim_tile_7_uart_dataavailable) , 
		.uart_readyfordata(sim_tile_7_uart_readyfordata) , 
		.ss_clk_in(clk) , 
		.aeMB_sys_ena_i(processors_en) , 
		.ss_reset_in(reset) , 
		.ni_credit_in(ni_credit_in[7]) , 
		.ni_credit_out(ni_credit_out[7]) , 
		.ni_current_x(2'd1) , 
		.ni_current_y(2'd2) , 
		.ni_flit_in(ni_flit_in[7]) , 
		.ni_flit_in_wr(ni_flit_in_wr[7]) , 
		.ni_flit_out(ni_flit_out[7]) , 
		.ni_flit_out_wr(ni_flit_out_wr[7]) 
	);
 

 // Tile:8 (x=2,y=2)
   	sim_tile #(
 		.CORE_ID(8) ,
		.ni_B(B) ,
		.ni_DEBUG_EN(DEBUG_EN) ,
		.ni_NX(NX) ,
		.ni_NY(NY) ,
		.ni_ROUTE_NAME(ROUTE_NAME) ,
		.ni_TOPOLOGY(TOPOLOGY) ,
		.ni_V(V) ,
		.Led_PORT_WIDTH(sim_tile_8_Led_PORT_WIDTH) ,
		.aeMB_AEMB_BSF(sim_tile_8_aeMB_AEMB_BSF) ,
		.aeMB_AEMB_MUL(sim_tile_8_aeMB_AEMB_MUL) ,
		.ram_Aw(sim_tile_8_ram_Aw) ,
		.ram_Dw(sim_tile_8_ram_Dw) 
	)the_sim_tile_8(
 
		.Led_port_o(sim_tile_8_Led_port_o) , 
		.uart_dataavailable(sim_tile_8_uart_dataavailable) , 
		.uart_readyfordata(sim_tile_8_uart_readyfordata) , 
		.ss_clk_in(clk) , 
		.aeMB_sys_ena_i(processors_en) , 
		.ss_reset_in(reset) , 
		.ni_credit_in(ni_credit_in[8]) , 
		.ni_credit_out(ni_credit_out[8]) , 
		.ni_current_x(2'd2) , 
		.ni_current_y(2'd2) , 
		.ni_flit_in(ni_flit_in[8]) , 
		.ni_flit_in_wr(ni_flit_in_wr[8]) , 
		.ni_flit_out(ni_flit_out[8]) , 
		.ni_flit_out_wr(ni_flit_out_wr[8]) 
	);
 
endmodule
