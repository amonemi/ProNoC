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
require "graph.pl";

use List::MoreUtils qw(uniq);




sub generate_sim_bin_file() {
	my ($simulate,$info_text) =@_;
	
	$simulate->object_add_attribute('status',undef,'run');
	set_gui_status($simulate,"ref",1);
	
	my $target_dir= "$ENV{PRONOC_WORK}/simulate";
	
	my $dir = Cwd::getcwd();
	my $project_dir	  = abs_path("$dir/..");
	my $src_verilator_dir="$project_dir/src_verilator";
	my $src_noc_dir="$project_dir/src_noc";	
	my $script_dir="$project_dir/script";
	my $testbench_file= "$src_verilator_dir/simulator.cpp";
	
	my $src_verilog_dr ="$target_dir/src_verilog";
	my $obj_dir ="$target_dir/verilator/processed_rtl/obj_dir/";
	
	rmtree("$src_verilog_dr");
	mkpath("$src_verilog_dr/",1,01777);
	
	#copy src_verilator files
	my @files=(
		$src_noc_dir,
		"$src_verilator_dir/noc_connection.sv",
		"$src_verilator_dir/router_verilator.v",
		"$src_verilator_dir/traffic_gen_verilator.v"		
	);
	
	copy_file_and_folders (\@files,$project_dir,$src_verilog_dr);
	
	
	
	# generate NoC parameter file
	my ($noc_param,$pass_param)=gen_noc_param_v($simulate);
	open(FILE,  ">$src_verilog_dr/parameter.v") || die "Can not open: $!";
	my $fifow=$simulate->object_get_attribute('fpga_param','TIMSTMP_FIFO_NUM');



	print FILE  " \`ifdef     INCLUDE_PARAM \n \n 
	$noc_param  
	/* verilator lint_off WIDTH */ 
	localparam  P=(TOPOLOGY==\"RING\" || TOPOLOGY==\"LINE\")? 3 : 5;
 	localparam  ROUTE_TYPE = (ROUTE_NAME == \"XY\" || ROUTE_NAME == \"TRANC_XY\" )?    \"DETERMINISTIC\" : 
                        (ROUTE_NAME == \"DUATO\" || ROUTE_NAME == \"TRANC_DUATO\" )?   \"FULL_ADAPTIVE\": \"PAR_ADAPTIVE\"; 
	/* verilator lint_on WIDTH */
	//simulation parameter	
	localparam MAX_RATIO = ".MAX_RATIO.";
	localparam MAX_PCK_NUM = ".MAX_SIM_CLKs.";
	localparam MAX_PCK_SIZ = ".MAX_PCK_SIZ."; 
	localparam MAX_SIM_CLKs=  ".MAX_SIM_CLKs.";
	localparam TIMSTMP_FIFO_NUM = $fifow;
\n \n \`endif" ; 
	close FILE;
	
		
	
	my %tops = (
        "Vrouter" => "router_verilator.v", 
        "Vnoc" => "noc_connection.sv",
 		"Vtraffic"=> "traffic_gen_verilator.v"
    );
	my $result = verilator_compilation (\%tops,$target_dir,$$info_text);
	
	if ($result){
		add_colored_info($info_text,"Veriator model has been generated successfully!\n",'blue');
	}else {
		add_colored_info($info_text,"Verilator compilation failed!\n","red"); 
		$simulate->object_add_attribute('status',undef,'programer_failed');
		set_gui_status($simulate,"ref",1);
		return;
	}		
	
		


	
	@files=(
			
		"$src_verilator_dir/traffic_task_graph.h",
			
	);

	copy_file_and_folders (\@files,$project_dir,$obj_dir);
	copy($testbench_file,"$obj_dir/testbench.cpp"); 
	
	#compile the testbench
	my $param_h=gen_noc_param_h($simulate);
	$param_h =~ s/\d\'b/ /g;
	open(FILE,  ">$obj_dir/parameter.h") || die "Can not open: $!";
	print FILE  "
#ifndef     INCLUDE_PARAM
	#define   INCLUDE_PARAM \n \n 

	$param_h 
	
	int   P=(strcmp (TOPOLOGY,\"RING\")==0 || strcmp (TOPOLOGY,\"LINE\")==0 )    ?   3 : 5;
 	
	
	//simulation parameter	
	#define MAX_RATIO   ".MAX_RATIO."
	#define AVG_LATENCY_METRIC \"HEAD_2_TAIL\"
	#define TIMSTMP_FIFO_NUM   $fifow
\n \n \#endif" ; 
	close FILE;
	
	
	
	$result = run_make_file("$obj_dir/",$$info_text,'lib');	
	
	if ($result ==0){
		$simulate->object_add_attribute('status',undef,'programer_failed');
		set_gui_status($simulate,"ref",1);
		return;
	}		
	
	run_make_file("$obj_dir/",$$info_text);	
	if ($result ==0){
		$simulate->object_add_attribute('status',undef,'programer_failed');
		set_gui_status($simulate,"ref",1);
		return;
	}		
	
	
	
	
	#my $end = localtime; 		
	

	
	#save the binarry file
	my $bin= "$obj_dir/testbench";
	my $path=$simulate->object_get_attribute ('sim_param',"BIN_DIR");
	my $name=$simulate->object_get_attribute ('sim_param',"SAVE_NAME");
	
	#create project directory if it does not exist
	my	($stdout,$exit)=run_cmd_in_back_ground_get_stdout("mkdir -p $path" );
	if($exit != 0 ){ 	print "$stdout\n"; 	message_dialog($stdout,'error'); return;}
	

	
	#check if the verilation was successful
	if ((-e $bin)==0) {#something goes wrong 		
    	#message_dialog("Verilator compilation was unsuccessful please check the $path/$name.log files for more information",'error'); 
    	add_colored_info($info_text,"Verilator compilation failed!\n","red"); 
    	$simulate->object_add_attribute('status',undef,'programer_failed');
		set_gui_status($simulate,"ref",1);
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

	$simulate->object_add_attribute('status',undef,'ideal');
	set_gui_status($simulate,"ref",1);
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
	print FILE Data::Dumper->Dump([\%$simulate],["simulate"]);
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
			my @samples =$pp->object_get_attribute_order("samples");
			foreach my $sample (@samples){
				my $st=$pp->object_get_attribute ($sample,"status");	
				$pp->object_add_attribute ($sample,"status",'done');# if ($st eq "run");	
			}
			clone_obj($simulate,$pp);
			#message_dialog("done!");				
		}					
     }
     $dialog->destroy;
}



sub gen_custom_traffic {
	my ($self,$info,$mode)=@_;
		
	my $table=def_table(20,10,FALSE);
	my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);
	$scrolled_win->set_policy( "automatic", "automatic" );
	$scrolled_win->add_with_viewport($table);
	my $row=0;
	
	#page title	
	my $title_l =  "Custom Traffic  Generator";
	my $title=gen_label_in_center($title_l);
	$table->attach ($title , 0, 10,  $row, $row+1,'expand','shrink',2,2); $row++;
	my $separator = Gtk2::HSeparator->new;	
	$table->attach ($separator , 0, 10 , $row, $row+1,'fill','fill',2,2);	$row++;	
	    
	#fileds title
	my @positions=(0,1,2,3,4,5,6);
	my $col=0;
	
	my @title=("Traffic name", " Add/Remove "," Edit ");
	foreach my $t (@title){		
		$table->attach (gen_label_in_center($title[$col]), $positions[$col], $positions[$col+1], $row, $row+1,'expand','shrink',2,2);$col++;
	}
	 $row++;
	
	
	#create new traffic
	my $add=def_image_button("icons/plus.png", );
	$table->attach ($add, $positions[1], $positions[2], $row, $row+1,'expand','shrink',2,2);

	$add->signal_connect("clicked"=> sub{
		generate_new_traffic ($self);
			
	});
	return $scrolled_win;	
	
} 






sub generate_new_traffic {
	my $self=shift;
	
	my $window = def_popwin_size(40,40,"Step 2: Compile",'percent');
	my $table = def_table(10, 10, FALSE);
	
	
	
	my @info = (
	{ label=>'Traffic_name', param_name=>'CUSTOM_NAME', type=>"Entry", default_val=>undef, content=>undef, info=>undef, param_parent=>'traffic_param', ref_delay=> undef},
  	{ label=>'Routers per Row', param_name=>'CUSTOM_X', type=>"Spin-button", default_val=>2, content=>"2,64,1", info=>undef, param_parent=>'traffic_param', ref_delay=>undef},
	{ label=>"Routers per Column", param_name=>"CUSTOM_Y", type=>"Spin-button", default_val=>2, content=>"1,64,1", info=>undef, param_parent=>'traffic_param',ref_delay=>undef },
	);
	
	my $row=0;
	my $col=0;
	foreach my $d (@info) {
		($row,$col)=add_param_widget ($self, $d->{label}, $d->{param_name}, $d->{default_val}, $d->{type}, $d->{content}, $d->{info}, $table,$row,$col,1, $d->{param_parent}, $d->{ref_delay},undef,"vertical");
	}
	
	$row++;
	
	
	
	my $next=def_image_button('icons/run.png','Next');
	my $back=def_image_button('icons/left.png','Previous');	
	
	$col=1;
	my $i;	
	for ($i=$row; $i<5; $i++){
		
		my $temp=gen_label_in_center(" ");
		$table->attach_defaults ($temp, 3, 4 , $i, $i+1);
	}
	$row=$i;
	
	#$table->attach($back,2,3,9,10,'shrink','shrink',2,2);
	$table->attach($next,3,4,$row,$row+1,'shrink','shrink',2,2);


	
	$back-> signal_connect("clicked" => sub{ 
		
		$window->destroy;
		
		
	});
	$next-> signal_connect("clicked" => sub{ 
		
		$window->destroy;
		
		
	});
	


	

	$window->add ($table);
	$window->show_all();



}


sub check_hotspot_parameters{
	my ($self,$sample)=@_;
	my $num=$self->object_get_attribute($sample,"HOTSPOT_NUM");
	my $result;
	if (defined $num){
		my @hotspots;	
		my $acuum=0;	
		for (my $i=0;$i<$num;$i++){
			my $w1 = $self->object_get_attribute($sample,"HOTSPOT_CORE_$i");
			if( grep (/^\Q$w1\E$/,@hotspots)){
				$result="Error: Tile $w1 has been selected for Two or more than two hotspot nodes.\n";					
			}
			push( @hotspots,$w1);			
			my $w2 = $self->object_get_attribute($sample,"HOTSPOT_PERCENT_$i");
			$acuum+=$w2;
					
		}
		if ($acuum > 100){
			$result="Error: The traffic sumation of all hotspot nodes is $acuum. The hotspot sumation must be <=100";
			
		}
	}
	return $result;
}


sub get_simulator_noc_configuration{
	my ($self,$mode,$sample,$set_win) =@_;
	
	my $table=def_table(10,2,FALSE);
	my $row=0;
	
	my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);
	$scrolled_win->set_policy( "automatic", "automatic" );
	$scrolled_win->add_with_viewport($table);
		
	my $ok = def_image_button('icons/select.png','OK');
	my $mtable = def_table(10, 1, TRUE);

	$mtable->attach_defaults($scrolled_win,0,1,0,9);
	$mtable-> attach ($ok , 0, 1,  9, 10,'expand','shrink',2,2); 
	
	

	$set_win ->signal_connect (destroy => sub{		
		$self->object_add_attribute("active_setting",undef,undef);
	});	
		
	
	my $dir = Cwd::getcwd();
	my $open_in	  = abs_path("$ENV{PRONOC_WORK}/simulate");	
	
	
	attach_widget_to_table ($table,$row,gen_label_in_left(" Search Path:"),gen_button_message ("Select the the Path where the verilator simulation files are located. Different NoC verilated models can be generated using Generate NoC configuration tab.","icons/help.png"), 
	get_dir_in_object ($self,$sample,"sof_path",undef,'ref_set_win',1,$open_in)); $row++;
	
	$open_in	= $self->object_get_attribute($sample,"sof_path");	
	
	
	
	my @files = glob "$open_in/*";
	my $exe_files="";
	foreach my $file (@files){
		#print "$file is executable\n" if( -x $file && -f $file) ;
		
		if( -x $file && -f $file){
			my ($name,$path,$suffix) = fileparse("$file",qr"\..[^.]*$");
			$exe_files="$exe_files,$name"
			
		} 
		
	}
		
	attach_widget_to_table ($table,$row,gen_label_in_left(" Verilated Model:"),gen_button_message ("Select the verilator simulation file. Different NoC simulators can be generated using Generate NoC configuration tab.","icons/help.png"), 
	gen_combobox_object ($self,$sample, "sof_file", $exe_files, undef, undef, undef)); $row++;

    $row=noc_param_widget ($self, "Traffic Type", "TRAFFIC_TYPE", "Synthetic", 'Combo-box', "Synthetic,Task-graph", undef, $table,$row,1, $sample, 1,'ref_set_win');

    my $traffictype=$self->object_get_attribute($sample,"TRAFFIC_TYPE");
   
   


	
	

	
	
	
	
	if($traffictype eq "Synthetic"){
		
		my $min=$self->object_get_attribute($sample,'MIN_PCK_SIZE');
		my $max=$self->object_get_attribute($sample,'MAX_PCK_SIZE');
		$min=$max=5 if(!defined $min);
		my $avg=floor(($min+$max)/2);	
		
			my $traffics="tornado,transposed 1,transposed 2,bit reverse,bit complement,random,hot spot"; 	
		my @synthinfo = (
		
		
		{ label=>'Configuration name:', param_name=>'line_name', type=>'Entry', default_val=>$sample, content=>undef, info=>"NoC configration name. This name will be shown in load-latency graph for this configuration", param_parent=>$sample, ref_delay=> undef, new_status=>undef},
	
		
	
	  	{ label=>"Traffic name", param_name=>'traffic', type=>'Combo-box', default_val=>'random', content=>$traffics, info=>"Select traffic pattern", param_parent=>$sample, ref_delay=>1, new_status=>'ref_set_win'},
	
		{ label=>"Min pck size :", param_name=>'MIN_PCK_SIZE', type=>'Spin-button', default_val=>5, content=>"2,$max,1", info=>"Minimum packet size in flit. The injected packet size is randomly selected between minimum and maximum packet size", param_parent=>$sample, ref_delay=>10, new_status=>'ref_set_win'},
		{ label=>"Max pck size :", param_name=>'MAX_PCK_SIZE', type=>'Spin-button', default_val=>5, content=>"$min,".MAX_PCK_SIZ.",1", info=>"Maximum packet size in flit. The injected packet size is randomly selected between minimum and maximum packet size", param_parent=>$sample, ref_delay=>10, new_status=>'ref_set_win'},
		
		
		
		{ label=>"Avg. Packet size:", param_name=>'PCK_SIZE', type=>'Combo-box', default_val=>$avg, content=>"$avg", info=>undef, param_parent=>$sample, ref_delay=>undef},
	
		{ label=>"Total packet number limit:", param_name=>'PCK_NUM_LIMIT', type=>'Spin-button', default_val=>200000, content=>"2,".MAX_PCK_NUM.",1", info=>"Simulation will stop when total numbr of sent packets by all nodes reaches packet number limit  or total simulation clock reach its limit", param_parent=>$sample, ref_delay=>undef, new_status=>undef},
	
		{ label=>"Simulator clocks limit:", param_name=>'SIM_CLOCK_LIMIT', type=>'Spin-button', default_val=>100000, content=>"2,".MAX_SIM_CLKs.",1", info=>"Each node stops sending packets when it reaches packet number limit  or simulation clock number limit", param_parent=>$sample, ref_delay=>undef,  new_status=>undef},
		
		
		
		);
		
		foreach my $d (@synthinfo) {
			$row=noc_param_widget ($self, $d->{label}, $d->{param_name}, $d->{default_val}, $d->{type}, $d->{content}, $d->{info}, $table,$row,1, $d->{param_parent}, $d->{ref_delay}, $d->{new_status});
		}
		
		

		
	
		my $traffic=$self->object_get_attribute($sample,"traffic");

		if ($traffic eq 'hot spot'){
			my $htable=def_table(10,2,FALSE);
			
			my $d= { label=>'number of Hot Spot nodes:', param_name=>'HOTSPOT_NUM', type=>'Spin-button', default_val=>1,  content=>"1,256,1", info=>"Number of hot spot nodes in the network",			  param_parent=>$sample, ref_delay=> 1, new_status=>'ref_set_win'};
			$row=noc_param_widget ($self, $d->{label}, $d->{param_name}, $d->{default_val}, $d->{type}, $d->{content}, $d->{info}, $table,$row,1, $d->{param_parent}, $d->{ref_delay}, $d->{new_status});
				
				my $l1=gen_label_help("Defne the tile number which is  hotspt. All other nodes will send [Hot Spot traffic percentage] of their traffic to this node","  Hot Spot tile number \%");
				my $l2=gen_label_help("If it is set as \"n\" then each node sends n % of its traffic to each hotspot node","  Hot Spot traffic \%");
				my $l3=gen_label_help("If it is checked then hot spot node also sends packets to other nodes otherwise it only recieves packets from other nodes","  send enable");
				
				$htable->attach  ($l1 , 0, 1,  $row,$row+1,'fill','shrink',2,2);
				$htable->attach  ($l2 , 1, 2,  $row,$row+1,'fill','shrink',2,2);
				$htable->attach  ($l3 , 2,3,  $row,$row+1,'fill','shrink',2,2);
				$row++;
						
				my $num=$self->object_get_attribute($sample,"HOTSPOT_NUM");
				for (my $i=0;$i<$num;$i++){
					my $w1 = gen_spin_object ($self,$sample,"HOTSPOT_CORE_$i","0,256,1", $i,undef,undef);
					my $w2 = gen_spin_object ($self,$sample,"HOTSPOT_PERCENT_$i","0.1,100,0.1", 0.1,undef,undef);
					my $w3 = gen_check_box_object ($self,$sample,"HOTSPOT_SEND_EN_$i", 0,undef,undef);
					$htable->attach  ($w1 , 0, 1,  $row,$row+1,'fill','shrink',2,2);
					$htable->attach  ($w2 ,1, 2,  $row,$row+1,'fill','shrink',2,2);
					$htable->attach  ($w3 , 2,3,  $row,$row+1,'fill','shrink',2,2);
					$row++;
				
				}
				
				$table->attach  ($htable , 0, 3,  $row,$row+1,'shrink','shrink',2,2); $row++;
			
			
			
			
			
			
		
		}
		my $l= "Define injection ratios. You can define individual ratios seprating by comma (\',\') or define a range of injection ratios with \$min:\$max:\$step format.
			As an example defining 2,3,4:10:2 will result in (2,3,4,6,8,10) injection ratios." ;
		my $u=get_injection_ratios ($self,$sample,"ratios");
		
		attach_widget_to_table ($table,$row,gen_label_in_left(" Injection ratios:"),gen_button_message ($l,"icons/help.png") , $u); $row++;
	
		$ok->signal_connect("clicked"=> sub{
			#check if sof file has been selected
			my $s=$self->object_get_attribute($sample,"sof_file");
			#check if injection ratios are valid
			my $r=$self->object_get_attribute($sample,"ratios");
			my $h;
			if ($traffic eq 'hot spot'){
				$h=	check_hotspot_parameters($self,$sample);
			}	
			
			if(defined $s && defined $r && !defined $h) {	
					$set_win->destroy;
					#$emulate->object_add_attribute("active_setting",undef,undef);
					set_gui_status($self,"ref",1);
			} else {
				
				if(!defined $s){
					my $m= "Please select NoC verilated file";
					message_dialog($m);  
				} elsif (! defined $r) {
					 message_dialog("Please define valid injection ratio(s)!");
				} else {
					 message_dialog("$h");					
				}
			}
		});
	
	}	
	
	
		
	if($traffictype eq "Task-graph"){
		
		my @custominfo = (
		#{ label=>"Verilated Model", param_name=>'sof_file', type=>'Combo-box', default_val=>undef, content=>$exe_files, info=>"Select the the verilator simulation file. Different NoC simulators can be generated using Generate NoC configuration tab.", param_parent=>$sample, ref_delay=>undef, new_status=>undef},
		
		{ label=>'Configuration name:', param_name=>'line_name', type=>'Entry', default_val=>$sample, content=>undef, info=>"NoC configration name. This name will be shown in load-latency graph for this configuration", param_parent=>$sample, ref_delay=> undef, new_status=>undef},
	
	  	{ label=>"Number of Files", param_name=>"TRAFFIC_FILE_NUM", type=>'Spin-button', default_val=>1, content=>"1,100,1", info=>"Select number of input files", param_parent=>$sample, ref_delay=>1, new_status=>'ref_set_win'},
		
		{ label=>"Simulator clocks limit:", param_name=>'SIM_CLOCK_LIMIT', type=>'Spin-button', default_val=>100000, content=>"2,".MAX_SIM_CLKs.",1", info=>"Each node stops sending packets when it reaches packet number limit  or simulation clock number limit", param_parent=>$sample, ref_delay=>undef,  new_status=>undef},
		);
		
		foreach my $d (@custominfo) {
			$row=noc_param_widget ($self, $d->{label}, $d->{param_name}, $d->{default_val}, $d->{type}, $d->{content}, $d->{info}, $table,$row,1, $d->{param_parent}, $d->{ref_delay}, $d->{new_status});
		}
		
		
		
	
		my $open_in  = "$ENV{'PRONOC_WORK'}/traffic_pattern";
		
		
	
		 my $num=$self->object_get_attribute($sample,"TRAFFIC_FILE_NUM");
		 for (my $i=0; $i<$num; $i++){
		 	attach_widget_to_table ($table,$row,gen_label_in_left("traffic pattern file $i:"),gen_button_message ("Select the the traffic pattern input file.","icons/help.png"), get_file_name_object ($self,$sample,"traffic_file$i",undef,$open_in)); $row++;
		 }
		 
		$ok->signal_connect("clicked"=> sub{
			#check if sof file has been selected
			my $s=$self->object_get_attribute($sample,"sof_file");
			if(!defined $s){
					message_dialog("Please select NoC verilated file"); 
					return;
			}
						
			#check if traffic files have been selected
			for (my $i=0; $i<$num; $i++){
				my $f=$self->object_get_attribute($sample,"traffic_file$i");
				if(!defined $f){
					my $m= "Please select traffic_file$i";
					message_dialog($m); 
					return;
				}
			 	
			}
			$set_win->destroy;
			set_gui_status($self,"ref",1);
				
		});
		 
		 
	}
	
	
	
	$set_win->add ($mtable);
	$set_win->show_all();	
	
	
}



############
#	run_simulator
###########

sub run_simulator {
	my ($simulate,$info)=@_;
	#return if(!check_samples($emulate,$info));
	$simulate->object_add_attribute('status',undef,'run');
	set_gui_status($simulate,"ref",1);
	show_info($info, "Start Simulation\n");
	my $name=$simulate->object_get_attribute ("simulate_name",undef);	
	
	#unlink $log; # remove old log file
	
	my @samples =$simulate->object_get_attribute_order("samples");
	foreach my $sample (@samples){
		my $status=$simulate->object_get_attribute ($sample,"status");	
		next if($status ne "run");
		next if(!check_sim_sample($simulate,$sample,$info));
		my $traffictype=$simulate->object_get_attribute($sample,"TRAFFIC_TYPE");
		run_synthetic_simulation($simulate,$info,$sample,$name) if($traffictype eq "Synthetic");
		run_custom_simulation($simulate,$info,$sample,$name) if($traffictype eq "Task-graph");
		
    	
	}
	
	add_info($info, "Simulation is done!\n");
	$simulate->object_add_attribute('status',undef,'ideal');
	set_gui_status($simulate,"ref",1);
}	


sub run_synthetic_simulation {
	my ($simulate,$info,$sample,$name)=@_;
	my $log= (defined $name)? "$ENV{PRONOC_WORK}/simulate/$name.log": "$ENV{PRONOC_WORK}/simulate/sim.log";
	my $r= $simulate->object_get_attribute($sample,"ratios");
	my @ratios=@{check_inserted_ratios($r)};
	#$emulate->object_add_attribute ("sample$i","status","run");
	my $bin_path=$simulate->object_get_attribute ($sample,"sof_path");	
	my $bin_file=$simulate->object_get_attribute ($sample,"sof_file");			
	my $bin="$bin_path/$bin_file";
	
	#load traffic configuration
	my $patern=$simulate->object_get_attribute ($sample,'traffic');
	my $MIN_PCK_SIZE=$simulate->object_get_attribute ($sample,"MIN_PCK_SIZE");
	my $MAX_PCK_SIZE=$simulate->object_get_attribute ($sample,"MAX_PCK_SIZE");
	my $PCK_NUM_LIMIT=$simulate->object_get_attribute ($sample,"PCK_NUM_LIMIT");
	my $SIM_CLOCK_LIMIT=$simulate->object_get_attribute ($sample,"SIM_CLOCK_LIMIT");
	
	
	#hotspot 
	my $hotspot="";
	if($patern eq "hot spot"){
		$hotspot="-h \" ";
		my $num=$simulate->object_get_attribute($sample,"HOTSPOT_NUM");
		if (defined $num){
			$hotspot="$hotspot $num";
			
			for (my $i=0;$i<$num;$i++){
				my $w1 = $simulate->object_get_attribute($sample,"HOTSPOT_CORE_$i");
				my $w2 = $simulate->object_get_attribute($sample,"HOTSPOT_PERCENT_$i");
				$w2=$w2*10;
				my $w3 = $simulate->object_get_attribute($sample,"HOTSPOT_SEND_EN_$i");
				$hotspot="$hotspot,$w1,$w3,$w2";
			}
			
		}
		
		$hotspot="$hotspot \"";
				
	}
			
				
		
	foreach  my $ratio_in (@ratios){						
	    	#my $r= $ratio_in * MAX_RATIO/100;
	    	add_info($info, "Run $bin with  injection ratio of $ratio_in \% \n");
	    	my $cmd="$bin -t \"$patern\"  -s $MIN_PCK_SIZE -m $MAX_PCK_SIZE  -n  $PCK_NUM_LIMIT  -c	$SIM_CLOCK_LIMIT   -i $ratio_in -p \"100,0,0,0,0\"  $hotspot";
			add_info($info, "$cmd \n");
			my $time_strg = localtime;
			append_text_to_file($log,"started at:$time_strg\n"); #save simulation output
			my ($stdout,$exit,$stderr)=run_cmd_in_back_ground_get_stdout("$cmd");
			if($exit){
				add_info($info, "Error in running simulation: $stderr \n");
				$simulate->object_add_attribute ($sample,"status","failed");	
				$simulate->object_add_attribute('status',undef,'ideal');
				return;
			}
	 			
			append_text_to_file($log,$stdout); #save simulation output
			$time_strg = localtime;
			append_text_to_file($log,"Ended at:$time_strg\n"); #save simulation output
			
			#my @q =split  (/average latency =/,$stdout);
			#my $d=$q[1];
			#@q =split  (/\n/,$d);
			#my $avg=$q[0];
			my $avg_latency =capture_number_after("average latency =",$stdout);
			my $avg_thput =capture_number_after("Avg throughput is:",$stdout);
			my $total_time =capture_number_after("simulation clock cycles:",$stdout);
			
			my %packet_rsvd_per_core = capture_cores_data("total number of received packets:",$stdout);
			my %worst_rsvd_delay_per_core = capture_cores_data('worst-case-delay of received pckets \(clks\):',$stdout);
			my %packet_sent_per_core = capture_cores_data("total number of sent packets:",$stdout);
			my %worst_sent_delay_per_core = capture_cores_data('worst-case-delay of sent pckets \(clks\):',$stdout);
			#my $avg = sprintf("%.1f", $avg);
	    		
		    	
	    	next if (!defined $avg_latency);
			update_result($simulate,$sample,"latency_result",$ratio_in,$avg_latency);
			update_result($simulate,$sample,"throughput_result",$ratio_in,$avg_thput);
			update_result($simulate,$sample,"exe_time_result",$ratio_in,$total_time);
			foreach my $p (sort keys %packet_rsvd_per_core){
				update_result($simulate,$sample,"packet_rsvd_result",$ratio_in,$p,$packet_rsvd_per_core{$p} );
				update_result($simulate,$sample,"worst_delay_rsvd_result",$ratio_in,$p,$worst_rsvd_delay_per_core{$p});
				update_result($simulate,$sample,"packet_sent_result",$ratio_in,$p,$packet_sent_per_core{$p} );
				update_result($simulate,$sample,"worst_delay_sent_result",$ratio_in,$p,$worst_sent_delay_per_core{$p});
		    	}
		    	set_gui_status($simulate,"ref",2);
		
	  	
		    	
	    		    	
		}
		$simulate->object_add_attribute ($sample,"status","done");	
	
	
}



sub run_custom_simulation{
	my ($simulate,$info,$sample,$name)=@_;
	my $log= (defined $name)? "$ENV{PRONOC_WORK}/simulate/$name.log": "$ENV{PRONOC_WORK}/simulate/sim.log";
	my $SIM_CLOCK_LIMIT=$simulate->object_get_attribute ($sample,"SIM_CLOCK_LIMIT");
	my $bin_path=$simulate->object_get_attribute ($sample,"sof_path");	
	my $bin_file=$simulate->object_get_attribute ($sample,"sof_file");			
	my $bin="$bin_path/$bin_file";
	my $dir = Cwd::getcwd();
	my $project_dir	  = abs_path("$dir/../.."); #mpsoc directory address
	$bin= "$project_dir/$bin"   if(!(-f $bin));
	my $num=$simulate->object_get_attribute($sample,"TRAFFIC_FILE_NUM");
	for (my $i=0; $i<$num; $i++){
		 my $f=$simulate->object_get_attribute($sample,"traffic_file$i");
		 add_info($info, "Run $bin for $f  file \n");	
		 my $cmd="$bin  -c	$SIM_CLOCK_LIMIT  -f \"$project_dir/$f\"";
		 add_info($info, "$cmd \n");
		 my $time_strg = localtime;
		 append_text_to_file($log,"started at:$time_strg\n"); #save simulation output	
		 
		 my ($stdout,$exit,$stderr)=run_cmd_in_back_ground_get_stdout("$cmd");
		 if($exit){
				add_info($info, "Error in running simulation: $stderr \n");
				$simulate->object_add_attribute ($sample,"status","failed");	
				$simulate->object_add_attribute('status',undef,'ideal');
				return;
		 }
		 append_text_to_file($log,$stdout); #save simulation output
			$time_strg = localtime;
			append_text_to_file($log,"Ended at:$time_strg\n"); #save simulation output
			
			#my @q =split  (/average latency =/,$stdout);
			#my $d=$q[1];
			#@q =split  (/\n/,$d);
			#my $avg=$q[0];
			my $avg_latency =capture_number_after("average latency =",$stdout);
			my $avg_thput =capture_number_after("Avg throughput is:",$stdout);
			my %packet_rsvd_per_core = capture_cores_data("total number of received packets:",$stdout);
			my %worst_rsvd_delay_per_core = capture_cores_data('worst-case-delay of received pckets \(clks\):',$stdout);
			my %packet_sent_per_core = capture_cores_data("total number of sent packets:",$stdout);
			my %worst_sent_delay_per_core = capture_cores_data('worst-case-delay of sent pckets \(clks\):',$stdout);
			my $total_time =capture_number_after("simulation clock cycles:",$stdout);
			#my $avg = sprintf("%.1f", $avg);
	    		
		    	
	    	next if (!defined $avg_latency);
			update_result($simulate,$sample,"latency_result",$i,$avg_latency);
			update_result($simulate,$sample,"throughput_result",$i,$avg_thput);
			update_result($simulate,$sample,"exe_time_result",$i,$total_time);
			foreach my $p (sort keys %packet_rsvd_per_core){
				update_result($simulate,$sample,"packet_rsvd_result",$i,$p,$packet_rsvd_per_core{$p} );
				update_result($simulate,$sample,"worst_delay_rsvd_result",$i,$p,$worst_rsvd_delay_per_core{$p});
				update_result($simulate,$sample,"packet_sent_result",$i,$p,$packet_sent_per_core{$p} );
				update_result($simulate,$sample,"worst_delay_sent_result",$i,$p,$worst_sent_delay_per_core{$p});
		    	}
		    	set_gui_status($simulate,"ref",2);
		 
		 
		 
	}
	
	
	$simulate->object_add_attribute ($sample,"status","done");	
}	



##########
# check_sample
##########

sub check_sim_sample{
	my ($self,$sample,$info)=@_;
	my $status=1;
	my $bin_path=$self->object_get_attribute ($sample,"sof_path");	
	my $bin_file=$self->object_get_attribute ($sample,"sof_file");			
	my $sof="$bin_path/$bin_file";
	
		
	# ckeck if sample have sof file
	if(!defined $sof){
		add_info($info, "Error: bin file has not set for $sample!\n");
		$self->object_add_attribute ($sample,"status","failed");	
		$status=0;
	} else {
		# ckeck if bin file has info file 
		my ($name,$path,$suffix) = fileparse("$sof",qr"\..[^.]*$");
		my $sof_info= "$path$name.inf";
		if(!(-f $sof_info)){
			add_info($info, "Could not find $name.inf file in $path. An information file is required for each sof file containig the device name and  NoC configuration. Press F4 for more help.\n");
			$self->object_add_attribute ($sample,"status","failed");	
			$status=0;
		}else { #add info
			my $pp= do $sof_info ;

			my $p=$pp->{'noc_param'};
			
			$status=0 if $@;
			message_dialog("Error reading: $@") if $@;
			if ($status==1){
				$self->object_add_attribute ($sample,"noc_info",$p) ;
					
			
			}			
		}		
	}
				
	return $status;
}



############
#    main
############
sub simulator_main{
	
	add_color_to_gd();
	my $simulate= emulator->emulator_new();
	set_gui_status($simulate,"ideal",0);
	

	my $main_table = Gtk2::Table->new (25, 12, FALSE);
	my ($infobox,$info)= create_text();	
	add_colors_to_textview($info);	
	

my @pages =(
	{page_name=>" Avg. throughput/latency", page_num=>0},
	{page_name=>" Injected Packet ", page_num=>1},
	{page_name=>" Worst-Case Delay ",page_num=>2},
	{page_name=>" Executaion Time ",page_num=>3},
);



my @charts = (
	{ type=>"2D_line", page_num=>0, graph_name=> "Latency", result_name => "latency_result", X_Title=> 'Desired Avg. Injected Load Per Router (flits/clock (%))', Y_Title=>'Latency (clock)', Z_Title=>undef, Y_Max=>100},
  	{ type=>"2D_line", page_num=>0, graph_name=> "Throughput", result_name => "throughput_result", X_Title=> 'Desired Avg. Injected Load Per Router (flits/clock (%))', Y_Title=>'Avg. Throughput (flits/clock (%))', Z_Title=>undef},
	{ type=>"3D_bar",  page_num=>1, graph_name=> "Received", result_name => "packet_rsvd_result", X_Title=>'Core ID' , Y_Title=>'Received Packets Per Router', Z_Title=>undef},
	{ type=>"3D_bar",  page_num=>1, graph_name=> "Sent", result_name => "packet_sent_result", X_Title=>'Core ID' , Y_Title=>'Sent Packets Per Router', Z_Title=>undef},
	{ type=>"3D_bar",  page_num=>2, graph_name=> "Received", result_name => "worst_delay_rsvd_result",X_Title=>'Core ID' , Y_Title=>'Worst-Case Delay (clk)', Z_Title=>undef},
	{ type=>"3D_bar",  page_num=>2, graph_name=> "Sent", result_name => "worst_delay_sent_result",X_Title=>'Core ID' , Y_Title=>'Worst-Case Delay (clk)', Z_Title=>undef},
	{ type=>"2D_line", page_num=>3, graph_name=> "-", result_name => "exe_time_result",X_Title=>'Desired Avg. Injected Load Per Router (flits/clock (%))' , Y_Title=>'Total Simulation Time (clk)', Z_Title=>undef},
	
	);
	
	
	my ($conf_box,$set_win)=process_notebook_gen($simulate,\$info,"simulate",@charts);
	my $chart   =gen_multiple_charts  ($simulate,\@pages,\@charts);
    


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
	
	
	
	
	my $v1=gen_vpaned($conf_box,.45,$image);
	my $v2=gen_vpaned($infobox,.2,$chart);
	my $h1=gen_hpaned($v1,.4,$v2);
	
	
	
	$main_table->attach_defaults ($h1  , 0, 12, 0,24);
	$main_table->attach ($open,0, 3, 24,25,'expand','shrink',2,2);
	$main_table->attach ($entrybox,3, 6, 24,25,'expand','shrink',2,2);
	$main_table->attach ($generate, 6, 9, 24,25,'expand','shrink',2,2);
	


	#check soc status every 0.5 second. referesh device table if there is any changes 
	Glib::Timeout->add (100, sub{ 
	 
		my ($state,$timeout)= get_gui_status($simulate);
		
		if ($timeout>0){
			$timeout--;
			set_gui_status($simulate,$state,$timeout);	
			return TRUE;
			
		}
		if($state eq "ideal"){
			return TRUE;
			 
		}
		
		if($state eq 'ref_set_win'){
			
			my $s=$simulate->object_get_attribute("active_setting",undef);
			$set_win->destroy();
			$simulate->object_add_attribute("active_setting",undef,$s);		 
		}
		
		
		#refresh GUI
		my $name=$simulate->object_get_attribute ("simulate_name",undef);	
		$entry->set_text($name) if(defined $name);
									
		$conf_box->destroy();
		$chart->destroy();
		$image->destroy(); 
		$image = get_status_gif($simulate);
		($conf_box,$set_win)=process_notebook_gen($simulate,\$info,"simulate",@charts);				
		$chart = gen_multiple_charts  ($simulate,\@pages,\@charts);
		$v1 -> pack1($conf_box, TRUE, TRUE); 	
		$v1 -> pack2($image, TRUE, TRUE); 		
		$v2 -> pack2($chart, TRUE, TRUE); 	
		$conf_box->show_all();
		$main_table->show_all();			
		set_gui_status($simulate,"ideal",0);
		
		return TRUE;
		
	} );
		
		
	$generate-> signal_connect("clicked" => sub{ 
		my @samples =$simulate->object_get_attribute_order("samples");	
		foreach my $sample (@samples){
			$simulate->object_add_attribute ("$sample","status","run");	
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
		#print Dumper($simulate);
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
