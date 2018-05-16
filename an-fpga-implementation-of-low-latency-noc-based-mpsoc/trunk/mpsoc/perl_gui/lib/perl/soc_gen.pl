#! /usr/bin/perl -w
use Glib qw/TRUE FALSE/;
use strict;
use warnings;
use soc;
use ip;
use interface;
use POSIX 'strtol';

use File::Path;
#use File::Find;
use File::Copy;
use File::Copy::Recursive qw(dircopy);
use Cwd 'abs_path';


use Gtk2;
use Gtk2::Pango;




# clean names for column numbers.
use constant DISPLAY_COLUMN    => 0;
use constant CATRGORY_COLUMN    => 1;
use constant MODULE_COLUMN     => 2;
use constant ITALIC_COLUMN   => 3;
use constant NUM_COLUMNS     => 4;


require "widget.pl"; 
require "verilog_gen.pl";
require "readme_gen.pl";
require "hdr_file_gen.pl";
require "diagram.pl";
require "compile.pl";
require  "software_editor.pl";

 

sub is_hex {
    local $!;
    return ! (POSIX::strtol($_[0], 16))[1];
 }

###############
#   get_instance_id
# return an instance id which is the module name with a unique number 
#############
sub get_instance_id{
	my ($soc,$category,$module)=@_;
	my @id_list= $soc->soc_get_all_instances_of_module($category,$module);
	my $id=0;
	my $instance_id="$module$id";
	do {
		$instance_id = "$module$id";
		$id++;
   	}while ((grep {$_ eq $instance_id} @id_list) ) ;
	#print "$instance_id\n";
	return ($instance_id,$id);

}



#################
#  add_module_to_soc
###############
sub add_module_to_soc{
	my ($soc,$ip,$category,$module,$info)=@_;
	my ($instance_id,$id)= get_instance_id($soc,$category,$module);
	
	#add module instanance
	my $result=$soc->soc_add_instance($instance_id,$category,$module,$ip);
	
	if($result == 0){
		my $info_text= "Failed to add \"$instance_id\" to SoC. $instance_id is already exist.";	 
		show_info($info,$info_text); 
		return;
	}
	$soc->soc_add_instance_order($instance_id);
	# Add IP version 
	my $v=$ip->ip_get($category,$module,"version"); 
	$v = 0 if(!defined $v);
	#print "$v\n";
	$soc->object_add_attribute($instance_id,"version",$v);
	# Read default parameter from lib and add them to soc
	my %param_default= $ip->get_param_default($category,$module);
	
	my $rr=$soc->soc_add_instance_param($instance_id,\%param_default);
	if($rr == 0){
		my $info_text= "Failed to add defualt parameter to \"$instance_id\".  $instance_id does not exist exist.";	 
		show_info($info,$info_text); 
		return;
	}
	my @r=$ip->ip_get_param_order($category,$module);
	$soc->soc_add_instance_param_order($instance_id,\@r);
	
	get_module_parameter($soc,$ip,$instance_id);
	
	
	
} 
################
#	remove_instance_from_soc
################
sub remove_instance_from_soc{
	my ($soc,$instance_id)=@_;
	$soc->soc_remove_instance($instance_id);
	$soc->soc_remove_from_instance_order($instance_id);
	set_gui_status($soc,"refresh_soc",0);
}	



###############
#   get module_parameter
##############

sub get_module_parameter{
	my ($soc,$ip,$instance_id)=@_;
	
	#read module parameters from lib
	my $module=$soc->soc_get_module($instance_id);
	my $category=$soc->soc_get_category($instance_id);
	my @parameters=$ip->ip_get_param_order($category,$module);
	my $param_num = @parameters;
	
	#read soc parameters
	my %param_value= $soc->soc_get_module_param($instance_id);
	my %new_param_value=%param_value;
	#gui
	my $table_size = ($param_num<10) ? 10 : $param_num;
	my $window =  def_popwin_size(60,60, "Parameter setting for $module ",'percent');
	my $table = def_table($table_size, 7, FALSE);
	
	my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);
	$scrolled_win->set_policy( "automatic", "automatic" );
	$scrolled_win->add_with_viewport($table);
	my $row=0;
	
	my $ok = def_image_button('icons/select.png','OK');
	
	my $at0= 'expand';
	my $at1= 'shrink';
	
	$table->attach (gen_label_in_left("Parameter name"),0, 3, $row, $row+1,$at0,$at1,2,2);
	$table->attach (gen_label_in_left("Value"),3, 6, $row, $row+1,$at0,$at1,2,2);
	$table->attach (gen_label_in_left("Description"),6, 7, $row, $row+1,$at0,$at1,2,2);
	$row++;
	foreach my $p (@parameters){
		my ($default,$type,$content,$info)= $ip->ip_get_parameter($category,$module,$p);
		
		my $value=$param_value{$p};
		#$value = $default if (!defined $value && defined $default);
		#print "$value\n";
		if ($type eq "File_Entry"){
			my $entry=gen_entry($value);
			my $brows=get_file_name(undef,undef,$entry,undef,undef,undef,undef,undef);
			my $box=def_hbox(TRUE,0);
			$box->pack_start($entry,FALSE,FALSE,3);
			$box->pack_start($brows,FALSE,FALSE,3);
			$table->attach ($box, 3, 6, $row, $row+1,$at0,$at1,2,2);
			$entry-> signal_connect("changed" => sub{$new_param_value{$p}=$entry->get_text();});
		}
		
		elsif ($type eq "Entry"){
			my $entry=gen_entry($value);
			$table->attach ($entry, 3, 6, $row, $row+1,$at0,$at1,2,2);
			$entry-> signal_connect("changed" => sub{$new_param_value{$p}=$entry->get_text();});
		}
		elsif ($type eq "Combo-box"){
			my @combo_list=split(",",$content);
			my $pos=get_item_pos($value, @combo_list);
			my $combo=gen_combo(\@combo_list, $pos);
			$table->attach ($combo, 3, 6, $row, $row+1,$at0,$at1,2,2);
			$combo-> signal_connect("changed" => sub{$new_param_value{$p}=$combo->get_active_text();});
			
		}
		elsif 	($type eq "Spin-button"){ 
		  my ($min,$max,$step)=split(",",$content);
		  $value=~ s/\D//g;
		  $min=~ s/\D//g;
		  $max=~ s/\D//g;
		  $step=~ s/\D//g;
		  my $spin=gen_spin($min,$max,$step);
		  if(defined $value) {$spin->set_value($value);}
		  else {$spin->set_value($min);}
		  $table->attach ($spin, 3, 4, $row, $row+1,$at0,$at1,2,2);
		  $spin-> signal_connect("value_changed" => sub{ $new_param_value{$p}=$spin->get_value_as_int(); });
		 
		 # $box=def_label_spin_help_box ($param,$info, $value,$min,$max,$step, 2);
		}
		if (defined $info && $type ne "Fixed"){
			my $info_button=def_image_button('icons/help.png');
			$table->attach ($info_button, 6, 7, $row, $row+1,$at0,$at1,2,2);	
			$info_button->signal_connect('clicked'=>sub{
				message_dialog($info);
				
			});
			
		}		
		if ($type ne "Fixed"){
			#print "$p:val:$value\n";
			my $label =gen_label_in_left($p);
			$table->attach ($label, 0, 3, $row, $row+1,$at0,$at1,2,2);
			$row++;
		}		 
		
		
	}
	#if ($row== 0){
			#my $label =gen_label_in_left("The $module IP does not have any adjatable parameter");
		#	$table->attach ($label, 0, 7, $row, $row+1,$at0,'shrink',2,2);

	#}
	
	
	
	my $mtable = def_table(10, 1, FALSE);

	$mtable->attach_defaults($scrolled_win,0,1,0,9);
	$mtable->attach($ok,0,1,9,10,'expand','fill',2,2);
	
	$window->add ($mtable);
	$window->show_all();
	
	$ok-> signal_connect("clicked" => sub{ 
		$window->destroy;
		#save new values 
		$soc->soc_add_instance_param($instance_id,\%new_param_value);
		
		
		#check if wishbone address bus is parameterizable regenerate the addresses again 
		my @plugs= $soc->soc_get_all_plugs_of_an_instance($instance_id);
		foreach my $plug (@plugs){
			if ($plug eq 'wb_slave'){
				my @nums=$soc->soc_list_plug_nums($instance_id,$plug);
				foreach my $plug_num (@nums){					
					my ($addr_connect,$base,$end,$name,$connect_id,$connect_socket,$connect_socket_num)=$soc->soc_get_plug($instance_id,$plug,$plug_num);
					if($connect_id ne 'IO' && $connect_id ne 'NC'){
						#print "$connect_id : soc_get_plug_addr ($instance_id,$plug,$plug_num)\n";
						#remove old wb addr
						$soc->soc_add_plug_base_addr($instance_id,$plug,$plug_num,undef,undef);
						#get base and address width
						my ($addr , $width)=$soc->soc_get_plug_addr ($instance_id,$plug,$plug_num);
						#check if width is a parameter
						my $val= get_parameter_final_value($soc,$instance_id,$width);
						$width= $val if(defined $val);
						#allocate new address in $connect_id
						my ($base,$end)=get_wb_address($soc,$connect_id,$addr,$width);
						if(defined $base){#save it
							$soc->soc_add_plug_base_addr($instance_id,$plug,$plug_num,$base,$end);
						}
					}
				}#plug_num
			}#if
		}#plugs
		
		
		set_gui_status($soc,"refresh_soc",0);
		#$$refresh_soc->clicked;
		
		});


}



############
#  param_box
#
############
sub get_item_pos{#if not in return 0
		my ($item,@list)=@_;
		my $pos=0;
		foreach my $p (@list){
				#print "$p eq $item\n";
				if ($p eq $item){return $pos;}
				$pos++;
		}	
		return 0;
	
}	

 sub param_box{
	 my ($param, $default,$type,$content,$info, $value)=@_;
	 my $box=def_hbox(TRUE,0);
	 my $label =gen_label_in_left($param);
	 $box->pack_start($label,FALSE,FALSE,3);
	 
	 if ($type eq "Entry"){
		my $entry=gen_entry($default);
		$box->pack_start($entry,FALSE,FALSE,3);
		
	 }
	 elsif ($type eq "Combo-box"){
		 my @combo_list=split(",",$content);
		 my $pos=get_item_pos($default, @combo_list);
		 my $combo=gen_combo(\@combo_list, $pos);
		 $box->pack_start($combo,FALSE,FALSE,3);
	 }
	 elsif 	($type eq "Spin-button"){ 
		  my ($min,$max,$step)=split(",",$content);
		  $default=~ s/\D//g;
		  $min=~ s/\D//g;
		  $max=~ s/\D//g;
		  $step=~ s/\D//g;
		  my $spin=gen_spin($min,$max,$step);
		  $box->pack_start($spin,FALSE,FALSE,3);
		 # $box=def_label_spin_help_box ($param,$info, $value,$min,$max,$step, 2);
	 }	 
	
	 return $box;
}


###############
#  get_mathced_socket_pos
###############


sub  get_mathced_socket_pos{
	my ($soc,$instance_id,$plug,$plug_num,@connettions)=@_;	
	my ($id,$socket,$num)=$soc->soc_get_module_plug_conection($instance_id,$plug,$plug_num);
	my $pos=($id eq "IO")? 0: (scalar @connettions)-1;	
	if($id ne "IO" && $id ne 'NC'){
		my $name= $soc->soc_get_instance_name($id);
		if (defined $name){
			my $connect="$name\:$socket\[$num]"; 
			if( grep {$_ eq $connect} @connettions){$pos = get_scolar_pos($connect,@connettions);}
		}
		else {
			$soc->soc_add_instance_plug_conection($instance_id,$plug,$plug_num,"IO");
			
		}
	}
	return $pos;	
}


##############
#	gen_dev_box
##############

sub gen_instance{
	#my ($soc,$ip,$infc,$instance_id,$info)=@_;
	my ($soc,$ip,$infc,$instance_id,$info,$table,$offset)=@_;
	
	
	
#	my $box= def_vbox (FALSE,0);
	
#	my $table = def_table(3,5,TRUE);
	my $data_in;
	
#column 1	
	#module name
	my $module=$soc->soc_get_module($instance_id);
	my $category=$soc->soc_get_category($instance_id);
	my $module_name_label=box_label(FALSE,0,$module);
	my $box0=def_hbox(FALSE,5);
	$box0->pack_start( $module_name_label, FALSE, FALSE, 3);

	#module pdf
	my $pdf=$soc->soc_get_description_pdf($instance_id);
	if(defined $pdf){
		my $b=def_image_button('icons/evince-icon.png');
		$box0->pack_start( $b, FALSE, FALSE, 3);
		$b->signal_connect ("clicked"  => sub{
			my $dir = Cwd::getcwd();
			my $project_dir	  = abs_path("$dir/../../"); #mpsoc directory address
			#print "path ${project_dir}$pdf\n";
			if (-f "${project_dir}$pdf"){
				system qq (xdg-open ${project_dir}$pdf);
			}elsif (-f "$pdf"){
				system qq (xdg-open $pdf);
			}else{
				message_dialog("Error! $pdf or ${project_dir}$pdf did not find!\n");	
			}

		});

	}
	$table->attach  ($box0,0,1,$offset+0,$offset+1,'expand','shrink',2,2);

	#parameter setting button
	my $param_button = def_image_button('icons/setting.png','Setting');
	my $box1=def_hbox(FALSE,5);
	my $up=def_image_button("icons/up_sim.png");
	$box1->pack_start( $up, FALSE, FALSE, 3);
	$box1->pack_start($param_button,   FALSE, FALSE,3);
	$table->attach  ($box1 ,0,1,$offset+1,$offset+2,'expand','shrink',2,2);
	$param_button->signal_connect (clicked => sub{
		get_module_parameter($soc,$ip,$instance_id);	
		
	});
	$up->signal_connect (clicked => sub{
		$soc->soc_decrease_instance_order($instance_id);
		set_gui_status($soc,"refresh_soc",0);
		
	});
	
	#remove button
	#my ($box2,$cancel_button) = button_box("Remove");
	my $cancel_button=def_image_button('icons/cancel.png','Remove');
	my $box2=def_hbox(FALSE,5);
	
	my $dwn=def_image_button("icons/down_sim.png");
	$box2->pack_start( $dwn, FALSE, FALSE, 3);
	$box2->pack_start($cancel_button,   FALSE, FALSE,3);
	$table->attach  ($box2,0,1,$offset+2,$offset+3,'expand','shrink',2,2); 
	$cancel_button->signal_connect (clicked => sub{
		remove_instance_from_soc($soc,$instance_id);
				
	});	
	$dwn->signal_connect (clicked => sub{
		$soc->soc_increase_instance_order($instance_id);
		set_gui_status($soc,"refresh_soc",0);
		
	});

	
	
	#instance name
	my $instance_name=$soc->soc_get_instance_name($instance_id);
	my $instance_label=gen_label_in_left(" Instance name");
	my $instance_entry = gen_entry($instance_name);
	   
	
	
	$table->attach  ($instance_label,1,2,$offset+0,$offset+1,'expand','shrink',2,2);
	#$table->attach_defaults ($instance_entry,1,2,$offset+1,$offset+2);


	my $enter= def_image_button("icons/enter.png");
	
	my $box=def_pack_hbox(FALSE,0,$instance_entry );
	$table->attach  ($box,1,2,$offset+1,$offset+2,'expand','shrink',2,2);

	my ($old_v,$new_v)=  get_old_new_ip_version ($soc,$ip,$instance_id);
	if($old_v != $new_v){
		my $warn=def_image_button("icons/warnning.png");
		$table->attach  ($warn,1,2,$offset+2,$offset+3,'expand','shrink',2,2);  #$box2->pack_start($warn, FALSE, FALSE, 3);  
		$warn->signal_connect (clicked => sub{
			message_dialog("Warning: ${module}'s version (V.$old_v) missmatches with the one exsiting in librray (V.$new_v). The generated system may not work correctly.  Please remove and then add $module again to update it with current version")
				
		});	


	}
	

	$instance_entry->signal_connect ("activate"  => sub{
		#print "changed\n";
		my $new_name=$instance_entry->get_text();
		#check if instance name exist in soc
		set_gui_status($soc,"refresh_soc",1) if($instance_name eq $new_name );
		my @instance_names= $soc->soc_get_all_instance_name();
		if( grep {$_ eq $new_name} @instance_names){
			print "$new_name exist\n";
		}
		else {
		#add instance name to soc
			$soc->soc_set_instance_name($instance_id,$new_name);
		
			set_gui_status($soc,"refresh_soc",1);
				
		}	
	});
	my $change=0;
	$instance_entry->signal_connect ("changed"  => sub{
		if($change ==0){		
			$box->pack_start( $enter, FALSE, FALSE, 0);
			$box->show_all;
			$change=1;
		}

	});
	
	$enter->signal_connect ("clicked"  => sub{
		my $new_name=$instance_entry->get_text();
		#check if instance name exist in soc
		set_gui_status($soc,"refresh_soc",1) if($instance_name eq $new_name );
		my @instance_names= $soc->soc_get_all_instance_name();
		if( grep {$_ eq $new_name} @instance_names){
			print "$new_name exist\n";
		}
		else {
		#add instance name to soc
			$soc->soc_set_instance_name($instance_id,$new_name);
		
			set_gui_status($soc,"refresh_soc",1);
				
		}	


	});


	
	#interface_pluges
	my %plugs = $ip->get_module_plugs_value($category,$module);
			
	my $row=0;
	foreach my $plug (sort keys %plugs) {
		
		my $plug_num= $plugs{$plug};
		for (my $k=0;$k<$plug_num;$k++){
			
			my @connettions=("IO");
			my @connettions_name=("IO");
			
			my ($connection_num,$matched_soket)= $infc->get_plug($plug);
					
			
			
			my %connect_list= $soc->get_modules_have_this_socket($matched_soket);
			foreach my $id(sort keys %connect_list ){
				if($instance_id ne $id){ # assum its forbidden to connect the socket and plug of same ip to each other
					#generate soket list
					my $name=$soc->soc_get_instance_name($id);
					#check if its a number or parameter
					my $param=$connect_list{$id};
					my $value=$soc->soc_get_module_param_value($id,$param);
					my $array_name=0;
					if ( !length( $value || '' )) {
						$value=$param;
						$array_name=1;					
						
						
					};
					for(my $i=0; $i<$value; $i++){
						my $s= "$name\:$matched_soket\[$i]";
						push (@connettions,$s);
						
						# show sockets with their connected plugs 
						my ($type_t,$value_t,$connection_num_t)=$soc->soc_get_socket_of_instance($id,$matched_soket);
							
						my $cc=find_connection($soc,$id,$matched_soket,$i);
						$cc= (!defined $cc )? '': 
							 ($cc eq "$instance_id:$plug\[$k\]" || $connection_num_t eq 'multi connection')? '':  "->$cc";

						if($array_name eq 0){
							my $n= $soc->soc_get_socket_name($id,$matched_soket, 0);
							
							$n = (!defined $n)? $s:"$name\:$n\[$i]"; 
							$n = "$n$cc";
							push (@connettions_name,"$n");
							
						}else{
							my $n= $soc->soc_get_socket_name($id,$matched_soket, $i);
							
							$n = (!defined $n)? $s:"$name\:$n"; 
							$n = "$n$cc";
							push (@connettions_name,"$n");
							
						}					
						
					}
					
				}	
				
			
			}
			push (@connettions,"NC");
			push (@connettions_name,"NC");
				
			#print "connection is $connect for $p\n";
			#my @socket_list= $soc_get_sockets();
			
			
			my $pos= get_mathced_socket_pos($soc,$instance_id,$plug,$k,@connettions);
			
			#plug name
			my $plug_name=	$soc->soc_get_plug_name($instance_id,$plug,$k);
			if(! defined $plug_name ){$plug_name=($plug_num>1)?"$plug\[$k\]":$plug}
			$plug_name="  $plug_name  ";
			my($plug_box, $plug_combo)= def_h_labeled_combo_scaled($plug_name,\@connettions_name,$pos,1,2);
			
			#if($row>2){$table->resize ($row, 2);}
			$table->attach ($plug_box,2,5,$row+$offset,$row+$offset+1,'fill','fill',2,2);	$row++;
			
			my $plug_num=$k;
			my @ll=($soc,$instance_id,$plug,$info,$plug_num);
			$plug_combo->signal_connect (changed => sub{
				my $self=shift;
				my $ref= shift;
				my($soc,$instance_id,$plug,$info,$plug_num) = @{$ref};
				my $connect_name=$plug_combo->get_active_text();
				my $pos=get_item_pos($connect_name, @connettions_name);
				my $connect=$connettions[$pos];
				
				
				
				my($intance_name,$socket,$num)= split("[:\[ \\]]", $connect);
				my $id=$intance_name;# default IO or NC
				if(($intance_name ne 'IO') && ($intance_name ne 'NC')){
					
					$id=$soc->soc_get_instance_id($intance_name);
					my ($type,$value,$connection_num)=$soc->soc_get_socket_of_instance($id,$socket);
					#print "\$$connection_num=$connection_num\n";
					if($connection_num eq 'single connection'){# disconnect other plug from this soket
						my ($ref1,$ref2)= $soc->soc_get_modules_plug_connected_to_socket($id,$socket,$num);
						my %connected_plugs=%$ref1;
						my %connected_plug_nums=%$ref2;
						foreach my $p (sort keys %connected_plugs) {
							#%pp{$instance_id}=$plug
							$soc->soc_add_instance_plug_conection($p,$connected_plugs{$p},$connected_plug_nums{$p},'IO');
							my $info_text="$id\:$socket\[$num\] support only single connection.  The previouse connection to $p:$connected_plugs{$p}\[$connected_plug_nums{$p}] has been removed.";
							show_info(\$info, $info_text);
						}
						
					}
				}
				#print "$id \n $connect \n$num\n";
				#my @rr=$soc->soc_get_all_plugs_of_an_instance($id);
				
				
			
				
				$soc->soc_add_instance_plug_conection($instance_id,$plug,$plug_num,$id,$socket,$num);
				
				#get address for wishbone slave port
				if ($plug eq 'wb_slave'){
						#remove old wb addr
						$soc->soc_add_plug_base_addr($instance_id,$plug,$plug_num,undef,undef);
						
						#get base and address width
						my ($addr , $width)=$soc->soc_get_plug_addr ($instance_id,$plug,$plug_num);
						
						#check if width is a parameter
						my $val= get_parameter_final_value($soc,$instance_id,$width);
						#print "my $val= get_parameter_final_value($soc,$instance_id,$width);\n";
						$width= $val if(defined $val);
						
							
						#allocate new address in $id
						my ($base,$end)=get_wb_address($soc,$id,$addr,$width);
						if(defined $base){#save it
							#print "($base,$end)\n";
							$soc->soc_add_plug_base_addr($instance_id,$plug,$plug_num,$base,$end);
						}
						
						
						#$id
				}	
				# "$name\:$connect\[$i]";
				
			
			
				set_gui_status($soc,"refresh_soc",0);
			},\@ll);
			
	
	}#for $plug_num
		
	}#foreach plug

				
	
	
	
	
	
	
	#$box->pack_start($table, FALSE, FALSE, 0);
	my $separator = Gtk2::HSeparator->new;
	#$box->pack_start($separator, FALSE, FALSE, 3);
	if($row<3) {$row=3;}
	$table->attach ($separator,0,5,$row+$offset,$row+$offset+1,'fill','fill',2,2);	$row++;
	return ($offset+$row);
}	


sub find_connection{
	my ($soc,$id,$socket,$num)=@_;
	my ($ref1,$ref2)= $soc->soc_get_modules_plug_connected_to_socket($id,$socket,$num);
	my %connected_plugs=%$ref1;
	my %connected_plug_nums=%$ref2;
	my $c;
	foreach my $p (sort keys %connected_plugs) {
				$c="$p:$connected_plugs{$p}\[$connected_plug_nums{$p}]" ;
				#print "($instance_id,$plug,$plug_num);($p:$connected_plugs{$p}\[$connected_plug_nums{$p})\n";
	}
	return $c;

}



###############
#	generate_dev_table
############
sub generate_dev_table{
	my($soc,$ip,$infc,$info)=@_;	
	#my $box= def_hbox (TRUE,0);
  
	my $table=def_table(3,25,FALSE);
	my $row=0;
	my @instance_list=$soc->soc_get_instance_order();
	if (scalar @instance_list ==0 ){
		@instance_list=$soc->soc_get_all_instances();
	}
	my $i=0;
	
	foreach my $instanc(@instance_list){
		$row=gen_instance($soc,$ip,$infc,$instanc,$info,$table,$row);
		
	}
	if($row<20){for ($i=$row; $i<20; $i++){
		
		#my $temp=gen_label_in_center(" ");
		#$table->attach_defaults ($temp, 0, 1 , $i, $i+1);
	}}	
	
	
	#$box->pack_start( $scrolled_win, TRUE, TRUE, 3);
	return $table;
}	
	 
	 
####################
#  show_active_dev
#
################ 

sub show_active_dev{
	my($soc,$ip,$infc,$refresh_ref,$info)=@_;
	my $box= def_table (1, 1, FALSE);
	my $dev_table = generate_dev_table($soc,$ip,$infc,$info);
	my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);
	$scrolled_win->set_policy( "automatic", "automatic" );
	$scrolled_win->add_with_viewport($dev_table);
	


	$$refresh_ref-> signal_connect("clicked" => sub{ 
	   	
		$dev_table->destroy;
		select(undef, undef, undef, 0.1); #wait 10 ms
		$dev_table = generate_dev_table($soc,$ip,$infc,$info);
		#$box->attach_defaults ($dev_table, 0, 1, 0, 1);#( $dev_table, FALSE, FALSE, 3);
		$scrolled_win->add_with_viewport($dev_table);
		$dev_table->show;
		$scrolled_win->show_all;
		
		
		
	});
	#$box->attach_defaults ($dev_table, 0, 1, 0, 1);#$box->pack_start( $dev_table, FALSE, FALSE, 3);
	#$box->show_all;
	return $scrolled_win;
	
	
	
}	





sub row_activated_cb{
	 my ($tree_view, $path, $column) = @_;
	 my $model = $tree_view->get_model;
	 my $iter = $model->get_iter ($path);

	#my ($selection, $ref) = @_;
	#my ($model,$textview)=@{$ref};
	#my $iter = $selection->get_selected;
  	#return unless defined $iter;
	my ($category) = $model->get ($iter, DISPLAY_COLUMN);
  	my ($module) = $model->get ($iter, CATRGORY_COLUMN);

	

	#if($module){print "$module   is selected via row activaton!\n"}
}




##############
#	create tree
##############
sub create_tree {
   my ($info,$ip,$soc)=@_;
   my $model = Gtk2::TreeStore->new ('Glib::String', 'Glib::String', 'Glib::Scalar', 'Glib::Boolean');
   my $tree_view = Gtk2::TreeView->new;
   $tree_view->set_model ($model);
   my $selection = $tree_view->get_selection;

   $selection->set_mode ('browse');
   #$tree_view->set_size_request (200, -1);

   #
   # this code only supports 1 level of children. If we
   # want more we probably have to use a recursing function.
   #
   

   my @categories= $ip->ip_get_categories();
 



   foreach my $p (@categories)
   {
	my @modules= $ip->get_modules($p);
	#my @dev_entry=  @{$tree_entry{$p}}; 	
	my $iter = $model->append (undef);
	$model->set ($iter,
                   DISPLAY_COLUMN,    $p,
                   CATRGORY_COLUMN, $p || '',
                   MODULE_COLUMN,     0     || '',
                   ITALIC_COLUMN,   FALSE);

	next unless  @modules;
	
	foreach my $v ( @modules){
		 my $child_iter = $model->append ($iter);
		 my $entry= '';
		
         	$model->set ($child_iter,
			DISPLAY_COLUMN,    $v,
                   	CATRGORY_COLUMN, $p|| '',
                   	MODULE_COLUMN,     $v     || '',
                   	ITALIC_COLUMN,   FALSE);
      	}	
	


   }
	
   my $cell = Gtk2::CellRendererText->new;
   $cell->set ('style' => 'italic');
   my $column = Gtk2::TreeViewColumn->new_with_attributes
 					("IP list",
                                        $cell,
                                        'text' => DISPLAY_COLUMN,
                                        'style_set' => ITALIC_COLUMN);

  $tree_view->append_column ($column);
  my @ll=($model,\$info);
#row selected
  $selection->signal_connect (changed =>sub {
	my ($selection, $ref) = @_;
	my ($model,$info)=@{$ref};
	my $iter = $selection->get_selected;
  	return unless defined $iter;

  	my ($category) = $model->get ($iter, CATRGORY_COLUMN);
  	my ($module) = $model->get ($iter,MODULE_COLUMN );
  	my $describ=$ip->ip_get($category,$module,"description");
	if($describ){
		#print "$entry describtion is: $describ \n";
		show_info($info,$describ);
		
	}


}, \@ll);

#  row_activated 
  $tree_view->signal_connect (row_activated => sub{

         my ($tree_view, $path, $column) = @_;
	 my $model = $tree_view->get_model;
	 my $iter = $model->get_iter ($path);
        my ($category) = $model->get ($iter, CATRGORY_COLUMN);
  	my ($module) = $model->get ($iter,MODULE_COLUMN );

	

	if($module){ 
		#print "$module  is selected via row activaton!\n";
		add_module_to_soc($soc,$ip,$category,$module,\$info);
		set_gui_status($soc,"refresh_soc",0);	
	}
		


	
	



}, \@ll);

  #$tree_view->expand_all;

  my $scrolled_window = Gtk2::ScrolledWindow->new;
  $scrolled_window->set_policy ('automatic', 'automatic');
  $scrolled_window->set_shadow_type ('in');
  $scrolled_window->add($tree_view);

  my $hbox = Gtk2::HBox->new (FALSE, 0);
  $hbox->pack_start ( $scrolled_window, TRUE, TRUE, 0);

  

  return $hbox;
}



sub get_all_files_list {
	my ($soc,$list_name)=@_;
	my @instances=$soc->soc_get_all_instances();
	my $ip = ip->lib_new ();
	my @files;
	my $dir = Cwd::getcwd();
	my $warnings;
	#make target dir
	my $project_dir	  = abs_path("$dir/../..");
	
	foreach my $id (@instances){
		my $module 		=$soc->soc_get_module($id);
		my $module_name	=$soc->soc_get_module_name($id);
		my $category 	=$soc->soc_get_category($id);
		my $inst   		=$soc->soc_get_instance_name($id);
			
		my @new=$ip->ip_get_list( $category,$module,$list_name);
		#print "@new\n";
		foreach my $f(@new){
    			my $n="$project_dir$f";
    			 if (!(-f "$n") && !(-f "$f" ) && !(-d "$n") && !(-d "$f" )     ){
    			 	$warnings=(defined $warnings)? "$warnings WARNING: Can not find  \"$f\" which is required for \"$inst\" \n":"WARNING: Can not find  \"$f\"  which is required for \"$inst\"\n ";   
    			 	
    			 }
    			
    		
    		}
		
		
		
		
		@files=(@files,@new);
	}
	return \@files,$warnings;
}

################
#	generate_soc
#################

sub generate_soc{
	my ($soc,$info,$target_dir,$hw_path,$sw_path,$gen_top,$gen_hw_lib)=@_;
		my $name=$soc->object_get_attribute('soc_name');
	
		
		my ($file_v,$top_v,$readme,$prog)=soc_generate_verilog($soc,$sw_path);
			
		# Write object file
		open(FILE,  ">lib/soc/$name.SOC") || die "Can not open: $!";
		print FILE perl_file_header("$name.SOC");
		print FILE Data::Dumper->Dump([\%$soc],['soc']);
		close(FILE) || die "Error closing file: $!";
			
		# Write verilog file
		my $h=autogen_warning().get_license_header("${name}.v")."\n`timescale 1ns / 1ps\n";
		open(FILE,  ">lib/verilog/$name.v") || die "Can not open: $!";
		print FILE $h.$file_v;
		close(FILE) || die "Error closing file: $!";
			
		# Write Top module file
		if($gen_top){
			my $l=autogen_warning().get_license_header("${name}_top.v")."\n`timescale 1ns / 1ps\n";
			open(FILE,  ">lib/verilog/${name}_top.v") || die "Can not open: $!";
			print FILE "$l\n$top_v";
			close(FILE) || die "Error closing file: $!";
		}
			
		# Write readme file
		open(FILE,  ">lib/verilog/README") || die "Can not open: $!";
		print FILE $readme;
		close(FILE) || die "Error closing file: $!";


		# Write memory prog file
		open(FILE,  ">lib/verilog/write_memory.sh") || die "Can not open: $!";
		print FILE $prog;
		close(FILE) || die "Error closing file: $!";

		#generate prog_mem
    		open(FILE,  ">lib/verilog/program.sh") || die "Can not open: $!";
		print FILE soc_mem_prog();
		close(FILE) || die "Error closing file: $!";


		
		my $dir = Cwd::getcwd();
		my $project_dir	  = abs_path("$dir/../../"); 		
		if($gen_hw_lib){

			#make target dir
			my $hw_lib="$hw_path/lib";
			mkpath("$hw_lib/",1,01777);
			mkpath("$sw_path/",1,01777);
   		
			#copy hdl codes in src_verilog   
			
			my ($file_ref,$warnings)= get_all_files_list($soc,"hdl_files");
		
			copy_file_and_folders($file_ref,$project_dir,$hw_lib);
			show_info(\$info,$warnings)     		if(defined $warnings);  
    		
    		
			#copy jtag control files 
			my @jtags=(("/mpsoc/src_peripheral/jtag/jtag_wb"),("jtag"));
			copy_file_and_folders(\@jtags,$project_dir,$hw_lib);    		
			move ("$dir/lib/verilog/$name.v","$hw_path/"); 
			move ("$dir/lib/verilog/${name}_top.v","$hw_path/"); 		
			move ("$dir/lib/verilog/README" ,"$sw_path/");
			move ("$dir/lib/verilog/write_memory.sh" ,"$sw_path/");
			move ("$dir/lib/verilog/program.sh" ,"$sw_path/");
		}
		
		# Copy Software files
		my ($file_ref,$warnings)= get_all_files_list($soc,"sw_files");
		copy_file_and_folders($file_ref,$project_dir,$sw_path);
    		
		# Write system.h and Software gen files
		generate_header_file($soc,$project_dir,$sw_path,$hw_path,$dir);
			 
    		
    			


		# Write main.c file if not exist
		my $n="$sw_path/main.c";
		if (!(-f "$n")) { 
			# Write main.c
			open(FILE,  ">$n") || die "Can not open: $!";
			print FILE main_c_template($name);
			close(FILE) || die "Error closing file: $!";
			
		}
			
			
			
			
			

}	


sub main_c_template{
	my $hdr=shift;
	my $text="
#include \"$hdr.h\"


// a simple delay function
void delay ( unsigned int num ){
	
	while (num>0){ 
		num--;
		nop(); // asm volatile (\"nop\");
	}
	return;

}

int main(){
	while(1){
		
	

	}

return 0;
}

";

return $text;


}




sub get_wb_address	{
	my ($soc,$instance_id,$addr,$width)=@_;
	my ($base,$end);
	my @list= split (" ",$addr);
	$base= hex ($list[0]);
	$end= $base+(1 << $width)-1;
	#print "$addr:$base \& $end\n";
	my %taken_bases= $soc->soc_list_base_addreses($instance_id);
	
	my $conflict=0;
	do{
		$conflict=0;
		foreach my $taken_end (sort {$a<=>$b} keys %taken_bases){
			my $taken_base=$taken_bases{$taken_end};
			#print "taken:($taken_base,$taken_end)\n";
			if (($base <= $taken_base && $end >= $taken_base ) || ($base <= $taken_end && $end >= $taken_end )){
			#if (!(($base < $taken_base && $end < $taken_end ) || ($base > $taken_base && $end > $taken_end ))){
				 $conflict=1;
				 $base=$taken_end+1;
				 $end= $base+(1 << $width)-1;				 
				 last;
				 
			}
		}	
		
	}while($conflict==1 && $end<(1 << 32));
	if($conflict==0){
		#print"new ($base,$end);\n";
		return ($base,$end);
		
	}	
	
	return ;

}	









##########
#	wb address setting
#########

sub wb_address_setting {
	my $soc=shift;
		
	
	my $window = def_popwin_size(80,50,"Wishbone slave port address setting",'percent');
	my $table = def_table(10, 6, FALSE);
	
	my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);
	$scrolled_win->set_policy( "automatic", "automatic" );
	$scrolled_win->add_with_viewport($table);
	my $row=0;
	
	#title
	$table->attach(gen_label_in_left  ("Instance name"),0,1,$row,$row+1,'expand','shrink',2,2);
	$table->attach(gen_label_in_left  ("Interface name"),1,2,$row,$row+1,'expand','shrink',2,2);
	$table->attach(gen_label_in_left  ("Bus name"),2,3,$row,$row+1,'expand','shrink',2,2);
	$table->attach(gen_label_in_center("Base address"),3,4,$row,$row+1,'expand','shrink',2,2);
	$table->attach(gen_label_in_center("End address"),4,5,$row,$row+1,'expand','shrink',2,2);
	$table->attach(gen_label_in_center("Size (Bytes)"),5,6,$row,$row+1,'expand','shrink',2,2);
	
	my (@newbase,@newend,@connects);
	
	$row++;
	my @all_instances=$soc->soc_get_all_instances();
	foreach my $instance_id (@all_instances){
		my @plugs= $soc->soc_get_all_plugs_of_an_instance($instance_id);
		foreach my $plug (@plugs){
			my @nums=$soc->soc_list_plug_nums($instance_id,$plug);
			foreach my $num (@nums){
				my ($addr,$base,$end,$name,$connect_id,$connect_socket,$connect_socket_num)=$soc->soc_get_plug($instance_id,$plug,$num);
				if((defined $connect_socket) && ($connect_socket eq 'wb_slave')){
					my $number=$row-1;
					$newbase[$number]=$base;
					$newend[$number]=$end;
					$connects[$number]=$connect_id;	
					$row++;	
				}#if
			}#foreach my $num
		}#foreach my $plug
	}#foreach my $instance_id

	my @status_all;
	$row=1;
	foreach my $instance_id (@all_instances){
		my @plugs= $soc->soc_get_all_plugs_of_an_instance($instance_id);
		foreach my $plug (@plugs){
			my @nums=$soc->soc_list_plug_nums($instance_id,$plug);
			foreach my $num (@nums){
				my ($addr,$base,$end,$name,$connect_id,$connect_socket,$connect_socket_num)=$soc->soc_get_plug($instance_id,$plug,$num);
				if((defined $connect_socket) && ($connect_socket eq 'wb_slave')){
					my $instance_name=$soc->soc_get_instance_name($instance_id);
					my $plug_name=(defined $name ) ? gen_label_in_left($name):
													 gen_label_in_left("$plug\[$num\]");
							
					my $connected_instance_name= $soc->soc_get_instance_name($connect_id);
					my $number=$row-1;
					my $label1= gen_label_in_left("$number: $instance_name");
					my $label2= gen_label_in_left($connected_instance_name);
					my $entry1= Gtk2::Entry->new_with_max_length (10);
				    $entry1->set_text(sprintf("0x%08x", $base));
						
					my $entry2= Gtk2::Entry->new_with_max_length (10);
					$entry2->set_text(sprintf("0x%08x", $end));
												
					my ($box,$valid) =addr_box_gen(sprintf("0x%08x", $base), sprintf("0x%08x", $end),\@newbase,\@newend,\@connects,$number);
					$status_all[$number]=$valid;
							
							
					$table->attach($label1,0,1,$row,$row+1,'expand','shrink',2,2);
					$table->attach($plug_name,1,2,$row,$row+1,'expand','shrink',2,2);
					$table->attach($label2,2,3,$row,$row+1,'expand','shrink',2,2);
					$table->attach($entry1,3,4,$row,$row+1,'expand','shrink',2,2);
					$table->attach($entry2,4,5,$row,$row+1,'expand','shrink',2,2);
							
							
					$table->attach($box,5,7,$row,$row+1,'expand','shrink',2,2);
							
							
					$entry1->signal_connect('changed'=>sub{
						my $base_in=$entry1->get_text();
						if (length($base_in)<2){ $entry1->set_text('0x')};
						my $end_in=$entry2->get_text();
						my $valid;
						$box->destroy;
						($box,$valid)=addr_box_gen($base_in, $end_in,\@newbase,\@newend,\@connects,$number);
						$status_all[$number]=$valid;
						$table->attach($box,5,7,$number+1,$number+2,'expand','shrink',2,2);
						$table->show_all;
						
								
					} );
					$entry2->signal_connect('changed'=>sub{
						my $base_in=$entry1->get_text();
						my $end_in=$entry2->get_text();
						if (length($end_in)<2){ $entry2->set_text('0x')};
						my $valid;
						$box->destroy;
						($box,$valid)=addr_box_gen($base_in, $end_in,\@newbase,\@newend,\@connects,$number);
						$status_all[$number]=$valid;
						$table->attach($box,5,7,$number+1,$number+2,'expand','shrink',2,2);	
						$table->show_all;				
					} );
														
							
							
					$row++;		
							
						
				}#if
			}#foreach my $num
		}#foreach my $plug
	}#foreach my $instance_id
		
	
	my $ok = def_image_button('icons/select.png','OK');
	
	
	
	my $refresh = def_image_button('icons/revert.png','Revert');
	my $refbox=def_hbox(TRUE,0);
	$refbox->pack_start($refresh, FALSE, FALSE,0);
			
	$refresh->signal_connect( 'clicked'=> sub {
		$window->destroy;
		wb_address_setting($soc);
		
		
		});
	$ok->signal_connect	( 'clicked'=> sub {
		my $st=1;
		foreach my $valid (@status_all){ 
			if($valid==0){
				$st=0;
				
			} 
		}
		
		if($st==1){
			$row=1;
			foreach my $instance_id (@all_instances){
			my @plugs= $soc->soc_get_all_plugs_of_an_instance($instance_id);
			foreach my $plug (@plugs){
				my @nums=$soc->soc_list_plug_nums($instance_id,$plug);
				foreach my $num (@nums){
					my ($addr,$base,$end,$name,$connect_id,$connect_socket,$connect_socket_num)=$soc->soc_get_plug($instance_id,$plug,$num);
					if(defined $connect_socket && ($connect_socket eq 'wb_slave')){
						my $number=$row-1;
						$soc->soc_add_plug_base_addr($instance_id,$plug,$num,$newbase[$number],$newend[$number]);
						$row++;
					}#if
				}#foreach my $num
			}#foreach my $plug
		}#foreach my $instance_id
			
			
			
			
			
			$window->destroy;
		}else{
			message_dialog("Invalid address !");
			
		}	
		
		
		});
		
		
	
	
	$table->attach ($refbox,2,3,$row,$row+1,'expand','shrink',2,2);
	$table->attach ($ok,3,4,$row,$row+1,'expand','shrink',2,2);
	
	$window->add($scrolled_win);
	$window->show_all;
	
	
	
}	
##############
#	addr_box_gen
##############

sub addr_box_gen{
	my ($base_in, $end_in,$newbase_ref,$newend_ref,$connects_ref,$number)=@_;
	my $box= def_hbox(TRUE,0);
	my $label;
	my $valid=1;
	my $info;
	if(is_hex($base_in) && is_hex($end_in)){
		my $size=(hex ($end_in) >= hex ($base_in))? hex ($end_in) - hex ($base_in) +1 : 0;
		my $size_text=	metric_conversion($size);
		$label= gen_label_in_center($size_text);
		$$newbase_ref[$number]=hex($base_in);
		$$newend_ref[$number]=hex($end_in);
		$info=check_entered_address($newbase_ref,$newend_ref,$connects_ref,$number);
		if(defined 	$info) {$valid=0;}
		
	}
	else {
		$label= gen_label_in_center("Invalid hex value!");
		$info="Invalid hex value!";
		$valid=0;
	}
	
	
	my $status=(defined $info)? gen_button_message ($info,'icons/warnning.png'):
								gen_button_message (undef,'icons/select.png');
							
	$box->pack_start($label,FALSE,FALSE,3);
	$box->pack_start($status,FALSE,FALSE,3);
	return ($box,$valid);
	
}	




###########
#	get_parameter_final_value
############
sub get_parameter_final_value{
	my ($soc,$id,$param)=@_;
	#get ordered param
	my @ordered_param=$soc->soc_get_instance_param_order($id);
	my %sim_params;
	foreach my $p (@ordered_param){
		my $value=$soc->soc_get_module_param_value($id,$p);
		foreach my $q (sort keys %sim_params){
			$value=replace_value($value,$q,$sim_params{$q}) if (defined $value);
		}
		$sim_params{$p}=$value;
		#print "$sim_params{$p}=$value;\n";
	}
	return $sim_params{$param};
}	
	
	
	
	
sub replace_value{
	my ($string,$param,$value)=@_;

	my $new_string=$string;
	#print "$new_range\n";
	my $new_param= $value;
	($new_string=$new_string)=~ s/\b$param\b/$new_param/g;
	return eval $new_string;

		
}	













sub check_entered_address{
my 	($base_ref,$end_ref,$connect_ref,$number)=@_;
my @bases=@{$base_ref};
my @ends=@{$end_ref};
my @connects=@{$connect_ref};

my $current_base=$bases[$number];
my $current_end=$ends[$number];

if($current_base>  $current_end) {
		
return "Error: the given base address is bigger than the End address!";	
	}

my $size= scalar @bases; 
my $conflicts;
foreach (my $i=0; $i<$size; $i++){
	if($i != $number){ #if not same row
		if	($connects[$i] eq $connects[$number]) {#same bus
				my $ok=(($bases[$i]< $bases[$number] && $bases[$i] < $ends[$number])||($bases[$i]> $bases[$number] && $bases[$i] > $ends[$number]));
			    if($ok==0) {
					$conflicts=(defined $conflicts )? "$conflicts,$i": $i;
				}
		}	
	
	
	}
	
	
}	
if (defined $conflicts){ return " The given address range has conflict with rows:$conflicts"; }
return;
	
	
}	

#############
#	load_soc
#############

sub load_soc{
	my ($soc,$info,$ip)=@_;
	my $file;
	my $dialog = Gtk2::FileChooserDialog->new(
            	'Select a File', undef,
            	'open',
            	'gtk-cancel' => 'cancel',
            	'gtk-ok'     => 'ok',
        	);

	my $filter = Gtk2::FileFilter->new();
	$filter->set_name("SoC");
	$filter->add_pattern("*.SOC");
	$dialog->add_filter ($filter);
	my $dir = Cwd::getcwd();
	$dialog->set_current_folder ("$dir/lib/soc")	;		


	if ( "ok" eq $dialog->run ) {
		$file = $dialog->get_filename;
		my ($name,$path,$suffix) = fileparse("$file",qr"\..[^.]*$");
		if($suffix eq '.SOC'){
			my $pp= eval { do $file };
			if ($@ || !defined $pp){		
				show_info(\$info,"**Error reading  $file file: $@\n");
				 $dialog->destroy;
				return;
			} 
			clone_obj($soc,$pp);
			check_instances_version($soc,$ip);
			set_gui_status($soc,"load_file",0);		
		}					
     }
     $dialog->destroy;

   

	

}


sub check_instances_version{
	my ($soc,$ip)=@_;

 #check if the IP's version didnt increases 
    my @all_instances=$soc->soc_get_all_instances();
    foreach my $instance_id (@all_instances){
	my ($old_v,$new_v)=  get_old_new_ip_version ($soc,$ip,$instance_id);
	my $differences='';
	$differences="$differences \t The $instance_id version (V.$old_v) missmatches with the one exsiting in the library (V.$new_v).\n " if($old_v != $new_v);
		
	
	message_dialog("Warning: The generated system may not work correctly: \n $differences Please remove and then add the aforementioned instance(s) to update them with current version(s)") if(length($differences)>1);

    }


}

sub get_old_new_ip_version{
	my ($soc,$ip,$instance_id)=@_;
	my $old_v=$soc->object_get_attribute($instance_id,"version",undef);
	$old_v=0 if(!defined $old_v);
	my $module=$soc->soc_get_module($instance_id);
	my $category=$soc->soc_get_category($instance_id);
	my $new_v=$ip->ip_get($category,$module,"version");
	$new_v=0 if(!defined $new_v);
	return ($old_v,$new_v);
}

sub check_for_ni{
	my $self=shift;
	my $ckeck=0;
	my @instances=$self->soc_get_all_instances();
	foreach my $id (@instances){
		my $category = $self->soc_get_category($id);
		if ($category eq 'NoC') {
		$ckeck=1;
		}
	}
	return $ckeck;

}


sub get_ram_init{
	my $soc=shift;
	my $window = def_popwin_size(80,50,"Memory initial file setting setting",'percent');
	my $table = def_table(10, 6, FALSE);
	
	my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);
	$scrolled_win->set_policy( "automatic", "automatic" );
	$scrolled_win->add_with_viewport($table);
	my $row=0;
	my $col=0;
	my @instances=$soc->soc_get_all_instances();
	foreach my $id (@instances){
		my $category = $soc->soc_get_category($id);
		if ($category eq 'RAM') {
			my $ram_name=  $soc->soc_get_instance_name($id);
			$table->attach (gen_label_in_left("$ram_name"),$col,$col+1, $row, $row+1,'fill','shrink',2,2);$col++;
			my $init_type=gen_combobox_object ($soc,'RAM_INIT','type',"Dont_Care,Fill_0,Fill_1,Search_in_sw,Fixed_file","Search_in_sw",undef);
			my $init_inf= "Define how the memory must be initialized :
 Dont_Care: The memory wont be initialized
 Fill_0: All memory bits will fill with value zero
 Fill_1: All memory bits will fill with value one
 Search_in_sw: Each instance of this processing core 
               use different initial file that is 
               located in its SW folder. 
 Fixed_file: All instance of this processing core 
             use the same initial file";
			
			$row++;
		}
	}
	
	
	$window->add($scrolled_win);
	$window->show_all;
}


sub software_edit_soc {
	my $soc=shift;	
	my $name=$soc->object_get_attribute('soc_name');
	if (length($name)==0){
		message_dialog("Please define the Tile name!");
		return ;
	}
	my $target_dir  = "$ENV{'PRONOC_WORK'}/SOC/$name";
	my $sw 	= "$target_dir/sw";
	my ($app,$table,$tview) = software_main($sw);

	


	my $make = def_image_button('icons/gen.png','Compile');
	my $regen= def_image_button('icons/refresh.png','Regenerate main.c');
	my $prog= def_image_button('icons/write.png','Program the memory');

	$table->attach ($regen,0, 1, 1,2,'shrink','shrink',0,0);	
	$table->attach ($make,5, 6, 1,2,'shrink','shrink',0,0);
	$table->attach ($prog,9, 10, 1,2,'shrink','shrink',0,0); 
	$regen -> signal_connect ("clicked" => sub{
		my $dialog = Gtk2::MessageDialog->new (my $window,
                                      'destroy-with-parent',
                                      'question', # message type
                                      'yes-no', # which set of buttons?
                                      "Are you sure you want to regenaret the main.c file? Note that any changes you have made will be lost");
  		my $response = $dialog->run;
  		if ($response eq 'yes') {
      			
			save_file ("$sw/main.c",main_c_template($name));
			$app->load_source("$sw/main.c");	
  		}		
		$dialog->destroy;

	});

	$make -> signal_connect("clicked" => sub{
		$app->do_save();
		run_make_file($sw,$tview);	

	});

	#Programe the board 
	$prog-> signal_connect("clicked" => sub{ 
		my $error = 0;
		my $bash_file="$target_dir/sw/program.sh";

		add_info(\$tview,"Programe the board using quartus_pgm and $bash_file file\n");
		#check if the programming file exists
		unless (-f $bash_file) {
			add_colored_info(\$tview,"\tThe $bash_file does not exists! \n", 'red');
			$error=1;
		}
		
		return if($error);
		my $command = "cd $target_dir/sw; sh program.sh";
		add_info(\$tview,"$command\n");
		my ($stdout,$exit,$stderr)=run_cmd_in_back_ground_get_stdout($command);
		if(length $stderr>1){			
			add_colored_info(\$tview,"$stderr\n",'red');
			add_colored_info(\$tview,"Memory was not programed successfully!\n",'red');
		}else {

			if($exit){
				add_colored_info(\$tview,"$stdout\n",'red');
				add_colored_info(\$tview,"Memory was not programed successfully!\n",'red');
			}else{
				add_info(\$tview,"$stdout\n");
				add_colored_info(\$tview,"Memory is programed successfully!\n",'blue');

			}
			
		}		
	});

}


sub soc_mem_prog {
	 my $string='
#!/bin/sh


#JTAG_INTFC="$PRONOC_WORK/toolchain/bin/JTAG_INTFC"
source ./jtag_intfc.sh

#reset and disable cpus, then release the reset but keep the cpus disabled

$JTAG_INTFC -n 127  -d  "I:1,D:2:3,D:2:2,I:0"

# jtag instruction 
#	0: bypass
#	1: getting data
# jtag data :
# 	bit 0 is reset 
#	bit 1 is disable
# I:1  set jtag_enable  in active mode
# D:2:3 load jtag_enable data register with 0x3 reset=1 disable=1
# D:2:2 load jtag_enable data register with 0x2 reset=0 disable=1
# I:0  set jtag_enable  in bypass mode



#programe the memory

	sh write_memory.sh 

 
#Enable the cpu
$JTAG_INTFC -n 127  -d  "I:1,D:2:0,I:0"
# I:1  set jtag_enable  in active mode
# D:2:0 load jtag_enable data register with 0x0 reset=0 disable=0
# I:0  set jtag_enable  in bypass mode
';
return $string;
	
}




############
#    main
############
sub socgen_main{
	 
	my $infc = interface->interface_new(); 
	my $ip = ip->lib_new ();
	my $soc = soc->soc_new();
	set_gui_status($soc,"ideal",0);
	
	#my $soc= eval { do 'lib/soc/soc.SOC' };
	#message_dialog("$ENV{'PRONOC_WORK'}\n");
	
	# main window
	#my $window = def_win_size(1000,800,"Top");
	#  The main table containg the lib tree, selected modules and info section 
	my $main_table = Gtk2::Table->new (20, 12, FALSE);
	
	# The box which holds the info, warning, error ...  mesages
	my ($infobox,$info)= create_text();	
	
	
	my $refresh_dev_win = Gtk2::Button->new_from_stock('ref');
	
	# A tree view for holding a library
	my $tree_box = create_tree ($info,$ip,$soc);



	$main_table->set_row_spacings (4);
	$main_table->set_col_spacings (1);
	
	my  $device_win=show_active_dev($soc,$ip,$infc,\$refresh_dev_win,$info);
	
	
	my $generate = def_image_button('icons/gen.png','Generate RTL');
	my $compile  = def_image_button('icons/gate.png','Compile RTL');
	my $software = def_image_button('icons/binary.png','Software');
	my $diagram  = def_image_button('icons/diagram.png','Diagram');
	my $ram      = def_image_button('icons/RAM.png','Memory');
	




	
	my $wb = def_image_button('icons/setting.png','Wishbone-bus addr');
	
	
	
	my $open = def_image_button('icons/browse.png','Load Tile');
	
	
	my $entry=gen_entry_object($soc,'soc_name',undef,undef,undef,undef);
	my $entrybox=labele_widget_info(" Tile name:",$entry);
	
	
	#$table->attach_defaults ($event_box, $col, $col+1, $row, $row+1);




	#$main_table->attach_defaults ($tree_box , 0, 2, 0, 17);
	#$main_table->attach_defaults ($device_win , 2, 12, 0, 17);
	#$main_table->attach_defaults ($infobox  , 0, 12, 17,19);


	my $h1=gen_hpaned($tree_box,.15,$device_win);
	my $v2=gen_vpaned($h1,.55,$infobox);
	$main_table->attach_defaults ($v2  , 0, 12, 0,19);




	
	$main_table->attach ($open,0, 2, 19,20,'expand','shrink',2,2);
	$main_table->attach_defaults ($entrybox,2, 4, 19,20);
	$main_table->attach ($wb, 4,6, 19,20,'expand','shrink',2,2);
	$main_table->attach ($diagram, 6, 7, 19,20,'expand','shrink',2,2);
	$main_table->attach ($generate, 7, 8, 19,20,'expand','shrink',2,2);
	$main_table->attach ($software, 8, 9, 19,20,'expand','shrink',2,2);
	#$main_table->attach ($ram, 9, 10, 19,20,'expand','shrink',2,2);
	$main_table->attach ($compile, 10, 12, 19,20,'expand','shrink',2,2);
	

	$diagram-> signal_connect("clicked" => sub{ 
		show_tile_diagram ($soc);
	});
	
		
	$generate-> signal_connect("clicked" => sub{ 
		my $name=$soc->object_get_attribute('soc_name');
		
		if (length($name)==0){
			message_dialog("Please define the Tile name!");
			return ;
		}	
			
		
		my @tmp=split('_',$name);
		if ( $tmp[-1] =~ /^[0-9]+$/ ){
			message_dialog("The soc name must not end with '_number'!");
			return ;
		}
		my $error = check_verilog_identifier_syntax($name);
		if ( defined $error ){
			message_dialog("The \"$name\" is given with an unacceptable formatting. This name will be used as top level verilog module name so it must follow Verilog identifier declaration formatting:\n $error");
			return ;
		}

		my $target_dir  = "$ENV{'PRONOC_WORK'}/SOC/$name";
		my $hw_dir 	= "$target_dir/src_verilog";
		my $sw_path 	= "$target_dir/sw";
    		
		$soc->object_add_attribute('global_param','CORE_ID',0);	
		generate_soc($soc,$info,$target_dir,$hw_dir,$sw_path,1,1);
		#message_dialog("SoC \"$name\" has been created successfully at $target_dir/ " );
		my $has_ni= check_for_ni($soc);
		if($has_ni){
			my $dialog = Gtk2::MessageDialog->new (my $window,
		                              'destroy-with-parent',
		                              'question', # message type
		                              'yes-no', # which set of buttons?
		                              "Processing Tile  \"$name\" has been created successfully at $target_dir/.  In order to include this tile in MPSoC Generator you need to restar the ProNoC. Do you ant to reset the ProNoC now?");
	  		my $response = $dialog->run;
	  		if ($response eq 'yes') {
	      			exec($^X, $0, @ARGV);# reset ProNoC to apply changes	
	  		}
	  		$dialog->destroy;
		} else {
			message_dialog("Processing Tile  \"$name\" has been created successfully at $target_dir/.");

		}
	



	});

	$software -> signal_connect("clicked" => sub{
		software_edit_soc($soc);

	});

	$ram-> signal_connect("clicked" => sub{
		get_ram_init($soc);

	});

	
	$compile -> signal_connect("clicked" => sub{ 
		$soc->object_add_attribute('compile','compilers',"QuartusII,Verilator,Modelsim");
		my $name=$soc->object_get_attribute('soc_name');
		if (length($name)==0){
			message_dialog("Please define the Tile name!");
			return ;
		}
		my $target_dir  = "$ENV{'PRONOC_WORK'}/SOC/$name";
		my $hw_dir 	= "$target_dir/src_verilog";
		my $sw_path 	= "$target_dir/sw";
		my $top 	= "$target_dir/src_verilog/${name}_top.v";
		if (-f $top){
			generate_soc($soc,$info,$target_dir,$hw_dir,$sw_path,1,1);	
			select_compiler($soc,$name,$top,$target_dir);
		} else {
			message_dialog("Cannot find $top file. Please run RTL Generator first!");
			return;
		}
	});

	$wb-> signal_connect("clicked" => sub{ 
		wb_address_setting($soc);
	
	});

	$open-> signal_connect("clicked" => sub{ 
		load_soc($soc,$info,$ip);
	
	});	

	my $sc_win = new Gtk2::ScrolledWindow (undef, undef);
		$sc_win->set_policy( "automatic", "automatic" );
		$sc_win->add_with_viewport($main_table);



	#check soc status every 0.5 second. referesh device table if there is any changes 
	Glib::Timeout->add (100, sub{ 
	 	my ($state,$timeout)= get_gui_status($soc);
		
		if ($timeout>0){
			$timeout--;
			set_gui_status($soc,$state,$timeout);
				
		}elsif ($state eq 'save_project'){
			# Write object file
			my $name=$soc->object_get_attribute('soc_name',undef);
			open(FILE,  ">lib/soc/$name.SOC") || die "Can not open: $!";
			print FILE perl_file_header("$name.SOC");
			print FILE Data::Dumper->Dump([\%$soc],['soc']);
			close(FILE) || die "Error closing file: $!";
			set_gui_status($soc,"ideal",0);	
		}
		elsif( $state ne "ideal" ){
			$refresh_dev_win->clicked;
			my $saved_name=$soc->object_get_attribute('soc_name',undef);
			if(defined $saved_name) {$entry->set_text($saved_name);}
			set_gui_status($soc,"ideal",0);			
		}	
		return TRUE;
		
	} );

	

	return $sc_win;
	#return $main_table;
	

}






