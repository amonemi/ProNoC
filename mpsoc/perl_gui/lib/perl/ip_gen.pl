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
use File::Path qw/make_path/;

use Gtk2;


require "widget.pl"; 
require "readme_gen.pl";




use constant DISPLY_COLUMN    => 0;
use constant CATGR_COLUMN    => 1;
use constant INTFC_COLUMN     => 2;
use constant ITAL_COLUMN   => 3;
use constant NUM_COLUMN     => 4;

################
#  check_input_file
################

sub check_input_file{
	my ($file,$ipgen,$info)=@_;
	my ($name,$path,$suffix) = fileparse("$file",qr"\..[^.]*$");
	if($suffix eq '.IP'){
		$ipgen->ipgen_add("file_name",$file);
		set_gui_status($ipgen,"load_file",0);
		
		
	}else{
		read_all_module ($file,$ipgen,$info);
	
	}	
	
	
}		


sub read_all_module{
	my ($file,$ipgen,$info)=@_;
	
	if (!defined $file) {return; }
	if (-e $file) { 
		my $vdb =  read_verilog_file($file);
		my @modules=sort $vdb->get_modules($file);
		#foreach my $p(@module_list) {print "$p\n"}
		$ipgen->ipgen_add("file_name",$file);



		$ipgen->ipgen_add("module_name",$modules[0]);
		$ipgen->ipgen_set_module_list(@modules);
		load_default_setting($ipgen,$modules[0]);
		
		
		set_gui_status($ipgen,"file_selected",1);
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
   my ($info,$intfc,$ipgen)=@_;
   my $model = Gtk2::TreeStore->new ('Glib::String', 'Glib::String', 'Glib::Scalar', 'Glib::Boolean');
   my $tree_view = Gtk2::TreeView->new;
   $tree_view->set_model ($model);
   my $selection = $tree_view->get_selection;

   $selection->set_mode ('browse');
  # $tree_view->set_size_request (200, -1);
 

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
 					("Interfaces list",
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
		add_intfc_to_ip($intfc,$ipgen,$name,'plug',\$info);
	
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
	my ($ipgen,$info,$table,$row)=@_;
	my $label = gen_label_in_left(" Select file:");
	my $entry = Gtk2::Entry->new;
	#my $open= def_image_button("icons/select.png","Open");
	my $browse= def_image_button("icons/browse.png","Browse");
	my $file= $ipgen->ipgen_get("file_name");
	if(defined $file){$entry->set_text($file);}


	
	my $entry2=labele_widget_info(" IP name:",gen_entry_object($ipgen,'ip_name',undef,undef,undef,undef));



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
					check_input_file($file,$ipgen,$info);
            		#print "file = $file\n";
       		 }
       		$dialog->destroy;
       		


	} , \$entry);
	
	
	
	
	$entry->signal_connect("activate"=>sub{
		my $file_name=$entry->get_text();
		check_input_file($file_name,$ipgen,$info);
	});
		
	$entry->signal_connect("changed"=>sub{
		show_info(\$info,"Please select the verilog file containig the interface\n");
	});
	
	$table->attach_defaults ($label, 0, 1 , $row, $row+1);
	$table->attach_defaults ($entry, 1, 8 , $row, $row+1);
	$table->attach ($browse, 8, 9, $row, $row+1,,'expand','shrink',2,2);
	$table->attach_defaults ($entry2,  9, 11, $row, $row+1);
	
	
	
}




sub select_module{
	my ($ipgen,$info,$table,$row)=@_;

	
	my @modules= $ipgen->ipgen_get_module_list();
	my $saved_module=$ipgen->ipgen_get("module_name");
	my $pos=(defined $saved_module ) ? get_scolar_pos( $saved_module,@modules) : 0;
	my $combo = gen_combo(\@modules, $pos);
	my $top_module=labele_widget_info("  Select\n module:",$combo);




	my $param= def_image_button("icons/setting.png","Parameter\n   setting");
	my $def= def_image_button("icons/setting.png","Definition\n file setting");
	
	
	
	#Category	
	my $ip = ip->lib_new ();
	my @categories= $ip->ip_get_categories();
	$ip =undef;
	my $saved_category=$ipgen->ipgen_get("category");
	if(defined $saved_category ){	push(@categories,$saved_category) if(!( grep /^$saved_category$/, @categories ));}
	my $content=join( ',', @categories);	
	my $combentry=gen_comboentry_object ($ipgen,'category',undef,$content,$saved_category,undef,undef);
	my $category=labele_widget_info("  Select\n Category:",$combentry,"Select the IP category form the given list or you can add a new category.");


	
	my $ipinfo= def_image_button("icons/add_info.png","    IP\n Description");
	my $header_h= def_image_button("icons/h_file.png","Add Software\n      files");
	my $lib_hdl= def_image_button("icons/add-notes.png","Add HDL\n     files");
	

	#$table->attach_defaults ($top_module, 0, 1 , $row, $row+1);
	$table->attach ($top_module, 0, 4 , $row,$row+1,'fill','shrink',2,2);
	$table->attach ($param, 4, 6 , $row, $row+1,'expand','shrink',2,2);
		
	$table->attach ($category, 6, 8 , $row, $row+1,'expand','shrink',2,2);
	$table->attach ($ipinfo, 8, 9 , $row, $row+1,'expand','shrink',2,2);
	$table->attach ($header_h, 9, 10 , $row, $row+1,'expand','shrink',2,2);
	$table->attach ($lib_hdl, 10, 11 , $row, $row+1,'expand','shrink',2,2);
	
	
	$combo->signal_connect("changed"=> sub{
		
		my $module= $combo->get_active_text();
		load_default_setting($ipgen,$module); 
		set_gui_status($ipgen,'intfc_changed',0);
		
		
	});
	
	$param->signal_connect("clicked"=> sub{
		get_parameter_setting($ipgen,$info);
		
		
	});	

	$def->signal_connect("clicked"=> sub{
		get_def_setting($ipgen,$info);
		
		
	});	
	
	$ipinfo->signal_connect("clicked"=> sub{
		get_Description($ipgen,$info);		
		
	});	
	$header_h->signal_connect("clicked"=> sub{
		my %page_info;
		my $help1="The files and folder that selected here will be copied in genertated processing tile SW folder.";
		my $help2="The file listed here can contain some variable with \${var_name} format. The file genertor will replace them with their values during file generation. The variable can be selected from above listed global vairables";
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

		$page_info{1}{page_name} = "_Add files contain variables";
		$page_info{1}{filed_name}= "gen_sw_files";
		$page_info{1}{filed_type}= "file_with_variables";
		$page_info{1}{rename_file}=1; 
		$page_info{1}{folder_en}=0;
		$page_info{1}{help}=$help2;

		$page_info{2}{page_name} = "_Add to tile.h";
		$page_info{2}{filed_name}= "system_h";
		$page_info{2}{filed_type}= "file_content";
		$page_info{2}{rename_file}=undef; 
		$page_info{2}{folder_en}=0;
		$page_info{2}{help}=$help3;


		get_source_file($ipgen,$info,0,"Add software file(s)","SW",\%page_info);
		#get_software_file($ipgen,$info,0);		
		
	});	
	$lib_hdl->signal_connect("clicked"=> sub{
		my $help1="The files and folder that selected here will be copied in genertated processing tile RTL  folder.";
		my $help2="The file listed here can contain some variable with \${var_name} format. The file genertor will replace them with their values during file generation. The variable can be selected from above listed global vairables";
		my %page_info;
		$page_info{0}{page_name} = "_Add exsiting HDL file/folder";
		$page_info{0}{filed_name}= "hdl_files";
		$page_info{0}{filed_type}= "exsiting_file/folder";
		$page_info{0}{rename_file}=undef;
		$page_info{0}{folder_en}=1; 
		$page_info{0}{help}=$help1;

		$page_info{1}{page_name} = "_Add files contain variables";
		$page_info{1}{filed_name}= "gen_hw_files";
		$page_info{1}{filed_type}= "file_with_variables";
		$page_info{1}{rename_file}=1; 
		$page_info{1}{folder_en}=0;
		$page_info{1}{help}=$help2;

		get_source_file($ipgen,$info,0,"Add HDL file(s)", "hw",\%page_info);

		#get_hdl_file($ipgen,$info);
				
		
	});	
}

sub load_default_setting{
	my ($ipgen,$module)=@_; 
	my $file= $ipgen->ipgen_get("file_name");
	$ipgen->ipgen_add("module_name",$module);
	my $vdb =read_verilog_file($file);
	my %parameters = $vdb->get_modules_parameters_not_local($module);
	my @parameters_order= $vdb->get_modules_parameters_not_local_order($module);
	my @ports_order=$vdb->get_module_ports_order($module);
	#print "@port_order\n";
	
	#add default parameter setting
	$ipgen->ipgen_remove_all_parameters();
	foreach my $p (keys %parameters){
			#print "$p\n";
			my $v = $parameters{$p};
			$v =~s/[\n]//gs;
			$ipgen->ipgen_add_parameter($p,$v,'Fixed','','Parameter',1);
			
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
	my($ipgen,$info)=@_;
	my $table=def_table(2,11,FALSE);
	my $table1=def_table(1,11,FALSE);
	my $table2=def_table(1,11,FALSE);
	ip_file_box ($ipgen,$info,$table1,0);
	select_module($ipgen,$info,$table2,0);
	$table->attach_defaults($table1,0,11,0,1);
	$table->attach_defaults($table2,0,11,1,2);
	return $table;
	
	
}




sub show_file_info{
	my($ipgen,$info,$refresh_ref)=@_;
	my $table = file_info_box($ipgen,$info,$info);
	my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);
	$scrolled_win->set_policy( "automatic", "never" );
	$scrolled_win->add_with_viewport($table);
	


	$$refresh_ref-> signal_connect("clicked" => sub{ 
		$table->destroy;
		$table = file_info_box($ipgen,$info,$info);
		
		$scrolled_win->add_with_viewport($table);
		$table->show;
		$scrolled_win->show_all;
			
		
		
	});
	
	return $scrolled_win;
	
	
	
}	


sub show_port_info{
	my($intfc,$ipgen,$info,$refresh_ref)=@_;
	my $table = port_info_box($intfc,$ipgen,$info,$info);
	my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);
	$scrolled_win->set_policy( "automatic", "automatic" );
	$scrolled_win->add_with_viewport($table);
	


	$$refresh_ref-> signal_connect("clicked" => sub{ 
		$table->destroy;
		$table = port_info_box($intfc,$ipgen,$info,$info);
		
		$scrolled_win->add_with_viewport($table);
		$table->show;
		$scrolled_win->show_all;
		
		
		
		
	});
	
	return $scrolled_win;
	
}


sub show_interface_info{
	my($intfc,$ipgen,$info,$refresh_ref)=@_;
	my $table = interface_info_box($intfc,$ipgen,$info,$info);
	my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);
	$scrolled_win->set_policy( "automatic", "automatic" );
	$scrolled_win->add_with_viewport($table);
	


	$$refresh_ref-> signal_connect("clicked" => sub{ 
		$table->destroy;
		select(undef, undef, undef, 0.1); #wait 10 ms
		$table = interface_info_box($intfc,$ipgen,$info,$info);
		
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
	my ($ipgen,$info)=@_;
	
	
	my $file= $ipgen->ipgen_get("file_name");
	if (!defined $file) {
			message_dialog("The input verilog file is empty");
			return;
			
	}		
	my $module = $ipgen->ipgen_get("module_name");
	
	
	my $window =  def_popwin_size(85,50,"Define parameters detail",'percent');	
	
	
	
	
	my @widget_type_list=("Fixed","Entry","Combo-box","Spin-button");
	my @param_type_list=("Parameter","Localparam","Don't include");
	my $type_info="Define the parameter type: 

Fixed: The parameter is fixed and get the default value. Users can not see or change the parameter value.

Entry: The parameter value is received via entry. The user can type anything.

Combo-box: The parameter value can be selected from a list of predefined value.

Spin-button: The parameter is numeric and will be obtained using spin button.";
	my $content_info='
For Fixed and Entry leave it empty.
For Combo box define the parameters which must be shown in combo box as: "PAEAMETER1","PARAMETER2"...,"PARAMETERn".
For Spin button define it as "minimum, maximum, step" e.g 0,10,1.';
	my $param_info='Define how parameter is included in the top module containig this IP core.';

	my $redefine_info='
	If checked, the defined parameter/localparam in SoC will be passed to the IP core';

	#TABLE
	my $table = Gtk2::Table->new (12, 8, FALSE);
	my @positions=(0,1,2,3,4,5,6,7,8);
	my $col=0;
	#title
	my @title;
	$title[0]=gen_label_in_center("Parameter name");
	$title[1]=gen_label_in_center("Default value");
	$title[2]=gen_label_help($type_info,"Widget type");
	$title[3]=gen_label_help($content_info,"Widget content");
	$title[4]=gen_label_help($param_info,"Type");
	$title[5]=gen_label_help($redefine_info,"");
	$title[6]=gen_label_help("You can add aditional information about this parameter.","info");
	$title[7]=gen_label_in_center("add/remove");
	
	
	foreach my $t (@title){
		$table->attach ($title[$col], $positions[$col], $positions[$col+1], 0, 1,'expand','shrink',2,2); $col++;

	}
	

	
	
	
	
	

	my @parameters=$ipgen->ipgen_get_all_parameters_list();
	my @params_order= $ipgen->ipgen_get_list("parameters_order");
	if((@params_order)) {@parameters=@params_order;}
	
	my $ok = def_image_button('icons/select.png','OK');
	

	my ($b,$new_param)= def_h_labeled_entry("Add new parameter name:");
	my $add = def_image_button('icons/plus.png','Add parameter');
	my $addbox=def_hbox(FALSE,0);
	$addbox->pack_start($b,FALSE, FALSE,0);
	$addbox->pack_start($add,   FALSE, FALSE,0);
	
	my @allowed;
	
	my $row=1;
	my $error;
	push(@parameters,"#new#");
	foreach my $p (@parameters) {
		my ($saved_default,$saved_widget_type,$saved_content,$saved_info,$vfile_param_type,$redefine_param)=  $ipgen->ipgen_get_parameter_detail($p);
		#print 	"($saved_default,$saved_type,$saved_content)\n";
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

		my $default_entry= gen_entry($saved_default);
		my $pos=(defined $saved_widget_type ) ? get_scolar_pos( $saved_widget_type,@widget_type_list) : 0;
		my $widget_type_combo=gen_combo(\@widget_type_list, $pos);
		my $content_entry= gen_entry($saved_content);


		
		$vfile_param_type= "Don't include" if (!defined $vfile_param_type );
		$vfile_param_type= "Parameter"  if ($vfile_param_type eq 1);
		$vfile_param_type= "Localparam" if ($vfile_param_type eq 0);
		$pos=get_scolar_pos($vfile_param_type,@param_type_list);
		my $check_param= gen_combo(\@param_type_list, $pos);


		#$check_param->set_active($vfile_param_type) if(defined $vfile_param_type );
		my $check_redefine= Gtk2::CheckButton->new('Redefine');
		$check_redefine->set_active(1) ;
		$check_redefine->set_active($redefine_param) if(defined $redefine_param );		
		




		#my $check= Gtk2::CheckButton->new;
		#$check->set_active($vfile_param_type) if(defined $vfile_param_type );


		my $info=def_image_button("icons/add_info.png");
		#print "\$vfile_param_type =$vfile_param_type\n";
		
		$col=0;
		my @all_widget=($param_name,$default_entry,$widget_type_combo,$content_entry,$check_param,$check_redefine,$info,$add_remove);
		foreach my $t (@all_widget){
			$table->attach ($t, $positions[$col], $positions[$col+1], $row, $row+1,'expand','shrink',2,2);$col++;

		}		
		
		
		$info->signal_connect (clicked => sub{
			
			get_param_info($ipgen,\$saved_info);
		});
		
				
		$ok->signal_connect (clicked => sub{
			if($p ne "#new#"){		
				my $default=$default_entry->get_text();
				my $type= $widget_type_combo->get_active_text();
				my $content=$content_entry->get_text();
				my $vfile_param_type=$check_param->get_active_text();					
				my $check_result=$check_redefine->get_active();
				my $redefine_param=($check_result eq 1)? 1:0;
				$ipgen->ipgen_add_parameter($p,$default,$type,$content,$saved_info,$vfile_param_type,$redefine_param);
				
				if 	($type eq "Spin-button"){ 
					my @d=split(",",$content);
					 if( scalar @d != 3){
						$error=$error."wrong content setting for parameter $p\n" ;
						print "$error";
					}
				}


			}
		});
		$add_remove->signal_connect (clicked => sub{
			if($p eq "#new#"){ #add new parameter
				my $param= $param_name->get_text();
				$param=remove_all_white_spaces($param);
			        
				if( length($param) ){
					my $default=$default_entry->get_text();
					my $type=$widget_type_combo->get_active_text();
					my $content=$content_entry->get_text();
					my $vfile_param_type=$check_param->get_active_text();	
					my $check_result=$check_redefine->get_active();
					my $redefine_param=($check_result eq 1)? 1:0;
					$ipgen->ipgen_add_parameter($param,$default,$type,$content,$saved_info,$vfile_param_type,$redefine_param);
					$ipgen->ipgen_push_parameters_order($param);
					set_gui_status($ipgen,"change_parameter",0);
					$ok->clicked;
					#$window->destroy();
				}

			} else { #remove the parameter
				$ipgen->ipgen_remove_parameter($p);
				$ipgen->ipgen_remove_parameters_order($p);
				$p = "#new#";
				set_gui_status($ipgen,"change_parameter",0);
				$ok->clicked;
					#$window->destroy();
	
			}
			#my $param_name=$new_param->get_text();
			#	if( length($param_name) ){
			#		print "$param_name\n";
			#		$ipgen->ipgen_add_parameter($param_name,undef);
			#		set_gui_status($ipgen,"change_parameter",0);
			#		$window->destroy();
			
		});

		
		
	$row++;	
	}
	



	
	my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);
	$scrolled_win->set_policy( "automatic", "automatic" );
	$scrolled_win->add_with_viewport($table);




	
	
	

	$add->signal_connect (clicked => sub{
		my $param_name=$new_param->get_text();
		if( length($param_name) ){
			#print "$param_name\n";
			$ipgen->ipgen_add_parameter($param_name,undef);
			set_gui_status($ipgen,"change_parameter",0);
			$window->destroy();
		}

#/*******************************************************************************************************************************/

	});
	
	$ok->signal_connect (clicked => sub{

		


				
		
		if (defined $error){
			message_dialog("$error");
			$error=undef;
		}else {
			$window->destroy();
		}

	});
	
	my $mtable = def_table(10, 1, FALSE);
	$mtable->attach_defaults($scrolled_win,0,1,0,9);
	$mtable->attach($ok,0,1,9,10,'expand','shrink',2,2);
	
	$window->add ($mtable);
	$window->show_all();
	
	
	
}




############
#  get_def_setting
##########
sub get_def_setting { 
	my ($ipgen,$info)=@_;
	my $table = Gtk2::Table->new (15, 15, TRUE);
	my $table2 = Gtk2::Table->new (15, 15, TRUE);
	my $window =  def_popwin_size(70,70,"Add definition file",'percent');
	my $ok=def_image_button("icons/select.png",' Ok ');
	my $scrwin=  new Gtk2::ScrolledWindow (undef, undef);
	$scrwin->set_policy( "automatic", "automatic" );
	$scrwin->add_with_viewport($table2);

	my $label=gen_label_help("You ","Selecet the Verilog file containig the definitions."); 
	my $brows=def_image_button("icons/browse.png",' Browse');
	$table->attach_defaults($label,0,10,0,1);
	$table->attach($brows,10,12,1,2,'expand','shrink',2,2);
	$table->attach_defaults($scrwin,0,15,2,14);
	$table->attach($ok,6,9,14,15,'expand','shrink',2,2);

	$window->add($table);
	$window->show_all;


}


###########
#	get description
#########

sub get_Description{
	my ($ipgen,$info)=@_;
	my $description = $ipgen->ipgen_get("description");	
	my $table = Gtk2::Table->new (15, 15, FALSE);
	my $window =  def_popwin_size(40,40, "Add description",'percent');
	my ($scrwin,$text_view)=create_text();
	#my $buffer = $textbox->get_buffer();
	my $ok=def_image_button("icons/select.png",' Ok ');
	$table->attach_defaults(gen_label_help("User can open the PDF file when oppening IP parameter setting","IP Documentation file in PDF"),0,7,0,1);
	$table->attach_defaults(gen_label_help("Description will be shown on IP generator text view when selecting this IP","Short Description"),5,10,1,2);
	$table->attach_defaults(get_file_name_object ( $ipgen, 'description_pdf',undef,"pdf",undef),7,15,0,1);
	$table->attach_defaults($scrwin,0,15,2,14);
	$table->attach($ok,6,9,14,15,'expand','shrink',2,2);
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
	

	my $table=def_table(10,10,FALSE);#	my ($row,$col,$homogeneous)=@_;
	my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);
	my $ok=def_image_button("icons/select.png",' Ok ');

	$scrolled_win->set_policy( "automatic", "automatic" );
	$scrolled_win->add_with_viewport($table);
	$table->attach  (gen_label_in_center("File path"), 0, 5 , 0, 1,'expand','shrink',2,2);
   	$table->attach (gen_label_help("The target name can contain any of Global variables e.g \$IP\$.h","Copy as"), 5, 9 , 0, 1,'expand','shrink',2,2) if(defined $rename_file_en);
	my $col=0;
        my $row=1;
	my @files=  $ipgen->ipgen_get_list($list_name); #@{$ref};
	my $file_num= scalar @files;	
	foreach my $p(@files){
			my ($path,$rename)=split('frename_sep_t',$p); 
			my $entry=gen_entry($path);
			my $entry2=gen_entry($rename) ;
			my $remove=def_image_button("icons/cancel.png");
			$table->attach  ($entry, 0, 5 , $row, $row+1,'fill','shrink',2,2);
			$table->attach  ($entry2, 5, 9 , $row, $row+1,'fill','shrink',2,2) if(defined $rename_file_en);
			$table->attach ($remove, 9,10 , $row, $row+1,'expand','shrink',2,2);
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
	my $table = Gtk2::Table->new (15, 15, FALSE);
	my $window =  def_popwin_size(50,50,"Add description",'percent');
	my ($scrwin,$text_view)=create_text();
	my $ok=def_image_button("icons/select.png",' Ok ');
	
	$table->attach_defaults($scrwin,0,15,0,14);
	$table->attach($ok,6,9,14,15,'expand','shrink',2,2);
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
	my($intfc,$ipgen,$info)=@_;
	my $table=def_table(7,7,FALSE);
	my @sokets=$ipgen->ipgen_list_sokets;
	my @plugs=$ipgen->ipgen_list_plugs;
	
	my @positions=(0,1,2,4,5,6,7);
	
	
	my $row=0;
	my $col=0;
	$table->attach (gen_label_in_center(" Interface name"), $positions[0], $positions[1], $row, $row+1,'expand','shrink',2,2);
	$table->attach (gen_label_in_center("Type"), $positions[1], $positions[2], $row, $row+1,'expand','shrink',2,2);
	$table->attach (gen_label_in_left("Interface Num"), $positions[2], $positions[3], $row, $row+1,'expand','shrink',2,2);
	
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
			set_gui_status($ipgen,'intfc_changed',0);		
			
			}  );
		$name_setting->signal_connect ('clicked'=> sub{
			get_intfc_setting($ipgen,$p,'socket');
			
			
		});	
		$combo_type	->signal_connect ('changed'=> sub{
			$ipgen->ipgen_remove_socket($p);
			add_intfc_to_ip($intfc,$ipgen,$p,'plug',$info);
				
			}  );
		$table->attach ($remove, $positions[4], $positions[5], $row, $row+1,'expand','shrink',2,2);

	
		if ($type eq 'num'){
			my ($type_box,$type_spin)=gen_spin_help ('Define the number of this interface in module', 1,1024,1);
			$type_box->pack_start($name_setting,FALSE,FALSE,0);
			$type_spin->set_value($value);
			my $advance_button=def_image_button('icons/advance.png','separate');
			$table->attach ($type_box, $positions[2], $positions[3], $row, $row+1,'expand','shrink',2,2);
			$table->attach ($advance_button, $positions[3], $positions[4], $row, $row+1,'expand','shrink',2,2);
			$type_spin->signal_connect("value_changed"=>sub{
				my $wiget=shift;
				my $num=$wiget->get_value_as_int();
				$ipgen->ipgen_add_soket($p,'num',$num);
				set_gui_status($ipgen,'intfc_changed',0);
				
			});
			$advance_button->signal_connect("clicked"=>sub{
				$ipgen->ipgen_add_soket($p,'param');
				set_gui_status($ipgen,'intfc_changed',0);
				
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
			$table->attach ($type_box, $positions[2], $positions[3], $row, $row+1,'expand','shrink',2,2);
			$table->attach ($advance_button, $positions[3], $positions[4], $row, $row+1,'expand','shrink',2,2);	
			$type_combo->signal_connect("changed"=>sub{
				my $wiget=shift;
				my $value=$wiget->get_active_text();
				$ipgen->ipgen_add_soket($p,'param',$value);
				set_gui_status($ipgen,'intfc_changed',0);
				
			});
			$advance_button->signal_connect("clicked"=>sub{
				$ipgen->ipgen_add_soket($p,'num',0);
				set_gui_status($ipgen,'intfc_changed',0);
				
			});	
			
		}	
		
		
		
		
		
		
		$table->attach ($label_name, $positions[0], $positions[1], $row, $row+1,'expand','shrink',2,2);
		$table->attach ($combo_type, $positions[1], $positions[2], $row, $row+1,'expand','shrink',2,2);
		
		
		
			
		$row++;
	}	
	foreach my $q( @plugs){
		#my ($range,$type,$intfc_name,$intfc_port)=$ipgen->ipgen_get_port($p);
		my ($type,$value)= $ipgen->ipgen_get_plug($q);
		my $label_name=gen_label_in_center($q);
		my $combo_type=gen_combo(\@type_list,0);
		my $remove=	def_image_button('icons/cancel.png','Remove');
		my $name_setting=def_image_button('icons/setting.png');
		
		$table->attach ($remove, $positions[4], $positions[5], $row, $row+1,'expand','shrink',2,2);
		$remove->signal_connect ('clicked'=> sub{
			$ipgen->ipgen_remove_plug($q);
			set_gui_status($ipgen,'intfc_changed',0);		
			
			}  );
		$name_setting->signal_connect ('clicked'=> sub{
			get_intfc_setting($ipgen,$q,'plug');
			
			
		}	);	
		$combo_type	->signal_connect ('changed'=> sub{
			$ipgen->ipgen_remove_plug($q);
			add_intfc_to_ip($intfc,$ipgen,$q,'socket',$info);
				
			}  );	
		#my $range_entry=gen_entry($range);
		if ($type eq 'num'){
			my ($type_box,$type_spin)=gen_spin_help ('Define the number of this interface in module', 1,1024,1);
			$type_box->pack_start($name_setting,FALSE,FALSE,0);
			$type_spin->set_value($value);
			$table->attach ($type_box, $positions[2], $positions[3], $row, $row+1,'expand','shrink',2,2);
			$type_spin->signal_connect("value_changed"=>sub{
				my $wiget=shift;
				my $num=$wiget->get_value_as_int();
				$ipgen->ipgen_add_plug($q,'num',$num);
				set_gui_status($ipgen,'intfc_changed',0);
				
			});
			
		}	
		$table->attach ($label_name, $positions[0], $positions[1], $row, $row+1,'expand','shrink',2,2);
		$table->attach ($combo_type, $positions[1], $positions[2], $row, $row+1,'expand','shrink',2,2);
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
			$table->attach ($addr, $positions[5], $positions[6], $row, $row+1,'expand','shrink',2,2);
			
			
		}	
		
			
		$row++;
	}	
	
	
	
	
	
	return $table;
	
}	
########
#	get_intfc_setting
########

sub get_intfc_setting{
	
	my ($ipgen,$intfc_name, $intfc_type)=@_;
	my $window =  def_popwin_size(70,70,"Interface parameter setting",'percent');
	my $table=def_table(7,6,FALSE);
	my $ok = def_image_button('icons/select.png','OK');
	
	
	
	my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);
	$scrolled_win->set_policy( "automatic", "automatic" );
	$scrolled_win->add_with_viewport($table);
	
	#title
	my $lable1=gen_label_in_left("interface name");
	$table->attach ( $lable1,0,2,0,1,'expand','shrink',2,2);
	
	
	
	
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
		
		$table->attach($entry_name,0,2,$i+1,$i+2,'expand','shrink',2,2);
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
		my $lable3=gen_label_help("This field defines the total memory_map address  which is required by this module in byte. ( =2 ^ block_address_width).
You can define a fixed value or assign it to any of module parameter","block address width");

		$table->attach ( $lable2,2,5,0,1,'expand','shrink',2,2);
		$table->attach ( $lable3,5,6,0,1,'expand','shrink',2,2);
		
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
		
			$table->attach ($name_combo,2,5,$i+1,$i+2 ,'expand','shrink',2,2);
			$table->attach ($sbox,5,6,$i+1,$i+2,'expand','shrink',2,2);
			$ok->signal_connect('clicked'=>sub{
				my $addr=$name_combo->get_active_text();
				my $in=$comb->get_active_text();
				my $width=($in eq "Fixed" )? $widget->get_value_as_int(): $widget->get_active_text() ;
				$ipgen->ipgen_save_wb_addr($plug,$num,$addr,$width);
			
			});
		

		}
		
		
	
	}

	

	

	my $mtable = def_table(10, 1, FALSE);
	$mtable->attach_defaults($scrolled_win,0,1,0,9);
	$mtable->attach($ok,0,1,9,10,'expand','shrink',2,2);
	
	$window->add ($mtable);
	$window->show_all();




	 $ok->signal_connect('clicked'=>sub{
			$window->destroy;
			set_gui_status($ipgen,"interface_selected",1);
			 
		 } );

	


}



sub is_integer {
   defined $_[0] && $_[0] =~ /^[+-]?\d+$/;
}


#############
#  add_intfc_to_ip
##############


sub add_intfc_to_ip{
	my ($intfc,$ipgen,$infc_name,$infc_type,$info)=@_;
	if($infc_type eq 'socket'){ 
		my ($connection_num,$connect_to)=$intfc->get_socket($infc_name);
		$ipgen->ipgen_add_soket($infc_name,'num',1,$connection_num);
	}
	else { $ipgen->ipgen_add_plug($infc_name,'num',1);}
	set_gui_status($ipgen,"interface_selected",1);
	
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
		@ports=('IO','NC');
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
	my($intfc,$ipgen,$info)=@_;
	my $table=def_table(8,10,FALSE);
	my @ports=$ipgen->ipgen_list_ports;
	my $row=0;
	my ($name_ref,$ref)=get_list_of_all_interfaces($ipgen);
	my @interfaces_name=@{$name_ref};
	my @interfaces=@{$ref};
	#print "@interfaces_name\n";
	
	$table->attach  (gen_label_in_left(" Type "), 0, 1, $row, $row+1,'expand','shrink',2,2);
	$table->attach  (gen_label_in_left(" Port name "), 1, 3, $row, $row+1,'expand','shrink',2,2);
	$table->attach  (gen_label_in_left(" Interface name "), 3, 5, $row, $row+1,'expand','shrink',2,2);
	$table->attach  (gen_label_in_center(" Interface port  "), 5, 7, $row, $row+1,'fill','shrink',2,2);
	$table->attach  (gen_label_in_left("  Port Range "), 7, 9, $row, $row+1,'expand','shrink',2,2);
	$row++;
	#print  @interfaces;
	my @ports_order=$ipgen->ipgen_get_ports_order();
	if(scalar(@ports_order) >1 ){ @ports= @ports_order}
	



	foreach my $p( @ports){
		my ($range,$type,$intfc_name,$intfc_port)=$ipgen->ipgen_get_port($p);
		#my $label_name=gen_label_in_left(" $p ");
		my $name_entry=gen_label_in_left($p);
		my $label_type=gen_label_in_left(" $type ");
		my $range_entry=gen_entry($range);
		my $pos=(defined $intfc_name ) ? get_scolar_pos( $intfc_name,@interfaces) : 0;
		if (!defined $pos){
			$pos=0;
			$ipgen->ipgen_set_port_intfc_name($p,'IO');
		};
		my $intfc_name_combo=gen_combo(\@interfaces_name,$pos);
		my $intfc_port_combo=gen_intfc_port_combo($intfc,$ipgen,$intfc_name,$type,$p);
		
		
		$table->attach ($label_type, 0, 1, $row, $row+1,'expand','shrink',2,2);
		$table->attach ($name_entry, 1, 3, $row, $row+1,'expand','shrink',2,2);
		$table->attach ($intfc_name_combo,3, 5, $row, $row+1,'expand','shrink',2,2);
		$table->attach ($intfc_port_combo, 5, 7, $row, $row+1,'fill','shrink',2,2);
		$table->attach ($range_entry ,7, 9, $row, $row+1,'fill','shrink',2,2);
				
		$intfc_name_combo->signal_connect('changed'=>sub{
			my $intfc_name=$intfc_name_combo->get_active_text();
			my $pos=  get_scolar_pos( $intfc_name,@interfaces_name);
			#my($type,$name,$num)= split("[:\[ \\]]", $intfc_name);
			#print "$type,$name,$num\n";
			$ipgen->ipgen_set_port_intfc_name($p,$interfaces[$pos]);
			set_gui_status($ipgen,"interface_selected",1);
		});
		$range_entry->signal_connect('changed'=>sub{
			my $new_range=$range_entry->get_text();
			$ipgen->ipgen_add_port($p,$new_range,$type,$intfc_name,$intfc_port);
		});
			
		$row++;
	}	
	
	
	
	
	return $table;
	
	
}


sub write_ip{
	my $ipgen=shift;	
	my $name=$ipgen->ipgen_get("module_name");
	my $category=$ipgen->ipgen_get("category");
	my $ip_name= $ipgen->ipgen_get("ip_name");
	my $dir = Cwd::getcwd();

	#Increase IP version
	my $v=$ipgen->object_get_attribute("version",undef);
	$v = 0 if(!defined $v);
	$v++;
	$ipgen->object_add_attribute("version",undef,$v);
	#print "$v\n";

	# Write
	mkpath("$dir/lib/ip/$category/",1,01777);	
	open(FILE,  ">lib/ip/$category/$ip_name.IP") || die "Can not open: $!";
	print FILE perl_file_header("$ip_name.IP");
	print FILE Data::Dumper->Dump([\%$ipgen],["ipgen"]);
	close(FILE) || die "Error closing file: $!";
	my $message="IP $ip_name has been generated successfully. In order to see the generated IP in processing tile generator you need to reset the ProNoC. Do you want to reset the ProNoC now?" ;
			
	my $dialog = Gtk2::MessageDialog->new (my $window,
                     'destroy-with-parent',
                     'question', # message type
                     'yes-no', # which set of buttons?
                     "$message");
  	my $response = $dialog->run;
  	if ($response eq 'yes') {
      		exec($^X, $0, @ARGV);# reset ProNoC to apply changes	
  	}
  	$dialog->destroy;

}



sub generate_ip{
	my $ipgen=shift;
	my $name=$ipgen->ipgen_get("module_name");
	my $category=$ipgen->ipgen_get("category");
	my $ip_name= $ipgen->ipgen_get("ip_name");
	my $dir = Cwd::getcwd();
	
	

	#check if name has been set
	if(defined ($name) && defined ($category)){
		if (!defined $ip_name) {$ip_name= $name}
		my $error = check_verilog_identifier_syntax($ip_name);
		if ( defined $error ){
			message_dialog("The IP name \"$ip_name\" is given with an unacceptable formatting. This name will be used as a verilog module name so it must follow Verilog identifier declaration formatting:\n $error");
			return ;
		}



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
	      			write_ip($ipgen);
				
				
  			}
  			$dialog->destroy;


  			#$dialog->show_all;
			
		}else{

			write_ip($ipgen);
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
	my ($ipgen)=@_;
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
			set_gui_status($ipgen,"load_file",0);
		}					
     }
     $dialog->destroy;

	

}






############
#	get_source_file
###########



sub get_source_file{
	my($ipgen,$info,$page,$title,$dest,$page_info_ref)=@_;

		
	my $var_list='${parameter_name}: Verilog module parameter values.
 
${CORE_ID} Each wishbone bus based SoC will have a unique CORE_ID that represents its location in NoC topology. CORE_ID=((y * number_of_nodes_in_x_ dimension) + x) where (x,y) are the node location in x and y axises. If the generated tile is used as top level module CORE_ID will take the default value of zero.
      
${IP}: is the peripheral device instance name.

${CORE}: is the peripheral device module name.

${BASE}: is the wishbone base addresse(s) and will be added during soc generation to system.h. If more than one slave wishbone bus are used  define them as ${BASE0}, ${BASE1}... . 
'
;
	my $var_help=gen_button_message($var_list,"icons/info.png","Global variables");
	
	
	my $window = def_popwin_size(75,75,$title,'percent');
	
	my $notebook=source_notebook($ipgen,$info,$window,$page,$dest,$page_info_ref);
	my $table=def_table (15, 15, FALSE);						
	
		
	$table->attach ($var_help, 5, 7, 0, 1,'expand','shrink',2,2);
	$table->attach_defaults ($notebook , 0, 15, 1, 15);
		
	$window->add($table);
	$window->show_all;	
	return $window;	  
	
}

##########
# source_notebook
##########

sub source_notebook{
	my($ipgen,$info,$window,$page,$dest,$page_info_ref)=@_;
	my $notebook = Gtk2::Notebook->new;
	my %page_info=%{$page_info_ref};
	foreach my $p (sort keys %page_info){
		my $page_ref;
		$page_ref=get_file_folder($ipgen,$info,$window,$p,$page_info_ref) if($page_info{$p}{filed_type} eq "exsiting_file/folder"); 
		$page_ref=get_file_folder($ipgen,$info,$window,$p,$page_info_ref) if($page_info{$p}{filed_type} eq "file_with_variables"); 
		$page_ref=get_file_content($ipgen,$info,$window,$page_info{$p},$page_info_ref) if($page_info{$p}{filed_type} eq "file_content"); 
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
	my ($ipgen,$info,$window,$page,$page_info_ref)=@_;
	my %page_info=%{$page_info_ref};
	my @sw_dir = $ipgen->ipgen_get_list($page_info{$page}{filed_name});
	my $table = Gtk2::Table->new (15, 15, FALSE);	
	my $help=gen_label_help($page_info{$page}{help});	
	$table->attach ($help,0,2,0,1,'expand','shrink',2,2);	
	my ($scrwin,$ok)=gen_file_list($ipgen,$page_info{$page}{filed_name},$window,$page_info{$page}{rename_file});
	
	my $label=gen_label_in_left("Selecet file(s):"); 
	my $brows=def_image_button("icons/browse.png",' Browse');
	$table->attach ($label,2,4,0,1,'expand','shrink',2,2);
	$table->attach($brows,4,6,0,1,'expand','shrink',2,2);
	
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
            		get_source_file($ipgen,$info,$page,"Add software file(s)","SW",$page_info_ref);
            		$window->destroy;
            		
       		 }
       		$dialog->destroy;
	} );# # ,\$entry);
	
	if($page_info{$page}{folder_en} eq 1){
		my $label2=gen_label_in_left("Selecet folder(s):"); 
		my $brows2=def_image_button("icons/browse.png",' Browse');
		$table->attach($label2,7,9,0,1,'expand','shrink',2,2);
		$table->attach($brows2,9,11,0,1,'expand','shrink',2,2);

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
		    		get_source_file($ipgen,$info,$page,"Add software file(s)","SW",$page_info_ref);
		    		$window->destroy;
		    		
		    		
						#$$entry_ref->set_text($file);
					
		    		#print "file = $file\n";
	       		 }
	       		$dialog->destroy;
	       		


		} );# # ,\$entry);
	}	
	
	
	
	$table->attach_defaults($scrwin,0,15,1,14);
	$table->attach($ok,6,9,14,15,'expand','shrink',2,2);
	
	return ($table)

	
}	



###########
#	get_file_content
#########

sub get_file_content{
	my ($ipgen,$info,$window,$page_info_ref)=@_;
	my %page_info=%{$page_info_ref};
	#my $hdr = $ipgen->ipgen_get_hdr();
	my  $hdr = $ipgen-> ipgen_get($page_info{filed_name});	
	my $table = Gtk2::Table->new (14, 15, FALSE);
	my ($scrwin,$text_view)=create_text();

	my $help=gen_label_help($page_info{help}); 
	$table->attach ($help,0,8,0,1,'expand','shrink',2,2);
	$table->attach_defaults($scrwin,0,15,1,14);
	my $text_buffer = $text_view->get_buffer;
	if(defined $hdr) {$text_buffer->set_text($hdr)};	
	
	my $ok=def_image_button("icons/select.png",' Save ');
	$ok->signal_connect("clicked"=> sub {#		  
		 my $text = $text_buffer->get_text($text_buffer->get_bounds, TRUE);
		 $ipgen->ipgen_add($page_info{filed_name},$text);	
		 $window->destroy;
				
	});

	$table->attach($ok,6,7,14,15,'expand','shrink',2,2);
	return ($table);
	
}	
















############
#	get_unused_intfc_ports_list
###########

sub get_unused_intfc_ports_list {
	my($intfc,$ipgen,$info)=@_;
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
				my $r= check_intfc_port_exits($intfc,$ipgen,$info,$intfc_name,$p);
				if ($r eq "0"){
					$ipgen->ipgen_add_unused_intfc_port( $intfc_name,$p );
				}
				
		}	

	}
}

sub check_intfc_port_exits{
	my($intfc,$ipgen,$info,$intfc_name,$intfc_port)=@_;
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
	set_gui_status($ipgen,"ideal",0);	
	
	#  The main table containg the lib tree, selected modules and info section 
	my $main_table = def_table (15, 12, FALSE);




	
	#my $vpaned = Gtk2::VPaned -> new;
	#$table->attach_defaults ($vpaned,0, 10, 0,1);
	#my $make = def_image_button('icons/run.png','Compile');
	#$table->attach ($make,9, 10, 1,2,'shrink','shrink',0,0);
	#$make -> signal_connect("clicked" => sub{
		#$self->do_save();
		#run_make_file($sw,$tview);	

	#});

	#$window -> add ( $table);

	#my($width,$hight)=max_win_size();
	
	#my $scwin_dirs = Gtk2::ScrolledWindow -> new;
	#$scwin_dirs -> set_policy ('automatic', 'automatic');
	




	
	# The box which holds the info, warning, error ...  mesages
	my ($infobox,$info)= create_text();	
	
	
	my $refresh_dev_win = Gtk2::Button->new_from_stock('ref');
	my $generate = def_image_button('icons/gen.png','Generate');
	
	
	# A tree view for holding a library
	my $tree_box = create_interface_tree  ($info,$intfc,$ipgen);


	my $file_info=show_file_info($ipgen,$info,\$refresh_dev_win);
	my $port_info=show_port_info($intfc,$ipgen,$info,\$refresh_dev_win);
	my $intfc_info=show_interface_info($intfc,$ipgen,$info,\$refresh_dev_win);
	
	
	my $open = def_image_button('icons/browse.png','Load IP');
	

	$main_table->set_row_spacings (4);
	$main_table->set_col_spacings (1);
	
	#my  $device_win=show_active_dev($soc,$lib,$infc,\$refresh_dev_win,$info);
	
	
	#$table->attach_defaults ($event_box, $col, $col+1, $row, $row+1);

	my $v1=gen_vpaned($file_info,.2,$intfc_info);
	my $v2=gen_vpaned($v1,.4,$port_info);
	my $h1=gen_hpaned($tree_box,.15,$v2);
	my $v3=gen_vpaned($h1,.6,$infobox);


	#$main_table->attach_defaults ($tree_box , 0, 2, 0, 13);
	#$main_table->attach_defaults ($file_info , 2, 12, 0, 2);
	#$main_table->attach_defaults ($intfc_info , 2, 12, 2, 6);
	
	#$main_table->attach_defaults ($port_info  , 2, 12, 6,13);
	#$main_table->attach_defaults ($infobox  , 0, 12, 13,14);
	$main_table->attach_defaults  ($v3, 0, 12, 0,14);
	$main_table->attach ($generate, 6, 8, 14,15,'expand','shrink',2,2);
	$main_table->attach ($open,0, 1, 14,15,'expand','shrink',2,2);

	#check soc status every 0.5 second. referesh device table if there is any changes 
Glib::Timeout->add (100, sub{ 
	 
		my ($state,$timeout)= get_gui_status($ipgen);
		if($state eq "load_file"){
			my $file=$ipgen->ipgen_get("file_name");
			my $pp= eval { do $file };
			clone_obj($ipgen,$pp);
						
			
			set_gui_status($ipgen,"ref",1);
			
			
		}elsif ($timeout>0){
			$timeout--;
			set_gui_status($ipgen,$state,$timeout);		
		}
		elsif( $state eq "change_parameter" ){
			get_parameter_setting($ipgen,$info);
			set_gui_status($ipgen,"ideal",0);
			
			
			
		}
		elsif( $state ne "ideal" ){
			$refresh_dev_win->clicked;
			set_gui_status($ipgen,"ideal",0);
			
			
		}	
		return TRUE;
		
		} );
	$open-> signal_connect("clicked" => sub{ 
		load_ip($ipgen);
	
	});		
		
	$generate-> signal_connect("clicked" => sub{ 
		get_unused_intfc_ports_list ($intfc,$ipgen,$info);
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



