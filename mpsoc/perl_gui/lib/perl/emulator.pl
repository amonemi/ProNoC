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
require "emulate_ram_gen.pl"; 
require "mpsoc_gen.pl"; 
require "mpsoc_verilog_gen.pl"; 
require "readme_gen.pl";
require "graph.pl";

use List::MoreUtils qw(uniq);


# hardware parameters taken from noc_emulator.v
use constant PCK_CNTw =>30;  # packet counter width in bits (results in maximum of 2^30 = 1  G packets)
use constant PCK_SIZw =>14;  # packet size width in bits (results in maximum packet size of 2^14 = 16 K flit)
use constant MAXXw    =>4;   # maximum nodes in x dimention is 2^MAXXw equal to 16 nodes in x dimention
use constant MAXYw    =>4;   # 16 nodes in y dimention : hence max emulator size is 16X16
use constant MAXCw    =>4;   # 16 message classes  
use constant RATIOw   =>7;   # log2(100)
use constant RAM_Aw   =>7;
use constant RAM_RESERVED_ADDR_NUM=>8;
use constant MAX_PATTERN => ((2**RAM_Aw)-(RAM_RESERVED_ADDR_NUM));  
use constant RAM_SIZE => (2**RAM_Aw);       

    
#use constant MAX_PCK_NUM => (2**PCK_CNTw)-1;
use constant MAX_PCK_NUM => (2**PCK_CNTw)-1;
use constant MAX_PCK_SIZ => (2**PCK_SIZw)-1; 
use constant MAX_SIM_CLKs=> 1000000000; # simulation end at if clock counter reach this number 

          
use constant MAX_RATIO => 1000;# 0->0 1->0.1 ...  1000->100
use constant EMULATION_RTLS => "/mpsoc/src_emulate/rtl/ , /mpsoc/src_peripheral/jtag/jtag_wb/ , /mpsoc/src_peripheral/ram/ , /mpsoc/src_noc/ ,";
use constant EMULATION_TOP => "/mpsoc/src_emulate/emulator_top.v";



sub check_inserted_ratios {
		my $str=shift;
		my @ratios;
	    	
	    my @chunks=split(',',$str);
	    foreach my $p (@chunks){
			if($p !~ /^[0-9.:,]+$/){ message_dialog ("$p has invalid character(S)" ); return undef; }
			my @range=split(':',$p);
			my $size= scalar @range;
			if($size==1){ # its a number
				if ( $range[0] <= 0 || $range[0] >100  ) { message_dialog ("$range[0] is out of boundery (1:100)" ); return undef; }
				push(@ratios,$range[0]);
			}elsif($size ==3){# its a range
				my($min,$max,$step)=@range;
				if ( $min <= 0 || $min >100  ) { message_dialog ("$min in  $p is out of boundery (1:100)" ); return undef; }
				if ( $max <= 0 || $max >100  ) { message_dialog ("$max in  $p is out of boundery (1:100)" ); return undef; }
				for (my $i=$min; $i<=$max; $i=$i+$step){
						push(@ratios,$i);
				}			
				
			}else{
				 message_dialog ("$p has invalid format. The correct format for range is \$min:\$max:\$step" );
				
			}			
			
		}#foreach
		my @r=uniq(sort {$a<=>$b} @ratios);
		return \@r;
			
}


sub get_injection_ratios{
		my ($emulate,$atrebute1,$atrebute2)=@_;
		my $box = Gtk2::HBox->new( FALSE, 0 );
		my $init=$emulate->object_get_attribute($atrebute1,$atrebute2);
		my $entry=gen_entry($init);
		my $button=def_image_button("icons/right.png",'Check');		
		$button->signal_connect("clicked" => sub {
			my $text= $entry->get_text();
			my $r=check_inserted_ratios($text);	
			if(defined 	$r){	
				my $all=  join (',',@$r);
				message_dialog ("$all" );
			}
			
			
		});	
		$entry->signal_connect ("changed" => sub {	
			my $text= $entry->get_text();
			$emulate->object_add_attribute($atrebute1,$atrebute2,$text);
			
		});	
		$box->pack_start( $entry, 1,1, 0);
		$box->pack_start( $button, 0, 1, 3);
		return 	$box;
}



sub get_noc_configuration{
	my ($emulate,$mode,$sample,$set_win) =@_;	
	if($mode eq "simulate") {get_simulator_noc_configuration(@_); return;} 
	get_emulator_noc_configuration(@_);
}

sub get_sof_file_full_addr{
	my ($emulate,$sample)=@_;
	my $open_in	= $emulate->object_get_attribute($sample,"sof_path");	
	my $board	= $emulate->object_get_attribute($sample,"FPGA_board");	
	my $file	= $emulate->object_get_attribute($sample,"sof_file");
	return undef if(!defined ${open_in} || !defined ${board} || !defined $file );
	my $sof = "${open_in}/${board}/$file";
	#print "\n$sof\n";
	return $sof;
}


sub get_emulator_noc_configuration{
	my ($emulate,$mode,$sample,$set_win) =@_;	
	my $table=def_table(10,2,FALSE);
	my $row=0;
		
	my $traffics="tornado,transposed 1,transposed 2,bit reverse,bit complement,random"; #TODO hot spot for emulator
	
	#search path	
	my $dir = Cwd::getcwd();
	my $open_in	  = abs_path("$ENV{PRONOC_WORK}/emulate/sof");		
	attach_widget_to_table ($table,$row,gen_label_in_left("Search Path:"),gen_button_message ("Select the the Path where the verilator simulation files are located. Different NoC verilated models can be generated using Generate NoC configuration tab.","icons/help.png"), 
	get_dir_in_object ($emulate,$sample,"sof_path",undef,'ref_set_win',1,$open_in)); $row++;
	$open_in	= $emulate->object_get_attribute($sample,"sof_path");	
	
	
	
	#select the board
	my($label,$param,$default,$content,$type,$info);
	my @dirs = grep {-d} glob("$open_in/*");
	my $fpgas;
	foreach my $dir (@dirs) {
		my ($name,$path,$suffix) = fileparse("$dir",qr"\..[^.]*$");
		$default=$name;
		$fpgas= (defined $fpgas)? "$fpgas,$name" : "$name";		
	}	
	
	attach_widget_to_table ($table,$row,gen_label_in_left("Select FPGA board:"),gen_button_message ("Select the FPGA board. You can add your own FPGA board by adding its configuration file to mpsoc/boards directory","icons/help.png"), 
	gen_combobox_object ($emulate,$sample, "FPGA_board", $fpgas, undef,'ref_set_win',1)); $row++;
	
	
	#select the sram object file
	my $board	= $emulate->object_get_attribute($sample,"FPGA_board");	
	my @files;
	@files = glob "${open_in}/${board}/*" if(defined $board);
	my $sof_files="";
	foreach my $file (@files){
		my ($name,$path,$suffix) = fileparse("$file",qr"\..[^.]*$");
		$sof_files="$sof_files,$name" if($suffix eq '.sof');			
	}		
	attach_widget_to_table ($table,$row,gen_label_in_left("Sram Object File:"),gen_button_message ("Select the verilator simulation file. Different NoC simulators can be generated using Generate NoC configuration tab.","icons/help.png"), 
	gen_combobox_object ($emulate,$sample, "sof_file", $sof_files, undef,undef,undef)); $row++;	
		
		
		
	#attach_widget_to_table ($table,$row,gen_label_in_left("SoF file:"),gen_button_message ("Select the SRAM Object File (sof) for this NoC configration.","icons/help.png"), get_file_name_object ($emulate,$sample,"sof_file",'sof',$open_in)); $row++;
	

   my @emulateinfo = (
	{ label=>'Configuration name:', param_name=>'line_name', type=>'Entry', default_val=>$sample, content=>undef, info=>"NoC configration name. This name will be shown in load-latency graph for this configuration", param_parent=>$sample, ref_delay=> undef},

  	{ label=>"Traffic name", param_name=>'traffic', type=>'Combo-box', default_val=>'random', content=>$traffics, info=>"Select traffic pattern", param_parent=>$sample, ref_delay=>undef},

{ label=>"Packet size in flit:", param_name=>'PCK_SIZE', type=>'Spin-button', default_val=>4, content=>"2,".MAX_PCK_SIZ.",1", info=>undef, param_parent=>$sample, ref_delay=>undef},

	{ label=>"Packet number limit per node:", param_name=>'PCK_NUM_LIMIT', type=>'Spin-button', default_val=>1000000, content=>"2,".MAX_PCK_NUM.",1", info=>"Each node stops sending packets when it reaches packet number limit  or simulation clock number limit", param_parent=>$sample, ref_delay=>undef},

{ label=>"Emulation clocks limit:", param_name=>'SIM_CLOCK_LIMIT', type=>'Spin-button', default_val=>MAX_SIM_CLKs, content=>"2,".MAX_SIM_CLKs.",1", info=>"Each node stops sending packets when it reaches packet number limit  or simulation clock number limit", param_parent=>$sample, ref_delay=>undef},

	
);



	my @siminfo = (
	{ label=>'Configuration name:', param_name=>'line_name', type=>'Entry', default_val=>$sample, content=>undef, info=>"NoC configration name. This name will be shown in load-latency graph for this configuration", param_parent=>$sample, ref_delay=> undef, new_status=>undef},

  	{ label=>"Traffic name", param_name=>'traffic', type=>'Combo-box', default_val=>'random', content=>$traffics, info=>"Select traffic pattern", param_parent=>$sample, ref_delay=>1, new_status=>'ref_set_win'},

	{ label=>"Packet size in flit:", param_name=>'PCK_SIZE', type=>'Spin-button', default_val=>4, content=>"2,".MAX_PCK_SIZ.",1", info=>undef, param_parent=>$sample, ref_delay=>undef},

	{ label=>"Total packet number limit:", param_name=>'PCK_NUM_LIMIT', type=>'Spin-button', default_val=>200000, content=>"2,".MAX_PCK_NUM.",1", info=>"Simulation will stop when total numbr of sent packets by all nodes reaches packet number limit  or total simulation clock reach its limit", param_parent=>$sample, ref_delay=>undef, new_status=>undef},

	{ label=>"Simulator clocks limit:", param_name=>'SIM_CLOCK_LIMIT', type=>'Spin-button', default_val=>100000, content=>"2,".MAX_SIM_CLKs.",1", info=>"Each node stops sending packets when it reaches packet number limit  or simulation clock number limit", param_parent=>$sample, ref_delay=>undef,  new_status=>undef},
	);


my $hot_num=$emulate->object_get_attribute($sample,"HOTSPOT_NUM");
$hot_num=1 if(!defined $hot_num); 
my $max= ($hot_num>0)? 100/$hot_num: 20;

my @hotspot_info=(
	{ label=>'Hot Spot num:', param_name=>'HOTSPOT_NUM', type=>'Spin-button', default_val=>1, 
	  content=>"1,5,1", info=>"Number of hot spot nodes in the network", 
	  param_parent=>$sample, ref_delay=> 1, new_status=>'ref_set_win'},
	{ label=>'Hot Spot traffic percentage:', param_name=>'HOTSPOT_PERCENTAGE', type=>'Spin-button', default_val=>1, 
	  content=>"1, $max,1", info=>"If it is set as n then each node sends n % of its traffic to each hotspot node", 
	  param_parent=>$sample, ref_delay=> undef, new_status=>undef},
	  
	{ label=>'Hot Spot nodes send enable:', param_name=>'HOTSPOT_SEND', type=>'Combo-box', default_val=>1, 
	  content=>"0,1", info=>"If it is set as 0 then hot spot nodes only recieves packet from other nodes and do not send packets to others", 
	  param_parent=>$sample, ref_delay=> undef, new_status=>undef},  
	  
	
	);
	
		
	my @info= ($mode eq "simulate")? @siminfo : @emulateinfo; 
	
		
	foreach my $d ( @info) {
	$row=noc_param_widget ($emulate, $d->{label}, $d->{param_name}, $d->{default_val}, $d->{type}, $d->{content}, $d->{info}, $table,$row,1, $d->{param_parent}, $d->{ref_delay}, $d->{new_status});
	}
	my $traffic=$emulate->object_get_attribute($sample,"traffic");

	if ($traffic eq 'hot spot'){
		foreach my $d ( @hotspot_info) {
			$row=noc_param_widget ($emulate, $d->{label}, $d->{param_name}, $d->{default_val}, $d->{type}, $d->{content}, $d->{info}, $table,$row,1, $d->{param_parent}, $d->{ref_delay}, $d->{new_status});
		}
		my $num=$emulate->object_get_attribute($sample,"HOTSPOT_NUM");
		for (my $i=0;$i<$num;$i++){
			my $m=$i+1;
			$row=noc_param_widget ($emulate, "Hotspot $m tile num:", "HOTSPOT_CORE_$m", 0, 'Spin-button', "0,256,1",
			 "Defne the tile number which is  hotspt. All other nodes will send [Hot Spot traffic percentage] of their traffic to this node ", $table,$row,1,$sample );
					
		}
	
	}
	my $l= "Define injection ratios. You can define individual ratios seprating by comma (\',\') or define a range of injection ratios with \$min:\$max:\$step format.
As an example defining 2,3,4:10:2 will result in (2,3,4,6,8,10) injection ratios." ;
	my $u=get_injection_ratios ($emulate,$sample,"ratios");
		
	attach_widget_to_table ($table,$row,gen_label_in_left("Injection ratios:"),gen_button_message ($l,"icons/help.png") , $u); $row++;
	
	my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);
	$scrolled_win->set_policy( "automatic", "automatic" );
	$scrolled_win->add_with_viewport($table);
		
	my $ok = def_image_button('icons/select.png','OK');
	my $mtable = def_table(10, 1, TRUE);

	$mtable->attach_defaults($scrolled_win,0,1,0,9);
	$mtable-> attach ($ok , 0, 1,  9, 10,'expand','shrink',2,2); 
	
	$set_win->add ($mtable);
	$set_win->show_all();

	$set_win ->signal_connect (destroy => sub{
		
		$emulate->object_add_attribute("active_setting",undef,undef);
	});

	
	
	$ok->signal_connect("clicked"=> sub{
		#check if sof file has been selected
		my $s=get_sof_file_full_addr($emulate,$sample);
		#check if injection ratios are valid
		my $r=$emulate->object_get_attribute($sample,"ratios");
		if(defined $s && defined $r) {	
				$set_win->destroy;
				#$emulate->object_add_attribute("active_setting",undef,undef);
				set_gui_status($emulate,"ref",1);
		} else {
			
			if(!defined $s){
				my $m=($mode eq 'simulate') ? "Please select NoC verilated file" : "Please select sof file!";
				message_dialog($m);  
			} else {
				 message_dialog("Please define valid injection ratio(s)!");
			}
		}
	});
	
	
}	
	 

      
#####################
#		gen_widgets_column
###################      
      
sub gen_emulation_column {
	my ($emulate,$mode, $row_num,$info,@charts)=@_;
	my $table=def_table($row_num,10,FALSE);
	
	my $set_win=def_popwin_size(40,80,"NoC configuration setting",'percent');
	my $scrolled_win = gen_scr_win_with_adjst ($emulate,"emulation_column");
	$scrolled_win->add_with_viewport($table);	
	my $row=0;
	
	#title	
	my $title_l =($mode eq "simulate" ) ? "NoC Simulator" : "NoC Emulator";
	my $title=gen_label_in_center($title_l);
	$table->attach ($title , 0, 10,  $row, $row+1,'expand','shrink',2,2); $row++;
	my $separator = Gtk2::HSeparator->new;	
	$table->attach ($separator , 0, 10 , $row, $row+1,'fill','fill',2,2);	$row++;
	

	my @positions=(0,1,2,3,4,5,6);
	my $col=0;
	
	my @title=("Name", " Add/Remove "," Setting ", "Line\'s color", "Clear","Run");
	foreach my $t (@title){
		
		$table->attach (gen_label_in_center($title[$col]), $positions[$col], $positions[$col+1], $row, $row+1,'expand','shrink',2,2);$col++;
	}
	
	my $traffics="Random,Transposed 1,Transposed 2,Tornado";

	$col=0;
	$row++;
	@positions=(0,1,2,3,4,5,6,7);

	
	#my $i=0;
	my $active=$emulate->object_get_attribute("active_setting",undef);
	my @samples; 
	@samples =$emulate->object_get_attribute_order("samples");
	
	foreach my $ss (@samples){
		
		$col=0;
		my $sample=$ss;
		#my $sample="sample$i";
		#my $n=$i;
		
		my $name=$emulate->object_get_attribute($sample,"line_name");
		my $l;
		my $s=($mode eq "simulate" ) ? 1 : get_sof_file_full_addr($emulate,$sample);
		#check if injection ratios are valid
		my $r=$emulate->object_get_attribute($sample,"ratios");
		if(defined $s  && defined $name){
			 $l=gen_label_in_center($name); 
		} else {
			$l=gen_label_in_left("Define NoC configuration");
			$l->set_markup("<span  foreground= 'red' ><b>Define NoC configuration</b></span>");			 
		}
		#my $box=def_pack_hbox(FALSE,0,(gen_label_in_left("$i- "),$l,$set));
		$table->attach ($l, $positions[$col], $positions[$col+1], $row, $row+1,'expand','shrink',2,2);$col++;

		#remove 
		my $remove=def_image_button("icons/cancel.png");
		$table->attach ($remove, $positions[$col], $positions[$col+1], $row, $row+1,'expand','shrink',2,2);$col++;
		$remove->signal_connect("clicked"=> sub{
			$emulate->object_delete_attribute_order("samples",$sample);
			set_gui_status($emulate,"ref",2);
		});

		#setting
		my $set=def_image_button("icons/setting.png");
		$table->attach ($set, $positions[$col], $positions[$col+1], $row, $row+1,'expand','shrink',2,2);$col++;

		
		if(defined $active){#The setting windows ask for refershing so open it again
			get_noc_configuration($emulate,$mode,$sample,$set_win) if	($active eq $sample);
		}
		
		
		
		$set->signal_connect("clicked"=> sub{
			$emulate->object_add_attribute("active_setting",undef,$sample);
			get_noc_configuration($emulate,$mode,$sample,$set_win);
		});
		
		
		
		my $color_num=$emulate->object_get_attribute($sample,"color");
		if(!defined $color_num){
			$color_num = (scalar @samples) +1;
			$emulate->object_add_attribute($sample,"color",$color_num);
		}
		my $color=def_colored_button("    ",$color_num);
		$table->attach ($color, $positions[$col], $positions[$col+1], $row, $row+1,'expand','shrink',2,2);$col++;
		
		
		
		$color->signal_connect("clicked"=> sub{
			get_color_window($emulate,$sample,"color");
		});
		
		#clear line
		my $clear = def_image_button('icons/clear.png');
		$clear->signal_connect("clicked"=> sub{
			foreach my $chart (@charts){	
				$emulate->object_add_attribute ($sample,"$chart->{result_name}",undef);
				
				#print "\$emulate->object_add_attribute ($sample,$chart->{result_name}_result,undef);";
				
			}
			set_gui_status($emulate,"ref",2);
		});
		$table->attach ($clear, $positions[$col], $positions[$col+1], $row, $row+1,'expand','shrink',2,2);$col++;
		#run/pause
		my $run = def_image_button('icons/run.png',undef);
		$table->attach ($run, $positions[$col], $positions[$col+1], $row, $row+1,'expand','shrink',2,2);$col++;
		$run->signal_connect("clicked"=> sub{
			$emulate->object_add_attribute ($sample,"status","run");
			#start the emulator if it is not running	
			my $status= $emulate->object_get_attribute('status',undef);
			if($status ne 'run'){
				
				run_emulator($emulate,$info) if($mode eq 'emulate');
				run_simulator($emulate,$info) if($mode eq 'simulate');  
				set_gui_status($emulate,"ref",2);
			}
			
		});
		
		my $image = gen_noc_status_image($emulate,$sample);
		
		$table->attach ($image, $positions[$col], $positions[$col+1], $row, $row+1,'expand','shrink',2,2);
		
		
		$row++;
		
	}
	# add new simulation
	my $add=def_image_button("icons/plus.png", );
	$table->attach ($add, $positions[1], $positions[2], $row, $row+1,'expand','shrink',2,2);

	$add->signal_connect("clicked"=> sub{
		my $n=$emulate->object_get_attribute("id",undef);
		$n=0 if (!defined $n);
		my $sample="sample$n";
		$n++;
		$emulate->object_add_attribute("id",undef,$n);
		$emulate->object_add_attribute("active_setting",undef,$sample);
		#get_noc_configuration($emulate,$mode,$sample,$set_win);
		$emulate->object_add_attribute_order("samples",$sample);
		set_gui_status($emulate,"ref",1);		
			
	});	
	
	 
	return ($scrolled_win,$set_win);
}	      



##########
# check_sample
##########

sub check_sample{
	my ($emulate,$sample,$info)=@_;
	my $status=1;
	my $sof=get_sof_file_full_addr($emulate,$sample);
	
	
	
	# ckeck if sample have sof file
	if(!defined $sof){
		#add_info($info, "Error: SoF file has not set for $sample!\n");
		add_colored_info($info, "Error: SoF file has not set for $sample!\n",'red');
		$emulate->object_add_attribute ($sample,"status","failed");	
		$status=0;
	} else {
		# ckeck if sof file has info file 
		my ($name,$path,$suffix) = fileparse("$sof",qr"\..[^.]*$");
		my $sof_info= "$path$name.inf";
		
	#	print "\n $sof \t $sof_info\n";
		
		if(!(-f $sof_info)){
			add_colored_info($info, "Error: Could not find $name.inf file in $path. An information file is required for each sof file containig the device name and  NoC configuration. Press F4 for more help.\n",'red');
			$emulate->object_add_attribute ($sample,"status","failed");	
			$status=0;
		}else { #add info
			my $pp= do $sof_info ;

			my $p=$pp->{'noc_param'};
			
			$status=0 if $@;
			message_dialog("Error reading: $@") if $@;
			if ($status==1){
				$emulate->object_add_attribute ($sample,"noc_info",$p) ;
					
			
			}			
		}		
	}
				
	return $status;
}



##########
#  run external commands
##########

sub run_cmd_in_back_ground
{
  my $command = shift;
  #print "\t$command\n";
 
  ### Start running the Background Job:
    my $proc = Proc::Background->new($command);
    my $PID = $proc->pid;
    my $start_time = $proc->start_time;
    my $alive = $proc->alive;

  ### While $alive is NOT '0', then keep checking till it is...
  #  *When $alive is '0', it has finished executing.
  while($alive ne 0)
  {
    $alive = $proc->alive;

    # This while loop will cause Gtk2 to conti processing events, if
    # there are events pending... *which there are...
    while (Gtk2->events_pending) {
      Gtk2->main_iteration;
    }
    Gtk2::Gdk->flush;

    usleep(1000);
  }
  
  my $end_time = $proc->end_time;
 # print "*Command Completed at $end_time, with PID = $PID\n\n";

  # Since the while loop has exited, the BG job has finished running:
  # so close the pop-up window...
 # $popup_window->hide;

  # Get the RETCODE from the Background Job using the 'wait' method
  my $retcode = $proc->wait;
  $retcode /= 256;

  print "\t*RETCODE == $retcode\n\n";
  Gtk2::Gdk->flush;
  ### Check if the RETCODE returned with an Error:
  if ($retcode ne 0) {
    print "Error: The Background Job ($command) returned with an Error...!\n";
    return 1;
  } else {
    #print "Success: The Background Job Completed Successfully...!\n";
    return 0;
  }
	
}




sub run_cmd_in_back_ground_get_stdout
{
	my $cmd=shift;
	my $exit;
	my ($stdout, $stderr);
	capture { $exit=run_cmd_in_back_ground($cmd) } \$stdout, \$stderr;
	return ($stdout,$exit,$stderr);
	
}	


#############
#  images
##########
sub get_status_gif{
		my $emulate=shift;
		my $status= $emulate->object_get_attribute('status',undef);
		if($status eq 'ideal'){
			return show_gif ("icons/ProNoC.png");
		} elsif ($status eq 'run') {
			my($width,$hight)=max_win_size();
			my $image=($width>=1600)? "icons/hamster_l.gif":
			          ($width>=1200)? "icons/hamster_m.gif": "icons/hamster_s.gif"; 
				  
			return show_gif ($image);			
		} elsif ($status eq 'programer_failed') {
			return show_gif ("icons/Error.png");			
		}
	
}	




sub gen_noc_status_image {
	my ($emulate,$sample)=@_;
	my   $status= $emulate->object_get_attribute ($sample,"status");	
	 $status='' if(!defined  $status);
	my $image;
	my $vbox = Gtk2::HBox->new (TRUE,1);
	$image = Gtk2::Image->new_from_file ("icons/load.gif") if($status eq "run");
	$image = def_icon("icons/button_ok.png") if($status eq "done");
	$image = def_icon("icons/warnning.png") if($status eq "failed");
	#$image_file = "icons/load.gif" if($status eq "run");
	
	if (defined $image) {
		my $align = Gtk2::Alignment->new (0.5, 0.5, 0, 0);
     	my $frame = Gtk2::Frame->new;
		$frame->set_shadow_type ('in');
		# Animation
		$frame->add ($image);
		$align->add ($frame);
		$vbox->pack_start ($align, FALSE, FALSE, 0);
	}
	return $vbox;
	
}


############
#	run_emulator
###########

sub run_emulator {
	my ($emulate,$info)=@_;
	#my $graph_name="latency_ratio";
	#return if(!check_samples($emulate,$info));
	$emulate->object_add_attribute('status',undef,'run');
	set_gui_status($emulate,"ref",1);
	show_colored_info($info, "start emulation\n",'blue');

#	#search for available usb blaster
#	my $cmd = "jtagconfig";
#	my ($stdout,$exit)=run_cmd_in_back_ground_get_stdout("$cmd");
#	my @matches= ($stdout =~ /USB-Blaster.*/g);
#	my $usb_blaster=$matches[0];
# 	if (!defined $usb_blaster){
#		add_info($info, "jtagconfig could not find any USB blaster cable: $stdout \n");
#		$emulate->object_add_attribute('status',undef,'programer_failed');
#		set_gui_status($emulate,"ref",2);
#		#/***/
#		return;	
#	}else{
#		add_info($info, "find $usb_blaster\n");
#	}
	my @samples =$emulate->object_get_attribute_order("samples");
	foreach my $sample (@samples){
		my $status=$emulate->object_get_attribute ($sample,"status");	
		next if($status ne "run");
		next if(!check_sample($emulate,$sample,$info));
		my $r= $emulate->object_get_attribute($sample,"ratios");
		my @ratios=@{check_inserted_ratios($r)};
		#$emulate->object_add_attribute ("sample$i","status","run");			
		my $sof=get_sof_file_full_addr($emulate,$sample);	
		add_info($info, "Programe FPGA device using $sof.sof\n");
		my ($name,$path,$suffix) = fileparse("$sof",qr"\..[^.]*$");
		my $programer="$path/program_device.sh";
		my $jtag_intfc="$path/jtag_intfc.sh";
		if((-f $programer)==0){
			add_colored_info ($info, " Error: file  \"$programer\"  dose not exist. \n",'red'); 
			$emulate->object_add_attribute('status',undef,'programer_failed');
			$emulate->object_add_attribute ($sample,"status","failed");	
			set_gui_status($emulate,"ref",2);
			last;		
		}
		if((-f $jtag_intfc)==0){
			add_colored_info ($info, " Error: file  \"$jtag_intfc\"  dose not exist. \n",'red'); 
			$emulate->object_add_attribute('status',undef,'programer_failed');
			$emulate->object_add_attribute ($sample,"status","failed");	
			set_gui_status($emulate,"ref",2);
			last;		
		}
		my $cmd =  "sh $programer $sof.sof";
		
		
		#my $Quartus_bin=  $ENV{QUARTUS_BIN};
			

		#my $cmd = "$Quartus_bin/quartus_pgm -c \"$usb_blaster\" -m jtag -o \"p;$sof\"";
	
		#my $output = `$cmd 2>&1 1>/dev/null`;           # either with backticks

		#/***/
		my ($stdout,$exit)=run_cmd_in_back_ground_get_stdout("$cmd");	
		if($exit){#programming FPGA board has failed
			$emulate->object_add_attribute('status',undef,'programer_failed');
			add_colored_info($info, "$stdout\n",'red');
			$emulate->object_add_attribute ($sample,"status","failed");	
			set_gui_status($emulate,"ref",2);
			next;			
		}
		#print "$stdout\n";
		
		# load noc configuration 
		foreach  my $ratio_in (@ratios){						
	    	
		    	add_info($info, "Configure packet generators for  injection ratio of $ratio_in \% \n");
		    	if(!programe_pck_gens($emulate,$sample,$ratio_in,$info,$jtag_intfc)){
		    		add_colored_info($info, "Error in programe_pck_gens function\n",'red');		    		
		    		next;
		    	}
		    	
		    	
		    	my $r=read_pack_gen($emulate,$sample,$info,$jtag_intfc,$ratio_in);
			    next if (!defined $r);
			    
			   
	
		    	set_gui_status($emulate,"ref",2);
	    		    	
		}
		$emulate->object_add_attribute ($sample,"status","done");	
    	
	}
	
	add_colored_info($info, "End emulation!\n",'blue');
	$emulate->object_add_attribute('status',undef,'ideal');
	set_gui_status($emulate,"ref",1);
}






##############
#	 process_notebook_gen
##############


sub process_notebook_gen{
		my ($emulate,$info,$mode,@charts)=@_;
		my $notebook = Gtk2::Notebook->new;
		$notebook->set_tab_pos ('left');
		$notebook->set_scrollable(TRUE);
		$notebook->can_focus(FALSE);

		
		my ($page1,$set_win)=gen_emulation_column($emulate, $mode,10,$info,@charts);
		$notebook->append_page ($page1,Gtk2::Label->new_with_mnemonic ("  _Run emulator  ")) if($mode eq "emulate");
		$notebook->append_page ($page1,Gtk2::Label->new_with_mnemonic ("  _Run simulator ")) if($mode eq "simulate");
		
		
		my $page2=get_noc_setting_gui ($emulate,$info,$mode);
		my $tt=($mode eq "emulate")? "  _Generate NoC \nEmulation Model" : "  _Generate NoC \nSimulation Model" ;
		$notebook->append_page ($page2,Gtk2::Label->new_with_mnemonic ($tt));
		
		#if($mode eq "simulate"){
			#my $page3=gen_custom_traffic ($emulate,$info,$mode);
			#$notebook->append_page ($page3,Gtk2::Label->new_with_mnemonic ("_Generate Custom\n Traffic Pattern"));
		#}		
		
		my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);
		$scrolled_win->set_policy( "automatic", "automatic" );
		$scrolled_win->add_with_viewport($notebook);
		$scrolled_win->show_all;	
		my $page_num=$emulate->object_get_attribute ("process_notebook","currentpage");		
		$notebook->set_current_page ($page_num) if(defined $page_num);
		$notebook->signal_connect( 'switch-page'=> sub{			
			$emulate->object_add_attribute ("process_notebook","currentpage",$_[2]);	#save the new pagenumber
					
		});
		
		return ($scrolled_win,$set_win);
	
}


sub get_noc_setting_gui {
	my ($emulate,$info_text,$mode)=@_;
	my $table=def_table(20,10,FALSE);#	my ($row,$col,$homogeneous)=@_;
	
	my $scrolled_win = gen_scr_win_with_adjst ($emulate,"noc_setting_gui");
	$scrolled_win->add_with_viewport($table);
	my $row=noc_config ($emulate,$table);
	    
	my($label,$param,$default,$content,$type,$info);
	my @dirs = grep {-d} glob("../boards/*");
	my $fpgas;
	foreach my $dir (@dirs) {
		my ($name,$path,$suffix) = fileparse("$dir",qr"\..[^.]*$");
		$default=$name;
		$fpgas= (defined $fpgas)? "$fpgas,$name" : "$name";		
	}
	
	my @fpgainfo;
	if($mode eq "emulate"){	
		@fpgainfo = (
		{ label=>'Pck. injector FIFO Width:', param_name=>'TIMSTMP_FIFO_NUM', type=>'Spin-button', default_val=>16, content=>"2,128,2", info=>"Packet injectors' timestamp FIFO width. In case a packet cannot be injected according to the desired injection ratio, the current system time is saved in a FIFO and then at injection time it will be read and attached to the packet. The larger FIFO width results in more accurate latency calculation at the cost of higher area overhead." , param_parent=>'fpga_param', ref_delay=> undef},
	  	{ label=>'Save as:', param_name=>'SAVE_NAME', type=>"Entry", default_val=>'emulate1', content=>undef, info=>undef, param_parent=>'fpga_param', ref_delay=>undef},
		{ label=>"Project directory", param_name=>"SOF_DIR", type=>"DIR_path", default_val=>"$ENV{'PRONOC_WORK'}/emulate", content=>undef, info=>"Define the working directory for generating .sof file", param_parent=>'fpga_param',ref_delay=>undef },
		);	

	}
	else {
		@fpgainfo = (
		{ label=>'Pck. injector FIFO Width:', param_name=>'TIMSTMP_FIFO_NUM', type=>'Spin-button', default_val=>16, content=>"2,128,2", info=>"Packet injectors' timestamp FIFO width. In case a packet cannot be injected according to the desired injection ratio, the current system time is saved in a FIFO and then at injection time it will be read and attached to the packet. The larger FIFO width results in more accurate latency calculation." , param_parent=>'fpga_param', ref_delay=> undef},
  		{ label=>'Save as:', param_name=>'SAVE_NAME', type=>"Entry", default_val=>'simulate1', content=>undef, info=>undef, param_parent=>'sim_param', ref_delay=>undef},
		{ label=>"Project directory", param_name=>"BIN_DIR", type=>"DIR_path", default_val=>"$ENV{'PRONOC_WORK'}/simulate", content=>undef, info=>"Define the working directory for generating simulation executable binarry file", param_parent=>'sim_param',ref_delay=>undef },
		);	
	}
	
	foreach my $d (@fpgainfo) {
		$row=noc_param_widget ($emulate, $d->{label}, $d->{param_name}, $d->{default_val}, $d->{type}, $d->{content}, $d->{info}, $table,$row,1, $d->{param_parent}, $d->{ref_delay});
	}   
	   
	my $generate = def_image_button('icons/gen.png','Generate');
	$table->attach ($generate, 0,3, $row, $row+1,'expand','shrink',2,2);
    
    $generate->signal_connect ('clicked'=> sub{
		generate_sof_file($emulate,$info_text) if($mode eq "emulate");
		generate_sim_bin_file($emulate,$info_text) if($mode eq "simulate");
	});
		    
	return $scrolled_win;	
}

##########
#	generate_sof_file
##########


sub generate_sof_file {
	my ($self,$info)=@_;	

	my $name=$self->object_get_attribute ('fpga_param',"SAVE_NAME"); 
	my $target_dir  = "$ENV{'PRONOC_WORK'}/emulate/$name";
	my $top 	= "$target_dir/src_verilog/${name}_top.v";

	
	if (!defined $name){
		message_dialog("Please define the Save as filed!");
		return;
	}

	#copy all noc source codes
	my @files = split(/\s*,\s*/,EMULATION_RTLS);
	my $dir = Cwd::getcwd();
	my $project_dir	  = abs_path("$dir/../../");
	my ($stdout,$exit)=run_cmd_in_back_ground_get_stdout("mkdir -p $target_dir/src_verilog" );
	copy_file_and_folders(\@files,$project_dir,"$target_dir/src_verilog/lib/");
	

	#generate parameters for emulator_top.v file
	my ($localparam, $pass_param)=gen_noc_param_v( $self);
	open(FILE,  ">$target_dir/src_verilog/noc_parameters.v") || die "Can not open: $!";
	print FILE $localparam;
	close(FILE) || die "Error closing file: $!";
	open(FILE,  ">$target_dir/src_verilog/pass_parameters.v") || die "Can not open: $!";
	print FILE $pass_param;
	my $fifow=$self->object_get_attribute('fpga_param','TIMSTMP_FIFO_NUM');
	print FILE ",.TIMSTMP_FIFO_NUM($fifow)\n";
	close(FILE) || die "Error closing file: $!";
	open(FILE,  ">$top") || die "Can not open: $!";
	print FILE create_emulate_top($self,$name,$top);
	close(FILE) || die "Error closing file: $!";
	select_compiler($self,$name,$top,$target_dir,\&save_the_sof_file);
	
return;
}

sub create_emulate_top{
	my ($self,$name,$top)=@_;
	my $top_v= get_license_header("$top");

$top_v	="$top_v

`timescale	 1ns/1ps

module ${name}_top(
	output done_led,
	output noc_reset_led,
	output jtag_reset_led,
	input  reset,
	input  clk
); 


	localparam
		STATISTIC_VJTAG_INDEX=124,  
		PATTERN_VJTAG_INDEX=125,
   		COUNTER_VJTAG_INDEX=126,
		DONE_RESET_VJTAG_INDEX=127;
				

	//NoC parameters will be defined by user
	`define NOC_PARAM
	`include \"noc_parameters.v\"
 	
	wire  reset_noc, reset_injector, reset_noc_sync, reset_injector_sync, done;
	wire jtag_reset_injector, jtag_reset_noc;
	wire start_o;
	wire done_time_limit;
		
	assign done_led	= done | done_time_limit; 
	assign noc_reset_led= reset_noc;
	assign jtag_reset_led	= reset_injector;

	

	//  two reset sources which can be controled using jtag. One for reseting NoC another packet injectors
	jtag_source_probe #(
		.VJTAG_INDEX(DONE_RESET_VJTAG_INDEX),
	 	.Dw(2)	//source/probe width in bits
 	)the_reset(
		.probe({done_time_limit,done}),
		.source({jtag_reset_injector,jtag_reset_noc})
	);


	assign  reset_noc		=	(jtag_reset_noc | reset);
	assign  reset_injector		=	(jtag_reset_injector | reset);	

	altera_reset_synchronizer noc_rst_sync
	(
		.reset_in(reset_noc), 
		.clk(clk),
		.reset_out(reset_noc_sync)
	);


	altera_reset_synchronizer inject_rst_sync
	(
		.reset_in(reset_injector), 
		.clk(clk),
		.reset_out(reset_injector_sync)
	);
	
	//noc emulator
	
	noc_emulator #(
	.STATISTIC_VJTAG_INDEX(STATISTIC_VJTAG_INDEX),  
	.PATTERN_VJTAG_INDEX(PATTERN_VJTAG_INDEX),
	`include \"pass_parameters.v\"
		 
	)
	noc_emulate_top
	(
		.reset(reset_noc_sync),
		.jtag_ctrl_reset(reset_injector_sync),
		.clk(clk),
		.start_o(start_o),
		.done(done)
	);
	
	
	
	//clock counter
	
	function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end 	   
      end   
    endfunction // log2 
	
	localparam   MAX_SIM_CLKs  = 1_000_000_000;
	localparam   CLK_CNTw = log2(MAX_SIM_CLKs+1);
	
	reg     [CLK_CNTw-1             :   0] clk_counter;
	wire    [CLK_CNTw-1             :   0] clk_limit;
	reg start;
	always @(posedge clk or posedge reset_injector_sync) begin 
		if(reset_injector_sync)begin 
			clk_counter <= {CLK_CNTw{1'b0}};
			start<=1'b0;		
		end else begin 
			if(start_o) start<=1'b1;
			if(done==1'b0 && start ) clk_counter<=clk_counter +1'b1;
		end	
	end
	
	jtag_source_probe #(
		.VJTAG_INDEX(COUNTER_VJTAG_INDEX),
	 	.Dw(CLK_CNTw)	//source/probe width in bits
 	)the_clk_counter(
		.probe(clk_counter),
		.source(clk_limit)
	);
	
	assign done_time_limit = (clk_counter >= clk_limit);
endmodule
";
	return $top_v;
}

sub save_the_sof_file{

	my $self=shift;
	my $name=$self->object_get_attribute ('fpga_param',"SAVE_NAME"); 
	my $sofdir="$ENV{PRONOC_WORK}/emulate/sof";
	my $fpga_board=$self->object_get_attribute('compile','board');
	my $target_dir  = "$ENV{'PRONOC_WORK'}/emulate/$name";

	mkpath("$sofdir/$fpga_board/",1,01777);
	open(FILE,  ">$sofdir/$fpga_board/$name.inf") || die "Can not open: $!";
	print FILE perl_file_header("$name.inf");
	my %pp;
	$pp{'noc_param'}= $self->{'noc_param'};
	$pp{'fpga_param'}= $self->{'fpga_param'};
	print FILE Data::Dumper->Dump([\%pp],["emulate_info"]);
	close(FILE) || die "Error closing file: $!";	


	#find  $dir_name -name \*.sof -exec cp '{}' $sofdir/$fpga_board/$save_name.sof" 
	my @files = File::Find::Rule->file()
                 ->name( '*.sof' )
                 ->in( "$target_dir" );
	copy($files[0],"$sofdir/$fpga_board/$name.sof") or do { 
		my $err= "Error copy($files[0] , $sofdir/$fpga_board/$name.sof";	
		print "$err\n"; 	
		message_dialog($err); 
		return;
	};
	#copy the board's programming and jtag interface files
	
	my $board_name=$self->object_get_attribute('compile','board');
	#copy board jtag_intfc.sh file 
	copy("../boards/$board_name/jtag_intfc.sh","$sofdir/$fpga_board/jtag_intfc.sh");
	#print "../boards/$board_name/jtag_intfc.sh","$sofdir/$fpga_board/jtag_intfc.sh\n";
	#add argument run to jtag_interface file 
	my $runarg='

if [ $# -ne 0 ]
  then
    $JTAG_INTFC $1
fi
';
	append_text_to_file ("$sofdir/$fpga_board/jtag_intfc.sh",$runarg );
	
	
	

	#copy board program_device.sh file 
	copy("../boards/$board_name/program_device.sh","$sofdir/$fpga_board/program_device.sh");
	
	

	message_dialog("sof file has been generated successfully");	
}



##########
#	save_emulation
##########
sub save_emulation {
	my ($emulate)=@_;
	# read emulation name
	my $name=$emulate->object_get_attribute ("emulate_name",undef);	
	my $s= (!defined $name)? 0 : (length($name)==0)? 0 :1;	
	if ($s == 0){
		message_dialog("Please set emulation name!");
		return 0;
	}
	# Write object file
	open(FILE,  ">lib/emulate/$name.EML") || die "Can not open: $!";
	print FILE perl_file_header("$name.EML");
	print FILE Data::Dumper->Dump([\%$emulate],["emulate"]);
	close(FILE) || die "Error closing file: $!";
	message_dialog("Emulation saved as lib/emulate/$name.EML!");
	return 1;
}

#############
#	load_emulation
############

sub load_emulation {
	my ($emulate,$info)=@_;
	my $file;
	my $dialog = Gtk2::FileChooserDialog->new(
            	'Select a File', undef,
            	'open',
            	'gtk-cancel' => 'cancel',
            	'gtk-ok'     => 'ok',
        	);

	my $filter = Gtk2::FileFilter->new();
	$filter->set_name("EML");
	$filter->add_pattern("*.EML");
	$dialog->add_filter ($filter);
	my $dir = Cwd::getcwd();
	$dialog->set_current_folder ("$dir/lib/emulate");		


	if ( "ok" eq $dialog->run ) {
		$file = $dialog->get_filename;
		my ($name,$path,$suffix) = fileparse("$file",qr"\..[^.]*$");
		if($suffix eq '.EML'){
			my $pp= eval { do $file };
			if ($@ || !defined $pp){		
				add_colored_info($info,"**Error reading  $file file: $@\n",'red');
				 $dialog->destroy;
				return;
			} 

			clone_obj($emulate,$pp);
			#message_dialog("done!");				
		}					
     }
     $dialog->destroy;
}



sub update_result {
	my ($self,$sample,$name,$x,$y,$z)=@_;
	my $ref=$self->object_get_attribute ($sample,$name);
	my %results;
	%results= %{$ref} if(defined $ref);
	if(!defined $z) {$results{$x}=$y;}
	else {$results{$x}{$y}=$z;}	
	$self->object_add_attribute ($sample,$name,\%results);
}	


sub capture_cores_data {
	my ($data,$text)=@_;
	my %result;
	my @q =split  (/Core/,$text);
	my $i=0;
	foreach my $p (@q){
		if ($i!=0){
			my @d = split (/[^0-9. ]/,$p);
			my $n=	$d[0];
			my $val = capture_number_after("$data",$p);
			$result{remove_all_white_spaces($n)}=remove_all_white_spaces($val);
		}
		$i++;
	}	
	return %result; 
}





############
#    main
############
sub emulator_main{
		
	add_color_to_gd();
	my $emulate= emulator->emulator_new();
	set_gui_status($emulate,"ideal",0);
	$emulate->object_add_attribute('compile','compilers',"QuartusII");
	my $left_table = Gtk2::Table->new (25, 6, FALSE);
	my $right_table = Gtk2::Table->new (25, 6, FALSE);
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
  		{ type=>"2D_line", page_num=>3, graph_name=> "-", result_name => "exe_time_result",X_Title=>'Desired Avg. Injected Load Per Router (flits/clock (%))' , Y_Title=>'Total Emulation Time (clk)', Z_Title=>undef},
  	);
		
	my ($conf_box,$set_win)=process_notebook_gen($emulate,\$info,"emulate", @charts);
	my $chart   =gen_multiple_charts ($emulate,\@pages,\@charts);
    
	$main_table->set_row_spacings (4);
	$main_table->set_col_spacings (1);
		
	my $generate = def_image_button('icons/forward.png','Run all');
	my $open = def_image_button('icons/browse.png','Load');
		
	my ($entrybox,$entry) = def_h_labeled_entry('Save as:',undef);
	
	$entry->signal_connect( 'changed'=> sub{
		my $name=$entry->get_text();
		$emulate->object_add_attribute ("emulate_name",undef,$name);	
	});	
	my $save = def_image_button('icons/save.png','Save');
	$entrybox->pack_end($save,   FALSE, FALSE,0);
		
	my $image = get_status_gif($emulate);	
	my $v1=gen_vpaned($conf_box,.45,$image);
	my $v2=gen_vpaned($infobox,.2,$chart);
	my $h1=gen_hpaned($v1,.4,$v2);
	
	#$table->attach_defaults ($event_box, $col, $col+1, $row, $row+1);
	$main_table->attach_defaults ($h1  , 0, 12, 0,24);
	$main_table->attach ($open,0, 3, 24,25,'expand','shrink',2,2);
	$main_table->attach ($entrybox,3, 6, 24,25,'expand','shrink',2,2);
	$main_table->attach ($generate, 6, 9, 24,25,'expand','shrink',2,2);
		
	#check soc status every 0.5 second. referesh device table if there is any changes 
	Glib::Timeout->add (100, sub{ 	 
		my ($state,$timeout)= get_gui_status($emulate);
		
		if ($timeout>0){
			$timeout--;
			set_gui_status($emulate,$state,$timeout);	
			return TRUE;
		}
		if($state eq "ideal"){
			return TRUE;
			 
		}
		elsif($state eq 'ref_set_win'){
			my $s=$emulate->object_get_attribute("active_setting",undef);
			$set_win->destroy();
			$emulate->object_add_attribute("active_setting",undef,$s);				
		}
		
		#refresh GUI
		my $name=$emulate->object_get_attribute ("emulate_name",undef);	
		$entry->set_text($name) if(defined $name);
		$conf_box->destroy();
		$set_win->destroy();
		$chart->destroy();
		$image->destroy(); 
		$image = get_status_gif($emulate);
		($conf_box,$set_win)=process_notebook_gen($emulate,\$info,"emulate", @charts);
		$chart   =gen_multiple_charts  ($emulate,\@pages,\@charts);
		$v1 -> pack1($conf_box, TRUE, TRUE); 	
		$v1 -> pack2($image, TRUE, TRUE); 
		$v2 -> pack2($chart, TRUE, TRUE); 
		$conf_box->show_all();
		$main_table->show_all();
		set_gui_status($emulate,"ideal",0);
		
		return TRUE;
		
	} );
		
		
	$generate-> signal_connect("clicked" => sub{ 
		my @samples =$emulate->object_get_attribute_order("samples");
		foreach my $sample (@samples){
			$emulate->object_add_attribute ($sample,"status","run");	
		}
		run_emulator($emulate,\$info);
	});


	$open-> signal_connect("clicked" => sub{ 
		load_emulation($emulate,\$info);
		set_gui_status($emulate,"ref",5);
	});	

	$save-> signal_connect("clicked" => sub{ 
		save_emulation($emulate);		
		set_gui_status($emulate,"ref",5);
	});	

	my $sc_win = new Gtk2::ScrolledWindow (undef, undef);
	$sc_win->set_policy( "automatic", "automatic" );
	$sc_win->add_with_viewport($main_table);	

	return $sc_win;
}



