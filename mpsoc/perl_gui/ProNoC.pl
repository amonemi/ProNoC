#!/usr/bin/perl -w

use Glib qw/TRUE FALSE/;


use Gtk2;
use strict;
use warnings;
#use Image::Base::Gtk2::Gdk::Pixbuf;

use lib 'lib/perl';
require "widget.pl"; 
require "interface_gen.pl";
require "ip_gen.pl";
require "soc_gen.pl";
require "mpsoc_gen.pl";
require "noc_sim.pl";

#use PDF::API2;



sub set_deafualt_font{
	my($width,$hight)=@_;
	#print "($width,$hight)\n";
	my $font_size;
	if($width>1600){
	    $font_size=10;
		Gtk2::Rc->parse_string(<<__);
			style "normal" { 
				font_name ="Verdana 10" 
			}
			widget "*" style "normal"
__

	}
	elsif ($width>1400){
		$font_size=9;
		Gtk2::Rc->parse_string(<<__);
		style "normal" { 
				font_name ="Verdana 9" 
			}
			widget "*" style "normal"
__

	}
	elsif ($width>1200){
		$font_size=8;
		Gtk2::Rc->parse_string(<<__);
		style "normal" { 
				font_name ="Verdana 8" 
			}
			widget "*" style "normal"
__

	}
	elsif ($width>1000){
	    $font_size=7;
		Gtk2::Rc->parse_string(<<__);
		style "normal" { 
				font_name ="Verdana 7" 
			}
			widget "*" style "normal"
__

	}
	else{
	    $font_size=6;
		Gtk2::Rc->parse_string(<<__);
		style "normal" { 
				font_name ="Verdana 6" 
			}
			widget "*" style "normal"
__

	}
	#print "	    \$font_size=	    $font_size\n";
	return 	    $font_size;
	

}

sub get_mpsoc{
	my ($ipgen,$soc_state,$info)=@_;
	my $description = "Will be available soon!";
	my $table = Gtk2::Table->new (15, 15, TRUE);
	#my $window=def_popwin_size(500,500,"Add description");
	my ($scrwin,$text_view)=create_text();
	#my $buffer = $textbox->get_buffer();
	my $ok=def_image_button("icons/select.png",' Ok ');
	
	$table->attach_defaults($scrwin,0,15,0,14);
	$table->attach_defaults($ok,6,9,14,15);
	my $text_buffer = $text_view->get_buffer;
	if(defined $text_buffer) {$text_buffer->set_text($description)};
	
	$ok->signal_connect("clicked"=> sub {
				 
		my $text = $text_buffer->get_text($text_buffer->get_bounds, TRUE);
		# $ipgen->ipgen_set_description($text);	
		print "$text\n";
		
	});
	
	#$window->add($table);
	#$window->show_all();
	return $table;
	
}	




sub main{



my $notebook = Gtk2::Notebook->new;
#$hbox->pack_start ($notebook, TRUE, TRUE, 0);

my($width,$hight)=max_win_size();
set_deafualt_font_size();



my $intfc_gen=  intfc_main();
$notebook->append_page ($intfc_gen,Gtk2::Label->new_with_mnemonic ("_Interface generator"));

my $ipgen=ipgen_main();
$notebook->append_page ($ipgen,Gtk2::Label->new_with_mnemonic ("_IP generator"));

my $socgen=socgen_main();			
$notebook->append_page ($socgen,Gtk2::Label->new_with_mnemonic ("_Processing tile generator"));

my $mpsocgen =mpsocgen_main();
$notebook->append_page ($mpsocgen,Gtk2::Label->new_with_mnemonic ("_NoC based MPSoC generator"));	

								
			
			
			
		my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);
		$scrolled_win->set_policy( "automatic", "automatic" );
		$scrolled_win->add_with_viewport($notebook);	
		
		my $window = def_win_size($width-100,$hight-100,"ProNoC");
		#$window->add($scrolled_win);
		

		my $navIco = Gtk2::Gdk::Pixbuf->new_from_file("./icons/ProNoC.png");         # advance1.png");  
		$window->set_default_icon($navIco); 


	





		my @entries = (
        ### Everything falls under the following 3 rows ###
        [ 'FileMenu',       undef, '_File' ],
        [ 'ViewMenu',       undef, '_View' ],
        [ 'HelpMenu',       undef, '_Help' ],

        # Quit
        [   'Exit',           'gtk-quit',
            'E_xit', '<control>X',
            undef,      sub { Gtk2->main_quit },
            FALSE
        ],
        # About
        [   'About',                          'gtk-about',
            '_About',                           '<control>A',
            undef,      \&about,
            FALSE
        ],

	 # intf_gen help
        [   'interface generator',                          'gtk-about',
            '_Interface generator',                           'F1',
            undef,      \&intfc_help,
            FALSE
        ],
	 # ip_gen help
        [   'ip generator',                          'gtk-about',
            '_IP generator',                           'F2',
            undef,      \&ip_help,
            FALSE
        ],
	 # pt_gen help
        [   'pt generator',                          'gtk-about',
            '_Processing tile generator',                           'F3',
            undef,      \&pt_help,
            FALSE
        ],
);

    my $ui_info = "<ui>
        <menubar name='MenuBar'>
         <menu action='FileMenu'>
          <separator/>
          <menuitem action='Exit'/>
         </menu>
          <menu action='ViewMenu'>
         </menu>
         <menu action='HelpMenu'>
          <menuitem action='About'/>
	  <menuitem action='interface generator'/>
	  <menuitem action='ip generator'/>
	  <menuitem action='pt generator'/>

         </menu>
        </menubar>
</ui>";

    my $actions = Gtk2::ActionGroup->new('Actions');
    $actions->add_actions( \@entries, undef );

    my $ui = Gtk2::UIManager->new;
    $ui->insert_action_group( $actions, 0 );

    $window->add_accel_group( $ui->get_accel_group );
    $ui->add_ui_from_string($ui_info);
   my $vbox = Gtk2::VBox->new( FALSE, 0 );
    $vbox->pack_start( $ui->get_widget('/MenuBar'), FALSE, FALSE, 0 );
    $vbox->pack_end( $scrolled_win, TRUE, TRUE,10 );

$window->add($vbox);




		$window->set_resizable (1);
		$window->show_all();
		
		
	 
	 





}			



sub about {
    my $about = Gtk2::AboutDialog->new;
    $about->set_authors("Alireza Monemi\n Email: alirezamonemi\@opencores.org");
    $about->set_version( '1.0' );
    $about->set_website('http://opencores.org/project,an-fpga-implementation-of-low-latency-noc-based-mpsoc');
    $about->set_comments('NoC based MPSoC generator.');
    $about->set_license(
                 "This program is free software; you can redistribute it\n"
                . "and/or modify it under the terms of the GNU General \n"
		. "Public License as published by the Free Software \n"
		. "Foundation; either version 1, or (at your option)\n"
		. "any later version.\n\n"
                 
        );
    $about->run;
    $about->destroy;
    return;
}

sub intfc_help{
    my $dir = Cwd::getcwd();
    my $help="$dir/doc/interface_gen.pdf";	
    system qq (xdg-open $help);
    return;

}

sub ip_help{ 
    my $dir = Cwd::getcwd();
    my $help="$dir/doc/ip_gen.pdf";	
    system qq (xdg-open $help);
    return;
}



sub pt_help{ 
    my $dir = Cwd::getcwd();
    my $help="$dir/doc/pt-gen.pdf";	
    system qq (xdg-open $help);
    return;
}




Gtk2->init;
main;
Gtk2->main();
