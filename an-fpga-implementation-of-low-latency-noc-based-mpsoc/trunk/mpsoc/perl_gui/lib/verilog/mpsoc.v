module mpsoc (
	clk,
	reset ,
	test_0_gpi_port_i ,
	test_1_gpi_port_i ,
	test_2_gpi_port_i ,
	test2_0_gpi_port_i ,
	test1_0_gpi_port_i ,
	test1_1_gpi_port_i ,
	test1_2_gpi_port_i ,
	test3_0_gpi_port_i ,
	test2_1_gpi_port_i ,
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
 
	 //Parameter setting for test  located in tile: 0 
	 localparam test_0_Altera_single_port_ram0_Aw=13;
	 localparam test_0_Altera_single_port_ram0_Dw=32;
	 localparam test_0_aeMB0_AEMB_BSF= 1;
	 localparam test_0_aeMB0_AEMB_MUL= 1;
	 localparam test_0_gpi_PORT_WIDTH=1;
 
	 //Parameter setting for test  located in tile: 1 
	 localparam test_1_Altera_single_port_ram0_Aw=15;
	 localparam test_1_Altera_single_port_ram0_Dw=32;
	 localparam test_1_aeMB0_AEMB_BSF= 1;
	 localparam test_1_aeMB0_AEMB_MUL= 1;
	 localparam test_1_gpi_PORT_WIDTH=1;
 
	 //Parameter setting for test  located in tile: 2 
	 localparam test_2_Altera_single_port_ram0_Aw=10;
	 localparam test_2_Altera_single_port_ram0_Dw=32;
	 localparam test_2_aeMB0_AEMB_BSF= 1;
	 localparam test_2_aeMB0_AEMB_MUL= 1;
	 localparam test_2_gpi_PORT_WIDTH=   1;
 
	 //Parameter setting for test2  located in tile: 3 
	 localparam test2_0_Altera_single_port_ram0_Aw=10;
	 localparam test2_0_Altera_single_port_ram0_Dw=32;
	 localparam test2_0_aeMB0_AEMB_BSF= 1;
	 localparam test2_0_aeMB0_AEMB_MUL= 1;
	 localparam test2_0_gpi_PORT_WIDTH=   1;
 
	 //Parameter setting for test1  located in tile: 4 
	 localparam test1_0_Altera_single_port_ram0_Aw=10;
	 localparam test1_0_Altera_single_port_ram0_Dw=32;
	 localparam test1_0_aeMB0_AEMB_BSF= 1;
	 localparam test1_0_aeMB0_AEMB_MUL= 1;
	 localparam test1_0_gpi_PORT_WIDTH=   1;
 
	 //Parameter setting for test1  located in tile: 5 
	 localparam test1_1_Altera_single_port_ram0_Aw=10;
	 localparam test1_1_Altera_single_port_ram0_Dw=32;
	 localparam test1_1_aeMB0_AEMB_BSF= 1;
	 localparam test1_1_aeMB0_AEMB_MUL= 1;
	 localparam test1_1_gpi_PORT_WIDTH=   1;
 
	 //Parameter setting for test1  located in tile: 6 
	 localparam test1_2_Altera_single_port_ram0_Aw=10;
	 localparam test1_2_Altera_single_port_ram0_Dw=32;
	 localparam test1_2_aeMB0_AEMB_BSF= 1;
	 localparam test1_2_aeMB0_AEMB_MUL= 1;
	 localparam test1_2_gpi_PORT_WIDTH=   1;
 
	 //Parameter setting for test3  located in tile: 7 
	 localparam test3_0_Altera_single_port_ram0_Aw=10;
	 localparam test3_0_Altera_single_port_ram0_Dw=32;
	 localparam test3_0_aeMB0_AEMB_BSF= 1;
	 localparam test3_0_aeMB0_AEMB_MUL= 1;
	 localparam test3_0_gpi_PORT_WIDTH=   1;
 
	 //Parameter setting for test2  located in tile: 8 
	 localparam test2_1_Altera_single_port_ram0_Aw=10;
	 localparam test2_1_Altera_single_port_ram0_Dw=32;
	 localparam test2_1_aeMB0_AEMB_BSF= 1;
	 localparam test2_1_aeMB0_AEMB_MUL= 1;
	 localparam test2_1_gpi_PORT_WIDTH=   1;
 
 

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
 	localparam COMBINATION_TYPE="COMB_SPEC1";
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
 	input	 [ test_0_gpi_PORT_WIDTH-1     :   0    ] test_0_gpi_port_i;
 	input	 [ test_1_gpi_PORT_WIDTH-1     :   0    ] test_1_gpi_port_i;
 	input	 [ test_2_gpi_PORT_WIDTH-1     :   0    ] test_2_gpi_port_i;
 	input	 [ test2_0_gpi_PORT_WIDTH-1     :   0    ] test2_0_gpi_port_i;
 	input	 [ test1_0_gpi_PORT_WIDTH-1     :   0    ] test1_0_gpi_port_i;
 	input	 [ test1_1_gpi_PORT_WIDTH-1     :   0    ] test1_1_gpi_port_i;
 	input	 [ test1_2_gpi_PORT_WIDTH-1     :   0    ] test1_2_gpi_port_i;
 	input	 [ test3_0_gpi_PORT_WIDTH-1     :   0    ] test3_0_gpi_port_i;
 	input	 [ test2_1_gpi_PORT_WIDTH-1     :   0    ] test2_1_gpi_port_i;
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
   	test #(
 		.CORE_ID(0) ,
		.ni_B(B) ,
		.ni_DEBUG_EN(DEBUG_EN) ,
		.ni_NX(NX) ,
		.ni_NY(NY) ,
		.ni_ROUTE_NAME(ROUTE_NAME) ,
		.ni_TOPOLOGY(TOPOLOGY) ,
		.ni_V(V) ,
		.Altera_single_port_ram0_Aw(test_0_Altera_single_port_ram0_Aw) ,
		.Altera_single_port_ram0_Dw(test_0_Altera_single_port_ram0_Dw) ,
		.aeMB0_AEMB_BSF(test_0_aeMB0_AEMB_BSF) ,
		.aeMB0_AEMB_MUL(test_0_aeMB0_AEMB_MUL) ,
		.gpi_PORT_WIDTH(test_0_gpi_PORT_WIDTH) 
	)the_test_0(
 
		.gpi_port_i(test_0_gpi_port_i) , 
		.clk_source0_clk_in(clk) , 
		.aeMB0_sys_ena_i(processors_en) , 
		.clk_source0_reset_in(reset) , 
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
   	test #(
 		.CORE_ID(1) ,
		.ni_B(B) ,
		.ni_DEBUG_EN(DEBUG_EN) ,
		.ni_NX(NX) ,
		.ni_NY(NY) ,
		.ni_ROUTE_NAME(ROUTE_NAME) ,
		.ni_TOPOLOGY(TOPOLOGY) ,
		.ni_V(V) ,
		.Altera_single_port_ram0_Aw(test_1_Altera_single_port_ram0_Aw) ,
		.Altera_single_port_ram0_Dw(test_1_Altera_single_port_ram0_Dw) ,
		.aeMB0_AEMB_BSF(test_1_aeMB0_AEMB_BSF) ,
		.aeMB0_AEMB_MUL(test_1_aeMB0_AEMB_MUL) ,
		.gpi_PORT_WIDTH(test_1_gpi_PORT_WIDTH) 
	)the_test_1(
 
		.gpi_port_i(test_1_gpi_port_i) , 
		.clk_source0_clk_in(clk) , 
		.aeMB0_sys_ena_i(processors_en) , 
		.clk_source0_reset_in(reset) , 
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
   	test #(
 		.CORE_ID(2) ,
		.ni_B(B) ,
		.ni_DEBUG_EN(DEBUG_EN) ,
		.ni_NX(NX) ,
		.ni_NY(NY) ,
		.ni_ROUTE_NAME(ROUTE_NAME) ,
		.ni_TOPOLOGY(TOPOLOGY) ,
		.ni_V(V) ,
		.Altera_single_port_ram0_Aw(test_2_Altera_single_port_ram0_Aw) ,
		.Altera_single_port_ram0_Dw(test_2_Altera_single_port_ram0_Dw) ,
		.aeMB0_AEMB_BSF(test_2_aeMB0_AEMB_BSF) ,
		.aeMB0_AEMB_MUL(test_2_aeMB0_AEMB_MUL) ,
		.gpi_PORT_WIDTH(test_2_gpi_PORT_WIDTH) 
	)the_test_2(
 
		.gpi_port_i(test_2_gpi_port_i) , 
		.clk_source0_clk_in(clk) , 
		.aeMB0_sys_ena_i(processors_en) , 
		.clk_source0_reset_in(reset) , 
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
   	test2 #(
 		.CORE_ID(3) ,
		.ni_B(B) ,
		.ni_DEBUG_EN(DEBUG_EN) ,
		.ni_NX(NX) ,
		.ni_NY(NY) ,
		.ni_ROUTE_NAME(ROUTE_NAME) ,
		.ni_TOPOLOGY(TOPOLOGY) ,
		.ni_V(V) ,
		.Altera_single_port_ram0_Aw(test2_0_Altera_single_port_ram0_Aw) ,
		.Altera_single_port_ram0_Dw(test2_0_Altera_single_port_ram0_Dw) ,
		.aeMB0_AEMB_BSF(test2_0_aeMB0_AEMB_BSF) ,
		.aeMB0_AEMB_MUL(test2_0_aeMB0_AEMB_MUL) ,
		.gpi_PORT_WIDTH(test2_0_gpi_PORT_WIDTH) 
	)the_test2_0(
 
		.gpi_port_i(test2_0_gpi_port_i) , 
		.clk_source0_clk_in(clk) , 
		.aeMB0_sys_ena_i(processors_en) , 
		.clk_source0_reset_in(reset) , 
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
   	test1 #(
 		.CORE_ID(4) ,
		.ni_B(B) ,
		.ni_DEBUG_EN(DEBUG_EN) ,
		.ni_NX(NX) ,
		.ni_NY(NY) ,
		.ni_ROUTE_NAME(ROUTE_NAME) ,
		.ni_TOPOLOGY(TOPOLOGY) ,
		.ni_V(V) ,
		.Altera_single_port_ram0_Aw(test1_0_Altera_single_port_ram0_Aw) ,
		.Altera_single_port_ram0_Dw(test1_0_Altera_single_port_ram0_Dw) ,
		.aeMB0_AEMB_BSF(test1_0_aeMB0_AEMB_BSF) ,
		.aeMB0_AEMB_MUL(test1_0_aeMB0_AEMB_MUL) ,
		.gpi_PORT_WIDTH(test1_0_gpi_PORT_WIDTH) 
	)the_test1_0(
 
		.gpi_port_i(test1_0_gpi_port_i) , 
		.clk_source0_clk_in(clk) , 
		.aeMB0_sys_ena_i(processors_en) , 
		.clk_source0_reset_in(reset) , 
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
   	test1 #(
 		.CORE_ID(5) ,
		.ni_B(B) ,
		.ni_DEBUG_EN(DEBUG_EN) ,
		.ni_NX(NX) ,
		.ni_NY(NY) ,
		.ni_ROUTE_NAME(ROUTE_NAME) ,
		.ni_TOPOLOGY(TOPOLOGY) ,
		.ni_V(V) ,
		.Altera_single_port_ram0_Aw(test1_1_Altera_single_port_ram0_Aw) ,
		.Altera_single_port_ram0_Dw(test1_1_Altera_single_port_ram0_Dw) ,
		.aeMB0_AEMB_BSF(test1_1_aeMB0_AEMB_BSF) ,
		.aeMB0_AEMB_MUL(test1_1_aeMB0_AEMB_MUL) ,
		.gpi_PORT_WIDTH(test1_1_gpi_PORT_WIDTH) 
	)the_test1_1(
 
		.gpi_port_i(test1_1_gpi_port_i) , 
		.clk_source0_clk_in(clk) , 
		.aeMB0_sys_ena_i(processors_en) , 
		.clk_source0_reset_in(reset) , 
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
   	test1 #(
 		.CORE_ID(6) ,
		.ni_B(B) ,
		.ni_DEBUG_EN(DEBUG_EN) ,
		.ni_NX(NX) ,
		.ni_NY(NY) ,
		.ni_ROUTE_NAME(ROUTE_NAME) ,
		.ni_TOPOLOGY(TOPOLOGY) ,
		.ni_V(V) ,
		.Altera_single_port_ram0_Aw(test1_2_Altera_single_port_ram0_Aw) ,
		.Altera_single_port_ram0_Dw(test1_2_Altera_single_port_ram0_Dw) ,
		.aeMB0_AEMB_BSF(test1_2_aeMB0_AEMB_BSF) ,
		.aeMB0_AEMB_MUL(test1_2_aeMB0_AEMB_MUL) ,
		.gpi_PORT_WIDTH(test1_2_gpi_PORT_WIDTH) 
	)the_test1_2(
 
		.gpi_port_i(test1_2_gpi_port_i) , 
		.clk_source0_clk_in(clk) , 
		.aeMB0_sys_ena_i(processors_en) , 
		.clk_source0_reset_in(reset) , 
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
   	test3 #(
 		.CORE_ID(7) ,
		.ni_B(B) ,
		.ni_DEBUG_EN(DEBUG_EN) ,
		.ni_NX(NX) ,
		.ni_NY(NY) ,
		.ni_ROUTE_NAME(ROUTE_NAME) ,
		.ni_TOPOLOGY(TOPOLOGY) ,
		.ni_V(V) ,
		.Altera_single_port_ram0_Aw(test3_0_Altera_single_port_ram0_Aw) ,
		.Altera_single_port_ram0_Dw(test3_0_Altera_single_port_ram0_Dw) ,
		.aeMB0_AEMB_BSF(test3_0_aeMB0_AEMB_BSF) ,
		.aeMB0_AEMB_MUL(test3_0_aeMB0_AEMB_MUL) ,
		.gpi_PORT_WIDTH(test3_0_gpi_PORT_WIDTH) 
	)the_test3_0(
 
		.gpi_port_i(test3_0_gpi_port_i) , 
		.clk_source0_clk_in(clk) , 
		.aeMB0_sys_ena_i(processors_en) , 
		.clk_source0_reset_in(reset) , 
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
   	test2 #(
 		.CORE_ID(8) ,
		.ni_B(B) ,
		.ni_DEBUG_EN(DEBUG_EN) ,
		.ni_NX(NX) ,
		.ni_NY(NY) ,
		.ni_ROUTE_NAME(ROUTE_NAME) ,
		.ni_TOPOLOGY(TOPOLOGY) ,
		.ni_V(V) ,
		.Altera_single_port_ram0_Aw(test2_1_Altera_single_port_ram0_Aw) ,
		.Altera_single_port_ram0_Dw(test2_1_Altera_single_port_ram0_Dw) ,
		.aeMB0_AEMB_BSF(test2_1_aeMB0_AEMB_BSF) ,
		.aeMB0_AEMB_MUL(test2_1_aeMB0_AEMB_MUL) ,
		.gpi_PORT_WIDTH(test2_1_gpi_PORT_WIDTH) 
	)the_test2_1(
 
		.gpi_port_i(test2_1_gpi_port_i) , 
		.clk_source0_clk_in(clk) , 
		.aeMB0_sys_ena_i(processors_en) , 
		.clk_source0_reset_in(reset) , 
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
