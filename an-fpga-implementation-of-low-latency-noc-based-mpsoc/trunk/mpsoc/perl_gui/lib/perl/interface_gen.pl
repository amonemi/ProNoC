#! /usr/bin/perl -w
use Glib qw/TRUE FALSE/;
use strict;
use warnings;
use Data::Dumper;
use intfc_gen;
use rvp;
use Gtk2;



require "widget.pl"; 


sub read_file_modules{
	my ($file,$intfc_gen,$soc_state,$info)=@_;
	
	if (!defined $file) {return; }
	if (-e $file) { 
		my $vdb =  read_file($file);
		my @modules=sort $vdb->get_modules($file);
		#foreach my $p(@module_list) {print "$p\n"}
		$intfc_gen->intfc_set_interface_file($file);
		$intfc_gen->intfc_set_module_name($modules[0]);
		$intfc_gen->intfc_add_module_list(@modules);
		
		set_state($soc_state,"file_selected",1);
		show_info(\$info,"Select the module which contain the interface ports\n ");	
	    
	}
	else { 
		show_info(\$info,"File $file doese not exsit!\n ");	
		
	}	
}	


################
#  check_input_intfc_file
################

sub check_input_intfc_file{
	my ($file,$intfc_gen,$soc_state,$info)=@_;
	my ($name,$path,$suffix) = fileparse("$file",qr"\..[^.]*$");
	if($suffix eq '.ITC'){
		$intfc_gen->intfc_set_interface_file($file);
		set_state($soc_state,"load_file",0);
		
		
	}else{
		read_file_modules($file,$intfc_gen,$soc_state,$info);
	
	}	
	
	
}	

sub file_box {
	my ($intfc_gen,$soc_state,$info,$table,$row)=@_;
	my $label = gen_label_in_left("Select file:");
	my $entry = Gtk2::Entry->new;
	my $open= def_image_button("icons/select.png","Open");
	my $browse= def_image_button("icons/browse.png","Browse");
	my $file= $intfc_gen->intfc_get_interface_file();
	my $intfc_info= def_image_button("icons/info.png","Description");
	$intfc_info->signal_connect("clicked"=> sub{
		get_intfc_description($intfc_gen,$soc_state,$info);
		
		
	});	
	
	if(defined $file){$entry->set_text($file);}
	show_info(\$info,"Please select the verilog file containig the interface\n");
	$browse->signal_connect("clicked"=> sub{
		my $entry_ref=$_[1];
 		my $file;
        my $dialog = Gtk2::FileChooserDialog->new(
            	'Select a File', undef,
            	'open',
            	'gtk-cancel' => 'cancel',
            	'gtk-ok'     => 'ok',
        	);

			my $filter = Gtk2::FileFilter->new();
			$filter->set_name("Verilog");
			$filter->add_pattern("*.v");
			my $filter2 = Gtk2::FileFilter->new();
			$filter2->set_name("Interface");
			$filter2->add_pattern("*.ITC");
			$dialog->add_filter ($filter);
			$dialog->add_filter ($filter2);


        	if ( "ok" eq $dialog->run ) {
            		$file = $dialog->get_filename;
					$$entry_ref->set_text($file);
					check_input_intfc_file($file,$intfc_gen,$soc_state,$info);
					#read_file_modules($file,$intfc_gen,$soc_state,$info);
            		#print "file = $file\n";
       		 }
       		$dialog->destroy;



	} , \$entry);
	
	$open->signal_connect("clicked"=> sub{
		my $file_name=$entry->get_text();
		check_input_intfc_file($file,$intfc_gen,$soc_state,$info);
		#read_file_modules($file_name,$intfc_gen,$soc_state,$info);
		
		});
	$entry->signal_connect("activate"=>sub{
		my $file_name=$entry->get_text();
		read_file_modules($file_name,$intfc_gen,$soc_state,$info);
	});
		
	$entry->signal_connect("changed"=>sub{
		show_info(\$info,"Please select the verilog file containig the interface\n");
	});
	
	$table->attach_defaults ($label, 0, 1 , $row, $row+1);
	$table->attach_defaults ($entry, 1, 7 , $row, $row+1);
	$table->attach_defaults ($browse, 7, 8, $row, $row+1);
	$table->attach_defaults ($intfc_info, 8, 9 , $row, $row+1);
	#$table->attach_defaults ($open,  9, 10, $row, $row+1);
	#$table->attach_defaults ($entry, $col, $col+1, $row, $row+1);
	#return $table;
	
	
}



sub get_ports_type{
	my ($vdb,$top_module)=@_;
	my %ports;
	
	foreach my $sig (sort $vdb->get_modules_signals($top_module)) {
	my ($line,$a_line,$i_line,$type,$file,$posedge,$negedge,
	 $type2,$s_file,$s_line,$range,$a_file,$i_file,$dims) = 
	   $vdb->get_module_signal($top_module,$sig);

		if($type eq "input" or $type eq "inout" or $type eq "output" ){
			$ports{$sig}=$type;
			
		}
	}
	return %ports;
}



sub get_ports_rang{
	my ($vdb,$top_module)=@_;
	my %ports;
	
	foreach my $sig (sort $vdb->get_modules_signals($top_module)) {
	my ($line,$a_line,$i_line,$type,$file,$posedge,$negedge,
	 $type2,$s_file,$s_line,$range,$a_file,$i_file,$dims) = 
	   $vdb->get_module_signal($top_module,$sig);

		if($type eq "input" or $type eq "inout" or $type eq "output" ){
		 
		
			
			$ports{$sig}=remove_all_white_spaces($range);
			
		}
	}
	return %ports;
}



sub get_interface_ports {
	my ($infc_gen,$soc_state,$info)=@_;
	my $window=def_popwin_size(800,600,"Import Ports");

	my $file=$infc_gen->intfc_get_interface_file();
	if (!defined $file){show_info(\$info,"File name has not been defined yet!");  return;}
	my $module=$infc_gen->intfc_get_module_name();
	if (!defined $module){  show_info(\$info,"Module name has not been selected yet!");  return;}
	my $vdb=read_file($file);
	my %port_type=get_ports_type($vdb,$module);
	my %port_range=get_ports_rang($vdb,$module);
	
	my $table=def_table(8,8,TRUE);
	my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);
	$scrolled_win->set_policy( "automatic", "automatic" );
	$scrolled_win->add_with_viewport($table);
	
	
	
	my $title=gen_label_in_center("Select the ports included in the interface");
	my $title1=gen_label_in_center("Type");
	my $title2=gen_label_in_center("Range");
	my $title3=gen_label_in_center("Name");
	my $title4=gen_label_in_center("Select");
	
	my $row	=0;
	$table->attach_defaults($title, 0,8, $row, $row+1); 
	$row++;
	$table->attach_defaults($title1, 0,1, $row, $row+1); 
	$table->attach_defaults($title2, 1,4, $row, $row+1); 
	$table->attach_defaults($title3, 4,7, $row, $row+1); 
	$table->attach_defaults($title4, 7,8, $row, $row+1); 
	
	my $separator = Gtk2::HSeparator->new;
	$row++;
	
	$table->attach_defaults($separator, 0,8, $row, $row+1); 
	
	$row++;
	$infc_gen->intfc_remove_ports();
	foreach my $p (sort keys %port_type){
		my $port_id= $p;
		my $porttype=$port_type{$p};
		my $label1= gen_label_in_center("$porttype");
		$table->attach_defaults($label1, 0,1, $row, $row+1); 
		my $portrange=$port_range{$p};
		if (  $port_range{$p} ne ''){
			
			my $label2= gen_label_in_center("\[$portrange\]");
			$table->attach_defaults($label2, 1,4, $row, $row+1);
		}
		
		my $label3= gen_label_in_center($p);
		$table->attach_defaults($label3, 4,7, $row, $row+1); 
		
		my $check= Gtk2::CheckButton->new;
		$table->attach_defaults($check, 7,8, $row, $row+1); 
		
		$row++;
		if($row>8){$table->resize ($row, 8);}
		#print "$p\:$port_type{$p}\n";
		
		$check->signal_connect("toggled"=>sub{
			my $widget=shift;
			my $in=$widget->get_active();
			if ($in eq 1){
				my $connect_type=($porttype eq "input")? "output" : ($porttype eq "output")? "input" : $porttype;
				$infc_gen->intfc_add_port($port_id,$porttype,$portrange,$p,$connect_type,$portrange,$p,"concatenate","Active low");
				
				
				
				#print "chanhed to $in \n";
			}else {
				$infc_gen->intfc_remove_port($port_id);
				
				#print "chanhed to 0 \n";
				
			}	
			
			
		});
		
	}
	
	
	my $ok= def_image_button("icons/select.png","ok");
	$table->attach_defaults($ok, 3,5, $row, $row+1); 
	
	$ok->signal_connect("clicked"=>sub{
		$window->destroy;
		set_state($soc_state,"refresh",1);
		
		
		});
	
	$window->add($scrolled_win);
	
	$window->show_all();
}	






sub module_select{
	my ($infc_gen,$soc_state,$info,$table,$row)=@_;
	my $file= $infc_gen->intfc_get_interface_file();
	my $label = gen_label_in_left("Select module:");
	
	my @modules= $infc_gen->intfc_get_module_list();
	my $saved_module=$infc_gen->intfc_get_module_name();
	my $pos=(defined $saved_module ) ? get_scolar_pos( $saved_module,@modules) : 0;
	my $combo = gen_combo(\@modules, $pos);
	my $port= def_image_button("icons/import.png","Import Ports");
	my $label2= gen_label_in_left(" Select Category:");
	my ($category,$category_entry)=gen_entry_help('Define the Interface category:e.g RAM, wishbone,...');
	my $saved_category=$infc_gen->intfc_get_category();
	if(defined $saved_category){$category_entry->set_text($saved_category);}
	
	
	$table->attach_defaults ($label, 0, 1 , $row, $row+1);
	$table->attach_defaults ($combo, 1, 3 , $row,$row+1);
	$table->attach_defaults ($port, 3, 4 , $row, $row+1);
	$table->attach_defaults ($label2, 4, 5 , $row, $row+1);
	$table->attach_defaults ($category, 5, 6 , $row, $row+1);
	
	
	
	$combo->signal_connect("changed"=> sub{
		my $module= $combo->get_active_text();
		$infc_gen->intfc_set_module_name($module);
		
		
	});
	
	$port->signal_connect("clicked"=> sub{
		get_interface_ports($infc_gen,$soc_state,$info);
		
		
	});	
	$category_entry->signal_connect("changed"=> sub{
		my $name=$category_entry->get_text();
		$infc_gen->intfc_set_category($name);
		
	});
	
	
	
	
	
}	

sub interface_type_select {
	my ($infc_gen,$soc_state,$info,$table,$row)=@_;	
	my $saved_intfc_type= $infc_gen->intfc_get_interface_type();
	my $label = gen_label_in_left("Interface name:");
	
	
	my $saved_name=$infc_gen->intfc_get_interface_name();
	my $entry=gen_entry($saved_name);
	
	$entry->signal_connect("changed"=>sub{
		my $widget=shift;
		my $name=$widget->get_text();
		$infc_gen->intfc_set_interface_name($name);
		set_state($soc_state,"refresh",50);
		
	}
	);
	
	my $saved_connection_num= $infc_gen->intfc_get_connection_num();
	my $label2 = gen_label_in_left("Select soket type:");
	
	my @connection_nums=("single connection","multi connection");
	my $pos;
	if(defined $saved_connection_num){
		$pos= get_scolar_pos( $saved_connection_num,@connection_nums);
	}
	else {
		$pos= 0;
		$infc_gen->intfc_set_connection_num($connection_nums[0]);
	}	 
	my $combo=gen_combo(\@connection_nums,$pos);
	
	$combo->signal_connect("changed"=>sub{
		my $widget=shift;
		my $connection_num=$widget->get_active_text();
		$infc_gen->intfc_set_connection_num($connection_num);
		set_state($soc_state,"refresh",1);
		
	});
	$table->attach_defaults ($label, 0, 1 , $row, $row+1);
	$table->attach_defaults ($entry, 1, 2 , $row, $row+1);
	$table->attach_defaults ($label2, 2, 3 , $row, $row+1);
	$table->attach_defaults ($combo, 3, 4 , $row, $row+1);
	
	
	
}	






sub port_select{
	my ($infc_gen,$soc_state,$info,$table,$row)=@_;	
	my(%types,%ranges,%names,%connect_types,%connect_ranges,%connect_names,%outport_types,%default_outs);
	$infc_gen->intfc_get_ports(\%types,\%ranges,\%names,\%connect_types,\%connect_ranges,\%connect_names,\%outport_types,\%default_outs);

	my $size = keys %types;
	if($size >0){
		my $sep = Gtk2::HSeparator->new;
		$table->attach_defaults ($sep, 0, 10 , $row, $row+1);	$row++;
		
		
		my $swap= def_image_button("icons/swap.png","swap");
			
		$swap->signal_connect('clicked'=>sub{
			my $type=$infc_gen->intfc_get_interface_type();
			if($type eq 'plug'){
					$infc_gen->intfc_set_interface_type('socket');
			}
			else {
					$infc_gen->intfc_set_interface_type('plug');
			}	
			set_state($soc_state,"refresh",1);			
			
		});
		
		
		my @intfcs=("plug","socket");
		my $inttype=$infc_gen->intfc_get_interface_type();
		if (!defined $inttype){
			$inttype='plug';
			$infc_gen->intfc_set_interface_type($inttype);
		}	
				
		#my $lab1= gen_label_in_center($inttype);
		my ($lab1,$lab2);
		if ($inttype eq 'plug'){
			$lab1=def_image_label('icons/plug.png'  ,'plug  ');
			$lab2=def_image_label('icons/socket.png','socket');
		}else {
			$lab2=def_image_label('icons/plug.png','plug');
			$lab1=def_image_label('icons/socket.png','socket');
			
		}	
		
		my $sep2 = Gtk2::HSeparator->new;
		
		
		$table->attach_defaults ($lab1, 1, 2 , $row, $row+1);	
		$table->attach_defaults ($swap, 3, 4 , $row, $row+1);
		$table->attach_defaults ($lab2, 5, 6 , $row, $row+1);	$row++;		
		$table->attach_defaults ($sep2, 0, 9 , $row, $row+1);	$row++;
		
		
		my $lab3= gen_label_in_center("Type");
		my $lab4= gen_label_in_center("Range");
		my $lab5= gen_label_in_center("Name");
		$table->attach_defaults ($lab3, 0, 1 , $row, $row+1);
		$table->attach_defaults ($lab4, 1, 2 , $row, $row+1);
		$table->attach_defaults ($lab5, 2, 3 , $row, $row+1); 
		my $lab6= gen_label_in_center("Type");
		my $lab7= gen_label_in_center("Range");
		my $lab8= gen_label_in_center("Name");
		$table->attach_defaults ($lab6, 4, 5 , $row, $row+1);
		$table->attach_defaults ($lab7, 5, 6 , $row, $row+1);
		$table->attach_defaults ($lab8, 6, 7 , $row, $row+1); 
		my $lab9= gen_label_help ("When an IP core does not have any of interface output port, the default value will be send to the IP core's input port which is supposed to be connected to that port","Output port Default ");
		$table->attach_defaults ($lab9, 8, 9 , $row, $row+1); 
		$row++;
	
		foreach my $id (sort keys %ranges){
			my $type=$types{$id};
			my $range=$ranges{$id};
			my $name=$names{$id};
			my $connect_type=$connect_types{$id};
			my $connect_range=$connect_ranges{$id};
			my $connect_name=$connect_names{$id};
			my $outport_type=$outport_types{$id};
			my $default_out=$default_outs{$id};
			if(! defined $default_out){
				$default_out = "Active low"; # port_width_repeat($connect_range,"1\'b0");
				$infc_gen->intfc_add_port($id,$type,$range,$name,$connect_type,$connect_range,$connect_name,$outport_type,$default_out);
				print "\$default_out is set to: $default_out\n ";
			}
			
			#my $box=def_hbox(FALSE,0);
			
			my @ports_type=("input","output","inout");
			my $pos=get_scolar_pos($type,@ports_type);
			my $combo1=gen_combo(\@ports_type,$pos);
			my $entry2=gen_entry($range);
			my $entry3=gen_entry($name);
			my $separator = Gtk2::VSeparator->new;
			my $connect_type_lable= gen_label_in_center($connect_type);
			my $entry4=gen_entry($connect_range);
			my $entry5=gen_entry($connect_name);
			my @outport_types=("shared","concatenate");
			my $pos2=get_scolar_pos($outport_type,@outport_types);			
			my $combo2=gen_combo(\@outport_types,$pos2);
							
			
			#my @list=(port_width_repeat($range,"1\'b0"),port_width_repeat($range,"1\'b1"),port_width_repeat($range,"1\'bx"));
			my @list=("Active low","Active high","Don't care");
			
			my $combentry=gen_combo_entry(\@list);
			$pos2=get_scolar_pos($default_out,@list);		 
			if( defined $pos2){
				$combentry->set_active($pos2);
			} else {
				($combentry->child)->set_text($default_out); 
			} 
			
			
			#$box->pack_start($entry3,TRUE,FALSE,3);
			#$box->pack_start($separator,TRUE,FALSE,3);
		
			$table->attach_defaults ($combo1, 0, 1 , $row, $row+1);
			$table->attach_defaults ($entry2, 1, 2 , $row, $row+1);
			$table->attach_defaults ($entry3, 2, 3 , $row, $row+1);
		
			
			$table->attach_defaults ($connect_type_lable, 4, 5 , $row, $row+1);
			$table->attach_defaults ($entry4, 5, 6 , $row, $row+1);
			$table->attach_defaults ($entry5, 6, 7 , $row, $row+1);
			$table->attach_defaults ($combentry, 8, 9 , $row, $row+1);
		
			$combo1->signal_connect("changed"=>sub{
				my $new_type=$combo1->get_active_text();
				my $new_connect_type=($new_type eq "input")? "output" : ($new_type eq "output")? "input" : $new_type;
				$infc_gen->intfc_add_port($id,$new_type,$range,$name,$new_connect_type,$connect_range,$connect_name,$outport_type,$default_out);
				set_state($soc_state,"refresh",1);
			
			});
			$entry2->signal_connect("changed"=>sub{
				$range=$entry2->get_text(); 
				$infc_gen->intfc_add_port($id,$type,$range,$name,$connect_type,$connect_range,$connect_name,$outport_type,$default_out);
				set_state($soc_state,"refresh",50);
				
			});	
			$entry3->signal_connect("changed"=>sub{
				$name=$entry3->get_text(); 
				$infc_gen->intfc_add_port($id,$type,$range,$name,$connect_type,$connect_range,$connect_name,$outport_type,$default_out);
				set_state($soc_state,"refresh",50);
				
			});	
			
			$entry4->signal_connect("changed"=>sub{
				$connect_range=$entry4->get_text(); 
				$infc_gen->intfc_add_port($id,$type,$range,$name,$connect_type,$connect_range,$connect_name,$outport_type,$default_out);
				set_state($soc_state,"refresh",50);
				
			});	
			$entry5->signal_connect("changed"=>sub{
				$connect_name=$entry5->get_text(); 
				$infc_gen->intfc_add_port($id,$type,$range,$name,$connect_type,$connect_range,$connect_name,$outport_type,$default_out);
				set_state($soc_state,"refresh",50);
				
			});	
			$combo2->signal_connect("changed"=>sub{
				my $new_outport_type=$combo2->get_active_text();
				$infc_gen->intfc_add_port($id,$type,$range,$name,$connect_type,$connect_range,$connect_name,$new_outport_type,$default_out);
				set_state($soc_state,"refresh",1);
			
			});
			($combentry->child)->signal_connect('changed' => sub {
				my ($entry) = @_;
				$default_out=$entry->get_text();
				$infc_gen->intfc_add_port($id,$type,$range,$name,$connect_type,$connect_range,$connect_name,$outport_type,$default_out);
			
				
			});
			
			
			
			$row++;
		
		
		}#foreach port	
	
	
	}
	return $row;
}










sub dev_box_gen{
	my($infc_gen,$soc_state,$info)=@_;
	my $table = def_table(20,10,FALSE);
	
	file_box($infc_gen,$soc_state,$info,$table,0);	
	module_select($infc_gen,$soc_state,$info,$table,1);	
	interface_type_select($infc_gen,$soc_state,$info,$table,2);	
	my $row=port_select($infc_gen,$soc_state,$info,$table,3);	
	for (my $i=$row; $i<20; $i++){
		my $temp=gen_label_in_center("");
		$table->attach_defaults ($temp, 0, 1 , $i, $i+1);
	}	
		
	return 	$table;	
}	





sub dev_box_show{
	my($infc_gen,$soc_state,$info,$refresh_ref)=@_;
	my $box= def_table (1, 1, TRUE);
	my $dev_table = dev_box_gen($infc_gen,$soc_state,$info);
	my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);
	$scrolled_win->set_policy( "automatic", "automatic" );
	$scrolled_win->add_with_viewport($dev_table);
	


	$$refresh_ref-> signal_connect("clicked" => sub{ 
		$dev_table->destroy;
		$dev_table = dev_box_gen($infc_gen,$soc_state,$info);
		#$box->attach_defaults ($dev_table, 0, 1, 0, 1);#( $dev_table, FALSE, FALSE, 3);
		$scrolled_win->add_with_viewport($dev_table);
		$dev_table->show;
		$scrolled_win->show_all;
		
		
		
	});
	#$box->attach_defaults ($dev_table, 0, 1, 0, 1);#$box->pack_start( $dev_table, FALSE, FALSE, 3);
	#$box->show_all;
	return $scrolled_win;
	
}	




sub check_intfc{
	my $intfc_gen=shift;
	my $result;
	my $message;
	
		
	$result=$intfc_gen->intfc_ckeck_ports_available();
	if(!defined $result){$message="No port connection has been selected for this interface!";}
	$result=$intfc_gen->intfc_get_interface_name();
	if(!defined $result){$message="The interface name is empty!";}
	$result=$intfc_gen->intfc_get_interface_file();
	if(!defined $result){$message="The verilog file containig the interface has not been selected!";}
	
	if(!defined $message){return 1;}
	else {message_dialog($message); return 0;}
		
	
}	



sub generate_lib{
	my $intfc_gen=shift;
	my $name=$intfc_gen->intfc_get_interface_name();
	my $category=$intfc_gen->intfc_get_category();
	# Write
	if(defined ($category)){
		open(FILE,  ">lib/interface/$name.ITC") || die "Can not open: $!";
		print FILE Data::Dumper->Dump([\%$intfc_gen],["HashRef"]);
		close(FILE) || die "Error closing file: $!";
		#store \%$intfc_gen, "lib/$name.ITC";
		my $message="Interface $name has been generated successfully" ;
		message_dialog($message);
		exec($^X, $0, @ARGV);# reset ProNoC to apply changes
		#$hashref = retrieve('file');
	}else{
		my $message="Category must be defined!";
		message_dialog($message);
		
	}	
	
	
return 1;	
}	



###########
#	get description
#########

sub get_intfc_description{
	my ($intfc_gen,$soc_state,$info)=@_;
	my $description = $intfc_gen->intfc_get_description();	
	my $table = Gtk2::Table->new (15, 15, TRUE);
	my $window=def_popwin_size(500,500,"Add description");
	my ($scrwin,$text_view)=create_text();
	#my $buffer = $textbox->get_buffer();
	my $ok=def_image_button("icons/select.png",' Ok ');
	
	$table->attach_defaults($scrwin,0,15,0,14);
	$table->attach_defaults($ok,6,9,14,15);
	my $text_buffer = $text_view->get_buffer;
	if(defined $description) {$text_buffer->set_text($description)};
	
	$ok->signal_connect("clicked"=> sub {
		$window->destroy;
		 
		 my $text = $text_buffer->get_text($text_buffer->get_bounds, TRUE);
		 $intfc_gen->intfc_set_description($text);	
		#print "$text\n";
		
	});
	
	$window->add($table);
	$window->show_all();
	
}	



sub load_interface{
	my ($intfc_gen,$soc_state)=@_;
	my $file;
	my $dialog = Gtk2::FileChooserDialog->new(
            	'Select a File', undef,
            	'open',
            	'gtk-cancel' => 'cancel',
            	'gtk-ok'     => 'ok',
        	);

	my $filter = Gtk2::FileFilter->new();
	$filter->set_name("ITC");
	$filter->add_pattern("*.ITC");
	$dialog->add_filter ($filter);
	my $dir = Cwd::getcwd();
	$dialog->set_current_folder ("$dir/lib/interface")	;			


	if ( "ok" eq $dialog->run ) {
		$file = $dialog->get_filename;
		my ($name,$path,$suffix) = fileparse("$file",qr"\..[^.]*$");
		if($suffix eq '.ITC'){
			$intfc_gen->intfc_set_interface_file($file);
			set_state($soc_state,"load_file",0);
		}					
     }
     $dialog->destroy;

	

}



############
#    main
############
sub intfc_main{
	
	my $intfc_gen= intfc_gen->interface_generator();
	
	my $soc_state=  def_state("ideal");
	# main window
	#my $window = def_win_size(1000,800,"Top");
	#  The main table containg the lib tree, selected modules and info section 
	my $main_table = Gtk2::Table->new (15, 12, FALSE);
	
	# The box which holds the info, warning, error ...  mesages
	my ($infobox,$info)= create_text();	
	
	
	my $refresh = Gtk2::Button->new_from_stock('ref');
	my $generate = def_image_button('icons/gen.png','Generate');
	my $genbox=def_hbox(TRUE,5);
	$genbox->pack_start($generate,   FALSE, FALSE,3);
	
	# A tree view for holding a library
	#my $tree_box = create_tree ($info,$lib,$soc,$soc_state);



	$main_table->set_row_spacings (4);
	$main_table->set_col_spacings (1);
	
	my $devbox=dev_box_show($intfc_gen,$soc_state,$info,\$refresh);
	
	$main_table->attach_defaults ($devbox , 0, 12, 0,12);
	$main_table->attach_defaults ($infobox  , 0, 12, 12,14);
	$main_table->attach_defaults ($genbox	, 6, 8, 14,15);


	my $open = def_image_button('icons/browse.png','Load Interface');
	my $openbox=def_hbox(TRUE,0);
	$openbox->pack_start($open,   FALSE, FALSE,0);
	$main_table->attach_defaults ($openbox,0, 2, 14,15);

	#check soc status every 0.5 second. referesh gui if there is any changes 
Glib::Timeout->add (100, sub{ 
	 
		my ($state,$timeout)= get_state($soc_state);
		if ($timeout>0){
			$timeout--;
			set_state($soc_state,$state,$timeout);		
		}
		elsif($state eq "load_file"){
			my $file=$intfc_gen->intfc_get_interface_file();
			my $pp= eval { do $file };
			clone_obj($intfc_gen,$pp);
						
			
			set_state($soc_state,"ref",1);
			
			
		}
		elsif( $state ne "ideal" ){
			$refresh->clicked;
			set_state($soc_state,"ideal",0);
			
		}	
		return TRUE;
		
		} );
	
	$open-> signal_connect("clicked" => sub{ 
		load_interface($intfc_gen,$soc_state);
	
	});		
		
	$generate-> signal_connect("clicked" => sub{ 
		if( check_intfc($intfc_gen)) {
			generate_lib($intfc_gen); 
			
		}
		
		$refresh->clicked;
	
});

	#show_selected_dev($info,\@active_dev,\$dev_list_refresh,\$dev_table);



#$box->show;
	#$window->add ($main_table);
	#$window->show_all;
	#return $main_table;

	my $sc_win = new Gtk2::ScrolledWindow (undef, undef);
		$sc_win->set_policy( "automatic", "automatic" );
		$sc_win->add_with_viewport($main_table);	

	return $sc_win;
	

}





1

