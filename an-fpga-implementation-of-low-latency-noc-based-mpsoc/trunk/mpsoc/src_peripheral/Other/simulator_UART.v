/**************************************
* Module: simulator_UART
* Date:2017-06-13  
* Author: alireza     
*
* Description: A simple uart that display input characters on simulator terminal using $write command.
*              This module start wrting on terminal when the buffer becomes full or wait counter reach its limit. 
*              The buffer  perevents the conflict between multiple simulation UART messages 
*              Wait counter reset by each individual write on buffer
***************************************/
module  simulator_UART #(
    parameter BUFFER_SIZE   =100,  
    parameter WAIT_COUNT    =1000,
    parameter Dw            =   32,
    parameter S_Aw          =   7,
    parameter M_Aw          =   32,
    parameter TAGw          =   3,
    parameter SELw          =   4


)(
    reset,
    clk,
    s_dat_i,
    s_sel_i,
    s_addr_i,  
    s_cti_i,
    s_stb_i,
    s_cyc_i,
    s_we_i,    
    s_dat_o,
    s_ack_o


);


  


    input reset,clk;
//wishbone slave interface signals
    input   [Dw-1       :   0]      s_dat_i;
    input   [SELw-1     :   0]      s_sel_i;
    input   [S_Aw-1     :   0]      s_addr_i;  
    input   [TAGw-1     :   0]      s_cti_i;
    input                           s_stb_i;
    input                           s_cyc_i;
    input                           s_we_i;
    
    output  reg    [Dw-1       :   0]  s_dat_o;
    output  reg                     s_ack_o;

     wire s_ack_o_next    =   s_stb_i & (~s_ack_o);
     
    always @(posedge clk)begin 
        if( reset   )s_ack_o<=1'b0;
       else s_ack_o<=s_ack_o_next;
    end
     
     
//synthesis translate_off
//synopsys  translate_off
   
   function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end       
      end   
    endfunction // log2 
   
    localparam CNTw= log2(WAIT_COUNT+1);
    localparam Bw = log2(BUFFER_SIZE+1);
    
    reg [CNTw-1 :   0]counter,counter_next;
    reg [7  : 0 ] buffer [ BUFFER_SIZE-1    :   0];
    reg [Bw-1   :   0] ptr,ptr_next;
   
    always @(posedge clk)begin 
        if( reset   )s_ack_o<=1'b0;
       else s_ack_o<=s_ack_o_next;
    end
            
  
  reg print_en,buff_en;
  
   always @(*)begin 
        counter_next = counter;
        ptr_next = ptr;
        print_en =0;
        buff_en=0;
        if (ptr > 0 ) counter_next = counter + 1'b1;
        if (counter == WAIT_COUNT || ptr == BUFFER_SIZE) begin
           counter_next = 0;  
           ptr_next =0;
           print_en =1;
        end       
        if( s_stb_i &  s_cyc_i &  s_we_i & s_ack_o  )begin 
           counter_next=0;
           buff_en=1;
           if( ptr < BUFFER_SIZE)begin 
                ptr_next  =  ptr+1;
           end              
        end  
    end
  
  
  
  
  integer i;
  
  
  
  
  
  
  always @(posedge clk)begin 
    if(reset) begin 
        counter<=0;
        ptr<=0;
    end else begin
       counter<=counter_next;
       ptr <= ptr_next;
       if( buff_en )  buffer[ptr]<=s_dat_i[7:0];
       if (print_en)  for(i=0;i<  ptr;i=i+1) $write("%c",buffer[i]);       
    end
  end



  
 //synopsys  translate_on
//synthesis translate_on 

endmodule

