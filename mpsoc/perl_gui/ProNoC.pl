#!/usr/bin/perl 
package ProNOC;





#add home dir in perl 5.6
use FindBin;
use lib $FindBin::Bin;
use constant::boolean;


use strict;
use warnings;


use lib 'lib/perl';
use Consts;


use Getopt::Long;
use base 'Class::Accessor::Fast';

our %glob_setting;
$glob_setting{'FONT_SIZE'}='default';
$glob_setting{'ICON_SIZE'}='default';
$glob_setting{'DSPLY_X'}  ='default';
$glob_setting{'DSPLY_Y'}  ='default';

BEGIN {
    my $module = (Consts::GTK_VERSION==2) ? 'Gtk2' : 'Gtk3';
    my $file = $module;
    $file =~ s[::][/]g;
    $file .= '.pm';
    require $file;
    $module->import;
}


require "widget.pl";
require "readme_gen.pl";
require "interface_gen.pl";
require "ip_gen.pl";
require "soc_gen.pl";
require "mpsoc_gen.pl";
require "emulator.pl";
require "simulator.pl";
require "trace_gen.pl";
require "network_maker.pl";
require "uart.pl";
require "run_time_jtag_debug.pl";
require "gdown.pl"; # google drive downlouder

use File::Basename;



use POSIX qw(locale_h);
use locale;
setlocale(LC_CTYPE, "en_US.UTF-8");#set numeric format to dot english

select(STDERR);
$| = 1;
select(STDOUT); # default
$| = 1;



sub main{
	# check if environment variables are defined
	#STDERR->autoflush ;
	my $project_dir	  = get_project_dir(); #mpsoc dir addr
	my $paths_file= "$project_dir/mpsoc/perl_gui/lib/Paths";
	if (-f 	$paths_file){#} && defined $ENV{PRONOC_WORK} ) {
		my $paths= do $paths_file;
		
		set_gui_setting($paths);
		
		main_window();		
	}
	else{
		show_setting(1);
	}	
}





sub main_window{
	
	set_path_env();

	my($width,$hight)=max_win_size();
	#print "($width,$hight)\n";
	
	set_defualt_font_size();
	
	if ( !defined $ENV{PRONOC_WORK} ) {
	my $message;
	if ( !defined $ENV{PRONOC_WORK}) {
		my $dir = Cwd::getcwd();
		my $project_dir	  = abs_path("$dir/../../mpsoc_work");
		$ENV{'PRONOC_WORK'}= $project_dir;
		$message= "\n\nWarning: PRONOC_WORK envirement varibale has not been set. The PRONOC_WORK is autumatically set to $ENV{'PRONOC_WORK'}.\n";
    
	}


  	
	#$message= $message."Warning: QUARTUS_BIN environment variable has not been set. It is required only for working with NoC emulator." if(!defined $ENV{QUARTUS_BIN});
	
	#$message= $message."\n\nPlease add aformentioned variables to ~\.bashrc file e.g: export PRONOC_WORK=[path_to]/mpsoc_work.";
    	message_dialog("$message");
    
}

	my $table = def_table(1,3,FALSE);
	
			
	#________
	#radio btn "Generator"	
		
			
	my ($notebook,$noteref) = generate_main_notebook('Generator');
	

	my $window = def_win_size($width-100,$hight-100,"ProNoC");
	set_pronoc_icon($window);


 my @menu_items = (
  [ "/_File",            undef,        undef,          0, "<Branch>" ],
  [ "/File/_Setting",       "<control>O", sub { show_setting(0); },  0,  undef ],
  [ "/File/_Restart",  "<control>R", sub { restart_Pronoc(); },  0,  undef ],
  [ "/File/_Quit",       "<control>Q", sub { gui_quite(); },  0, "<StockItem>", 'gtk-quit' ],
  
  [ "/Tools",            undef,        undef,          0, "<Branch>" ],
  [ "/Tools/_UART Terminal", "<control>U", sub { uart(0); },  0,  undef ],
  [ "/Tools/Run time JTAG debuger", "<control>P", sub { source_probe(0); },  0,  undef ],
  [ "/Tools/Add New Altera FPGA Board", undef, sub { add_altera_board(); },  0,  undef ],
  [ "/Tools/Add New XILINX FPGA Board", undef, sub { add_xilinx_board(); },  0,  undef ],
  
 
  [ "/_View",                  undef, undef,         0, "<Branch>" ],
  [ "/View/_ProNoC System Generator",  "<control>1", 	sub{ ($notebook,$noteref)=open_page($notebook,$noteref,$table,'Generator'); } ,	0,	undef ],
  [ "/View/_ProNoC Simulator",  "<control>2", 	sub{ ($notebook,$noteref)=open_page($notebook,$noteref,$table,'Simulator'); } ,	0,	undef ],
  [ "/View/_ProNoC Network maker",  "<control>3", 	sub{ ($notebook,$noteref)=open_page($notebook,$noteref,$table,'Networkgen'); } ,	0,	undef ],
 
 


  [ "/_Help", 		undef,		undef,          0, 	"<Branch>" ],
  [ "/Help/_About",  	"F1", 		sub{about(Consts::VERSION,$window)} ,	0,	undef ],
  [ "/Help/_ProNoC System Overview",  	"F2", 		\&overview ,	0,	undef ],  
  [ "/Help/_ProNoC User Manual",  "F3",		\&user_help, 	0,	undef ],
 
);
	
	my $menubar=gen_MenuBar($window,@menu_items);    
	$table->attach ($menubar,0, 1, 0,1,,'fill','fill',0,0); #,'expand','shrink',2,2);
    
   


	
	
	
	my $rbtn_generator = gen_radiobutton (undef,'Generator','icons/hardware.png','ProNoC System Generator'); 
	my $rbtn_simulator = gen_radiobutton ($rbtn_generator,'Simulator','icons/simulator.png', "ProNoC Simulator");
	my $rbtn_networkgen= gen_radiobutton ($rbtn_generator,'Network maker','icons/diagram.png', "ProNoC Topology Maker");
	
	

	my $dt=creating_detachable_toolbar($rbtn_generator,$rbtn_simulator,$rbtn_networkgen);
		
	$rbtn_generator->signal_connect('toggled', sub{
		($notebook,$noteref)=open_page($notebook,$noteref,$table,'Generator');				
	});
	
	$rbtn_simulator->signal_connect('toggled', sub{
		($notebook,$noteref)=open_page($notebook,$noteref,$table,'Simulator');		
	});
	
	$rbtn_networkgen->signal_connect('toggled', sub{
		($notebook,$noteref)=open_page($notebook,$noteref,$table,'Networkgen');		
	});	
 
   $table->attach ($dt,1, 2, 0,1,'shrink','fill',0,0);
   
   
   
   $table->attach_defaults( $notebook, 0, 2, 1,2);

	$window->add($table);
	$window->set_resizable (1);
	$window->show_all();		
}			


sub open_page{
	my ( $notebook,$noteref,$table,$page_name)=@_;
	$notebook->destroy;
	
	($notebook,$noteref) = generate_main_notebook($page_name);
	$table->attach_defaults( $notebook, 0, 2, 1,2);	
	$table->show_all;
	return ($notebook,$noteref);

}


sub user_help{ 
    my $dir = Cwd::getcwd();
    my $help="$dir/../../doc/ProNoC_User_manual.pdf";	
    system qq (xdg-open $help);
    return;
}

sub overview{
    my $dir = Cwd::getcwd();
    my $help="$dir/../../doc/ProNoC_System_Overview.pdf";	
    system qq (xdg-open $help);
    return;
}

sub show_setting{
	my $reset=shift;
	my $project_dir	  = get_project_dir(); #mpsoc dir addr
	my $paths_file= "$project_dir/mpsoc/perl_gui/lib/Paths";

	__PACKAGE__->mk_accessors(qw{
	PRONOC_WORK
	});
	my $self;
	if (-f 	$paths_file ){
		$self= do $paths_file;
	}else{
		$self = __PACKAGE__->new();
		
	}
	
	
	my $old_pronoc_work = $self->object_get_attribute("PATH","PRONOC_WORK");
	my $old_quartus = $self->object_get_attribute("PATH","QUARTUS_BIN");
	my $old_modelsim = $self->object_get_attribute("PATH","MODELSIM_BIN");
	make_undef_as_string(\$old_pronoc_work,\$old_quartus,\$old_modelsim);
	
	my $table=def_table(10,10,FALSE);	
	my $set_win=def_popwin_size(50,80,"Configuration setting",'percent');
	
	my $scrolled_win = add_widget_to_scrolled_win($table);
	

	my $row=0; my $col=0;
	
	#title1		
	my $title1=gen_label_in_center("Path setting");
	$table->attach ($title1 , 0, 10,  $row, $row+1,'expand','shrink',2,2); $row++;
	add_Hsep_to_table($table, 0, 10 , $row);	$row++;
    $table->attach_defaults (get_path_envirement_gui($self,$set_win,$reset) , 0, 10 , $row, $row+1);	$row++;
   
  

	#title2		
	my $title2=gen_label_in_center("Toolchain");
	$table->attach ($title2 , 0, 5,  $row, $row+1,'expand','shrink',2,2); 	
	$table->attach (gen_label_in_center("ORCC EDK"), 5, 10,  $row, $row+1,'expand','shrink',2,2); $row++;


	
	add_Hsep_to_table($table, 0, 10 , $row);	$row++;

	#check which toolchain is available in the system
	my @f1=("/bin/mb-g++","/bin/mb-objcopy");
	my @f2=("/bin/lm32-elf-gcc","/bin/lm32-elf-ld","/bin/lm32-elf-objcopy","/bin/lm32-elf-objdump","/lm32-elf/lib","/lib/gcc/lm32-elf/4.5.3");
	my @f3=("/bin/or1k-elf-gcc","/bin/or1k-elf-ld","/bin/or1k-elf-objcopy","/bin/or1k-elf-objdump","/lib/gcc/or1k-elf/5.2.0");
	
	my @tool = (
	{ label=>"aeMB", tooldir=>"aemb", files=>\@f1, size=>'21 MB', path=>'https://drive.google.com/file/d/1PT7lliPzhqsVl2Xq2bJsFuKu83Vk1ee4/view?usp=sharing' },
	{ label=>"lm32", tooldir=>"lm32", files=>\@f2, size=>'57 MB', path=>'https://drive.google.com/file/d/1ly32nItfQwBNxhTjDd5xoi7kXPPQjZz7/view?usp=sharing' },
	{ label=>"or1k-elf", tooldir=>"or1k-elf", files=>\@f3, size=>'219 MB', path=>'https://drive.google.com/file/d/1AeV3oeSltZ_aEqHcd419kfeI8EtHmUwr/view?usp=sharing' },
	);

	my @f4=("/dropins","/plugins");
    my @f5=("/AddArray", "/Communication", "/HelloWorld", "/README.md","/StreamBlocks");

	my @tool2 = (
	{ label=>"eclipse-orcc", tooldir=>"eclipse-orcc", files=>\@f4, size=>'208 MB', path=>'https://drive.google.com/file/d/1YAOAyAk8PA6LXwIPz3aIy-Mongh__WBW/view?usp=sharing' },
	{ label=>"orcc-apps", tooldir=>"orc-apps", files=>\@f5, size=>'28 MB', path=>'https://drive.google.com/file/d/1Qs4rxcSr-E5H4lYaxawqczTHfCPPCo4V/view?usp=sharing' },
	#{ label=>"or1k-elf", tooldir=>"or1k-elf", files=>\@f3, size=>'219 MB', path=>'https://drive.google.com/file/d/1AeV3oeSltZ_aEqHcd419kfeI8EtHmUwr/view?usp=sharing' },
	);

	$table->attach_defaults (check_toolchains($self,$set_win,$reset,"toolchain",@tool) , 0, 5 , $row, $row+1);	
	add_Vsep_to_table($table, 5, $row,$row+1);	
	$table->attach_defaults (check_toolchains($self,$set_win,$reset,"orcc",@tool2) , 5, 10 , $row, $row+1);	
	
	$row++;	
	#title3
	$table->attach (gen_label_in_center("Tools") , 0, 10,  $row, $row+1,'expand','shrink',2,2); $row++;
	add_Hsep_to_table($table, 0, 10 , $row);	$row++;

	#check which toolchain is available in the system
	$table->attach_defaults (check_tools($self,$set_win,$reset) , 0, 10 , $row, $row+1);$row++;
	
	#title4
	$table->attach (gen_label_in_center("GUI setting") , 0, 10,  $row, $row+1,'expand','shrink',2,2); $row++;
	add_Hsep_to_table($table, 0, 10 , $row);	$row++;
	$table->attach_defaults (get_gui_setting($self,$set_win,$reset) , 0, 10 , $row, $row+1);$row++;
	
	my $ok = def_image_button('icons/select.png','OK');
	my $mtable = def_table(10, 1, FALSE);

	$mtable->attach_defaults($scrolled_win,0,1,0,9);
	$mtable-> attach ($ok , 0, 1,  9, 10,'expand','shrink',2,2); 
	
	$set_win->add ($mtable);
	$set_win->show_all();
	
	
	
	$ok->signal_connect("clicked"=> sub{
		#save setting
		open(FILE,  ">$paths_file") || die "Can not open: $!";
		print FILE perl_file_header("Paths");
		print FILE Data::Dumper->Dump([\%$self],['setting']);
		close(FILE) || die "Error closing file: $!";
		my $pronoc_work = $self->object_get_attribute("PATH","PRONOC_WORK");
		my $quartus = $self->object_get_attribute("PATH","QUARTUS_BIN");
		my $modelsim = $self->object_get_attribute("PATH","MODELSIM_BIN");
		make_undef_as_string(\$pronoc_work,\$quartus,\$modelsim);
			
		if(($old_pronoc_work ne $pronoc_work) || !defined $ENV{PRONOC_WORK}){
			mkpath("$pronoc_work/emulate",1,01777) unless -d "$pronoc_work/emulate";
			mkpath("$pronoc_work/simulate",1,01777) unless -d "$pronoc_work/simulate";	
			mkpath("$pronoc_work/tmp",1,01777) unless -d "$pronoc_work/tmp";
			mkpath("$pronoc_work/toolchain",1,01777) unless -d "$pronoc_work/toolchain";
						
		}
		
		
	
		set_path_env();
		if($old_pronoc_work ne $pronoc_work ){
			update_bashrc_file($self,$old_pronoc_work,$old_quartus,$old_modelsim);			
		}

		my  ($file_path,$text)=@_;
		$set_win->destroy;
		
		my %new_setting = %{$self->object_get_attribute('GUI_SETTING')};
		my $eq=1;
		foreach my $k (sort keys %new_setting){
			$eq= 0 if	$new_setting{$k} ne $glob_setting{$k};
		}
			
		if($eq ==0){
			restart_Pronoc ();
		}
		
		main_window() if($reset);
		
		
		
		

	});
	
}

sub restart_Pronoc {
	exec($^X, $0, @ARGV);# reset ProNoC to apply changes	
}


sub get_path_envirement_gui {
	my($self,$set_win,$reset)=@_;
	my $table = def_table(10, 1, FALSE);
	my $row=0;
	my $col=0;
	my $project_dir	  = get_project_dir(); #mpsoc dir addr
	my $paths_file= "$project_dir/mpsoc/perl_gui/lib/Paths";
	my $old_pronoc_work = $self->object_get_attribute("PATH","PRONOC_WORK");
	my $old_quartus = $self->object_get_attribute("PATH","QUARTUS_BIN");
	my $old_modelsim = $self->object_get_attribute("PATH","MODELSIM_BIN");
	make_undef_as_string(\$old_pronoc_work,\$old_quartus,\$old_modelsim);
	
	
	
	my $pronoc_w_row=0;
	my @paths = (
	{ label=>"PRONOC_WORK", param_name=>"PRONOC_WORK", type=>"DIR_path", default_val=>"$project_dir/mpsoc_work", content=>undef, info=>"Define the working directory where the projects' files will be created", param_parent=>'PATH',ref_delay=>undef },
	{ label=>"QUARTUS_BIN", param_name=>"QUARTUS_BIN", type=>"DIR_path", default_val=>undef, content=>undef, info=>"Define the path to QuartusII compiler bin directory.  Setting of this variable is optional and is needed if you are going to use Altera FPGAs for implementation or emulation", param_parent=>'PATH',ref_delay=>undef },
	{ label=>"VIVADO_BIN", 	param_name=>"VIVADO_BIN", type=>"DIR_path", default_val=>undef, content=>undef, info=>"Define the path to Xilinx/Vivado compiler bin directory.  Setting of this variable is optional and is needed if you are going to use Xilinx FPGAs for implementation or emulation", param_parent=>'PATH',ref_delay=>undef },
	{ label=>"SDK_BIN"	,	param_name=>"SDK_BIN", type=>"DIR_path", default_val=>undef, content=>undef, info=>"Define the path to Xilinx/SDK/bin directory. Setting of this variable is optional and is needed if you are going to use Xilinx FPGAs for implementation or emulation", param_parent=>'PATH',ref_delay=>undef },
	{ label=>"MODELSIM_BIN",param_name=>"MODELSIM_BIN", type=>"DIR_path", default_val=>undef, content=>undef, info=>"Define the path to Modelsim simulator bin directory.  Setting of this variable is optional and is needed if you have installed Modelsim simulator and you want ProNoC to auto-generate the
simulation models using Modelsim software", param_parent=>'PATH',ref_delay=>undef },
		);	

	foreach my $d (@paths) {
		#$mpsoc,$name,$param, $default,$type,$content,$info, $table,$row,$column,$show,$attribut1,$ref_delay,$new_status,$loc
		my $widget;
		($row,$col)=add_param_widget ($self, $d->{label}, $d->{param_name}, $d->{default_val}, $d->{type}, $d->{content}, $d->{info}, $table,$row,$col,1, $d->{param_parent}, $d->{ref_delay},undef,"vertical");
		
	}
	#add apply buton for work dir
	my $apply=def_image_button("icons/enter.png",'Apply');
	$table->attach ($apply , 4, 5,  $pronoc_w_row, $pronoc_w_row+1,'fill','shrink',2,2); $row++;
	$apply->signal_connect("clicked"=> sub{
			my $pronoc_work = $self->object_get_attribute("PATH","PRONOC_WORK");
			make_undef_as_string(\$pronoc_work);
			if(($old_pronoc_work ne $pronoc_work)){
				open(FILE,  ">$paths_file") || die "Can not open: $!";
				print FILE perl_file_header("Paths");
				print FILE Data::Dumper->Dump([\%$self],['setting']);
				close(FILE) || die "Error closing file: $!";
				mkpath("$pronoc_work/emulate",1,01777) unless -d "$pronoc_work/emulate";
				mkpath("$pronoc_work/simulate",1,01777) unless -d "$pronoc_work/simulate";	
				mkpath("$pronoc_work/tmp",1,01777) unless -d "$pronoc_work/tmp";
				mkpath("$pronoc_work/toolchain",1,01777) unless -d "$pronoc_work/toolchain";
				update_bashrc_file($self,$old_pronoc_work,$old_quartus,$old_modelsim);	
					
			}
			set_path_env();		
		    $set_win->destroy;
			show_setting($reset);
	});
	return $table;	
}


sub update_bashrc_file {
	my ($self,$old_pronoc_work,$old_quartus,$old_modelsim)=@_;
	my $pronoc_work = $self->object_get_attribute("PATH","PRONOC_WORK");
	my $quartus = $self->object_get_attribute("PATH","QUARTUS_BIN");
	my $modelsim = $self->object_get_attribute("PATH","MODELSIM_BIN");
	
	my $response =  yes_no_dialog("ProNoC variable has been changed. Do you want to update ~/.bashrc file with new ones?");
	if ($response eq 'yes') {
     			make_undef_as_string(\$pronoc_work,\$quartus,\$modelsim);
				append_text_to_file ("$ENV{HOME}/.bashrc", "\nexport PRONOC_WORK=$pronoc_work\n") if(($old_pronoc_work ne $pronoc_work) || !defined $ENV{PRONOC_WORK}); 
				#append_text_to_file ("$ENV{HOME}/.bashrc", "export QUARTUS_BIN=$quartus\n") if($old_quartus ne $quartus) ;
				#append_text_to_file ("$ENV{HOME}/.bashrc", "export MODELSIM_BIN=$modelsim\n") if($old_modelsim ne $modelsim) ;
  	
  	
  	
  	}
  
}




sub check_toolchains{
	my ($self,$set_win,$reset,$root,@tool)=@_;
	my $table = def_table(10, 1, FALSE);
    my $pronoc_work = $self->object_get_attribute("PATH","PRONOC_WORK");
	mkpath("$pronoc_work/$root",1,01777) unless -d "$pronoc_work/$root";
	
	
	my $row =0;
	my $download_st=0;
	my $i=0;
	foreach my $d (@tool) {
		my $index=$i;
		$i++;
		my $exist=1;
		my $miss="";
		my $pronoc_work = $self->object_get_attribute("PATH","PRONOC_WORK");
		my $tooldir=$d->{tooldir};
		my @files=@{$d->{files}};
		my $tool_path="$pronoc_work/$root/$tooldir";
		unless (-d $tool_path){
			$exist=0;
			$miss=$miss." $tool_path is missing\n";
		}else{
			foreach my $f (@files){
				
				my $file_path= "$tool_path/$f";
				unless ( -f $file_path || -d $file_path){
					$exist=0;
					$miss=$miss." $file_path file is missing\n";
				}
			}
		}
		if ($exist==0){
			my $col=0;
			my $w=def_image_button("icons/warning.png",$d->{label});
			$w->signal_connect("clicked" => sub {message_dialog($miss);});	
			$table->attach ($w , $col, $col+1,  $row, $row+1,'shrink','shrink',2,2);  $col++;
			$table->attach (gen_label_in_center("Size: $d->{size}") , $col, $col+1,  $row, $row+1,'shrink','shrink',2,2);  $col++; 	
			my $dowload=def_image_button("icons/download.png",'Download Now');
			$table->attach ($dowload , $col, $col+1,  $row, $row+1,'shrink','shrink',2,2);  $col++;
			my $srow=	$row;
			$dowload ->signal_connect("clicked" => sub {
				$dowload ->set_sensitive (FALSE);
				$download_st = $download_st | (1 << $index);
				my $load= show_gif("icons/load.gif");
				$table->attach ($load, $col, $col+1, $srow,$srow+ 1,'shrink','shrink',0,0);  $col++;
				$load->show_all;
				my $filename="$pronoc_work/$root/$d->{label}.zip";
				my $target="$pronoc_work/$root/$d->{label}";
				#download the file from google drive
				download_from_google_drive("$d->{path}" ,"$filename"  );
				#unzip the file
				my $cmd= "unzip $pronoc_work/$root/$d->{label}.zip -d $pronoc_work/$root/";				
				return if(run_cmd_message_dialog_errors($cmd));
				$load->destroy;
				#remove zip file
				unlink "$pronoc_work/$root/$d->{label}.zip";
				$download_st = $download_st & ~(1 << $index);
				
				if ($download_st==0){
					$cmd = "chmod +x -Rf $pronoc_work/$root/";
					return if(run_cmd_message_dialog_errors($cmd));
					$set_win->destroy;
					show_setting($reset);
				}				
			});		
								
			$row++;			
		}else{
			my $w=def_image_label("icons/button_ok.png",$d->{label});
			$table->attach ($w , 0, 1,  $row, $row+1,'shrink','shrink',2,2); $row++;			
		}
			
	}			
	return $table;	
}







sub Dir_isEmpty {
    return 0 unless -d $_[0];
    opendir my $dh, $_[0] or die $!;
    my $count = () = readdir $dh;    # gets count thru ()
    return $count - 2;     #maybe not the best way of removing . and .
}

sub get_gui_setting{
	my ($self,$set_win,$reset)=@_;
	my $table = def_table(10, 1, FALSE);
	
	my $w="default";
	for (my $i=100;$i<3000;$i+=100) {$w.= ",$i";} 

	my @gui=(
	{ label=>'Font size:', param_name=>'FONT_SIZE', type=>'Combo-box', default_val=> $glob_setting{'FONT_SIZE'},
	  content=>"default,5,6,7,8,9,10,11,12,13,14,15", info=>undef, 
	  param_parent=>"GUI_SETTING", ref_delay=> undef, new_status=>undef},
	
	{ label=>'ICON size:', param_name=>'ICON_SIZE', type=>'Combo-box', default_val=> $glob_setting{'ICON_SIZE'},
	  content=>"default,11,14,17,20,23,26,29,32,35,38,41", info=>undef, 
	  param_parent=>"GUI_SETTING", ref_delay=> undef, new_status=>undef},
	  
	  
	{ label=>'Display width:', param_name=>'DSPLY_X', type=>'Combo-box', default_val=> $glob_setting{'DSPLY_X'},
	  content=>"$w", info=>undef, 
	  param_parent=>"GUI_SETTING", ref_delay=> undef, new_status=>undef}, 	  
	  
	  
	{ label=>'Display height:', param_name=>'DSPLY_Y', type=>'Combo-box', default_val=> $glob_setting{'DSPLY_Y'},
	  content=>"$w", info=>undef, 
	  param_parent=>"GUI_SETTING", ref_delay=> undef, new_status=>undef}, 	   	  	  
	
	);
	
	my $row=0;
	my $col=0;	
	foreach my $d ( @gui) {
		my $w;
		($row,$col,$w)=add_param_widget ($self, $d->{label}, $d->{param_name}, $d->{default_val}, $d->{type}, $d->{content}, $d->{info}, $table,$row,$col,1, $d->{param_parent}, $d->{ref_delay}, $d->{new_status},'Horizental');
		
	}

	return $table;
	
	
}


	
sub check_tools{
	my ($self,$set_win,$reset)=@_;
	my $table = def_table(10, 1, FALSE);
	my $row=0;
	my $pronoc_work = $self->object_get_attribute("PATH","PRONOC_WORK");
	my $label1;
	if (Dir_isEmpty("$pronoc_work/toolchain/bin") == 0){
		$label1=def_image_label("icons/warning.png","The tools directory is empty! You need to run the Make tools first.");	
		
	}else{
		$label1=gen_label_in_left("Regenerate ProNoC tools");
		
	}
	$table->attach ($label1 , 0, 1,  $row, $row+1,'shrink','shrink',2,2); 
	
	my $make=def_image_button('icons/setting2.png','Make tools');
	$table->attach ($make , 1, 2,  $row, $row+1,'shrink','shrink',2,2); $row++;
	my $srow = $row;
	$make ->signal_connect("clicked" => sub {
		#unzip the file
		$make ->set_sensitive (FALSE);
		my $load= show_gif("icons/load.gif");
		$table->attach ($load, 2, 3, $srow,$srow+ 1,'shrink','shrink',0,0);  		
				my $project_dir	  = get_project_dir(); #mpsoc dir addr
				my $cmd= "xterm -hold -e bash -c \' cd $project_dir/mpsoc/src_c; make; echo \"\n\nPlease close this window to continue .....\n\n\"\'";
				return if(run_cmd_message_dialog_errors($cmd));
				$load->destroy;
				$set_win->destroy;
				show_setting($reset);
		
	});	
	
	
	return $table;

}

sub uart {
	uart_main();	
}

sub source_probe{
	source_probe_main();	
}


sub global_param{
	my $project_dir	  = get_project_dir(); #mpsoc dir addr
	my $paths_file= "$project_dir/mpsoc/perl_gui/lib/glob_params";
	
	__PACKAGE__->mk_accessors(qw{
	PRONOC_WORK
	});
	my $self;
	if (-f 	$paths_file ){
		$self= do $paths_file;
	}else{
		$self = __PACKAGE__->new();		
	}
		
		
		
	
	my $table1=def_table(10,10,FALSE);	
	my $set_win=def_popwin_size(60,80,"Configuration setting",'percent');
	my $scrolled_win= add_widget_to_scrolled_win($table1);


	my $row=0; my $col=0;
	#title1		
	my $title1=gen_label_in_center("Global Parameters setting");
	$table1->attach ($title1 , 0, 10,  $row, $row+1,'expand','shrink',2,2); $row++;
	add_Hsep_to_table($table1, 0, 10 , $row);	$row++;
	
    
    my @parameters = object_get_attribute_order($self,'Parameters');
   	my $ok = def_image_button('icons/select.png','OK');
   


	foreach my $p (@parameters) {
	 	   	my $name = object_get_attribute($self,$p,'name');
			my $default = object_get_attribute($self,$p,'default');
			my $type= object_get_attribute($self,$p,'type');
			my $content= object_get_attribute($self,$p,'content');
			my $info= object_get_attribute($self,$p,'info');			
			add_param_widget($self,$name,$p, $default,$type,$content,$info, $table1,$row,$col,1,'Parameters',0,undef,undef);
			my $remove= def_image_button("icons/cancel.png","remove");
			$table1->attach ($remove, 4, 5, $row, $row+1,'expand','shrink',2,2);
			$row++;
			$remove->signal_connect (clicked => sub{
				delete $self->{$p};
				object_remove_attribute_order($self,'Parameters',$p);
				object_remove_attribute($self,'Parameters',$p);
				$ok->clicked;
				global_param();
			});	
	} 
	
	$row=0;  $col=0;
	my $table2=def_table(10,10,FALSE);	
	#title1		
	$title1=gen_label_in_center("Add new Global Parameter");
	$table2->attach ($title1 , 0, 10,  $row, $row+1,'expand','shrink',2,2); $row++;
	add_Hsep_to_table($table2, 0, 10 , $row);	$row++;	
	my $scrolled_win2= add_widget_to_scrolled_win($table2);
	
	my @widget_type_list=("Fixed","Entry","Combo-box","Spin-button");
    my $type_info="Define the parameter type: 

Fixed: The parameter is fixed and get the default value. Users can not see or change the parameter value.

Entry: The parameter value is received via entry. The user can type anything.

Combo-box: The parameter value can be selected from a list of predefined value.

Spin-button: The parameter is numeric and will be obtained using spin button.";
	my $content_info='
For Fixed and Entry leave it empty.
For Combo box define the parameters which must be shown in combo box as: "PAEAMETER1","PARAMETER2"...,"PARAMETERn".
For Spin button define it as "minimum, maximum, step" e.g 0,10,1.';
	my $param_info='Define how parameter is included in the top module containig this IP core.';
	
	
	#title
	my @title;
	$title[0]=gen_label_in_center("Parameter name");
	$title[1]=gen_label_in_center("Default value");
	$title[2]=gen_label_help($type_info,"Widget type");
	$title[3]=gen_label_help($content_info,"Widget content");
	$title[4]=gen_label_help("You can add aditional information about this parameter.","info");
	$title[5]=gen_label_in_center("add/remove");
	
	
	foreach my $t (@title){
		$table2->attach ($t, $col, $col+1, $row, $row+1,'expand','shrink',2,2); $col++;

	}
	$row++;$col=0;

	my $param_name= gen_entry();			
	my $default_entry= gen_entry();
	my $widget_type_combo=gen_combo(\@widget_type_list, 0);
	my $content_entry= gen_entry( );
	my $info=def_image_button("icons/add_info.png");
	my $add= def_image_button("icons/plus.png","add");
			
	$table2->attach ($param_name, $col, $col+1, $row, $row+1,'expand','shrink',2,2);$col++;
	$table2->attach ($default_entry, $col, $col+1, $row, $row+1,'expand','shrink',2,2);$col++;
	$table2->attach ($widget_type_combo, $col, $col+1, $row, $row+1,'expand','shrink',2,2);$col++;
	$table2->attach ($content_entry, $col, $col+1, $row, $row+1,'expand','shrink',2,2);$col++;
	$table2->attach ($info, $col, $col+1, $row, $row+1,'expand','shrink',2,2);$col++;
	$table2->attach ($add, $col, $col+1, $row, $row+1,'expand','shrink',2,2);$col++;
	my $sinfo;
	$info->signal_connect (clicked => sub{			
			get_param_info($self,\$sinfo);
		});	
		
	$add->signal_connect (clicked => sub{	
		my $param= $param_name->get_text();
		$param=remove_all_white_spaces($param);
			        
		if( length($param) ){
				my $default=$default_entry->get_text();
				my $type=$widget_type_combo->get_active_text();
				my $content=$content_entry->get_text();
				
				object_add_attribute($self,$param,'name',$param);
			    object_add_attribute($self,$param,'default',$default);
			    object_add_attribute($self,$param,'type',$type);
			    object_add_attribute($self,$param,'content',$content);
			    object_add_attribute($self,$param,'info',$sinfo);			
				object_add_attribute_order($self,'Parameters',$param);
				$ok->clicked;
				global_param();
		}
		
		
	});		

	
	
	
	
	my $mtable = def_table(10, 1, FALSE);
    my $v2=gen_vpaned($scrolled_win,.55,$scrolled_win2);
	$mtable->attach_defaults($v2,0,1,0,9);
	
	$mtable-> attach ($ok , 0, 1,  9, 10,'expand','shrink',2,2); 
	
	$set_win->add ($mtable);
	$set_win->show_all();
	
	
	
	$ok->signal_connect("clicked"=> sub{
		#save setting
		open(FILE,  ">$paths_file") || die "Can not open: $!";
		print FILE perl_file_header("Paths");
		print FILE Data::Dumper->Dump([\%$self],['glob']);
		close(FILE) || die "Error closing file: $!";
	
			
		

	
		$set_win->destroy;
	

	});
	
	
	
	
	
	
}







sub add_altera_board{
	
	__PACKAGE__->mk_accessors(qw{
	PRONOC_WORK
	});
	my $self= __PACKAGE__->new();
		
	
	
	add_new_fpga_board($self,undef,undef,undef,undef,'Altera');
	
}

sub add_xilinx_board{
		__PACKAGE__->mk_accessors(qw{
	PRONOC_WORK
	});
	my $self= __PACKAGE__->new();
		
	add_new_fpga_board($self,undef,undef,undef,undef,'Xilinx');
	
	
}


sub generate_main_notebook {
	my $mode =shift;
	
	my $notebook = gen_notebook();
	$notebook->show_all;
	if($mode eq 'Generator'){
		my $intfc_gen=  intfc_main();
		my $label1=def_image_label("icons/intfc.png"," _Interface generator ",1);
		$notebook->append_page ($intfc_gen,$label1);
		$label1->show_all;

		my $ipgen= ipgen_main();
		my $label2=def_image_label("icons/ip.png"," I_P generator ",1);
		$notebook->append_page ($ipgen,$label2);
		$label2->show_all;

		my $socgen= socgen_main();
		my $label3=def_image_label("icons/tile.png"," P_rocessing tile generator ",1);			
		$notebook->append_page ($socgen,$label3 );
		$label3->show_all;		

		my $mpsocgen =  mpsocgen_main();
		my $label4=def_image_label("icons/noc.png"," _NoC based MPSoC generator ",1);	
		$notebook->append_page ($mpsocgen,$label4);
		$label4->show_all;	
		
	
	} elsif($mode eq 'Networkgen'){
	
		my $networkgen = network_maker_main();
		my $label5=def_image_label("icons/trace.png"," Network Maker ");	
		$notebook->append_page ($networkgen,$label5);
		$label5->show_all;	
	
	
	}else{
			
		
		
		
		my $simulator = simulator_main();
		my $label2=def_image_label("icons/sim.png"," _NoC simulator ",1);
		
		
		$notebook->append_page ($simulator,$label2);
		$label2->show_all;
		$simulator->show_all;		

		my $emulator = emulator_main();
		my $label3=def_image_label("icons/emul.png"," _NoC emulator ",1);
		$notebook->append_page ($emulator,$label3);
		$label3->show_all;
		$emulator->show_all;	

		my $trace_gen= trace_gen_main('task');
		my $label1=def_image_label("icons/trace.png"," _Trace generator ",1);

		set_tip($label1, "Generate trace file from application task graph");
		
		$notebook->append_page ($trace_gen,$label1);		
		$label1->show_all;
		$trace_gen->show_all;


	}		
		my $scrolled_win = add_widget_to_scrolled_win($notebook);			

		return ($scrolled_win,$notebook);	
}




	gtk_gui_run(\&main);


