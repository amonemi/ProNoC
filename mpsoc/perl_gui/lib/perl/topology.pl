#!/usr/bin/perl -w

#this file contains NoC topology related sub-functions

use constant::boolean;
use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;

sub get_topology_info {
	my ($self) =@_;
	my $topology=$self->object_get_attribute('noc_param','TOPOLOGY');
	my $T1=$self->object_get_attribute('noc_param','T1');
	my $T2=$self->object_get_attribute('noc_param','T2');
	my $T3=$self->object_get_attribute('noc_param','T3');
	my $V = $self->object_get_attribute('noc_param','V');
	my $Fpay = $self->object_get_attribute('noc_param','Fpay');
	
	return get_topology_info_sub($topology, $T1, $T2, $T3,$V, $Fpay);	
}	


sub get_topology_info_from_parameters {
	my ($ref) =@_;
	my %noc_info;
	my %param= %$ref if(defined $ref );			
	my $topology=$param{'TOPOLOGY'};
	my $T1  =$param{'T1'};
	my $T2  =$param{'T2'};
	my $T3  =$param{'T3'};
	my $V   =$param{'V'};
	my $Fpay=$param{'Fpay'};	
	return get_topology_info_sub($topology, $T1, $T2, $T3,$V, $Fpay);	
}



sub get_topology_info_sub {

	my ($topology, $T1, $T2, $T3,$V, $Fpay)=@_;
	
	my $NE; # number of end points
	my $NR; # number of routers
	my $RAw; # routers address width
	my $EAw; # Endpoints address width
	
	
	my $Fw = 2+$V+$Fpay; 
	if($topology eq '"TREE"') {
		my $K =  $T1;
        my $L =  $T2;
        $NE = powi( $K,$L );
        $NR = sum_powi ( $K,$L );
        my $Kw=log2($K);
        my $LKw=$L*$Kw;
        my $Lw=log2($L);  
        $RAw=$LKw + $Lw;   
        $EAw = $LKw;          
	
	}elsif($topology eq '"FATTREE"') {
		my $K =  $T1;
        my $L =  $T2;
		$NE = powi( $K,$L );
        $NR = $L * powi( $K , $L - 1 );
        my $Kw=log2($K);
        my $LKw=$L*$Kw;
        my $Lw=log2($L);  
        $RAw=$LKw + $Lw;   
        $EAw = $LKw;      
		
	}elsif ($topology eq '"RING"' || $topology eq '"LINE"'){
		my $NX=$T1;
		my $NY=1;
		my $NL=$T3;
		$NE = $NX*$NY*$NL;
        $NR = $NX*$NY;    
        my $Xw=log2($NX);
        my $Yw=log2($NY); 
        my $Lw=log2($NL);               
        $RAw = $Xw; 
        $EAw = ($NL==1) ? $RAw : $RAw + $Lw;		
       
	}elsif ($topology eq '"MESH"' || $topology eq '"TORUS"' ) {
		my $NX=$T1;
		my $NY=$T2;
		my $NL=$T3;
		$NE = $NX*$NY*$NL;
		$NR = $NX*$NY;    
        my $Xw=log2($NX);
        my $Yw=log2($NY); 
        my $Lw=log2($NL);         
        $RAw = $Xw + $Yw;
        $EAw = ($NL==1) ? $RAw : $RAw + $Lw;
	}elsif ($topology eq '"FMESH"'){
		my $NX=$T1;
		my $NY=$T2;
		my $NL=$T3;
		$NE = $NX*$NY*$NL + 2*($NX + $NY);
		$NR = $NX*$NY;    
        my $Xw=log2($NX);
        my $Yw=log2($NY); 
        my $Lw=log2($NL);         
        $RAw = $Xw + $Yw;
        $EAw = $RAw + log2(4+$NL);		
		
	}elsif ($topology eq '"STAR"' ) {	
		$NE= $T1; 
		$NR= 1;
		$RAw=log2($NR);
		$EAw=log2($NE);		
	
	}else{ #custom
		$NE= $T1; 
		$NR= $T2;
		$RAw=log2($NR);
		$EAw=log2($NE);		
	}		
	return ($NE, $NR, $RAw, $EAw, $Fw); 	
}


sub fattree_addrencode {
	my ( $pos, $k, $l)=@_;
	my  $pow; my $ tmp;
	my $addrencode=0;
	my $kw=log2($k);
	$pow=1;
	for (my $i = 0; $i <$l; $i=$i+1 ) {
		$tmp=int($pos/$pow);
		$tmp=$tmp % $k;
		$tmp=$tmp<<($i)*$kw;
		$addrencode=$addrencode | $tmp;
		$pow=$pow * $k;
	}
	 return $addrencode;
}

sub fattree_addrdecode{
	my ($addrencode, $k, $l)=@_;
	my $kw=0;
	my $mask=0;
	my $pow; my $tmp;
	my $pos=0;
	while((0x1<<$kw) < $k){
		$kw++;
		$mask<<=1;
		$mask|=0x1;
	}
	$pow=1;
	for (my $i = 0; $i <$l; $i=$i+1 ) {
		$tmp = $addrencode & $mask;
		#printf("tmp1=%u\n",tmp);
		$tmp=($tmp*$pow);
		$pos= $pos + $tmp;
		$pow=$pow * $k;
		$addrencode>>=$kw;
	}
	return $pos;
}









sub get_connected_router_id_to_endp{
	my ($self,$endp_id)=@_;
	my $topology=$self->object_get_attribute('noc_param','TOPOLOGY');
	my $T1=$self->object_get_attribute('noc_param','T1');
	my $T2=$self->object_get_attribute('noc_param','T2');
	my $T3=$self->object_get_attribute('noc_param','T3');
	if($topology eq '"FATTREE"' || $topology eq '"TREE"') {
		return int($endp_id/$T1);
	}elsif ($topology eq '"RING"' || $topology eq '"LINE"'  ||  $topology eq '"MESH"' || $topology eq '"TORUS"'){
		 return int($endp_id/$T3);
	}elsif ($topology eq '"STAR"' ) {	
		 return 0;#there is only one routerin star topology
	}elsif ($topology eq '"FMESH"'){
		my $tmp = $T1*$T2*$T3;
		return int($endp_id/$T3) if($endp_id<$tmp);
		return $endp_id-$tmp if($endp_id<$tmp+$T1);
		return ($endp_id-$tmp-$T1)+ $T1*($T2-1) if($endp_id<$tmp+2*$T1); 
		return ($endp_id-$tmp-2*$T1)*$T1 if($endp_id<$tmp+2*$T1+$T2); 
		return ($endp_id-$tmp-2*$T1-$T2+1)*$T1-1;
		 
	}else{#custom
		my @er_addr = $self->object_get_attribute('noc_connection','er_addr');  
		return $er_addr[$endp_id];		
	}	
}


sub fmesh_addrencode{ 
	my($id,$T1,$T2,$T3)=@_;
	my  ($y, $x, $l,$p, $diff,$mul);
	$mul  = $T1*$T2*$T3; 
	
	my  $LOCAL   =   0;  
	my	$EAST    =   1; 
	my	$NORTH   =   2;  
	my	$WEST    =   3;  
	my	$SOUTH   =   4;  
	           
	if($id < $mul) { 
		$y = (($id/$T3) / $T1 ); 
		$x = (($id/$T3) % $T1 ); 
		$l = ( $id %$T3); 
		$p = ($l==0)? $LOCAL : 4+$l;		     
	}else{       
		$diff = $id -  $mul ;
		if( $diff <  $T1){ #top mesh edge
			$y = 0;
			$x = $diff;
			$p = $NORTH;			
		}
		elsif ( $diff < 2* $T1) { #bottom mesh edge 
			$y = $T2-1;
			$x = $diff-$T1;
			$p = $SOUTH;			 
		}
	 	elsif ( $diff < (2* $T1)+$T2 ) { #left mesh edge 
			$y = $diff - (2* $T1);
			$x = 0;
			$p = $WEST;			 
		}
		else {	#right mesh edge 
			$y = $diff - (2* $T1) -$T2;
			$x = $T1-1;
			$p = $EAST; 
		}
	}
	my $NXw=log2($T1);
	my $NYw=log2($T2);
    my $addrencode=0;
    $addrencode = ($p<<($NXw+$NYw)|  ($y << $NXw) | $x);
    return $addrencode;	
}   

sub fmesh_endp_addr_decoder {
	my ($code, $T1, $T2, $T3)=@_;
	my ($x, $y, $p) =mesh_tori_addr_sep ($code, $T1, $T2, $T3);
	my  $LOCAL   =   0;  
	my	$EAST    =   1; 
	my	$NORTH   =   2;  
	my	$WEST    =   3;  
	my	$SOUTH   =   4;  
	return (($y*$T1)+$x)*$T3 if($p== $LOCAL);
	return (($y*$T1)+$x)*$T3+($p-$SOUTH) if($p > $SOUTH);
	return (($T1*$T2*$T3) + $x) if($p== $NORTH);
	return (($T1*$T2*$T3) + $T1 + $x) if($p== $SOUTH);
	return (($T1*$T2*$T3) + 2*$T1 + $y) if($p== $WEST );
	return (($T1*$T2*$T3) + 2*$T1 + $T2 + $y) if($p== $EAST );
	return 0; #should not reach here
}
	
	



sub get_router_num {
	my ($self,$x, $y)=@_;
	my $topology=$self->object_get_attribute('noc_param','TOPOLOGY');
	my $T1=$self->object_get_attribute('noc_param','T1');
	my $T2=$self->object_get_attribute('noc_param','T2');
	if($topology eq '"FATTREE"') {
		return fattree_addrdecode($x, $T1, $T2);
	}elsif ($topology eq '"RING"' || $topology eq '"LINE"' ||  $topology eq '"FMESH"'  ||  $topology eq '"MESH"' || $topology eq '"TORUS"'){
		 return ($y*$T1)+$x;		
	}else{#custom
		#It is not used for custom & STAR topology 
	}
}

sub router_addr_encoder{
	my ($self, $id)=@_;
	my $topology=$self->object_get_attribute('noc_param','TOPOLOGY');
	my $T1=$self->object_get_attribute('noc_param','T1');
	my $T2=$self->object_get_attribute('noc_param','T2');
	my $T3=$self->object_get_attribute('noc_param','T3');
	if($topology eq '"FATTREE"' || $topology eq '"TREE"') {
		return fattree_addrencode($id, $T1, $T2);
	}elsif ($topology eq '"RING"' || $topology eq '"LINE"'  ||  $topology eq '"MESH"' || $topology eq '"FESH"' || $topology eq '"TORUS"'){
		return mesh_tori_addrencode($id,$T1, $T2,1);
	}else { #custom & STAR
		return $id;		
	}	
}

sub endp_addr_encoder{
	my ($self, $id)=@_;
	my $topology=$self->object_get_attribute('noc_param','TOPOLOGY');
	my $T1=$self->object_get_attribute('noc_param','T1');
	my $T2=$self->object_get_attribute('noc_param','T2');
	my $T3=$self->object_get_attribute('noc_param','T3');
	if($topology eq '"FATTREE"' || $topology eq '"TREE"') {
		return fattree_addrencode($id, $T1, $T2);
	}elsif ($topology eq '"RING"' || $topology eq '"LINE"'  ||  $topology eq '"MESH"' || $topology eq '"TORUS"'){
		return mesh_tori_addrencode($id,$T1, $T2,$T3);
	}elsif ($topology eq '"FMESH"' ){
		return 	fmesh_addrencode($id,$T1, $T2,$T3);
	}else{#CUSTOM & STAR
		return $id;
	}
}

sub endp_addr_decoder {
	my ($self,$code)=@_;
	my $topology=$self->object_get_attribute('noc_param','TOPOLOGY');
	my $T1=$self->object_get_attribute('noc_param','T1');
	my $T2=$self->object_get_attribute('noc_param','T2');
	my $T3=$self->object_get_attribute('noc_param','T3');
	if($topology eq '"FATTREE"' || $topology eq '"TREE"') {
		return fattree_addrdecode($code, $T1, $T2);
	}
	elsif ($topology eq '"RING"' || $topology eq '"LINE"'  ||  $topology eq '"MESH"' || $topology eq '"TORUS"'){
		my ($x, $y, $l) = mesh_tori_addr_sep($code,$T1, $T2,$T3);
		#print "my ($x, $y, $l) = mesh_tori_addr_sep($code,$T1, $T2,$T3);\n";
		return (($y*$T1)+$x)*$T3+$l;
	}elsif ($topology eq '"FMESH"' ){
		return fmesh_endp_addr_decoder($code,$T1, $T2,$T3);
	}else{#custom & STAR
		return $code;
	}
}

sub mask_gen{
	my $k=shift;
	my $kw=0;
	my $mask=0;
	while((0x1<<$kw) < $k){
		$kw++;
		$mask<<=1;
		$mask|=0x1;
	}
	return $mask;
}


sub mesh_tori_addr_sep {
	my ($code,$NX, $NY,$NL)=@_;
	my ($x, $y, $l);
	my $NXw=log2($NX);
	my $NYw=log2($NY);
	$x = $code &  mask_gen($NX);
	$code>>=$NXw;
	$y = $code &   mask_gen($NY);
	$code>>=$NYw;
	$l = $code;
	return ($x, $y, $l);
}

sub mesh_tori_addrencode{
	my ($id,$T1, $T2,$T3)=@_;
	my ($x,$y,$l)=mesh_tori_addrencod_sep($id,$T1,$T2,$T3);
    return mesh_tori_addr_join($x,$y,$l,$T1, $T2,$T3);
}

sub  mesh_tori_addrencod_sep{
	my ($id,$T1,$T2,$T3)=@_;
	my ($x,$y,$l);
	$l=$id % $T3; # id%NL
	my $R= int($id / $T3);
	$x= $R % $T1;# (id/NL)%NX
	$y=int($R / $T1);# (id/NL)/NX
	return ($x,$y,$l);	
}

sub mesh_tori_addr_join {
	my ($x, $y, $l,$T1, $T2,$T3)=@_;
	my $NXw=log2($T1);
	my $NYw=log2($T2);
    my $addrencode=0;
    $addrencode =($T3==1)?   ($y << $NXw | $x) : ($l<<($NXw+$NYw)|  ($y << $NXw) | $x);
    return $addrencode;
}


sub mcast_partial_width {
        my ($p,$NE)=@_;
        my $m=0;
        $p=remove_not_hex($p);
        my @arr=split (//, $p);
        foreach my $i (@arr) {        	
        	my $n=hex($i);
        	$m++ if($n & 0x1);
        	$m++ if($n & 0x2);
        	$m++ if($n & 0x4);
        	$m++ if($n & 0x8);
        }
       return $m;
}



sub get_noc_verilator_top_modules_info {
	my ($self) =@_;
	
	my $topology=$self->object_get_attribute('noc_param','TOPOLOGY');
	my $T1=$self->object_get_attribute('noc_param','T1');
	my $T2=$self->object_get_attribute('noc_param','T2');
	my $T3=$self->object_get_attribute('noc_param','T3');
	my $cast = $self->object_get_attribute('noc_param','MCAST_ENDP_LIST');	
	my $CAST_TYPE= $self->object_get_attribute('noc_param','CAST_TYPE');	
	my $DAw_OFFSETw  =  ($topology eq '"MESH"' || $topology eq '"TORUS"' || $topology eq '"FMESH"')?  $T1 : 0; 
	
	
	my %tops;
	my %nr_p; # number of routers have $p port num
	my $router_p; #number of routers with different port number in topology 
	
	my ($ne, $nr, $RAw, $EAw)=get_topology_info($self); 

	my $MCAST_PRTLw= mcast_partial_width($cast,$ne);
	my $MCASTw =
            ($CAST_TYPE eq '"MULTICAST_FULL"') ? $ne :
            ($CAST_TYPE eq '"MULTICAST_PARTIAL"' && $EAw >= $MCAST_PRTLw) ? $EAw +1 : 
            ($CAST_TYPE eq '"MULTICAST_PARTIAL"' && $EAw <  $MCAST_PRTLw) ? $MCAST_PRTLw +1 :
            $EAw +1; #broadcast
	
	my $DAw = ($CAST_TYPE eq '"UNICAST"') ?   $EAw: $MCASTw +  $DAw_OFFSETw;           
	
	print "$DAw=$DAw\n";

	my $custom_include="";
	if($topology eq '"FATTREE"') {
		my $K =  $T1;
        my $L =  $T2;		
        my $p2 = 2*$K;       
        $router_p=2;
        my $NRL= $ne/$K; #number of router in  each layer
        $nr_p{1}=$NRL;
        $nr_p{2}=$nr-$NRL;
        $nr_p{p1}=$K;
        $nr_p{p2}=2*$K;
       
        %tops = (
			#"Vrouter1" => "router_top_v_p${K}.v", 
			#"Vrouter2" => "router_top_v_p${p2}.v", 
			"Vrouter1" => "--top-module  router_top_v  -GP=${K}  ", 
			"Vrouter2" => "--top-module  router_top_v  -GP=${p2} ", 
	       # "Vnoc" => " --top-module noc_connection ",
	 		
    	);
	}elsif ($topology eq '"TREE"'){
        my $K =  $T1;
        my $L =  $T2;		
        my $p2 = $K+1;       
        $router_p=2;# number of router with different port number                        
        $nr_p{1}=1;
        $nr_p{2}=$nr-1;
        $nr_p{p1}=$K;
        $nr_p{p2}=$K+1;
       
        %tops = (
			#"Vrouter1" => "router_top_v_p${K}.v", 
			#"Vrouter2" => "router_top_v_p${p2}.v",
			"Vrouter1" => "--top-module  router_top_v  -GP=${K}  ", 
			"Vrouter2" => "--top-module  router_top_v  -GP=${p2} ",  
	       # "Vnoc" => " --top-module noc_connection ", 		
    	);
		
	}elsif ($topology eq '"RING"' || $topology eq '"LINE"'){
		
		$router_p=1;
		$nr_p{1}=$nr;
		my $ports= 3+$T3-1;
		$nr_p{p1}=$ports;
		%tops = (
			#"Vrouter1" => "router_top_v_p${ports}.v", 
	       "Vrouter1" => "--top-module  router_top_v  -GP=${ports}  ", 
		  # "Vnoc" => " --top-module noc_connection ",
	 		
    	);
				
       
	}elsif ($topology eq '"MESH"' || $topology eq '"TORUS"' || $topology eq '"FMESH"') {
		
        $router_p=1;
        $nr_p{1}=$nr;
        my $ports= 5+$T3-1;
		$nr_p{p1}=$ports;
        %tops = (
        	#"Vrouter1" => "router_top_v_p${ports}.v",
        	"Vrouter1" => "--top-module  router_top_v  -GP=${ports}  ",  
	      #  "Vnoc" => " --top-module noc_connection",
	 		
    	);
    }elsif ($topology eq '"STAR"') { 
     	 $router_p=1;# number of router with different port number
     	 my $ports= $T1;
     	 $nr_p{p1}=$ports;
     	 $nr_p{1}=1;
     	  %tops = (
        	#"Vrouter1" => "router_top_v_p${ports}.v",
        	"Vrouter1" => "--top-module  router_top_v  -GP=${ports}  ",  
	      #  "Vnoc" => " --top-module noc_connection",
	 		
    	);
        
	}else {#custom
		
		my $dir =get_project_dir()."/mpsoc/rtl/src_topolgy";
		my $file="$dir/param.obj";	
		my %param;
		if(-f $file){
			my ($pp,$r,$err) = regen_object($file );
	        if ($r){        
	        	print "**Error: cannot open $file file: $err\n";
	            return;
	         } 
	         
		 	%param=%{$pp};		
		}else {
			print "**Error: cannot find $file \n";
			return;
		}
		 
	    my $topology_name=$self->object_get_attribute('noc_param','CUSTOM_TOPOLOGY_NAME'); 
		my $ref=$param{$topology_name}{'ROUTER_Ps'};
		print $ref;
		my %router_ps= %{$ref};
		my $i=1;
		#%tops = ("Vnoc" => " --top-module noc_connection");
		
		#should sort neumeric. The router with smaller port number should comes first
		
		foreach my $p (sort { $a <=> $b } keys  %router_ps){
			$nr_p{$i}=$router_ps{$p};
            $nr_p{"p$i"}=$p;
            #$tops{"Vrouter$i"}= "router_top_v_p${p}.v", 
            $tops{"Vrouter$i"}= "--top-module  router_top_v  -GP=${p}  ", 
			$i++;
			
		}	
		$router_p=$i-1;	
		${topology_name} =~ s/\"+//g;
		$custom_include="#define IS_${topology_name}_noc\n";
	}#else
	
		
	
	my $includ_h="\n";
	for (my $p=1; $p<=$router_p ; $p++){
		 $includ_h=$includ_h."#include \"Vrouter$p.h\" \n";
	}
	my $rns_num = $router_p+1;
	$includ_h.="int router_NRs[$rns_num];\n";
	
	my $max_p=0;
	for (my $p=1; $p<=$router_p ; $p++){
		  my $pnum= $nr_p{"p$p"};
		 $includ_h=$includ_h."#define NR${p} $nr_p{$p}\n";
	 	 $includ_h=$includ_h."#define NR${p}_PNUM $pnum\n";
		
		 $includ_h=$includ_h."Vrouter${p}		*router${p}[ $nr_p{$p} ];   // Instantiation of router with $pnum  port number\n";
		 $max_p = $pnum if($max_p < $pnum);
	}
	$includ_h.="#define MAX_P  $max_p //The maximum number of ports available in a router in this topology\n";
	
	$includ_h.="#define DAw $DAw //The traffic generator's destination address width\n";
	
	
	my $st1='';
	my $st2='';
	my $st3='';
	my $st4='';
	my $st5='';
	my $st6='';
	my $st7='';
	my $st8='';
		
	my $i=1;
	my $j=0;
	my $accum=0;
	for (my $p=1; $p<=$router_p ; $p++){
		$includ_h=$includ_h."
		
		

";
#if		ROUTER_P_NUM >$j

#endif

$st2=$st2."
    router_NRs[$p] =$nr_p{$p};
	for(i=0;i<NR${i};i++)	router${i}[i] 	= new Vrouter${i};            
";

$st3=$st3."
	for(i=0;i<NR${i};i++){
		router${i}[i]->reset= reset;
		router${i}[i]->clk= clk ;
	}
";

$st4=$st4."
	for(i=0;i<NR${i};i++) router${i}[i]->eval();
";


$st5=$st5."
	for(i=0;i<NR${i};i++) router${i}[i]->final();
";


$st6=$st6."
	if (i<NR${i}){ router${i}[i]->eval(); return;}
	i-=	NR${i};
";





$st7.="
	if (i<NR${i}){ 
		update_router_st(
			NR${i}_PNUM,
			router${i}[i]->current_r_id,   
			router${i}[i]->router_event
		); 
		return;
	}
	i-=	NR${i};
";

$st8=$st8."
	if (i<NR${i}){ 
		router${i}[i]->reset= reset;
		router${i}[i]->clk= clk ;
		return;
	}
	i-=	NR${i};
";



	$i++;
	$j++;
	$accum=$accum+$nr_p{$p};
	
}
	
	
$includ_h=$includ_h."


void Vrouter_new(){
	int i=0;
	$st2	
}

$custom_include

void inline connect_routers_reset_clk(){
	int i;
	$st3
}


void inline routers_eval(){
	int i=0;
	$st4
}

void inline routers_final(){
	int i;
	$st5
}	

void inline single_router_eval(int i){
	$st6
}

#define SMART_NUM  ((SMART_MAX==0)? 1 : SMART_MAX)
#if SMART_NUM > 8
	typedef unsigned int EVENT;
#else
	typedef unsigned char EVENT;
#endif

extern void update_router_st (
  unsigned int,
  unsigned int, 
  EVENT *  
);
 
void  single_router_st_update(int i){
	$st7
}

void  inline single_router_reset_clk(int i){
	$st8
}

	
";	

#$includ_h.=" void connect_all_nodes(){\n";

#my $dot_file=get_dot_file_text($self,'topology');
#print "$dot_file\n";
#my @lines =split ("\n",$dot_file);
#foreach my $l (@lines) {
#    if ( $l =~  m{#*\"\s*R(\d+)\"\s*:\s*\"[pP](\d+)\"\s*->\s*\"R(\d+)\"\s*:\s*\"[pP](\d+)\"} ) {
#		my ($R1, $P1, $R2,$P2) = ($1, $2,$3,$4);
#		$includ_h.=connect_sim_nodes ($self,$topology,$R1, $P1, $R2, $P2);
#		
#   
#	}
#	if ( $l =~  m{#*\"\s*R(\d+)\"\s*:\s*\"[pP](\d+)\"\s*->\s*\"[Tt](\d+)\"} ) {
#		my ($R1, $P1, $T) = ($1, $2,$3);
#		$includ_h.=connect_sim_nodes($self,$topology,$R1, $P1, $T);
#		
#   
#	}
#	if ( $l =~  m{#*\s*\"[Tt](\d+)\"\s*->\s*\"R(\d+)\"\s*:\s*\"[pP](\d+)\"} ) {
#   		my ($T, $R1, $P1) = ($1, $2,$3);
#		$includ_h.=connect_sim_nodes($self,$topology,$R1, $P1, $T);
#	}
#} 
#$includ_h.="\n}\n";

	 return ($nr,$ne,$router_p,\%tops,$includ_h);	
}

sub connect_sim_nodes{
	my ($self,$topology,$R1, $P1, $R2, $P2)=@_;
	if(defined $P2){ #R2R
		if($topology eq '"FATTREE"' || $topology eq '"TREE"'){
			
		}else{
			return connect_r2r(1,$R1, $P1,1, $R2, $P2);
			
		}
	}else {
		my $T=$R2;
		if($topology eq '"FATTREE"' || $topology eq '"TREE"'){
			
		}else{
			return connect_r2t(1,$R1, $P1, $T);
			
		}
		
	}
	
	
}

sub connect_r2r{
	my ($vrouter1_num,$r1,$p1,$vrouter2_num,$r2,$p2)=@_;
return "	
	memcpy(&router${vrouter1_num}[$r1]->chan_in[$p1], router${vrouter2_num}[$r2]->chan_out[$p2] , sizeof( router${vrouter1_num}[$r1]->chan_in[$p1] ) );
	memcpy(&router${vrouter2_num}[$r2]->chan_in[$p2], router${vrouter1_num}[$r1]->chan_out[$p1] , sizeof( router${vrouter1_num}[$r1]->chan_in[$p1] ) );
	";
}

sub connect_r2t{
my ($vrouter1_num,$r1, $p1, $T)=@_;
return "
	memcpy(&router${vrouter1_num}[$r1]->chan_in[$p1], traffic[$T]->chan_out , sizeof( traffic[$T]->chan_in ) );
	memcpy(&traffic[$T]->chan_in, router${vrouter1_num}[$r1]->chan_out[$p1] , sizeof( traffic[$T]->chan_in ) );	
	";
}


sub gen_tiles_physical_addrsses_header_file{
	my ($self,$file)=@_;
	my $topology=$self->object_get_attribute('noc_param','TOPOLOGY');
	my $txt = "#ifndef PHY_ADDR_H
	#define PHY_ADDR_H\n\n";
	
	#add phy addresses
	my ($NE, $NR, $RAw, $EAw,$Fw)=get_topology_info($self);
	for (my $id=0; $id<$NE; $id++){
		my $phy= endp_addr_encoder($self,$id);	
		my $hex = sprintf("0x%x", $phy);
		$txt=$txt."\t#define PHY_ADDR_ENDP_$id  $hex\n";	
		
	}	
		
	
	$txt=$txt."#endif\n";
	save_file($file,$txt);		
}


sub get_endpoints_mah_distance {
	my ($self,$endp1,$endp2)=@_;
	
	my $router1=get_connected_router_id_to_endp($self,$endp1);
	my $router2=get_connected_router_id_to_endp($self,$endp2);
	
	my $topology=$self->object_get_attribute('noc_param','TOPOLOGY');
	if($topology eq '"FATTREE"' || $topology eq '"TREE"') {
		return fattree_mah_distance($self, $router1,$router2);
	}elsif ($topology eq '"RING"' || $topology eq '"LINE"'  ||  $topology eq '"MESH"' || $topology eq '"TORUS"' || $topology eq '"FMESH"' ){
		return mesh_tori_mah_distance($self, $router1,$router2);
	}elsif ($topology eq '"STAR"'){
		return 1;
	}else { #custom
		return undef;		
	}	
	
}

sub mesh_tori_mah_distance {
	my ($self, $router1,$router2)=@_;
	my $T1=$self->object_get_attribute('noc_param','T1');
	my $T2=$self->object_get_attribute('noc_param','T2');
	my ($x1,$y1,$l1) = mesh_tori_addrencod_sep ($router1,$T1,$T2,1);
	my ($x2,$y2,$l2) = mesh_tori_addrencod_sep ($router2,$T1,$T2,1);
	my $x_diff = ($x1 > $x2) ? ($x1 - $x2) : ($x2 - $x1);
	my $y_diff = ($y1 > $y2) ? ($y1 - $y2) : ($y2 - $y1);
	my $mah_distance = $x_diff + $y_diff;
	return $mah_distance;	
}

sub fattree_mah_distance {
	my ($self, $router1,$router2)=@_;
	my $k =$self->object_get_attribute('noc_param','T1');
	my $l =$self->object_get_attribute('noc_param','T2');
	
	my  $pow; 
	my $tmp1;
	my $tmp2;	
	my $distance=0;
	$pow=1;
	for (my $i = 0; $i <$l; $i=$i+1 ) {
		$tmp1=int($router1/$pow);
		$tmp2=int($router2/$pow);		
		$tmp1=$tmp1 % $k;
		$tmp2=$tmp2 % $k;		
		$pow=$pow * $k;		
		$distance= ($i+1)*2-1 if($tmp1!=$tmp2); # distance obtained based on the highest level index which differ 
		
	}
	 return $distance;	
}	

1
