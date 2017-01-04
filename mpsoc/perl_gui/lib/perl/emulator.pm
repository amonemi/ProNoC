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
    emulator_initial_setting($self);
	

    bless($self,$class);

   
    return $self;
} 

sub emulator_initial_setting{
	my $self=shift;
	$self->{status}="ideal";
	$self->{graph_scale}=5;
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
	return @{$self->{parameters_order}{$attribute}};
}




1
