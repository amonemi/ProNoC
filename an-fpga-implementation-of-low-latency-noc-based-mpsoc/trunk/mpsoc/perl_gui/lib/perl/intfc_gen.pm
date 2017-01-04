#!/usr/bin/perl -w -I ..
###############################################################################
#
# File:         interface.pm
# 
#
###############################################################################
use warnings;
use strict;



package intfc_gen;

sub interface_generator {
		my $class = "intfc_gen";
		my $self;
		$self->{file_name}=();
		$self->{modules}={};
		$self->{module_name}=();
		$self->{type}=();	
		$self->{name}=();
		bless($self,$class);
		return $self;
}	

sub intfc_set_interface_file {
	my ($self,$file)= @_;
	if (defined $file){ 
		#print "file name has been changed to $file\n";
		$self->{file_name}=$file;
		#delete old data
		if(exists ($self->{modules})) {delete $self->{modules}; } ;
		if(exists ($self->{module_name})) {delete $self->{module_name}; } ;
		if(exists ($self->{ports})){ delete $self->{ports}};
		
		
		
		}
}	

sub intfc_get_interface_file {
	my ($self)=@_;
	my $file;
	if (exists ($self->{file_name})){
		$file=$self->{file_name};	
	}
	return $file;	
}	

sub intfc_add_module_list{
		my ($self,@list)=@_;
		$self->{modules}={};
		foreach my $p(@list) {			
			$self->{modules}{$p}={};	
			
		}
	
}	


sub intfc_get_module_list{
		my ($self)=@_;
		my @modules;
		if(exists($self->{modules})){
			@modules=keys %{$self->{modules}};
		}
		return @modules;	
}	

sub intfc_set_module_name{
	my ($self,$module)= @_;	
	$self->{module_name}=$module;
	if(exists ($self->{ports})){ delete $self->{ports}};		
}	

sub intfc_remove_ports{
	my $self=shift;
	if(exists ($self->{ports})){ delete $self->{ports}};
}



sub intfc_get_module_name {
	my ($self)=@_;
	my $module;
	if (exists ($self->{module_name})){
		$module=$self->{module_name};	
	}
	return $module;	
}	


sub intfc_add_port{
	my ($self,$port_id,$type,$range,$name,$connect_type,$connect_range,$connect_name,$outport_type,$default_out)=@_;
	$self->{ports}{$port_id}{name}=$name;
	$self->{ports}{$port_id}{range}=$range;
	$self->{ports}{$port_id}{type}=$type;
	$self->{ports}{$port_id}{connect_name}=$connect_name;	
	$self->{ports}{$port_id}{connect_range}=$connect_range;
	$self->{ports}{$port_id}{connect_type}=$connect_type;	
	$self->{ports}{$port_id}{outport_type}=$outport_type;
	$self->{ports}{$port_id}{default_out}=$default_out;	
}	

sub intfc_get_ports{
	my ($self,$types_ref,$ranges_ref,$names_ref,$connect_types_ref,$connect_ranges_ref,$connect_name_ref,$outport_type_ref,$default_out_ref)=@_;
	if(exists ($self->{ports})){
		foreach my $id (sort keys %{$self->{ports}}){
				$types_ref->{$id}=$self->{ports}{$id}{type};
				$ranges_ref->{$id}=$self->{ports}{$id}{range};
				$names_ref->{$id}=$self->{ports}{$id}{name};
				$connect_types_ref->{$id}=$self->{ports}{$id}{connect_type};
				$connect_ranges_ref->{$id}=$self->{ports}{$id}{connect_range};
				$connect_name_ref->{$id}=$self->{ports}{$id}{connect_name};
				$outport_type_ref->{$id}=$self->{ports}{$id}{outport_type};
				$default_out_ref->{$id}=$self->{ports}{$id}{default_out};
		}
	}
}

sub intfc_ckeck_ports_available{
	my ($self)=@_;
	my $result;
	if(exists ($self->{ports})){$result=1;}
	return $result;
	
}	

sub intfc_remove_port{
		my ($self,$port_id)=@_;
		if(exists ($self->{ports}{$port_id})){
			delete $self->{ports}{$port_id};
		}	
}	


sub intfc_get_ports_type{
	my ($self)=@_;
	my %ports_type;
	if(exists ($self->{ports})){
		foreach my $p (sort keys %{$self->{ports}}){
			$ports_type{$p}= $self->{ports}{$p}{type};
			
		}
	}
	return %ports_type;
}	



sub intfc_set_interface_name{
	my ($self,$name)=@_;
	$self->{name}=$name;
}	

sub intfc_get_interface_name {
	my ($self)=@_;
	my $name;
	if(exists ($self->{name})){
		$name=$self->{name};
	}
	return $name;
}




sub intfc_set_interface_type {
	my ($self,$intfc_type)=@_;
	$self->{type}=$intfc_type;
}


sub intfc_get_interface_type {
	my ($self)=@_;
	my $type;
	if(exists ($self->{type})){
		$type=$self->{type};
	}
	return $type;
}


sub intfc_set_connection_num {
	my ($self,$connection_num)=@_;
	$self->{connection_num}=$connection_num;
}


sub intfc_get_connection_num {
	my ($self)=@_;
	my $connection_num;
	if(exists ($self->{connection_num})){
		$connection_num=$self->{connection_num};
	}
	return $connection_num;
}





sub intfc_set_description{
	my  ($self,$description)=@_;
	$self->{description}=$description;	
}
	


sub intfc_get_description{
my ($self)=@_;
	my $des;
	if(exists ($self->{description})){
		$des=$self->{description};
	}
	return $des;
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
