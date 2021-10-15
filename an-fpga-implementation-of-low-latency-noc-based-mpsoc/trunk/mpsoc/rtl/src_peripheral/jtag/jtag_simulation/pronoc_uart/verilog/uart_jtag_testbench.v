/**************************************
* Module: uart_jtag_testbench
* Date:2020-04-14  
* Author: alireza     
*
* Description: 
***************************************/


// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

module  uart_jtag_testbench #(
     parameter JTAG_INDEX =  126,
     parameter JAw = 32,
     parameter JDw=32,
     parameter JINDEXw = 8,
     parameter JSTATUSw = 8
)(
   wb_to_jtag,
   jtag_to_wb
);

    localparam 
        J2WBw= 1+1+JDw+JAw,
        WB2Jw=1+JSTATUSw+JINDEXw+1+JDw;

     //jtag
    input   [WB2Jw-1  : 0] wb_to_jtag;
    output  [J2WBw-1 : 0] jtag_to_wb; 


    wire [JSTATUSw-1 : 0] wb_to_jtag_status;
    wire [JINDEXw-1 : 0] wb_to_jtag_index;
    reg [JDw-1 : 0] jtag_to_wb_dat;
    reg [JAw-1 : 0] jtag_to_wb_addr;
    reg jtag_to_wb_stb;
    reg jtag_to_wb_we;
    wire [JDw-1 : 0] wb_to_jtag_dat; 
    wire wb_to_jtag_ack;
    reg [15 : 0] jtag_wspace;
    
    assign  {wb_to_jtag_status,wb_to_jtag_ack,wb_to_jtag_dat,wb_to_jtag_index,clk}=wb_to_jtag;
    assign  jtag_to_wb= {jtag_to_wb_addr,jtag_to_wb_stb,jtag_to_wb_we,jtag_to_wb_dat};
    

    reg jtag_clk;
    
    initial begin 
        jtag_clk=1'b0;
        forever jtag_clk = #33 ~jtag_clk;    
    end

    reg  capture_jtag_dat_o;
    reg [JDw-1 : 0] captured_jtag_dat;
    
    always @(posedge jtag_clk)begin 
        if(capture_jtag_dat_o) captured_jtag_dat= wb_to_jtag_dat;
    end

    task jtag_wr_wb_reg;
    input reg addr;
    input integer dat_in;
    begin 
       jtag_to_wb_addr= addr;
       jtag_to_wb_dat= dat_in;
       jtag_to_wb_stb= 1'b1;
       // wb_cyc_i= 1'b1;
       jtag_to_wb_we =1'b1;
       @(posedge wb_to_jtag_ack)#1
        capture_jtag_dat_o=1'b1;
       @(posedge jtag_clk)#1;
       capture_jtag_dat_o=1'b0;
       jtag_to_wb_stb= 1'b0;
       //wb_cyc_i= 1'b0; 
     // $display(" jtag_wr_wb_reg (%d,%d);",addr,dat_in);
    end
    endtask

  
    
     //always @(*)begin         captured_jtag_dat= wb_to_jtag_dat;    end


    task jtag_rd_wb_reg;
    input reg addr;
    begin 
       jtag_to_wb_addr= addr;
       jtag_to_wb_stb= 1'b1;
       //wb_cyc_i= 1'b1;
       jtag_to_wb_we =1'b0;
       @(posedge wb_to_jtag_ack)#1
       capture_jtag_dat_o=1'b1;
       @(posedge jtag_clk)#1;
       capture_jtag_dat_o=1'b0;
      // $display("%d",captured_jtag_dat);  
       jtag_to_wb_stb= 1'b0;
       //wb_cyc_i= 1'b0; 
      
    end
    endtask
    
    integer   char_idx;       // character_loop index
    reg [0: 7] character;

    task  jtag_capture;
    input [0:7] data;        
    begin
        jtag_wr_wb_reg(0,data);
        if(captured_jtag_dat[7:0]!=0) $display("%tjtag read %s",$time,captured_jtag_dat[7:0]);
        jtag_wspace = captured_jtag_dat[23:8];
        #1021;
    end
    endtask   
    
    task capture_until_send_chanel_ready; 
    begin
        while (jtag_wspace ==0)begin 
            jtag_capture(0);
        end
    end
    endtask  
       
       
    task  jtag_putc;
    input [0:7] data;        
    begin
        capture_until_send_chanel_ready(); 
        jtag_capture(data);
    end
    endtask   
       
    
       
       
    
    task  jtag_puts;
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
            if (character!=0) jtag_putc(character);
        end//for 
    end
    endtask



    initial begin 
       jtag_to_wb_addr= 0;
       jtag_to_wb_dat= 0;
       jtag_to_wb_stb= 1'b0;
       jtag_to_wb_we =1'b0;  
       capture_jtag_dat_o=1'b0;
       jtag_wspace=2;
       #300000
       repeat(15) begin
            jtag_capture(0);
       end   
      jtag_puts("XYZXYZ");
       repeat(1500) begin
            jtag_capture(0);
       end   
       
    end


endmodule

