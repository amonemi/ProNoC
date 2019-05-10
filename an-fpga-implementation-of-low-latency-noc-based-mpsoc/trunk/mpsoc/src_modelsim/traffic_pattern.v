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
    parameter C3_p = 25,
    parameter MAX_PCK_NUM = 10000,
    parameter NE=4
    
)(
    en,
    pck_class_in,
    pck_number,
    core_num,
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
    NEw=log2(NE),
    Cw = (C>1)? log2(C) : 1,
    PCK_CNTw = log2(MAX_PCK_NUM+1),
    RNDw = log2(100);
               
    output reg [Cw-1    :   0]  pck_class_in;
    input      [NEw-1   :   0]  core_num;
    input      [PCK_CNTw-1 :0]  pck_number;  
    input                       reset,clk,en;
    wire       [RNDw-1  :   0]  rnd;
   
 
   
 // generate a random num between 0 to 99
    pseudo_random #(
        .MAX_RND    (99),
        .MAX_CORE   (NE-1),
        .MAX_NUM    (MAX_PCK_NUM)
    )
    rnd_gen
    (
        .core       (core_num),
        .num        (pck_number),
        .rnd        (rnd),
        .rnd_en     (en),
        .reset      (reset),
        .clk        (clk)
    );
    always @(*) begin 
        if      ( rnd <   C0_p)                 pck_class_in =0;
        else if ( rnd <   (C0_p+C1_p))          pck_class_in =1;
        else if ( rnd <   (C0_p+C1_p+C2_p))     pck_class_in =2;
        else                                    pck_class_in =3;
    end
 
   
   
endmodule

/**********************************

        pck_dst_gen

*********************************/
 
 
module  pck_dst_gen  #(
    parameter T1 = 4,
    parameter T2 = 4,
    parameter T3 = 4,
    parameter EAw=2,
    parameter NE=4,
    parameter TOPOLOGY="MESH",
    parameter TRAFFIC =   "RANDOM",
    parameter MAX_PCK_NUM = 10000,
    parameter HOTSPOT_NUM           =   4, //maximum 5
    parameter HOTSPOT_PERCENTAGE    =   3,  //max 100/HOTSPOT_NUM
    parameter HOTSPOT_CORE_1        =   10,
    parameter HOTSPOT_CORE_2        =   11,
    parameter HOTSPOT_CORE_3        =   12,
    parameter HOTSPOT_CORE_4        =   13,
    parameter HOTSPOT_CORE_5        =   14,
    parameter HOTSPOT_SEND_EN       =   0

)(
    en,
    current_e_addr,
    core_num,
    pck_number,
    dest_e_addr, 
    clk,
    reset,
    valid_dst 
); 
 
 
    localparam      ADDR_DIMENTION =   (TOPOLOGY ==    "MESH" || TOPOLOGY ==  "TORUS") ? 2 : 1;  // "RING" and FULLY_CONNECT 
 
 
    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end 	   
      end   
    endfunction // log2 
     
     
    localparam  NEw= log2(NE),
                PCK_CNTw = log2(MAX_PCK_NUM+1);
    
    input                       reset,clk,en;
    input   [NEw-1      :   0]  core_num;
    input   [PCK_CNTw-1 :   0]  pck_number; 
    input   [EAw-1      :   0]  current_e_addr; 
    output  [EAw-1      :   0]  dest_e_addr; 
    output                      valid_dst;      
 
 
     generate 
     if ( ADDR_DIMENTION == 2) begin :two_dim
     
        two_dimention_pck_dst_gen #(
        	.T1(T1),
        	.T2(T2),
        	.T3(T3),
        	.EAw(EAw),
        	.NE(NE),
        	.TOPOLOGY(TOPOLOGY),
        	.TRAFFIC(TRAFFIC),
        	.MAX_PCK_NUM(MAX_PCK_NUM),
        	.HOTSPOT_PERCENTAGE(HOTSPOT_PERCENTAGE),
        	.HOTSPOT_NUM(HOTSPOT_NUM),
        	.HOTSPOT_CORE_1(HOTSPOT_CORE_1),
        	.HOTSPOT_CORE_2(HOTSPOT_CORE_2),
        	.HOTSPOT_CORE_3(HOTSPOT_CORE_3),
        	.HOTSPOT_CORE_4(HOTSPOT_CORE_4),
        	.HOTSPOT_CORE_5(HOTSPOT_CORE_5),
        	.HOTSPOT_SEND_EN(HOTSPOT_SEND_EN)
        )
        the_two_dimention_pck_dst_gen
        (
        	.reset(reset),
        	.clk(clk),
        	.en(en),
        	.core_num(core_num),
        	.pck_number(pck_number),
        	.current_e_addr(current_e_addr),
            .dest_e_addr(dest_e_addr),
        	.valid_dst(valid_dst)
        );
        
     end else begin : one_dim
      
        one_dimention_pck_dst_gen #(
            .T1(T1),
            .T2(T2),
            .T3(T3),
            .EAw(EAw),
            .NE(NE),
            .TOPOLOGY(TOPOLOGY),
            .TRAFFIC(TRAFFIC),
            .MAX_PCK_NUM(MAX_PCK_NUM),
            .HOTSPOT_PERCENTAGE(HOTSPOT_PERCENTAGE),
            .HOTSPOT_NUM(HOTSPOT_NUM),
            .HOTSPOT_CORE_1(HOTSPOT_CORE_1),
            .HOTSPOT_CORE_2(HOTSPOT_CORE_2),
            .HOTSPOT_CORE_3(HOTSPOT_CORE_3),
            .HOTSPOT_CORE_4(HOTSPOT_CORE_4),
            .HOTSPOT_CORE_5(HOTSPOT_CORE_5),
            .HOTSPOT_SEND_EN(HOTSPOT_SEND_EN)
        )
        the_one_dimention_pck_dst_gen
        (
            .reset(reset),
            .clk(clk),
            .en(en),
            .core_num(core_num),
            .pck_number(pck_number),
            .current_e_addr(current_e_addr),
            .dest_e_addr(dest_e_addr),
            .valid_dst(valid_dst)
        );       
       
     end     
     endgenerate 
 endmodule
 
 
 
 
module two_dimention_pck_dst_gen  #(
    parameter T1 = 4,
    parameter T2 = 4,
    parameter T3 = 4,
    parameter EAw=4,
    parameter NE=16,
    parameter TOPOLOGY="MESH",
    parameter TRAFFIC =   "RANDOM",
    parameter MAX_PCK_NUM = 10000,
    parameter HOTSPOT_PERCENTAGE    =   3,   //maximum 20
    parameter HOTSPOT_NUM           =   4, //maximum 4
    parameter HOTSPOT_CORE_1        =   10,
    parameter HOTSPOT_CORE_2        =   11,
    parameter HOTSPOT_CORE_3        =   12,
    parameter HOTSPOT_CORE_4        =   13,
    parameter HOTSPOT_CORE_5        =   14,
    parameter HOTSPOT_SEND_EN = 0

)(
    en,
    current_e_addr,
    dest_e_addr,
    core_num,
    pck_number,
    clk,
    reset,
    valid_dst 
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
                PCK_CNTw = log2(MAX_PCK_NUM+1);
    
    input                       reset,clk,en;
    input   [NEw-1      :   0]  core_num;
    input   [PCK_CNTw-1 :   0]  pck_number; 
    input   [EAw-1 : 0] current_e_addr;
    output  [EAw-1 : 0]  dest_e_addr;
    output                      valid_dst;  
    
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
    
    
    wire    [NEw-1  :   0]  dest_ip_num;
    genvar i;
            
    generate     
    if (TRAFFIC == "RANDOM") begin 
        
        pseudo_random_no_core #(
            .MAX_RND    (NE-1),
            .MAX_CORE   (NE-1),
            .MAX_NUM    (MAX_PCK_NUM)
        )
        rnd_dest_gen
        (
            .core   (core_num),
            .num    (pck_number),
            .rnd    (dest_ip_num),
            .rnd_en (en),
            .reset  (reset),
            .clk    (clk)

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
               
     end else if (TRAFFIC == "HOTSPOT") begin 
                      
        pseudo_hotspot_no_core #(
            .MAX_RND            (NE-1),
            .MAX_CORE           (NE-1),
            .MAX_NUM            (MAX_PCK_NUM),
            .HOTSPOT_PERCENTAGE (HOTSPOT_PERCENTAGE),   //maximum 25%
            .HOTSPOT_NUM        (HOTSPOT_NUM), //maximum 4
            .HOTSPOT_CORE_1     (HOTSPOT_CORE_1),
            .HOTSPOT_CORE_2     (HOTSPOT_CORE_2),
            .HOTSPOT_CORE_3     (HOTSPOT_CORE_3),
            .HOTSPOT_CORE_4     (HOTSPOT_CORE_4),
            .HOTSPOT_CORE_5     (HOTSPOT_CORE_5),
            .HOTSPOT_SEND_EN    (HOTSPOT_SEND_EN)
        )
        rnd_dest_gen
        (   
            .core  (core_num),
            .num   (pck_number),
            .rnd   (dest_ip_num),
            .rnd_en(en),
            .reset (reset),
            .clk   (clk)
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
        
    end else if( TRAFFIC == "TRANSPOSE2") begin :transpose2
        
        assign dest_x   = current_y;
        assign dest_y   = current_x;
        assign dest_l   = current_l;
        assign dest_e_addr = (T3==1)? {dest_y,dest_x} : {dest_l,dest_y,dest_x};
         
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
                    
    end else if( TRAFFIC == "TORNADO" ) begin :tornado
        //[(x+(k/2-1)) mod k, (y+(k/2-1)) mod k],
        assign dest_x  = (current_x> ((NX+1)/2))? current_x- ((NX+1)/2) -1   :  (NX/2)+current_x-1;  //  = ((current_x + ((NX/2)-1))%NX); 
        assign dest_y  = (current_y> ((NY+1)/2))? current_y- ((NY+1)/2) -1   :  (NY/2)+current_y-1;  //  = ((current_y + ((NY/2)-1))%NY);
        assign dest_l   = current_l;
        assign dest_e_addr = (T3==1)? {dest_y,dest_x} : {dest_l,dest_y,dest_x};
    
    end else if(TRAFFIC == "CUSTOM" )begin 
        /*
        assign send_en = (current_x==0 && current_y==0);// core (0,0) sends packets to (7,7)
        assign dest_x = 7;
        assign dest_y = 7;
   */
        reg [NXw-1   :   0]dest_x_reg;
        reg [NYw-1   :   0]dest_y_reg;
        reg [NLw-1   :   0]dest_l_reg;
        reg               valid_dst_reg;
        
        always @(*) begin 
        valid_dst_reg=1'b0;  
	    dest_x_reg = current_x;
        dest_y_reg= current_y;
	    dest_l_reg=current_l;
         //   if((current_x==0) &&  (current_y== 0) && (current_l==0)) begin 
            //    dest_x_reg=  NX-1; dest_y_reg=  NY-1; valid_dst_reg=1'b1;
            //    dest_l_reg= NL-1;
          //  end
          
           if((current_x==0) &&  (current_y== 0) && (current_l==0)) begin 
                dest_x_reg=  T1-1; dest_y_reg=  T2-1;   dest_l_reg= T3-1;  valid_dst_reg=1'b1;
            end
          
/*
            if((current_x==1) &&  (current_y== 0) && (current_l==0) ) begin 
                dest_x_reg=  NX-1; dest_y_reg=  NY-2; valid_dst_reg=1'b1;
                dest_l_reg= NL-1;
            end
 
         
           if((current_x==1) &&  (current_y== 1)) begin 
                dest_x_reg=  1; dest_y_reg=  6; valid_dst_reg=1'b1;
            end
            if((current_x==1) &&  (current_y== 2)) begin 
                dest_x_reg=  1; dest_y_reg=  5; valid_dst_reg=1'b1;
            end
            if((current_x==1) &&  (current_y== 3)) begin 
                dest_x_reg=  1; dest_y_reg=  4; valid_dst_reg=1'b1;
            end
*/
        end
      /*
        0  0   1  1
        0  1   1  2
        1  0   1  7
        1  1   1  6
        1  2   1  5
        1  3   1  4
        */
        assign valid_dst = valid_dst_reg;
        assign dest_y =  dest_y_reg;
        assign dest_x = dest_x_reg;
        assign dest_l = dest_l_reg;
        assign dest_e_addr = (T3==1)? {dest_y,dest_x} : {dest_l,dest_y,dest_x};
              
    end  
    
     //check if destination address is valid
     if(TRAFFIC != "CUSTOM" )begin 
         assign valid_dst  = (dest_e_addr  !=  current_e_addr ) &  (dest_x  <= (NX-1)) & (dest_y  <= (NY-1) & (dest_l <= NL-1));
     end
   
    endgenerate
     
endmodule



/************

************/


module one_dimention_pck_dst_gen #(
    parameter T1 = 4,
    parameter T2 = 4,
    parameter T3 = 4,
    parameter EAw= 4,
    parameter NE = 16,
    parameter TOPOLOGY="RING",//"FULLY_CONNECT"
    parameter TRAFFIC =   "RANDOM",
    parameter MAX_PCK_NUM = 10000,
    parameter HOTSPOT_PERCENTAGE    =   3,   //maximum 20
    parameter HOTSPOT_NUM           =   4, //maximum 4
    parameter HOTSPOT_CORE_1        =   10,
    parameter HOTSPOT_CORE_2        =   11,
    parameter HOTSPOT_CORE_3        =   12,
    parameter HOTSPOT_CORE_4        =   13,
    parameter HOTSPOT_CORE_5        =   14,
    parameter HOTSPOT_SEND_EN       =   0

)(
    en,
    core_num,
    pck_number,
    current_e_addr,
    dest_e_addr, 
    clk,
    reset,
    valid_dst   
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
        PCK_CNTw = log2(MAX_PCK_NUM+1);
    
    input   reset,clk,en;
    input   [NEw-1 : 0] core_num;  
    input   [PCK_CNTw-1  :   0]  pck_number; 
    input   [EAw-1       :   0]  current_e_addr;     
    output  [EAw-1       :   0]  dest_e_addr;   
    output  valid_dst;  
        
    wire [NEw-1 : 0] dest_ip_num;
    
    genvar i;            
    generate     
    if (TRAFFIC == "RANDOM") begin 
        
        pseudo_random_no_core #(
            .MAX_RND    (NE-1),
            .MAX_CORE   (NE-1),
            .MAX_NUM    (MAX_PCK_NUM)
        )
        rnd_dest_gen
        (
            .core   (core_num),
            .num    (pck_number),
            .rnd    (dest_ip_num),
            .rnd_en (en),
            .reset  (reset),
            .clk    (clk)

        );  
         
        
     end else if (TRAFFIC == "HOTSPOT") begin 
                      
        pseudo_hotspot_no_core #(
            .MAX_RND            (NE-1   ),
            .MAX_CORE           (NE-1   ),
            .MAX_NUM            (MAX_PCK_NUM),
            .HOTSPOT_PERCENTAGE (HOTSPOT_PERCENTAGE),   //maximum 25%
            .HOTSPOT_NUM        (HOTSPOT_NUM), //maximum 4
            .HOTSPOT_CORE_1     (HOTSPOT_CORE_1),
            .HOTSPOT_CORE_2     (HOTSPOT_CORE_2),
            .HOTSPOT_CORE_3     (HOTSPOT_CORE_3),
            .HOTSPOT_CORE_4     (HOTSPOT_CORE_4),
            .HOTSPOT_CORE_5     (HOTSPOT_CORE_5),
            .HOTSPOT_SEND_EN    (HOTSPOT_SEND_EN)
         )
         rnd_dest_gen
         (    
            .core  (core_num),
            .num   (pck_number),
            .rnd   (dest_ip_num),
            .rnd_en(en),
            .reset (reset),
            .clk   (clk)
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
           
    end else if(TRAFFIC == "CUSTOM" )begin 
        /*
        assign send_en = (current_x==0 && current_y==0);// core (0,0) sends packets to (7,7)
        assign dest_x = 7;
        assign dest_y = 7;
   */
        reg [NEw-1   :   0]dest_x_reg;
         
        reg               valid_dst_reg;
        
        always @(*) begin 
            valid_dst_reg=1'b0;   
	    dest_x_reg = core_num;
     	     
          //  if( current_x>=0 && current_x<=6  ) begin 
           //     dest_x_reg=  8;   valid_dst_reg=1'b1;
          //  end
 
           if((core_num==3)  ) begin 
                dest_x_reg=  25;   valid_dst_reg=1'b1;
            end
 
      //     if((current_x>=7 && current_x<=14 )  ) begin 
      //          dest_x_reg= 14;   valid_dst_reg=1'b1;
      //      end
	end
 /*
           if((current_x==1) &&  (current_y== 1)) begin 
                dest_x_reg=  1; dest_y_reg=  6; valid_dst_reg=1'b1;
            end
            if((current_x==1) &&  (current_y== 2)) begin 
                dest_x_reg=  1; dest_y_reg=  5; valid_dst_reg=1'b1;
            end
            if((current_x==1) &&  (current_y== 3)) begin 
                dest_x_reg=  1; dest_y_reg=  4; valid_dst_reg=1'b1;
            end

        end
      /*
        0  0   1  1
        0  1   1  2
        1  0   1  7
        1  1   1  6
        1  2   1  5
        1  3   1  4
        */
        assign valid_dst = valid_dst_reg;       
        assign dest_ip_num = dest_x_reg;          
              
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
       
     //check if destination address is valid
     if(TRAFFIC != "CUSTOM" )begin 
         assign valid_dst  =  (dest_e_addr   !=   current_e_addr)  &  (dest_ip_num  <= (NE-1));
     end
   
    endgenerate
     
endmodule
 
/***************************
 *  pck_size_gen
 * *************************/

module pck_size_gen #(
        parameter MIN = 2,
        parameter MAX = 5
)
(
    reset,
    clk,
    en,
    pck_size 
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
        PCK_w= log2(MAX+1);
     

    input reset, clk, en;
    output [PCK_w-1 : 0] pck_size;

    
    generate
    if (MIN == MAX) begin :eq 
        assign pck_size = MIN;
    end
    else begin :noteq
        reg [PCK_w-1 : 0] rnd;
        always @(posedge clk) begin 
            if(reset) rnd = MIN;
            else if(en) rnd = $urandom_range(MAX,MIN);
        end
        assign pck_size = rnd;
    end
    endgenerate
endmodule 



module  endp_addr_encoder #(
    parameter TOPOLOGY ="MESH",
    parameter T1=4,
    parameter T2=4,
    parameter T3=4,
    parameter EAw=4,
    parameter NE=16
)
(
    id,
    code
 );    

    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end        
      end   
    endfunction // log2 
    
    localparam NEw= log2(NE);
    
     input [NEw-1 :0] id;
     output [EAw-1 : 0] code;
     
     generate 
     if(TOPOLOGY == "FATTREE" || TOPOLOGY == "TREE" ) begin : tree
     
       fattree_addr_encoder #(
       	.K(T1),
       	.L(T2)
       )
       addr_encoder
       (
       	.id(id),
       	.code(code)
       );
     
     
     end else begin 
     
        mesh_tori_addr_encoder #(
        	.NX(T1),
        	.NY(T2),
        	.NL(T3),
        	.NE(NE),
        	.EAw(EAw),
        	.TOPOLOGY(TOPOLOGY)
        )
        mesh_tori_addr_encoder(
        	.id(id),
        	.code(code)
        );
     
     
     end
     endgenerate
endmodule
