#!/usr/bin/perl
use strict;
use warnings;
use constant::boolean;
use Cwd 'abs_path';
use base 'Class::Accessor::Fast';
require "widget.pl";
require "diagram.pl";
require "topology_verilog_gen.pl";
use String::Scanf; # imports sscanf()
use FindBin;
use lib $FindBin::Bin;
use tsort;
use File::Basename;
use Cwd 'abs_path';

__PACKAGE__->mk_accessors(qw{
    window
    sourceview
});

my $NAME = 'phy_noc_maker';
exit phy_noc_maker_main() unless caller;

sub phy_noc_maker_main {
    my $app = __PACKAGE__->new();
    my $table=$app->build_phy_noc_gui();
    return $table;
}

sub get_noc_num_page {
    my ($self,$noc_num,$info)=@_;
    my $table=def_table(20,10,FALSE);#    my ($row,$col,$homogeneous)=@_;
    my $scrolled_win = gen_scr_win_with_adjst ($self,"noc${noc_num}_setting_gui");
    add_widget_to_scrolled_win($table,$scrolled_win);
    my $row=noc_config ($self,$table,$info,$noc_num);
    return $scrolled_win;
}

my @pages=();
my @page_wins=();
sub gen_notebook_phy {
    my ($self,$info)=@_;
    my $phys= $self->object_get_attribute('phy_num');
    my $notebook = gen_notebook();
    $notebook->set_tab_pos ('left');
    $notebook->set_scrollable(TRUE);
    for (my $i=0;$i<$phys;$i++){
        $pages[$i]=get_noc_num_page($self,$i,$info);
        $page_wins[$i] = add_widget_to_scrolled_win($pages[$i]);
        $notebook->append_page ($page_wins[$i],gen_label_in_center  (" NoC $i"));
    }
    $notebook->signal_connect( 'switch-page'=> sub{ # rebulid the current page
        $self->object_add_attribute ("process_notebook","currentpage",$_[2]);    #save the new pagenumber
        set_gui_status($self,"ref",1);
    });
    return $notebook;
}

#############
#    load_phy
#############
sub load_phy{
    my ($soc,$info,$ip)=@_;
    my $file;
    my $dialog =  gen_file_dialog (undef, 'phy');
    my $dir = Cwd::getcwd();
    $dialog->set_current_folder ("$dir/lib/multi_nocs");
    if ( "ok" eq $dialog->run ) {
        $file = $dialog->get_filename;
        my ($name,$path,$suffix) = fileparse("$file",qr"\..[^.]*$");
        if($suffix eq '.phy'){
            my ($pp,$r,$err) = regen_object($file);
            if ($r || !defined $pp){
                show_info($info,"**Error reading  $file file: $err\n");
                $dialog->destroy;
                return;
            }
            clone_obj($soc,$pp);
            set_gui_status($soc,"load_file",0);
        }
    }
    $dialog->destroy;
}

sub generate_phynocs{
    my ($self,$info)=@_;
    my $name=$self->object_get_attribute('phy_name');
    return 0 if (check_mpsoc_name($name,$info,"Phy NoCs"));
    #make target dir
    my $pronoc_dir      = get_project_dir(); #mpsoc dir addr
    my $target_dir= "$ENV{PRONOC_WORK}/src_phy_nocs/$name";
    my $phys= $self->object_get_attribute('phy_num');
    my $ports1="";
    my $ports2="";
    my $imports="";
    my $nocs="";
    my $flist1=perl_file_header("phy_nocs.flist");
    my $flist2="";
    #create a unique verilog modules for each NoC
    for (my $i=0;$i<$phys;$i++){
        my $append="N$i";
        add_info($info,"Generating NoC$i Rtl code ...\n");
        mkpath("$target_dir/noc$i",1,0755);
        my $cmd = "perl $pronoc_dir/mpsoc/script/phy_noc_gen/phy_noc.pl $append $target_dir/noc$i";
        run_cmd_textview_errors ($cmd,$info);
        gen_noc_localparam_v_file($self,"$target_dir/noc$i",undef,$i);
        $cmd = "mv $target_dir/noc$i/noc_localparam.v $target_dir/noc$i/noc_localparam_${append}.v";
        run_cmd_textview_errors ($cmd,$info);
        $ports1.=",\n" if($i!=0);
        $ports1.= "\tchan_in_$append,\n\tchan_out_$append";
        $ports2.= "\tinput  smartflit_chanel_t_$append chan_in_$append;\n";
        $ports2.= "\toutput smartflit_chanel_t_$append chan_out_$append;\n";
        $imports.= "\timport pronoc_pkg_${append}::*;\n";
        $flist1.="+incdir+./noc$i\n";
        $flist2.="-F  noc$i/noc_filelist_${append}.f\n";
        $nocs.="
    noc_top_${append} noc_${append} (
        .reset(reset),
        .clk(clk),
        .chan_in_all(chan_in_$append),
        .chan_out_all(chan_out_$append),
        .router_event()
    );
"
    }
    #copy common rtl modules
    my $cmd = "cp $pronoc_dir/mpsoc/rtl/*.v  $target_dir/";
    run_cmd_textview_errors ($cmd,$info);
    my $top=autogen_warning().get_license_header("${name}_top.v");
    $top.="module ${name}_top(
    reset,
    clk,
$ports1
    );
$imports
    input reset,clk;
$ports2
$nocs
endmodule
    ";
    save_file ("$target_dir/${name}_top.v",$top);
    save_file ("$target_dir/${name}.flist",$flist1.$flist2."./${name}_top.v");
    message_dialog("Multiple physical NoCs \"$name\" has been created successfully at $target_dir/ " );
    return 1;
}

sub build_phy_noc_gui {
    my ($self) = @_;
    set_gui_status($self,"ideal",0);
    $self->object_add_attribute ("process_notebook","currentpage",0);
    my $main_table= def_table(2,10,FALSE);
    add_param_widget ($self,"Phy NoCs #:" , undef, 3, 'Spin-button', "1,20,1","Specify the number of independent phisical NoCs. each NoC can have its unique set of parameter configuration.", $main_table,24,0,1, 'phy_num', 1,'ref_nocs','vertical');
    my ($infobox,$info)= create_txview();
    my $notebook = gen_notebook_phy($self,$info);
    my $v2=gen_vpaned($notebook,.65,$infobox);
    my $pronoc_dir      = get_project_dir(); #mpsoc dir addr
    my $target_dir= "$ENV{PRONOC_WORK}/src_phy_nocs/";
    my ($entrybox,$entry ) =gen_save_load_widget (
        $self, #the object
        "Phy Name",#the label shown for setting configuration
        'phy_name',#the key name for saveing the setting configuration in object
        'multiple physical NoCs',#the label full name show in tool tips
        $target_dir,#Where the generted RTL files are loacted. Undef if not aplicaple
        'soc',#check the given name match the SoC or mpsoc name rules
        'lib/multi_nocs',#where the current configuration seting file is saved
        'phy',#the extenstion given for configuration seting file
        \&load_phy,#refrence to load function
        $info
        );
    my $generate = def_image_button('icons/gen.png','Generate');
    $main_table->attach_defaults ($v2  , 0, 12, 0,24);
    $main_table->attach ($entrybox,3, 4, 24,25,'expand','shrink',2,2);
    $main_table->attach ($generate, 6, 9, 24,25,'expand','shrink',2,2);
    my $sc_win = add_widget_to_scrolled_win($main_table);
    $generate->signal_connect("clicked" => sub{
        my $load= show_gif("icons/load.gif");
        $main_table->attach ($load, 9, 10, 24,25,'expand','shrink',2,2);
        $load->show_all;
        generate_phynocs($self,$info);
        $load->destroy;
    });
    #check soc status every 0.5 second. refresh device table if there is any changes
    Glib::Timeout->add (100, sub{
        my ($state,$timeout)= get_gui_status($self);
        if ($timeout>0){
            $timeout--;
            set_gui_status($self,$state,$timeout);
            return TRUE;
        }
        if($state eq "ideal"){
            return TRUE;
        }
        if($state eq 'ref_nocs'){
            $notebook->destroy;
            $notebook = gen_notebook_phy($self,$info);
            $v2 -> pack1($notebook, TRUE, TRUE);
            $v2 -> show_all;
        } else { #only refresh current NoC setting
            my $page_num=$self->object_get_attribute ("process_notebook","currentpage");
            $pages[$page_num]->destroy;
            $pages[$page_num]=get_noc_num_page($self,$page_num,$info);
            add_widget_to_scrolled_win($pages[$page_num],$page_wins[$page_num]);
            $page_wins[$page_num]->show_all;
        }
        my $saved_name=$self->object_get_attribute('save_as');
        $entry->set_text($saved_name)if(defined $saved_name);
        set_gui_status($self,"ideal",0);
        $main_table->show_all();
        return TRUE;
    } );
    return $sc_win;
}
1;