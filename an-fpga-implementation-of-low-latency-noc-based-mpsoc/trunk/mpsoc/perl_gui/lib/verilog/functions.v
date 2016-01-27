
	function integer log2;
		input integer number; begin	
        	log2=0;	
        	while(2**log2<number) begin	
      		  	log2=log2+1;	
       		end	
      		end	
   	endfunction // log2 
   	
   	function   [15:0]i2s;   
        input   integer c;  integer i;  integer tmp; begin 
            tmp =0; 
            for (i=0; i<2; i=i+1'b1) begin 
            tmp =  tmp +    (((c % 10)   + 6'd48) << i*8); 
                c       =   c/10; 
            end 
            i2s = tmp[15:0];
        end     
   endfunction //i2s
