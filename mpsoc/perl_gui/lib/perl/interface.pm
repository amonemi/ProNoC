#!/usr/bin/perl -w -I ..
###############################################################################
#
# File:         interface.pm
# 
#
###############################################################################
use warnings;
use strict;
use intfc_gen;
use Data::Dumper;

use Cwd;
  


package interface;





sub interface_new {
    # be backwards compatible with non-OO call
    my $class = ("ARRAY" eq ref $_[0]) ? "interface" : shift;
    my $self;

   
    $self = {};
    $self->{plugs}        = {}; 
    $self->{sockets}      = {}; 
    $self->{categories}   = {}; 
    
    
	my $dir = Cwd::getcwd();
	$dir =~ s/ /\\ /g;
	my @files = glob "$dir/lib/interface/*.ITC";
	for my $p (@files){
		#print "$p\n"; 
		#my $infc_gen = Storable::retrieve($p);
	# Read
	my  $infc_gen;
	$infc_gen = eval { do $p };
 	# Might need "no strict;" before and "use strict;" after "do"
	die "Error reading: $@" if $@;
	
	add_intfc($self,$infc_gen);
	}
	

    bless($self,$class);

   
    return $self;
} 


sub add_category{
	my ($self,$category,$intfc_name,$info)=@_;
	$self->{categories}{$category}{names}{$intfc_name}{info}=$info; 
	
}	

sub get_description{
	my ($self,$category,$name)=@_;
	my $info;
	if(exists ($self->{categories}{$category}{names}{$name})){
		$info= $self->{categories}{$category}{names}{$name}{info};
	}	
	return $info;	
}	


sub add_plug{
		my($self,$plug,$info,$category,$connection_num,$connect_to)=@_; 
		$self->{plugs}{$plug}={};	
		$self->{plugs}{$plug}{connection_num}=$connection_num;
		$self->{plugs}{$plug}{connect_to}=$connect_to;
		$self->{plugs}{$plug}{info}=$info;
		$self->{plugs}{$plug}{category}=$category;
}

sub get_plug{
		my($self,$plug)=@_; 
		my ($connection_num,$connect_to,$info,$category);
		if(exists ($self->{plugs}{$plug})){
			$connection_num	=$self->{plugs}{$plug}{connection_num};
			$connect_to		=$self->{plugs}{$plug}{connect_to};
			$info			=$self->{plugs}{$plug}{info};
			$category		=$self->{plugs}{$plug}{category};
			
		}
		return ($connection_num,$connect_to,$info,$category);
}	



sub add_socket{
		my($self,$socket,$info,$category,$connection_num,$connect_to)=@_; 
		$self->{sockets}{$socket}={};	
		$self->{sockets}{$socket}{connection_num}=$connection_num;
		$self->{sockets}{$socket}{connect_to}=$connect_to;
		$self->{sockets}{$socket}{info}=$info;
		$self->{sockets}{$socket}{category}=$category;
}	
	
	
sub get_socket{
		my($self,$socket)=@_; 
		my ($connection_num,$connect_to,$info,$category);
		if(exists ($self->{sockets}{$socket})){
			$connection_num	=$self->{sockets}{$socket}{connection_num};
			$connect_to		=$self->{sockets}{$socket}{connect_to};
			$info			=$self->{sockets}{$socket}{info};
			$category		=$self->{sockets}{$socket}{category}=$category;
		}
		return ($connection_num,$connect_to,$info,$category);
}		
	

sub add_param_to_plug{
		my($self,$interface,$param,$value)=@_;
		$self->{plugs}{$interface}{parameters}{$param}=$value;		
	
}


sub add_param_to_socket{
		my($self,$interface,$param,$value)=@_;
		$self->{sockets}{$interface}{parameters}{$param}=$value;		
	
}		



sub add_port_to_plug{
	my($self,$interface,$port,$range,$type,$outport_type,$connect,$default_out)=@_;
	$self->{plugs}{$interface}{ports}{$port}={};
	$self->{plugs}{$interface}{ports}{$port}{range}=$range;
	$self->{plugs}{$interface}{ports}{$port}{type}=$type;
	$self->{plugs}{$interface}{ports}{$port}{outport_type}=$outport_type;
	$self->{plugs}{$interface}{ports}{$port}{connect}=$connect;
	$self->{plugs}{$interface}{ports}{$port}{default_out}=$default_out;
	
}


sub get_port_info_of_socket{
	my($self,$socket,$port)=@_;
	my($range,$type,$connect,$default_out);
	if(exists ($self->{sockets}{$socket}{ports}{$port})){
		$range=$self->{sockets}{$socket}{ports}{$port}{range};
		$type=$self->{sockets}{$socket}{ports}{$port}{type};
		$connect=$self->{sockets}{$socket}{ports}{$port}{connect};
		$default_out=$self->{sockets}{$socket}{ports}{$port}{default_out};
	}
	return ($range,$type,$connect,$default_out);
}

sub get_port_info_of_plug{
	my($self,$plug,$port)=@_;
	my($range,$type,$connect,$default_out);
	if(exists ($self->{plugs}{$plug}{ports}{$port})){
		$range=$self->{plugs}{$plug}{ports}{$port}{range};
		$type=$self->{plugs}{$plug}{ports}{$port}{type};
		$connect=$self->{plugs}{$plug}{ports}{$port}{connect};
		$default_out=$self->{plugs}{$plug}{ports}{$port}{default_out};

	}
	return ($range,$type,$connect,$default_out);
}


sub add_port_to_socket{
	my($self,$socket,$port,$range,$type,$outport_type,$connect,$default_out)=@_;
	$self->{sockets}{$socket}{ports}{$port}={};
	$self->{sockets}{$socket}{ports}{$port}{range}=$range;
	$self->{sockets}{$socket}{ports}{$port}{type}=$type;
	$self->{sockets}{$socket}{ports}{$port}{outport_type}=$outport_type;
	$self->{sockets}{$socket}{ports}{$port}{connect}=$connect;
	$self->{sockets}{$socket}{ports}{$port}{default_out}=$default_out;
	
}


sub get_socket_port_list{
	my($self,$socket)=@_;
	my @ports;
	if(exists ($self->{sockets}{$socket}{ports})){
		foreach my $p(keys %{$self->{sockets}{$socket}{ports}}){
			push (@ports,$p);
		}
	}
	return @ports;		
}

sub get_plug_port_list{
	my($self,$plug)=@_;
	my @ports;
	if(exists ($self->{plugs}{$plug}{ports})){
		foreach my $p(keys %{$self->{plugs}{$plug}{ports}}){
			push (@ports,$p);
		}
	}
	return @ports;		
}



sub get_interfaces{
	my $self=shift;
	my @interfaces;
	if(exists ($self->{plugs})){
		foreach my $p (sort keys %{$self->{plugs}}){
			push (@interfaces,$p);
		}	
	}
	return @interfaces;
	
	
}	

sub get_categories{
	my $self=shift;
	my @categories;
	if(exists ($self->{categories})){
		foreach my $p (sort keys %{$self->{categories}}){
			push (@categories,$p);
		}	
	}
	return @categories;	
	
}	
	
sub get_intfcs_of_category{
	my ($self,$category)=@_;
	my @list;
	if(exists ($self->{categories}{$category}{names})){
		foreach my $p (sort keys %{$self->{categories}{$category}{names}}){
			push (@list,$p);
		}
		
	}
	return @list;
}	


sub add_intfc{

	my ($self,$infc_gen) =@_;
	
	my $intfc_name=$infc_gen->object_get_attribute('name');
	my $connection_num=$infc_gen->object_get_attribute('connection_num');
	my $intfc_type=$infc_gen->object_get_attribute('type');
	my $intfc_info=$infc_gen->object_get_attribute('description');
	my $intfc_category=$infc_gen->object_get_attribute('category');
	
	
	my(%types,%ranges,%names,%connect_types,%connect_ranges,%connect_names,%outport_types,%default_outs);
	
	
	add_socket($self,$intfc_name,$intfc_info,$intfc_category,$connection_num,$intfc_name);
	add_plug($self,$intfc_name,$intfc_info,$intfc_category,$connection_num,$intfc_name);
	
	add_category($self,$intfc_category,$intfc_name,$intfc_info);
	
	
	$infc_gen->intfc_get_ports(\%types,\%ranges,\%names,\%connect_types,\%connect_ranges,\%connect_names,\%outport_types,\%default_outs);	
	foreach my $id (sort keys %ranges){
			my $type=$types{$id};
			my $range=$ranges{$id};
			my $name=$names{$id};
			my $connect_type=$connect_types{$id};
			my $connect_range=$connect_ranges{$id};
			my $connect_name=$connect_names{$id};
			my $outport_type=$outport_types{$id};
			my $default_out=$default_outs{$id};
			if($intfc_type eq 'plug'){
				
				 #my($self,$interface,$port,$range,$type,$outport_type)
				add_port_to_plug	($self,$intfc_name,$name,$range,$type,$outport_type,$connect_name,$default_out);
				#print "add_port_to_plug(\$self,$intfc_name,$name,$range,$type,,$outport_type);\n";
				add_port_to_socket	($self,$intfc_name,$connect_name,$connect_range,$connect_type,$outport_type,$name,$default_out);
				#print "add_port_to_socket(\$self,$connect_name,$connect_range,$connect_type);\n";
			}	
			else{
				add_port_to_socket($self,$intfc_name,$name,$range,$type,$outport_type,$connect_name,$default_out);
				add_port_to_plug($self,$intfc_name,$connect_name,$connect_range,$connect_type,$outport_type,$name,$default_out);
			}	
	}		
	
}	










1
