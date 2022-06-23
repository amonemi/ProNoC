#!/usr/bin/perl -w
use strict;
use warnings;

use constant::boolean;

use FindBin;
use lib $FindBin::Bin;

use Data::Dumper;
use File::Which;
use File::Basename;

use IPC::Run qw( harness start pump finish timeout );

use Consts;
BEGIN {
    my $module = (Consts::GTK_VERSION==2) ? 'Gtk2' : 'Gtk3';
    my $file = $module;
    $file =~ s[::][/]g;
    $file .= '.pm';
    require $file;
    $module->import;
}



require "widget.pl";
require "uart.pl";
require "compile.pl";


use String::Scanf; # imports sscanf()


use constant JTAG_UPDATE_WB_ADDR => 7;
use constant JTAG_UPDATE_WB_WR_DATA=>  6;
use constant JTAG_UPDATE_WB_RD_DATA => 5;	


use base 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors(qw{
	window
	sourceview		
});

my $NAME = 'Soure Probe';
my 	$path = "";



my %memory;
my %status;


sub source_probe_stand_alone(){
	$path = "../../";
	set_path_env();
	my $project_dir	  = get_project_dir(); #mpsoc dir addr
	my $paths_file= "$project_dir/mpsoc/perl_gui/lib/Paths";
	if (-f 	$paths_file){#} && defined $ENV{PRONOC_WORK} ) {
		my $paths= do $paths_file;
		set_gui_setting($paths);
	}
	
	set_defualt_font_size();
	my $window=source_probe_main();
	$window->signal_connect (destroy => sub { gui_quite();});
}

exit gtk_gui_run(\&source_probe_stand_alone) unless caller;


sub get_jtag_intfc_rst_cmd {
	my $self=shift;
	
	my $vendor = $self->object_get_attribute('CTRL','VENDOR');
	my $board  = $self->object_get_attribute('CTRL','Board_Name');
	my $chain  = $self->object_get_attribute('CTRL','RESET_CHAIN');
	my $index  = 127;
	my $pronoc = get_project_dir();
	my $intfc = "$pronoc/mpsoc/boards/$vendor/$board/jtag_intfc.sh";
	#my $script  = "$ENV{'PRONOC_WORK'}/tmp/script.bash";
	
	my $t = ($vendor eq 'Xilinx') ? "-t  $chain " : "";
	
	my $cmd = "bash -c \"source $intfc; \\\$JTAG_INTFC $t -n $index";
	return $cmd;
	
}


sub jtag_enable_cpus_func{
	my ($self,$new,$tview)=@_;
	my $intfc = get_jtag_intfc_rst_cmd($self);
    my $e = ($new eq 'Enabled')? 0 : 2;
	my $cmd =	"$intfc  -d   I:1,D:2:$e,I:0\"";
	add_info($tview,"$cmd\n");	
	my $results =run_cmd_textview_errors($cmd,$tview);
	return 1 if(!defined $results);

}

sub jtag_reset_cpus_func {
	my ($self,$tview)=@_;
	my $intfc = get_jtag_intfc_rst_cmd($self);

	my $cmd =	"$intfc  -d   I:1,D:2:1,D:2:0,I:0\"";
	add_info($tview,"$cmd\n");	
	my $results =run_cmd_textview_errors($cmd,$tview);
	return 1 if(!defined $results);
			
};	





sub source_probe_ctrl {
	my ($self,$tview)=@_;
	my $table= def_table(2,10,FALSE);
	
	my $vendor= $self->object_get_attribute('CTRL','VENDOR');
	$vendor= 'Xilinx' if(!defined $vendor);
	
	
	#get the list of boards located in "boards/*" folder
	my $pronoc = get_project_dir();

	my @dirs = grep {-d} glob("$pronoc/mpsoc/boards/$vendor/*");
	my ($fpgas,$init);
	
	
	foreach my $dir (@dirs) {
		my ($name,$path,$suffix) = fileparse("$dir",qr"\..[^.]*$");		
		$fpgas= (defined $fpgas)? "$fpgas,$name" : "$name";	
		$init="$name";	
	}
	
	
	my @info = (
	{ label=>" FPGA Vendor name: ", param_name=>'VENDOR', type=>"Combo-box", default_val=>'Xilinx', content=>"Xilinx,Altera", info=>undef, param_parent=>'CTRL', ref_delay=> 1, new_status=>'ref_ctrl', loc=>'vertical'},
	{ label=>" Board Name ", param_name=>'Board_Name', type=>"Combo-box", default_val=>$init, content=>$fpgas, info=>undef, param_parent=>'CTRL', ref_delay=> undef, new_status=>undef, loc=>'vertical'},
	{ label=>" JTAG Index: ", param_name=>'JTAG_INDEX', type=>"Spin-button", default_val=>0, content=>"0,128,1", info=>undef, param_parent=>'CTRL', ref_delay=> undef, new_status=> undef, loc=>'vertical'}	
	);	
	
	
	
	if ($vendor eq "Xilinx" ) {
		push (@info,{ label=>" JTAG CHAIN ", param_name=>'JTAG_CHAIN', type=>"Combo-box", default_val=>4, content=>"1,2,3,4", info=>undef, param_parent=>'CTRL', ref_delay=> 0, new_status=>'ref_ctrl', loc=>'vertical'}) ;

	}
	
		
	my ($row,$col)=(0,6);
	
	foreach my $d (@info) {
		my $wiget;		
		($row,$col,$wiget)=add_param_widget  ($self, $d->{label}, $d->{param_name}, $d->{default_val}, $d->{type}, $d->{content}, $d->{info}, $table,$row,$col,1, $d->{param_parent}, $d->{ref_delay}, $d->{new_status}, $d->{loc});
		my $sc=$col;
		if($d->{param_name} eq 'Board_Name'){
			my $add=def_image_button("icons/plus.png");
			$table->attach ($add,  $sc+4, $sc+5,$row-1,$row,'shrink','shrink',2,2); 
			set_tip($add, "Add new FPGA Board"); 
			$add-> signal_connect("clicked" => sub{
				add_new_fpga_board($self,undef,undef,undef,undef,$vendor);
			}); 			
			
		}
	
	
	}	
	
	 
	 $table->attach (  gen_Vsep(), 5, 6 , 0, $row+1,'fill','fill',2,2);
	
	#Column 2
	$row=0;$col=0;
	my $d={ label=>" Number of Sources/Probes:", param_name=>'SP_NUM', type=>"Spin-button", default_val=>1, content=>"1,128,1", info=>undef, param_parent=>'CTRL', ref_delay=> 1, new_status=>'ref_all', loc=>'vertical'};		
	($row,$col)=add_param_widget  ($self, $d->{label}, $d->{param_name}, $d->{default_val}, $d->{type}, $d->{content}, $d->{info}, $table,$row,$col,1, $d->{param_parent}, $d->{ref_delay}, $d->{new_status}, $d->{loc});
	$d={ label=>" Address format: ", param_name=>'R_ADDR_FORMAT', type=>"Combo-box", default_val=>'Decimal', content=>"Decimal,Hexadecimal", info=>undef, param_parent=>'FILE_VIEW', ref_delay=> 1, new_status=>'ref_file_view', loc=>'vertical'},
	($row,$col)=add_param_widget  ($self, $d->{label}, $d->{param_name}, $d->{default_val}, $d->{type}, $d->{content}, $d->{info}, $table,$row,$col,1, $d->{param_parent}, $d->{ref_delay}, $d->{new_status}, $d->{loc});
	
	
	#enable
	my $en_state=$self->object_get_attribute("CTRL","enable");
	if (!defined $en_state){
		$en_state='Enabled' ;
		$self->object_add_attribute("CTRL","enable",$en_state);
	}		
	my $enable= ($en_state eq 'Enabled')? def_colored_button('Enabled',17): def_colored_button('Disabled',4);
	
	my $reset= def_button('Reset');
	
	if ($vendor eq "Xilinx" ) {
	
		my $w=gen_combobox_object ($self,'CTRL','RESET_CHAIN',"4,3,2,1","4",undef,undef);
		my $h=gen_button_message ("The JTAG remote reset/enable is connected to the Jtag tab chain with the largest chain number in each tile.  ","icons/help.png");
		my $b= def_pack_hbox(FALSE,0,(gen_label_in_center  ("CPU(s) Chain:"),$w,$h));
		$table->attach ($b ,  $col, $col+1,$row,$row+1,'shrink','shrink',2,2); $col+=1;
	
	}else{	
		$table->attach (gen_label_in_center  ("CPU(s)") ,  $col, $col+1,$row,$row+1,'shrink','shrink',2,2); $col+=1;
	}
	
	$table->attach ($reset ,  $col, $col+1,$row,$row+1,'shrink','shrink',2,2); $col+=1;
	$table->attach ($enable ,  $col, $col+1,$row,$row+1,'shrink','shrink',2,2); $row++;
	
	$enable -> signal_connect("clicked" => sub{ 
			my $en_state=$self->object_get_attribute("CTRL","enable");			
			my $new = ($en_state eq 'Enabled')? 'Disabled' : 'Enabled';
			jtag_enable_cpus_func($self,$new,$tview);
			$self->object_add_attribute("CTRL","enable",$new);	
			set_gui_status($self,"ref",1);		
	});	
	
	$reset -> signal_connect("clicked" => sub{ 
			jtag_reset_cpus_func($self,$tview);		
	});	
	
	
	my $scrolled_win=gen_scr_win_with_adjst ($self,"receive_box");
	add_widget_to_scrolled_win($table,$scrolled_win);
	return $scrolled_win;		
}








sub soure_probe_widgets_old {
	my $self=shift;
	my $table= def_table(2,10,FALSE);	
	my $scrolled_win=gen_scr_win_with_adjst ($self,"receive_box");
	add_widget_to_scrolled_win($table,$scrolled_win);
	my $num = $self->object_get_attribute('CTRL','SP_NUM');
	
	my $y= 0;
   	my $x= 0; 	
	
	$table->attach (gen_label_in_center(" Source "), 0, 3 , $y, $y+1,'shrink','shrink',2,2); 
	$table->attach (gen_label_in_center(" Probe  "), 4, 7 , $y, $y+1,'shrink','shrink',2,2); 
	$y++;
	$table->attach ( gen_Hsep(), 0, 7 , $y, $y+1, 'fill','shrink',2,2); 
	
	$y++;
	my @sources;
	for (my $i=0; $i<$num; $i+=1){	
			my $n=$i+1;
			$table->attach (gen_label_in_left("  $n- "), $x, $x+1 , $y, $y+1,'shrink','shrink',2,2); $x++;
			my $entry=gen_entry( );
			$table->attach ($entry, $x, $x+1 , $y, $y+1,'shrink','shrink',2,2); $x++;			
  			
    		my $enter=def_image_button("icons/write.png","Write");   		

	        $table->attach ($enter, $x, $x+1 , $y, $y+1,'shrink','shrink',2,2); $x++;
	       
	        $x++; #sep
	       
	        #probe 
	        #$table->attach (gen_label_in_left(" Probe:  " )	, $x, $x+1 , $y, $y+1,'shrink','shrink',2,2); $x++; 
	        my $probe_val = $self-> object_get_attribute('SP','PROBE_$n');
	      
	        my $probe_label= gen_label_in_left(" "); 
	        
	        ${probe_val}=25 if ($n ==1);
	        
	        $probe_label->set_markup("<span  foreground= 'red' ><b>XXXX</b></span>") if(!defined $probe_val );	
	        $probe_label->set_markup("<span  foreground= 'blue' ><b></b>    ${probe_val}   </span>") unless(!defined $probe_val );	
	        
	        my $frame = gen_frame();
			$frame->set_shadow_type ('in');
			# Animation
			$frame->add ($probe_label);
	        
	        
	        $table->attach ($frame, $x, $x+1 , $y, $y+1,'shrink','shrink',2,2); $x++; 
	        my $read=def_image_button("icons/simulator.png","Read"); 
	        $table->attach ($read, $x, $x+1 , $y, $y+1,'shrink','shrink',2,2); $x++;
	        
	        $y++; $x=0; 
	        $table->attach (gen_Hsep(), 0, 7 , $y, $y+1, 'fill','shrink',2,2); 
	        $y++;	     
	        
	}	
	
	  $table->attach ( gen_Vsep(), 3, 4 , 0, $y+1,'fill','fill',2,2);
	  $table->attach ( gen_Vsep(), 6, 7 , 0, $y+1,'fill','fill',2,2);
	
	return ($scrolled_win,\@sources);
}

sub read_mem_specefic_addr{
	my ($self,$addr,$tview)=@_;
	add_info($tview,"Read addr: $addr\n"); 	
	my $intfc = get_jtag_intfc_cmd($self);
	$addr=($addr>>2);
	$addr=sprintf("%x",$addr);
	my $cmd =	"$intfc -d  I:${\JTAG_UPDATE_WB_RD_DATA},R:32:$addr,I:0\"";
	add_info($tview,"$cmd\n");	
	my $results =run_cmd_textview_errors($cmd,$tview);
	return 1 if(!defined $results);	
	my ($hex)= sscanf("###read data#0x%s###read data#", $results);
	###read data#0x18000000###read data#
	#add_info($tview," $results \n"); 	
	#add_info($tview," $hex \n"); 	
	return $hex;
}


sub write_mem_specefic_addr {
	my ($self,$addr,$value,$tview)=@_;
	my $intfc = get_jtag_intfc_cmd($self);
	$addr=($addr>>2);
	$addr=sprintf("%x",$addr);
	my $cmd =	"$intfc -d  I:${\JTAG_UPDATE_WB_ADDR},D:32:$addr,I:${\JTAG_UPDATE_WB_WR_DATA},D:32:$value,I:0\"";
	add_info($tview,"$cmd\n");	
	my $results =run_cmd_textview_errors($cmd,$tview);
	return 1 if(!defined $results);
}	

sub soure_probe_widgets {
	my ($self,$tview)=@_;
	my $table= def_table(2,10,FALSE);	
	my $scrolled_win=gen_scr_win_with_adjst ($self,"receive_box");
	add_widget_to_scrolled_win($table,$scrolled_win);
	my $num = $self->object_get_attribute('CTRL','SP_NUM');
	$num = 1 if (!defined $num);
	my $y= 0;
   	my $x= 0; 	
	
	


	
	$table->attach (gen_label_in_center(" Address (in byte)"), 0, 1 , $y, $y+1,'shrink','shrink',2,2); 
	$table->attach (gen_label_in_center(" Memory Content  "), 2, 3 , $y, $y+1,'shrink','shrink',2,2); 
	$table->attach (gen_label_in_center(" Action "), 4, 6 , $y, $y+1,'shrink','shrink',2,2); 
	$y++;
	
	$table->attach ( gen_Hsep(), 0, 6 , $y, $y+1, 'fill','shrink',2,2); 
	
	$y++;
	$x= 0; 	
	
	for (my $i=0; $i<$num; $i+=1){	
			my $n=$i+1;
			my $status=0;
			#$table->attach (gen_label_in_left("  $n-address "), $x, $x+1 , $y, $y+1,'shrink','shrink',2,2); $x++;
		#	($y,$x,$addr)=add_param_widget  ($self,"$n-", "$n-address", 0, "Spin-button", "0,99999999,1", undef, $table,$y,$x,1, "JTAG_WB", undef, undef, 'horizontal');
		   # ($y,$x,$entry)=add_param_widget  ($self,undef, "$n-value", 0, "Entry", undef, undef, $table,$y,$x,1, "JTAG_WB", undef, undef, 'horizontal');
		    
		    my $addr = gen_entry(0);
		    my $entry =gen_entry('xxxxxxxx');	   
		    my $read=def_image_button($path."icons/simulator.png","Read"); 
		    my $write=def_image_button($path."icons/write.png","Write"); 		    
		   
		    
		    $entry->set_max_length (8);
			$entry->set_width_chars(8);
			
			$table->attach ($addr, $x, $x+1 , $y, $y+1,'shrink','shrink',2,2); $x+=2;	
		    $table->attach ($entry, $x, $x+1 , $y, $y+1,'shrink','shrink',2,2); $x+=2;		  
	        $table->attach ($read, $x, $x+1 , $y, $y+1,'shrink','shrink',2,2);  $x++; 		   
			$table->attach ($write, $x, $x+1 , $y, $y+1,'shrink','shrink',2,2); $x++;
			my $sy= $y;
			my $sx=7; 
			        
	        $y++; $x=0; 
	        $table->attach ( gen_Hsep(), 0, $sx , $y, $y+1, 'fill','shrink',2,2); 
	        $y++;
	        
	      
	        
	        $read-> signal_connect("clicked" => sub{
	        	my $address=$addr->get_text();
	        	my $format =$self->	object_get_attribute('FILE_VIEW','R_ADDR_FORMAT');
				$format= 'Decimal' if (!defined $format);
	        	$address = hex($address) unless($format eq 'Decimal');	        	
	        	my $load= show_gif("icons/load.gif");
				$table->attach ($load,$sx, $sx+1 , $sy, $sy+1,'shrink','shrink',0,0);
				$table->show_all();
	        	my $val =read_mem_specefic_addr($self,$address,$tview);
	        	$entry->set_text($val) if (defined $val);
	        	$status =1;
	        	entry_set_text_color($entry,-1);
	        	$load->destroy;
	        });
	        
	        $write-> signal_connect("clicked" => sub{
	        	my $value = $entry->get_text();
	        	my $address=$addr->get_text();
	        	my $format =$self->	object_get_attribute('FILE_VIEW','R_ADDR_FORMAT');
				$format= 'Decimal' if (!defined $format);
	        	$address = hex($address) unless($format eq 'Decimal');
	        	my $load= show_gif("icons/load.gif");
				$table->attach ($load,$sx, $sx+1 , $sy, $sy+1,'shrink','shrink',0,0);
				$table->show_all();
	        	write_mem_specefic_addr($self,$address,$value,$tview);
	        	$status =1;
	        	entry_set_text_color($entry,-1);
	        	$load->destroy;
	        	
	        });
	        
	        $entry->signal_connect("changed" => sub{
				if($status==0 || $status==1 ){
					$status =2;#modified
					#change color to red
					entry_set_text_color($entry,11);
					
				}
				my $in = $entry->get_text();
				$entry->set_text(remove_not_hex($in));
				
			});	
			
			
			$addr->signal_connect("changed" => sub{
				my $format =$self->	object_get_attribute('FILE_VIEW','R_ADDR_FORMAT');
				$format= 'Decimal' if (!defined $format);
				my $in = $addr->get_text();
				$addr->set_text(remove_not_hex($in)) if ($format ne 'Decimal' );
				$addr->set_text(remove_not_number($in)) if ($format eq 'Decimal' );
			});	
	        
	}	
	
	$table->attach ( gen_Vsep(), 1, 2 , 0, $y+1,'fill','fill',2,2);
	$table->attach ( gen_Vsep(), 3, 4 , 0, $y+1,'fill','fill',2,2);
	$table->attach ( gen_Vsep(), 6, 7 , 0, $y+1,'fill','fill',2,2);
		
	return $scrolled_win;
}

sub get_file_b_setting{
	my($self)=@_;
	my $window = def_popwin_size (30,30,'Source Probe','percent');
    my $table= def_table(2,10,FALSE);	
    my @info = (
	#{ label=>" Address format: ", param_name=>'R_ADDR_FORMAT', type=>"Combo-box", default_val=>'Decimal', content=>"Decimal,Hexadecimal", info=>undef, param_parent=>'FILE_VIEW', ref_delay=> 1, new_status=>'ref_file_view', loc=>'vertical'},
	{ label=>" Page row number: ", param_name=>'PAGE_MAX_X', type=>"Spin-button", default_val=>10, content=>"0,128,1", info=>undef, param_parent=>'FILE_VIEW', ref_delay=> 1, new_status=>'ref_file_view', loc=>'vertical'},
	{ label=>" Page column number:", param_name=>'PAGE_MAX_Y', type=>"Spin-button", default_val=>10, content=>"1,128,1", info=>undef, param_parent=>'FILE_VIEW', ref_delay=> 1, new_status=>'ref_file_view', loc=>'vertical'}
	);	
	my $row=0;
	my $col=0;
	foreach my $d (@info) {
		($row,$col)=add_param_widget  ($self, $d->{label}, $d->{param_name}, $d->{default_val}, $d->{type}, $d->{content}, $d->{info}, $table,$row,$col,1, $d->{param_parent}, $d->{ref_delay}, $d->{new_status}, $d->{loc});
	}
	$table->attach (gen_label_in_center(' '), 2, 3,$row,$row+1,'shrink','shrink',2,2); $row++; 
	$table->attach (gen_label_in_center(' '), 2, 3,$row,$row+1,'shrink','shrink',2,2); $row++; 
	$table->attach (gen_label_in_center(' '), 2, 3,$row,$row+1,'shrink','shrink',2,2); $row++; 
	
	
	my $ok=def_image_button($path."icons/select.png",'OK');
	$table->attach ($ok, 2, 3,$row,$row+1,'shrink','shrink',2,2); 
	$ok-> signal_connect("clicked" => sub{
		$window->destroy(); 
	});
	
	$window->add(add_widget_to_scrolled_win($table));	
	$window->show_all;

}

sub fill_memory_array_from_file{
	my  ($self,$fname,$tview)=@_;
	
	my $offset = $self->object_get_attribute('FILE_VIEW','IN_FILE_OFFSET');
	my $BLOCK_SIZE =4;
	
	open(F,"<$fname") or die("Unable to open file $fname, $!");
	binmode(F);
	my $buf;
	my $ct=($offset>>2);

	my $start = ($offset>>2);
	my $r=read(F,$buf,$BLOCK_SIZE);
	while($r){
		my $v='';
		foreach(split(//, $buf)){
			$v.=sprintf("%02x",ord($_));			
		}
		if($r!=4){
			$v.='0'x(( 4 - $r)*2);
		}
		$memory{$ct}= $v;
	    $status{$ct}=2;
		$ct++;
		$r=read(F,$buf,$BLOCK_SIZE);
	}
	close(F);
	
	add_info($tview,"Load $fname\n"); 
	$ct=($ct << 2);
	add_info($tview,"address $offset to $ct\n"); 
}

sub get_file_in_name{
	my ($self,$tview)=@_;
	
	my $file;
	my $title ='select bin file';
	my $dialog = gen_file_dialog ($title);
		
	if ( "ok" eq $dialog->run ) {
	    	$file = $dialog->get_filename;
			$dialog->destroy;
			$self->object_add_attribute('FILE_VIEW','IN_FILE',$file);
				
			#get offset address;
			my $window = def_popwin_size (30,20,'Get Offset Address','percent');
			my $table= def_table(2,10,FALSE);	
			my $d=
			{ label=>" Offset address (in byte): ", param_name=>'IN_FILE_OFFSET', type=>"Spin-button", default_val=>0, content=>'0,9999999999,1', info=>'The Wishbone bus offset address where the beginning of the memory bin file is written there (It can be the base address of the peripheral device where the memory file is intended to be written to.)   ', param_parent=>'FILE_VIEW', ref_delay=> undef, new_status=>undef, loc=>'vertical'};
			my $row=0;
			my $col=0;
			($row,$col)=add_param_widget  ($self, $d->{label}, $d->{param_name}, $d->{default_val}, $d->{type}, $d->{content}, $d->{info}, $table,$row,$col,1, $d->{param_parent}, $d->{ref_delay}, $d->{new_status}, $d->{loc});
			my $ok=def_image_button($path."icons/select.png",'OK');
			$table->attach ($ok, 2, 3,$row,$row+1,'shrink','shrink',2,2); 
			$ok-> signal_connect("clicked" => sub{
				fill_memory_array_from_file ($self,$file,$tview);
				set_gui_status($self,'ref_file_view',1);
				$window->destroy(); 
			});
			$window->add(add_widget_to_scrolled_win($table));	
			$window->show_all;
			
			
	} 
	
	
	
}




sub get_jtag_intfc_cmd {
	my $self=shift;
	
	my $vendor = $self->object_get_attribute('CTRL','VENDOR');
	my $board  = $self->object_get_attribute('CTRL','Board_Name');
	my $chain  = $self->object_get_attribute('CTRL','JTAG_CHAIN');
	my $index  = $self->object_get_attribute('CTRL','JTAG_INDEX');
	my $pronoc = get_project_dir();
	my $intfc = "$pronoc/mpsoc/boards/$vendor/$board/jtag_intfc.sh";
	#my $script  = "$ENV{'PRONOC_WORK'}/tmp/script.bash";
	
	my $t = ($vendor eq 'Xilinx') ? "-t  $chain " : "";
	
	my $cmd = "bash -c \"source $intfc; \\\$JTAG_INTFC $t -n $index";
	return $cmd;
	
}


sub read_memory_array_from_device {
	my ($self,$tview)=@_;
	my $lower  = $self->object_get_attribute('FILE_VIEW','READ_LBA');
	my $upper  = $self->object_get_attribute('FILE_VIEW','READ_UBA');
		
	$lower= sprintf("0x%x",$lower);
	$upper= sprintf("0x%x",$upper); 
		
	my $intfc = get_jtag_intfc_cmd($self);
	#my $comand = "#!/bin/bash\n  source $intfc\n \$JTAG_INTFC $t -n $index -s \"$lower\" -e \"$upper\" -r";
	my $cmd = "$intfc -s $lower -e $upper -r\"";
	
	#save_file ($script,$comand);
	#chmod 0755, $script;
		
	#my $cmd = "bash -c \"  $script \"";	
	add_info($tview,"$cmd\n");	
	my $results =run_cmd_textview_errors($cmd,$tview);
	return 1 if(!defined $results);	
	
	
			
	my @nn = split (/###read data#\n/,$results);	
	if(!defined $nn[1]){
		add_colored_info($tview,"Got an Error:$results!\n",'red');
		return 1;
	}
	my @nums=split (/\n/,$nn[1]);
	
	$lower  = $self->object_get_attribute('FILE_VIEW','READ_LBA');
	$lower>>=2; #change to word
	foreach my $n ( @nums) {
		$n='0'x( 8 - length $n).$n;
		$memory{$lower }= $n;
	    $status{$lower}=1; #valid
	    $lower++;
			
	}	 
}	 


sub print_32_bit_val {
	my ($file,$v)=@_;
	for (my $i= 24; $i >=0 ; $i-=8) {
		my $byte= ($v >> $i ) & 0xFF;
		print $file pack('C*',$byte);
		#printf ("%02x\t",$byte);
	}
}


sub write_memory_array_from_device {
	my ($self,$tview)=@_;
	my $lower  = $self->object_get_attribute('FILE_VIEW','READ_LBA');
	my $upper  = $self->object_get_attribute('FILE_VIEW','READ_UBA');
	
	my $tmp_bin= "$ENV{'PRONOC_WORK'}/tmp/tmp.bin";
	
		
	#create binfile
	unlink $tmp_bin;
	open(my $F,">$tmp_bin") or die("Unable to open file $tmp_bin, $!");
	#binmode($F);
	my $warning;
	my $n;
	for (my $i=($lower>>2); $i< ($upper>>2); $i++){
		 my $s =(defined $status{$i}) ? $status{$i} : 0; 
		 if( $s==0) {
		 	$n= 0;
		 	$warning=$i;
		 }
		 else{
		 	$n= $memory{$i};
		 	$status{$i}=1;	
		}
		print_32_bit_val ($F, hex($n));
	}
	close ($F);
	
	
	

	$lower= sprintf("0x%x",$lower);
	$upper= sprintf("0x%x",$upper); 
		
	
	#my $comand = "#!/bin/bash\n  source $intfc\n \$JTAG_INTFC $t -n $index -s \"$lower\" -e \"$upper\"  -i  $tmp_bin -c";
	
	#save_file ($script,$comand);
	#chmod 0755, $script;
		
	#my $cmd = "bash -c \"  $script \"";
	my $intfc = get_jtag_intfc_cmd($self);
	my $cmd = "$intfc -s $lower -e $upper  -i  $tmp_bin -c\"";
		
	add_info($tview,"$cmd\n");	
	my $results =run_cmd_textview_errors($cmd,$tview);
	return 1 if(!defined $results);	
	
	my @lines = split (/\n/, $results);
	foreach my $line (@lines) {
		add_colored_info($tview,"$line\n",'red') if	 ($line =~ /Error/);
	}	 
}	 







	

sub read_write_widget {
	my ($self,$tview,$rw)=@_;
	#get start & end addresses;
	my $window = def_popwin_size (30,20,'Select Memory Boundary Addresses','percent');
	my $table= def_table(2,10,FALSE);	
	my $l ={ label=>" Lower-bound address (in byte): ", param_name=>'READ_LBA', type=>"Spin-button", default_val=>0, content=>'0,9999999999,1', info=>'The Wishbone bus offset address where the beginning of the memory bin file is written there (It can be the base address of the peripheral device where the memory file is intended to be written to.)   ', param_parent=>'FILE_VIEW', ref_delay=> undef, new_status=>undef, loc=>'vertical'};
	my $u ={ label=>" Upper-bound address (in byte): ", param_name=>'READ_UBA', type=>"Spin-button", default_val=>0, content=>'0,9999999999,1', info=>'The Wishbone bus offset address where the end of the memory bin file is written there (It can be the base address of the peripheral device where the memory file is intended to be written to plus bin file size in byte.)   ', param_parent=>'FILE_VIEW', ref_delay=> undef, new_status=>undef, loc=>'vertical'};
	my ($l_spin,$u_spin);
	my $row=0;
	my $col=0;
	($row,$col,$l_spin)=add_param_widget  ($self, $l->{label}, $l->{param_name}, $l->{default_val}, $l->{type}, $l->{content}, $l->{info}, $table,$row,$col,1, $l->{param_parent}, $l->{ref_delay}, $l->{new_status}, $l->{loc});
	($row,$col,$u_spin)=add_param_widget  ($self, $u->{label}, $u->{param_name}, $u->{default_val}, $u->{type}, $u->{content}, $u->{info}, $table,$row,$col,1, $u->{param_parent}, $u->{ref_delay}, $l->{new_status}, $u->{loc});
	
	$l_spin-> signal_connect("value_changed" => sub{
		my $lower=$l_spin->get_value();
		$u_spin->set_range ($lower, 9999999999);
		
	});
	
	$u_spin-> signal_connect("value_changed" => sub{
		my $upper=$u_spin->get_value();
		$l_spin->set_range (0,$upper);
		
	});		
	
	
	
	
	my $ok=def_image_button($path."icons/select.png",'OK');
	$table->attach ($ok, 2, 3,$row,$row+1,'shrink','shrink',2,2); 
	$ok-> signal_connect("clicked" => sub{
		my $vendor= $self->object_get_attribute('CTRL','VENDOR');
		my $load= show_gif("icons/load.gif");
		$table->attach ($load,1, 2, $row,$row+ 1,'shrink','shrink',0,0);
		$table->show_all();
		read_memory_array_from_device ($self,$tview)  if ($rw eq 'READ');	
		write_memory_array_from_device ($self,$tview) if ($rw eq 'WRITE');	
		set_gui_status($self,'ref_file_view',1);
		$window->destroy(); 
	});
	$window->add(add_widget_to_scrolled_win($table));	
	$window->show_all;	
}	







sub read_write_bin_file {
	my ($self,$tview)=@_;
	my $table= def_table(2,10,FALSE);	
	my $scrolled_win=gen_scr_win_with_adjst ($self,"receive_box");
	add_widget_to_scrolled_win($table,$scrolled_win);
	my @data;
	
	
	my $MAX_X=$self->	object_get_attribute('FILE_VIEW','PAGE_MAX_X');
	$MAX_X=10 if (!defined $MAX_X);
	my $MAX_Y=$self->	object_get_attribute('FILE_VIEW','PAGE_MAX_Y');
	$MAX_Y=10 if (!defined $MAX_Y);
	my $format =$self->	object_get_attribute('FILE_VIEW','R_ADDR_FORMAT');
	$format= 'Decimal' if (!defined $format);
	
	
	my $OFFSET=0;
	
	my $table1= def_table(2,10,FALSE);
	
	#$page_num= 0 if(!defined $page_num);

	
	
	
	my $setting=def_image_button("icons/setting.png","setting");
	my $load=def_image_button("icons/download.png","Load File");
	my $read=def_image_button($path."icons/simulator.png","Read Memory");		
	my $write=def_image_button($path."icons/write.png","Write Memory");   
	my $clear=def_image_button($path."icons/clear.png");  
	my $x=0;
	
	
	$table->attach ($setting, $x, $x+1, 0, 1,'fill','fill',2,2);$x++; 
	$table->attach ($load, $x, $x+1 , 0, 1,'fill','fill',2,2);$x++; 
	$table->attach ($read, $x, $x+1 , 0, 1,'shrink','shrink',2,2); $x++; 
	$table->attach ($write, $x, $x+1 , 0, 1,'shrink','shrink',2,2); $x++;
	$table->attach ($clear, $x, $x+1 , 0, 1,'shrink','shrink',2,2); $x++;
	
	add_param_widget  ($self,"Page_num", 'FILE_VIEW',  0, "Spin-button", "0,999999,1", undef, $table,0, $x, 1, "R_PAGE_NUM",1,'ref_file_view');
	
	my $page_num =$self->object_get_attribute("R_PAGE_NUM",'FILE_VIEW'); 
	
	
	
	
	$setting-> signal_connect("clicked" => sub{
				get_file_b_setting($self);
	}); 	
	
	$load-> signal_connect("clicked" => sub{
				get_file_in_name($self,$tview);
	}); 	
	
	$clear-> signal_connect("clicked" => sub{
		undef %memory;
		undef %status;
		set_gui_status($self,'ref_file_view',1);
	}); 	
	
	$read-> signal_connect("clicked" => sub{
		read_write_widget($self,$tview,'READ');
	}); 
	
	$write->signal_connect("clicked" => sub{
		read_write_widget($self,$tview,'WRITE');
	}); 
	
	my $base_addr=$page_num*$MAX_X*$MAX_Y+$OFFSET;	
		
	
	#column address labels
	for (my $y=1; $y<=$MAX_Y; $y++){
		my $addr=(($y-1) << 2);
		$addr =($format eq 'Hexadecimal')? sprintf("%x", $addr) : $addr;
		
		my $l=gen_label_in_center (" $addr ");
		$table1->attach ( $l, $y, $y+1 , 0, 1,'fill','fill',2,2);
	}	
	
	
	#row address labels
	for (my $x=1; $x<=$MAX_X; $x++){
		my $addr=$base_addr+($x-1) * $MAX_Y;
		
		$addr = ($format eq 'Hexadecimal')? sprintf("%x",($addr << 2))   : ($addr << 2);
		
		
		my $l=gen_label_in_left (" $addr ");
		$table1->attach ( $l, 0, 1 , $x, $x+1,'fill','fill',2,2);
	}	
	
	#entries	
	for (my $x=1; $x<=$MAX_X; $x++){
		for (my $y=1; $y<=$MAX_Y; $y++){
			
			
			my $state=0;# not modified
			
			my $addr =$base_addr+ (($x-1) * $MAX_Y ) + $y-1;
			my $addr_tip=($format eq 'Hexadecimal')? sprintf("0x%x",($addr << 2))   : ($addr << 2);
			
			my $v= $memory{$addr};
			my $s = $status{$addr};
			
			$v= "xxxxxxxx" if (!defined $v);
			$s = 0 if (!defined $s); #0 dontcare			
			
						
			my $entry =gen_entry($v );
			
			$entry->set_max_length (8);
			$entry->set_width_chars(8);
			set_tip($entry,"$addr_tip");
			$table1->attach ( $entry, $y, $y+1 , $x, $x+1,'fill','fill',2,2);
			
			if($s==2 ){
				#change color to red
				entry_set_text_color($entry,11);
			}
			
			$entry->signal_connect("changed" => sub{
				if($s==0 || $s==1 ){
					$status{$addr} =2;#modified
					#change color to red
					entry_set_text_color($entry,11);
					
				}
				my $in = $entry->get_text();
				$memory{$addr}=$in;
				$entry->set_text(remove_not_hex($in));
				
			});	
		
		}
	}
 		  
  		  
     
	
	$table->attach ( $table1, 0, 20 , 1, 10,'fill','fill',2,2);
	
	$scrolled_win->show_all;
	return $scrolled_win;
	
}



############
#	main
############



sub source_probe_main {
	my $self = __PACKAGE__->new(); 
	
	
	
	set_gui_status($self,"ideal",0);
	my $window = def_popwin_size (85,85,'Run time JTAG debug','percent');
	my ($sw,$tview) =create_txview();# a textveiw for showing the info, erro messages etc
	my $ctrl = source_probe_ctrl($self,$tview);
	my $sp= soure_probe_widgets ($self,$tview);
	my $bin_f = read_write_bin_file($self,$tview);
	#my $bin_ctrl = file_bin_ctrl($self,$tview);
	
	
	my $h1 = gen_hpaned ($sp,0.35,$ctrl);
	#my $h2 = gen_hpaned ($bin_f,0.55,$bin_ctrl);
	my $v1 = gen_vpaned ($h1,0.2,$bin_f);
	my $v2 = gen_vpaned ($v1,0.65,$sw);
	
	
	
	
		
	#check soc status every ? second. referesh device table if there is any changes 
    Glib::Timeout->add (100, sub{ 
        my ($state,$timeout)= get_gui_status($self);
        
        if ($timeout>0){
            $timeout--;
            set_gui_status($self,$state,$timeout);           
        }
        elsif( $state ne "ideal" ){        	
            if($state eq 'ref_all') {
            	$sp->destroy();
            	$sp= soure_probe_widgets ($self,$tview);
            	$bin_f->destroy(); 
            	$bin_f = read_write_bin_file($self,$tview);
            	$h1-> pack1($sp, TRUE, TRUE);
            	$v1-> pack2($bin_f, TRUE, TRUE);
            	$v2-> show_all(); 
            }
            elsif ($state eq  'ref_file_view'){
            	$bin_f->destroy(); 
            	$bin_f = read_write_bin_file($self,$tview);
            	$v1-> pack2($bin_f, TRUE, TRUE);
            	$v2-> show_all(); 
            	
            	
            } 	  
            
            $ctrl->destroy();
            $ctrl = source_probe_ctrl($self,$tview);
            $h1-> pack2($ctrl, TRUE, TRUE);
            $v2-> show_all(); 
            set_gui_status($self,"ideal",0);         
               
            
       }
             
    	return TRUE;
        
    } );
	
	
	
	$window->add($v2);
	$window->show_all();
	return $window;	
}	



