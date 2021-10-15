// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

/**************************************
* Module: fattree
* Date:2019-01-01  
* Author: alireza     
*
* 
Description: 

    FatTree

      Each level of the hierarchical indirect Network has
      k^(l-1) Routers. The Routers are organized such that 
      each node has k descendents, and each parent is
      replicated k  times.
      most routers has 2K ports, excep the top level has only K

***************************************/


module  fattree_noc_top 
		import pronoc_pkg::*; 
	(

		reset,
		clk,    
		chan_in_all,
		chan_out_all  
	);
  
  
	input   clk,reset;
	//local ports 
	input   smartflit_chanel_t chan_in_all  [NE-1 : 0];
	output  smartflit_chanel_t chan_out_all [NE-1 : 0];
	
	
	//all routers port 
	smartflit_chanel_t    router_chan_in   [NR-1 :0][MAX_P-1 : 0];
	smartflit_chanel_t    router_chan_out  [NR-1 :0][MAX_P-1 : 0];

	
 
		localparam
			PV = V * MAX_P,
			PFw = MAX_P * Fw,       
			NRL= NE/K, //number of router in  each layer       
			NEFw = NE * Fw,
			NEV = NE * V,
			CONG_ALw = CONGw * MAX_P,
			PLKw = MAX_P * LKw,
			PLw = MAX_P * Lw,       
			PRAw = MAX_P * RAw; // {layer , Pos} width     
        
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
        
    wire [LKw-1 : 0] current_pos_addr [NR-1 :0];
    wire [Lw-1  : 0] current_layer_addr [NR-1 :0];   
    wire [RAw-1 : 0] current_r_addr [NR-1 : 0];
    
//add roots

genvar pos,level,port;



generate 
for( pos=0; pos<NRL; pos=pos+1) begin : root 
      
	  router_top # (
               .P(K)               
      )
      the_router
      (              
        	.current_r_addr  (current_r_addr [pos]), 
           	.chan_in         (router_chan_in [pos][K-1 : 0]), 
           	.chan_out        (router_chan_out[pos][K-1 : 0]), 
           	.clk             (clk            ), 
           	.reset           (reset          )
      );
      	
  
end   

//add leaves

for( level=1; level<L; level=level+1) begin :level_lp
   for( pos=0; pos<NRL; pos=pos+1) begin : pos_lp 
      
   	router_top # (
   			.P(2*K)         
   		)
   		the_router
   		(              
   			.current_r_addr  (current_r_addr [NRL*level+pos]), 
   			.chan_in         (router_chan_in [NRL*level+pos]), 
   			.chan_out        (router_chan_out[NRL*level+pos]), 
   			.clk             (clk            ), 
   			.reset           (reset          )
   		);           
   
    end
end
      
   
//connect all down input chanels
localparam NPOS = powi( K, L-1);
localparam CHAN_PER_DIRECTION = (K * powi( L , L-1 )); //up or down
localparam CHAN_PER_LEVEL = 2*(K * powi( K , L-1 )); //up+down

for (level = 0; level<L-1; level=level+1) begin : level_c
/* verilator lint_off WIDTH */
    localparam [Lw-1 : 0] LEAVE_L = L-1-level;
/* verilator lint_on WIDTH */    
    //input chanel are numbered interleavely, the interleaev depends on level
    localparam ROUTERS_PER_NEIGHBORHOOD = powi(K,L-1-(level)); 
    localparam ROUTERS_PER_BRANCH = powi(K,L-1-(level+1)); 
    localparam LEVEL_OFFSET = ROUTERS_PER_NEIGHBORHOOD*K;
    for ( pos = 0; pos < NPOS; pos=pos+1 ) begin : pos_c
        localparam ADRRENCODED=addrencode(pos,K,L,Kw);
        localparam NEIGHBORHOOD = (pos/ROUTERS_PER_NEIGHBORHOOD);
        localparam NEIGHBORHOOD_POS = pos % ROUTERS_PER_NEIGHBORHOOD;
        for ( port = 0; port < K; port=port+1 ) begin : port_c
            localparam LINK = 
                ((level+1)*CHAN_PER_LEVEL - CHAN_PER_DIRECTION)  //which levellevel
                +NEIGHBORHOOD* LEVEL_OFFSET   //region in level
                +port*ROUTERS_PER_BRANCH*K //sub region in region
                +(NEIGHBORHOOD_POS)%ROUTERS_PER_BRANCH*K //router in subregion
                +(NEIGHBORHOOD_POS)/ROUTERS_PER_BRANCH; //port on router


            localparam L2= (LINK+CHAN_PER_DIRECTION)/CHAN_PER_LEVEL;
            localparam POS2 = ((LINK+CHAN_PER_DIRECTION) % CHAN_PER_LEVEL)/K;
            localparam PORT2= (((LINK+CHAN_PER_DIRECTION) % CHAN_PER_LEVEL)  %K)+K;
            localparam ID1 =NRL*level+pos;
            localparam ID2 =NRL*L2 + POS2;
            localparam POS_ADR_CODE2= addrencode(POS2,K,L,Kw);
            localparam POS_ADR_CODE1= addrencode(pos,K,L,Kw);
           
            
           // $dotfile=$dotfile.node_connection('R',$id1,undef,$port,'R',$connect_id,undef,$connect_port);    
       		assign  router_chan_in [ID1][port ] = router_chan_out [ID2][PORT2];
			assign  router_chan_in [ID2][PORT2] = router_chan_out [ID1][port ];
                   
            assign current_layer_addr [ID1] = LEAVE_L;
            assign current_pos_addr [ID1] = ADRRENCODED[LKw-1 :0];         
            assign current_r_addr [ID1] = {current_layer_addr [ID1],current_pos_addr[ID1]};

			if(level==L-2)begin 
				 assign current_layer_addr [ID2] ={Lw{1'b0}};
            	 assign current_pos_addr [ID2] = POS_ADR_CODE2[LKw-1 :0];         
            	 assign current_r_addr [ID2] = {current_layer_addr [ID2],current_pos_addr[ID2]};
			end

         
         end
    end
end 
   
   
   
 for ( pos = 0; pos <  NE; pos=pos+1 ) begin : endpoints
    localparam RID= NRL*(L-1)+(pos/K);
    localparam RPORT = pos%K;
    
     //$dotfile=$dotfile.node_connection('T',$i,undef,undef,'R',$r,undef,$i%($k));    
 
            assign router_chan_in [RID][RPORT] =    chan_in_all [pos];                     
            assign chan_out_all [pos] = router_chan_out [RID][RPORT];             
 
 
 end
 endgenerate    


endmodule




