#!/usr/bin/perl -w

#this fle contains NoC topology related subfunctions

use Glib qw/TRUE FALSE/;
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
        $EAw = $RAw;          
	
	}elsif($topology eq '"FATTREE"') {
		my $K =  $T1;
        my $L =  $T2;
		$NE = powi( $K,$L );
        $NR = $L * powi( $L , $L - 1 );
        my $Kw=log2($K);
        my $LKw=$L*$Kw;
        my $Lw=log2($L);  
        $RAw=$LKw + $Lw;   
        $EAw = $RAw;      
		
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
       
	}else {#mesh torus
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
	}else{
		 return int($endp_id/$T3);
	}	
}


sub get_router_num {
	my ($self,$x, $y)=@_;
	my $topology=$self->object_get_attribute('noc_param','TOPOLOGY');
	my $T1=$self->object_get_attribute('noc_param','T1');
	my $T2=$self->object_get_attribute('noc_param','T2');
	if($topology eq '"FATTREE"') {
		return fattree_addrdecode($x, $T1, $T2);
	}else{
		 return ($y*$T1)+$x;		
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
	}else{
		return mesh_tori_addrencode($id,$T1, $T2,1);
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
	}else{
	return mesh_tori_addrencode($id,$T1, $T2,$T3);
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
	else{
		my ($x, $y, $l) = mesh_tori_addr_sep($code,$T1, $T2,$T3);
		return (($y*$T1)+$x)*$T3+$l;
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





sub get_noc_verilator_top_modules_info {
	my ($self) =@_;
	
	my $topology=$self->object_get_attribute('noc_param','TOPOLOGY');
	my $T1=$self->object_get_attribute('noc_param','T1');
	my $T2=$self->object_get_attribute('noc_param','T2');
	my $T3=$self->object_get_attribute('noc_param','T3');
	
	my %tops;
	my %nr_p; # number of routers have $p port num
	my $router_p; #number of routers with different port number in topology 
	
	my ($ne,$nr) =get_topology_info($self);
	
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
			"Vrouter1" => "router_verilator_p${K}.v", 
			"Vrouter2" => "router_verilator_p${p2}.v", 
	        "Vnoc" => "noc_connection.sv",
	 		
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
			"Vrouter1" => "router_verilator_p${K}.v", 
			"Vrouter2" => "router_verilator_p${p2}.v", 
	        "Vnoc" => "noc_connection.sv",	 		
    	);
		
	}elsif ($topology eq '"RING"' || $topology eq '"LINE"'){
		
		$router_p=1;
		$nr_p{1}=$nr;
		my $ports= 3+$T3-1;
		$nr_p{p1}=$ports;
		%tops = (
			"Vrouter1" => "router_verilator_p${ports}.v", 
	        "Vnoc" => "noc_connection.sv",
	 		
    	);
				
       
	}else {#mesh torus
		
        $router_p=1;
        $nr_p{1}=$nr;
        my $ports= 5+$T3-1;
		$nr_p{p1}=$ports;
        %tops = (
			"Vrouter1" => "router_verilator_p${ports}.v", 
	        "Vnoc" => "noc_connection.sv",
	 		
    	);
        
	}
	
	my $includ_h="\n";
	for (my $p=1; $p<=$router_p ; $p++){
		 $includ_h=$includ_h."#include \"Vrouter$p.h\" \n";
	}
	for (my $p=1; $p<=$router_p ; $p++){
		 $includ_h=$includ_h."#define NR${p} $nr_p{$p}\n";
		 $includ_h=$includ_h."Vrouter${p}		*router${p}[ $nr_p{$p} ];   // Instantiation of router with   port number\n";
	}
	
	for (my $p=1; $p<=$router_p ; $p++){
		$includ_h=$includ_h."
		
	#define NE  $ne
 	#define NR  $nr
 	#define ROUTER_P_NUM $router_p
 	
 	extern Vnoc		 	*noc;
    extern int reset,clk;
 	
 	
		
void router${p}_connect_to_noc (unsigned int r, unsigned int n){
	unsigned int j;
	int flit_out_all_size = sizeof(router${p}[0]->flit_out_all)/sizeof(router${p}[0]->flit_out_all[0]);
	router${p}[r]->current_r_addr	= noc->current_r_addr[n];
	router${p}[r]->neighbors_r_addr 	= noc->neighbors_r_addr[n];
	

	router${p}[r]->flit_in_we_all	= noc->router_flit_out_we_all[n];
	router${p}[r]->credit_in_all	= noc->router_credit_out_all[n];
	router${p}[r]->congestion_in_all	= noc->router_congestion_out_all[n];
	for(j=0;j<flit_out_all_size;j++)router${p}[r]->flit_in_all[j] 	= noc->router_flit_out_all[n][j];
		noc->router_flit_in_we_all[n]	=	router${p}[r]->flit_out_we_all ;
		noc->router_credit_in_all[n]	=	router${p}[r]->credit_out_all;
		noc->router_congestion_in_all[n]=	router${p}[r]->congestion_out_all;
	for(j=0;j<flit_out_all_size;j++) noc->router_flit_in_all[n][j]	= router${p}[r]->flit_out_all[j] ;	
}
";
	}
$includ_h=$includ_h."
void inline connect_all_routers_to_noc ( ){
	int i;
if((strcmp(TOPOLOGY ,\"FATTREE\")==0) || (strcmp(TOPOLOGY ,\"TREE\")==0) ){				
				for(i=0;i<NR1;i++) router1_connect_to_noc (i, i);
#if		ROUTER_P_NUM >1
				for(i=0;i<NR2;i++) router2_connect_to_noc (i, i+NR1);
#endif
				
			}else{
				for (i=0;i<NR1;i++) 	router1_connect_to_noc (i, i);						
			}
}

void Vrouter_new(){
	int i=0;
	for(i=0;i<NR1;i++)	router1[i] 	= new Vrouter1;             // root nodes
#if		ROUTER_P_NUM >1
	for(i=0;i<NR2;i++)	router2[i] 	= new Vrouter2;             // leaves
#endif

	
}

void inline connect_routers_reset_clk(){
	int i;
	for(i=0;i<NR1;i++) {
		router1[i]->reset= reset;
		router1[i]->clk= clk ;
	}
#if		ROUTER_P_NUM >1
	for(i=0;i<NR2;i++) {
		router2[i]->reset= reset;
		router2[i]->clk= clk ;
	}
#endif
}


void inline routers_eval(){
	int i=0;
	for(i=0;i<NR1;i++) router1[i]->eval();
#if		ROUTER_P_NUM >1
	for(i=0;i<NR2;i++) router2[i]->eval();
#endif
}

void inline routers_final(){
	int i;
	for(i=0;i<NR1;i++) router1[i]->final();
#if		ROUTER_P_NUM >1
		for(i=0;i<NR2;i++) router2[i]->final();
#endif
}		
";	
	 return ($nr,$ne,$router_p,\%tops,$includ_h);	
}


sub gen_tiles_physical_addrsses_header_file{
	my ($self,$file)=@_;
	my $topology=$self->object_get_attribute('noc_param','TOPOLOGY');
	my $txt = "#ifndef PHY_ADDR_H
	#define PHY_ADDR_H\n\n";
	
	#add phy addresses
	my ($NE, $NR, $RAw, $EAw)=get_topology_info($self);
	for (my $id=0; $id<$NE; $id++){
		my $phy= endp_addr_encoder($self,$id);	
		my $hex = sprintf("0x%x", $phy);
		$txt=$txt."\t#define PHY_ADDR_ENDP_$id  $hex\n";	
		
	}	
		
	
	$txt=$txt."#endif\n";
	save_file($file,$txt);		
}



1
