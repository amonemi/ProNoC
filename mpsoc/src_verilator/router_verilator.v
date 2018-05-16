module router_verilator
(
	current_x,
	current_y,
	
	flit_in_all,
	flit_in_we_all,
	credit_out_all,
	congestion_in_all,
	//iport_weight_in_all,
    
	flit_out_all,
	flit_out_we_all,
	credit_in_all,
	congestion_out_all,
	//iport_weight_out_all,

	clk,reset

);

   


    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
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
                      (CONGESTION_INDEX==10)? 4:
                      (CONGESTION_INDEX==12)? 3:2;


	localparam
        Xw = log2(NX),
        Yw = log2(NY),
        PV = V * P,
        P_1 = P-1,
        Fw = 2+V+Fpay,	//flit width;
        PFw = P * Fw,
        CONG_ALw = CONGw * P,    //  congestion width per router      
        W = WEIGHTw,
        WP = W * P;  

    input  [Xw-1        :	0]	current_x;
    input  [Yw-1        :	0]	current_y;
    
    input  [PFw-1       :	0]	flit_in_all;
	input  [P-1         :	0]	flit_in_we_all;
	output [PV-1        :	0]	credit_out_all;
    input  [CONG_ALw-1  :   0]  congestion_in_all;
   // input  [WP-1        :   0]  iport_weight_in_all;
     
	output [PFw-1		:	0]	flit_out_all;
	output [P-1			:	0]	flit_out_we_all;
    input  [PV-1        :	0]	credit_in_all;
    output [CONG_ALw-1  :   0]  congestion_out_all;
 //   output [WP-1        :   0]  iport_weight_out_all;

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
        .ADD_PIPREG_AFTER_CROSSBAR(ADD_PIPREG_AFTER_CROSSBAR),
        .CVw(CVw),
        .CLASS_SETTING(CLASS_SETTING),   
        .ESCAP_VC_MASK(ESCAP_VC_MASK),
        .SSA_EN(SSA_EN),
        .SWA_ARBITER_TYPE(SWA_ARBITER_TYPE),
        .WEIGHTw(WEIGHTw) 
       
        
	)
	the_router
	(
		.current_x(current_x),
		.current_y(current_y),
		.flit_in_all(flit_in_all),
		.flit_in_we_all(flit_in_we_all),
		.credit_out_all(credit_out_all),
		.congestion_in_all(congestion_in_all),
	//	.iport_weight_in_all(iport_weight_in_all),
		.flit_out_all(flit_out_all),
		.flit_out_we_all(flit_out_we_all),
		.credit_in_all(credit_in_all),
		.congestion_out_all(congestion_out_all),
	//	.iport_weight_out_all(iport_weight_out_all),
		.clk(clk),
		.reset(reset)

	);
endmodule






