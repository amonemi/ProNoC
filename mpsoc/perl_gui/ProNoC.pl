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




our $VERSION = '1.6.0'; 

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


my $notebook = Gtk2::Notebook->new;

my $intfc_gen=  intfc_main();
$notebook->append_page ($intfc_gen,Gtk2::Label->new_with_mnemonic ("  _Interface generator  "));

my $ipgen=ipgen_main();
$notebook->append_page ($ipgen,Gtk2::Label->new_with_mnemonic ("  _IP generator  "));

my $socgen=socgen_main();			
$notebook->append_page ($socgen,Gtk2::Label->new_with_mnemonic ("  _Processing tile generator  "));

my $mpsocgen =mpsocgen_main();
$notebook->append_page ($mpsocgen,Gtk2::Label->new_with_mnemonic ("  _NoC based MPSoC generator  "));	


my $simulator =simulator_main();
$notebook->append_page ($simulator,Gtk2::Label->new_with_mnemonic (" _NoC simulator   "));		

my $emulator =emulator_main();
$notebook->append_page ($emulator,Gtk2::Label->new_with_mnemonic (" _NoC emulator "));								
			
			
			
		my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);
		$scrolled_win->set_policy( "automatic", "automatic" );
		$scrolled_win->add_with_viewport($notebook);	
		
		my $window = def_win_size($width-100,$hight-100,"ProNoC");
		#$window->add($scrolled_win);
		

		my $navIco = Gtk2::Gdk::Pixbuf->new_from_file("./icons/ProNoC.png");         # advance1.png");  
		$window->set_default_icon($navIco); 


	





		my @menu_items = (
     

  [ "/_File",            undef,        undef,          0, "<Branch>" ],
 # [ "/File/_New",        "<control>N", \&menuitem_cb,  0, "<StockItem>", 'gtk-new' ],
 # [ "/File/_Open",       "<control>O", \&menuitem_cb,  0, "<StockItem>", 'gtk-open' ],
 # [ "/File/_Save",       "<control>S", \&menuitem_cb,  0, "<StockItem>", 'gtk-save' ],
 # [ "/File/Save _As...", undef,        \&menuitem_cb,  0, "<StockItem>", 'gtk-save' ],
 # [ "/File/sep1",        undef,        \&menuitem_cb,  0, "<Separator>" ],
  [ "/File/_Quit",       "<control>Q", sub { Gtk2->main_quit },  0, "<StockItem>", 'gtk-quit' ],

  [ "/_View",                  undef, undef,         0, "<Branch>" ],


  ["/_Help", 		undef,		undef,          0, 	"<Branch>" ],
  ["/_Help/_About",  	"F1", 		\&about ,	0,	undef ],
  ["/_Help/_intf_gen",  "F2",		\&intfc_help, 	0,	undef ],
  ["/_Help/_ip_gen",  	"F3", 		\&ip_help ,	0,	undef ],
  ["/_Help/_pt_gen",  	"F4", 		\&pt_help ,	0,	undef ],
  ["/_Help/_sim_help",  "F5",		\&sim_help ,	0,	undef ],
  ["/_Help/_Tutorial_1", undef, 	\&Tutorial_1 ,	0,	undef ],
  ["/_Help/_Tutorial_2", undef, 	\&Tutorial_2 ,	0,	undef ],




  #["/_View/_Font12",    undef,         sub{ setfont(12,,$window)} ,   0, "<RadioItem>" ],	
 

  #[ "/_Preferences",                  undef, undef,         0, "<Branch>" ],
  #[ "/_Preferences/_Color",           undef, undef,         0, "<Branch>" ],
  #[ "/_Preferences/Color/_Red",       undef, \&menuitem_cb, 0, "<RadioItem>" ],
  #[ "/_Preferences/Color/_Green",     undef, \&menuitem_cb, 0, "/Preferences/Color/Red" ],
  #[ "/_Preferences/Color/_Blue",      undef, \&menuitem_cb, 0, "/Preferences/Color/Red" ],
  #[ "/_Preferences/_Shape",           undef, undef,         0, "<Branch>" ],
  #[ "/_Preferences/Shape/_Square",    undef, \&menuitem_cb, 0, "<RadioItem>" ],
  #[ "/_Preferences/Shape/_Rectangle", undef, \&menuitem_cb, 0, "/Preferences/Shape/Square" ],
  #[ "/_Preferences/Shape/_Oval",      undef, \&menuitem_cb, 0, "/Preferences/Shape/Rectangle" ],

);





   
   #my $table = Gtk2::Table->new (1, 4, FALSE);
     my $vbox = Gtk2::VBox->new( FALSE, 0 );  
            
      my $accel_group = Gtk2::AccelGroup->new;
      $window->add_accel_group ($accel_group);
      
      my $item_factory = Gtk2::ItemFactory->new ("Gtk2::MenuBar", "<main>", 
                                                 $accel_group);

      # Set up item factory to go away with the window
      $window->{'<main>'} = $item_factory;

      # create menu items
      $item_factory->create_items ($window, @menu_items);

     


 $vbox->pack_start( $item_factory->get_widget ("<main>"), FALSE, FALSE, 0 );
 	

	

  #  my $ui = Gtk2::UIManager->new;
  #  $ui->insert_action_group( $actions, 0 );
   # Add the actiongroup to the uimanager		
 #	$ui->insert_action_group($radio_actions,0);

  #  $window->add_accel_group( $ui->get_accel_group );
  #  $ui->add_ui_from_string($ui_info);

    #my $actions_media = Gtk2::ActionGroup->new ("media_dvd");
   

   
  # $vbox->pack_start( $ui->get_widget('/MenuBar'), FALSE, FALSE, 0 );
    $vbox->pack_end( $scrolled_win, TRUE, TRUE,10 );

$window->add($vbox);




		$window->set_resizable (1);
		$window->show_all();
		
		
	 
	 





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

sub intfc_help{
    my $dir = Cwd::getcwd();
    my $help="$dir/doc/ProNoC_intfc_gen.pdf";	
    system qq (xdg-open $help);
    return;

}

sub ip_help{ 
    my $dir = Cwd::getcwd();
    my $help="$dir/doc/ProNoC_ip_gen.pdf";	
    system qq (xdg-open $help);
    return;
}



sub pt_help{ 
    my $dir = Cwd::getcwd();
    my $help="$dir/doc/ProNoC_pt_gen.pdf";	
    system qq (xdg-open $help);
    return;
}


sub sim_help{ 
    my $dir = Cwd::getcwd();
    my $help="$dir/doc/ProNoC_simulator.pdf";	
    system qq (xdg-open $help);
    return;
}


sub Tutorial_1{
    my $dir = Cwd::getcwd();
    my $help="$dir/doc/ProNoC_Tutorial1.pdf";	
    system qq (xdg-open $help);
    return;

}

sub Tutorial_2{
    my $dir = Cwd::getcwd();
    my $help="$dir/doc/ProNoC_Tutorial2.pdf";	
    system qq (xdg-open $help);
    return;

}



Gtk2->init;
main;
Gtk2->main();
