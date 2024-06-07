// synthesis translate_off
`include "pronoc_def.v"

module pck_injector_test;
	parameter NOC_ID=0;
    `NOC_CONF
	
	reg     reset ,clk;
	
	initial begin 
		clk = 1'b0;
		forever clk = #10 ~clk;
	end 

	initial begin 
`ifdef ACTIVE_LOW_RESET_MODE 
        	reset = 1'b0;
 `else 
        	reset = 1'b1;
`endif  
		#110;
        	@(posedge clk) #1;
		reset=~reset;
	end
	
	
       smartflit_chanel_t chan_in_all  [NE-1 : 0];
	smartflit_chanel_t chan_out_all [NE-1 : 0];
	
	pck_injct_t pck_injct_in [NE-1 : 0];
	pck_injct_t pck_injct_out[NE-1 : 0];	
	noc_top  # ( 
		.NOC_ID(NOC_ID)
	) the_noc (
		.reset(reset),
		.clk(clk),    
		.chan_in_all(chan_in_all),
		.chan_out_all(chan_out_all),
		.router_event( )
	);
		
	reg  [NEw-1 : 0] dest_id [NE-1 : 0];
	wire [NEw-1 : 0] src_id  [NE-1 : 0];
	wire [NEw-1: 0] current_e_addr [NE-1 : 0];
		
	genvar i;
	generate 
	for(i=0; i< NE; i=i+1) begin : endpoints
		
		endp_addr_encoder #( .TOPOLOGY(TOPOLOGY), .T1(T1), .T2(T2), .T3(T3), .EAw(EAw),  .NE(NE)) encode1 ( .id(i[NEw-1 :0]), .code(current_e_addr[i]));
		
		packet_injector #(
			.NOC_ID(NOC_ID)
		) pck_inj (
			//general
			.current_e_addr(current_e_addr[i]),
			.reset(reset),
			.clk(clk),		
   			//noc port
			.chan_in(chan_out_all[i]),
			.chan_out(chan_in_all[i]),  
			//control interafce
			.pck_injct_in(pck_injct_in[i]),
			.pck_injct_out(pck_injct_out[i])		
		);			
	

		endp_addr_encoder #( .TOPOLOGY(TOPOLOGY), .T1(T1), .T2(T2), .T3(T3), .EAw(EAw),  .NE(NE)) encode2 ( .id(dest_id[i]), .code(pck_injct_in[i].endp_addr));
		
		
	   reg [31:0]k;

		initial begin 
			k=0;
			pck_injct_in[i].data =0;
			#10
			pck_injct_in[i].class_num=0; 
			pck_injct_in[i].init_weight=1;
			pck_injct_in[i].vc=1;
			pck_injct_in[i].pck_wr=1'b0; 
			#100;
			@(posedge clk) #1;
			#100;
			@(posedge clk) #1;
			if(i==1) begin 
				repeat(10) begin 
					while (pck_injct_out[i].ready[0] == 1'b0) @(posedge clk)   #1;
						
					pck_injct_in[i].data='h123456789ABCDEFEDCBA987654321+k;
					pck_injct_in[i].size=3+(k%18);
					dest_id[i]=0;				
					pck_injct_in[i].pck_wr=1'b1;  	
					@(posedge clk)	#1 k++;
					pck_injct_in[i].pck_wr=1'b0;
					@(posedge clk)	#1 k++;

				end

				#8000
			@(posedge clk) $stop;

			end
			
			
			
			
			
			
		end
		
		endp_addr_decoder  #(   .TOPOLOGY(TOPOLOGY), .T1(T1), .T2(T2), .T3(T3), .EAw(EAw),  .NE(NE)) decode1 ( .id(src_id[i]), .code(pck_injct_out[i].endp_addr));    
		
		always @(posedge clk) begin
			if(pck_injct_out[i].pck_wr) begin 
				$display ("%t:pck_inj(%d) got a packet from source_id=%d, with size=%d flits and data=%h",$time,i,
						src_id[i],pck_injct_out[i].size,pck_injct_out[i].data);
			end		
			
		end
		
	
	  
	end//for
	endgenerate
       
	



	
	

	
	

endmodule
// synthesis translate_on

