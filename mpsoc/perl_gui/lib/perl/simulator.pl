#! /usr/bin/perl -w
use constant::boolean;
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;



use GD::Graph::Data;
use emulator;
use GD::Graph::colour qw/:colours/;

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




sub generate_sim_bin_file {
	my ($simulate,$info_text) =@_;
	#check simulator envirement
	my $simulator =$simulate->object_get_attribute("Simulator");
	#TODO generate .sim file only for modelsim simulator
		
	$simulate->object_add_attribute('status',undef,'run');
	set_gui_status($simulate,"ref",1);
	
	my ($nr,$ne,$router_p,$ref_tops,$includ_h)= get_noc_verilator_top_modules_info($simulate);
	my %tops = %{$ref_tops};
	
	$tops{Vtraffic} = "--top-module traffic_gen_top";	
	$tops{Vpck_inj} = "--top-module packet_injector_verilator";	
	my $target_dir= "$ENV{PRONOC_WORK}/simulate";
	
	
	my $project_dir	  = get_project_dir()."/mpsoc/";
	my $src_verilator_dir="$project_dir/src_verilator";
	my $src_c="$project_dir/src_c";
	my $src_noc_dir="$project_dir/rtl/src_noc";	
	my $script_dir="$project_dir/script";
	my $testbench_file= "$src_verilator_dir/simulator.cpp";
	
	my $target_verilog_dr ="$target_dir/src_verilog";
	my $obj_dir ="$target_dir/verilator/obj_dir/";
	
	rmtree("$target_dir/verilator");
	rmtree("$target_verilog_dr");
	mkpath("$target_verilog_dr/",1,01777);
	
	#copy src_verilator files
	my @files_list = File::Find::Rule->file()
                            ->name( '*.v','*.V','*.sv' )
                            ->in( "$src_verilator_dir" );

	#make sure source files have key word 'module' 
	my @files;
	foreach my $p (@files_list){
		push (@files,$p)	if(check_file_has_string($p,'module')); 
	}
	push (@files,$src_noc_dir);
	push (@files,"$project_dir/rtl/arbiter.v");
	push (@files,"$project_dir/rtl/main_comp.v");
	push (@files,"$project_dir/rtl/pronoc_def.v");
	
		
	#my @files=(
	#	$src_noc_dir,
	#	"$src_verilator_dir/noc_connection.sv",
	#	"$src_verilator_dir/mesh_torus_noc_connection.sv",			
	#	"$src_verilator_dir/router_verilator.v",
	#	"$src_verilator_dir/traffic_gen_verilator.v"		
	#);
	
	copy_file_and_folders (\@files,$project_dir,$target_verilog_dr);
	copy_file_and_folders (\@files,$project_dir,"$target_dir/modelsim/src_verilog/");
	
	my $target_modelsim_dr ="$target_dir/modelsim/src_modelsim";
	my $src_modelsim_dir="$project_dir/rtl/src_modelsim";	
	rmtree("$target_modelsim_dr");
	mkpath("$target_modelsim_dr/",1,01777);
	
	#copy src_verilator files
	@files_list = File::Find::Rule->file()
                            ->name( '*.v','*.V','*.sv' )
                            ->in( "$src_modelsim_dir" );

	#make sure source files have key word 'module' 
	@files=();
	foreach my $p (@files_list){
		push (@files,$p)	if(check_file_has_string($p,'module')); 
	}
	copy_file_and_folders (\@files,$project_dir,$target_modelsim_dr);
	
	
		
	
	#check if we have a custom topology 
	my $topology=$simulate->object_get_attribute('noc_param','TOPOLOGY');
	if ($topology eq '"CUSTOM"'){ 
		my $name=$simulate->object_get_attribute('noc_param','CUSTOM_TOPOLOGY_NAME');
		$name=~s/["]//gs;     
		my $dir1=  get_project_dir()."/mpsoc/rtl/src_topolgy/$name";
		my $dir2=  get_project_dir()."/mpsoc/rtl/src_topolgy/common";
		my @files = File::Find::Rule->file()
                            ->name( '*.v','*.V','*.sv' )
                            ->in( "$dir1" );
		copy_file_and_folders (\@files,$project_dir,$target_verilog_dr);
		copy_file_and_folders (\@files,$project_dir,"$target_dir/modelsim/src_verilog/");
		
		@files = File::Find::Rule->file()
                            ->name( '*.v','*.V','*.sv' )
                            ->in( "$dir2" );
                         
		copy_file_and_folders (\@files,$project_dir,$target_verilog_dr);
		copy_file_and_folders (\@files,$project_dir,"$target_dir/modelsim/src_verilog/");
		
		
	
	}
	# generate NoC parameter file	
	my $fifow=$simulate->object_get_attribute('fpga_param','TIMSTMP_FIFO_NUM');
	gen_noc_localparam_v_file($simulate,"$target_verilog_dr/src_noc");

	#generate routers with different port num		
	my $cpu_num = $simulate->object_get_attribute('compile', 'cpu_num');
	my $result = verilator_compilation (\%tops,$target_dir,$info_text,$cpu_num);
	
	
	if ($result){
		add_colored_info($info_text,"Veriator model has been generated successfully!\n",'blue');
	}else {
		add_colored_info($info_text,"Verilator compilation failed!\n","red"); 
		$simulate->object_add_attribute('status',undef,'programmer_failed');
		set_gui_status($simulate,"ref",1);
		print "gen-ended!\n";
		return;
	}
	
	my $r;	
	#copy nettrace synful
	dircopy("$src_c/netrace-1.0","$obj_dir/netrace-1.0") or $r=$!;
	dircopy("$src_c/synfull","$obj_dir/synful") or $r=$!;
	add_colored_info($info_text,"ERROR: $r\n","red") if(defined $r ) ; 	
	
	
	#copy simulation c header files
	@files = File::Find::Rule->file()
                            ->name( '*.h')
                            ->in( "$src_verilator_dir" );
	
	copy_file_and_folders (\@files,$project_dir,$obj_dir);
	copy($testbench_file,"$obj_dir/testbench.cpp"); 
		
	
		
	#compile the testbench
	my $param_h=gen_noc_param_h($simulate);
	my $text = gen_sim_parameter_h($param_h,$includ_h,$ne,$nr,$router_p,$fifow);	
	
	
	open(FILE,  ">$obj_dir/parameter.h") || die "Can not open: $!";
	print FILE  "$text";
	
	close FILE;
	
	
	
	#$result = run_make_file("$obj_dir/",$info_text,'lib');	
	my $lib_num=0;
	add_colored_info($info_text,"Makefie will use the maximum number of $cpu_num core(s) in parallel for compilation\n",'green');
	my $length=scalar (keys %tops);
	my $cmd="";
	foreach my $top (sort keys %tops) { 
		$cmd.= "lib$lib_num & ";
		$lib_num++;				
		if( $lib_num % $cpu_num == 0 || $lib_num == $length){
			$cmd.="wait\n";
			$result = run_make_file("$obj_dir/",$info_text,$cmd);	
			if ($result ==0){
				$simulate->object_add_attribute('status',undef,'programmer_failed');
				set_gui_status($simulate,"ref",1);
				print "gen-ended!\n";
				return;
			}		
			$cmd="";
		}else {
			$cmd.=" make ";
		}	
	}
		
		
	
	
	run_make_file("$obj_dir/",$info_text);	
	if ($result ==0){
		$simulate->object_add_attribute('status',undef,'programmer_failed');
		set_gui_status($simulate,"ref",1);
		print "gen-ended!\n";
		return;
	}		
	
	
	
	
	#my $end = localtime; 		
	

	
	#save the binarry file
	my $bin= "$obj_dir/testbench";
	my $path=$simulate->object_get_attribute ('sim_param',"BIN_DIR");
	my $name=$simulate->object_get_attribute ('sim_param',"SAVE_NAME");
	
	#create project directory if it does not exist
	my	($stdout,$exit)=run_cmd_in_back_ground_get_stdout("mkdir -p $path" );
	if($exit != 0 ){ 	print "$stdout\n";  print "gen-ended!\n";	message_dialog($stdout,'error'); return;}
	

	
	#check if the verilation was successful
	if ((-e $bin)==0) {#something goes wrong 		
    	#message_dialog("Verilator compilation was unsuccessful please check the $path/$name.log files for more information",'error'); 
    	add_colored_info($info_text,"Verilator compilation failed!\n","red"); 
    	$simulate->object_add_attribute('status',undef,'programmer_failed');
		set_gui_status($simulate,"ref",1);
		print "gen-ended!\n";
		return;
	}
	
	
	#copy ($bin,"$path/$name") or  die "Can not copy: $!";
	($stdout,$exit)=run_cmd_in_back_ground_get_stdout("cp -f $bin $path/$name");
	if($exit != 0 ){ 	print "$stdout\n";  print "gen-ended!\n";	message_dialog($stdout,'error'); return;}
		
	#save noc info
	open(FILE,  ">$path/$name.inf") || die "Can not open: $!";
	print FILE perl_file_header("$name.inf");
	my %pp;
	$pp{'noc_param'}= $simulate->{'noc_param'};
	$pp{'sim_param'}= $simulate->{'sim_param'};
	print FILE Data::Dumper->Dump([\%pp],["emulate_info"]);
	close(FILE) || die "Error closing file: $!";		
	
	print "gen-ended successfully!\n";
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
	my $dialog =  gen_file_dialog (undef, 'SIM');	
	
	my $dir = Cwd::getcwd();
	$dialog->set_current_folder ("$dir/lib/simulate");		


	if ( "ok" eq $dialog->run ) {
		$file = $dialog->get_filename;
		my ($name,$path,$suffix) = fileparse("$file",qr"\..[^.]*$");
		if($suffix eq '.SIM'){
			my ($pp,$r,$err) = regen_object($file);
			if ($r){		
				add_colored_info($info,"**Error reading $file file: $err\n",'red');
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
			$result="Error: The traffic summation of all hotspot nodes is $acuum. The hotspot summation must be <=100";
			
		}
	}
	return $result;
}

sub get_district_avg { 
	my ($self,$sample)=@_;
	my $vt=$self->object_get_attribute($sample,"DISCRETE_RANGE");
	$vt =  "2,3,4,5" unless (defined $vt);
	my $pt=$self->object_get_attribute($sample,"PROBEB_RANGE");
	$pt= "25,25,25,25" unless (defined $pt);
	
	my $avg=0;
	my @valus = split(',',$vt);
	my @probs = split(',',$pt);
	my $i=0;
	my $sum=0;
	my $min=10000000;
	my $max=0;
	foreach my $v (@valus) { 
		return ("-","The $v is not numeric value") unless (is_integer($v));
		$sum+=	$probs[$i];
		$avg+=$v*$probs[$i];
		$i++;	
		$min=$v if($min>$v);
		$max=$v if($max<$v);
	}
	return ("-","The summation of probebilities are $sum which is not equal 100.") if($sum!=100);
	$avg/=100;
	
	$self->object_add_attribute ($sample,"MIN_PCK_SIZE",$min);
	$self->object_add_attribute ($sample,"MAX_PCK_SIZE",$max);
	return ($avg,undef); 
}

sub get_simulator_noc_configuration{
	my ($self,$mode,$sample,$set_win) =@_;	
		
	my $table=def_table(10,2,FALSE);	
	my $row=0;
	
	
	my $scrolled_win = add_widget_to_scrolled_win ($table,gen_scr_win_with_adjst($self,'noc_conf_scr_win'));
		
	my $ok = def_image_button('icons/select.png','_OK',FALSE,1);
	my $import   = def_image_button('icons/import.png','I_mport',FALSE,1);
	my $save   = def_image_button('icons/save.png','_Export',FALSE,1);
	
	$save ->signal_connect("clicked"=> sub{
		my $dialog=save_file_dialog  ("Enter configuration file name",'conf');
		#$dialog->set_current_folder ($open_in) if(defined  $open_in);
		if ( "ok" eq $dialog->run ) {
	   		my	$file = $dialog->get_filename;
	   		my ($name,$path,$suffix) = fileparse("$file",qr"\..[^.]*$");
			my $t=$self->object_get_attribute($sample);
			open(FILE,  ">$path/${name}.conf") || die "Can not open: $!";
			print FILE Data::Dumper->Dump([\$t],['config']);
			close FILE;
		}	
		$dialog->destroy();			
	});
	
	$import ->signal_connect("clicked"=> sub{
		my $dialog=save_file_dialog  ("Enter configuration file name",'conf');
		#$dialog->set_current_folder ($open_in) if(defined  $open_in);
		if ( "ok" eq $dialog->run ) {
	   		my	$file = $dialog->get_filename;
	   		my $pp= do $file ;		
		    my $status=1;
		    $status=0 if $@;
			message_dialog("Error reading: $@") if $@;
			if ($status==1){
				$self->object_add_attribute ("$sample",undef,$$pp);
				set_gui_status($self,'ref_set_win',1);
			}
		}
		$dialog->destroy();		
	});
	
	
	
	my $mtable = def_table(10, 3, TRUE);

	$mtable->attach_defaults($scrolled_win,0,3,0,9);
	$mtable-> attach ($ok , 1, 2,  9, 10,'expand','shrink',2,2); 
	$mtable-> attach ($import , 0, 1,  9, 10,'expand','shrink',2,2); 
	$mtable-> attach ($save , 2, 3,  9, 10,'expand','shrink',2,2); 
	
	

	$set_win ->signal_connect (destroy => sub{		
		$self->object_add_attribute("active_setting",undef,undef);
		
	});	
		
	
	my $dir = Cwd::getcwd();
	my $open_in	  = abs_path("$ENV{PRONOC_WORK}/simulate");	
	
	
	attach_widget_to_table ($table,$row,gen_label_in_left(" Search Path:"),gen_button_message ("Select the Path where the verilator simulation files are located. Different NoC verilated models can be generated using Generate NoC configuration tab.","icons/help.png"), 
	get_dir_in_object ($self,$sample,"sof_path",undef,'ref_set_win',1,$open_in)); $row++;
	
	$open_in	= $self->object_get_attribute($sample,"sof_path");	
	
	
	
	my @files = glob "$open_in/*";
	my $exe_files="";
	foreach my $file (@files){
		my ($name,$path,$suffix) = fileparse("$file",qr"\..[^.]*$");
		if($suffix eq '.inf'){
			$exe_files="$exe_files,$name";
		}		
	}
	my $model_obj = gen_combobox_object ($self,$sample, "sof_file", $exe_files, undef,'ref_set_win',1);	
	attach_widget_to_table ($table,$row,gen_label_in_left(" Verilated Model:"),gen_button_message ("Select the verilator simulation file. Different NoC simulators can be generated using Generate NoC configuration tab.","icons/help.png"), 
	$model_obj); $row++;
      
    my $cast_type=  '"UNICAST"';
      
    #get simulation parameters here                        
  	my $s=$self->object_get_attribute($sample,"sof_file");
  	if (defined $s){
  		my ($infobox,$info)= create_txview();
  		my $sof=get_sim_bin_path($self,$sample,$info);  		
  		my ($name,$path,$suffix) = fileparse("$sof",qr"\..[^.]*$");
		my $sof_info= "$path$name.inf";
  		
  		my $pp= do $sof_info ;
		my $p=$pp->{'noc_param'};
  		$cast_type = $p->{'CAST_TYPE'};  
  		$cast_type=  '"UNICAST"' if (!defined $cast_type);
  	}
  
   my $trf_info = "Select of the following traffic models:
   1- Synthetic
   2- Task-graph :  
       The task graph traffic pattern can be generated
       using ProNoC trace generator	
   3- Netrace: 
       Dependency-Tracking Trace-Based Network-on-Chip
       Simulation. For downloading the trace files and more 
       information refere to https://www.cs.utexas.edu/~netrace/
   4- SynFull: 
       Synthetic Traffic Models Capturing a Full Range
       of Cache Coherent Behaviour
       https://github.com/mariobadr/synfull-isca   
"; 
   
    my $coltmp=0;
    ($row,$coltmp)=add_param_widget  ($self, "Traffic Type", "TRAFFIC_TYPE", "Synthetic", 'Combo-box', "Synthetic,Task-graph,SynFull,Netrace", $trf_info, $table,$row,undef,1, $sample, 1,'ref_set_win');
    
    my $traffictype=$self->object_get_attribute($sample,"TRAFFIC_TYPE");
    my $MIN_PCK_SIZE=$self->object_get_attribute($sample,"MIN_PCK_SIZE");
    
   
    
   my $max_pck_num = get_MAX_PCK_NUM();
   my $max_sim_clk = get_MAX_SIM_CLKs();
   
   my $pck_info = "Select how injected packet size are selected. 
		random-range:    The injected packet size is randomly selected between given minimum and maximum packet size. 
		random-discrete: The injected packet size is randomly selected among given district valuse.";
	
	if($traffictype eq "Synthetic"){
		
		my $min=$self->object_get_attribute($sample,'MIN_PCK_SIZE');
		my $max=$self->object_get_attribute($sample,'MAX_PCK_SIZE');
		$min=5 if(!defined $min);
		$max=5 if(!defined $max);
		$max= $min if($max< $min);
		my $avg=floor(($min+$max)/2);	
		my $msg;
		my $max_pck_size =	 get_MAX_PCK_SIZ();
		
		my $NE;
		my ($infobox,$info)= create_txview();
		
		
		my $traffics="tornado,transposed 1,transposed 2,bit reverse,bit complement,random,hot spot,shuffle,bit rotation,neighbor,custom"; 	
		my @synthinfo = (
		
		
		{ label=>'Configuration name:', param_name=>'line_name', type=>'Entry', default_val=>$sample, content=>undef, info=>"NoC configuration name. This name will be shown in load-latency graph for this configuration", param_parent=>$sample, ref_delay=> undef, new_status=>undef},
	
		
		
		{ label=>"Total packet number limit:", param_name=>'PCK_NUM_LIMIT', type=>'Spin-button', default_val=>200000, content=>"2,$max_pck_num,1", info=>"Simulation will stop when total number of sent packets by all nodes reaches packet number limit  or total simulation clock reach its limit", param_parent=>$sample, ref_delay=>undef, new_status=>undef},
	
		{ label=>"Simulator clocks limit:", param_name=>'SIM_CLOCK_LIMIT', type=>'Spin-button', default_val=>100000, content=>"2,$max_sim_clk,1", info=>"Each node stops sending packets when it reaches packet number limit  or simulation clock number limit", param_parent=>$sample, ref_delay=>undef,  new_status=>undef},
		
		{ label=>"Traffic name", param_name=>'traffic', type=>'Combo-box', default_val=>'random', content=>$traffics, info=>"Select traffic pattern", param_parent=>$sample, ref_delay=>1, new_status=>'ref_set_win'},
	
		{ label=>"Packet size (#flit)", param_name=>'PCK_SIZ_SEL', type=>'Combo-box', default_val=>'random-range', content=>"random-range,random-discrete", info=>$pck_info, param_parent=>$sample, ref_delay=>1, new_status=>'ref_set_win'},
	
		);
		my $coltmp=0;
		
		foreach my $d (@synthinfo) {
			
			($row,$coltmp)=add_param_widget ($self, $d->{label}, $d->{param_name}, $d->{default_val}, $d->{type}, $d->{content}, $d->{info}, $table,$row,undef,1, $d->{param_parent}, $d->{ref_delay}, $d->{new_status});
			
		}
		
		my $t=$self->object_get_attribute($sample,"PCK_SIZ_SEL");
		if($t eq 'random-range' ){
			
			@synthinfo = (	
			{ label=>"Min pck size :", param_name=>'MIN_PCK_SIZE', type=>'Spin-button', default_val=>5, content=>"1,$max,1", info=>"Minimum packet size in flit. The injected packet size is randomly selected between minimum and maximum packet size", param_parent=>$sample, ref_delay=>10, new_status=>'ref_set_win'},
			{ label=>"Max pck size :", param_name=>'MAX_PCK_SIZE', type=>'Spin-button', default_val=>5, content=>"$min,$max_pck_size,1", info=>"Maximum packet size in flit. The injected packet size is randomly selected between minimum and maximum packet size", param_parent=>$sample, ref_delay=>10, new_status=>'ref_set_win'},
			{ label=>"Avg. Packet size:", param_name=>'PCK_SIZE', type=>'Fixed', default_val=>$avg, content=>"$avg", info=>undef, param_parent=>$sample, ref_delay=>undef},
			);
			
		}else{
			#$self->object_add_attribute ($sample,"MIN_PCK_SIZE",2);#will be updated by get_district_avg  
			my $vt=$self->object_get_attribute($sample,"DISCRETE_RANGE");
			$vt =  "2,3,4,5" unless (defined $vt);
			my $pt=$self->object_get_attribute($sample,"PROBEB_RANGE");
			$pt= "25,25,25,25" unless (defined $pt);
			
			#($avg,$msg) = get_district_avg($self,$sample);
			
			 
			@synthinfo = (	
			{ label=>"pck size discrete range: ", param_name=>'DISCRETE_RANGE', type=>'Entry', default_val=>$vt, content=>undef, info=>"Set discrete set of number as packet size separated by \",\" (v1,v2,v3 ..). The injected packet size is randomly selected among these discrete values", param_parent=>$sample, ref_delay=>10, new_status=>'ref_set_win'},
		    { label=>"pck size probebility(%): ", param_name=>'PROBEB_RANGE'  , type=>'Entry', default_val=>$pt, content=>undef, info=>"Set the probability  separated by \",\" (p1,p2,p3 ..). The probabilities pi must satisfy two requirements: every probability pi is a number between 0 and 100, and the sum of all the probabilities is 100.", param_parent=>$sample, ref_delay=>10, new_status=>'ref_set_win'},
		   # { label=>"Avg. Packet size:", param_name=>'PCK_SIZE', type=>'Fixed', default_val=>$avg, content=>"$avg", info=>undef, param_parent=>$sample, ref_delay=>undef}, 
			);	
			
			
		}	
		
		foreach my $d (@synthinfo){
		 	($row,$coltmp)=add_param_widget ($self, $d->{label}, $d->{param_name}, $d->{default_val}, $d->{type}, $d->{content}, $d->{info}, $table,$row,undef,1, $d->{param_parent}, $d->{ref_delay}, $d->{new_status});
		}
		if(defined $msg){
				my $error= def_image_button("icons/cancel.png");
				$table->attach  ($error , 6, 7,  $row-1,$row,'shrink','shrink',2,2); 
		}	
			
	
		my $traffic=$self->object_get_attribute($sample,"traffic");
		
		my $st =  check_sim_sample($self,$sample,$info);  
		if ($st==0){
				$NE=100;
		}else{
			my ($topology, $T1, $T2, $T3, $V, $Fpay) = get_sample_emulation_param($self,$sample);
			my ($NEe, $NR, $RAw, $EAw, $Fw) = get_topology_info_sub ($topology, $T1, $T2, $T3, $V, $Fpay);
			$NE=$NEe;				
		}
			
		
		if ($traffic eq 'custom'){
						
			
			my $htable=def_table(10,2,FALSE);
			
			my $d= { label=>'number of active nodes:', param_name=>'CUSTOM_SRC_NUM', type=>'Spin-button', default_val=>1,  content=>"1,$NE,1", info=>"Number of active nodes which injects packets to the NoC",			  param_parent=>$sample, ref_delay=> 1, new_status=>'ref_set_win'};
			($row,$coltmp)=add_param_widget ($self, $d->{label}, $d->{param_name}, $d->{default_val}, $d->{type}, $d->{content}, $d->{info}, $table,$row,undef,1, $d->{param_parent}, $d->{ref_delay}, $d->{new_status});
			my $num=$self->object_get_attribute($sample,"CUSTOM_SRC_NUM");
			$htable->attach ( gen_label_in_left ("Source "), 0, 1,  $row,$row+1,'fill','shrink',2,2);
			$htable->attach ( gen_label_in_left (" -> "), 1, 2,  $row,$row+1,'fill','shrink',2,2);
			$htable->attach ( gen_label_in_left ("Destination"), 2, 3,  $row,$row+1,'fill','shrink',2,2);						
			
			$row++;
			
			
			my $tiles="0";
			for (my $i=1;$i<$NE;$i++){$tiles.=",$i";}
			
						
			for (my $i=0;$i<$num;$i++){
				my $w1 = gen_combobox_object ($self,$sample,"SRC_$i",$tiles, $i,undef,undef);
				my $w2 = gen_combobox_object ($self,$sample,"DST_$i",$tiles, $i+1,undef,undef);
				$htable->attach  ($w1 , 0, 1,  $row,$row+1,'shrink','shrink',2,2);
				$htable->attach  ($w2 , 2, 3,  $row,$row+1,'shrink','shrink',2,2);
				$row++;
					
			}	
			$table->attach  ($htable , 0, 3,  $row,$row+1,'shrink','shrink',2,2); $row++;
				
		}
		
		
		if ($cast_type ne '"UNICAST"'){	
			my $min=$self->object_get_attribute($sample,'MCAST_PCK_SIZ_MIN');
			my $max=$self->object_get_attribute($sample,'MCAST_PCK_SIZ_MAX');
			$min=5 if(!defined $min);
			$max=5 if(!defined $max);
			$max= $min if($max< $min);
		
				
			my $s = ($cast_type eq '"BROADCAST_FULL"' || $cast_type eq '"BROADCAST_PARTIAL"')? "Broadcast" :  "Milticast";
			my $info1= "Define the percentage ratio of $s traffic towards Unicast traffic";
			my $info2= "Define how destinations is selected in Multicast packets";
			($row,$coltmp)=add_param_widget  ($self, "$s Node Select"  , "MCAST_TRAFFIC_TYPE" , "Uniform-Random",  'Combo-box', "Uniform-Random", $info1, $table,$row,undef,1, $sample);
			($row,$coltmp)=add_param_widget  ($self, "$s Traffic Ratio", "MCAST_TRAFFIC_RATIO", 5 , 'Spin-button',  "0,100,1"  , $info2, $table,$row,undef,1, $sample);	
			
			($row,$coltmp)=add_param_widget  ($self, "$s min pck size", "MCAST_PCK_SIZ_MIN", 5 , 'Spin-button',  "1,$max,1"  , $info2, $table,$row,undef,1, $sample,1,'ref_set_win');	
			
			($row,$coltmp)=add_param_widget  ($self, "$s max pck size", "MCAST_PCK_SIZ_MAX", 5 , 'Spin-button',  "$min,100,1"  , $info2, $table,$row,undef,1, $sample,1,'ref_set_win');	
			
			
						
		}
		
		
		
		
		my $d= { label=>'number of message class:', param_name=>'MESSAGE_CLASS', type=>'Spin-button', default_val=>0,  content=>"0,256,1", info=>"Number of packet message classes. Each message class can be configured to use specefic subset of avilable VCs",			  param_parent=>$sample, ref_delay=> 1, new_status=>'ref_set_win'};
		($row,$coltmp)=add_param_widget ($self, $d->{label}, $d->{param_name}, $d->{default_val}, $d->{type}, $d->{content}, $d->{info}, $table,$row,undef,1, $d->{param_parent}, $d->{ref_delay}, $d->{new_status});
		my $num=$self->object_get_attribute($sample,"MESSAGE_CLASS");
		if($num>0){
			my $htable=def_table(10,2,FALSE);
			$htable->attach ( gen_label_in_left ("Class num "), 0, 1,  $row,$row+1,'fill','shrink',2,2);
			$htable->attach ( gen_label_in_left (" - "), 1, 2,  $row,$row+1,'fill','shrink',2,2);
			$htable->attach ( gen_label_in_left ("Traffic(%)"), 2, 3,  $row,$row+1,'fill','shrink',2,2);						
			$row++;
			
			for (my $i=0;$i<$num;$i++){	
				$htable->attach ( gen_label_in_left ("$i"), 0, 1,  $row,$row+1,'fill','shrink',2,2);
				my $w1 = gen_spin_object ($self,$sample,"CLASS_$i","0,100,1", 100/$num,undef,undef);
				$htable->attach ( $w1, 2, 3,  $row,$row+1,'fill','shrink',2,2);
				$row++;
			}
			$table->attach  ($htable , 0, 3,  $row,$row+1,'shrink','shrink',2,2); $row++;
		}
		
		

		if ($traffic eq 'hot spot'){
			my $htable=def_table(10,2,FALSE);
			
			my $d= { label=>'number of Hot Spot nodes:', param_name=>'HOTSPOT_NUM', type=>'Spin-button', default_val=>1,  content=>"1,256,1", info=>"Number of hot spot nodes in the network",			  param_parent=>$sample, ref_delay=> 1, new_status=>'ref_set_win'};
			($row,$coltmp)=add_param_widget ($self, $d->{label}, $d->{param_name}, $d->{default_val}, $d->{type}, $d->{content}, $d->{info}, $table,$row,undef,1, $d->{param_parent}, $d->{ref_delay}, $d->{new_status});
				
				my $l1=gen_label_help("Define the tile number which is  hotspt. All other nodes will send [Hot Spot traffic percentage] of their traffic to this node","  Hot Spot tile number \%");
				my $l2=gen_label_help("If it is set as \"n\" then each node sends n % of its traffic to each hotspot node","  Hot Spot traffic \%");
				my $l3=gen_label_help("If it is checked then hot spot node also sends packets to other nodes otherwise it only receives packets from other nodes","  send enable");
				
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
		my $l= "Define injection ratios. You can define individual ratios separating by comma (\',\') or define a range of injection ratios with \$min:\$max:\$step format.
			As an example defining 2,3,4:10:2 will result in (2,3,4,6,8,10) injection ratios." ;
		my $u=get_injection_ratios ($self,$sample,"ratios");
		
		attach_widget_to_table ($table,$row,gen_label_in_left(" Injection ratios:"),gen_button_message ($l,"icons/help.png") , $u); $row++;
	
		$ok->signal_connect("clicked"=> sub{
			#check if sof file has been selected
			my $s=$self->object_get_attribute($sample,"sof_file");
			#check if injection ratios are valid
			my $r=$self->object_get_attribute($sample,"ratios");
			
			my $h;
			
			my $t=$self->object_get_attribute($sample,"PCK_SIZ_SEL");
			unless ($t eq 'random-range' ){
				($avg,$msg) = get_district_avg($self,$sample);	
				if(defined $msg){ 
	 			message_dialog($msg);  
	 			return;
				}
			}	
			
			if ($traffic eq 'hot spot'){
				$h=	check_hotspot_parameters($self,$sample);
			}
			
			my $v;
			if(defined $r ){
					$v=check_inserted_ratios($r);
			}
			
			if(defined $s && defined $r && defined $v && !defined $h) {	
					#$set_win->destroy;
					$set_win->hide();
					$self->object_add_attribute("active_setting",undef,undef);
					set_gui_status($self,"ref",1);
			} else {
				
				if(!defined $s){
					my $m= "Please select NoC verilated file";
					message_dialog($m);  
				} elsif (! defined $r) {
					 message_dialog("Please define valid injection ratio(s)!");
				} elsif (defined $h){
					 message_dialog("$h");					
				}
			}
		});
	
	}	
	
	
	if($traffictype eq "Task-graph"){
		
		my @custominfo = (
		#{ label=>"Verilated Model", param_name=>'sof_file', type=>'Combo-box', default_val=>undef, content=>$exe_files, info=>"Select the verilator simulation file. Different NoC simulators can be generated using Generate NoC configuration tab.", param_parent=>$sample, ref_delay=>undef, new_status=>undef},
		
		{ label=>'Configuration name:', param_name=>'line_name', type=>'Entry', default_val=>$sample, content=>undef, info=>"NoC configuration name. This name will be shown in load-latency graph for this configuration", param_parent=>$sample, ref_delay=> undef, new_status=>undef},
	
	  	{ label=>"Number of Files", param_name=>"TRAFFIC_FILE_NUM", type=>'Spin-button', default_val=>1, content=>"1,100,1", info=>"Select number of input files", param_parent=>$sample, ref_delay=>1, new_status=>'ref_set_win'},
		
		{ label=>"Simulator clocks limit:", param_name=>'SIM_CLOCK_LIMIT', type=>'Spin-button', default_val=>100000, content=>"2,$max_sim_clk,1", info=>"Each node stops sending packets when it reaches packet number limit  or simulation clock number limit", param_parent=>$sample, ref_delay=>undef,  new_status=>undef},
		);
		
		foreach my $d (@custominfo) {
			($row,$coltmp)=add_param_widget ($self, $d->{label}, $d->{param_name}, $d->{default_val}, $d->{type}, $d->{content}, $d->{info}, $table,$row,undef,1, $d->{param_parent}, $d->{ref_delay}, $d->{new_status});
			
		}	
		
	
		my $open_in  = "$ENV{'PRONOC_WORK'}/traffic_pattern";
		
		
	
		 my $num=$self->object_get_attribute($sample,"TRAFFIC_FILE_NUM");
		 for (my $i=0; $i<$num; $i++){
		 	attach_widget_to_table ($table,$row,gen_label_in_left("traffic pattern file $i:"),gen_button_message ("Select the traffic pattern input file. Any custom traffic based on application task graphs can be generated using ProNoC Trace Generator tool.","icons/help.png"), get_file_name_object ($self,$sample,"traffic_file$i",undef,$open_in)); $row++;
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
			#$set_win->destroy;
			$set_win->hide();
			$self->object_add_attribute("active_setting",undef,undef);
			set_gui_status($self,"ref",1);
				
		});
		 
		 
	}
	
	
	if($traffictype eq "SynFull"){
		#get the synful model names
		my $models_dir  = get_project_dir()."/mpsoc/src_c/synfull/generated-models/";		
		my ($flist)=get_file_list_by_extention ("$models_dir",".model");
	
		
		my $model_obj = gen_combobox_object ($self,$sample, "MODEL_NAME", $flist, undef,undef,undef);	
		attach_widget_to_table ($table,$row,gen_label_in_left(" Traffic Model name:"),gen_button_message ("Select an application traffic model.","icons/help.png"), 
		$model_obj); $row++;
		
		
		
		my @custominfo = (
		{ label=>"Synful Flit-size:(Bytes)", param_name=>'SYNFUL_FLITw', type=>'Spin-button', default_val=>4, content=>"4,72,4", info=>"The synful flit size in Byte. It defines the number of flits that should be set to ProNoC for each synful packets. The ProNoC packet size is : 
		\t Ceil( synful packet size/synful flit size).  ", param_parent=>$sample, ref_delay=>undef,  new_status=>undef},
		{ label=>'Configuration name:', param_name=>'line_name', type=>'Entry', default_val=>$sample, content=>undef, info=>"NoC configuration name. This name will be shown in load-latency graph for this configuration", param_parent=>$sample, ref_delay=> undef, new_status=>undef},
	    { label=>"Total packet number limit:", param_name=>'PCK_NUM_LIMIT', type=>'Spin-button', default_val=>200000, content=>"2,$max_pck_num,1", info=>"Simulation will stop when total number of sent packets by all nodes reaches packet number limit  or total simulation clock reach its limit", param_parent=>$sample, ref_delay=>undef, new_status=>undef},
		{ label=>"Simulator clocks limit:", param_name=>'SIM_CLOCK_LIMIT', type=>'Spin-button', default_val=>100000, content=>"2,$max_sim_clk,1", info=>"Each node stops sending packets when it reaches packet number limit  or simulation clock number limit", param_parent=>$sample, ref_delay=>undef,  new_status=>undef},
		{ label=>"Markov Chain Random seed:", param_name=>'RND_SEED', type=>'Spin-button', default_val=>53432145, content=>"0,999999999,1", info=>"The seed valus is passe to synfull random number generator.", param_parent=>$sample, ref_delay=>undef,  new_status=>undef},
		{ label=>"Exit at steady state:", param_name=>'EXIT_STEADY', type=>'Check-box', default_val=>0, content=>"1", info=>"Exit the simulation when it reaches to a steady state.", param_parent=>$sample, ref_delay=>undef,  new_status=>undef},
		
	
	
		);
		
		
		
		foreach my $d (@custominfo) {
			($row,$coltmp)=add_param_widget ($self, $d->{label}, $d->{param_name}, $d->{default_val}, $d->{type}, $d->{content}, $d->{info}, $table,$row,undef,1, $d->{param_parent}, $d->{ref_delay}, $d->{new_status});
			
		}	
		
		$ok->signal_connect("clicked"=> sub{
			#check if sof file has been selected
			my $s=$self->object_get_attribute($sample,"MODEL_NAME");
			if(!defined $s){
					message_dialog("Please select a SynFull traffic model"); 
					return;
			}
						
			
			#$set_win->destroy;
			$set_win->hide();
			$self->object_add_attribute("active_setting",undef,undef);
			set_gui_status($self,"ref",1);
				
		});
		
		
		
	}#SynFull
	
	
	if($traffictype eq "Netrace"){
		#get the synful model names
		my $models_dir  = "$ENV{PRONOC_WORK}/simulate/netrace";		
		my ($flist)=get_file_list_by_extention ("$models_dir",".bz2");
	
		my $model_obj = gen_combobox_object ($self,$sample, "MODEL_NAME", $flist, undef,undef,undef);	
		my $download=def_image_button("icons/download.png",'Download');	
		my $box =def_hbox(FALSE, 0);
		$box->pack_start( $model_obj , 1,1, 0);
		$box->pack_start( $download, 0, 1, 3);
				
		attach_widget_to_table ($table,$row,gen_label_in_left(" Trace name:"),gen_button_message ("Select a netrace trace file. You can download traces using download button.","icons/help.png"), 
		$box); 
		
		
		$row++;
		
		
		
		my @custominfo = (
		{ label=>'Configuration name:', param_name=>'line_name', type=>'Entry', default_val=>$sample, content=>undef, info=>"NoC configuration name. This name will be shown in load-latency graph for this configuration", param_parent=>$sample, ref_delay=> undef, new_status=>undef},
	    { label=>"Total packet number limit:", param_name=>'PCK_NUM_LIMIT', type=>'Spin-button', default_val=>200000, content=>"2,$max_pck_num,1", info=>"Simulation will stop when total number of sent packets by all nodes reaches packet number limit  or total simulation clock reach its limit", param_parent=>$sample, ref_delay=>undef, new_status=>undef},
		#{ label=>"Simulator clocks limit:", param_name=>'SIM_CLOCK_LIMIT', type=>'Spin-button', default_val=>100000, content=>"2,$max_sim_clk,1", info=>"Each node stops sending packets when it reaches packet number limit  or simulation clock number limit", param_parent=>$sample, ref_delay=>undef,  new_status=>undef},
		{ label=>"ignore dependencies:", param_name=>'IGNORE_DPNDCY', type=>'Check-box', default_val=>0, content=>"1", info=>"Ignore dependency between packets", param_parent=>$sample, ref_delay=>undef,  new_status=>undef},
		{ label=>"Enable reader throttling:", param_name=>'READER_THRL', type=>'Check-box', default_val=>0, content=>"1", info=>"If Reader throttling is enabled, simulators offloads much of the work of reading and tracking packets to the Netrace reader,
which simplifies the code in the network simulator.", param_parent=>$sample, ref_delay=>undef,  new_status=>undef},
		{ label=>"trace file start region:", param_name=>'START_RGN', type=>'Spin-button', default_val=>0, content=>"0,10000,1", info=>undef, param_parent=>$sample, ref_delay=>undef,  new_status=>undef},
		{ label=>"Netrace to Pronoc clk ratio:", param_name=>'SPEED_UP', type=>'Spin-button', default_val=>1, content=>"1,99,1", info=>"The ratio of netrace frequency to pronoc.The higher value results in higher injection ratio to the NoC. Default is one\n", param_parent=>$sample, ref_delay=>undef,  new_status=>undef},
		
		
		
		
	
	
		);
		
		
		
		foreach my $d (@custominfo) {
			($row,$coltmp)=add_param_widget ($self, $d->{label}, $d->{param_name}, $d->{default_val}, $d->{type}, $d->{content}, $d->{info}, $table,$row,undef,1, $d->{param_parent}, $d->{ref_delay}, $d->{new_status});
			
		}	
		
		$ok->signal_connect("clicked"=> sub{
			#check if sof file has been selected
			my $s=$self->object_get_attribute($sample,"MODEL_NAME");
			if(!defined $s){
					message_dialog("Please select a SynFull traffic model"); 
					return;
			}
						
			
			#$set_win->destroy;
			$set_win->hide();
			$self->object_add_attribute("active_setting",undef,undef);
			set_gui_status($self,"ref",1);
				
		});
		
		$download->signal_connect("clicked"=> sub{ download_netrace("$models_dir")	});


		
	}#netrace
	
	
	
	
	
	
	add_widget_to_scrolled_win ($mtable,$set_win);
	
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
		if($traffictype eq "Synthetic") {run_synthetic_simulation($simulate,$info,$sample,$name);} 
		elsif($traffictype eq "Task-graph"){run_task_simulation($simulate,$info,$sample,$name) ;}
		else {run_trace_simulation($simulate,$info,$sample,$name);}
    	
	}
	
	add_info($info, "Simulation is done!\n");
	printf "Simulation is done!\n";
	$simulate->object_add_attribute('status',undef,'ideal');
	set_gui_status($simulate,"ref",1);
}	


sub run_synthetic_simulation {
	my ($simulate,$info,$sample,$name)=@_;
	

	my %traffic= (
	'tornado' => 'TORNADO',
	'transposed 1' => "TRANSPOSE1",
	'transposed 2' => "TRANSPOSE2",
	'bit reverse'  => "BIT_REVERSE",
	'bit complement' => "BIT_COMPLEMENT",
	'random' => "RANDOM",
	'hot spot' => "HOTSPOT",
	'shuffle' => "SHUFFLE",
	'bit rotation' => "BIT_ROTATE",
	'neighbor' => "NEIGHBOR",
	'custom' => "CUSTOM"	 
	);
	
	my $simulator =$simulate->object_get_attribute("Simulator");
	my $log= (defined $name)? "$ENV{PRONOC_WORK}/simulate/$name.log": "$ENV{PRONOC_WORK}/simulate/sim.log";
	my $out_path ="$ENV{PRONOC_WORK}/simulate/"; 
	my $r= $simulate->object_get_attribute($sample,"ratios");
	my @ratios=@{check_inserted_ratios($r)};
	#$emulate->object_add_attribute ("sample$i","status","run");
	my $bin=get_sim_bin_path($simulate,$sample,$info);
	
	#load traffic configuration
	my $patern=$simulate->object_get_attribute ($sample,'traffic');	
	my $PCK_NUM_LIMIT=$simulate->object_get_attribute ($sample,"PCK_NUM_LIMIT");
	my $SIM_CLOCK_LIMIT=$simulate->object_get_attribute ($sample,"SIM_CLOCK_LIMIT");
	my $MIN_PCK_SIZE=$simulate->object_get_attribute ($sample,"MIN_PCK_SIZE");
	my $MAX_PCK_SIZE=$simulate->object_get_attribute ($sample,"MAX_PCK_SIZE");
	
	
	#hotspot 
	my $custom="";
	my $custom_sv="";
	if ($patern eq 'custom'){
		$custom="";
		my $num=$simulate->object_get_attribute($sample,"CUSTOM_SRC_NUM");
		$custom_sv.="localparam CUSTOM_NODE_NUM=$num;\n\twire [NEw-1 : 0] custom_traffic_t   [NE-1 : 0];\n\twire [NE-1 : 0] custom_traffic_en;\n";
			my @srcs;
		for (my $i=0;$i<$num; $i++){
			my $src = $simulate->object_get_attribute($sample,"SRC_$i");
			my $dst = $simulate->object_get_attribute($sample,"DST_$i");
			
			$custom.=($i==0)? "-H \"$src,$dst" : ",$src,$dst";
			
		}
		my ($topology, $T1, $T2, $T3, $V, $Fpay) = get_sample_emulation_param($simulate,$sample);
		my ($NE, $NR, $RAw, $EAw, $Fw) = get_topology_info_sub ($topology, $T1, $T2, $T3, $V, $Fpay);
			
		for (my $i=0;$i<$NE; $i++){
			my ($src,$dst) = custom_traffic_dest ($simulate,$sample,$i);
			$custom_sv.="\tassign custom_traffic_t[$src]=$dst;\n";
			$custom_sv.="\tassign custom_traffic_en[$src]=";
			$custom_sv.=($dst==-1)? "1'b0;//off \n" : "1'b1;\n"
		}	
		$custom.="\"";	
		
	}
	else{
		$custom_sv.="localparam CUSTOM_NODE_NUM=0;\n\twire [NEw-1 : 0] custom_traffic_t   [NE-1 : 0];\n\twire [NE-1 : 0] custom_traffic_en;
		";		
	}
	#multicast
	my $mcast="";
	my $mcast_sv="";
	my $p= $simulate->object_get_attribute ($sample,"noc_info");    
    my $cast_type=$p->{"CAST_TYPE"};
	if ($cast_type ne '"UNICAST"'){	
		#$self->object_get_attribute ($sample,  "MCAST_TRAFFIC_TYPE");
		my $mr   = $simulate->object_get_attribute  ($sample,  "MCAST_TRAFFIC_RATIO");
		my $mmax = $simulate->object_get_attribute  ($sample,  "MCAST_PCK_SIZ_MAX");
		my $mmin = $simulate->object_get_attribute  ($sample,  "MCAST_PCK_SIZ_MIN");
		
		$mcast = "-u \"$mr,$mmin,$mmax\"";
		$mcast_sv.= "localparam	MCAST_TRAFFIC_RATIO =	$mr;\n";
		$mcast_sv.= "localparam	MCAST_PCK_SIZ_MAX =	$mmax;\n";
		$mcast_sv.= "localparam	MCAST_PCK_SIZ_MIN =	$mmin;\n";	
	}else {
		$mcast_sv.= "localparam	MCAST_TRAFFIC_RATIO =	0;\n";	
		$mcast_sv.= "localparam	MCAST_PCK_SIZ_MAX =	0;\n";
		$mcast_sv.= "localparam	MCAST_PCK_SIZ_MIN =	0;\n";	
	}
	
	
	
	
	
	my $classes;
	my $num=$simulate->object_get_attribute($sample,"MESSAGE_CLASS");
	$classes.="-p 100" if($num==0);
	for (my $i=0;$i<$num;$i++){
		my $w1 = $simulate->object_get_attribute($sample,"CLASS_$i");
		$classes.= ($i==0)?  "-p $w1" : ",$w1" ;		
	
	}
	
	my $discrete_sv="";
	my $hotspot="";
	my $hotspot_sv="";
	if($patern eq "hot spot"){
		$hotspot="-h \" ";
		my $num=$simulate->object_get_attribute($sample,"HOTSPOT_NUM");
		if (defined $num){
			$hotspot.=" $num";
			
			$hotspot_sv.="localparam HOTSPOT_NODE_NUM=$num;\n\thotspot_t  hotspot_info [HOTSPOT_NODE_NUM-1 : 0];\n";
			my $acum=0;
			
			for (my $i=0;$i<$num;$i++){
				my $w1 = $simulate->object_get_attribute($sample,"HOTSPOT_CORE_$i");
				my $w2 = $simulate->object_get_attribute($sample,"HOTSPOT_PERCENT_$i");
				$w2=$w2*10;
				my $w3 = $simulate->object_get_attribute($sample,"HOTSPOT_SEND_EN_$i");
				$hotspot.=",$w1,$w3,$w2";
				$acum+=$w2;
				
				$hotspot_sv.="
	assign  hotspot_info[$i].ip_num=$w1;
	assign  hotspot_info[$i].send_enable=$w3;
	assign  hotspot_info[$i].percentage=$acum;	// $w2
";			}
			
		}
		
		$hotspot.=" \"";
				
	}
	else{ $hotspot_sv.="localparam HOTSPOT_NODE_NUM = 0;\n\thotspot_t  hotspot_info [0:0];\n" }		
	
	my $pck_size;
	my $t=$simulate->object_get_attribute($sample,"PCK_SIZ_SEL");
	if($t eq 'random-range' ){
		
		$pck_size = "-m \"R,$MIN_PCK_SIZE,$MAX_PCK_SIZE\"";
		$discrete_sv="\t localparam DISCRETE_PCK_SIZ_NUM=1;
\t rnd_discrete_t rnd_discrete [DISCRETE_PCK_SIZ_NUM-1:0];\n";
	
	}else{
		my $vt=$simulate->object_get_attribute($sample,"DISCRETE_RANGE");
		my $pt=$simulate->object_get_attribute($sample,"PROBEB_RANGE");
		$pck_size = "-m \"D,$vt,P,$pt\"";		
		my @injects = split(',',$vt);
		my @probs = split(',',$pt);
		my $i=0;
		my $sum=0;
		for my $v (@injects) {
			$sum+=$probs[$i];
			$discrete_sv.= "\t assign rnd_discrete[$i].value= $v;\n";
			$discrete_sv.= "\t assign rnd_discrete[$i].percentage= $sum;\n";
			$i++;
		}
		$discrete_sv="\t localparam DISCRETE_PCK_SIZ_NUM=$i;
\t rnd_discrete_t rnd_discrete [DISCRETE_PCK_SIZ_NUM-1: 0];\n".$discrete_sv;
	}
	
	my $modelsim_bin=  $ENV{MODELSIM_BIN};
	my $vsim = (! defined $modelsim_bin)? "vsim" : "$modelsim_bin/vsim";
	
	
			
		
	my $cpu_num = $simulate->object_get_attribute('compile', 'cpu_num');
	$cpu_num = 1 if (!defined $cpu_num);
	
	my $thread_num = $simulate->object_get_attribute('compile', 'thread_num');
	$thread_num = 1 if (!defined $thread_num);
	
	if ($simulator ne 'Verilator'){
		for (my $i=0; $i<$cpu_num; $i++  ){
			my $out="$out_path/modelsim/work$i";
			rmtree("$out");
			mkpath("$out",1,01777);
	my $vsim = ($simulator eq 'Modelsim')? "vsim -c": "vsim";					
			gen_noc_localparam_v_file($simulate,"$out",$sample);
			my $param="
// simulation parameter setting

`ifdef INCLUDE_SIM_PARAM
	localparam 
		TRAFFIC=\"$traffic{$patern}\",
		PCK_SIZ_SEL=\"$t\",	
	  	AVG_LATENCY_METRIC= \"HEAD_2_TAIL\",
		//simulation min and max packet size. The injected packet take a size randomly selected between min and max value
		MIN_PACKET_SIZE=$MIN_PCK_SIZE,
		MAX_PACKET_SIZE=$MAX_PCK_SIZE,
		STOP_PCK_NUM=$PCK_NUM_LIMIT,
		STOP_SIM_CLK=$SIM_CLOCK_LIMIT;
	
	    		
	$hotspot_sv	
		
	$custom_sv
	
	$mcast_sv
	
$discrete_sv
		
		parameter INJRATIO=90; 
`endif			
			";
			save_file("$out/sim_param.sv",$param);
			
			
			#Get the list of  all verilog files in src_verilog folder
			my @files = File::Find::Rule->file()
			->name( '*.v','*.V','*.sv' )
			->in( "$out_path/modelsim/src_verilog" );
		
			#get list of all verilog files in src_sim folder 
    		my @sim_files = File::Find::Rule->file()
			->name( '*.v','*.V','*.sv' )
			->in( "$out_path/modelsim/src_modelsim" );		
			push (@files, @sim_files);	
			my $tt =create_file_list("$out_path/modelsim",\@files,'modelsim');
			$tt="+incdir+./ \n$tt";	
			save_file("$out/file_list.f",  "$tt");
			my $tcl="#!/usr/bin/tclsh


transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work


vlog  +acc=rn  -F $out/file_list.f

$vsim -t 1ps  -L rtl_work -L work -voptargs=\"+acc\"  testbench_noc

add wave *
view structure
view signals
run -all
quit
";
	
			save_file ("$out/model.tcl",$tcl);
			
			my $cmd="cd $out; rm -Rf rtl_work; $vsim -do $out/model.tcl ";
			save_file ("$out/run.sh",'#!/bin/bash'."			
			sed -i \"s/ INJRATIO=\[\[:digit:\]\]\\+/ INJRATIO=\$1/\" $out/sim_param.sv
			".$cmd);			
			add_info($info, "model.tcl is created in $out\n");
		}#for		
	}
	
	
	
	my @paralel_ratio;
	my $total=scalar @ratios;
	my $jobs=0;	
	my $c=0;
	my $cmds="";
	
	
	foreach  my $ratio_in (@ratios){						
	    	#my $r= $ratio_in * MAX_RATIO/100;
	    	my $cmd;
	    	
	    	if ($simulator eq 'Modelsim'){
	    		add_info($info, "Run $bin with  injection ratio of $ratio_in \% \n");
	    		my $out="$out_path/modelsim/work$c";
	    		$cmd="	xterm -e bash -c '	cd $out; sed -i \"s/ INJRATIO=\[\[:digit:\]\]\\+/ INJRATIO=$ratio_in/\" $out/sim_param.sv; rm -Rf rtl_work; $vsim -c -do $out/model.tcl -l $out_path/sim_out$ratio_in;' &\n	";			
	    	
	    	}elsif ($simulator eq 'Modelsim gui'){
	    		add_info($info, "Run $bin with  injection ratio of $ratio_in \% \n");
	    		my $out="$out_path/modelsim/work$c";
	    		$cmd="cd $out; sed -i \"s/ INJRATIO=\[\[:digit:\]\]\\+/ INJRATIO=$ratio_in/\" $out/sim_param.sv;  rm -Rf rtl_work; $vsim -do $out/model.tcl -l $out_path/sim_out$ratio_in;	";			
	    	
	    	}else{	
	    		add_info($info, "Run $bin with  injection ratio of $ratio_in \% \n");
		    	$cmd="$bin -t \"$patern\" $pck_size -T $thread_num -n $PCK_NUM_LIMIT -c $SIM_CLOCK_LIMIT -i $ratio_in $classes $hotspot $custom $mcast > $out_path/sim_out$ratio_in & ";
							
	    	}
	    	$cmds .=$cmd;	
			add_info($info, "$cmd \n");
			
			my $time_strg = localtime;
			#append_text_to_file($log,"started at:$time_strg\n"); #save simulation output
			$jobs++;
			
			push (@paralel_ratio,$ratio_in);
			$c++;
			if($jobs % $cpu_num ==0 || $jobs == $total){
				
				#run paralle simulation				
					my ($stdout,$exit,$stderr)=run_cmd_in_back_ground_get_stdout("$cmds\n wait\n");
					if($exit || (length $stderr >4)){
							add_colored_info($info, "Error in running simulation: $stderr \n",'red');
							$simulate->object_add_attribute ($sample,"status","failed");	
							$simulate->object_add_attribute('status',undef,'ideal');
							return;
					 } 
				
				#save results
				for (my $i=0; $i<$c; $i++){
					my $r      = $paralel_ratio[$i];
					
					my @errors = unix_grep("$out_path/sim_out$r","ERROR:");
					if (scalar @errors  ){
						add_colored_info($info, "Error in running simulation: @errors \n",'red');
						$simulate->object_add_attribute ($sample,"status","failed");	
						$simulate->object_add_attribute('status',undef,'ideal');
						return;						
					}		
					
					
					my $stdout = load_file("$out_path/sim_out$r");
							
					extract_and_update_noc_sim_statistic ($simulate,$sample,$r,$stdout);
					    
		   
				} 
				
				$cmds="";
				@paralel_ratio=();
				$c=0;
				
				set_gui_status($simulate,"ref",2);
			}  	
	    		    	
		}#@ratios	
		
		$simulate->object_add_attribute ($sample,"status","done");	
	
}


sub extract_st_by_name{
	my($st_name, $stdout)=@_;
	
	my @results = split($st_name,$stdout);
	my %statistcs;
	my @lines = split("\n",$results[1]);	
	my @names;
	my $i=0;
	foreach my $line (@lines){
		$line=remove_all_white_spaces($line);
		$line =~ s/^#//g; #remove # from beginig of each line in modelsim 
		if($i==0) {
			$i++;
			next;
		}
		elsif($i==1){
			#first line is statsitic names
			@names=split(",",$line);
			$i++;
			next;
		}elsif(length($line)>1) {
			my @fileds=split(",",$line);
			my $j=0;
			#print ("ff :@fileds\n");
			foreach my $f (@fileds){				
				unless($j==0){
					$statistcs{$fileds[0]}{$names[$j]}=$f;	
				}
				$j++;
			}
			$i++;
		}else{ #empty line end of endp statistic
			last;
		}
		
	}
	#print Dumper(\%statistcs);
	return  %statistcs;	
}



sub extract_and_update_noc_sim_statistic {
	my ($simulate,$sample,$ratio_in,$stdout)=@_;
		
	
	
	my $total_time =capture_number_after("Simulation clock cycles:",$stdout);

	my %statistcs = extract_st_by_name("Endpoints Statistics:",$stdout);
			
	return if (!defined $statistcs{"total"}{'avg_latency_pck'});
	update_result($simulate,$sample,"latency_result",$ratio_in,$statistcs{"total"}{'avg_latency_pck'});
	update_result($simulate,$sample,"latency_flit_result",$ratio_in,$statistcs{"total"}{'avg_latency_flit'});
	update_result($simulate,$sample,"sd_latency_result",$ratio_in,$statistcs{"total"}{'avg.std_dev'});
	update_result($simulate,$sample,"throughput_result",$ratio_in,$statistcs{"total"}{'avg_throughput(%)'});
	update_result($simulate,$sample,"exe_time_result",$ratio_in,$total_time);
	update_result($simulate,$sample,"worst_latency_result",$ratio_in,$statistcs{"total"}{'sent_stat.worst_latency'});
	update_result($simulate,$sample,"latency_perhop_result",$ratio_in,$statistcs{"total"}{'avg_latency_per_hop'});
	update_result($simulate,$sample,"min_latency_result",,$ratio_in,$statistcs{"total"}{'sent_stat.min_latency'});
	update_result($simulate,$sample,"injected_pck_total",,$ratio_in,$statistcs{"total"}{'sent_stat.pck_num'});
	update_result($simulate,$sample,"injected_flit_total",,$ratio_in,$statistcs{"total"}{'sent_stat.flit_num'});
	foreach my $p (sort keys %statistcs){
		next unless (is_integer($p));
		update_result($simulate,$sample,"packet_rsvd_result",$ratio_in,$p,$statistcs{$p}{'rsvd_stat.pck_num'});
		update_result($simulate,$sample,"worst_delay_rsvd_result",$ratio_in,$p,$statistcs{$p}{'rsvd_stat.worst_latency'});
		update_result($simulate,$sample,"packet_sent_result",$ratio_in,$p,$statistcs{$p}{'sent_stat.pck_num'} );
		update_result($simulate,$sample,"worst_delay_sent_result",$ratio_in,$p,$statistcs{$p}{'sent_stat.worst_latency'});
		update_result($simulate,$sample,"flit_rsvd_result",$ratio_in,$p,$statistcs{$p}{'rsvd_stat.flit_num'});
		update_result($simulate,$sample,"flit_sent_result",$ratio_in,$p,$statistcs{$p}{'sent_stat.flit_num'});
	}	
	
	my %st1 = extract_st_by_name("Endp_to_Endp flit_num:",$stdout);
	update_result($simulate,$sample,"endp-endp-flit_result",$ratio_in,\%st1);
	
	my %st2 = extract_st_by_name("Endp_to_Endp pck_num:",$stdout);
	update_result($simulate,$sample,"endp-endp-pck_result",$ratio_in,\%st2);
	
	my %st3 = extract_st_by_name("Routers' statistics:",$stdout);
	foreach my $p (sort keys %st3){
		update_result($simulate,$sample,"flit_per_router_result",$ratio_in,$p,$st3{$p}{'flit_in'});
		update_result($simulate,$sample,"packet_per_router_result",$ratio_in,$p,$st3{$p}{'pck_in'});
		my $tmp= ($st3{$p}{'flit_in'}==0)? 0 : ($st3{$p}{'flit_in_buffered'}*100) / $st3{$p}{'flit_in'};
		#print " $tmp= ($st3{$p}{'flit_in_buffered'}*100) / $st3{$p}{'flit_in'};\n";
		update_result($simulate,$sample,"flit_buffered_router_ratio",$ratio_in,$p,$tmp);
		$tmp= ($st3{$p}{'flit_in'}==0)? 0 : ($st3{$p}{'flit_in_bypassed'}*100) / $st3{$p}{'flit_in'};
		update_result($simulate,$sample,"flit_bypass_router_ratio",$ratio_in,$p,$tmp);
		
	}
	
	#my $p= $simulate->object_get_attribute ($sample,"noc_info");    
   # my $TOPOLOGY=$p->{"TOPOLOGY"};
	#print "$TOPOLOGY\n";
	
	
}


sub run_task_simulation{
	my ($simulate,$info,$sample,$name)=@_;
	my $log= (defined $name)? "$ENV{PRONOC_WORK}/simulate/$name.log": "$ENV{PRONOC_WORK}/simulate/sim.log";
	my $SIM_CLOCK_LIMIT=$simulate->object_get_attribute ($sample,"SIM_CLOCK_LIMIT");
	
	my $bin=get_sim_bin_path($simulate,$sample,$info);
	
	my $dir = Cwd::getcwd();
	my $project_dir	  = abs_path("$dir/../.."); #mpsoc directory address
	$bin= "$project_dir/$bin"   if(!(-f $bin));
	my $num=$simulate->object_get_attribute($sample,"TRAFFIC_FILE_NUM");
	
	my $cpu_num = $simulate->object_get_attribute('compile', 'cpu_num');
	$cpu_num = 1 if (!defined $cpu_num);
	
	my @paralel_ratio;
	my $total=$num;
	my $jobs=0;	
	my $c=0;
	my $cmds="";
	my $out_path ="$ENV{PRONOC_WORK}/simulate/"; 
	
	for (my $i=0; $i<$num; $i++){
		 my $f=$simulate->object_get_attribute($sample,"traffic_file$i");
		 add_info($info, "Run $bin for $f  file \n");	
		 my $cmd="$bin -c $SIM_CLOCK_LIMIT -f  \"$f\" > $out_path/sim_out$i & ";
		 $cmds .=$cmd;
		 add_info($info, "$cmd \n");
		 $jobs++;
		 push (@paralel_ratio,$i);
		 $c++;
		 if($jobs % $cpu_num ==0 || $jobs == $total){
			#run paralle simulation
			my ($stdout,$exit,$stderr)=run_cmd_in_back_ground_get_stdout("$cmds\n wait\n");
			#print "($stdout,$exit,$stderr)\n";
			if($exit || (length $stderr >4)){
				add_colored_info($info, "Error in running simulation: $stderr \n",'red');
				$simulate->object_add_attribute ($sample,"status","failed");	
				$simulate->object_add_attribute('status',undef,'ideal');
				return;
			 } 
			 
			
			 
			 
			#save results
			for (my $j=0; $j<$c; $j++){
				my $r      = $paralel_ratio[$j];
				my $stdout = load_file("$out_path/sim_out$r");
				my @errors = unix_grep("$out_path/sim_out$r","ERROR:");
				if (scalar @errors  ){
						add_colored_info($info, "Error in running simulation: @errors \n",'red');
						$simulate->object_add_attribute ($sample,"status","failed");	
						$simulate->object_add_attribute('status',undef,'ideal');
						return;						
				}		
			
				extract_and_update_noc_sim_statistic ($simulate,$sample,$r,$stdout);
			} 
			
			$cmds="";
			@paralel_ratio=();
			$c=0;
			set_gui_status($simulate,"ref",2);	
		} 		 
		    	 
	}#for i
	
	$simulate->object_add_attribute ($sample,"status","done");	
}	




sub run_trace_simulation{
	my ($simulate,$info,$sample,$name)=@_;
	my $log= (defined $name)? "$ENV{PRONOC_WORK}/simulate/$name.log": "$ENV{PRONOC_WORK}/simulate/sim.log";
	
		
	my $bin=get_sim_bin_path($simulate,$sample,$info);
	
	
	my $project_dir	  = get_project_dir();
	$bin= "$project_dir/$bin"   if(!(-f $bin));
	
	
	my $cpu_num = $simulate->object_get_attribute('compile', 'cpu_num');
	$cpu_num = 1 if (!defined $cpu_num);
	
	my @paralel_ratio;
	
	my $jobs=0;	
	my $c=0;
	my $cmds="";
	my $out_path ="$ENV{PRONOC_WORK}/simulate/"; 
	my $thread_num = $simulate->object_get_attribute('compile', 'thread_num');
	$thread_num = 1 if (!defined $thread_num);
	
	my $model= $simulate->object_get_attribute($sample,'MODEL_NAME');
	
	add_info($info, "Run $bin for $model model \n");
	
	my $cmd="$bin -T $thread_num ";	
	my $traffictype=$simulate->object_get_attribute($sample,"TRAFFIC_TYPE");
	if($traffictype eq "Netrace"){
		my $PCK_NUM_LIMIT=$simulate->object_get_attribute ($sample,"PCK_NUM_LIMIT");		
		my $IGNORE_DPNDCY=$simulate->object_get_attribute ($sample,"IGNORE_DPNDCY");
		my $READER_THRL=$simulate->object_get_attribute ($sample,"READER_THRL");
		my $START_RGN=$simulate->object_get_attribute ($sample,"START_RGN");
		my $SPEED_UP=$simulate->object_get_attribute ($sample,"SPEED_UP");
	
		my $models_dir  = "$ENV{PRONOC_WORK}/simulate/netrace";		
		
		$cmd .="-F $models_dir/$model.bz2 -n $PCK_NUM_LIMIT -r $START_RGN  -v 0 -s $SPEED_UP";
		$cmd .=" -l " if ($READER_THRL eq "1\'b1" );
		$cmd .=" -d " if ($IGNORE_DPNDCY eq "1\'b1");
		
		
	
		
		
	}else{#synful
		my $SIM_CLOCK_LIMIT=$simulate->object_get_attribute ($sample,"SIM_CLOCK_LIMIT");
		my $PCK_NUM_LIMIT=$simulate->object_get_attribute ($sample,"PCK_NUM_LIMIT");
		my $RND_SEED=$simulate->object_get_attribute ($sample,"RND_SEED");
		my $EXIT_STEADY=$simulate->object_get_attribute ($sample,"EXIT_STEADY");
		my $FLITw=$simulate->object_get_attribute ($sample,"SYNFUL_FLITw");
		
		
		my $models_dir  = get_project_dir()."/mpsoc/src_c/synfull/generated-models/";	
		$cmd .=" -S $models_dir/$model.model -n $PCK_NUM_LIMIT -r $RND_SEED -c $SIM_CLOCK_LIMIT -v 0 -w $FLITw";
		$cmd .=" -s " if ($EXIT_STEADY eq "1\'b1");

		
		
	}
	$cmd .=" > $out_path/sim_out";	
	add_info($info, "$cmd \n");
	
	my ($stdout,$exit,$stderr)=run_cmd_in_back_ground_get_stdout("$cmd\n wait\n");
	if($exit || (length $stderr >4)){
		add_colored_info($info, "Error in running simulation: $stderr \n",'red');
		$simulate->object_add_attribute ($sample,"status","failed");	
		$simulate->object_add_attribute('status',undef,'ideal');
		return;
	 } 
		
	
		 
	$stdout = load_file("$out_path/sim_out");
	my @errors = unix_grep("$out_path/sim_out","ERROR:");
	if (scalar @errors  ){
		add_colored_info($info, "Error in running simulation: @errors \n",'red');
		$simulate->object_add_attribute ($sample,"status","failed");	
		$simulate->object_add_attribute('status',undef,'ideal');
		return;						
	}		
			
	extract_and_update_noc_sim_statistic ($simulate,$sample,0,$stdout);
	
			
	set_gui_status($simulate,"ref",2);	
		
	
	$simulate->object_add_attribute ($sample,"status","done");	
}	




##########
# check_sample
##########

sub get_sim_bin_path {
	my ($self,$sample,$info)=@_;
	my $bin_path=$self->object_get_attribute ($sample,"sof_path");	
	unless (-d $bin_path){
		my $path= $self->object_get_attribute ("sim_param","BIN_DIR");
		if(-d $path){
			add_colored_info($info, "Warning: The given path ($bin_path) for searching $sample bin file does not exist. The system search in default $path instead.\n",'green');
			$bin_path=$path;
		}
	}	
	my $bin_file=$self->object_get_attribute ($sample,"sof_file");	
	$bin_file = "-" if(!defined $bin_file);		
	my $sof="$bin_path/$bin_file";
	return $sof;
}

sub check_sim_sample{
	my ($self,$sample,$info)=@_;
	my $status=1;
	my $sof=get_sim_bin_path($self,$sample,$info);
			
	# ckeck if sample have sof file
	if(!defined $sof){
		add_colored_info($info, "Error: bin file has not set for $sample!\n",'red');
		$self->object_add_attribute ($sample,"status","failed");	
		$status=0;
	} else {
		# ckeck if bin file has info file 
		my ($name,$path,$suffix) = fileparse("$sof",qr"\..[^.]*$");
		my $sof_info= "$path$name.inf";
		if(!(-f $sof_info)){
			add_colored_info($info, "Could not find $name.inf file in $path. An information file is required for each sof file containing the device name and  NoC configuration. Press F3 for more help.\n",'red');
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
	#check if sample min packet size matches in simulation 
	
	my $p= $self->object_get_attribute ($sample,"noc_info");    
    my $HW_MIN_PCK_SIZE=$p->{"MIN_PCK_SIZE"};
    my $HW_PCK_TYPE=$p->{"PCK_TYPE"};
    my $SIM_MIN_PCK_SIZE=$self->object_get_attribute ($sample,"MIN_PCK_SIZE");
    my $SIM_MAX_PCK_SIZE=$self->object_get_attribute ($sample,"MAX_PCK_SIZE");
   if(!defined $HW_MIN_PCK_SIZE){
    	$HW_MIN_PCK_SIZE= 2;   
    	#print "undef\n"; 	
    }
    $HW_PCK_TYPE = "MULTI_FLIT" if(~defined $HW_PCK_TYPE);
	if($HW_MIN_PCK_SIZE>$SIM_MIN_PCK_SIZE){
		add_colored_info($info, "Error: The minimum simulation packet size of $SIM_MIN_PCK_SIZE flit(s) is smaller than $HW_MIN_PCK_SIZE which is defined in generating verilog model of NoC!\n",'red');
		$self->object_add_attribute ($sample,"status","failed");	
		$status=0;
	}
	if( $HW_PCK_TYPE eq '"SINGLE_FLIT"' && $SIM_MAX_PCK_SIZE !=1){
		#print "$HW_PCK_TYPE  \n"; 
		add_colored_info($info, "Error: The maximum packet size is set as $SIM_MAX_PCK_SIZE however, the selected NoC model only support single-flit packet injection! Please redefine it to one\n",'red');
		
		$self->object_add_attribute ($sample,"status","failed");	
		$status=0;
	}
			
	return $status;
}

sub noc_sim_ctrl{
	my ($simulate,$info)=@_;
	
	my $generate = def_image_button('icons/forward.png','R_un all',FALSE,1);
	my $open = def_image_button('icons/browse.png',"_Load",FALSE,1);
	my $save = def_image_button('icons/save.png','Sav_e',FALSE,1);
	my $save_all_results = def_image_button('icons/copy.png',"E_xtract all results",FALSE,1);
	my $cpus=select_parallel_process_num($simulate);
	my ($object,$attribute1,$attribute2,$content,$default,$status,$timeout)=@_;
	
	my $compiler =def_pack_hbox('FALSE',0, gen_label_in_center('Simulator:'), gen_combobox_object($simulate,'Simulator',undef,"Modelsim gui,Modelsim,Verilator","Verilator",'ref',1));
	
	
	my $entry = gen_entry_object($simulate,'simulate_name',undef,undef,undef,undef);
	my $entrybox=gen_label_info(" Save as:",$entry);
	$entrybox->pack_start( $save, FALSE, FALSE, 0);
	
	my $simulator =$simulate->object_get_attribute("Simulator");
	
	
	my $thread=select_parallel_thread_num($simulate);
	
		
	my $table = def_table (1, 12, FALSE);
	$table->attach ($open,		0, 1, 0,1,'expand','shrink',2,2);
	$table->attach ($compiler, 1, 2, 0,1,'expand','shrink',2,2);
	
	$table->attach ($cpus, 		2, 4, 0,1,'expand','shrink',2,2);
	if($simulator eq "Verilator"){
		$table->attach ($thread, 4, 5, 0,1,'expand','shrink',2,2);		
	}
	
	$table->attach ($entrybox,	5, 7, 0,1,'expand','shrink',2,2);
	$table->attach ($save_all_results, 7, 8, 0,1,'shrink','shrink',2,2);
	$table->attach ($generate, 	8, 9, 0,1,'expand','shrink',2,2);
	
	$generate-> signal_connect("clicked" => sub{ 
		my @samples =$simulate->object_get_attribute_order("samples");	
		foreach my $sample (@samples){
			$simulate->object_add_attribute ("$sample","status","run");	
		}
		run_simulator($simulate,$info);
		#set_gui_status($emulate,"ideal",2);

	});

#	$wb-> signal_connect("clicked" => sub{ 
#		wb_address_setting($mpsoc);
#	
#	});

	$open-> signal_connect("clicked" => sub{ 
		
		load_simulation($simulate,$info);
		#print Dumper($simulate);
		set_gui_status($simulate,"ref",5);
	
	});	

	$save-> signal_connect("clicked" => sub{ 
		save_simulation($simulate);		
		set_gui_status($simulate,"ref",5);
		
	
	});	
	
	$save_all_results-> signal_connect("clicked" => sub{ 
		#Get the path where to save all the simulation results
		my $open_in = $simulate->object_get_attribute ('sim_param','BIN_DIR');
     	get_dir_name($simulate,"Select the target directory","sim_param","ALL_RESULT_DIR",$open_in,'ref',1);
		$simulate->object_add_attribute ("graph_save","save_all_result",1);
		
	});	
	
	
	return add_widget_to_scrolled_win($table,gen_scr_win_with_adjst($simulate,"ctrl_sc_win"));
	
}


############
#    main
############
sub simulator_main{
	
	add_color_to_gd();
	my $simulate= emulator->emulator_new();
	set_gui_status($simulate,"ideal",0);
	

	my $main_table = def_table (25, 12, FALSE);
	$main_table->show_all;
	my ($infobox,$info)= create_txview();	
	
	

my @pages =(
	{page_name=>" Average/Total ", page_num=>0},
	{page_name=>" Per node ", page_num=>1},
	#{page_name=>" Worst-Case Delay ",page_num=>2},
	#{page_name=>" Execution Time ",page_num=>3},
	{page_name=>" Heat-Map. ",page_num=>4},
);



my @charts = (
	{ type=>"2D_line", page_num=>0, graph_name=> "Avg. packet Latency", result_name => "latency_result", X_Title=> 'Desired Avg. Injected Load Per Router (flits/clock (%))', Y_Title=>'Avg. Packet Latency (clock)', Z_Title=>undef, Y_Max=>100},
  	{ type=>"2D_line", page_num=>0, graph_name=> "Avg. flit Latency", result_name => "latency_flit_result", X_Title=> 'Desired Avg. Injected Load Per Router (flits/clock (%))', Y_Title=>'Avg. Flit Latency (clock)', Z_Title=>undef, Y_Max=>100},
  	{ type=>"2D_line", page_num=>0, graph_name=> "Avg. flit Latency per hop", result_name => "latency_perhop_result", X_Title=> 'Desired Avg. Injected Load Per Router (flits/clock (%))', Y_Title=>'Avg. Flit Latency per hop (clock)', Z_Title=>undef, Y_Max=>100},
    { type=>"2D_line", page_num=>0, graph_name=> "Avg. throughput", result_name => "throughput_result", X_Title=> 'Desired Avg. Injected Load Per Router (flits/clock (%))', Y_Title=>'Avg. Throughput (flits/clock (%))', Z_Title=>undef,Y_Max=>100},
  	{ type=>"2D_line", page_num=>0, graph_name=> "Avg. SD latency", result_name => "sd_latency_result", X_Title=> 'Desired Avg. Injected Load Per Router (flits/clock (%))', Y_Title=>'Latency Standard Deviation (clock)', Z_Title=>undef},
	{ type=>"2D_line", page_num=>0, graph_name=> "Worst pck latency (clk)", result_name => "worst_latency_result", X_Title=> 'Desired Avg. Injected Load Per Router (flits/clock (%))', Y_Title=>'Worst Packet Latency (clock)', Z_Title=>undef},
	{ type=>"2D_line", page_num=>0, graph_name=> "Min pck latency (clk)", result_name => "min_latency_result", X_Title=> 'Desired Avg. Injected Load Per Router (flits/clock (%))', Y_Title=>'Minimum Packet Latency (clock)', Z_Title=>undef},
	{ type=>"2D_line", page_num=>0, graph_name=> "Total injected pck", result_name =>"injected_pck_total" , X_Title=> 'Desired Avg. Injected Load Per Router (flits/clock (%))', Y_Title=>'Total Injected packets', Z_Title=>undef},
	{ type=>"2D_line", page_num=>0, graph_name=> "Total injected flit",result_name =>"injected_flit_total", X_Title=> 'Desired Avg. Injected Load Per Router (flits/clock (%))', Y_Title=>'Total Injected Fslits', Z_Title=>undef},
	{ type=>"2D_line", page_num=>0, graph_name=> "Execuation Cycles", result_name => "exe_time_result",X_Title=>'Desired Avg. Injected Load Per Router (flits/clock (%))' , Y_Title=>'Total Simulation Time (clk)', Z_Title=>undef},
	
	

	{ type=>"3D_bar",  page_num=>1, graph_name=> "Received packets per Endp", result_name => "packet_rsvd_result", X_Title=>'Endpoint ID' , Y_Title=>'Received Packets Per Endpoint', Z_Title=>undef},
	{ type=>"3D_bar",  page_num=>1, graph_name=> "Sent packets per Endp", result_name => "packet_sent_result", X_Title=>'Endpoint ID' , Y_Title=>'Sent Packets Per Endpoint', Z_Title=>undef},
	{ type=>"3D_bar",  page_num=>1, graph_name=> "Received flits per Endp", result_name => "flit_rsvd_result", X_Title=>'Endpoint ID' , Y_Title=>'Received Flits Per Endpoint', Z_Title=>undef},
	{ type=>"3D_bar",  page_num=>1, graph_name=> "Sent flits per Endp", result_name => "flit_sent_result", X_Title=>'Endpoint ID' , Y_Title=>'Sent Packets Flits Endpoint', Z_Title=>undef},
	{ type=>"3D_bar",  page_num=>1, graph_name=> "Flits per Router", result_name => "flit_per_router_result", X_Title=>'Router ID' , Y_Title=>'Received Flits Per Router', Z_Title=>undef},
	{ type=>"3D_bar",  page_num=>1, graph_name=> "Packets per Router", result_name => "packet_per_router_result", X_Title=>'Router ID' , Y_Title=>'Received Packets Per Router', Z_Title=>undef},
	{ type=>"3D_bar",  page_num=>1, graph_name=> "Worst Received pck latency per Endp", result_name => "worst_delay_rsvd_result",X_Title=>'Endpoint ID' , Y_Title=>'Worst-Case Delay (clk)', Z_Title=>undef},
	{ type=>"3D_bar",  page_num=>1, graph_name=> "Worst Sent pck latency per Endp", result_name => "worst_delay_sent_result",X_Title=>'Endpoint ID' , Y_Title=>'Worst-Case Delay (clk)', Z_Title=>undef},
	
	{ type=>"3D_bar",  page_num=>1, graph_name=> "Buffered Flit in Ratio Per Router", result_name => "flit_buffered_router_ratio",X_Title=>'Router ID' , Y_Title=>'Flit in buffered in router/Flit in (%)', Z_Title=>undef},
	{ type=>"3D_bar",  page_num=>1, graph_name=> "Bypassed Flit in Ratio Per Router", result_name => "flit_bypass_router_ratio",X_Title=>'Router ID' , Y_Title=>'Flit in bypassed in router/Flit in (%)', Z_Title=>undef},
	
	
	
	
		
	
	
	
	
	
	
	
	{ type=>"Heat-map", page_num=>4, graph_name=> "Select", result_name => "undef",X_Title=>'-' , Y_Title=> undef, Z_Title=>undef},
	{ type=>"Heat-map", page_num=>4, graph_name=> "Endp-2-Endp Flit-num", result_name => "endp-endp-flit_result",X_Title=>'total flit number sent from an endpoint to another' , Y_Title=> undef, Z_Title=>undef},
	{ type=>"Heat-map", page_num=>4, graph_name=> "Endp-2-Endp Packet-num", result_name => "endp-endp-pck_result",X_Title=>'total packet number sent from an endpoint to another' , Y_Title=> undef, Z_Title=>undef},
	
	
	);
	
	
	my ($conf_box,$set_win)=process_notebook_gen($simulate,$info,"simulate",undef,@charts);
	my $chart   =gen_multiple_charts  ($simulate,\@pages,\@charts,0.4);
    


	$main_table->set_row_spacings (4);
	$main_table->set_col_spacings (1);
	
	
	#my  $device_win=show_active_dev($soc,$soc,$infc,$soc_state,\$refresh,$info);
	
	
	
	
	my $image = get_status_gif($simulate);
	my $ctrl  = noc_sim_ctrl ($simulate,$info);
	
	my $v1=gen_vpaned($conf_box,.45,$image);
	my $v2=gen_vpaned($infobox,.2,$chart);
	my $h1=gen_hpaned($v1,.4,$v2);
	
	
	
	$main_table->attach_defaults ($h1  , 0, 12, 0,24);
	$main_table->attach ($ctrl, 0,12, 24,25,'fill','fill',2,2);
	
	my $sc_win=add_widget_to_scrolled_win($main_table);


	#check soc status every 0.5 second. refresh device table if there is any changes 
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
		
		
		
		#refresh GUI
		
		
		$ctrl->destroy();							
		$conf_box->destroy();
		$chart->destroy();
		$image->destroy(); 
		$image = get_status_gif($simulate);
		($conf_box,$set_win)=process_notebook_gen($simulate,$info,"simulate",$set_win,@charts);				
		$chart = gen_multiple_charts  ($simulate,\@pages,\@charts,0.4);
		$ctrl  = noc_sim_ctrl ($simulate,$info);
		$main_table->attach ($ctrl,0, 12, 24,25,'fill','fill',2,2);
		$v1 -> pack1($conf_box, TRUE, TRUE); 	
		$v1 -> pack2($image, TRUE, TRUE); 		
		$v2 -> pack2($chart, TRUE, TRUE); 	
		
		
		
		
		$conf_box->show_all();
		$main_table->show_all();			
		set_gui_status($simulate,"ideal",0);
		
		
		return TRUE;
		
	} );
		
		
	
		
	

	return $sc_win;

		

}

sub custom_traffic_dest{
	my ($self,$sample,$core_num)	=@_;
	
	my $num=$self->object_get_attribute($sample,"CUSTOM_SRC_NUM");
    for (my $i=0;$i<$num;$i++){
			my $src = $self->object_get_attribute($sample,"SRC_$i");
			my $dst = $self->object_get_attribute($sample,"DST_$i");
			return  ($core_num,$dst) if($src == $core_num);
    }
	return ($core_num, -1);#off	
}

sub download_netrace{
	my ($path) =@_;
	#create path if it is not exist
	unless (-d $path){
		mkpath("$path",1,01777);
	}
	my $window = def_popwin_size(30,85,"Netrace download",'percent');
	my $table = def_table(1, 1, FALSE);	
	my $scrolled_win = add_widget_to_scrolled_win($table);
	
	
my @links =(
{ label=>"blackscholes simlarge (907M) ",name=>"blackscholes_64c_simlarge.tra.bz2" ,url=>"https://www.cs.utexas.edu/~netrace/download/blackscholes_64c_simlarge.tra.bz2"},
{ label=>"blackscholes simmedium (182M)",name=>"blackscholes_64c_simmedium.tra.bz2",url=>"https://www.cs.utexas.edu/~netrace/download/blackscholes_64c_simmedium.tra.bz2"},
{ label=>"blackscholes simsmall (55M)  ",name=>"blackscholes_64c_simsmall.tra.bz2" ,url=>"https://www.cs.utexas.edu/~netrace/download/blackscholes_64c_simsmall.tra.bz2"},
{ label=>"bodytrack simlarge (3.5G)    ",name=>"bodytrack_64c_simlarge.tra.bz2"    ,url=>"https://www.cs.utexas.edu/~netrace/download/bodytrack_64c_simlarge.tra.bz2"},
{ label=>"canneal simmedium (3.5G)     ",name=>"canneal_64c_simmedium.tra.bz2"     ,url=>"https://www.cs.utexas.edu/~netrace/download/canneal_64c_simmedium.tra.bz2"},
{ label=>"dedup simmedium (4.1G)       ",name=>"dedup_64c_simmedium.tra.bz2"       ,url=>"https://www.cs.utexas.edu/~netrace/download/dedup_64c_simmedium.tra.bz2"},
{ label=>"ferret simmedium (2.7G)      ",name=>"ferret_64c_simmedium.tra.bz2"      ,url=>"https://www.cs.utexas.edu/~netrace/download/ferret_64c_simmedium.tra.bz2"},
{ label=>"fluidanimate simlarge (1.8G) ",name=>"fluidanimate_64c_simlarge.tra.bz2" ,url=>"https://www.cs.utexas.edu/~netrace/download/fluidanimate_64c_simlarge.tra.bz2"},
{ label=>"fluidanimate simmedium (677M)",name=>"fluidanimate_64c_simmedium.tra.bz2",url=>"https://www.cs.utexas.edu/~netrace/download/fluidanimate_64c_simmedium.tra.bz2"},
{ label=>"fluidanimate simsmall (317M) ",name=>"fluidanimate_64c_simsmall.tra.bz2" ,url=>"https://www.cs.utexas.edu/~netrace/download/fluidanimate_64c_simsmall.tra.bz2"},
{ label=>"swaptions simlarge (3.0G)    ",name=>"swaptions_64c_simlarge.tra.bz2"    ,url=>"https://www.cs.utexas.edu/~netrace/download/swaptions_64c_simlarge.tra.bz2"},
{ label=>"vips simmedium (3.1G)        ",name=>"vips_64c_simmedium.tra.bz2"        ,url=>"https://www.cs.utexas.edu/~netrace/download/vips_64c_simmedium.tra.bz2"},
{ label=>"x264 simmedium (5.1G)        ",name=>"x264_64c_simmedium.tra.bz2"        ,url=>"https://www.cs.utexas.edu/~netrace/download/x264_64c_simmedium.tra.bz2"},
{ label=>"x264 simsmall (1.2G)         ",name=>"x264_64c_simsmall.tra.bz2"         ,url=>"https://www.cs.utexas.edu/~netrace/download/x264_64c_simsmall.tra.bz2"},
);

	my $row=0;
	

	foreach my $d (@links){
		my $srow=$row;
		$table-> attach (gen_label_in_left($d->{label}) , 0, 1,  $row,$row+1,'expand','shrink',2,2); 
		my $file="$path/$d->{name}";
		if (-f $file){
			
		}else{
			my $download=def_image_button("icons/download.png",'Download');	
			$table-> attach ($download , 2, 3,  $row,$row+1,'expand','shrink',2,2);
			$download->signal_connect("clicked"=> sub{
					$download ->set_sensitive (FALSE);
					my $load= show_gif("icons/load.gif");
				    $table->attach ($load, 1, 2, $srow,$srow+ 1,'shrink','shrink',0,0); 
				    $load->show_all;
					my $o=$d->{name};					
					download_from_google_drive("$d->{url}" ,"$path/$o"  );
					$load->destroy;
					$download->destroy if (-f $file);
			});
		}
		$row++;
	}





$window ->add($scrolled_win);
$window->show_all;

}
