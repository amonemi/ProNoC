#! /usr/bin/perl -w
use Glib qw/TRUE FALSE/;
use strict;
use warnings;
use soc;
#use ip;
#use interface;
#use POSIX 'strtol';

use File::Path;
use File::Find::Rule;
use File::Copy;
use File::Copy::Recursive qw(dircopy);
use Cwd 'abs_path';
use Verilog::EditFiles;

use Gtk2;
#use Gtk2::Pango;

use List::MoreUtils qw( minmax );



################
#	Comile
#################



sub is_capital_sensitive()
{
  my ($cell_layout, $cell, $tree_model, $iter, $data) = @_;
  my $sensitive = !$tree_model->iter_has_child($iter);
  $cell->set('sensitive', $sensitive);
}

sub gen_combo_model{
	my $ref=shift;
	my %inputs=%{$ref};
	my $store = Gtk2::TreeStore->new('Glib::String');
  	 for my $i (sort { $a cmp $b} keys %inputs ) {
    	 	my $iter = $store->append(undef);
		
    	 	$store->set($iter, 0, $i);
    		for my $capital (sort { $a cmp $b} keys %{$inputs{$i}}) {
      			my $iter2 = $store->append($iter);
       			$store->set($iter2, 0, $capital);
    		}
 	}
	return $store;

}

sub gen_tree_combo{
	my $model=shift;
	my $combo = Gtk2::ComboBox->new_with_model($model);
   	my $renderer = Gtk2::CellRendererText->new();
    	$combo->pack_start($renderer, TRUE);
    	$combo->set_attributes($renderer, "text", 0);
    	$combo->set_cell_data_func($renderer, \&is_capital_sensitive);
	return $combo;

}

sub get_range {
	my ($board,$self,$porttype,$assignname,$portrange,$portname) =@_;
	my $box= def_hbox(FALSE,0);
	my @range=$board->board_get_pin_range($porttype,$assignname);
	
	
	if ($range[0] ne '*undefine*'){
		my $content = join(",", @range); 
		my ($min, $max) = minmax @range;
		if  (length($portrange)!=0){
			my $range_hsb=gen_combobox_object($self,'compile_pin_range_hsb',$portname,$content,$max,undef,undef);
			$box->pack_start( $range_hsb, FALSE, FALSE, 0);
			$box->pack_start(gen_label_in_center(':'),, FALSE, FALSE, 0);
		}

		my $range_lsb=gen_combobox_object($self,'compile_pin_range_lsb',$portname,$content,$min,undef,undef);
		$box->pack_start( $range_lsb, FALSE, FALSE, 0);
		
	}
	return $box;

}


sub read_top_v_file{
	my $top_v=shift;
	my $board = soc->board_new(); 
	my $vdb=read_verilog_file($top_v);
	my @modules=sort $vdb->get_modules($top_v);
	my %Ptypes=get_ports_type($vdb,$modules[0]);
	my %Pranges=get_ports_rang($vdb,$modules[0]);
	foreach my $p (sort keys %Ptypes){
		my $Ptype=$Ptypes{$p};
		my $Prange=$Pranges{$p};		
		my $type=($Ptype eq "input")? "Input" : ($Ptype eq "output")? 'Output' : 'Bidir';
		if (  $Prange ne ''){
			my @r=split(":",$Prange);
			my $a=($r[0]<$r[1])? $r[0] : $r[1];
			my $b=($r[0]<$r[1])? $r[1] : $r[0];
			for (my $i=$a; $i<=$b; $i++){
				$board->board_add_pin ($type,"$p\[$i\]");
				
			}			
		}
		else {$board->board_add_pin ($type,$p);}			
	}	
	return $board;
}




sub gen_top_v{
	my ($self,$board,$name,$top)=@_;

	my $top_v=get_license_header("Top.v");
	#read port list 
	my $vdb=read_verilog_file($top);
	my %port_type=get_ports_type($vdb,"${name}_top");
	my %port_range=get_ports_rang($vdb,"${name}_top");
	
	
	my $io='';
	my $io_def='';
	my $io_assign='';
	my %board_io;
	my $first=1;
	foreach my $p (sort keys %port_type){
		my $porttype=$port_type{$p};
		my $portrange=$port_range{$p};
		my $assign_type = $self->object_get_attribute('compile_assign_type',$p);
		my $assign_name = $self->object_get_attribute('compile_pin',$p);
		my $range_hsb   = $self->object_get_attribute('compile_pin_range_hsb',$p);
		my $range_lsb   = $self->object_get_attribute('compile_pin_range_lsb',$p);
		my $assign="\t";
		if (defined $assign_name){
			if($assign_name eq '*VCC'){
				$assign= (length($portrange)!=0)? '{32{1\'b1}}' : '1\'b1';
			} elsif ($assign_name eq '*GND'){
				$assign= (length($portrange)!=0)? '{32{1\'b0}}' : '1\'b0';
			}elsif ($assign_name eq '*NOCONNECT'){ 
				$assign="\t";

			}else{ 
				
				$board_io{$assign_name}=$porttype;
				
				
				my $range = (defined $range_hsb) ? "[$range_hsb : $range_lsb]" : 
					    (defined $range_lsb) ?  "[ $range_lsb]" : " ";
				my $l=(defined $assign_type)? 
					($assign_type eq 'Direct') ? '' : '~' : '';
				$assign="$l $assign_name $range";
			 	
				
			}	
		}
		$io_assign= ($first)? "$io_assign \t  .$p($assign)":"$io_assign,\n \t  .$p($assign)";		
		$first=0;
	}
	$first=1;
	foreach my $p (sort keys %board_io){
			$io=($first)? "\t$p" : "$io,\n\t$p";
			my $dir=$board_io{$p};
			my $range;
			my $type= ($dir eq  'input') ? 'Input' : 
			  	  ($dir eq  'output')? 'Output' : 'Bidir';
			my @r= $board->board_get_pin_range($type,$p);
			if ($r[0] eq '*undefine*'){
				$range="\t\t\t";
			} else {
				my ($min, $max) = minmax @r;
				$range="\t[$max : $min]\t";
			}
			$io_def = "$io_def \t $dir $range $p;\n";
			$first=0;	
		
	}
	$top_v="$top_v 
module Top (
$io
);
$io_def

	${name}_top uut(	
$io_assign
	);


endmodule
";
	my ($fname,$fpath,$fsuffix) = fileparse("$top",qr"\..[^.]*$");
	my $board_top_file= "$fpath/Top.v";
	save_file($board_top_file,$top_v);
}










sub select_compiler {
	my ($self,$name,$top,$target_dir,$end_func)=@_;
	my $window = def_popwin_size(40,40,"Step 1: Select Compiler",'percent');
	#get the list of boards located in "boards/*" folder
	my @dirs = grep {-d} glob("../boards/*");
	my ($fpgas,$init);
	foreach my $dir (@dirs) {
		my ($name,$path,$suffix) = fileparse("$dir",qr"\..[^.]*$");
		$init=$name;
		$fpgas= (defined $fpgas)? "$fpgas,$name" : "$name";		
	}
	my $table = def_table(2, 2, FALSE);
	my $col=0;
	my $row=0;

	my $compilers=$self->object_get_attribute('compile','compilers');#"QuartusII,Verilator,Modelsim"
	
	my $compiler=gen_combobox_object ($self,'compile','type',$compilers,"QuartusII",undef,undef);
	$table->attach(gen_label_in_center("Compiler tool"),$col,$col+1,$row,$row+1,'fill','shrink',2,2);$col++;
	$table->attach($compiler,$col,$col+1,$row,$row+1,'fill','shrink',2,2);$col++;
	$row++;$col=0;
	
	
	
	my $old_board_name=$self->object_get_attribute('compile','board');
	my $old_compiler=$self->object_get_attribute('compile','type');
	my $compiler_options = ($old_compiler eq "QuartusII")? select_board  ($self,$name,$top,$target_dir): 
			       ($old_compiler eq "Modelsim")?  select_model_path  ($self,$name,$top,$target_dir): 
								gen_label_in_center(" ");
	$table->attach($compiler_options,$col,$col+2,$row,$row+1,'fill','shrink',2,2); $row++;

	$col=1;
	my $i;	
	for ($i=$row; $i<5; $i++){
		
		my $temp=gen_label_in_center(" ");
		$table->attach_defaults ($temp, 0, 1 , $i, $i+1);
	}
	$row=$i;	
		

	$window->add ($table);
	$window->show_all();
	my $next=def_image_button('icons/right.png','Next');
	$table->attach($next,$col,$col+1,$row,$row+1,'shrink','shrink',2,2);$col++;
	$next-> signal_connect("clicked" => sub{
		my $compiler_type=$self->object_get_attribute('compile','type');
		if($compiler_type eq "QuartusII"){
			my $new_board_name=$self->object_get_attribute('compile','board');
			if(defined $old_board_name) {
				if ($old_board_name ne $new_board_name){
					remove_pin_assignment($self); 
					my ($fname,$fpath,$fsuffix) = fileparse("$top",qr"\..[^.]*$");
					#delete jtag_intfc.sh file
					unlink "${fpath}../sw/jtag_intfc.sh";
					#program_device.sh file  
					unlink "${fpath}../program_device.sh";
				}

				my ($fname,$fpath,$fsuffix) = fileparse("$top",qr"\..[^.]*$");
				my $board_top_file= "$fpath/Top.v";
				unlink $board_top_file if ($old_board_name ne $new_board_name);


			}
			if($new_board_name eq "Add New Board") {add_new_fpga_board($self,$name,$top,$target_dir,$end_func);}
			else {get_pin_assignment($self,$name,$top,$target_dir,$end_func);}
		}elsif($compiler_type eq "Modelsim"){
			modelsim_compilation($self,$name,$top,$target_dir);

		}else{#verilator
			verilator_compilation_win($self,$name,$top,$target_dir);

		}

		$window->destroy;
		
	});

	$compiler->signal_connect("changed" => sub{
		$compiler_options->destroy;
		my $new_board_name=$self->object_get_attribute('compile','type');
		$compiler_options = ($new_board_name eq "QuartusII")? select_board  ($self,$name,$top,$target_dir):
				    ($new_board_name eq "Modelsim")?  select_model_path  ($self,$name,$top,$target_dir):
				 gen_label_in_center(" ");
		$table->attach($compiler_options,0,2,1,2,'fill','shrink',2,2); 	
		$table->show_all;

	});

}





sub select_board {
	my ($self,$name,$top,$target_dir)=@_;
	
	#get the list of boards located in "boards/*" folder
	my @dirs = grep {-d} glob("../boards/*");
	my ($fpgas,$init);
	$fpgas="Add New Board";
	
	foreach my $dir (@dirs) {
		my ($name,$path,$suffix) = fileparse("$dir",qr"\..[^.]*$");
		
		$fpgas= (defined $fpgas)? "$fpgas,$name" : "$name";	
		$init="$name";	
	}
	my $table = def_table(2, 2, FALSE);
	my $col=0;
	my $row=0;

	
	my $old_board_name=$self->object_get_attribute('compile','board');
	$table->attach(gen_label_help("The list of supported boards are obtained from \"mpsoc/boards/\" path. You can add your boards by adding its required files in aformentioned path. Note that currently only Altera FPGAs are supported. For boards from other vendors, you need to directly use their own compiler and call $name.v file in your top level module.",'Targeted Board:'),$col,$col+1,$row,$row+1,'fill','shrink',2,2);$col++;
	$table->attach(gen_combobox_object ($self,'compile','board',$fpgas,$init,undef,undef),$col,$col+1,$row,$row+1,'fill','shrink',2,2);$row++;
	
	my $bin = $self->object_get_attribute('compile','quartus_bin');
	my $Quartus_bin=  $ENV{QUARTUS_BIN};
	$col=0;
	$self->object_add_attribute('compile','quartus_bin',$ENV{QUARTUS_BIN}) if (!defined $bin && defined $Quartus_bin);
	$table->attach(gen_label_help("Path to quartus/bin directory. You can set a default path as QUARTUS_BIN envirement variable in ~/.bashrc file.
e.g:  export QUARTUS_BIN=/home/alireza/altera/13.0sp1/quartus/bin",'Quartus  bin:'),$col,$col+1,$row,$row+1,'fill','shrink',2,2);$col++;
	$table->attach(get_dir_in_object ($self,'compile','quartus_bin',undef,undef,undef),$col,$col+1,$row,$row+1,'fill','shrink',2,2);$row++;
	
	return $table;
	
}

sub select_model_path {
	my ($self,$name,$top,$target_dir)=@_;
	
	
	my $table = def_table(2, 2, FALSE);
	my $col=0;
	my $row=0;

	
	
	
	my $bin = $self->object_get_attribute('compile','modelsim_bin');
	my $modelsim_bin=  $ENV{MODELSIM_BIN};
	$col=0;
	$self->object_add_attribute('compile','modelsim_bin',$modelsim_bin) if (!defined $bin && defined $modelsim_bin);
	$table->attach(gen_label_help("Path to modelsim/bin directory. You can set a default path as MODELSIM_BIN envirement variable in ~/.bashrc file.
e.g.  export MODELSIM_BIN=/home/alireza/altera/modeltech/bin",'Modelsim  bin:'),$col,$col+1,$row,$row+1,'fill','shrink',2,2);$col++;
	$table->attach(get_dir_in_object ($self,'compile','modelsim_bin',undef,undef,undef),$col,$col+1,$row,$row+1,'fill','shrink',2,2);$row++;
	
	return $table;
	
}


sub remove_pin_assignment{
	my $self=shift;
	$self->object_remove_attribute('compile_pin_pos');
	$self->object_remove_attribute('compile_pin');
	$self->object_remove_attribute('compile_assign_type');
	$self->object_remove_attribute('compile_pin_range_hsb');
	$self->object_remove_attribute('compile_pin_range_lsb');
}





sub add_new_fpga_board{
	my ($self,$name,$top,$target_dir,$end_func)=@_;	
	my $window = def_popwin_size(50,80,"Add New FPGA Board",'percent');
	my $table = def_table(2, 2, FALSE);
	my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);
	$scrolled_win->set_policy( "automatic", "automatic" );
	$scrolled_win->add_with_viewport($table);


	my $mtable = def_table(10, 10, FALSE);
	
	my $next=def_image_button('icons/plus.png','Add');
	my $back=def_image_button('icons/left.png','Previous');	
    my $auto=def_image_button('icons/advance.png','Auto-fill');	

	$mtable->attach_defaults($scrolled_win,0,10,0,9);
	$mtable->attach($back,2,3,9,10,'shrink','shrink',2,2);
	$mtable->attach($auto,5,6,9,10,'shrink','shrink',2,2);
	$mtable->attach($next,8,9,9,10,'shrink','shrink',2,2);
	
	set_tip($auto, "Auto-fill JTAG configuration. The board must be powered on and be connecred to the PC.");
	
	
	
	my $widgets= add_new_fpga_board_widgets($self,$name,$top,$target_dir,$end_func);
	my ($Twin,$tview)=create_text();
	add_colors_to_textview($tview);

	my $v1=gen_vpaned($widgets,0.3,$Twin);
	
	$table->attach_defaults($v1,0,3,0,2); 
	#$table->attach_defaults( $Twin,0,3,1,2); 	
	
		
	
	
	$back-> signal_connect("clicked" => sub{ 
		
		$window->destroy;
		select_compiler($self,$name,$top,$target_dir,$end_func);
		
	});
	
	$next-> signal_connect("clicked" => sub{ 
		my $result = add_new_fpga_board_files($self);
		if(! defined $result ){
			select_compiler($self,$name,$top,$target_dir,$end_func);
			message_dialog("The new board has been added successfully!");
			
			$window->destroy;
			
		}else {
			show_info(\$tview," ");
			show_colored_info(\$tview,$result,'red');			
			
		}
	
		
		
	});
	
	$auto-> signal_connect("clicked" => sub{ 
		my $pid;
		my $hw;
		my $dir = Cwd::getcwd();
		my $project_dir	  = abs_path("$dir/../../"); #mpsoc directory address		
		my $command=  "$project_dir/mpsoc/src_c/jtag/jtag_libusb/list_usb_dev";
		add_info(\$tview,"$command\n");
		my ($stdout,$exit,$stderr)=run_cmd_in_back_ground_get_stdout($command);
		if(length $stderr>1){			
			add_colored_info(\$tview,"$stderr\n",'red');
			add_colored_info(\$tview,"$command was not run successfully!\n",'red');
		}else {

			if($exit){
				add_colored_info(\$tview,"$stdout\n",'red');
				add_colored_info(\$tview,"$command was not run successfully!\n",'red');
			}else{
				add_info(\$tview,"$stdout\n");
				my @a=split /vid=9fb/, $stdout; 
				if(defined $a[1]){
					my @b=split /pid=/, $a[1]; 
					my @c=split /\n/, $b[1]; 
					$pid=$c[0]; 
					$self->object_add_attribute('compile','quartus_pid',$pid);
					add_colored_info(\$tview,"Detected PID: $pid\n",'blue');
					
				}else{
					add_colored_info(\$tview,"The Altera vendor ID of 9fb is not detected. Make sure You have connected your Altera board to your USB port\n",'red');
					return;
				}
			}
		}
		
		
		$command=  "$ENV{QUARTUS_BIN}/jtagconfig";
		add_info(\$tview,"$command\n");
		($stdout,$exit,$stderr)=run_cmd_in_back_ground_get_stdout($command);
		if(length $stderr>1){			
			add_colored_info(\$tview,"$stderr\n",'red');
			add_colored_info(\$tview,"$command was not run successfully!\n",'red');
		}else {

			if($exit){
				add_colored_info(\$tview,"$stdout\n",'red');
				add_colored_info(\$tview,"$command was not run successfully!\n",'red');
			}else{
				add_info(\$tview,"$stdout\n");
				my @a=split /1\)\s+/, $stdout; 
				if(defined $a[1]){
					my @b=split /\s+/, $a[1]; 
					$hw=$b[0];
					$self->object_add_attribute('compile','quartus_hardware',$hw);
					add_colored_info(\$tview,"Detected Hardware: $hw\n",'blue');
					my $qsf=$self->object_get_attribute('compile','quartus_qsf');	
					if(!defined $qsf ){
						add_colored_info (\$tview,"Cannot detect devce location in JTAG chin. Please enter the QSF file or fill in manually \n",'red'); 
										
					}else{
						#search for device nam ein qsf file
						$qsf=add_project_dir_to_addr($qsf);
						if (!(-f $qsf)){
							add_colored_info (\$tview, "Error Could not find $qsf file!\n");
							return;
						}
						my $str=load_file($qsf);
						my $dw= capture_string_between(' DEVICE ',$str,"\n");
						if(defined $dw){
					    	add_colored_info(\$tview,"Device name in qsf file is: $dw\n",'blue');
					    	@b=split /\n/, $a[1];
					    	
					    	#capture device name in JTAG chain
							my @f=(0);
							foreach my $c (@b){
								my @e=split /\s+/, $c;
								push(@f,$e[2]) if(defined $e[2]);
							} 
							
							my $pos=find_the_most_similar_position($dw ,@f);
							$self->object_add_attribute('compile','quartus_device',$pos);
					    	add_colored_info(\$tview,"$dw has the most similarity with $f[$pos] in JTAG chain\n",'blue');
	
						
					    }else{
					    	add_colored_info (\$tview, "Could not find device name in the $qsf file!\n");
					    }
						
					}
					
					
				}else{
					#add_colored_info(\$tview,"The Altera vendor ID of 9fb is not detected. Make sure You have connected your Altera board to your USB port\n",'red');
				
				}
				
			}
		}
		$widgets->destroy();
		$widgets= add_new_fpga_board_widgets($self,$name,$top,$target_dir,$end_func);
		$v1-> pack1($widgets, TRUE, TRUE); 	
		#$table->attach_defaults($widgets,0,3,0,1); 
		$table->show_all();		
	 #	my $cmd=" $ENV{'QUARTUS_BIN'}"
	 	
	});
		
		
	
	$window->add ($mtable);
	$window->show_all();
	
}










sub add_new_fpga_board_widgets{
	my ($self,$name,$top,$target_dir,$end_func)=@_;	
	my $table = def_table(2, 2, FALSE);
		
	my $help1="FPGA Board name. Do not use any space in given name";
	my $help2="Path to FPGA board qsf file. In your Altra board installation CD or in the Internet search for a QSF file containing your FPGA device name with other necessary global project setting including the pin assignments (e.g DE10_Nano_golden_top.qsf).";
	my $help3="Path to FPGA_board_top.v file. In your Altra board installation CD or in the Internet search for a verilog file containing all your FPGA device IO ports (e.g DE10_Nano_golden_top.v).";
	my $help4="FPGA Borad USB-Blaster product ID (PID). Power on your FPGA board and connect it to your PC. Then press Auto-fill button to find PID. Optinally you can run mpsoc/
src_c/jtag/jtag_libusb/list_usb_dev to find your USB-Blaster PID. Search for PID of a device having 9fb (altera) Vendor ID (VID)";
	my $help5="Power on your FPGA board and connect it to your PC. Then press Auto-fill button to find your hardware name. Optinally you can run \$QUARTUS_BIN/jtagconfig to find your programming hardware name. 
an example of output from the 'jtagconfig' command:
\t  1) ByteBlasterMV on LPT1
\t       090010DD   EPXA10
\t       049220DD   EPXA_ARM922
or
\t   1) DE-SoC [1-3]
\t       48A00477   SOCVHP5 
\t       02D020DC   5CS(EBA6ES|XFC6c6ES)   
ByteBlasterMV \& DE-SoC are the programming hardware name.";
my $help6="Power on your FPGA board and connect it to your PC. Then press Auto-fill button to find your devive location in jtag chain. Optinally you can run \$QUARTUS_BIN/jtagconfig to find your target device location in jtag chain."; 
		   



	my @info = (
	{ label=>"FPGA Borad name:",                   param_name=>'quartus_board', type=>"Entry",     default_val=>undef, content=>undef, info=>$help1, param_parent=>'compile', ref_delay=> undef},
  	{ label=>'FPGA board golden top QSF file:',    param_name=>'quartus_qsf',   type=>"FILE_path", default_val=>undef, content=>"qsf", info=>$help2, param_parent=>'compile', ref_delay=>undef},
	{ label=>"FPGA board golden top verilog file", param_name=>'quartus_v',     type=>"FILE_path", default_val=>undef, content=>"v", info=>$help3, param_parent=>'compile',ref_delay=>undef },
	);
	
	my @usb = (
	{ label=>"FPGA Borad USB Blaster PID:",        param_name=>'quartus_pid',   type=>"Entry",     default_val=>undef, content=>undef, info=>$help4, param_parent=>'compile', ref_delay=> undef},
	{ label=>"FPGA Borad Programming Hardware Name:", param_name=>'quartus_hardware',   type=>"Entry",     default_val=>undef, content=>undef, info=>$help5, param_parent=>'compile', ref_delay=> undef},
	{ label=>"FPGA Borad Device location in JTAG chain:", param_name=>'quartus_device',   type=>"Spin-button",     default_val=>0, content=>"0,100,1", info=>$help6, param_parent=>'compile', ref_delay=> undef},
	);	
	
	
	my $col=0;
	my $row=0;
	foreach my $d (@info) {
		($row,$col)=add_param_widget ($self, $d->{label}, $d->{param_name}, $d->{default_val}, $d->{type}, $d->{content}, $d->{info}, $table,$row,$col,1, $d->{param_parent}, $d->{ref_delay},undef,"vertical");
	}
	
	my $labl=def_pack_vbox(FALSE, 0,(Gtk2::HSeparator->new,gen_label_in_center("FPGA Board JTAG Configuration"),Gtk2::HSeparator->new));
		
	$table->attach( $labl,0,3,$row,$row+1,'fill','shrink',2,2); $row++; $col=0;
	
	foreach my $d (@usb) {
		($row,$col)=add_param_widget ($self, $d->{label}, $d->{param_name}, $d->{default_val}, $d->{type}, $d->{content}, $d->{info}, $table,$row,$col,1, $d->{param_parent}, $d->{ref_delay},undef,"vertical");
	}
	
	
	return ($row, $col, $table);	
}





sub add_new_fpga_board_files{
	my $self=shift;
	
	#check the board name
	my $board_name=$self->object_get_attribute('compile','quartus_board');
	return "Please define the Board Name\n" if(! defined $board_name ); 
	return "Please define the Board Name\n" if(length($board_name) ==0 ); 
	my $r=check_verilog_identifier_syntax($board_name);	
	return "Error in given Board Name: $r\n" if(defined $r ); 
	
	#check qsf file 
	my $qsf=$self->object_get_attribute('compile','quartus_qsf');	
	return "Please define the QSF file\n" if(!defined $qsf );
	
	#check v file 
	my $top=$self->object_get_attribute('compile','quartus_v');
	return "Please define the verilog file file\n" if(!defined $top );
	
	#check PID
	my $pid=$self->object_get_attribute('compile','quartus_pid');
	return "Please define the PID\n" if(! defined $pid ); 
	return "Please define the PID\n" if(length($pid) ==0 ); 
	
	#check Hardware name
	my $hw=$self->object_get_attribute('compile','quartus_hardware');
	return "Please define the Hardware Name\n" if(! defined $hw ); 
	return "Please define the Hardware Name\n" if(length($hw) ==0 ); 
	
	
	#check Device name name
	my $dw=$self->object_get_attribute('compile','quartus_device');
	return "Please define targeted Device location in JTAG chain. The device location must be larger than zero.\n" if( $dw == 0 ); 
	
	
	
	#make board directory
	my $dir = Cwd::getcwd();
	my $path="$dir/../boards/$board_name";
	mkpath($path,1,01777);
	return "Error cannot make $path path" if ((-d $path)==0);
	
	#generate new qsf file
	$qsf=add_project_dir_to_addr($qsf);
	$top=add_project_dir_to_addr($top);
	open my $file, "<", $qsf or return "Error Could not open $qsf file in read mode!";
	open my $newqsf, ">", "$path/$board_name.qsf" or return "Error Could not create $path/$board_name.qsf file in write mode!";
	
	#remove the lines contain following strings
	my @p=("TOP_LEVEL_ENTITY","VERILOG_FILE","SYSTEMVERILOG_FILE","VHDL_FILE","AHDL_FILE","PROJECT_OUTPUT_DIRECTORY" );
	while (my $line = <$file>){
		if ($line =~ /\Q$p[0]\E/ || $line =~ /\Q$p[1]\E/ || $line =~ /\Q$p[2]\E/ ||  $line =~ /\Q$p[3]\E/ ||  $line =~ /\Q$p[4]\E/){#dont copy the line contain TOP_LEVEL_ENTITY
		
		}
		
		else{			
			print $newqsf $line;
		}
		
	}
	print $newqsf "\nset_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files\n";

	close $newqsf;
	close $file;
	copy($top,"$path/$board_name.v");
	
	#generate jtag_intfc.sh
	open $file, ">", "$path/jtag_intfc.sh" or return "Error: Could not create $path/jtag_intfc.sh file in write mode!";
	my $jtag;
	if($pid eq 6001 || $pid eq 6002 || $pid eq 6003){
		$jtag="JTAG_INTFC=\"\$PRONOC_WORK/toolchain/bin/jtag_libusb -a \$PRODUCT_ID\"";	
		
	}else{
		$jtag="JTAG_INTFC=\"\$PRONOC_WORK/toolchain/bin/jtag_quartus_stp -a \$HARDWARE_NAME -b \$DEVICE_NAME\"";
		
	}
	print $file "#!/bin/sh

PRODUCT_ID=\"0x$pid\" 
HARDWARE_NAME=\'$hw *\'
DEVICE_NAME=\"\@$dw*\" 
	
$jtag
		
	";	
	close $file;
	
	
	#generate program_device.sh
	open $file, ">", "$path/program_device.sh" or return "Error: Could not create $path/program_device.sh file in write mode!";
	
	
print $file "#!/bin/sh

#usage: 
#	sh program_device.sh  programming_file.sof

#programming file 
#given as an argument:  \$1

#Programming mode
PROG_MODE=jtag

#cable name. Connect the board to ur PC and then run jtagconfig in terminal to find the cable name
NAME=\"$hw\"

#device name
DEVICE=\@$dw".'


#programming command
if [ -n "${QUARTUS_BIN+set}" ]; then
  $QUARTUS_BIN/quartus_pgm -m $PROG_MODE -c "$NAME" -o "p;${1}${DEVICE}"
else
  quartus_pgm -m $PROG_MODE -c "$NAME" -o "p;${1}${DEVICE}"
fi
';	
	
close $file;	
$self->object_add_attribute('compile','board',$board_name);		
	
	return undef;
}

sub  get_pin_assignment{
	my ($self,$name,$top,$target_dir,$end_func)=@_;	
	my $window = def_popwin_size(80,80,"Step 2: Pin Assignment",'percent');

	my $table = def_table(2, 2, FALSE);
	my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);
	$scrolled_win->set_policy( "automatic", "automatic" );
	$scrolled_win->add_with_viewport($table);


	my $mtable = def_table(10, 10, FALSE);
	
	my $next=def_image_button('icons/right.png','Next');
	my $back=def_image_button('icons/left.png','Previous');	


	$mtable->attach_defaults($scrolled_win,0,10,0,9);
	$mtable->attach($back,2,3,9,10,'shrink','shrink',2,2);
	$mtable->attach($next,8,9,9,10,'shrink','shrink',2,2);

	


	
	my $board_name=$self->object_get_attribute('compile','board');
	#copy board jtag_intfc.sh file 
	my ($fname,$fpath,$fsuffix) = fileparse("$top",qr"\..[^.]*$");
	copy("../boards/$board_name/jtag_intfc.sh","${fpath}../sw/jtag_intfc.sh");

	#copy board program_device.sh file 
	copy("../boards/$board_name/program_device.sh","${fpath}../program_device.sh");

	#get boards pin list
	my $top_v= "../boards/$board_name/$board_name.v";
	if(!-f $top_v){
		message_dialog("Error: Could not load the board pin list. The $top_v does not exist!");
		$window->destroy;
	}
	
	my $board=read_top_v_file($top_v);

	# Write object file
	#open(FILE,  ">lib/soc/tttttttt") || die "Can not open: $!";
	#print FILE Data::Dumper->Dump([\%$board],['board']);
	#close(FILE) || die "Error closing file: $!";

	my @dirs = ('Input', 'Bidir', 'Output');
	my %models;
	foreach my $p (@dirs){
		my %pins=$board->board_get_pin($p);
		$models{$p}=gen_combo_model(\%pins);
		
	}
	
	my $row=0;
	my $col=0;
	my @lables= ('Port Direction','Port Range     ','Port name      ','Assigment Type','Board Port name ','Board Port Range');
	foreach my $p (@lables){
		my $l=gen_label_in_left($p);		
		$l->set_markup("<b>  $p    </b>");
		$table->attach ($l, $col,$col+1, $row, $row+1,'fill','shrink',2,2); 
		$col++
	}
	$row++;


	#read port list 
	my $vdb=read_verilog_file($top);
	my %port_type=get_ports_type($vdb,"${name}_top");
	my %port_range=get_ports_rang($vdb,"${name}_top");
	my %param = $vdb->get_modules_parameters("${name}_top");
	
	foreach my $p (sort keys %port_type){
		my $porttype=$port_type{$p};
		my $portrange=$port_range{$p};

		if  (length($portrange)!=0){	
			#replace parameter with their values		
			my @a= split (/\b/,$portrange);
			foreach my $l (@a){
				my $value=$param{$l};
				if(defined $value){
					chomp $value;
					($portrange=$portrange)=~ s/\b$l\b/$value/g      if(defined $param{$l});
				}
			}
			$portrange = "[ $portrange ]" ;
		}	
		
		my $label1= gen_label_in_left("  $porttype");
		my $label2= gen_label_in_left("  $portrange");
		my $label3= gen_label_in_left("  $p");

		$table->attach($label1, 0,1, $row, $row+1,'fill','shrink',2,2);
		$table->attach($label2, 1,2, $row, $row+1,'fill','shrink',2,2); 
		$table->attach($label3, 2,3, $row, $row+1,'fill','shrink',2,2); 
		
		my $assign_type= "Direct,Negate(~)";
		if ($porttype eq  'input') {
			my $assign_combo=gen_combobox_object($self,'compile_assign_type',$p,$assign_type,'Direct',undef,undef);
			$table->attach( $assign_combo, 3,4, $row, $row+1,'fill','shrink',2,2); 
		}

		my $type= ($porttype eq  'input') ? 'Input' : 
			  ($porttype eq  'output')? 'Output' : 'Bidir';

		my $combo= gen_tree_combo($models{$type});
		my $saved=$self->object_get_attribute('compile_pin_pos',$p);
		my $box;
		my $loc=$row;
		if(defined $saved) {
			  my @indices=@{$saved};
			  my $path = Gtk2::TreePath->new_from_indices(@indices);
			  my $iter = $models{$type}->get_iter($path);
    			  undef $path;
    			  $combo->set_active_iter($iter);
			  $box->destroy if(defined $box);
			  my $text=$self->object_get_attribute('compile_pin',$p);
			  $box=get_range ($board,$self,$type,$text,$portrange,$p);
			  $table->attach($box, 5,6, $loc, $loc+1,'fill','shrink',2,2);			 
		}
		
		
		
		
    		$combo->signal_connect("changed" => sub{ 
			
			#get and saved new value
			my $treeiter=  $combo->get_active_iter();
			my $text = $models{$type}->get_value($treeiter, 0);
			$self->object_add_attribute('compile_pin',$p,$text);
			#get and saved value position in model
			my $treepath = $models{$type}->get_path ($treeiter);
			my @indices=   $treepath->get_indices();
			$self->object_add_attribute('compile_pin_pos',$p,\@indices);
			#update borad port range
			$box->destroy if(defined $box);
			$box=get_range ($board,$self,$type,$text,$portrange,$p);
			$table->attach($box, 5,6, $loc, $loc+1,'fill','shrink',2,2);
			$table->show_all;

		});
   		
    		$table->attach($combo, 4,5, $row, $row+1,'fill','shrink',2,2); 

    		





		$row++;

	}
	$next-> signal_connect("clicked" => sub{ 
		
		$window->destroy;
		quartus_compilation($self,$board,$name,$top,$target_dir,$end_func);
		
	});
	$back-> signal_connect("clicked" => sub{ 
		
		$window->destroy;
		select_compiler($self,$name,$top,$target_dir,$end_func);
		
	});


	$window->add ($mtable);
	$window->show_all();
}





sub quartus_compilation{
	my ($self,$board,$name,$top,$target_dir,$end_func)=@_;
	
	my $run=def_image_button('icons/gate.png','Compile');
	my $back=def_image_button('icons/left.png','Previous');	
	my $regen=def_image_button('icons/refresh.png','Regenerate Top.v');	
	my $prog=def_image_button('icons/write.png','Program the board');	


	my ($fname,$fpath,$fsuffix) = fileparse("$top",qr"\..[^.]*$");
	my $board_top_file ="${fpath}Top.v";
	unless (-e $board_top_file ){ 
		gen_top_v($self,$board,$name,$top) ;		
	}

	my ($app,$table,$tview,$window) = software_main($fpath,'Top.v');
	$table->attach($back,1,2,1,2,'shrink','shrink',2,2);
	$table->attach($regen,4,5,1,2,'shrink','shrink',2,2);
	$table->attach ($run,7, 8, 1,2,'shrink','shrink',2,2);
	$table->attach($prog,9,10,1,2,'shrink','shrink',2,2);

	
	
	$regen-> signal_connect("clicked" => sub{
		my $dialog = Gtk2::MessageDialog->new (my $window,
                                      'destroy-with-parent',
                                      'question', # message type
                                      'yes-no', # which set of buttons?
                                      "Are you sure you want to regenaret the Top.v file? Note that any changes you have made will be lost");
  		my $response = $dialog->run;
  		if ($response eq 'yes') {
      			gen_top_v($self,$board,$name,$top);
			$app->load_source("$board_top_file");	
  		}
  		$dialog->destroy;
		
	});
	
	
	
	$back-> signal_connect("clicked" => sub{ 
		
		$window->destroy;
		get_pin_assignment($self,$name,$top,$target_dir);
		
	});


	#compile
	$run-> signal_connect("clicked" => sub{ 
		set_gui_status($self,'save_project',1);
		$app->do_save();
		my $error = 0;
		add_info(\$tview,"CREATE: start creating Quartus project in $target_dir\n");

		#get list of source file
		add_info(\$tview,"        Read the list of all source files $target_dir/src_verilog\n");
		my @files = File::Find::Rule->file()
                            ->name( '*.v','*.V','*.sv' )
                            ->in( "$target_dir/src_verilog" );

		#make sure source files have key word 'module' 
		my @sources;
		foreach my $p (@files){
			push (@sources,$p)	if(check_file_has_string($p,'module')); 
		}
		my $files = join ("\n",@sources);
		add_info(\$tview,"$files\n");

		#creat project qsf file
		my $qsf_file="$target_dir/${name}.qsf";
		save_file ($qsf_file,"# Generated using ProNoC\n");

		#append global assignets to qsf file
		my $board_name=$self->object_get_attribute('compile','board');
		my @qsfs =   glob("../boards/$board_name/*.qsf");
		if(!defined $qsfs[0]){
			message_dialog("Error: ../boards/$board_name folder does not contain the qsf file.!");
			$window->destroy;
		}


		my $assignment_file =  $qsfs[0];
		
		if(-f $assignment_file){
			merg_files ($assignment_file,$qsf_file);
		}
		

		#add the list of source fils to qsf file
		my $s="\n\n\n set_global_assignment -name TOP_LEVEL_ENTITY Top\n";
		foreach my $p (@sources){
			my ($name,$path,$suffix) = fileparse("$p",qr"\..[^.]*$");
			$s="$s set_global_assignment -name VERILOG_FILE $p\n" if ($suffix eq ".v");
			$s="$s set_global_assignment -name SYSTEMVERILOG_FILE $p\n" if ($suffix eq ".sv");
			
		}
		append_text_to_file($qsf_file,$s);
		add_info(\$tview,"\n Qsf file has been created\n");

		#start compilation
		my $Quartus_bin= $self->object_get_attribute('compile','quartus_bin');;
		add_info(\$tview, "Start Quartus compilation.....\n");
		my @compilation_command =(
			"cd \"$target_dir/\" \n xterm -e sh -c '$Quartus_bin/quartus_map --64bit $name --read_settings_files=on; echo \$? > status' ",
			"cd \"$target_dir/\" \n xterm -e sh -c '$Quartus_bin/quartus_fit --64bit $name --read_settings_files=on; echo \$? > status' ",
			"cd \"$target_dir/\" \n xterm -e sh -c '$Quartus_bin/quartus_asm --64bit $name --read_settings_files=on; echo \$? > status' ",
			"cd \"$target_dir/\" \n xterm -e sh -c '$Quartus_bin/quartus_sta --64bit $name;echo \$? > status' ");
		
		foreach my $cmd (@compilation_command){
			add_info(\$tview,"$cmd\n");
			unlink "$target_dir/status";
			my ($stdout,$exit)=run_cmd_in_back_ground_get_stdout( $cmd);
			open(my $fh,  "<$target_dir/status") || die "Can not open: $!";
			read($fh,my $status,1);
			close($fh);
			if("$status" != "0"){			
				($stdout,$exit)=run_cmd_in_back_ground_get_stdout("cd \"$target_dir/output_files/\" \n grep -h \"Error (\" *");
				add_colored_info(\$tview,"$stdout\n Quartus compilation failed !\n",'red');
				$error=1;
				last;
			}			
		}
		add_colored_info(\$tview,"Quartus compilation is done successfully in $target_dir!\n", 'blue') if($error==0);
		if (defined $end_func){
			if ($error==0){
				$end_func->($self);
				$window->destroy;
			}else {
				message_dialog("Error in Quartus compilation!",'error');	
			}
		}
		
	});


	#Programe the board 
	$prog-> signal_connect("clicked" => sub{ 
		my $error = 0;
		my $sof_file="$target_dir/output_files/${name}.sof";
		my $bash_file="$target_dir/program_device.sh";

		add_info(\$tview,"Programe the board using quartus_pgm and $sof_file file\n");
		#check if the programming file exists
		unless (-f $sof_file) {
			add_colored_info(\$tview,"\tThe $sof_file does not exists! Make sure you have compiled the code successfully.\n", 'red');
			$error=1;
		}
		#check if the program_device.sh file exists
		unless (-f $bash_file) {
			add_colored_info(\$tview,"\tThe $bash_file does not exists! This file veries depend on your target board and must be available inside mpsoc/boards/[board_name].\n", 'red');
			$error=1;
		}
		return if($error);
		my $command = "sh $bash_file $sof_file";
		add_info(\$tview,"$command\n");
		my ($stdout,$exit,$stderr)=run_cmd_in_back_ground_get_stdout($command);
		if(length $stderr>1){			
			add_colored_info(\$tview,"$stderr\n",'red');
			add_colored_info(\$tview,"Board was not programed successfully!\n",'red');
		}else {

			if($exit){
				add_colored_info(\$tview,"$stdout\n",'red');
				add_colored_info(\$tview,"Board was not programed successfully!\n",'red');
			}else{
				add_info(\$tview,"$stdout\n");
				add_colored_info(\$tview,"Board is programed successfully!\n",'blue');

			}
			
		}		
	});
	

}






sub modelsim_compilation{
	my ($self,$name,$top,$target_dir)=@_;
	#my $window = def_popwin_size(80,80,"Step 2: Compile",'percent');
	
	
	my $run=def_image_button('icons/run.png','run');
	my $back=def_image_button('icons/left.png','Previous');	
	my $regen=def_image_button('icons/refresh.png','Regenerate testbench.v');	
	#create testbench.v
	gen_modelsim_soc_testbench ($self,$name,$top,$target_dir) if ((-f "$target_dir/src_verilog/testbench.v")==0);



	my ($app,$table,$tview,$window) = software_main("$target_dir/src_verilog",'testbench.v');
	$table->attach($back,1,2,1,2,'shrink','shrink',2,2);
	$table->attach($regen,4,5,1,2,'shrink','shrink',2,2);
	$table->attach ($run,9, 10, 1,2,'shrink','shrink',0,0);
	
	
	
	$regen-> signal_connect("clicked" => sub{
		my $dialog = Gtk2::MessageDialog->new (my $window,
                                      'destroy-with-parent',
                                      'question', # message type
                                      'yes-no', # which set of buttons?
                                      "Are you sure you want to regenaret the testbench.v file? Note that any changes you have made will be lost");
  		my $response = $dialog->run;
  		if ($response eq 'yes') {
      			gen_modelsim_soc_testbench ($self,$name,$top,$target_dir);
			$app->load_source("$target_dir/src_verilog/testbench.v");	
  		}
  		$dialog->destroy;
		
	});
	
	
	


	
	$back-> signal_connect("clicked" => sub{ 
		
		$window->destroy;
		select_compiler($self,$name,$top,$target_dir);
		
	});
	

	#creat modelsim dir
	add_info(\$tview,"creat Modelsim dir in $target_dir\n");
	my $model="$target_dir/Modelsim";
	rmtree("$model");
	mkpath("$model/rtl_work",1,01777);
	
	#create modelsim.tcl file
my $tcl="#!/usr/bin/tclsh


transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work
";

#Get the list of  all verilog files in src_verilog folder
	add_info(\$tview,"Get the list of all verilog files in src_verilog folder\n");
	my @files = File::Find::Rule->file()
        	->name( '*.v','*.V','*.sv' )
                ->in( "$target_dir/src_verilog" );
#make sure source files have key word 'module' 
	my @sources;
	foreach my $p (@files){
		my ($name,$path,$suffix) = fileparse("$p",qr"\..[^.]*$");
		if(check_file_has_string($p,'module')){
			if ($suffix eq ".sv"){$tcl=$tcl."vlog -sv -work work +incdir+$path \{$p\}\n";}
			else {$tcl=$tcl."vlog -vlog01compat -work work +incdir+$path \{$p\}\n";}
		}	
	}

$tcl="$tcl	
vsim -t 1ps  -L rtl_work -L work -voptargs=\"+acc\"  testbench

add wave *
view structure
view signals
run -all
";
	add_info(\$tview,"Create run.tcl file\n");
	save_file ("$model/run.tcl",$tcl);
	$run -> signal_connect("clicked" => sub{
		set_gui_status($self,'save_project',1);
		$app->do_save();
		my $modelsim_bin= $self->object_get_attribute('compile','modelsim_bin');		
		my $cmd="cd $target_dir; $modelsim_bin/vsim -do $model/run.tcl";
		add_info(\$tview,"$cmd\n");
		my ($stdout,$exit,$stderr)=run_cmd_in_back_ground_get_stdout($cmd);
		if(length $stderr>1){	
			add_colored_info(\$tview,"$stderr\n","red"); 		
			
		}else {
			add_info(\$tview,"$stdout\n");
		}			

	});
	
	#$window->show_all();
}


# source files : $target_dir/src_verilog
# work dir : $target_dir/src_verilog

sub verilator_compilation {
	my ($top_ref,$target_dir,$outtext)=@_;
	
	my %tops = %{$top_ref};
	#creat verilator dir
	add_info(\$outtext,"creat verilator dir in $target_dir\n");
	my $verilator="$target_dir/verilator";
	rmtree("$verilator/rtl_work");
	rmtree("$verilator/processed_rtl");
	mkpath("$verilator/rtl_work/",1,01777);
	mkpath("$verilator/processed_rtl/",1,01777);

	
	#copy all verilog files in rtl_work folder
	add_info(\$outtext,"Copy all verilog files in rtl_work folder\n");
	my @files = File::Find::Rule->file()
        	->name( '*.v','*.V','*.sv','*.vh')
                ->in( "$target_dir/src_verilog" );
	foreach my $file (@files) {
		copy($file,"$verilator/rtl_work/");
	}
	
	@files = File::Find::Rule->file()
        	->name( '*.sv','*.vh' )
            ->in( "$target_dir/src_verilog" );
	foreach my $file (@files) {
		copy($file,"$verilator/processed_rtl");
	}
	
	

	#"split all verilog modules in separate  files"
	add_info(\$outtext,"split all verilog modules in separate files\n");
   	my $split = Verilog::EditFiles->new
       	(outdir => "$verilator/processed_rtl",
        translate_synthesis => 0,
        celldefine => 0,
        );
   	$split->read_and_split(glob("$verilator/rtl_work/*.v"));
   	$split->write_files();
   	$split->read_and_split(glob("$verilator/rtl_work/*.sv"));
   	$split->write_files();
	
   	
	#run verilator
	#my $cmd= "cd \"$verilator/processed_rtl\" \n xterm -e sh -c ' verilator  --cc $name.v --profile-cfuncs --prefix \"Vtop\" -O3  -CFLAGS -O3'";
	foreach my $top (sort keys %tops) {
		my $cmd= "cd \"$verilator/processed_rtl\" \n  verilator  --cc $tops{$top} --profile-cfuncs --prefix \"$top\" -O3  -CFLAGS -O3";
		add_info(\$outtext,"$cmd\n");	
		my ($stdout,$exit,$stderr)=run_cmd_in_back_ground_get_stdout($cmd);
		if(length $stderr>1){			
			add_info(\$outtext,"$stderr\n");
		}else {
			add_info(\$outtext,"$stdout\n");
		}			
	}
	

	#check if verilator model has been generated 
	foreach my $top (sort keys %tops) {
		if (-f "$verilator/processed_rtl/obj_dir/$top.cpp"){#succsess
			#generate makefile
			gen_verilator_makefile($top_ref,"$verilator/processed_rtl/obj_dir/Makefile");
			
		}else {
			return 0;
		}	
	}
	return 1;
}


sub gen_verilator_makefile{
	my ($top_ref,$target_dir) =@_;
	my %tops = %{$top_ref};
	my $p='';
	my $q='';
	my $h='';
	my $l;
	foreach my $top (sort keys %tops) {
		$p = "$p ${top}__ALL.a ";
		$q = "$q\t\$(MAKE) -f ${top}.mk\n"; 
		$h = "$h ${top}.h "; 
		$l = $top;
	}
	
	
	my $make= "
	
default: sim



include $l.mk

lib: 
$q


#######################################################################
# Compile flags

CPPFLAGS += -DVL_DEBUG=1
ifeq (\$(CFG_WITH_CCWARN),yes)	# Local... Else don't burden users
CPPFLAGS += -DVL_THREADED=1
CPPFLAGS += -W -Werror -Wall
endif

#######################################################################
# Linking final exe -- presumes have a sim_main.cpp


sim:	testbench.o \$(VK_GLOBAL_OBJS) $p
	\$(LINK) \$(LDFLAGS) -g \$^ \$(LOADLIBES) \$(LDLIBS) -o testbench \$(LIBS) -Wall -O3 2>&1 | c++filt

testbench.o: testbench.cpp $h

clean:
	rm *.o *.a main	
";



save_file ($target_dir,$make);




}	



sub verilator_compilation_win {
	my ($self,$name,$top,$target_dir)=@_;
	my $window = def_popwin_size(80,80,"Step 2: Compile",'percent');
	my $mtable = def_table(10, 10, FALSE);
	my ($outbox,$outtext)= create_text();
	add_colors_to_textview($outtext);
	my $next=def_image_button('icons/run.png','Next');
	my $back=def_image_button('icons/left.png','Previous');	
	

	$mtable->attach_defaults ($outbox ,0, 10, 4,9);
	$mtable->attach($back,2,3,9,10,'shrink','shrink',2,2);
	$mtable->attach($next,8,9,9,10,'shrink','shrink',2,2);


	
	$back-> signal_connect("clicked" => sub{ 
		
		$window->destroy;
		select_compiler($self,$name,$top,$target_dir);
		
	});
	$next-> signal_connect("clicked" => sub{ 
		
		$window->destroy;
		verilator_testbench($self,$name,$top,$target_dir);
		
	});
	my %tops;
	$tops{"Vtop"}= "$name.v";
	my $result = verilator_compilation (\%tops,$target_dir,$outtext);
	#check if verilator model has been generated 
	if ($result){
		add_colored_info(\$outtext,"Veriator model has been generated successfully!",'blue');
	}else {
		add_colored_info(\$outtext,"Verilator compilation failed!\n","red"); 
		$next->destroy();
	}			


	

	$window->add ($mtable);
	$window->show_all();



}



sub gen_verilator_soc_testbench {
	my ($self,$name,$top,$target_dir)=@_;
	my $verilator="$target_dir/verilator";
	my $dir="$verilator/";
	my $soc_top= $self->soc_get_top ();
	my @intfcs=$soc_top->top_get_intfc_list();
	my %PP;
	my $top_port_info="IO type\t  port_size\t  port_name\n";
	foreach my $intfc (@intfcs){
		my $key= ( $intfc eq 'plug:clk[0]')? 'clk' : 
			 ( $intfc eq 'plug:reset[0]')? 'reset':
			 ( $intfc eq 'plug:enable[0]')? 'en' : 'other';
		my $key1="${key}1";
		my $key0="${key}0";

		my @ports=$soc_top->top_get_intfc_ports_list($intfc);
		foreach my $p (@ports){
			my($inst,$range,$type,$intfc_name,$intfc_port)= $soc_top->top_get_port($p);
			$PP{$key1}= (defined $PP{$key1})? "$PP{$key1} top->$p=1;\n" : "top->$p=1;\n";
			$PP{$key0}= (defined $PP{$key0})? "$PP{$key0} top->$p=0;\n" : "top->$p=0;\n";	
			$top_port_info="$top_port_info $type  $range  top->$p \n";
		}
		

	}
	my $main_c=get_license_header("testbench.cpp");
$main_c="$main_c
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <verilated.h>          // Defines common routines
#include \"Vtop.h\"               // From Verilating \"$name.v\" file

Vtop		 	*top;
/*
$top_port_info
*/

int reset,clk;
unsigned int main_time = 0; // Current simulation time

int main(int argc, char** argv) {
	Verilated::commandArgs(argc, argv);   // Remember args
	top	= new Vtop;

	/********************
	*	initialize input
	*********************/

	$PP{reset1}
	$PP{en1}  
	main_time=0;
	printf(\"Start Simulation\\n\");
	while (!Verilated::gotFinish()) {
	   
		if (main_time >= 10 ) { 
			$PP{reset0}
		}	


		if ((main_time & 1) == 0) {
			$PP{clk1}      // Toggle clock
			// you can change the inputs and read the outputs here in case they are captured at posedge of clock 



		}//if
		else
		{
			$PP{clk0}  
			
		

		}//else
			
		
		main_time ++;		 
		top->eval(); 
		}
	top->final(); 
}

double sc_time_stamp () {       // Called by \$time in Verilog
	return main_time;
}
";
	save_file("$dir/testbench.cpp",$main_c);

	

}


sub gen_modelsim_soc_testbench {
	my ($self,$name,$top,$target_dir)=@_;
	my $dir="$target_dir/src_verilog";
	my $soc_top= $self->object_get_attribute('top_ip',undef);
	my @intfcs=$soc_top->top_get_intfc_list();
	my %PP;
	my $top_port_def="// ${name}.v IO definition \n";
	my $pin_assign;
	my $rst_inputs='';

	#read port list 
	my $vdb=read_verilog_file($top);
	my %param = $vdb->get_modules_parameters("${name}_top");
	
	




	foreach my $intfc (@intfcs){
		my $key= ( $intfc eq 'plug:clk[0]')? 'clk' : 
			 ( $intfc eq 'plug:reset[0]')? 'reset':
			 ( $intfc eq 'plug:enable[0]')? 'en' : 'other';
		my $key1="${key}1";
		my $key0="${key}0";

		my @ports=$soc_top->top_get_intfc_ports_list($intfc);
		my $f=1;
		foreach my $p (@ports){
			my($inst,$range,$type,$intfc_name,$intfc_port)= $soc_top->top_get_port($p);
			
			$PP{$key1}= (defined $PP{$key1})? "$PP{$key1} $p=1;\n" : "$p=1;\n";
			$PP{$key0}= (defined $PP{$key0})? "$PP{$key0} $p=0;\n" : "$p=0;\n";	


			if  (length($range)!=0){	
				#replace parameter with their values		
				my @a= split (/\b/,$range);
				foreach my $l (@a){
					my $value=$param{$l};
					if(defined $value){
						chomp $value;
						($range=$range)=~ s/\b$l\b/$value/g      if(defined $param{$l});
					}
				}
				$range = "[ $range ]" ;
			}	



			if($type eq 'input'){
				$top_port_def="$top_port_def  reg  $range  $p;\n" 
			}else{
				$top_port_def="$top_port_def  wire  $range  $p;\n" 
			}
			$pin_assign=(defined $pin_assign)? "$pin_assign,\n\t\t.$p($p)":  "\t\t.$p($p)";
			$rst_inputs= "$rst_inputs $p=0;\n" if ($key eq 'other' && $type eq 'input' );
		}
		

	}

my $test_v= get_license_header("testbench.v");

$test_v	="$test_v

`timescale	 1ns/1ps

module testbench;

$top_port_def


	$name uut (
$pin_assign
	);

//clock defination
initial begin 
	forever begin 
	#5 $PP{clk0}
	#5 $PP{clk1}
	end	
end



initial begin 
	// reset $name module at the start up
	$PP{reset1}	
	$PP{en1}
	$rst_inputs
	// deasert the reset after 200 ns
	#200
	$PP{reset0}  

	// write your testbench here




end

endmodule
";
	save_file("$dir/testbench.v",$test_v);

	

}

sub verilator_testbench{
	my ($self,$name,$top,$target_dir)=@_;
	my $verilator="$target_dir/verilator";
	my $dir="$verilator";
	gen_verilator_soc_testbench (@_) if((-f "$dir/testbench.cpp")==0); 
	#copy makefile
	#copy("../script/verilator_soc_make", "$verilator/processed_rtl/obj_dir/Makefile"); 
	

	my ($app,$table,$tview,$window) = software_main($dir,'testbench.cpp');


	my $make = def_image_button('icons/gen.png','Compile');
	my $regen=def_image_button('icons/refresh.png','Regenerate Testbench.cpp');	
	my $run = def_image_button('icons/run.png','Run');
	my $back=def_image_button('icons/left.png','Previous');	
	
	$table->attach ($back,1,2,1,2,'shrink','shrink',0,0);
	$table->attach ($regen,3,4,1,2,'shrink','shrink',0,0);
	$table->attach ($make,7, 8, 1,2,'shrink','shrink',0,0);
	$table->attach ($run,9, 10, 1,2,'shrink','shrink',0,0);

	$back-> signal_connect("clicked" => sub{ 
		
		$window->destroy;
		verilator_compilation_win($self,$name,$top,$target_dir);
		
	});

	$regen-> signal_connect("clicked" => sub{
		my $dialog = Gtk2::MessageDialog->new (my $window,
                                      'destroy-with-parent',
                                      'question', # message type
                                      'yes-no', # which set of buttons?
                                      "Are you sure you want to regenaret the testbench.cpp file? Note that any changes you have made will be lost");
  		my $response = $dialog->run;
  		if ($response eq 'yes') {
      			gen_verilator_soc_testbench ($self,$name,$top,$target_dir);
			$app->load_source("$dir/testbench.cpp");	
  		}
  		$dialog->destroy;
		
	});
	
	
	$make -> signal_connect("clicked" => sub{
		$app->do_save();
		copy("$dir/testbench.cpp", "$verilator/processed_rtl/obj_dir/testbench.cpp"); 
		run_make_file("$verilator/processed_rtl/obj_dir/",$tview);	

	});

	$run -> signal_connect("clicked" => sub{
		my $bin="$verilator/processed_rtl/obj_dir/testbench";
		if (-f $bin){
			my $cmd= "cd \"$verilator/processed_rtl/obj_dir/\" \n xterm -e sh -c $bin";
			add_info(\$tview,"$cmd\n");	
			my ($stdout,$exit,$stderr)=run_cmd_in_back_ground_get_stdout($cmd);
			if(length $stderr>1){			
				add_colored_info(\$tview,"$stderr\n",'red');
			}else {
				add_info(\$tview,"$stdout\n");
			}			

		}else{
			add_colored_info(\$tview,"Cannot find $bin executable binary file! make sure you have compiled the testbench successfully\n", 'red')
		}	
	
		});


}


1;
