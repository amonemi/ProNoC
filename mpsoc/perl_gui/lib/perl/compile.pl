#!/usr/bin/perl -w
use constant::boolean;
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use soc;
use File::Path;
use File::Find::Rule;
use File::Copy;
use File::Copy::Recursive qw(dircopy);
use Cwd 'abs_path';
use Verilog::EditFiles;
use List::MoreUtils qw( minmax );

################
#    Compile
#################

sub is_capital_sensitive()
{
    my ($cell_layout, $cell, $tree_model, $iter, $data) = @_;
    my $sensitive = !$tree_model->iter_has_child($iter);
    $cell->set('sensitive', $sensitive);
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
    my $table = def_table(2, 2, FALSE);
    my $col=0;
    my $row=0;
    my $compilers=$self->object_get_attribute('compile','compilers');#"QuartusII,Vivado,Verilator,Modelsim"
    my $compiler=gen_combobox_object ($self,'compile','type',$compilers,"QuartusII",undef,undef);
    $table->attach(gen_label_in_center("Compiler tool"),$col,$col+1,$row,$row+1,'fill','shrink',2,2);$col++;
    $table->attach($compiler,$col,$col+1,$row,$row+1,'fill','shrink',2,2);$col++;
    $row++;$col=0;
    my $old_board_name=$self->object_get_attribute('compile','board');
    my $old_compiler=$self->object_get_attribute('compile','type');
    my $vendor= ($old_compiler eq "QuartusII")? 'Altera' : 'Xilinx';
    
    #get the list of boards located in "boards/*" folder
    my @dirs = grep {-d} glob("../boards/$vendor/*");
    my ($fpgas,$init);
    foreach my $dir (@dirs) {
        my ($name,$path,$suffix) = fileparse("$dir",qr"\..[^.]*$");
        $init=$name;
        $fpgas= (defined $fpgas)? "$fpgas,$name" : "$name";        
    }
    
    my $compiler_options =
        ($old_compiler eq "QuartusII")? select_board  ($self,$name,$top,$target_dir,$vendor): 
        ($old_compiler eq "Vivado"   )? select_board  ($self,$name,$top,$target_dir,$vendor): 
        ($old_compiler eq "Modelsim" )? select_model_path  ($self,$name,$top,$target_dir): 
        ($old_compiler eq "Verilator")? select_parallel_process_num ($self,$name,$top,$target_dir):
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
    my $next=def_image_button('icons/right.png','_Next',FALSE,1);
    $table->attach($next,$col,$col+1,$row,$row+1,'shrink','shrink',2,2);$col++;
    $next-> signal_connect("clicked" => sub{
        my $compiler_type=$self->object_get_attribute('compile','type');        
        if($compiler_type eq "QuartusII" || $compiler_type eq "Vivado"){
            $vendor= ($compiler_type eq "QuartusII")? 'Altera' : 'Xilinx';
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
            if($new_board_name eq "Add New Board") {add_new_fpga_board($self,$name,$top,$target_dir,$end_func,$vendor);}
            else {get_pin_assignment($self,$name,$top,$target_dir,$end_func,$vendor);}
        }
        elsif($compiler_type eq "Modelsim"){
            modelsim_compilation($self,$name,$top,$target_dir,$vendor);
        }else{#verilator
            verilator_compilation_win($self,$name,$top,$target_dir,$vendor);
        }
        $window->destroy;
    });
    
    $compiler->signal_connect("changed" => sub{
        $compiler_options->destroy;
        my $new_board_name=$self->object_get_attribute('compile','type');
        $compiler_options =
            ($new_board_name eq "QuartusII")? select_board  ($self,$name,$top,$target_dir,"Altera"):
            ($new_board_name eq "Vivado")? select_board  ($self,$name,$top,$target_dir,"Xilinx"):
            ($new_board_name eq "Modelsim")?  select_model_path  ($self,$name,$top,$target_dir):
            ($new_board_name eq "Verilator")? select_parallel_process_num ($self,$name,$top,$target_dir):
            gen_label_in_center(" ");
        $table->attach($compiler_options,0,2,1,2,'fill','shrink',2,2);     
        $table->show_all;
    });
}

sub select_board {
    my ($self,$name,$top,$target_dir,$vendor)=@_;
    #get the list of boards located in "boards/*" folder
    my @dirs = grep {-d} glob("../boards/$vendor/*");
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
    my $compiler = ($vendor eq "Altera")? 'quartus' : 'vivado';
    my $bin_name = "$compiler bin";
    my $env = ($vendor eq "Altera")? "QUARTUS_BIN" : "VIVADO_BIN";
    my $Fpga_bin=   $ENV{$env};
    my $old_board_name=$self->object_get_attribute('compile','board');
    $table->attach(gen_label_help("The list of supported boards are obtained from \"mpsoc/boards/$vendor\" path. You can add your boards by adding its required files in aformentioned path. Note that currently Altera and Xilinx FPGAs are supported.",'Targeted Board:'),$col,$col+1,$row,$row+1,'fill','shrink',2,2);$col++;
    $table->attach(gen_combobox_object ($self,'compile','board',$fpgas,$init,undef,undef),$col,$col+1,$row,$row+1,'fill','shrink',2,2);$row++;
    my $bin =  $self->object_get_attribute('compile',$bin_name);
    $col=0;
    $self->object_add_attribute('compile',$bin_name,$Fpga_bin) if (!defined $bin && defined $Fpga_bin);
    $table->attach(gen_label_help("Path to $vendor/bin directory. You can set a default path as $env environment variable in ~/.bashrc file.
e.g:  export $env=/home/alireza/$compiler/bin","$env:"),$col,$col+1,$row,$row+1,'fill','shrink',2,2);$col++;
    $table->attach(get_dir_in_object ($self,'compile',$bin_name,undef,undef,undef),$col,$col+1,$row,$row+1,'fill','shrink',2,2);$row++;
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
    $table->attach(gen_label_help("Path to modelsim/bin directory. You can set a default path as MODELSIM_BIN environment variable in ~/.bashrc file.
e.g.  export MODELSIM_BIN=/home/alireza/altera/modeltech/bin",'Modelsim  bin:'),$col,$col+1,$row,$row+1,'fill','shrink',2,2);$col++;
    $table->attach(get_dir_in_object ($self,'compile','modelsim_bin',undef,undef,undef),$col,$col+1,$row,$row+1,'fill','shrink',2,2);$row++;
    return $table;
}

my $cpu_num;
sub select_parallel_process_num {
    my ($self,$name,$top,$target_dir)=@_;    
    my $table = def_table(2, 2, FALSE);
    my $col=0;
    my $row=0;
    #get total number of processor in the system
    my $cmd = "nproc\n";
    if(!defined $cpu_num){
        my ($stdout,$exit,$stderr)=run_cmd_in_back_ground_get_stdout($cmd);
        if(length $stderr>1){            
            #nproc command has failed. set default 4 paralel processor
        }else {
            my ($number ) = $stdout =~ /(\d+)/;
            if (defined  $number ){ 
                $cpu_num =$number if  ($number > 0 );
            }
        }
    }
    ($row,$col)= add_param_widget ($self,"Paralle run:" , "cpu_num", 1, 'Spin-button', "1,$cpu_num,1","specify the number of processors the Verilator can use at once to run parallel compilations/simulations", $table,$row,$col,1, 'compile', undef,undef,'vertical');
    return $table;    
}

sub select_parallel_thread_num {
    my ($self,$name,$top,$target_dir)=@_;    
    my $table = def_table(2, 2, FALSE);
    my $col=0;
    my $row=0;
    #get total number of processor in the system
    my $cmd = "nproc\n";
    if(!defined $cpu_num){
        my ($stdout,$exit,$stderr)=run_cmd_in_back_ground_get_stdout($cmd);
        if(length $stderr>1){            
            #nproc command has failed. set default 4 paralel processor
        }else {
            my ($number ) = $stdout =~ /(\d+)/;
            if (defined  $number ){ 
                $cpu_num =$number if  ($number > 0 );
            }
        }
    }
    ($row,$col)= add_param_widget ($self,"Thread run:" , "thread_num", 1, 'Spin-button', "1,$cpu_num,1","specify the number of threads the Verilator can use at once in one simulation", $table,$row,$col,1, 'compile', undef,undef,'vertical');
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
    my ($self,$name,$top,$target_dir,$end_func,$vendor)=@_;    
    my $window = def_popwin_size(50,80,"Add New $vendor FPGA Board",'percent');
    my $table = def_table(2, 2, FALSE);
    my $scrolled_win=add_widget_to_scrolled_win($table);
    my $mtable = def_table(10, 10, FALSE);
    my $next=def_image_button('icons/plus.png','Add');
    my $back=def_image_button('icons/left.png','Previous');     
    $mtable->attach_defaults($scrolled_win,0,10,0,9);
    $mtable->attach($back,2,3,9,10,'shrink','shrink',2,2) if (defined $name);    
    $mtable->attach($next,8,9,9,10,'shrink','shrink',2,2);
    my ($Twin,$tview)=create_txview();
    my $widgets=
        ($vendor eq 'Altera')? add_new_altera_fpga_board_widgets($self,$name,$top,$target_dir,$end_func,$vendor):
        add_new_xilinx_fpga_board_widgets($self,$name,$top,$target_dir,$end_func,$vendor,$tview);
    my $v1=gen_vpaned($widgets,0.3,$Twin);
    $table->attach_defaults($v1,0,3,0,2); 
    #$table->attach_defaults( $Twin,0,3,1,2);     
    $back-> signal_connect("clicked" => sub{ 
        $window->destroy;
        select_compiler($self,$name,$top,$target_dir,$end_func);
    });
    $next-> signal_connect("clicked" => sub{ 
        my $result = ($vendor eq 'Altera')? 
            add_new_altera_fpga_board_files($self,$vendor):
            add_new_xilinx_fpga_board_files($self,$vendor); 
            
        if(! defined $result ){
            select_compiler($self,$name,$top,$target_dir,$end_func) if (defined $name);    
            $window->destroy;
            message_dialog("The new board has been added successfully!");            
        }else {
            show_info($tview," ");
            show_colored_info($tview,$result,'red');            
        }    
    });
    
    if($vendor eq 'Altera'){
        my $auto=def_image_button('icons/advance.png','Auto-fill'); 
        set_tip($auto, "Auto-fill JTAG configuration. The board must be powered on and be connected to the PC."); 
        $mtable->attach($auto,5,6,9,10,'shrink','shrink',2,2);
        $auto-> signal_connect("clicked" => sub{ 
            my $pid;
            my $hw;
            my $project_dir      = get_project_dir();        
            my $command=  "$project_dir/mpsoc/src_c/jtag/jtag_libusb/list_usb_dev";
            add_info($tview,"$command\n");
            my ($stdout,$exit,$stderr)=run_cmd_in_back_ground_get_stdout($command);
            if(length $stderr>1){            
                add_colored_info($tview,"$stderr\n",'red');
                add_colored_info($tview,"$command was not run successfully!\n",'red');
            }else {
                if($exit){
                    add_colored_info($tview,"$stdout\n",'red');
                    add_colored_info($tview,"$command was not run successfully!\n",'red');
                }else{
                    add_info($tview,"$stdout\n");
                    my @a=split /vid=9fb/, $stdout; 
                    if(defined $a[1]){
                        my @b=split /pid=/, $a[1]; 
                        my @c=split /\n/, $b[1]; 
                        $pid=$c[0]; 
                        $self->object_add_attribute('compile','quartus_pid',$pid);
                        add_colored_info($tview,"Detected PID: $pid\n",'blue');
                    }else{
                        add_colored_info($tview,"The Altera vendor ID of 9fb is not detected. Make sure You have connected your Altera board to your USB port\n",'red');
                        return;
                    }
                }
            }
            $command=  "$ENV{QUARTUS_BIN}/jtagconfig";
            add_info($tview,"$command\n");
            ($stdout,$exit,$stderr)=run_cmd_in_back_ground_get_stdout($command);
            if(length $stderr>1){            
                add_colored_info($tview,"$stderr\n",'red');
                add_colored_info($tview,"$command was not run successfully!\n",'red');
            }else {
                if($exit){
                    add_colored_info($tview,"$stdout\n",'red');
                    add_colored_info($tview,"$command was not run successfully!\n",'red');
                }else{
                    add_info($tview,"$stdout\n");
                    my @a=split /1\)\s+/, $stdout; 
                    if(defined $a[1]){
                        my @b=split /\s+/, $a[1]; 
                        $hw=$b[0];
                        $self->object_add_attribute('compile','quartus_hardware',$hw);
                        add_colored_info($tview,"Detected Hardware: $hw\n",'blue');
                        my $qsf=$self->object_get_attribute('compile','board_confg_file');    
                        if(!defined $qsf ){
                            add_colored_info ($tview,"Cannot detect device location in JTAG chin. Please enter the QSF file or fill in manually \n",'red'); 
                                            
                        }else{
                            #search for device name in qsf file
                            $qsf=add_project_dir_to_addr($qsf);
                            if (!(-f $qsf)){
                                add_colored_info($tview, "Error Could not find $qsf file!\n");
                                return;
                            }
                            my $str=load_file($qsf);
                            my $dw= capture_string_between(' DEVICE ',$str,"\n");
                            if(defined $dw){
                                add_colored_info($tview,"Device name in qsf file is: $dw\n",'blue');
                                @b=split /\n/, $a[1];
                                
                                #capture device name in JTAG chain
                                my @f=(0);
                                foreach my $c (@b){
                                    my @e=split /\s+/, $c;
                                    push(@f,$e[2]) if(defined $e[2]);
                                } 
                                my $pos=find_the_most_similar_position($dw ,@f);
                                $self->object_add_attribute('compile','quartus_device',$pos);
                                add_colored_info($tview,"$dw has the most similarity with $f[$pos] in JTAG chain\n",'blue');
                            }else{
                                add_colored_info ($tview, "Could not find device name in the $qsf file!\n");
                            }
                        }
                    }else{
                        #add_colored_info($tview,"The Altera vendor ID of 9fb is not detected. Make sure You have connected your Altera board to your USB port\n",'red');
                    }
                }
            }
            $widgets->destroy();
            $widgets= add_new_altera_fpga_board_widgets($self,$name,$top,$target_dir,$end_func,$vendor);
            $v1-> pack1($widgets, TRUE, TRUE);     
            #$table->attach_defaults($widgets,0,3,0,1); 
            $table->show_all();        
            #my $cmd=" $ENV{'QUARTUS_BIN'}"
        });
    }
    $window->add ($mtable);
    $window->show_all();
}

sub add_new_xilinx_fpga_board_widgets{
    my ($self,$name,$top,$target_dir,$end_func,$vendor,$tview)=@_;    
    my $table = def_table(2, 2, FALSE);
    my $col=0;
    my $row=0;
    my $help1="Your given FPGA Board name. Do not use any space in given name";
    my $help2="Path to FPGA board xdc file. In your Xilinx board installation CD or in the Internet, search for a xdc file containing your FPGA device pin assignment constrain).";
    my $help3="Path to FPGA_board_top.v file. A Verilog file containing all your FPGA device IO ports.";
    my $help4="Your Board name (Board PART) e.g. digilentinc.com:arty-z7-20:part0:1.0";
    my $help5="Your FPGA device name (PART) e.g. xc7z020clg400-1 ";
    my $help6="The order number of target device in jtag chain. Run jtag targets after \"connect\" command in xsct terminal to list all available targets.";
    my $help7="Path to Vivado board files repository. E.g download the repo from https://github.com/Digilent/vivado-boards and save in \$ProNoC_work/toolchain/board_files folder.";
    my $help8="Hardware device name e.g. xc7z020_1. To find it you can connect your FPGA board to your PC. In tcl terminal run 
        open_hw  
        connect_hw_server 
        open_hw_target
        get_hw_devices
It supposed to show the list of your hardware devices in your FPGA. Select the name represent your FPGA device        
        ";
    my $repo ="$ENV{PRONOC_WORK}/toolchain/board_files";
    $row++;
    my @info = ( 
    { label=>"FPGA board display name:",        param_name=>'fpga_board', type=>"Entry",     default_val=>undef, content=>undef, info=>$help1, param_parent=>'compile', ref_delay=> undef},      
    { label=>"Set board repo:", param_name=>'fpga_board_repo',  type=>"DIR_path", default_val=>"$repo", content=>undef, info=>$help7, param_parent=>'compile',ref_delay=>undef},    
    { label=>"FPGA board part name:", param_name=>'fpga_board_part', type=>"EntryCombo",default_val=>undef, content=>undef, info =>$help4, param_parent=>'compile', ref_delay=> undef},
    { label=>"FPGA part name:",       param_name=>'fpga_part', type=>"Entry",     default_val=>undef, content=>undef, info=>$help5, param_parent=>'compile', ref_delay=> undef},  
    { label=>"FPGA Hardware device name:", param_name=>'fpga_hw_device', type=>"EntryCombo", default_val=>undef, content=>undef, info=>$help8, param_parent=>'compile', ref_delay=> undef},  
    { label=>"Target device JTAG chain order number", param_name=>'fpga_board_order',  type=>"Spin-button", default_val=>1, content=>"0,256,1", info=>$help6, param_parent=>'compile',ref_delay=>undef},      
    { label=>'FPGA board xdc file:',    param_name=>'board_confg_file',   type=>"FILE_path", default_val=>undef, content=>"xdc", info=>$help2, param_parent=>'compile', ref_delay=>undef},
    { label=>"FPGA board golden top Verilog file", param_name=>'fpga_board_v',     type=>"FILE_path", default_val=>undef, content=>"v", info=>$help3, param_parent=>'compile',ref_delay=>undef},
    );
    my %widgets;
    my %rows;
    foreach my $d (@info) {
        $rows{$d->{param_name}} =$row; 
        ($row,$col,$widgets{$d->{param_name}})=add_param_widget ($self, $d->{label}, $d->{param_name}, $d->{default_val}, $d->{type}, $d->{content}, $d->{info}, $table,$row,$col,1, $d->{param_parent}, $d->{ref_delay},undef,'vertical');
    }
    my $icon = 'icons/advance.png';
    my $search=def_image_button($icon,undef); 
    my $search_board=def_image_button ($icon,undef); 
    my $search_dev=def_image_button ($icon,undef);
    my $search_chain=def_image_button ($icon,undef);  
    
    $table->attach($search,4,5,$rows{'fpga_board_part'},$rows{'fpga_board_part'}+1,'fill','shrink',2,2); 
    $table->attach($search_board,4,5,$rows{'fpga_part'},$rows{'fpga_part'}+1,'fill','shrink',2,2); 
    $table->attach($search_dev,4,5,$rows{'fpga_hw_device'},$rows{'fpga_hw_device'}+1,'fill','shrink',2,2);
    $table->attach($search_chain,4,5,$rows{'fpga_board_order'},$rows{'fpga_board_order'}+1,'fill','shrink',2,2);
    $search->signal_connect("clicked" => sub{
            my $load= show_gif("icons/load.gif");
            $table->attach ($load,5, 6, $rows{'fpga_board_part'},$rows{'fpga_board_part'}+ 1,'shrink','shrink',0,0);
            $table->show_all;
            my $result=    set_xilinx_board_from_repo($self,$tview);
            update_combo_entry_content($widgets{'fpga_board_part'}, $result);
            $load->destroy;
            $table->show_all;
        });    
    $search_board->signal_connect("clicked" => sub{
            my $load= show_gif("icons/load.gif");
            $table->attach ($load,5, 6, $rows{'fpga_part'},$rows{'fpga_part'}+1, 'shrink','shrink',0,0);
            $table->show_all;
            my $result=    get_xilinx_board_part($self,$tview);
            $widgets{'fpga_part'}->set_text($result);            
            #print "result = $result\n";
            $load->destroy;
            $table->show_all;
        }); 
    $search_dev->signal_connect("clicked" => sub{
            my $load= show_gif("icons/load.gif");
            $table->attach ($load,5, 6, $rows{'fpga_hw_device'},$rows{'fpga_hw_device'}+ 1,'shrink','shrink',0,0);
            $table->show_all;
            my $result=    get_xilinx_device_names($self,$tview);
            update_combo_entry_content($widgets{'fpga_hw_device'}, $result);
            $load->destroy;
            $table->show_all;
        }); 
    $search_chain->signal_connect("clicked" => sub{
        my $targets = show_all_xilinx_targets($self,$tview);
        if(!defined $targets){
            add_info($tview,"Unable to find the FPGA board target list. Make sure you have connected your FPGA board to your PC first and it is powered on.\n");
            return;
        }
        
        my @lines=split(/\r?\n/,$targets);
        my @list1;
        my @list2;
        foreach my $p (@lines){
            $p =~ s/^\s+//;#left trim
            my @words=split(/\s+/,$p);
            push (@list1,$words[0]);
            push (@list2,$words[1]);
        }
        my $hw =  $self->object_get_attribute('compile','fpga_hw_device');
        if( !defined $hw){
            add_colored_info($tview,"Please define the FPGA hardware device name first!\n",'red');
            return;
        }
        my $pos = find_the_most_similar_position ($hw ,@list2);
        add_info($tview,"$hw matched with target $list1[$pos] $list2[$pos]  ");
        $widgets{'fpga_board_order'}->set_value($list1[$pos]);
    });
    return ($row, $col, $table);    
}

sub set_xilinx_board_from_repo{
    my ($self,$tview)=@_;
    my $bin =  $self->object_get_attribute('compile',"vivado bin");
    my $vivado =(defined $bin)?  "${bin}/vivado" :  "vivado";
    my $result;
    my $repo= $self->object_get_attribute('compile','fpga_board_repo');    
    my $tcl= get_project_dir()."/mpsoc/perl_gui/lib/tcl/vivado_get_boards.tcl -tclargs $repo";
    my $command = "cd $ENV{PRONOC_WORK}/tmp;   $vivado -mode tcl -source $tcl";
    add_info($tview,"$command\n");
    my $stdout=run_cmd_textview_errors($command,$tview);
    return if (!defined $stdout); 
    add_info($tview,"$stdout\n");
    my @boards=split(/\s+/,$stdout);
    my $r=0;
    foreach my $board (@boards){
        my @pp=split(':',$board);
        if(scalar @pp  == 4 && $pp[1] =~ /[a-zA-Z]+/) {
            $r=1;
            $result= (!defined $result)? "$board" : $result.",$board";
        } 
    }
    add_colored_info($tview,"$stdout\n",'red') if($r==0);
    return $result;
}  

sub get_xilinx_device_names{
    my ($self,$tview)=@_;
    my $bin =  $self->object_get_attribute('compile',"vivado bin");
    my $vivado =(defined $bin)?  "${bin}/vivado" :  "vivado";
    my $result;
    my $repo= $self->object_get_attribute('compile','fpga_board_repo');    
    my $tcl= get_project_dir()."/mpsoc/perl_gui/lib/tcl/vivado_get_hw_device.tcl -tclargs";
    my $command = "cd $ENV{PRONOC_WORK}/tmp;   $vivado -mode tcl -source $tcl";
    add_info($tview,"$command\n");
    my $stdout=run_cmd_textview_errors($command,$tview);
    if (!defined $stdout){
        add_info($tview,"Unable to find the FPGA board devices list. Make sure you have connected your FPGA board to your PC first and it is powered on.\n");
        return;
    } 
    add_info($tview,"$stdout\n");
    my $devices =  capture_string_between ('\n\*RESULT:',$stdout,"\n");    
    my @D=split(/\s+/,$devices);
    return join ',', @D;
}  

sub get_xilinx_board_part{
    my ($self,$tview)=@_;
    my $bin =  $self->object_get_attribute('compile',"vivado bin");
    my $vivado =(defined $bin)?  "${bin}/vivado" :  "vivado";
    my $result;
    my $repo= $self->object_get_attribute('compile','fpga_board_repo');    
    my $board_part= $self->object_get_attribute('compile' ,'fpga_board_part');
    if (!defined $board_part  ){
        add_colored_info($tview,"Please define the FPGA board part name first!\n",'red');
        return;
    }    
    my $tcl= get_project_dir()."/mpsoc/perl_gui/lib/tcl/vivado_get_part.tcl -tclargs $board_part $repo ";
    my $command = "cd $ENV{PRONOC_WORK}/tmp;   $vivado -mode tcl -source $tcl";
    add_info($tview,"$command\n");
    my $stdout=run_cmd_textview_errors($command,$tview);
    return if (!defined $stdout); 
    add_info($tview,"$stdout\n");
    return capture_string_between ('\n\*RESULT:',$stdout,"\n");    
}    


sub add_new_altera_fpga_board_widgets{
    my ($self,$name,$top,$target_dir,$end_func,$vendor)=@_;    
    my $table = def_table(2, 2, FALSE);
    my $help1="FPGA Board name. Do not use any space in given name";
    my $help2="Path to FPGA board qsf file. In your Altra board installation CD or in the Internet search for a QSF file containing your FPGA device name with other necessary global project setting including the pin assignments (e.g DE10_Nano_golden_top.qsf).";
    my $help3="Path to FPGA_board_top.v file. In your Altra board installation CD or in the Internet search for a Verilog file containing all your FPGA device IO ports (e.g DE10_Nano_golden_top.v).";
    my $help4="FPGA Board USB-Blaster product ID (PID). Power on your FPGA board and connect it to your PC. Then press Auto-fill button to find PID. Optionally you can run mpsoc/
src_c/jtag/jtag_libusb/list_usb_dev to find your USB-Blaster PID. Search for PID of a device having 9fb (altera) Vendor ID (VID)";
    my $help5="Power on your FPGA board and connect it to your PC. Then press Auto-fill button to find your hardware name. Optionally you can run \$QUARTUS_BIN/jtagconfig to find your programming hardware name. 
an example of output from the 'jtagconfig' command:
\t  1) ByteBlasterMV on LPT1
\t       090010DD   EPXA10
\t       049220DD   EPXA_ARM922
or
\t   1) DE-SoC [1-3]
\t       48A00477   SOCVHP5 
\t       02D020DC   5CS(EBA6ES|XFC6c6ES)   
ByteBlasterMV \& DE-SoC are the programming hardware name.";
    my $help6="Power on your FPGA board and connect it to your PC. Then press Auto-fill button to find your device location in jtag chain. Optionally you can run \$QUARTUS_BIN/jtagconfig to find your target device location in jtag chain."; 
    my @info = (
    { label=>"FPGA Board Name:",                   param_name=>'fpga_board', type=>"Entry",     default_val=>undef, content=>undef, info=>$help1, param_parent=>'compile', ref_delay=> undef},
    { label=>'FPGA Board Golden top QSF file:',    param_name=>'board_confg_file',   type=>"FILE_path", default_val=>undef, content=>"qsf", info=>$help2, param_parent=>'compile', ref_delay=>undef},
    { label=>"FPGA Board Golden top Verilog file", param_name=>'fpga_board_v',     type=>"FILE_path", default_val=>undef, content=>"v", info=>$help3, param_parent=>'compile',ref_delay=>undef },
    );
    my @usb = (
    { label=>"FPGA Board USB Blaster PID:",        param_name=>'quartus_pid',   type=>"Entry",     default_val=>undef, content=>undef, info=>$help4, param_parent=>'compile', ref_delay=> undef},
    { label=>"FPGA Board Programming Hardware Name:", param_name=>'quartus_hardware',   type=>"Entry",     default_val=>undef, content=>undef, info=>$help5, param_parent=>'compile', ref_delay=> undef},
    { label=>"FPGA Board Device location in JTAG chain:", param_name=>'quartus_device',   type=>"Spin-button",     default_val=>0, content=>"0,100,1", info=>$help6, param_parent=>'compile', ref_delay=> undef},
    );    
    my $col=0;
    my $row=0;
    foreach my $d (@info) {
        ($row,$col)=add_param_widget ($self, $d->{label}, $d->{param_name}, $d->{default_val}, $d->{type}, $d->{content}, $d->{info}, $table,$row,$col,1, $d->{param_parent}, $d->{ref_delay},undef,"vertical");
    }
    my $labl=def_pack_vbox(FALSE, 0,(gen_Hsep(),gen_label_in_center("FPGA Board JTAG Configuration"),gen_Hsep()));
    $table->attach( $labl,0,3,$row,$row+1,'fill','shrink',2,2); $row++; $col=0;
    foreach my $d (@usb) {
        ($row,$col)=add_param_widget ($self, $d->{label}, $d->{param_name}, $d->{default_val}, $d->{type}, $d->{content}, $d->{info}, $table,$row,$col,1, $d->{param_parent}, $d->{ref_delay},undef,"vertical");
    }
    return ($row, $col, $table);    
}

sub add_new_xilinx_fpga_board_files{
    my ($self,$vendor)=@_;    
    #check the board name
    my $board_name=$self->object_get_attribute('compile','fpga_board');
    return "Please define the Board Name\n" if(! defined $board_name ); 
    return "Please define the Board Name\n" if(length($board_name) ==0 ); 
    my $r=check_verilog_identifier_syntax($board_name);    
    return "Error in given Board Name: $r\n" if(defined $r ); 
    #check xdc file 
    my $xdc=$self->object_get_attribute('compile','board_confg_file');    
    return "Please define the xdc file\n" if(!defined $xdc );
    $xdc=add_project_dir_to_addr($xdc);
    #check v file 
    my $top=$self->object_get_attribute('compile','fpga_board_v');
    return "Please define the verilog file file\n" if(!defined $top );
    $top=add_project_dir_to_addr($top);
    #check board part 
    my $part=$self->object_get_attribute('compile','fpga_part');
    my $board_part=$self->object_get_attribute('compile','fpga_board_part');
    return "Please define at least one of FPGA board part or FPGA part names"if(!defined $part && !defined $board_part  );   
    #make board directory
    my $project_dir = get_project_dir();
    my $path="$project_dir/mpsoc/boards/$vendor/$board_name";
    mkpath($path,1,01777);
    return "Error cannot make $path path" if ((-d $path)==0);
    copy( $xdc,"$path/$board_name.xdc");
    copy($top,"$path/$board_name.v");
    my $a=$self->object_get_attribute('compile','fpga_board_order');
    my $jtag_intfc="#!/bin/bash
JTAG_INTFC=\"\$PRONOC_WORK/toolchain/bin/jtag_xilinx_xsct -a $a -b 36\"
#it works only for 32-bit jtag data width for 64 pass -b 68 
";
    save_file ("$path/jtag_intfc.sh",$jtag_intfc);    
    my $bin =  $self->object_get_attribute('compile',"vivado bin");
    my $hw_dev=$self->object_get_attribute('compile',"fpga_hw_device");
    my $repo=  $self->object_get_attribute('compile','fpga_board_repo');
    my $tcl="proc set_project_properties { } {\n";
    if(-d $repo){
        $tcl=$tcl."\tset_property  \"board_part_repo_paths\" [list \"$repo\"] [current_project]\n";
    }else {
        $tcl=$tcl."\tset_property  \"board_part_repo_paths\" [get_property LOCAL_ROOT_DIR [xhub::get_xstores xilinx_board_store]] [current_project]\n" if(defined $board_part);
    }
    $tcl=$tcl."\tset_property \"part\" \"$part\" [current_project]\n" if(defined $part);
    $tcl=$tcl."\tset_property \"board_part\" \"$board_part\" [current_project]\n" if(defined $board_part);
    $tcl=$tcl."\tset_property \"default_lib\" \"xil_defaultlib\" [current_project]\n}\n";
    if (defined $hw_dev){
$tcl=$tcl."\n    
proc program_board {bit_file} {
    open_hw
    connect_hw_server
    open_hw_target
    set_property PROGRAM.FILE \$bit_file [get_hw_devices $hw_dev]
    program_hw_devices [get_hw_devices $hw_dev]
    refresh_hw_device [get_hw_devices $hw_dev]
}
";    
    }    
    save_file ("$path/board_property.tcl",$tcl);
    $self->object_add_attribute('compile','board',$board_name);        
    return undef;
}

sub add_new_altera_fpga_board_files{
    my ($self,$vendor)=@_;
    #check the board name
    my $board_name=$self->object_get_attribute('compile','fpga_board');
    return "Please define the Board Name\n" if(! defined $board_name ); 
    return "Please define the Board Name\n" if(length($board_name) ==0 ); 
    my $r=check_verilog_identifier_syntax($board_name);    
    return "Error in given Board Name: $r\n" if(defined $r ); 
    #check qsf file 
    my $qsf=$self->object_get_attribute('compile','board_confg_file');    
    return "Please define the QSF file\n" if(!defined $qsf );
    #check v file 
    my $top=$self->object_get_attribute('compile','fpga_board_v');
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
    my $project_dir = get_project_dir();
    my $path="$project_dir/mpsoc/boards/$vendor/$board_name";
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
    print $file "#!/bin/bash

PRODUCT_ID=\"0x$pid\" 
HARDWARE_NAME=\'$hw *\'
DEVICE_NAME=\"\@$dw*\" 
    
$jtag
        
    ";    
    close $file;
    
    
    #generate program_device.sh
    open $file, ">", "$path/program_device.sh" or return "Error: Could not create $path/program_device.sh file in write mode!";
    
    
    print $file "#!/bin/bash

#usage: 
#    bash program_device.sh  programming_file.sof

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
    my ($self,$name,$top,$target_dir,$end_func,$vendor)=@_;    
    my $window = def_popwin_size(80,80,"Step 2: Pin Assignment",'percent');
    my $table = def_table(2, 2, FALSE);
    my $scrolled_win = add_widget_to_scrolled_win($table);
    my $mtable = def_table(10, 10, FALSE);    
    my $next=def_image_button('icons/right.png','Next');
    my $back=def_image_button('icons/left.png','Previous');    
    $mtable->attach_defaults($scrolled_win,0,10,0,9);
    $mtable->attach($back,2,3,9,10,'shrink','shrink',2,2);
    $mtable->attach($next,8,9,9,10,'shrink','shrink',2,2);
    my $board_name=$self->object_get_attribute('compile','board');
    #copy board jtag_intfc.sh file 
    my ($fname,$fpath,$fsuffix) = fileparse("$top",qr"\..[^.]*$");
    copy("../boards/$vendor/$board_name/jtag_intfc.sh","${fpath}../sw/jtag_intfc.sh");    
    my $m= $self->object_get_attribute('mpsoc_name',undef);
    if(defined $m){    # we are compiling a complete NoC-based mpsoc                        
        my ($nr,$ne,$router_p,$ref_tops)= get_noc_verilator_top_modules_info($self);
        for (my $tile_num=0;$tile_num<$ne;$tile_num++){
            #print "$tile_num\n";
            my ($soc_name,$num)= $self->mpsoc_get_tile_soc_name($tile_num);
            next if(!defined $soc_name);
            copy("../boards/$vendor/$board_name/jtag_intfc.sh","${fpath}../sw/tile$tile_num/jtag_intfc.sh");
        }
    }
    #copy board program_device.sh file 
    copy("../boards/$vendor/$board_name/program_device.sh","${fpath}../program_device.sh");
    #get boards pin list
    my $top_v= "../boards/$vendor/$board_name/$board_name.v";
    if(!-f $top_v){
        message_dialog("Error: Could not load the board pin list. The $top_v does not exist!",'error');
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
    my @labels= ('Port Direction','Port Range     ','Port name      ','Assignment Type','Board Port name ','Board Port Range');
    foreach my $p (@labels){
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
                #    print"($portrange=$portrange)=~ s/\b$l\b/$value/g      if(defined $param{$l})\n";
                }
            }
            my($s1,$s2)=split (":",$portrange);
            {
                no warnings 'numeric';
                $s1 = eval $s1;
                $s2 = eval $s2;
            }
            $portrange = "[ $portrange ]" ;    
            if(defined $s1 && defined $s2 ){
                $portrange = "" if($s1 eq 0 && $s2 eq 0);             #the upper and lower range are equal zero so remove it                
            }
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
            my $path = TreePath_new_from_indices(@indices);
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
        fpga_compilation($self,$board,$name,$top,$target_dir,$end_func,$vendor);
        
    });
    $back-> signal_connect("clicked" => sub{ 
        
        $window->destroy;
        select_compiler($self,$name,$top,$target_dir,$end_func,$vendor);
        
    });
    $window->add ($mtable);
    $window->show_all();
}

sub fpga_compilation{
    my ($self,$board,$name,$top,$target_dir,$end_func,$vendor)=@_;
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
    $table->attach ($run,6, 7, 1,2,'shrink','shrink',2,2);
    $table->attach($prog,9,10,1,2,'shrink','shrink',2,2);
    $regen-> signal_connect("clicked" => sub{
        my $response =  yes_no_dialog("Are you sure you want to regenerate the Top.v file? Note that any changes you have made will be lost");
        if ($response eq 'yes') {
            gen_top_v($self,$board,$name,$top);
            $app->refresh_source("$board_top_file");    
        }        
    });
    
    $back-> signal_connect("clicked" => sub{ 
        
        $window->destroy;
        get_pin_assignment($self,$name,$top,$target_dir,$end_func,$vendor);
        
    });

    #compile
    $run-> signal_connect("clicked" => sub{
        my $load= show_gif("icons/load.gif");
        $table->attach ($load,8, 9, 1,2,'shrink','shrink',2,2);
        $load->show_all;
        set_gui_status($self,'save_project',1);
        $app->ask_to_save_changes();
        quartus_run_compile ($self,$app,$tview,$target_dir,$name,$window,$end_func,$vendor) if($vendor eq 'Altera');
        xilinx_run_compile ($self,$app,$tview,$target_dir,$name,$window,$end_func,$vendor)  if($vendor eq 'Xilinx');
        $load->destroy;
    });

    #Programe the board 
    $prog-> signal_connect("clicked" => sub{ 
        quartus_program_the_board($self,$tview,$target_dir,$name,$vendor) if($vendor eq 'Altera');
        vivado_program_the_board($self,$tview,$target_dir,$name,$vendor) if($vendor eq 'Xilinx');
    });    
}

sub vivado_program_the_board {
    my     ($self,$tview,$target_dir,$name,$vendor) =@_;
    my $bit_file="$target_dir/Vivado/xilinx_compile/${name}.runs/impl_1/Top.bit";
    
    unless (-f "$target_dir/Vivado/program_board.tcl"){    
    #create tcl file
    my $xpr = "\$tcl_path/xilinx_compile/${name}.xpr";
    my $tcl="
#Get tcl shell path relative to current script
set tcl_path    [file dirname [info script]] 

set projectName $name

source \"\$tcl_path/board_property.tcl\"
set projectXpr \"$xpr\"
#Open project
open_project   \$projectXpr
program_board \"\$tcl_path/xilinx_compile/${name}.runs/impl_1/Top.bit\"
close_project
exit

    ";
    save_file ("$target_dir/Vivado/program_board.tcl",$tcl);    
    add_info($tview,"File $target_dir/Vivado/program_board.tcl is created\n");
    }
    
    #check bit file existance
    unless (-f $bit_file){    
        add_colored_info($tview,"Could not find $bit_file. Click on project Compile button first and make sure it runs successfully.",'red');    
        return    
    }    
    #run vivado using program_board.tcl
    my $error =run_vivado ($self,$target_dir,$tview,"$target_dir/Vivado/program_board.tcl");    
    add_colored_info($tview,"Board is programmed successfully!\n",'blue') if($error==0);
}    

sub quartus_program_the_board{
    my ($self,$tview,$target_dir,$name,$vendor)=@_;
    my $error = 0;
    my $sof_file="$target_dir/Quartus/output_files/${name}.sof";
    my $bash_file="$target_dir/program_device.sh";
    add_info($tview,"Program the board using Quartus_pgm and $sof_file file\n");
    #check if the programming file exists
    unless (-f $sof_file) {
        add_colored_info($tview,"\tThe $sof_file does not exists! Make sure you have compiled the code successfully.\n", 'red');
        $error=1;
    }
    #check if the program_device.sh file exists
    unless (-f $bash_file) {
        add_colored_info($tview,"\tThe $bash_file does not exist! This file varies depending on your target board and must be available inside mpsoc/boards/$vendor/[board_name].\n", 'red');
        $error=1;
    }
    return if($error);
    my $command = "bash $bash_file $sof_file";
    add_info($tview,"$command\n");
    my ($stdout,$exit,$stderr)=run_cmd_in_back_ground_get_stdout($command);
    if(length $stderr>1){            
        add_colored_info($tview,"$stderr\n",'red');
        add_colored_info($tview,"Board was not programmed successfully!\n",'red');
    }else {
        if($exit){
            add_colored_info($tview,"$stdout\n",'red');
            add_colored_info($tview,"Board was not programmed successfully!\n",'red');
        }else{
            add_info($tview,"$stdout\n");
            add_colored_info($tview,"Board is programmed successfully!\n",'blue');
        }
    }        
}

sub quartus_run_compile{
    my ($self,$app,$tview,$target_dir,$name,$window,$end_func,$vendor)=@_;     
    my $error = 0;
    add_info($tview,"CREATE: start creating Quartus project in $target_dir/Quartus folder\n");
    mkpath("$target_dir/Quartus",1,01777);
    #get list of source file
    add_info($tview,"        Read the list of all source files $target_dir/src_verilog\n");
    my @files = File::Find::Rule->file()
            ->name( '*.v','*.V','*.sv' )
            ->in( "$target_dir/src_verilog" );
    #make sure source files have key word 'module' 
    my @sources;
    foreach my $p (@files){
        push (@sources,$p)    if(check_file_has_string($p,'endpackage')); 
    }
    foreach my $p (@files){
        push (@sources,$p)    if(check_file_has_string($p,'module')); 
    }
    my $files = join ("\n",@sources);
    add_info($tview,"$files\n");
    #creat project qsf file
    my $qsf_file="$target_dir/Quartus/${name}.qsf";
    save_file ($qsf_file,"# Generated using ProNoC\n");
    #append global assignets to qsf file
    my $board_name=$self->object_get_attribute('compile','board');
    my @qsfs =   glob("../boards/$vendor/$board_name/*.qsf");
    if(!defined $qsfs[0]){
        message_dialog("Error: ../boards/$vendor/$board_name folder does not contain the qsf file.!",'error');
        $window->destroy;
    }
    my $assignment_file =  $qsfs[0];
    if(-f $assignment_file){
        merg_files ($assignment_file,$qsf_file);
    }
    my %paths;    
    #add the list of source fils to qsf file
    my $s="\n\n\n set_global_assignment -name TOP_LEVEL_ENTITY Top\n";
    foreach my $p (@sources){
        my ($name,$path,$suffix) = fileparse("$p",qr"\..[^.]*$");
        $s="$s set_global_assignment -name VERILOG_FILE $p\n" if ($suffix eq ".v");
        $s="$s set_global_assignment -name SYSTEMVERILOG_FILE $p\n" if ($suffix eq ".sv");
        $paths{$path}=1;
    }
    foreach my $p (sort keys %paths){
        $s="$s set_global_assignment -name SEARCH_PATH  $p\n";    
    }
    append_text_to_file($qsf_file,$s);
    add_info($tview,"\n Qsf file has been created\n");
    #start compilation
    my $Quartus_bin= $self->object_get_attribute('compile','quartus bin');
    my @qfiles = ("quartus_map","quartus_fit","quartus_asm","quartus_sta");
    foreach my $f (@qfiles){
        unless(-f "$Quartus_bin/$f" ){
            $error=1;
            add_colored_info($tview, "$Quartus_bin/$f No such file or directory\n",'red');
            last;
        }
    }
    my $run_sh = "#!/bin/bash
$Quartus_bin/quartus_map --64bit $name --read_settings_files=on
$Quartus_bin/quartus_fit --64bit $name --read_settings_files=on 
$Quartus_bin/quartus_asm --64bit $name --read_settings_files=on
$Quartus_bin/quartus_sta --64bit $name    
    ";
    save_file("$target_dir/Quartus/run.sh",  $run_sh);
    add_info($tview, "Start Quartus compilation.....\n");
    my @compilation_command =(
        "cd \"$target_dir/Quartus\" \n xterm -e bash -c '$Quartus_bin/quartus_map --64bit $name --read_settings_files=on; echo \$? > status; sleep 1' ",
        "cd \"$target_dir/Quartus\" \n xterm -e bash -c '$Quartus_bin/quartus_fit --64bit $name --read_settings_files=on; echo \$? > status; sleep 1' ",
        "cd \"$target_dir/Quartus\" \n xterm -e bash -c '$Quartus_bin/quartus_asm --64bit $name --read_settings_files=on; echo \$? > status; sleep 1' ",
        "cd \"$target_dir/Quartus\" \n xterm -e bash -c '$Quartus_bin/quartus_sta --64bit $name; echo \$? > status; sleep 1 ' ");
        foreach my $cmd (@compilation_command){
            last if($error); 
        add_info($tview,"$cmd\n");
        unlink "$target_dir/Quartus/status";
        my ($stdout,$exit,$stderr)=run_cmd_in_back_ground_get_stdout( $cmd);
        if($exit){
            add_colored_info($tview, "$stdout\n",'red') if(defined $stdout);
            add_colored_info($tview, "$stderr\n",'red') if(defined $stderr);
            $error=1;
            last;            
        }        
        open(my $fh,  "<$target_dir/Quartus/status") || die "Can not open: $!";
        read($fh,my $status,1);
        close($fh);
        if("$status" != "0"){            
            ($stdout,$exit,$stderr)=run_cmd_in_back_ground_get_stdout("cd \"$target_dir/Quartus/output_files/\" \n grep -h \"Error (\" *");
            add_colored_info($tview,"$stderr\n",'red') if(defined $stderr);
            add_colored_info($tview,"$stdout\n",'red');
            $error=1;
            last;
        }            
    }
    add_colored_info($tview,"Quartus compilation failed !\n",'red') if($error==1);
    add_colored_info($tview,"Quartus compilation is done successfully in $target_dir/Quartus!\n", 'blue') if($error==0);
    if (defined $end_func){
        if ($error==0){
            $end_func->($self);
            $window->destroy;
        }else {
            message_dialog("Error in Quartus compilation!",'error');    
        }
    }
}

sub xilinx_run_compile{
    my ($self,$app,$tview,$target_dir,$name,$window,$end_func,$vendor)=@_;
    add_info($tview,"CREATE: start creating Vivado project in $target_dir/Vivado\n");
    #get list of source file
    add_info($tview,"        Read the list of all source files $target_dir/src_verilog\n");
    my @files = File::Find::Rule->file()
            ->name( '*.v','*.V','*.sv' )
            ->in( "$target_dir/src_verilog" );
    #make sure source files have key word 'module' 
    my @sources;
    foreach my $p (@files){
        push (@sources,$p)    if(check_file_has_string($p,'endpackage')); 
    }
    foreach my $p (@files){
        push (@sources,$p)    if(check_file_has_string($p,'module')); 
    }
    my %paths;
    foreach my $p (@files){
        my ($name,$path,$suffix) = fileparse("$p",qr"\..[^.]*$");
        #print "$path\n";
        my $remove="$target_dir/";
        $path =~ s/$remove//;     
        $paths{$path}=1;
    }
    my $incdir="set include_dir_list [list";
    foreach my $p (sort keys %paths){
        $incdir.=" \$Dir/$p";    
    }
    $incdir.="]";
    my $files = join ("\n",@sources);
    #add mem initial file to sources
    my $mem_files="";
    my @initial_files = File::Find::Rule->file()
        ->name( '*.mem')
        ->in( "$target_dir/sw" );
    mkpath("$target_dir/Vivado/xilinx_mem",1,01777) unless -f "$target_dir/Vivado/xilinx_mem";
    foreach my $f     (@initial_files){
        #    /home/alireza/work/hca_git/mpsoc_work/SOC/mor1k_soc/sw/RAM/ram0.mif  fpr soc
        #   /home/alireza/work/hca_git/mpsoc_work/MPSOC/newAdder/sw/tile0/RAM/ram0.mif fpr mpsoc
        my @m = split('\/sw\/',$f );
        my $d = $m[-1];#take the last file path name after /sw/
        $d=~ s/RAM//g; #remove RAM
        $d=~ s/\///g; #remove /
        $d = "tile0".$d unless($m[-1]=~/^tile/); #add tile0 to soc
        copy($f,"$target_dir/Vivado/xilinx_mem/$d");
        $mem_files="$mem_files \$tcl_path/xilinx_mem/$d";         
    }
    add_info($tview,"HDL sources:\n$files\nMem sources:\n$mem_files\n");
    #make tcl file
    my $tcl="
#Get tcl shell path relative to current script
set tcl_path    [file dirname [info script]] 
set Dir \"\$tcl_path/..\"
";
    
    $tcl=$tcl."set projectName $name";
    
    $tcl =$tcl."
source \"\$tcl_path/board_property.tcl\" 
#Create output directory and clear contents
set outputdir \"\$tcl_path/xilinx_compile\"";
    $tcl =$tcl.'
file mkdir $outputdir
set files [glob -nocomplain "$outputdir/*"]
if {[llength $files] != 0} {
    puts "deleting contents of $outputdir"
    file delete -force {*}[glob -directory $outputdir *]; # clear folder contents
} else {
    puts "$outputdir is empty"
}

#Create project
create_project  $projectName $outputdir

set_project_properties

#add source files to Vivado project    
';

    #get top level port names
    #get boards pin list
    my $top_v= "$target_dir/src_verilog/Top.v";
    if(!-f $top_v){
        message_dialog("Error: Could not load the board pin list. The Top.v does not exist!",'error');
        $window->destroy;
    }
    my @ports=verilog_file_get_ports_list(read_verilog_file($top_v),"Top");
    #get board tcl
    my $board_name=$self->object_get_attribute('compile','board');
    my @tcls= glob("../boards/$vendor/$board_name/*.tcl");
    foreach my $f (@tcls){
        copy($f,"$target_dir/Vivado");
    }
    #get board xdc
    my @xdcs= glob("../boards/$vendor/$board_name/*.xdc");
    my $i=1;
    
    foreach my $f (@xdcs){
        my $out="";
        #capture file content
        my $string= load_file($f);
        my @lines=split('\n',$string);
        #make sure lines describing the port name are not comment
        foreach my $l (@lines){
            foreach my $p (@ports){
                
                $l=~ s/^\s*#/ /g if($l =~ /^\s*#/   && $l =~  /\[\s*get_ports\s*[{\s]\s*$p[\s\[\]\}]/ );#             /\[get_ports\s*{\s*$p[\s\}\[]/);
                
            }
            $out=$out."$l\n";            
        }    
        my ($fname,$fpath,$fsuffix) = fileparse("$f",qr"\..[^.]*$");
        my $xdc_file = "$target_dir/Vivado/$fname.xdc";
        #save new xdc file
        save_file($xdc_file,$out);                
        #add xdc to tcl file
        $tcl =$tcl."add_files -fileset constrs_1 \$tcl_path/$fname.xdc\n";
        $i++;    
    }    
    #internal clock constrain
    my $clk_xdc=get_clk_constrain_file($self);
    #save_file ("$target_dir/clk.xdc",$clk_xdc);
    #$tcl =$tcl."add_files -fileset constrs_1 \$tcl_path/clk.xdc\n";
    $tcl =$tcl."add_files ";
    #add hdl sources
    foreach my $f (@sources){
        my $p =cut_dir_path($f,'src_verilog');        
        $tcl =$tcl." \$Dir/src_verilog/$p ";    
    }    
    $tcl =$tcl."\n";
    $tcl =$tcl."#add memory initial files to Vivado project
    add_files -norecurse $mem_files" if(length($mem_files)>3);
    $tcl =$tcl."\n set_property \"top\"  \"Top\" [current_fileset]\n";
    $tcl =$tcl."
    update_compile_order -fileset sources_1
    #launch synthesis
    
    # Make all reset syncron 
    set_property verilog_define {{SYNC_RESET_MODE}} [current_fileset]
    
    # include source dirs
    $incdir
    set_property include_dirs  \$include_dir_list [current_fileset]
    
    launch_runs synth_1
    wait_on_run synth_1
    #Run implementation and generate bitstream
    set_property STEPS.PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
    launch_runs impl_1 -to_step write_bitstream
    wait_on_run impl_1
    puts \"Implementation done!\"
    ";
    $tcl =$tcl."\nexit";    
    #creat make_project tcl file
    save_file ("$target_dir/Vivado/make_project.tcl",$tcl);    
    my $error =run_vivado ($self,$target_dir,$tview,"$target_dir/Vivado/make_project.tcl");
    add_colored_info($tview,"Vivado compilation is done successfully in $target_dir/Vivado!\n", 'blue') if($error==0);
    if (defined $end_func){
        if ($error==0){
            $end_func->($self);
            $window->destroy;
        }else {
            message_dialog("Error in Vivado compilation!",'error');    
        }
    }
}    

sub run_vivado {
    my ($self,$target_dir,$tview,$tcl)=@_;
    my $error=0;
    #start compilation
    my $vivado_bin= $self->object_get_attribute('compile','vivado bin');
    add_info($tview, "Start compilation using vivado.....\n");
    my @compilation_command =(
        "cd \"$target_dir/Vivado/\" \n xterm -e bash -c '$vivado_bin/vivado -mode tcl -source $tcl'"        
    );
    save_file("$target_dir/Vivado/run.sh",  "#!/bin/bash \n $vivado_bin/vivado -mode tcl -source $tcl");
    my $log="$target_dir/Vivado/vivado.log";    
    #unlink $log;
    foreach my $cmd (@compilation_command){
        add_info($tview,"$cmd\n");
        my ($stdout,$exit,$stderr)=run_cmd_in_back_ground_get_stdout( $cmd);
        if($exit){
            $error=1;
            add_colored_info($tview, "$stdout\n",'red') if(defined $stdout);
            add_colored_info($tview, "$stderr\n",'red') if(defined $stderr);            
        }
    }    
    #check vivado.log for error
    my $r;
    open my $fd, "<" , $log or $r=$!;
    if(defined $r ) {
        add_colored_info($tview, "could not open $log to check errors: $r\n",'red');
        $error=1;
    }
    else{
        #check error
        while (my $line = <$fd>) {
            chomp $line;
            if( $line =~ /ERROR:/){
                add_colored_info($tview, "$line\n",'red');
                $error=1;
            }
        } 
        #check warning
        close($fd);
        open $fd, "<" , $log;
        #print     "$log\n";
        if($error==0){
            while (my $line = <$fd>) {
                chomp $line;
                if( $line =~ /^\s*WARNING:/){
                    add_info($tview, "$line\n");
                }
            } 
        }
        #check critical warning
        close($fd);
        open $fd, "<" , $log;
        #print     "$log\n";
        if($error==0){
            while (my $line = <$fd>) {
                chomp $line;
                if( $line =~ /^\s*CRITICAL WARNING:/){
                    add_colored_info($tview, "$line\n",'green');
                }
            } 
        }
        close($fd);    
    }
    return $error;    
}

sub modelsim_compilation{
    my ($self,$name,$top,$target_dir,$vendor)=@_;
    #my $window = def_popwin_size(80,80,"Step 2: Compile",'percent');
    my $run=def_image_button('icons/run.png','_run',FALSE,1);
    my $back=def_image_button('icons/left.png','Previous');    
    my $regen=def_image_button('icons/refresh.png','Regenerate testbench.v');    
    #creat modelsim dir
    my $model="$target_dir/Modelsim";
    unlink("$model/model.tcl");
    rmtree("$target_dir/rtl_work");
    mkpath("$model/rtl_work",1,01777);
    my ($app,$table,$tview,$window) = software_main("$target_dir/Modelsim",undef);
    #create testbench.v
    gen_modelsim_soc_testbench ($self,$name,$top,$target_dir,$tview) unless (-f "$target_dir/Modelsim/testbench.v");
    $app->refresh_source("$target_dir/Modelsim/testbench.v");    
    add_info($tview,"create Modelsim dir in $target_dir\n");
    $table->attach($back,1,2,1,2,'shrink','shrink',2,2);
    $table->attach($regen,4,5,1,2,'shrink','shrink',2,2);
    $table->attach ($run,9, 10, 1,2,'shrink','shrink',0,0);
    $regen-> signal_connect("clicked" => sub{
        my $response =  yes_no_dialog("Are you sure you want to regenerate the testbench.v file? Note that any changes you have made will be lost");
        if ($response eq 'yes') {
            gen_modelsim_soc_testbench ($self,$name,$top,$target_dir,$tview);
            $app->refresh_source("$target_dir/Modelsim/testbench.v");    
        }        
    });
    $back-> signal_connect("clicked" => sub{ 
        $window->destroy;
        select_compiler($self,$name,$top,$target_dir);
    });
    
    #Get the list of  all verilog files in src_verilog folder
    add_info($tview,"Get the list of all Verilog files in src_verilog folder\n");
    my @files = File::Find::Rule->file()
        ->name( '*.v','*.V','*.sv' )
        ->in( "$target_dir/src_verilog" );
        
    #get list of all verilog files in src_sim folder 
    my @sim_files = File::Find::Rule->file()
        ->name( '*.v','*.V','*.sv' )
        ->in( "$target_dir/src_sim" );        
    push (@files, @sim_files);    
    #add testnemch.v
    push (@files, "$target_dir/Modelsim/testbench.v");
    
    #create a file list
    my $tt =create_file_list($target_dir,\@files,'modelsim');    
    save_file("$target_dir/Modelsim/file_list.f",  "$tt");
    #create modelsim.tcl file
my $tcl="#!/usr/bin/tclsh

transcript on
if {[file exists rtl_work]} {
    vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work


vlog  +acc=rn  -F $target_dir/Modelsim/file_list.f

vsim -t 1ps  -L rtl_work -L work -voptargs=\"+acc\"  testbench

add wave *
view structure
view signals
run -all
";
    add_info($tview,"Create model.tcl, run.sh files\n");
    save_file ("$model/model.tcl",$tcl);
    my $modelsim_bin= $self->object_get_attribute('compile','modelsim_bin');        
    my $cmd="cd $target_dir/Modelsim; rm -Rf rtl_work; $modelsim_bin/vsim -do $model/model.tcl";
    save_file ("$model/run.sh",'#!/bin/bash'."\n".$cmd);
    $run -> signal_connect("clicked" => sub{
        set_gui_status($self,'save_project',1);
        $app->ask_to_save_changes();
        add_info($tview,"$cmd\n");
        my ($stdout,$exit,$stderr)=run_cmd_in_back_ground_get_stdout($cmd);
        if(length $stderr>1){    
            add_colored_info($tview,"$stderr\n","red");         
        }else {
            add_info($tview,"$stdout\n");
        }            
    });
    #$window->show_all();
}

# source files : $target_dir/src_verilog
# work dir : $target_dir/src_verilog
sub create_file_list {
    my ($target_dir,$files_ref, $platform)=@_;
    my @ff=@{$files_ref} if(defined $files_ref);
    my $pakages=""; 
    my $file_list="";
    my $include="";    
    my %paths;
    my @files = File::Find::Rule->file()
            ->name( '*.v','*.V','*.sv','*.vh')
            ->in( @ff );
    @ff =uniq( @ff);        
    foreach my $file (@files) {
        my ($name,$path,$suffix) = fileparse("$file",qr"\..[^.]*$");
        #print "$path\n";
        my $remove="$target_dir/";
        $path =~ s/$remove//;     
        $paths{$path}=1;
        #put packages at the top of the list 
        if(check_file_has_string($file,'endpackage')){
            $pakages.="../${path}${name}$suffix\n" if($platform eq 'modelsim');
            $pakages.="./${name}$suffix\n" if($platform eq 'verilator');
        } else{
            $file_list.= "../${path}${name}$suffix\n"if($platform eq 'modelsim');
            $file_list.= "./${name}$suffix\n"if($platform eq 'verilator');
        }        
    }
    foreach my $p (sort keys %paths){
        $include.="+incdir+../$p\n";    
    }
    return "$include\n$pakages\n$file_list";
}

sub verilator_compilation {
    my ($top_ref,$target_dir,$outtext,$cpu_num)=@_;
    $cpu_num = 1 if (!defined $cpu_num);
    my %tops = %{$top_ref};
    #creat verilator dir
    add_info($outtext,"create verilator dir in $target_dir\n");
    my $verilator="$target_dir/verilator";
    rmtree("$verilator");
    mkpath("$verilator",1,01777);
    my @ff = ("$target_dir/src_verilog");
    push (@ff,"$target_dir/src_verilator") if (-d "$target_dir/src_verilator");
    push (@ff,"$target_dir/src_sim") if (-d "$target_dir/src_sim");
    #create a file list
    add_info($outtext,"make a file list containig all RTL modules\n");
    my $tt =create_file_list($target_dir,\@ff,'verilator');    
    save_file("$verilator/file_list.f",  "$tt");
    #check if -Wno-TIMESCALEMOD flag is supported"
    my $flag="";
    #   my $cmd ="verilator --version | head -n1 | cut -d\" \" -f2";
    #     my ($stdout,$exit,$stderr)=run_cmd_in_back_ground_get_stdout($cmd);
    #    my $current_v=$stdout;
    #    $current_v =~ s/[^0-9.]//g;
    #    if (defined $current_v){
    #        $cmd = "printf \'%s\n\' \"4.0.0\" \"$current_v\" | sort -V | head -n1";
    #        my ($stdout,$exit,$stderr)=run_cmd_in_back_ground_get_stdout($cmd);
    #        $stdout =~ s/[^0-9.]//g;
    #        if ($stdout eq "4.0.0" ){
    #            add_info($outtext, "Verilator vesrion $current_v is Greater than or equal to 4.0.0. So compile with -Wno-TIMESCALEMOD flag\n");
    #            $flag.="-Wno-TIMESCALEMOD";
    #        }else{
    #             add_info($outtext, "Verilator vesrion is $current_v\n");
    #        }
    #     }
    my $pdir      = get_project_dir();
    my $tmp = "$pdir/mpsoc/perl_gui/lib/verilog/tmp.v";
    my $cmd = "verilator --lint-only $tmp  -Wno-TIMESCALEMOD";
    my ($stdout,$exit,$stderr)=run_cmd_in_back_ground_get_stdout($cmd); 
    
    if(length $stderr>1){    #-Wno-TIMESCALEMOD not supported        
        #add_info($outtext,"$stderr\n"); #verilator compain some ignoerabe warnning as error.  
    }else {
        #add_info($outtext,"compile verilator with -Wno-TIMESCALEMOD\n");
        $flag.="-Wno-TIMESCALEMOD";
    }     
    
    #run verilator
    my $jobs=0; #a counter to limit the number of paralle process 
    my $make_lib=""; 
    $cmd="cd \"$verilator\"; ";
    my $vrun="#!/bin/bash
cd \"$verilator\"
";
    #my $cmd= "cd \"$verilator/processed_rtl\" \n xterm -e bash -c ' verilator  --cc $name.v --profile-cfuncs --prefix \"Vtop\" -O3  -CFLAGS -O3'";
    my $length = scalar (keys %tops);
    foreach my $top (sort keys %tops) {
        add_colored_info($outtext,"Generate $top Verilator model from $tops{$top} file\n",'green');
        $cmd.= "verilator -DNO_HETRO_IVC=1 -f ./file_list.f --cc $tops{$top}  --prefix \"$top\" $flag -O3  -CFLAGS -O3 & ";
        $vrun.="verilator -DNO_HETRO_IVC=1 -f ./file_list.f --cc $tops{$top}  --prefix \"$top\" $flag -O3  -CFLAGS -O3 &\n";
        
        $make_lib.="make lib$jobs &\n";
        $jobs++;
        
        if( $jobs % $cpu_num == 0 || $jobs == $length){
            $vrun.="wait\n"; $make_lib.="wait\n"; $cmd.="wait\n";
            add_info($outtext,"$cmd\n");    
            my ($stdout,$exit,$stderr)=run_cmd_in_back_ground_get_stdout($cmd);
            if(length $stderr>1){            
                add_info($outtext,"$stderr\n"); #verilator compain some ignoerabe warnning as error.  
            }else {
                add_info($outtext,"$stdout\n");
            }
            $cmd="cd \"$verilator\"; ";
        }            
    }
    #check if verilator model has been generated 
    foreach my $top (sort keys %tops) {
        
        $vrun.=" 
if ! [ -f $verilator/obj_dir/$top.cpp ]; then
    echo  \"Failed to generate: $verilator/obj_dir/$top.cpp \"
    exit 1    
fi
";
        if (-f "$verilator/obj_dir/$top.cpp"){#succsess
        }else {
            return 0;
        }    
    }
    #generate makefile
    gen_verilator_makefile($top_ref,"$verilator/obj_dir/Makefile");
    
$vrun.="    echo  \"Verilator modules are generated successfully\". 

cd $verilator/obj_dir/

#run make file 
$make_lib

make sim
#done
";
    save_file ("$verilator/verilate.sh",$vrun);
    #copy topology connection header files
    my $project_dir    = get_project_dir();
    $project_dir= "$project_dir/mpsoc";
    my $src_verilator_dir="$project_dir/src_verilator";
    my @files = File::Find::Rule->file()
            ->name( '*.h')
            ->in( "$src_verilator_dir" );
    copy_file_and_folders (\@files,$project_dir,"$verilator/obj_dir/");
    
    return 1;
}

sub verilator_compilation_win {
    my ($self,$name,$top,$target_dir,$vendor)=@_;
    my $window = def_popwin_size(80,80,"Step 2: Compile",'percent');
    my $mtable = def_table(10, 10, FALSE);
    my ($outbox,$outtext)= create_txview();   
    
    my $next=def_image_button('icons/run.png','Next');
    my $back=def_image_button('icons/left.png','Previous');    
    my $load= show_gif("icons/load.gif");
    $mtable->attach($load,8,9,9,10,'shrink','shrink',2,2);
    
    $mtable->attach_defaults ($outbox ,0, 10, 4,9);
    $mtable->attach($back,2,3,9,10,'shrink','shrink',2,2);    
    $back-> signal_connect("clicked" => sub{ 
        $window->destroy;
        select_compiler($self,$name,$top,$target_dir);
        
    });
    $next-> signal_connect("clicked" => sub{ 
        
        $window->destroy;
        verilator_testbench($self,$name,$top,$target_dir,$vendor);
        
    });

    $window->add ($mtable);
    $window->show_all();
    my $result;
    my $cpu_num = $self->object_get_attribute('compile', 'cpu_num');
    my $n= $self->object_get_attribute('soc_name',undef);
    if(defined $n){    #we are compiling a single tile as SoC
        my $sw_path     = "$target_dir/sw";
        my %params = soc_get_all_parameters($self);
        my $verilator = soc_generate_verilator ($self,$sw_path,"verilator_$n",\%params);    
        my %tops;
        $tops{"Vtop"}= "--top-module verilator_$n";
        my $target_verilator_dr ="$target_dir/src_verilator";
        mkpath("$target_verilator_dr",1,01777);
        save_file ("$target_verilator_dr/verilator_${n}.sv",$verilator);    
        #$tops{"Vtop"}= "--top-module $name";
        $result = verilator_compilation (\%tops,$target_dir,$outtext,$cpu_num);    
        $self->object_add_attribute('verilator','libs',\%tops);    
    }
    else { # we are compiling a complete NoC-based mpsoc
        $result = gen_mpsoc_verilator_model ($self,$name,$top,$target_dir,$outtext,$cpu_num);        
    }
    #check if verilator model has been generated 
    if ($result){
        add_colored_info($outtext,"Veriator model has been generated successfully!",'blue');
        $load->destroy();
        $mtable->attach($next,8,9,9,10,'shrink','shrink',2,2);
    }else {
        add_colored_info($outtext,"Verilator compilation failed!\n","red"); 
        $load->destroy();
        $next->destroy();
    }            
}

sub  gen_mpsoc_verilator_model{
    my ($self,$name,$top,$target_dir,$outtext,$cpu_num)=@_;    
    my $project_dir    = get_project_dir();
    $project_dir= "$project_dir/mpsoc";
    my $src_verilator_dir="$project_dir/src_verilator";
    my $target_verilog_dr ="$target_dir/src_verilog";
    my $target_verilator_dr ="$target_dir/src_verilator";
    
    my $sw_dir     = "$target_dir/sw";
    my $src_noc_dir="$project_dir/rtl/src_noc";    
    mkpath("$target_verilator_dr",1,01777);
    #copy src_verilator files
    my @files_list = File::Find::Rule->file()
                            ->name( '*.v','*.V','*.sv' )
                            ->in( "$src_verilator_dir" );

    #make sure source files have key word 'module' 
    my @files;
    foreach my $p (@files_list){
        push (@files,$p)    if(check_file_has_string($p,'module')); 
    }
    copy_file_and_folders (\@files,$project_dir,$target_verilator_dr);
    #copy src_noc files
    #my @files2;
    #push (@files2,$src_noc_dir);
    #copy_file_and_folders (\@files2,$project_dir,$target_verilog_dr);
    #create each tile top module     
    my $processors_en=0;
    my $mpsoc=$self;    
    my $lisence= get_license_header("verilator_tiles"); 
    my $warning=autogen_warning();    
    my $verilator=$lisence.$warning;
    # generate NoC parameter file
    my ($noc_param,$pass_param)=gen_noc_param_v($self);
    my $noc_param_v= " \`ifdef     INCLUDE_PARAM \n \n 
    $noc_param  
    
    //simulation parameter    
    
\n \n \`endif" ; 
    #save_file("$target_verilator_dr/parameter.v",$noc_param_v);
    my ($nr,$ne,$router_p,$ref_tops)= get_noc_verilator_top_modules_info($self);
    my %tops = %{$ref_tops};
    for (my $tile_num=0;$tile_num<$ne;$tile_num++){
        #print "$tile_num\n";
        my ($soc_name,$num)= $mpsoc->mpsoc_get_tile_soc_name($tile_num);
        my $soc=eval_soc($mpsoc,$soc_name,$outtext);
        my $top=$mpsoc->mpsoc_get_soc($soc_name);
        my $soc_num= $tile_num;        
        #update core id
        $soc->object_add_attribute('global_param','CORE_ID',$tile_num);
        #update NoC param
        my $nocparam =$mpsoc->object_get_attribute('noc_param',undef);
        my ($NE, $NR, $RAw, $EAw, $Fw) = get_topology_info($mpsoc);
        my %y=%{$nocparam};
        $y{'EAw'} = $EAw;
        $y{'RAw'} = $RAw;
        $y{'Fw'}  = $Fw;         
        my @nis=get_NI_instance_list($top);
        $soc->soc_add_instance_param($nis[0] ,\%y );
        my %z;
        my %param_type=  $soc->soc_get_module_param_type($nis[0]); 
        foreach my $p (sort keys %y){
            $z{$p}=$param_type{$p}; #"Parameter";
        }
        $soc->soc_add_instance_param_type($nis[0] ,\%z );
        my $tile=$tile_num;
        my $setting=$mpsoc->mpsoc_get_tile_param_setting($tile);
        my %params;
        #if ($setting eq 'Custom'){
        %params= $top->top_get_custom_soc_param($tile);
        #}else{
        #     %params=$top->top_get_default_soc_param();
        #}
        my $sw_path     = "$sw_dir/tile$tile_num";
        $verilator = $verilator.soc_generate_verilator ($soc,$sw_path,"tile_$tile",\%params);    
        $tops{"Vtile$tile_num"}= "--top-module tile_$tile";
    }
    save_file ("$target_verilator_dr/verilator_tiles.sv",$verilator);
    my $result = verilator_compilation (\%tops,$target_dir,$outtext,$cpu_num);
    $self->object_add_attribute('verilator','libs',\%tops);        
    return $result;
}

sub gen_verilator_soc_testbench {
    my ($self,$name,$top,$target_dir)=@_;
    my $verilator="$target_dir/verilator";
    my $dir="$verilator/";
    my $soc_top= $self->soc_get_top ();
    my $include='#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
';
    my @intfcs=$soc_top->top_get_intfc_list();
    my %PP;
    my %rxds;
    my $top_port_info="IO type\t  port_size\t  port_name\n";
    foreach my $intfc (@intfcs){
        my $key= ( $intfc eq 'plug:clk[0]')? 'clk' : 
            ( $intfc eq 'plug:reset[0]')? 'reset':
            ( $intfc eq 'plug:enable[0]')? 'en' : 
            ( $intfc eq  'socket:RxD_sim[0]')? 'rxd':
            'other';
        my $key1="${key}1";
        my $key0="${key}0";
        my @ports=$soc_top->top_get_intfc_ports_list($intfc);
        foreach my $p (@ports){
            my($inst,$range,$type,$intfc_name,$intfc_port)= $soc_top->top_get_port($p);
            $PP{$key1}= (defined $PP{$key1})? "$PP{$key1} top->$p=1;\n" : "top->$p=1;\n";
            $PP{$key0}= (defined $PP{$key0})? "$PP{$key0} top->$p=0;\n" : "top->$p=0;\n";    
            $top_port_info="$top_port_info $type  $range  top->$p \n";
        }
        if($key eq 'rxd'){
            my @ports=$soc_top->top_get_intfc_ports_list($intfc);
            foreach my $p (@ports){
                my($id,$range,$type,$intfc_name,$intfc_port)= $soc_top->top_get_port($p);
                my @q =split  (/RxD_ready_si/,$p);
                $rxds{$id}{p}=$q[0]  if( defined $q[1]);
                $rxds{$id}{top}='top'  if( defined $q[1]);
            }            
        }
    }
    my ($rxd_info, $rxd_num, $rxd_wr_cal,$rxd_cap_cal, $include1)=rxd_testbench_verilator_gen (\%rxds,$dir);
    my $include2="";
 $include2 .= '#include "RxDsim.h" // Header file for sending charactor to UART from STDIN' if($rxd_num > 0);
    
my $main_c=get_license_header("testbench.cpp");

$main_c="$main_c
$include
$include1
#include <verilated.h>          // Defines common routines
#include \"Vtop.h\"               // From Verilating \"$name.v\" file
Vtop             *top;
$include2
/*
$top_port_info
*/



int reset,clk;
unsigned int main_time = 0; // Current simulation time

int main(int argc, char** argv) {
    $rxd_info
    Verilated::commandArgs(argc, argv);   // Remember args
    top    = new Vtop;

    /********************
    *    initialize input
    *********************/

    $PP{reset1}
    $PP{en1}  
    main_time=0;
    printf(\"Start Simulation\\n\");
    while (!Verilated::gotFinish()) {
        $rxd_cap_cal
        if ((main_time & 0x3FF)==0) fflush(stdout); // fflush \$dispaly command each 1024 clock cycle 
        if (main_time >= 10 ) { 
            $PP{reset0}
        }    

        if ((main_time & 1) == 0) {
            $PP{clk1}      // Toggle clock
            // you can change the inputs and read the outputs here in case they are captured at posedge of clock 
            $rxd_wr_cal


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

sub eval_soc{
    my ($mpsoc,$soc_name,$outtext)=@_;
    my $path=$mpsoc->object_get_attribute('setting','soc_path');    
    $path=~ s/ /\\ /g;
    my $p = "$path/$soc_name.SOC";
    my ($soc,$r,$err) = regen_object($p);
    if ($r){        
        show_info($outtext,"**Error reading  $p file: $err\n");
        next; 
    } 
    return $soc;    
}

sub rxd_testbench_verilator_gen {
my     ($rxds_ref,$dir)=@_;
my $rxd_info='';
my $rxd_num=0;
my $rxd_func='';
my $rxd_wr_cal='';
my $rxd_cap_cal='';
my $include='';

my %rxds=%{$rxds_ref};
foreach my $rxd (sort keys %rxds){
    my $n=$rxds{$rxd}{p};
    my $top=$rxds{$rxd}{top};
    $rxd_info.="\\t$rxd_num : ${top}_${n}RXD\\n";
    $rxd_func.="
    // we have a character to send to interface $rxd_num
    if (sent_table[$rxd_num]!=0 &&  $top->${n}RxD_ready_sim){ 
        $top->${n}RxD_din_sim=sent_table[$rxd_num]; 
        $top->${n}RxD_wr_sim=1; 
        sent_table[$rxd_num]=0;
    }else {
        $top->${n}RxD_wr_sim=0; 
    }
";
    $rxd_num++;
} 



if($rxd_num>0){    
$rxd_func="
#ifndef RXD_SIM_H
#define RXD_SIM_H
    #define RXD_NUM  $rxd_num  // number of rxd input interfaces
    char sent_table[RXD_NUM]={0};    
    unsigned char active_rxd_num=0;    
    void write_char_on_RXD( ) {            
        $rxd_func    
    }
    
    int kbhit(void) {
        struct termios oldt, newt;
        int ch;
        int oldf;
        
        tcgetattr(STDIN_FILENO, &oldt);
        newt = oldt;
        newt.c_lflag &= ~(ICANON | ECHO);
        tcsetattr(STDIN_FILENO, TCSANOW, &newt);
        oldf = fcntl(STDIN_FILENO, F_GETFL, 0);
        fcntl(STDIN_FILENO, F_SETFL, oldf | O_NONBLOCK);
        
        ch = getchar();     
        
        tcsetattr(STDIN_FILENO, TCSANOW, &oldt);
        fcntl(STDIN_FILENO, F_SETFL, oldf);
        
        if(ch != EOF)
        {
            ungetc(ch, stdin);
            return 1;
        }     
        return 0;
    }
    
    void capture_char_on_RXD (){
        char c;
        if(kbhit()){
            c=getchar();
            if(c=='+'){
                active_rxd_num++;                
                if(active_rxd_num>=$rxd_num) active_rxd_num=0;
                printf(\"The active input interface num is \%u\\n\",active_rxd_num);
            }else if(c=='-'){
                active_rxd_num--;                
                if(active_rxd_num>=$rxd_num) active_rxd_num=($rxd_num-1);
                printf(\"The active input interface num is \%u\\n\",active_rxd_num);
            }else{
                sent_table[active_rxd_num]=c;
            }            
        }    
    }
#endif    
    ";
    
    
    $include .='#include <termios.h>
#include <fcntl.h>
';
    $rxd_wr_cal="write_char_on_RXD( );";
    $rxd_cap_cal="capture_char_on_RXD( );"; 
    $rxd_info="printf(\"There are total of $rxd_num RXD (UART) interface ports in the top module:\\n${rxd_info}The default interfce is 0. You can switch to different interfaces by pressing + or - key.\\n\");"    
}

    my $rxsim_c=get_license_header("RxDsim.h");
    $rxsim_c.="$rxd_func";
    save_file("$dir/RxDsim.h",$rxsim_c) if($rxd_num > 0);
    return ($rxd_info, $rxd_num, $rxd_wr_cal,$rxd_cap_cal, $include);
    
}

sub gen_verilator_mpsoc_testbench {
    my ($mpsoc,$name,$top,$target_dir,$tview)=@_;
    my $verilator="$target_dir/verilator";
    my $dir="$verilator/";
    my $parameter_h=gen_noc_param_h($mpsoc);
    
    
    my ($nr,$ne,$router_p,$ref_tops,$includ_h)= get_noc_verilator_top_modules_info($mpsoc);
    
    $parameter_h.="
    #define NE  $ne
    #define NR  $nr
    ";
    $parameter_h=$parameter_h.$includ_h;
    

    
    my $libh="";
    my $inst= "";
    my $newinst="";
    
    my $tile_addr="";
    my $tile_flit_in="";
    my $tile_flit_in_l="";
    my $tile_credit="";
    my $noc_credit="";
    my $noc_flit_in="";
    my $noc_flit_in_l="";    
    my $noc_flit_in_wr="";
    my $noc_flit_in_wr_l="";
    my $tile_flit_in_wr="";    
    my $tile_flit_in_wr_l="";
    my $tile_eval="";
    my $tile_final="";     
    my $tile_reset="";    
    my $tile_clk="";    
    my $tile_en="";        
    my $top_port_info="IO type\t  port_size\t  port_name\n";    
    my $no_connected='';
    my %rxds;
    
    my $tile_chans="";
    my $tmp_reg='';
    for (my $endp=0; $endp<$ne;$endp++){    
        my $e_addr=endp_addr_encoder($mpsoc,$endp);
        my $router_num = get_connected_router_id_to_endp($mpsoc,$endp);
        my $r_addr=router_addr_encoder($mpsoc,$router_num);
        my ($soc_name,$num)= $mpsoc->mpsoc_get_tile_soc_name($endp);        
        if(defined $soc_name) {#we have a conncted tile
        
            #get ni instance name
            my $ni_name;
            my $soc=eval_soc($mpsoc,$soc_name,$tview);
            my $soc_top=$soc->object_get_attribute('top_ip',undef);
            my @intfcs=$soc_top->top_get_intfc_list();
            my @instances=$soc->soc_get_all_instances();
            foreach my $id (@instances){
                    my $category = $soc->soc_get_category($id);
                    if ($category eq 'NoC') {
                        $ni_name=  $soc->soc_get_instance_name($id);
                    }
            }
                $tile_chans.="\ttile_chan_out[$endp] = &tile$endp->ni_chan_out;\n\ttile_chan_in[$endp] = &tile$endp->ni_chan_in;\n";
                $libh=$libh."#include \"Vtile${endp}.h\"\n";
                $inst=$inst."Vtile${endp}\t*tile${endp};\t  // Instantiation of tile${endp}\n";
                $newinst = $newinst."\ttile${endp}\t=\tnew Vtile${endp};\n"; 
                $tile_flit_in = $tile_flit_in . "\ttile${endp}->${ni_name}_flit_in  = noc->ni_flit_out [${endp}];\n";    
                $tile_flit_in_l = $tile_flit_in_l . "\t\ttile${endp}->${ni_name}_flit_in[j]  = noc->ni_flit_out [${endp}][j];\n";
                $tile_credit= $tile_credit."\ttile${endp}->${ni_name}_credit_in= noc->ni_credit_out[${endp}];\n";
                $noc_credit= $noc_credit."\tnoc->ni_credit_in[${endp}] = tile${endp}->${ni_name}_credit_out;\n";    
                $noc_flit_in=$noc_flit_in."\tnoc->ni_flit_in [${endp}]  = tile${endp}->${ni_name}_flit_out;\n";
                $noc_flit_in_l=$noc_flit_in_l."\t\t\tnoc->ni_flit_in [${endp}][j]  = tile${endp}->${ni_name}_flit_out[j];\n";
                $noc_flit_in_wr= $noc_flit_in_wr."\tif(tile${endp}->${ni_name}_flit_out_wr) noc->ni_flit_in_wr = noc->ni_flit_in_wr | ((vluint64_t)1<<${endp});\n";
                $tile_flit_in_wr=$tile_flit_in_wr."\ttile${endp}->${ni_name}_flit_in_wr= ((noc->ni_flit_out_wr >> ${endp}) & 0x01);\n";
                $noc_flit_in_wr_l= $noc_flit_in_wr_l."\tif(tile${endp}->${ni_name}_flit_out_wr) MY_VL_SETBIT_W(noc->ni_flit_in_wr ,${endp});\n";
                $tile_flit_in_wr_l=$tile_flit_in_wr_l."\ttile${endp}->${ni_name}_flit_in_wr=   (VL_BITISSET_W(noc->ni_flit_out_wr,${endp})>0);\n";
                $tile_eval=$tile_eval."\ttile${endp}->eval();\n";
                $tile_final=$tile_final."\ttile${endp}->final();\n";                 
                foreach my $intfc (@intfcs){
                    my $key=($intfc eq 'plug:clk[0]')? 'clk' : 
                            ($intfc eq 'plug:reset[0]')? 'reset':
                            ($intfc eq 'plug:enable[0]')? 'en' :
                            ($intfc eq 'socket:RxD_sim[0]')? 'rxd': 
                            'other';

                    my @ports=$soc_top->top_get_intfc_ports_list($intfc);
                    foreach my $p (@ports){
                        my($inst,$range,$type,$intfc_name,$intfc_port)= $soc_top->top_get_port($p);
                        $tile_reset=$tile_reset."\t\ttile${endp}->$p=reset;\n" if $key eq 'reset';    
                        $tile_clk=$tile_clk."\t\ttile${endp}->$p=clk;\n" if $key eq 'clk';        
                        $tile_en=$tile_en."\t\ttile${endp}->$p=enable;\n" if $key eq 'en';    ;        
                        $top_port_info="$top_port_info $type  $range  tile${endp}->$p \n";
                    }#ports
                    
                    if($key eq 'rxd'){
                        my @ports=$soc_top->top_get_intfc_ports_list($intfc);
                        foreach my $p (@ports){
                            my($id,$range,$type,$intfc_name,$intfc_port)= $soc_top->top_get_port($p);
                            my @q =split  (/RxD_ready_si/,$p);
                            $rxds{$endp.$id}{p}=$q[0]  if( defined $q[1]);
                            $rxds{$endp.$id}{top}="tile$endp"  if( defined $q[1]);
                        }            
                    }
                }#interface
                $tile_addr= $tile_addr."\ttile${endp}->${ni_name}_current_r_addr=$r_addr; // noc->er_addr[${endp}];\n";
                $tile_addr= $tile_addr."\ttile${endp}->${ni_name}_current_e_addr=$e_addr;\n";
            }else{
                #this tile is not connected to any ip. the noc input ports will be connected to ground
                $tmp_reg.="\tunsigned char tmp1 [1024]={0};\n \tunsigned char tmp2 [1024]={0};";
                $tile_chans.="\n // Tile:$endp ($e_addr)   is not assigned to any ip. Connet coresponding chan to ground.\n";
                $tile_chans.="\ttile_chan_out[$endp] = tmp1;\n\ttile_chan_in[$endp] = tmp2;\n";
            }
    }
    my ($rxd_info, $rxd_num, $rxd_wr_cal,$rxd_cap_cal, $include1)=rxd_testbench_verilator_gen (\%rxds,$dir);
    my $include2="";
    $include2 .= '#include "RxDsim.h" // Header file for sending charactor to UART from STDIN' if($rxd_num > 0);
    my $main_c=get_license_header("testbench.cpp");
$main_c="$main_c
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
$include1
#include <verilated.h>          // Defines common routines
$tmp_reg


$libh


$inst
int reset,clk,enable;


#include \"parameter.h\"
void * tile_chan_out[NE];
void * tile_chan_in[NE];



#define CHAN_SIZE   sizeof(tile0->ni_chan_in)

#define conect_r2r(T1,r1,p1,T2,r2,p2)  \\
    memcpy(&router##T1 [r1]->chan_in[p1] , &router##T2 [r2]->chan_out[p2], CHAN_SIZE )

#define connect_r2gnd(T,r,p)\\
    memset(&router##T [r]->chan_in [p],0x00,CHAN_SIZE)

#define connect_r2e(T,r,p,e) \\
    memcpy(&router##T [r]->chan_in[p], tile_chan_out[e], CHAN_SIZE );\\
    memcpy(tile_chan_in[e], &router##T [r]->chan_out[p], CHAN_SIZE )



#include \"topology_top.h\"
$include2

/*
$top_port_info
*/


unsigned int main_time = 0; // Current simulation time



void connect_clk_reset_en_all(void){
    //clk,reset,enable
$tile_reset
$tile_clk        
$tile_en
    connect_routers_reset_clk();    
}

void sim_eval_all(void){
        routers_eval();
$tile_eval
}

void sim_final_all(void ){
    routers_final();    
$tile_final    
}    

void clk_posedge_event(void) {

    clk = 1;       // Toggle clock
    // you can change the inputs and read the outputs here in case they are captured at posedge of clock 
    $rxd_wr_cal    
    connect_clk_reset_en_all();
    sim_eval_all();
}


void clk_negedge_event(void){

    clk = 0;
    topology_connect_all_nodes ();
    connect_clk_reset_en_all();
    sim_eval_all();    
}    


int main(int argc, char** argv) {
    int i,j,x,y;
    $rxd_info
    Verilated::commandArgs(argc, argv);   // Remember args
    Vrouter_new();             // Create instance
    
$newinst
    
    /********************
    *    initialize input
    *********************/
    $tile_chans
    
    reset=1;
    enable=1;
    topology_init();
    
    $no_connected
    
$tile_addr


    main_time=0;
    printf(\"Start Simulation\\n\");
    while (!Verilated::gotFinish()) {
        $rxd_cap_cal
        if ((main_time & 0x3FF)==0) fflush(stdout); // fflush \$dispaly command each 1024 clock cycle 
        if (main_time >= 10 )     reset=0;
        
        clk_posedge_event( );
        //The valus of all registers and input ports valuse change @ posedge of the clock. Once clk is deasserted,  as multiple modules are connected inside the testbench we need several eval for propogating combinational logic values 
        //between modules when the clock . 
        for (i=0;i<2*(SMART_MAX+1);i++) clk_negedge_event( );

        main_time++;  
    }//while
    
    // Simulation is done
    sim_final_all();
}

double sc_time_stamp () {       // Called by \$time in Verilog
    return main_time;
}


";

    save_file("$dir/parameter.h",$parameter_h);    
    save_file("$dir/testbench.cpp",$main_c);    

}

sub soc_get_all_parameters {
    my $soc=shift;    
    my @instances=$soc->soc_get_all_instances();
    my %all_param; 
    foreach my $id (@instances){
        
        my $module     =$soc->soc_get_module($id);
        my $category     =$soc->soc_get_category($id);    
        my $inst       = $soc->soc_get_instance_name($id);
        my %params    = $soc->soc_get_module_param($id);
        my %params_type    = $soc->soc_get_module_param_type($id);
        my $ip = ip->lib_new ();        
        my @param_order=$soc->soc_get_instance_param_order($id);
        foreach my $p (sort keys %params){
            my $inst_param= "$inst\_$p";
            #add instance name to parameter value
            $params{$p}=add_instantc_name_to_parameters(\%params,$inst,$params{$p});
            my ($default,$type,$content,$info,$vfile_param_type,$redefine_param)= $ip->ip_get_parameter($category,$module,$p);
            
            $vfile_param_type= "Don't include" if (!defined $vfile_param_type );
            if ($vfile_param_type eq "Localparam"){
                my $type = $params_type{$p};
                $type = "Localparam" if (! defined $type);    
                $vfile_param_type = ($type eq 'Parameter')?  "Parameter" : "Localparam";
            }
            #$vfile_param_type= "Parameter"  if ($vfile_param_type eq 1);
            #$vfile_param_type= "Localparam" if ($vfile_param_type eq 0);        
            $all_param{ $inst_param} =     $params{ $p} if($vfile_param_type eq "Parameter" || $vfile_param_type eq "Localparam"  );    
            #print"$all_param{ $inst_param} =     $params{ $p} if($vfile_param_type eq \"Parameter\" || $vfile_param_type eq \"Localparam\"  );    \n";    
        }
    }
    return %all_param;
}

sub soc_get_all_parameters_order {
    my $soc=shift;    
    my @instances=$soc->soc_get_all_instances();
    my $ip = ip->lib_new ();        
    my @all_order; 
    foreach my $id (@instances){
        my $module     =$soc->soc_get_module($id);
        my $category     =$soc->soc_get_category($id);    
        my $inst       = $soc->soc_get_instance_name($id);
        my @order    = $soc->soc_get_instance_param_order($id);
        my %params_type    = $soc->soc_get_module_param_type($id);
        foreach my $p ( @order){
            my $inst_param= "$inst\_$p";
            my ($default,$type,$content,$info,$vfile_param_type,$redefine_param)= $ip->ip_get_parameter($category,$module,$p);
            $vfile_param_type= "Don't include" if (!defined $vfile_param_type );
            if ($vfile_param_type eq "Localparam"){
                my $type = $params_type{$p};
                $type = "Localparam" if (! defined $type);    
                $vfile_param_type = ($type eq 'Parameter')?  "Parameter" : "Localparam";
            }
            #$vfile_param_type= "Parameter"  if ($vfile_param_type eq 1);
            #$vfile_param_type= "Localparam" if ($vfile_param_type eq 0);        
            push(@all_order, $inst_param) if($vfile_param_type eq "Parameter" || $vfile_param_type eq "Localparam"  );                
        }
    }
    return @all_order;
}

sub gen_modelsim_soc_testbench {
    my ($self,$name,$top,$target_dir,$tview)=@_;
    my $dir="$target_dir/Modelsim";
    my $soc_top= $self->object_get_attribute('top_ip',undef);
    my @intfcs=$soc_top->top_get_intfc_list();
    my %PP;
    my $top_port_def="// ${name}.v IO definition \n";
    my $pin_assign;
    my $rst_inputs='';
    #add functions
    my $project_dir      = get_project_dir();
    open my $file1, "<", "$project_dir/mpsoc/perl_gui/lib/verilog/functions.v" or die;
    my $functions_all='';
    while (my $f1 = readline ($file1)) {    
        $functions_all="$functions_all $f1 ";
    }
    close($file1);
    #get parameters
    my $params_v="";
    my $n= $self->object_get_attribute('soc_name',undef);
    if(defined $n){    #we are compiling a single tile as SoC
        my $core_id= $self->object_get_attribute('global_param','CORE_ID');
        my $sw_loc = $self->object_get_attribute('global_param','SW_LOC');    
    
            $params_v="\tlocalparam\tCORE_ID=$core_id;
\tlocalparam\tSW_LOC=\"$sw_loc\";\n";
        my %params=soc_get_all_parameters($self);
        my @order= soc_get_all_parameters_order($self);        
        foreach my $p (@order){
            add_text_to_string(\$params_v,"\tlocalparam  $p = $params{$p};\n") if(defined $params{$p} );            
        }
    }else{ # we are simulating a mpsoc
        $params_v= gen_socs_param($self);        
    }
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
#                #replace parameter with their values        #
#                my @a= split (/\b/,$range);
#                print "a=@a\n";
#                foreach my $l (@a){
#                    my $value=$params{$l};
#                    if(defined $value){
#                        chomp $value;
#                        ($range=$range)=~ s/\b$l\b/$value/g      if(defined $params{$l});
#                        print "($range=$range)=~ s/\b$l\b/$value/g      if(defined $params{$l}); \n";
#                    }
#                }
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
my $global_localparam=get_golal_param_v();    
my $test_v= get_license_header("testbench.v");

my $mpsoc_name=$self->object_get_attribute('mpsoc_name');
#if(defined $mpsoc_name){
    if(0){
    my $top_ip=ip_gen->top_gen_new();
    my $target_dir  = "$ENV{'PRONOC_WORK'}/MPSOC/$mpsoc_name";
    my $hw_dir     = "$target_dir/src_verilog";
    my $sw_dir     = "$target_dir/sw";
    my ($socs_v,$io_short,$io_full,$top_io_short,$top_io_full,$top_io_pass,$href)=gen_socs_v($self,$top_ip,$sw_dir,$tview);
    my $socs_param= gen_socs_param($self);
    my $global_localparam=get_golal_param_v();
    my ($clk_set, $clk_io_sim,$clk_io_full, $clk_assigned_port)= get_top_clk_setting($self);

$test_v.="

$clk_set, $clk_io_sim,$clk_io_full, $clk_assigned_port

`timescale     1ns/1ps

module testbench;

$functions_all

$global_localparam    

$socs_param

$top_port_def


\t${mpsoc_name} the_${mpsoc_name} (
$top_io_pass

\t);
/*****************************************************************/
";


}

$test_v    ="$test_v

`timescale     1ns/1ps

module testbench;

$functions_all

$global_localparam
    
$params_v

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
    my ($self,$name,$top,$target_dir,$vendor)=@_;
    my $verilator="$target_dir/verilator";
    my $dir="$verilator";
    
    my ($app,$table,$tview,$window) = software_main($dir,'testbench.cpp');
    
    my $n= $self->object_get_attribute('soc_name',undef);
    if(defined $n){    #we are compiling a single tile as SoC
        gen_verilator_soc_testbench (@_) if((-f "$dir/testbench.cpp")==0);         
    }
    else { # we are compiling a complete NoC-based mpsoc
        gen_verilator_mpsoc_testbench (@_,$tview) if((-f "$dir/testbench.cpp")==0);         
    }
    #copy makefile
    #copy("../script/verilator_soc_make", "$verilator/obj_dir/Makefile"); 
    my $make = def_image_button('icons/gen.png','Compile');
    my $regen=def_image_button('icons/refresh.png','Regenerate Testbench.cpp');    
    my $run = def_image_button('icons/run.png','Run');
    my $back=def_image_button('icons/left.png','Previous');    
    $table->attach ($back,1,2,1,2,'shrink','shrink',0,0);
    $table->attach ($regen,3,4,1,2,'shrink','shrink',0,0);
    $table->attach ($make,6, 7, 1,2,'shrink','shrink',0,0);    
    $table->attach ($run,9, 10, 1,2,'shrink','shrink',0,0);
    $back-> signal_connect("clicked" => sub{ 
        $window->destroy;
        verilator_compilation_win($self,$name,$top,$target_dir,$vendor);
    });

    $regen-> signal_connect("clicked" => sub{
        my $response = yes_no_dialog("Are you sure you want to regenerate the testbench.cpp file? Note that any changes you have made will be lost");
        if ($response eq 'yes') {
            my $n= $self->object_get_attribute('soc_name',undef);
            if(defined $n){    #we are compiling a single tile as SoC
                gen_verilator_soc_testbench ($self,$name,$top,$target_dir);         
            }
            else { # we are compiling a complete NoC-based mpsoc
                gen_verilator_mpsoc_testbench ($self,$name,$top,$target_dir,$tview);         
            }
            $app->refresh_source("$dir/testbench.cpp");    
        }    
    });
    $make -> signal_connect("clicked" => sub{
        $make->hide;
        my $load= show_gif("icons/load.gif");
        $table->attach ($load,8, 9, 1,2,'shrink','shrink',0,0);
        $table->show_all;
        $app->ask_to_save_changes();
        copy("$dir/testbench.cpp", "$verilator/obj_dir/testbench.cpp"); 
        copy("$dir/parameter.h", "$verilator/obj_dir/parameter.h") if(-f "$dir/parameter.h"); 
        copy("$dir/RxDsim.h", "$verilator/obj_dir/RxDsim.h") if(-f "$dir/RxDsim.h");
        my $tops_ref=$self->object_get_attribute('verilator','libs');
        my %tops=%{$tops_ref};
        my $lib_num=0;
        my $cpu_num = $self->object_get_attribute('compile', 'cpu_num');
        $cpu_num = 1 if (!defined $cpu_num);
        add_colored_info($tview,"Makefie will use the maximum number of $cpu_num core(s) in parallel for compilation\n",'green');
        my $length=scalar (keys %tops);
        my $cmd="";
        foreach my $top (sort keys %tops) { 
            $cmd.= "lib$lib_num & ";
            $lib_num++;                
            if( $lib_num % $cpu_num == 0 || $lib_num == $length){
                $cmd.="wait\n";
                run_make_file("$verilator/obj_dir/",$tview,$cmd);    
                $cmd="";
            }else {
                $cmd.=" make ";
            }    
        }
        run_make_file("$verilator/obj_dir/",$tview,"sim");    
        $load->destroy;
        $make->show_all;
        
    });
    $run -> signal_connect("clicked" => sub{
        my $bin="$verilator/obj_dir/testbench";
        if (-f $bin){
            my $cmd= "cd \"$verilator/obj_dir/\" \n xterm -e bash -c \"$bin; sleep 5\"";
            add_info($tview,"$cmd\n");    
            my ($stdout,$exit,$stderr)=run_cmd_in_back_ground_get_stdout($cmd);
            if(length $stderr>1){            
                add_colored_info($tview,"$stderr\n",'red');
            }else {
                add_info($tview,"$stdout\n");
            }            
        }else{
            add_colored_info($tview,"Cannot find $bin executable binary file! make sure you have compiled the testbench successfully\n", 'red')
        }    
    });
}

1;