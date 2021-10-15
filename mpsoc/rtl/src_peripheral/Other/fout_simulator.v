/**************************************
* Module: print to file simulator.
* Date:2017-06-13  
* Author: alireza     
*
* Description: A simple module that use Verilog fwrite command to repicate C fprintf command. 
* TODO: suuport fread vcommand 
***************************************/
// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on



module  fout_simulator #(
    parameter BUFFER_SIZE   =255,  // for getting fle name
	parameter FLUSH_COUNTER = 0    // define after how many charactor writes the $fflush command should be executaed. define it as zero to deactivate the $fflush command. 

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

   localparam 
	Dw            =   32,
	M_Aw          =   32,
    TAGw          =   3,
    SELw          =   4;
  


    input reset,clk;
	//wishbone slave interface signals
    input   [Dw-1       :   0]      s_dat_i;
    input   [SELw-1     :   0]      s_sel_i;
    input   [2:0]    			    s_addr_i;  
    input   [TAGw-1     :   0]      s_cti_i;
    input                           s_stb_i;
    input                           s_cyc_i;
    input                           s_we_i;
    
    output  reg [Dw-1       :   0]  s_dat_o;
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

   
    
    localparam Bw = log2(BUFFER_SIZE+1);
    
   
    reg [7  : 0 ]  buffer [ 0  : BUFFER_SIZE-1];
    wire [ BUFFER_SIZE*8-1 : 0] buff_string;
   


   
    reg [Bw-1   :   0] ptr,ptr_next;
   
    always @(posedge clk)begin 
        if( reset   )s_ack_o<=1'b0;
       else s_ack_o<=s_ack_o_next;
    end
            
  
	reg buff_en;

		

	reg [7: 0 ]  file_ptr,file_ptr_next;
	integer file [0:126];

	genvar i;
    generate
    for (i=0;i<BUFFER_SIZE;i=i+1)begin 
		assign  buff_string [(i+1)*8-1 : i*8] = buffer [BUFFER_SIZE-i-1];
	end
   	endgenerate

	integer k;
	initial begin
		for (k=0;k<127;k=k+1)file[k] = 0;
	end



	
	
	
localparam //WB address registers
	GET_FLE_PTR   = 0,
	GET_FILE_NAME	= 1,
	GET_FILE_CONTENT = 2,
	FILE_MODE =3;

localparam [3:0]
	MODE_CLOSE  = 1,
	MODE_W      = 2,
	MODE_WB     = 3,
	MODE_A      = 4,
	MODE_AB     = 5;


localparam CNTw= log2(FLUSH_COUNTER);

reg [CNTw-1: 0] counter_next,counter;
reg [3: 0] mode,mode_next;
   always @(*)begin 
        counter_next=counter;
        ptr_next = ptr;
        buff_en=0;
        file_ptr_next=file_ptr;
		mode_next = mode;
		if( s_stb_i &  s_cyc_i &  s_we_i & ~s_ack_o) begin // get a write command from WB interface
			case(s_addr_i)
			GET_FLE_PTR:begin
					file_ptr_next=s_dat_i[7:0];			
			end
			GET_FILE_NAME:begin 
				if(s_dat_i[7:0]==0)begin //end of file name. Open the file to write
					case(mode)
						MODE_W: begin 
							file[file_ptr] = $fopen(buff_string, "w");
							$display("file_ptr[%u]= fopen(%s,w)\n",file_ptr,buff_string);		
						end
						MODE_WB:  begin 
						    file[file_ptr] = $fopen(buff_string, "wb");
							$display("file_ptr[%u]= fopen(%s,wb)\n",file_ptr,buff_string);	
						end						
						MODE_A:   begin 
						    file[file_ptr] = $fopen(buff_string, "a");
							$display("file_ptr[%u]= fopen(%s,a)\n",file_ptr,buff_string);	
						end						
						MODE_AB:  begin   
							file[file_ptr] = $fopen(buff_string, "ab");
							$display("file_ptr[%u]= $fopen(%s,ab)\n",file_ptr,buff_string);	
						end
						default :   begin 
							$display("Mode %d is not supported fule mode",mode);	
							$stop;	
						end
					endcase
					ptr_next  =  0;
								
				end else begin 				
					buff_en=1;
					if( ptr < BUFFER_SIZE)begin 
						ptr_next  =  ptr+1;
						if(counter < FLUSH_COUNTER ) counter_next=counter+1'b1;
						else counter_next={CNTw{1'b0}};
					end    
				end 
			end
			GET_FILE_CONTENT:begin
				$fwrite (file[file_ptr], "%c", s_dat_i[7:0]);
				
			end
			FILE_MODE:begin
				mode_next = s_dat_i[3:0];
				//$display("mode[%u].\n",mode);	
				if(s_dat_i[3:0]== MODE_CLOSE) begin 
					$fclose (file[file_ptr]);
					file[file_ptr] = 0;
					$display("Close file_ptr[%u].\n",file_ptr);	
				end								
			end
			endcase
		end
    end
  

   generate 
   if (FLUSH_COUNTER>0) begin :flush
	   for (i=0;i<127;i=i+1)begin :i_
			always @ (posedge clk)begin 
				if(reset==1'b0 && counter== {CNTw{1'b0}} && file[i]!=0) $fflush (file[i]);				
			end	//always		
	   end //for
   end//if
   endgenerate
  
  
    
    always @(posedge clk)begin 
        if(reset) begin 
           
            ptr<=0;
            buffer[0]<=0;
			file_ptr<=0; 
			counter<={CNTw{1'b0}};
			mode<=3'd0;
        end else begin
			file_ptr<=file_ptr_next;
            counter<=counter_next;
            ptr <= ptr_next;
			mode<= mode_next;
            if( buff_en )begin 
                buffer[ptr]<=s_dat_i[7:0];
                if(ptr<BUFFER_SIZE-1) buffer[ptr+1]<=0;         
            end 
        end
    end

	


  
 //synopsys  translate_on
//synthesis translate_on 

endmodule




