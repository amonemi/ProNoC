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


sub read_csv_file{
	my $file=shift;
	open(my $fh,  "<$file") || die "Cannot open:$file; $!";

	my $board = soc->board_new(); 
	#read header format
	
	my $header;
	
	while (my $line= <$fh>){
		chomp $line;
		$line=remove_all_white_spaces($line);
		#print "l:$line\n";
		if(length ( $line)!=0){
			if ($line !~ /\#/) {
				$header= $line; 
				last;
			}
			
			
		}
		
	}

	my @headers = split (',',$header);
	my $pin_name_col = get_scolar_pos('To',@headers);
	if(!defined $pin_name_col){
		message_dialog("Error: $file file has an unsupported format!");
		return $board;
	}
	my $direction_col = get_scolar_pos('Direction',@headers);
	
	close $fh;

	#save pins
	open( $fh,  "<$file") || die "Cannot open:$file; $!";

	
	while (my $line= <$fh>){
		chomp $line;
		my @fileds = split (',',$line);
		my $to = $fileds[$pin_name_col];
		my $direction = (defined $direction_col )?  $fileds[$direction_col] : 'Unknown';
		if(defined $direction && length($to)!=0){
			if ($direction eq 'Input' || $direction eq 'Output' || $direction eq 'Bidir'){
				$board->board_add_pin ($fileds[1],$to);
			}elsif($direction eq 'Unknown'){
				$board->board_add_pin ('Input',$to);
				$board->board_add_pin ('Output',$to);
				$board->board_add_pin ('Bidir',$to);

			}
		}

	}
	close $fh;
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
	my ($self,$name,$top,$target_dir)=@_;
	my $window = def_popwin_size(40,40,"Step 1: Select Compiler",'percent');
	#get the list of boards located in "boards/*" folder
	my @dirs = grep {-d} glob("./lib/boards/*");
	my ($fpgas,$init);
	foreach my $dir (@dirs) {
		my ($name,$path,$suffix) = fileparse("$dir",qr"\..[^.]*$");
		$init=$name;
		$fpgas= (defined $fpgas)? "$fpgas,$name" : "$name";		
	}
	my $table = def_table(2, 2, FALSE);
	my $col=0;
	my $row=0;

	my $compiler=gen_combobox_object ($self,'compile','type',"QuartusII,Verilator,Modelsim","QuartusII",undef,undef);
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
				remove_pin_assignment($self) if ($old_board_name ne $new_board_name); 
				my ($fname,$fpath,$fsuffix) = fileparse("$top",qr"\..[^.]*$");
				my $board_top_file= "$fpath/Top.v";
				unlink $board_top_file if ($old_board_name ne $new_board_name);


			}
		
			get_pin_assignment($self,$name,$top,$target_dir);
		}elsif($compiler_type eq "Modelsim"){
			modelsim_compilation($self,$name,$top,$target_dir);

		}else{#verilator
			verilator_compilation($self,$name,$top,$target_dir);

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
	my @dirs = grep {-d} glob("./lib/boards/*");
	my ($fpgas,$init);
	foreach my $dir (@dirs) {
		my ($name,$path,$suffix) = fileparse("$dir",qr"\..[^.]*$");
		$init=$name;
		$fpgas= (defined $fpgas)? "$fpgas,$name" : "$name";		
	}
	my $table = def_table(2, 2, FALSE);
	my $col=0;
	my $row=0;

	
	my $old_board_name=$self->object_get_attribute('compile','board');
	$table->attach(gen_label_help("The list of supported boards are obtained from \"perl_gui/lib/boards/\" path. You can add your boards by adding its required files in aformentioned path. Note that currently only Altera FPGAs are supported. For boards from other vendors, you need to directly use their own compiler and call $name.v file in your top level module.",'Targeted Board:'),$col,$col+1,$row,$row+1,'fill','shrink',2,2);$col++;
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


sub  get_pin_assignment{
	my ($self,$name,$top,$target_dir)=@_;	
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


	


	#get boards pin list
	my $board_name=$self->object_get_attribute('compile','board');
	my @csv_file =   glob("./lib/boards/$board_name/*.csv");
	if(!defined $csv_file[0]){
		message_dialog("Error: ./lib/boards/$board_name folder does not contain the csv file.!");
		$window->destroy;
	}
	my $board=read_csv_file($csv_file[0]);

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
		quartus_compilation($self,$board,$name,$top,$target_dir);
		
	});
	$back-> signal_connect("clicked" => sub{ 
		
		$window->destroy;
		select_compiler($self,$name,$top,$target_dir);
		
	});


	$window->add ($mtable);
	$window->show_all();
}





sub quartus_compilation{
	my ($self,$board,$name,$top,$target_dir)=@_;
	my $run=def_image_button('icons/run.png','run');
	my $back=def_image_button('icons/left.png','Previous');	
	my $regen=def_image_button('icons/refresh.png','Regenerate Top.v');		


	my ($fname,$fpath,$fsuffix) = fileparse("$top",qr"\..[^.]*$");
	my $board_top_file ="${fpath}Top.v";
	unless (-e $board_top_file ){ 
		gen_top_v($self,$board,$name,$top) ;		
	}

	my ($app,$table,$tview,$window) = software_main($fpath,'Top.v');
	$table->attach($back,1,2,1,2,'shrink','shrink',2,2);
	$table->attach($regen,4,5,1,2,'shrink','shrink',2,2);
	$table->attach ($run,9, 10, 1,2,'shrink','shrink',0,0);

	
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
		my @qsfs =   glob("./lib/boards/$board_name/*.qsf");
		if(!defined $qsfs[0]){
			message_dialog("Error: ./lib/boards/$board_name folder does not contain the qsf file.!");
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

	save_file ("$model/run.tcl",$tcl);
	$run -> signal_connect("clicked" => sub{
		set_gui_status($self,'save_project',1);
		$app->do_save();
		my $modelsim_bin= $self->object_get_attribute('compile','modelsim_bin');		
		my $cmd="cd $target_dir; $modelsim_bin/vsim -do $model/run.tcl";
		my ($stdout,$exit,$stderr)=run_cmd_in_back_ground_get_stdout($cmd);
		if(length $stderr>1){			
			add_info(\$tview,"$stderr\n");
		}else {
			add_info(\$tview,"$stdout\n");
		}			

	});
	
	#$window->show_all();
}




sub verilator_compilation {
	my ($self,$name,$top,$target_dir)=@_;
	my $window = def_popwin_size(80,80,"Step 2: Compile",'percent');
	my $mtable = def_table(10, 10, FALSE);
	my ($outbox,$outtext)= create_text();
	add_colored_tag($outtext,'red');
	add_colored_tag($outtext,'blue');	
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
        	->name( '*.v','*.V','*.sv' )
                ->in( "$target_dir/src_verilog" );
	foreach my $file (@files) {
		copy($file,"$verilator/rtl_work/");
	}

	#"split all verilog modules in separate  files"
	add_info(\$outtext,"split all verilog modules in separate files\n");
   	my $split = Verilog::EditFiles->new
       	(outdir => "$verilator/processed_rtl",
        translate_synthesis => 0,
        celldefine => 0,
        );
   	$split->read_and_split(glob("$verilator/rtl_work/*.v"));
	$split->read_and_split(glob("$verilator/rtl_work/*.sv"));
   	$split->write_files();
   	
	#run verilator
	#my $cmd= "cd \"$verilator/processed_rtl\" \n xterm -e sh -c ' verilator  --cc $name.v --profile-cfuncs --prefix \"Vtop\" -O3  -CFLAGS -O3'";
	my $cmd= "cd \"$verilator/processed_rtl\" \n  verilator  --cc $name.v --profile-cfuncs --prefix \"Vtop\" -O3  -CFLAGS -O3";
	add_info(\$outtext,"$cmd\n");	
	my ($stdout,$exit,$stderr)=run_cmd_in_back_ground_get_stdout($cmd);
	if(length $stderr>1){			
		add_info(\$outtext,"$stderr\n");
	}else {
		add_info(\$outtext,"$stdout\n");
	}			

	#check if verilator model has been generated 
	if (-f "$verilator/processed_rtl/obj_dir/Vtop.cpp"){
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
	copy("../script/verilator_soc_make", "$verilator/processed_rtl/obj_dir/Makefile"); 
	

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
		verilator_compilation($self,$name,$top,$target_dir);
		
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
