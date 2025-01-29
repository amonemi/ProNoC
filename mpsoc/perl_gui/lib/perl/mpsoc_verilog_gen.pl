use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;

use mpsoc;
use soc;
use ip;
use ip_gen;
use Cwd;
use rvp;


sub mpsoc_generate_verilog{
	my ($mpsoc,$sw_dir,$txview)=@_;
	my $mpsoc_name=$mpsoc->object_get_attribute('mpsoc_name');
	my $top_ip=ip_gen->top_gen_new();
	
	                                                                     
	
	
	my $param_as_in_v;
	# generate top 
	
	
	
	#generate socs_parameter
	my $socs_param= gen_socs_param($mpsoc);
	
	#generate noc_parameter
	my ($noc_param,$pass_param)=gen_noc_param_v($mpsoc);
	
	#generate the noc
	my $noc_v=gen_noc_v($mpsoc,$pass_param);
	
	#generate socs	
	my ($socs_v,$io_short,$io_full,$top_io_short,$top_io_full,$top_io_pass,$href)=gen_socs_v($mpsoc,$top_ip,$sw_dir,$txview);
	my %jtag_info=%{$href};
	my $jtag_v=add_jtag_ctrl (\%jtag_info,$txview); 
	
	my ($clk_set, $clk_io_sim,$clk_io_full, $clk_assigned_port)= get_top_clk_setting($mpsoc);
   
	$top_io_short=$top_io_short.",\n$clk_io_sim" if (defined $clk_io_sim);
    $top_io_full=$top_io_full."\n$clk_io_full";            
    $top_io_pass=$top_io_pass.",\n$clk_assigned_port" if (defined $clk_assigned_port);
	
	#functions
	my $functions=get_functions();
	$param_as_in_v = (defined $param_as_in_v)? "$param_as_in_v,\nparameter NOC_ID=0\n" : "parameter NOC_ID=0\n";
	my $global_localparam=get_golal_param_v();	
	my $pdef = "`include \"pronoc_def.v\"";
	my $mpsoc_v = (defined $param_as_in_v )? " $pdef\nmodule $mpsoc_name\n\t  #(\n $param_as_in_v)(\n$io_short\n);\n\t`NOC_CONF": "$pdef\nmodule $mpsoc_name\n \t (\n$io_short\n);\n\t`NOC_CONF";
	$mpsoc_v=$mpsoc_v. "
$global_localparam	
$socs_param
$io_full
$noc_v
$socs_v
endmodule
";
	
	
	my $top_v = (defined $param_as_in_v )? "$pdef\nmodule ${mpsoc_name}_top #(\n $param_as_in_v\n)(\n$top_io_short\n);\n": "$pdef\nmodule ${mpsoc_name}_top (\n $top_io_short\n);\n";

$top_v=$top_v."
$global_localparam	
$socs_param
$top_io_full
$clk_set
$jtag_v	
\t${mpsoc_name} the_${mpsoc_name} (
$top_io_pass

\t);
endmodule
";	



	
	
#	my $mp=get_top_ip($mpsoc,'mpsoc');
	
#	mkpath("$dir/lib/ip/mpsoc/",1,01777);	
#	open(FILE,  ">$dir/lib/ip/mpsoc/MPSOC.IP") || die "Can not open: $!";
#	print FILE perl_file_header("MPSOC.IP");
#	print FILE Data::Dumper->Dump([\%$mp],["ipgen"]);
#	close(FILE) || die "Error closing file: $!";
	
	
#	my ($mp_v,$top_v)=soc_generate_verilog($top_soc,"target_dir/sw1",$txview);


	
	#my $ins= gen_mpsoc_instance_v($mpsoc,$mpsoc_name,$param_pass_v);

	#add_text_to_string(\$top_v,$local_param_v_all."\n".$io_full_v_all);
	#add_text_to_string(\$top_v,$ins);
	$mpsoc->object_add_attribute('top_ip',undef,$top_ip);
	
	my @chains = (sort { $b <=> $a } keys  %jtag_info);
	$mpsoc->object_add_attribute('JTAG','M_CHAIN',$chains[0]);
	
	return ($mpsoc_v,$top_v,$noc_param);
}

sub add_sources_to_top_ip{
	my ($mpsoc,$top_ip)=@_;
	my $sourc_short;
	my $source_full="";
	my @sources=('clk','reset');
	foreach my $s (@sources){
		my $num = $mpsoc->object_get_attribute('SOURCE_SET',"${s}_number");
		$num=1 if (!defined $num);
		for (my $n=0;$n<$num;$n++){ 
			my $name=$mpsoc->object_get_attribute('SOURCE_SET',"${s}_${n}_name");
			$name=$s if(!defined $name);
			$top_ip->top_add_port('IO',$name,'', 'input' ,"plug:$s\[$n\]","${s}_i");
			$sourc_short= (defined $sourc_short)? $sourc_short.",\n\t$name" : "\t$name"; 
			#$source_full=$source_full. "// synthesis attribute keep of $name is true;\n" if($s eq 'clk');
			$source_full=$source_full."\tinput $name;\n";
		}
		#$top_ip->top_add_port('IO','clk','', 'input' ,'plug:clk[0]','clk_i');
	}	
	return ($sourc_short, $source_full);
}


sub get_clk_constrain_file{
	my ($self)=@_;
	my $s='clk';
	my $num = $self->object_get_attribute('SOURCE_SET',"${s}_number");
	my $top_name=$self->object_get_attribute('mpsoc_name');
	$top_name=$self->object_get_attribute('soc_name') if(!defined $top_name);
	my $xdc="";
	return  if (!defined $num);
	for (my $n=0;$n<$num;$n++){ 
		my $clk_name=$self->object_get_attribute('SOURCE_SET',"${s}_${n}_name");
		my $period=$self->object_get_attribute('SOURCE_SET',"${s}_${n}_period");
		my $fall=$self->object_get_attribute('SOURCE_SET',"${s}_${n}_fall");
		my $rise=$self->object_get_attribute('SOURCE_SET',"${s}_${n}_rise");
		my $fal_ns=  ($period * $fall)/100;
		my $rise_ns= ($period * $rise)/100;
		
		$xdc=$xdc."create_clock -period $period -name internal_clk$n -waveform {$rise_ns $fal_ns} -add \[get_nets uut/the_${top_name}/${clk_name}\]\n";
		
	}
	return $xdc;
		
}



sub add_jtag_ctrl {
	my ($ref,$txview)=@_;
	my %jtag_info=%{$ref};

	my $jtag_v="\t//Allow software to remote reset/enable the cpu via jtag
\twire jtag_cpu_en, jtag_system_reset;	
";
	my @chains = (sort { $b <=> $a } keys  %jtag_info);
	my $altera=0;
	my $xilinx=0;
	my $glob_en;
	foreach my $c (@chains){
		my $xilinx_jtag_ctrl_in;
		my $xilinx_jtag_ctrl_out;
		my $r = $jtag_info{$c}{'wire'};
		my $index = $jtag_info{$c}{'index'};
		
		my @array = (defined $r)? @{$r} :();		
		my $wires_def = join ("\n",@array); 
		$jtag_v=$jtag_v."\n//\tJtag chain $c Wire def\n$wires_def\n" if(@array);		
		$r= $jtag_info{$c}{'altera_num'};
		@array = (defined $r)? @{$r} :();	
		my $altera_jtag_ctrl =(@array)? scalar @array : 0;
		$r= $jtag_info{$c}{'xilinx_num'};
		@array = (defined $r)? @{$r} :();	
		my $xilinx_jtag_ctrl =(@array)? scalar @array : 0;
		$altera+=$altera_jtag_ctrl;
		$xilinx+=$xilinx_jtag_ctrl;
		if ($xilinx_jtag_ctrl>0){
			$r=$jtag_info{$c}{'input'};
			@array = (defined $r)? @{$r} :();	
			$xilinx_jtag_ctrl_in = ($xilinx_jtag_ctrl!=1)? '{'.join(',',@array).'}' : $array[0];
			$r=$jtag_info{$c}{'output'};
			@array = (defined $r)? @{$r} :();	
			$xilinx_jtag_ctrl_out= ($xilinx_jtag_ctrl!=1)? '{'.join(',',@array).'}' : $array[0];
			my $ctrl = (defined $glob_en)? "
		.system_reset( ),
		.cpu_en( ),
	" : "//The global reset/enable signals are connected to the tap with the largest jtag chain number 
		.system_reset(jtag_system_reset),
		.cpu_en(jtag_cpu_en),
	";	
	
	
	
		
			$glob_en=1;			
			$jtag_v=$jtag_v."
	xilinx_jtag_wb  #(
		.JTAG_CHAIN($c),
		.JWB_NUM($xilinx_jtag_ctrl)		
	)
	jwb_$c
	(		
		$ctrl
		.reset(jtag_debug_reset_in),		
		.wb_to_jtag_all($xilinx_jtag_ctrl_out),
		.jtag_to_wb_all($xilinx_jtag_ctrl_in)
	);		
";	
			
		
		}
		
	}#for
	
	if($altera>0 && $xilinx>0){
		my $r = $jtag_info{0}{'inst'};
		my @array = (defined $r)? @{$r} :();	
		my $inst=join ("\n\t",@array);
		add_colored_info($txview,"Found JTAG communication ports from different FPGA vendors:\n$inst.",'red');			
	}
	elsif($altera>0){
		$jtag_v=$jtag_v."	
		jtag_system_en #(
			.FPGA_VENDOR(\"ALTERA\")
		) jtag_en (
			.cpu_en(jtag_cpu_en),
			.system_reset(jtag_system_reset)
		
		);	
	";		
	}
	
	elsif($altera==0 && $xilinx==0){
		$jtag_v=$jtag_v."
    	//No jtag connection has found in the design	
		jtag_system_en #(
			.FPGA_VENDOR(FPGA_VENDOR)
		) jtag_en (
			.cpu_en(jtag_cpu_en),
			.system_reset(jtag_system_reset)
		
		);	
";	
	
	
	}
			
return $jtag_v;	
	
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
				
	';
	
	return $p;
}


sub  gen_socs_param{
	my $mpsoc=shift;
	my $socs_param="
//SOC parameters\n";
	my ($NE, $NR, $RAw,  $EAw, $Fw) = get_topology_info($mpsoc);
	my $processors_en=0;
    for (my $tile=0;$tile<$NE;$tile++){
			my ($soc_name,$n,$soc_num)=$mpsoc->mpsoc_get_tile_soc_name($tile);
			if(defined $soc_name) {
				my $param=	gen_soc_param($mpsoc,$soc_name,$soc_num,$tile);
				$socs_param=$socs_param.$param;
			}	
	}#$tile
	$socs_param="$socs_param \n";
	return $socs_param;	
}


sub  gen_soc_param {
	my ($mpsoc,$soc_name,$soc_num,$tile_num)=@_;
	my $top=$mpsoc->mpsoc_get_soc($soc_name);
	my $setting=$mpsoc->mpsoc_get_tile_param_setting($tile_num);
	my %params;
	#if ($setting eq 'Custom'){
	%params= $top->top_get_custom_soc_param($tile_num);
	#}else{
	#	 %params=$top->top_get_default_soc_param();
	#}
	my $params="\n\t //Parameter setting for $soc_name  located in tile: $tile_num \n";
	$params{'CORE_ID'}=$tile_num;
	foreach my $p (get_param_list_in_order(\%params)){
			$params{$p}=add_instantc_name_to_parameters(\%params,"T$tile_num",$params{$p});
			
			$params="$params\t localparam T${tile_num}_$p=$params{$p};\n";
	}
	return $params;
}



sub gen_noc_param_v{
	my ($mpsoc,$sample,$noc_id)=@_;
	$noc_id="" if(!defined $noc_id);
	my $noc_param = "noc_param$noc_id";	
	my $param_v="\n\n//NoC parameters\n";
	my $pass_param="";
	my @params=$mpsoc->object_get_attribute_order($noc_param);
	my $custom_topology = $mpsoc->object_get_attribute($noc_param,'CUSTOM_TOPOLOGY_NAME');
	my ($NE, $NR, $RAw, $EAw, $Fw) = get_topology_info($mpsoc,$noc_id);
	my %noc_info;
	my $hashref= $mpsoc->object_get_attribute('noc_param_comments');
	my %comments = %{$hashref} if defined $hashref;

	if(defined $sample ){
		my $ref=$mpsoc->object_get_attribute($sample,"noc_info"); 
		%noc_info= %$ref;	
		($NE, $NR, $RAw, $EAw, $Fw) = get_topology_info_from_parameters($ref);			
	}
	
	foreach my $p (@params){
		
		my $val= (defined $sample) ? $noc_info{$p} :$mpsoc->object_get_attribute($noc_param,$p);
		next if($p eq "CUSTOM_TOPOLOGY_NAME");
		$val=$custom_topology if($p eq "TOPOLOGY" && $val eq "\"CUSTOM\"");
		if($p eq 'MCAST_ENDP_LIST'){
			
			$val="$NE".$val;
		}
		
		$param_v= $param_v."\tlocalparam $p=$val;\n";
		my $comment=$comments{$p};
		if(defined $comment){
			$comment=~ s/\n/\n            \/\//g;
			$param_v.="            //$p : $comment\n\n";
		}
		$pass_param=$pass_param."\t\t.$p($p),\n";
		#print "$p:$val\n";
		
	}
	my $class=$mpsoc->object_get_attribute($noc_param,"C");
	my $str;
	if( $class > 1){
		for (my $i=0; $i<=$class-1; $i++){
			my $n="Cn_$i";
			my $val=$mpsoc->object_get_attribute('class_param',$n);
			$param_v=$param_v."\tlocalparam $n=$val;\n";
		}
		$str="CLASS_SETTING={";
		for (my $i=$class-1; $i>=0;$i--){
			$str=($i==0)?  "${str}Cn_0};\n " : "${str}Cn_$i,";
		}
	}else {
		$str="CLASS_SETTING={V{1\'b1}};\n";
	}	
	$param_v=$param_v."\tlocalparam $str";
	$pass_param=$pass_param."\t\t.CLASS_SETTING(CLASS_SETTING),\n";
	my $v=$mpsoc->object_get_attribute($noc_param,"V")-1;
	my $escape=$mpsoc->object_get_attribute($noc_param,"ESCAP_VC_MASK");
	if (! defined $escape){
		$param_v=$param_v."\tlocalparam [$v	:0] ESCAP_VC_MASK=1;\n";
		$pass_param=$pass_param.".\t\tESCAP_VC_MASK(ESCAP_VC_MASK),\n"; 
	}
	$param_v=$param_v." \tlocalparam  CVw=(C==0)? V : C * V;\n";
	$pass_param=$pass_param."\t\t.CVw(CVw)\n";	
	return ($param_v,$pass_param);	
	
}


sub gen_noc_param_h{
	my $mpsoc=shift;
	my $param_h="\n\n//NoC parameters\n";
	
	my $topology = $mpsoc->object_get_attribute('noc_param','TOPOLOGY');
	$topology =~ s/"//g;
	$param_h.="\t#define  IS_${topology}\n";
	
	my ($NE, $NR, $RAw, $EAw, $Fw) = get_topology_info($mpsoc);
	
	
	
	
	my @params=$mpsoc->object_get_attribute_order('noc_param');
	my $custom_topology = $mpsoc->object_get_attribute('noc_param','CUSTOM_TOPOLOGY_NAME');
	foreach my $p (@params){
		my $val=$mpsoc->object_get_attribute('noc_param',$p);
		next if($p eq "CUSTOM_TOPOLOGY_NAME");
		next if($p eq "int VC_CONFIG_TABLE [MAX_ROUTER][MAX_PORT]");
		$val=$custom_topology if($p eq "TOPOLOGY" && $val eq "\"CUSTOM\"");
		if($p eq "MCAST_ENDP_LIST" || $p eq "ESCAP_VC_MASK"){
			$val="$NE".$val if($p eq 'MCAST_ENDP_LIST');
			$val =~ s/\'/\\\'/g;
			$val="\"$val\"";			
		}
		
		$param_h=$param_h."\t#define $p\t$val\n";
		
		#print "$p:$val\n";
		
	}
	my $class=$mpsoc->object_get_attribute('noc_param',"C");
	my $str;
	if( $class > 1){
		for (my $i=0; $i<=$class-1; $i++){
			my $n="Cn_$i";
			my $val=$mpsoc->object_get_attribute('class_param',$n);
			$param_h=$param_h."\t#define $n\t$val\n";
		}
		$str="CLASS_SETTING  {";
		for (my $i=$class-1; $i>=0;$i--){
			$str=($i==0)?  "${str}Cn_0};\n " : "${str}Cn_$i,";
		}
	}else {
		$str="CLASS_SETTING={V{1\'b1}}\n";
	}	
	#add_text_to_string (\$param_h,"\t#define $str");
	 
	my $v=$mpsoc->object_get_attribute('noc_param',"V")-1;
	my $escape=$mpsoc->object_get_attribute('noc_param',"ESCAP_VC_MASK");
	if (! defined $escape){
		#add_text_to_string (\$param_h,"\tlocalparam [$v	:0] ESCAP_VC_MASK=1;\n");
		#add_text_to_string (\$pass_param,".ESCAP_VC_MASK(ESCAP_VC_MASK),\n"); 
	}
	#add_text_to_string (\$param_h," \tlocalparam  CVw=(C==0)? V : C * V;\n");
	#add_text_to_string (\$pass_param,".CVw(CVw)\n");
	
	
	#remove 'b and 'h
	#$param_h =~ s/\d\'b/ /g;
	#$param_h =~ s/\'h/ /g;
	
	return  $param_h;	
}





sub gen_noc_v{
	my ($mpsoc,$pass_param) = @_;
	my ($NE, $NR, $RAw, $EAw, $Fw) = get_topology_info($mpsoc);
	

    my $noc_clk   =  $mpsoc->object_get_attribute('SOURCE_SET_CONNECT',"NoC_clk");
	my $noc_reset =  $mpsoc->object_get_attribute('SOURCE_SET_CONNECT',"NoC_reset");
	$noc_clk   = 'clk0'   if(!defined $noc_clk  );
	$noc_reset = 'reset0' if(!defined $noc_reset);

	my $noc_v="

	//connection wire to NoC
	smartflit_chanel_t ni_chan_in  [NE-1 : 0];
	smartflit_chanel_t ni_chan_out [NE-1 : 0];
	
	wire 					noc_clk_in,noc_reset_in;    
   
    //NoC
 	noc_top # ( 
		.NOC_ID(NOC_ID)
	) the_noc (
		.reset(noc_reset_in),
		.clk(noc_clk_in),    
		.chan_in_all(ni_chan_out),
		.chan_out_all(ni_chan_in),
		.router_event( )  
	);	
	
	clk_source  src 	(
		.clk_in($noc_clk),
		.clk_out(noc_clk_in),
		.reset_in($noc_reset),
		.reset_out(noc_reset_in)
	);    
";

;
	return $noc_v;
	
}




sub gen_socs_v{
	my ($mpsoc,$top_ip,$sw_dir,$txview)=@_;
	
	#add clk reset signals
	my ($sourc_short, $source_full)=add_sources_to_top_ip($mpsoc,$top_ip);
	
	   
	my $io_short=$sourc_short;
	my $top_io_short="\tjtag_debug_reset_in";   
	
	
#	my $jtag_def="// Allow software to remote reset/enable the cpu via jtag
#\twire jtag_cpu_en, jtag_system_reset;	
#\twire processors_en_anded_jtag = processors_en & jtag_cpu_en;
#	
#";
	
	my $io_full=$source_full;
	my $top_io_full= "\tinput jtag_debug_reset_in;\n";   
	my $top_io_pass="//";
	
	my %jtag_info;
	%jtag_info=append_to_hash (\%jtag_info,0,'wire',"wire processors_en_anded_jtag = processors_en & jtag_cpu_en;\n"); 
	#my $altera_jtag_ctrl=0;
	#my $xilinx_jtag_ctrl=0; #if it becomes larger than 0 then add jtag to wb module 
	#my $jtag_insts="";
	#my $xilinx_jtag_ctrl_in="";
	#my $xilinx_jtag_ctrl_out=""; 
	
	   
	my $socs_v=""; 
	my ($NE, $NR, $RAw, $EAw, $Fw)= get_topology_info ($mpsoc); 
    
  
	my $processors_en=0;
	for (my $tile_num=0;$tile_num<$NE;$tile_num++){
			my ($soc_name,$n,$soc_num)=$mpsoc->mpsoc_get_tile_soc_name($tile_num);
			
			if(defined $soc_name) {				
				my ($soc_v,$en,$io_short1,$io_full1,$top_io_short1,$top_io_full1,$top_io_pass1,$ref)= 
				gen_soc_v($mpsoc,$top_ip,$sw_dir,$soc_name,$tile_num,$soc_num,$txview,\%jtag_info);
				%jtag_info=%{$ref};
				$socs_v=$socs_v.$soc_v;
				$io_short    = $io_short    .$io_short1;
				$io_full     = $io_full     .$io_full1;
				$top_io_short= $top_io_short.$top_io_short1;
				$top_io_full = $top_io_full. $top_io_full1;
				$top_io_pass = $top_io_pass. $top_io_pass1;
			#	$jtag_def    = $jtag_def    .$jtag_def1;
			#	$jtag_insts=$jtag_insts.$jtag_insts1; 
			#	$altera_jtag_ctrl+=$altera_jtag_ctrl1;
			#	$xilinx_jtag_ctrl+=$xilinx_jtag_ctrl1;
			#	$xilinx_jtag_ctrl_in =(length ($xilinx_jtag_ctrl_in )>2)? "$xilinx_jtag_ctrl_in,$xilinx_jtag_ctrl_in1"  : $xilinx_jtag_ctrl_in.$xilinx_jtag_ctrl_in1;
			#	$xilinx_jtag_ctrl_out=(length ($xilinx_jtag_ctrl_out)>2)? "$xilinx_jtag_ctrl_out,$xilinx_jtag_ctrl_out1" :$xilinx_jtag_ctrl_out.$xilinx_jtag_ctrl_out1;
		
				$processors_en|=$en;
			
			}else{
				#this tile is not connected to any ip. the noc input ports will be connected to ground
				my $soc_v="\n\n // Tile:$tile_num    is not assigned to any ip\n";
				$soc_v="$soc_v
	
	assign ni_credit_out[$tile_num]={V{1'b0}}; 
	assign ni_flit_out[$tile_num]={Fw{1'b0}}; 
	assign ni_flit_out_wr[$tile_num]=1'b0; 
	";
		$socs_v=$socs_v.$soc_v;			
				
			}
	
	}
                
    if($processors_en){
    	$io_short=$io_short.",\n\tprocessors_en";
    	$io_full=$io_full."\tinput processors_en;";
    	$top_io_short=$top_io_short.",\n\tprocessors_en";
    	$top_io_full=$top_io_full."\t input processors_en;";
    	$top_io_pass=$top_io_pass.",\n\t\t.processors_en(processors_en_anded_jtag)";
		$top_ip->top_add_port('IO','processors_en','' ,'input','plug:enable[0]','enable_i');
    	
    }            
    
 #  $io_short=$io_short.",\n\tjtag_system_reset";
 #  $io_full=$io_full."\n\tinput jtag_system_reset;"; 
 #  $top_io_pass=$top_io_pass.",\n\t\t.jtag_system_reset(jtag_system_reset)";
    
   
	return ($socs_v,$io_short,$io_full,$top_io_short,$top_io_full,$top_io_pass,\%jtag_info);

}



##############
#	gen_soc_v
##############


#$mpsoc,$top_ip,$sw_dir,$soc_name,$id,$soc_num,$txview
sub   gen_soc_v{
	my ($mpsoc,$top_ip,$sw_path,$soc_name,$tile_num,$soc_num,$txview,$href)=@_;
	my %jtag_info = %{$href};
		
	my $io_short="";
	my $io_full="";
	my $top_io_short="";
	my $top_io_full="";
	my $top_io_pass="";

	
	
	my $processor_en=0;

	
	
	
	
	my ($NE, $NR, $RAw, $EAw, $Fw)= get_topology_info ($mpsoc); 
	my $e_addr=endp_addr_encoder($mpsoc,$tile_num);
	my $router_num = get_connected_router_id_to_endp($mpsoc,$tile_num);
	my $r_addr=router_addr_encoder($mpsoc,$router_num);
	
	
	
	my $soc_v="\n\n // Tile:$tile_num ($e_addr)\n   \t$soc_name #(\n";
	
	# Global parameter
	$soc_v=$soc_v."\t\t.CORE_ID($tile_num),\n\t\t.SW_LOC(\"$sw_path/tile$tile_num\")";
	
		
	# ni parameter
	my $top=$mpsoc->mpsoc_get_soc($soc_name);
	my @nis=get_NI_instance_list($top);
	my @noc_param=$top->top_get_parameter_list($nis[0]);
	my $inst_name=$top->top_get_def_of_instance($nis[0],'instance');
	
	#other parameters
	my %params=$top->top_get_default_soc_param();
	
	
	
	foreach my $p (@noc_param){
		my $parm_next = $p;
		$parm_next =~ s/${inst_name}_//;
		my $param=  ",\n\t\t.$p($parm_next)"; 
		$soc_v=$soc_v.$param;		
	}
	foreach my $p (sort keys %params){
		my $parm_next= "T${tile_num}_$p";
		my $param=  ",\n\t\t.$p($parm_next)"; 
		$soc_v=$soc_v.$param;			
		
	}	
	
	$soc_v=$soc_v."\n\t)the_${soc_name}_$soc_num(\n";
	
	my @intfcs=$top->top_get_intfc_list();
	
	my $i=0;

	my $dir = Cwd::getcwd();
	my $mpsoc_name=$mpsoc->object_get_attribute('mpsoc_name');
	my $target_dir  = "$ENV{'PRONOC_WORK'}/MPSOC/$mpsoc_name";
	my $soc_file="$target_dir/src_verilog/tiles/$soc_name.sv";
			
	my $vdb =read_verilog_file($soc_file);
		
	my %soc_localparam = $vdb->get_modules_parameters($soc_name);
	

	foreach my $intfc (@intfcs){
		
		# ni intfc	
		if( $intfc eq 'socket:ni[0]'){
			my @ports=$top->top_get_intfc_ports_list($intfc);
		
			foreach my $p (@ports){
				my($inst,$range,$type,$intfc_name,$intfc_port)= $top->top_get_port($p);
				my $q=	($intfc_port eq "current_e_addr")? "$EAw\'d$e_addr" : 
						($intfc_port eq "current_r_addr")? "$RAw\'d$r_addr" :						
						"ni_$intfc_port\[$tile_num\]";
				$soc_v=$soc_v.',' if ($i);	
				$soc_v=$soc_v."\n\t\t.$p($q)";
				$i=1;
			
				
			}			
		}
		# clk source
		elsif( $intfc =~ /plug:clk\[/ ){
			my @ports=$top->top_get_intfc_ports_list($intfc);
			foreach my $p (@ports){
				my($inst,$range,$type,$intfc_name,$intfc_port)= $top->top_get_port($p);
				$soc_v=$soc_v.',' if ($i);	
				my $src =  $mpsoc->object_get_attribute('SOURCE_SET_CONNECT',"T${tile_num}_$p");				
				$src = 'clk0' if(!defined $src);
				$soc_v=$soc_v."\n\t\t.$p($src)";					
			    $i=1;	
				
			}	
		}		
		#reset
		elsif( $intfc =~ /plug:reset\[/){
			my @ports=$top->top_get_intfc_ports_list($intfc);
			foreach my $p (@ports){
				my($inst,$range,$type,$intfc_name,$intfc_port)= $top->top_get_port($p);
				$soc_v=$soc_v.',' if ($i);	
				my $src =  $mpsoc->object_get_attribute('SOURCE_SET_CONNECT',"T${tile_num}_$p");
				$src = 'reset0' if(!defined $src);
				$soc_v=$soc_v."\n\t\t.$p(${src} )";#| jtag_system_reset)";				
			    $i=1;		
				
			}		
		}
		#enable
		elsif( $intfc =~ /plug:enable\[/){
			my @ports=$top->top_get_intfc_ports_list($intfc);
			foreach my $p (@ports){
				my($inst,$range,$type,$intfc_name,$intfc_port)= $top->top_get_port($p);
				$soc_v=$soc_v.',' if ($i);	
				$soc_v=$soc_v."\n\t\t.$p(processors_en)";
			    $processor_en=1;
			    $i=1;			
			}			
		}
		#RxD_sim
		elsif( $intfc eq 'socket:RxD_sim[0]'){
			#This interface is for simulation only donot include it in top module
			my @ports=$top->top_get_intfc_ports_list($intfc);
			foreach my $p (@ports){
				$soc_v=$soc_v.',' if ($i);	
				$soc_v=$soc_v."\n\t\t.$p( )";
				$i=1;
			}		
		
		}		
		#jtag_to_wb	
		elsif( $intfc =~ /socket:jtag_to_wb\[/){ #check JTAG connect parameter. if it is XILINX then connect it to jtag tap
			my @ports=$top->top_get_intfc_ports_list($intfc);
			
			my $setting=$mpsoc->mpsoc_get_tile_param_setting($tile_num);
			my %topparams;
			#if ($setting eq 'Custom'){
				 %topparams= $top->top_get_custom_soc_param($tile_num);
		#	}else{
			#	 %topparams=$top->top_get_default_soc_param();
			#}
		
		
			#my $JTAG_CONNECT=$soc->soc_get_module_param_value ($id,'JTAG_CONNECT');
			
			foreach my $p (@ports){
				my($id,$range,$type,$intfc_name,$intfc_port)= $top->top_get_port($p);
				my $inst_name=$top->top_get_def_of_instance($id,'instance');
				my $JTAG_CONNECT=  $topparams{"${inst_name}_JTAG_CONNECT"};
				my $chain=$topparams{"${inst_name}_JTAG_CHAIN"};	
				my $index=$topparams{"${inst_name}_JTAG_INDEX"};	
				#print Dumper (\%topparams);
				#print "my $JTAG_CONNECT=  \$topparams{${inst_name}_JTAG_CONNECT}\n"; 
				
				#print "$inst,$range,$type,$intfc_name,$intfc_port-> $JTAG_CONNECT;";
				if($JTAG_CONNECT  =~ /XILINX_JTAG_WB/){
					
					my ($io_port,$type,$new_range,$intfc_name,$intfc_port)=	get_top_port_io_info($top,$p,$tile_num,\%params,\%soc_localparam);
					my $port_def=(length ($new_range)>1 )? 	"\t$type\t [ $new_range    ] $io_port;\n": "\t$type\t\t\t$io_port;\n";			 
					$top_ip->top_add_port("T${tile_num}" ,$io_port, $new_range ,$type,$intfc_name,$intfc_port);
					
					my $wire_def=(length ($new_range)>1 )? 	"\twire\t [ $new_range    ] $io_port;": "\twire\t\t\t$io_port;";			 
				#	my $new_range = add_instantc_name_to_parameters(\%params,"${soc_name}_$soc_num",$range);
					
				#	$jtag_def=$jtag_def."$wire_def";
					%jtag_info=append_to_hash (\%jtag_info,$chain,'wire',"$wire_def");
					
					
					$soc_v=$soc_v.',' if ($i);	
					$soc_v=$soc_v."\n\t\t.$p($io_port)";
					$i=1;	
					if($type eq 'input'){
						%jtag_info=check_jtag_indexs(\%jtag_info,$chain,$index,$txview,$inst_name,$tile_num);
						#$jtag_insts=$jtag_insts."$id XILINX JTAG,";
						%jtag_info=append_to_hash (\%jtag_info,0,'inst',"$id XILINX JTAG");
						#$xilinx_jtag_ctrl++;
						%jtag_info=append_to_hash (\%jtag_info,$chain,'xilinx_num',1);
						#$xilinx_jtag_ctrl_in=(length ($xilinx_jtag_ctrl_in)>2)? "$xilinx_jtag_ctrl_in,$io_port" : "$io_port";
						%jtag_info=append_to_hash (\%jtag_info,$chain,'input',$io_port);
					}else {
						#$xilinx_jtag_ctrl_out=(length($xilinx_jtag_ctrl_out)>2)? "$xilinx_jtag_ctrl_out,$io_port" : "$io_port";
						%jtag_info=append_to_hash (\%jtag_info,$chain,'output',$io_port);
					}
					$io_short=$io_short.",\n\t$io_port";
					$io_full=$io_full."$port_def";
					$top_io_pass=$top_io_pass.",\n\t\t.$io_port($io_port)";
#					
				}else{#Dont not connect 
					$soc_v=$soc_v.',' if ($i);	
					$soc_v=$soc_v."\n\t\t.$p( )";
					$i=1;
				}
			
				if($JTAG_CONNECT =~ /ALTERA_JTAG_WB/){
					if($type eq 'input'){
						#$jtag_insts=$jtag_insts."$id ALTERA JTAG,";
						#$altera_jtag_ctrl++;
						%jtag_info=append_to_hash (\%jtag_info,0,'inst',"$id ALTERA JTAG");
						%jtag_info=append_to_hash (\%jtag_info,0,'altera_num',1);
						%jtag_info=check_jtag_indexs(\%jtag_info,0,$index,$txview,$inst_name,$tile_num);
						
					}
				}	
				
			}		
		
		}
		
		else {
		#other interface
			my @ports=$top->top_get_intfc_ports_list($intfc);
			foreach my $p (@ports){
				my ($io_port,$type,$new_range,$intfc_name,$intfc_port)=	get_top_port_io_info($top,$p,$tile_num,\%params,\%soc_localparam);
				
				$io_short=$io_short.",\n\t$io_port";
				$top_io_short=$top_io_short.",\n\t$io_port";
				$top_io_pass=$top_io_pass.",\n\t\t.$io_port($io_port)";
				#io definition
				#my $new_range = add_instantc_name_to_parameters(\%params,"${soc_name}_$soc_num",$range);
				my $port_def=(length ($new_range)>1 )? 	"\t$type\t [ $new_range    ] $io_port;\n": "\t$type\t\t\t$io_port;\n";			 
				$top_ip->top_add_port("T${tile_num}" ,$io_port, $new_range ,$type,$intfc_name,$intfc_port);
				
				$io_full=$io_full."$port_def";
				$top_io_full=$top_io_full."$port_def";
				$soc_v=$soc_v.',' if ($i);	
				$soc_v=$soc_v."\n\t\t.$p($io_port)";	
				$i=1;	
				
			}			
		}			
	}
	
	
	
	$soc_v=$soc_v."\n\t);\n";
	
			
	return ($soc_v,$processor_en,$io_short,$io_full,$top_io_short,	$top_io_full,$top_io_pass,\%jtag_info);

}


sub check_jtag_indexs{
	my ($ref,$chain,$index,$txview,$inst_name,$core_id)=@_;
	my %jtag_info = %{$ref} if (defined $ref);
	
	chomp $index;   
	# replace coreid parameter  	
	($index=$index)=~ s/CORE_ID/$core_id/g; 
	$index = eval $index;
	my $inst1 =$jtag_info{$chain}{'index'}{$index};
	my $id1 = $jtag_info{$chain}{'core_id'}{$index};
	if (defined $inst1){
		add_colored_info($txview,"Error: The JTAG INDEX number $index in JTAG Chain $chain is not unique. The same index number is used in tile($id1):$inst1  & tile($core_id):$inst_name  IPs. It should be used in only one module.\n",'red');				
	}
	$jtag_info{$chain}{'index'}{$index}=$inst_name;
	$jtag_info{$chain}{'core_id'}{$index}=$core_id;
	#print "\$jtag_info{$chain}{'index'}{$index}=$inst_name\n";
	return %jtag_info;
}



sub get_top_clk_setting{
	my $mpsoc=shift;
    #get mpsoc with clock setting interface
	my $dir = Cwd::getcwd();
	my $soc =get_source_set_top($mpsoc);
	
    my @instances=$soc->soc_get_all_instances();
    my $top_ip=ip_gen->top_gen_new();
    my $body_v;
    my $param_pass_v="";	
    my $io_sim_v;
	my $io_top_sim_v;
	my $core_id= 0 ;
	my $param_as_in_v="";
	my $local_param_v_all="";
	my $inst_v_all="";
    my $param_v_all="";
    my $wire_def_v_all="";
	my $plugs_assign_v_all="";
	my $sockets_assign_v_all="";
	my $io_full_v_all="";
	my $io_top_full_v_all="";
	my $io_sim_v_all;
	my $system_v_all="";
	
	my $wires=soc->new_wires();
	my $intfc=interface->interface_new();
	my $clk_assigned_port;
    foreach my $id (@instances){
    	my ($param_v, $local_param_v, $wire_def_v, $inst_v, $plugs_assign_v, $sockets_assign_v,$io_full_v,$io_top_full_v,$io_sim_v,
		$top_io_short,$param_as_in_v,$param_pass_v,$system_v,$assigned_ports,$top_io_pass,$src_io_short, $src_io_full)=gen_module_inst($id,$soc,$top_ip,$intfc,$wires);
    	
		#my ($param_v, $local_param_v, $wire_def_v, $inst_v, $plugs_assign_v, $sockets_assign_v,$io_full_v,$io_top_full_v,$system_v,$assigned_ports)=gen_module_inst($id,$soc,\$io_sim_v,\$io_top_sim_v,\$param_as_in_v,$top_ip,$intfc,$wires,\$param_pass_v,\$system_v);
   		my $inst   	= $soc->soc_get_instance_name($id);
		if ($id ne 'TOP'){
			add_text_to_string(\$body_v,"/*******************\n*\n*\t$inst\n*\n*\n*********************/\n");
			add_text_to_string(\$system_v_all,"$system_v\n")   	if(defined($system_v)); 
			add_text_to_string(\$local_param_v_all,"$local_param_v\n")   	if(defined($local_param_v)); 
			add_text_to_string(\$wire_def_v_all,"$wire_def_v\n")		 	if(defined($wire_def_v));
			add_text_to_string(\$inst_v_all,$inst_v)					 	if(defined($inst_v));
			add_text_to_string(\$plugs_assign_v_all,"$plugs_assign_v\n") 	if(defined($plugs_assign_v));
			add_text_to_string(\$sockets_assign_v_all,"$sockets_assign_v\n")if(defined($sockets_assign_v));
			add_text_to_string(\$io_full_v_all,"$io_full_v\n")				if(length($io_full_v)>3);
			add_text_to_string(\$io_top_full_v_all,"$io_top_full_v\n")		if(length($io_top_full_v)>3);
			$io_sim_v_all     = (defined $io_sim_v_all    )? "$io_sim_v_all,\n$io_sim_v"         : $io_sim_v  	    	if(defined($io_sim_v)); 
		}else{
			add_text_to_string(\$system_v_all,"$system_v\n")   	if(defined($system_v)); 
			add_text_to_string(\$wire_def_v_all,"$wire_def_v\n")		 	if(defined($wire_def_v));
			add_text_to_string(\$plugs_assign_v_all,"$plugs_assign_v\n") 	if(defined($plugs_assign_v));
			add_text_to_string(\$sockets_assign_v_all,"$sockets_assign_v\n")if(defined($sockets_assign_v));
			add_text_to_string(\$io_full_v_all,"$io_full_v\n")				if(length($io_full_v)>3);
			$io_sim_v_all     = (defined $io_sim_v_all    )? "$io_sim_v_all,\n$io_sim_v"         : $io_sim_v  	    	if(defined($io_sim_v)); 
			add_text_to_string(\$io_top_full_v_all,"$io_top_full_v\n")			if(length($io_top_full_v)>3);		
			$clk_assigned_port= (defined $clk_assigned_port)? "$clk_assigned_port,\n$assigned_ports"  : $assigned_ports if(defined $assigned_ports);
		} 
   
    }	
    
    
       
    
    
    
    my $unused_wiers_v=assign_unconnected_wires($wires,$intfc);
    $unused_wiers_v= "" if(!defined $unused_wiers_v);
    
   my $soc_v = "
   $system_v_all
   $local_param_v_all  
   $wire_def_v_all
   $unused_wiers_v
   $inst_v_all
   $plugs_assign_v_all
   $sockets_assign_v_all

";
	my $clk_io_full= $io_full_v_all;
	my $clk_io_sim=$io_sim_v_all;
	return ($soc_v,$clk_io_sim,$clk_io_full,$clk_assigned_port);

}

sub get_top_port_io_info{
	my ($top,$port,$tile_num,$params_ref,$local_param_ref)=@_;
	my %params =%{$params_ref} if(defined $params_ref);
	my %localparams=%{$local_param_ref} if(defined $local_param_ref);
	my($inst,$range,$type,$intfc_name,$intfc_port)= $top->top_get_port($port);
	my $io_port="T${tile_num}_${port}";
    #resolve range parameter
	if (defined $range ){
			my @a= split (/\b/,$range);			
			foreach my $l (@a){
				#if defined in parameter list ignore it
				next  if(defined $params{$l});
				($range=$range)=~ s/\b$l\b/$localparams{$l}/g      if(defined $localparams{$l});
			}
	}
	my $new_range = add_instantc_name_to_parameters(\%params,"T${tile_num}",$range);
	return ($io_port,$type,$new_range,$intfc_name,$intfc_port);
}





	


1
