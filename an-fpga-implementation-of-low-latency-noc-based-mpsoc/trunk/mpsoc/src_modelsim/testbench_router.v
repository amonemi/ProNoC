`timescale	 1ns/1ps


module testbench_router;


	parameter V 		= 4, 	// V
				 P			= 5, 	// router port num
				 B 		= 4, 	// buffer space :flit per VC 
				 NX		= 4,	// number of node in x axis
				 NY		= 4,	// number of node in y axis
				 X			= 2,	//router x addr
				 Y			= 2,	// router y addr
				 C			= 4,	//	number of flit class 
				 Fpay 	= 32,
				 MUX_TYPE="ONE_HOT",	//"ONE_HOT" or "BINARY"
				 VC_REALLOCATION_TYPE	=	"NONATOMIC",// "ATOMIC" , "NONATOMIC"
				 COMBINATION_TYPE= "BASELINE",// "BASELINE", "COMB_SPEC1", "COMB_SPEC2", "COMB_NONSPEC"
				 TOTAL_PKT_PER_PORT		=	100;
				
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
					
	
	
	reg										clk;
	reg										reset;
	reg 										report;
	reg [Pw-1						:0]	P_bin	[P-1	:	0];
	reg [CLASS_IN_HDR_WIDTH-1	:0]	C_bin	[P-1	:	0];
	reg [P-1							:0]	inject_en;

	
	
	
	wire [31							:0]	 time_stamp 		[P-1		:	0];
	wire [31							:0]	 distance			[P-1		:	0]; 
	
	// router_pck_gen interfaces
	wire	[Fw-1						:0] 	gen_flit_out		[P-1		:	0];     
	wire    			   					gen_flit_out_wr	[P-1		:	0];        
	wire 	[V-1						:0]	gen_credit_in		[P-1		:	0];     
	
	wire	[Fw-1						:0] 	gen_flit_in			[P-1		:	0];        
	wire 	    			   				gen_flit_in_wr		[P-1		:	0];        
	wire	[V-1						:0]	gen_credit_out		[P-1		:	0];   
	
	wire	[P-1						:0]	flit_in_we_all;
	wire	[PFw-1					:0]	flit_in_all;
	wire	[PV-1						:0]	credit_out_all;
	wire	[P-1						:0]	flit_out_we_all;
	wire	[PFw-1					:0]	flit_out_all;
	wire	[PV-1						:0]	credit_in_all;
	
	
	wire	[P-1						:0]	sent_done;     
	wire 	[P-1						:0]   update ;  

	integer 									pck_counter			[P-1		:	0];
	reg	[P-1						:0]	done,done_reg;
	reg 										count_en;
	wire 										all_generator_done;
	reg										start;
	reg 	[15						:0]	pck_size				[P-1			:0];
	wire 	[Pw-1						:0] 	rnd_port 			[P-1			:0];
	wire	[CLASS_IN_HDR_WIDTH-1:0]	rnd_class			[P-1			:0];
	
	
	
	
	
	
	
	
	router # (
		.V							(V),
		.P							(P),
		.B 						(B), 
		.NX						(NX),
		.NY						(NY),
		.X							(X),	
		.Y							(Y),	
		.C							(C),	
		.Fpay 					(Fpay),	
		.VC_REALLOCATION_TYPE(VC_REALLOCATION_TYPE),
		.COMBINATION_TYPE		(COMBINATION_TYPE),
		.MUX_TYPE				(MUX_TYPE)
	
	)
	router
	(
		.flit_in_all			(flit_in_all),
		.flit_in_we_all		(flit_in_we_all),
		.credit_out_all		(credit_out_all),
		
		.flit_out_all			(flit_out_all),
		.flit_out_we_all		(flit_out_we_all),
		.credit_in_all			(credit_in_all),
		
		.clk						(clk),
		.reset					(reset)

	);



localparam NUM_WIDTH = log2(TOTAL_PKT_PER_PORT);

genvar i;
generate
for (i=0;i<P; i=i+1'b1) begin :lp

	router_pck_gen #(
		.V 			(V),
		.Fpay 		(Fpay ),
		.B 			(B),
		.SW_LOC		(i),
		.P				(P),
		.NX			(5),
		.NY			(5),
		.X				(0),
		.Y				(0)	
		
	)
	pck_gen_inst
	(
		.reset			(reset) ,	// input  reset
		.clk				(clk) ,	// input  clk
		.inject_en		(inject_en[i]) ,	// input  inject_en
		.pck_size		(pck_size[i]) ,	// input [15:0] pck_size
		.wr_des_x_addr		(4'd0) ,	// input [3:0] des_x_addr
		.wr_des_y_addr		(4'd1) ,	// input [3:0] des_y_addr
		.update			(update[i]) ,	// output  update
		.time_stamp		(time_stamp[i]) ,	// output [31:0] time_stamp
		//.distance(distance[i]) ,	// output [31:0] distance
		.flit_out		(gen_flit_out[i]) ,	// output [Fw-1:0] flit_out
		.flit_out_wr	(gen_flit_out_wr[i]) ,	// output  flit_out_wr
		.credit_in		(gen_credit_in[i]) ,	// input [V-1:0] credit_in
		.flit_in			(gen_flit_in[i]) ,	// input [Fw-1:0] flit_in
		.flit_in_wr		(gen_flit_in_wr[i]) ,	// input  flit_in_wr
		.credit_out		(gen_credit_out[i]) ,	// output [V-1:0] credit_out
		.sent_done		(sent_done[i]) ,	// output  sent_done
		.report			(report) ,	// input  report
		.P_bin			(P_bin[i]), 	// input [LK_PORT_SEL_WIDTH-1:0] port_sel
		.wr_class_hdr	(C_bin[i])
	);

	pseudo_random_no_core #(
		.MAX_RND		(P-1	),
		.MAX_CORE	(P-1	),
		.MAX_NUM 	(TOTAL_PKT_PER_PORT)
	)rnd_port_gen
	(
		.core		(i[Pw-1	:0]),
		.num		(pck_counter[i][NUM_WIDTH-1	:0]),
		.rnd		(rnd_port [i]),
		.rnd_en	(1'b1),
		.reset	(reset),
		.clk		(clk)
	);
	
	pseudo_random #(
		.MAX_RND		(V),
		.MAX_CORE 	(V),
		.MAX_NUM 	(TOTAL_PKT_PER_PORT)
	)
	rnd_gen
	(
	
		.core		(i[Pw-1	:0]),
		.num		(pck_counter[i][NUM_WIDTH-1	:0]),
		.rnd		(rnd_class [i]),
		.rnd_en	(1'b1),
		.reset	(reset),
		.clk		(clk)
	

);
	

	assign  	flit_in_all[(i+1)*Fw-1		:	i*Fw] = gen_flit_out [i];
	assign 	flit_in_we_all[i]= gen_flit_out_wr[i];
	assign	gen_credit_in[i]= credit_out_all[(i+1)*V-1:	i*V];
	
	assign  	gen_flit_in [i] = flit_out_all[(i+1)*Fw-1		:	i*Fw];
	assign 	gen_flit_in_wr[i] =flit_out_we_all[i];
	assign	credit_in_all[(i+1)*V-1:	i*V]= gen_credit_out[i];
		
	
end

endgenerate

//synthesis translate_off 
assign all_generator_done = &done;
initial begin 
	clk =0;
	forever clk= #10 ~clk;
end

initial begin 
	reset =1;
	start =0;
	#100 
	@(posedge clk) reset =0;
	#100 
	@(posedge clk) start =1;
	@(posedge clk) start =0;
end
//synthesis translate_on
reg [31	:	0] clk_counter;

always @ (posedge clk or posedge reset)begin 
	if			(reset	) begin clk_counter  <= 0; done_reg <= 0; end
	else  begin 
		if	(count_en) clk_counter	<= clk_counter+1'b1;	
		done_reg <= done; 
	end
end

always @(posedge	clk) begin 
		if (reset) count_en <=1'b0;
		else if(start) count_en <=1'b1;
		else if(all_generator_done) count_en <=1'b0;
	end

//synthesis translate_off 

initial begin 
report =1'b0;
#200

 @(posedge  all_generator_done);
#100
@(posedge clk) report =1'b1;
@(posedge clk) report =1'b0;

	


end
	
	
	parameter ST_NUMBER	=	5;
	parameter IDEAL_ST 	=	1;
	parameter WARM_UP		=	2;
	parameter SEND_ST 	=	4;
	parameter DELAY_ST 	=	8;
	parameter END_ST 		=	16;
	
	reg[ST_NUMBER-1:0] ps [P-1	:0];
	
	integer clk_delay_counter [P-1 :0];
	reg[8	:0] rndnum_loc [P-1 :0];


task automatic send_packet;
		input 			send_start;
		input integer 	core_num;
		input integer 	P_i;
		input integer  C_i;
		input integer	size;
		input integer	pck_num;
		input integer	clk_delay;
	
		//reg core_num;
		//reg [ST_NUMBER-1:0] ps;
		
		begin 
		if(reset) begin 
			ps[core_num]<=IDEAL_ST;
			inject_en	[core_num]	<= 1'b0;
			clk_delay_counter[core_num]<=0;
			done[core_num] <= 1'b0;
			pck_counter[core_num]<= 0;
			rndnum_loc[core_num] <= core_num*20;
			clk_delay_counter[core_num]<= X+Y+2;
		end else begin 
			case(ps[core_num]) 
				IDEAL_ST:  begin 
					inject_en	[core_num]	<= 1'b0;
					pck_size		[core_num]	<= size;
					P_bin[core_num]	<= P_i;
					C_bin[core_num]	<= C_i;
					ps[core_num]<=IDEAL_ST;
					if(send_start) begin 
						ps[core_num]<=WARM_UP;
					end
				end
				WARM_UP: begin 
					clk_delay_counter[core_num]<=clk_delay_counter[core_num]-1'b1;
					if(clk_delay_counter[core_num]==0) ps[core_num]<=SEND_ST;
				end
				SEND_ST: begin 
					done[core_num] <= 1'b0;
					inject_en	[core_num]	<= 1'b1;
					clk_delay_counter[core_num] <=0;
					if( sent_done[core_num] )begin 
					  	pck_counter[core_num] <= pck_counter[core_num]+1'b1;
						if(pck_counter[core_num]==pck_num-1'b1) begin 
						  ps[core_num] <= END_ST;
						  inject_en	[core_num]	<= 1'b0;
						 end
						else if(clk_delay>0) begin 
							inject_en	[core_num]	<= 1'b0;
							ps[core_num] <= DELAY_ST;
							rndnum_loc[core_num] <= rndnum_loc[core_num]+1'b1; 
						end
					end
				end
				DELAY_ST: begin 
					inject_en	[core_num]	<= 1'b0;
					clk_delay_counter[core_num] <=clk_delay_counter[core_num] +1'b1;
					if(clk_delay_counter[core_num] >= clk_delay	)
								ps[core_num]<= SEND_ST;
				end
				END_ST: begin 
					inject_en	[core_num]	<= 1'b0;
					clk_delay_counter[core_num] <=clk_delay_counter[core_num] +1'b1;
					ps[core_num]<= IDEAL_ST;
					done[core_num] <= 1'b1;
				end
				default ps[core_num]<=IDEAL_ST;
			endcase
		end//else 
	end
	endtask



	task automatic send_rnd_packet(
		input 			send_start,
		input integer 	core_num,
		input integer	size,
		input integer	pck_num,
		input integer	clk_delay
	);
		//reg core_num;
		//reg [ST_NUMBER-1:0] ps;
		
		begin 
		if(reset) begin 
			ps[core_num]<=IDEAL_ST;
			inject_en	[core_num]	<= 1'b0;
			clk_delay_counter[core_num]<=0;
			done[core_num] <= 1'b0;
			pck_counter[core_num]<= 0;
			rndnum_loc[core_num] <= core_num*20;
			clk_delay_counter[core_num]<= X+Y+2;
		end else begin 
			case(ps[core_num]) 
				IDEAL_ST:  begin 
					inject_en	[core_num]	<= 1'b0;
					pck_size		[core_num]	<= size;
					
					P_bin[core_num]	<=  rnd_port [core_num];
					C_bin[core_num]	<=  rnd_class[core_num];
					ps[core_num]<=IDEAL_ST;
					if(send_start) begin 
						ps[core_num]<=WARM_UP;
					end
				end
				WARM_UP: begin 
					clk_delay_counter[core_num]<=clk_delay_counter[core_num]-1'b1;
					if(clk_delay_counter[core_num]==0) ps[core_num]<=SEND_ST;
				end
				SEND_ST: begin 
					done[core_num] <= 1'b0;
					inject_en	[core_num]	<= 1'b1;
					clk_delay_counter[core_num] <=0;
					if( sent_done[core_num] )begin 
						P_bin[core_num]	<=  rnd_port [core_num];
						C_bin[core_num]	<=  rnd_class [core_num];
					  	pck_counter[core_num] <= pck_counter[core_num]+1'b1;
						if(pck_counter[core_num]==pck_num-1'b1) begin 
						  ps[core_num] <= END_ST;
						  inject_en	[core_num]	<= 1'b0;
						end
						else if(clk_delay>0) begin 
							inject_en	[core_num]	<= 1'b0;
							ps[core_num] <= DELAY_ST;
							rndnum_loc[core_num] <= rndnum_loc[core_num]+1'b1; 
						end
					end
				end
				DELAY_ST: begin 
					inject_en	[core_num]	<= 1'b0;
					clk_delay_counter[core_num] <=clk_delay_counter[core_num] +1'b1;
					if(clk_delay_counter[core_num] >= clk_delay	)
								ps[core_num]<= SEND_ST;
				end
				END_ST: begin 
					inject_en	[core_num]	<= 1'b0;
					clk_delay_counter[core_num] <=clk_delay_counter[core_num] +1'b1;
					ps[core_num]<= IDEAL_ST;
					done[core_num] <= 1'b1;
				end
				default ps[core_num]<=IDEAL_ST;
			endcase
		end//else 
	end
	endtask

	


generate 
	for(i=0;i<P;i=i+1'b1 ) begin :loo
		always @(posedge clk) begin send_rnd_packet(start,i, 5, 1000, 0);  end 		
	end//for
endgenerate


/*
generate 
	for(i=0;i<P;i=i+1'b1 ) begin :loo
		if (i==0 )always @(posedge clk) begin send_packet(start,i,3,1, 5, 1000, 0);  end 
		else if (i==1 )always @(posedge clk) begin send_packet(start,i,3,2, 5, 1000, 0);  end 
		else if (i==2 )always @(posedge clk) begin send_packet(start,i,3,2, 5, 1000, 0);  end 
		else if (i==4 )always @(posedge clk) begin send_packet(start,i,3,1, 5, 1000, 0);  end 
		else always @(posedge clk) begin send_packet(0,i,0,1, 5, 1000, 0);  end 
	end//for
endgenerate
*/

//synthesis translate_on



endmodule










