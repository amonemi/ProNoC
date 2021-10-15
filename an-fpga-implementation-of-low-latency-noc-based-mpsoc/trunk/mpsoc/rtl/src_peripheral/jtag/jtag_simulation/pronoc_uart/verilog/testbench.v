/**************************************
* Module: testbench
* Date:2020-04-13  
* Author: alireza     
*
* Description: 
***************************************/


// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

module  testbench(

);


      function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end       
      end   
    endfunction // log2 
    
    
    // parameters
     parameter JTAG_INDEX =  126;
     parameter JAw = 32;
     parameter JINDEXw = 8;
     parameter JSTATUSw = 8;
     parameter BUFF_Aw =    6;
     parameter SELw =    4;
     parameter Aw =    1;
     parameter Dw =    32;
     parameter TAGw =    3;
     parameter JDw =  32;
    
    
    
     //wb interface
    localparam 
        DATA_REG = 1'b0,            
        CONTROL_REG  = 1'b1 ,  
        CONTROL_WSPACE_MSK = 32'hFFFF0000,
        DATA_RVALID_MSK = 32'h00008000,
        DATA_DATA_MSK = 32'h000000FF,
        B = 2 ** (BUFF_Aw-1),
        B_1 = B-1,
        Bw = log2(B),
        DEPTHw=log2(B+1),
        J2WBw= 1+1+JDw+JAw,
        WB2Jw=1+JSTATUSw+JINDEXw+1+JDw;
        
    localparam  [Bw-1   :   0] Bint =   B_1[Bw-1    :   0];
    
    //wb
    reg            clk;
    reg            reset;
    wire           wb_irq;
    wire [ Dw-1: 0] wb_dat_o;
    wire       wb_ack_o;
    reg            wb_adr_i;
    reg            wb_stb_i;
    reg            wb_cyc_i;
    reg            wb_we_i;
    reg   [ Dw-1: 0] wb_dat_i;
    wire           dataavailable;
    wire           readyfordata; //jtag
  
    //jtag
    wire [WB2Jw-1  : 0] wb_to_jtag;
    wire  [J2WBw-1 : 0] jtag_to_wb; 


    pronoc_jtag_uart_hw #(
      	.BUFF_Aw(BUFF_Aw),
    	.JTAG_INDEX(JTAG_INDEX),
    	.JDw(JDw),
    	.JAw(JAw),
    	.JINDEXw(JINDEXw),
    	.JSTATUSw(JSTATUSw)
    )
    pronoc_jtag_uart
    (
    	.clk(clk),
    	.reset(reset),
    	//.wb_irq(wb_irq),
    	.wb_dat_o(wb_dat_o),
    	.wb_ack_o(wb_ack_o),
    	.wb_adr_i(wb_adr_i),
    	.wb_stb_i(wb_stb_i),
    	.wb_cyc_i(wb_cyc_i),
    	.wb_we_i(wb_we_i),
    	.wb_dat_i(wb_dat_i),
    	//.dataavailable(dataavailable),
    	//.readyfordata(readyfordata),
    	.wb_to_jtag(wb_to_jtag),
    	.jtag_to_wb(jtag_to_wb)
    );

    integer   char_idx;       // character_loop index
    reg [0: 7] character;
   
    task  uart_puts;
    input [0:1023] data;        
    begin
        character=1; 
        for(char_idx = 0;char_idx <=1023 ;char_idx = char_idx + 8)
        begin : character_loop
            character[0]  = data[char_idx];
            character[1]  = data[char_idx+1];
            character[2]  = data[char_idx+2];
            character[3]  = data[char_idx+3];
            character[4]  = data[char_idx+4];
            character[5]  = data[char_idx+5];
            character[6]  = data[char_idx+6];
            character[7]  = data[char_idx+7];
            if (character!=0) uart_putc(character);
        end//for 
    end
    endtask

    task  uart_putc;
    input [0:7] data;        
    begin
        wait_until_send_chanel_ready(); 
        write_wb_reg(DATA_REG,data);
    end
    endtask
    
    reg  capture_wb_dat_o;
    reg [Dw-1 : 0] captured_wb_dat;
    
    always @(posedge clk)begin 
        if(capture_wb_dat_o) captured_wb_dat= wb_dat_o;
    end
  
    
    task read_wb_reg;
    input reg addr;
    begin 
       wb_adr_i= addr;
       wb_stb_i= 1'b1;
       wb_cyc_i= 1'b1;
       wb_we_i =1'b0;
       @(posedge wb_ack_o)#1      
       wb_stb_i= 1'b0;
       wb_cyc_i= 1'b0; 
       capture_wb_dat_o=1'b1;
       @(posedge clk)#1;
       capture_wb_dat_o=1'b0; 
       @(posedge clk)#10;    
      // $display("%d",captured_wb_dat); 
    end
    endtask
    
    
    task write_wb_reg;
    input reg addr;
    input integer dat_in;
    begin 
       wb_adr_i= addr;
       wb_dat_i= dat_in;
       wb_stb_i= 1'b1;
       wb_cyc_i= 1'b1;
       wb_we_i =1'b1;
       @(posedge wb_ack_o)#1
       wb_stb_i= 1'b0;
       wb_cyc_i= 1'b0; 
       @(posedge clk)#1000;
    end
    endtask
    
    
    reg[15:0] wspace;
    task wait_until_send_chanel_ready;
    begin
        wspace=0;
        while(wspace == 0)begin
            read_wb_reg(CONTROL_REG);
            wspace = captured_wb_dat[31:16];
        end
    end
    endtask
    
    
    task uart_getc;
    begin 
        read_wb_reg(0);
        if(captured_wb_dat[15])begin
            $display("Wb got %s",captured_wb_dat[7:0]);
        end else begin
            uart_getc;
        end    
    end
    endtask
    
    
    uart_jtag_testbench #(
        .JTAG_INDEX(JTAG_INDEX),
        .JAw(JAw),
        .JDw(JDw),
        .JINDEXw(JINDEXw),
        .JSTATUSw(JSTATUSw)
    )
    uart_jtag
    (
        .wb_to_jtag(wb_to_jtag),
        .jtag_to_wb(jtag_to_wb)
    );    
    
    
    
    initial begin 
        clk=1'b0;
        forever clk = #4 ~clk;    
    end


    initial begin 
        reset =1'b1;
      //  jtag_to_wb=0;
        wb_adr_i=0;
        wb_cyc_i=0;
        wb_dat_i=0;
        wb_stb_i=0;
        wb_we_i=0;
        #1000
        @(posedge clk ) reset =1'b0;
        #10
        @(posedge clk ) 
              
        uart_puts("hi every one! This is a test message\n");
       
        repeat (6)begin    uart_getc;        end
        
        uart_puts("Also this one!");
uart_puts("hi every one! This is a test message\n");
uart_puts("hi every one! This is a test message\n");
    
    end

  

 


endmodule

