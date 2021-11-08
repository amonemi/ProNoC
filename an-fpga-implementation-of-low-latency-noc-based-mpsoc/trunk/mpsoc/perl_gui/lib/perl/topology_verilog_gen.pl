use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;




sub generate_topology_top_v {
	my ($self,$info,$dir)=@_;
	
		
	#create topology top file
	my $name=$self->object_get_attribute('save_as');
	
	my $r; 
	my $top="$dir/${name}_noc.sv";
    open my $fd, ">$top" or $r = "$!\n";
    if(defined $r) {
    	add_colored_info($info,"Error in creating $top: $r",'red');
		return;
    } 
    print $fd autogen_warning();
    print $fd get_license_header($top);   

   
    my $param_str ="\tparameter TOPOLOGY = \"$name\",
\tparameter ROUTE_NAME = \"${name}_DETERMINISTIC\"";

   my @parameters=@{$self->object_get_attribute ('Verilog','Router_param')};
   my @ports= @{$self->object_get_attribute('Verilog','Router_ports')}; 
    
#	foreach my $d (@parameters){
#		$param_str = $param_str.",\n\tparameter $d->{param_name} = $d->{value}";
#	}
 
    my @ends=get_list_of_all_endpoints($self);
    my @routers=get_list_of_all_routers($self);
    
    my $MAX_P=0;
    foreach my $p (@routers){
    	my $Pnum=$self->object_get_attribute("$p",'PNUM');
    	$MAX_P =$Pnum  if($Pnum>$MAX_P );    	
    }	

    my $NE= scalar @ends;
    my $NR= scalar @routers;

   

	
	
	#step 2 	add routers
	my @nodes=get_list_of_all_routers($self);
	my $i=0;
	
	my $ports="\treset,
\tclk";
	my $wires='',
	my $routers='';
	
	foreach my $p (@ends){
		my $instance= $self->object_get_attribute("$p","NAME");	
		$ports=$ports.",\n\t//$instance";
		$wires=$wires."
	/*******************
	*		$instance
	*******************/
";
		
		$wires=$wires."\tinput  smartflit_chanel_t ${instance}_chan_in;\n";
		$wires=$wires."\toutput smartflit_chanel_t ${instance}_chan_out;\n";
		$ports=$ports.",\n\t${instance}_chan_in,\n\t${instance}_chan_out";
		
		foreach my $d (@ports){		
				my $range = ($d->{pwidth} eq 1)? " " :  " [$d->{pwidth}-1 : 0]";
				my $type=$d->{type};
				my $ctype= ($type eq 'input')? 'output' : 'input';	
				if( $d->{endp} eq "yes"){ 	    	 
					#$wires=$wires."\t$type $range ${instance}_$d->{pname};\n";
					#$wires=$wires."\t$ctype $range ${instance}_$d->{pconnect};\n";
					#$ports=$ports.",\n\t${instance}_$d->{pname},\n\t${instance}_$d->{pconnect}";
				}
		}	
	}
	
	
	foreach my $p (@nodes){
		
		my ($wire,$router) = get_router_instance_v($self,$p,$i,$NE,$NR,$MAX_P);
		$wires=$wires.$wire,
		$routers=$routers.$router;
		 
		
		$i++;
	}
	
	my $assign="";
	foreach my $p (@ends){
		my $instance= $self->object_get_attribute("$p","NAME");	
		my $pname= "Port[0]";
		my $connect = $self->{$p}{'PCONNECT'}{$pname};
		if(defined $connect){
			my ($cname,$pnode)=split(/\s*,\s*/,$connect);
			my $cinstance= $self->object_get_attribute("$cname","NAME");
			my ($cp)= sscanf("Port[%u]","$pnode");
			#$assign = $assign."//Connect $instance output ports 0 to  $cinstance input ports $cp\n";
			my $cpplus=$cp+1;
			
		
			foreach my $p (@ports){	
				my $w=$p->{pwidth};
				my $range = ($w eq 1)? 	" " : "[$w-1 : 		 0 ]";
				my $crange = ($w eq 1)? "[$cp]"	: "[($cpplus*$w)-1 :	 $cp*$w ]";
				my $cport =  "${cinstance}_$p->{connect}";
				my $port ="${instance}_$p->{pconnect}";
				if($p->{type} eq 'input' ){						
					# $assign=  $assign."\t\tassign  $port $range = $cport $crange;\n" if($p->{endp} eq "yes");		
				}else{
					# $assign=  $assign."\t\tassign  $cport $crange= $port $range;\n" if($p->{endp} eq "yes");		
				}	
				
			 }	#@port
		}

	}
	
	
	
	
	 print $fd "
module   ${name}_noc
	import pronoc_pkg::*; 
	(
   $ports
);
	
	 function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end 	   
      end   
    endfunction // log2 

	localparam 
		NE = $NE,
		NR = $NR,
		RAw=log2(NR);
       
      

    
    input reset,clk;    
       
    $wires
    
    $routers
    
    $assign
             
endmodule
";
	add_info($info,"$top file is created\n  ");
	close $fd;
	
	
}




sub get_router_instance_v {
	my ($self,$rname,$current_r,$NE,$NR,$MAX_P)=@_;
	
	
	my $instance= $self->object_get_attribute("$rname","NAME");		
	my $Pnum=$self->object_get_attribute("$rname",'PNUM');
	
	#read ruter parameters and ports
	 my @parameters=@{$self->object_get_attribute ('Verilog','Router_param')};
     my @ports= @{$self->object_get_attribute('Verilog','Router_ports')}; 
	
	my $wires_v="
	/*******************
	*		$instance
	*******************/
\twire ${instance}_clk;
\twire ${instance}_reset;

\twire [RAw-1 :  0] ${instance}_current_r_addr;

\tsmartflit_chanel_t    ${instance}_chan_in   [$Pnum-1 : 0];
\tsmartflit_chanel_t    ${instance}_chan_out  [$Pnum-1 : 0]; 

";

	

	
	my $router_v="	
	/*******************
	*		$instance
	*******************/
	router_top #(
		.P($Pnum)		
	)
	$instance
	(	
		.clk(${instance}_clk), 
		.reset(${instance}_reset),
		.current_r_addr  (${instance}_current_r_addr), 
		.chan_in   (${instance}_chan_in), 
		.chan_out  (${instance}_chan_out)
	);
";

	
$router_v= $router_v."
\t\tassign ${instance}_clk = clk;
\t\tassign ${instance}_reset = reset;
\t\tassign ${instance}_current_r_addr = $current_r;
"; 


		

for (my $i=0;$i<$Pnum; $i++){ 
	my $pname= "Port[${i}]";
	my $connect = $self->{$rname}{'PCONNECT'}{$pname};
	my $iplus=$i+1;
	if(defined $connect){
		my ($cname,$pnode)=split(/\s*,\s*/,$connect);
		my $cinstance= $self->object_get_attribute("$cname","NAME");
		my $ctype = $self->object_get_attribute("$cname",'TYPE'); 		
		my ($cp)= sscanf("Port[%u]","$pnode");
		$router_v = $router_v."//Connect $instance port $i to  $cinstance port $cp\n";
		if($ctype ne 'ENDP'){
			$router_v.=" \t\tassign ${instance}_chan_in [$i]   = ${cinstance}_chan_out [$cp];\n";			
		}else{
			$router_v.=" \t\tassign ${instance}_chan_in [$i]  = ${cinstance}_chan_in;\n";
			$router_v.=" \t\tassign ${cinstance}_chan_out = ${instance}_chan_out [$i];\n";
		}
		my $cpplus=$cp+1;
		    	
		#{name=> "flit_in_all", type=>"input", width=>"PFw", connect=>"flit_out_all",  pwidth=>"Fw" },
		
		
		
		foreach my $p (@ports){	
			my $w=$p->{pwidth};
			my $range = ($w eq 1)? 	"[$i]" : "[($iplus*$w)-1 : 		 $i*$w ]";
			my $crange = ($ctype eq 'ENDP') ? '' :
			($w eq 1)? "[$cp]"	: "[($cpplus*$w)-1 :	 $cp*$w ]";
			my $cport = ($ctype eq 'ENDP') ? "${cinstance}_$p->{pname}" : "${cinstance}_$p->{connect}";
			my $port ="${instance}_$p->{name}";
			if($ctype eq 'ENDP' && $p->{endp} eq "no" && $p->{type} eq 'input' ){						
				# $router_v=  $router_v."\t\tassign  $port $range = 0;\n";		
						
			}else{
				if($p->{type} eq 'input' ){						
				# $router_v=  $router_v."\t\tassign  $port $range = $cport $crange;\n";		
				}else{
				# $router_v=  $router_v."\t\tassign  $cport $crange= $port $range;\n";	
				}	
			}
		 }	#@port
			
	}else {
			$router_v = $router_v."//Connect $instance port $i to  ground
\t	assign  ${instance}_chan_in [$i]= {SMARTFLIT_CHANEL_w{1'b0}};\n";
			
			foreach my $p (@ports){	
				my $w=$p->{pwidth};
				my $range = ($w eq 1)? 	"[$i]" : "[($iplus*$w)-1 : 		 $i*$w ]";
				if($p->{type} eq 'input' ){		
			 	#	$router_v=  $router_v."\t\tassign  ${instance}_$p->{name} $range = \{$w\{1'b0\}\};\n";		
				}
			}	
	}		
			
}	
	
	
	return ($wires_v,$router_v);		
}



#*******************
#	generate_topology_top_genvar_v
#********************


sub generate_topology_top_genvar_v{
	my ($self,$info,$dir)=@_;
	
		
	#create topology top file
	my $name=$self->object_get_attribute('save_as');
	my $r; 
	my $top="$dir/${name}_noc_genvar.sv";
    open my $fd, ">$top" or $r = "$!\n";
    if(defined $r) {
    	add_colored_info($info,"Error in creating $top: $r",'red');
		return;
    } 
    print $fd autogen_warning();
    print $fd get_license_header($top);   

   
    my $param_str ="\tparameter TOPOLOGY = \"$name\",
\tparameter ROUTE_NAME = \"${name}_DETERMINISTIC\"";

   my @parameters=@{$self->object_get_attribute ('Verilog','Router_param')};
   my @ports= @{$self->object_get_attribute('Verilog','Router_ports')}; 
    
	foreach my $d (@parameters){
		$param_str = $param_str.",\n\tparameter $d->{param_name} = $d->{value}";
	}
 
    my @ends=get_list_of_all_endpoints($self);
    my @routers=get_list_of_all_routers($self);
    
    my $MAX_P=0;
    foreach my $p (@routers){
    	my $Pnum=$self->object_get_attribute("$p",'PNUM');
    	$MAX_P =$Pnum  if($Pnum>$MAX_P );    	
    }	

    my $NE= scalar @ends;
    my $NR= scalar @routers;

   	
	
	my @nodes=get_list_of_all_routers($self);
	my $i=0;
	
	my $ports="\treset,
\tclk,
\tchan_in_all,
\tchan_out_all  
";
    my $ports_def="
\tinput  reset;
\tinput  clk;
\tinput  smartflit_chanel_t chan_in_all  [NE-1 : 0];
\toutput smartflit_chanel_t chan_out_all [NE-1 : 0];

//all routers port 
\tsmartflit_chanel_t    router_chan_in   [NR-1 :0][MAX_P-1 : 0];
\tsmartflit_chanel_t    router_chan_out  [NR-1 :0][MAX_P-1 : 0];

\twire [RAw-1 : 0] current_r_addr [NR-1 : 0];


";

	my $router_wires="";
	my $endps_wires="";

	
	
	
	foreach my $d (@ports){		
		my $range = ($d->{width} eq 1)? " " :  " [$d->{width}-1 : 0]";	
		my $pdef_range = ($d->{pwidth} eq 1)? "[NE-1 : 0]" : "[(NE*$d->{pwidth})-1 : 0]";
		my $endp_range = "[$d->{pwidth}-1 : 0]";
		my $type=$d->{type};
		my $ctype= ($type eq 'input')? 'output' : 'input';
		if( $d->{endp} eq "yes"){ 	    	 
			#$ports_def=$ports_def."\t$type $pdef_range $d->{name};\n";
			#$ports_def=$ports_def."\t$ctype $pdef_range $d->{connect};\n";			
			#$ports=$ports.",\n\t$d->{name},\n\t$d->{connect}";
		}	
			if($d->{width} eq 1){
				#$router_wires=$router_wires. "\twire [NR-1 :0] router_$d->{name};\n";
				#$router_wires=$router_wires. "\twire [NR-1 :0] router_$d->{connect};\n";
			}else{	
				#$router_wires=$router_wires. "\twire $range router_$d->{name} [NR-1 :0];\n";
				#$router_wires=$router_wires. "\twire $range router_$d->{connect} [NR-1 :0];\n";
			}
		if( $d->{endp} eq "yes"){ 		
		    if($d->{pwidth} eq 1){
		    	#$endps_wires=$endps_wires. "\twire [NE-1 :0] ni_$d->{pname};\n";
				#$endps_wires=$endps_wires. "\twire [NE-1 :0] ni_$d->{pconnect};\n";
		    }else{	
				#$endps_wires=$endps_wires. "\twire $endp_range ni_$d->{pname} [NE-1 :0];\n";
				#$endps_wires=$endps_wires. "\twire $endp_range ni_$d->{pconnect} [NE-1 :0];\n";
		    }
			
		}
	}	
		
	
	
	
	#step 2 	add routers
	my $Tnum=1;
	
	my $routers='
	genvar i;
	generate	
	';
	my $offset=0;
	my $assign="";
	my $assign_h="";
	my $init_h="";
	my %new_h;
	my $addr=0;
	for ( my $i=2;$i<=12; $i++){
		my $n= $self->object_get_attribute("ROUTER${i}","NUM");
		$n=0 if(!defined $n);
		if($n>0){	
						
			for(my $rr=0; $rr<$n; $rr=$rr+1) {
				my $pos= ($offset==0)? $rr : $rr+$offset;
				$new_h{"TNUM_${pos}"}="$Tnum";
				$new_h{"RNUM_${pos}"}="$rr";
				
				$init_h.="router${Tnum}[$rr]->current_r_addr=$addr;\n";
				$addr++;
			}	
			$offset+=	$n;
			$Tnum++;		
		}
	}
	
	
	
	
	
	
	
	$offset=0;
	
	for ( my $i=2;$i<=12; $i++){
		my $n= $self->object_get_attribute("ROUTER${i}","NUM");
		$n=0 if(!defined $n);
		if($n>0){	
			my $router_pos= ($offset==0)? 'i' : "i+$offset";
			#my $instant=get_router_genvar_instance_v($self,$i,$router_pos,$NE,$NR,$MAX_P);
					
			$routers=$routers."
\tfor( i=0; i<$n; i=i+1) begin : router_${i}_port_lp

	router_top #(
		.P($i)
	)
	router_${i}_port
	(	
		.clk(clk), 
		.reset(reset),
		.current_r_addr($router_pos),	
		.chan_in  (router_chan_in\[$router_pos\]), 
		.chan_out (router_chan_out\[$router_pos\])		
	);
    
    
    
\tend    
			";
	
			for ( my $j=0;$j<$n; $j++){
				my $rname ="ROUTER${i}_$j";
				my ($ass_v,$ass_h)=get_wires_assignment_genvar_v($self,$rname,0,\%new_h);
				
				$assign=$assign.$ass_v;
				$assign_h.=$ass_h;
			}
			
		$offset+=	$n;
		
		}	
	}
	
	
$routers.="endgenerate\n";	
	
	
	
	
	
	
	 print $fd "
module   ${name}_noc_genvar 
   import pronoc_pkg::*; 
	(

    reset,
    clk,    
    chan_in_all,
    chan_out_all  
);

	 function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end 	   
      end   
    endfunction // log2 

	localparam 
		NE = $NE,
		NR = $NR,
		RAw=log2(NR),
		MAX_P=$MAX_P;
	
    
$ports_def

$router_wires

$endps_wires
   
$routers

$assign  

  
             
endmodule
";
	
	close $fd;
	add_info($info,"$top file is created\n  ");

	my $project_dir	= get_project_dir();
	$project_dir= "$project_dir/mpsoc";
	my $src_verilator_dir="$project_dir/src_verilator/topology/custom";
	mkpath("$src_verilator_dir",1,01777) unless -f $src_verilator_dir;
    $top="$src_verilator_dir/${name}_noc.h";
    open $fd, ">$top" or $r = "$!\n";
    if(defined $r) {
    	add_colored_info($info,"Error in creating $top: $r",'red');
		return;
    } 
    print $fd "



void topology_connect_all_nodes (void){
   	 $assign_h
}

void topology_init(void){
	$init_h
}
";
    close $fd;
	add_info($info,"$top file is created\n  ");
	
}




sub get_router_genvar_instance_v{
	my ($self,$Pnum,$router_pos,$NE,$NR,$MAX_P)=@_;

	#read ruter parameters and ports
	my @parameters=@{$self->object_get_attribute ('Verilog','Router_param')};
    my @ports= @{$self->object_get_attribute('Verilog','Router_ports')}; 
	
	
	
	my $router_v="	
	
	router_top #(
		.P($Pnum)
	)
	router_${Pnum}_port
	(	
		.clk(clk), 
		.reset(reset),
		.current_r_addr($router_pos),
		.chan_in (router_chan_in\[$router_pos\]), 
		.chan_out(router_chan_out\[$router_pos\])		
	);
	
	
	
";

return $router_v;


}


sub get_wires_assignment_genvar_v{
	my ($self,$rname,$reverse,$cref)=@_;
    $reverse = 0 if(!defined $reverse);
	my $instance= $self->object_get_attribute("$rname","NAME");		
	my $Pnum=$self->object_get_attribute("$rname",'PNUM');
	
	#read ruter parameters and ports
	 my @parameters=@{$self->object_get_attribute ('Verilog','Router_param')};
     my @ports= @{$self->object_get_attribute('Verilog','Router_ports')}; 

	my $assign="";
	my $ass_h="";

	my @ends=get_list_of_all_endpoints($self);
    my @routers=get_list_of_all_routers($self);

	my $pos = get_scolar_pos($rname,@routers);
	my $type = "ROUTER";
	if(!defined $pos){
		$pos = get_scolar_pos($rname,@ends);
		$type = "ENDP";
	}
	
	my %rinfo = %{$cref} if (defined $cref);
	
for (my $i=0;$i<$Pnum; $i++){ 
	my $pname= "Port[${i}]";
	my $connect = $self->{$rname}{'PCONNECT'}{$pname};
	my $iplus=$i+1;
	if(defined $connect){
		my ($cname,$pnode)=split(/\s*,\s*/,$connect);
		my $cinstance= $self->object_get_attribute("$cname","NAME");
		my $ctype = $self->object_get_attribute("$cname",'TYPE'); 		
		my ($cp)= sscanf("Port[%u]","$pnode");
		$assign.="//Connect $instance input ports $i to  $cinstance output ports $cp\n";
		$ass_h.="//Connect $instance input ports $i to  $cinstance output ports $cp\n";
		
		my $cpos =($ctype eq 'ENDP')?  get_scolar_pos($cname,@ends) :  get_scolar_pos($cname,@routers);
		
		my $cpplus=$cp+1;
		my $cposplus = $cpos+1;
		my $posplus=$pos+1;    	
		#{name=> "flit_in_all", type=>"input", width=>"PFw", connect=>"flit_out_all",  pwidth=>"Fw" },
		
		my $TNUM_pos  = $rinfo{"TNUM_${pos}"};  
		my $RNUM_pos  = $rinfo{"RNUM_${pos}"};  
		my $TNUM_cpos = $rinfo{"TNUM_${cpos}"};
		my $RNUM_cpos = $rinfo{"RNUM_${cpos}"};
		
		#$assign = $assign."//connet  $instance input port $i to  $cinstance output port $cp\n";
		if($type  ne 'ENDP'  &&  $ctype eq 'ENDP'){
			$assign=  $assign."\t\tassign  router_chan_in \[$pos\]\[$i\] = chan_in_all \[$cpos\];\n" if($reverse==0);
			$assign=  $assign."\t\tassign  chan_in_all \[$cpos\] = router_chan_in \[$pos\]\[$i\];\n" if($reverse==1);
		
			$assign=  $assign."\t\tassign  chan_out_all \[$cpos\] = router_chan_out \[$pos\]\[$i\];\n" if($reverse==0);
			$assign=  $assign."\t\tassign  router_chan_out \[$pos\]\[$i\] = chan_out_all \[$cpos\];\n" if($reverse==1);
			
			$ass_h.=  "\tconnect_r2e($TNUM_pos,$RNUM_pos,$i,$cpos);\n"	if (defined $TNUM_pos);	
			
		
		}elsif ($type  ne 'ENDP'  &&  $ctype ne 'ENDP'){
			$assign=  $assign."\t\tassign  router_chan_in \[$pos\]\[$i\] = router_chan_out \[$cpos\]\[$cp\];\n" if($reverse==0);
			$assign=  $assign."\t\tassign  router_chan_out \[$cpos\]\[$cp\] = router_chan_in \[$pos\]\[$i\];\n" if($reverse==1);			
			$ass_h.=  "\tconect_r2r($TNUM_pos,$RNUM_pos,$i,$TNUM_cpos,$RNUM_cpos,$cp);\n" if (defined $TNUM_pos);	
			
		}
				
		
		
		
			
	}else {
			my $TNUM_pos  = $rinfo{"TNUM_${pos}" };  
			my $RNUM_pos  = $rinfo{"RNUM_${pos}" };  
		
			$assign = $assign."//Connect $instance port $i to  ground\n";
			$ass_h.="//Connect $instance port $i to  ground\n";
			$assign=  $assign."\t\tassign  router_chan_in  \[$pos\]\[$i\] ={SMARTFLIT_CHANEL_w{1'b0}};\n	" if($reverse==0);
			$assign=  $assign."\t\tassign  router_chan_out \[$pos\]\[$i\] ={SMARTFLIT_CHANEL_w{1'b0}};\n	" if($reverse==1);	
			$ass_h.=  "\tconnect_r2gnd($TNUM_pos,$RNUM_pos,$i);\n" if (defined $TNUM_pos);			
	}		
			
}	

	return ($assign,$ass_h);
}





sub generate_routing_v {
	my ($self,$info,$dir)=@_;
	
	my @ends=get_list_of_all_endpoints($self);
	my @routers=get_list_of_all_routers($self);
	
#########################	
#  conventional_routing
#########################


	#create routing file
	my $name=$self->object_get_attribute('save_as');
	my $rname=$self->object_get_attribute('routing_name');
	my $Vname="T${name}R${rname}";
	
	my $r; 
	my $top="$dir/${Vname}_conventional_routing.v";
    open my $fd, ">$top" or $r = "$!\n";
    if(defined $r) {
    	add_colored_info($info,"Error in creating $top: $r",'red');
		return;
    } 
    print $fd autogen_warning();
    print $fd get_license_header($top);   
	
	
	
	
	
	my $route_str="\talways@(*)begin
\t\tdestport=0;
\t\tcase(src_e_addr) //source address of each individual NI is fixed. So this CASE will be optimized by the synthesizer for each endpoint. 
";
	
	foreach my $src (@ends){
		my $PNUM=$self->object_get_attribute($src,"PNUM");
		my $src_num=get_scolar_pos($src,@ends);
	    my %route;		
		$route_str=$route_str."\t\t$src_num: begin
\t\t\tcase(dest_e_addr)
";
		
		foreach my $dst (@ends){
			    my $dest_num = get_scolar_pos($dst,@ends);
				my $ref = $self->object_get_attribute('Route',"${src}::$dst");
				next if(!defined $ref);
				my @path = @{$ref};
				my ($p1,$p2)= get_connection_port_num_between_two_nodes($self,$path[1],$path[2] );
				#print " ($p1,$p2)= get_connection_port_num_between_two_nodes($self,$path[1],$path[2] );\n";
				$route{$p1} = (defined $route{$p1})? $route{$p1}.",$dest_num" : "$dest_num";						
		}
		foreach my $q (sort {$a <=> $b} keys %route){
			$route_str=$route_str."\t\t\t$route{$q}: begin 
\t\t\t\tdestport= $q; 
\t\t\tend
";
		}
		$route_str=$route_str."
\t\t\tdefault: begin 
\t\t\t\tdestport= {DSTPw{1\'bX}};
\t\t\tend
\t\t\tendcase\n\t\tend//$src_num\n";
	}
	$route_str=$route_str."
\t\tdefault: begin 
\t\t\tdestport= {DSTPw{1\'bX}};
\t\tend
\t\tendcase\n\tend\n";

	
	
	 print $fd "module ${Vname}_conventional_routing  #(
\tparameter RAw = 3,  
\tparameter EAw = 3,   
\tparameter DSTPw=4  
)
(
\tdest_e_addr,
\tsrc_e_addr,
\tdestport        
);
    
\tinput   [EAw-1   :0] dest_e_addr;
\tinput   [EAw-1   :0] src_e_addr;
\toutput reg [DSTPw-1 :0] destport;	
        
    
$route_str
		
	
endmodule  
    
";
close($fd);
add_info($info,"$top file is created\n  ");

##################
#   look_ahead_routing
###################

#create routing file
	$top="$dir/${Vname}_look_ahead_routing.v";
    open  $fd, ">$top" or $r = "$!\n";
    if(defined $r) {
    	add_colored_info($info,"Error in creating $top: $r",'red');
		return;
    } 
    print $fd autogen_warning();
    print $fd get_license_header($top);   


	$route_str="\talways@(*)begin
\t\tdestport=0;
\t\tcase(current_r_addr) //current_r_addr of each individual router is fixed. So this CASE will be optimized by the synthesizer for each router. 
";



foreach my $router (@routers){
		my $PNUM=$self->object_get_attribute($router,"PNUM");
		my $router_num=get_scolar_pos($router,@routers);
	    my %route;		
		$route_str=$route_str."\t\t$router_num: begin
\t\t\tcase({src_e_addr,dest_e_addr})
";
	# for each src-dest check if $router include in path 
	foreach my $src (@ends){
		foreach my $dst (@ends){
			my $ref = $self->object_get_attribute('Route',"${src}::$dst");
			next if(!defined $ref);
			my @path = @{$ref};
		    my $loc= get_scolar_pos($router,@path);
		    next if(!defined $loc);# this router does not exist in path skip it
		    my $next_router1=$path[$loc+1];
		    my $next_router2=$path[$loc+2];
		    next if(!defined $next_router2);
		    my ($p1,$p2)= get_connection_port_num_between_two_nodes($self,$next_router1,$next_router2);		    
		    next if(!defined $p1);
		    my $src_num=get_scolar_pos($src,@ends);
		    my $dest_num = get_scolar_pos($dst,@ends);
			$route{$p1} = (defined $route{$p1})? $route{$p1}.",{E$src_num,E$dest_num}" : "{E$src_num,E$dest_num}";
			
			#print "@path\n";
			#print "(current_router, next_router1, next_router2)=($router, $next_router1, $next_router2)\n";
			#print "($p1,$p2)= get_connection_port_num_between_two_nodes(\$self,$next_router1,$next_router2)\n";	
			#print "\$route{$p1} ={E$src_num,E$dest_num}\n";
			#print"***************************\n"; 
			
		}
	}
	foreach my $q (sort {$a <=> $b} keys %route){
			$route_str=$route_str."\t\t\t$route{$q}: begin 
\t\t\t\tdestport= $q; 
\t\t\tend
";		
					
	}				
		
	$route_str.="\t\t\tdefault: begin 
\t\t\t\tdestport= {DSTPw{1\'bX}};
\t\t\tend
\t\t\tendcase\n\t\tend//$router_num\n";
	}
$route_str.="\t\tdefault: begin 
\t\t\tdestport= {DSTPw{1\'bX}};
\t\tend
\t\tendcase\n\tend\n";
	


my $localparam="";
	my $i=0;
	foreach my $src (@ends){
		$localparam= $localparam."localparam [EAw-1 : 0]\tE$i=$i;\n";
		$i++;
	}	
	



 print $fd "
/*******************
*  ${Vname}_look_ahead_routing
*******************/  
module ${Vname}_look_ahead_routing  #(
\tparameter RAw = 3,  
\tparameter EAw = 3,   
\tparameter DSTPw=4  
)
(
\treset,
\tclk,
\tcurrent_r_addr,
\tdest_e_addr,
\tsrc_e_addr,
\tdestport        
);
    
\tinput   [RAw-1   :0] current_r_addr;
\tinput   [EAw-1   :0] dest_e_addr;
\tinput   [EAw-1   :0] src_e_addr;
\toutput  [DSTPw-1 :0] destport;	
\tinput reset,clk;

	reg [EAw-1   :0] dest_e_addr_delay;
	reg [EAw-1   :0] src_e_addr_delay;

	always @(posedge clk)begin 
		if(reset)begin 
			dest_e_addr_delay<={EAw{1'b0}};
			src_e_addr_delay<={EAw{1'b0}};			
		end else begin 
			dest_e_addr_delay<=dest_e_addr;
			src_e_addr_delay<=src_e_addr;					
		end 	
	end

	${Vname}_look_ahead_routing_comb  #(
		.RAw(RAw),  
		.EAw(EAw),   
		.DSTPw(DSTPw)  
	)
	lkp_cmb
	(
		.current_r_addr(current_r_addr),
		.dest_e_addr(dest_e_addr_delay),
		.src_e_addr(src_e_addr_delay),
		.destport(destport)        
	);


	
endmodule  
 
/*******************
*  ${Vname}_look_ahead_routing_comb
*******************/ 
  
 module ${Vname}_look_ahead_routing_comb  #(
\tparameter RAw = 3,  
\tparameter EAw = 3,   
\tparameter DSTPw=4  
)
(
\tcurrent_r_addr,
\tdest_e_addr,
\tsrc_e_addr,
\tdestport        
);
    
\tinput   [RAw-1   :0] current_r_addr;
\tinput   [EAw-1   :0] dest_e_addr;
\tinput   [EAw-1   :0] src_e_addr;
\toutput reg [DSTPw-1 :0] destport;	

$localparam
        
$route_str  

	
endmodule  


";

close($fd);
add_info($info,"$top file is created\n  ");

#########################	
#  conventional_routing_genvar
#########################


	#create routing file
	$top="$dir/${Vname}_conventional_routing_genvar.v";
    open $fd, ">$top" or $r = "$!\n";
    if(defined $r) {
    	add_colored_info($info,"Error in creating $top: $r",'red');
		return;
    } 
    print $fd autogen_warning();
    print $fd get_license_header($top);   
	
	
	
	
	
	$route_str="\tgenerate

";
	
	foreach my $src (@ends){
		my $PNUM=$self->object_get_attribute($src,"PNUM");
		my $src_num=get_scolar_pos($src,@ends);
	    my %route;		
		$route_str=$route_str."\tif(SRC_E_ADDR == $src_num) begin : SRC$src_num
\t\talways@(*)begin	
\t\t\tdestport= 0; 
\t\t\tcase(dest_e_addr)
";
		
		foreach my $dst (@ends){
			    my $dest_num = get_scolar_pos($dst,@ends);
				my $ref = $self->object_get_attribute('Route',"${src}::$dst");
				next if(!defined $ref);
				my @path = @{$ref};
				my ($p1,$p2)= get_connection_port_num_between_two_nodes($self,$path[1],$path[2] );
				#print " ($p1,$p2)= get_connection_port_num_between_two_nodes($self,$path[1],$path[2] );\n";
				$route{$p1} = (defined $route{$p1})? $route{$p1}.",$dest_num" : "$dest_num";						
		}
		foreach my $q (sort {$a <=> $b} keys %route){
			$route_str=$route_str."\t\t\t$route{$q}: begin 
\t\t\t\tdestport= $q; 
\t\t\tend
";
		}
		$route_str=$route_str."\t\t\tdefault: begin 
\t\t\t\tdestport= {DSTPw{1\'bX}};
\t\t\tend

\t\t\tendcase\n\t\tend\n\tend//SRC$src_num\n\n";
	}
	$route_str=$route_str."\tendgenerate\n";

	
	
	 print $fd "module ${Vname}_conventional_routing_genvar  #(
\tparameter RAw = 3,  
\tparameter EAw = 3,   
\tparameter DSTPw=4,
\tparameter SRC_E_ADDR=0  
)
(
\tdest_e_addr,
\tdestport        
);
    
\tinput   [EAw-1   :0] dest_e_addr;
\toutput reg [DSTPw-1 :0] destport;	
        
    
$route_str
		
	
endmodule  
    
";
close($fd);
add_info($info,"$top file is created\n  ");

##################
#   look_ahead_routing_genvar
###################

#create routing file
	$top="$dir/${Vname}_look_ahead_routing_genvar.v";
    open  $fd, ">$top" or $r = "$!\n";
    if(defined $r) {
    	add_colored_info($info,"Error in creating $top: $r",'red');
		return;
    } 
    print $fd autogen_warning();
    print $fd get_license_header($top);   



	$route_str="\talways@(*)begin
\t\tdestport=0;
\t\tcase(current_r_addr) //current_r_addr of each individual router is fixed. So this CASE will be optimized by the synthesizer for each router. 
";

$route_str="\tgenerate\n";


foreach my $router (@routers){
		my $PNUM=$self->object_get_attribute($router,"PNUM");
		my $router_num=get_scolar_pos($router,@routers);
	    my %route;		
		$route_str=$route_str."\tif(CURRENT_R_ADDR == $router_num) begin :R$router_num
\t\talways@(*)begin	
\t\t\tdestport= 0; 
\t\t\tcase({src_e_addr,dest_e_addr})
";
	# for each src-dest check if $router include in path 
	foreach my $src (@ends){
		foreach my $dst (@ends){
			my $ref = $self->object_get_attribute('Route',"${src}::$dst");
			next if(!defined $ref);
			my @path = @{$ref};
		    my $loc= get_scolar_pos($router,@path);
		    next if(!defined $loc);# this router does not exist in path skip it
		    my $next_router1=$path[$loc+1];
		    my $next_router2=$path[$loc+2];
		    next if(!defined $next_router2);
		    my ($p1,$p2)= get_connection_port_num_between_two_nodes($self,$next_router1,$next_router2);		    
		    next if(!defined $p1);
		    my $src_num=get_scolar_pos($src,@ends);
		    my $dest_num = get_scolar_pos($dst,@ends);
			$route{$p1} = (defined $route{$p1})? $route{$p1}.",{E$src_num,E$dest_num}" : "{E$src_num,E$dest_num}";
			
			#print "@path\n";
			#print "(current_router, next_router1, next_router2)=($router, $next_router1, $next_router2)\n";
			#print "($p1,$p2)= get_connection_port_num_between_two_nodes(\$self,$next_router1,$next_router2)\n";	
			#print "\$route{$p1} ={E$src_num,E$dest_num}\n";
			#print"***************************\n"; 
			
		}
	}
	foreach my $q (sort {$a <=> $b} keys %route){
			$route_str=$route_str."\t\t\t$route{$q}: begin 
\t\t\t\tdestport= $q; 
\t\t\tend
";		
					
	}				
		
	$route_str=$route_str."\t\t\tendcase\n\t\tend\n\tend//R$router_num\n\n";
	}
	$route_str=$route_str."\tendgenerate\n";
	


 print $fd "
/*****************************
*	${Vname}_look_ahead_routing_genvar
******************************/ 
module ${Vname}_look_ahead_routing_genvar  #(
\tparameter RAw = 3,  
\tparameter EAw = 3,   
\tparameter DSTPw=4,
\tparameter CURRENT_R_ADDR=0
)
(
\tdest_e_addr,
\tsrc_e_addr,
\tdestport,
\treset,
\tclk        
);

\tinput   [EAw-1   :0] dest_e_addr;
\tinput   [EAw-1   :0] src_e_addr;
\toutput  [DSTPw-1 :0] destport;
\tinput reset,clk;

	reg [EAw-1   :0] dest_e_addr_delay;
	reg [EAw-1   :0] src_e_addr_delay;

	always @(posedge clk)begin 
		if(reset)begin 
			dest_e_addr_delay<={EAw{1'b0}};
			src_e_addr_delay<={EAw{1'b0}};			
		end else begin 
			dest_e_addr_delay<=dest_e_addr;
			src_e_addr_delay<=src_e_addr;					
		end 	
	end

	${name}_look_ahead_routing_genvar_comb  #(
		.RAw(RAw),  
		.EAw(EAw),   
		.DSTPw(DSTPw),
		.CURRENT_R_ADDR(CURRENT_R_ADDR)  
	)
	lkp_cmb
	(
		
		.dest_e_addr(dest_e_addr_delay),
		.src_e_addr(src_e_addr_delay),
		.destport(destport)        
	);


	
endmodule   
 
/*******************
* ${Vname}_look_ahead_routing_genvar_comb
********************/ 
  
 
 module ${Vname}_look_ahead_routing_genvar_comb  #(
\tparameter RAw = 3,  
\tparameter EAw = 3,   
\tparameter DSTPw=4,
\tparameter CURRENT_R_ADDR=0
)
(
\tdest_e_addr,
\tsrc_e_addr,
\tdestport        
);

\tinput   [EAw-1   :0] dest_e_addr;
\tinput   [EAw-1   :0] src_e_addr;
\toutput  reg [DSTPw-1 :0] destport;

$localparam
        
$route_str  

	
endmodule  


";


close($fd);
add_info($info,"$top file is created\n  ");

}



sub generate_connection_v{
	my($self,$info,$dir)=@_;
	
	#create connection top file
	my $name=$self->object_get_attribute('save_as');

	my $r; 
	my $top="$dir/${name}_connection.sv";
    open my $fd, ">$top" or $r = "$!\n";
    if(defined $r) {
    	add_colored_info($info,"Error in creating $top: $r",'red');
		return;
    } 
    print $fd autogen_warning();
    print $fd get_license_header($top);   




   
  

   my @parameters=@{$self->object_get_attribute ('Verilog','Router_param')};
   my @ports= @{$self->object_get_attribute('Verilog','Router_ports')}; 
    
	
 
    my @ends=get_list_of_all_endpoints($self);
    my @routers=get_list_of_all_routers($self);
    
    my $MAX_P=0;
    foreach my $p (@routers){
    	my $Pnum=$self->object_get_attribute("$p",'PNUM');
    	$MAX_P =$Pnum  if($Pnum>$MAX_P );    	
    }	

    my $NE= scalar @ends;
    my $NR= scalar @routers;

   	
	
	my @nodes=get_list_of_all_routers($self);
	my $i=0;
	
	my $ports="\treset,
\tclk,
\tstart_i,
\tstart_o,
\ter_addr, 
\tcurrent_r_addr,
\tchan_in_all,
\tchan_out_all, 
\trouter_chan_in,
\trouter_chan_out  
";


    my $ports_def="
\tinput reset;
\tinput clk;
\tinput start_i;
\toutput [RAw-1 : 0] er_addr [NE-1 : 0]; // provide router address for each connected endpoint 
\toutput [RAw-1 : 0] current_r_addr [NR-1 : 0]; // provide each router current address  ;
\toutput [NE-1 : 0] start_o;
\toutput smartflit_chanel_t chan_in_all [NE-1 : 0];
\tinput  smartflit_chanel_t chan_out_all [NE-1 : 0]; 
\tinput  smartflit_chanel_t    router_chan_in   [NR-1 :0][MAX_P-1 : 0];
\toutput smartflit_chanel_t    router_chan_out  [NR-1 :0][MAX_P-1 : 0];

";

	my $router_wires="";
	my $endps_wires="";

	
	
	
	foreach my $d (@ports){		
		my $range = ($d->{width} eq 1)? " " :  " [$d->{width}-1 : 0]";	
		my $pdef_range = ($d->{pwidth} eq 1)? "[NE-1 : 0]" : "[$d->{pwidth}-1 : 0]";
		my $pdef_range2 = ($d->{pwidth} eq 1)? "" : "[NE-1 : 0]";
		#$ports=$ports.",\n\trouter_$d->{name},\n\trouter_$d->{connect}";
		my $type=$d->{type};
		my $ctype= ($type eq 'input')? 'output' : 'input';
		if( $d->{endp} eq "yes"){ 	    	 
			#$ports_def=$ports_def."\t$type\t$pdef_range ni_$d->{pname} $pdef_range2;\n";
			#$ports_def=$ports_def."\t$ctype\t$pdef_range ni_$d->{pconnect} $pdef_range2;\n";			
			#$ports=$ports.",\n\tni_$d->{pname},\n\tni_$d->{pconnect}";
		}	
		if($d->{width} eq 1){
			#$ports_def=$ports_def. "\t$type\t[NR-1 :0] router_$d->{name};\n";
			#$ports_def=$ports_def. "\t$ctype\t[NR-1 :0] router_$d->{connect};\n";
		}else{	
			#$ports_def=$ports_def. "\t$type\t$range router_$d->{name} [NR-1 :0];\n";
			#$ports_def=$ports_def. "\t$ctype\t$range router_$d->{connect} [NR-1 :0];\n";
		}
					
		
	}	
	
	  
	
	
	my $routers='
	genvar i;
	generate	
	';
	my $offset=0;
	my $assign="";
	
	for ( my $i=2;$i<=12; $i++){
		my $n= $self->object_get_attribute("ROUTER${i}","NUM");
		$n=0 if(!defined $n);
		if($n>0){	
			my $router_pos= ($offset==0)? 'i' : "i+$offset";
			my $instant=get_router_genvar_instance_v($self,$i,$router_pos,$NE,$NR,$MAX_P);
					
			$routers=$routers."
\tfor( i=0; i<$n; i=i+1) begin : router_${i}_port_lp
\t\t$instant
    
\tend    
			";
			
			for ( my $j=0;$j<$n; $j++){
				my $rname ="ROUTER${i}_$j";		
				my ($ass_v, $ass_h)=	get_wires_assignment_genvar_v($self,$rname,1);
				$assign=$assign.$ass_v;
			}
			
		$offset+=	$n;
			
		}	
	}
	
	
	
	foreach my $end (@ends){
		#$assign=$assign.get_wires_assignment_genvar_v($self,$end,1);		
	}
	
	$assign=$assign."\n";
	
	
	my $pos=0;
	$assign.="//The router address connected to each endpoint\n";
	foreach my $end (@ends){
		my $connect = $self->{$end}{'PCONNECT'}{'Port[0]'};
		my ($Rname,$Rport)=split(/\s*,\s*/,$connect);
		my $R = get_scolar_pos($Rname,@routers);
		my $rname = $self->object_get_attribute("$Rname","NAME");
		my $tname = $self->object_get_attribute("$end","NAME");
		$assign=$assign."\tassign er_addr [$pos] = $R; //$tname -> $rname\n";  
		$pos++;   		
	}
	
	$assign=$assign."\n";
	
	$pos=0;
	foreach my $router (@routers){
		my $rname = $self->object_get_attribute("$router","NAME");
		$assign=$assign."\tassign current_r_addr [$pos] = $pos; // $rname\n";  
		$pos++;   		
	}
	
	
	
	
		 print $fd "
module  ${name}_connection 
	import pronoc_pkg::*; 
(
    $ports
);

	 function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end 	   
      end   
    endfunction // log2 

	localparam 
		NE = $NE,
		NR = $NR,
		RAw=log2(NR),
		MAX_P=$MAX_P;
	
	
	
	                
    
	
	
	
	
	localparam
		P= MAX_P,
        PV = V * P,
        PFw = P * Fw,
        CONG_ALw = CONGw * P,
        PRAw = P * RAw;    
    	
		
       
      

    
$ports_def

$router_wires

$endps_wires
   

$assign   


	start_delay_gen #(
        .NC(NE)
    )
    delay_gen
    (
        .clk(clk),
        .reset(reset),
        .start_i(start_i),
        .start_o(start_o)
    );
 
             
endmodule
";
	
	add_info($info,"$top file is created\n  ");
	close $fd;
	
				
	
}





sub add_routing_instance_v{
	my ($self,$info,$dir)=@_;
	my $name=$self->object_get_attribute('save_as');
	my $rname=$self->object_get_attribute('routing_name');
	my $Vname="T${name}R${rname}";
	#####################################
	#			custom_ni_routing
	####################################
	my $str="
	//do not modify this line ===${Vname}===
    if(TOPOLOGY == \"$name\" && ROUTE_NAME== \"$rname\" ) begin : $Vname
    
        ${Vname}_conventional_routing  #(
            .RAw(RAw),  
            .EAw(EAw),   
            .DSTPw(DSTPw)  
        )
        the_conventional_routing
        (
            .dest_e_addr(dest_e_addr),
            .src_e_addr(src_e_addr),
            .destport(destport)        
        );    
    
    end	
    
    endgenerate
    	
";
	
	my $file = "$dir/../common/custom_ni_routing.v";	
	#check if ***$name**** exist in the file
	unless (-f $file){
		add_colored_info($info,"$file dose not exist\n",'red');
		return; 
	}	
	my $r = check_file_has_string($file, "===${Vname}==="); 
	if ($r==1){
		add_info($info,"The instance  ${Vname}_conventional_routing exists in $file. This file is not modified\n  ",'blue');
	
	}else{
		my $text = read_file_cntent($file,' ');
        my @a = split('endgenerate',$text);
        save_file($file,"$a[0] $str $a[1]");
        add_info($info,"$file has been modified. The  ${Vname}_conventional_routing has been added to the file\n  ",'blue');
		
	}
	
	
	
	#####################################
	#			custom_lkh_routing
	####################################
	 $str="
	//do not modify this line ===${Vname}===
    if(TOPOLOGY == \"$name\" && ROUTE_NAME== \"$rname\" ) begin : ${Vname}
     
	   ${Vname}_look_ahead_routing  #(
            .RAw(RAw),  
            .EAw(EAw),   
            .DSTPw(DSTPw)  
        )
        the_lkh_routing
        (
            .current_r_addr(current_r_addr),
            .dest_e_addr(dest_e_addr),
            .src_e_addr(src_e_addr),
            .destport(destport),
            .reset(reset),
            .clk(clk)        
        );    
    
    end	
    
    endgenerate
    	
";
	
	$file = "$dir/../common/custom_lkh_routing.v";	

	unless (-f $file){
		add_colored_info($info,"$file dose not exist\n",'red');
		return; 
	}	
	$r = check_file_has_string($file, "===${Vname}==="); 
	if ($r==1){
		add_info($info,"The instance ${Vname}_look_ahead_routing exist in $file. This file is not modified\n  ",'blue');
	
	}else{
		my $text = read_file_cntent($file,' ');
        my @a = split('endgenerate',$text);
        save_file($file,"$a[0] $str $a[1]");	
        add_info($info,"$file has been modified. The  ${Vname}_look_ahead_routing has been added to the file\n  ",'blue');
				
	}
	

}

sub add_noc_instance_v{
	my ($self,$info,$dir)=@_;
	my $name=$self->object_get_attribute('save_as');
	
	#####################################
	#			add connection
	####################################
	
	my $ports="\t\t.reset(reset),
\t\t.clk(clk),
\t\t.start_i(start_i),
\t\t.start_o(start_o),
\t\t.er_addr(er_addr), 
\t\t.current_r_addr(current_r_addr),
\t\t.chan_in_all(chan_in_all),
\t\t.chan_out_all(chan_out_all), 
\t\t.router_chan_in(router_chan_in),
\t\t.router_chan_out(router_chan_out)  


";
	
	

	
	my $str="
	//do not modify this line ===${name}===
    if(TOPOLOGY == \"$name\" ) begin : T$name
    
        ${name}_connection  connection
        (
$ports     
        );    
    
    end	
    
    endgenerate
    	
";
	
	#my $file = "$dir/../common/custom_noc_connection.sv";	
	#check if ***$name**** exist in the file
	#unless (-f $file){
	#	add_colored_info($info,"$file dose not exist\n",'red');
	#	return; 
	#}	
	#my $r = check_file_has_string($file, "===${name}==="); 
	#if ($r==1){
		#add_info($info,"The instance  ${name}_connection exists in $file. This file is not modified\n  ",'blue');
	
	#}else{
		#my $text = read_file_cntent($file,' ');
       # my @a = split('endgenerate',$text);
      #  save_file($file,"$a[0] $str $a[1]");
       # add_info($info,"$file has been modified. The  ${name}_connection has been added to the file\n  ",'blue');
			
	#}
	
	
	#####################################
	#		add NoC 
	####################################
	
	
	 my $param_str ="\t\t.TOPOLOGY(TOPOLOGY),
\t\t.ROUTE_NAME(ROUTE_NAME)";

   my @parameters=@{$self->object_get_attribute ('Verilog','Router_param')};
      
	foreach my $d (@parameters){
		$param_str = $param_str.",\n\t\t.$d->{param_name}($d->{param_name})";
	}
	
	$ports="\t\t.reset(reset),
\t\t.clk(clk)";
	
	
	
	
	$str="
	//do not modify this line ===${name}===
    if(TOPOLOGY == \"$name\" ) begin : T$name
    
		${name}_noc_genvar the_noc			
		(	
		    .reset(reset),
		    .clk(clk),    
		    .chan_in_all(chan_in_all),
		    .chan_out_all(chan_out_all)  
		);
    end
    
    endgenerate
	
	";
	
	
	
	my $file = "$dir/../common/custom_noc_top.sv";	
	#check if ***$name**** exist in the file
	unless (-f $file){
		add_colored_info($info,"$file dose not exist\n",'red');
		return; 
	}	
	my $r = check_file_has_string($file, "===${name}==="); 
	if ($r==1){
		add_info($info,"The instance  ${name}_noc exists in $file. This file is not modified\n  ",'blue');
	
	}else{
		my $text = read_file_cntent($file,' ');
        my @a = split('endgenerate',$text);
        save_file($file,"$a[0] $str $a[1]");
        add_info($info,"$file has been modified. The  ${name}_noc has been added to the file\n  ",'blue');			
	}
	
	
	
	
	
	
	
	
	
	
		
}


1

