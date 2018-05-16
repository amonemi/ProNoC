#!/usr/bin/perl -w -I ..
###############################################################################
#
# File:         emulator.pm
# 
#
###############################################################################
use warnings;
use strict;



package emulator;



sub emulator_new {
    # be backwards compatible with non-OO call
    my $class = ("ARRAY" eq ref $_[0]) ? "mpsoc" : shift;
    my $self;

   
    $self = {};
    $self->{file_name}        = (); # information on each file
    $self->{samples} = ();
    emulator_initial_setting($self);
	

    bless($self,$class);

   
    return $self;
} 

sub emulator_initial_setting{
	my $self=shift;
	$self->{status}="ideal";
	$self->{setting}{show_noc_setting}=1;
	$self->{setting}{show_adv_setting}=0;
	$self->{setting}{show_tile_setting}=0;	
	$self->{setting}{soc_path}="lib/soc";
	
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
	my @array;
	@array =  @{$self->{parameters_order}{$attribute}} if (defined $self->{parameters_order}{$attribute});
	return @array;
}


sub object_delete_attribute_order{
	my ($self,$attribute,@param)=@_;
	my @array=object_get_attribute_order($self,$attribute);
	foreach my $p (@param){
		@array=remove_scolar_from_array(\@array,$p);

	}
	$self->{'parameters_order'}{$attribute}=[];
	object_add_attribute_order($self,$attribute,@array);
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
	
sub remove_scolar_from_array{
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



1
