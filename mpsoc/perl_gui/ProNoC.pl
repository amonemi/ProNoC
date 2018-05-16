#!/usr/bin/perl -w

package ProNOC;



use Glib qw/TRUE FALSE/;


use Gtk2;
use strict;
use warnings;



use lib 'lib/perl';
require "widget.pl"; 
require "interface_gen.pl";
require "ip_gen.pl";
require "soc_gen.pl";
require "mpsoc_gen.pl";
require "emulator.pl";
require "simulator.pl";
require "trace_gen.pl";

use File::Basename;


our $VERSION = '1.8.0'; 

sub main{




my($width,$hight)=max_win_size();
set_defualt_font_size();


# check if envirement variables are defined
if ( !defined $ENV{PRONOC_WORK} || !defined $ENV{QUARTUS_BIN}) {
	my $message;
	if ( !defined $ENV{PRONOC_WORK}) {
		my $dir = Cwd::getcwd();
		my $project_dir	  = abs_path("$dir/../../mpsoc_work");
		$ENV{'PRONOC_WORK'}= $project_dir;
		$message= "\n\nWarning: PRONOC_WORK envirement varibale has not been set. The PRONOC_WORK is autumatically set to $ENV{'PRONOC_WORK'}.\n";
    
	}


  	
	$message= $message."Warning: QUARTUS_BIN environment variable has not been set. It is required only for working with NoC emulator." if(!defined $ENV{QUARTUS_BIN});
	
	$message= $message."\n\nPlease add aformentioned variables to ~\.bashrc file e.g: export PRONOC_WORK=[path_to]/mpsoc_work.";
    	message_dialog("$message");
    
}
my $table = Gtk2::Table->new (1, 3, FALSE);

			
	#________
	#radio btn "Generator"	
	my $rbtn_generator = Gtk2::RadioToolButton->new (undef);		
			
	my ($notebook,$noteref) = generate_main_notebook('Generator');
	my $window = def_win_size($width-100,$hight-100,"ProNoC");
	my $navIco = Gtk2::Gdk::Pixbuf->new_from_file("./icons/ProNoC.png");         # advance1.png");  
	$window->set_default_icon($navIco); 


 my @menu_items = (
  [ "/_File",            undef,        undef,          0, "<Branch>" ],
  [ "/File/_Quit",       "<control>Q", sub { Gtk2->main_quit },  0, "<StockItem>", 'gtk-quit' ],
  [ "/_View",                  undef, undef,         0, "<Branch>" ],
  [ "/_View/_ProNoC System Generator",  undef, 	sub{ open_page($notebook,$noteref,$table,'Generator'); } ,	0,	undef ],
  [ "/_View/_ProNoC Simulator",  undef, 	sub{ open_page($notebook,$noteref,$table,'Simulator'); } ,	0,	undef ],
 


  [ "/_Help", 		undef,		undef,          0, 	"<Branch>" ],
  [ "/_Help/_About",  	"F1", 		\&about ,	0,	undef ],
  [ "/_Help/_ProNoC System Overview",  	"F2", 		\&overview ,	0,	undef ],  
  [ "/_Help/_ProNoC User Manual",  "F3",		\&user_help, 	0,	undef ],
 
);





   
	
    my $accel_group = Gtk2::AccelGroup->new;
    $window->add_accel_group ($accel_group);
      
    my $item_factory = Gtk2::ItemFactory->new ("Gtk2::MenuBar", "<main>",$accel_group);

    # Set up item factory to go away with the window
    $window->{'<main>'} = $item_factory;

    # create menu items
    $item_factory->create_items ($window, @menu_items);

        

	$table->attach ($item_factory->get_widget ("<main>"),0, 1, 0,1,,'fill','fill',0,0); #,'expand','shrink',2,2);
   
    my $tt = Gtk2::Tooltips->new();


	#====================================
	#The handle box helps in creating a detachable toolbar 
	my $hb = Gtk2::HandleBox->new;
	#create a toolbar, and do some initial settings
	my $toolbar = Gtk2::Toolbar->new;
	$toolbar->set_icon_size ('small-toolbar');
	
	$toolbar->set_show_arrow (FALSE);
	
		
	
	
		
	$rbtn_generator->set_label ('Generator');
	$rbtn_generator->set_icon_widget (def_icon('icons/hardware.png'));
	set_tip($rbtn_generator, "ProNoC System Generator");
	$toolbar->insert($rbtn_generator,-1);
	
	
	
	#________
	#radio btn "Simulator"
	my $rbtn_simulator = Gtk2::RadioToolButton->new_from_widget($rbtn_generator);
	$rbtn_simulator->set_label ('Simulator');
	$rbtn_simulator->set_icon_widget (def_icon('icons/simulator.png')) ;
	
	set_tip($rbtn_simulator, "ProNoC Simulator");
	$toolbar->insert($rbtn_simulator,-1);
	
	
	
	
	
	$hb->add($toolbar);
	#====================================
	
	$rbtn_generator->signal_connect('toggled', sub{
		open_page($notebook,$noteref,$table,'Generator');
		
		
				
	});
	
	$rbtn_simulator->signal_connect('toggled', sub{
		open_page($notebook,$noteref,$table,'Simulator');
		
			
	});
 
   $table->attach ($hb,0, 1, 0,1,'fill','fill',0,0);
   $table->attach_defaults( $notebook, 0, 2, 1,2);

#$window->add($vbox);
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

}


sub about {
    my $about = Gtk2::AboutDialog->new;
    $about->set_authors("Alireza Monemi\n Email: alirezamonemi\@opencores.org");
    $about->set_version( $VERSION );
    $about->set_website('http://opencores.org/project,an-fpga-implementation-of-low-latency-noc-based-mpsoc');
    $about->set_comments('NoC based MPSoC generator.');
    $about->set_program_name('ProNoC');

    $about->set_license(
                 "This program is free software; you can redistribute it\n"
                . "and/or modify it under the terms of the GNU General \n"
		. "Public License as published by the Free Software \n"
		. "Foundation; either version 1, or (at your option)\n"
		. "any later version.\n\n"
                 
        );
	# Add the Hide action to the 'Close' button in the AboutDialog():
    $about->signal_connect('response' => sub { $about->hide; });


    $about->run;
    $about->destroy;
    return;
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



sub generate_main_notebook {
	my $mode =shift;
	
	my $notebook = Gtk2::Notebook->new;
	$notebook->show_all;
	if($mode eq 'Generator'){
		my $intfc_gen=  intfc_main();
		my $lable1=def_image_label("icons/intfc.png"," Interface generator ");
		$notebook->append_page ($intfc_gen,$lable1);#Gtk2::Label->new_with_mnemonic ("  _Interface generator  "));
		$lable1->show_all;

		my $ipgen=ipgen_main();
		my $lable2=def_image_label("icons/ip.png"," IP generator ");
		$notebook->append_page ($ipgen,$lable2);#Gtk2::Label->new_with_mnemonic ("  _IP generator  "));
		$lable2->show_all;

		my $socgen=socgen_main();
		my $lable3=def_image_label("icons/tile.png"," Processing tile generator ");			
		$notebook->append_page ($socgen,$lable3 );#,Gtk2::Label->new_with_mnemonic ("  _Processing tile generator  "));
		$lable3->show_all;		

		my $mpsocgen =mpsocgen_main();
		my $lable4=def_image_label("icons/noc.png"," NoC based MPSoC generator ");	
		$notebook->append_page ($mpsocgen,$lable4);#Gtk2::Label->new_with_mnemonic ("  _NoC based MPSoC generator  "));	
		$lable4->show_all;	
		
	
	} else{
		
		
		my $trace_gen= trace_gen_main();
		my $lable1=def_image_label("icons/trace.png"," Trace generator ");
		#my $lb=Gtk2::Label->new_with_mnemonic (" _Trace generator   ");
		set_tip($lable1, "Generate trace file from application task graph");
		
		$notebook->append_page ($trace_gen,$lable1);		
		$lable1->show_all;
		$trace_gen->show_all;
		
		my $simulator =simulator_main();
		my $lable2=def_image_label("icons/sim.png"," NoC simulator ");
		
		$notebook->append_page ($simulator,$lable2);#Gtk2::Label->new_with_mnemonic (" _NoC simulator   "));		
		$lable2->show_all;
		$simulator->show_all;		

		my $emulator =emulator_main();
		my $lable3=def_image_label("icons/emul.png"," NoC emulator ");
		$notebook->append_page ($emulator,$lable3);#Gtk2::Label->new_with_mnemonic (" _NoC emulator"));				
		$lable3->show_all;
		$emulator->show_all;

		

	}		
			
		my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);
		$scrolled_win->set_policy( "automatic", "automatic" );
		$scrolled_win->add_with_viewport($notebook);	
		$scrolled_win->show_all;
		

		return ($scrolled_win,$notebook);
	
}











Gtk2->init;
main;
Gtk2->main();
