`include "pronoc_def.v"

/**************************************
* Module: router_bypass
* Date:2020-11-24  
* Author: alireza     
*
* Description: 
*   This file contains HDL modules that can be added
*   to a 2-stage NoC router and provides router bypassing
***************************************/

/**************************
 * SMART_flags_gen:
 * generate SMART flags based on NoC parameter, current router's port and address,
 * and destination router address
 * located in router output port (port number:SPB_OPORT_NUM)
 * smart_flag_o indicates how many more router in direct line can be bypassed
 * if SPB_OPORT_NUM  is also one of the possible output port in 
 * lk-ahead routing, The packet can by-pass the next router once the bypassing condition are met
 ***************************/

`include "pronoc_def.v"

	
module reduction_or #(
	parameter W = 5,//out width
	parameter N = 4 //array lenght 
)(
	in,
	out	
);
    input  [W-1 : 0] in [N-1 : 0];
    output reg [W-1 : 0] out;	
	
    // assign out = in.or(); //it is not synthesizable able by some compiler
	always_comb begin
		out = {W{1'b0}};
		for (int i = 0; i < N; i++)
			out |=   in[i];
	end


endmodule

module onehot_mux_2D #(
		parameter W = 5,//out width
		parameter N = 4 //sel width 
		)(
		in,
		sel,
		out	
		);

 	input  [W-1 : 0] in [N-1 : 0];
	input  [N-1 : 0] sel;
	output reg [W-1 : 0] out;	

    
	always_comb begin
		out = {W{1'b0}};
		for (int i = 0; i < N; i++)
			out |= (sel[i]) ?  in[i] :  {W{1'b0}};
	end
	
    
endmodule
	
module onehot_mux_1D #(
		parameter W = 5,//out width
		parameter N = 4 //sel width 
	)(
		input  [W*N-1 : 0] in,
		input  [N-1 : 0] sel,
		output [W-1 : 0] out	
	);

wire  [W-1 : 0] in_array [N-1 : 0];

genvar i;
generate
for (i=0;i<N;i++)begin :sep 
	assign in_array[i] = in[(i+1)*W-1 : i*W];
end
endgenerate
	

	onehot_mux_2D #(
		.W    (W), 
		.N    (N)
		) onehot_mux_2D (
		.in   (in_array), 
		.sel  (sel), 
		.out  (out));
	
    
endmodule	
	

module onehot_mux_1D_reverse #(
		parameter W = 5,//out width  p
		parameter N = 4 //sel width  v
		)(
		input  [W*N-1 : 0] in,
		input  [N-1 : 0] sel,
		output [W-1 : 0] out	
		);

	wire  [N-1 : 0] in_array [W-1 : 0];
	wire  [W-1 : 0] in_array2[N-1 : 0];

	genvar i,j;
	generate
		for (i=0;i<W;i++)begin :sep 
			assign in_array[i] = in[(i+1)*N-1 : i*N];
			for (j=0;j<N;j++)begin :sep
				assign in_array2[j][i] = in_array[i][j];
			end
		end
	endgenerate
	

	onehot_mux_2D #(
			.W    (N), 
			.N    (W)
		) onehot_mux_2D (
			.in   (in_array2), 
			.sel  (sel), 
			.out  (out));
	
    
endmodule	



module header_flit_info #(
	parameter NOC_ID = 0,
	parameter DATA_w = 0	
)(
	flit,
	hdr_flit,		
	data_o    
); 	
 	
 	`NOC_CONF
 	
 	localparam 
	Dw = (DATA_w==0)? 1 : DATA_w;
	
	input flit_t flit;
	output hdr_flit_t hdr_flit;
	output [Dw-1 : 0] data_o;
              
     
	localparam		         
		DATA_LSB= MSB_BE+1,               DATA_MSB= (DATA_LSB + DATA_w)<FPAYw ? DATA_LSB + Dw-1 : FPAYw-1,
		OFFSETw = DATA_MSB - DATA_LSB +1;
   
	wire [OFFSETw-1 : 0 ] offset;
  
	assign hdr_flit.src_e_addr  = flit.payload [E_SRC_MSB : E_SRC_LSB];
	assign hdr_flit.dest_e_addr = flit.payload [E_DST_MSB : E_DST_LSB];
	assign hdr_flit.destport    = flit.payload [DST_P_MSB : DST_P_LSB];
    
   
	generate
		if(C>1)begin : have_class 
			assign hdr_flit.message_class = flit.payload [CLASS_MSB : CLASS_LSB];
		end else begin : no_class
			assign hdr_flit.message_class = {Cw{1'b0}};
		end   

		/* verilator lint_off WIDTH */
		if(SWA_ARBITER_TYPE != "RRA")begin  : wrra_b
		/* verilator lint_on WIDTH */
			assign hdr_flit.weight =  flit.payload [WEIGHT_MSB : WEIGHT_LSB];    
		end else begin : rra_b
			assign hdr_flit.weight = {WEIGHTw{1'bX}};        
		end 
    
		if( BYTE_EN) begin : be_1
			assign hdr_flit.be = flit.payload [BE_MSB : BE_LSB];    
		end else begin : be_0    
			assign hdr_flit.be = {BEw{1'bX}};
		end
    
    
		assign offset = flit.payload [DATA_MSB : DATA_LSB];    
    
    
		if(Dw > OFFSETw) begin : if1     
			assign data_o={{(Dw-OFFSETw){1'b0}},offset};
		end else begin : if2 
			assign data_o=offset[Dw-1 : 0];
		end    
    
	endgenerate          
   
	

endmodule

//synthesis translate_off 
//synopsys  translate_off

module smart_chanel_check #(
	parameter NOC_ID=0
) (
	flit_chanel,
	smart_chanel,
	reset,
	clk		
);

	`NOC_CONF

	input flit_chanel_t  flit_chanel;
	input smart_chanel_t   smart_chanel; 		
	input reset,clk;
	
	smart_chanel_t   smart_chanel_delay; 
	always @(posedge clk) smart_chanel_delay<=smart_chanel;
	
	hdr_flit_t hdr_flit;
	header_flit_info #(
		.NOC_ID (NOC_ID)	
	) extract (
		.flit(flit_chanel.flit),
		.hdr_flit(hdr_flit),		
		.data_o()
	);

	always @(posedge clk) begin 
		if(flit_chanel.flit_wr) begin 
			if(smart_chanel_delay.ovc!=flit_chanel.flit.vc) begin 
				$display("%t: ERROR: smart ovc %d is not equal with flit ovc %d. %m",$time,smart_chanel_delay.ovc,flit_chanel.flit.vc);
				$finish;
			end
			if(flit_chanel.flit.hdr_flag==1'b1 &&   hdr_flit.dest_e_addr != smart_chanel_delay.dest_e_addr) begin 
				$display("%t: ERROR: smart dest_e_addr %d is not equal with flit dest_e_addr %d. %m",$time,smart_chanel_delay.dest_e_addr,hdr_flit.dest_e_addr);
				$finish;
			end
			if(flit_chanel.flit.hdr_flag!=smart_chanel_delay.hdr_flit) begin 
				$display("%t: ERROR: smart and current hdr flag (%d!=%d) miss-match. %m",$time, smart_chanel_delay.hdr_flit, flit_chanel.flit.hdr_flag);
				$finish;
			end
			
		end	
		
	end	
endmodule	
 
//synopsys  translate_on
//synthesis translate_on 


module smart_forward_ivc_info #(
	parameter NOC_ID=0,
	parameter P=5
) (			
	ivc_info,
	iport_info,
	oport_info,
	smart_chanel,
	ovc_locally_requested,
	reset,clk
);
		
	`NOC_CONF	
	
	//ivc info 
	input reset,clk;
	input  ivc_info_t 	ivc_info    [P-1 : 0][V-1 : 0];
	input  iport_info_t iport_info  [P-1 : 0];
	input  oport_info_t oport_info  [P-1 : 0]; 
	output smart_chanel_t smart_chanel  [P-1 : 0];
	output [V-1 : 0] ovc_locally_requested [P-1 : 0];
			
	smart_ivc_info_t  smart_ivc_info [P-1 : 0][V-1 : 0];
	smart_ivc_info_t  smart_ivc_mux  [P-1 : 0];
	
	smart_ivc_info_t  smart_ivc_info_all_port [P-1 : 0] [P-1 : 0];
	smart_ivc_info_t  smart_vc_info_o [P-1 : 0];
	
	wire [V-1 : 0] assigned_ovc [P-1:0];
	wire [V-1 : 0] non_assigned_vc_req [P-1:0];
	wire [P-1 : 0] mask_gen  [P-1 : 0][V-1 :0];
	wire [V-1 : 0] ovc_locally_requested_next [P-1 : 0];
	
	/* 
						P  V                   P		P  V   p
	non_assigned_vc_req[i][j] destport_one_hot[z]-->   [z][ j][i]
	non_assigned_vc_req[0][0] destport_one_hot[3]--> | [3][0] [0]
	non_assigned_vc_req[1][0] destport_one_hot[3]--> | [3][0] [1]
	non_assigned_vc_req[2][0] destport_one_hot[3]--> | [3][0] [2]
	*/
	
	smart_chanel_t smart_chanel_next  [P-1 : 0];
	
	
	genvar i,j,z;
	generate 
	for (i=0;i<P;i=i+1) begin : port_
				
		for (j=0; j < V; j=j+1) begin : ivc					
			assign smart_ivc_info[i][j].dest_e_addr = ivc_info[i][j].dest_e_addr;
			assign smart_ivc_info[i][j].ovc_is_assigned= ivc_info[i][j].ovc_is_assigned;
			assign smart_ivc_info[i][j].assigned_ovc_bin=ivc_info[i][j].assigned_ovc_bin;	
			assign non_assigned_vc_req[i][j] = ~ivc_info[i][j].ovc_is_assigned & ivc_info[i][j].ivc_req;
			for (z=0; z < P; z=z+1) begin : port
				assign mask_gen[z][j][i] = non_assigned_vc_req[i][j] & ivc_info[i][j].destport_one_hot[z]; 
			end
			assign ovc_locally_requested_next[i][j]=|mask_gen[i][j];
		end//V
		
		pronoc_register #(.W(V)) reg1 (.in(ovc_locally_requested_next[i]), .reset(reset), .clk(clk), .out(ovc_locally_requested[i]));
		
		
		
		
		onehot_mux_2D	#(.W(SMART_IVC_w),.N(V)) mux1 ( .in(smart_ivc_info[i]), .sel(iport_info[i].swa_first_level_grant), .out(smart_ivc_mux[i]));
		//demux
		for (j=0;j<P;j=j+1) begin : port_
			assign smart_ivc_info_all_port[j][i] = (iport_info[i].granted_oport_one_hot[j]==1'b1)? smart_ivc_mux[i] : {SMART_IVC_w{1'b0}};	
		end		
		
		//assign smart_vc_info_o[i] = smart_ivc_info_all_port[i].or; not synthesizable
		// assign smart_vc_info_o[i] = smart_ivc_info_all_port[i].[0] | smart_ivc_info_all_port[i].[1] | smart_ivc_info_all_port[i].[2]  ... | smart_ivc_info_all_port[i].[p-1];
		reduction_or #(
			.W    (SMART_IVC_w), 
			.N    (P)
		) _or (
			.in   (smart_ivc_info_all_port[i]), 
			.out  (smart_vc_info_o[i])
		);
		/*
		always_comb begin
			smart_vc_info_o[i] = {SMART_IVC_w{1'b0}};
			for (int ii = 0; ii < P; ii++)
				smart_vc_info_o[i] |= smart_ivc_info_all_port[i][ii];
		end
		*/
		
		
		bin_to_one_hot #(
			.BIN_WIDTH      (Vw), 
			.ONE_HOT_WIDTH  (V)
		) conv (
			.bin_code       (smart_vc_info_o[i].assigned_ovc_bin), 
			.one_hot_code   (assigned_ovc[i])
		);
				
		
		
		assign smart_chanel_next[i].dest_e_addr= smart_vc_info_o[i].dest_e_addr;	
		assign smart_chanel_next[i].ovc= (smart_vc_info_o[i].ovc_is_assigned)? assigned_ovc[i] : oport_info[i].non_smart_ovc_is_allocated;
		assign smart_chanel_next[i].hdr_flit=~smart_vc_info_o[i].ovc_is_assigned;
		assign smart_chanel_next[i].requests = (oport_info[i].any_ovc_granted)? {SMART_NUM{1'b1}}:{SMART_NUM{1'b0}} ;
		assign smart_chanel_next[i].bypassed_num = {BYPASSw{1'b0}} ;
		
		
		if( ADD_PIPREG_AFTER_CROSSBAR == 1) begin :link_reg
			pronoc_register #(
				.W      ( SMART_CHANEL_w)
				) register (
				.in     (smart_chanel_next[i]), 
				.reset  (reset), 
				.clk    (clk), 
				.out    (smart_chanel[i]));
		
		end else begin :no_link_reg
				assign smart_chanel[i] = smart_chanel_next[i];		
		end
		/*
		
			always @ (`pronoc_clk_reset_edge)begin 
				if(`pronoc_reset) begin 	
					smart_chanel[i].dest_e_addr<= {EAw{1'b0}};	
					smart_chanel[i].ovc<= {V{1'b0}};
					smart_chanel[i].hdr_flit<=1'b0;
				end else begin 	
					smart_chanel[i].dest_e_addr<= smart_vc_info_o[i].dest_e_addr;	
					smart_chanel[i].ovc<= (smart_vc_info_o[i].ovc_is_assigned)? assigned_ovc[i] : oport_info[i].non_smart_ovc_is_allocated;
					smart_chanel[i].hdr_flit<=~smart_vc_info_o[i].ovc_is_assigned;
					smart_chanel[i].requests <= (oport_info[i].any_ovc_granted)? {SMART_NUM{1'b1}}:{SMART_NUM{1'b0}} ;					
				end
			end		
	
		*/
			
			
			
	
		
		end//port_
		endgenerate	
	
//	generate for (i=0; i < P; i=i+1) begin : port
//			assign smart_ivc_info_o[i] = (granted_dest_port[i]==1'b1)? ivc_info_mux : {SMART_IVC_w{1'b0}};		
//		end endgenerate 	

			
endmodule
 
 
 
 
module smart_bypass_chanels #(
	parameter NOC_ID=0,
	parameter P=5	
) (			
	ivc_info,
	iport_info,
	oport_info,
	smart_chanel_new,
	smart_chanel_in,
	smart_chanel_out,
	smart_req,
	reset,
	clk	
);
		
	`NOC_CONF	

	input reset,clk;	
	input smart_chanel_t smart_chanel_new  [P-1 : 0];
	input smart_chanel_t smart_chanel_in   [P-1 : 0];
	input ivc_info_t   ivc_info    [P-1 : 0][V-1 : 0];
 	input iport_info_t iport_info  [P-1 : 0];
 	input oport_info_t oport_info  [P-1 : 0];
 	
 	output [P-1 : 0] smart_req;
 	output smart_chanel_t smart_chanel_out   [P-1 : 0];
 	
 	
	smart_chanel_t smart_chanel_shifted  [P-1 : 0];
	localparam DISABLE = P;
	
	wire [V-1 : 0 ] ivc_forwardable [P-1 : 0];
	wire [P-1 :0] smart_forwardable;
	logic [P-1 :0] outport_is_granted;
	reg [P-1 : 0] rq;
	genvar i;
	generate
	for (i=0;i<P;i=i+1) begin: port	
		/* verilator lint_off WIDTH */
		assign ivc_forwardable[i] =  (PCK_TYPE == "SINGLE_FLIT")?  1'b1 :~iport_info[i].ivc_req;
		/* verilator lint_on WIDTH */
		
		
		if( ADD_PIPREG_AFTER_CROSSBAR == 1) begin :link_reg
		always @( posedge clk)begin
		    outport_is_granted[i] <= oport_info[i].any_ovc_granted;
		end	
		end else begin 
			assign outport_is_granted[i] = oport_info[i].any_ovc_granted;
		end
		
		localparam SS_PORT = strieght_port (P,i); // the straight port number
		if(SS_PORT != DISABLE) begin: ssp 
			
			//smart_chanel_shifter
			assign smart_forwardable[i] = |  (ivc_forwardable[i] & smart_chanel_in[i].ovc);
			always @(*) begin 
				smart_chanel_shifted[i] = smart_chanel_in [i];
				{smart_chanel_shifted[i].requests,rq[i]} =(smart_forwardable[i])? {1'b0,smart_chanel_in[i].requests}:{{SMART_NUM{1'b0}},smart_chanel_in[i].requests[0]};
				smart_chanel_shifted[i].bypassed_num =   smart_chanel_in [i].bypassed_num +1'b1;
			end
			assign smart_req[i]=rq[i];
			// mux out smart chanel
			assign smart_chanel_out[i] = (outport_is_granted[i])? smart_chanel_new[i] : smart_chanel_shifted[SS_PORT];
			
			
			
			
		end else begin
			assign {smart_chanel_shifted[i].requests,smart_req[i]} = {(SMART_NUM+1){1'b0}};
			assign smart_chanel_out[i] = {SMART_CHANEL_w{1'b0}};
		end
		
	end	
	endgenerate
 
 
endmodule 
 
 
 
 
 

module check_straight_oport #(
		parameter TOPOLOGY          =   "MESH", 
		parameter ROUTE_NAME        =   "XY",
		parameter ROUTE_TYPE        =   "DETERMINISTIC", 
		parameter DSTPw             =   4,
		parameter SS_PORT_LOC     =   1
		)(
		destport_coded_i,
		goes_straight_o
		);
	
	input   [DSTPw-1 : 0] destport_coded_i;
	output  goes_straight_o;
		
	generate 
	/* verilator lint_off WIDTH */ 
		if(TOPOLOGY == "MESH" || TOPOLOGY == "TORUS" || TOPOLOGY =="FMESH") begin :twoD		
			/* verilator lint_on WIDTH */ 
			if (SS_PORT_LOC == 0 || SS_PORT_LOC > 4) begin : local_ports
				assign goes_straight_o = 1'b0; // There is not a next router in this case at all	
			end	
			else begin :non_local
								
				wire [4 : 0 ] destport_one_hot;
				mesh_tori_decode_dstport decoder(
						.dstport_encoded(destport_coded_i),
						.dstport_one_hot(destport_one_hot)
					);
				
				assign goes_straight_o = destport_one_hot [SS_PORT_LOC];	
			end//else
		end//mesh_tori
		/* verilator lint_off WIDTH */ 
		else if(TOPOLOGY ==  "RING" || TOPOLOGY ==  "LINE") begin :oneD		
			/* verilator lint_on WIDTH */ 
			if (SS_PORT_LOC == 0 || SS_PORT_LOC > 2) begin : local_ports
				assign goes_straight_o = 1'b0; // There is not a next router in this case at all	
			end	
			else begin :non_local
				
				wire [2: 0 ] destport_one_hot;
    
				line_ring_decode_dstport decoder(
						.dstport_encoded(destport_coded_i),
						.dstport_one_hot(destport_one_hot)
						
					);
				assign goes_straight_o = destport_one_hot [SS_PORT_LOC];	
				
			end	//non_local
		end// oneD
		
		//TODO Add fattree & custom 
			
	endgenerate	
	
endmodule	

 

	
module smart_validity_check_per_ivc  #(
	parameter NOC_ID=0,
	parameter IVC_NUM = 0
) (
	reset,
	clk,
	//smart channel
	goes_straight ,
	smart_requests_i,
	smart_ivc_i,
	smart_hdr_flit,		
	//flit		               
	flit_hdr_flag_i,
	flit_tail_flag_i,
	flit_wr_i,
	//router ivc status
	ovc_locally_requested,
	assigned_to_ss_ovc,
	assigned_ovc_not_full,
	ovc_is_assigned,
	ivc_request,
	//ss port status		                    
	ss_ovc_avalable_in_ss_port,
	ss_port_link_reg_flit_wr,
	ss_ovc_crossbar_wr,
	//output                          
	smart_single_flit_pck_o,
	smart_ivc_smart_en_o,
	smart_credit_o,
	smart_buff_space_decreased_o,
	smart_ss_ovc_is_allocated_o,
	smart_ss_ovc_is_released_o,
	smart_mask_available_ss_ovc_o, 
	smart_ivc_num_getting_ovc_grant_o,
	smart_ivc_reset_o,			
	smart_ivc_granted_ovc_num_o
);
	
	
	`NOC_CONF

	
	input reset, clk;
	//smart channel
	input goes_straight,
	smart_requests_i,
	smart_ivc_i,
	smart_hdr_flit,		
	//flit		               
	flit_hdr_flag_i ,
	flit_tail_flag_i,
	flit_wr_i,
	//router ivc status
	ovc_locally_requested,
	assigned_to_ss_ovc,
	assigned_ovc_not_full,
	ovc_is_assigned,
	ivc_request,
	//ss port status		                    
	ss_ovc_avalable_in_ss_port,
	ss_ovc_crossbar_wr,
	ss_port_link_reg_flit_wr;
//output                          
output 
	smart_single_flit_pck_o	,
	smart_ivc_smart_en_o,
	smart_credit_o,
	smart_buff_space_decreased_o,
	smart_ss_ovc_is_allocated_o,
	smart_ss_ovc_is_released_o,
	smart_ivc_num_getting_ovc_grant_o,
	smart_ivc_reset_o,			
	smart_mask_available_ss_ovc_o;	
		
output reg [V-1 : 0] smart_ivc_granted_ovc_num_o;

always @(*) begin 
	smart_ivc_granted_ovc_num_o={V{1'b0}};
	smart_ivc_granted_ovc_num_o[IVC_NUM]=smart_ivc_num_getting_ovc_grant_o;
end	
		
		
		
wire  smart_req_valid_next  = smart_requests_i &  smart_ivc_i & goes_straight;
logic smart_req_valid;	
wire  smart_hdr_flit_req_next = smart_req_valid_next  & smart_hdr_flit;
logic smart_hdr_flit_req;
	
pronoc_register #(.W(1)) req1 (.in(smart_req_valid_next), .reset(reset), .clk(clk), .out(smart_req_valid));
pronoc_register #(.W(1)) req2 (.in(smart_hdr_flit_req_next), .reset(reset), .clk(clk), .out(smart_hdr_flit_req));



	
// condition1: new smart vc allocation condition
wire hdr_flit_condition    = ~ovc_locally_requested & ss_ovc_avalable_in_ss_port;	
wire nonhdr_flit_condition = assigned_to_ss_ovc & assigned_ovc_not_full;
wire condition1 = 
	/* verilator lint_off WIDTH */
	(PCK_TYPE == "SINGLE_FLIT")?  hdr_flit_condition :
	/* verilator lint_on WIDTH */	
	(ovc_is_assigned)? nonhdr_flit_condition : hdr_flit_condition;
wire condition2;
generate

/* verilator lint_off WIDTH */
wire non_empty_ivc_condition =(PCK_TYPE == "SINGLE_FLIT")?  1'b0 :ivc_request;
/* verilator lint_on WIDTH */

	
if( ADD_PIPREG_AFTER_CROSSBAR == 1) begin :link_reg
	assign condition2= ~(non_empty_ivc_condition | ss_port_link_reg_flit_wr| ss_ovc_crossbar_wr);
end else begin : no_link_reg
	assign condition2= ~(non_empty_ivc_condition | ss_port_link_reg_flit_wr); // ss_port_link_reg_flit_wr are identical with ss_ovc_crossbar_wr when there is no link reg
end
	
endgenerate	
wire conditions_met = condition1 & condition2;
assign smart_ivc_smart_en_o = conditions_met & smart_req_valid;
	


assign smart_single_flit_pck_o     = 
	/* verilator lint_off WIDTH */
	(PCK_TYPE == "SINGLE_FLIT")? 1'b1 :
	/* verilator lint_on WIDTH */
	(MIN_PCK_SIZE==1)?  flit_tail_flag_i & flit_hdr_flag_i : 1'b0; 

assign smart_buff_space_decreased_o =  smart_ivc_smart_en_o & flit_wr_i ;
assign smart_ivc_num_getting_ovc_grant_o  =  smart_buff_space_decreased_o & !ovc_is_assigned  & flit_hdr_flag_i;
assign smart_ivc_reset_o   =  smart_buff_space_decreased_o & flit_tail_flag_i;
assign smart_ss_ovc_is_released_o = smart_ivc_reset_o & ~smart_single_flit_pck_o;
assign smart_ss_ovc_is_allocated_o = smart_ivc_num_getting_ovc_grant_o & ~smart_single_flit_pck_o;



	
//mask the available SS OVC for local requests allocation if the following conditions met
assign smart_mask_available_ss_ovc_o = smart_hdr_flit_req & ~ovc_locally_requested & condition2;
	
	
pronoc_register #(.W(1)) credit(.in(smart_buff_space_decreased_o), .reset(reset), .clk(clk), .out(smart_credit_o));
	
endmodule
	
	
	
module smart_allocator_per_iport # (
	parameter NOC_ID=0,
	parameter P=5,
	parameter SW_LOC=0,
	parameter SS_PORT_LOC=1
) (
	//general
	clk,
	reset,
	current_r_addr_i,
	neighbors_r_addr_i,
	//smart_chanel & flit in
	smart_chanel_i,
	flit_chanel_i,
	//router status signals
	ivc_info,			
	ss_ovc_info,
	ovc_locally_requested,//make sure no conflict is existed between local & SMART VC allocation
	ss_port_link_reg_flit_wr,
	ss_smart_chanel_new,
	//output
	smart_destport_o,
	smart_lk_destport_o,
	smart_ivc_smart_en_o,              		
	smart_credit_o,             	
	smart_buff_space_decreased_o, 
	smart_ss_ovc_is_allocated_o,     
	smart_ss_ovc_is_released_o, 
	smart_ivc_num_getting_ovc_grant_o,
	smart_ivc_reset_o,
	smart_mask_available_ss_ovc_o,
	smart_hdr_flit_req_o,
	smart_ivc_granted_ovc_num_o,	
	smart_ivc_single_flit_pck_o,
	smart_ovc_single_flit_pck_o
);
	
	`NOC_CONF

	//general
 	input clk, reset;
 	input [RAw-1   :0]  current_r_addr_i;
 	input [RAw-1:  0]  neighbors_r_addr_i [P-1 : 0];	
	//channels
	input smart_chanel_t smart_chanel_i;
	input flit_chanel_t flit_chanel_i;
	//ivc
	input ivc_info_t ivc_info [V-1 : 0];
	input [V-1 : 0] ovc_locally_requested;
	//ss port
	input ovc_info_t   ss_ovc_info [V-1 : 0];
	input ss_port_link_reg_flit_wr;	
	input smart_chanel_t ss_smart_chanel_new;
	//output
	output [DSTPw-1 : 0] smart_destport_o,smart_lk_destport_o;
	output smart_hdr_flit_req_o;
	output [V-1 : 0] 
		smart_ivc_smart_en_o,              		
		smart_credit_o,             	
		smart_buff_space_decreased_o, 
		smart_ss_ovc_is_allocated_o,     
		smart_ss_ovc_is_released_o, 
		smart_mask_available_ss_ovc_o,
		smart_ivc_num_getting_ovc_grant_o,
		smart_ivc_reset_o,		
		smart_ivc_single_flit_pck_o,
		smart_ovc_single_flit_pck_o;	
	output [V*V-1 : 0] smart_ivc_granted_ovc_num_o;
	
	assign smart_ovc_single_flit_pck_o = smart_ivc_single_flit_pck_o;
	wire  [DSTPw-1  :   0]  destport,lkdestport;
	wire  goes_straight;
	
	
	
	/* verilator lint_off WIDTH */ 
	localparam  LOCATED_IN_NI=  
		(TOPOLOGY=="RING" || TOPOLOGY=="LINE") ? (SW_LOC == 0 || SW_LOC>2) :
		(TOPOLOGY =="MESH" || TOPOLOGY=="TORUS" || TOPOLOGY == "FMESH")? (SW_LOC == 0 || SW_LOC>4) : 0;
	/* verilator lint_on WIDTH */ 
	
	// does the route computation for the current router
	conventional_routing #(
		.NOC_ID          (NOC_ID),
		.TOPOLOGY        (TOPOLOGY), 
		.ROUTE_NAME      (ROUTE_NAME), 
		.ROUTE_TYPE      (ROUTE_TYPE), 
		.T1              (T1), 
		.T2              (T2), 
		.T3              (T3), 
		.RAw             (RAw), 
		.EAw             (EAw), 
		.DSTPw           (DSTPw),
		.LOCATED_IN_NI   (LOCATED_IN_NI)
	) routing (
		.reset           (reset), 
		.clk             (clk), 
		.current_r_addr  (current_r_addr_i), 
		.src_e_addr  	 (			),// needed only for custom routing
		.dest_e_addr     (smart_chanel_i.dest_e_addr), 
		.destport        (destport)
	); 
	
	pronoc_register #(.W(DSTPw)) reg1 (.in(destport), .reset(reset), .clk(clk), .out(smart_destport_o));
	
	check_straight_oport #(
		.TOPOLOGY      ( TOPOLOGY),
		.ROUTE_NAME    ( ROUTE_NAME),
		.ROUTE_TYPE    ( ROUTE_TYPE),
		.DSTPw         ( DSTPw),
		.SS_PORT_LOC   ( SS_PORT_LOC)
	) check_straight (
		.destport_coded_i (destport),
		.goes_straight_o  (goes_straight)
	);   
	
	//look ahead routing. take straight next router address as input
	conventional_routing #(
			.NOC_ID(NOC_ID),
			.TOPOLOGY        (TOPOLOGY), 
			.ROUTE_NAME      (ROUTE_NAME), 
			.ROUTE_TYPE      (ROUTE_TYPE), 
			.T1              (T1), 
			.T2              (T2), 
			.T3              (T3), 
			.RAw             (RAw), 
			.EAw             (EAw), 
			.DSTPw           (DSTPw),
			.LOCATED_IN_NI   (LOCATED_IN_NI)
		) lkrouting (
			.reset           (reset), 
			.clk             (clk), 
			.current_r_addr  (neighbors_r_addr_i[SS_PORT_LOC]), 
			.src_e_addr  	 (			),// needed only for custom routing
			.dest_e_addr     (smart_chanel_i.dest_e_addr), 
			.destport        (lkdestport)
		); 
	
	pronoc_register #(.W(DSTPw)) reg2 (.in(lkdestport), .reset(reset), .clk(clk), .out(smart_lk_destport_o));
	
	wire [V-1 : 0] ss_ovc_crossbar_wr;//If asserted, a flit will be injected to ovc at next clk cycle 
	assign ss_ovc_crossbar_wr = (ss_smart_chanel_new.requests[0]) ? ss_smart_chanel_new.ovc : {V{1'b0}};
	
		
	
	//assign smart_ivc_num_getting_ovc_grant_o = smart_ss_ovc_is_allocated_o;
	//assign smart_ivc_reset_o = smart_ss_ovc_is_released_o;
	
	genvar i,j;
	generate
	for (i=0;i<V; i=i+1) begin : vc
		smart_validity_check_per_ivc #(
			.NOC_ID(NOC_ID),
			.IVC_NUM(i)		
		) validity_check (
			.reset                       (reset), 
			.clk                         (clk), 
			.goes_straight				 (goes_straight),
			.smart_requests_i              (smart_chanel_i.requests[0] 		), 
			.smart_ivc_i                   (smart_chanel_i.ovc  [i]    		),
			.smart_hdr_flit				 (smart_chanel_i.hdr_flit),
						
			.flit_hdr_flag_i         	(flit_chanel_i.flit.hdr_flag),
			.flit_tail_flag_i        	(flit_chanel_i.flit.tail_flag),
			.flit_wr_i               	(flit_chanel_i.flit_wr),
				
			.ovc_locally_requested      (ovc_locally_requested[i]	), 
						
			.assigned_to_ss_ovc          (ivc_info[i].assigned_ovc_num[i]),
			.assigned_ovc_not_full       (~ss_ovc_info[i].full), 
			.ovc_is_assigned             (ivc_info[i].ovc_is_assigned), 
			.ivc_request                 (ivc_info[i].ivc_req  	),
						
			.ss_ovc_avalable_in_ss_port  (ss_ovc_info[i].avalable), 
			.ss_port_link_reg_flit_wr    (ss_port_link_reg_flit_wr), 
			.ss_ovc_crossbar_wr          (ss_ovc_crossbar_wr[i]),	
			
			.smart_single_flit_pck_o       (smart_ivc_single_flit_pck_o[i]),
			.smart_ivc_smart_en_o      		 (smart_ivc_smart_en_o[i]	),
			.smart_credit_o             	 (smart_credit_o[i]), 
			.smart_buff_space_decreased_o  (smart_buff_space_decreased_o[i]), 
			.smart_ss_ovc_is_allocated_o   (smart_ss_ovc_is_allocated_o[i]), 
			.smart_ss_ovc_is_released_o    (smart_ss_ovc_is_released_o[i]),
			.smart_mask_available_ss_ovc_o (smart_mask_available_ss_ovc_o[i]),
			.smart_ivc_num_getting_ovc_grant_o(smart_ivc_num_getting_ovc_grant_o[i]),
			.smart_ivc_reset_o			 (smart_ivc_reset_o[i]),			
			.smart_ivc_granted_ovc_num_o   (smart_ivc_granted_ovc_num_o[(i+1)*V-1 : i*V])
		);	
				
		
		
		
		
	end//for
	endgenerate	
	
	
	pronoc_register #(.W(1)) reg3 (.in(smart_chanel_i.hdr_flit), .reset(reset), .clk(clk), .out(smart_hdr_flit_req_o));
	
endmodule	
 
//
module smart_credit_manage #(
	parameter V=4,	
	parameter B=2
	)(
		credit_in,
		smart_credit_in,
		credit_out,
		reset,
		clk
	);
	localparam Bw=$clog2(B);
		
 	input [V-1 : 0]  credit_in, smart_credit_in;
 	input reset,	clk;
 	output [V-1 : 0]  credit_out;
	genvar i;
	generate 
	for (i=0;i<V;i=i+1)begin :v_
	 	smart_credit_manage_per_vc #(
	 		.Bw(Bw)
	 		)credit(
	 			.credit_in(credit_in[i]),
	 			.smart_credit_in(smart_credit_in[i]),
	 			.credit_out(credit_out[i]),
	 			.reset(reset),
	 			.clk(clk)
	 		);
	end
	endgenerate	
endmodule	
	
module smart_credit_manage_per_vc #(
		parameter Bw=2
)(
	credit_in,
	smart_credit_in,
	credit_out,
	reset,
	clk
);

 	input credit_in, smart_credit_in,	reset,	clk;
 	output credit_out;

 	logic [Bw : 0] counter, counter_next;
 	
 	always @(*) begin 
 		counter_next=counter;
 		if(credit_in & 	smart_credit_in) counter_next = counter +1'b1;
 		else if(credit_in |	smart_credit_in) counter_next=counter;
 		else if(counter > 0) counter_next = counter -1'b1;
 	end

 	assign credit_out = credit_in | 	smart_credit_in | (counter > 0);

 	pronoc_register #(.W(Bw+1)) reg1 (.in(counter_next), .reset(reset), .clk(clk), .out(counter));
 	

endmodule

 

 
 
 
 
 
 
 
 
 
 
 

	


