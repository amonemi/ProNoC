#! /usr/bin/perl -w
use Glib qw/TRUE FALSE/;
use strict;
use warnings;
use Gtk2;
use Gtk2::Ex::Graph::GD;
use GD::Graph::Data;
use emulator;
use IO::CaptureOutput qw(capture qxx qxy);
use GD::Graph::colour qw/:colours/;
use Proc::Background;
use Time::HiRes qw( usleep ualarm gettimeofday tv_interval nanosleep  clock_gettime clock_getres clock_nanosleep clock stat );

use File::Basename;
use File::Path qw/make_path/;
use File::Copy;
use File::Find::Rule;

require "widget.pl"; 
require "mpsoc_gen.pl"; 
require "emulator.pl";
require "mpsoc_verilog_gen.pl"; 
require "readme_gen.pl";

use List::MoreUtils qw(uniq);




sub generate_sim_bin_file() {
	my ($simulate,$info_text) =@_;
	my $dir = Cwd::getcwd();
	my $project_dir	  = abs_path("$dir/..");
	my $src_verilator_dir="$project_dir/src_verilator";
	my $script_dir="$project_dir/script";
	# save parameters inside parameter.v file in src_verilator folder
	my ($noc_param,$pass_param)=gen_noc_param_v($simulate);
	open(FILE,  ">$src_verilator_dir/parameter.v") || die "Can not open: $!";
	print FILE  " \`ifdef     INCLUDE_PARAM \n \n 
	$noc_param   
	localparam  P=(TOPOLOGY==\"RING\")? 3 : 5;
 	localparam  ROUTE_TYPE = (ROUTE_NAME == \"XY\" || ROUTE_NAME == \"TRANC_XY\" )?    \"DETERMINISTIC\" : 
                        (ROUTE_NAME == \"DUATO\" || ROUTE_NAME == \"TRANC_DUATO\" )?   \"FULL_ADAPTIVE\": \"PAR_ADAPTIVE\"; 
	
	//simulation parameter	
	localparam MAX_PCK_NUM = ".MAX_SIM_CLKs.";
	localparam MAX_PCK_SIZ = ".MAX_PCK_SIZ."; 
	localparam MAX_SIM_CLKs=  ".MAX_SIM_CLKs.";
	localparam TIMSTMP_FIFO_NUM = 16;
\n \n \`endif" ; 
	close FILE;
	
	
	
	
	#verilate the noc
	my $command = "rm -f  $script_dir/logfile1.txt  $script_dir/logfile2.txt"; 
	my ($stdout,$exit)=run_cmd_in_back_ground_get_stdout( $command);
	
	my $start = localtime;
	add_info($info_text, "verilate the NoC and make the library files");
	$command = "cd \"$script_dir/\" \n	xterm  	-l -lf logfile1.txt -e  sh verilator_compile_hw.sh";
	($stdout,$exit)=run_cmd_in_back_ground_get_stdout( $command);
	if($exit != 0){			
		print "Verilator compilation failed !\n";
		add_info($info_text, "Verilator compilation failed !\n$command\n $stdout\n");
		return;
	}
		


	#compile the testbench
	my $param_h=gen_noc_param_h($simulate);
	$param_h =~ s/\d\'b/ /g;
	open(FILE,  ">$src_verilator_dir/parameter.h") || die "Can not open: $!";
	print FILE  "
#ifndef     INCLUDE_PARAM
	#define   INCLUDE_PARAM \n \n 

	$param_h 
	
	int   P=(strcmp (TOPOLOGY,\"RING\")==0)    ?   3 : 5;
 	
	
	//simulation parameter	
	#define AVG_LATENCY_METRIC \"HEAD_2_TAIL\"
	#define TIMSTMP_FIFO_NUM   16 
\n \n \#endif" ; 
	close FILE;
	
	$command = "cd \"$script_dir/\" \n	xterm  	-l -lf logfile2.txt	-e  sh verilator_compile_simulator.sh";
	($stdout,$exit)=run_cmd_in_back_ground_get_stdout( $command);
	if($exit != 0){			
		print "Verilator compilation failed !\n";
		add_info($info_text, "Verilator compilation failed !\n$command\n $stdout\n");
		return;
	}
	my $end = localtime; 		
	

	
	#save the binarry file
	my $bin= "$ENV{PRONOC_WORK}/verilator/work/processed_rtl/obj_dir/testbench";
	my $path=$simulate->object_get_attribute ('sim_param',"BIN_DIR");
	my $name=$simulate->object_get_attribute ('sim_param',"SAVE_NAME");
	
	#create project directory if its not exist
	($stdout,$exit)=run_cmd_in_back_ground_get_stdout("mkdir -p $path" );
	if($exit != 0 ){ 	print "$stdout\n"; 	message_dialog($stdout,'error'); return;}
	
	#move the log file 
	unlink "$path/$name.log";
	append_text_to_file("$path/$name.log","start:$start\n");
	merg_files("$script_dir/logfile1.txt" , "$path/$name.log");
	merg_files("$script_dir/logfile2.txt" , "$path/$name.log");
	append_text_to_file("$path/$name.log","end:$end\n");
	#check if the verilation was successful
	if ((-e $bin)==0) {#something goes wrong 		
    	message_dialog("Verilator compilation was unsuccessful please check the $path/$name.log files for more information",'error'); 
    	return;
	}
	
	
	#copy ($bin,"$path/$name") or  die "Can not copy: $!";
	($stdout,$exit)=run_cmd_in_back_ground_get_stdout("cp -f $bin $path/$name");
	if($exit != 0 ){ 	print "$stdout\n"; 	message_dialog($stdout,'error'); return;}
		
	#save noc info
	open(FILE,  ">$path/$name.inf") || die "Can not open: $!";
	print FILE perl_file_header("$name.inf");
	my %pp;
	$pp{'noc_param'}= $simulate->{'noc_param'};
	$pp{'sim_param'}= $simulate->{'sim_param'};
	print FILE Data::Dumper->Dump([\%pp],["emulate_info"]);
	close(FILE) || die "Error closing file: $!";		

	message_dialog("The simulation binary file has been successfully generated in $path!"); 


	#make project dir
	#my $dir= $simulate->object_get_attribute ("sim_param","BIN_DIR");
	#my $name=$simulate->object_get_attribute ("sim_param","SAVE_NAME");	
	#my $path= "$dir/$name";
	#add_info($info_text, "$src_verilator_dir!\n");
	#mkpath("$path",1,01777);

	



}


##########
#	save_simulation
##########
sub save_simulation {
	my ($simulate)=@_;
	# read emulation name
	my $name=$simulate->object_get_attribute ("simulate_name",undef);	
	my $s= (!defined $name)? 0 : (length($name)==0)? 0 :1;	
	if ($s == 0){
		message_dialog("Please set Simulation name!");
		return 0;
	}
	# Write object file
	open(FILE,  ">lib/simulate/$name.SIM") || die "Can not open: $!";
	print FILE perl_file_header("$name.SIM");
	print FILE Data::Dumper->Dump([\%$simulate],[$name]);
	close(FILE) || die "Error closing file: $!";
	message_dialog("Simulation has saved as lib/simulate/$name.SIM!");
	return 1;
}

#############
#	load_simulation
############

sub load_simulation {
	my ($simulate,$info)=@_;
	my $file;
	my $dialog = Gtk2::FileChooserDialog->new(
            	'Select a File', undef,
            	'open',
            	'gtk-cancel' => 'cancel',
            	'gtk-ok'     => 'ok',
        	);

	my $filter = Gtk2::FileFilter->new();
	$filter->set_name("SIM");
	$filter->add_pattern("*.SIM");
	$dialog->add_filter ($filter);
	my $dir = Cwd::getcwd();
	$dialog->set_current_folder ("$dir/lib/simulate");		


	if ( "ok" eq $dialog->run ) {
		$file = $dialog->get_filename;
		my ($name,$path,$suffix) = fileparse("$file",qr"\..[^.]*$");
		if($suffix eq '.SIM'){
			my $pp= eval { do $file };
			if ($@ || !defined $pp){		
				add_info($info,"**Error reading  $file file: $@\n");
				 $dialog->destroy;
				return;
			} 
			#deactivate running simulations
			$pp->object_add_attribute('status',undef,'ideal');
			my $sample_num=$pp->object_get_attribute("emulate_num",undef);
			for (my $i=1; $i<=$sample_num; $i++){
				my $st=$pp->object_get_attribute ("sample$i","status");	
				$pp->object_add_attribute ("sample$i","status",'done');# if ($st eq "run");	
			}
			clone_obj($simulate,$pp);
			#message_dialog("done!");				
		}					
     }
     $dialog->destroy;
}


############
#    main
############
sub simulator_main{
	
	add_color_to_gd();
	my $simulate= emulator->emulator_new();
	set_gui_status($simulate,"ideal",0);
	my $left_table = Gtk2::Table->new (25, 6, FALSE);
	my $right_table = Gtk2::Table->new (25, 6, FALSE);

	my $main_table = Gtk2::Table->new (25, 12, FALSE);
	my ($infobox,$info)= create_text();	
	my $refresh = Gtk2::Button->new_from_stock('ref');
	

	
	
	
	my ($conf_box,$set_win)=process_notebook_gen($simulate,\$info,"simulate");
	my $chart   =gen_chart  ($simulate);
    


	$main_table->set_row_spacings (4);
	$main_table->set_col_spacings (1);
	
	#my  $device_win=show_active_dev($soc,$soc,$infc,$soc_state,\$refresh,$info);
	
	
	my $generate = def_image_button('icons/forward.png','Run all');
	my $open = def_image_button('icons/browse.png','Load');
	
	
	
	
	my ($entrybox,$entry) = def_h_labeled_entry('Save as:',undef);
	$entry->signal_connect( 'changed'=> sub{
		my $name=$entry->get_text();
		$simulate->object_add_attribute ("simulate_name",undef,$name);	
	});	
	my $save = def_image_button('icons/save.png','Save');
	$entrybox->pack_end($save,   FALSE, FALSE,0);
	

	#$table->attach_defaults ($event_box, $col, $col+1, $row, $row+1);
	my $image = get_status_gif($simulate);
	
	
	
	
	
	$left_table->attach_defaults ($conf_box , 0, 6, 0, 20);
	$left_table->attach_defaults ($image , 0, 6, 20, 24);
	$left_table->attach ($open,0, 3, 24,25,'expand','shrink',2,2);
	$left_table->attach ($entrybox,3, 6, 24,25,'expand','shrink',2,2);
	$right_table->attach_defaults ($infobox  , 0, 6, 0,12);
	$right_table->attach_defaults ($chart , 0, 6, 12, 24);
	$right_table->attach ($generate, 4, 6, 24,25,'expand','shrink',2,2);
	$main_table->attach_defaults ($left_table , 0, 6, 0, 25);
	$main_table->attach_defaults ($right_table , 6, 12, 0, 25);
	
	

	#referesh the mpsoc generator 
	$refresh-> signal_connect("clicked" => sub{ 
		my $name=$simulate->object_get_attribute ("simulate_name",undef);	
		$entry->set_text($name) if(defined $name);


		$conf_box->destroy();
		$chart->destroy();
		$image->destroy(); 
		$image = get_status_gif($simulate);
		($conf_box,$set_win)=process_notebook_gen($simulate,\$info,"simulate");
		$chart   =gen_chart  ($simulate);
		$left_table->attach_defaults ($image , 0, 6, 20, 24);
		$left_table->attach_defaults ($conf_box , 0, 6, 0, 12);
		$right_table->attach_defaults ($chart , 0, 6, 12, 24);

		$conf_box->show_all();
		$main_table->show_all();


	});



	#check soc status every 0.5 second. referesh device table if there is any changes 
	Glib::Timeout->add (100, sub{ 
	 
		my ($state,$timeout)= get_gui_status($simulate);
		
		if ($timeout>0){
			$timeout--;
			set_gui_status($simulate,$state,$timeout);	
			
		}
		elsif($state eq 'ref_set_win'){
			
			my $s=$simulate->object_get_attribute("active_setting",undef);
			$set_win->destroy();
			$simulate->object_add_attribute("active_setting",undef,$s);		 
			$refresh->clicked;			
			set_gui_status($simulate,"ideal",0);
			
		}
		elsif( $state ne "ideal" ){
			$refresh->clicked;
			#my $saved_name=$mpsoc->mpsoc_get_mpsoc_name();
			#if(defined $saved_name) {$entry->set_text($saved_name);}
			set_gui_status($simulate,"ideal",0);
			
		}	
		return TRUE;
		
	} );
		
		
	$generate-> signal_connect("clicked" => sub{ 
		my $sample_num=$simulate->object_get_attribute("emulate_num",undef);
		for (my $i=1; $i<=$sample_num; $i++){
			$simulate->object_add_attribute ("sample$i","status","run");	
		}
		run_simulator($simulate,\$info);
		#set_gui_status($emulate,"ideal",2);

	});

#	$wb-> signal_connect("clicked" => sub{ 
#		wb_address_setting($mpsoc);
#	
#	});

	$open-> signal_connect("clicked" => sub{ 
		
		load_simulation($simulate,\$info);
		set_gui_status($simulate,"ref",5);
	
	});	

	$save-> signal_connect("clicked" => sub{ 
		save_simulation($simulate);		
		set_gui_status($simulate,"ref",5);
		
	
	});	

	my $sc_win = new Gtk2::ScrolledWindow (undef, undef);
		$sc_win->set_policy( "automatic", "automatic" );
		$sc_win->add_with_viewport($main_table);	

	return $sc_win;
	

}



