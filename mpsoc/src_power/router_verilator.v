module router_verilator	
(
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

  function integer CORE_NUM;
        input integer x,y;
        begin
            CORE_NUM = ((y * NX) +  x);
        end
    endfunction

    `define   INCLUDE_PARAM
	`include "parameter.v"

    localparam CONGw= (CONGESTION_INDEX==3)?  3:
                      (CONGESTION_INDEX==5)?  3:
                      (CONGESTION_INDEX==7)?  3:
                      (CONGESTION_INDEX==9)?  3:
                      (CONGESTION_INDEX==10)? 4:2;


	localparam 	Xw		= 	log2(NX),
				Yw		=  log2(NY),
                PV		=	V		*	P,
                P_1     =	P-1,
                Fw      =	2+V+Fpay,	//flit width;
                PFw		=	P*Fw,
                CONG_ALw=   CONGw* P;    //  congestion width per router      


    input  [Xw-1        :	0]	current_x;
    input  [Yw-1        :	0]	current_y;
    
    input  [PFw-1       :	0]	flit_in_all;
	input  [P-1         :	0]	flit_in_we_all;
	output [PV-1        :	0]	credit_out_all;
    input  [CONG_ALw-1  :   0]  congestion_in_all;
    
	output [PFw-1		:	0]	flit_out_all;
	output [P-1			:	0]	flit_out_we_all;
    input  [PV-1        :	0]	credit_in_all;
    output [CONG_ALw-1  :   0]  congestion_out_all;

	input clk,reset;

   

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
        .ROUTE_TYPE(ROUTE_TYPE),
        .ROUTE_NAME(ROUTE_NAME),  
        .ROUTE_SUBFUNC(ROUTE_SUBFUNC),
        .AVC_ATOMIC_EN(AVC_ATOMIC_EN),
        .CONGESTION_INDEX(CONGESTION_INDEX),
        .CONGw(CONGw),
        .DEBUG_EN(DEBUG_EN),
 	.CVw(CVw),
    	.CLASS_SETTING(CLASS_SETTING), // shows how each class can use VCs   
    	.ESCAP_VC_MASK(ESCAP_VC_MASK)  // mask scape vc, valid only for full adaptive  
        
	)
	the_router
	(
		.current_x(current_x),
        .current_y(current_y),
		.flit_in_all(flit_in_all),
		.flit_in_we_all(flit_in_we_all),
		.credit_out_all(credit_out_all),
		.congestion_in_all(congestion_in_all),
		.flit_out_all(flit_out_all),
		.flit_out_we_all(flit_out_we_all),
		.credit_in_all(credit_in_all),
		.congestion_out_all(congestion_out_all),
		.clk(clk),
		.reset(reset)

	);

integer fp;
    
    

reg [31:0] counter,last_counter;
reg [P-1         :	0]	last_flit_in_we_all;
reg [PV-1         :	0]	last_credit_in_all;
reg [PFw-1       :	0]	last_flit_in_all;

	always @(posedge clk or posedge reset) begin 
		if(reset) begin 
			counter		<= 32'd0;
			last_counter	<= 32'd0;
			last_flit_in_we_all <= {P{1'b0}};
			last_credit_in_all <= {PV{1'b0}};
			last_flit_in_all <= {PFw{1'b0}};

			if((current_x==4) && (current_y==4)) begin 
 `ifndef verilator       
        			fp = $fopen("Result.txt");
  `else
   			     	fp = $fopen("Result.txt","w");
   `endif  
	end
		end
		else begin
			if((current_x==4) && (current_y==4)) begin 
				counter	<= counter +1'b1;
				if((flit_in_we_all!=last_flit_in_we_all )||(last_flit_in_all !== flit_in_all) || (credit_in_all !=last_credit_in_all) )begin
	if((counter-last_counter)!=0)$fwrite(fp,"repeat(%d)begin  @(posedge clk) #10;  end\n",((counter-last_counter)));
	last_counter<=counter;

end




				if(flit_in_we_all!=last_flit_in_we_all)begin 
					$fwrite(fp,"\tflit_in_we_all  =%d'h%h; \n",P,flit_in_we_all);
					last_flit_in_we_all<=flit_in_we_all;	

				end
				if(last_flit_in_all !== flit_in_all) begin
					$fwrite(fp,"\tflit_in_all  =%d'h%h; \n",PFw,flit_in_all);	
					last_flit_in_all <=flit_in_all;

				end
				if (credit_in_all !=last_credit_in_all) begin
					$fwrite(fp,"\tcredit_in_all  =%d'h%h; \n",PV,credit_in_all);	
					last_credit_in_all<=credit_in_all;

				end
			end

		end	
	 if((flit_in_we_all!=last_flit_in_we_all )||(last_flit_in_all !== flit_in_all) || (credit_in_all !=last_credit_in_all) )$fflush(fp);

	end  
	

endmodule






