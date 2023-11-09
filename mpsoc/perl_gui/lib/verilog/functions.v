
	
   	
   	function   [15:0]i2s;   
        input   integer c;  integer i;  integer tmp; begin 
            tmp =0; 
            for (i=0; i<2; i=i+1) begin 
            tmp =  tmp +    (((c % 10)   + 48) << i*8); 
                c       =   c/10; 
            end 
            i2s = tmp[15:0];
        end     
   endfunction //i2s

/*

function integer log2;
		input integer number; begin	
        	log2=0;	
        	while(2**log2<number) begin	
      		  	log2=log2+1;	
       		end	
      		end	
   	endfunction // log2 

function   [159:0]f2s;   
          input   real f; reg s;reg b; integer i; integer j;integer a;  real tmp; begin 
              s=0;
              b=0;
	      f2s={160{1'b0}};
	      if(f<0)begin 
	        s=1;
		f=-f;	
	      end  
	      f=f*1000;
              a=f;
              i=0;
              j=0;
	      while(a>0)begin
         	j=j+1;
                
		if((a%10)!=0 || j>3 || b)begin 
                        	//f2s=(f2s & ~(8'hFF<< (i*8)));      
				f2s=f2s + (((a%10)+48)<< i*8); 
			      i=i+1;
                              b=1;
		end
		a=a/10;
                
		if(j==3 && b==1)begin
		   //f2s=(f2s & ~(8'hFF<< (i*8)));  
		   f2s=f2s   + ("."<< i*8); 
		   i=i+1;	
                   j=j+1;
		end
	      end
	      if(s) begin 
	        //f2s=(f2s & ~(8'hFF<< (i*8)));  
		f2s=f2s + ("-"<< i*8); 

	      end
	end
      endfunction //f2s
*/
