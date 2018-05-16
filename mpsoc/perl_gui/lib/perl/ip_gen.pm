#!/usr/bin/perl -w -I ..
###############################################################################
#
# File:         interface.pm
# 
#
###############################################################################
use warnings;
use strict;


package ip_gen;
#use Clone 'clone';



sub ip_gen_new {
    # be backwards compatible with non-OO call
    my $class = ("ARRAY" eq ref $_[0]) ? "ip_gen" : shift;
    my $self;

   
    $self = {};
    $self->{file_name}        = (); 
    $self->{parameters_order}=[];
    $self->{ports_order}=[];
    $self->{hdl_files}=[];
	
	

    bless($self,$class);

   
    return $self;
} 



sub ipgen_set_module_list{
	my ($self,@list)=@_;
	$self->{modules}={};
	foreach my $p(@list) {			
		$self->{modules}{$p}={};	
	}
	
}	



sub ipgen_get_module_list{
		my ($self)=@_;
		my @modules;
		if(exists($self->{modules})){
			@modules=keys %{$self->{modules}};
		}
		return @modules;
}		



sub ipgen_add_parameter{
	my ($self,$parameter,$default,$type,$content,$info,$global_param,$redefine)=@_;
	$self->{parameters}{$parameter}{"default"}=$default;	
	$self->{parameters}{$parameter}{type}=$type;
	$self->{parameters}{$parameter}{content}=$content;
	$self->{parameters}{$parameter}{info}=$info;
	$self->{parameters}{$parameter}{global_param}=$global_param;
	$self->{parameters}{$parameter}{redefine_param}=$redefine;						
}	






sub ipgen_push_parameters_order{
	my ($self,$param)=@_;
	if(defined $param){
		push(@{$self->{parameters_order}},$param);
	}

}

sub ipgen_remove_parameters_order{
	my ($self,$param)=@_;
	my @r=@{$self->{parameters_order}};
	my @n;
	foreach my $p(@r){
		if( $p ne $param) {push(@n,$p)};	

	}
	$self->{parameters_order}=\@n;

}


sub ipgen_add_ports_order{
	my ($self,@ports_order) =@_;
	$self->{ports_order}=\@ports_order;
}



sub ipgen_get_ports_order{
	my $self =shift;
	my @order=(defined $self->{ports_order})?  @{$self->{ports_order}} : undef;
    return  @order;
}




sub ipgen_remove_parameter{
	my ($self,$parameter)=@_;
	if(exists ( $self->{parameters}{$parameter})){
		delete $self->{parameters}{$parameter};	
	}
}	
	
sub ipgen_get_parameter_detail{
	my ($self,$parameter)=@_;
	my ($default,$type,$content,$info,$global_param,$redefine);
	if(exists ($self->{parameters}{$parameter})){
		$default		=$self->{parameters}{$parameter}{"default"};
		$type 			=$self->{parameters}{$parameter}{type};
		$content 		=$self->{parameters}{$parameter}{content};
		$info			=$self->{parameters}{$parameter}{info};
		$global_param		=$self->{parameters}{$parameter}{global_param};
		$redefine		=$self->{parameters}{$parameter}{redefine_param};	
		
	}		
	return ($default,$type,$content,$info,$global_param,$redefine);	
}		

sub ipgen_get_all_parameters_list{
	my ($self)=@_;
	my @parameters;
	if(exists ($self->{parameters})){
		foreach my $p ( keys %{$self->{parameters}}){
			push(@parameters,$p);
		}	
	}		
	return @parameters;
}		

sub ipgen_remove_all_parameters{
	my ($self)=@_;
	if (exists ($self->{parameters})){
		delete $self->{parameters};
	}
}	



sub ipgen_add_port{
	my($self,$port,$range,$type,$intfc_name,$intfc_port)=@_;
	$self->{ports}{$port}{range}=$range;
	$self->{ports}{$port}{type}=$type;
	$self->{ports}{$port}{intfc_name}=$intfc_name;
	$self->{ports}{$port}{intfc_port}=$intfc_port;
}

sub ipgen_get_port{
	my($self,$port)=@_;
	my($range,$type,$intfc_name,$intfc_port);
	if(exists ($self->{ports}{$port})){
		$range=$self->{ports}{$port}{range};
		$type=$self->{ports}{$port}{type};
		$intfc_name=$self->{ports}{$port}{intfc_name};
		$intfc_port=$self->{ports}{$port}{intfc_port};
	}
	return ($range,$type,$intfc_name,$intfc_port);
}


sub ipgen_list_ports{
	my($self)=@_;
	my @ports;
	foreach my $p (keys %{$self->{ports}}){
		push (@ports,$p);
	}	
	return @ports;
}



sub ipgen_remove_all_ports{
	my $self=shift;
	if (exists ($self->{ports})){
		delete $self->{ports};
	}
	
}		

sub ipgen_add_soket{
	my ($self,$socket,$type,$value,$connection_num)=@_;
	$self->{sockets}{$socket}{type}=$type;
	if(defined $value) {
		$self->{sockets}{$socket}{value}=$value;
		
	}
	if(defined $connection_num) {$self->{sockets}{$socket}{connection_num}=$connection_num;}	
	if($type eq 'num'){
		if($value == 1) {ipgen_set_socket_name($self,$socket,0,$socket);}
		else{
				for (my $i=0; $i<$value; $i++){
					my $name="$socket\_$i";
					ipgen_set_socket_name($self,$socket,$i,$name);
				}
			
		}	
		
	}
	else{ipgen_set_socket_name($self,$socket,0,$socket);}		
	
	#print "\$self->{sockets}{$socket}{type}=$type;\n"
}

sub ipgen_add_plug{
	my ($self,$plug,$type,$value)=@_;
	$self->{plugs}{$plug}{type}=$type;
	if(defined $value){$self->{plugs}{$plug}{value}=$value};
	if($type eq 'num'){
		if($value == 1) {ipgen_set_plug_name($self,$plug,0,$plug);}
		else{
				for (my $i=0; $i<$value; $i++){
					my $name="$plug\_$i";
					ipgen_set_plug_name($self,$plug,$i,$name);
				}
			
		}	
		
	}
	else{ipgen_set_plug_name($self,$plug,0,$plug);}		
	
}		

sub ipgen_list_sokets{
	my ($self)=@_;
	my @sokets;
	
	if(exists ($self->{sockets})){
		foreach my $p(keys %{$self->{sockets}}){
			push (@sokets,$p);
		}
	}	
	return @sokets;	
}


sub ipgen_list_plugs{
	my ($self)=@_;
	my @plugs;
	if(exists ($self->{plugs})){
		foreach my $p(keys %{$self->{plugs}}){
			push (@plugs,$p);
		}
	}	
	return @plugs;	
}
	


sub ipgen_get_socket{
	my ($self,$socket)=@_;
	my ($type,$value,$connection_num);
	if(exists ($self->{sockets}{$socket})){		
		$type	=$self->{sockets}{$socket}{type};
		$value	=$self->{sockets}{$socket}{value};
		$connection_num= $self->{sockets}{$socket}{connection_num};
		#print "$type,$value\n"
	} 
	return ($type,$value,$connection_num);
}

sub ipgen_get_plug{
	my ($self,$plug)=@_;
	my ($type,$value,$connection_num);
	if(exists ($self->{plugs}{$plug})){
		$type	=$self->{plugs}{$plug}{type};
		$value	=$self->{plugs}{$plug}{value};
		$connection_num=$self->{plugs}{$plug}{connection_num};
	}
	return ($type,$value,$connection_num);
}

sub ipgen_remove_socket{
		my ($self,$socket)=@_;
		if(exists ($self->{sockets}{$socket})) {
				delete $self->{sockets}{$socket};
		}	
}	

sub ipgen_remove_plug{
		my ($self,$plug)=@_;
		if(exists ($self->{plugs}{$plug})) {
				delete $self->{plugs}{$plug};
		}	
}	
	
	

sub ipgen_set_port_intfc_name{
	my ($self,$port,$intfc_name)=@_;	
	if(exists ($self->{ports}{$port})){
		$self->{ports}{$port}{intfc_name}=$intfc_name;
	}

}

sub ipgen_get_port_intfc_name{
	my ($self,$port)=@_;
	my $intfc_name;
	if(exists ($self->{ports}{$port}{intfc_name})){
		$intfc_name=$self->{ports}{$port}{intfc_name};
	}
	return ($intfc_name);
}	

sub ipgen_set_port_intfc_port{
	my ($self,$port,$intfc_port)=@_;	
	if(exists ($self->{ports}{$port})){
		$self->{ports}{$port}{intfc_port}=$intfc_port;
	}

}

sub ipgen_get_port_intfc_port{
	my ($self,$port)=@_;
	my $intfc_port;
	if(exists ($self->{ports}{$port}{intfc_port})){
		$intfc_port=$self->{ports}{$port}{intfc_port};
	}
	return ($intfc_port);
}	
	
	





sub ipgen_save_wb_addr{
	my ($self,$plug,$num,$addr,$width)=@_;
	$self->{plugs}{$plug}{$num}{addr}=$addr;
	$self->{plugs}{$plug}{$num}{width}=$width;	
	
}	
	
sub ipgen_get_wb_addr{
	my ($self,$plug,$num)=@_;
	my($addr,$width);
	if(exists ($self->{plugs}{$plug}{$num})){
		$addr= $self->{plugs}{$plug}{$num}{addr};
		$width=$self->{plugs}{$plug}{$num}{width};
	}
	return 	($addr,$width); 
}		
	
sub ipgen_set_plug_name{
	my ($self,$plug,$num,$name)=@_;
	if(exists ($self->{plugs}{$plug})){
		$self->{plugs}{$plug}{$num}{name}=$name;
		
	}	
	
}	


sub ipgen_get_plug_name{
	my ($self,$plug,$num)=@_;
	my $name;
	if(exists ($self->{plugs}{$plug}{$num}{name})){
		 $name=$self->{plugs}{$plug}{$num}{name};
		
	}
	return 	$name;	
}

sub ipgen_set_socket_name {
	my ($self,$socket,$num,$name)= @_;
	if(exists ($self->{sockets}{$socket})){
		$self->{sockets}{$socket}{$num}{name}=$name;
		
	}	
	
}	

sub ipgen_get_socket_name{
	my ($self,$socket,$num)=@_;
	my $name;
	if(exists ($self->{sockets}{$socket}{$num}{name})){
		$name=$self->{sockets}{$socket}{$num}{name};
		
	}	
	return $name;
	
}		

	

sub ipgen_add_unused_intfc_port{
	my ($self,$intfc_name,$port)=@_;
	push(@{$self->{unused}{$intfc_name}},$port);	
}





#add,read,remove object fileds

sub ipgen_add{
	my ($self,$filed_name,$filed_data)=@_;
	$self->{$filed_name}=$filed_data;		
}

sub ipgen_remove{
	my ($self,$filed_name)=@_;
	$self->{$filed_name}=undef;		
}

sub ipgen_get{
	my ($self,$filed_name)=@_;
	return $self->{$filed_name}		
}

sub ipgen_get_list{
	my ($self,$list_name)=@_;
	my @l;
	if ( defined $self->{$list_name} ){
		@l=@{$self->{$list_name}};		
	}	
	
	return @l;
}




######################################




sub top_gen_new {
    # be backwards compatible with non-OO call
    my $class =  shift;
    my $self;

   
    $self = {};
    $self->{instance_ids}={};
    bless($self,$class);

   
    return $self;
} 

sub top_add_def_to_instance {
	my ($self,$inst,$def,$value )=@_;
		$self->{instance_ids}{$inst}{$def}=$value;
}

sub top_get_def_of_instance {
	my ($self,$inst,$def)=@_;
	my $val;
	$val=$self->{instance_ids}{$inst}{$def} if(exists $self->{instance_ids}{$inst}{$def})	;
	return $val;
}


sub top_add_port{
	my($self,$inst,$port,$range,$type,$intfc_name,$intfc_port)=@_;
	
	#all ports
	$self->{ports}{$port}{range}=$range;
	$self->{ports}{$port}{type}=$type;
	$self->{ports}{$port}{intfc_name}=$intfc_name;
	$self->{ports}{$port}{intfc_port}=$intfc_port;
	$self->{ports}{$port}{instance_name}=$inst;
	
	
	#based on instance name	
	$self->{instance_ids}{$inst}{ports}{$port}{range}=$range;
	$self->{instance_ids}{$inst}{ports}{$port}{type}=$type;
	$self->{instance_ids}{$inst}{ports}{$port}{intfc_name}=$intfc_name;
	$self->{instance_ids}{$inst}{ports}{$port}{intfc_port}=$intfc_port;
	
	#based on interface name
	$self->{interface}{$intfc_name}{ports}{$port}{range}=$range;
	$self->{interface}{$intfc_name}{ports}{$port}{type}=$type;
	$self->{interface}{$intfc_name}{ports}{$port}{instance_name}=$inst;
	$self->{interface}{$intfc_name}{ports}{$port}{intfc_port}=$intfc_port;
}




sub top_get_port{
	my($self,$port)=@_;
	my($inst,$range,$type,$intfc_name,$intfc_port);
	$inst		=$self->{ports}{$port}{instance_name};
	$range		=$self->{ports}{$port}{range};
	$type		=$self->{ports}{$port}{type};
	$intfc_name	=$self->{ports}{$port}{intfc_name};
	$intfc_port	=$self->{ports}{$port}{intfc_port};
	return ($inst,$range,$type,$intfc_name,$intfc_port);	
}

sub top_get_port_list{
	my$self=shift;
	my @l;
	if(exists $self->{ports}){
		@l= sort keys %{$self->{ports}};
	}
	return @l;
}



sub top_add_parameter{
	my ($self,$inst,$parameter,$default,$type,$content,$info,$global_param,$redefine)=@_;
	$self->{instance_ids}{$inst}{parameters}{$parameter}{"default"}=$default;	
	$self->{instance_ids}{$inst}{parameters}{$parameter}{type}=$type;
	$self->{instance_ids}{$inst}{parameters}{$parameter}{content}=$content;
	$self->{instance_ids}{$inst}{parameters}{$parameter}{info}=$info;
	$self->{instance_ids}{$inst}{parameters}{$parameter}{global_param}=$global_param;
	$self->{instance_ids}{$inst}{parameters}{$parameter}{redefine_param}=$redefine;						
}	

sub top_get_parameter{
	my ($self,$inst,$parameter)=@_;
	my ($default,$type,$content,$info,$global_param,$redefine);
	$default=$self->{instance_ids}{$inst}{parameters}{$parameter}{"default"};	
	$type=$self->{instance_ids}{$inst}{parameters}{$parameter}{type};
	$content=$self->{instance_ids}{$inst}{parameters}{$parameter}{content};
	$info=$self->{instance_ids}{$inst}{parameters}{$parameter}{info};
	$global_param=$self->{instance_ids}{$inst}{parameters}{$parameter}{global_param};
	$redefine=$self->{instance_ids}{$inst}{parameters}{$parameter}{redefine_param};	
	return  ($default,$type,$content,$info,$global_param,$redefine);					
}	

sub top_get_parameter_list{
	my($self,$inst)=@_;
	my @l;
	if(exists $self->{instance_ids}{$inst}{parameters}){
		@l= sort keys %{$self->{instance_ids}{$inst}{parameters}};
	}
	return @l;
}

sub top_add_default_soc_param{
	my ($self,$param_ref)=@_;
	my %l=%{$param_ref};
	foreach my $p (sort keys %l){	
		$self->{parameters}{$p}=$l{$p};
		#print"$self->{parameters}{$p}=$l{$p};\n";
	}	
}	

sub top_get_default_soc_param{
	my $self=shift;
	my %l;
	if(exists $self->{parameters}){
		 %l=%{$self->{parameters}};
	}
	return  %l;
}	
	
	
sub top_get_all_instances{
	my ($self)=shift;
	my @r= keys %{$self->{instance_ids}};
	return @r;	
	
}


sub top_get_intfc_list{
	my ($self)=shift;
	my @intfcs;
	if(exists $self->{interface}){
		@intfcs= sort keys %{$self->{interface}};
	}
	
	return 	@intfcs;
}


sub top_get_intfc_ports_list{
	my($self,$intfc_name)=@_;
	my @ports;
	if( exists $self->{interface}{$intfc_name}{ports}){
		@ports= sort keys %{$self->{interface}{$intfc_name}{ports}};
	}
	return @ports;
}


sub top_add_custom_soc_param{
	my ($self,$param_ref,$tile)=@_;
	my %l=%{$param_ref};
	foreach my $p (sort keys %l){	
		$self->{tiles}{$tile}{parameters}{$p}=$l{$p};
		#print"$self->{parameters}{$p}=$l{$p};\n";
	}	
}	
	
sub top_get_custom_soc_param{
	my ($self,$tile)=@_;
	my %l;
	if(exists $self->{tiles}{$tile}{parameters}){#get custom param
		 %l=%{$self->{tiles}{$tile}{parameters}};
	}elsif (exists $self->{parameters}){#get default param
		 %l=%{$self->{parameters}};
	}
	return  %l;
	
}		



sub object_add_attribute{
	my ($self,$attribute1,$attribute2,$value)=@_;
	if(!defined $attribute2){$self->{$attribute1}=$value;}
	else {$self->{$attribute1}{$attribute2}=$value;}

}

sub object_get_attribute{
	my ($self,$attribute1,$attribute2)=@_;
	if(!defined $attribute2) {return $self->{$attribute1};}
	return $self->{$attribute1}{$attribute2};


}

sub object_add_attribute_order{
	my ($self,$attribute,@param)=@_;
	$self->{'parameters_order'}{$attribute}=[] if (!defined $self->{parameters_order}{$attribute});
	foreach my $p (@param){
		push (@{$self->{parameters_order}{$attribute}},$p);

	}
}

sub object_get_attribute_order{
	my ($self,$attribute)=@_;
	return @{$self->{parameters_order}{$attribute}};
}
	


	1
