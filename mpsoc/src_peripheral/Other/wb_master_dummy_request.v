/**************************************
* Module: wb_master_dummy_request
* Date:2017-05-14  
* Author: alireza     
*
* Description: This is a dummy wishnbone bus request sender. 
*  
***************************************/


module wb_master_dummy_request #(
	 //wishbone port parameters
    parameter Dw            =   32,
    parameter S_Aw          =   7,
    parameter M_Aw          =   32,
    parameter TAGw          =   3,
    parameter SELw          =   4,


		parameter REQ_LEN_CLK_NUM = 10,
		parameter REQ_WAIT_CLK_NUM = 20

)(

	 clk,
	 reset,
     //wishbone master rd interface signals
    m_rd_sel_o,
    m_rd_addr_o,
    m_rd_cti_o,
    m_rd_stb_o,
    m_rd_cyc_o,
    m_rd_we_o,
    m_rd_dat_i,
    m_rd_ack_i   

);





 //wishbone master wr interface signals
     function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end       
      end   
    endfunction // log2 
	 
	 
	

	input reset,clk;

	//wishbone read master interface signals
    output  [SELw-1          :   0] m_rd_sel_o;
    output  [M_Aw-1          :   0] m_rd_addr_o;
    output  [TAGw-1          :   0] m_rd_cti_o;
    output                          m_rd_stb_o;
    output   reg                    m_rd_cyc_o;
    output                          m_rd_we_o;
    input   [Dw-1           :  0]   m_rd_dat_i;
    input                           m_rd_ack_i;  
	
	assign m_rd_sel_o = {TAGw{1'b1}};
	assign m_rd_addr_o ={M_Aw{1'b0}};
	assign m_rd_cti_o = 3'd0;
	assign m_rd_stb_o = m_rd_cyc_o;
	assign m_rd_we_o= 1'b0;
	
	
	 localparam  
		ACTIVEw= log2(REQ_LEN_CLK_NUM),
		DELAYw = log2(REQ_WAIT_CLK_NUM),
		COUNTERw = (ACTIVEw > DELAYw)? ACTIVEw : DELAYw;
	 
	 reg [COUNTERw-1	:	0] counter,counter_next;
	 
	 localparam ST_NUM = 3;
	 
	 localparam [ST_NUM-1:0]
		DELAY_ST = 1,		
		WAIT_FOR_ACK =2,
		HOLD_REQ =4;
		
	

	reg [ST_NUM-1	:	0] ps,ns;
	
	
	
	
	
	
	
	always @(*) begin 
		ns = ps;
		counter_next =counter;
		m_rd_cyc_o=1'b0;
		case(ps)
			DELAY_ST: begin 
				counter_next=counter + 1'b1;
				if(counter == REQ_WAIT_CLK_NUM) begin 					
					ns= WAIT_FOR_ACK;				
				end
			end
			WAIT_FOR_ACK: begin 
				 m_rd_cyc_o=1'b1;
				 counter_next= {COUNTERw{1'b0}};
				 if(m_rd_ack_i)begin 
					ns= HOLD_REQ;		
				 end
			
			end
			HOLD_REQ: begin 
				m_rd_cyc_o=1'b1;
				counter_next=counter + 1'b1;
				if(counter == REQ_LEN_CLK_NUM) begin 					
					 counter_next= {COUNTERw{1'b0}};
					 ns= DELAY_ST;				
				end
			
			end
			default: begin 
			
			end
		endcase
	end

	always @ (posedge clk or posedge reset)begin 
		if(reset)begin 
			ps <= DELAY_ST;
			counter<= {COUNTERw{1'b0}};
		end else begin 
			ps<=ns;
			counter <= counter_next;
		
		end	
	end


endmodule


