#! /usr/bin/perl -w
use Glib qw/TRUE FALSE/;
use strict;
use warnings;
use soc;
use ip;
use interface;
use POSIX 'strtol';

use File::Path;
use File::Find;
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

require "hdr_file_gen.pl";



 

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
	my ($soc,$ip,$category,$module,$info,$soc_state)=@_;
	my ($instance_id,$id)= get_instance_id($soc,$category,$module);
	
	#add module instanance
	my $result=$soc->soc_add_instance($instance_id,$category,$module,$ip);
	
	if($result == 0){
		my $info_text= "Failed to add \"$instance_id\" to SoC. $instance_id is already exist.";	 
		show_info($info,$info_text); 
		return;
	}
	$soc->soc_add_instance_order($instance_id);
	
	# Read deafult parameter from lib and add them to soc
	my %param_default= $ip->get_param_default($category,$module);
	
	my $rr=$soc->soc_add_instance_param($instance_id,\%param_default);
	if($rr == 0){
		my $info_text= "Failed to add deafualt parameter to \"$instance_id\".  $instance_id does not exist exist.";	 
		show_info($info,$info_text); 
		return;
	}
	my @r=$ip->ip_get_param_order($category,$module);
	$soc->soc_add_instance_param_order($instance_id,\@r);
	
	get_module_parameter($soc,$ip,$instance_id,$soc_state);
	
	
	
} 
################
#	remove_instance_from_soc
################
sub remove_instance_from_soc{
	my ($soc,$instance_id,$soc_state)=@_;
	$soc->soc_remove_instance($instance_id);
	$soc->soc_remove_from_instance_order($instance_id);
	set_state($soc_state,"refresh_soc",0);
}	



###############
#   get module_parameter
##############

sub get_module_parameter{
	my ($soc,$ip,$instance_id,$soc_state)=@_;
	
	#read module parameters from lib
	my $module=$soc->soc_get_module($instance_id);
	my $category=$soc->soc_get_category($instance_id);
	my @parameters=$ip->ip_get_module_parameters($category,$module);
	my $param_num = @parameters;
	
	#read soc parameters
	my %param_value= $soc->soc_get_module_param($instance_id);
	my %new_param_value=%param_value;
	#gui
	my $table_size = ($param_num<10) ? 10 : $param_num;
	my $window = def_popwin_size(600,400,"Parameter setting for $module ");
	my $table = def_table($table_size, 7, TRUE);
	
	my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);
	$scrolled_win->set_policy( "automatic", "automatic" );
	$scrolled_win->add_with_viewport($table);
	my $row=0;
	
	my $ok = def_image_button('icons/select.png','OK');
	my $okbox=def_hbox(TRUE,0);
	$okbox->pack_start($ok, FALSE, FALSE,0);
	foreach my $p (@parameters){
		my ($deafult,$type,$content,$info)= $ip->ip_get_parameter($category,$module,$p);
		
		my $value=$param_value{$p};
		
		if ($type eq "Entry"){
			my $entry=gen_entry($value);
			$table->attach_defaults ($entry, 3, 6, $row, $row+1);
			$entry-> signal_connect("changed" => sub{$new_param_value{$p}=$entry->get_text();});
		}
		elsif ($type eq "Combo-box"){
			my @combo_list=split(",",$content);
			my $pos=get_item_pos($value, @combo_list);
			my $combo=gen_combo(\@combo_list, $pos);
			$table->attach_defaults ($combo, 3, 6, $row, $row+1);
			$combo-> signal_connect("changed" => sub{$new_param_value{$p}=$combo->get_active_text();});
			
		}
		elsif 	($type eq "Spin-button"){ 
		  my ($min,$max,$step)=split(",",$content);
		  $value=~ s/\D//g;
		  $min=~ s/\D//g;
		  $max=~ s/\D//g;
		  $step=~ s/\D//g;
		  my $spin=gen_spin($min,$max,$step);
		  $spin->set_value($value);
		  $table->attach_defaults ($spin, 3, 4, $row, $row+1);
		  $spin-> signal_connect("value_changed" => sub{ $new_param_value{$p}=$spin->get_value_as_int(); });
		 
		 # $box=def_label_spin_help_box ($param,$info, $value,$min,$max,$step, 2);
		}
		if (defined $info && $type ne "Fixed"){
			my $info_button=def_image_button('icons/help.png');
			$table->attach_defaults ($info_button, 6, 7, $row, $row+1);	
			$info_button->signal_connect('clicked'=>sub{
				message_dialog($info);
				
			});
			
		}		
		if ($type ne "Fixed"){
			#print "$p:val:$value\n";
			my $label =gen_label_in_center($p);
			$table->attach_defaults ($label, 0, 3, $row, $row+1);	
			$row++;
		}		 
			
		
	}
	
	my $mtable = def_table(10, 1, TRUE);

	$mtable->attach_defaults($scrolled_win,0,1,0,9);
	$mtable->attach_defaults($okbox,0,1,9,10);
	
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
		
		
		set_state($soc_state,"refresh_soc",0);
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

sub gen_instance{;
	#my ($soc,$ip,$infc,$instance_id,$soc_state,$info)=@_;
	my ($soc,$ip,$infc,$instance_id,$soc_state,$info,$table,$offset)=@_;
	
	
	
#	my $box= def_vbox (FALSE,0);
	
#	my $table = def_table(3,5,TRUE);
	my $data_in;
	
#column 1	
	#module name
	my $module=$soc->soc_get_module($instance_id);
	my $category=$soc->soc_get_category($instance_id);
	my $module_name_label=box_label(FALSE,0,$module);
	$table->attach_defaults ($module_name_label,0,1,$offset+0,$offset+1);
	
	#parameter setting button
	my $param_button = def_image_button('icons/setting.png','Setting');
	my $box1=def_hbox(FALSE,5);
	my $up=def_image_button("icons/up_sim.png");
	$box1->pack_start( $up, FALSE, FALSE, 3);
	$box1->pack_start($param_button,   FALSE, FALSE,3);
	$table->attach_defaults ($box1 ,0,1,$offset+1,$offset+2);
	$param_button->signal_connect (clicked => sub{
		get_module_parameter($soc,$ip,$instance_id,$soc_state);	
		
	});
	$up->signal_connect (clicked => sub{
		$soc->soc_decrease_instance_order($instance_id);
		set_state($soc_state,"refresh_soc",0);
		
	});
	
	#remove button
	#my ($box2,$cancel_button) = button_box("Remove");
	my $cancel_button=def_image_button('icons/cancel.png','Remove');
	my $box2=def_hbox(FALSE,5);
	
	my $dwn=def_image_button("icons/down_sim.png");
	$box2->pack_start( $dwn, FALSE, FALSE, 3);
	$box2->pack_start($cancel_button,   FALSE, FALSE,3);
	$table->attach_defaults ($box2,0,1,$offset+2,$offset+3);
	$cancel_button->signal_connect (clicked => sub{
		remove_instance_from_soc($soc,$instance_id,$soc_state);
				
	});	
	$dwn->signal_connect (clicked => sub{
		$soc->soc_increase_instance_order($instance_id);
		set_state($soc_state,"refresh_soc",0);
		
	});
	
	
	#instance name
	my $instance_name=$soc->soc_get_instance_name($instance_id);
	my $instance_label=gen_label_in_left("Instance name");
	my $instance_entry = gen_entry($instance_name);
	   
	
	
	$table->attach_defaults ($instance_label,1,2,$offset+0,$offset+1);
	$table->attach_defaults ($instance_entry,1,2,$offset+1,$offset+2);
	
	$instance_entry->signal_connect (changed => sub{
		#print "changed\n";
		$instance_name=$instance_entry->get_text();
		#check if instance name exist in soc
		my @instance_names= $soc->soc_get_all_instance_name();
		if( grep {$_ eq $instance_name} @instance_names){
			print "$instance_name exist\n";
		}
		else {
		#add instance name to soc
			$soc->soc_set_instance_name($instance_id,$instance_name);
		
			set_state($soc_state,"refresh_soc",25);
				
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
			$plug_name="    $plug_name";
			my($plug_box, $plug_combo)= def_h_labeled_combo_scaled($plug_name,\@connettions_name,$pos,1,2);
			
			#if($row>2){$table->resize ($row, 2);}
			$table->attach_defaults ($plug_box,2,5,$row+$offset,$row+$offset+1);$row=$row+1;
			
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
				
			
			
				set_state($soc_state,"refresh_soc",0);
			},\@ll);
			
	
	}#for $plug_num
		
	}#foreach plug

				
	
	
	
	
	
	
	#$box->pack_start($table, FALSE, FALSE, 0);
	my $separator = Gtk2::HSeparator->new;
	#$box->pack_start($separator, FALSE, FALSE, 3);
	if($row<3) {$row=3;}
	$table->attach_defaults ($separator,0,5,$row+$offset,$row+$offset+1);$row=$row+1;
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
	my($soc,$ip,$infc,$soc_state,$info)=@_;	
	#my $box= def_hbox (TRUE,0);
  
	my $table=def_table(3,25,FALSE);
	my $row=0;
	my @instance_list=$soc->soc_get_instance_order();
	if (scalar @instance_list ==0 ){
		@instance_list=$soc->soc_get_all_instances();
	}
	my $i=0;
	
	foreach my $instanc(@instance_list){
		$row=gen_instance($soc,$ip,$infc,$instanc,$soc_state,$info,$table,$row);
		
	}
	if($row<20){for ($i=$row; $i<20; $i++){
		
		my $temp=gen_label_in_center(" ");
		$table->attach_defaults ($temp, 0, 1 , $i, $i+1);
	}}	
	
	
	#$box->pack_start( $scrolled_win, TRUE, TRUE, 3);
	return $table;
}	
	 
	 
####################
#  show_active_dev
#
################ 

sub show_active_dev{
	my($soc,$ip,$infc,$soc_state,$refresh_ref,$info)=@_;
	my $box= def_table (1, 1, FALSE);
	my $dev_table = generate_dev_table($soc,$ip,$infc,$soc_state,$info);
	my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);
	$scrolled_win->set_policy( "automatic", "automatic" );
	$scrolled_win->add_with_viewport($dev_table);
	


	$$refresh_ref-> signal_connect("clicked" => sub{ 
	   	
		$dev_table->destroy;
		select(undef, undef, undef, 0.1); #wait 10 ms
		$dev_table = generate_dev_table($soc,$ip,$infc,$soc_state,$info);
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
   my ($info,$ip,$soc,$soc_state)=@_;
   my $model = Gtk2::TreeStore->new ('Glib::String', 'Glib::String', 'Glib::Scalar', 'Glib::Boolean');
   my $tree_view = Gtk2::TreeView->new;
   $tree_view->set_model ($model);
   my $selection = $tree_view->get_selection;

   $selection->set_mode ('browse');
   $tree_view->set_size_request (200, -1);

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
 					("Double click to add the device",
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
		add_module_to_soc($soc,$ip,$category,$module,\$info,$soc_state);
		set_state($soc_state,"refresh_soc",0);	
	}
		


	
	



}, \@ll);

  #$tree_view->expand_all;

  my $scrolled_window = Gtk2::ScrolledWindow->new;
  $scrolled_window->set_policy ('automatic', 'automatic');
  $scrolled_window->set_shadow_type ('in');
  $scrolled_window->add($tree_view);

  my $hbox = Gtk2::HBox->new (TRUE, 0);
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
	my ($soc,$info)=@_;
	my $name=$soc->soc_get_soc_name();
		if (length($name)>0){
			my @tmp=split('_',$name);
			if ( $tmp[-1] =~ /^[0-9]+$/ ){
				message_dialog("The soc name must not end with '_number'!");
				return 0;
			}
			
			my $file_v=soc_generate_verilog($soc);
			
			# Write object file
			open(FILE,  ">lib/soc/$name.SOC") || die "Can not open: $!";
			print FILE Data::Dumper->Dump([\%$soc],[$name]);
			close(FILE) || die "Error closing file: $!";
			
			# Write verilog file
			open(FILE,  ">lib/verilog/$name.v") || die "Can not open: $!";
			print FILE $file_v;
			close(FILE) || die "Error closing file: $!";
			
			
			
			
			# copy all files in project work directory
			my $dir = Cwd::getcwd();
			#make target dir
			my $project_dir	  = abs_path("$dir/../../");
			my $target_dir  = "$project_dir/mpsoc_work/SOC/$name";
			mkpath("$target_dir/src_verilog/lib/",1,0755);
			mkpath("$target_dir/sw",1,0755);
    		
    		#copy hdl codes in src_verilog
    		
    		my ($file_ref,$warnings)= get_all_files_list($soc,"hdl_files");
		copy_file_and_folders($file_ref,$project_dir,"$target_dir/src_verilog/lib");
    		
			show_info(\$info,$warnings)     		if(defined $warnings);  
    		
    		
    		#my @pathes=("$dir/../src_peripheral","$dir/../src_noc","$dir/../src_processor");
    		#foreach my $p(@pathes){
    		#	find(
    		#		sub {
        	#			return unless ( -f $_ );
        	#			$_ =~ /\.v$/ && copy( $File::Find::name, "$target_dir/src_verilog/lib/" );
    		#		},
    		#	$p
			#	);
    		#}
    		
    		
    		move ("$dir/lib/verilog/$name.v","$target_dir/src_verilog/"); 	
    		
    		
    		
    		# Write system.h and generated file
			generate_header_file($soc,$project_dir,$target_dir,$dir);
			 
    		
    		# Write Software files
			($file_ref,$warnings)= get_all_files_list($soc,"sw_files");
			copy_file_and_folders($file_ref,$project_dir,"$target_dir/sw");
			
		# Write Software gen files
			($file_ref,$warnings)= get_all_files_list($soc,"gen_sw_files");
			foreach my $f(@{$file_ref}){
				#print "$f\n";
				

			}


		# Write main.c file if not exist
		my $n="$target_dir/sw/main.c";
		if (!(-f "$n")) { 
			# Write main.c
			open(FILE,  ">$n") || die "Can not open: $!";
			print FILE main_c_template($name);
			close(FILE) || die "Error closing file: $!";
			
		}
			
			
			
			
			message_dialog("SoC \"$name\" has been created successfully at $target_dir/ " );
			exec($^X, $0, @ARGV);# reset ProNoC to apply changes
		
		}else {
			message_dialog("Please define the SoC name!");
			
		}	
		
return 1;	
}	


sub main_c_template{
	my $hdr=shift;
	my $text="
#include \"$hdr.h\"


// a simple delay function
void delay ( unsigned int num ){
	
	while (num>0){ 
		num--;
		asm volatile (\"nop\");
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
		
	
	my $window = def_popwin_size(1200,500,"Wishbone slave port address setting");
	my $table = def_table(10, 6, TRUE);
	
	my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);
	$scrolled_win->set_policy( "automatic", "automatic" );
	$scrolled_win->add_with_viewport($table);
	my $row=0;
	
	#title
	$table->attach_defaults(gen_label_in_left  ("Instance name"),0,1,$row,$row+1);
	$table->attach_defaults(gen_label_in_left  ("Interface name"),1,2,$row,$row+1);
	$table->attach_defaults(gen_label_in_left  ("Bus name"),2,3,$row,$row+1);
	$table->attach_defaults(gen_label_in_center("Base address"),3,4,$row,$row+1);
	$table->attach_defaults(gen_label_in_center("End address"),4,5,$row,$row+1);
	$table->attach_defaults(gen_label_in_center("Size (Bytes)"),5,6,$row,$row+1);
	
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
							
							
					$table->attach_defaults($label1,0,1,$row,$row+1);
					$table->attach_defaults($plug_name,1,2,$row,$row+1);
					$table->attach_defaults($label2,2,3,$row,$row+1);
					$table->attach_defaults($entry1,3,4,$row,$row+1);
					$table->attach_defaults($entry2,4,5,$row,$row+1);
							
							
					$table->attach_defaults($box,5,7,$row,$row+1);
							
							
					$entry1->signal_connect('changed'=>sub{
						my $base_in=$entry1->get_text();
						if (length($base_in)<2){ $entry1->set_text('0x')};
						my $end_in=$entry2->get_text();
						my $valid;
						$box->destroy;
						($box,$valid)=addr_box_gen($base_in, $end_in,\@newbase,\@newend,\@connects,$number);
						$status_all[$number]=$valid;
						$table->attach_defaults($box,5,7,$number+1,$number+2);	
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
						$table->attach_defaults($box,5,7,$number+1,$number+2);	
						$table->show_all;				
					} );
														
							
							
					$row++;		
							
						
				}#if
			}#foreach my $num
		}#foreach my $plug
	}#foreach my $instance_id
		
	
	my $ok = def_image_button('icons/select.png','OK');
	my $okbox=def_hbox(TRUE,0);
	$okbox->pack_start($ok, FALSE, FALSE,0);
	
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
		
		
	
	$row= ($row<9)? 9:$row;
	$table->attach_defaults($refbox,2,3,$row,$row+1);
	$table->attach_defaults($okbox,3,4,$row,$row+1);
	
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
	my ($soc,$soc_state)=@_;
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
			clone_obj($soc,$pp);
			set_state($soc_state,"load_file",0);		
		}					
     }
     $dialog->destroy;



	

}






















############
#    main
############
sub socgen_main{
	 
	my $infc = interface->interface_new(); 
	my $ip = ip->lib_new ();
	my $soc = soc->soc_new();
	#my $soc= eval { do 'lib/soc/soc.SOC' };
	
	my $soc_state=  def_state("ideal");
	# main window
	#my $window = def_win_size(1000,800,"Top");
	#  The main table containg the lib tree, selected modules and info section 
	my $main_table = Gtk2::Table->new (20, 12, FALSE);
	
	# The box which holds the info, warning, error ...  mesages
	my ($infobox,$info)= create_text();	
	
	
	my $refresh_dev_win = Gtk2::Button->new_from_stock('ref');
	
	# A tree view for holding a library
	my $tree_box = create_tree ($info,$ip,$soc,$soc_state);



	$main_table->set_row_spacings (4);
	$main_table->set_col_spacings (1);
	
	my  $device_win=show_active_dev($soc,$ip,$infc,$soc_state,\$refresh_dev_win,$info);
	
	
	my $generate = def_image_button('icons/gen.png','Generate');
	my $genbox=def_hbox(TRUE,0);
	$genbox->pack_start($generate,   FALSE, FALSE,0);




	
	my $wb = def_image_button('icons/setting.png','Wishbone address setting');
	my $wbbox=def_hbox(TRUE,0);
	$wbbox->pack_start($wb,   FALSE, FALSE,0);
	
	my $open = def_image_button('icons/browse.png','Load Tile');
	my $openbox=def_hbox(TRUE,0);
	$openbox->pack_start($open,   FALSE, FALSE,0);
	
	
	
	my ($entrybox,$entry) = def_h_labeled_entry('Tile name:');
	$entry->signal_connect( 'changed'=> sub{
		my $name=$entry->get_text();
		$soc->soc_set_soc_name($name);		
	});	
	
	#$table->attach_defaults ($event_box, $col, $col+1, $row, $row+1);
	$main_table->attach_defaults ($tree_box , 0, 2, 0, 17);
	$main_table->attach_defaults ($device_win , 2, 12, 0, 17);
	$main_table->attach_defaults ($infobox  , 0, 12, 17,19);
	$main_table->attach_defaults ($openbox,0, 3, 19,20);
	$main_table->attach_defaults ($entrybox,3, 7, 19,20);
	$main_table->attach_defaults ($wbbox, 7, 10, 19,20);
	$main_table->attach_defaults ($genbox, 10, 12, 19,20);
	

	#check soc status every 0.5 second. referesh device table if there is any changes 
	Glib::Timeout->add (100, sub{ 
	 
		my ($state,$timeout)= get_state($soc_state);

		if ($timeout>0){
			$timeout--;
			set_state($soc_state,$state,$timeout);		
		}
		elsif( $state ne "ideal" ){
			$refresh_dev_win->clicked;
			my $saved_name=$soc->soc_get_soc_name();
			if(defined $saved_name) {$entry->set_text($saved_name);}
			set_state($soc_state,"ideal",0);
			
		}	
		return TRUE;
		
	} );
		
		
	$generate-> signal_connect("clicked" => sub{ 
		generate_soc($soc,$info);
		$refresh_dev_win->clicked;
	
	});

	$wb-> signal_connect("clicked" => sub{ 
		wb_address_setting($soc);
	
	});

	$open-> signal_connect("clicked" => sub{ 
		load_soc($soc,$soc_state);
	
	});	

	my $sc_win = new Gtk2::ScrolledWindow (undef, undef);
		$sc_win->set_policy( "automatic", "automatic" );
		$sc_win->add_with_viewport($main_table);	

	return $sc_win;
	#return $main_table;
	

}