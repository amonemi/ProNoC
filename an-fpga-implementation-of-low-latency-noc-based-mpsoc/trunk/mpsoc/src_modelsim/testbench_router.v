`timescale	 1ns/1ps

module testbench_router;


	parameter V    = 2; 	// V
	parameter B    = 4; 	// buffer space :flit per VC 
	parameter NX   = 8;	   // The number of node in x axis of mesh or torus. For ring topology is total number of nodes in ring.
	parameter NY   = 8;	   // The number of node in y axis of mesh or torus. Not used in ring topology.
	parameter C    = 4;	   //	number of flit class 
	parameter Fpay = 32;
	parameter MUX_TYPE	=	"BINARY";	//"ONE_HOT" or "BINARY"
	parameter VC_REALLOCATION_TYPE	=	"NONATOMIC";// "ATOMIC" ; "NONATOMIC"
	parameter COMBINATION_TYPE= "COMB_NONSPEC";// "BASELINE"; "COMB_SPEC1"; "COMB_SPEC2"; "COMB_NONSPEC"
	parameter FIRST_ARBITER_EXT_P_EN   =	1;	
	parameter TOPOLOGY =	"MESH";//"MESH";"TORUS";"RING"
	parameter ROUTE_NAME    =   "XY";
	parameter CONGESTION_INDEX =   2;
	parameter DEBUG_EN =   0;
	parameter ROUTE_SUBFUNC ="XY";
	parameter AVC_ATOMIC_EN=1;
	parameter ADD_PIPREG_AFTER_CROSSBAR=0;
    	parameter CVw=(C==0)? V : C * V;
    	parameter [CVw-1:   0] CLASS_SETTING = {CVw{1'b1}}; // shows how each class can use VCs   
    	parameter [V-1  :   0] ESCAP_VC_MASK = 4'b1000;  // mask scape vc; valid only for full adaptive
    	parameter SSA_EN="YES"; // "YES" ; "NO"          					 
	
	localparam ROUTE_TYPE = (ROUTE_NAME == "XY" || ROUTE_NAME == "TRANC_XY" )?    "DETERMINISTIC" : 
                           (ROUTE_NAME == "DUATO" || ROUTE_NAME == "TRANC_DUATO" )?   "FULL_ADAPTIVE": "PAR_ADAPTIVE";    
			  
	localparam P=5;
	
		localparam CONGw= (CONGESTION_INDEX==3)?  3:
                      (CONGESTION_INDEX==5)?  3:
                      (CONGESTION_INDEX==7)?  3:
                      (CONGESTION_INDEX==9)?  3:
                      (CONGESTION_INDEX==10)? 4:
                      (CONGESTION_INDEX==12)? 3:2;	
 localparam		CONG_ALw   =    CONGw   *P;	//	congestion width per router
	function integer log2;
		input integer number;	begin	
		log2=0;	
		while(2**log2<number) begin	
		log2=log2+1;	
		end	
     		end	
   	endfunction // log2 
	
	localparam 	PV		=	V		*	P,
					VV		=	V		*	V,
					PVV	=	PV		*  V,	
					P_1	=	P-1	,
					VP_1	=	V		* 	P_1,				
					PP_1	=	P_1	*	P,
					PVP_1	=	PV		*	P_1;
	
	localparam 	Pw			=	log2(P),
					P_1w		=	log2(P_1),
					Vw			=	log2(V),
					Xw			= 	log2(NX),	// number of node in x axis
					Yw			=  log2(NY),	// number of node in y axis
					Cw			=  log2(C),
					Fw			=	2+V+Fpay,
					PFw		=	P*	Fw;	//flit width;	

	
	localparam	HDR_FLG						=1,
					TAIL_FLG						=0,
					CLASS_IN_HDR_WIDTH		=8,
					DEST_IN_HDR_WIDTH			=8,
					X_Y_IN_HDR_WIDTH			=4;
					
	
	//routers input/output ports
	
	reg										clk;
	reg										reset;

	wire	[PFw-1						:0]	flit_in_all; 
	reg	[P-1						:0]	flit_in_we_all;
	
	wire	[PV-1						:0]	credit_out_all;
	wire	[P-1						:0]	flit_out_we_all;
	wire	[PFw-1						:0]	flit_out_all;
	wire	[PV-1						:0]	credit_in_all;




	// seperate IO per port
	reg	[Fw-1						:0]	flit_in		[P-1	:	0];	 
	wire	[V-1						:0]	credit_out 	[P-1	:	0]; 
	wire	[Fw-1						:0]	flit_out	[P-1	:	0]; 
	reg	[V-1						:0]	credit_in	[P-1	:	0]; 



	// asssign seperate IO to the routers port
genvar i;
generate 
	for (i=0;i<P;i=i+1) begin : ports_blk
		assign flit_in_all   [Fw*(i+1)-1:	i*Fw] = flit_in[i];
		assign credit_in_all [V*(i+1)-1	:	i*V ] = credit_in[i];
		assign flit_out      [i]		      = flit_out_all [Fw*(i+1)-1	:	i*Fw];
		assign credit_out    [i] 		      = credit_out_all[V*(i+1)-1	:	i*V ];

	end
endgenerate

	
	


	router #(
		.V(V),
		.P(P),
      		.B(B), 
       		.NX(NX),
       		.NY(NY),
       		.C(C),	
       		.Fpay(Fpay),	
       		.TOPOLOGY(TOPOLOGY),
       		.MUX_TYPE(MUX_TYPE),
       		.VC_REALLOCATION_TYPE(VC_REALLOCATION_TYPE),
       		.COMBINATION_TYPE(COMBINATION_TYPE),
       		.FIRST_ARBITER_EXT_P_EN(FIRST_ARBITER_EXT_P_EN),
       		.ROUTE_TYPE(ROUTE_TYPE),
       		.ROUTE_NAME(ROUTE_NAME),  
                .CONGESTION_INDEX(CONGESTION_INDEX),
                .DEBUG_EN(DEBUG_EN),
                .ROUTE_SUBFUNC(ROUTE_SUBFUNC),
                .AVC_ATOMIC_EN(AVC_ATOMIC_EN),
                .CONGw(CONGw),
                .ADD_PIPREG_AFTER_CROSSBAR(ADD_PIPREG_AFTER_CROSSBAR),
                .CVw(CVw),
                .CLASS_SETTING(CLASS_SETTING),   
                .ESCAP_VC_MASK(ESCAP_VC_MASK),
                .SSA_EN(SSA_EN)  )   
	the_router

	(

		.current_x(3'd3),	
        	.current_y(3'd3),
		.flit_in_all		(flit_in_all),
		.flit_in_we_all		(flit_in_we_all),
		.credit_out_all		(credit_out_all),
		.congestion_in_all	(0), 

		.flit_out_all		(flit_out_all),
		.flit_out_we_all	(flit_out_we_all),
		.credit_in_all		(credit_in_all),
		.congestion_out_all     ( ),
		
		.clk			(clk),
		.reset			(reset)

	);




	initial begin 
		clk=1'b0;
		forever clk= #10 ~clk; 
	end


	integer k;

	initial begin 
	//reset 
		 reset=1'b1;		 
		 flit_in_we_all ={P{1'b0}};
		 for (k=0;k<P;k=k+1) begin
		 	flit_in[k]= {Fw{1'b0}};	 
			credit_in[k]=	{V{1'b0}}; 
		 end

	//deassert the reset
		 
		#200
		@(posedge clk)#1
		reset=1'b0;		 
		
		#200
		//send a packet from port zero (local) to the south 
	 	@(posedge clk)#1

		// send header flit
		flit_in_we_all[0]  = 1'b1;
		flit_in[0][Fw-1:Fw-2]=2'b10; // header flag
		flit_in[0][Fpay+V-1:Fpay]=1; // inputport VC
		//header flit payload		
		flit_in[0][Fpay-1 :0]= { /*/{reserved & wr_class_hdr}[7:0]*/ 8'd0,  /*reserved [3:0]*/ 4'd0, /*wr_destport_hdr[P-2:0]*/4'b1000,/*wr_des_x_addr[3:0]*/4'd4,/*wr_des_y_addr[3:0]*/4'd4,/*wr_src_x_addr[3:0]*/4'd3,/*wr_src_y_addr[3:0]*/4'd3};

		/*
		destport_hd: 
			in deterministic routing:
				is a one-hot code showing the position of output port. The sender port position must be removed from the one-hot code

				port order :{south,west,north,east,local}
			        e.g : send packet from north port to west:   one_hot code including all ports  {5'b01000} then removing north bit : 4'b0100;
			
			in partially/fully adaptive: 
				destport = {x,y,a,b};
					x= (dest_x  > current_x);   
					y= (dest_y  > current_y);
					a= if is one packet can be sent from x dimention to reach its destination 
					b= if is one packet can be sent from y dimention to reach its destination   
					   if both a and b are packet can be delivered from any of x or y dimention    						
					   if both a and b one zero packet will be delivered to local port.
				
					e.g destport={4'b1111}:    destination is located at east_south quarter and packet can sent from any of these two ports
					 
				


		*/
		


 		
		 
		// you can send flit from other ports in the same clock cycle here as well



		
		@(posedge clk)#1
		//send body flit 1
		flit_in_we_all[0]  = 1'b1;
		flit_in[0][Fw-1:Fw-2]=2'b00; // body flag
		flit_in[0][Fpay+V-1:Fpay]=1; // inputport VC	
		flit_in[0][Fpay-1:0]=  32'hAB000000; // your first data to send


		@(posedge clk)#1
		//send body flit 2
		flit_in_we_all[0]  = 1'b1;
		flit_in[0][Fw-1:Fw-2]=2'b00; // body flag
		flit_in[0][Fpay+V-1:Fpay]=1; // inputport VC	
		flit_in[0][Fpay-1:0]=  32'hAB000001; // your first data to send
		

		@(posedge clk)#1
		//send tail flit 3
		flit_in_we_all[0]  = 1'b1;
		flit_in[0][Fw-1:Fw-2]=2'b01; // tail flag
		flit_in[0][Fpay+V-1:Fpay]=1; // inputport VC	
		flit_in[0][Fpay-1:0]=  32'hAB000002; // your first data to send

		@(posedge clk)#1
		flit_in_we_all[0]  = 1'b0;

		#100
		$stop;

	end


	// assume the credit is recived with one clock cycle delay
	always @ (posedge clk) begin
		for (k=0;k<P;k=k+1)begin 
			credit_in[k]<=(flit_out_we_all[k]==1'b1)? flit_out[k][Fpay+V-1:Fpay] : {V{1'b0}};
		end

	end



endmodule

