`timescale	 1ns/1ps



module router # (
	parameter V = 2, 	// vc_num_per_port
	parameter P = 5, 	// router port num
	parameter B = 4, 	// buffer space :flit per VC 
	parameter NX = 5,	// number of node in x axis
	parameter NY = 5,	// number of node in y axis
	parameter C = 2,	//	number of flit class 
	parameter Fpay = 32,
	parameter TOPOLOGY=	"MESH", 
	parameter MUX_TYPE=	"BINARY",	//"ONE_HOT" or "BINARY"
	parameter VC_REALLOCATION_TYPE	=	"NONATOMIC",// "ATOMIC" , "NONATOMIC"
	parameter COMBINATION_TYPE= "BASELINE",// "BASELINE", "COMB_SPEC1", "COMB_SPEC2", "COMB_NONSPEC"
	parameter FIRST_ARBITER_EXT_P_EN		=	1,
	parameter ROUTE_TYPE = "DETERMINISTIC",// "DETERMINISTIC", "FULL_ADAPTIVE", "PAR_ADAPTIVE"
	parameter ROUTE_NAME = "XY",
    parameter CONGESTION_INDEX  =  2,
    parameter DEBUG_EN=1,
    parameter ROUTE_SUBFUNC= "XY",
    parameter AVC_ATOMIC_EN= 0,
    parameter CONGw   =   2, //congestion width per port
    parameter ADD_PIPREG_AFTER_CROSSBAR=0,
    parameter ADD_PIPREG_BEFORE_CROSSBAR=0,
    parameter CVw=(C==0)? V : C * V,
    parameter [CVw-1:   0] CLASS_SETTING = {CVw{1'b1}}, // shows how each class can use VCs   
    parameter [V-1  :   0] ESCAP_VC_MASK = 4'b1000  // mask scape vc, valid only for full adaptive    
 	
	

)(
	current_x,
	current_y,
	flit_in_all,
	flit_in_we_all,
	credit_out_all,
	//congestion_in_all,
	
	flit_out_all,
	flit_out_we_all,
	credit_in_all,
	congestion_out_all,
	
	clk,reset

);

	function integer log2;
      input integer number;	begin	
         log2=0;	
         while(2**log2<number) begin	
            log2=log2+1;	
         end	
      end	
   endfunction // log2 
 
 
	

	localparam 	PV		=	V		*	P,
				PVV	    =	PV		*  V,	
				P_1	    =	P-1	,
				PP_1	=	P_1     *	P,
				PVP_1	=	PV      *	P_1;

	localparam 	Fw		=	2+V+Fpay,	//flit width;	
                PFw		=	P*Fw,
                Xw      =   log2(NX),
                Yw      =   log2(NY),
                CONG_ALw=   CONGw* P;    //  congestion width per router         
                   

	
	input  [Xw-1       :   0]  current_x;
	input  [Yw-1       :   0]  current_y;
	
	input  [PFw-1      :   0]  flit_in_all;
	input  [P-1        :   0]  flit_in_we_all;
	output [PV-1       :   0]  credit_out_all;
	//input  [CONG_ALw-1 :   0]  congestion_in_all;
	wire   [CONG_ALw-1 :   0]  congestion_in_all={CONG_ALw{1'b0}};
	output [PFw-1      :   0]  flit_out_all;
	output [P-1        :   0]  flit_out_we_all;
	input  [PV-1       :   0]  credit_in_all;
	output [CONG_ALw-1 :   0]  congestion_out_all;
	
	input clk,reset;

	
	//internal wires
	wire	[PV-1     :	0] ovc_allocated_all;
	wire	[PVV-1    :	0] granted_ovc_num_all;
	wire	[PV-1     :	0] ivc_num_getting_sw_grant;
	wire	[PV-1     :	0] ivc_num_getting_ovc_grant;
	wire	[PVV-1    :	0] spec_ovc_num_all;
	wire	[PV-1     :	0] nonspec_first_arbiter_granted_ivc_all;
	wire	[PV-1     :	0] spec_first_arbiter_granted_ivc_all;
	wire	[PP_1-1   :	0] nonspec_granted_dest_port_all;
	wire	[PP_1-1   :	0] spec_granted_dest_port_all;	
	wire	[PP_1-1   :	0] granted_dest_port_all;
	wire	[P-1      :	0] any_ivc_sw_request_granted_all;
		
		// to vc/sw allocator
	wire   [PVP_1-1    :   0] dest_port_all;
	wire   [PV-1       :   0] ovc_is_assigned_all;
	wire   [PV-1       :   0] ivc_request_all;
	wire   [PV-1       :   0] assigned_ovc_not_full_all;
	wire   [PVV-1      :   0] masked_ovc_request_all;
		
		
		// to the crossbar
	wire   [PFw-1		:	0]	iport_flit_out_all;
	

	reg    [PP_1-1		:	0]	granted_dest_port_all_delayed;
	
	
	inout_ports
 #(
	.V(V),
	.P(P),
	.B(B), 
	.NX(NX),
	.NY(NY),
	.C(C),	
	.Fpay(Fpay),	
	.VC_REALLOCATION_TYPE(VC_REALLOCATION_TYPE),
	.COMBINATION_TYPE(COMBINATION_TYPE),
	.TOPOLOGY(TOPOLOGY),
	.ROUTE_TYPE(ROUTE_TYPE),
	.ROUTE_NAME(ROUTE_NAME),
    .CONGESTION_INDEX(CONGESTION_INDEX),
    .DEBUG_EN(DEBUG_EN),
    .ROUTE_SUBFUNC(ROUTE_SUBFUNC),
    .AVC_ATOMIC_EN(AVC_ATOMIC_EN),
    .CONGw(CONGw),
    .ADD_PIPREG_AFTER_CROSSBAR(ADD_PIPREG_AFTER_CROSSBAR),
    .ADD_PIPREG_BEFORE_CROSSBAR(ADD_PIPREG_BEFORE_CROSSBAR),
    .CVw(CVw),
    .CLASS_SETTING(CLASS_SETTING), // shows how each class can use VCs   
    .ESCAP_VC_MASK(ESCAP_VC_MASK)  // mask scape vc, valid only for full adaptive  
	
	
)the_inout_ports
(
	.current_x(current_x),
	.current_y(current_y),
	.flit_in_all(flit_in_all),
	.flit_in_we_all(flit_in_we_all),
	.credit_out_all(credit_out_all),
	.credit_in_all(credit_in_all),
	.masked_ovc_request_all(masked_ovc_request_all),
	.ovc_allocated_all(ovc_allocated_all), 
	.granted_ovc_num_all(granted_ovc_num_all), 
	.ivc_num_getting_sw_grant(ivc_num_getting_sw_grant), 
	.ivc_num_getting_ovc_grant(ivc_num_getting_ovc_grant), 
	.spec_ovc_num_all(spec_ovc_num_all), 
	.nonspec_first_arbiter_granted_ivc_all(nonspec_first_arbiter_granted_ivc_all), 
	.spec_first_arbiter_granted_ivc_all(spec_first_arbiter_granted_ivc_all), 
	.nonspec_granted_dest_port_all(nonspec_granted_dest_port_all), 
	.spec_granted_dest_port_all(spec_granted_dest_port_all), 
	.granted_dest_port_all(granted_dest_port_all), 
	.any_ivc_sw_request_granted_all(any_ivc_sw_request_granted_all), 
	.dest_port_all(dest_port_all), 
	.ovc_is_assigned_all(ovc_is_assigned_all), 
	.ivc_request_all(ivc_request_all), 
	.assigned_ovc_not_full_all(assigned_ovc_not_full_all), 
	.flit_out_all(iport_flit_out_all),
	.congestion_in_all(congestion_in_all),
	.congestion_out_all(congestion_out_all),
	.clk(clk), 
	.reset(reset)
);


combined_vc_sw_alloc #(
	.V(V),	//VC number per port
	.P(P), //port number
	.COMBINATION_TYPE(COMBINATION_TYPE),
	.FIRST_ARBITER_EXT_P_EN (FIRST_ARBITER_EXT_P_EN),
	.ROUTE_TYPE(ROUTE_TYPE),
	.ESCAP_VC_MASK(ESCAP_VC_MASK),
	.DEBUG_EN(DEBUG_EN)
 	
)the_combined_vc_sw_alloc
(
	.dest_port_all(dest_port_all), 
	.masked_ovc_request_all(masked_ovc_request_all),
	.ovc_is_assigned_all(ovc_is_assigned_all), 
	.ivc_request_all(ivc_request_all), 
	.assigned_ovc_not_full_all(assigned_ovc_not_full_all), 
	.ovc_allocated_all(ovc_allocated_all), 
	.granted_ovc_num_all(granted_ovc_num_all), 
	.ivc_num_getting_ovc_grant(ivc_num_getting_ovc_grant), 
	.ivc_num_getting_sw_grant(ivc_num_getting_sw_grant), 
	.spec_first_arbiter_granted_ivc_all(spec_first_arbiter_granted_ivc_all), 
	.nonspec_first_arbiter_granted_ivc_all(nonspec_first_arbiter_granted_ivc_all), 
	.nonspec_granted_dest_port_all(nonspec_granted_dest_port_all), 
	.spec_granted_dest_port_all(spec_granted_dest_port_all), 
	.granted_dest_port_all(granted_dest_port_all), 
	.any_ivc_sw_request_granted_all(any_ivc_sw_request_granted_all), 
	.spec_ovc_num_all(spec_ovc_num_all),     
	.clk(clk), 
	.reset(reset)
	);
	
	
	always @( posedge clk or posedge reset)begin
		if(reset) begin 
			granted_dest_port_all_delayed<= {PP_1{1'b0}};
			
		end else begin
			granted_dest_port_all_delayed<= granted_dest_port_all;
			
		end	
	end//always
	
	
	crossbar #(
		.V				(V), 	// vc_num_per_port
		.P				(P), 	// router port num
		.Fpay			(Fpay),
		.MUX_TYPE	(MUX_TYPE)	
	
	)the_crossbar
	(
		.granted_dest_port_all	(granted_dest_port_all_delayed),
		.flit_in_all				(iport_flit_out_all),
		.flit_out_all				(flit_out_all),
		.flit_out_we_all			(flit_out_we_all)
		
	);	

	
	include_random rnd();
	
	//synthesis translate_off 
    localparam 	EAST  = 1,
                NORTH = 2,
                WEST  = 3,
                SOUTH = 4;

	generate 
	if(DEBUG_EN)begin
        always @(posedge clk) begin 
            if(TOPOLOGY	 ==	"MESH")begin
                if(current_x 	== {Xw{1'b0}} 		&& flit_out_we_all[WEST]) $display ( "%t\t   Error: a packet is going to the WEST in a router located in first column in mesh topology %m",$time ); 
                if(current_x	== NX-1 	&& flit_out_we_all[EAST]) $display ( "%t\t   Error: a packet is going to the EAST in a router located in last column in mesh topology %m",$time ); 
                if(current_y 	== {Yw{1'b0}} 		&& flit_out_we_all[NORTH])$display ( "%t\t  Error: a packet is going to the NORTH in a router located in first row in mesh topology %m",$time ); 
                if(current_y	== NY-1	&& flit_out_we_all[SOUTH])$display ( "%t\t  Error: a packet is going to the SOUTH in a router located in last row in mesh topology %b  %m",$time,flit_out_all[(SOUTH+1)*Fw-1 : SOUTH*Fw] ); 
            
            end
        end//always 
	end// DEBUG
	endgenerate
	
	
	
	/*
	// for testing the route path
	reg tt;
	always @(posedge clk) begin
		if(reset) tt<=0;
		else begin 
			if(flit_in_we_all>0 && tt==0)begin 
				$display("%t : x=%d,Y=%d",$time,current_x,current_y);
				tt<=1;
			end
		end
	end
	*/
	/*
	reg [10    :   0]  counter;
	reg [31    :   0]  flit_counter;
	
	always @(posedge clk or posedge reset) begin
        if(reset) begin 
            flit_counter <=0;
            counter <= 0;
        end else begin 
            if(flit_in_we_all>0 )begin 
                counter <=0;
                flit_counter<=flit_counter+1'b1;
                          
            end else begin 
                counter <= counter+1'b1;
                if( counter == 512 ) $display("%t : total flits received in (x=%d,Y=%d) is %d ",$time,current_x,current_y,flit_counter);
            end
        end
    end
    */

//synthesis translate_on 

endmodule


/****************************************

	register router input/output port

****************************************/



module router_test # (
	parameter V 		= 4, 	// vc_num_per_port
	parameter P			= 5, 	// router port num
	parameter B 		= 4, 	// buffer space :flit per VC 
	parameter NX		= 5,	// number of node in x axis
	parameter NY		= 5,	// number of node in y axis
	//parameter current_x			= 2,	//router x addr
	//parameter current_y			= 2,	// router y addr
	parameter C			= 2,	//	number of class 
	parameter Fpay 	= 32,
	parameter TOPOLOGY=	"MESH", 
	parameter MUX_TYPE=	"BINARY",	//"ONE_HOT" or "BINARY"
	parameter VC_REALLOCATION_TYPE	=	"NONATOMIC",// "ATOMIC" , "NONATOMIC"
	parameter COMBINATION_TYPE= "BASELINE",// "BASELINE", "COMB_SPEC1", "COMB_SPEC2", "COMB_NONSPEC"
	parameter FIRST_ARBITER_EXT_P_EN		=	0,
	parameter ROUTE_NAME="WEST_FIRST",// "XY", "TRANC_XY"
    parameter ROUTE_TYPE="PAR_ADAPTIVE",// "DETERMINISTIC", "FULL_ADAPTIVE", "PAR_ADAPTIVE"
    parameter CONGESTION_INDEX     =   2,
    parameter ADD_PIPREG_AFTER_CROSSBAR=0,
    parameter ADD_PIPREG_BEFORE_CROSSBAR=0,
    parameter CVw=(C==0)? V : C * V,
    parameter [CVw-1:   0] CLASS_SETTING = {CVw{1'b1}}, // shows how each class can use VCs   
    parameter [V-1  :   0] ESCAP_VC_MASK = 4'b1000  // mask scape vc, valid only for full adaptive    

)(
	current_x,
	current_y,
	flit_in_all,
	flit_in_we_all,
	credit_out_all,
	congestion_in_all,
	flit_out_all,
	flit_out_we_all,
	credit_in_all,
	congestion_out_all,
	clk,reset

);

	function integer log2;
      input integer number;	begin	
         log2=0;	
         while(2**log2<number) begin	
            log2=log2+1;	
         end	
      end	
   endfunction // log2 
 
 
    localparam  P_1     =   P-1,
	            Xw		= 	log2(NX),	
				Yw		=   log2(NY),
				PV		=	V		*	P,
        	 	Fw		=	2+V+Fpay,	//flit width;	
				PFw		=	P*Fw,
				CONGw   =   2, //congestion width per port
                CONG_ALw=   CONGw   *   P;    //  congestion width per router  

	
    input   [Xw-1			:	0]	current_x;
    input   [Yw-1			:	0]	current_y;
	
	input	[PFw-1		    :	0]	flit_in_all;
	input	[P-1			:	0]	flit_in_we_all;
	output reg[PV-1			:	0]	credit_out_all;
    input   [CONG_ALw-1     :   0]  congestion_in_all;
	
	output reg[PFw-1		:	0]	flit_out_all;
	output reg [P-1			:	0]	flit_out_we_all;
	input	[PV-1			:	0]	credit_in_all;
	output reg [CONG_ALw-1  :   0]  congestion_out_all;
	
	input clk,reset;
	
	
    reg [Xw-1           :	0]	X_reg;
    reg [Yw-1			:	0]	Y_reg;
	
	reg	[PFw-11         :	0]	flit_in_all_reg;
	reg	[P-1			:	0]	flit_in_we_all_reg;
    wire[PV-1			:	0]	credit_out_all_o;
    reg [CONG_ALw-1     :   0]  congestion_in_all_reg;
    
    wire[PFw-1			:	0]	flit_out_all_o;
	wire[P-1			:	0]	flit_out_we_all_o;
	reg	[PV-1			:	0]	credit_in_all_reg;
	wire[CONG_ALw-1    :   0]  congestion_out_all_o;
	
	always @ (posedge clk or posedge reset) begin 
			if(reset) begin
				X_reg <=0;
				Y_reg <=0;
				flit_in_all_reg	<=0;
				flit_in_we_all_reg<=0;
				credit_in_all_reg <=0;
				flit_out_all <=0;
				flit_out_we_all	<=0;
				credit_out_all <=0;
				congestion_in_all_reg<= 0;
				congestion_out_all<=0;
			
			end else begin 
				X_reg<=current_x;
				Y_reg<=current_y;
				flit_in_all_reg	<=flit_in_all;
				flit_in_we_all_reg<=flit_in_we_all;
				credit_in_all_reg <=credit_in_all;
				flit_out_all <=flit_out_all_o;
				flit_out_we_all	<=flit_out_we_all_o;
				credit_out_all <=credit_out_all_o;
				congestion_in_all_reg<= congestion_in_all;
                congestion_out_all<=congestion_out_all_o;
			
			end
	end
	
	router # (
		.V(V),
		.P(P),
		.B(B), 
		.NX(NX),
		.NY(NY),
		.C(C),	
		.Fpay(Fpay),	
		.MUX_TYPE(MUX_TYPE),
		.VC_REALLOCATION_TYPE(VC_REALLOCATION_TYPE),
		.COMBINATION_TYPE(COMBINATION_TYPE),
		.FIRST_ARBITER_EXT_P_EN(FIRST_ARBITER_EXT_P_EN),
		.TOPOLOGY(TOPOLOGY),
        .ROUTE_NAME(ROUTE_NAME),
        .ROUTE_TYPE(ROUTE_TYPE),
        .CONGESTION_INDEX(CONGESTION_INDEX),
        .ADD_PIPREG_AFTER_CROSSBAR(ADD_PIPREG_AFTER_CROSSBAR),
        .ADD_PIPREG_BEFORE_CROSSBAR(ADD_PIPREG_BEFORE_CROSSBAR),
        .CVw(CVw),
        .CLASS_SETTING(CLASS_SETTING), // shows how each class can use VCs   
        .ESCAP_VC_MASK(ESCAP_VC_MASK)  // mask scape vc, valid only for full adaptive    
	)
	test_uut
	(
		.current_x(X_reg),	
		.current_y(Y_reg),
		.flit_in_all(flit_in_all_reg),
		.flit_in_we_all(flit_in_we_all_reg),
		.credit_out_all(credit_out_all_o),
		.congestion_in_all(congestion_in_all_reg),
    	.flit_out_all(flit_out_all_o),
		.flit_out_we_all(flit_out_we_all_o),
		.credit_in_all(credit_in_all_reg),
		.congestion_out_all(congestion_out_all_o),
		.clk(clk),
		.reset(reset)

	);	
			
	
	
	endmodule
