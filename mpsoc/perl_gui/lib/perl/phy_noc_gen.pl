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
	my $table=def_table(20,10,FALSE);#	my ($row,$col,$homogeneous)=@_;
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
		$self->object_add_attribute ("process_notebook","currentpage",$_[2]);	#save the new pagenumber
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
	my $pronoc_dir	  = get_project_dir(); #mpsoc dir addr
	my $target_dir= "$pronoc_dir/mpsoc/rtl/src_phy_nocs/$name";
    my $phys= $self->object_get_attribute('phy_num');
		
	for (my $i=0;$i<$phys;$i++){
		 add_info($info,"Generating NoC$i Rtl code ...\n");
		 mkpath("$target_dir/noc$i",1,0755); 
		 my $cmd = "perl $pronoc_dir/mpsoc/script/phy_noc_gen/phy_noc.pl $i $target_dir/noc$i";
		 run_cmd_textview_errors ($cmd,$info);
		 gen_noc_localparam_v_file($self,"$target_dir/noc$i",undef,$i);
		 $cmd = "mv $target_dir/noc$i/noc_localparam.v $target_dir/noc$i/noc_localparam_${i}.v";
		 run_cmd_textview_errors ($cmd,$info);
	}

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
	


    my $load = def_image_button('icons/load2.png');
    my $entry=gen_entry_object($self,'phy_name',undef,undef,undef,undef);
    my $entrybox=gen_label_info("Name:",$entry);
    my $save      = def_image_button('icons/save.png');	
    my $open_dir  = def_image_button('icons/open-folder.png');
    set_tip($save, "Save current multiple physical NoCs configuration setting");
	set_tip($load, "Load a saved multiple physical NoCs configuration setting");
	set_tip($open_dir, "Open target multiple physical NoCs folder");
    	
	$entrybox->pack_start( $save, FALSE, FALSE, 0);
	$entrybox->pack_start( $load, FALSE, FALSE, 0);
	$entrybox->pack_start( $open_dir , FALSE, FALSE, 0);
	my $generate = def_image_button('icons/gen.png','Generate');
	
	$open_dir-> signal_connect("clicked" => sub{ 
    	my $name=$self->object_get_attribute('phy_name');
    	my $pronoc_dir	  = get_project_dir(); #mpsoc dir addr
		my $target_dir= "$pronoc_dir/mpsoc/rtl/src_phy_nocs/$name";
		unless (-d $target_dir){
			message_dialog("Cannot find $target_dir.\n Please run RTL Generator first!",'error');
			return;
		}
		system "xdg-open   $target_dir";
	});
	
	$save-> signal_connect("clicked" => sub{ 
    	my $name=$self->object_get_attribute('phy_name');		
		return if(check_mpsoc_name($name,"phy_NoCs")) ;
			
		# Write object file
		open(FILE,  ">lib/multi_nocs/$name.phy") || die "Can not open $name.phy: $!";
		print FILE perl_file_header("$name.phy");
		print FILE Data::Dumper->Dump([\%$self],['phy']);
		close(FILE) || die "Error closing file: $!";
		message_dialog("Processing Tile  \"$name\" is saved as lib/multi_nocs/$name.phy.");		
    
    });


    $load-> signal_connect("clicked" => sub{ 
        set_gui_status($self,"ref",5);
        load_phy($self,$info);    
    });

	
	
	
	$entry->signal_connect( 'changed'=> sub{
		my $name=$entry->get_text();
		$self->object_add_attribute ("save_as",undef,$name);	
	});	
	
	my ($entrybox2,$entry2) = def_h_labeled_entry('Routing Alg. name:',undef);
	
	$entry2->signal_connect( 'changed'=> sub{
		my $name=$entry2->get_text();
		$self->object_add_attribute ("routing_name",undef,$name);	
	});	
	
	
	$main_table->attach_defaults ($v2  , 0, 12, 0,24);
   

	
	#$main_table->attach ($save,1, 2, 24,25,'expand','shrink',2,2);
	
	$main_table->attach ($entrybox,3, 4, 24,25,'expand','shrink',2,2);
#	$main_table->attach ($entrybox2,4, 6, 24,25,'expand','shrink',2,2);
    
	$main_table->attach ($generate, 6, 9, 24,25,'expand','shrink',2,2);
	

	my $sc_win = add_widget_to_scrolled_win($main_table);
	
	
	#setting for graphs
	my $n=0;
    my $sample="sample$n";
	$n++;
	$self->object_add_attribute("id",undef,$n);
	$self->object_add_attribute("active_setting",undef,undef);
	$self->object_add_attribute_order("samples",$sample);
	$self->object_add_attribute($sample,"color",1);
	add_color_to_gd($self);
	
	
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
		    
		$saved_name = $self->object_get_attribute('routing_name');
		$entry2->set_text($saved_name) if(defined $saved_name);
		    
		set_gui_status($self,"ideal",0);
		$main_table->show_all();	
							
		
		
		
		return TRUE;
		
	} );	



	return $sc_win;

	
	
}

1;