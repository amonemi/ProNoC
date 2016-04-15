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
use File::Find;
use File::Copy;

use Cwd 'abs_path';


use Gtk2;
use Gtk2::Pango;




require "widget.pl"; 
require "mpsoc_verilog_gen.pl";
require "hdr_file_gen.pl";


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
	 my ($mpsoc,$name,$param, $default,$type,$content,$info, $state,$table,$row,$show)=@_;
	 my $label =gen_label_in_left(" $name");
	 my $widget;
	 my $value=$mpsoc->mpsoc_get_param($param);
	 if(! defined $value) {
			$mpsoc->mpsoc_add_param($param,$default);
			$mpsoc->mpsoc_add_param_order($param);
			$value=$default;
	 }
	 if ($type eq "Entry"){
		$widget=gen_entry($value);
		$widget-> signal_connect("changed" => sub{
			my $new_param_value=$widget->get_text();
			$mpsoc->mpsoc_add_param($param,$new_param_value);
			set_state($state,"ref",10);

		});
		
		
	 }
	 elsif ($type eq "Combo-box"){
		 my @combo_list=split(",",$content);
		 my $pos=get_pos($value, @combo_list);
		 if(!defined $pos){
		 	$mpsoc->mpsoc_add_param($param,$default);	
		 	$pos=get_item_pos($default, @combo_list);
		 		 	
		 }
		#print " my $pos=get_item_pos($value, @combo_list);\n";
		 $widget=gen_combo(\@combo_list, $pos);
		 $widget-> signal_connect("changed" => sub{
		 my $new_param_value=$widget->get_active_text();
		 $mpsoc->mpsoc_add_param($param,$new_param_value);
		 set_state($state,"ref",1);


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
		  $widget-> signal_connect("changed" => sub{
		  my $new_param_value=$widget->get_value_as_int();
		  $mpsoc->mpsoc_add_param($param,$new_param_value);
		  set_state($state,"ref",1);

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
				$mpsoc->mpsoc_add_param($param,$default);
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
				$mpsoc->mpsoc_add_param($param,$new_val);
				#print "\$new_val=$new_val\n";
				set_state($state,"ref",1);
			});
		}




	}
	else {
		 $widget =gen_label_in_left("unsuported widget type!");
	}

	my $inf_bt= gen_button_message ($info,"icons/help.png");
	if($show==1){
		my $tmp=gen_label_in_left(" "); 
		$table->attach_defaults ($label , 0, 4,  $row,$row+1);
		$table->attach_defaults ($inf_bt , 4, 5, $row,$row+1);
		$table->attach_defaults ($widget , 5, 9, $row,$row+1);
		$table->attach_defaults ($tmp , 9, 10, $row,$row+1);
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
		my @exceptions=('ni0');
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
	my $mpsoc=shift;

	my $path=$mpsoc->mpsoc_get_setting('soc_path');	
	$path =~ s/ /\\ /g;
    	my @socs;
	my @files = glob "$path/*.SOC";
	for my $p (@files){
		
		# Read
		my  $soc = eval { do $p };
		my $top=$soc->soc_get_top();
		if (defined $top){
			my @instance_list=$top->top_get_all_instances();
			#check if the soc has ni port
			foreach my $instanc(@instance_list){
				my $module=$top->top_get_def_of_instance($instanc,'module');
				if($module eq 'ni') 
				{
					my $name=$soc->soc_get_soc_name();			
					$mpsoc->mpsoc_add_soc($name,$top);
					#print" $name\n";
				}		
			}			
		
		}
		
		
		
		
		
		#my @instance_list=$soc->soc_get_all_instances();
		#my $i=0;
		
		#check if the soc has ni port
		#foreach my $instanc(@instance_list){
		#	my $module=$soc->soc_get_module($instanc);
		#	if($module eq 'ni') 
		#	{
		#		my $name=$soc->soc_get_soc_name();			
		#		$mpsoc->mpsoc_add_soc($name,$soc);
		#		#print" $name\n";
		#	} 
		#}	
		
		
	}#files
	
	# initial  default soc parameter
	initial_default_param($mpsoc);
	
	
	
	return $mpsoc->mpsoc_get_soc_list;



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
	my ($mpsoc,$name,$inserted,$conflicts,$msg,$state)=@_;
	$msg="\tThe inserted tile number(s) have been mapped previously to \n\t\t\"$msg\".\n\tDo you want to remove the conflicted tiles number(s) in newly \n\tinsterd range or remove them from the previous ones? ";
	
	my $wind=def_popwin_size(100,300,"warning");
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
		set_state($state,"ref",1);		
		$wind->destroy();
			
	});
	
	$b2->signal_connect( "clicked"=> sub{#Remove Current
		my @new= get_diff_array($inserted,$conflicts);	
		$mpsoc->mpsoc_add_soc_tiles_num($name,\@new) if(scalar @new  );
		$mpsoc->mpsoc_add_soc_tiles_num($name,undef) if(scalar @new ==0 );
		set_state($state,"ref",1);		
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
	my  ($mpsoc,$name,$str,$state)=@_;
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
	my $nx= $mpsoc->mpsoc_get_param("NX");
	my $ny= $mpsoc->mpsoc_get_param("NY");
	
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
		get_conflict_decision($mpsoc,$name,\@all_num,\@conflicts,$conflicts_msg,$state);
		
	}else {
		#save the entered ips
		if( scalar @all_num>0){ $mpsoc->mpsoc_add_soc_tiles_num($name,\@all_num);}
		else {$mpsoc->mpsoc_add_soc_tiles_num($name,undef);}
		set_state($state,"ref",1);
	}
	


}




#################
# get_soc_parameter_setting
################

sub get_soc_parameter_setting{
	my ($mpsoc,$soc_name,$state,$tile)=@_;
	
	my $window = (defined $tile)? def_popwin_size(600,400,"Parameter setting for $soc_name located in tile($tile) "):def_popwin_size(600,400,"Default Parameter setting for $soc_name ");
	my $table = def_table(10, 7, TRUE);
	
	my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);
	$scrolled_win->set_policy( "automatic", "automatic" );
	$scrolled_win->add_with_viewport($table);
	my $row=0;
	
	my $top=$mpsoc->mpsoc_get_soc($soc_name);
	
	#read soc parameters
	my %param_value=(defined $tile) ? $top->top_get_custom_soc_param($tile)  : $top->top_get_default_soc_param();
	
	
	
	my @insts=$top->top_get_all_instances();
	my @exceptions=('ni0');
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
				my $pos=get_item_pos($param_value{$p}, @combo_list);
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
		  		$spin-> signal_connect("changed" => sub{$param_value{$p}=$spin->get_value_as_int();});
		 
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
	#my @parameters=$ip->ip_get_module_parameters($category,$module);
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
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
		#set_state($soc_state,"refresh_soc",1);
		#$$refresh_soc->clicked;
		
		});
	
	
	
}
	






################
#	tile_set_widget
################

sub tile_set_widget{
	my ($mpsoc,$soc_name,$num,$table,$state,$show,$row)=@_;
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
		get_soc_parameter_setting($mpsoc,$soc_name,$state,undef);
		
	});	
	
	
	$set->signal_connect("clicked"=> sub{
		my $data=$entry->get_text();
		check_inserted_ip_nums($mpsoc,$soc_name,$data,$state);
		
		
		
	});
	$remove->signal_connect("clicked"=> sub{
		$mpsoc->mpsoc_remove_soc($soc_name);
		set_state($state,"ref",1);

	});

	
if($show){
	$table->attach_defaults ( $button, 0, 4, $row,$row+1);
	$table->attach_defaults ( $remove, 4, 5, $row,$row+1);
	$table->attach_defaults ( $entry , 5, 9, $row,$row+1);	
	$table->attach_defaults ( $set, 9, 10, $row,$row+1);
	

		
	$row++;
}		
	
	return $row;	
	
	
}		





##################
#	defualt_tilles_setting
###################

sub defualt_tilles_setting {
	my ($mpsoc,$state,$table,$show,$row)=@_;
		
	#title	
	my $separator1 = Gtk2::HSeparator->new;
	my $separator2 = Gtk2::HSeparator->new;
	my $title2=gen_label_in_center("Tile Configuration");
	my $box1=def_vbox(FALSE, 1);
	$box1->pack_start( $separator1, FALSE, FALSE, 3);
	$box1->pack_start( $title2, FALSE, FALSE, 3);
	$box1->pack_start( $separator2, FALSE, FALSE, 3);
	if($show){$table->attach_defaults ($box1 ,0,10, $row,$row+1);$row++;}
	
	
	
	
	my $label = gen_label_in_left("Tiles path:");
	my $entry = Gtk2::Entry->new;
	my $browse= def_image_button("icons/browse.png");
	my $file= $mpsoc->mpsoc_get_setting('soc_path');	
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
			$mpsoc->mpsoc_set_setting('soc_path',$file);
			$mpsoc->mpsoc_remove_all_soc();
			set_state($state,"ref",1);			
			#check_input_file($file,$socgen,$soc_state,$info);
            		#print "file = $file\n";
       		 }
       		$dialog->destroy;
       		


	} , \$entry);
	
	
	
	
	$entry->signal_connect("activate"=>sub{
		my $file_name=$entry->get_text();
		$mpsoc->mpsoc_set_setting('soc_path',$file_name);
		$mpsoc->mpsoc_remove_all_soc();	
		set_state($state,"ref",1);	
		#check_input_file($file_name,$socgen,$soc_state,$info);
	});
		
	
	
	if($show){
		my $tmp=gen_label_in_left(" "); 
		$table->attach_defaults ($label, 0, 4 , $row,$row+1);
		$table->attach_defaults ($tmp, 4, 5 , $row,$row+1);		
		$table->attach_defaults ($entry, 5, 9 , $row,$row+1);
		$table->attach_defaults ($browse, 9, 10, $row,$row+1);
		$row++;
	}
	
	
	
	my @socs=$mpsoc->mpsoc_get_soc_list();
	if( scalar @socs == 0){		
		@socs=get_soc_list($mpsoc); 
				
	}
	@socs=$mpsoc->mpsoc_get_soc_list();
	
	
	
	my $lab1=gen_label_in_center(' Tile name');
	
	my $lab2=gen_label_help('Define the tile numbers that each IP is mapped to.
you can add individual numbers or ranges as follow 
	eg: 0,2,5:10
	', ' Tile numbers ');
	if($show){
		$table->attach_defaults ($lab1 ,0,3, $row,$row+1);
		$table->attach_defaults ($lab2 ,5,10, $row,$row+1);$row++;
	}
	
	
	
	my $soc_num=0;
	foreach my $soc_name (@socs){	
		$row=tile_set_widget ($mpsoc,$soc_name,$soc_num,$table,$state,$show,$row);	
		$soc_num++;	
		
			
			
		
	}

	
	
	
	
	return $row;
	
	
}








#######################
#   noc_config
######################

sub noc_config{
	my ($mpsoc,$state)=@_;
	my $table=def_table(20,10,FALSE);#	my ($row,$col,$homogeneous)=@_;
	my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);
	$scrolled_win->set_policy( "automatic", "automatic" );
	$scrolled_win->add_with_viewport($table);

	
	#title	
	my $title=gen_label_in_center("NoC Configuration");
	my $box=def_vbox(FALSE, 1);
	$box->pack_start( $title, FALSE, FALSE, 3);
	my $separator = Gtk2::HSeparator->new;
	$box->pack_start( $separator, FALSE, FALSE, 3);
	$table->attach_defaults ($box , 0, 10, 0,1);

	my $label;
	my $param;
	my $default;
	my $type;
	my $content;
	my $info;
	my $row=1;
	
	#parameter start
	my $b1;
	my $show_noc=$mpsoc->mpsoc_get_setting('show_noc_setting');
	if($show_noc == 0){	
		$b1= def_image_button("icons/down.png","NoC Parameters");
		$label=gen_label_in_center(' ');
		$table->attach_defaults ( $label , 2, 10, $row,$row+1);	
		$table->attach_defaults ( $b1 , 0, 4, $row,$row+1);$row++;	
	}
	
	
	#Router type
	$label='Router Type';
	$param='ROUTER_TYPE';
	$default='"VC_BASED"';
	$content='"INPUT_QUEUED","VC_BASED"';
	$type='Combo-box';
    $info="    Input-queued: simple router with low performance and does not support fully adaptive routing.
    VC-based routers offer higher performance, fully adaptive routing  and traffic isolation for different packet classes."; 
	$row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $state,$table,$row,$show_noc);
	my $router_type=$mpsoc->mpsoc_get_param("ROUTER_TYPE");
	
	
	#P port number 
	$label= 'Port Number';
	$param= 'P';
    $default=' 5';
	$content='3,12,1';
    $info= 'Number of NoC router port';
    $type= 'Spin-button';             
	$row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $state,$table,$row,0);
	
	

	#Routers per row
	$label= 'Routers per row';
	$param= 'NX';
    $default=' 2';
	$content='2,16,1';
    $info= 'Number of NoC routers in row (X dimention)';
    $type= 'Spin-button';             
	$row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $state,$table,$row,$show_noc);
	


	#Routers per column
	$label= 'Routers per column';
	$param= 'NY';
    $default=' 2';
	$content='2,16,1';
    $info= 'Number of NoC routers in column (Y dimention)';
    $type= 'Spin-button';             
	$row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $state,$table,$row,$show_noc);

	if($router_type eq '"VC_BASED"'){
		#VC number per port
		my $v=$mpsoc->mpsoc_get_param('V');
		$mpsoc->mpsoc_add_param('V',2) if($v eq 1);
		$label='VC number per port';
		$param='V';
		$default='2';
		$type='Spin-button';
		$content='2,16,1';
		$info='Number of Virtual Channel per each router port';
		$row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $state,$table,$row,$show_noc);
	} else {
		$mpsoc->mpsoc_add_param('V',1);
		$mpsoc->mpsoc_add_param('C',0);
		
		
	}
	
	#buffer width per VC
	$label=($router_type eq '"VC_BASED"')? 'Buffer flits per VC': "Buffer flits";
 	$param='B';
    $default='4';                                  
    $content='2,256,1';
    $type='Spin-button';
 	$info=($router_type eq '"VC_BASED"')?  'Buffer queue size per VC in flits' : 'Buffer queue size in flits';
    $row= noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $state,$table,$row,$show_noc);
	
	#packet payload width
	$label='payload width';
	$param='Fpay';
	$default='32';   	
	$content='32,256,32';
	$type='Spin-button';
    $info="The packet payload width in bits"; 
	$row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $state,$table,$row,$show_noc);

	#topology
	$label='Topology';
	$param='TOPOLOGY';
	$default='"MESH"';
	$content='"MESH","TORUS"';
	$type='Combo-box';
    $info="NoC topology"; 
	$row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $state,$table,$row,$show_noc);

	#routing algorithm
	my $topology=$mpsoc->mpsoc_get_param('TOPOLOGY');
	$label='Routing Algorithm';
	$param="ROUTE_NAME";
	$type="Combo-box";
	if($router_type eq '"VC_BASED"'){
		$content=($topology eq '"MESH"')?  '"XY","WEST_FIRST","NORTH_LAST","NEGETIVE_FIRST","DUATO"' :
				   	   	    '"TRANC_XY","TRANC_WEST_FIRST","TRANC_NORTH_LAST","TRANC_NEGETIVE_FIRST","TRANC_DUATO"';
	
	}else{
		$content=($topology eq '"MESH"')?  '"XY","WEST_FIRST","NORTH_LAST","NEGETIVE_FIRST"' :
				   	   	    '"TRANC_XY","TRANC_WEST_FIRST","TRANC_NORTH_LAST","TRANC_NEGETIVE_FIRST"';
	
		
	}
	$default=($topology eq '"MESH"')?  '"XY"':'"TRANC_XY"';
	$info="Select the routing algorithm: XY(DoR) , partially adaptive (Turn models). Fully adaptive (Duato) "; 
	$row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $state,$table,$row,$show_noc);


	if($show_noc == 1){	
		$b1= def_image_button("icons/up.png","NoC Parameters");
		$table->attach_defaults ( $b1 , 0, 2, $row,$row+1);$row++;	
	}
	$b1->signal_connect("clicked" => sub{ 
		$show_noc=($show_noc==1)?0:1;
		$mpsoc->mpsoc_set_setting('show_noc_setting',$show_noc);
		set_state($state,"ref",1);

	});

	#advance parameter start
	my $advc;
	my $adv_set=$mpsoc->mpsoc_get_setting('show_adv_setting');
	if($adv_set == 0){	
		$advc= def_image_button("icons/down.png","Advance Parameters");
		$table->attach_defaults ( $advc , 0, 4, $row,$row+1);$row++;
	
	}
	
	
	
	#Fully and partially adaptive routing setting
		my $route=$mpsoc->mpsoc_get_param("ROUTE_NAME");
		if($route ne '"XY"' and $route ne '"TRANC_XY"' ){
			$label="Congestion index";	
			$param="CONGESTION_INDEX";
		   	$type="Spin-button";
		   	$content="0,12,1";
			$info="Congestion index determines how congestion information is collected from neighboring routers. Please refer to the usere manual for more information";
		    $default=3;
		   	$row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $state,$table,$row,$adv_set);
		   
		}
		#Fully adaptive routing setting
		if( $route eq '"TRANC_DUATO"' or $route eq '"DUATO"'  ){
		  	 my $v=$mpsoc->mpsoc_get_param("V");
		  	 $label="Select Escap VC";	
		  	 $param="ESCAP_VC_MASK";
		  	 $type="Check-box";
		  	 $content=$v;
		  	 $default="$v\'b";
		  	 for (my $i=1; $i<=$v-1; $i++){$default=  "${default}0";}
		  	 $default=  "${default}1";
			
		
		  	 $info="Select the escap VC for fully adaptive routing.";
		  	 $row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $state,$table,$row,$adv_set,$adv_set);
	  	
	  	 }
		
	# VC reallocation type
		$label=($router_type eq '"VC_BASED"')? 'VC reallocation type': 'Queue reallocation type';	
		$param='VC_REALLOCATION_TYPE';
                $info="VC reallocation type: If set as atomic only empty VCs can be allocated for new packets. Whereas, in non-atomic a non-empty VC which has received the last packet tail flit can accept a new  packet"; 
                $default='"NONATOMIC"';  
                $content='"ATOMIC","NONATOMIC"';
                $type='Combo-box';
                $row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $state,$table,$row,$adv_set);                                           




	if ($router_type eq '"VC_BASED"'){
	#vc/sw allocator type
		$label = 'VC/SW combination type';
 		$param='COMBINATION_TYPE';
                $default='"COMB_NONSPEC"';
                $content='"BASELINE","COMB_SPEC1","COMB_SPEC2","COMB_NONSPEC"';
                $type='Combo-box';
                $info="The joint VC/ switch allocator type. using canonical combination is not recommanded";                    
                $row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $state,$table,$row,$adv_set);                   

	}
	
	# Crossbar mux type 
		$label='Crossbar mux type';
		$param='MUX_TYPE';
		$default='"BINARY"';
		$content='"ONE_HOT","BINARY"';
		$type='Combo-box';
		$info="Crossbar multiplexer type";
        $row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $state,$table,$row,$adv_set);             
       
	if($router_type eq '"VC_BASED"'){
	#class
		$label='class number';
		$param='C';
		$default= 0;
		$info='Number of message classes. Each specific class can use different set of VC'; 
		$content='0,16,1';
	    $type='Spin-button';
	    $row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $state,$table,$row,$adv_set);                             
		

		my $class=$mpsoc->mpsoc_get_param("C");
		my $v=$mpsoc->mpsoc_get_param("V");
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
		  	 $row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $state,$table,$row,$adv_set);


		}


	
	}#($router_type eq '"VC_BASED"')
	 
	 

	 #simulation debuge enable     
		$label='Debug enable';
		$param='DEBUG_EN';
                $info= "Add extra verilog code for debuging NoC for simulation";
		$default='0';
                $content='0,1';
                $type='Combo-box';
                $row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $state,$table,$row,$adv_set);  



	
	
	$label="Add pipeline reg after crossbar";	
	$param="ADD_PIPREG_AFTER_CROSSBAR";
	$type="Check-box";
	$content=1;
	$default="1\'b0";
	$info="If ebabled it adds a pipline register at the output port of the router.";
	$row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $state,$table,$row,0);
	  	
	
	$label="Add pipeline reg befor crossbar";	
	$param="ADD_PIPREG_BEFORE_CROSSBAR";
	$type="Check-box";
	$content=1;
	$default="1\'b0";
	$info="If ebabled it adds a pipline register after the input memory sd ram.";
	$row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $state,$table,$row,0);
	  	

	
	if($adv_set == 1){	
		$advc= def_image_button("icons/up.png","Advance Parameters");
		$table->attach_defaults ( $advc , 0, 4, $row,$row+1);$row++;
	}
	$advc->signal_connect("clicked" => sub{ 
		$adv_set=($adv_set==1)?0:1;
		$mpsoc->mpsoc_set_setting('show_adv_setting',$adv_set);
		set_state($state,"ref",1);


	});
	
	
	#other fixed parameters       
	

	#FIRST_ARBITER_EXT_P_EN
	$label='FIRST_ARBITER_EXT_P_EN';
	$param='FIRST_ARBITER_EXT_P_EN';
	$default= 0;
	$info='FIRST_ARBITER_EXT_P_EN'; 
	$content='0,1';
	$type="Combo-box";
	$row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $state,$table,$row,0);         
	
	#ROUTE_TYPE
	$param='ROUTE_TYPE';
	$default='(ROUTE_NAME == "XY" || ROUTE_NAME == "TRANC_XY" )?    "DETERMINISTIC" : 
			 (ROUTE_NAME == "DUATO" || ROUTE_NAME == "TRANC_DUATO" )?   "FULL_ADAPTIVE": "PAR_ADAPTIVE"';
	$info='ROUTE_TYPE'; 
	$type="Entry";
	$row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $state,$table,$row,0);     
	
	# AVC_ATOMIC_EN
	$label='AVC_ATOMIC_EN';
	$param='AVC_ATOMIC_EN';
	$default= 0;
	$info='AVC_ATOMIC_EN'; 
	$content='0,1';
	$type="Combo-box";
	$row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $state,$table,$row,0);
	
	
	#ROUTE_SUBFUNC
	$label='ROUTE_SUBFUNC';
	$param='ROUTE_SUBFUNC';
	$default= '"XY"';
	$info='ROUTE_SUBFUNC'; 
	$content='"XY"';
	$type="Combo-box";
	$row=noc_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $state,$table,$row,0);
	
	#tile setting 
	my $tile_set;
	my $show=$mpsoc->mpsoc_get_setting('show_tile_setting');
	if($show == 0){	
		$tile_set= def_image_button("icons/down.png","Tiles setting");
		$table->attach_defaults ( $tile_set , 0, 4, $row,$row+1);$row++;
	
	}
	
	
	
	
	
	$row=defualt_tilles_setting($mpsoc,$state,$table,$show,$row);
	
	

	


	

	#end tile setting
	if($show == 1){	
		$tile_set= def_image_button("icons/up.png","Tiles setting");
		$table->attach_defaults ( $tile_set , 0, 1, $row,$row+1);$row++;
	}
	$tile_set->signal_connect("clicked" => sub{ 
		$show=($show==1)?0:1;
		$mpsoc->mpsoc_set_setting('show_tile_setting',$show);
		set_state($state,"ref",1);


	});



	
	for(my $i=$row; $i<25; $i++){
		my $empty_col=gen_label_in_left(' ');
		$table->attach_defaults ($empty_col , 0, 1, $i,$i+1);

	}
	
	   




return  $scrolled_win;

}


#############
#
###########

sub gen_socs {
	my ($mpsoc,$info)=@_;

	my $path=$mpsoc->mpsoc_get_setting('soc_path');	
	$path=~ s/ /\\ /g;
    	my @socs;
	my @files = glob "$path/*.SOC";
	my @soc_list=$mpsoc-> mpsoc_get_soc_list();
	my @used_socs;
	foreach my $soc_name (@soc_list){
		my @n=$mpsoc->mpsoc_get_soc_tiles_num($soc_name);
		if(scalar @n){
			#this soc has been used generate the verilog files of it
			push(@used_socs,$soc_name);			
		}		
	}
	
	for my $p (@files){
		# Read
		my  $soc = eval { do $p };
		my  $name=$soc->soc_get_soc_name();
		if( grep (/^$name$/,@used_socs)){
		#generate the soc
		generate_soc_files($mpsoc,$soc,$info);
		
		
		
		
		};
		
		
	}
		
		
}

################
#	generate_soc
#################

sub generate_soc_files{
	my ($mpsoc,$soc,$info)=@_;
	my $mpsoc_name=$mpsoc->mpsoc_get_mpsoc_name();
	my $soc_name=$soc->soc_get_soc_name();
	my $file_v=soc_generate_verilog($soc);
		
	# Write object file
	open(FILE,  ">lib/soc/$soc_name.SOC") || die "Can not open: $!";
	print FILE Data::Dumper->Dump([\%$soc],[$soc_name]);
	close(FILE) || die "Error closing file: $!";
		
	# Write verilog file
	open(FILE,  ">lib/verilog/$soc_name.v") || die "Can not open: $!";
	print FILE $file_v;
	close(FILE) || die "Error closing file: $!";
			
			
			
			
	# copy all files in project work directory
	my $dir = Cwd::getcwd();
	#make target dir
	my $project_dir	  = abs_path("$dir/../../");
	my $target_dir  = "$project_dir/mpsoc_work/MPSOC/$mpsoc_name";
	mkpath("$target_dir/src_verilog/lib/",1,0755);
	mkpath("$target_dir/src_verilog/tiles/",1,0755);
	mkpath("$target_dir/sw",1,0755);
    		
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
			my $file_h=generate_header_file($soc);
			open(FILE,  ">lib/verilog/$soc_name.h") || die "Can not open: $!";
			print FILE $file_h;
			close(FILE) || die "Error closing file: $!";
			
    		
    				
			move ("$dir/lib/verilog/$soc_name.h","$target_dir/sw/"); 
			
			#use File::Copy::Recursive qw(dircopy);
			#dircopy("$dir/../src_processor/aeMB/compiler","$target_dir/sw/") or die("$!\n");
			
			
			my $msg="SoC \"$soc_name\" has been created successfully at $target_dir/ ";
			
		
		
		
return $msg;	
}	


################
#	generate_mpsoc
#################

sub generate_mpsoc{
	my ($mpsoc,$info)=@_;
	my $name=$mpsoc->mpsoc_get_mpsoc_name();
		my $size= (defined $name)? length($name) :0;
		if ($size >0){
			my $file_v=mpsoc_generate_verilog($mpsoc);
			
			# Write object file
			open(FILE,  ">lib/mpsoc/$name.MPSOC") || die "Can not open: $!";
			print FILE Data::Dumper->Dump([\%$mpsoc],[$name]);
			close(FILE) || die "Error closing file: $!";
			
			# Write verilog file
			open(FILE,  ">lib/verilog/$name.v") || die "Can not open: $!";
			print FILE $file_v;
			close(FILE) || die "Error closing file: $!";
			
			
			
			
			# copy all files in project work directory
			my $dir = Cwd::getcwd();
			#make target dir
			my $project_dir	  = abs_path("$dir/../../");
			my $target_dir  = "$project_dir/mpsoc_work/MPSOC/$name";
			mkpath("$target_dir/src_verilog/lib/",1,0755);
			mkpath("$target_dir/sw",1,0755);
    		
    		gen_socs($mpsoc,$info);
    		
    		move ("$dir/lib/verilog/$name.v","$target_dir/src_verilog/"); 	
    		
    		
    		
    		
    		
			
			
			
			message_dialog("SoC \"$name\" has been created successfully at $target_dir/ " );
		
		}else {
			message_dialog("Please define the MPSoC name!");
			
		}	
		
return 1;	
}	




sub get_tile_LIST{
 	my ($mpsoc,$state,$x,$y,$soc_num,$row,$table)=@_;
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
		set_state($state,"ref",20);
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
	my ($mpsoc,$soc_state)=@_;

	my $nx= $mpsoc->mpsoc_get_param("NX");
	my $ny= $mpsoc->mpsoc_get_param("NY");

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
			get_tile($mpsoc,$soc_state,$x,$y,$soc_num,$row,$table);$row++;
					
			


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
	my ($mpsoc,$state,$tile,$x,$y)=@_;
	

	my ($soc_name,$num)= $mpsoc->mpsoc_get_tile_soc_name($tile);
	
	my $button;
	if( defined $soc_name){
		my $setting=$mpsoc->mpsoc_get_tile_param_setting($tile);
		$button=($setting eq 'Custom')? def_colored_button("Tile $tile ($x,$y)*\n$soc_name",$num) :	def_colored_button("Tile $tile ($x,$y)\n$soc_name",$num) ;
	}else {
		$button =def_colored_button("Tile $tile ($x,$y)\n",50) if(! defined $soc_name);
	}
	
	$button->signal_connect("clicked" => sub{ 
		my $window = def_popwin_size(400,400,"Parameter setting for Tile $tile ");
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
		my ($box2,$combo2)=gen_combo_help("Defualt: the tail will get  deafualt parameter setting of $nn.\n Custom: it will allow custom parameter  setting for this tile only." , \@list, $pos);
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
			set_state($state,"refresh_soc",1);
			my $soc_name=$combo->get_active_text();
			my $setting=$combo2->get_active_text();
			if ($soc_name ne ' ' && $setting ne 'Default'){
			get_soc_parameter_setting ($mpsoc,$soc_name,$state,$tile);
			
			}
			#save new values 
			#$top->top_add_default_soc_param(\%param_value);
			#set_state($soc_state,"refresh_soc",1);
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
	my ($mpsoc,$soc_state)=@_;

	my $nx= $mpsoc->mpsoc_get_param("NX");
	my $ny= $mpsoc->mpsoc_get_param("NY");

	#print "($nx,$ny);\n";
	my $table=def_table($nx,$ny,FALSE);#	my ($row,$col,$homogeneous)=@_;
	my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);
	$scrolled_win->set_policy( "automatic", "automatic" );
	$scrolled_win->add_with_viewport($table);



	
	

	for (my $y=0;$y<$ny;$y++){
		for (my $x=0; $x<$nx;$x++){
			my $tile_num=($nx*$y)+ $x; 
			my $tile=get_tile($mpsoc,$soc_state,$tile_num,$x,$y);
		#print "($x,$y);\n";
		$table->attach_defaults ($tile, $x, $x+1 , $y, $y+1);


	}}











############
#    main
############
sub mpsocgen_main{
	
	my $infc = interface->interface_new(); 
	my $soc = ip->lib_new ();
	#my $soc = soc->soc_new();

	my $mpsoc= mpsoc->mpsoc_new();
	#my $soc= eval { do 'lib/soc/soc.SOC' };
	
	my $soc_state=  def_state("ideal");
	# main window
	#my $window = def_win_size(1000,800,"Top");
	#  The main table containg the lib tree, selected modules and info section 
	my $main_table = Gtk2::Table->new (25, 12, FALSE);
	
	# The box which holds the info, warning, error ...  mesages
	my ($infobox,$info)= create_text();	
	
	
	my $refresh = Gtk2::Button->new_from_stock('ref');
	
	
	my $noc_conf_box=noc_config ($mpsoc,$soc_state);
	my $noc_tiles=gen_tiles($mpsoc,$soc_state);



	$main_table->set_row_spacings (4);
	$main_table->set_col_spacings (1);
	
	#my  $device_win=show_active_dev($soc,$soc,$infc,$soc_state,\$refresh,$info);
	
	
	my $generate = def_image_button('icons/gen.png','Generate');
	my $genbox=def_hbox(TRUE,0);
	$genbox->pack_start($generate,   FALSE, FALSE,0);
	
	
	
	my $open = def_image_button('icons/browse.png','Load MPSoC');
	my $openbox=def_hbox(TRUE,0);
	$openbox->pack_start($open,   FALSE, FALSE,0);
	
	
	
	my ($entrybox,$entry) = def_h_labeled_entry('MPSoC name:');
	$entry->signal_connect( 'changed'=> sub{
		my $name=$entry->get_text();
		$mpsoc->mpsoc_set_mpsoc_name($name);		
	});	
	
	#$table->attach_defaults ($event_box, $col, $col+1, $row, $row+1);
	$main_table->attach_defaults ($noc_conf_box , 0, 4, 0, 23);
	$main_table->attach_defaults ($noc_tiles , 4, 12, 0, 23);
	$main_table->attach_defaults ($infobox  , 0, 12, 23,24);
	$main_table->attach_defaults ($openbox,0, 3, 24,25);
	$main_table->attach_defaults ($entrybox,3, 7, 24,25);
	
	$main_table->attach_defaults ($genbox, 10, 12, 24,25);
	

	#referesh the mpsoc generator 
	$refresh-> signal_connect("clicked" => sub{ 
		$noc_conf_box->destroy();
		$noc_conf_box=noc_config ($mpsoc,$soc_state);
		$main_table->attach_defaults ($noc_conf_box , 0, 4, 0, 23);
		$noc_conf_box->show_all();			
		


		$noc_tiles->destroy();
		$noc_tiles=gen_tiles($mpsoc,$soc_state);
		$main_table->attach_defaults ($noc_tiles , 4, 12, 0, 23);

		$main_table->show_all();


	});



	#check soc status every 0.5 second. referesh device table if there is any changes 
	Glib::Timeout->add (100, sub{ 
	 
		my ($state,$timeout)= get_state($soc_state);

		if ($timeout>0){
			$timeout--;
			set_state($soc_state,$state,$timeout);		
		}
		elsif( $state ne "ideal" ){
			$refresh->clicked;
			my $saved_name=$mpsoc->mpsoc_get_mpsoc_name();
			if(defined $saved_name) {$entry->set_text($saved_name);}
			set_state($soc_state,"ideal",0);
			
		}	
		return TRUE;
		
	} );
		
		
	$generate-> signal_connect("clicked" => sub{ 
		generate_mpsoc($mpsoc,$info);
		$refresh->clicked;

	});

#	$wb-> signal_connect("clicked" => sub{ 
#		wb_address_setting($mpsoc);
#	
#	});

	$open-> signal_connect("clicked" => sub{ 
		set_state($soc_state,"ref",5);
		load_mpsoc($mpsoc,$soc_state);
	
	});	

	
	my $sc_win = new Gtk2::ScrolledWindow (undef, undef);
		$sc_win->set_policy( "automatic", "automatic" );
		$sc_win->add_with_viewport($main_table);	

	return $sc_win;
	

}




	return $scrolled_win;
}




#############
#	load_mpsoc
#############

sub load_mpsoc{
	my ($mpsoc,$soc_state)=@_;
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


	if ( "ok" eq $dialog->run ) {
		$file = $dialog->get_filename;
		my ($name,$path,$suffix) = fileparse("$file",qr"\..[^.]*$");
		if($suffix eq '.MPSOC'){
			my $pp= eval { do $file };
			clone_obj($mpsoc,$pp);
			set_state($soc_state,"load_file",0);		
		}					
     }
     $dialog->destroy;



	

}

##########

##########
sub copy_noc_files{
	my ($project_dir,$dest)=@_;
	
my @noc_files=('/mpsoc/src_noc/arbiter.v',
	'/mpsoc/src_noc/baseline.v',
	'/mpsoc/src_noc/canonical_credit_count.v',
	'/mpsoc/src_noc/class_table.v',
	'/mpsoc/src_noc/combined_vc_sw_alloc.v',
	'/mpsoc/src_noc/comb_nonspec.v',
	'/mpsoc/src_noc/comb_spec2.v',
	'/mpsoc/src_noc/comb-spec1.v',
	'/mpsoc/src_noc/congestion_analyzer.v',
	'/mpsoc/src_noc/credit_count.v',
	'/mpsoc/src_noc/crossbar.v',
	'/mpsoc/src_noc/flit_buffer.v',
	'/mpsoc/src_noc/inout_ports.v',
	'/mpsoc/src_noc/inout_ports.v.classic',
	'/mpsoc/src_noc/input_ports.v',
	'/mpsoc/src_noc/main_comp.v',
	'/mpsoc/src_noc/noc.v',
	'/mpsoc/src_noc/route_mesh.v',
	'/mpsoc/src_noc/router.v',
	'/mpsoc/src_noc/route_torus.v',
	'/mpsoc/src_noc/routing.v',
	'/mpsoc/src_noc/vc_alloc_request_gen.v');
	foreach my $f (@noc_files){
		copy ("$project_dir$f",$dest); 
		
	}
	
	
}	
