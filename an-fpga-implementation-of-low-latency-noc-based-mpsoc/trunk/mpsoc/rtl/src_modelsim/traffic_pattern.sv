/**************************************
* Module: traffic_pattern
* Date:2015-10-05  
* Author: alireza     
*
* Description: 
***************************************/

`timescale  1ns/1ps


 
/************************************

        pck_class_in_gen

***********************************/ 
 
module pck_class_in_gen #(
    parameter C = 4,    //  number of packet class 
    parameter C0_p = 25,    //  the percentage of injected packets with class 0 
    parameter C1_p = 25,
    parameter C2_p = 25,
    parameter C3_p = 25    
)(
    pck_class_o,
    en,   
    reset,
    clk

); 
     
    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end 	   
      end   
    endfunction // log2 
     
   
    localparam 
    Cw = (C>1)? log2(C) : 1,
    RNDw = log2(100);
               
    output reg [Cw-1    :   0]  pck_class_o;
    input                       reset,clk,en;
    reg       [RNDw-1  :   0]  rnd;
   
 
   
 // generate a random num between 0 to 99
    always @(posedge clk ) begin 
    	if(en | reset) begin 
    		rnd =     $urandom_range(99,0);    		
    	end    		
    end
    
    always @(*) begin 
        if      ( rnd <   C0_p)                 pck_class_o =0;
        else if ( rnd <   (C0_p+C1_p))          pck_class_o =1;
        else if ( rnd <   (C0_p+C1_p+C2_p))     pck_class_o =2;
        else                                    pck_class_o =3;
    end
 
   
   
endmodule

/**********************************

        pck_dst_gen

*********************************/
 
 
module  pck_dst_gen  
	import pronoc_pkg::*; 	
	#(
    parameter NE=4,
    parameter TRAFFIC =   "RANDOM",
    parameter MAX_PCK_NUM = 10000,
    parameter HOTSPOT_NODE_NUM =  4
)(
    en,
    current_e_addr,
    core_num,
    pck_number,
    dest_e_addr, 
    clk,
    reset,
    valid_dst,
    hotspot_info,
	custom_traffic_t,
	custom_traffic_en
); 
 
 
    localparam      ADDR_DIMENSION =   (TOPOLOGY ==    "MESH" || TOPOLOGY ==  "TORUS") ? 2 : 1;  // "RING" and FULLY_CONNECT 
 
 
    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end 	   
      end   
    endfunction // log2 
     
     
    localparam  NEw= log2(NE),
                PCK_CNTw = log2(MAX_PCK_NUM+1),
                HOTSPOT_NUM= (TRAFFIC=="HOTSPOT")? HOTSPOT_NODE_NUM : 1;
    
    input                       reset,clk,en;
    input   [NEw-1      :   0]  core_num;
    input   [PCK_CNTw-1 :   0]  pck_number; 
    input   [EAw-1      :   0]  current_e_addr; 
    output  [EAw-1      :   0]  dest_e_addr; 
    output                      valid_dst; 
	input  [NEw-1 : 0] custom_traffic_t;
	input  custom_traffic_en;
    
    input hotspot_t  hotspot_info [HOTSPOT_NUM-1 : 0];
 
 
     generate 
     if ( ADDR_DIMENSION == 2) begin :two_dim
     
        two_dimension_pck_dst_gen #(
        	.NE(NE),
        	.TRAFFIC(TRAFFIC),
        	.MAX_PCK_NUM(MAX_PCK_NUM),
        	.HOTSPOT_NODE_NUM(HOTSPOT_NODE_NUM)
        	
        )
        the_two_dimension_pck_dst_gen
        (
        	.reset(reset),
        	.clk(clk),
        	.en(en),
        	.core_num(core_num),
        	.pck_number(pck_number),
        	.current_e_addr(current_e_addr),
            .dest_e_addr(dest_e_addr),
        	.valid_dst(valid_dst),
        	.hotspot_info(hotspot_info),
			.custom_traffic_t(custom_traffic_t),
			.custom_traffic_en(custom_traffic_en)
        );
        
     end else begin : one_dim
      
        one_dimension_pck_dst_gen #(
        		.NE(NE),
        		.TRAFFIC(TRAFFIC),
        		.MAX_PCK_NUM(MAX_PCK_NUM),
        		.HOTSPOT_NODE_NUM(HOTSPOT_NODE_NUM)
        )
        the_one_dimension_pck_dst_gen
        (
            .reset(reset),
            .clk(clk),
            .en(en),
            .core_num(core_num),
            .pck_number(pck_number),
            .current_e_addr(current_e_addr),
            .dest_e_addr(dest_e_addr),
            .valid_dst(valid_dst),
            .hotspot_info(hotspot_info),
			.custom_traffic_t(custom_traffic_t),
			.custom_traffic_en(custom_traffic_en)
        );       
       
     end     
     endgenerate 
 endmodule
 
 
 
 
module two_dimension_pck_dst_gen  
		import pronoc_pkg::*; 	
	#(
		parameter NE=4,
		parameter TRAFFIC =   "RANDOM",
		parameter MAX_PCK_NUM = 10000,
		parameter HOTSPOT_NODE_NUM =  4

)(
    en,
    current_e_addr,
    dest_e_addr,
    core_num,
    pck_number,
    clk,
    reset,
    valid_dst,
    hotspot_info,
	custom_traffic_t,
	custom_traffic_en
);    
    
   
    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end 	   
      end   
    endfunction // log2 
     
     
    localparam NEw= log2(NE),
                PCK_CNTw = log2(MAX_PCK_NUM+1),
                HOTSPOT_NUM= (TRAFFIC=="HOTSPOT")? HOTSPOT_NODE_NUM : 1;
    
    input                       reset,clk,en;
    input   [NEw-1      :   0]  core_num;
    input   [PCK_CNTw-1 :   0]  pck_number; 
    input   [EAw-1 : 0] current_e_addr;
    output  [EAw-1 : 0]  dest_e_addr;
    output                      valid_dst;  
    input hotspot_t  hotspot_info [HOTSPOT_NUM-1 : 0];
	input  [NEw-1 : 0] custom_traffic_t;
	input  custom_traffic_en;
    
    localparam 
        NX = T1,
        NY = T2,    
        NL = T3,
        NXw = log2(NX),
        NYw= log2(NY),
        NLw= log2(NL);
    
    wire [NXw-1 : 0] current_x; 
    wire [NYw-1 : 0] current_y;  
    wire [NLw-1  : 0] current_l;    
    wire [NXw-1 : 0] dest_x; 
    wire [NYw-1 : 0] dest_y;
    wire [NLw-1  : 0] dest_l;   
        
    mesh_tori_endp_addr_decode #(
    	.TOPOLOGY(TOPOLOGY),
    	.T1(T1),
    	.T2(T2),
    	.T3(T3),
    	.EAw(EAw)
    )
    src_addr_decode
    (
    	.e_addr(current_e_addr),
    	.ex(current_x),
    	.ey(current_y),
    	.el(current_l),
    	.valid( )
    );    
    
    wire off_flag;
  
    
    
    
    
    wire    [NEw-1  :   0]  dest_ip_num;
    genvar i;
            
    generate     
    if (TRAFFIC == "RANDOM") begin 
        
    	logic [6 : 0] rnd_reg;
    
    	always @(posedge clk ) begin 
    		if(en | reset) begin 
    			rnd_reg =     $urandom_range(NE-1,0);
    			if(SELF_LOOP_EN	== "NO")	while(rnd_reg==core_num) rnd_reg =     $urandom_range(NE-1,0);// get a random IP core, make sure its not same as sender core   			
    			
     		end    		
    	end
    	assign dest_ip_num = rnd_reg;
       
       endp_addr_encoder #(
       	.T1(T1),
       	.T2(T2),
       	.T3(T3),
       	.NE(NE),
       	.EAw(EAw),
       	.TOPOLOGY(TOPOLOGY)
       )
       addr_encoder
       (
       	.id(dest_ip_num),
       	.code(dest_e_addr)
       );
           
     end else if (TRAFFIC == "HOTSPOT") begin 
                      
     	hot_spot_dest_gen  #(
     			.HOTSPOT_NUM(HOTSPOT_NUM),	
     			.NE(NE),
     			.NEw(NEw)
     		)hspot
     		(
     			.reset(reset),
     			.clk(clk),
     			.en(en),
     			.hotspot_info(hotspot_info),
     			.dest_ip_num (dest_ip_num),
     			.core_num(core_num),
     			.off_flag(off_flag)
     		);
       
        endp_addr_encoder #(
            .T1(T1),
            .T2(T2),
            .T3(T3),
            .NE(NE),
            .EAw(EAw),
            .TOPOLOGY(TOPOLOGY)
        )
        addr_encoder
        (
            .id(dest_ip_num),
            .code(dest_e_addr)
        );
   
       
        
    end else if( TRAFFIC == "TRANSPOSE1") begin 
       
        assign dest_x   = NX-current_y-1;
        assign dest_y   = NY-current_x-1;
        assign dest_l   = NL-current_l-1; 
        assign dest_e_addr = (T3==1)? {dest_y,dest_x} : {dest_l,dest_y,dest_x};
        
        endp_addr_decoder  #(
        	.T1(T1),
        	.T2(T2),
        	.T3(T3),
        	.NE(NE),
        	.EAw(EAw),
        	.TOPOLOGY(TOPOLOGY)
        )enc
        (
        	.code(dest_e_addr),
        	.id(dest_ip_num)
        );    
        
     
        
        
      
        
    end else if( TRAFFIC == "TRANSPOSE2") begin :transpose2
        
        assign dest_x   = current_y;
        assign dest_y   = current_x;
        assign dest_l   = current_l;
        assign dest_e_addr = (T3==1)? {dest_y,dest_x} : {dest_l,dest_y,dest_x};
        
        endp_addr_decoder  #(
        		.T1(T1),
        		.T2(T2),
        		.T3(T3),
        		.NE(NE),
        		.EAw(EAw),
        		.TOPOLOGY(TOPOLOGY)
        	)enc
        	(
        		.code(dest_e_addr),
        		.id(dest_ip_num)
        	);    
        
          
         
    end  else if( TRAFFIC == "BIT_REVERSE") begin :bitreverse
        
        for(i=0; i<(EAw); i=i+1'b1) begin :lp//reverse the address
            assign dest_ip_num[i]  = current_e_addr [((EAw)-1)-i];
        end
                   
        endp_addr_encoder #(
            .T1(T1),
            .T2(T2),
            .T3(T3),
            .NE(NE),
            .EAw(EAw),
            .TOPOLOGY(TOPOLOGY)
        )
        addr_encoder(
            .id(dest_ip_num),
            .code(dest_e_addr)
        ); 
              
   
    end  else if( TRAFFIC == "BIT_COMPLEMENT") begin :bitcomp

        assign dest_x   = ~current_x;
        assign dest_y   = ~current_y;  
        assign dest_l   = ~dest_l;
        assign dest_e_addr = (T3==1)? {dest_y,dest_x} : {dest_l,dest_y,dest_x};
       
        endp_addr_decoder  #(
        		.T1(T1),
        		.T2(T2),
        		.T3(T3),
        		.NE(NE),
        		.EAw(EAw),
        		.TOPOLOGY(TOPOLOGY)
        	)enc
        	(
        		.code(dest_e_addr),
        		.id(dest_ip_num)
        	);    
        
        
        
                    
    end else if( TRAFFIC == "TORNADO" ) begin :tornado
        //[(x+(k/2-1)) mod k, (y+(k/2-1)) mod k],
        assign dest_x  = (current_x> ((NX+1)/2))? current_x- ((NX+1)/2) -1   :  (NX/2)+current_x-1;  //  = ((current_x + ((NX/2)-1))%NX); 
        assign dest_y  = (current_y> ((NY+1)/2))? current_y- ((NY+1)/2) -1   :  (NY/2)+current_y-1;  //  = ((current_y + ((NY/2)-1))%NY);
        assign dest_l   = current_l;
        assign dest_e_addr = (T3==1)? {dest_y,dest_x} : {dest_l,dest_y,dest_x};
      
        endp_addr_decoder  #(
        		.T1(T1),
        		.T2(T2),
        		.T3(T3),
        		.NE(NE),
        		.EAw(EAw),
        		.TOPOLOGY(TOPOLOGY)
        	)enc
        	(
        		.code(dest_e_addr),
        		.id(dest_ip_num)
        	);    
        
        
        
   
	end else if( TRAFFIC == "NEIGHBOR")  begin :neighbor
		//dx = sx + 1 mod k
		 assign dest_x = (current_x + 1) >= NX? 0 : (current_x + 1);
		 assign dest_y = (current_y + 1) >= NY? 0 : (current_y + 1);
		 assign dest_l = current_l;
		 assign dest_e_addr = (T3==1)? {dest_y,dest_x} : {dest_l,dest_y,dest_x};
		
		 endp_addr_decoder  #(
		 		.T1(T1),
		 		.T2(T2),
		 		.T3(T3),
		 		.NE(NE),
		 		.EAw(EAw),
		 		.TOPOLOGY(TOPOLOGY)
		 	)enc
		 	(
		 		.code(dest_e_addr),
		 		.id(dest_ip_num)
		 	);    
		 
		 
		 
		 
	end else if( TRAFFIC == "SHUFFLE") begin: shuffle
		//di = si−1 mod b
		for(i=1; i<(EAw); i=i+1'b1) begin :lp//reverse the address
            assign dest_ip_num[i]  = current_e_addr [i-1];
        end
		assign dest_ip_num[0]  = current_e_addr [EAw-1];		
		 endp_addr_encoder #(
            .T1(T1),
            .T2(T2),
            .T3(T3),
            .NE(NE),
            .EAw(EAw),
            .TOPOLOGY(TOPOLOGY)
        )
        addr_encoder(
            .id(dest_ip_num),
            .code(dest_e_addr)
        );
		
		
    end else if(TRAFFIC == "BIT_ROTATION") begin :bitrot
		//di = si+1 mod b
		for(i=0; i<(EAw-1); i=i+1'b1) begin :lp//reverse the address
            assign dest_ip_num[i]  = current_e_addr [i+1];
        end
		assign dest_ip_num[EAw-1]  = current_e_addr [0];		
		endp_addr_encoder #(
            .T1(T1),
            .T2(T2),
            .T3(T3),
            .NE(NE),
            .EAw(EAw),
            .TOPOLOGY(TOPOLOGY)
        )
        addr_encoder(
            .id(dest_ip_num),
            .code(dest_e_addr)
        ); 
		
	end else if(TRAFFIC == "CUSTOM" )begin 
		
        assign dest_ip_num = custom_traffic_t;
		 endp_addr_encoder #(
            .T1(T1),
            .T2(T2),
            .T3(T3),
            .NE(NE),
            .EAw(EAw),
            .TOPOLOGY(TOPOLOGY)
        )
        addr_encoder
        (
            .id(dest_ip_num),
            .code(dest_e_addr)
        );
	
		assign  off_flag  =  ~custom_traffic_en;	
		 
		      
    end  else begin 
			initial begin 
				$display("ERROR: Undefined Traffic pattern:%s",TRAFFIC);
				$stop;
			end
	end
    
    	
    	
    	wire valid_temp  =    (dest_ip_num  <= (NE-1));	
    	
    	if (TRAFFIC == "HOTSPOT" || TRAFFIC == "CUSTOM") begin 
    		assign valid_dst  = ~off_flag & valid_temp;
    	end else begin 
    		assign valid_dst  =  valid_temp;
    	end	
     
    
    endgenerate
     
endmodule



/************

************/


module one_dimension_pck_dst_gen 
import pronoc_pkg::*; 	
#(
		parameter NE=4,
		parameter TRAFFIC =   "RANDOM",
		parameter MAX_PCK_NUM = 10000,
		parameter HOTSPOT_NODE_NUM =  4

)(
    en,
    core_num,
    pck_number,
    current_e_addr,
    dest_e_addr, 
    clk,
    reset,
    valid_dst,
    hotspot_info,
	custom_traffic_t,
	custom_traffic_en
); 
      
    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end 	   
      end   
    endfunction // log2 
     
     
     localparam 
        NEw= log2(NE),
        PCK_CNTw = log2(MAX_PCK_NUM+1),
        HOTSPOT_NUM= (TRAFFIC=="HOTSPOT")? HOTSPOT_NODE_NUM : 1;
    
    input   reset,clk,en;
    input   [NEw-1 : 0] core_num;  
    input   [PCK_CNTw-1  :   0]  pck_number; 
    input   [EAw-1       :   0]  current_e_addr;     
    output  [EAw-1       :   0]  dest_e_addr;   
    output  valid_dst;  
    input hotspot_t  hotspot_info [HOTSPOT_NUM-1 : 0];
	input  [NEw-1 : 0] custom_traffic_t; 
	input  custom_traffic_en;
        
    wire [NEw-1 : 0] dest_ip_num;
    wire off_flag;
    genvar i;            
    generate     
    if (TRAFFIC == "RANDOM") begin 
    	logic [6 : 0] rnd_reg;
    
    	always @(posedge clk ) begin 
    		if(en | reset) begin 
    			rnd_reg =     $urandom_range(NE-1,0);
    			if(SELF_LOOP_EN	== "NO")	while(rnd_reg==core_num) rnd_reg =     $urandom_range(NE-1,0);// get a random IP core, make sure its not same as sender core   			
     		end    		
    	end
    	assign dest_ip_num = rnd_reg;
         
        
     end else if (TRAFFIC == "HOTSPOT") begin 
        
     	hot_spot_dest_gen  #(
     		.HOTSPOT_NUM(HOTSPOT_NUM),	
     		.NE(NE),
     		.NEw(NEw)
		)hspot
		(
     		.clk(clk),
     		.en(en),
     		.hotspot_info(hotspot_info),
     		.dest_ip_num (dest_ip_num),
     		.core_num(core_num),
     		.off_flag(off_flag)
     	);
     	
     	
       
    end else if( TRAFFIC == "TRANSPOSE1") begin :tran1
    
        assign dest_ip_num   = NE-core_num-1;                  
        
    end  else if( TRAFFIC == "BIT_REVERSE") begin :bitreverse
    
        for(i=0; i<NEw; i=i+1'b1) begin :lp//reverse the address
            assign dest_ip_num[i]  = core_num [NEw-1-i];
        end
        
    end  else if( TRAFFIC == "BIT_COMPLEMENT") begin :bitcomp
                              
            assign dest_ip_num   = ~core_num;
    
    end else if( TRAFFIC == "TORNADO" ) begin :tornado
        //[(x+(k/2-1)) mod k, (y+(k/2-1)) mod k],
          assign dest_ip_num  = (core_num > ((NE+1)/2))? core_num- ((NE+1)/2) -1   :  (NE/2)+core_num-1;  //  = ((current_x + ((NX/2)-1))%NX);
           
	end else if( TRAFFIC == "NEIGHBOR")  begin :neighbor
		//dx = sx + 1 mod k
		 assign dest_ip_num = ((core_num + 1) >= NE) ? 0 : (core_num + 1);
		
	end else if( TRAFFIC == "SHUFFLE") begin: shuffle
		//di = si−1 mod b
		for(i=1; i<(NEw); i=i+1'b1) begin :lp
            assign dest_ip_num[i]  = core_num [i-1];
        end
		assign dest_ip_num[0]  = core_num [NEw-1];				 
		
    end else if(TRAFFIC == "BIT_ROTATION") begin :bitrot
		//di = si+1 mod b
		for(i=0; i<(NEw-1); i=i+1) begin :lp//reverse the address
            assign dest_ip_num[i]  = core_num [i+1];
        end
		assign dest_ip_num[NEw-1]  = core_num [0];		
	
	end else if(TRAFFIC == "CUSTOM" )begin
		assign off_flag = ~custom_traffic_en;
         assign dest_ip_num = custom_traffic_t;
    end   
   
    endp_addr_encoder #(
        .T1(T1),
        .T2(T2),
        .T3(T3),
        .NE(NE),
        .EAw(EAw),
        .TOPOLOGY(TOPOLOGY)
    )
    addr_encoder
    (
        .id(dest_ip_num),
        .code(dest_e_addr)
    );
      
    wire valid_temp  =    (dest_ip_num  <= (NE-1));	
    	
    if (TRAFFIC == "HOTSPOT" || TRAFFIC == "CUSTOM") begin 
    	assign valid_dst  = ~off_flag & valid_temp;
    end else begin 
    	assign valid_dst  =  valid_temp;
    end
   
    endgenerate
     
endmodule
 
/***************************
 *  pck_size_gen
 * *************************/

module pck_size_gen
		import pronoc_pkg::*; 
#(
		parameter PCK_SIZw=4,
        parameter MIN = 2,
        parameter MAX = 5,
        parameter PCK_SIZ_SEL="random-discrete",	
        parameter DISCRETE_PCK_SIZ_NUM=1
)
(
    reset,
    clk,
    en,
    pck_size,
    rnd_discrete
);

	input rnd_discrete_t rnd_discrete [DISCRETE_PCK_SIZ_NUM-1: 0];
     

    input reset, clk, en;
    output [PCK_SIZw-1 : 0] pck_size;

    
    generate
	if(PCK_SIZ_SEL == "random-discrete"	) begin :discrete
		if(DISCRETE_PCK_SIZ_NUM==1) begin :single 
			assign pck_size = rnd_discrete[0].value;
		end else begin :multi
			reg [PCK_SIZw-1 : 0] rnd,rnd_next;
			integer rnd2;
			integer k;
			always @(*) begin 
				rnd_next = rnd;
				if(en) begin 
					if(rnd2 < rnd_discrete[0].percentage) rnd_next = rnd_discrete[0].value;
					for (k=1;k<DISCRETE_PCK_SIZ_NUM;k++)begin 
						if(rnd2 >= rnd_discrete[k-1].percentage && rnd2 < rnd_discrete[k].percentage) rnd_next = rnd_discrete[k].value;
					end
				end	
			end//always
			
			
			always @(posedge clk) begin 
				if(reset)  begin 
					rnd2<= 0;
					rnd <= rnd_discrete[0].value;					
				end else  begin 
					if(en) rnd2<= $urandom_range(99,0);
					rnd <= rnd_next;
				end
			end//always
			
			assign pck_size = rnd;
		end//multi
		
	end else begin :range
		if (MIN == MAX) begin :eq 
	        assign pck_size = MIN;
	    end  else begin :noteq
	        reg [PCK_SIZw-1 : 0] rnd;
	        always @(posedge clk) begin 
	            if(reset) rnd = MIN;
	            else if(en) rnd = $urandom_range(MAX,MIN);
	        end
	        assign pck_size = rnd;
	    end
	end
	endgenerate
endmodule 




module hot_spot_dest_gen 
	import pronoc_pkg::*; 
#(
	parameter HOTSPOT_NUM=2,	
	parameter NE=16,
	parameter NEw=4
)
(
clk,
reset,
en,
hotspot_info,
core_num,
dest_ip_num,
off_flag
);
	
	input clk,en,reset;
	input hotspot_t  hotspot_info [HOTSPOT_NUM-1 : 0];
	input   [NEw-1 : 0] core_num;
	output  [NEw-1 : 0] dest_ip_num;
	output reg off_flag;
	
	logic [6 : 0] rnd_reg, hotspot_node;
	reg [9 : 0] rnd1000;
	always @(posedge clk ) begin 
		if(en | reset) begin 
			rnd_reg =     $urandom_range(NE-1,0);
			if(SELF_LOOP_EN	== "NO")	while(rnd_reg==core_num) rnd_reg =     $urandom_range(NE-1,0);// get a random IP core, make sure its not same as sender core    			
     			
			rnd1000 =     $urandom_range(999,0);// generate a random number between 0 & 1000     					
		end    		
	end
     	
	logic hotspot_flag;
	integer i;
	
	always @(*)begin 
		off_flag=0;
		for (i=0;i<HOTSPOT_NUM; i=i+1)begin
			if ( hotspot_info[i].send_enable == 0 && core_num ==hotspot_info[i].ip_num)begin
				off_flag=1;
			end
		end
		hotspot_flag=0;
		hotspot_node=0;
		if ( rnd1000 < hotspot_info[0].percentage && core_num !=hotspot_info[0].ip_num)begin 
			hotspot_flag=1;
			hotspot_node=hotspot_info[0].ip_num;
		end else begin
			for (i=1;i<HOTSPOT_NUM; i=i+1)begin
				if (rnd1000 >= hotspot_info[i-1].percentage && rnd1000 < hotspot_info[i].percentage && core_num !=hotspot_info[i].ip_num) begin
					hotspot_flag=1;
					hotspot_node=hotspot_info[i].ip_num;
				end
			end end
     		
	end  
	
	
	assign dest_ip_num = (off_flag)? core_num : (hotspot_flag)? hotspot_node : rnd_reg;
     	
     	
endmodule	
