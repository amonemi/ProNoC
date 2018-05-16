#!/usr/bin/perl
use strict;
use warnings;

use Glib qw(TRUE FALSE);
use Gtk2 '-init';
use Gtk2::SourceView2;
use Data::Dumper;
use List::Util 'shuffle';
use File::Path;
use File::Copy;
use POSIX qw(ceil floor);
use Cwd 'abs_path';



use base 'Class::Accessor::Fast';
require "widget.pl"; 
require "diagram.pl";


__PACKAGE__->mk_accessors(qw{
	window
	sourceview
	buffer
	filename
	search_regexp
	search_case
	search_entry
	regexp
	highlighted
	
});

my $NAME = 'Trace_gen';


exit trace_gen_main() unless caller;


sub trace_gen_main {
	
	my $app = __PACKAGE__->new();
	my $table=$app->build_trace_gui();
		
	return $table;
}



sub build_trace_gui {
	my ($self) = @_;
	$self->object_add_attribute("file_id",undef,'a');
	$self->object_add_attribute("trace_id",undef,0);
	$self->object_add_attribute('select_multiple','action',"_");
	$self->object_add_attribute('Auto','Auto_inject',"1\'b1");
	
	set_gui_status($self,"ideal",0);

	my $main_table= def_table(2,10,FALSE);
	my ($scwin_info,$tview)= create_text();	
	
	my $traces=trace_pad($self,$tview);
	my $traces_ctrl=trace_pad_ctrl($self,$tview);
	
	my $map= trace_map($self,$tview);
	my $map_ctrl= trace_map_ctrl($self,$tview);
	my $map_info=map_info($self);
	
	my $h1=gen_hpaned($traces_ctrl,.25,$traces);
	my $h2=gen_hpaned($map_ctrl,.25,$map);
	my $h3=gen_hpaned($h2,.65,$map_info);

	my $v1=gen_vpaned($h1,.3,$h3);
	#my $v2=gen_vpaned($v1,.6,$scwin_info);
	
	my $generate = def_image_button('icons/gen.png','Generate');
	my $open = def_image_button('icons/browse.png','Load');	
	my ($entrybox,$entry) = def_h_labeled_entry('Save as:',undef);
	$entry->signal_connect( 'changed'=> sub{
		my $name=$entry->get_text();
		$self->object_add_attribute ("save_as",undef,$name);	
	});	
	
	my $entry2=gen_entry_object($self,'out_name',undef,undef,undef,undef);
	my $entrybox2=labele_widget_info(" Output file name:",$entry2);
	
	my $save = def_image_button('icons/save.png','Save');
	$entrybox->pack_end($save,   FALSE, FALSE,0);

	$main_table->attach_defaults ($v1  , 0, 12, 0,24);
	$main_table->attach ($open,0, 3, 24,25,'expand','shrink',2,2);
	$main_table->attach ($entrybox,3, 5, 24,25,'expand','shrink',2,2);
	$main_table->attach ($entrybox2,5,6 , 24,25,'expand','shrink',2,2);
	$main_table->attach ($generate, 6, 9, 24,25,'expand','shrink',2,2);
	

	my $sc_win = new Gtk2::ScrolledWindow (undef, undef);
	$sc_win->set_policy( "automatic", "automatic" );
	$sc_win->add_with_viewport($main_table);
	
	
	
	$open-> signal_connect("clicked" => sub{ 
		
		load_workspace($self);
		set_gui_status($self,"ref",5);
	
	});	

	$save-> signal_connect("clicked" => sub{ 
		save_as($self);		
		set_gui_status($self,"ref",5);
		
	
	});	
	
	$generate->signal_connect("clicked" => sub{ 
		genereate_output($self);
		
	
	});	
	
	
	
	
	
	
	#check soc status every 0.5 second. referesh device table if there is any changes 
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
		
		
		
		#refresh GUI
		my $saved_name=$self->object_get_attribute('save_as');
		if(defined $saved_name) {$entry->set_text($saved_name);}
		
		$saved_name=$self->object_get_attribute('out_name');
		if(defined $saved_name) {$entry2->set_text($saved_name);}
		
		
									
		$traces->destroy();
		$traces=trace_pad($self,$tview);
		$map->destroy();
		$map= trace_map($self,$tview);
		$map_ctrl->destroy();
		$map_ctrl= trace_map_ctrl($self,$tview);
		$traces_ctrl->destroy();
		$traces_ctrl=trace_pad_ctrl($self,$tview);
		$map_info->destroy();
		$map_info=map_info($self);
		
		$h1 -> pack1($traces_ctrl, TRUE, TRUE); 	
		$h1 -> pack2($traces, TRUE, TRUE); 	
		$h2 -> pack1($map_ctrl, TRUE, TRUE); 		
		$h2 -> pack2($map, TRUE, TRUE); 
		$h3 -> pack2($map_info, TRUE, TRUE); 	
		
		$traces->show_all();
		$map->show_all();
		$main_table->show_all();			
		set_gui_status($self,"ideal",0);
		
		return TRUE;
		
	} );	



	return $sc_win;

	
	
}

########
#  trace_ctr
########

sub trace_pad_ctrl{
	my ($self,$tview)=@_;
		
	my $table= def_table(2,10,FALSE);
	#my $separator = Gtk2::HSeparator->new;	
	my $row=0;
	my $col=0;
	#$table->attach ($separator , 0, 10 , $row, $row+1,'fill','fill',2,2);	$row++;	
	
	my $add = def_image_button('icons/import.png');
	set_tip($add,'Load Task Graph');
	my $remove = def_image_button('icons/cancel.png');
	set_tip($remove,'Remove Selected Trace(s)');
	my $draw = def_image_button('icons/diagram.png');
	set_tip($draw,'View Task Graph');
	my $auto = def_image_button('icons/refresh.png');
	set_tip($auto,'Automatically calculate the traces burst size and injection ratio according to their bandwith');
	
	
	
	
	my $box=def_pack_hbox(FALSE,FALSE,$add,$draw,$remove,$auto);
	
	#my $auto = def_image_button('icons/setting.png');
	#set_tip($auto,'Automatically set the burst size and injection ratio according to the packet size and bandwidth');
	
	
	$col=0;
	$table->attach ($box,$col, $col+1,  $row, $row+1,'shrink','shrink',2,2);$col++;
	
	$row++;	
	$col=0;
	my $info="Automatically set the burst size and injection ratio according to the packet size and bandwidth";
	#add_param_widget($self,"Auto inject rate \& burst size",'Auto_inject', 0,"Check-box",1,$info, $table,$row,$col,1,'Auto',0,'ref',"vertical");
	$row++;
	
	
	
	$col=0;
	
my $info1="If hard-bulid QoS is enabled in NoC by using Wieghted round robin arbiter (WRRA) instead of RRA, then the initial weights allow QoS support in NoC as in presence of contention, packets with higher initial weights receive higher bandwidth and lower worst case delay compared to others." ;
	
	my $selects="tornado,transposed 1,transposed 2,bit reverse,bit complement,random,hot spot"; 
	my $min=$self->object_get_attribute('select_multiple','min_pck_size');
	my $max=$self->object_get_attribute('select_multiple','max_pck_size');	
	$min=$max=5 if(!defined $min);
	
	my @selectedinfo;
	$self->object_add_attribute('Auto','Auto_inject',"1\'b0" );
	my $a= $self->object_get_attribute('Auto','Auto_inject');
	if ($a eq "1\'b0"){
		@selectedinfo = (
		{ label=>" Initial weight ", param_name=>'init_weight', type=>'Spin-button', default_val=>1, content=>"1,16,1", info=>$info1, param_parent=>'select_multiple', ref_delay=> undef, new_status=>undef},
		{ label=>" Min pck size ", param_name=>'min_pck_size', type=>'Spin-button', default_val=>5, content=>"2,$max,1", info=>undef, param_parent=>'select_multiple', ref_delay=> 10, new_status=>'ref'},
		{ label=>" Max pck size ",param_name=>'max_pck_size', type=>'Spin-button', default_val=>5, content=>"$min,1024,1", info=>undef, param_parent=>'select_multiple', ref_delay=> 10, new_status=>'ref'},
		{ label=>" Burst_size ", param_name=>'burst_size', type=>'Spin-button', default_val=>1, content=>"1,1024,1", info=>undef, param_parent=>'select_multiple', ref_delay=> undef, new_status=>undef},
		{ label=>" Inject rate(%) ", param_name=>'injct_rate', type=>'Spin-button', default_val=>10, content=>"1,100,1", info=>undef, param_parent=>'select_multiple', ref_delay=> undef, new_status=>undef},
		{ label=>" Inject rate variation(%) ", param_name=>'injct_rate_var', type=>'Spin-button', default_val=>20, content=>"0,100,1", info=>undef, param_parent=>'select_multiple', ref_delay=> undef, new_status=>undef},

	);
		
		
	}else{
		@selectedinfo = (
		{ label=>" Initial weight ", param_name=>'init_weight', type=>'Spin-button', default_val=>1, content=>"1,16,1", info=>undef, param_parent=>'select_multiple', ref_delay=> undef, new_status=>undef},
		{ label=>" Min pck size ", param_name=>'min_pck_size', type=>'Spin-button', default_val=>5, content=>"2,$max,1", info=>undef, param_parent=>'select_multiple', ref_delay=> 10, new_status=>'ref'},
		{ label=>" Max pck size ",param_name=>'max_pck_size', type=>'Spin-button', default_val=>5, content=>"$min,1024,1", info=>undef, param_parent=>'select_multiple', ref_delay=> 10, new_status=>'ref'},
		
	);
		
	}
	
	
	my @traces= $self->get_trace_list();
	my $any_selected=0;
	foreach my $p (@traces) {	
		my ($src,$dst, $Mbytes, $file_id, $file_name)=$self->get_trace($p);
		$any_selected=1 if($self->object_get_attribute("trace_$p",'selected')==1); 
	
	}	
	
	if($any_selected){
		$table->attach (Gtk2::HSeparator->new,0, 10,  $row, $row+1,'fill','fill',2,2);$row++;	
		$table->attach (gen_label_in_center('Apply to all selected traces'),0, 10,  $row, $row+1,'fill','fill',2,2);$row++;	
	}
	
	foreach my $d (@selectedinfo) {
		my $apply= def_image_button("icons/enter.png",undef);
		$apply->signal_connect( 'clicked'=> sub{
			$self->object_add_attribute('select_multiple','action',$d->{param_name});
			$self->set_gui_status('ref',0);
		});
		if($any_selected){
			($row,$col)=add_param_widget ($self, $d->{label}, $d->{param_name}, $d->{default_val}, $d->{type}, $d->{content}, $d->{info}, $table,$row,$col,1, $d->{param_parent}, $d->{ref_delay},$d->{new_status},"horizental");
			$table->attach  ($apply , $col, $col+1,  $row,$row+1,'shrink','shrink',2,2);$row++;$col=0;
		#	$row=noc_param_widget ($self, $d->{label}, $d->{param_name}, $d->{default_val}, $d->{type}, $d->{content}, $d->{info}, $table,$row,1, $d->{param_parent}, $d->{ref_delay}, $d->{new_status});
		}
		}
	
	
	
	
			
	my $dir = Cwd::getcwd();
	my $project_dir	  = abs_path("$dir/.."); #mpsoc directory address
	
	
	$add->signal_connect ( 'clicked'=> sub{
		
 		my $file;
        my $dialog = Gtk2::FileChooserDialog->new(
            	'Select a File', undef,
            	'open',
            	'gtk-cancel' => 'cancel',
            	'gtk-ok'     => 'ok',
        	);
        	my $open_in	  = abs_path("${project_dir}/perl_gui/lib/simulate/embedded_app_graphs");
        	$dialog->set_current_folder ($open_in); 
        	my $filter = Gtk2::FileFilter->new();
			$filter->set_name("app");
			$filter->add_pattern("*.app");
			$dialog->add_filter ($filter);
		

        	if ( "ok" eq $dialog->run ) {
            		$file = $dialog->get_filename;
					$self->load_tarce_file($file,$tview);
            }
       		$dialog->destroy;	
	});
	
	$draw->signal_connect ( 'clicked'=> sub{
		show_trace_diagram($self,'trace');
	});
	
	$remove->signal_connect ( 'clicked'=> sub{
		$self->remove_selected_traces();
	});
	
	$auto->signal_connect ( 'clicked'=> sub{
		$self->auto_generate_injtratio();
	});
	
	
	my $sc_win = new Gtk2::ScrolledWindow (undef, undef);
	$sc_win->set_policy( "automatic", "automatic" );
	$sc_win->add_with_viewport($table);
	
	
	return $sc_win;
	
}


######
# map_ctr
######	
	
sub trace_map_ctrl{
	
	my ($self,$tview)=@_;
	my $table= def_table(2,10,FALSE);
	
	my $run_map= def_image_button("icons/enter.png",undef);
	my $drawmap = def_image_button('icons/diagram.png');
	set_tip($drawmap,'View Task Mapping');
	my $auto = def_image_button('icons/refresh.png');
	set_tip($auto,'Automatically set the network dimentions acording to the task number');
	
	my $clean = def_image_button('icons/clear.png');
	set_tip($clean,'Remove mapping');
	
	
	
	
	my $box=def_pack_hbox(FALSE,FALSE,$drawmap,$clean,$auto);
	
	
	
	
	my $col=0;
	my $row=0;
	$table->attach ($box,$col, $col+1,  $row, $row+1,'shrink','shrink',2,2);$row++;
	
	
	
	my @info = (
  	{ label=>'Routers per Row', param_name=>'NX', type=>"Spin-button", default_val=>2, content=>"2,64,1", info=>undef, param_parent=>'noc_param', ref_delay=>1,placement=>'vertical'},
	{ label=>"Routers per Column", param_name=>"NY", type=>"Spin-button", default_val=>2, content=>"1,64,1", info=>undef, param_parent=>'noc_param',ref_delay=>1, placement=>'vertical'},
	{ label=>"Mapping Algorithm", param_name=>"Map_Algrm", type=>"Combo-box", default_val=>'Random', content=>"Nmap,Random,Reverse-NMAP,Direct", info=>undef, param_parent=>'map_param',ref_delay=>undef,placement=>'horizental'},
	
	);
	
	
	
	foreach my $d (@info) {
		($row,$col)=add_param_widget ($self, $d->{label}, $d->{param_name}, $d->{default_val}, $d->{type}, $d->{content}, $d->{info}, $table,$row,$col,1, $d->{param_parent}, $d->{ref_delay},'ref',$d->{placement});
		if($d->{param_name} eq "Map_Algrm"){$table->attach  ($run_map , $col, $col+1,  $row,$row+1,'shrink','shrink',2,2);$row++;$col=0;}
		
	}
	
		
	
	
	$run_map->signal_connect( 'clicked'=> sub{
		my $alg=$self->object_get_attribute('map_param','Map_Algrm');
		
		$self->random_map() if ($alg eq 'Random');
		$self->worst_map_algorithm() if ($alg eq 'Reverse-NMAP');		
		$self->nmap_algorithm() if ($alg eq 'Nmap');
		$self->direct_map() if ($alg eq 'Direct');
		
	
	});
	
	$drawmap->signal_connect ( 'clicked'=> sub{
		show_trace_diagram($self,'map');
	});
	
	$auto->signal_connect ( 'clicked'=> sub{
		my @tasks = $self->get_all_tasks();
		my $task_num= scalar @tasks;
		return if($task_num ==0);
		my ($nx,$ny) =network_dim_cal($task_num);
		$self->object_add_attribute('noc_param','NX',$nx);
		$self->object_add_attribute('noc_param','NY',$ny);	
		set_gui_status($self,"ref",1);	
	});
	
	$clean->signal_connect ( 'clicked'=> sub{
		remove_mapping($self);
		set_gui_status($self,"ref",1);	
	});
	
	
	my $sc_win = new Gtk2::ScrolledWindow (undef, undef);
	$sc_win->set_policy( "automatic", "automatic" );
	$sc_win->add_with_viewport($table);
	
	
	return $sc_win;
}
	
#########
# trace
#########

sub trace_pad{
	my ($self,$tview)=@_;
	my $table= def_table(10,10,FALSE);
	#my $separator = Gtk2::HSeparator->new;	
	my $row=0;
	my $col=0;
		
	
	my @selectedinfo = (
		{ label=>" Initial weight ", param_name=>'init_weight', type=>'Spin-button', default_val=>1, content=>"1,16,1", info=>undef, param_parent=>'select_multiple', ref_delay=> undef, new_status=>undef},
		{ label=>" Min pck size ", param_name=>'min_pck_size', type=>'Spin-button', default_val=>5, content=>"2,1024,1", info=>undef, param_parent=>'select_multiple', ref_delay=> 10, new_status=>'ref'},
		{ label=>" Max pck size ",param_name=>'max_pck_size', type=>'Spin-button', default_val=>5, content=>"2,1024,1", info=>undef, param_parent=>'select_multiple', ref_delay=> 10, new_status=>'ref'},
		{ label=>" Burst_size ", param_name=>'burst_size', type=>'Spin-button', default_val=>1, content=>"1,1024,1", info=>undef, param_parent=>'select_multiple', ref_delay=> undef, new_status=>undef},
		{ label=>" Inject rate(%) ", param_name=>'injct_rate', type=>'Spin-button', default_val=>10, content=>"1,100,1", info=>undef, param_parent=>'select_multiple', ref_delay=> undef, new_status=>undef},
	    { label=>" Inject rate variation (%) ", param_name=>'injct_rate_var', type=>'Spin-button', default_val=>20, content=>"0,100,1", info=>undef, param_parent=>'select_multiple', ref_delay=> undef, new_status=>undef},
	);
	
	
	my @traces= $self->get_trace_list();
	my %f;
	
	
	my $sel=$self->object_get_attribute('select_multiple','action');
	
	foreach my $p (@traces) {	
		my ($src,$dst, $Mbytes, $file_id, $file_name)=$self->get_trace($p);
		$f{$file_id}=$file_id.'*';
		$self->object_add_attribute("trace_$p",'selected', 1 ) if ($sel eq  'All');
		$self->object_add_attribute("trace_$p",'selected', 0 ) if ($sel eq  'None');
		$self->object_add_attribute("trace_$p",'selected', 1 ) if ($sel eq  "All-$file_id*");
		$self->object_add_attribute("trace_$p",'selected', 0 ) if ($sel eq  "None-$file_id*");
		
		my $seleceted =$self->object_get_attribute("trace_$p",'selected');
		foreach my $d (@selectedinfo) {
			my $val=$self->object_get_attribute($d->{param_parent},$d->{param_name}) if ($sel eq  $d->{param_name} && $seleceted);	
			$self->object_add_attribute("trace_$p",$d->{param_name}, $val ) if ($sel eq  $d->{param_name}&& $seleceted);	
			
		}
	}	
	my $sel_options= "Select,All,None";
	if( keys %f > 1){
		foreach my $p (sort keys %f) {
			$sel_options="$sel_options,All-$f{$p}";
			$sel_options="$sel_options,None-$f{$p}";
		}
	}	
	$self->object_add_attribute('select_multiple','action',"Select");
	my $selcombo = $self-> gen_combobox_object ('select_multiple',"action", $sel_options,'-','ref',1);
	
	
	if(scalar @traces ){$table-> attach  ($selcombo, $col, $col+1,  $row, $row+1,'shrink','shrink',2,2);  $col++;}
	
	
	my @titles = (scalar @traces ) ? (" # "," Source "," Destination "," Bandwidth(MB) ", " Initial weight ", " Min pck size ",  " Max pck size "):
	("Load a task graph");
	
	my $auto=$self->object_get_attribute('Auto','Auto_inject');
	
	push (@titles, (" Burst_size ", " Inject rate(%) ", " Inject rate variation(%) ")) if ($auto eq "1\'b0");
	foreach my $p (@titles){
		$table-> attach  (gen_label_in_left($p), $col, $col+1,  $row, $row+1,'shrink','shrink',2,2);  
		$col++;
	}
		$row++;	
				
	my $i=0;
	#my @t=sort { $a cmp $b } @traces;
	
	foreach my $p (@traces) {	
		$col=0;	
		my ($src,$dst, $Mbytes, $file_id, $file_name)=$self->get_trace($p);
		
				
		my $check = gen_check_box_object ($self,"trace_$p",'selected',0,'ref',0);
		my $weight= gen_spin_object ($self,"trace_$p",'init_weight',"1,16,1", 1,undef,undef);
		
		my $min=$self->object_get_attribute("trace_$p",'min_pck_size');
		my $max=$self->object_get_attribute("trace_$p",'max_pck_size');
		$min=$max=5 if(!defined $min);
		my $min_pck_size= gen_spin_object ($self,"trace_$p",'min_pck_size',"2,$max,1", 5,'ref',10);
		my $max_pck_size= gen_spin_object ($self,"trace_$p",'max_pck_size',"$min,1024,1", 5,'ref',10);
		
		my $burst_size	= gen_spin_object ($self,"trace_$p",'burst_size',"1,1024,1", 1,undef,undef);
		my $injct_rate  = gen_spin_object ($self,"trace_$p",'injct_rate',"1,100,1", 10,undef,undef);
		my $injct_rate_var  = gen_spin_object ($self,"trace_$p",'injct_rate_var',"0,100,1", 20,undef,undef);
		
		#my $weight=  trace_$trace_id",'init_weight'
		
		$table-> attach  ($check, $col, $col+1,  $row, $row+1,'shrink','shrink',2,2);  $col++;
		
		$table-> attach (gen_label_in_left($i), $col, $col+1,  $row, $row+1,'shrink','shrink',2,2);  $col++; 
		$table-> attach (gen_label_in_left("$src") ,$col, $col+1,  $row, $row+1,'shrink','shrink',2,2);  $col++;
		$table-> attach (gen_label_in_left("$dst") , $col, $col+1,  $row, $row+1,'shrink','shrink',2,2);  $col++;
		$table-> attach (gen_label_in_left("$Mbytes") ,$col, $col+1,  $row, $row+1,'shrink','shrink',2,2);  $col++;
		$table-> attach ($weight ,$col, $col+1,  $row, $row+1,'shrink','shrink',2,2);  $col++;
		$table-> attach ($min_pck_size, $col, $col+1,  $row, $row+1,'shrink','shrink',2,2);  $col++;
		$table-> attach ($max_pck_size, $col, $col+1,  $row, $row+1,'shrink','shrink',2,2);  $col++;
		if ($auto eq "1\'b0"){
			$table-> attach ($burst_size ,$col, $col+1,  $row, $row+1,'shrink','shrink',2,2);  $col++;
			$table-> attach ($injct_rate ,$col, $col+1,  $row, $row+1,'shrink','shrink',2,2);  $col++;
			$table-> attach ($injct_rate_var ,$col, $col+1,  $row, $row+1,'shrink','shrink',2,2);  $col++;
			
		}
		
		
		$row++;	
		$i++;		
		
	}
	
	my $sc_win = gen_scr_win_with_adjst($self,'trace_pad');
	$sc_win->add_with_viewport($table);
	
	return $sc_win;
}



sub load_tarce_file{
	my ($self,$file,$tview)=@_;
	#open file
	my @x;
	my %traces;
	if (!defined $file) {return; }
	if (-e $file) { 
		my $f_id=$self->object_get_attribute("file_id",undef);
		my $t_id=$self->object_get_attribute("trace_id",undef);
		open(my $fh, '<:encoding(UTF-8)', $file) or die "Could not open file '$file' $!";
		while (my $row = <$fh>) {
			chomp $row;
			my @data = 	split (/\s/,$row);
			
			next if (! defined $data[0]);
			next if ($data[0] eq '#' || scalar @data < 3);
			
			$self->add_trace($f_id,$t_id,$data[0],$data[1],$data[2],$file);
			$t_id++;			
		}
		$f_id++;
		$self->object_add_attribute("trace_id",undef,$t_id);
		$self->object_add_attribute("file_id",undef,$f_id);
	}
	set_gui_status($self,"ref",1);
	
}




########
# map
#######


sub trace_map {
	my ($self,$tview)=@_;
	my $table= def_table(10,10,FALSE);
	
	
	my $sc_win = gen_scr_win_with_adjst($self,'trace_map');
	$sc_win->add_with_viewport($table);
	
	my $row=0;
	my $col=0;
	
	my @titles = (" # "," Task-name ", " Mapped-to " ,"Lock ", " Sent-Bandwidth ", " Resvd-Bandwidth ", " Total-Bandwidth ");
	foreach my $p (@titles){
		$table-> attach  (gen_label_in_left($p), $col, $col+1,  $row, $row+1,'shrink','shrink',2,2); $col++;
	}
	$col=0;
	$row++;	
	
	 # 	{ label=>'Routers per Row', param_name=>'NX', type=>"Spin-button", default_val=>2, content=>"2,64,1", info=>undef, param_parent=>'noc_param', ref_delay=>undef},

	my $nx=$self->object_get_attribute('noc_param','NX');
	my $ny=$self->object_get_attribute('noc_param','NY');
	
	
	
	my @tiles=get_tiles_name($self);
	
	
	my $i=0;
	my @tasks=get_all_tasks($self);
	
	my @assigned = $self->get_assigned_tiles();
	
	
	#a-b
	my @list= get_diff_array(\@tiles ,\@assigned);
	push(@list,'-');
	
	#print "tils=@tiles \nass=@assigned  \nlist=@list\n";
	my %com_tasks= $self->get_communication_task();
	
	foreach my $p (@tasks){
		my $value=$self->object_get_attribute("MAP_TILE",$p);
		$value = "-" if (!defined $value);
		my @l=($value eq "-" || grep (/^\Q$value\E$/,@tiles)==0 )? @list : (@list,$value);
		my $combo= map_combobox ($self,"$p",\@l,'-');
		
		#my $lock=$self->object_get_attribute("MAP_LOCK",$p);
		#$lock = 0 if (!defined $lock);
		my $lock = gen_check_box_object ($self,"MAP_LOCK",$p,0,undef,undef);
		
			
		$table-> attach  (gen_label_in_left($i), $col, $col+1,  $row, $row+1,'shrink','shrink',2,2); $col++; 
		$table-> attach  (gen_label_in_left($p), $col, $col+1,  $row, $row+1,'shrink','shrink',2,2); $col++; 
		$table-> attach  ($combo, $col, $col+1,  $row, $row+1,'shrink','shrink',2,2); $col++; 
		$table-> attach  ($lock, $col, $col+1,  $row, $row+1,'shrink','shrink',2,2); $col++; 
		my @a=('sent','rsv','total');
		foreach my $q (@a){
			my $s = (defined $com_tasks{$p}{$q}) ? $com_tasks{$p}{$q} : '-';
			$table-> attach  (gen_label_in_left($s), $col, $col+1,  $row, $row+1,'shrink','shrink',2,2); $col++; 
		
		}
		
		
		
		
	
		$i++;
		$col=0;
		$row++;						
	}
			
	
	return $sc_win;
	
}



########
# map_info
#######


sub map_info {
	my ($self)=@_;
	my $sc_win = gen_scr_win_with_adjst($self,'map_info');
	my $table= def_table(10,10,FALSE);
	$sc_win->add_with_viewport($table);
	
	my $row=0;
	my $col=0;
	my ($avg,$max,$min,$norm)=get_map_info($self);
	
	
	my @data = (
  {label => "Average distance",  value =>"$avg"}, 
  {label => "Max distance",  value =>"$max" },  
  {label => "Min distance",value => "$min"},    
  {label => "Normlized data per hop", value =>"$norm" }
  );
	
	
	
  # create list store
  my $store = Gtk2::ListStore->new (#'Glib::Boolean', # => G_TYPE_BOOLEAN
                                    #'Glib::Uint',    # => G_TYPE_UINT
                                    'Glib::String',  # => G_TYPE_STRING
                                    'Glib::String'); # you get the idea

  # add data to the list store
  foreach my $d (@data) {
      my $iter = $store->append;
      $store->set ($iter,
		   0, $d->{label},
		   1, $d->{value},
      );
  }

 my $treeview = Gtk2::TreeView->new ($store);
    $treeview->set_rules_hint (TRUE);
 

	$treeview->set_search_column (1);

   
    # add columns to the tree view
   my $renderer = Gtk2::CellRendererToggle->new;
   $renderer->signal_connect (toggled => \&fixed_toggled, $store);

 

  # column for severities
  $renderer = Gtk2::CellRendererText->new;
  my $column = Gtk2::TreeViewColumn->new_with_attributes ("Mapping summary",
						       $renderer,
						       text => 0);
  $column->set_sort_column_id (0);
  $treeview->append_column ($column);

  # column for description
  $renderer = Gtk2::CellRendererText->new;
  $column = Gtk2::TreeViewColumn->new_with_attributes (" ",
						       $renderer,
						       text => 1);
  $column->set_sort_column_id (1);
  $treeview->append_column ($column);

	
	$table-> attach  ($treeview, $col, $col+1,  $row, $row+1,'shrink','shrink',2,2); $row++; 
	#$table-> attach  (gen_label_in_left("Max distance:  $max  "), $col, $col+1,  $row, $row+1,'shrink','shrink',2,2); $row++; 
	#$table-> attach  (gen_label_in_left("Min distance: $min   "), $col, $col+1,  $row, $row+1,'shrink','shrink',2,2); $row++; 
	#$table-> attach  (gen_label_in_left("Normlized data per hop: $norm"), $col, $col+1,  $row, $row+1,'shrink','shrink',2,2); $row++; 
		
	
	return $sc_win;

}




sub get_map_info {
	my $self=shift;
	my ($avg,$max,$min,$norm)=(0,0,999999,0);
	my $sum=0;	
	my $num=0;	
	
	my $data=0;	
	my $comtotal=0;	
	
	my @traces= $self->get_trace_list();
	foreach my $p (@traces) {	
		my ($src, $dst, $Mbytes, $file_id, $file_name)=$self->get_trace($p);
		my $src_tile = $self->object_get_attribute('MAP_TILE',"$src");
		my $dst_tile = $self->object_get_attribute('MAP_TILE',"$dst");
		next if(!defined $src_tile || !defined  $dst_tile );
		next if($src_tile eq '-' || $dst_tile eq "-" );
		my ($src_x,$src_y)= tile_id_to_loc($src_tile);
		my ($dst_x,$dst_y)= tile_id_to_loc($dst_tile);
		
		
		
		#print" ($dst_x,$dst_y)= tile_id_to_loc($dst_tile)\n";
		
		my $mah_distance=get_mah_distance($src_x,$src_y,$dst_x,$dst_y);
		#print "$mah_distance=get_mah_distance($src_x,$src_y,$dst_x,$dst_y);\n";
		$min = $mah_distance if($min> $mah_distance);
		$max = $mah_distance if($max< $mah_distance);
		$sum+=$mah_distance;	
		$num++;	
		
		$data+=($Mbytes*$mah_distance);	
	    $comtotal+=$Mbytes;	
		
	}
	
	$avg=$sum/$num if($num!=0);
	$min = 0 if $min == 999999;
	$norm = $data/$comtotal if ($comtotal !=0);
	return ($avg,$max,$min,$norm);
	
}	





sub map_combobox {
 	my ($object,$task_name,$content,$default)=@_;
	my @combo_list=@{$content};
	my $value=$object->object_get_attribute("MAP_TILE",$task_name);
	my $pos;
	$pos=get_pos($value, @combo_list) if (defined $value);
	if(!defined $pos && defined $default){
		$object->object_add_attribute("MAP_TILE",$task_name,$default);	
	 	$pos=get_item_pos($default, @combo_list);
	}
	#print " my $pos=get_item_pos($value, @combo_list);\n";
	my $widget=gen_combo(\@combo_list, $pos);
	$widget-> signal_connect("changed" => sub{
		my $new_tile=$widget->get_active_text();
		$object->map_task($task_name,$new_tile);
				
		set_gui_status($object,'ref',1);
	 });
	return $widget;	
}


##########
#	save_as
##########
sub save_as{
	my ($self)=@_;
	# read emulation name
	my $name=$self->object_get_attribute ("save_as",undef);	
	my $s= (!defined $name)? 0 : (length($name)==0)? 0 :1;	
	if ($s == 0){
		message_dialog("Please define file name!");
		return 0;
	}
	# Write object file
	open(FILE,  ">lib/simulate/$name.TRC") || die "Can not open: $!";
	print FILE perl_file_header("$name.TRC");
	print FILE Data::Dumper->Dump([\%$self],['Trace']);
	close(FILE) || die "Error closing file: $!";
	message_dialog("workspace has been saved as lib/simulate/$name.TRC!");
	return 1;
}




#############
#	load_workspace
############

sub load_workspace {
	my $self=shift;
	my $file;
	my $dialog = Gtk2::FileChooserDialog->new(
            	'Select a File', undef,
            	'open',
            	'gtk-cancel' => 'cancel',
            	'gtk-ok'     => 'ok',
        	);

	my $filter = Gtk2::FileFilter->new();
	$filter->set_name("TRC");
	$filter->add_pattern("*.TRC");
	$dialog->add_filter ($filter);
	my $dir = Cwd::getcwd();
	$dialog->set_current_folder ("$dir/lib/simulate");		


	if ( "ok" eq $dialog->run ) {
		$file = $dialog->get_filename;
		my ($name,$path,$suffix) = fileparse("$file",qr"\..[^.]*$");
		if($suffix eq '.TRC'){
			my $pp= eval { do $file };
			if ($@ || !defined $pp){		
				message_dialog("**Error reading  $file file: $@\n");
				 $dialog->destroy;
				return;
			} 
			
			clone_obj($self,$pp);
			#message_dialog("done!");				
		}					
     }
     $dialog->destroy;
}


########
# genereate_output
########

sub genereate_output{
	my $self=shift;
	my $name= $self->object_get_attribute('out_name');
	my $size= (defined $name)? length($name) :0;
	if ($size ==0) {
		message_dialog("Please define the output file name!");
		return 0;
	}
	
	
	
	# make target dir
	my $dir = Cwd::getcwd();
	my $target_dir  = "$ENV{'PRONOC_WORK'}/traffic_pattern";
	mkpath("$target_dir",1,0755);
	
	my @tasks=get_all_tasks($self);
	foreach my $p (@tasks) {	
		my $tile=$self->object_get_attribute("MAP_TILE",$p);
		if ( $tile eq "-" ){
			message_dialog("Error: unmapped task. Please map task $p to a tile", 'error' );
			return;
		}
	
	}
	#creat output file
    open(FILE,  ">$target_dir/$name.cfg") || die "Can not open: $!";
	print FILE get_cfg_content($self);
	close(FILE) || die "Error closing file: $!";
	message_dialog("The traffic pattern is saved as $target_dir/$name.cfg" );
	
}

sub get_cfg_content{
	my $self=shift;
	my $file="% source tile, destination tile, bytes, initial_weight, min_pck_size, max_pck_size, burst_size, injection_rate(%), injection_rate variation(%)\n";
	

	
	my @traces= $self->get_trace_list();
	foreach my $p (@traces) {	
		my ($src,$dst, $Mbytes, $file_id, $file_name,$init_weight,$min_pck, $max_pck,  $burst, $injct_rate, $injct_rate_var)=$self->get_trace($p);
		
		
		my $src_tile=$self->get_tile_id($src);
		my $dst_tile=$self->get_tile_id($dst);
		my $auto=$self->object_get_attribute('Auto','Auto_inject');
		
		my $bytes = $Mbytes * 1000000;
		
		$file=$file."$src_tile, $dst_tile, $bytes, $init_weight, $min_pck, $max_pck";
		$file=$file.", $burst, $injct_rate, $injct_rate_var \n" if ($auto eq "1\'b0");
		$file=$file." \n" if ($auto eq "1\'b1");
	}
	
	return $file;
}

sub get_tile_id{
	my ($self,$task)=@_;
	my $nx=$self->object_get_attribute('noc_param','NX');
	my $tile=$self->object_get_attribute("MAP_TILE",$task);
	my ($x, $y) =  $tile =~ /(\d+)/g;  
	$y=0 if(!defined $y);
	my $IP_NUM =    ($y * $nx) +    $x;	
	return $IP_NUM;
}

sub object_add_attribute{
	my ($self,$attribute1,$attribute2,$value)=@_;
	if(!defined $attribute2){$self->{$attribute1}=$value;}
	else {$self->{$attribute1}{$attribute2}=$value;}

}



sub object_get_attribute{
	my ($self,$attribute1,$attribute2)=@_;
	if(!defined $attribute2) {return $self->{$attribute1};}
	return $self->{$attribute1}{$attribute2};


}


sub object_add_attribute_order{
	my ($self,$attribute,@param)=@_;
	$self->{'parameters_order'}{$attribute}=[] if (!defined $self->{parameters_order}{$attribute});
	foreach my $p (@param){
		push (@{$self->{parameters_order}{$attribute}},$p);

	}
}
sub object_get_attribute_order{
	my ($self,$attribute)=@_;
	return @{$self->{parameters_order}{$attribute}};
}

sub object_remove_attribute{
	my ($self,$attribute1,$attribute2)=@_;
	if(!defined $attribute2){
		delete $self->{$attribute1} if ( exists( $self->{$attribute1})); 
	}
	else {
		delete $self->{$attribute1}{$attribute2} if ( exists( $self->{$attribute1}{$attribute2})); ;

	}

}

sub add_trace{
	my ($self, $file_id,$trace_id, $source,$dest, $Mbytes, $file_name)=@_;	
	$self->object_add_attribute("trace_$trace_id",'file',$file_id);
	$self->object_add_attribute("trace_$trace_id",'source',"${file_id}${source}");
	$self->object_add_attribute("trace_$trace_id",'destination',"${file_id}${dest}");
	$self->object_add_attribute("trace_$trace_id",'Mbytes', $Mbytes);
	$self->object_add_attribute("trace_$trace_id",'file_name', $file_name);  
	$self->object_add_attribute("trace_$trace_id",'selected', 0); 
	$self->object_add_attribute("trace_$trace_id",'init_weight', 1); 
		
	$self->{'traces'}{$trace_id}=1;
	
}

sub remove_trace{
	my ($self, $trace_id)=@_;
	delete $self->{"trace_$trace_id"};	
	delete $self->{'traces'}{$trace_id};
}

sub get_trace_list{
	my ($self)=@_;
	return sort (keys %{$self->{'traces'}});	
}

sub get_trace{
	my ($self,$trace_id)=@_;	
	my $file_id		= $self->object_get_attribute("trace_$trace_id",'file');
	my $source 		= $self->object_get_attribute("trace_$trace_id",'source');
	my $dest		= $self->object_get_attribute("trace_$trace_id",'destination');
	my $Mbytes  	= $self->object_get_attribute("trace_$trace_id",'Mbytes');
	my $file_name	= $self->object_get_attribute("trace_$trace_id",'file_name');	
	my $init_weight = $self->object_get_attribute("trace_$trace_id",'init_weight'); 
	my $min_pck_size= $self->object_get_attribute("trace_$trace_id",'min_pck_size');
	my $max_pck_size= $self->object_get_attribute("trace_$trace_id",'max_pck_size');
	my $burst_size	= $self->object_get_attribute("trace_$trace_id",'burst_size'); 
	my $injct_rate  = $self->object_get_attribute("trace_$trace_id",'injct_rate');	
	my $injct_rate_var = $self->object_get_attribute("trace_$trace_id",'injct_rate_var');	
	  
	return ($source,$dest, $Mbytes, $file_id,$file_name,$init_weight,$min_pck_size, $max_pck_size, $burst_size, $injct_rate, $injct_rate_var);	
}

sub get_all_tasks{
	my $self=shift;
	my @traces= $self->get_trace_list();
	my @x;
	foreach my $p (@traces){
		my ($src,$dst, $Mbytes, $file_id, $file_name)=$self->get_trace($p);
		push(@x,$src);
		push(@x,$dst);		
	}
	my @x2 =  uniq(sort  @x) if (scalar @x);
	return @x2;	
}


sub remove_mapping{
	my $self=shift;
	$self->object_add_attribute('MAP_TASK',undef,undef);
	$self->object_add_attribute('MAP_TILE',undef,undef);
}



sub remove_nlock_mapping{
	my $self=shift;
	my @tasks=get_all_tasks($self);
	
	foreach my $p (@tasks){
		my $lock=$self->object_get_attribute("MAP_LOCK",$p);
		$lock = 0 if (!defined $lock);
		if($lock == 0){
			my $tile=$self->object_get_attribute("MAP_TILE",$p);
			$self->object_add_attribute("MAP_TILE",$p,undef);
			$self->object_add_attribute("MAP_TASK",$tile,undef);
			
		}		
	}	
}


sub get_nlock_tasks {
	#my ($self,$taskref,$tileref)=shift;
	my $self=shift;
	my @unluck_tasks;
	my @tasks=get_all_tasks($self);
	
	foreach my $p (@tasks){
		my $lock=$self->object_get_attribute("MAP_LOCK",$p);
		$lock = 0 if (!defined $lock);
		if($lock == 0){
			push(@unluck_tasks,$p);
		}
	
	}
	return  @unluck_tasks;	
}

sub get_nlock_tiles {
	#my ($self,$taskref,$tileref)=shift;
	my $self=shift;
	my @luck_tiles;
	my @tasks=get_all_tasks($self);
	
	foreach my $task (@tasks){
		my $lock=$self->object_get_attribute("MAP_LOCK",$task);
		$lock = 0 if (!defined $lock);
		if($lock == 1){
			my $tile=$self->object_get_attribute('MAP_TILE',"$task");
			push(@luck_tiles,$tile);
		}
	
	}
	my @tiles=get_tiles_name($self);
	
	#a-b
	return get_diff_array(\@tiles,\@luck_tiles);	
}


sub get_locked_map {
	my $self=shift;
	my %map; 
	my @tasks=get_all_tasks($self);
	
	foreach my $task (@tasks){
		my $lock=$self->object_get_attribute("MAP_LOCK",$task);
		
		$lock = 0 if (!defined $lock);
		if($lock == 1){
			my $tile=$self->object_get_attribute('MAP_TILE',"$task");
			$map{$task}=$tile;
		}
	
	}
	return  %map;	
}


#########
#	Mapping algorithm
#########
sub random_map{
	my $self=shift;
		
	
	
	my $nx=$self->object_get_attribute('noc_param','NX');
	my $ny=$self->object_get_attribute('noc_param','NY');
	my $nc= $nx * $ny;
	
	
	
	my @tasks=get_nlock_tasks($self);	
	my @tiles=get_nlock_tiles($self);	
	$self->remove_nlock_mapping() ;
	
	
	my @rnd= shuffle @tiles;
	
	my $i=0;
	foreach my $task (@tasks){
		if($i>=scalar @rnd){
			last;
		};
		my $tile=$rnd[$i];
		$self->object_add_attribute('MAP_TILE',"$task",$tile);
		$self->object_add_attribute('MAP_TASK',"$tile",$task);
	
		$i++;	
		
	}
	
	set_gui_status($self,"ref",1);
	
}

sub direct_map {
	my $self=shift;
	
	my $nx=$self->object_get_attribute('noc_param','NX');
	my $ny=$self->object_get_attribute('noc_param','NY');
	my $nc= $nx * $ny;	
	my @tasks=get_nlock_tasks($self);	
	my @tiles=get_nlock_tiles($self);	
	$self->remove_nlock_mapping() ;
	
	my @sort_tiles;
	my %tilenum;
	foreach my $tile (@tiles){
		my ($x,$y)=tile_id_to_loc($tile);
		my $id= $y*$nx+$x;
		$tilenum{$id}=$tile;
	}
	
	foreach my $id  (sort keys %tilenum){
		
		push(@sort_tiles, $tilenum{$id});
	}
	
	
	my @sort_tasks = sort @tasks;
	
	
	my $i=0;
	foreach my $task (@sort_tasks){
		if($i>=scalar @sort_tiles){
			last;
		};
		my $tile=$sort_tiles[$i];
		$self->object_add_attribute('MAP_TILE',"$task",$tile);
		$self->object_add_attribute('MAP_TASK',"$tile",$task);
	
		$i++;	
		
	}
	
	set_gui_status($self,"ref",1);
	
	
}



	
	
	




sub network_dim_cal{
	my $n_tasks= shift;
	 
	my $dim_y = floor(sqrt($n_tasks));

	my $dim_x = ceil($n_tasks/$dim_y);
	
	return ($dim_x,$dim_y);

	#cout << "dim_x = " << dim_x << "; dim_y = " << dim_y << endl;
}


sub get_tiles_name{
	my $self=shift;
	my @tiles;
	my $nx=$self->object_get_attribute('noc_param','NX');
	my $ny=$self->object_get_attribute('noc_param','NY');
	if(defined $ny){
		if($ny == 1){
			for(my $x=0; $x<$nx; $x++){
				push(@tiles,"tile($x)");
			}
			
		}
		else{
			for(my $y=0; $y<$ny; $y++){my $nx=$self->object_get_attribute('noc_param','NX');
	my $ny=$self->object_get_attribute('noc_param','NY');
				for(my $x=0; $x<$nx; $x++){
					push(@tiles,"tile(${x}_$y)");
				}
			}
			
		}
	}
	return @tiles;	
}

sub get_tile_name{
	my ($self,$x,$y)=@_;

	my $nx=$self->object_get_attribute('noc_param','NX');
	my $ny=$self->object_get_attribute('noc_param','NY');
	if(defined $ny){
		return "tile($x)" if($ny == 1);
	}
	return "tile(${x}_$y)";
}


sub tile_id_to_loc{
	my $tile=shift;
	my ($x, $y) =  $tile =~ /(\d+)/g;  
	$y=0 if(!defined $y);
	return ($x,$y);
}

sub get_mah_distance{
	my ($x1,$y1,$x2,$y2)=@_;
	my $x_diff = ($x1 > $x2) ? ($x1 - $x2) : ($x2 - $x1);
	my $y_diff = ($y1 > $y2) ? ($y1 - $y2) : ($y2 - $y1);
	my $mah_distance = $x_diff + $y_diff;
	return $mah_distance;
}

sub get_communication_task{
	my $self=shift;
	my %com_tasks;
	my @traces= $self->get_trace_list();
	my @tasks=get_all_tasks($self);
	foreach my $p (@tasks){
		$com_tasks{$p}{'total'}= 0;
		foreach my $q (@tasks){
			$com_tasks{$p}{$q}= 0;
		
		}
	}
	
	foreach my $p (@traces){
		my ($src,$dst, $Mbytes, $file_id, $file_name)=$self->get_trace($p);
		
		
		$com_tasks{$src}{'sent'} += $Mbytes;
		$com_tasks{$dst}{'rsv'} += $Mbytes;
		
		$com_tasks{$src}{'total'} += $Mbytes;
		$com_tasks{$dst}{'total'} += $Mbytes;
		$com_tasks{$src}{$dst} += $Mbytes;
		$com_tasks{$file_id}{'maxsent'} = $com_tasks{$src}{'sent'} if(!defined $com_tasks{$file_id}{'maxsent'});
		$com_tasks{$file_id}{'maxsent'} = $com_tasks{$src}{'sent'} if( $com_tasks{$file_id}{'maxsent'}<$com_tasks{$src}{'sent'});
		
		
		
		my $minpck = $self->object_get_attribute("trace_$p",'min_pck_size');
		my $maxpck = $self->object_get_attribute("trace_$p",'max_pck_size');
		my $avg_pck_size =($minpck+ $maxpck)/2;
		my $pck_num = ($Mbytes*8) /($avg_pck_size*64);
		$pck_num= 1 if($pck_num==0); 		
		$com_tasks{$src}{'min_pck_num'} =$pck_num if(!defined $com_tasks{$src}{'min_pck_num'}); 
		$com_tasks{$src}{'min_pck_num'} =$pck_num if( $com_tasks{$src}{'min_pck_num'} > $pck_num); 
		
	}
	return %com_tasks;
}	


sub find_max_neighbor_tile{
	my $self=shift;
	my $nx=$self->object_get_attribute('noc_param','NX');
	my $ny=$self->object_get_attribute('noc_param','NY');
	my $x_mid = floor($nx/2);
	my $y_mid = floor($ny/2);
	#my $centered_tile= get_tile_name($self,$x_mid ,$y_mid);
	#Select the tile located in center as the max-neighbor if its not locked for any other task
	#therwise select the tile with the min manhatan distance to center tile
	my @tiles=get_nlock_tiles($self);
	my $min=1000000;
	my $max_neighbors_tile_id;
	foreach my $tile (@tiles){
		my ($x,$y)=tile_id_to_loc($tile);
		my $mah_distance=get_mah_distance($x,$y,$x_mid,$y_mid);
		if($min > $mah_distance ){
			$min = $mah_distance;
			$max_neighbors_tile_id=$tile;
		}
		
	} 	

	return $max_neighbors_tile_id;
}	
	
	
sub find_min_neighbor_tile	{
	my $self=shift;
	my $nx=$self->object_get_attribute('noc_param','NX');
	my $ny=$self->object_get_attribute('noc_param','NY');
	my $x_mid = 0;
	my $y_mid = 0;
	#my $centered_tile= get_tile_name($self,$x_mid ,$y_mid);
	#Select the tile located in center as the max-neighbor if its not locked for any other task
	#therwise select the tile with the min manhatan distance to center tile
	my @tiles=get_nlock_tiles($self);
	my $min=1000000;
	my $min_neighbors_tile_id;
	foreach my $tile (@tiles){
		my ($x,$y)=tile_id_to_loc($tile);
		my $mah_distance=get_mah_distance($x,$y,$x_mid,$y_mid);
		if($min > $mah_distance ){
			$min = $mah_distance;
			$min_neighbors_tile_id=$tile;
		}
		
	} 	

	return $min_neighbors_tile_id;
}	
	


sub nmap_algorithm{

	my $self=shift;
	
	
	my $nx=$self->object_get_attribute('noc_param','NX');
	my $ny=$self->object_get_attribute('noc_param','NY');
	my $nc= $nx * $ny;
	
	my @tasks=get_all_tasks($self);
	my @tiles= get_tiles_name($self);
	
	my $n_tasks = scalar  @tasks;
	
	
	
	
	my @unmapped_tasks_set=@tasks; # unmapped set of tasks
	my @unallocated_tiles_set=@tiles;	# tile ids which are not allocated yet
	
	
	
	
	#------ step 1: find the task with highest weighted communication volume
	# find the max of com_vol
	# consider all incoming and outgoing connections of each tasks
	
	my %com_tasks= $self->get_communication_task();
	#print  Data::Dumper->Dump([\%com_tasks],['mpsoc']);	
	
	my $max_com_task;
	my $max_com =0;
	foreach my $p (sort keys %com_tasks){
		#print "$p\n";
		if(defined $com_tasks{$p}{'total'}){
		if ($com_tasks{$p}{'total'} >$max_com){
			$max_com = $com_tasks{$p}{'total'};
			$max_com_task = $p;
		}}
	}
	
	
	
	
	#------ step 2: find the tile with max number of neighbors
	# normally, this tile is in the middle of the array
	my $max_neighbors_tile_id = find_max_neighbor_tile($self);
	
	
	
	
	my %map=get_locked_map ($self);	
	$self->remove_nlock_mapping();
	foreach my $mapped_task (sort keys %map){
			my $mapped_tile=$map{$mapped_task};
			@unmapped_tasks_set=remove_scolar_from_array(\@unmapped_tasks_set,$mapped_task);
			@unallocated_tiles_set=remove_scolar_from_array(\@unallocated_tiles_set,$mapped_tile);
	}
		
	
	
	
	# add this task with highest weighted communication volume to the mapped task set
	#push(@mapped_tasks_set,$max_com_task);
	#task_mapping[max_com_task] = max_neighbors_tile_id;
	
	if(!defined $map{$max_com_task}){
		$map{$max_com_task}=$max_neighbors_tile_id;
		@unmapped_tasks_set=remove_scolar_from_array(\@unmapped_tasks_set,$max_com_task);
		@unallocated_tiles_set=remove_scolar_from_array(\@unallocated_tiles_set,$max_neighbors_tile_id);
	}







	#------ step 3: map all unmapped tasks
	while(scalar @unmapped_tasks_set){
		$max_com =0;
		my $max_com_unmapped_task;
		my $max_overall_com=0;
		#--------- step 3.1:
		# find the unmapped task which communicates most with mapped_tasks_set
		# among many tasks which have the same communication volume with mapped_tasks,
		# choose the task with highest communication volume with others
		
		foreach my $unmapped_task (@unmapped_tasks_set){
			
			my $com_vol=0;
			foreach my $mapped_task (sort keys %map){
				$com_vol += $com_tasks{$unmapped_task}{$mapped_task};
				$com_vol += $com_tasks{$mapped_task}{$unmapped_task};
			}
			
			my $overall_com_vol = 0;
			foreach my $p (@tasks){
				$overall_com_vol += $com_tasks{$unmapped_task}{$p};
				$overall_com_vol += $com_tasks{$p}{$unmapped_task};
			}
			
			
			if ($com_vol > $max_com){
				$max_com = $com_vol;
				$max_com_unmapped_task = $unmapped_task;
				$max_overall_com = $overall_com_vol;
			}
			elsif ($com_vol == $max_com){ # choose if it have higher comm volume
				if ($overall_com_vol > $max_overall_com){
					$max_com_unmapped_task = $unmapped_task;
					$max_overall_com = $overall_com_vol;
				}
			}
		}#foreach my $unmapped_task (@unmapped_tasks_set)

		#--------- step 3.2, find the unallocated tile with lowest communication cost to/from allocated_tile_set
		my $min_com_cost;
		my $min_com_cost_tile_id;
		
		
		foreach my $unallocated_tile(@unallocated_tiles_set){
			my $com_cost = 0;
			my ($unallocated_x,$unallocated_y)=tile_id_to_loc($unallocated_tile);
			# scan all mapped tasks
			foreach my $mapped_task (sort keys %map){
				# get location of this mapped task
				my $mapped_tile=$map{$mapped_task};
				my ($allocated_x,$allocated_y)=tile_id_to_loc($mapped_tile);				
				# mahattan distance of 2 tiles
				my $mah_distance=get_mah_distance($unallocated_x,$unallocated_y,$allocated_x,$allocated_y);
				

				$com_cost += $com_tasks{$max_com_unmapped_task}{$mapped_task} * $mah_distance;
				$com_cost += $com_tasks{$mapped_task}{$max_com_unmapped_task} * $mah_distance;
					
			}
			$min_com_cost = $com_cost+1 if(!defined $min_com_cost);
			if ($com_cost < $min_com_cost){
				$min_com_cost = $com_cost;
				$min_com_cost_tile_id = $unallocated_tile;
			}
		}
		
		# add max_com_unmapped_task to the mapped_tasks_set set
		#task_mapping[max_com_unmapped_task] = min_com_cost_tile_id;
		$map{$max_com_unmapped_task}=$min_com_cost_tile_id;
		@unmapped_tasks_set=remove_scolar_from_array(\@unmapped_tasks_set,$max_com_unmapped_task);
		@unallocated_tiles_set=remove_scolar_from_array(\@unallocated_tiles_set,$min_com_cost_tile_id);
		
	}
	
	
	foreach my $mapped_task (sort keys %map){
			my $mapped_tile=$map{$mapped_task};
			#print "$mapped_tile=\$map{$mapped_task};\n";
			$self->object_add_attribute('MAP_TILE',"$mapped_task", $mapped_tile) if(defined $mapped_tile);
			$self->object_add_attribute('MAP_TASK',"$mapped_tile",$mapped_task) if(defined $mapped_tile);
			
	}
	set_gui_status($self,"ref",1);
		
}	
		
		






sub worst_map_algorithm{

	my $self=shift;
	
	
	my $nx=$self->object_get_attribute('noc_param','NX');
	my $ny=$self->object_get_attribute('noc_param','NY');
	my $nc= $nx * $ny;
	
	my @tasks=get_all_tasks($self);
	my @tiles= get_tiles_name($self);
	
	my $n_tasks = scalar  @tasks;
	
	
	
	
	my @unmapped_tasks_set=@tasks; # unmapped set of tasks
	my @unallocated_tiles_set=@tiles;	# tile ids which are not allocated yet
	
	
	
	
	#------ step 1: find the task with highest weighted communication volume
	# find the max of com_vol
	# consider all incoming and outgoing connections of each tasks
	
	my %com_tasks= $self->get_communication_task();
	#print  Data::Dumper->Dump([\%com_tasks],['mpsoc']);	
	
	my $max_com_task;
	my $max_com =0;
	foreach my $p (sort keys %com_tasks){
		#print "$p\n";
		if(defined $com_tasks{$p}{'total'}){
		if ($com_tasks{$p}{'total'} >$max_com){
			$max_com = $com_tasks{$p}{'total'};
			$max_com_task = $p;
		}}
	}
	
	
	
	
	#------ step 2: find the tile with min number of neighbors
	# normally, this tile is in the corners 
	my $min_neighbors_tile_id = find_min_neighbor_tile($self);
	
	
	
	
	my %map=get_locked_map ($self);	
	$self->remove_nlock_mapping();
	foreach my $mapped_task (sort keys %map){
			my $mapped_tile=$map{$mapped_task};
			@unmapped_tasks_set=remove_scolar_from_array(\@unmapped_tasks_set,$mapped_task);
			@unallocated_tiles_set=remove_scolar_from_array(\@unallocated_tiles_set,$mapped_tile);
	}
		
	
	
	
	# add this task with highest weighted communication volume to the mapped task set
	#push(@mapped_tasks_set,$max_com_task);
	#task_mapping[max_com_task] = max_neighbors_tile_id;
	
	if(!defined $map{$max_com_task}){
		$map{$max_com_task}=$min_neighbors_tile_id;
		@unmapped_tasks_set=remove_scolar_from_array(\@unmapped_tasks_set,$max_com_task);
		@unallocated_tiles_set=remove_scolar_from_array(\@unallocated_tiles_set,$min_neighbors_tile_id);
	}







	#------ step 3: map all unmapped tasks
	while(scalar @unmapped_tasks_set){
		$max_com =0;
		my $max_com_unmapped_task;
		my $max_overall_com=0;
		#--------- step 3.1:
		# find the unmapped task which communicates most with mapped_tasks_set
		# among many tasks which have the same communication volume with mapped_tasks,
		# choose the task with highest communication volume with others
		
		foreach my $unmapped_task (@unmapped_tasks_set){
			
			my $com_vol=0;
			foreach my $mapped_task (sort keys %map){
				$com_vol += $com_tasks{$unmapped_task}{$mapped_task};
				$com_vol += $com_tasks{$mapped_task}{$unmapped_task};
			}
			
			my $overall_com_vol = 0;
			foreach my $p (@tasks){
				$overall_com_vol += $com_tasks{$unmapped_task}{$p};
				$overall_com_vol += $com_tasks{$p}{$unmapped_task};
			}
			
			
			if ($com_vol > $max_com){
				$max_com = $com_vol;
				$max_com_unmapped_task = $unmapped_task;
				$max_overall_com = $overall_com_vol;
			}
			elsif ($com_vol == $max_com){ # choose if it have higher comm volume
				if ($overall_com_vol > $max_overall_com){
					$max_com_unmapped_task = $unmapped_task;
					$max_overall_com = $overall_com_vol;
				}
			}
		}#foreach my $unmapped_task (@unmapped_tasks_set)

		#--------- step 3.2, find the unallocated tile with highest communication cost to/from allocated_tile_set
		my $max_com_cost;
		my $max_com_cost_tile_id;
		
		
		foreach my $unallocated_tile(@unallocated_tiles_set){
			my $com_cost = 0;
			my ($unallocated_x,$unallocated_y)=tile_id_to_loc($unallocated_tile);
			# scan all mapped tasks
			foreach my $mapped_task (sort keys %map){
				# get location of this mapped task
				my $mapped_tile=$map{$mapped_task};
				my ($allocated_x,$allocated_y)=tile_id_to_loc($mapped_tile);				
				# mahattan distance of 2 tiles
				my $mah_distance=get_mah_distance($unallocated_x,$unallocated_y,$allocated_x,$allocated_y);
				

				$com_cost += $com_tasks{$max_com_unmapped_task}{$mapped_task} * $mah_distance;
				$com_cost += $com_tasks{$mapped_task}{$max_com_unmapped_task} * $mah_distance;
					
			}
			$max_com_cost = $com_cost-1 if(!defined $max_com_cost);
			if ($com_cost > $max_com_cost){
				$max_com_cost = $com_cost;
				$max_com_cost_tile_id = $unallocated_tile;
			}
		}
		
		# add max_com_unmapped_task to the mapped_tasks_set set
		#task_mapping[max_com_unmapped_task] = min_com_cost_tile_id;
		$map{$max_com_unmapped_task}=$max_com_cost_tile_id;
		@unmapped_tasks_set=remove_scolar_from_array(\@unmapped_tasks_set,$max_com_unmapped_task);
		@unallocated_tiles_set=remove_scolar_from_array(\@unallocated_tiles_set,$max_com_cost_tile_id);
		
	}
	
	
	foreach my $mapped_task (sort keys %map){
			my $mapped_tile=$map{$mapped_task};
			#print "$mapped_tile=\$map{$mapped_task};\n";
			$self->object_add_attribute('MAP_TILE',"$mapped_task", $mapped_tile) if(defined $mapped_tile);
			$self->object_add_attribute('MAP_TASK',"$mapped_tile",$mapped_task) if(defined $mapped_tile);
			
	}
	set_gui_status($self,"ref",1);
		
}	














sub get_task_assigned_to_tile {
	my ($self,$x,$y)=@_;
	my $p;
	$p= $self->object_get_attribute("MAP_TASK","tile($x)");
	return $p if (defined $p); 
	$p= $self->object_get_attribute("MAP_TASK","tile(${x}_$y)");
	return $p;
}



sub get_assigned_tiles{
	my $self=shift;
	my @tiles = sort keys %{$self->{'MAP_TASK'}};
	return @tiles;	
	
}

sub map_task {
	my ($self,$task,$tile)=@_;
	my $oldtile= $self->{"MAP_TILE"}{$task};
	if($tile eq "-"){		
	 	delete $self->{"MAP_TILE"}{$task};
	}else{
		$self->{"MAP_TILE"}{$task}= $tile;
		$self->{'MAP_TASK'}{$tile}= $task;
	}	
	delete $self->{"MAP_TASK"}{$oldtile} if(defined $oldtile);			
}

sub remove_selected_traces{
	my $self=shift;
	my @traces= $self->get_trace_list();
	foreach my $p (@traces) {	
		my $select=$self->object_get_attribute("trace_$p",'selected', 0); 
		
		if($select){
			$self->remove_trace("$p");
			
		}
	}
	set_gui_status($self,"ref",1);
}



sub auto_generate_injtratio{
	my $self=shift;
	my %com_tasks= $self->get_communication_task();
	my @traces= $self->get_trace_list();
	foreach my $p (@traces) {	
		my ($src,$dst, $Mbytes, $file_id, $file_name)=$self->get_trace($p);
		my $max= $com_tasks{$file_id}{'maxsent'};
		my $sent= $com_tasks{$src}{'sent'};
		my $ratio = ($sent*100)/$max;
		$self->object_add_attribute("trace_$p",'injct_rate',$ratio);
		
		my $minpck = $self->object_get_attribute("trace_$p",'min_pck_size');
		my $maxpck = $self->object_get_attribute("trace_$p",'max_pck_size' );
		my $avg_pck_size =($minpck+ $maxpck)/2;
		my $pck_num = ($Mbytes*8) /($avg_pck_size*64);
		
				
		my $burst =$pck_num/ $com_tasks{$src}{'min_pck_num'} ;
		$self->object_add_attribute("trace_$p",'burst_size',ceil($burst));
		
		#my $burst_size	= gen_spin_object ($self,"trace_$p",'burst_size',"1,1024,1", 1,undef,undef);
		
		
		
	}
	set_gui_status($self,"ref",1);
	
	
}
	
