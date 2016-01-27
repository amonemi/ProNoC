

use strict;
use warnings;
use mpsoc;
use soc;
use ip;
use ip_gen;
use Cwd;
use rvp;



sub mpsoc_generate_verilog{
	my $mpsoc=shift;
	my $mpsoc_name=$mpsoc->mpsoc_get_mpsoc_name();
	my $io_v="\tclk,\n\treset";
	my $io_def_v="
//IO
\tinput\tclk,reset;\n";
	my $param_as_in_v;
	
	#generate socs_parameter
	my $socs_param= gen_socs_param($mpsoc);
	
	#generate noc_parameter
	my $noc_param=gen_noc_param_v($mpsoc);
	
	#generate the noc
	my $noc_v=gen_noc_v();
	
	#generate socs
	my $socs_v=gen_socs_v($mpsoc,\$io_v,\$io_def_v);
	
	#functions
	my $functions=get_functions();
	
	my $mpsoc_v = (defined $param_as_in_v )? "module $mpsoc_name #(\n $param_as_in_v\n)(\n$io_v\n);\n": "module $mpsoc_name (\n$io_v\n);\n";
	add_text_to_string (\$mpsoc_v,$functions);
	add_text_to_string (\$mpsoc_v,$socs_param);
	add_text_to_string (\$mpsoc_v,$noc_param);
	add_text_to_string (\$mpsoc_v,$io_def_v);
	add_text_to_string (\$mpsoc_v,$noc_v);
	add_text_to_string (\$mpsoc_v,$socs_v);
	add_text_to_string (\$mpsoc_v,"\nendmodule\n");
	
	
	return $mpsoc_v;
}

sub get_functions{
	my $p='
//functions	
	function integer log2;
		input integer number; begin   
			log2=0;    
			while(2**log2<number) begin    
				log2=log2+1;    
			end    
	end   
	endfunction // log2 
    
	function integer CORE_NUM;
		input integer x,y;
		begin
			CORE_NUM = ((y * NX) +  x);
		end
	endfunction
    
        

	localparam	Fw      =   2+V+Fpay,
				NC      =   NX*NY,  //flit width; 
				Xw      =   log2(NX),
				Yw      =   log2(NY) , 
				Cw      =   (C>1)? log2(C): 1,
				NCw     =   log2(NC),
				NCV     =   NC  * V,
				NCFw    =   NC  * Fw;
	';
	
	return $p;
	
	
	
}


sub  gen_socs_param{
	my $mpsoc=shift;
	my $socs_param="
//SOC parameters\n";
	my $nx= $mpsoc->mpsoc_get_param("NX");
    my $ny= $mpsoc->mpsoc_get_param("NY");
    my $processors_en=0;
    for (my $y=0;$y<$ny;$y++){
		for (my $x=0; $x<$nx;$x++){
			my $tile=($nx*$y)+ $x;
			my ($soc_name,$n,$soc_num)=$mpsoc->mpsoc_get_tile_soc_name($tile);
			if(defined $soc_name) {
				my $param=	gen_soc_param($mpsoc,$soc_name,$soc_num,$tile);
				add_text_to_string(\$socs_param,$param);
			}	
	}}#x&y
	$socs_param="$socs_param \n";
	return $socs_param;
	
}


sub  gen_soc_param {
	my ($mpsoc,$soc_name,$soc_num,$tile)=@_;
	my $top=$mpsoc->mpsoc_get_soc($soc_name);
	my $setting=$mpsoc->mpsoc_get_tile_param_setting($tile);
	my %params;
	if ($setting eq 'Custom'){
		 %params= $top->top_get_custom_soc_param($tile);
	}else{
		 %params=$top->top_get_default_soc_param();
	}
	my $params="\n\t //Parameter setting for $soc_name  located in tile: $tile \n";
	foreach my $p (sort keys %params){
			$params="$params\t localparam ${soc_name}_${soc_num}_$p=$params{$p};\n";
	}
		
	
	
	return $params;
}


sub gen_noc_param_v{
	my $mpsoc=shift;
	my $param_v="\n\n//NoC parameters\n";
	my @params=$mpsoc->mpsoc_get_param_order();
	foreach my $p (@params){
		my $val=$mpsoc->mpsoc_get_param($p);
		add_text_to_string (\$param_v,"\tlocalparam $p=$val;\n");
		#print "$p\n";
		
	}
	my $class=$mpsoc->mpsoc_get_param("C");
	my $str;
	if( $class > 1){
		$str="CLASS_SETTING={";
		for (my $i=$class-1; $i>=0;$i--){
			$str=($i==0)?  "${str}Cn_0};\n " : "${str}Cn_$i,";
		}
	}else {
		$str="CLASS_SETTING={V{1\'b1}};\n";
	}	
	add_text_to_string (\$param_v,"\tlocalparam $str");
	my $v=$mpsoc->mpsoc_get_param("V")-1;
	my $escape=$mpsoc->mpsoc_get_param("ESCAP_VC_MASK");
	add_text_to_string (\$param_v,"\tlocalparam [$v	:0] ESCAP_VC_MASK=1;\n") if (! defined $escape);
	add_text_to_string (\$param_v," \tlocalparam  CVw=(C==0)? V : C * V;\n");
	
	
	
	return $param_v;	
	
	
	
}




sub gen_noc_v{
	
	
	my $noc =  read_file("../src_noc/noc.v");
	my @noc_param=$noc->get_modules_parameters_not_local_order('noc');
	
	
	my $noc_v='
	
//NoC ports                
	wire [Fw-1      :   0]  ni_flit_out                 [NC-1           :0];   
	wire [NC-1      :   0]  ni_flit_out_wr; 
	wire [V-1       :   0]  ni_credit_in                [NC-1           :0];
	wire [Fw-1      :   0]  ni_flit_in                  [NC-1           :0];   
	wire [NC-1      :   0]  ni_flit_in_wr;  
	wire [V-1       :   0]  ni_credit_out               [NC-1           :0];    
	wire [NCFw-1    :   0]  flit_out_all;
	wire [NC-1      :   0]  flit_out_wr_all;
	wire [NCV-1     :   0]  credit_in_all;
	wire [NCFw-1    :   0]  flit_in_all;
	wire [NC-1      :   0]  flit_in_wr_all;  
	wire [NCV-1     :   0]  credit_out_all;
	wire 					noc_clk,noc_reset;
    
    ';
	
	
	
	$noc_v="$noc_v
//NoC\n \tnoc #(\n";
	my $i=0;
	foreach my $p (@noc_param){
		my $param=($i==0)?  "\t\t.$p($p)":",\n\t\t.$p($p)";
		$i=1;
		add_text_to_string(\$noc_v,$param);			
	}	
	add_text_to_string(\$noc_v,"\n\t)\n\tthe_noc\n\t(\n");		
	
	my @ports= $noc->get_module_ports_order('noc');
	$i=0;
	foreach my $p (@ports){
		my $port;
		if($p eq 'reset' ){
			$port=($i==0)?  "\t\t.$p(noc_reset)":",\n\t\t.$p(noc_reset)";
		}elsif( $p eq 'clk'){
			$port=($i==0)?  "\t\t.$p(noc_clk)":",\n\t\t.$p(noc_clk)";
		}else {
			$port=($i==0)?  "\t\t.$p($p)":",\n\t\t.$p($p)";			
		}
		$i=1;
		add_text_to_string(\$noc_v,$port);			
	}	
	add_text_to_string(\$noc_v,"\n\t);\n\n");		

add_text_to_string(\$noc_v,'	
	clk_source  src 	(
		.clk_in(clk),
		.clk_out(noc_clk),
		.reset_in(reset),
		.reset_out(noc_reset)
	);    
');	




add_text_to_string(\$noc_v,'	

//NoC port assignment
  genvar x,y;
  generate 
    for (x=0;   x<NX; x=x+1) begin :x_loop1
        for (y=0;   y<NY;   y=y+1) begin: y_loop1
                localparam IP_NUM   =   ((y * NX) +  x);           
             
           
            assign  ni_flit_in      [IP_NUM] =   flit_out_all    [(IP_NUM+1)*Fw-1    : IP_NUM*Fw];   
            assign  ni_flit_in_wr   [IP_NUM] =   flit_out_wr_all [IP_NUM]; 
            assign  credit_in_all   [(IP_NUM+1)*V-1 : IP_NUM*V]     =   ni_credit_out   [IP_NUM];  
            assign  flit_in_all     [(IP_NUM+1)*Fw-1    : IP_NUM*Fw]    =   ni_flit_out     [IP_NUM];
            assign  flit_in_wr_all  [IP_NUM] =   ni_flit_out_wr  [IP_NUM];
            assign  ni_credit_in    [IP_NUM] =   credit_out_all  [(IP_NUM+1)*V-1 : IP_NUM*V];
  
    
           
            
                        
        end
    end
endgenerate

'
);




















	return $noc_v;
	
}




sub gen_socs_v{
	my ($mpsoc,$io_v_ref,$io_def_v)=@_;
	#generate loop
	
#	my $socs_v='
#	genvar x,y;    
#    
#    generate 
#    for (x=0;   x<NX; x=x+1) begin :x_loop1
#        for (y=0;   y<NY;   y=y+1) begin: y_loop1
#                localparam IP_NUM   =   CORE_NUM(x,y);'  ;	
                
        
                
# 	my @socs= $mpsoc->mpsoc_get_soc_list();
# 	foreach my $soc (@socs){
   	
#  	#tile num condition
#		my @tiles= $mpsoc->mpsoc_get_soc_tiles_num($soc);
#	if(scalar @tiles>0){
#  		my $condition="\n\t\tif(";
# 		my $s=compress_nums( @tiles);
#		my @sep=split(',',$s);
#	   		my $i=0;
#	   		foreach my $p (@sep){
#	   			my @range=split(':',$p);
#	   			my $tt;
#	   			if($i==0){
#	   				$tt= (scalar @range>1)? "(IP_NUM>=$range[0] && IP_NUM<=$range[1])":"(IP_NUM==$range[0])" ;
#	   			}else{
#	   			}
#	   			add_text_to_string(\$condition,$tt);
#	   			$i=1;
#	   		}
#	   		add_text_to_string(\$condition,") begin :${soc}_if\n ");	
#	  		#soc instance
#	  		my $soc_v= gen_soc_v($mpsoc,$soc);
#	  
#	  		add_text_to_string(\$socs_v,$condition );
#	  		add_text_to_string(\$socs_v,$soc_v);
#	  		add_text_to_string(\$socs_v,"\t\tend // ${soc}_if \n");
#  		}#scalar @tile  
# }	#froeach soc
   
   
   
 my $socs_v;  
                
   my $nx= $mpsoc->mpsoc_get_param("NX");
   my $ny= $mpsoc->mpsoc_get_param("NY");
   my $processors_en=0;
   for (my $y=0;$y<$ny;$y++){
		for (my $x=0; $x<$nx;$x++){
			my $tile_num=($nx*$y)+ $x;
			
			my ($soc_name,$n,$soc_num)=$mpsoc->mpsoc_get_tile_soc_name($tile_num);
		
			if(defined $soc_name) {
				my ($soc_v,$en)= gen_soc_v($mpsoc,$soc_name,$tile_num,$x,$y,$soc_num,$io_v_ref,$io_def_v);
				add_text_to_string(\$socs_v,$soc_v);	
				$processors_en|=$en;
			}else{
				#this tile is not connected to any ip. the noc input ports will be connected to ground
				my $soc_v="\n\n // Tile:$tile_num (x=$x,y=$y)   is not assigned to any ip\n";
				$soc_v="$soc_v
	
	assign ni_credit_out[$tile_num]={V{1'b0}}; 
	assign ni_flit_out[$tile_num]={Fw{1'b0}}; 
	assign ni_flit_out_wr[$tile_num]=1'b0; 
	";
		add_text_to_string(\$socs_v,$soc_v);			
				
			}
	
	}}
                
    if($processors_en){
    	add_text_to_string($io_v_ref,",\n\tprocessors_en");
    	add_text_to_string($io_def_v,"\t input processors_en;");
    	
    }            
                

	return $socs_v;

}

##############
#	gen_soc_v
##############



sub   gen_soc_v{
	my ($mpsoc,$soc_name,$tile_num,$x,$y,$soc_num,$io_v_ref,$io_def_v)=@_;
	my $soc_v;
	my $processor_en=0;
	my $xw= log2($mpsoc->mpsoc_get_param("NX"));
	my $yw= log2($mpsoc->mpsoc_get_param("NY"));
	$soc_v="\n\n // Tile:$tile_num (x=$x,y=$y)\n   \t$soc_name #(\n";
	
	# core id
	add_text_to_string(\$soc_v,"\t\t.CORE_ID($tile_num)");
	
	# ni parameter
	my $top=$mpsoc->mpsoc_get_soc($soc_name);
	my @noc_param=$top->top_get_parameter_list('ni0');
	my $inst_name=$top->top_get_def_of_instance('ni0','instance');
	
	#other parameters
	my %params=$top->top_get_default_soc_param();
	
	foreach my $p (@noc_param){
		my $parm_next = $p;
		$parm_next =~ s/${inst_name}_//;
		my $param=  ",\n\t\t.$p($parm_next)"; 
		add_text_to_string(\$soc_v,$param);		
	}
	foreach my $p (sort keys %params){
		my $parm_next= "${soc_name}_${soc_num}_$p";
		my $param=  ",\n\t\t.$p($parm_next)"; 
		add_text_to_string(\$soc_v,$param);			
		
	}	
	
	add_text_to_string(\$soc_v,"\n\t)the_${soc_name}_$soc_num(\n");
	
	my @intfcs=$top->top_get_intfc_list();
	
	my $i=0;
	foreach my $intfc (@intfcs){
		
		# ni intfc	
		if( $intfc eq 'socket:ni[0]'){
			my @ports=$top->top_get_intfc_ports_list($intfc);
		
			foreach my $p (@ports){
				my($inst,$range,$type,$intfc_name,$intfc_port)= $top->top_get_port($p);
				my $q=($intfc_port eq "current_x")? "$xw\'d$x" : 
								  ($intfc_port eq "current_y")?	"$yw\'d$y" :"ni_$intfc_port\[$tile_num\]";
				add_text_to_string(\$soc_v,',') if ($i);	
				add_text_to_string(\$soc_v,"\n\t\t.$p($q)");
				$i=1;
			
				
			}			
		}
		# clk source
		elsif( $intfc eq 'plug:clk[0]'){
			my @ports=$top->top_get_intfc_ports_list($intfc);
			foreach my $p (@ports){
				my($inst,$range,$type,$intfc_name,$intfc_port)= $top->top_get_port($p);
				add_text_to_string(\$soc_v,',') if ($i);	
			    add_text_to_string(\$soc_v,"\n\t\t.$p(clk)");	
			    $i=1;	
				
			}	
		}		
		#reset
		elsif( $intfc eq 'plug:reset[0]'){
			my @ports=$top->top_get_intfc_ports_list($intfc);
			foreach my $p (@ports){
				my($inst,$range,$type,$intfc_name,$intfc_port)= $top->top_get_port($p);
				add_text_to_string(\$soc_v,',') if ($i);	
			    add_text_to_string(\$soc_v,"\n\t\t.$p(reset)");
			    $i=1;		
				
			}			
			
			
			
		}
		elsif( $intfc eq 'plug:enable[0]'){
			my @ports=$top->top_get_intfc_ports_list($intfc);
			foreach my $p (@ports){
				my($inst,$range,$type,$intfc_name,$intfc_port)= $top->top_get_port($p);
				add_text_to_string(\$soc_v,',') if ($i);	
			    add_text_to_string(\$soc_v,"\n\t\t.$p(processors_en)");
			    $processor_en=1;
			    $i=1;		
				
			}		
		
		
		}
		else {
		#other interface
			my @ports=$top->top_get_intfc_ports_list($intfc);
			foreach my $p (@ports){
			my($inst,$range,$type,$intfc_name,$intfc_port)= $top->top_get_port($p);
			my $io_port="${soc_name}_${soc_num}_${p}";
			#io name 
			add_text_to_string($io_v_ref,",\n\t$io_port");
			#io definition
			my $new_range = add_instantc_name_to_parameters(\%params,"${soc_name}_$soc_num",$range);
			#my $new_range=$range;
			my $port_def=(length ($range)>1 )? 	"\t$type\t [ $new_range    ] $io_port;\n": "\t$type\t\t\t$io_port;\n";			 
			
			
			add_text_to_string($io_def_v,"$port_def");
			add_text_to_string(\$soc_v,',') if ($i);	
			add_text_to_string(\$soc_v,"\n\t\t.$p($io_port)");	
			$i=1;	
				
			}		
			
			
		}	
		
		
	}
	
	add_text_to_string(\$soc_v,"\n\t);\n");	
	
	
	
	
	
	
	
	
	
	
	return ($soc_v,$processor_en);

}


sub log2{
	my $num=shift;
	my $log=0;    
	while( (1<<$log)  < $num) {    
				$log++;    
	}
	return  $log;  
}


1
