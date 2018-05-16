#! /usr/bin/perl -w
use strict;

package soc;

use ip;


sub soc_new {
    # be backwards compatible with non-OO call
    my $class = ("ARRAY" eq ref $_[0]) ? "soc" : shift;
    my $self;
  
    $self = {};
    $self->{modules}        = {}; 
    $self->{instance_order}=();
    $self->{hdl_files}=();
  
    bless($self,$class);
  
    return $self;
} 


sub soc_add_instance{
	my ($self,$instance_id,$category,$module,$ip) = @_;
	if(exists ($self->{instances}{$instance_id})){
		return 0;
	}
	my $module_name=$ip->ip_get($category,$module,"module_name");
	#print "$module_name\n";
	$self->{instances}{$instance_id}={};
	$self->{instances}{$instance_id}{module}=$module;
	$self->{instances}{$instance_id}{module_name}=$module_name;
	$self->{instances}{$instance_id}{category}=$category;
	$self->{instances}{$instance_id}{instance_name}=$instance_id;
	my @sockets=$ip->ip_get_module_sockets_list($category,$module);
	foreach my $socket(@sockets){
		my ($type,$value,$connection_num)=$ip->ip_get_socket ($category,$module,$socket);
		soc_add_socket_to_instance($self,$instance_id,$socket,$type,$value,$connection_num);
		#add socket names
		my $int_num=($type eq 'num')? $value :1;
		for (my $i=0;$i<$int_num;$i++){
			my $name=$ip->ip_get_socket_name($category,$module, $socket,$i);
			$self->{instances}{$instance_id}{sockets}{$socket}{nums}{$i}{name}=$name;
		}	
		
		
	}
	my @plugs=$ip->ip_get_module_plugs_list($category,$module);
	foreach my $plug(@plugs){
		my ($type,$value,$connection_num)=$ip->ip_get_plug ($category,$module,$plug);
		soc_add_plug_to_instance($self,$instance_id,$plug,$type,$value,$connection_num);
		#add plug names anf Default connection as IO
		my $int_num=($type eq 'num')? $value :1;
		for (my $i=0;$i<$int_num;$i++){
			my $name=$ip->ip_get_plug_name($category,$module, $plug,$i);
			$self->{instances}{$instance_id}{plugs}{$plug}{nums}{$i}{name}=$name;
			soc_add_instance_plug_conection($self,$instance_id,$plug,$i,"IO");
			my ($addr , $width) =$ip->ip_get_wb_addr ($category,$module,$plug,$i);
			if(defined $addr){
				$self->{instances}{$instance_id}{plugs}{$plug}{nums}{$i}{addr}=$addr;
				$self->{instances}{$instance_id}{plugs}{$plug}{nums}{$i}{width}=$width;
			}	
		}
	}


	$self->{instances}{$instance_id}{description_pdf}=$ip->ip_get($category,$module,'description_pdf');
	
	return 1;
}

sub soc_add_instance_order{
	my ($self,$instance_id)=@_;
	push (@{$self->{instance_order}},$instance_id);
	#print " @{$self->{instance_order}} \n";	
}

sub soc_remove_scolar_from_array{
	my ($array_ref,$item)=@_;
	my @array=@{$array_ref};
	my @new;
	foreach my $p (@array){
		if($p ne $item ){
			push(@new,$p);
		}		
	}
	return @new;	
}

sub soc_get_scolar_pos{
	my ($item,@list)=@_;
	my $pos;
	my $i=0;
	foreach my $c (@list)
	{
		if(  $c eq $item) {$pos=$i}
		$i++;
	}	
	return $pos;	
}	

sub soc_remove_from_instance_order{
	my ($self,$instance_id)=@_;
	my @a=soc_remove_scolar_from_array($self->{instance_order},$instance_id);
	$self->{instance_order}=\@a;
	#print " @{$self->{instance_order}} \n";	
}

sub soc_get_instance_order{
	my $self=shift;
	my @order;
	@order = @{$self->{instance_order}} if (defined $self->{instance_order});
	return @order;	
}

sub soc_increase_instance_order{
	my ($self,$item)=@_;
	my @order;
	if (defined $self->{instance_order}){
		@order = @{$self->{instance_order}}; 
		my $pos=soc_get_scolar_pos($item,@order);
		if(defined $order[$pos+1] ){
			$order[$pos]=$order[$pos+1];
			$order[$pos+1]=$item;
			$self->{instance_order}=\@order;			
		}	
	}		
}

sub soc_decrease_instance_order{
	my ($self,$item)=@_;
	my @order;
	if (defined $self->{instance_order}){
		@order = @{$self->{instance_order}}; 
		my $pos=soc_get_scolar_pos($item,@order);
		if($pos !=0 ){
			$order[$pos]=$order[$pos-1];
			$order[$pos-1]=$item;
			$self->{instance_order}=\@order;			
		}	
	}		
}

sub soc_get_module_name{
	my ($self,$instance_id)=@_;
	my $module_name;
	if(exists ($self->{instances}{$instance_id}{module_name})){
		$module_name= $self->{instances}{$instance_id}{module_name};
	}
	return $module_name;	
}	


sub soc_get_description_pdf{
	my ($self,$instance_id)=@_;
	return $self->{instances}{$instance_id}{description_pdf};
}

sub soc_get_plug_name {
	my ($self,$instance_id,$plug,$num)=@_;
	my $name;
	if(exists($self->{instances}{$instance_id}{plugs}{$plug}{nums}{$num}{name})){
		$name=$self->{instances}{$instance_id}{plugs}{$plug}{nums}{$num}{name};		
	}
	return $name;		
}

sub soc_get_plug_addr {
	my ($self,$instance_id,$plug,$num)=@_;
	my ($addr , $width);
	if(exists($self->{instances}{$instance_id}{plugs}{$plug}{nums}{$num}{addr})){
		$addr=	$self->{instances}{$instance_id}{plugs}{$plug}{nums}{$num}{addr};
		$width=	$self->{instances}{$instance_id}{plugs}{$plug}{nums}{$num}{width};
	}
	return ($addr , $width);	
}


sub soc_get_socket_name {
	my ($self,$instance_id,$socket,$num)=@_;
	my $name;
	if(exists($self->{instances}{$instance_id}{sockets}{$socket}{nums}{$num})){
		$name=$self->{instances}{$instance_id}{sockets}{$socket}{nums}{$num}{name};
	}
	return $name;		
}		

sub soc_remove_instance{
	my ($self,$instance_id)=@_;
	if ( exists( $self->{instances}{$instance_id} )) {
	     delete( $self->{instances}{$instance_id} );
	}
	
	
}	


sub soc_add_socket_to_instance{
	my ($self,$instance_id,$socket,$type,$value,$connection_num)=@_;
	if ( exists( $self->{instances}{$instance_id} )){
		$self->{instances}{$instance_id}{sockets}{$socket}{type}=$type;
		$self->{instances}{$instance_id}{sockets}{$socket}{value}=$value;
		$self->{instances}{$instance_id}{sockets}{$socket}{connection_num}=$connection_num;	
					
	}		
}

sub soc_get_socket_of_instance{
	my ($self,$instance_id,$socket)=@_;
	my ($type,$value,$connection_num);
	if ( exists( $self->{instances}{$instance_id} )){
		$type=$self->{instances}{$instance_id}{sockets}{$socket}{type};
		$value=$self->{instances}{$instance_id}{sockets}{$socket}{value};
		$connection_num=$self->{instances}{$instance_id}{sockets}{$socket}{connection_num};		
	}	
	return ($type,$value,$connection_num);	
}





sub soc_add_plug_to_instance{
	my ($self,$instance_id,$plug,$type,$value,$connection_num)=@_;
	if ( exists( $self->{instances}{$instance_id} )){
		$self->{instances}{$instance_id}{plugs}{$plug}{type}=$type;
		$self->{instances}{$instance_id}{plugs}{$plug}{value}=$value;
		$self->{instances}{$instance_id}{plugs}{$plug}{connection_num}=$connection_num;			
		
	}		
}

sub soc_get_plug_of_instance{
	my ($self,$instance_id,$plug)=@_;
	my ($type,$value,$connection_num);
	if ( exists( $self->{instances}{$instance_id} )){
		$type=$self->{instances}{$instance_id}{plugs}{$plug}{type};
		$value=$self->{instances}{$instance_id}{plugs}{$plug}{value};
		$connection_num=$self->{instances}{$instance_id}{plugs}{$plug}{connection_num};		
	}	
	return ($type,$value,$connection_num);	
}










sub soc_add_instance_plug_conection{
			 
	my ($self,$instance_id,$plug,$plug_num,$id,$socket,$num)=@_;
	if(exists ($self->{instances}{$instance_id}{plugs}{$plug})){
		$self->{instances}{$instance_id}{plugs}{$plug}{nums}{$plug_num}{connect_id}=$id;
		$self->{instances}{$instance_id}{plugs}{$plug}{nums}{$plug_num}{connect_socket}=$socket;
		$self->{instances}{$instance_id}{plugs}{$plug}{nums}{$plug_num}{connect_socket_num}=$num;
	}
		
}

sub soc_get_module_plug_conection{
	my ($self,$instance_id,$plug,$plug_num)=@_;
	my ($id,$socket,$num);
	if(exists($self->{instances}{$instance_id}{plugs}{$plug}{nums}{$plug_num})){
		$id =	$self->{instances}{$instance_id}{plugs}{$plug}{nums}{$plug_num}{connect_id};
		$socket=	$self->{instances}{$instance_id}{plugs}{$plug}{nums}{$plug_num}{connect_socket};
		$num=	$self->{instances}{$instance_id}{plugs}{$plug}{nums}{$plug_num}{connect_socket_num};
	}
	return 	($id,$socket,$num);
}

sub soc_get_all_plugs_of_an_instance{
	my ($self,$instance_id)=@_;
	my @list;
	
	if(exists ($self->{instances}{$instance_id}{plugs})){
		foreach my $p (sort keys %{$self->{instances}{$instance_id}{plugs}}){
		push (@list,$p);
		
		}	
	}
	return @list;
	
}

sub soc_get_all_sockets_of_an_instance{
	my ($self,$instance_id)=@_;
	my @list;
	
	if(exists ($self->{instances}{$instance_id}{sockets})){
		foreach my $p (sort keys %{$self->{instances}{$instance_id}{sockets}}){
		push (@list,$p);
		
		}	
	}
	return @list;
	
}		


##############################################
sub soc_get_modules_plug_connected_to_socket{
	my ($self,$id,$socket,$socket_num)=@_;
	my %plugs;
	my %plug_nums;
	my @instances=soc_get_all_instances($self);
	foreach my $instance_id (@instances){
			my @plugs=soc_get_all_plugs_of_an_instance($self,$instance_id);
			foreach my $plug (@plugs){
				foreach my $plug_num (keys %{$self->{instances}{$instance_id}{plugs}{$plug}{nums}}){
					my $id_ =	$self->{instances}{$instance_id}{plugs}{$plug}{nums}{$plug_num}{connect_id};
					my $socket_=	$self->{instances}{$instance_id}{plugs}{$plug}{nums}{$plug_num}{connect_socket};
					my $socket_num_=	$self->{instances}{$instance_id}{plugs}{$plug}{nums}{$plug_num}{connect_socket_num};
					#print "if($id_ eq $id && $socket_ eq $socket &&  $socket_num_ eq $socket_num )\n";
					if($id_ eq $id && $socket_ eq $socket &&  $socket_num_ eq $socket_num ) {
						$plugs{$instance_id}=$plug;
						$plug_nums{$instance_id}=$plug_num;
						
					}
				}
			}
		
	}	
	
	
	
	return (\%plugs, \%plug_nums);
	
}	













sub get_modules_have_this_socket{
	my ($self,$socket)=@_;
	my %r;
	my @instances=soc_get_all_instances($self);
	if(!defined $socket ){return %r;}
	foreach my $p (@instances)
	{
			if(exists ($self->{instances}{$p}{sockets}{$socket})) {
				$r{$p}=$self->{instances}{$p}{sockets}{$socket}{value};
			
			}
		
	}	
	return %r;
	
}	


	

sub soc_get_all_instances{
	my ($self)=@_;
	my @list;
	foreach my $p (sort keys %{$self->{instances}}){
		push (@list,$p);
	}
	return @list;
}

sub soc_get_all_instances_of_module{
	my ($self,$category,$module)=@_;
	my @list;
	my @m_list;
	@list=soc_get_all_instances($self);
	
	foreach my $p (@list){
		#printf "\$p=$p  \& $self->{instances}{$p}{module}\n";
		if(($self->{instances}{$p}{module} eq $module) &&
		   ($self->{instances}{$p}{category} eq $category)){
			push(@m_list,$p); 		
		}
	}
	return @m_list;
}



sub soc_add_instance_param{
		my ($self,$instance_id,$param_ref)=@_;
		if(exists ($self->{instances}{$instance_id})){
			my %param=%$param_ref;
			foreach my $p (sort keys %param){
				my $value = $param{$p};
				$self->{instances}{$instance_id}{parameters}{$p}{value}=$value;
				#print "lllllllll:$value\n";
			}	
			return 1;
		}
		return 0;
}	


sub soc_add_instance_param_order{
		my ($self,$instance_id,$param_ref)=@_;
		if(exists ($self->{instances}{$instance_id})){
			$self->{instances}{$instance_id}{parameters_order}=$param_ref;
			return 1;
		}
		return 0;
}	

sub soc_get_instance_param_order{
		my ($self,$instance_id)=@_;
		my @r;
		if(defined ($self->{instances}{$instance_id}{parameters_order}) ){
			@r=@{$self->{instances}{$instance_id}{parameters_order}};
			
		}
		return @r;
}	



sub soc_get_module_param{
		my ($self,$instance_id)=@_;
		my %param;
		if(exists ($self->{instances}{$instance_id}{parameters}))
		{
			foreach my $p (sort keys %{$self->{instances}{$instance_id}{parameters}})
			{
				$param{$p}=$self->{instances}{$instance_id}{parameters}{$p}{value};
			}
		}		
		return %param; 
}



sub soc_get_module_param_value{
		my ($self,$instance_id,$param)=@_;
		my $value;
		if(exists ($self->{instances}{$instance_id}{parameters}{$param})){
			$value= $self->{instances}{$instance_id}{parameters}{$param}{value};
		}
		return $value;
}	

	



sub soc_get_all_instance_name{
	my ($self)=@_;
	my @instance_names;
	my @instances=$self->soc_get_all_instances();
	foreach my $instance_id (@instances){
			my $name= $self->{instances}{$instance_id}{instance_name};
			push(@instance_names,$name);
		
	}	
	return @instance_names;	
}


sub soc_set_instance_name{
	my ($self,$instance_id,$instance_name)=@_;
	if ( exists( $self->{instances}{$instance_id} )){
		$self->{instances}{$instance_id}{instance_name}=$instance_name;
	}

}	

sub soc_get_instance_name{
	my ($self,$instance_id)=@_;
	my $instance_name;
	if ( exists( $self->{instances}{$instance_id} )){
		 $instance_name=$self->{instances}{$instance_id}{instance_name};
	}
	return $instance_name;

}	


sub soc_get_instance_id{
	my ($self,$intance_name)=@_;
	foreach my $id (sort keys %{$self->{instances}}){
		my $p=$self->{instances}{$id}{instance_name};
		if ($p eq $intance_name) {return $id;}
		
	}	
	return; 
}	

sub soc_get_module{
	my ($self,$instance_id) = @_;
	my $module;
	if ( exists( $self->{instances}{$instance_id} )){
		$module=$self->{instances}{$instance_id}{module};
	}
	return $module;
}	

sub soc_get_category{
	my ($self,$instance_id) = @_;
	my $category;
	if ( exists( $self->{instances}{$instance_id} )){
		$category=$self->{instances}{$instance_id}{category};
	}
	return $category;
}	

sub soc_add_plug_base_addr{
	my($self,$instance_id,$plug,$num,$base,$end)=@_;
	if(exists ($self->{instances}{$instance_id}{plugs}{$plug}{nums}{$num})){
		$self->{instances}{$instance_id}{plugs}{$plug}{nums}{$num}{base}=$base;
		$self->{instances}{$instance_id}{plugs}{$plug}{nums}{$num}{end}=$end;
	}	
}

	

sub soc_list_base_addreses{
		my ($self,$id) = @_;
		my %bases;
		my @all_instances=soc_get_all_instances($self);
		foreach my $instance_id (@all_instances){
			my @plugs=soc_get_all_plugs_of_an_instance($self,$instance_id);
			foreach my $plug (@plugs){
				foreach my $num (sort keys  %{$self->{instances}{$instance_id}{plugs}{$plug}{nums}}){
					my $base=$self->{instances}{$instance_id}{plugs}{$plug}{nums}{$num}{base};
					my $end=$self->{instances}{$instance_id}{plugs}{$plug}{nums}{$num}{end};
					my $connect_id=$self->{instances}{$instance_id}{plugs}{$plug}{nums}{$num}{connect_id};
					if(defined $base && ($connect_id eq $id)){
						$bases{$end}=$base;
						
					}	
				}	
			}
		}	
		return %bases;
	
}	


sub soc_list_plug_nums{
	my ($self,$instance_id,$plug)=@_;
	my @list;
	if(exists($self->{instances}{$instance_id}{plugs}{$plug})){
		foreach my $num (sort keys  %{$self->{instances}{$instance_id}{plugs}{$plug}{nums}}){
			push (@list,$num);
		}
	}
	return @list;
}

sub soc_list_socket_nums{
	my ($self,$instance_id,$socket)=@_;
	my @list;
	if(exists($self->{instances}{$instance_id}{sockets}{$socket})){
		foreach my $num (sort keys  %{$self->{instances}{$instance_id}{sockets}{$socket}{nums}}){
			push (@list,$num);
		}
	}
	return @list;
}	
	


sub soc_get_plug{
	my ($self,$instance_id,$plug,$num) = @_;
	my ($addr,$base,$end,$name,$connect_id,$connect_socket,$connect_socket_num);
	if(exists($self->{instances}{$instance_id}{plugs}{$plug}{nums}{$num})){
		$addr=				$self->{instances}{$instance_id}{plugs}{$plug}{nums}{$num}{addr};
		$base=				$self->{instances}{$instance_id}{plugs}{$plug}{nums}{$num}{base};
		$end=				$self->{instances}{$instance_id}{plugs}{$plug}{nums}{$num}{end};
		$name=				$self->{instances}{$instance_id}{plugs}{$plug}{nums}{$num}{name};
		$connect_id=		$self->{instances}{$instance_id}{plugs}{$plug}{nums}{$num}{connect_id};
		$connect_socket=	$self->{instances}{$instance_id}{plugs}{$plug}{nums}{$num}{connect_socket};
		$connect_socket_num=$self->{instances}{$instance_id}{plugs}{$plug}{nums}{$num}{connect_socket_num};
					
	}				
	return ($addr,$base,$end,$name,$connect_id,$connect_socket,$connect_socket_num);
	
}	



sub soc_add_top{
	my ($self,$top_ip)=@_;
	$self->{top_ip}=$top_ip;	
	
}

sub soc_get_top{
	my $self=shift;
	return $self->{top_ip};
	
}

sub soc_get_hdl_files{
	my ($self)=shift;
	return @{$self->{hdl_files}};
}


sub soc_add_hdl_files{
	my ($self,@hdl_list)=@_;
	my @old=@{$self->{hdl_files}};
	my @new=(@old,@hdl_list);
	$self->{hdl_files}=\@new;	
}

#a-b
sub soc_get_diff_array{
	my ($a_ref,$b_ref)=@_;
	my @A=@{$a_ref};
	my @B=@{$b_ref};
	my @C;
	foreach my $p (@A){
		if( !grep (/^$p$/,@B)){push(@C,$p)};
	}
	return  @C;	
	
}

sub soc_remove_hdl_files{
	my ($self,@hdl_list)=@_;
	my @old=@{$self->{hdl_files}};
	my @new=soc_get_diff_array(\@old,\@hdl_list);
	$self->{hdl_files}=\@new;	
}



sub new_wires {
		my $class = shift;
		my $self;
		$self->{assigned_name}={};
		bless($self,$class);
		return $self;
}	
sub wire_add{
	my ($self,$name,$filed,$data)=@_;
	$self->{assigned_name}{$name}{$filed}=$data;	
}

sub wire_get{
	my ($self,$name,$filed)=@_;
	return	$self->{assigned_name}{$name}{$filed};	
}

sub wires_list{
	my($self)=shift;
	my @list=	sort keys %{$self->{assigned_name}};
	return @list;
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


sub object_remove_attribute{
	my ($self,$attribute1,$attribute2)=@_;
	if(!defined $attribute2){
		delete $self->{$attribute1} if ( exists( $self->{$attribute1})); 
	}
	else {
		delete $self->{$attribute1}{$attribute2} if ( exists( $self->{$attribute1}{$attribute2})); ;

	}

}


sub board_new {
    # be backwards compatible with non-OO call
    my $class = ("ARRAY" eq ref $_[0]) ? "soc" : shift;
    my $self;
  
    $self->{'Input'}{'*VCC'}{'*VCC'}   =  ['*undefine*']; 
    $self->{'Input'}{'*GND'}{'*GND'}   =  ['*undefine*']; 
    $self->{'Input'}{'*NOCONNECT'}{'*NOCONNECT'}    = ['*undefine*']; 
    $self->{'Output'}{'*NOCONNECT'}{'*NOCONNECT'}   = ['*undefine*']; 
    $self->{'Bidir'}{'*NOCONNECT'}{'*NOCONNECT'}    = ['*undefine*'];   
  
    bless($self,$class);
  
    return $self;
} 



sub board_add_pin {
	my ($self,$direction,$name)=@_;
	my ($intfc,$pin_name,$pin_num);
	my @f= split('_',$name);
	if(!defined $f[1]){ # There is no '_' in pin name
		
		my @p= split(/\[/,$name);
		$intfc=$p[0];
		$pin_name=$p[0];
		if(defined $p[1]){ #it is an array
			my @q= split(/\]/,$p[1]);
			$pin_num=$q[0]; #save pin num
		}else{
			$pin_num='*undefine*';			
		}
	}
	else{ # take the word before '_' as interface
		$intfc=$f[0];
		my @p= split(/\[/,$name);
		$pin_name=$p[0];
		if(defined $p[1]){
			my @q= split(/\]/,$p[1]);
			$pin_num=$q[0];
		}else{
			$pin_num='*undefine*';			
		}
	}
	
	my @a;
	@a=   @{$self->{$direction}{$intfc}{$pin_name}} if(exists $self->{$direction}{$intfc}{$pin_name});
	push (@a,$pin_num);
	@{$self->{$direction}{$intfc}{$pin_name}}=@a;	

}

sub board_get_pin {
	my ($self,$direction)=@_;
	my %p=%{$self->{$direction}};
	return %p;	

}

sub board_get_pin_range {
	my ($self,$direction,$pin_name)=@_;
	my @f= split('_',$pin_name);
	my $intfc = $f[0];
	my $ref =$self->{$direction}{$intfc}{$pin_name};
	my @range;
	@range= @{$ref} if(defined $ref);
	return @range;
}


1
