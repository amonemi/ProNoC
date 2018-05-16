#! /usr/bin/perl -w
use Glib qw/TRUE FALSE/;
use strict;
use warnings;

use mpsoc;
use soc;
use ip;
use interface;

use POSIX 'strtol';

use File::Path;
use File::Copy;

use Cwd 'abs_path';


use Gtk2;
use Gtk2::Pango;




require "widget.pl"; 
require "mpsoc_verilog_gen.pl";
require "hdr_file_gen.pl";
require "readme_gen.pl";
require "soc_gen.pl";

sub get_pos{
		my ($item,@list)=@_;
		my $pos=0;
		foreach my $p (@list){
				#print "$p eq $item\n";
				if ($p eq $item){return $pos;}
				$pos++;
		}	
		return undef;
	
}	


sub noc_param_widget{
	 my ($mpsoc,$name,$param, $default,$type,$content,$info, $table,$row,$show,$attribut1,$ref_delay,$new_status)=@_;
	 my $label =gen_label_in_left(" $name");
	 my $widget;
	 my $value=$mpsoc->object_get_attribute($attribut1,$param);
	 if(! defined $value) {
			$mpsoc->object_add_attribute($attribut1,$param,$default);
			$mpsoc->object_add_attribute_order($attribut1,$param);
			$value=$default;
	 }
	 if(! defined $new_status){
		$new_status='ref';
	 }
	 if ($type eq "Entry"){
		$widget=gen_entry($value);
		$widget-> signal_connect("changed" => sub{
			my $new_param_value=$widget->get_text();
			$mpsoc->object_add_attribute($attribut1,$param,$new_param_value);
			set_gui_status($mpsoc,$new_status,$ref_delay) if(defined $ref_delay);
			

		});
		
		
	 }
	 elsif ($type eq "Combo-box"){
		 my @combo_list=split(",",$content);
		 my $pos=get_pos($value, @combo_list) if(defined $value);
		 if(!defined $pos){
		 	$mpsoc->object_add_attribute($attribut1,$param,$default);	
		 	$pos=get_item_pos($default, @combo_list) if (defined $default);
		 		 	
		 }
		#print " my $pos=get_item_pos($value, @combo_list);\n";
		 $widget=gen_combo(\@combo_list, $pos);
		 $widget-> signal_connect("changed" => sub{
		 my $new_param_value=$widget->get_active_text();
		 $mpsoc->object_add_attribute($attribut1,$param,$new_param_value);
		 set_gui_status($mpsoc,$new_status,$ref_delay) if(defined $ref_delay);


		 });
		 
	 }
	 elsif 	($type eq "Spin-button"){ 
		  my ($min,$max,$step)=split(",",$content);
		  $value=~ s/\D//g;
		  $min=~ s/\D//g;
		  $max=~ s/\D//g;
		  $step=~ s/\D//g;
		  $widget=gen_spin($min,$max,$step);
		  $widget->set_value($value);
		  $widget-> signal_connect("value_changed" => sub{
		  my $new_param_value=$widget->get_value_as_int();
		  $mpsoc->object_add_attribute($attribut1,$param,$new_param_value);
		  set_gui_status($mpsoc,$new_status,$ref_delay) if(defined $ref_delay);

		  });
		 
		 # $box=def_label_spin_help_box ($param,$info, $value,$min,$max,$step, 2);
	 }
	
	elsif ( $type eq "Check-box"){
		$widget = def_hbox(FALSE,0);
		my @check;
		for (my $i=0;$i<$content;$i++){
			$check[$i]= Gtk2::CheckButton->new;
		}
		for (my $i=0;$i<$content;$i++){
			$widget->pack_end(  $check[$i], FALSE, FALSE, 0);
			
			my @chars = split("",$value);
			#check if saved value match the size of check box
			if($chars[0] ne $content ) {
				$mpsoc->object_add_attribute($attribut1,$param,$default);
				$value=$default;
				@chars = split("",$value);
			}
			#set initial value
			
			#print "\@chars=@chars\n";
			for (my $i=0;$i<$content;$i++){
				my $loc= (scalar @chars) -($i+1);
					if( $chars[$loc] eq '1') {$check[$i]->set_active(TRUE);}
					else {$check[$i]->set_active(FALSE);}
			}


			#get new value
			$check[$i]-> signal_connect("toggled" => sub{
				my $new_val="$content\'b";			
 				
				for (my $i=$content-1; $i >= 0; $i--){
					if($check[$i]->get_active()) {$new_val="${new_val}1" ;}
					else {$new_val="${new_val}0" ;}
				}
				$mpsoc->object_add_attribute($attribut1,$param,$new_val);
				#print "\$new_val=$new_val\n";
				set_gui_status($mpsoc,$new_status,$ref_delay) if(defined $ref_delay);
			});
		}




	}
	elsif ( $type eq "DIR_path"){
			$widget =get_dir_in_object ($mpsoc,$attribut1,$param,$value,'ref',10);
			set_gui_status($mpsoc,$new_status,$ref_delay) if(defined $ref_delay);
	}
	
	
	
	else {
		 $widget =gen_label_in_left("unsuported widget type!");
	}

	my $inf_bt= gen_button_message ($info,"icons/help.png");
	if($show==1){
		attach_widget_to_table ($table,$row,$label,$inf_bt,$widget);
		$row++;
	}
    return $row;
}




sub initial_default_param{
	my $mpsoc=shift;
	my @socs=$mpsoc->mpsoc_get_soc_list();
	foreach my $soc_name (@socs){
		my %param_value;
		my $top=$mpsoc->mpsoc_get_soc($soc_name);
		my @insts=$top->top_get_all_instances();
		my @exceptions=get_NI_instance_list($top);
		@insts=get_diff_array(\@insts,\@exceptions);
		foreach my $inst (@insts){
			my @params=$top->top_get_parameter_list($inst);
			foreach my $p (@params){	
				my  ($default,$type,$content,$info,$global_param,$redefine)=$top->top_get_parameter($inst,$p);
				$param_value{$p}=$default;
			}
		}
		$top->top_add_default_soc_param(\%param_value);
	}
	
}

#############
#	get_soc_lists
############

sub get_soc_list {
	my ($mpsoc,$info)=@_;

	
	my $path=$mpsoc->object_get_attribute('setting','soc_path');		
	
	$path =~ s/ /\\ /g;
    	my @socs;
	my @files = glob "$path/*.SOC";
	for my $p (@files){
		
		# Read
		my  $soc = eval { do $p };
		 if ($@ || !defined $soc){		
			add_info(\$info,"**Error reading  $p file: $@\n");
		         next; 
		} 
		my $top=$soc->soc_get_top();
		if (defined $top){
			my @instance_list=$top->top_get_all_instances();
			#check if the soc has ni port
			foreach my $instanc(@instance_list){
				my $category=$top->top_get_def_of_instance($instanc,'category');
				if($category eq 'NoC') 
				{
					my $name=$soc->object_get_attribute('soc_name');			
					$mpsoc->mpsoc_add_soc($name,$top);
					#print" $name\n";
				}		
			}			
		
		}
		
		
		
		
		
		
		
		
	}#files
	
	# initial  default soc parameter
	initial_default_param($mpsoc);
	
	
	
	return $mpsoc->mpsoc_get_soc_list;



}


sub get_NI_instance_list {
	my $top=shift;
	my @nis;
	my @instance_list=$top->top_get_all_instances();
	#check if the soc has ni port
	foreach my $instanc(@instance_list){
			my $category=$top->top_get_def_of_instance($instanc,'category');
			 push(@nis,$instanc) if($category eq 'NoC') ;
	}
	return @nis;
}

####################
# get_conflict_decision
###########################
sub b_box{
# create a new button
	my @label=@_;
	my $button = Gtk2::Button->new_from_stock(@label);
	my $box=def_vbox(FALSE,5);
	$box->pack_start($button,   FALSE, FALSE,0);
	
	return ($box,$button);

}

sub get_conflict_decision{
	my ($mpsoc,$name,$inserted,$conflicts,$msg)=@_;
	$msg="\tThe inserted tile number(s) have been mapped previously to \n\t\t\"$msg\".\n\tDo you want to remove the conflicted tiles number(s) in newly \n\tinsterd range or remove them from the previous ones? ";
	
	my $wind=def_popwin_size(10,30,"warning",'percent');
	my $label= gen_label_in_left($msg);	
	my $table=def_table(2,6,FALSE);
	$table->attach_defaults ($label , 0, 6, 0,1);
	$wind->add($table);

	my ($box1,$b1)= b_box("Remove Previous");
	my ($box2,$b2)= b_box("Remove Current");
	my ($box3,$b3)= b_box("Cancel");
	
	$table->attach_defaults ($box1 , 0, 1, 1,2);
	$table->attach_defaults ($box2 , 3, 4, 1,2);
	$table->attach_defaults ($box3 , 5, 6, 1,2);

	$wind->show_all();
	
	$b1->signal_connect( "clicked"=> sub{ #Remove Previous
		my @socs=$mpsoc->mpsoc_get_soc_list();		
		foreach my $p (@socs){
			if($p ne $name){
				my @taken_tiles=$mpsoc->mpsoc_get_soc_tiles_num($p);
				my @diff=get_diff_array(\@taken_tiles,$inserted);
				$mpsoc->mpsoc_add_soc_tiles_num($p,\@diff) if(scalar @diff  );
				$mpsoc->mpsoc_add_soc_tiles_num($p,undef) if(scalar @diff ==0 );
			}
		}
		$mpsoc->mpsoc_add_soc_tiles_num($name,$inserted) if(defined $inserted  );
		set_gui_status($mpsoc,"ref",1);		
		$wind->destroy();
			
	});
	
	$b2->signal_connect( "clicked"=> sub{#Remove Current
		my @new= get_diff_array($inserted,$conflicts);	
		$mpsoc->mpsoc_add_soc_tiles_num($name,\@new) if(scalar @new  );
		$mpsoc->mpsoc_add_soc_tiles_num($name,undef) if(scalar @new ==0 );
		set_gui_status($mpsoc,"ref",1);		
		$wind->destroy();		
		
	});
	
	$b3->signal_connect( "clicked"=> sub{
		$wind->destroy();		
			
	});
		
}	



#############
#	check_inserted_ip_nums
##########


sub check_inserted_ip_nums{
	my  ($mpsoc,$name,$str)=@_;
	my @all_num=();
	$str= remove_all_white_spaces ($str);
	
	if($str !~ /^[0-9.:,]+$/){ message_dialog ("The Ip numbers contains invalid character" ); return; }
	my @chunks=split(',',$str);
	foreach my $p (@chunks){
		my @range=split(':',$p);
		my $size= scalar @range;
		if($size==1){ # its a number
			if ( grep( /^$range[0]$/, @all_num ) ) { message_dialog ("Multiple definition for Ip number $range[0]" ); return; }
			push(@all_num,$range[0]);
		}elsif($size ==2){# its a range
			my($min,$max)=@range;
			if($min>$max) {message_dialog ("invalid range: [$p]" ); return;} 
			for (my $i=$min; $i<=$max; $i++){
				if ( grep( /^$i$/, @all_num ) ) { message_dialog ("Multiple definition for Ip number $i in $p" ); return; }
				push(@all_num,$i);
				
			}
			
		}else{message_dialog ("invalid range: [$p]" ); return; }	
		
	}
	#check if range does not exceed the tile numbers
	my $nx= $mpsoc->object_get_attribute('noc_param',"NX");
	my $ny= $mpsoc->object_get_attribute('noc_param',"NY");
	
	my $max_tile_num=$nx*$ny;
	my @f=sort { $a <=> $b }  @all_num;
	my @l;
	foreach my $num (@f){
		push(@l,$num) if($num<$max_tile_num);			
		
	}
	@all_num=@l;
	
	#check if any ip number exists in the rest
	my $conflicts_msg;
	my @conflicts;
	
	
	my @socs=$mpsoc->mpsoc_get_soc_list();
	foreach my $p (@socs){
		if($p ne $name){
			my @taken_tiles=$mpsoc->mpsoc_get_soc_tiles_num($p);
			my @c=get_common_array(\@all_num,\@taken_tiles);
			if (scalar @c) {
				my $str=join(',', @c);
				$conflicts_msg = (defined $conflicts_msg)? "$conflicts_msg\n\t\t $str->$p" : "$str->$p";
				@conflicts= (defined $conflicts_msg)? (@conflicts,@c): @c;
			}
		}#if
	}
	if (defined $conflicts_msg) {
		get_conflict_decision($mpsoc,$name,\@all_num,\@conflicts,$conflicts_msg);
		
	}else {
		#save the entered ips
		if( scalar @all_num>0){ $mpsoc->mpsoc_add_soc_tiles_num($name,\@all_num);}
		else {$mpsoc->mpsoc_add_soc_tiles_num($name,undef);}
		set_gui_status($mpsoc,"ref",1);
	}
	


}




#################
# get_soc_parameter_setting
################

sub get_soc_parameter_setting{
	my ($mpsoc,$soc_name,$tile)=@_;
	
	my $window = (defined $tile)? def_popwin_size(40,40,"Parameter setting for $soc_name located in tile($tile) ",'percent'):def_popwin_size(40,40,"Default Parameter setting for $soc_name ",'percent');
	my $table = def_table(10, 7, TRUE);
	
	my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);
	$scrolled_win->set_policy( "automatic", "automatic" );
	$scrolled_win->add_with_viewport($table);
	my $row=0;
	
	my $top=$mpsoc->mpsoc_get_soc($soc_name);
	
	#read soc parameters
	my %param_value=(defined $tile) ? $top->top_get_custom_soc_param($tile)  : $top->top_get_default_soc_param();
	
	
	
	my @insts=$top->top_get_all_instances();
	my @exceptions=get_NI_instance_list($top);
	@insts=get_diff_array(\@insts,\@exceptions);
	foreach my $inst (@insts){
		my @params=$top->top_get_parameter_list($inst);
		foreach my $p (@params){	
			my  ($default,$type,$content,$info,$global_param,$redefine)=$top->top_get_parameter($inst,$p);
			
			if ($type eq "Entry"){
				my $entry=gen_entry($param_value{$p});
				$table->attach_defaults ($entry, 3, 6, $row, $row+1);
				$entry-> signal_connect("changed" => sub{$param_value{$p}=$entry->get_text();});
			}
			elsif ($type eq "Combo-box"){
				my @combo_list=split(",",$content);
				my $pos=get_item_pos($param_value{$p}, @combo_list) if(defined $param_value{$p});
				my $combo=gen_combo(\@combo_list, $pos);
				$table->attach_defaults ($combo, 3, 6, $row, $row+1);
				$combo-> signal_connect("changed" => sub{$param_value{$p}=$combo->get_active_text();});
				
			}
			elsif 	($type eq "Spin-button"){ 
			  	my ($min,$max,$step)=split(",",$content);
			  	$param_value{$p}=~ s/\D//g;
			  	$min=~ s/\D//g;
			  	$max=~ s/\D//g;	
		  		$step=~ s/\D//g;
		  		my $spin=gen_spin($min,$max,$step);
		  		$spin->set_value($param_value{$p});
		  		$table->attach_defaults ($spin, 3, 4, $row, $row+1);
		  		$spin-> signal_connect("value_changed" => sub{$param_value{$p}=$spin->get_value_as_int();});
		 
		 # $box=def_label_spin_help_box ($param,$info, $value,$min,$max,$step, 2);
			}
			my $label =gen_label_in_center($p);
			$table->attach_defaults ($label, 0, 3, $row, $row+1);
			if (defined $info){
			my $info_button=def_image_button('icons/help.png');
			$table->attach_defaults ($info_button, 6, 7, $row, $row+1);	
			$info_button->signal_connect('clicked'=>sub{
				message_dialog($info);
				
			});
			
		}		
				
			$row++;
						
		
		}
	}
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	my $ok = def_image_button('icons/select.png','OK');
	my $okbox=def_hbox(TRUE,0);
	$okbox->pack_start($ok, FALSE, FALSE,0);
	
	
	my $mtable = def_table(10, 1, TRUE);

	$mtable->attach_defaults($scrolled_win,0,1,0,9);
	$mtable->attach_defaults($okbox,0,1,9,10);
	
	$window->add ($mtable);
	$window->show_all();
	
	$ok-> signal_connect("clicked" => sub{ 
		$window->destroy;
		#save new values 
		if(!defined $tile ) {
			$top->top_add_default_soc_param(\%param_value);
		}
		else {
			$top->top_add_custom_soc_param(\%param_value,$tile);				
			
		}
		#set_gui_status($mpsoc,"refresh_soc",1);
		#$$refresh_soc->clicked;
		
		});
	
	
	
}
	






################
#	tile_set_widget
################

sub tile_set_widget{
	my ($mpsoc,$soc_name,$num,$table,$show,$row)=@_;
	#my $lable=gen_label_in_left($soc);
	my @all_num= $mpsoc->mpsoc_get_soc_tiles_num($soc_name);
	my $init=compress_nums(@all_num);
	my $entry;
	if (defined $init){$entry=gen_entry($init) ;}
	else			  {$entry=gen_entry();}
	my $set= def_image_button('icons/right.png');
	my $remove= def_image_button('icons/cancel.png');
	#my $setting= def_image_button('icons/setting.png','setting');
	
			
	my $button = def_colored_button($soc_name,$num);
	$button->signal_connect("clicked"=> sub{
		get_soc_parameter_setting($mpsoc,$soc_name,undef);
		
	});	
	
	
	$set->signal_connect("clicked"=> sub{
		my $data=$entry->get_text();
		check_inserted_ip_nums($mpsoc,$soc_name,$data);
		
		
		
	});
	$remove->signal_connect("clicked"=> sub{
		$mpsoc->mpsoc_remove_soc($soc_name);
		set_gui_status($mpsoc,"ref",1);

	});

	
if($show){
	$table->attach ( $button, 0, 1, $row,$row+1,'fill','fill',2,2);
	$table->attach ( $remove, 1, 2, $row,$row+1,'fill','shrink',2,2);
	$table->attach ( $entry , 2, 3, $row,$row+1,'fill','shrink',2,2);	
	$table->attach ( $set, 3, 4, $row,$row+1,'fill','shrink',2,2);
	

		
	$row++;
}		
	
	return $row;	
	
	
}		





##################
#	defualt_tilles_setting
###################

sub defualt_tilles_setting {
	my ($mpsoc,$table,$show,$row,$info)=@_;
		
	#title	
	my $separator1 = Gtk2::HSeparator->new;
	my $separator2 = Gtk2::HSeparator->new;
	my $title2=gen_label_in_center("Tile Configuration");
	my $box1=def_vbox(FALSE, 1);
	$box1->pack_start( $separator1, FALSE, FALSE, 3);
	$box1->pack_start( $title2, FALSE, FALSE, 3);
	$box1->pack_start( $separator2, FALSE, FALSE, 3);
	if($show){$table->attach_defaults ($box1 ,0,4, $row,$row+1);$row++;}
	
	
	
	
	my $label = gen_label_in_left("Tiles path:");
	my $entry = Gtk2::Entry->new;
	my $browse= def_image_button("icons/browse.png");
	my $file= $mpsoc->object_get_attribute('setting','soc_path');
	if(defined $file){$entry->set_text($file);}
	
	
	$browse->signal_connect("clicked"=> sub{
		my $entry_ref=$_[1];
 		my $file;





        my $dialog = Gtk2::FileChooserDialog->new(
            	'Select tile directory', undef,
		#       	'open',
		'select-folder',
            	'gtk-cancel' => 'cancel',
            	'gtk-ok'     => 'ok',
        	);
       
        	
        	if ( "ok" eq $dialog->run ) {
            		$file = $dialog->get_filename;
			$$entry_ref->set_text($file);
			$mpsoc->object_add_attribute('setting','soc_path',$file);
			$mpsoc->mpsoc_remove_all_soc();
			set_gui_status($mpsoc,"ref",1);			
			#check_input_file($file,$socgen,$info);
            		#print "file = $file\n";
       		 }
       		$dialog->destroy;
       		


	} , \$entry);
	
	
	
	
	$entry->signal_connect("activate"=>sub{
		my $file_name=$entry->get_text();
		$mpsoc->object_add_attribute('setting','soc_path',$file_name);
		$mpsoc->mpsoc_remove_all_soc();	
		set_gui_status($mpsoc,"ref",1);	
		#check_input_file($file_name,$socgen,$info);
	});
		
	
	
	if($show){
		my $tmp=gen_label_in_left(" "); 
		$table->attach  ($label, 0, 1 , $row,$row+1,'fill','shrink',2,2);
		$table->attach ($tmp, 1, 2 , $row,$row+1,'fill','shrink',2,2);		
		$table->attach ($entry, 2, 3 , $row,$row+1,'fill','shrink',2,2);
		$table->attach ($browse, 3, 4, $row,$row+1,'fill','shrink',2,2);
		$row++;
	}
	
	
	
	my @socs=$mpsoc->mpsoc_get_soc_list();
	if( scalar @socs == 0){		
		@socs=get_soc_list($mpsoc,$info); 
				
	}
	@socs=$mpsoc->mpsoc_get_soc_list();
	
	
	
	my $lab1=gen_label_in_center(' Tile name');
	
	my $lab2=gen_label_help('Define the tile numbers that each IP is mapped to.
you can add individual numbers or ranges as follow 
	eg: 0,2,5:10
	', ' Tile numbers ');
	if($show){
		$table->attach_defaults ($lab1 ,0,1, $row,$row+1);
		$table->attach_defaults ($lab2 ,2,3, $row,$row+1);$row++;
	}	
	
	my $soc_num=0;
	foreach my $soc_name (@socs){	
		$row=tile_set_widget ($mpsoc,$soc_name,$soc_num,$table,$show,$row);	
		$soc_num++;		
		
	}	
	return $row;
	
}




#######################
#   noc_config
######################

sub noc_config{
	my ($mpsoc,$table)=@_;
	

	
	#title	
	my $row=0;
	my $title=gen_label_in_center("NoC Configuration");
	$table->attach ($title , 0, 4,  $row, $row+1,'expand','shrink',2,2); $row++;
	my $separator = Gtk2::HSeparator->new;	
	$table->attach ($separator , 0, 4 , $row, $row+1,'fill','fill',2,2);	$row++;

	my $label;
	my $param;
	my $default;
	my $type;
	my $content;
	my $info;
	
	
	#parameter start
	my $b1;
	my $show_noc=$mpsoc->object_get_attribute('setting','show_noc_setting');
	if(!defined $show_noc){
		$show_noc=1;
		$mpsoc->object_add_attribute('setting','show_noc_setting',$show_noc);
		
	}
	if($show_noc == 0){	
		$b1= def_image_button("icons/down.png","NoC Parameters");
		$label=gen_label_in_center(' ');
		$table->attach  ( $label , 2, 3, $row,$row+1 ,'fill','shrink',2,2);
		$table->attach  ( $b1 , 0, 2, $row,$row+1,'fill','shrink',2,2);
		$row++;	
	}
	
	
	#Router type
	$label='Router Type';
	$param='ROUTER_TYPE';
	$default='"VC_BASED"';
	$content='"INPUT_QUEUED","VC_BASED"';
	$type='Combo-box';
    $info="    Input-queued: simple router with low performance and does not support fully adaptive routing.
    VC-based routers offer higher performance, fully adaptive routing  and traffic isolation for different packet classes."; 
	$row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,$show_noc,'noc_type',1);
	my $router_type=$mpsoc->object_get_attribute('noc_type',"ROUTER_TYPE");
	
	#topology
	$label='Topology';
	$param='TOPOLOGY';
	$default='"MESH"';
	$content='"MESH","TORUS","RING","LINE"';
	$type='Combo-box';
    $info="NoC topology"; 
	$row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,$show_noc,'noc_param',1);
			
	my $topology=$mpsoc->object_get_attribute('noc_param','TOPOLOGY');
	
	#Routers per row
	$label= 'Routers per row';
	$param= 'NX';
    $default=' 2';
	$content=($topology eq '"MESH"' || $topology eq '"TORUS"') ? '2,16,1':'2,64,1';
    $info= 'Number of NoC routers in row (X dimention)';
    $type= 'Spin-button';             
	$row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,$show_noc,'noc_param',1);
	

	
	#Routers per column
	if($topology eq '"MESH"' || $topology eq '"TORUS"') {
		$label= 'Routers per column';
		$param= 'NY';
	    $default=' 2';
		$content='2,16,1';
	    $info= 'Number of NoC routers in column (Y dimention)';
	    $type= 'Spin-button';             
		$row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,$show_noc,'noc_param',1);
	} else {
		$mpsoc->object_add_attribute('noc_param','NY',1);		
	}
	
	#VC number per port
	if($router_type eq '"VC_BASED"'){	
		my $v=$mpsoc->object_get_attribute('noc_param','V');
		if(defined $v){ $mpsoc->object_add_attribute('noc_param','V',2) if($v eq 1);}
		$label='VC number per port';
		$param='V';
		$default='2';
		$type='Spin-button';
		$content='2,16,1';
		$info='Number of Virtual Channel per each router port';
		$row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,$show_noc,'noc_param',1);
	} else {
		$mpsoc->object_add_attribute('noc_param','V',1);
		$mpsoc->object_add_attribute('noc_param','C',0);		
	}
	
	#buffer width per VC
	$label=($router_type eq '"VC_BASED"')? 'Buffer flits per VC': "Buffer flits";
 	$param='B';
    $default='4';                                  
    $content='2,256,1';
    $type='Spin-button';
 	$info=($router_type eq '"VC_BASED"')?  'Buffer queue size per VC in flits' : 'Buffer queue size in flits';
    $row= noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,$show_noc,'noc_param',undef);
	
	#packet payload width
	$label='payload width';
	$param='Fpay';
	$default='32';   	
	$content='32,256,32';
	$type='Spin-button';
    $info="The packet payload width in bits"; 
	$row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info,$table,$row,$show_noc,'noc_param',undef);


	#routing algorithm
	$label='Routing Algorithm';
	$param="ROUTE_NAME";
	$type="Combo-box";
	if($router_type eq '"VC_BASED"'){
		$content=($topology eq '"MESH"')?  '"XY","WEST_FIRST","NORTH_LAST","NEGETIVE_FIRST","ODD_EVEN","DUATO"' :
				 ($topology eq '"TORUS"')? '"TRANC_XY","TRANC_WEST_FIRST","TRANC_NORTH_LAST","TRANC_NEGETIVE_FIRST","TRANC_DUATO"':
				 ($topology eq '"RING"')? '"TRANC_XY"' : '"XY"';
				  
	
	}else{
		$content=($topology eq '"MESH"')?  '"XY","WEST_FIRST","NORTH_LAST","NEGETIVE_FIRST","ODD_EVEN"' :
				 ($topology eq '"TORUS"')? '"TRANC_XY","TRANC_WEST_FIRST","TRANC_NORTH_LAST","TRANC_NEGETIVE_FIRST"':
				 ($topology eq '"RING"')? '"TRANC_XY"' : '"XY"';
	
		
	}
	$default=($topology eq '"MESH"' || $topology eq '"LINE"' )?  '"XY"':'"TRANC_XY"';
	$info="Select the routing algorithm: XY(DoR) , partially adaptive (Turn models). Fully adaptive (Duato) "; 
	$row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,$show_noc,'noc_param',1);


	#SSA
	$label='SSA Ebable'; 
	$param='SSA_EN';
	$default='"NO"';
	$content='"YES","NO"';
	$type='Combo-box';
	$info="Enable single cycle latency on packets traversing in the same direction using static straight allocator (SSA)"; 
	$row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,$show_noc,'noc_param',undef);


	

	if($show_noc == 1){	
		$b1= def_image_button("icons/up.png","NoC Parameters");
		$table->attach  ( $b1 , 0, 2, $row,$row+1,'fill','shrink',2,2);
		$row++;	
	}
	$b1->signal_connect("clicked" => sub{ 
		$show_noc=($show_noc==1)?0:1;
		$mpsoc->object_add_attribute('setting','show_noc_setting',$show_noc);
		set_gui_status($mpsoc,"ref",1);
	});


	#advance parameter start
	my $advc;
	my $adv_set=$mpsoc->object_get_attribute('setting','show_adv_setting');
	if($adv_set == 0){	
		$advc= def_image_button("icons/down.png","Advance Parameters");
		$table->attach ( $advc , 0, 2, $row,$row+1,'fill','shrink',2,2);
		$row++;	
	}
	
	
	#Fully and partially adaptive routing setting
	my $route=$mpsoc->object_get_attribute('noc_param',"ROUTE_NAME");
	$label="Congestion index";	
	$param="CONGESTION_INDEX";
	$type="Spin-button";
	$content="0,12,1";
	$info="Congestion index determines how congestion information is collected from neighboring routers. Please refer to the usere manual for more information";
	$default=3;
	if($route ne '"XY"' and $route ne '"TRANC_XY"' ){
	   	$row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,$adv_set,'noc_param',undef);
	} else {
		$row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,0,'noc_param',undef);
	}
	
	#Fully adaptive routing setting
	my $v=$mpsoc->object_get_attribute('noc_param',"V");
	$label="Select Escap VC";	
	$param="ESCAP_VC_MASK";
	$type="Check-box";
	$content=$v;
	$default="$v\'b";
	for (my $i=1; $i<=$v-1; $i++){$default=  "${default}0";}
	$default=  "${default}1";
	$info="Select the escap VC for fully adaptive routing.";
	if( $route eq '"TRANC_DUATO"' or $route eq '"DUATO"'  ){
	  	 $row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,$adv_set, 'noc_param',undef);
	 }
	else{
		 $row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,0, 'noc_param',undef);
	}
		
	# VC reallocation type
	$label=($router_type eq '"VC_BASED"')? 'VC reallocation type': 'Queue reallocation type';	
	$param='VC_REALLOCATION_TYPE';
    $info="VC reallocation type: If set as atomic only empty VCs can be allocated for new packets. Whereas, in non-atomic a non-empty VC which has received the last packet tail flit can accept a new  packet"; 
    $default='"NONATOMIC"';  
    $content='"ATOMIC","NONATOMIC"';
    $type='Combo-box';
    $row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,$adv_set,'noc_param',undef);                                           


	#vc/sw allocator type
	$label = 'VC/SW combination type';
	$param='COMBINATION_TYPE';
    $default='"COMB_NONSPEC"';
    $content='"BASELINE","COMB_SPEC1","COMB_SPEC2","COMB_NONSPEC"';
    $type='Combo-box';
    $info="The joint VC/ switch allocator type. using canonical combination is not recommanded";   
	if ($router_type eq '"VC_BASED"'){                 
	    $row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,$adv_set,'noc_param',undef);                   
	} else{
		 $row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,0,'noc_param',undef);  
	}
	
	# Crossbar mux type 
	$label='Crossbar mux type';
	$param='MUX_TYPE';
	$default='"BINARY"';
	$content='"ONE_HOT","BINARY"';
	$type='Combo-box';
	$info="Crossbar multiplexer type";
    $row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,$adv_set,'noc_param',undef);             
    
    #class   
	if($router_type eq '"VC_BASED"'){
		$label='class number';
		$param='C';
		$default= 0;
		$info='Number of message classes. Each specific class can use different set of VC'; 
		$content='0,16,1';
	    $type='Spin-button';
	    $row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,$adv_set,'noc_param',5);                             
		

		my $class=$mpsoc->object_get_attribute('noc_param',"C");
		my $v=$mpsoc->object_get_attribute('noc_param',"V");
		$default= "$v\'b";
		for (my $i=1; $i<=$v; $i++){
			$default=  "${default}1";
		}	
		#print "\$default=$default\n";
		for (my $i=0; $i<=$class-1; $i++){
			
			 $label="Class $i Permitted VCs";	
		  	 $param="Cn_$i";
		  	 $type="Check-box";
		  	 $content=$v;
		  	 $info="Select the permitted VCs which the message class $i can be sent via them.";
		  	 $row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,$adv_set,'class_param',undef);
		}
	
	}#($router_type eq '"VC_BASED"')
	 
	 

	#simulation debuge enable     
	$label='Debug enable';
	$param='DEBUG_EN';
    $info= "Add extra verilog code for debuging NoC for simulation";
	$default='0';
	$content='0,1';
	$type='Combo-box';
	$row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,$adv_set,'noc_param');  

	
	#pipeline reg	
	$label="Add pipeline reg after crossbar";	
	$param="ADD_PIPREG_AFTER_CROSSBAR";
	$type="Check-box";
	$content=1;
	$default="1\'b0";
	$info="If enabeled it adds a pipline register at the output port of the router.";
	$row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,$adv_set,'noc_param');
	 
	#FIRST_ARBITER_EXT_P_EN
	$label='Swich allocator first level 
arbiters extenal priority enable';
	$param='FIRST_ARBITER_EXT_P_EN';
	$default= 1;
	$info='If set as 1 then the switch allocator\'s input (first) arbiters\' priority registers are enabled only when a request get both input and output arbiters\' grants'; 
	$content='0,1';
	$type="Combo-box";
	$row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info,$table,$row,$adv_set,'noc_param');     
	  	
	
	#Arbiter type
	$label='SW allocator arbiteration type'; 
	$param='SWA_ARBITER_TYPE';
	$default='"RRA"';
	$content='"RRA","WRRA"'; #,"WRRA_CLASSIC"';
	$type='Combo-box';
    $info="Switch allocator arbitertion type: 
    RRA: Round robin arbiter. Only local fairness in a router. 
    WRRA: Weighted round robin arbiter. Results in global fairness in the NoC. 
          Switch allocation requests are grated acording to their weight which increases due to contention"; 
	$row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,$adv_set,'noc_param',1);
	
	  	
	
    my $arbiter=$mpsoc->object_get_attribute('noc_param',"SWA_ARBITER_TYPE");
    my $wrra_show = ($arbiter ne  '"RRA"' && $adv_set == 1 )? 1 : 0;
	# weight width
	$label='Weight width';
	$param='WEIGHTw';
	$default='4';
	$content='2,7,1';
	$info= 'Maximum weight width';
	$type= 'Spin-button';  
	$row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,$wrra_show,'noc_param',undef);  
	
	#WRRA_CONFIG_INDEX
	$label='Weight configuration index';
	$param='WRRA_CONFIG_INDEX';
	$default='0';
	$content='0,7,1';
	$info= 'WRRA_CONFIG_INDEX:

';
	$type= 'Spin-button';  
	#$row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,$wrra_show,'noc_param',undef);  
	
	
	
	if($adv_set == 1){	
		$advc= def_image_button("icons/up.png","Advance Parameters");
		$table->attach ( $advc , 0, 2, $row,$row+1,'fill','shrink',2,2);
		$row++;
	}
	$advc->signal_connect("clicked" => sub{ 
		$adv_set=($adv_set==1)?0:1;
		$mpsoc->object_add_attribute('setting','show_adv_setting',$adv_set);
		set_gui_status($mpsoc,"ref",1);
	});
	
	
	#other fixed parameters       
	
               
    
	    
	
	   
	
	# AVC_ATOMIC_EN
	$label='AVC_ATOMIC_EN';
	$param='AVC_ATOMIC_EN';
	$default= 0;
	$info='AVC_ATOMIC_EN'; 
	$content='0,1';
	$type="Combo-box";
	$row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,0,'noc_param');
	
	
	#ROUTE_SUBFUNC
	$label='ROUTE_SUBFUNC';
	$param='ROUTE_SUBFUNC';
	$default= '"XY"';
	$info='ROUTE_SUBFUNC'; 
	$content='"XY"';
	$type="Combo-box";
	$row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,0,'noc_param');
	
	return $row;
}




















#######################
#   get_config
######################

sub get_config{
	my ($mpsoc,$info)=@_;
	my $table=def_table(20,10,FALSE);#	my ($row,$col,$homogeneous)=@_;
	#my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);
	#$scrolled_win->set_policy( "automatic", "automatic" );
	#$scrolled_win->add_with_viewport($table);

	#noc_setting
	my $row=noc_config ($mpsoc,$table);
	
		
	#tile setting 
	my $tile_set;
	my $show=$mpsoc->object_get_attribute('setting','show_tile_setting');
	
	if($show == 0){	
		$tile_set= def_image_button("icons/down.png","Tiles setting");
		$table->attach ( $tile_set , 0, 2, $row,$row+1,'fill','shrink',2,2);
		$row++;
	
	}
	
	
	
	
	
	$row=defualt_tilles_setting($mpsoc,$table,$show,$row,$info);
	
	

	


	

	#end tile setting
	if($show == 1){	
		$tile_set= def_image_button("icons/up.png","Tiles setting");
		$table->attach ( $tile_set , 0, 2, $row,$row+1,'fill','shrink',2,2);
		$row++;
	}
	$tile_set->signal_connect("clicked" => sub{ 
		$show=($show==1)?0:1;
		$mpsoc->object_add_attribute('setting','show_tile_setting',$show);
		set_gui_status($mpsoc,"ref",1);


	});



	
	#for(my $i=$row; $i<25; $i++){
		#my $empty_col=gen_label_in_left(' ');
		#$table->attach_defaults ($empty_col , 0, 1, $i,$i+1);

	#}
	
	   




return  $table;

}


#############
#
###########




sub gen_all_tiles{
	my ($mpsoc,$info, $hw_dir,$sw_dir)=@_;
	my $nx= $mpsoc->object_get_attribute('noc_param',"NX");
	my $ny= $mpsoc->object_get_attribute('noc_param',"NY");
	my $mpsoc_name=$mpsoc->object_get_attribute('mpsoc_name');
	my $target_dir  = "$ENV{'PRONOC_WORK'}/MPSOC/$mpsoc_name";
	
	
	
	
	
	my @generated_tiles;
	
	#print "nx=$nx,ny=$ny\n";
	for (my $y=0;$y<$ny;$y++){for (my $x=0; $x<$nx;$x++){
		
		my $tile_num= $y*$nx+$x;
		#print "$tile_num\n";
		my ($soc_name,$num)= $mpsoc->mpsoc_get_tile_soc_name($tile_num);
		my $path=$mpsoc->object_get_attribute('setting','soc_path');	
		$path=~ s/ /\\ /g;
  		my $p = "$path/$soc_name.SOC";
		my  $soc = eval { do $p };
		if ($@ || !defined $soc){		
			show_info(\$info,"**Error reading  $p file: $@\n");
		       next; 
		} 
		
		#update core id
		$soc->object_add_attribute('global_param','CORE_ID',$tile_num);
		#update NoC param
		#my %nocparam = %{$mpsoc->object_get_attribute('noc_param',undef)};
		my $nocparam =$mpsoc->object_get_attribute('noc_param',undef);
		my $top=$mpsoc->mpsoc_get_soc($soc_name);
		my @nis=get_NI_instance_list($top);
		$soc->soc_add_instance_param($nis[0] ,$nocparam );
		#foreach my $p ( sort keys %nocparam ) {
			
		#	print "$p = $nocparam{$p} \n";
		#}

		my $sw_path 	= "$sw_dir/tile$tile_num";
		#print "$sw_path\n";
		if( grep (/^$soc_name$/,@generated_tiles)){ # This soc is generated before only create the software file
			generate_soc($soc,$info,$target_dir,$hw_dir,$sw_path,0,0);
		}else{
			generate_soc($soc,$info,$target_dir,$hw_dir,$sw_path,0,1);
			move ("$hw_dir/$soc_name.v","$hw_dir/tiles/"); 	
			
		}	
	
	
	}}
	
	
}


################
#	generate_soc
#################

sub generate_soc_files{
	my ($mpsoc,$soc,$info)=@_;
	my $mpsoc_name=$mpsoc->object_get_attribute('mpsoc_name');
	my $soc_name=$soc->object_get_attribute('soc_name');
	
	# copy all files in project work directory
	my $dir = Cwd::getcwd();
	my $project_dir	  = abs_path("$dir/../../");
	#make target dir
	my $target_dir  = "$ENV{'PRONOC_WORK'}/MPSOC/$mpsoc_name";
	mkpath("$target_dir/src_verilog/lib/",1,0755);
	mkpath("$target_dir/src_verilog/tiles/",1,0755);
	mkpath("$target_dir/sw",1,0755);

	my ($file_v,$tmp)=soc_generate_verilog($soc,"$target_dir/sw");
		
	# Write object file
	open(FILE,  ">lib/soc/$soc_name.SOC") || die "Can not open: $!";
	print FILE perl_file_header("$soc_name.SOC");
	print FILE Data::Dumper->Dump([\%$soc],['soc']);
	close(FILE) || die "Error closing file: $!";
		
	# Write verilog file
	open(FILE,  ">lib/verilog/$soc_name.v") || die "Can not open: $!";
	print FILE $file_v;
	close(FILE) || die "Error closing file: $!";
			
			
			
			
	
    		
    #copy hdl codes in src_verilog
    	
    my ($hdl_ref,$warnings)= get_all_files_list($soc,"hdl_files");
    foreach my $f(@{$hdl_ref}){
	
    	my $n="$project_dir$f";
    	 if (-f "$n") {
    		 	copy ("$n","$target_dir/src_verilog/lib"); 		
    	 }elsif(-f "$f" ){
    		 	copy ("$f","$target_dir/src_verilog/lib"); 		
    			 	
    	 }
    			
    		
    }
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
    		
    		
    		move ("$dir/lib/verilog/$soc_name.v","$target_dir/src_verilog/tiles/"); 	
    		copy_noc_files($project_dir,"$target_dir/src_verilog/lib");
    		
    		
    		# Write header file
			generate_header_file($soc,$project_dir,$target_dir,$target_dir,$dir);
			
    		
    				
			
			
			#use File::Copy::Recursive qw(dircopy);
			#dircopy("$dir/../src_processor/aeMB/compiler","$target_dir/sw/") or die("$!\n");
			
			
			my $msg="SoC \"$soc_name\" has been created successfully at $target_dir/ ";
			
		
		
		
return $msg;	
}	


sub generate_mpsoc_lib_file {
	my ($mpsoc,$info) = @_;
	my $name=$mpsoc->object_get_attribute('mpsoc_name');
	$mpsoc->mpsoc_remove_all_soc_tops(); 
	open(FILE,  ">lib/mpsoc/$name.MPSOC") || die "Can not open: $!";
	print FILE perl_file_header("$name.MPSOC");
	print FILE Data::Dumper->Dump([\%$mpsoc],['mpsoc']);
	close(FILE) || die "Error closing file: $!";
	get_soc_list($mpsoc,$info); 
	
}	


################
#	generate_mpsoc
#################

sub generate_mpsoc{
	my ($mpsoc,$info)=@_;
	my $name=$mpsoc->object_get_attribute('mpsoc_name');
	my $error = check_verilog_identifier_syntax($name);
	if ( defined $error ){
		message_dialog("The \"$name\" is given with an unacceptable formatting. The mpsoc name will be used as top level verilog module name so it must follow Verilog identifier declaration formatting:\n $error");
		return 0;
	}
	my $size= (defined $name)? length($name) :0;
	if ($size ==0) {
		message_dialog("Please define the MPSoC name!");
		return 0;
	}
	
	# make target dir
	my $dir = Cwd::getcwd();
	my $target_dir  = "$ENV{'PRONOC_WORK'}/MPSOC/$name";
	my $hw_dir 	= "$target_dir/src_verilog";
	my $sw_dir 	= "$target_dir/sw";
	
	mkpath("$hw_dir/lib/",1,0755);
	mkpath("$hw_dir/tiles",1,0755);
	mkpath("$sw_dir",1,0755);
	
	
	#generate/copy all tiles HDL/SW codes
	gen_all_tiles($mpsoc,$info, $hw_dir,$sw_dir );
		
	#copy all NoC HDL files
	
	my @files = glob( "$dir/../src_noc/*.v" );
	copy_file_and_folders(\@files,$dir,"$hw_dir/lib/");  
	
	
		
	my ($file_v,$top_v)=mpsoc_generate_verilog($mpsoc,$sw_dir);
	
	
		
	# Write object file
	generate_mpsoc_lib_file($mpsoc,$info);
			
	# Write verilog file
	open(FILE,  ">lib/verilog/$name.v") || die "Can not open: $!";
	print FILE $file_v;
	close(FILE) || die "Error closing file: $!";
			
	my $l=autogen_warning().get_license_header("${name}_top.v");
	open(FILE,  ">lib/verilog/${name}_top.v") || die "Can not open: $!";
	print FILE "$l\n$top_v";
	close(FILE) || die "Error closing file: $!";		
			
		
	
    		
    #gen_socs($mpsoc,$info);
    move ("$dir/lib/verilog/$name.v","$target_dir/src_verilog/");
    move ("$dir/lib/verilog/${name}_top.v","$target_dir/src_verilog/"); 
    
    #generate makefile
    open(FILE,  ">$sw_dir/Makefile") || die "Can not open: $!";
	print FILE mpsoc_sw_make();
	close(FILE) || die "Error closing file: $!";
	
	#generate prog_mem
    open(FILE,  ">$sw_dir/program.sh") || die "Can not open: $!";
	print FILE mpsoc_mem_prog();
	close(FILE) || die "Error closing file: $!";
    
    
   
    	 	
    message_dialog("SoC \"$name\" has been created successfully at $target_dir/ " );
		
		
		
return 1;	
}	

sub mpsoc_sw_make {
	 my $make='
 SUBDIRS := $(wildcard */.)
 all: $(SUBDIRS)
 $(SUBDIRS):
	$(MAKE) -C $@

 .PHONY: all $(SUBDIRS) 
	
 clean:
	$(MAKE) -C $(CODE_DIR) clean	
';
return $make;
	
}


sub mpsoc_mem_prog {
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
for i in $(ls -d */); do 
	cd ${i%%/}
	sh write_memory.sh 
	cd ..
done
 
#Enable the cpu
$JTAG_INTFC -n 127  -d  "I:1,D:2:0,I:0"
# I:1  set jtag_enable  in active mode
# D:2:0 load jtag_enable data register with 0x0 reset=0 disable=0
# I:0  set jtag_enable  in bypass mode
';
return $string;
	
}


sub get_tile_LIST{
 	my ($mpsoc,$x,$y,$soc_num,$row,$table)=@_;
	my $instance_name=$mpsoc->mpsoc_get_instance_info($soc_num);	
	if(!defined $instance_name){
		$mpsoc->mpsoc_set_default_ip($soc_num);
		$instance_name=$mpsoc->mpsoc_get_instance_info($soc_num);	

	}

	#ipname
	my $col=0;
	my $label=gen_label_in_left("IP_$soc_num($x,$y)");
	$table->attach_defaults ( $label, $col, $col+1 , $row, $row+1);$col+=2;
	#instance name
	my $entry=gen_entry($instance_name);
	$table->attach_defaults ( $entry, $col, $col+1 , $row, $row+1);$col+=2;
	$entry->signal_connect( 'changed'=> sub{
		my $new_instance=$entry->get_text();
		$mpsoc->mpsoc_set_ip_inst_name($soc_num,$new_instance);
		set_gui_status($mpsoc,"ref",20);
		print "changed to  $new_instance\n ";	

	});


	#combo box
	my @list=('A','B');
	my $combo=gen_combo(\@list,0);
	$table->attach_defaults ( $combo, $col, $col+1 , $row, $row+1);$col+=2;
	#setting
	my $setting= def_image_button("icons/setting.png","Browse");
	$table->attach_defaults ( $setting, $col, $col+1 , $row, $row+1);$col+=2;


}




##########
#
#########

sub gen_tiles_LIST{
	my ($mpsoc)=@_;

	my $nx= $mpsoc->object_get_attribute('noc_param',"NX");
	my $ny= $mpsoc->object_get_attribute('noc_param',"NY");

	# print "($nx,$ny);\n";
	my $table=def_table($nx*$ny,4,FALSE);#	my ($row,$col,$homogeneous)=@_;
	my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);
	$scrolled_win->set_policy( "automatic", "automatic" );
	$scrolled_win->add_with_viewport($table);


    my @titles=("IP_num(x,y)","Instance name","IP module name","setting");
	my $col=0;
    my $row=0;
	foreach my$p(@titles){
		my $label=gen_label_in_left($p);
	    $table->attach_defaults ($label, $col, $col+1 , $row, $row+1);$col++;
		my $sepv = Gtk2::VSeparator->new;		
		$table->attach_defaults ($sepv, $col , $col+1 ,0 , 2*($nx*$ny)+2 );$col++;
		
	}$row+=2;
	

	$col=0;
	for (my $y=0;$y<$ny;$y++){
		
		

		for (my $x=0; $x<$nx;$x++){
			my $soc_num= $y*$nx+$x;
			my $seph = Gtk2::HSeparator->new;
			$table->attach_defaults ($seph, 0, 8 , $row, $row+1);$row++;
			get_tile($mpsoc,$x,$y,$soc_num,$row,$table);$row++;
					
			


	}}
	my $seph = Gtk2::HSeparator->new;
	$table->attach_defaults ($seph, 0, 8 , $row, $row+1);$row++;

   while( $row<30){
		my $label=gen_label_in_left(' ');
	    $table->attach_defaults ($label, $col, $col+1 , $row, $row+1);$row++;



	}


	return $scrolled_win;
}









sub get_tile{
	my ($mpsoc,$tile,$x,$y)=@_;
	

	my ($soc_name,$num)= $mpsoc->mpsoc_get_tile_soc_name($tile);
	
	my $button;
	my $topology=$mpsoc->object_get_attribute('noc_param','TOPOLOGY');
	my $cordibate =	 ($topology eq '"RING"' || $topology eq '"LINE"' ) ? "" : "($x,$y)";
	if( defined $soc_name){
		my $setting=$mpsoc->mpsoc_get_tile_param_setting($tile);
		$button=($setting eq 'Custom')? def_colored_button("Tile $tile ${cordibate}*\n$soc_name",$num) :	def_colored_button("Tile $tile ${cordibate}\n$soc_name",$num) ;
	}else {
		$button =def_colored_button("Tile $tile ${cordibate}\n",50) if(! defined $soc_name);
	}
	
	$button->signal_connect("clicked" => sub{ 
		my $window = def_popwin_size(40,40,"Parameter setting for Tile $tile ",'percent');
		my $table = def_table(6, 2, TRUE);
	
		my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);
		$scrolled_win->set_policy( "automatic", "automatic" );
		$scrolled_win->add_with_viewport($table);
		my $row=0;
		my ($soc_name,$g,$t)=$mpsoc->mpsoc_get_tile_soc_name($tile);
		
		
		my @socs=$mpsoc->mpsoc_get_soc_list();
		my @list=(' ',@socs);
		my $pos=(defined $soc_name)? get_scolar_pos($soc_name,@list): 0;
		my $combo=gen_combo(\@list, $pos);
		my $lable=gen_label_in_left("  SoC name:");
		$table->attach_defaults($lable,0,3,$row,$row+1);
		$table->attach_defaults($combo,3,7,$row,$row+1);$row++;
		my $separator1 = Gtk2::HSeparator->new;
		$table->attach_defaults($separator1,0,7,$row,$row+1);$row++;
		
		my $ok = def_image_button('icons/select.png','OK');
		my $okbox=def_hbox(TRUE,0);
		$okbox->pack_start($ok, FALSE, FALSE,0);
		
		
		
		my $param_setting=$mpsoc->mpsoc_get_tile_param_setting($tile);
		@list=('Default','Custom');
		$pos=(defined $param_setting)? get_scolar_pos($param_setting,@list): 0;
		my $nn=(defined $soc_name)? $soc_name : 'soc';
		my ($box2,$combo2)=gen_combo_help("Defualt: the tail will get  defualt parameter setting of $nn.\n Custom: it will allow custom parameter  setting for this tile only." , \@list, $pos);
		my $lable2=gen_label_in_left("  Parameter Setting:");
		$table->attach_defaults($lable2,0,3,$row,$row+1);
		$table->attach_defaults($box2,3,7,$row,$row+1);$row++;
		$combo2->signal_connect('changed'=>sub{
			my $in=$combo2->get_active_text();
			$mpsoc->mpsoc_set_tile_param_setting($tile,$in);
				
		
		});
		
			
				
		
		
		$combo->signal_connect('changed'=>sub{
			my $new_soc=$combo->get_active_text();
			if ($new_soc eq ' '){
				#unconnect tile
				$mpsoc->mpsoc_set_tile_free($tile);
			}else {
				$mpsoc->mpsoc_set_tile_soc_name($tile,$new_soc);
			}
			
			
			
		});
		
		
		
		
	
	
		my $mtable = def_table(10, 1, TRUE);

		$mtable->attach_defaults($scrolled_win,0,1,0,9);
		$mtable->attach_defaults($okbox,0,1,9,10);
	
		$window->add ($mtable);
		$window->show_all();
	
		$ok-> signal_connect("clicked" => sub{ 
			$window->destroy;
			set_gui_status($mpsoc,"refresh_soc",1);
			my $soc_name=$combo->get_active_text();
			my $setting=$combo2->get_active_text();
			if ($soc_name ne ' ' && $setting ne 'Default'){
			get_soc_parameter_setting ($mpsoc,$soc_name,$tile);
			
			}
			#save new values 
			#$top->top_add_default_soc_param(\%param_value);
			#set_gui_status($mpsoc,"refresh_soc",1);
			#$$refresh_soc->clicked;
		
			});
	
	});
	
	
	#$button->show_all;
	return $button;


}


	
		
					



##########
#
#########

sub gen_tiles{
	my ($mpsoc)=@_;

	my $nx= $mpsoc->object_get_attribute('noc_param',"NX");
	my $ny= $mpsoc->object_get_attribute('noc_param',"NY");

	#print "($nx,$ny);\n";
	my $table=def_table($nx,$ny,FALSE);#	my ($row,$col,$homogeneous)=@_;
	



	
	

	for (my $y=0;$y<$ny;$y++){
		for (my $x=0; $x<$nx;$x++){
			my $tile_num=($nx*$y)+ $x; 
			my $tile=get_tile($mpsoc,$tile_num,$x,$y);
		#print "($x,$y);\n";
		$table->attach_defaults ($tile, $x, $x+1 , $y, $y+1);


	}}
	return $table;
}






sub software_edit_mpsoc {
	my $self=shift;	
	my $name=$self->object_get_attribute('mpsoc_name');
	if (length($name)==0){
		message_dialog("Please define the MPSoC name!");
		return ;
	}
	my $target_dir  = "$ENV{'PRONOC_WORK'}/MPSOC/$name/sw";
	my $sw 	= "$target_dir";
	my ($app,$table,$tview) = software_main($sw);

	


	my $make = def_image_button('icons/gen.png','Compile');
	
		
	$table->attach ($make,9, 10, 1,2,'shrink','shrink',0,0);
	

	$make -> signal_connect("clicked" => sub{
		$app->do_save();
		apend_to_textview($tview,' ');
		run_make_file($sw,$tview);	

	});

}



#############
#	load_mpsoc
#############

sub load_mpsoc{
	my ($mpsoc,$info)=@_;
	my $file;
	my $dialog = Gtk2::FileChooserDialog->new(
            	'Select a File', undef,
            	'open',
            	'gtk-cancel' => 'cancel',
            	'gtk-ok'     => 'ok',
        	);

	my $filter = Gtk2::FileFilter->new();
	$filter->set_name("MPSoC");
	$filter->add_pattern("*.MPSOC");
	$dialog->add_filter ($filter);
		my $dir = Cwd::getcwd();
	$dialog->set_current_folder ("$dir/lib/mpsoc")	;
	my @newsocs=$mpsoc->mpsoc_get_soc_list();
	add_info(\$info,'');
	if ( "ok" eq $dialog->run ) {
		$file = $dialog->get_filename;
		my ($name,$path,$suffix) = fileparse("$file",qr"\..[^.]*$");
		if($suffix eq '.MPSOC'){
			my $pp= eval { do $file };
			if ($@ || !defined $pp){		
				add_info(\$info,"**Error: cannot open $file file: $@\n");
				 $dialog->destroy;
				return;
			} 
			

			clone_obj($mpsoc,$pp);
			#read save mpsoc socs
			my @oldsocs=$mpsoc->mpsoc_get_soc_list();
			#add exsiting SoCs and add them to mpsoc
			
			my $error;
			#print "old: @oldsocs\n new @newsocs \n"; 
			foreach my $p (@oldsocs) {
				#print "$p\n";
				my @num= $mpsoc->mpsoc_get_soc_tiles_num($p);
				if (scalar @num && ( grep (/^$p$/,@newsocs)==0)){
					my $m="Processing tile $p that has been used for ties  @num but is not located in librray anymore\n";
				 	$error = (defined $error ) ? "$error $m" : $m;
				} 
				$mpsoc->mpsoc_remove_soc ($p) if (grep (/^$p$/,@newsocs)==0); 
				 	

			}
			@newsocs=get_soc_list($mpsoc,$info); # add all existing socs
			add_info(\$info,"**Error:  \n $error\n") if(defined $error);

			set_gui_status($mpsoc,"load_file",0);
					
		}					
     }
     $dialog->destroy;
}

############
#    main
############
sub mpsocgen_main{
	
	my $infc = interface->interface_new(); 
	my $soc = ip->lib_new ();
	my $mpsoc= mpsoc->mpsoc_new();
	
	
	set_gui_status($mpsoc,"ideal",0);
	
	my $main_table = Gtk2::Table->new (25, 12, FALSE);
	
	# The box which holds the info, warning, error ...  mesages
	my ($infobox,$info)= create_text();	
		
	my $noc_conf_box=get_config ($mpsoc,$info);
	my $noc_tiles=gen_tiles($mpsoc);

	my $scr_conf = new Gtk2::ScrolledWindow (undef, undef);
	$scr_conf->set_policy( "automatic", "automatic" );
	$scr_conf->add_with_viewport($noc_conf_box);
	
	my $scr_tile = new Gtk2::ScrolledWindow (undef, undef);
	$scr_tile->set_policy( "automatic", "automatic" );
	$scr_tile->add_with_viewport($noc_tiles);

	$main_table->set_row_spacings (4);
	$main_table->set_col_spacings (1);
	
		
	my $generate = def_image_button('icons/gen.png','Generate RTL');
	my $open = def_image_button('icons/browse.png','Load MPSoC');
	my $compile  = def_image_button('icons/gate.png','Compile RTL');
	my $software = def_image_button('icons/binary.png','Software');
	my $entry=gen_entry_object($mpsoc,'mpsoc_name',undef,undef,undef,undef);
	my $entrybox=labele_widget_info(" MPSoC name:",$entry);
	
	my $h1=gen_hpaned($scr_conf,.3,$scr_tile);
	my $v2=gen_vpaned($h1,.55,$infobox);

	$main_table->attach_defaults ($v2  , 0, 12, 0,24);
	$main_table->attach ($open,0, 3, 24,25,'expand','shrink',2,2);
	$main_table->attach_defaults ($entrybox,3, 7, 24,25);
	$main_table->attach ($generate, 8, 9, 24,25,'expand','shrink',2,2);
	$main_table->attach ($software, 9, 10, 24,25,'expand','shrink',2,2);	
	$main_table->attach ($compile, 10, 12, 24,25,'expand','shrink',2,2);

	


	#check soc status every 0.5 second. referesh device table if there is any changes 
	Glib::Timeout->add (100, sub{ 
		my ($state,$timeout)= get_gui_status($mpsoc);
		

		if ($timeout>0){
			$timeout--;
			set_gui_status($mpsoc,$state,$timeout);						
		}elsif ($state eq 'save_project'){
			# Write object file
			my $name=$mpsoc->object_get_attribute('mpsoc_name');
			open(FILE,  ">lib/mpsoc/$name.MPSOC") || die "Can not open: $!";
			print FILE perl_file_header("$name.MPSOC");
			print FILE Data::Dumper->Dump([\%$mpsoc],[$name]);
			close(FILE) || die "Error closing file: $!";
			set_gui_status($mpsoc,"ideal",0);	
		}
		elsif( $state ne "ideal" ){
			$noc_conf_box->destroy();
			$noc_conf_box=get_config ($mpsoc,$info);
			$scr_conf->add_with_viewport($noc_conf_box);
			$noc_tiles->destroy();
			$noc_tiles=gen_tiles($mpsoc);
			$scr_tile->add_with_viewport($noc_tiles);
			$h1 -> pack1($scr_conf, TRUE, TRUE); 	
			$h1 -> pack2($scr_tile, TRUE, TRUE); 		
			$v2-> pack1($h1, TRUE, TRUE); 	
			$h1->show_all;
			$main_table->show_all();
			my $saved_name=$mpsoc->object_get_attribute('mpsoc_name');
			if(defined $saved_name) {$entry->set_text($saved_name);}
			set_gui_status($mpsoc,"ideal",0);
			
			
		}	
		return TRUE;
		
	} );
		
		
	$generate-> signal_connect("clicked" => sub{ 
		generate_mpsoc($mpsoc,$info);
		set_gui_status($mpsoc,"refresh_soc",1);

	});


	$open-> signal_connect("clicked" => sub{ 
		set_gui_status($mpsoc,"ref",5);
		load_mpsoc($mpsoc,$info);
	
	});


	$compile -> signal_connect("clicked" => sub{ 
		$mpsoc->object_add_attribute('compile','compilers',"QuartusII,Verilator,Modelsim");
		my $name=$mpsoc->object_get_attribute('mpsoc_name');
		if (length($name)==0){
			message_dialog("Please define the MPSoC name!");
			return ;
		}
		my $target_dir  = "$ENV{'PRONOC_WORK'}/MPSOC/$name";
		my $top_file 	= "$target_dir/src_verilog/${name}_top.v";
		if (-f $top_file){	
			select_compiler($mpsoc,$name,$top_file,$target_dir);
		} else {
			message_dialog("Cannot find $top_file file. Please run RTL Generator first!");
			return;
		}
	});	
	
	$software -> signal_connect("clicked" => sub{
		software_edit_mpsoc($mpsoc);

	});

	
	my $sc_win = new Gtk2::ScrolledWindow (undef, undef);
		$sc_win->set_policy( "automatic", "automatic" );
		$sc_win->add_with_viewport($main_table);	

	return $sc_win;
	

}








