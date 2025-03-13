#! /usr/bin/perl -w
use constant::boolean;
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use Data::Dumper;
use intfc_gen;
use rvp;
require "widget.pl";

sub read_file_modules{
    my ($file,$intfc_gen,$info)=@_;
    if (!defined $file) {
        add_colored_info($info,"No input file is given. Please set an input Verilog fle first.\n", 'red');
        return;
    }
    my $f=add_project_dir_to_addr($file);
    if (-e $f) {
        my $vdb =  read_verilog_file($f);
        my @modules=sort $vdb->get_modules($f);
        #foreach my $p(@module_list) {print "$p\n"}
        $intfc_gen->intfc_set_interface_file($file);
        $intfc_gen->intfc_set_module_name($modules[0]);
        $intfc_gen->intfc_add_module_list(@modules);
        set_gui_status($intfc_gen,"file_selected",1);
        add_info($info,"$f is loaded\n");
    }
    else {
        add_colored_info($info,"File $file does not exist!\n", 'red');
    }
}

################
#  check_input_intfc_file
################
sub check_input_intfc_file{
    my ($file,$intfc_gen,$info)=@_;
    my ($name,$path,$suffix) = fileparse("$file",qr"\..[^.]*$");
    if($suffix eq '.ITC'){
        $intfc_gen->intfc_set_interface_file($file);
        set_gui_status($intfc_gen,"load_file",0);
    }else{
        read_file_modules($file,$intfc_gen,$info);
    }
}

sub file_box {
    my ($intfc_gen,$info)=@_;
    my $label = gen_label_in_left("Select file:");
    my $entry = gen_entry();
    my $open= def_image_button("icons/select.png","Open");
    my $browse= def_image_button("icons/browse.png","Browse");
    my $file= $intfc_gen->intfc_get_interface_file();
    my $intfc_info= def_image_button("icons/add_info.png","Description");
    my $table = def_table(1,10,FALSE);
    $intfc_info->signal_connect("clicked"=> sub{
        get_intfc_description($intfc_gen,$info);
    });
    if(defined $file){$entry->set_text($file);}
    else {show_info($info,"Please select the Verilog file containing the interface\n");}
    $browse->signal_connect("clicked"=> sub{
        my $entry_ref=$_[1];
        my $file;
        my $dialog = gen_file_dialog (undef, 'v','ITC');
        if ( "ok" eq $dialog->run ) {
                $file = $dialog->get_filename;
                $$entry_ref->set_text($file);
                check_input_intfc_file($file,$intfc_gen,$info);
        }
        $dialog->destroy;
    } , \$entry);
    $open->signal_connect("clicked"=> sub{
        my $file_name=$entry->get_text();
        check_input_intfc_file($file,$intfc_gen,$info);
        #read_file_modules($file_name,$intfc_gen,$info);
        });
    $entry->signal_connect("activate"=>sub{
        my $file_name=$entry->get_text();
        read_file_modules($file_name,$intfc_gen,$info);
    });
    $entry->signal_connect("changed"=>sub{
        #show_info($info,"Please select the verilog file containing the interface\n");
    });
    my $row=0;
    $table->attach_defaults ($label, 0, 1 , $row, $row+1);
    $table->attach_defaults ($entry, 1, 7 , $row, $row+1);
    $table->attach ($browse, 7, 8, $row, $row+1,'shrink','shrink',2,2);
    $table->attach ($intfc_info, 8, 9 , $row, $row+1,'shrink','shrink',2,2);
    #$table->attach_defaults ($open,  9, 10, $row, $row+1);
    #$table->attach_defaults ($entry, $col, $col+1, $row, $row+1);
    return $table;
}

sub get_interface_ports {
    my ($intfc_gen,$info)=@_;
    my $window=def_popwin_size(60,60,"Import Ports",'percent');
    my $file=$intfc_gen->intfc_get_interface_file();
    if (!defined $file){show_info($info,"File name has not been defined yet!");  return;}
    my $module=$intfc_gen->intfc_get_module_name();
    if (!defined $module){  show_info($info,"Module name has not been selected yet!");  return;}
    my $f=add_project_dir_to_addr($file);
    my $vdb=read_verilog_file($f);
    my %port_type=get_ports_type($vdb,$module);
    my %port_range=get_ports_rang($vdb,$module);
    my $table=def_table(8,8,TRUE);
    my $scrolled_win = add_widget_to_scrolled_win($table);
    my $title=gen_label_in_center("Select the ports included in the interface");
    my $title1=gen_label_in_center("Type");
    my $title2=gen_label_in_center("Range");
    my $title3=gen_label_in_center("Name");
    my $title4=gen_label_in_center("Select");
    my $row    =0;
    $table->attach_defaults($title, 0,8, $row, $row+1);
    $row++;
    $table->attach_defaults($title1, 0,1, $row, $row+1);
    $table->attach_defaults($title2, 1,4, $row, $row+1);
    $table->attach_defaults($title3, 4,7, $row, $row+1);
    $table->attach_defaults($title4, 7,8, $row, $row+1);
    $row++;
    add_Hsep_to_table($table, 0, 8 , $row);    $row++;
    $intfc_gen->intfc_remove_ports();
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
        my $check= gen_checkbutton();
        $table->attach_defaults($check, 7,8, $row, $row+1);
        $row++;
        if($row>8){$table->resize ($row, 8);}
        #print "$p\:$port_type{$p}\n";
        $check->signal_connect("toggled"=>sub{
            my $widget=shift;
            my $in=$widget->get_active();
            if ($in eq 1){
                my $connect_type=($porttype eq "input")? "output" : ($porttype eq "output")? "input" : $porttype;
                $intfc_gen->intfc_add_port($port_id,$porttype,$portrange,$p,$connect_type,$portrange,$p,"concatenate","Active low");
                #print "chanhed to $in \n";
            }else {
                $intfc_gen->intfc_remove_port($port_id);
                #print "chanhed to 0 \n";
            }
        });
    }
    my $ok= def_image_button("icons/select.png","ok");
    $table->attach($ok, 3,5, $row, $row+1,'shrink','shrink',2,2);
    $ok->signal_connect("clicked"=>sub{
        $window->destroy;
        set_gui_status($intfc_gen,"refresh",1);
        });
    $window->add($scrolled_win);
    $window->show_all();
}

sub module_select{
    my ($intfc_gen,$info)=@_;
    #my $file= $intfc_gen->intfc_get_interface_file();
    my $table = def_table(1,10,FALSE);
    my @modules= $intfc_gen->intfc_get_module_list();
    my $combo=gen_combobox_object($intfc_gen,'module_name',undef,join(',', @modules),undef,'refresh',1);
    my $modul_name=gen_label_info(" Select module:",$combo);
    my $port= def_image_button("icons/import.png","Import Ports");
    my $category_entry=gen_entry_object($intfc_gen,'category',undef,undef,undef,undef);
    my $category=gen_label_info(" Select Category:",$category_entry,'Define the Interface category:e.g RAM, wishbone,...');
    my $row=0;
    #$table->attach_defaults ($label, 0, 1 , $row, $row+1);
    $table->attach  ($modul_name, 0, 3 , $row,$row+1,'shrink','shrink',2,2);
    $table->attach ($port, 4, 6 , $row, $row+1,'shrink','shrink',2,2);
    $table->attach_defaults ($category, 7, 10 , $row, $row+1);
    $port->signal_connect("clicked"=> sub{
        get_interface_ports($intfc_gen,$info);
    });
    return $table;
}

sub interface_type_select {
    my ($intfc_gen,$info,$table,$row)=@_;
    my $entry=gen_entry_object($intfc_gen,'name',undef,undef,"refresh",50);
    my $entrybox=gen_label_info(" Interface name:",$entry);
    my $combo=gen_combobox_object($intfc_gen,'connection_num',undef,"single connection,multi connection","single connection",'refresh',1);
    my $combo_box=gen_label_info(" Select socket type:",$combo,'Define the socket as multi connection if only if all interfaces ports are output oprts and they can feed more than one plug interface. E.g. clk is defined as multi connection');
    $table->attach ($entrybox, 0, 2 , $row, $row+1,'expand','shrink',2,2);
    $table->attach ($combo_box, 3, 6 , $row, $row+1,'expand','shrink',2,2);
}

sub port_select{
    my ($intfc_gen,$info,$table,$row)=@_;
    my(%types,%ranges,%names,%connect_types,%connect_ranges,%connect_names,%outport_types,%default_outs);
    $intfc_gen->intfc_get_ports(\%types,\%ranges,\%names,\%connect_types,\%connect_ranges,\%connect_names,\%outport_types,\%default_outs);
    my $size = keys %types;
    if($size >0){
        add_Hsep_to_table($table, 0, 10 , $row);    $row++;
        my $swap= def_image_button("icons/swap.png","swap");
        $swap->signal_connect('clicked'=>sub{
            my $type=$intfc_gen->intfc_get_interface_type();
            if($type eq 'plug'){
                    $intfc_gen->intfc_set_interface_type('socket');
            }
            else {
                    $intfc_gen->intfc_set_interface_type('plug');
            }
            set_gui_status($intfc_gen,"refresh",1);
        });
        my @intfcs=("plug","socket");
        my $inttype=$intfc_gen->intfc_get_interface_type();
        if (!defined $inttype){
            $inttype='plug';
            $intfc_gen->intfc_set_interface_type($inttype);
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
        $table->attach ($lab1, 1, 2 , $row, $row+1,'expand','shrink',2,2);
        $table->attach ($swap, 3, 4 , $row, $row+1,'expand','shrink',2,2);
        $table->attach ($lab2, 5, 6 , $row, $row+1,'expand','shrink',2,2);    $row++;
        add_Hsep_to_table($table, 0, 9 , $row);    $row++;
        my $lab3= gen_label_in_center("Type");
        my $lab4= gen_label_in_center("Range");
        my $lab5= gen_label_in_center("Name");
        $table->attach ($lab3, 0, 1 , $row, $row+1,'expand','shrink',2,2);
        $table->attach ($lab4, 1, 2 , $row, $row+1,'expand','shrink',2,2);
        $table->attach ($lab5, 2, 3 , $row, $row+1,'expand','shrink',2,2);
        my $lab6= gen_label_in_center("Type");
        my $lab7= gen_label_in_center("Range");
        my $lab8= gen_label_in_center("Name");
        $table->attach ($lab6, 4, 5 , $row, $row+1,'expand','shrink',2,2);
        $table->attach ($lab7, 5, 6 , $row, $row+1,'expand','shrink',2,2);
        $table->attach ($lab8, 6, 7 , $row, $row+1,'expand','shrink',2,2);
        my $lab9= gen_label_help ("When an IP core does not have any of interface output port, the default value will be send to the IP core's input port which is supposed to be connected to that port","Output port Default ");
        $table->attach ($lab9, 8, 9 , $row, $row+1,'expand','shrink',2,2);
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
                $intfc_gen->intfc_add_port($id,$type,$range,$name,$connect_type,$connect_range,$connect_name,$outport_type,$default_out);
                print "\$default_out is set to: $default_out\n ";
            }
            #my $box=def_hbox(FALSE,0);
            my @ports_type=("input","output","inout");
            my $pos=get_scolar_pos($type,@ports_type);
            my $combo1=gen_combo(\@ports_type,$pos);
            my $entry2=gen_entry($range);
            my $entry3=gen_entry($name);
            my $connect_type_lable= gen_label_in_center($connect_type);
            my $entry4=gen_entry($connect_range);
            my $entry5=gen_entry($connect_name);
            my @outport_types=("shared","concatenate");
            my $pos2=get_scolar_pos($outport_type,@outport_types);
            my $combo2=gen_combo(\@outport_types,$pos2);
            #my @list=(port_width_repeat($range,"1\'b0"),port_width_repeat($range,"1\'b1"),port_width_repeat($range,"1\'bx"));
            my @list=("Active low","Active high","Don't care");
            my $combentry=gen_combo_entry(\@list);
            my $combochiled = combo_entry_get_chiled($combentry);
            $pos2=get_scolar_pos($default_out,@list);
            if( defined $pos2){
                $combentry->set_active($pos2);
            } else {
                $combochiled->set_text($default_out);
            }
            #$box->pack_start($entry3,TRUE,FALSE,3);
            #$box->pack_start($separator,TRUE,FALSE,3);
            $table->attach ($combo1, 0, 1 , $row, $row+1,'expand','shrink',2,2);
            $table->attach ($entry2, 1, 2 , $row, $row+1,'expand','shrink',2,2);
            $table->attach ($entry3, 2, 3 , $row, $row+1,'expand','shrink',2,2);
            $table->attach ($connect_type_lable, 4, 5 , $row, $row+1,'expand','shrink',2,2);
            $table->attach ($entry4, 5, 6 , $row, $row+1,'expand','shrink',2,2);
            $table->attach ($entry5, 6, 7 , $row, $row+1,'expand','shrink',2,2);
            $table->attach ($combentry, 8, 9 , $row, $row+1,'expand','shrink',2,2);
            $combo1->signal_connect("changed"=>sub{
                my $new_type=$combo1->get_active_text();
                my $new_connect_type=($new_type eq "input")? "output" : ($new_type eq "output")? "input" : $new_type;
                $intfc_gen->intfc_add_port($id,$new_type,$range,$name,$new_connect_type,$connect_range,$connect_name,$outport_type,$default_out);
                set_gui_status($intfc_gen,"refresh",1);
            });
            $entry2->signal_connect("changed"=>sub{
                $range=$entry2->get_text();
                $intfc_gen->intfc_add_port($id,$type,$range,$name,$connect_type,$connect_range,$connect_name,$outport_type,$default_out);
                set_gui_status($intfc_gen,"refresh",50);
            });
            $entry3->signal_connect("changed"=>sub{
                $name=$entry3->get_text();
                $intfc_gen->intfc_add_port($id,$type,$range,$name,$connect_type,$connect_range,$connect_name,$outport_type,$default_out);
                set_gui_status($intfc_gen,"refresh",50);
            });
            $entry4->signal_connect("changed"=>sub{
                $connect_range=$entry4->get_text();
                $intfc_gen->intfc_add_port($id,$type,$range,$name,$connect_type,$connect_range,$connect_name,$outport_type,$default_out);
                set_gui_status($intfc_gen,"refresh",50);
            });
            $entry5->signal_connect("changed"=>sub{
                $connect_name=$entry5->get_text();
                $intfc_gen->intfc_add_port($id,$type,$range,$name,$connect_type,$connect_range,$connect_name,$outport_type,$default_out);
                set_gui_status($intfc_gen,"refresh",50);
            });
            $combo2->signal_connect("changed"=>sub{
                my $new_outport_type=$combo2->get_active_text();
                $intfc_gen->intfc_add_port($id,$type,$range,$name,$connect_type,$connect_range,$connect_name,$new_outport_type,$default_out);
                set_gui_status($intfc_gen,"refresh",1);
            });
            $combochiled->signal_connect('changed' => sub {
                my ($entry) = @_;
                $default_out=$entry->get_text();
                $intfc_gen->intfc_add_port($id,$type,$range,$name,$connect_type,$connect_range,$connect_name,$outport_type,$default_out);
            });
            $row++;
        }#foreach port
    }
    return $row;
}

sub dev_box_show{
    my($intfc_gen,$info)=@_;
    my $table = def_table(20,10,FALSE);
    interface_type_select($intfc_gen,$info,$table,0);
    my $row=port_select($intfc_gen,$info,$table,1);
    for (my $i=$row; $i<20; $i++){
        my $temp=gen_label_in_center(" ");
        #$table->attach_defaults ($temp, 0, 1 , $i, $i+1);
    }
    my $scrolled_win = add_widget_to_scrolled_win($table);
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
    if(!defined $result){$message="The Verilog file containing the interface has not been selected!";}
    if(!defined $message){return 1;}
    else {message_dialog($message); return 0;}
}

sub generate_lib{
    my $intfc_gen=shift;
    my $name=$intfc_gen->intfc_get_interface_name();
    my $category=$intfc_gen->object_get_attribute('category');
    # Write
    if(defined ($category)){
        open(FILE,  ">lib/interface/$name.ITC") || die "Can not open: $!";
        print FILE perl_file_header("$name.ITC");
        print FILE Data::Dumper->Dump([\%$intfc_gen],["HashRef"]);
        close(FILE) || die "Error closing file: $!";
        #store \%$intfc_gen, "lib/$name.ITC";
        my $message="Interface $name has been generated successfully. In order to see this interface in IP generator you need to reset the ProNoC. Do you want to reset the ProNoC now?" ;
        my $response =  yes_no_dialog($message);
        if ($response eq 'yes') {
            exec($^X, $0, @ARGV);# reset ProNoC to apply changes
        }
    }else{
        my $message="Category must be defined!";
        message_dialog($message);
    }
return 1;
}

###########
#    get description
#########
sub get_intfc_description{
    my ($intfc_gen,$info)=@_;
    my $description = $intfc_gen->intfc_get_description();
    my $table = def_table(15,15,TRUE);
    my $window=def_popwin_size(50,50,"Add description",'percent');
    my ($scrwin,$text_view)=create_txview();
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
    my ($intfc_gen)=@_;
    my $file;
    my $dialog =  gen_file_dialog (undef, 'ITC');
    my $dir = Cwd::getcwd();
    $dialog->set_current_folder ("$dir/lib/interface")    ;
    if ( "ok" eq $dialog->run ) {
        $file = $dialog->get_filename;
        my ($name,$path,$suffix) = fileparse("$file",qr"\..[^.]*$");
        if($suffix eq '.ITC'){
            $intfc_gen->intfc_set_interface_file($file);
            set_gui_status($intfc_gen,"load_file",0);
        }
    }
    $dialog->destroy;
}

############
#    main
############
sub intfc_main{
    my $intfc_gen= intfc_gen->interface_generator();
    set_gui_status($intfc_gen,"ideal",0);
    my $main_table =def_table(15, 12, FALSE);
    $main_table->set_row_spacings (4);
    $main_table->set_col_spacings (1);
    # The box which holds the info, warning, error ...  mesages
    my ($infobox,$info)= create_txview();
    my $generate = def_image_button('icons/gen.png','Generate');
    my $fbox=file_box($intfc_gen,$info);
    my $sbox=module_select($intfc_gen,$info);
    my $devbox=dev_box_show($intfc_gen,$info);
    #$main_table->attach_defaults ($fbox , 0, 12, 0,1);
    #$main_table->attach_defaults ($sbox , 0, 12, 1,2);
    #$main_table->attach_defaults ($devbox , 0, 12, 2,12);
    #$main_table->attach_defaults ($infobox  , 0, 12, 12,14);
    my $table=def_table(2,11,FALSE);
    $table->attach($fbox,0,11,0,1,'fill','shrink',2,2);
    $table->attach($sbox,0,11,1,2,'fill','shrink',2,2);
    #my $v1=def_pack_vbox(TRUE,0,$fbox,$sbox);
    my $v2=gen_vpaned($table,.12,$devbox);
    my $v3=gen_vpaned($v2,.6,$infobox);
    $main_table->attach_defaults ($v3  , 0, 12, 0,14);
    $main_table->attach ($generate    , 6, 8, 14,15,'shrink','shrink',2,2);
    my $open = def_image_button('icons/browse.png','Load Interface');
    my $openbox=def_hbox(TRUE,0);
    $openbox->pack_start($open,   FALSE, FALSE,0);
    $main_table->attach ($openbox,0, 2, 14,15,'shrink','shrink',2,2);
    #check soc status every 0.5 second. referesh gui if there is any changes
    Glib::Timeout->add (100, sub{
        my ($state,$timeout)= get_gui_status($intfc_gen);
        if ($timeout>0){
            $timeout--;
            set_gui_status($intfc_gen,$state,$timeout);
        }
        elsif($state eq "load_file"){
            my $file=$intfc_gen->intfc_get_interface_file();
            my ($pp,$r,$err) = regen_object($file);
            if ($r){
                add_info($info,"**Error reading  $file file: $err\n");
                return;
            }
            clone_obj($intfc_gen,$pp);
            show_info($info,"$file is loaded!\n ");
            set_gui_status($intfc_gen,"ref",1);
        }
        elsif( $state ne "ideal" ){
            $devbox->destroy();
            $fbox->destroy();
            $sbox->destroy();
            select(undef, undef, undef, 0.1); #wait 10 ms
            $devbox=dev_box_show($intfc_gen,$info);
            $fbox=file_box($intfc_gen,$info);
            $sbox=module_select($intfc_gen,$info);
            $table->attach($fbox,0,11,0,1,'fill','shrink',2,2);
            $table->attach($sbox,0,11,1,2,'fill','shrink',2,2);
            $v2->pack2($devbox,TRUE, TRUE);
            $v3-> pack1($v2, TRUE, TRUE);
            #$main_table->attach_defaults ($v3  , 0, 12, 0,14);
            $v3->show_all();
            set_gui_status($intfc_gen,"ideal",0);
        }
        return TRUE;
        } );
    $open-> signal_connect("clicked" => sub{
        load_interface($intfc_gen);
    });
    $generate-> signal_connect("clicked" => sub{
        if( check_intfc($intfc_gen)) {
            generate_lib($intfc_gen);
        }
        set_gui_status($intfc_gen,"ref",1);
    });
    #show_selected_dev($info,\@active_dev,\$dev_list_refresh,\$dev_table);
    #$box->show;
    #$window->add ($main_table);
    #$window->show_all;
    #return $main_table;
    return  add_widget_to_scrolled_win($main_table);
}
1;