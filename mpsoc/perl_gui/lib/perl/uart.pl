#!/usr/bin/perl -w

use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;

require "widget.pl";


use constant::boolean;


use Data::Dumper;
use File::Which;
use File::Basename;

use IPC::Run qw( harness start pump finish timeout );
use String::Scanf; # imports sscanf()
use base 'Class::Accessor::Fast';


use Consts;
BEGIN {
    my $module = (Consts::GTK_VERSION==2) ? 'Gtk2' : 'Gtk3';
    my $file = $module;
    $file =~ s[::][/]g;
    $file .= '.pm';
    require $file;
    $module->import;
}



__PACKAGE__->mk_accessors(qw{
	window
	sourceview		
});

my $NAME = 'Uart Terminal';
my 	$path = "";
our $FONT_SIZE='default';
our $ICON_SIZE='default';



sub uart_stand_alone(){
	$path = "../../";
	set_path_env();
	my $project_dir	  = get_project_dir(); #mpsoc dir addr
	my $paths_file= "$project_dir/mpsoc/perl_gui/lib/Paths";
	if (-f 	$paths_file){#} && defined $ENV{PRONOC_WORK} ) {
		my $paths= do $paths_file;
		my %p=%{$paths};
		$FONT_SIZE= $p{'GUI_SETTING'}{'FONT_SIZE'} if (defined $p{'GUI_SETTING'}{'FONT_SIZE'});
		$ICON_SIZE= $p{'GUI_SETTING'}{'ICON_SIZE'} if (defined $p{'GUI_SETTING'}{'ICON_SIZE'});
	}
	
	set_defualt_font_size();
	my $window=uart_main();
	$window->signal_connect (destroy => sub { gui_quite();});	
}

exit gtk_gui_run(\&uart_stand_alone) unless caller;




sub create_rsv_box {
	my ($self,$num)=@_;
	my ($sw,$tview) =create_txview(); 
    $sw->set_policy('never','automatic');
    $sw->set_border_width(3);
    my($width,$hight)=max_win_size();
	$sw->set_size_request($width/10,$hight/10);
    my $frame = gen_frame();
	$frame->set_shadow_type ('in');
	$frame->add ($sw);
	my $def = 126-$num;
	my $spin=gen_spin_object($self,'CTRL',"INDEX_$num",'0,128,1',$def,undef,undef);	
	my $label=gen_label_in_center("INDEX#");
	my $box=def_pack_hbox( FALSE, 0 , $label,$spin);	
	$frame->set_label_widget ($box);        
    return ($frame,$tview);	
}



sub receive_boxes{
	my $self=shift;
	my $table= def_table(2,10,FALSE);	
	my $scrolled_win=gen_scr_win_with_adjst ($self,"receive_box");
	add_widget_to_scrolled_win($table,$scrolled_win);
	my $num = $self->object_get_attribute('CTRL','UART_NUM');
	my $dim_y = floor(sqrt($num));
	my @tviews;
	for (my $i=0; $i<$num; $i+=1){	
			my ($box,$tview) = create_rsv_box($self,$i);
			$tviews[$i]=$tview;  			
  			my $y= int($i/$dim_y);
    		my $x= $i % $dim_y;    		
	        $table->attach_defaults ($box, $x, $x+1 , $y, $y+1);	
	}	
	return ($scrolled_win,\@tviews);
}

sub ctrl_boxes{
	my ($self,$main_tview)=@_;
	
	my $state=$self->object_get_attribute("CTRL","RUN");
	if (!defined $state){
		$state='OFF' ;
		$self->object_add_attribute("CTRL","RUN",$state);
	}		
	
	
	my $table= def_table(2,10,FALSE);	
	my $scrolled_win=add_widget_to_scrolled_win ($table);
	my ($row,$col)=(0,0);
	my @info = (
	#TODO add Altera_Qsys_UART
		{ label=>" UART name ", param_name=>'UART_NAME', type=>"Combo-box", default_val=>'ProNoC_XILINX_UART', content=>"ProNoC_XILINX_UART,ProNoC_ALTERA_UART", info=>undef, param_parent=>'CTRL', ref_delay=> 1, new_status=>'ref_ctrl', loc=>'vertical'},
		{ label=>" Number of UART", param_name=>'UART_NUM', type=>"Spin-button", default_val=>1, content=>"1,128,1", info=>undef, param_parent=>'CTRL', ref_delay=> 1, new_status=>'ref_all', loc=>'vertical'}		
		
	);	
	
	
	my $uname= $self->object_get_attribute('CTRL','UART_NAME');
	$uname = 'ProNoC_XILINX_UART' if(!defined $uname);
	if ($uname eq "ProNoC_XILINX_UART" ) {
		push (@info,{ label=>" JTAG CHAIN ", param_name=>'JTAG_CHAIN', type=>"Combo-box", default_val=>3, content=>"1,2,3,4", info=>undef, param_parent=>'CTRL', ref_delay=> 1, new_status=>'ref_ctrl', loc=>'vertical'}) ;
		push (@info,{ label=>" JTAG TARGET ", param_name=>'JTAG_TARGET', type=>"Spin-button", default_val=>3, content=>"1,128,1", info=>"The FPGA device target number in the Jtag chain. Click on the front magnifier Icon to see the list of devices in your board JTAG chain.", param_parent=>'CTRL', ref_delay=> 1, new_status=>'ref_ctrl', loc=>'vertical'}) ;
	}elsif ($uname eq "ProNoC_ALTERA_UART" ) {
		my $list= $self->object_get_attribute('CTRL','quartus_device_list');
		push (@info,{ label=>" Hardware Name", param_name=>'quartus_hardware', type=>"Entry", default_val=>undef, content=>undef, info=>undef, param_parent=>'CTRL', ref_delay=> 1, new_status=>undef, loc=>'vertical'}) ;
		push (@info,{ label=>" Device Number",   param_name=>'quartus_device',   type=>"EntryCombo", default_val=>undef,  content=>$list, info=>undef,param_parent=>'CTRL', ref_delay=> 1, new_status=>undef, loc=>'vertical'}) ;
	}
	
	
	my @restricted_params= ('UART_NAME','JTAG_TARGET','quartus_hardware','quartus_device');
	
	foreach my $d (@info) {
		my $wiget;		
		($row,$col,$wiget)=add_param_widget  ($self, $d->{label}, $d->{param_name}, $d->{default_val}, $d->{type}, $d->{content}, $d->{info}, $table,$row,$col,1, $d->{param_parent}, $d->{ref_delay}, $d->{new_status}, $d->{loc});
		
		#the following parameter should not be changed while the jtag connection is stablished
		if($state eq "ON"){
			$wiget->set_sensitive (FALSE) if (check_scolar_exist_in_array($d->{param_name},\@restricted_params )); 
		}
		
		
		if($d->{param_name} eq 'JTAG_TARGET' || $d->{param_name} eq "quartus_hardware"){
			my $search=def_image_button($path."icons/browse.png");
			$table->attach ($search,  4, 5,$row-1,$row,'shrink','shrink',2,2); 
			set_tip($search, "Display all Jtag targets. You need to connect your FPGA device to your PC first."); 
			$search-> signal_connect("clicked" => sub{
				show_all_xilinx_targets ($self,$main_tview) if($uname eq "ProNoC_XILINX_UART");
				capture_altera_jtag_info($self,$main_tview) if($uname eq "ProNoC_ALTERA_UART");
			}); 			
			
		}
	} 
	
	
	
	$col=0;
	my $label=gen_label_in_left(" JTAG Connect ");
	my $run= ($state eq 'ON')? def_colored_button('ON',17): def_colored_button('OFF',4); 
	$table->attach ($label,  $col, $col+1,$row,$row+1,'fill','shrink',2,2); $col+=1; 
	$table->attach ($run,  $col, $col+1,$row,$row+1,'shrink','shrink',2,2); $row++;$col=0;
	$run -> signal_connect("clicked" => sub{ 
			my $state=$self->object_get_attribute("CTRL","RUN");			
			my $new = ($state eq "ON")? "OFF" : "ON";
			$self->object_add_attribute("CTRL","CONNECT",1) if($new eq 'ON');
			$self->object_add_attribute("CTRL","DISCONNECT",1) if($new eq 'OFF');
			set_gui_status($self,"ON-OFF",1);		
	});		
	
	return $scrolled_win;
}



sub select_uart_board {
	my ($self,$table,$vendor,$row,$col)=@_;
	
	#get the list of boards located in "boards/*" folder
	my @dirs = grep {-d} glob("$path/../boards/$vendor/*");
	my ($fpgas,$init);
	$fpgas="";
	
	foreach my $dir (@dirs) {
		my ($name,$fpath,$suffix) = fileparse("$dir",qr"\..[^.]*$");
		
		$fpgas= (defined $fpgas)? "$fpgas,$name" : "$name";	
		$init="$name";	
	}
	my $button=def_image_button("$path/icons/help.png");
	my $help1= "The list of supported boards are obtained from \"mpsoc/boards/$vendor\" path. You can add your boards by adding its required files in aforementioned path";
	$button->signal_connect("clicked" => sub {message_dialog($help1);});	
	my $combo=gen_combobox_object ($self,'compile','board',$fpgas,$init,undef,undef);	
	$table->attach(gen_label_in_left('Targeted Board:'),$col,$col+1,$row,$row+1,'fill','shrink',2,2);$col++;
	$table->attach($button,$col,$col+1,$row,$row+1,'fill','shrink',2,2);$col++;
	$table->attach($combo, $col,$col+1,$row,$row+1,'fill','shrink',2,2);$row++;
		
	#do not change the board when the connection is ON
	my $state=$self->object_get_attribute("CTRL","RUN");
	$combo->set_sensitive (FALSE) if($state eq "ON" );	
		
	
}



sub capture_altera_jtag_info {
	my ($self,$tview) = @_;
	my $command=  "$ENV{QUARTUS_BIN}/jtagconfig";
	#add_info($tview,"$command\n");
	my $stdout= run_cmd_textview_errors($command,$tview);
	if(!defined $stdout){
		add_colored_info($tview,"No JTAG Hardware is detected\n",'red');
		return 1; 
	}
	#add_info($tview,"$stdout\n");
	my @a=split /1\)\s+/, $stdout; 
	if(!defined $a[1]){
		add_colored_info($tview,"No JTAG Hardware is detected\n",'red');
		return 1;
	}
	my @b=split /\s+/, $a[1]; 
	my $hw=$b[0];
	
	
	
	
	my @devs=split /\n/, $stdout; 
	
	$self->object_add_attribute('CTRL','quartus_hardware',$hw);
	add_colored_info($tview,"Detected Hardware: $hw\n",'blue');
	
	#capture device name in JTAG chain
		
	my $i=0;
	my $info="";
	my $list;
	foreach my $p (@devs){
		next if ($p =~/^\s*1\)/); 
		$i++;
		$info .= "\t $i : $p\n"; 
		$list= (defined $list) ? "$list,$i" : $i;
		
	}
	
	$info = "There are total of $i devices in JTAG chain:\n $info. Select the corresponding Jtag device number which the serial port is connected to\n";
		
	
	my $names = join (',',@devs);
	add_colored_info($tview,"$info",'blue');
	$self->object_add_attribute('CTRL','quartus_device_list',$list);
	$self->object_add_attribute('CTRL','quartus_device',$i);
	set_gui_status($self,'ref_ctrl',1);	   
	return 0;		
}







sub show_all_xilinx_targets{
	my ($self,$tview) =@_;
	my ($pipe,$in, $out, $err,$r);
	my $xsct = which('xsct');	
	
	#check if $xsct exits
	unless(-f $xsct){
		add_colored_info($tview,"Error xsct not found. Please add the path to xilinx/SDK/bin to your \$PATH environment\n",'red');
		return 0;	
	}	
	my @cat = ( $xsct );
	$pipe =start \@cat, \$in, \$out, \$err or $r=$?;
	if(defined $r){
		add_colored_info($tview," quartus_stp got an Error: $r\n",'red');
		return 0;		
	}

    $in = "";
    return 0 unless run_xsct_pipe($self,\$pipe,\$in,\$out,\$err,$tview);
    $in = "set jseq [jtag sequence]\n connect\n";
    return 0 unless run_xsct_pipe($self,\$pipe,\$in,\$out,\$err,$tview);
    $in = "set R [jtag targets]\n puts \$R \n";
    return 0 unless run_xsct_pipe($self,\$pipe,\$in,\$out,\$err,$tview);
    if (length ($out)> 10){
    	add_colored_info($tview,"targets are:\n $out .\n",'blue');    	
    }else {
    	add_colored_info($tview,"No Jtag target is detected. Make sure your FPGA board is connected to the PC and it is powered on.\n",'red');
    } 
	close_xsct($self,\$pipe,$tview,\$in, \$out, \$err);
	return $out;
}



sub sender_box{
	my ($self,$main_tview)=@_;
	my $table= def_table(2,10,FALSE);	
	my $scrolled_win=add_widget_to_scrolled_win ($table);
	my ($sw,$tview) =create_txview(); 
    $sw->set_policy('never','automatic');
    $sw->set_border_width(3);
    my($width,$hight)=max_win_size();
	$sw->set_size_request($width/10,$hight/10);
    my $frame = gen_frame();
	$frame->set_shadow_type ('in');
	$frame->add ($sw);
	my $num = $self->object_get_attribute('CTRL','UART_NUM');
	my @indexs;
	my $def;
	for (my $i=0; $i<$num; $i+=1){	
		my $index= $self->object_get_attribute("CTRL","INDEX_$i");	
		$def= $index if(!defined $def);
		$indexs[$i]=$index;
	}
	my $indexs = join(',',@indexs);
	my $comb=gen_combobox_object($self,'CTRL',"SEND_TO_INDEX",$indexs,$def,undef,undef);	
	my $label=gen_label_in_center("SEND_TO INDEX#");
	my $send = def_image_button($path.'icons/run.png');	
	my $box=def_pack_hbox( FALSE, 0 , $label,$comb,$send);	
	$frame->set_label_widget ($box);   		
	$table->attach_defaults ($frame, 0, 1 , 0,1);
	$send-> signal_connect("clicked" => sub{ 
			my $st =$self->object_get_attribute("CTRL","RUN");
			my $index =$self->object_get_attribute("CTRL","SEND_TO_INDEX");
			if ($st eq 'OFF'){
				add_colored_info($main_tview,"Error: Cannot send the data. Jtag connection is not established yet.\n",'red');
				return;
			}
			my $text_buffer = $tview->get_buffer;
	        my $txt=$text_buffer->get_text($text_buffer->get_bounds, TRUE);
			if(length ($txt) >0 ){	
				my $buf=$self->object_get_attribute("SEND","TXT_$index");
				$txt=	$buf.$txt if(length $buf);		
				$self->object_add_attribute("SEND","TXT_$index",$txt);
				set_gui_status($self,"REF_SEND",1);	   
				
			}			
	});		
	
		
	return ($scrolled_win,$tview);	
}



sub check_jtag_connect {
	my ($self,$pipe,$tview,$in, $out, $err,$pipe_name)=@_;
	my $run =$self->object_get_attribute("CTRL","RUN");
	my $connect = $self->object_get_attribute("CTRL","CONNECT");
	my $disconnect = $self->object_get_attribute("CTRL","DISCONNECT");
	
	
	
	my $r;
	if($connect){
		
       	$r=start_xsct($self,$pipe,$tview,$in, $out, $err) if($pipe_name eq 'xsct' );
       	$r=start_stp ($self,$pipe,$tview,$in, $out, $err) if($pipe_name eq 'stp'  );
       	if($r){
       		$self->object_add_attribute("CTRL","RUN",'ON');
       		add_info($tview,"Connected!\n");
       		set_gui_status($self,"ref",1); 
       		
          		
       	}else{
       		$self->object_add_attribute("CTRL","RUN",'OFF');
       		add_colored_info($tview,"failed to connect!\n",'red');
      		set_gui_status($self,"ref",1); 
      		
       	}            					
		$self->object_add_attribute("CTRL","CONNECT",0);
	}if($disconnect){
		close_xsct($self,$pipe,$tview,$in, $out, $err) if($pipe_name eq 'xsct' );
		close_stp ($self,$pipe,$tview,$in, $out, $err) if($pipe_name eq 'stp'  );
		$self->object_add_attribute("CTRL","RUN",'OFF');
		$self->object_add_attribute("CTRL","DISCONNECT",0);	
		add_info($tview,"disconnected!\n");
		set_gui_status($self,"ref",1); 			
	}	
}	


use constant UART_UPDATE_WB_ADDR => 7;
use constant UART_UPDATE_WB_WR_DATA=>  6;
use constant UART_UPDATE_WB_RD_DATA => 5;	

# Converts pairs of hex digits to asci
sub hex_to_ascii { # $ascii ($hex)
  my $s = shift;
 
  return pack 'H*', $s;
}
	


sub nop{
	#no oprtstion
	return
}
##########
#	Quartus stp
##########


sub run_stp_pipe{
	my ($self,$pipe,$in,$out,$err,$tview)=@_;
	$$out='';	
	$$in .= "puts done\n";
	
	#print $$in;
	
	pump $$pipe while (length $$in);
    until ($$out =~ /done/ || (length $$err)){
    
    	pump $$pipe; 
    	refresh_gui();    	
    }	 
    if(length $$err){
    	add_colored_info($tview,"Got an Error: $$err\n",'red');
    	$self->object_add_attribute("CTRL","DISCONNECT",1);	
    	set_gui_status($self,"ON-OFF",0);	    	
    	return 0;    	
    }
    # stp does not print on stderr. we need to check stdout manually for error 
    my @error_list=("ERROR:","can't read");
    foreach my $err (@error_list) {
    	if( $$out =~ /$err/){
    		add_colored_info($tview,"Got an Error: $$out\n",'red');
    		$self->object_add_attribute("CTRL","DISCONNECT",1);	
    		set_gui_status($self,"ON-OFF",0);	    	
    		return 0;    		
    	}	
    	
    }
     
    refresh_gui();
    #print $$out;
	return 1;	
}

sub start_stp{
	my ($self,$pipe,$tview,$in, $out, $err)=@_;
	
	
	my $stp = which('quartus_stp');	
	
	#check if $xsct exits
	unless(-f $stp){
		add_colored_info($tview,"Error quartus_stp not found. Please add the path to QuartusII/bin to your \$PATH environment\n",'red');
		return 0;	
	}	
	my @run = ( "$stp" );
	my @run_args = ( "-s" );
	
	my $r;
	
	$$pipe =start [@run, @run_args], $in, $out, $err or $r=$?;
	if(defined $r){
		add_colored_info($tview," quartus_stp got an Error: $r\n",'red');
		return 0;		
	}
	
	my $hdw= $self->object_get_attribute('CTRL','quartus_hardware');
	my $dev= $self->object_get_attribute('CTRL','quartus_device');

	$hdw="" if(!defined $hdw);	
	$dev="" if(!defined $dev);
	
	
	if(length ($hdw) ==0){
		add_colored_info($tview,"Error: Cannot initial the quartus_stp. the hardware name is not defined!\n",'red');
		return 0;		
	}
	
	if(length ($dev)==0) {
		add_colored_info($tview,"Error: Cannot initial the quartus_stp. the device number is not defined!\n",'red');		
		return 0;
	}
	
	my $HARDWARE_NAME="$hdw *";
	my $DEVICE_NAME="\@$dev*"; 
		
	
	$$in = " ";	
	
    return 0 unless run_stp_pipe($self,$pipe,$in,$out,$err,$tview);
    $$in = "  foreach name [get_hardware_names] {
   if { [string match \"*${HARDWARE_NAME}*\" \$name] } {
       set hardware_name \$name\n
     }
   }
   puts \"\\nhardware_name is \$hardware_name\"
   foreach name [get_device_names -hardware_name \$hardware_name] {
     if { [string match \"*$DEVICE_NAME*\" \$name] } {
       set chip_name \$name
     }
   }
   puts \"device_name is \$chip_name\\n\";
   open_device -hardware_name \$hardware_name -device_name \$chip_name\n";
   return 0 unless run_stp_pipe($self,$pipe,$in,$out,$err,$tview);
         
    return 1;
}

sub close_stp{
	my ($self,$pipe,$tview,$in, $out, $err)=@_;
	$$in = 
"device_unlock
close_device
exit
";
  	pump $$pipe while (length $$in);
   	finish $$pipe;
}


sub stp_jtag_vir {
	my ($index,$ir)=@_;	
	my $hex = sprintf("%X", $ir);
	my $in = 
"device_lock -timeout 10000
device_virtual_ir_shift -instance_index $index -ir_value $hex -no_captured_ir_value
catch {device_unlock}
";
return $in;	
}


sub stp_jtag_vdr{
	my ($index,$dat,$width)=@_;
	my $digits= $width>>2;	
	my $hex = sprintf("%0${digits}X", $dat);
	my $in=
"device_lock -timeout 10000
set data [device_virtual_dr_shift -dr_value $hex -instance_index $index  -length $width  -value_in_hex]
catch {device_unlock}
puts R:\$data:R
";
	return $in;	
}


sub run_stp_jtag_scaner{
	my ($self,$tview,$tv_ref,$pipe,$in, $out, $err)=@_; 
		
	my $num = $self->object_get_attribute('CTRL','UART_NUM');
		
	
	my @tviews=@{$tv_ref};
	
	for (my $i=0; $i<$num; $i+=1){	
		my $index= $self->object_get_attribute("CTRL","INDEX_$i");	
		next if (!defined $index);
		
		
		
		my $txt= $self->object_get_attribute("SEND","TXT_$index");
		my $send_char =0;
		my $l=length $txt;
		if ($l){
			$send_char = substr $txt, 0,1;
			$send_char = ord($send_char); #convert a character to a number
			$txt =  substr $txt, 1,$l;
			$self->object_add_attribute("SEND","TXT_$index",$txt );
		}
		
			
		
		#select instruction
		$$in=stp_jtag_vir ($index,UART_UPDATE_WB_RD_DATA);	
		return  unless run_stp_pipe($self,$pipe,$in,$out,$err,$tview);
				
		
		#read uart reg 0 
		my $str=stp_jtag_vdr ($index,$send_char,32);	
		$$in=$str;
		nop();
		return  unless run_stp_pipe($self,$pipe,$in,$out,$err,$tview);
		nop();
		my ($tmp,$hex)= sscanf("%sR:%s:R",$$out);
		#print "capture $hex\n";
		my $char= substr($hex, -2);
		#print "char = $char\n";
		if($char ne '00'){	
			$char =hex_to_ascii($char);	
			add_info($tviews[$i],$char) if(defined $tviews[$i]);
		}
	}
}


###############
#	xsct 
##############

use constant UPDATE_INDEX => "01";
use constant UPDATE_IR    => "02";
use constant UPDATE_DAT   => "04";

#USER1 000010 Access user-defined register 1.
#USER2 000011 Access user-defined register 2.
#USER3 100010 Access user-defined register 3.
#USER4 100011 Access user-defined register 4

sub run_xsct_pipe{
	my ($self,$pipe,$in,$out,$err,$tview)=@_;
	$$out='';	
	$$in .= "puts done\n";
	
	pump $$pipe while (length $$in);
    until ($$out =~ /done/ || (length $$err)){
    
    	pump $$pipe; 
    	refresh_gui();    	
    }	 
    if(length $$err){
    	add_colored_info($tview,"Got an Error: $$err\n",'red');
    	$self->object_add_attribute("CTRL","DISCONNECT",1);	
    	set_gui_status($self,"ON-OFF",0);	    	
    	return 0;    	
    }
    refresh_gui();
  
	return 1;	
}


sub start_xsct{
	my ($self,$pipe,$tview,$in, $out, $err)=@_;
	
	
	my $xsct = which('xsct');	
	
	#check if $xsct exits
	unless(-f $xsct){
		add_colored_info($tview,"Error xsct not found. Please add the path to xilinx/SDK/bin to your \$PATH environment\n",'red');
		return 0;	
	}	
	my @cat = ( $xsct );
	my $r;
	
	$$pipe =start \@cat, $in, $out, $err or $r=$?;
	if(defined $r){
		add_colored_info($tview,"XSCT got an Error: $r\n",'red');
		return 0;		
	}
	
	
	my $target= $self->object_get_attribute('CTRL','JTAG_TARGET');
	
	$$in = "";
    return 0 unless run_xsct_pipe($self,$pipe,$in,$out,$err,$tview);
    $$in = "set jseq [jtag sequence]\n connect\n jtag targets $target\n";
    return 0 unless run_xsct_pipe($self,$pipe,$in,$out,$err,$tview);
         
    return 1;
}




sub close_xsct{
	my ($self,$pipe,$tview,$in, $out, $err)=@_;
	$$in = "exit\n";
  	pump $$pipe while (length $$in);
   	finish $$pipe;
}


sub jtag_reorder{
  my ( $string_in ) =@_;
  my @chars =( $string_in =~ m/../g );#split a string into chunks of two characters
  return join("", reverse @chars);  
}



sub xsct_send_to_jtag{
	my ($hex,$width,$chain) =@_;
	my $siz = $width+4;
	#print "$chain\n";
	my $str="\$jseq clear
\$jseq irshift -state IDLE -hex 6 $chain
\$jseq drshift -state IDLE -hex $siz $hex
\$jseq run
";
return $str;
}


sub xsct_send_capture_jtag {
	my ($hex,$width,$chain) =@_;
	my $siz = $width+4;
	my $str="\$jseq clear                                                      
\$jseq irshift -state IDLE -hex 6 $chain                 
\$jseq drshift -state IDLE -capture -hex $siz $hex  
set data [\$jseq run]
puts R:\$data:R
"; 
return $str;	
}


sub xsct_jtag_vdr{
	my ($dat,$width,$chain)=@_;
	my $digits= $width>>2;	
	my $hex = UPDATE_DAT.sprintf("%0${digits}X", $dat);
	$hex=jtag_reorder($hex);	
	return xsct_send_capture_jtag($hex,$width,$chain);
}


sub xsct_jtag_vir {
	my ($ir,$width,$chain)=@_;	
	my $digits= $width>>2;	
	my $hex = UPDATE_IR.sprintf("%0${digits}X", $ir);
	$hex=jtag_reorder($hex);
	return xsct_send_to_jtag($hex,$width,$chain);
}

sub xsct_jtag_vindex {
	my ($index,$width,$chain)=@_;	
	my $digits= $width>>2;	
	my $hex = UPDATE_INDEX.sprintf("%0${digits}X", $index);
	$hex=jtag_reorder($hex);
	return xsct_send_to_jtag($hex,$width,$chain);
}

sub run_xsct_jtag_scaner{
	my ($self,$tview,$tv_ref,$pipe,$in, $out, $err)=@_; 
		
	my $num = $self->object_get_attribute('CTRL','UART_NUM');
	my $chain= $self->object_get_attribute('CTRL','JTAG_CHAIN');
	my $chain_code=
		($chain==1)? '02':
		($chain==2)? '03':
		($chain==3)? '22':
		'23';
	
	my @tviews=@{$tv_ref};
	
	for (my $i=0; $i<$num; $i+=1){	
		my $index= $self->object_get_attribute("CTRL","INDEX_$i");	
		next if (!defined $index);
		my $txt= $self->object_get_attribute("SEND","TXT_$index");
		my $send_char =0;
		my $l=length $txt;
		if ($l){
			$send_char = substr $txt, 0,1;
			$send_char = ord($send_char); #convert a character to a number
			$txt =  substr $txt, 1,$l;
			$self->object_add_attribute("SEND","TXT_$index",$txt );
		}
		
	
		#select index		
		#print"select index\n";
		$$in=xsct_jtag_vindex ($index,32,$chain_code);
		return  unless run_xsct_pipe($self,$pipe,$in,$out,$err,$tview);
			
		
		#select instruction
		#print"select instruction\n";
		$$in=xsct_jtag_vir (UART_UPDATE_WB_RD_DATA,32,$chain_code);	
		return  unless run_xsct_pipe($self,$pipe,$in,$out,$err,$tview);
				
		
		#read uart reg 0 
		#print"read reg 0\n";
		my $str=xsct_jtag_vdr   ($send_char,32,$chain_code);	
		$$in=$str;
		nop();
		return  unless run_xsct_pipe($self,$pipe,$in,$out,$err,$tview);
		nop();
		my ($hex)= sscanf("R:%s:R",$$out);
		my $char= substr $hex, 0, 2;
		if($char ne '00'){	
			$char =hex_to_ascii(substr $hex, 0, 2);	
			add_info($tviews[$i],$char) if(defined $tviews[$i]);
		}
		
		
		
	}
}




############
#	main
############



sub uart_main {
	my $self = __PACKAGE__->new(); 
	set_gui_status($self,"ideal",0);
	my $window = def_popwin_size (85,85,'UART Terminal','percent');
	my ($sw,$tview) =create_txview();# a textveiw for showing the info, erro messages etc
	my $ctrl= ctrl_boxes($self,$tview);
	my ($rsv,$tv_ref) = receive_boxes($self);
	my ($send,$send_tv) =	sender_box($self,$tview);
	 
	my $v1 = gen_vpaned ($ctrl,0.3,$send);	
	my $v2 = gen_vpaned ($v1,0.5,$sw);
	my $h1 = gen_hpaned ($rsv,0.55,$v2);
	
	my ($pipe,$in, $out, $err);
	my $counter=5;
	#check soc status every 0.5 second. referesh device table if there is any changes 
    Glib::Timeout->add (10, sub{ 
        my ($state,$timeout)= get_gui_status($self);
        
        if ($timeout>0){
            $timeout--;
            set_gui_status($self,$state,$timeout);           
        }
        elsif( $state ne "ideal" ){        	
            if($state eq 'ref_all') {
            	 $rsv->destroy();
            	 ($rsv,$tv_ref) = receive_boxes($self);
            	 $h1-> pack1($rsv, TRUE, TRUE);
            }	  
            
            
           
            $ctrl->destroy();
            $send->destroy();
           
            ($send,$send_tv) =	sender_box($self,$tview);
            $ctrl= ctrl_boxes($self,$tview);
           
            $v1-> pack1($ctrl, TRUE, TRUE);
            $v1-> pack2($send, TRUE, TRUE);
            $h1->show_all();
            set_gui_status($self,"ideal",0);     
            if($state eq 'ON-OFF') {  
            	my $uname= $self->object_get_attribute('CTRL','UART_NAME');
            	my $pipe_name = ($uname eq 'ProNoC_XILINX_UART') ? 'xsct' : 'stp';            	
            	check_jtag_connect ($self,\$pipe,$tview,\$in, \$out, \$err,$pipe_name);
            	my $st =$self->object_get_attribute("CTRL","RUN");
            	$counter=5 if ($st eq 'OFF');
            	#print "ON-OFF\n";
            }
           # print "ref\n";
               
            
       }
        my $st =$self->object_get_attribute("CTRL","RUN");
        $counter-- if ($st eq 'ON' && $counter>0);
        if($counter ==0 ){
        	my $uname= $self->object_get_attribute('CTRL','UART_NAME');
			run_xsct_jtag_scaner($self,$tview,$tv_ref,\$pipe,\$in, \$out, \$err) if($uname eq 'ProNoC_XILINX_UART' ); 
			run_stp_jtag_scaner($self,$tview,$tv_ref,\$pipe,\$in, \$out, \$err) if($uname eq 'ProNoC_ALTERA_UART' ); 
        }
    	return TRUE;
        
    } );
	
	
	$window->add($h1);
	$window->show_all();
	return $window;	
}	


 	



1;
