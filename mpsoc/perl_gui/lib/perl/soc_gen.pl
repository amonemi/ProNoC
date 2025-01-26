#! /usr/bin/perl -w
use constant::boolean;
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use soc;
use ip;
use interface;
use POSIX 'strtol';

use File::Path;
#use File::Find;
use File::Copy;
use File::Copy::Recursive qw(dircopy);
use Cwd 'abs_path';


require "widget.pl"; 
require "verilog_gen.pl";
require "readme_gen.pl";
require "hdr_file_gen.pl";
require "diagram.pl";
require "compile.pl";
require "software_editor.pl";

 

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
	my ($soc,$category,$module,$info)=@_;
	my $ip = ip->lib_new ();
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
		my $info_text= "Failed to add default parameter to \"$instance_id\".  $instance_id does not exist exist.";	 
		show_info($info,$info_text); 
		return;
	}
	my @r=$ip->ip_get_param_order($category,$module);
	$soc->soc_add_instance_param_order($instance_id,\@r);
	
	get_module_parameter($soc,$ip,$instance_id);
	undef $ip;
	set_gui_status($soc,"refresh_soc",0);	
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
	my %param_type=  $soc->soc_get_module_param_type($instance_id);
	my %new_param_value=%param_value;
	
	
	
	#gui
	my $table_size = ($param_num<10) ? 10 : $param_num;
	my $window =  def_popwin_size(40,60, "Parameter setting for $module ",'percent');
	my $table = def_table($table_size, 7, FALSE);
	
	my $scrolled_win = add_widget_to_scrolled_win($table);

	my $row=0;
	my $column=0;
	
	my $ok = def_image_button('icons/select.png','OK');
	
	my $at0= 'shrink';
	my $at1= 'shrink';
	
	$table->attach (gen_label_in_left("Parameter name"),0, 2, $row, $row+1,$at0,$at1,2,2);
	$table->attach (gen_label_in_left("Value"),2, 3, $row, $row+1,$at0,$at1,2,2);
	my $param_info='Define how parameter will be included in the SoC/Tile top module containing this IP core. If you define it as "Parameter", its value can be changed at SoC/tile  instantiation time. So multiple different instancitaions of single SoC/tile can be used in MPSoC where each has its own parameter value';
	$table->attach (gen_label_help($param_info,"Type"),3, 4, $row, $row+1,$at0,$at1,2,2);
    
	$row++;
	foreach my $p (@parameters){
		my ($default,$type,$content,$info,$vfile_param_type)= $ip->ip_get_parameter($category,$module,$p);
		my $show = ($type ne "Fixed");
		if ($show){
			my $default_type=  "Localparam";
			$default_type=$param_type{$p} if(defined $param_type{$p});
			my $combo = gen_combobox_object($soc,'current_module_param_type',$p,"Parameter,Localparam",$default_type,undef,undef);
			$table->attach ($combo,3, 4, $row, $row+1,$at0,$at1,2,2) if($vfile_param_type ne 'Parameter' && $category ne 'NoC' && $p ne 'WB_Aw' );
		}
		$default= $param_value{$p} if(defined $param_value{$p});
		($row,$column)=add_param_widget($soc,$p,$p, $default,$type,$content,$info, $table,$row,$column,$show,'current_module_param',undef,undef,'vertical');
	   
	}
	
	
	
	
	my $mtable = def_table(10, 1, FALSE);

	$mtable->attach_defaults($scrolled_win,0,1,0,9);
	$mtable->attach($ok,0,1,9,10,'expand','fill',2,2);
	
	$window->add ($mtable);
	$window->show_all();
	
	$ok-> signal_connect("clicked" => sub{ 
		$window->destroy;
		#save new values 
		my $ref=$soc->object_get_attribute('current_module_param');
		if(defined $ref){
			%new_param_value=%{$ref} ;
			$soc->soc_add_instance_param($instance_id,\%new_param_value);
		}
		$ref=$soc->object_get_attribute('current_module_param_type');
		if(defined $ref){
			%new_param_value=%{$ref} ;
			$soc->soc_add_instance_param_type($instance_id,\%new_param_value);
		}
		
		
		
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
		$soc->object_add_attribute('current_module_param',undef,undef);
		$soc->object_add_attribute('current_module_param_type',undef,undef);
		set_gui_status($soc,"refresh_soc",0);
		
		});
}



############
#  param_box
#
############


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
		 my @combo_list=split(/\s*,\s*/,$content);
		 my $pos=get_item_pos($default, @combo_list);
		 my $combo=gen_combo(\@combo_list, $pos);
		 $box->pack_start($combo,FALSE,FALSE,3);
	 }
	 elsif 	($type eq "Spin-button"){ 
		  my ($min,$max,$step)=split(/\s*,\s*/,$content);
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
				message_dialog("Error! $pdf or ${project_dir}$pdf did not find!\n",'error');	
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
	$box2->pack_start($cancel_button,   FALSE, FALSE,3) ;
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
		my $warn=def_image_button("icons/warning.png");
		$table->attach  ($warn,1,2,$offset+2,$offset+3,'expand','shrink',2,2);  #$box2->pack_start($warn, FALSE, FALSE, 3);  
		$warn->signal_connect (clicked => sub{
			message_dialog("Warning: ${module}'s version (V.$old_v) mismatches with the one existing in library (V.$new_v). The generated system may not work correctly.  Please remove and then add $module again to update it with current version")
				
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
	
	##print "******* %plug=get_module_plugs_value($category,$module)*************\n";
		#print Dumper (\%$ip);	
	my $row=0;
	foreach my $plug (sort keys %plugs) {
		#print "******* $plug *************\n";
		my $plug_num= $plugs{$plug};
		for (my $k=0;$k<$plug_num;$k++){
			
			my @connettions=("IO");
			my @connettions_name=("IO");
			
			my ($connection_num,$matched_soket)= $infc->get_plug($plug);
					
			
			
			my %connect_list= $soc->get_modules_have_this_socket($matched_soket);
			foreach my $id(sort keys %connect_list ){
				if($instance_id ne $id){ # assume its forbidden to connect the socket and plug of same ip to each other
					#generate socket list
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
							my $info_text="$id\:$socket\[$num\] support only single connection.  The previous connection to $p:$connected_plugs{$p}\[$connected_plug_nums{$p}] has been removed.";
							show_info($info, $info_text);
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
	
	
	if($row<3) {$row=3;}
	add_Hsep_to_table ($table,0,5,$row+$offset);$row++;

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
				
	}}	
	

	return $table;
}	
	 
	 
####################
#  show_active_dev
#
################ 

sub show_active_dev{
	my($soc,$ip,$infc,$info)=@_;
	my $dev_table = generate_dev_table($soc,$ip,$infc,$info);
	my $scrolled_win = gen_scr_win_with_adjst($soc,'device_win_adj');
	add_widget_to_scrolled_win($dev_table,$scrolled_win);
	return $scrolled_win;
}	








sub show_select_ip_description {
	my ($soc,$category,$module,$info)=@_;
	my $ip = ip->lib_new ();
  	my $describ=$ip->ip_get($category,$module,"description");
	if($describ){
		show_info($info,$describ);
		
	}
	undef $ip;
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


sub add_to_project_file_list{
		my ($files_ref,$files_path,$list_path )=@_;
			my @new_file_ref;
			foreach my $f(@{$files_ref}){
				my ($name,$path,$suffix) = fileparse("$f",qr"\..[^.]*$");
				push(@new_file_ref,"$files_path/$name$suffix");
			}
			my ($old_file_ref,$r,$err) = regen_object("$list_path/file_list" );
			
			if (defined $old_file_ref){
				foreach my $f(@{$old_file_ref}){
					unless ( grep( /^$f$/, @new_file_ref ) ){
						push(@new_file_ref,$f);
					}

				}
			}			
			open(FILE,  ">$list_path/file_list") || die "Can not open: $!";
			print FILE Data::Dumper->Dump([\@new_file_ref],['files']);
			close(FILE) || die "Error closing file: $!"; 
}



################
#	generate_soc
#################

sub generate_soc{
	my ($soc,$info,$target_dir,$hw_path,$sw_path,$gen_top,$gen_hw_lib,$oldfiles,$multi_core)=@_;
		my $name=$soc->object_get_attribute('soc_name');
	    $oldfiles = "remove" if(!defined $oldfiles);
		$multi_core = 0 if(!defined $multi_core);
		my ($file_v,$top_v,$readme,$prog)=soc_generate_verilog($soc,$sw_path,$info);
			
		# Write object file
		open(FILE,  ">lib/soc/$name.SOC") || die "Can not open: $!";
		print FILE perl_file_header("$name.SOC");
		print FILE Data::Dumper->Dump([\%$soc],['soc']);
		close(FILE) || die "Error closing file: $!";
			
		# Write verilog file
		my $h=autogen_warning().get_license_header("${name}.sv")."\n";
		open(FILE,  ">lib/verilog/$name.sv") || die "Can not open: $!";
		print FILE $h.$file_v;
		close(FILE) || die "Error closing file: $!";
			
		# Write Top module file
		if($gen_top){
			my $l=autogen_warning().get_license_header("${name}_top.sv")."\n`timescale 1ns / 1ps\n";
			open(FILE,  ">lib/verilog/${name}_top.sv") || die "Can not open: $!";
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


        my $m_chain = $soc->object_get_attribute('JTAG','M_CHAIN');

		#generate prog_mem
		open(FILE,  ">lib/verilog/program.sh") || die "Can not open: $!";
		print FILE soc_mem_prog($m_chain) if (defined $m_chain);
		close(FILE) || die "Error closing file: $!";


		
		my $dir = Cwd::getcwd();
		my $project_dir	  = abs_path("$dir/../../"); 		
		if($gen_hw_lib){

			#make target dir
			my $hw_lib="$hw_path/lib";
			my $hw_sim="$hw_path/../src_sim";
			mkpath("$hw_lib/",1,01777);
			mkpath("$sw_path/",1,01777);
			mkpath("$hw_sim/",1,01777);
			
			if ($oldfiles eq "remove"){
				#remove old rtl files that were copied by ProNoC
				my ($old_file_ref,$r,$err) = regen_object("$hw_path/file_list");
				if (defined $old_file_ref){		
					remove_file_and_folders($old_file_ref,$target_dir);
				}				
			}
			
			#copy hdl codes in src_verilog			
			my ($file_ref,$warnings)= get_all_files_list($soc,"hdl_files");	
			my ($sim_ref,$warnings2)= get_all_files_list($soc,"hdl_files_ticked");
			#file_ref-sim_ref
			my @n= get_diff_array($file_ref,$sim_ref);
			$file_ref=\@n;
					
			copy_file_and_folders($file_ref,$project_dir,$hw_lib);
			show_colored_info($info,$warnings,'green')     		if(defined $warnings);			
			add_to_project_file_list($file_ref,$hw_lib,$hw_path);
			
			
			copy_file_and_folders($sim_ref,$project_dir,$hw_sim  );
			show_colored_info($info,$warnings2,'green')     if(defined $warnings2);			
			add_to_project_file_list($sim_ref,$hw_sim,$hw_path);
			    
			  
			    
			    
    		#copy clk setting hdl codes in src_verilog
    		my $sc_soc =get_source_set_top($soc,'soc');  
  			($file_ref,$warnings)= get_all_files_list($sc_soc,"hdl_files");	
  			($sim_ref,$warnings2)= get_all_files_list($soc,"hdl_files_ticked");
			#file_ref-sim_ref
			my @m= get_diff_array($file_ref,$sim_ref);
			$file_ref=\@m;
  			
  				
			copy_file_and_folders($file_ref,$project_dir,$hw_lib);
			show_colored_info($info,$warnings,'green')     		if(defined $warnings);			
			add_to_project_file_list($file_ref,$hw_lib,$hw_path);
			
			copy_file_and_folders($sim_ref,$project_dir,$hw_sim  );
			show_colored_info($info,$warnings2,'green')     if(defined $warnings2);			
			add_to_project_file_list($sim_ref,$hw_sim,$hw_path);
    		
			#copy jtag control files 
			my @jtags=(("/mpsoc/rtl/src_peripheral/jtag/jtag_wb"),("jtag"));
			copy_file_and_folders(\@jtags,$project_dir,$hw_lib); 
			add_to_project_file_list(\@jtags,$hw_lib,$hw_path);  
			 		
			move ("$dir/lib/verilog/$name.sv","$hw_path/"); 
			move ("$dir/lib/verilog/${name}_top.sv","$hw_path/"); 		
			move ("$dir/lib/verilog/README" ,"$sw_path/");
			move ("$dir/lib/verilog/write_memory.sh" ,"$sw_path/");
			move ("$dir/lib/verilog/program.sh" ,"$sw_path/");
		}
		
		#remove old software files that were copied by ProNoC
		
		my ($old_file_ref,$r,$err) = regen_object("$sw_path/file_list" );
		if (defined $old_file_ref){		
			remove_file_and_folders($old_file_ref,$project_dir);
		}
		
		# Copy Software files
		my ($file_ref,$warnings)= get_all_files_list($soc,"sw_files");
		copy_file_and_folders($file_ref,$project_dir,$sw_path);
		show_colored_info($info,$warnings,'green')     		if(defined $warnings);	
		
		my @new_file_ref;
		foreach my $f(@{$file_ref}){
			my ($name,$path,$suffix) = fileparse("$f",qr"\..[^.]*$");
			push(@new_file_ref,"$sw_path/$name$suffix");
		}
		
		push(@new_file_ref,"$sw_path/$name.h");
    	open(FILE,  ">$sw_path/file_list") || die "Can not open: $!";
		print FILE Data::Dumper->Dump([\@new_file_ref],['files']);
		close(FILE) || die "Error closing file: $!";
		
			
		# Write system.h and Software gen files
		generate_header_file($soc,$project_dir,$sw_path,$hw_path,$dir);   			


		# Write main.c file if not exist
		my $n="$sw_path/main.c";
		if (!(-f "$n")) { 
			# Write main.c
			open(FILE,  ">$n") || die "Can not open: $!";
			print FILE '#define MULTI_CORE' if($multi_core);
			print FILE main_c_template($name);
			close(FILE) || die "Error closing file: $!";
			
			#write makefile source lib list file
			open(FILE,  ">$sw_path/SOURCE_LIB") || die "Can not open: $!";
			print FILE "SOURCE_LIB += $name.c ";
			close(FILE) || die "Error closing file: $!";		
			
			
		}
		
		#regenerate linker var file
    	create_linker_var_file($soc);
		
			
		#write perl_object_file 
		mkpath("$target_dir/perl_lib/",1,01777);
		open(FILE,  ">$target_dir/perl_lib/$name.SOC") || die "Can not open: $!";
		print FILE perl_file_header("$name.SOC");
		print FILE Data::Dumper->Dump([\%$soc],['soc']);		
			

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
				 $base+=(1 << $width)while($base<$taken_end);
				# $base=$taken_end+1;
				 
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



#############
#  set_unset_infc
#############

sub set_unset_infc{
	my $soc =shift;
	my $window = def_popwin_size(40,60,"Unconnected Socket Interfaces",'percent');
	my $table = def_table(10,4, FALSE);	
	my $scrolled_win = add_widget_to_scrolled_win($table);
	my $row=0;
	my $column=0;
	
	my $ip = ip->lib_new ();
	my @instances=$soc->soc_get_all_instances();
	foreach my $id (@instances){
		my $module 	=$soc->soc_get_module($id);
		my $module_name	=$soc->soc_get_module_name($id);
		my $category 	=$soc->soc_get_category($id);
		my $inst   	= $soc->soc_get_instance_name($id);
		my @ports=$ip->ip_list_ports($category,$module);
		foreach my $port (@ports){
			my ($type,$range,$intfc_name,$i_port)=$ip->ip_get_port($category,$module,$port);
			my($i_type,$i_name,$i_num) =split("[:\[ \\]]", $intfc_name);
			if($i_type eq 'socket' && $i_name ne'wb_addr_map' && $i_name ne'jtag_to_wb'){ 				
				my ($ref1,$ref2)= $soc->soc_get_modules_plug_connected_to_socket($id,$i_name,$i_num);
				my %connected_plugs=%$ref1;
				my %connected_plug_nums=%$ref2;
				if(!%connected_plugs ){ 
					my  ($s_type,$s_value,$s_connection_num)=$soc->soc_get_socket_of_instance($id,$i_name);
					my $v=$soc->soc_get_module_param_value($id,$s_value);
					if ( length( $v || '' ) || $category eq 'NoC' ){ }
					else {
						($row,$column)=add_param_widget ($soc,"$inst->$port","$inst-$port", 'IO','Combo-box',"IO,NC",undef, $table,$row,$column,1,"Unset-intfc",undef,undef,"vertical");
						if($column == 0){
							$column = 4;
														
							$row= $row-1;
						}else{
							$column =  0;
							
							
							
						}
						
					}
					
				}
			}
		}
	}
	
	my $box1=def_hbox(FALSE, 1);
	$box1->pack_start( gen_Vsep(), FALSE, FALSE, 3);	
	$table->attach($box1,3,4,0,$row+1,'expand','fill',2,2);
	my $ok = def_image_button('icons/select.png','OK');
	$ok->signal_connect	( 'clicked'=> sub {
		$window->destroy;
	});
	
	my $mtable = def_table(10, 1, FALSE);
	$mtable->attach_defaults($scrolled_win,0,1,0,9);
	$mtable->attach($ok,0,1,9,10,'expand','fill',2,2);
	$window->add ($mtable);
	$window->show_all;
	
	
}





##########
#	wb address setting
#########

sub wb_address_setting {
	my $soc=shift;
		
	
	my $window = def_popwin_size(80,50,"Wishbone slave port address setting",'percent');
	my $table = def_table(10, 6, FALSE);
	
	my $scrolled_win = add_widget_to_scrolled_win($table);
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
					my $entry1= gen_entry_new_with_max_length (10,sprintf("0x%08x", $base));						
					my $entry2= gen_entry_new_with_max_length (10,sprintf("0x%08x", $end));
												
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
			message_dialog("Invalid address!",'error');
			
		}	
		
		
		});
		
	
	my $mtable = def_table(10, 2, FALSE);
	$mtable->attach_defaults($scrolled_win,0,2,0,9);
	$mtable->attach ($refbox,0,1,9,10,'expand','shrink',2,2);
	$mtable->attach($ok,1,2,9,10,'expand','fill',2,2);
	$window->add ($mtable);
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
	
	
	my $status=(defined $info)? gen_button_message ($info,'icons/warning.png'):
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
		#print "\n$value=\$soc->soc_get_module_param_value($id,$p)\n";
		foreach my $q (sort keys %sim_params){
			
			$value=replace_value($value,$q,$sim_params{$q}) if (defined $value);
			
			
		}
		$sim_params{$p}=$value;
		#print "\$sim_params{$p}=$value;\n";
	}
	return $sim_params{$param};
}	
	
	
	
	
sub replace_value{
	my ($string,$param,$value)=@_;

	my $new_string=$string;
	#print "$new_range\n";
	my $new_param= $value;
	($new_string=$new_string)=~ s/\b$param\b/$new_param/g;
	my $new_val = eval $new_string;
	return $new_val if (defined $new_val);
	return $string;
		
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
	my ($soc,$info)=@_;
	my $ip = ip->lib_new ();
	my $file;
	my $dialog =  gen_file_dialog (undef, 'SOC');	
	my $dir = Cwd::getcwd();
	$dialog->set_current_folder ("$dir/lib/soc");		


	if ( "ok" eq $dialog->run ) {
		$file = $dialog->get_filename;
		my ($name,$path,$suffix) = fileparse("$file",qr"\..[^.]*$");
		if($suffix eq '.SOC'){
			my ($pp,$r,$err) = regen_object($file);
			if ($r || !defined $pp){		
				show_info($info,"**Error reading  $file file: $err\n");
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
	$differences="$differences \t The $instance_id version (V.$old_v) mismatches with the one existing in the library (V.$new_v).\n " if($old_v != $new_v);
		
	
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
	
	my $scrolled_win = add_widget_to_scrolled_win($table);
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
	$name="" if (!defined $name);
	if (length($name)==0){
		message_dialog("Please define the Tile name!");
		return ;
	}
	my $target_dir  = "$ENV{'PRONOC_WORK'}/SOC/$name";
	my $sw 	= "$target_dir/sw";
	my ($app,$table,$tview) = software_main($sw);

	

    my $ram = def_image_button('icons/info.png',"Required BRAMs\' size",FALSE,1);
    my $linker = def_image_button('icons/setting.png','LD Linker',FALSE,1);
	my $make = def_image_button('icons/gen.png','Compile');
	my $regen= def_image_button('icons/refresh.png','Regenerate main.c');
	my $prog= def_image_button('icons/write.png','Program the memory');

	$table->attach ($ram,0, 1, 1,2,'shrink','shrink',0,0);	
	$table->attach ($regen,1, 2, 1,2,'shrink','shrink',0,0);
	$table->attach ($linker,4, 5, 1,2,'shrink','shrink',0,0);	
	$table->attach ($make,5, 6, 1,2,'shrink','shrink',0,0);
	$table->attach ($prog,9, 10, 1,2,'shrink','shrink',0,0); 
	$regen -> signal_connect ("clicked" => sub{
		my $response =  yes_no_dialog("Are you sure you want to regenerate the main.c file? Note that any changes you have made will be lost");
		if ($response eq 'yes') {      			
			save_file ("$sw/main.c",main_c_template($name));
			$app->refresh_source("$sw/main.c");	
  		}		
	});
    
    my $load;
	$make -> signal_connect("clicked" => sub{
		$load->destroy   if(defined $load);
		$app->ask_to_save_changes();
		$load= show_gif("icons/load.gif");
        $table->attach ($load,7, 8, 1,2,'shrink','shrink',0,0);
        $load->show_all; 
		unless (run_make_file($sw,$tview,'clean')){
        	$load->destroy;    
        	$load=def_icon("icons/cancel.png");
        	$table->attach ($load,7, 8, 1,2,'shrink','shrink',0,0); 
        	$load->show_all; 
        	return;
        };
		unless (run_make_file($sw,$tview)){
			$load->destroy;    
        	$load=def_icon("icons/cancel.png");
        	$table->attach ($load,7, 8, 1,2,'shrink','shrink',0,0); 
        	$load->show_all; 
        	return;			
		}
		$load->destroy;
		$load=def_icon("icons/button_ok.png");
        $table->attach ($load,7, 8, 1,2,'shrink','shrink',0,0); 
        $load->show_all; 
	});

	#Programe the board 
	$prog-> signal_connect("clicked" => sub{ 
		my $error = 0;
		my $bash_file="$target_dir/sw/program.sh";
		my $jtag_intfc="$sw/jtag_intfc.sh";

		add_info($tview,"Program the board using quartus_pgm and $bash_file file\n");
		#check if the programming file exists
		unless (-f $bash_file) {
			add_colored_info($tview,"\tThe $bash_file does not exists! \n", 'red');
			$error=1;
		}
		#check if the jtag_intfc.sh file exists
		unless (-f $jtag_intfc) {
			add_colored_info($tview,"\tThe $jtag_intfc does not exists!. Press the compile button and select your FPGA board first to generate $jtag_intfc file\n", 'red');
			$error=1;
		}
		
		return if($error);
		my $command = "cd $target_dir/sw; bash program.sh";
		add_info($tview,"$command\n");
		my ($stdout,$exit,$stderr)=run_cmd_in_back_ground_get_stdout($command);
		if(length $stderr>1){			
			add_colored_info($tview,"$stderr\n",'red');
			add_colored_info($tview,"Memory was not programmed successfully!\n",'red');
		}else {

			if($exit){
				add_colored_info($tview,"$stdout\n",'red');
				add_colored_info($tview,"Memory was not programmed successfully!\n",'red');
			}else{
				add_info($tview,"$stdout\n");
				add_colored_info($tview,"Memory is programmed successfully!\n",'blue');

			}
			
		}		
	});
	
	$ram -> signal_connect("clicked" => sub{
		show_reqired_brams($soc,$tview);
	});
	
	$linker -> signal_connect("clicked" => sub{
		linker_setting($soc,$tview);
	});

}


sub soc_mem_prog {
	my $chain=shift;
	my $string="#!/bin/bash


#JTAG_INTFC=\"\$PRONOC_WORK/toolchain/bin/JTAG_INTFC\"
source ./jtag_intfc.sh

#reset and disable cpus, then release the reset but keep the cpus disabled

\$JTAG_INTFC -t $chain -n 127  -d  \"I:1,D:2:3,D:2:2,I:0\"

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



#Program the memory

	bash write_memory.sh 

 
#Enable the cpu
\$JTAG_INTFC -t $chain -n 127  -d  \"I:1,D:2:0,I:0\"
# I:1  set jtag_enable  in active mode
# D:2:0 load jtag_enable data register with 0x0 reset=0 disable=0
# I:0  set jtag_enable  in bypass mode
";
return $string;
	
}


sub soc_gen_top_ip{
	my $soc=shift;
	my $top_ip=ip_gen->top_gen_new();
	my $ip = ip->lib_new ();
	my $intfc=interface->interface_new();
	my @instances=$soc->soc_get_all_instances();
	my $wires=soc->new_wires();
	foreach my $id (@instances){
		my ($param_v, $local_param_v, $wire_def_v, $inst_v, $plugs_assign_v, $sockets_assign_v,$io_full_v,$io_top_full_v,$io_sim_v,
		$top_io_short,$param_as_in_v,$param_pass_v,$system_v,$assigned_ports,$top_io_pass,$src_io_short, $src_io_full)=gen_module_inst($id,$soc,$top_ip,$intfc,$wires);
	}	#$id
	return $top_ip;
}




sub get_soc_clk_source_list{
	my $soc=shift;
    my %all_sources;    
    my $top = soc_gen_top_ip($soc);
    my @intfcs=$top->top_get_intfc_list();
	my @sources=('clk','reset');
	foreach my $intfc (@intfcs){	
			my($type,$name,$num)= split("[:\[ \\]]", $intfc);
			foreach my $s (@sources){
				if ($intfc =~ /plug:$s/){ 
					my @ports=$top->top_get_intfc_ports_list($intfc);				
					$all_sources{$s}=\@ports;
				}	
			}
	}
	return %all_sources;
}	

sub check_soc_name{
	my $name=shift;
	$name="" if (!defined $name);
	if (length($name)==0){
		message_dialog("Please define the Tile name!");
		return 1;
	}	
	
	my @tmp=split('_',$name);
	if ( $tmp[-1] =~ /^[0-9]+$/ ){
		message_dialog("The soc name must not end with '_number'!");
		return 1;
	}
	
	my $error = check_verilog_identifier_syntax($name);
	if ( defined $error ){
		message_dialog("The \"$name\" is given with an unacceptable formatting. This name will be used as top level Verilog module name so it must follow Verilog identifier declaration formatting:\n $error");
		return 1;
	}
	return 0;	
}


############
#    main
############



sub soc_clk_setting_win1 { 
	my ($soc,$info)=@_;
	my $window = def_popwin_size(80,80,"CLK setting",'percent');
   
    my $next=def_image_button('icons/right.png','Next'); 	
	my $mtable = def_table(10, 1, FALSE);
	#get the list of all tiles clk sources
	
	
	
	my $table = def_table(10, 7, FALSE);
	my($row,$column)=(0,0);
	
	my %all = get_soc_clk_source_list($soc) ;
	my @ports = @{$all{'clk'}} if defined $all{'clk'};
	my $n=0;
	foreach my $p (@ports){
		my $r_lab=gen_label_in_center("$p:");
		$table->attach  ($r_lab,$column,$column+1,$row,$row+1,'fill','shrink',2,2);$column+=1;
		$soc->object_add_attribute('SOURCE_SET',"clk_${n}_name",$p);
		($column,$row)=get_clk_constrain_widget($soc,$table,$column,$row,'clk',$n);	
		$n++;
	}

	$mtable->attach_defaults($table,0,1,0,1);
	$mtable->attach($next,0,1,20,21,'expand','fill',2,2);	
	$window->add ($mtable);
	$window->show_all();	
	$next-> signal_connect("clicked" => sub{ 			
		$window->destroy;		
		clk_setting_win2($soc,$info,'soc');
					
	});	


 	

}


######
# ctrl
######

sub soc_ctrl_tab {
	my ($soc,$info,$ip)=@_;
	
	my $generate = def_image_button('icons/gen.png','_Generate RTL',FALSE,1);
	my $compile  = def_image_button('icons/gate.png','Compile RTL');
	my $software = def_image_button('icons/binary.png','Software');
	my $diagram  = def_image_button('icons/diagram.png','Diagram');
	my $clk=  def_image_button('icons/clk.png','CLK setting');
	my $unset    = def_image_button('icons/intfc.png','Unset Intfc.');
	
	my $ram      = def_image_button('icons/RAM.png','Memory');	
	my $wb = def_image_button('icons/setting.png','WB addr');	
	#my $open = def_image_button('icons/browse.png',"_Load Tile",FALSE,1);
	#my $entry=gen_entry_object($soc,'soc_name',undef,undef,undef,undef);
	#my $entrybox=gen_label_info(" Tile name:",$entry);
	#my $save      = def_image_button('icons/save.png');	
	#my $open_dir  = def_image_button('icons/open-folder.png');
	#set_tip($save, "Save current tile configuration setting");
	#set_tip($open_dir, "Open target tile folder");
		
	#$entrybox->pack_start( $save, FALSE, FALSE, 0);
	#$entrybox->pack_start( $open_dir, FALSE, FALSE, 0);
	
	my $main_table = def_table (1, 12, FALSE);


    my $target_dir= "$ENV{'PRONOC_WORK'}/SOC";    
	my ($entrybox,$entry ) =gen_save_load_widget (
        $soc, #the object 
        "Tile name",#the label shown for setting configuration
        'soc_name',#the key name for saveing the setting configuration in object 
        'Tile',#the label full name show in tool tips
        $target_dir,#Where the generted RTL files are loacted. Undef if not aplicaple
        'soc',#check the given name match the SoC or mpsoc name rules
        'lib/soc',#where the current configuration seting file is saved
        'SOC',#the extenstion given for configuration seting file
		\&load_soc,#refrence to load function
		$info
        );




	
	#$main_table->attach ($open		, 0, 1, 0,1,'expand','shrink',2,2);
	$main_table->attach ($entrybox	, 1, 3, 0,1,'expand','shrink',2,2);
	$main_table->attach ($unset		, 3, 4, 0,1,'expand','shrink',2,2);
	$main_table->attach ($wb		, 4, 5, 0,1,'expand','shrink',2,2);
	$main_table->attach ($diagram	, 5, 6, 0,1,'expand','shrink',2,2);
	$main_table->attach ($clk		, 6, 7, 0,1,'expand','shrink',2,2);
	$main_table->attach ($generate	, 7, 8, 0,1,'expand','shrink',2,2);
	$main_table->attach ($software	, 8, 9, 0,1,'expand','shrink',2,2);
	$main_table->attach ($compile	,10,12, 0,1,'expand','shrink',2,2);
	
	
	$clk-> signal_connect("clicked" => sub{ 
			soc_clk_setting_win1($soc,$info);	
	});

	$diagram-> signal_connect("clicked" => sub{ 
		show_tile_diagram ($soc);
	});
	

	#$save-> signal_connect("clicked" => sub{ 
	#	my $name=$soc->object_get_attribute('soc_name');		
	#	return if(check_soc_name($name)) ;
			
	#	# Write object file
	#	open(FILE,  ">lib/soc/$name.SOC") || die "Can not open: $!";
	#	print FILE perl_file_header("$name.SOC");
	#	print FILE Data::Dumper->Dump([\%$soc],['soc']);
	#	close(FILE) || die "Error closing file: $!";
	#	message_dialog("Processing Tile  \"$name\" is saved as lib/soc/$name.SOC.");		
			
	#});
	
	
	$generate-> signal_connect("clicked" => sub{ 
		my $name=$soc->object_get_attribute('soc_name');		
		return if(check_soc_name($name)) ;

		my $target_dir  = "$ENV{'PRONOC_WORK'}/SOC/$name";
		my $hw_dir 	= "$target_dir/src_verilog";
		my $sw_path 	= "$target_dir/sw";
    		
		$soc->object_add_attribute('global_param','CORE_ID',0);	
		$soc->object_add_attribute('global_param','SW_LOC',$sw_path);	
		
		unlink  "$hw_dir/file_list";
		generate_soc($soc,$info,$target_dir,$hw_dir,$sw_path,1,1);
		
		my $has_ni= check_for_ni($soc);
		if($has_ni){
			my $message = "Processing Tile  \"$name\" has been created successfully at $target_dir/.  In order to include this tile in MPSoC Generator you need to restart the ProNoC. Do you ant to reset the ProNoC now?";
			my $response =  yes_no_dialog ($message);
			if ($response eq 'yes') {
	      			exec($^X, $0, @ARGV);# reset ProNoC to apply changes	
	  		}
	  		
		} else {
			message_dialog("Processing Tile  \"$name\" has been created successfully at $target_dir/.");

		}
	});

	$software -> signal_connect("clicked" => sub{
		software_edit_soc($soc);

	});
	
	$unset-> signal_connect("clicked" => sub{
		set_unset_infc($soc);
	});

	$ram-> signal_connect("clicked" => sub{
		get_ram_init($soc);

	});

   
	
	$compile -> signal_connect("clicked" => sub{ 
		$soc->object_add_attribute('compile','compilers',"QuartusII,Vivado,Verilator,Modelsim");
		my $name=$soc->object_get_attribute('soc_name');
		$name="" if (!defined $name);
		if (length($name)==0){
			message_dialog("Please define the Tile name!");
			return ;
		}
		my $target_dir  = "$ENV{'PRONOC_WORK'}/SOC/$name";
		my $hw_dir 	= "$target_dir/src_verilog";
		my $sw_path 	= "$target_dir/sw";
		my $top 	= "$target_dir/src_verilog/${name}_top.sv";
		if (-f $top){
			unlink  "$hw_dir/file_list";
			generate_soc($soc,$info,$target_dir,$hw_dir,$sw_path,1,1);	
			select_compiler($soc,$name,$top,$target_dir);
		} else {
			message_dialog("Cannot find $top file. Please run RTL Generator first!",'error');
			return;
		}
	});

	$wb-> signal_connect("clicked" => sub{ 
		wb_address_setting($soc);
	
	});

	#$open-> signal_connect("clicked" => sub{ 
	#	load_soc($soc,$info);
	
	#});	
	
	#$open_dir-> signal_connect("clicked" => sub{ 
	#	my $name=$soc->object_get_attribute('soc_name');
	#	$name="" if (!defined $name);
	#	if (length($name)==0){
	#		message_dialog("Please define the Tile name!");
	#		return ;
	#	}
	#	my $target_dir  = "$ENV{'PRONOC_WORK'}/SOC/$name";
	#	unless (-d $target_dir){
	#		message_dialog("Cannot find $target_dir.\n Please run RTL Generator first!",'error');
	#		return;
	#	}
	#	system "xdg-open   $target_dir";
		
	#});	
	
	return $main_table;
	
}


sub socgen_main{
	 
	my $infc = interface->interface_new(); 
	my $ip = ip->lib_new ();
	my $soc = soc->soc_new();
	set_gui_status($soc,"ideal",0);
		
	#  The main table containing the lib tree, selected modules and info section 
	my $main_table = def_table (20, 12, FALSE);
	
	# The box which holds the info, warning, error ...  messages
	my ($infobox,$info)= create_txview();	
		
	
	# A tree view for holding a library
	my %tree_text;
	my @categories= $ip->ip_get_categories();
    foreach my $p (@categories)
    {
   		#next if ($p eq 'PLL');
   		my @modules= $ip->get_modules($p);
   		$tree_text{$p}=\@modules;	
    }
	my $tree_box = create_tree ($soc,'IP list', $info,\%tree_text,\&show_select_ip_description,\&add_module_to_soc);

	$main_table->set_row_spacings (4);
	$main_table->set_col_spacings (1);
	
	my  $device_win=show_active_dev($soc,$ip,$infc,$info);
	
	
	
	
		
	my $h1=gen_hpaned($tree_box,.15,$device_win);
	my $v2=gen_vpaned($h1,.55,$infobox);
	$main_table->attach_defaults ($v2  , 0, 12, 0,19);
	
	my $ctrl = soc_ctrl_tab($soc,$info,$ip);
	$main_table->attach ($ctrl  , 0, 12, 19,20,'fill','fill',2,2);

	

	my $sc_win = add_widget_to_scrolled_win($main_table);



	#check soc status every 0.5 second. refresh device table if there is any changes 
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
			$device_win->destroy;
			$device_win=show_active_dev($soc,$ip,$infc,$info);
			$h1 -> pack2($device_win, TRUE, TRUE);  
			$h1 -> show_all; 
			$ctrl->destroy;
			$ctrl= soc_ctrl_tab($soc,$info,$ip);
			$main_table->attach ($ctrl  , 0, 12, 19,20,'fill','fill',2,2);
			$main_table->show_all; 
			set_gui_status($soc,"ideal",0);			
		}	
		return TRUE;
		
	} );

	

	return $sc_win;

	

}






