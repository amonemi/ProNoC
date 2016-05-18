#! /usr/bin/perl -w
use Glib qw/TRUE FALSE/;
use strict;
use warnings;
use wb_addr;
use interface;
use intfc_gen;
use ip_gen;
use rvp;
use Cwd 'abs_path';

use File::Basename;

use Gtk2;


require "widget.pl"; 


use String::Similarity;

 
sub find_the_most_similar_position{
	my ($item ,@list)=@_;
	my $most_similar_pos=0;
	my $lastsim=0;
	my $i=0;
	# convert item to lowercase
	$item = lc $item;
	foreach my $p(@list){
		my $similarity= similarity $item, $p;
		if ($similarity > $lastsim){
			$lastsim=$similarity;
			$most_similar_pos=$i;
		}
		$i++;
	}
	return $most_similar_pos;
}


use constant DISPLY_COLUMN    => 0;
use constant CATGR_COLUMN    => 1;
use constant INTFC_COLUMN     => 2;
use constant ITAL_COLUMN   => 3;
use constant NUM_COLUMN     => 4;

################
#  check_input_file
################

sub check_input_file{
	my ($file,$ipgen,$soc_state,$info)=@_;
	my ($name,$path,$suffix) = fileparse("$file",qr"\..[^.]*$");
	if($suffix eq '.IP'){
		$ipgen->ipgen_add("file_name",$file);
		set_state($soc_state,"load_file",0);
		
		
	}else{
		read_all_module ($file,$ipgen,$soc_state,$info);
	
	}	
	
	
}		


sub read_all_module{
	my ($file,$ipgen,$soc_state,$info)=@_;
	
	if (!defined $file) {return; }
	if (-e $file) { 
		my $vdb =  read_file($file);
		my @modules=sort $vdb->get_modules($file);
		#foreach my $p(@module_list) {print "$p\n"}
		$ipgen->ipgen_add("file_name",$file);



		$ipgen->ipgen_add("module_name",$modules[0]);
		$ipgen->ipgen_set_module_list(@modules);
		load_deafult_setting($ipgen,$modules[0]);
		
		
		set_state($soc_state,"file_selected",1);
		show_info(\$info,"Select the module which contain the interface ports\n ");	
	    
	}
	else { 
		show_info(\$info,"File $file doese not exsit!\n ");	
		
	}	
}	


##############
#	create_interface_tree 
##############
sub create_interface_tree {
   my ($info,$intfc,$ipgen,$soc_state)=@_;
   my $model = Gtk2::TreeStore->new ('Glib::String', 'Glib::String', 'Glib::Scalar', 'Glib::Boolean');
   my $tree_view = Gtk2::TreeView->new;
   $tree_view->set_model ($model);
   my $selection = $tree_view->get_selection;

   $selection->set_mode ('browse');
   $tree_view->set_size_request (200, -1);
 

  # my @interface= $intfc->get_interfaces();
	my @categories= $intfc->get_categories();



   foreach my $p (@categories)
   {
	my @intfc_names=  $intfc->get_intfcs_of_category($p);
	#my @dev_entry=  @{$tree_entry{$p}}; 	
	my $iter = $model->append (undef);
	$model->set ($iter,
                   DISPLY_COLUMN,    $p,
                   CATGR_COLUMN, $p || '',
                   INTFC_COLUMN,     0     || '',
                   ITAL_COLUMN,   FALSE);

	next unless  @intfc_names;
	
	foreach my $v ( @intfc_names){
		 my $child_iter = $model->append ($iter);
		 my $entry= '';
		
         	$model->set ($child_iter,
					DISPLY_COLUMN,    $v,
                   	CATGR_COLUMN, $p|| '',
                   	INTFC_COLUMN,     $v     || '',
                   	ITAL_COLUMN,   FALSE);
      	}	
	


   }
	
   my $cell = Gtk2::CellRendererText->new;
   $cell->set ('style' => 'italic');
   my $column = Gtk2::TreeViewColumn->new_with_attributes
 					("Double click to add the interface",
                                        $cell,
                                        'text' => DISPLY_COLUMN,
                                        'style_set' => ITAL_COLUMN);

  $tree_view->append_column ($column);
  my @ll=($model,\$info);
#row selected

  $selection->signal_connect (changed =>sub {
	my ($selection, $ref) = @_;
	my ($model,$info)=@{$ref};
	my $iter = $selection->get_selected;
  	return unless defined $iter;

  	my ($category) = $model->get ($iter, CATGR_COLUMN);
  	my ($name) = $model->get ($iter,INTFC_COLUMN );
  	my $describ=$intfc->get_description($category,$name);
  	
	if($describ){
		#print "$entry description is: $describ \n";
		show_info($info,$describ);
		
	}


}, \@ll);

#  row_activated 
  $tree_view->signal_connect (row_activated => sub{

	my ($tree_view, $path, $column) = @_;
	my $model = $tree_view->get_model;
	my $iter = $model->get_iter ($path);
	my ($category) = $model->get ($iter, CATGR_COLUMN);
	my ($name) = $model->get ($iter,INTFC_COLUMN );
  	
   

	if($name){ 
		#print "$infc_name-$infc_type  is selected via row activaton!\n";
		add_intfc_to_ip($intfc,$ipgen,$name,'plug',\$info,$soc_state);
	
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



sub save_ports_all{
	my ($ipgen,$vdb,$top_module)=@_;
	
	foreach my $sig (sort $vdb->get_modules_signals($top_module)) {
	my ($line,$a_line,$i_line,$type,$file,$posedge,$negedge,
	 $type2,$s_file,$s_line,$range,$a_file,$i_file,$dims) = 
	   $vdb->get_module_signal($top_module,$sig);

		if($type eq "input" or $type eq "inout" or $type eq "output" ){
			$ipgen->ipgen_add_port($sig,$range,$type,'IO','IO');
			#print "$sig,$range,$type,'IO','IO'\n";
			
		}
			

	}

}


############
#	file_info
#############

sub ip_file_box {
	my ($ipgen,$soc_state,$info,$table,$row)=@_;
	my $label = gen_label_in_left(" Select file:");
	my $entry = Gtk2::Entry->new;
	#my $open= def_image_button("icons/select.png","Open");
	my $browse= def_image_button("icons/browse.png","Browse");
	my $label2= gen_label_in_left(" IP name:");
	my $entry2= gen_entry();
	my $file= $ipgen->ipgen_get("file_name");
	if(defined $file){$entry->set_text($file);}
	my $ip_name= $ipgen->ipgen_get("ip_name");
	if(defined $ip_name){$entry2->set_text($ip_name);}
	show_info(\$info,"Please select the verilog file containig the ip module\n");
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
			$filter2->set_name("IP");
			$filter2->add_pattern("*.IP");
			$dialog->add_filter ($filter);
			$dialog->add_filter ($filter2);

        	if ( "ok" eq $dialog->run ) {
            		$file = $dialog->get_filename;
					$$entry_ref->set_text($file);
					check_input_file($file,$ipgen,$soc_state,$info);
            		#print "file = $file\n";
       		 }
       		$dialog->destroy;
       		


	} , \$entry);
	
	
	
	#$open->signal_connect("clicked"=> sub{
		#my $file_name=$entry->get_text();
		#check_input_file($file_name,$ipgen,$soc_state,$info);
		
		#});
	$entry->signal_connect("activate"=>sub{
		my $file_name=$entry->get_text();
		check_input_file($file_name,$ipgen,$soc_state,$info);
	});
		
	$entry->signal_connect("changed"=>sub{
		show_info(\$info,"Please select the verilog file containig the interface\n");
	});
	$entry2->signal_connect("changed"=>sub{
		my $name=$entry2->get_text();
		$ipgen->ipgen_add("ip_name",$name);
		
	});
	$table->attach_defaults ($label, 0, 1 , $row, $row+1);
	$table->attach_defaults ($entry, 1, 8 , $row, $row+1);
	$table->attach_defaults ($browse, 8, 9, $row, $row+1);
	$table->attach_defaults ($label2, 9, 10, $row, $row+1);
	$table->attach_defaults ($entry2,  10, 11, $row, $row+1);
	#$table->attach_defaults ($open,  7, 8, $row, $row+1);
	#$table->attach_defaults ($entry, $col, $col+1, $row, $row+1);
	#return $table;
	
	
}




sub select_module{
	my ($ipgen,$soc_state,$info,$table,$row)=@_;
	my $label= gen_label_in_left("  Select\n module:");
	my @modules= $ipgen->ipgen_get_module_list();
	my $saved_module=$ipgen->ipgen_get("module_name");
	my $pos=(defined $saved_module ) ? get_scolar_pos( $saved_module,@modules) : 0;
	my $combo = gen_combo(\@modules, $pos);
	my $param= def_image_button("icons/setting.png","Parameter\n   setting");
	my $def= def_image_button("icons/setting.png","Definition\n file setting");
	my $label2= gen_label_in_left("  Select\n Category:");
	my ($category,$category_entry)=gen_entry_help('Define the IP category:e.g RAM, GPIO,...');
	my $saved_category=$ipgen->ipgen_get("category");
	if(defined $saved_category){$category_entry->set_text($saved_category);}
	my $ipinfo= def_image_button("icons/info.png","    IP\n Description");
	my $header_h= def_image_button("icons/h_file.png","Add Software\n      files");
	my $lib_hdl= def_image_button("icons/add-notes.png","Add HDL\n     files");
	
	$table->attach_defaults ($label, 0, 1 , $row, $row+1);
	$table->attach_defaults ($combo, 1, 4 , $row,$row+1);
	$table->attach_defaults ($param, 4, 6 , $row, $row+1);
	#$table->attach_defaults ($def, 5, 6 , $row, $row+1);
	$table->attach_defaults ($label2, 6, 7 , $row, $row+1);	
	$table->attach_defaults ($category, 7, 8 , $row, $row+1);
	$table->attach_defaults ($ipinfo, 8, 9 , $row, $row+1);
	$table->attach_defaults ($header_h, 9, 10 , $row, $row+1);
	$table->attach_defaults ($lib_hdl, 10, 11 , $row, $row+1);
	
	
	$combo->signal_connect("changed"=> sub{
		
		my $module= $combo->get_active_text();
		load_deafult_setting($ipgen,$module); 
		set_state($soc_state,'intfc_changed',0);
		
		
	});
	
	$param->signal_connect("clicked"=> sub{
		get_parameter_setting($ipgen,$soc_state,$info);
		
		
	});	

	$def->signal_connect("clicked"=> sub{
		get_def_setting($ipgen,$soc_state,$info);
		
		
	});	
	$category_entry->signal_connect("changed"=> sub{
		my $name=$category_entry->get_text();
		$ipgen->ipgen_add("category",$name);
		
	});
	$ipinfo->signal_connect("clicked"=> sub{
		get_Description($ipgen,$soc_state,$info);		
		
	});	
	$header_h->signal_connect("clicked"=> sub{
		my %page_info;
		my $help1="The files and folder that selected here will be copied in genertated processing tile SW folder.";
		my $help2="The file listed here can contain some variable with \${var_name} format. The file genertor will replace them with their values during file generation. The variable can be selected from above listed global vairable";
		my $help3='Define the header file for this peripheral device. You can use global vriables listed at the top.  
  		
header file example 
   
 #define ${IP}_REG_0   (*((volatile unsigned int *) ($BASE)))   
 #define ${IP}_REG_1   (*((volatile unsigned int *) ($BASE+4)))
   
   
 #define ${IP}_WRITE_REG1(value)  ${IP}_REG_1=value	
 #define ${IP}_READ_REG1()  	${IP}_REG_1	    
  ';	

		$page_info{0}{page_name} = "_Add exsiting file/folder";
		$page_info{0}{filed_name}= "sw_files";
		$page_info{0}{filed_type}= "exsiting_file/folder";
		$page_info{0}{rename_file}=undef; 
		$page_info{0}{folder_en}=1;
		$page_info{0}{help}=$help1;

		$page_info{1}{page_name} = "_Add file generator(s)";
		$page_info{1}{filed_name}= "gen_sw_files";
		$page_info{1}{filed_type}= "file_generators";
		$page_info{1}{rename_file}=1; 
		$page_info{1}{folder_en}=0;
		$page_info{1}{help}=$help2;

		$page_info{2}{page_name} = "_Add to system.h";
		$page_info{2}{filed_name}= "system_h";
		$page_info{2}{filed_type}= "file_content";
		$page_info{2}{rename_file}=undef; 
		$page_info{2}{folder_en}=0;
		$page_info{2}{help}=$help3;


		get_source_file($ipgen,$soc_state,$info,0,"Add software file(s)","SW",\%page_info);
		#get_software_file($ipgen,$soc_state,$info,0);		
		
	});	
	$lib_hdl->signal_connect("clicked"=> sub{
		my $help1="The files and folder that selected here will be copied in genertated processing tile RTL  folder.";
		my %page_info;
		$page_info{0}{page_name} = "_Add exsiting HDL file/folder";
		$page_info{0}{filed_name}= "hdl_files";
		$page_info{0}{filed_type}= "exsiting_file/folder";
		$page_info{0}{rename_file}=undef;
		$page_info{0}{folder_en}=1; 
		$page_info{0}{help}=$help1;

		get_source_file($ipgen,$soc_state,$info,0,"Add HDL file(s)", "hw",\%page_info);

		#get_hdl_file($ipgen,$soc_state,$info);
				
		
	});	
}

sub load_deafult_setting{
	my ($ipgen,$module)=@_; 
	my $file= $ipgen->ipgen_get("file_name");
	$ipgen->ipgen_add("module_name",$module);
	my $vdb =read_file($file);
	my %parameters = $vdb->get_modules_parameters_not_local($module);
	my @parameters_order= $vdb->get_modules_parameters_not_local_order($module);
	my @ports_order=$vdb->get_module_ports_order($module);
	#print "@port_order\n";
	
	#add deafult parameter setting
	$ipgen->ipgen_remove_all_parameters();
	foreach my $p (keys %parameters){
			#print "$p\n";
			my $v = $parameters{$p};
			$v =~s/[\n]//gs;
			$ipgen->ipgen_add_parameter($p,$v,'Fixed','');
			
	}
	#add parameter order. 
	$ipgen->ipgen_add("parameters_order",\@parameters_order); 
	#add port order.
	$ipgen->ipgen_add_ports_order(@ports_order); 
	#add ports 
	$ipgen->ipgen_remove_all_ports();	
	save_ports_all($ipgen,$vdb,$module);

	

}

sub file_info_box {
	my($ipgen,$soc_state,$info)=@_;
	my $table=def_table(2,11,FALSE);
	my $table1=def_table(1,11,FALSE);
	my $table2=def_table(1,11,FALSE);
	ip_file_box ($ipgen,$soc_state,$info,$table1,0);
	select_module($ipgen,$soc_state,$info,$table2,0);
	$table->attach_defaults($table1,0,11,0,1);
	$table->attach_defaults($table2,0,11,1,2);
	return $table;
	
	
}




sub show_file_info{
	my($ipgen,$soc_state,$info,$refresh_ref)=@_;
	my $table = file_info_box($ipgen,$soc_state,$info,$info);
	my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);
	$scrolled_win->set_policy( "automatic", "never" );
	$scrolled_win->add_with_viewport($table);
	


	$$refresh_ref-> signal_connect("clicked" => sub{ 
		$table->destroy;
		$table = file_info_box($ipgen,$soc_state,$info,$info);
		
		$scrolled_win->add_with_viewport($table);
		$table->show;
		$scrolled_win->show_all;
			
		
		
	});
	
	return $scrolled_win;
	
	
	
}	


sub show_port_info{
	my($intfc,$ipgen,$soc_state,$info,$refresh_ref)=@_;
	my $table = port_info_box($intfc,$ipgen,$soc_state,$info,$info);
	my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);
	$scrolled_win->set_policy( "automatic", "automatic" );
	$scrolled_win->add_with_viewport($table);
	


	$$refresh_ref-> signal_connect("clicked" => sub{ 
		$table->destroy;
		$table = port_info_box($intfc,$ipgen,$soc_state,$info,$info);
		
		$scrolled_win->add_with_viewport($table);
		$table->show;
		$scrolled_win->show_all;
		
		
		
		
	});
	
	return $scrolled_win;
	
}


sub show_interface_info{
	my($intfc,$ipgen,$soc_state,$info,$refresh_ref)=@_;
	my $table = interface_info_box($intfc,$ipgen,$soc_state,$info,$info);
	my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);
	$scrolled_win->set_policy( "automatic", "automatic" );
	$scrolled_win->add_with_viewport($table);
	


	$$refresh_ref-> signal_connect("clicked" => sub{ 
		$table->destroy;
		select(undef, undef, undef, 0.1); #wait 10 ms
		$table = interface_info_box($intfc,$ipgen,$soc_state,$info,$info);
		
		$scrolled_win->add_with_viewport($table);
		$table->show;
		$scrolled_win->show_all;
		
		
	});
	
	return $scrolled_win;
	
	
	
}		








############
#  get_parameter_setting
##########
sub get_parameter_setting { 
	my ($ipgen,$soc_state,$info)=@_;
	
	my $module = $ipgen->ipgen_get("module_name");
	my $file= $ipgen->ipgen_get("file_name");
	if (!defined $file) {
			message_dialog("The input verilog file is empty");
			return;
			
	}		
	
	#my $titelbox=def_title_box(TRUE,5,("Parameter name","Deafult value","Widget type","Widget content","Global param   Optional info",));
	
	
	
	
	
	my @widget_type_list=("Fixed","Entry","Combo-box","Spin-button");
	my @param_type_list=("localparam-pass", "parameter-pass", "localparam-notpass","parameter-notpass");
	my $type_info="Define the parameter type: 

Fixed: The parameter is fixed and get the default value. Users can not see or change the parameter value.

Entry: The parameter value is received via entry. The user can type anything.

Combo-box: The parameter value can be selected from a list of predefined value.

Spin-button: The parameter is numeric and will be obtained using spin button.";
	my $content_info='
For Fixed and Entry leave it empty.
For Combo box define the parameters which must be shown in combo box as: "PAEAMETER1","PARAMETER2"...,"PARAMETERn".
For Spin button define it as "minimum, maximum, step" e.g 0,10,1.';
	my $param_info='
	If checked, the parameter will be defined as parameter in SoC file too, otherwise it will be defined as localparam.';

	my $redefine_info='
	If checked, the defined parameter/localparam in SoC will be passed to the IP core';

	#TABLE
	my $table = Gtk2::Table->new (12, 8, FALSE);
	my @positions=(0,1,2,3,4,5,6,7,8);
	my $col=0;
	#title
	my @title;
	$title[0]=gen_label_in_center("Parameter name");
	$title[1]=gen_label_in_center("Deafult value");
	$title[2]=gen_label_help($type_info,"Widget type");
	$title[3]=gen_label_help($content_info,"Widget content");
	$title[4]=gen_label_help($param_info);
	$title[5]=gen_label_help($redefine_info);
	$title[6]=gen_label_help("You can add aditional information about this parameter.","info");
	$title[7]=gen_label_in_center("add/remove");
	
	
	foreach my $t (@title){
		$table->attach_defaults ($title[$col], $positions[$col], $positions[$col+1], 0, 1);$col++;

	}
	

	
	my ($box,$window)=def_scrolled_window_box(1200,500,"Define parameters detail");
	
	
	

	my @parameters=$ipgen->ipgen_get_all_parameters_list();
	my @params_order= $ipgen->ipgen_get_list("parameters_order");
	if((@params_order)) {@parameters=@params_order;}
	
	my $ok = def_image_button('icons/select.png','OK');
	my $okbox=def_hbox(TRUE,0);
	$okbox->pack_start($ok,   FALSE, FALSE,0);

	my ($b,$new_param)= def_h_labeled_entry("Add new parameter name:");
	my $add = def_image_button('icons/plus.png','Add parameter');
	my $addbox=def_hbox(FALSE,0);
	$addbox->pack_start($b,FALSE, FALSE,0);
	$addbox->pack_start($add,   FALSE, FALSE,0);
	
	my @allowed;
	
	my $row=1;
	
	push(@parameters,"#new#");
	foreach my $p (@parameters) {
		my ($saved_deafult,$saved_widget_type,$saved_content,$saved_info,$global_param,$redefine_param)=  $ipgen->ipgen_get_parameter_detail($p);
		#print 	"($saved_deafult,$saved_type,$saved_content)\n";
		my $parameter_box = def_hbox(TRUE,5);
		my $param_name;
		my $add_remove;
		if($p ne "#new#"){
			$param_name= def_label($p);
			$add_remove=def_image_button("icons/cancel.png","remove");
		} else { 
			$param_name= gen_entry();
			$add_remove=def_image_button("icons/plus.png","add");
		}

		my $deafult_entry= gen_entry($saved_deafult);
		my $pos=(defined $saved_widget_type ) ? get_scolar_pos( $saved_widget_type,@widget_type_list) : 0;
		my $widget_type_combo=gen_combo(\@widget_type_list, $pos);
		my $content_entry= gen_entry($saved_content);
		my $check_param= Gtk2::CheckButton->new('Parameter');
		$check_param->set_active($global_param) if(defined $global_param );
		my $check_redefine= Gtk2::CheckButton->new('Redefine');
		$check_redefine->set_active(1) ;
		$check_redefine->set_active($redefine_param) if(defined $redefine_param );		
		




		#my $check= Gtk2::CheckButton->new;
		#$check->set_active($global_param) if(defined $global_param );


		my $info=def_image_button("icons/addinfo.png");
		#print "\$global_param =$global_param\n";
		
		$col=0;
		my @all_widget=($param_name,$deafult_entry,$widget_type_combo,$content_entry,$check_param,$check_redefine,$info,$add_remove);
		foreach my $t (@all_widget){
			$table->attach_defaults ($t, $positions[$col], $positions[$col+1], $row, $row+1);$col++;

		}		
		
		
		$info->signal_connect (clicked => sub{
			
			get_param_info($ipgen,\$saved_info);
		});
		
				
		$ok->signal_connect (clicked => sub{
			if($p ne "#new#"){		
				my $deafult=$deafult_entry->get_text();
				my $type= $widget_type_combo->get_active_text();
				my $content=$content_entry->get_text();
				my $check_result=$check_param->get_active();
				my $global_param=($check_result eq 1)? 1:0;
				$check_result=$check_redefine->get_active();
				my $redefine_param=($check_result eq 1)? 1:0;
				$ipgen->ipgen_add_parameter($p,$deafult,$type,$content,$saved_info,$global_param,$redefine_param);
			}
		});
		$add_remove->signal_connect (clicked => sub{
			if($p eq "#new#"){ #add new parameter
				my $param= $param_name->get_text();
				$param=remove_all_white_spaces($param);
			        
				if( length($param) ){
					my $deafult=$deafult_entry->get_text();
					my $type=$widget_type_combo->get_active_text();
					my $content=$content_entry->get_text();
					my $check_result=$check_param->get_active();
					my $global_param=($check_result eq 1)? 1:0;
					   $check_result=$check_redefine->get_active();
					my $redefine_param=($check_result eq 1)? 1:0;
					$ipgen->ipgen_add_parameter($param,$deafult,$type,$content,$saved_info,$global_param,$redefine_param);
					$ipgen->ipgen_push_parameters_order($param);
					set_state($soc_state,"change_parameter",0);
					$ok->clicked;
					#$window->destroy();
				}

			} else { #remove the parameter
				$ipgen->ipgen_remove_parameter($p);
				$ipgen->ipgen_remove_parameters_order($p);
				set_state($soc_state,"change_parameter",0);
				$ok->clicked;
					#$window->destroy();
	
			}
			#my $param_name=$new_param->get_text();
			#	if( length($param_name) ){
			#		print "$param_name\n";
			#		$ipgen->ipgen_add_parameter($param_name,undef);
			#		set_state($soc_state,"change_parameter",0);
			#		$window->destroy();
			
		});

		
		
	$row++;	
	}
	$box->pack_start( $table, FALSE, FALSE, 3);

	for (my $i=$row; $i<7;$i++){
		my $temp=gen_label_in_center(' ');
		$box->pack_start($temp,   TRUE, FALSE,3);
	}
	
	$box->pack_start($okbox,   TRUE, FALSE,3);

	$add->signal_connect (clicked => sub{
		my $param_name=$new_param->get_text();
		if( length($param_name) ){
			#print "$param_name\n";
			$ipgen->ipgen_add_parameter($param_name,undef);
			set_state($soc_state,"change_parameter",0);
			$window->destroy();
		}

#/*******************************************************************************************************************************/

	});
	
	$ok->signal_connect (clicked => sub{
				
		$window->destroy();

	});
	

	
	
	
	$window->show_all;
}




############
#  get_def_setting
##########
sub get_def_setting { 
	my ($ipgen,$soc_state,$info)=@_;
	my $table = Gtk2::Table->new (15, 15, TRUE);
	my $table2 = Gtk2::Table->new (15, 15, TRUE);
	my $window=def_popwin_size(600,600,"Add definition file");
	my $ok=def_image_button("icons/select.png",' Ok ');
	my $scrwin=  new Gtk2::ScrolledWindow (undef, undef);
	$scrwin->set_policy( "automatic", "automatic" );
	$scrwin->add_with_viewport($table2);

	my $label=gen_label_help("You ","Selecet the Verilog file containig the definitions."); 
	my $brows=def_image_button("icons/browse.png",' Browse');
	$table->attach_defaults($label,0,10,0,1);
	$table->attach_defaults($brows,10,12,1,2);
	$table->attach_defaults($scrwin,0,15,2,14);
	$table->attach_defaults($ok,6,9,14,15);

	$window->add($table);
	$window->show_all;


}


###########
#	get description
#########

sub get_Description{
	my ($ipgen,$soc_state,$info)=@_;
	my $description = $ipgen->ipgen_get("description");	
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
		 $ipgen->ipgen_add("description",$text);	
		#print "$text\n";
		
	});
	
	$window->add($table);
	$window->show_all();
	
}	






##########
#	gen_file_list
#########

sub gen_file_list{
	my ($ipgen,$list_name,$window,$rename_file_en)=@_;
	

	my $table=def_table(10,10,TRUE);#	my ($row,$col,$homogeneous)=@_;
	my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);
	my $ok=def_image_button("icons/select.png",' Ok ');

	$scrolled_win->set_policy( "automatic", "automatic" );
	$scrolled_win->add_with_viewport($table);
	$table->attach_defaults (gen_label_in_center("File path"), 0, 5 , 0, 1);
   	$table->attach_defaults (gen_label_help("The target name can contain any of Global variables e.g \$IP\$.h","Copy as"), 5, 9 , 0, 1) if(defined $rename_file_en);
	my $col=0;
        my $row=1;
	my @files=  $ipgen->ipgen_get_list($list_name); #@{$ref};
	my $file_num= scalar @files;	
	foreach my $p(@files){
			my ($path,$rename)=split('frename_sep_t',$p); 
			my $entry=gen_entry($path);
			my $entry2=gen_entry($rename) ;
			my $remove=def_image_button("icons/cancel.png");
			$table->attach_defaults ($entry, 0, 5 , $row, $row+1);
			$table->attach_defaults ($entry2, 5, 9 , $row, $row+1) if(defined $rename_file_en);
			$table->attach_defaults ($remove, 9,10 , $row, $row+1);
			$row++;		
			$remove->signal_connect("clicked"=> sub {
				my @saved_files=$ipgen->ipgen_get_list($list_name);
				@saved_files=remove_scolar_from_array(\@saved_files,$p);
				$ipgen->ipgen_add($list_name,\@saved_files);
				$entry->destroy;
				$entry2->destroy if(defined $rename_file_en);
				$remove->destroy;
			
			});
			$ok->signal_connect("clicked"=> sub {
				if(defined $entry){
					my $n= $entry->get_text();
					   if(defined $rename_file_en){
						$n= $n.'frename_sep_t'.$entry2->get_text() ;
					   }
					if($p ne $n){
						my @saved_files=$ipgen->ipgen_get_list($list_name);
						@saved_files=replace_in_array(\@saved_files,$p, $n);
						$ipgen->ipgen_add($list_name,\@saved_files);
					}
				
				}
			
			
			
			});
		
			#my $seph = Gtk2::HSeparator->new;
			#$table->attach_defaults ($seph, 0, 10 , $row, $row+1);
			#$row++;		
		
	}
	
	

	$ok->signal_connect("clicked"=> sub {
		$window->destroy;
	});

#   while( $row<10){
	#	my $label=gen_label_in_left(' ');
	   # $table->attach_defaults ($label, 0, 1 , $row, $row+1);$row++;
	#}

	
	return ($scrolled_win,$ok);
}



sub get_param_info{
	my ($ipgen,$saved_info)=@_;
	my $table = Gtk2::Table->new (15, 15, TRUE);
	my $window=def_popwin_size(500,500,"Add description");
	my ($scrwin,$text_view)=create_text();
	my $ok=def_image_button("icons/select.png",' Ok ');
	
	$table->attach_defaults($scrwin,0,15,0,14);
	$table->attach_defaults($ok,6,9,14,15);
	my $text_buffer = $text_view->get_buffer;
	if(defined $$saved_info) {$text_buffer->set_text($$saved_info)};
	
	$ok->signal_connect("clicked"=> sub {
		$window->destroy;
		 
		 $$saved_info = $text_buffer->get_text($text_buffer->get_bounds, TRUE);
		 
		
	});
	
	$window->add($table);
	$window->show_all();
	
	
}	



sub interface_info_box {
	my($intfc,$ipgen,$soc_state,$info)=@_;
	my $table=def_table(7,7,TRUE);
	my @sokets=$ipgen->ipgen_list_sokets;
	my @plugs=$ipgen->ipgen_list_plugs;
	
	my @positions=(0,1,2,4,5,6,7);
	
	
	my $row=0;
	my $col=0;
	$table->attach_defaults (gen_label_in_center(" Interface name"), $positions[0], $positions[1], $row, $row+1);
	$table->attach_defaults (gen_label_in_center("Type"), $positions[1], $positions[2], $row, $row+1);
	$table->attach_defaults (gen_label_in_left("Interface Num"), $positions[2], $positions[3], $row, $row+1);
	
	$row++;
	my @type_list=('plug','socket');
	
	foreach my $p( @sokets){
		#my ($range,$type,$intfc_name,$intfc_port)=$ipgen->ipgen_get_port($p);
		my ($type,$value,$connection_num)= $ipgen->ipgen_get_socket($p);
		my $label_name=gen_label_in_center($p);
		my $combo_type=gen_combo(\@type_list,1);
		my $remove=	def_image_button('icons/cancel.png','Remove');
		my $name_setting=def_image_button('icons/setting.png');
		$remove->signal_connect ('clicked'=> sub{
			$ipgen->ipgen_remove_socket($p);
			set_state($soc_state,'intfc_changed',0);		
			
			}  );
		$name_setting->signal_connect ('clicked'=> sub{
			get_intfc_setting($ipgen,$soc_state,$p,'socket');
			
			
		});	
		$combo_type	->signal_connect ('changed'=> sub{
			$ipgen->ipgen_remove_socket($p);
			add_intfc_to_ip($intfc,$ipgen,$p,'plug',$info,$soc_state);
				
			}  );
		$table->attach_defaults ($remove, $positions[4], $positions[5], $row, $row+1);	
		if ($type eq 'num'){
			my ($type_box,$type_spin)=gen_spin_help ('Define the number of this interface in module', 1,1024,1);
			$type_box->pack_start($name_setting,FALSE,FALSE,0);
			$type_spin->set_value($value);
			my $advance_button=def_image_button('icons/advance.png','separate');
			$table->attach_defaults ($type_box, $positions[2], $positions[3], $row, $row+1);
			$table->attach_defaults ($advance_button, $positions[3], $positions[4], $row, $row+1);	
			$type_spin->signal_connect("value_changed"=>sub{
				my $wiget=shift;
				my $num=$wiget->get_value_as_int();
				$ipgen->ipgen_add_soket($p,'num',$num);
				set_state($soc_state,'intfc_changed',0);
				
			});
			$advance_button->signal_connect("clicked"=>sub{
				$ipgen->ipgen_add_soket($p,'param');
				set_state($soc_state,'intfc_changed',0);
				
			});	
			
		}
		else {
			my @parameters=$ipgen->ipgen_get_all_parameters_list();
			my $pos= get_scolar_pos( $value,@parameters);
			if(!defined $pos){
				$pos=0;
				$ipgen->ipgen_add_soket($p,'param',$parameters[0]);
			}
			my ($type_box,$type_combo)=gen_combo_help ('Define the parameter which determine the number of this interface in module',\@parameters,$pos);
			$type_box->pack_start($name_setting,FALSE,FALSE,0);
			my $advance_button=def_image_button('icons/advance.png','concatenate');
			$table->attach_defaults ($type_box, $positions[2], $positions[3], $row, $row+1);
			$table->attach_defaults ($advance_button, $positions[3], $positions[4], $row, $row+1);		
			$type_combo->signal_connect("changed"=>sub{
				my $wiget=shift;
				my $value=$wiget->get_active_text();
				$ipgen->ipgen_add_soket($p,'param',$value);
				set_state($soc_state,'intfc_changed',0);
				
			});
			$advance_button->signal_connect("clicked"=>sub{
				$ipgen->ipgen_add_soket($p,'num',0);
				set_state($soc_state,'intfc_changed',0);
				
			});	
			
		}	
		
		
		
		
		
		
		$table->attach_defaults ($label_name, $positions[0], $positions[1], $row, $row+1);
		$table->attach_defaults ($combo_type, $positions[1], $positions[2], $row, $row+1);
		
		
		
			
		$row++;
	}	
	foreach my $q( @plugs){
		#my ($range,$type,$intfc_name,$intfc_port)=$ipgen->ipgen_get_port($p);
		my ($type,$value)= $ipgen->ipgen_get_plug($q);
		my $label_name=gen_label_in_center($q);
		my $combo_type=gen_combo(\@type_list,0);
		my $remove=	def_image_button('icons/cancel.png','Remove');
		my $name_setting=def_image_button('icons/setting.png');
		
		$table->attach_defaults ($remove, $positions[4], $positions[5], $row, $row+1);	
		$remove->signal_connect ('clicked'=> sub{
			$ipgen->ipgen_remove_plug($q);
			set_state($soc_state,'intfc_changed',0);		
			
			}  );
		$name_setting->signal_connect ('clicked'=> sub{
			get_intfc_setting($ipgen,$soc_state,$q,'plug');
			
			
		}	);	
		$combo_type	->signal_connect ('changed'=> sub{
			$ipgen->ipgen_remove_plug($q);
			add_intfc_to_ip($intfc,$ipgen,$q,'socket',$info,$soc_state);
				
			}  );	
		#my $range_entry=gen_entry($range);
		if ($type eq 'num'){
			my ($type_box,$type_spin)=gen_spin_help ('Define the number of this interface in module', 1,1024,1);
			$type_box->pack_start($name_setting,FALSE,FALSE,0);
			$type_spin->set_value($value);
			$table->attach_defaults ($type_box, $positions[2], $positions[3], $row, $row+1);
			$type_spin->signal_connect("value_changed"=>sub{
				my $wiget=shift;
				my $num=$wiget->get_value_as_int();
				$ipgen->ipgen_add_plug($q,'num',$num);
				set_state($soc_state,'intfc_changed',0);
				
			});
			
		}	
		$table->attach_defaults ($label_name, $positions[0], $positions[1], $row, $row+1);
		$table->attach_defaults ($combo_type, $positions[1], $positions[2], $row, $row+1);
		#$table->attach_defaults ($range_entry, 2, 4, $row, $row+1);
		
		#wishbone address seting
		#print "$q eq 'wb_slave'\n";
		if($q eq 'wb_slave'){
			my ($saved_addr,$saved_width)=$ipgen->ipgen_get_wb_addr($q,0);
			my $addr;
			if(!defined $saved_addr){
				 $addr=	def_image_button('icons/warnning.png');
				 $addr->signal_connect ('clicked'=> sub{
				     message_dialog("Wishbone slave address range has not been set yet! ");		
				
				}  );
			}else{
				 $addr=	def_image_button('icons/select.png');
				
			}	
			$table->attach_defaults ($addr, $positions[5], $positions[6], $row, $row+1);
			
			
		}	
		
			
		$row++;
	}	
	
	
	
	
	
	return $table;
	
}	
########
#	get_intfc_setting
########

sub get_intfc_setting{
	
	my ($ipgen,$soc_state,$intfc_name, $intfc_type)=@_;
	
	
	my $window =  def_popwin_size(1000,500);
	my $table=def_table(7,6,FALSE);
	my $ok = def_image_button('icons/select.png','OK');
	my $okbox=def_hbox(TRUE,0);
	$okbox->pack_start($ok, FALSE, FALSE,0);
	
	
	my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);
	$scrolled_win->set_policy( "automatic", "automatic" );
	$scrolled_win->add_with_viewport($table);
	
	#title
	my $lable1=gen_label_in_left("interface name");
	$table->attach_defaults( $lable1,0,2,0,1);
	
	
	
	
	my ($type,$value);
	if($intfc_type eq 'plug'){
		 ($type,$value)= $ipgen->ipgen_get_plug($intfc_name);
	}else {
		 ($type,$value)= $ipgen->ipgen_get_socket($intfc_name);
		
	}		
	if ($type ne 'num'){ $value=1;}
	my $i=0;
	for ( $i=0; $i < $value; $i++) {
		#intfc name
		my $saved_name;
		my $number=$i;
		if($intfc_type eq 'plug')	{$saved_name= $ipgen->ipgen_get_plug_name($intfc_name,$number);}
		else						{$saved_name= $ipgen->ipgen_get_socket_name($intfc_name,$number);}
		my  $entry_name=gen_entry($saved_name);
		
		$table->attach_defaults($entry_name,0,2,$i+1,$i+2);
		$ok->signal_connect('clicked'=>sub{
				my $new_name=$entry_name->get_text();
				#print "my new name is: $new_name\n";
				if($intfc_type eq 'plug'){ $ipgen->ipgen_set_plug_name($intfc_name,$number,$new_name); }
				else { 					   $ipgen->ipgen_set_socket_name($intfc_name,$number,$new_name);}
			
			});
		
	
	}	

	
	#wishbone addr
	if($intfc_name eq 'wb_slave' &&  $intfc_type eq 'plug'){ 
		my $lable2=gen_label_in_center("address range: (start end name)");
		my $lable3=gen_label_in_center("block address width");

		$table->attach_defaults( $lable2,2,5,0,1);
		$table->attach_defaults( $lable3,5,6,0,1);
		
		my $plug=$intfc_name;
		my $wb= wb_addr->wb_addr_new();
		my @ip_names=$wb->wb_list_names();
		my @list;
		foreach my $p(@ip_names){
			my($start,$end,$cashed,$size)=$wb->wb_get_addr_info($p);
			push (@list,"$start\t$end\t\t$p");
		
		}
		
		my ($type,$value,$connection_num)=$ipgen->ipgen_get_plug($plug);
		   $i=0;
		
		for ( $i=0; $i < $value; $i++) {
			my ($saved_addr,$saved_width)=$ipgen->ipgen_get_wb_addr($plug,$i);
			my $num=$i;
			my $pos;
			if(!defined $saved_addr){
				$pos=0;
				$saved_width=1;
				$ipgen->ipgen_save_wb_addr($plug,$num,$list[0],1);
			}
			else{
				$pos= get_scolar_pos($saved_addr,@list);	
			}	
			
			my $name_combo=gen_combo(\@list,$pos);
			my $sbox=def_hbox(FALSE,0);
			my $widget;
			my $size_lab;
			my @l=("Fixed","Parameterizable");

			if(!defined $saved_width){
				$pos=0;
				$saved_width=1;

			}
			else{
				if(is_integer($saved_width)){
			 		 $pos= 0; 
					 $widget=gen_spin(1,31,1);
					 $widget->set_value($saved_width);
					 my $d=2**$saved_width;
					 $size_lab=gen_label_in_left(metric_conversion($d). " Bytes");
				} else{
					$pos= 1; 
					my @parameters=$ipgen->ipgen_get_all_parameters_list();
					my $p=get_scolar_pos($saved_width,@parameters);

					$widget=gen_combo(\@parameters, $p); 
					$size_lab=gen_label_in_left(" ");

				}


			}


			
			my $comb=gen_combo(\@l, $pos); 
			#$widget->set_value($saved_width);
			$sbox->pack_start($comb,FALSE,FALSE,3);
			$sbox->pack_end($widget,FALSE,FALSE,3);
			$sbox->pack_end($size_lab,FALSE,FALSE,3);
			$comb->signal_connect('changed'=>sub{			
				my $condition=$comb->get_active_text();
				$widget->destroy;
				$size_lab->destroy;
				my @parameters=$ipgen->ipgen_get_all_parameters_list();
				$widget=($condition eq "Fixed" )? gen_spin(1,31,1):gen_combo(\@parameters, 0); 
				$size_lab=($condition eq "Fixed" )? gen_label_in_left("2 Bytes"):  gen_label_in_left(" ");
				$sbox->pack_end($widget,FALSE,FALSE,3);
				$sbox->pack_end($size_lab,FALSE,FALSE,3);
				$sbox->show_all();
				$widget->signal_connect('changed'=>sub{	
					$size_lab->destroy;
					my $in=$comb->get_active_text();
					my $width=($in eq "Fixed" )? $widget->get_value_as_int(): $widget->get_active_text() ;
					my $d=($in eq "Fixed" )? 2**$width:0;
				
					$size_lab=($in eq "Fixed" )? gen_label_in_left( metric_conversion($d). " Bytes"):gen_label_in_left(" ");
					$sbox->pack_end($size_lab,FALSE,FALSE,3);
					$sbox->show_all();
				});
			});
			$widget->signal_connect('changed'=>sub{	
				$size_lab->destroy;
				my $in=$comb->get_active_text();
				my $width=($in eq "Fixed" )? $widget->get_value_as_int(): $widget->get_active_text() ;
				my $d=($in eq "Fixed" )? 2**$width:0;
				
				$size_lab=($in eq "Fixed" )? gen_label_in_left(metric_conversion($d). " Bytes"):gen_label_in_left(" ");
				$sbox->pack_end($size_lab,FALSE,FALSE,3);
				$sbox->show_all();
			});
		
			$table->attach_defaults($name_combo,2,5,$i+1,$i+2);
			$table->attach_defaults($sbox,5,6,$i+1,$i+2);
			$ok->signal_connect('clicked'=>sub{
				my $addr=$name_combo->get_active_text();
				my $in=$comb->get_active_text();
				my $width=($in eq "Fixed" )? $widget->get_value_as_int(): $widget->get_active_text() ;
				$ipgen->ipgen_save_wb_addr($plug,$num,$addr,$width);
			
			});
		

		}
		
		
	
	}

	while($i<7){
		$i++;
		my $tmp=gen_label_in_left('  ');
		$table->attach_defaults($tmp,5,6,$i,$i+1);
		
	}

	 $i=($i<7)? 7:$i;
	

	my $mtable = def_table(10, 1, TRUE);
	$mtable->attach_defaults($scrolled_win,0,1,0,9);
	$mtable->attach_defaults($okbox,0,1,9,10);
	
	$window->add ($mtable);
	$window->show_all();




	 $ok->signal_connect('clicked'=>sub{
			$window->destroy;
			set_state($soc_state,"interface_selected",1);
			 
		 } );

	


}



sub is_integer {
   defined $_[0] && $_[0] =~ /^[+-]?\d+$/;
}


#############
#  add_intfc_to_ip
##############


sub add_intfc_to_ip{
	my ($intfc,$ipgen,$infc_name,$infc_type,$info,$soc_state)=@_;
	if($infc_type eq 'socket'){ 
		my ($connection_num,$connect_to)=$intfc->get_socket($infc_name);
		$ipgen->ipgen_add_soket($infc_name,'num',1,$connection_num);
	}
	else { $ipgen->ipgen_add_plug($infc_name,'num',1);}
	set_state($soc_state,"interface_selected",1);
	
}	


#################
#	get_list_of_all_interfaces
################

sub get_list_of_all_interfaces{
	my ($ipgen)=@_;
	my @sockets	=$ipgen->ipgen_list_sokets();
	my @plugs	=$ipgen->ipgen_list_plugs();
	my @interfaces=('IO');
	my @interfaces_name=('IO');
	foreach my $p( @sockets){
		my ($type,$value)=  $ipgen->ipgen_get_socket($p);
		if($type eq 'num'){
				for(my $i=0; $i<$value; $i++){
					push(@interfaces,"socket:$p\[$i\]");
					my $socket_name=$ipgen->ipgen_get_socket_name($p,$i);
					push(@interfaces_name,"socket:$socket_name");
				}#for	
			
		}#if
		else {
			push(@interfaces,"socket:$p\[array\]");
			my $socket_name=$ipgen->ipgen_get_socket_name($p,0);
			push(@interfaces_name,"socket:$socket_name");
			
			
		}#else		
		
	}#foreach	
	foreach my $p( @plugs){
		my ($type,$value)=  $ipgen->ipgen_get_plug($p);
		if($type eq 'num'){
				for(my $i=0; $i<$value; $i++){
					push(@interfaces,"plug:$p\[$i\]");
					my $plug_name=$ipgen->ipgen_get_plug_name($p,$i);
					push(@interfaces_name,"plug:$plug_name");
					
				}#for	
			
		}#if
		else {
			my $plug_name=$ipgen->ipgen_get_plug_name($p,0);
			push(@interfaces,"plug:$p\[array\]");
			push(@interfaces_name,"plug:$plug_name");
			
			
		}#else		
		
	}#foreach	
	return (\@interfaces_name,\@interfaces);
	
}	

sub gen_intfc_port_combo{
	my ($intfc,$ipgen,$intfc_name,$porttype,$portname)=@_;
	
	my($type,$name,$num)= split("[:\[ \\]]", $intfc_name);
	my @all_ports;
	my @ports;
	
	if($type eq 'socket'){
		@all_ports= $intfc->get_socket_port_list($name);
		foreach my $p(@all_ports){
			my ($r,$t,$c)=$intfc->get_port_info_of_socket($name,$p);
			if ($t eq $porttype){ push (@ports,$p);}
		}	
		
	}elsif($type eq 'plug'){
		@all_ports= $intfc->get_plug_port_list($name);
		
		foreach my $p(@all_ports){
			my ($r,$t,$c)=$intfc->get_port_info_of_plug($name,$p);
			#print "($t eq $porttype)\n";
			if ($t eq $porttype){ push (@ports,$p);}
		}	
		
	}
	else  {
		@ports=('IO');
	}
	my $saved_intfc_port=$ipgen->ipgen_get_port_intfc_port($portname);	
	my $pos=(defined $saved_intfc_port ) ? get_scolar_pos( $saved_intfc_port,@ports) : undef;
	if (!defined $pos){
		$pos=find_the_most_similar_position( $portname       ,@ports);
		$ipgen->ipgen_set_port_intfc_port($portname,$ports[$pos]);
		#print "$ports[$pos]\n;"
	}		
	my $intfc_port_combo=gen_combo(\@ports,$pos);	
	$intfc_port_combo->signal_connect('changed'=> sub {
		my $intfc_port=$intfc_port_combo->get_active_text();
		$ipgen->ipgen_set_port_intfc_port($portname,$intfc_port);
		
	});
	
	
	return  $intfc_port_combo;
}



sub port_info_box {
	my($intfc,$ipgen,$soc_state,$info)=@_;
	my $table=def_table(8,10,TRUE);
	my @ports=$ipgen->ipgen_list_ports;
	my $row=0;
	my ($name_ref,$ref)=get_list_of_all_interfaces($ipgen);
	my @interfaces_name=@{$name_ref};
	my @interfaces=@{$ref};
	#print "@interfaces_name\n";
	
	$table->attach_defaults (gen_label_in_left(" Type "), 0, 1, $row, $row+1);
	$table->attach_defaults (gen_label_in_left(" Port name "), 1, 3, $row, $row+1);
	$table->attach_defaults (gen_label_in_left(" Interface name "), 3, 5, $row, $row+1);
	$table->attach_defaults (gen_label_in_center(" Range "), 5, 7, $row, $row+1);	
	$table->attach_defaults (gen_label_in_left(" Interface port "), 7, 9, $row, $row+1);
	$row++;
	#print  @interfaces;
	my @ports_order=$ipgen->ipgen_get_ports_order();
	if(scalar(@ports_order) >1 ){ @ports= @ports_order}
	



	foreach my $p( @ports){
		my ($range,$type,$intfc_name,$intfc_port)=$ipgen->ipgen_get_port($p);
		#my $label_name=gen_label_in_left(" $p ");
		my $name_entry=gen_entry($p);
		my $label_type=gen_label_in_left(" $type ");
		my $range_entry=gen_entry($range);
		my $pos=(defined $intfc_name ) ? get_scolar_pos( $intfc_name,@interfaces) : 0;
		if (!defined $pos){
			$pos=0;
			$ipgen->ipgen_set_port_intfc_name($p,'IO');
		};
		my $intfc_name_combo=gen_combo(\@interfaces_name,$pos);
		my $intfc_port_combo=gen_intfc_port_combo($intfc,$ipgen,$intfc_name,$type,$p);
		
		
		$table->attach_defaults ($label_type, 0, 1, $row, $row+1);
		$table->attach_defaults ($name_entry, 1, 3, $row, $row+1);
		$table->attach_defaults ($intfc_name_combo,3, 5, $row, $row+1);
		$table->attach_defaults ($range_entry, 5, 7, $row, $row+1);
		$table->attach_defaults ($intfc_port_combo,7, 9, $row, $row+1);
		$intfc_name_combo->signal_connect('changed'=>sub{
			my $intfc_name=$intfc_name_combo->get_active_text();
			my $pos=  get_scolar_pos( $intfc_name,@interfaces_name);
			#my($type,$name,$num)= split("[:\[ \\]]", $intfc_name);
			#print "$type,$name,$num\n";
			$ipgen->ipgen_set_port_intfc_name($p,$interfaces[$pos]);
			set_state($soc_state,"interface_selected",1);
		});
		$range_entry->signal_connect('changed'=>sub{
			my $new_range=$range_entry->get_text();
			$ipgen->ipgen_add_port($p,$new_range,$type,$intfc_name,$intfc_port);
		});
			
		$row++;
	}	
	
	
	
	
	return $table;
	
	
}






sub generate_ip{
	my $ipgen=shift;
	my $name=$ipgen->ipgen_get("module_name");
	my $category=$ipgen->ipgen_get("category");
	my $ip_name= $ipgen->ipgen_get("ip_name");
	#check if name has been set
	if(defined ($name) && defined ($category)){
		if (!defined $ip_name) {$ip_name= $name}
		#check if any source file has been added for this ip
		my @l=$ipgen->ipgen_get_list("hdl_files");
		if( scalar @l ==0){
			my $mwindow;
			my $dialog = Gtk2::MessageDialog->new ($mwindow,
                                      'destroy-with-parent',
                                      'question', # message type
                                      'yes-no', # which set of buttons?
                                      "No hdl library file has been set for this IP. Do you want to generate this IP?");
  			my $response = $dialog->run;
  			if ($response eq 'yes') {
      			# Write
				open(FILE,  ">lib/ip/$ip_name.IP") || die "Can not open: $!";
				print FILE Data::Dumper->Dump([\%$ipgen],[$name]);
				close(FILE) || die "Error closing file: $!";
				my $message="IP $ip_name has been generated successfully" ;
				message_dialog($message);
				exec($^X, $0, @ARGV);# reset ProNoC to apply changes
  			}
  			$dialog->destroy;


  			#$dialog->show_all;
			
		}else{
			# Write
			open(FILE,  ">lib/ip/$ip_name.IP") || die "Can not open: $!";
			print FILE Data::Dumper->Dump([\%$ipgen],[$name]);
			close(FILE) || die "Error closing file: $!";
			my $message="IP $ip_name has been generated successfully" ;
			message_dialog($message);
			exec($^X, $0, @ARGV);# reset ProNoC to apply changes
		}
	}else{
		my $message;
		if(!defined ($name)){ $message="Input file has not been selected yet.\nNothing has been generated!" ;}
		elsif(!defined ($category)){ $message="Category must be defined!" ;}
		message_dialog($message);
		
	}		
#$hashref = retrieve('file');
	
	
	
return 1;	
}	




#########
#	load_ip
########

sub load_ip{
	my ($ipgen,$soc_state)=@_;
	my $file;
	my $dialog = Gtk2::FileChooserDialog->new(
            	'Select a File', undef,
            	'open',
            	'gtk-cancel' => 'cancel',
            	'gtk-ok'     => 'ok',
        	);

	my $filter = Gtk2::FileFilter->new();
	$filter->set_name("IP");
	$filter->add_pattern("*.IP");
	$dialog->add_filter ($filter);
	my $dir = Cwd::getcwd();
	$dialog->set_current_folder ("$dir/lib/ip")	;			


	if ( "ok" eq $dialog->run ) {
		$file = $dialog->get_filename;
		my ($name,$path,$suffix) = fileparse("$file",qr"\..[^.]*$");
		if($suffix eq '.IP'){
			$ipgen->ipgen_add("file_name",$file);	
			set_state($soc_state,"load_file",0);
		}					
     }
     $dialog->destroy;

	

}






############
#	get_source_file
###########



sub get_source_file{
	my($ipgen,$soc_state,$info,$page,$title,$dest,$page_info_ref)=@_;

		
	my $var_list='${parameter_name}: Verilog module parameter values. 

${BASE}: is the wishbone base addresse(s) and will be added during soc generation to system.h. If more than one slave wishbone bus are used  define them as ${BASE0}, ${BASE1}... . 
      
${IP}: is the peripheral device instance name.

${CORE}: is the peripheral device module name.';
	my $var_help=gen_button_message($var_list,"icons/info.png","Global variables");
	
	my($width,$hight)=max_win_size();
	my $window = def_popwin_size($width*2/3,$hight*2/3,$title);
	
	my $notebook=source_notebook($ipgen,$soc_state,$info,$window,$page,$dest,$page_info_ref);
	my $table=def_table (15, 15, TRUE);						
	
		
	$table->attach_defaults ($var_help, 5, 7, 0, 1);
	$table->attach_defaults ($notebook , 0, 15, 1, 15);
		
	$window->add($table);
	$window->show_all;	
	return $window;	  
	
}

##########
# source_notebook
##########

sub source_notebook{
	my($ipgen,$soc_state,$info,$window,$page,$dest,$page_info_ref)=@_;
	my $notebook = Gtk2::Notebook->new;
	my %page_info=%{$page_info_ref};
	foreach my $p (sort keys %page_info){
		my $page_ref;
		$page_ref=get_file_folder($ipgen,$soc_state,$info,$window,$p,$page_info_ref) if($page_info{$p}{filed_type} eq "exsiting_file/folder"); 
		$page_ref=get_file_folder($ipgen,$soc_state,$info,$window,$p,$page_info_ref) if($page_info{$p}{filed_type} eq "file_generators"); 
		$page_ref=get_file_content($ipgen,$soc_state,$info,$window,$page_info{$p},$page_info_ref) if($page_info{$p}{filed_type} eq "file_content"); 
		$notebook->append_page ($page_ref,Gtk2::Label->new_with_mnemonic ($page_info{$p}{page_name}));

	}	
	$notebook->show_all;	
	$notebook->set_current_page($page) if(defined $page);
	return $notebook;

}

##########
#  get_file_folder
#########

sub get_file_folder{
	my ($ipgen,$soc_state,$info,$window,$page,$page_info_ref)=@_;
	my %page_info=%{$page_info_ref};
	my @sw_dir = $ipgen->ipgen_get_list($page_info{$page}{filed_name});
	my $table = Gtk2::Table->new (15, 15, TRUE);	
	my $help=gen_label_help($page_info{$page}{help});	
	$table->attach_defaults($help,0,2,0,1);	
	my ($scrwin,$ok)=gen_file_list($ipgen,$page_info{$page}{filed_name},$window,$page_info{$page}{rename_file});
	
	my $label=gen_label_in_left("Selecet file(s):"); 
	my $brows=def_image_button("icons/browse.png",' Browse');
	$table->attach_defaults($label,2,4,0,1);
	$table->attach_defaults($brows,4,6,0,1);
	
	my $dir = Cwd::getcwd();
	my $project_dir	  = abs_path("$dir/../../"); #mpsoc directory address
	
	
	$brows->signal_connect("clicked"=> sub {
		my @files;
        my $dialog = Gtk2::FileChooserDialog->new(
            	'Select a File', 
            	 undef,
            	 'open',
            	'gtk-cancel' => 'cancel',
            	'gtk-ok'     => 'ok',
        	);
        	
        	my $filter = Gtk2::FileFilter->new();
			my $dir = Cwd::getcwd();
			$dialog->set_current_folder ("$dir/..")	;	
			$dialog->set_select_multiple(TRUE);

        	if ( "ok" eq $dialog->run ) {
            		@files = $dialog->get_filenames;            		
            		@sw_dir=$ipgen->ipgen_get_list($page_info{$page}{filed_name});
            		foreach my $p (@files){
            			#remove $project_dir form beginig of each file
            			$p =~ s/$project_dir//; 
				my ($name,$path,$suffix) = fileparse("$p",qr"\..[^.]*$");
				$p=$p.'frename_sep_t'.$name.$suffix if (defined $page_info{$page}{rename_file}); 
            			if(! grep (/^$p$/,@sw_dir)){push(@sw_dir,$p)};
            			
            		}            		
            		$ipgen->ipgen_add($page_info{$page}{filed_name},\@sw_dir);
            		get_source_file($ipgen,$soc_state,$info,$page,"Add software file(s)","SW",$page_info_ref);
            		$window->destroy;
            		
       		 }
       		$dialog->destroy;
	} );# # ,\$entry);
	
	if($page_info{$page}{folder_en} eq 1){
		my $label2=gen_label_in_left("Selecet folder(s):"); 
		my $brows2=def_image_button("icons/browse.png",' Browse');
		$table->attach_defaults($label2,7,9,0,1);
		$table->attach_defaults($brows2,9,11,0,1);

		$brows2->signal_connect("clicked"=> sub {
			my @files;
		
			 my $dialog = Gtk2::FileChooserDialog->new(
		    	'Select Folder(s)', 
		    	undef,
					'select-folder',
		    	'gtk-cancel' => 'cancel',
		    	'gtk-ok'     => 'ok',
			);
	       		
			my $filter = Gtk2::FileFilter->new();
				my $dir = Cwd::getcwd();
				$dialog->set_current_folder ("$dir/..")	;	
				$dialog->set_select_multiple(TRUE);

			if ( "ok" eq $dialog->run ) {
		    		@files = $dialog->get_filenames;
		    		
		    		@sw_dir=$ipgen->ipgen_get_list($page_info{$page}{filed_name});
		    		foreach my $p (@files){
		    			#remove $project_dir form beginig of each file
		    			$p =~ s/$project_dir//;  
		    			if(! grep (/^$p$/,@sw_dir)){push(@sw_dir,$p)};
		    			
		    		}
		    		
		    		$ipgen->ipgen_add($page_info{$page}{filed_name},\@sw_dir);
		    		get_source_file($ipgen,$soc_state,$info,$page,"Add software file(s)","SW",$page_info_ref);
		    		$window->destroy;
		    		
		    		
						#$$entry_ref->set_text($file);
					
		    		#print "file = $file\n";
	       		 }
	       		$dialog->destroy;
	       		


		} );# # ,\$entry);
	}	
	
	
	
	$table->attach_defaults($scrwin,0,15,1,14);
	$table->attach_defaults($ok,6,9,14,15);
	
	return ($table)

	
}	



###########
#	get_file_content
#########

sub get_file_content{
	my ($ipgen,$soc_state,$info,$window,$page_info_ref)=@_;
	my %page_info=%{$page_info_ref};
	#my $hdr = $ipgen->ipgen_get_hdr();
	my  $hdr = $ipgen-> ipgen_get($page_info{filed_name});	
	my $table = Gtk2::Table->new (14, 15, TRUE);
	#my $window=def_popwin_size(600,600,"Add header file");
	my ($scrwin,$text_view)=create_text();

	my $help=gen_label_help($page_info{help}); 
	$table->attach_defaults($help,0,8,0,1);
	$table->attach_defaults($scrwin,0,15,1,14);
	my $text_buffer = $text_view->get_buffer;
	if(defined $hdr) {$text_buffer->set_text($hdr)};	
	
	my $ok=def_image_button("icons/select.png",' Save ');
	$ok->signal_connect("clicked"=> sub {#		  
		 my $text = $text_buffer->get_text($text_buffer->get_bounds, TRUE);
		 $ipgen->ipgen_add($page_info{filed_name},$text);	
		 $window->destroy;
				
	});

	$table->attach_defaults($ok,6,9,14,15);
	return ($table);
	
}	
















############
#	get_unused_intfc_ports_list
###########

sub get_unused_intfc_ports_list {
	my($intfc,$ipgen,$soc_state,$info)=@_;
	my @ports=$ipgen->ipgen_list_ports;
	my ($name_ref,$ref)=get_list_of_all_interfaces($ipgen);
	my @interfaces_name=@{$name_ref};
	my @interfaces=@{$ref};
	$ipgen->ipgen_remove("unused");
	foreach my $intfc_name (@interfaces)
	{
		#print "$intfc_name\n";
		my($type,$name,$num)= split("[:\[ \\]]", $intfc_name);
		my @all_ports;
		if($type eq 'socket'){
			@all_ports= $intfc->get_socket_port_list($name);
			
		}elsif($type eq 'plug'){
			@all_ports= $intfc->get_plug_port_list($name);
		}
		foreach my $p(@all_ports){
				my $r= check_intfc_port_exits($intfc,$ipgen,$soc_state,$info,$intfc_name,$p);
				if ($r eq "0"){
					$ipgen->ipgen_add_unused_intfc_port( $intfc_name,$p );
				}
				
		}	

	}
}

sub check_intfc_port_exits{
	my($intfc,$ipgen,$soc_state,$info,$intfc_name,$intfc_port)=@_;
	my @ports=$ipgen->ipgen_list_ports;
	
	
	my $result="0";
	foreach my $p( @ports){
		my ($range,$type,$assigned_intfc_name,$assigned_intfc_port)=$ipgen->ipgen_get_port($p);
		#print "if($intfc_name eq $assigned_intfc_name && $intfc_port eq $assigned_intfc_port);\n";
		
		if($intfc_name eq $assigned_intfc_name && $intfc_port eq $assigned_intfc_port){
			if($result eq "1"){# one interface port has been connected to multiple IP port
				
			} 
			$result = "1";
						
		}
	}
	return $result;
	
}

















############
#    main
############
sub ipgen_main{
	my $ipgen=shift;
	my $intfc=interface->interface_new();
	if(!defined $ipgen) { $ipgen=ip_gen->ip_gen_new();}
	#my $ipgen = eval { do 'lib/ip/wishbone_bus.IP' };
	my $soc_state=  def_state("ideal");
	# main window
	#my $window = def_win_size(1000,800,"Top");
	#  The main table containg the lib tree, selected modules and info section 
	my $main_table = def_table (15, 12, FALSE);
	
	# The box which holds the info, warning, error ...  mesages
	my ($infobox,$info)= create_text();	
	
	
	my $refresh_dev_win = Gtk2::Button->new_from_stock('ref');
	my $generate = def_image_button('icons/gen.png','Generate');
	my $genbox=def_hbox(TRUE,5);
	$genbox->pack_start($generate,   FALSE, FALSE,3);
	
	# A tree view for holding a library
	my $tree_box = create_interface_tree  ($info,$intfc,$ipgen,$soc_state);


	my $file_info=show_file_info($ipgen,$soc_state,$info,\$refresh_dev_win);
	my $port_info=show_port_info($intfc,$ipgen,$soc_state,$info,\$refresh_dev_win);
	my $intfc_info=show_interface_info($intfc,$ipgen,$soc_state,$info,\$refresh_dev_win);
	
	
	my $open = def_image_button('icons/browse.png','Load IP');
	my $openbox=def_hbox(TRUE,0);
	$openbox->pack_start($open,   FALSE, FALSE,0);

	$main_table->set_row_spacings (4);
	$main_table->set_col_spacings (1);
	
	#my  $device_win=show_active_dev($soc,$lib,$infc,$soc_state,\$refresh_dev_win,$info);
	
	
	#$table->attach_defaults ($event_box, $col, $col+1, $row, $row+1);
	$main_table->attach_defaults ($tree_box , 0, 2, 0, 13);
	$main_table->attach_defaults ($file_info , 2, 12, 0, 2);
	$main_table->attach_defaults ($intfc_info , 2, 12, 2, 7);
	
	$main_table->attach_defaults ($port_info  , 2, 12, 7,13);
	$main_table->attach_defaults ($infobox  , 0, 12, 13,14);
	$main_table->attach_defaults ($genbox, 6, 8, 14,15);
	$main_table->attach_defaults ($openbox,0, 1, 14,15);

	#check soc status every 0.5 second. referesh device table if there is any changes 
Glib::Timeout->add (100, sub{ 
	 
		my ($state,$timeout)= get_state($soc_state);
		if($state eq "load_file"){
			my $file=$ipgen->ipgen_get("file_name");
			my $pp= eval { do $file };
			clone_obj($ipgen,$pp);
						
			
			set_state($soc_state,"ref",1);
			
			
		}elsif ($timeout>0){
			$timeout--;
			set_state($soc_state,$state,$timeout);		
		}
		elsif( $state eq "change_parameter" ){
			get_parameter_setting($ipgen,$soc_state,$info);
			set_state($soc_state,"ideal",0);
			
			
			
		}
		elsif( $state ne "ideal" ){
			$refresh_dev_win->clicked;
			set_state($soc_state,"ideal",0);
			
			
		}	
		return TRUE;
		
		} );
	$open-> signal_connect("clicked" => sub{ 
		load_ip($ipgen,$soc_state);
	
	});		
		
	$generate-> signal_connect("clicked" => sub{ 
		get_unused_intfc_ports_list ($intfc,$ipgen,$soc_state,$info);
		generate_ip($ipgen);
		
		$refresh_dev_win->clicked;
	
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



