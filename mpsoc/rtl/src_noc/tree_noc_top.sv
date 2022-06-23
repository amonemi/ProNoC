`include "pronoc_def.v"

/**************************************
 * Module: tree
 * Date:2019-01-01  
 * Author: alireza     
 *
 * 
Description: 

    Tree      

 ***************************************/

 
module  tree_noc_top 
		import pronoc_pkg::*; 
	(
		reset,
		clk,    
		chan_in_all,
		chan_out_all,
		router_event
	);
  
  
	input   clk,reset;
	//Endpoints ports 
	input   smartflit_chanel_t chan_in_all  [NE-1 : 0];
	output  smartflit_chanel_t chan_out_all [NE-1 : 0];
	
	//Events
	output  router_event_t  router_event [NR-1 : 0][MAX_P-1 : 0];
	
	//all routers port 
	smartflit_chanel_t    router_chan_in   [NR-1 :0][MAX_P-1 : 0];
	smartflit_chanel_t    router_chan_out  [NR-1 :0][MAX_P-1 : 0]; 
                         
   
        
	function integer addrencode;
		input integer pos,k,n,kw;
		integer pow,i,tmp;begin
			addrencode=0;
			pow=1;
			for (i = 0; i <n; i=i+1 ) begin 
				tmp=(pos/pow);
				tmp=tmp%k;
				tmp=tmp<<i*kw;
				addrencode=addrencode | tmp;
				pow=pow * k;
			end
		end   
	endfunction 
    
	localparam
		PV = V * MAX_P,		
		PFw = MAX_P * Fw,
		NEFw = NE * Fw,
		NEV = NE * V,
		CONG_ALw = CONGw * MAX_P,
		PLKw = MAX_P * LKw,
		PLw = MAX_P * Lw,       
		PRAw = MAX_P * RAw; // {layer , Pos} width   
    
    

    
   
    
	wire [LKw-1 : 0] current_pos_addr [NR-1 :0];
	wire [Lw-1  : 0] current_layer_addr [NR-1 :0];   
	wire [RAw-1 : 0] current_r_addr [NR-1 : 0];
    
    
     
    
	//add root 

	localparam [Lw-1 : 0] ROOT_L = L-1; 
	localparam ROOT_ID = 0;
 
	assign current_layer_addr [ROOT_ID] = ROOT_L;
	assign current_pos_addr [ROOT_ID] = {LKw{1'b0}};       
	assign current_r_addr[ROOT_ID] = {current_layer_addr [ROOT_ID],current_pos_addr[ROOT_ID]};

 
	router_top # (
			.P(K)
		)
		root_router
		(              
			.current_r_id    (ROOT_ID),
			.current_r_addr  (current_r_addr [ROOT_ID]), 
			.chan_in         (router_chan_in [ROOT_ID][K-1:0]), 
			.chan_out        (router_chan_out[ROOT_ID][K-1:0]), 
			.router_event    (router_event[ROOT_ID][K-1 : 0]),
			.clk             (clk            ), 
			.reset           (reset          )
		);
	

	genvar pos,level;


	//add leaves
	generate
		for( level=1; level<L; level=level+1) begin :level_lp
			localparam NPOS1 = powi(K,level); // number of routers in this level
			localparam NRATTOP1 = sum_powi ( K,level); // number of routers at top levels : from root until last level
			for( pos=0; pos<NPOS1; pos=pos+1) begin : pos_lp 
                localparam RID = NRATTOP1+pos;
				router_top # (
						.P(K+1)// leaves have K+1 port number						
					)
					the_router
					(                                  
						.current_r_id    (RID),
						.current_r_addr  (current_r_addr [RID]), 
						.chan_in         (router_chan_in [RID]), 
						.chan_out        (router_chan_out[RID]), 
						.router_event    (router_event[RID]),
						.clk             (clk            ), 
						.reset           (reset          )						
					);  
   
			end//pos
		end // level
       
   
		//connect all up connections
		for (level = 1; level<L; level=level+1) begin : level_c
			localparam  NPOS = powi(K,level); // number of routers in this level
			localparam L1 = L-1-level;
			localparam level2= level - 1;
			localparam L2 = L-1-level2;
			for ( pos = 0; pos < NPOS; pos=pos+1 ) begin : pos_c
          
				localparam ID1 = sum_powi ( K,level) + pos;        
				localparam FATTREE_EQ_POS1 = pos*(K**L1);
				localparam ADR_CODE1=addrencode(FATTREE_EQ_POS1,K,L,Kw);       
				localparam POS2 = pos /K ;
				localparam ID2 = sum_powi ( K,level-1) + (pos/K);
				localparam PORT2= pos % K;  
				localparam FATTREE_EQ_POS2 = POS2*(K**L2);
				localparam ADR_CODE2=addrencode(FATTREE_EQ_POS2,K,L,Kw);
        
				// node_connection('Router[id1][k] to router[id2][pos%k];  
				assign  router_chan_in [ID1][K] = router_chan_out [ID2][PORT2];
				assign  router_chan_in [ID2][PORT2] = router_chan_out [ID1][K];  
							
				assign current_layer_addr [ID1] = L1[Lw-1 : 0];
				assign current_pos_addr [ID1] = ADR_CODE1 [LKw-1 : 0];         
				assign current_r_addr [ID1] = {current_layer_addr [ID1],current_pos_addr[ID1]};
       
        
			end// pos
    
		end //level


		// connect endpoints 
   
		for ( pos = 0; pos <  NE; pos=pos+1 ) begin : endpoints
			//  node_connection T[pos] R[rid][pos %k];
			localparam RID= sum_powi(K,L-1)+(pos/K);
			localparam RPORT = pos%K;
    
			//$dotfile=$dotfile.node_connection('T',$i,undef,undef,'R',$r,undef,$i%($k));    
			assign router_chan_in [RID][RPORT] =    chan_in_all [pos];                     
			assign chan_out_all [pos] = router_chan_out [RID][RPORT];
 
		end
	endgenerate    


endmodule
