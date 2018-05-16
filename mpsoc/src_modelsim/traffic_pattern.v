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
    parameter NX = 4,
    parameter NY = 4,
    parameter TOPOLOGY="MESH",
    parameter C = 4,    //  number of packet class 
    parameter C0_p = 25,    //  the percentage of injected packets with class 0 
    parameter C1_p = 25,
    parameter C2_p = 25,
    parameter C3_p = 25,
    parameter MAX_PCK_NUM = 10000
    
)(
    en,
    pck_class_in,
    pck_number,
    core_num,
    deafult_class_num,
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
   
    localparam Cw = (C>1)? log2(C) : 1,
               NC =	(TOPOLOGY=="RING" || TOPOLOGY == "LINE")?  NX    :   NX*NY,	//number of cores
               NCw= log2(NC),
               PCK_CNTw = log2(MAX_PCK_NUM+1),
               RNDw = log2(100);
               
    output reg [Cw-1    :   0]  pck_class_in;
    input      [NCw-1   :   0]  core_num;
    input      [PCK_CNTw-1 :0]  pck_number;  
    input                       reset,clk,en;
    wire       [RNDw-1  :   0]  rnd;
    input                       deafult_class_num;
 
   
 // generate a random num between 0 to 99
    pseudo_random #(
        .MAX_RND    (99),
        .MAX_CORE   (NC-1),
        .MAX_NUM    (MAX_PCK_NUM)
    )rnd_gen
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
    parameter NX = 4,
    parameter NY = 4,
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
    current_x,
    current_y,
    core_num,
    pck_number,
    dest_x, 
    dest_y,  
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
     
     
    localparam  NC =    (TOPOLOGY=="RING" || TOPOLOGY == "LINE")?  NX    :   NX*NY,    //number of cores
                Xw = log2(NX),
                Yw = log2(NY), 
                NCw= log2(NC),
                PCK_CNTw = log2(MAX_PCK_NUM+1);
    
    input                       reset,clk,en;
    input   [NCw-1      :   0]  core_num;
    input   [PCK_CNTw-1 :   0]  pck_number; 
    input   [Xw-1       :   0]  current_x; 
    input   [Yw-1       :   0]  current_y;    
    output  [Xw-1       :   0]  dest_x; 
    output  [Yw-1       :   0]  dest_y;
    output                      valid_dst;      
 
 
     generate 
     if ( ADDR_DIMENTION == 2) begin :two_dim
     
        two_dimention_pck_dst_gen #(
        	.NX(NX),
        	.NY(NY),
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
        	.current_x(current_x),
        	.current_y(current_y),
        	.dest_x(dest_x),
        	.dest_y(dest_y),
        	.valid_dst(valid_dst)
        );
        
     end else begin : one_dim
     
         one_dimention_pck_dst_gen #(
        	.NX(NX),
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
        	.pck_number(pck_number),
        	.current_x(current_x),
        	.dest_x(dest_x),
        	.valid_dst(valid_dst)
        );
        assign dest_y = 1'b0;
     end     
     endgenerate 
 
 
 
 endmodule
 
 
 
 
 
module two_dimention_pck_dst_gen  #(
    parameter NX = 4,
    parameter NY = 4,
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
    current_x,
    current_y,
    core_num,
    pck_number,
    dest_x, 
    dest_y,  
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
     
     
     localparam NC =	(TOPOLOGY=="RING" || TOPOLOGY == "LINE")?  NX    :   NX*NY,	//number of cores
                Xw = log2(NX),
                Yw = log2(NY), 
                NCw= log2(NC),
                PCK_CNTw = log2(MAX_PCK_NUM+1);
    
    input                       reset,clk,en;
    input   [NCw-1      :   0]  core_num;
    input   [PCK_CNTw-1 :   0]  pck_number; 
    input   [Xw-1       :   0]  current_x; 
    input   [Yw-1       :   0]  current_y;    
    output  [Xw-1       :   0]  dest_x; 
    output  [Yw-1       :   0]  dest_y;
    output                      valid_dst;      
    
    
    wire    [NCw-1  :   0]  dest_ip_num;
    genvar i;
            
    generate     
    if (TRAFFIC == "RANDOM") begin 
        
        pseudo_random_no_core #(
            .MAX_RND    (NC-1),
            .MAX_CORE   (NC-1),
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
       
       assign dest_y = (dest_ip_num / NX ); 
       assign dest_x = dest_ip_num -  (dest_y * NX ); //dest_x = (dest_ip_num %NX ); 
         
        
     end else if (TRAFFIC == "HOTSPOT") begin 
                      
                pseudo_hotspot_no_core #(
                    .MAX_RND            (NC-1   ),
                    .MAX_CORE           (NC-1   ),
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
       
       assign dest_y = (dest_ip_num / NX ); 
       assign dest_x = dest_ip_num -  (dest_y * NX ); //dest_x = (dest_ip_num %NX ); 
   
       
    end else if( TRAFFIC == "TRANSPOSE1") begin 
       
                    assign dest_x   = NX-current_y-1;
                    assign dest_y   = NY-current_x-1;
            
        
    end else if( TRAFFIC == "TRANSPOSE2") begin :transpose2
        
                    assign dest_x   = current_y;
                    assign dest_y   = current_x;
                    
        
    end  else if( TRAFFIC == "BIT_REVERSE") begin :bitreverse
   
                    wire [(Xw+Yw)-1 :   0] joint_addr, reverse_addr;
                    assign joint_addr  = {current_x,current_y};
                    
                    for(i=0; i<(Xw+Yw); i=i+1'b1) begin :lp//reverse the address
                        assign reverse_addr[i]  = joint_addr [((Xw+Yw)-1)-i];
                    end
                    assign {dest_x,dest_y } = reverse_addr;
   
    end  else if( TRAFFIC == "BIT_COMPLEMENT") begin :bitcomp
                              
                    assign dest_x   = ~current_x;
                    assign dest_y   = ~current_y;              
    end else if( TRAFFIC == "TORNADO" ) begin :tornado
        //[(x+(k/2-1)) mod k, (y+(k/2-1)) mod k],
          assign dest_x  = (current_x> ((NX+1)/2))? current_x- ((NX+1)/2) -1   :  (NX/2)+current_x-1;  //  = ((current_x + ((NX/2)-1))%NX); 
          assign dest_y  = (current_y> ((NY+1)/2))? current_y- ((NY+1)/2) -1   :  (NY/2)+current_y-1;  //  = ((current_y + ((NY/2)-1))%NY);
      
    end else if(TRAFFIC == "CUSTOM" )begin 
        /*
        assign send_en = (current_x==0 && current_y==0);// core (0,0) sends packets to (7,7)
        assign dest_x = 7;
        assign dest_y = 7;
   */
        reg [Xw-1   :   0]dest_x_reg;
        reg [Yw-1   :   0]dest_y_reg;
        reg               valid_dst_reg;
        
        always @(*) begin 
            valid_dst_reg=1'b0;       
            if((current_x==0) &&  (current_y== 0)) begin 
                dest_x_reg=  NX-1; dest_y_reg=  NY-1; valid_dst_reg=1'b1;
            end

            if((current_x==1) &&  (current_y== 0)) begin 
                dest_x_reg=  NX-1; dest_y_reg=  NY-2; valid_dst_reg=1'b1;
            end
 
          if((current_x==2) &&  (current_y== 0)) begin 
                dest_x_reg= NX-1; dest_y_reg=   NY-1; valid_dst_reg=1'b1;
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
              
    end
   
    
     //check if destination address is valid
     if(TRAFFIC != "CUSTOM" )begin 
         assign valid_dst  = ({dest_x,dest_y}  !=  {current_x,current_y} ) &  (dest_x  <= (NX-1)) & (dest_y  <= (NY-1));
     end
   
    endgenerate
     
endmodule





/************

************/


module one_dimention_pck_dst_gen #(
    parameter NX = 4,
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
    current_x,
    pck_number,
    dest_x, 
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
     
     
     localparam Xw = log2(NX),
                PCK_CNTw = log2(MAX_PCK_NUM+1);
    
    input                       reset,clk,en;
  
    input   [PCK_CNTw-1 :   0]  pck_number; 
    input   [Xw-1       :   0]  current_x; 
     
    output  [Xw-1       :   0]  dest_x; 
  
    output                      valid_dst;      
    
    
  
    genvar i;
            
    generate     
    if (TRAFFIC == "RANDOM") begin 
        
        pseudo_random_no_core #(
            .MAX_RND    (NX-1),
            .MAX_CORE   (NX-1),
            .MAX_NUM    (MAX_PCK_NUM)
        )
        rnd_dest_gen
        (
            .core   (current_x),
            .num    (pck_number),
            .rnd    (dest_x),
            .rnd_en (en),
            .reset  (reset),
            .clk    (clk)

        );
       
      
         
        
     end else if (TRAFFIC == "HOTSPOT") begin 
                      
                pseudo_hotspot_no_core #(
                    .MAX_RND            (NX-1   ),
                    .MAX_CORE           (NX-1   ),
                    .MAX_NUM            (MAX_PCK_NUM),
                    .HOTSPOT_PERCENTAGE (HOTSPOT_PERCENTAGE),   //maximum 25%
                    .HOTSPOT_NUM        (HOTSPOT_NUM), //maximum 4
                    .HOTSPOT_CORE_1     (HOTSPOT_CORE_1),
                    .HOTSPOT_CORE_2     (HOTSPOT_CORE_2),
                    .HOTSPOT_CORE_3     (HOTSPOT_CORE_3),
                    .HOTSPOT_CORE_4     (HOTSPOT_CORE_4),
                    .HOTSPOT_CORE_5     (HOTSPOT_CORE_5),
                    .HOTSPOT_SEND_EN    (HOTSPOT_SEND_EN)
                    
                )rnd_dest_gen
                (
    
                    .core  (current_x),
                    .num   (pck_number),
                    .rnd   (dest_x),
                    .rnd_en(en),
                    .reset (reset),
                    .clk   (clk)

                );
       
       
   
       
    end else if( TRAFFIC == "TRANSPOSE1") begin :tran1
        assign dest_x=  NX-current_x-1;    
       // assign dest_x= (current_x<NX/2)? NX-current_x-1: current_x;            
        
   //end else if( TRAFFIC == "TRANSPOSE2") begin :transpose2
        
              
                   // assign dest_x   = current_y;
                   // assign dest_y   = current_x;
                    
        
    end  else if( TRAFFIC == "BIT_REVERSE") begin :bitreverse
   
                    wire [ Xw -1 :   0]  reverse_addr;
                  
                    
                    for(i=0; i<Xw; i=i+1'b1) begin :lp//reverse the address
                        assign reverse_addr[i]  = current_x [Xw-1-i];
                    end
                    assign  dest_x  = reverse_addr;
   
    end  else if( TRAFFIC == "BIT_COMPLEMENT") begin :bitcomp
                              
                    assign dest_x   = ~current_x;
    end else if( TRAFFIC == "TORNADO" ) begin :tornado
        //[(x+(k/2-1)) mod k, (y+(k/2-1)) mod k],
          assign dest_x  = (current_x > ((NX+1)/2))? current_x- ((NX+1)/2) -1   :  (NX/2)+current_x-1;  //  = ((current_x + ((NX/2)-1))%NX);
                      
         
    end else if(TRAFFIC == "CUSTOM" )begin 
        /*
        assign send_en = (current_x==0 && current_y==0);// core (0,0) sends packets to (7,7)
        assign dest_x = 7;
        assign dest_y = 7;
   */
        reg [Xw-1   :   0]dest_x_reg;
         
        reg               valid_dst_reg;
        
        always @(*) begin 
            valid_dst_reg=1'b0;       
            if( current_x>=0 && current_x<=6   ) begin 
                dest_x_reg=  8;   valid_dst_reg=1'b1;
            end
 
            if((current_x==7)  ) begin 
                dest_x_reg=  10;   valid_dst_reg=1'b1;
            end
 
           if((current_x>=8 && current_x<=14 )  ) begin 
                dest_x_reg= 14;   valid_dst_reg=1'b1;
            end
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
       
        assign dest_x = dest_x_reg;
              
    end
   
    
     //check if destination address is valid
     if(TRAFFIC != "CUSTOM" )begin 
         assign valid_dst  =  (dest_x   !=   current_x)  &  (dest_x  <= (NX-1));
     end
   
    endgenerate
     
endmodule
 

 




